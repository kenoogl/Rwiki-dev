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


def _aggregate_findings_array(findings: list[dict], m: dict[str, Any]) -> None:
  """Path A: dual+judgment 系統 = `findings[]` array path (= necessity_judgment.fix_decision.label 集計)."""
  for f in findings:
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


def _aggregate_summary_arrays(rc: dict, m: dict[str, Any]) -> None:
  """Path B: single / dual 系統 = summary array path (judgment skip 系で findings[] 不在).

  detection_count = primary_findings_summary + adversarial_findings_summary 件数
    (forced_divergence は count up しない、§12 整合 = total detect は P + A のみ)
  user_decision == "skip" → do_not_fix_count に集計 (judgment 系の do_not_fix label と意味的統一)
  user_decision != "skip" (= "fix_now" / "approved" 等) → must_fix_count に集計
  """
  primary = rc.get("primary_findings_summary", [])
  adversarial = rc.get("adversarial_findings_summary", [])
  for item in list(primary) + list(adversarial):
    m["detection_count"] += 1
    decision = item.get("user_decision", "")
    if decision == "skip":
      m["do_not_fix_count"] += 1
    else:
      m["must_fix_count"] += 1


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
    # schema 分岐: findings[] 存在で Path A、それ以外 (= summary array) で Path B
    findings = rc.get("findings")
    if findings:
      _aggregate_findings_array(findings, m)
    else:
      _aggregate_summary_arrays(rc, m)

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
