# test_figure_data_generator.py — TDD step 1 (Task 3.1、Req 5.1-5.6)

import json
import subprocess
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[3]
DOGFEEDING_DIR = REPO_ROOT / "scripts" / "dual_reviewer_dogfeeding"
GENERATOR_PATH = DOGFEEDING_DIR / "figure_data_generator.py"
PROTOTYPE_ROOT = REPO_ROOT / "scripts" / "dual_reviewer_prototype"


@pytest.fixture
def generator_module():
  sys.path.insert(0, str(DOGFEEDING_DIR))
  import figure_data_generator
  yield figure_data_generator
  sys.path.remove(str(DOGFEEDING_DIR))


@pytest.fixture
def mock_metrics_json(tmp_path):
  metrics_path = tmp_path / "dogfeeding_metrics.json"
  metrics = {
    "version": "1.0", "session_count": 30,
    "treatments": ["dual", "dual+judgment", "single"],
    "rounds": list(range(1, 11)),
    "commit_hash_variance": {"detected": False, "hashes": ["c1"]},
    "metrics": {
      t: {
        "detection_count": 20,
        "must_fix_count": 5, "should_fix_count": 5, "do_not_fix_count": 10,
        "must_fix_ratio": 0.25, "should_fix_ratio": 0.25, "do_not_fix_ratio": 0.50,
        "adoption_rate": 0.50, "over_correction_ratio": 0.50,
        "wall_clock_seconds": 4200,
        "judgment_override_count": 2, "override_reasons": [],
        "fatal_patterns_hit": 0, "phase_1_isomorphism_hit": 0,
        "adversarial_disagreement_count": 1,
        "miss_type_distribution": {"a": 1, "b": 2, "c": 3, "d": 4, "e": 5, "f": 6 - (5 if t == "single" else 0)},
        "difference_type_distribution": {"adversarial_trigger": 3 if t != "single" else 0,
                                         "x": 1, "y": 1, "z": 1, "u": 1, "v": 1},
        "trigger_state_distribution": {"negative_check": {"applied": 5, "skipped": 2},
                                       "escalate_check": {"applied": 3, "skipped": 4},
                                       "alternative_considered": {"applied": 4, "skipped": 3}},
      }
      for t in ["single", "dual", "dual+judgment"]
    },
  }
  metrics_path.write_text(json.dumps(metrics, indent=2))
  return metrics_path


@pytest.fixture
def design_review_spec_json(tmp_path):
  spec_path = tmp_path / "design_review_spec.json"
  spec_path.write_text(json.dumps({
    "phase": "tasks-approved",
    "approvals": {"design": {"approved": True}},
  }))
  return spec_path


@pytest.fixture
def design_review_spec_not_approved(tmp_path):
  spec_path = tmp_path / "design_review_spec_unapproved.json"
  spec_path.write_text(json.dumps({
    "phase": "design",
    "approvals": {"design": {"approved": False}},
  }))
  return spec_path


def test_module_exists(generator_module):
  assert hasattr(generator_module, "generate_figure_data")


def test_generate_4_files(generator_module, mock_metrics_json, design_review_spec_json, tmp_path):
  output_dir = tmp_path / "out"
  output_dir.mkdir()
  generator_module.generate_figure_data(
    metrics_path=mock_metrics_json,
    output_dir=output_dir,
    design_review_spec_path=design_review_spec_json,
  )
  for name in ["figure_1_data.json", "figure_2_data.json", "figure_3_data.json", "figure_ablation_data.json"]:
    assert (output_dir / name).is_file(), f"missing {name}"


def test_figure_2_skipped_when_design_review_not_approved(generator_module, mock_metrics_json, design_review_spec_not_approved, tmp_path):
  """figure 2 sequencing 制約: design-review approve = false → figure 2 skip + warning"""
  output_dir = tmp_path / "out"
  output_dir.mkdir()
  generator_module.generate_figure_data(
    metrics_path=mock_metrics_json,
    output_dir=output_dir,
    design_review_spec_path=design_review_spec_not_approved,
  )
  # figure 1, 3, ablation は生成、figure 2 は skip
  assert (output_dir / "figure_1_data.json").is_file()
  assert (output_dir / "figure_3_data.json").is_file()
  assert (output_dir / "figure_ablation_data.json").is_file()
  assert not (output_dir / "figure_2_data.json").is_file()


