"""phase_b_judgment.py — 5 条件評価 + V4 仮説検証 + go/hold 判定 + comparison-report append (Req 6.1-6.5).

5 条件 (dogfeeding spec Req 6.1):
- (a) 致命級発見 ≥ 2 件 (Spec 3 = 1 件 [外部固定] + Spec 6 fatal_patterns_hit or CRITICAL severity ≥ 1)
- (b) disagreement ≥ 3 件 (Spec 3 = 2 件 [外部固定] + Spec 6 adversarial_disagreement ≥ 1)
- (c) bias 共有反証 evidence (= adversarial 完全独立発見 ≥ 1 件、A1 + A2 fix 機械評価)
- (d) impact_score severity ∈ {CRITICAL, ERROR} ≥ 1 件
- (e) 過剰修正比率改善 (dual+judgment over_correction_ratio < dual)

V4 仮説 (V4 §4 整合):
- H1: 過剰修正比率 dual+judgment ≤ 20%
- H3: 採択率 dual+judgment ≥ 50%
- H4: wall-clock dual+judgment ≤ V3 baseline 420.7s + 50% per session

comparison-report.md §12 idempotent append (P5 fix): section-id `phase-b-fork-judgment-v1` HTML comment で既存 detect → append skip
"""

import argparse
import json
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
from helpers import resolve_foundation_root  # noqa: E402

V3_BASELINE_WALL_CLOCK_SECONDS = 420.7  # per review session (foundation V3 design 7th archive)
H4_THRESHOLD_PER_SESSION = V3_BASELINE_WALL_CLOCK_SECONDS * 1.5  # 631s
SECTION_ID = "phase-b-fork-judgment-v1"
SPEC3_FATAL_COUNT_DEFAULT = 1
SPEC3_DISAGREEMENT_COUNT_DEFAULT = 2


def _iter_review_cases(jsonl_path: Path):
  with Path(jsonl_path).open(encoding="utf-8") as f:
    for line in f:
      line = line.strip()
      if line:
        yield json.loads(line)


def evaluate_condition_c(jsonl_path: Path) -> dict[str, Any]:
  """condition (c): adversarial finding で primary 未検出 issue_id ≥ 1 件 (= 完全独立発見 case 1).

  case 1 (count up): adversarial finding の issue_id が同 review_case 内 primary issue_id list に存在しない
  case 2 (no count): adversarial finding の issue_id が primary issue_id 流用 (counter_evidence)

  A1 + A2 fix integrated.
  """
  evidence_references: list[dict] = []
  for rc in _iter_review_cases(jsonl_path):
    primary_ids = {f["issue_id"] for f in rc.get("findings", []) if f.get("source") == "primary"}
    for f in rc.get("findings", []):
      if f.get("source") == "adversarial" and f["issue_id"] not in primary_ids:
        evidence_references.append({
          "issue_id": f["issue_id"],
          "treatment": rc.get("treatment"),
          "round_index": rc.get("round_index"),
        })
  return {
    "bool": len(evidence_references) >= 1,
    "evidence_references": evidence_references,
  }


def evaluate_5_conditions(metrics: dict, jsonl_path: Path,
                           spec3_fatal_count: int = SPEC3_FATAL_COUNT_DEFAULT,
                           spec3_disagreement_count: int = SPEC3_DISAGREEMENT_COUNT_DEFAULT) -> dict[str, Any]:
  """5 条件評価 + go/hold 判定."""
  per = metrics["metrics"]
  dj = per.get("dual+judgment", {})
  dual = per.get("dual", {})

  # (a) 致命級発見 ≥ 2 件
  spec6_fatal = dj.get("fatal_patterns_hit", 0)
  for sev_dist in [m.get("severity_distribution", {}) for m in per.values()]:
    spec6_fatal += sev_dist.get("CRITICAL", 0)
  a_fatal = (spec3_fatal_count + spec6_fatal) >= 2

  # (b) disagreement ≥ 3 件
  spec6_disagreement = sum(m.get("adversarial_disagreement_count", 0) for m in per.values())
  b_disagreement = (spec3_disagreement_count + spec6_disagreement) >= 3

  # (c) bias 共有反証 evidence
  c_result = evaluate_condition_c(jsonl_path)

  # (d) severity CRITICAL or ERROR ≥ 1 件
  d_severity_count = 0
  for m in per.values():
    sd = m.get("severity_distribution", {})
    d_severity_count += sd.get("CRITICAL", 0) + sd.get("ERROR", 0)
  d_severity = d_severity_count >= 1

  # (e) 過剰修正比率改善 (dj < dual)
  e_over_correction_improved = dj.get("over_correction_ratio", 1.0) < dual.get("over_correction_ratio", 0.0)

  all_pass = all([a_fatal, b_disagreement, c_result["bool"], d_severity, e_over_correction_improved])

  return {
    "a_fatal": a_fatal,
    "b_disagreement": b_disagreement,
    "c_bias_counter_evidence": c_result["bool"],
    "d_severity": d_severity,
    "e_over_correction_improved": e_over_correction_improved,
    "decision": "go" if all_pass else "hold",
    "evidence_references": c_result["evidence_references"],
  }


