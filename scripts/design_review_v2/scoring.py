"""Phase 3 採点 + risk_level 判定 (Design Review v2)

Phase 2-A〜D の phase2_findings.yaml と Phase 2-E の drift_findings.yaml を統合し、
weighted composite score + risk_level (A/B/C/D) + human_review_required を判定して
review_report.yaml を生成する。

Usage:
    python scoring.py <dogfeeding_dir>
"""

from __future__ import annotations

import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import yaml


WEIGHTS = {
  "traceability": 0.30,
  "risk_pattern": 0.25,
  "structural": 0.20,
  "type": 0.15,
  "semantic": 0.10,
}


def compute_semantic_score(drift_findings: list[dict]) -> tuple[float, int, int]:
  """drift_findings から semantic_alignment_score を計算する."""
  total_pairs = len(drift_findings)
  if total_pairs == 0:
    return 1.0, 0, 0
  drift_count = sum(1 for f in drift_findings if f.get("drift_kind") != "no_drift")
  score = 1 - (drift_count / total_pairs)
  return round(score, 4), drift_count, total_pairs


def compute_composite(scores: dict[str, float]) -> float:
  return round(sum(scores[k] * WEIGHTS[k] for k in WEIGHTS), 4)


def determine_risk_level(scores: dict[str, float], error_count: int, composite: float) -> str:
  if error_count == 0 and all(s >= 0.95 for s in scores.values()):
    return "A"
  if error_count >= 1 or scores["semantic"] < 0.8:
    return "D"
  if composite >= 0.85:
    return "B"
  return "C"


def determine_human_review(risk_level: str, drift_findings: list[dict]) -> bool:
  if risk_level == "A":
    # drift があれば A でも human review 必須
    if any(f.get("drift_kind") != "no_drift" for f in drift_findings):
      return True
    return False
  return True


def recommended_action(risk_level: str) -> str:
  return {
    "A": "approve as-is、人間判断不要",
    "B": "ERROR 0 件確認後 approve、WARN は読み流し可",
    "C": "ERROR / WARN を逐一精査、必要に応じて design 改版",
    "D": "人間判断必須、設計改版または requirements 改版を要検討",
  }[risk_level]


def main(dogfeeding_dir: str) -> None:
  base = Path(dogfeeding_dir)
  phase2_path = base / "phase2_findings.yaml"
  drift_path = base / "drift_findings.yaml"

  with open(phase2_path) as f:
    phase2 = yaml.safe_load(f)
  with open(drift_path) as f:
    drift = yaml.safe_load(f)

  pr = phase2["phase_results"]
  scores = {
    "structural": pr["phase_a"]["score"],
    "traceability": pr["phase_b"]["score"],
    "type": pr["phase_c"]["score"],
    "risk_pattern": pr["phase_d"]["score"],
  }

  drift_findings = drift.get("drift_findings", []) or []
  semantic_score, drift_count, total_pairs = compute_semantic_score(drift_findings)
  scores["semantic"] = semantic_score

  # findings 統合
  findings: list[dict] = []
  for phase_key, ph in [("A", "phase_a"), ("B", "phase_b"), ("C", "phase_c"), ("D", "phase_d")]:
    for f in pr[ph].get("findings") or []:
      findings.append({
        "phase": f["phase"],
        "check_id": f["check_id"],
        "severity": f["severity"],
        "location": f["location"],
        "detail": f["detail"],
      })
  for f in drift_findings:
    if f.get("drift_kind") == "no_drift":
      continue  # no_drift は findings 集計から除外
    findings.append({
      "phase": "E",
      "check_id": f.get("drift_kind", ""),
      "severity": f.get("severity", "INFO"),
      "location": f.get("pair_id", ""),
      "detail": f.get("explanation", ""),
    })

  error_count = sum(1 for f in findings if f["severity"] == "ERROR")
  warn_count = sum(1 for f in findings if f["severity"] == "WARN")
  info_count = sum(1 for f in findings if f["severity"] == "INFO")

  composite = compute_composite(scores)
  risk_level = determine_risk_level(scores, error_count, composite)
  human_review = determine_human_review(risk_level, drift_findings)

  report = {
    "feature_name": phase2.get("feature_name"),
    "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    "scores": {
      "structural_score": scores["structural"],
      "traceability_score": scores["traceability"],
      "type_score": scores["type"],
      "risk_pattern_score": scores["risk_pattern"],
      "semantic_alignment_score": scores["semantic"],
    },
    "weights": WEIGHTS,
    "composite_score": composite,
    "risk_level": risk_level,
    "human_review_required": human_review,
    "summary": {
      "total_findings": len(findings),
      "errors": error_count,
      "warnings": warn_count,
      "info": info_count,
      "drift_pairs_checked": total_pairs,
      "drift_count": drift_count,
    },
    "recommended_action": recommended_action(risk_level),
    "findings": findings,
  }

  out_path = base / "review_report.yaml"
  with open(out_path, "w") as f:
    yaml.safe_dump(report, f, allow_unicode=True, sort_keys=False)

  # human-readable summary
  print(f"=== Design Review v2 Final Report ({report['feature_name']}) ===\n")
  print("Scores:")
  for k, v in report["scores"].items():
    print(f"  {k}: {v:.4f}")
  print(f"\ncomposite_score: {composite:.4f}")
  print(f"risk_level: {risk_level}")
  print(f"human_review_required: {human_review}")
  print(f"\nSummary: total={len(findings)} ERROR={error_count} WARN={warn_count} INFO={info_count}")
  print(f"Drift pairs: {drift_count}/{total_pairs} drift")
  print(f"\nRecommended action: {recommended_action(risk_level)}")
  print(f"\nreport written to: {out_path}")


if __name__ == "__main__":
  if len(sys.argv) != 2:
    print("Usage: python scoring.py <dogfeeding_dir>", file=sys.stderr)
    sys.exit(2)
  main(sys.argv[1])