def test_figure_data_has_6_top_level_fields(generator_module, mock_metrics_json, design_review_spec_json, tmp_path):
  output_dir = tmp_path / "out"
  output_dir.mkdir()
  generator_module.generate_figure_data(mock_metrics_json, output_dir, design_review_spec_json)
  for name in ["figure_1_data.json", "figure_2_data.json", "figure_3_data.json", "figure_ablation_data.json"]:
    data = json.loads((output_dir / name).read_text())
    for key in ["version", "figure_id", "generated_at", "metric_source", "data", "metadata"]:
      assert key in data, f"{name} missing top-level field: {key}"


def test_figure_1_miss_type_distribution_per_treatment(generator_module, mock_metrics_json, design_review_spec_json, tmp_path):
  output_dir = tmp_path / "out"
  output_dir.mkdir()
  generator_module.generate_figure_data(mock_metrics_json, output_dir, design_review_spec_json)
  data = json.loads((output_dir / "figure_1_data.json").read_text())
  assert data["figure_id"] == "figure_1_miss_type_distribution"
  for t in ["single", "dual", "dual+judgment"]:
    assert t in data["data"]
    assert isinstance(data["data"][t], dict)


def test_figure_2_difference_type_with_forced_divergence_effect(generator_module, mock_metrics_json, design_review_spec_json, tmp_path):
  output_dir = tmp_path / "out"
  output_dir.mkdir()
  generator_module.generate_figure_data(mock_metrics_json, output_dir, design_review_spec_json)
  data = json.loads((output_dir / "figure_2_data.json").read_text())
  assert data["figure_id"] == "figure_2_difference_type_distribution"
  # forced_divergence 効果: dual / dual+judgment で adversarial_trigger 件数 record
  assert "forced_divergence_effect" in data["data"]


def test_figure_3_trigger_state_applied_skipped(generator_module, mock_metrics_json, design_review_spec_json, tmp_path):
  output_dir = tmp_path / "out"
  output_dir.mkdir()
  generator_module.generate_figure_data(mock_metrics_json, output_dir, design_review_spec_json)
  data = json.loads((output_dir / "figure_3_data.json").read_text())
  assert data["figure_id"] == "figure_3_trigger_state_distribution"
  for t in ["single", "dual", "dual+judgment"]:
    assert t in data["data"]


def test_figure_ablation_dual_vs_dual_judgment(generator_module, mock_metrics_json, design_review_spec_json, tmp_path):
  output_dir = tmp_path / "out"
  output_dir.mkdir()
  generator_module.generate_figure_data(mock_metrics_json, output_dir, design_review_spec_json)
  data = json.loads((output_dir / "figure_ablation_data.json").read_text())
  assert data["figure_id"] == "figure_ablation_judgment_effect"
  for key in ["over_correction_reduction", "adoption_rate_increase", "judgment_override_count"]:
    assert key in data["data"]


def test_cli_main_produces_4_files(tmp_path, mock_metrics_json, design_review_spec_json):
  output_dir = tmp_path / "out"
  output_dir.mkdir()
  result = subprocess.run(
    [sys.executable, str(GENERATOR_PATH),
     "--metrics", str(mock_metrics_json), "--output-dir", str(output_dir),
     "--design-review-spec", str(design_review_spec_json),
     "--dual-reviewer-root", str(PROTOTYPE_ROOT)],
    capture_output=True, text=True,
  )
  assert result.returncode == 0, result.stderr
  files = sorted(p.name for p in output_dir.glob("*.json"))
  assert files == ["figure_1_data.json", "figure_2_data.json", "figure_3_data.json", "figure_ablation_data.json"]


# ---------- 改修 2: 3 系統 ablation 拡張 (47th 末 §12 整合) ----------


