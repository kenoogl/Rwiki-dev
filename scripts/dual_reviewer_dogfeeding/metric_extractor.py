"""metric_extractor.py — JSONL log → 12 軸 metric 算出 (Req 4.1-4.7).

Input: dev_log.jsonl (foundation review_case schema、treatment / round_index / design_md_commit_hash 4 field 含む consumer 拡張)
Output: dogfeeding_metrics.json (6 top-level field = version / session_count / treatments / rounds / commit_hash_variance / metrics)

12 軸 metric per treatment:
- detection_count / must_fix_count + ratio / should_fix_count + ratio / do_not_fix_count + ratio
- adoption_rate (= must_fix_ratio + should_fix_ratio)
- over_correction_ratio (= do_not_fix_ratio)
- adversarial_disagreement_count (= adversarial 修正否定 with primary disagreement)
- judgment_override_count + override_reasons
- wall_clock_seconds (timestamp_end - timestamp_start ISO8601 UTC normalize)
- phase_1_isomorphism_hit (= miss_type / difference_type に Phase 1 metapatterns 出現)
- fatal_patterns_hit (= fatal_patterns 8 種 enum hit)

Helper: helpers.py から resolve_foundation_root + _resolve_foundation_path を import (DRY、P3 apply)
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

# DRY 規律 (P3 apply): helpers.py から共通 helper import
sys.path.insert(0, str(Path(__file__).resolve().parent))
from helpers import resolve_foundation_root, _resolve_foundation_path  # noqa: E402

VERSION = "1.0"


def _parse_iso8601(s: str) -> datetime:
  """ISO8601 string → tz-aware datetime (UTC normalize)."""
  # Python 3.11+ supports `Z` suffix in fromisoformat, but for safety we replace
  if s.endswith("Z"):
    s = s[:-1] + "+00:00"
  dt = datetime.fromisoformat(s)
  return dt.astimezone(timezone.utc)


def _wall_clock_seconds(rc: dict) -> float:
  start = _parse_iso8601(rc["timestamp_start"])
  end = _parse_iso8601(rc["timestamp_end"])
  return (end - start).total_seconds()


def _label(finding: dict) -> str | None:
  necessity = finding.get("necessity_judgment")
  if not necessity:
    return None
  return necessity.get("fix_decision", {}).get("label")


_SKIP_PREFIXES = ("skip", "do_not_fix")


def _is_skip_value(v: str) -> bool:
  """user_decisions value (= prefix 不統一の文字列) から skip 判定 (= do_not_fix 同等)."""
  if not isinstance(v, str):
    return False
  v_lower = v.lower()
  if any(v_lower.startswith(p) for p in _SKIP_PREFIXES):
    return True
  if "skip_" in v_lower[:30] or "do_not_fix" in v_lower[:50]:
    return True
  return False


def _aggregate_findings_array(findings: list[dict], m: dict[str, Any]) -> None:
  """Path A: legacy findings[] array path (test fixture + entry に findings 含む dual+judgment 場合).

  必要性判定 5-field がある finding を `necessity_judgment.fix_decision.label` で集計.
  """
  for f in findings:
    if not isinstance(f, dict):
      continue
    m["detection_count"] += 1
    label = _label(f)
    if label == "must_fix":
      m["must_fix_count"] += 1
    elif label == "should_fix":
      m["should_fix_count"] += 1
    elif label == "do_not_fix":
      m["do_not_fix_count"] += 1
    necessity = f.get("necessity_judgment", {})
    if necessity.get("override_reason"):
      m["judgment_override_count"] += 1
      m["override_reasons"].append(necessity["override_reason"])
    if f.get("source") == "adversarial" and label in ("must_fix", "do_not_fix"):
      m["adversarial_disagreement_count"] += 1


def _aggregate_judgment_label_distribution(rc: dict, m: dict[str, Any]) -> None:
  """Path A': dual+judgment 実 data path = `judgment_label_distribution` 累計集計.

  47th 末確認: 実 data dual+judgment では judgment_label_distribution.must_fix/should_fix/do_not_fix
    の合計が §12 total detect (= 69) と一致、do_not_fix が §12 do_not_fix (= 23) と一致。
  override / adversarial_disagreement は findings[] が同 entry に在る場合は補完集計.
  """
  jld = rc.get("judgment_label_distribution", {})
  if not isinstance(jld, dict):
    return
  must = jld.get("must_fix", 0)
  should = jld.get("should_fix", 0)
  dnf = jld.get("do_not_fix", 0)
  m["detection_count"] += must + should + dnf
  m["must_fix_count"] += must
  m["should_fix_count"] += should
  m["do_not_fix_count"] += dnf
  # findings[] が同 entry にあれば override / adversarial_disagreement のみ補完
  findings = rc.get("findings", [])
  if isinstance(findings, list):
    for f in findings:
      if not isinstance(f, dict):
        continue
      label = _label(f)
      necessity = f.get("necessity_judgment", {})
      if necessity.get("override_reason"):
        m["judgment_override_count"] += 1
        m["override_reasons"].append(necessity["override_reason"])
      if f.get("source") == "adversarial" and label in ("must_fix", "do_not_fix"):
        m["adversarial_disagreement_count"] += 1
  # top-level judgment_override_count もあれば反映 (override_reasons は dev_log に明示なしの場合 0 で OK)
  rc_override = rc.get("judgment_override_count", 0)
  if rc_override and not findings:
    m["judgment_override_count"] += rc_override


def _aggregate_summary_arrays(rc: dict, m: dict[str, Any]) -> None:
  """Path B: judgment skip 系統 + summary item が dict (= 完全 schema) の場合.

  detection_count = primary_findings_summary + adversarial_findings_summary 件数
    (forced_divergence は count up しない、§12 整合 = total detect は P + A のみ)
  user_decision == "skip" → do_not_fix_count に集計、他 → must_fix_count.
  """
  primary = rc.get("primary_findings_summary", [])
  adversarial = rc.get("adversarial_findings_summary", [])
  ud_top = rc.get("user_decisions", {}) if isinstance(rc.get("user_decisions"), dict) else {}
  for item in list(primary) + list(adversarial):
    m["detection_count"] += 1
    if not isinstance(item, dict):
      m["must_fix_count"] += 1
      continue
    decision = item.get("user_decision", "")
    is_skip = _is_skip_value(decision)
    # fallback: item.user_decision 空 + top-level user_decisions[issue_id|finding_id] が skip
    if not is_skip and not decision:
      iid = item.get("issue_id") or item.get("finding_id") or ""
      if iid in ud_top:
        is_skip = _is_skip_value(ud_top[iid])
    if is_skip:
      m["do_not_fix_count"] += 1
    else:
      m["must_fix_count"] += 1


def _aggregate_top_level_with_user_decisions(rc: dict, m: dict[str, Any]) -> None:
  """Path C: 実 data 救済 path (= summary array が壊れている R9/R10 dual 等).

  detection_count = top-level primary_findings_count + adversarial_findings_count.
  do_not_fix_count = user_decisions value で skip prefix or do_not_fix を含むものを集計.
  """
  p = rc.get("primary_findings_count", 0)
  a = rc.get("adversarial_findings_count", 0)
  m["detection_count"] += p + a
  ud = rc.get("user_decisions", {})
  if isinstance(ud, dict):
    for k, v in ud.items():
      if _is_skip_value(v):
        m["do_not_fix_count"] += 1
      else:
        m["must_fix_count"] += 1


def _summary_items_usable(items: list) -> bool:
  """summary array の全 item が dict (= 解釈可能) か."""
  if not items:
    return False
  return all(isinstance(x, dict) for x in items)


def extract_metrics(jsonl_path: Path) -> dict[str, Any]:
  """JSONL log read + 12 軸 metric 算出.

  schema 分岐 (47th 末改修):
  - dual+judgment 系統 = `findings[]` array (= necessity_judgment.fix_decision.label 集計、Path A)
  - single / dual 系統 = `primary_findings_summary[]` + `adversarial_findings_summary[]`
    + `forced_divergence_summary[]` (judgment skip で findings[] 不在、Path B)
  過剰修正比率は系統横断統一 = skip 件数 (B 系統) / do_not_fix 件数 (A 系統) を do_not_fix_count に集計、
    over_correction_ratio = do_not_fix_count / detection_count (= total detect P+A)
  """
  jsonl_path = Path(jsonl_path)
  if not jsonl_path.is_file():
    raise FileNotFoundError(jsonl_path)

  review_cases: list[dict] = []
  hashes: set[str] = set()
  with jsonl_path.open(encoding="utf-8") as f:
    for line_no, line in enumerate(f, 1):
      line = line.strip()
      if not line:
        continue
      try:
        rc = json.loads(line)
      except json.JSONDecodeError as e:
        raise ValueError(f"JSON parse fail at line {line_no}: {e}")
      review_cases.append(rc)
      h = rc.get("design_md_commit_hash")
      if h:
        hashes.add(h)

  treatments_seen: set[str] = set()
  rounds_seen: set[int] = set()
  per_treatment: dict[str, dict[str, Any]] = {}
  for rc in review_cases:
    t = rc.get("treatment", "single")
    treatments_seen.add(t)
    rounds_seen.add(rc.get("round_index", 0))
    if t not in per_treatment:
      per_treatment[t] = {
        "detection_count": 0,
        "must_fix_count": 0, "should_fix_count": 0, "do_not_fix_count": 0,
        "wall_clock_seconds": 0.0,
        "judgment_override_count": 0, "override_reasons": [],
        "fatal_patterns_hit": 0, "phase_1_isomorphism_hit": 0,
        "adversarial_disagreement_count": 0,
        # top-level count field aggregation (47th 末改修: dev_log の上位 field を per-treatment 保持)
        "primary_findings_count": 0,
        "adversarial_findings_count": 0,
        "forced_divergence_findings_count": 0,
      }
    m = per_treatment[t]
    m["wall_clock_seconds"] += _wall_clock_seconds(rc)
    # top-level count field aggregation
    m["primary_findings_count"] += rc.get("primary_findings_count", 0)
    m["adversarial_findings_count"] += rc.get("adversarial_findings_count", 0)
    m["forced_divergence_findings_count"] += rc.get("forced_divergence_findings_count", 0)
    # schema 分岐 4 path (priority A' > A > B > C):
    #   A' = judgment_label_distribution non-empty (= dual+judgment 実 data 主軸)
    #   A  = legacy findings[] array (test fixture + judgment label 不在で findings 在る場合)
    #   B  = summary array dict items (= single / dual 健全 entry)
    #   C  = top-level count + user_decisions (= 実 data 救済 = summary 壊れ R9/R10 dual 等)
    jld = rc.get("judgment_label_distribution", {})
    jld_total = 0
    if isinstance(jld, dict):
      jld_total = jld.get("must_fix", 0) + jld.get("should_fix", 0) + jld.get("do_not_fix", 0)
    findings = rc.get("findings")
    primary_summary = rc.get("primary_findings_summary", [])
    adversarial_summary = rc.get("adversarial_findings_summary", [])
    summary_usable = (
      _summary_items_usable(primary_summary) or _summary_items_usable(adversarial_summary)
      or (not primary_summary and not adversarial_summary)
    )

    if jld_total > 0:
      _aggregate_judgment_label_distribution(rc, m)
    elif findings:
      _aggregate_findings_array(findings, m)
    elif summary_usable and (primary_summary or adversarial_summary):
      _aggregate_summary_arrays(rc, m)
    else:
      _aggregate_top_level_with_user_decisions(rc, m)

  # ratio + adoption_rate + over_correction_ratio (47th 末改修: 系統横断統一定義)
  for t, m in per_treatment.items():
    total = m["detection_count"] or 1
    m["must_fix_ratio"] = m["must_fix_count"] / total
    m["should_fix_ratio"] = m["should_fix_count"] / total
    m["do_not_fix_ratio"] = m["do_not_fix_count"] / total
    m["adoption_rate"] = m["must_fix_ratio"] + m["should_fix_ratio"]
    m["over_correction_ratio"] = m["do_not_fix_ratio"]

  return {
    "version": VERSION,
    "session_count": len(review_cases),
    "treatments": sorted(treatments_seen),
    "rounds": sorted(rounds_seen),
    "commit_hash_variance": {
      "detected": len(hashes) > 1,
      "hashes": sorted(hashes),
    },
    "metrics": per_treatment,
  }


def main() -> int:
  parser = argparse.ArgumentParser(description="metric_extractor: JSONL log → 12 軸 metric")
  parser.add_argument("--input", required=True, type=Path)
  parser.add_argument("--output", required=True, type=Path)
  parser.add_argument("--dual-reviewer-root", required=False, type=Path)
  args = parser.parse_args()

  try:
    resolve_foundation_root(args.dual_reviewer_root)  # validate
  except (ValueError, FileNotFoundError) as e:
    print(f"foundation install location error: {e}", file=sys.stderr)
    return 1

  if not args.input.is_file():
    print(f"input JSONL not found: {args.input}", file=sys.stderr)
    return 1

  try:
    metrics = extract_metrics(args.input)
  except ValueError as e:
    print(f"JSON parse fail: {e}", file=sys.stderr)
    return 2
  except FileNotFoundError:
    return 1

  try:
    args.output.write_text(json.dumps(metrics, indent=2, ensure_ascii=False), encoding="utf-8")
  except OSError as e:
    print(f"output write fail: {e}", file=sys.stderr)
    return 4

  return 0


if __name__ == "__main__":
  sys.exit(main())