def evaluate_v4_hypotheses(metrics: dict) -> dict[str, Any]:
  """V4 仮説 H1 / H3 / H4 評価."""
  dj = metrics["metrics"].get("dual+judgment", {})
  session_count_dj = sum(1 for _ in metrics.get("rounds", [])) or 10  # default 10 rounds for dj
  wall_per_session = dj.get("wall_clock_seconds", 0) / max(1, session_count_dj)
  return {
    "h1_over_correction": {
      "value": dj.get("over_correction_ratio", 0),
      "threshold": 0.20,
      "achieved": dj.get("over_correction_ratio", 1) <= 0.20,
    },
    "h3_adoption_rate": {
      "value": dj.get("adoption_rate", 0),
      "threshold": 0.50,
      "achieved": dj.get("adoption_rate", 0) >= 0.50,
    },
    "h4_wall_clock": {
      "value_per_session": wall_per_session,
      "threshold_per_session": H4_THRESHOLD_PER_SESSION,
      "v3_baseline_per_session": V3_BASELINE_WALL_CLOCK_SECONDS,
      "achieved": wall_per_session <= H4_THRESHOLD_PER_SESSION,
    },
  }


def build_judgment_record(metrics: dict, jsonl_path: Path,
                           spec3_fatal_count: int = SPEC3_FATAL_COUNT_DEFAULT,
                           figure_dir: Path | None = None) -> dict[str, Any]:
  """全 evaluation を集約した judgment record (stdout JSON、Req 6.5 client-verifiable)."""
  conditions = evaluate_5_conditions(metrics, jsonl_path, spec3_fatal_count=spec3_fatal_count)
  hypotheses = evaluate_v4_hypotheses(metrics)
  rec = {
    "decision": conditions["decision"],
    "conditions": {
      "a_fatal": conditions["a_fatal"],
      "b_disagreement": conditions["b_disagreement"],
      "c_bias_counter_evidence": conditions["c_bias_counter_evidence"],
      "d_severity": conditions["d_severity"],
      "e_over_correction_improved": conditions["e_over_correction_improved"],
    },
    "evidence_references": conditions["evidence_references"],
    "v4_hypotheses": hypotheses,
  }
  if figure_dir is not None:
    figure_dir = Path(figure_dir)
    figure_files = sorted(p.name for p in figure_dir.glob("figure_*.json"))
    rec["figure_data_references"] = figure_files
    # A2 apply: numeric reference (figure ablation 内 over_correction_reduction を引用)
    abl_path = figure_dir / "figure_ablation_data.json"
    if abl_path.is_file():
      abl = json.loads(abl_path.read_text(encoding="utf-8"))
      rec["figure_ablation_numeric_excerpt"] = {
        "over_correction_reduction": abl.get("data", {}).get("over_correction_reduction"),
        "adoption_rate_increase": abl.get("data", {}).get("adoption_rate_increase"),
      }
  return rec


def append_judgment_to_report(report_path: Path, judgment_record: dict) -> str:
  """comparison-report.md §12 append (idempotent、P5 fix).

  Returns: "appended" | "skipped"
  """
  report_path = Path(report_path)
  text = report_path.read_text(encoding="utf-8") if report_path.is_file() else ""
  if f"section-id: {SECTION_ID}" in text:
    print("warning: section-id already exists、append skip", file=sys.stderr)
    return "skipped"
  appendix = (
    f"\n## §12 Phase B fork judgment\n"
    f"<!-- section-id: {SECTION_ID} -->\n\n"
    f"- decision: {judgment_record.get('decision')}\n"
    f"- conditions: {json.dumps(judgment_record.get('conditions', {}), ensure_ascii=False)}\n"
    f"- evidence_references count: {len(judgment_record.get('evidence_references', []))}\n"
    f"- v4_hypotheses: {json.dumps(judgment_record.get('v4_hypotheses', {}), ensure_ascii=False)}\n"
  )
  with report_path.open("a", encoding="utf-8") as f:
    f.write(appendix)
  return "appended"


def main() -> int:
  parser = argparse.ArgumentParser(description="phase_b_judgment: 5 条件評価 + go/hold + V4 仮説 + comparison-report append")
  parser.add_argument("--metrics", required=True, type=Path)
  parser.add_argument("--figure-dir", required=True, type=Path)
  parser.add_argument("--report", required=True, type=Path)
  parser.add_argument("--jsonl", required=True, type=Path)
  parser.add_argument("--dual-reviewer-root", required=False, type=Path)
  args = parser.parse_args()

  try:
    resolve_foundation_root(args.dual_reviewer_root)
  except (ValueError, FileNotFoundError) as e:
    print(f"foundation install location error: {e}", file=sys.stderr)
    return 1

  if not args.metrics.is_file() or not args.jsonl.is_file():
    print("input not found", file=sys.stderr)
    return 1

  metrics = json.loads(args.metrics.read_text(encoding="utf-8"))
  rec = build_judgment_record(metrics, args.jsonl, figure_dir=args.figure_dir)
  print(json.dumps(rec, indent=2, ensure_ascii=False))

  try:
    append_judgment_to_report(args.report, rec)
  except OSError as e:
    print(f"report append fail: {e}", file=sys.stderr)
    return 2

  return 0


if __name__ == "__main__":
  sys.exit(main())