@pytest.fixture
def mock_metrics_3_treatments_ablation(tmp_path):
  """3 系統別の異なる over_correction_ratio + adoption_rate (= ablation diff 計算用)."""
  metrics_path = tmp_path / "dogfeeding_metrics_ablation.json"
  metrics = {
    "version": "1.0", "session_count": 30,
    "treatments": ["dual", "dual+judgment", "single"],
    "rounds": list(range(1, 11)),
    "commit_hash_variance": {"detected": False, "hashes": ["c1"]},
    "metrics": {
      "single": {
        "detection_count": 46, "must_fix_count": 17, "should_fix_count": 0, "do_not_fix_count": 29,
        "must_fix_ratio": 17/46, "should_fix_ratio": 0, "do_not_fix_ratio": 29/46,
        "adoption_rate": 17/46, "over_correction_ratio": 29/46,  # 63.0%
        "wall_clock_seconds": 4200,
        "judgment_override_count": 0, "override_reasons": [],
        "fatal_patterns_hit": 1, "phase_1_isomorphism_hit": 0,
        "adversarial_disagreement_count": 0,
        "primary_findings_count": 46, "adversarial_findings_count": 0,
        "forced_divergence_findings_count": 0,
      },
      "dual": {
        "detection_count": 60, "must_fix_count": 47, "should_fix_count": 0, "do_not_fix_count": 13,
        "must_fix_ratio": 47/60, "should_fix_ratio": 0, "do_not_fix_ratio": 13/60,
        "adoption_rate": 47/60, "over_correction_ratio": 13/60,  # 21.7%
        "wall_clock_seconds": 8400,
        "judgment_override_count": 0, "override_reasons": [],
        "fatal_patterns_hit": 0, "phase_1_isomorphism_hit": 0,
        "adversarial_disagreement_count": 14,
        "primary_findings_count": 29, "adversarial_findings_count": 31,
        "forced_divergence_findings_count": 14,
      },
      "dual+judgment": {
        "detection_count": 69, "must_fix_count": 7, "should_fix_count": 8, "do_not_fix_count": 23,
        "must_fix_ratio": 7/20, "should_fix_ratio": 8/20, "do_not_fix_ratio": 23/69,
        "adoption_rate": 15/20, "over_correction_ratio": 23/69,  # 33.3%
        "wall_clock_seconds": 12600,
        "judgment_override_count": 4, "override_reasons": ["override 1", "override 2"],
        "fatal_patterns_hit": 5, "phase_1_isomorphism_hit": 0,
        "adversarial_disagreement_count": 5,
        "primary_findings_count": 48, "adversarial_findings_count": 21,
        "forced_divergence_findings_count": 0,
      },
    },
  }
  metrics_path.write_text(json.dumps(metrics, indent=2))
  return metrics_path


def test_figure_ablation_includes_all_3_treatments(generator_module, mock_metrics_3_treatments_ablation,
                                                     design_review_spec_json, tmp_path):
  """改修 2: figure_ablation_data に 3 系統 over_correction_ratio + adoption_rate 全件含む."""
  output_dir = tmp_path / "out"
  output_dir.mkdir()
  generator_module.generate_figure_data(mock_metrics_3_treatments_ablation, output_dir, design_review_spec_json)
  data = json.loads((output_dir / "figure_ablation_data.json").read_text())
  assert "over_correction_ratio_per_treatment" in data["data"]
  for t in ["single", "dual", "dual+judgment"]:
    assert t in data["data"]["over_correction_ratio_per_treatment"]
  assert "adoption_rate_per_treatment" in data["data"]
  for t in ["single", "dual", "dual+judgment"]:
    assert t in data["data"]["adoption_rate_per_treatment"]


def test_figure_ablation_diff_single_to_dual_and_dual_to_dual_judgment(generator_module,
                                                                         mock_metrics_3_treatments_ablation,
                                                                         design_review_spec_json, tmp_path):
  """改修 2: ablation diff = single→dual + dual→dual+judgment 両方を data に記録 (§12.2 + §12.3 整合)."""
  output_dir = tmp_path / "out"
  output_dir.mkdir()
  generator_module.generate_figure_data(mock_metrics_3_treatments_ablation, output_dir, design_review_spec_json)
  data = json.loads((output_dir / "figure_ablation_data.json").read_text())["data"]
  # single (63.0%) → dual (21.7%) = -41.3pt
  assert "single_to_dual_over_correction_diff" in data
  assert abs(data["single_to_dual_over_correction_diff"] - (13/60 - 29/46)) < 0.01
  # dual (21.7%) → dual+judgment (33.3%) = +11.6pt
  assert "dual_to_dual_judgment_over_correction_diff" in data
  assert abs(data["dual_to_dual_judgment_over_correction_diff"] - (23/69 - 13/60)) < 0.01


def test_figure_ablation_preserves_legacy_dual_vs_dual_judgment_fields(generator_module,
                                                                        mock_metrics_3_treatments_ablation,
                                                                        design_review_spec_json, tmp_path):
  """改修 2 後方互換: 既存 over_correction_reduction / adoption_rate_increase / judgment_override_count 維持."""
  output_dir = tmp_path / "out"
  output_dir.mkdir()
  generator_module.generate_figure_data(mock_metrics_3_treatments_ablation, output_dir, design_review_spec_json)
  data = json.loads((output_dir / "figure_ablation_data.json").read_text())["data"]
  for key in ["over_correction_reduction", "adoption_rate_increase", "judgment_override_count"]:
    assert key in data
