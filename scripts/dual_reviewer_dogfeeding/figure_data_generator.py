"""figure_data_generator.py — metric → 4 figure data file 生成 (Req 5.1-5.6).

Output: 4 file (figure_1_data.json + figure_2_data.json + figure_3_data.json + figure_ablation_data.json)
6 top-level field per file (P4 fix): version + figure_id + generated_at + metric_source + data + metadata

figure 2 sequencing 制約 (Req 5.2): design-review/spec.json approvals.design.approved=false → figure 2 skip + warning
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
from helpers import resolve_foundation_root  # noqa: E402

VERSION = "1.0"


def _now_iso() -> str:
  return datetime.now(timezone.utc).isoformat()


def _envelope(figure_id: str, metric_source: Path, data: dict, metadata: dict | None = None) -> dict[str, Any]:
  return {
    "version": VERSION,
    "figure_id": figure_id,
    "generated_at": _now_iso(),
    "metric_source": str(metric_source),
    "data": data,
    "metadata": metadata or {},
  }


def _build_figure_1(metrics: dict) -> dict:
  """miss_type 6 enum 分布 × 3 系統 (Req 5.1)."""
  per_treatment = {}
  for t, m in metrics["metrics"].items():
    per_treatment[t] = m.get("miss_type_distribution", {})
  return {"miss_type_per_treatment": per_treatment, **per_treatment_helper(per_treatment)}


def per_treatment_helper(per_treatment: dict) -> dict:
  """Test convenience: also surface treatments at top level."""
  return per_treatment


def _build_figure_2(metrics: dict) -> dict:
  """difference_type 6 enum × 3 系統 + forced_divergence 効果 (Req 5.2)."""
  per_treatment = {}
  forced_divergence_effect = {}
  for t, m in metrics["metrics"].items():
    dist = m.get("difference_type_distribution", {})
    per_treatment[t] = dist
    forced_divergence_effect[t] = dist.get("adversarial_trigger", 0)
  result = {"difference_type_per_treatment": per_treatment, "forced_divergence_effect": forced_divergence_effect}
  for t, d in per_treatment.items():
    result[t] = d
  return result


def _build_figure_3(metrics: dict) -> dict:
  """trigger_state 3 field 発動率 × 3 系統 (Req 5.3)."""
  per_treatment = {}
  for t, m in metrics["metrics"].items():
    per_treatment[t] = m.get("trigger_state_distribution", {})
  return per_treatment


def _build_figure_ablation(metrics: dict) -> dict:
  """dual vs dual+judgment 過剰修正比率削減 + 採択率増加 + judgment override + 必要性判定 quality (Req 5.4、V4 §4.4 整合)."""
  dual = metrics["metrics"].get("dual", {})
  dual_judgment = metrics["metrics"].get("dual+judgment", {})
  return {
    "over_correction_reduction": dual.get("over_correction_ratio", 0) - dual_judgment.get("over_correction_ratio", 0),
    "adoption_rate_increase": dual_judgment.get("adoption_rate", 0) - dual.get("adoption_rate", 0),
    "judgment_override_count": dual_judgment.get("judgment_override_count", 0),
    "override_reasons": dual_judgment.get("override_reasons", []),
  }


def generate_figure_data(metrics_path: Path, output_dir: Path, design_review_spec_path: Path) -> list[Path]:
  """metric input → 4 figure data file 生成 (figure 2 は design-review approve 後のみ)."""
  metrics_path = Path(metrics_path)
  output_dir = Path(output_dir)
  output_dir.mkdir(parents=True, exist_ok=True)

  metrics = json.loads(metrics_path.read_text(encoding="utf-8"))
  spec = json.loads(Path(design_review_spec_path).read_text(encoding="utf-8"))
  design_approved = spec.get("approvals", {}).get("design", {}).get("approved", False)

  generated: list[Path] = []

  fig1 = _envelope("figure_1_miss_type_distribution", metrics_path, _build_figure_1(metrics))
  (output_dir / "figure_1_data.json").write_text(json.dumps(fig1, indent=2, ensure_ascii=False))
  generated.append(output_dir / "figure_1_data.json")

  if design_approved:
    fig2 = _envelope("figure_2_difference_type_distribution", metrics_path, _build_figure_2(metrics))
    (output_dir / "figure_2_data.json").write_text(json.dumps(fig2, indent=2, ensure_ascii=False))
    generated.append(output_dir / "figure_2_data.json")
  else:
    print("warning: design-review approve 未完、figure 2 skip", file=sys.stderr)

  fig3 = _envelope("figure_3_trigger_state_distribution", metrics_path, _build_figure_3(metrics))
  (output_dir / "figure_3_data.json").write_text(json.dumps(fig3, indent=2, ensure_ascii=False))
  generated.append(output_dir / "figure_3_data.json")

  fig_ablation = _envelope("figure_ablation_judgment_effect", metrics_path, _build_figure_ablation(metrics))
  (output_dir / "figure_ablation_data.json").write_text(json.dumps(fig_ablation, indent=2, ensure_ascii=False))
  generated.append(output_dir / "figure_ablation_data.json")

  return generated


def main() -> int:
  parser = argparse.ArgumentParser(description="figure_data_generator: metric → 4 figure data file")
  parser.add_argument("--metrics", required=True, type=Path)
  parser.add_argument("--output-dir", required=True, type=Path)
  parser.add_argument("--design-review-spec", required=True, type=Path)
  parser.add_argument("--dual-reviewer-root", required=False, type=Path)
  args = parser.parse_args()

  try:
    resolve_foundation_root(args.dual_reviewer_root)
  except (ValueError, FileNotFoundError) as e:
    print(f"foundation install location error: {e}", file=sys.stderr)
    return 1

  if not args.metrics.is_file():
    print(f"metrics not found: {args.metrics}", file=sys.stderr)
    return 1

  try:
    generate_figure_data(args.metrics, args.output_dir, args.design_review_spec)
  except OSError as e:
    print(f"output write fail: {e}", file=sys.stderr)
    return 2

  return 0


if __name__ == "__main__":
  sys.exit(main())
