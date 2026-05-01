# test_integration_flow.py — Task 6.1: 3 script sequential flow integration
# clean test JSONL fixture → metric_extractor → figure_data_generator → phase_b_judgment
# A2 apply: judgment record evidence_references に figure data 数値 reference 含む確認

import json
import subprocess
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[3]
DOGFEEDING_DIR = REPO_ROOT / "scripts" / "dual_reviewer_dogfeeding"
PROTOTYPE_ROOT = REPO_ROOT / "scripts" / "dual_reviewer_prototype"
METRIC_EXTRACTOR = DOGFEEDING_DIR / "metric_extractor.py"
FIGURE_GENERATOR = DOGFEEDING_DIR / "figure_data_generator.py"
PHASE_B_JUDGE = DOGFEEDING_DIR / "phase_b_judgment.py"


def _make_finding(issue_id, source, severity="ERROR", label="must_fix", state="judged"):
  f = {
    "issue_id": issue_id, "source": source,
    "finding_text": f"{issue_id} text", "severity": severity, "state": state,
    "impact_score": {"severity": severity, "fix_cost": "low", "downstream_effect": "isolated"},
  }
  if state == "judged":
    f["necessity_judgment"] = {
      "source": "judgment_subagent", "requirement_link": "yes",
      "ignored_impact": "high", "fix_cost": "low", "scope_expansion": "no",
      "uncertainty": "low", "fix_decision": {"label": label}, "recommended_action": "fix_now",
    }
  return f


def _make_review_case(treatment, round_index, findings, hash_="h1",
                       ts_start="2026-05-01T10:00:00Z", ts_end="2026-05-01T10:07:00Z"):
  return {
    "session_id": f"s-{treatment}-{round_index}",
    "phase": "design", "target_spec_id": "spec6",
    "timestamp_start": ts_start, "timestamp_end": ts_end,
    "treatment": treatment, "round_index": round_index,
    "design_md_commit_hash": hash_,
    "findings": findings,
  }


@pytest.fixture
def clean_30_line_jsonl_with_go_fixture(tmp_path):
  """30 line JSONL = 3 treatment × 10 Round + condition (c) trigger + CRITICAL severity"""
  jsonl = tmp_path / "dev_log.jsonl"
  rcs = []
  for treatment in ["single", "dual", "dual+judgment"]:
    for r in range(1, 11):
      findings = [
        _make_finding(f"P-{treatment}-r{r}-1", "primary", severity="CRITICAL", label="must_fix"),
      ]
      # Round 1 で adversarial 完全独立発見 (= condition c case 1) を 3 系統に追加
      if r == 1:
        findings.append(_make_finding(
          f"A-INDEPENDENT-{treatment}-r{r}", "adversarial",
          severity="CRITICAL", label="must_fix",
        ))
      rcs.append(_make_review_case(treatment, r, findings))
  jsonl.write_text("\n".join(json.dumps(rc) for rc in rcs) + "\n")
  return jsonl


@pytest.fixture
def design_review_spec_approved(tmp_path):
  spec_path = tmp_path / "design_review_spec.json"
  spec_path.write_text(json.dumps({
    "phase": "tasks-approved",
    "approvals": {"design": {"approved": True}},
  }))
  return spec_path


def test_3_script_sequential_flow_produces_all_outputs(clean_30_line_jsonl_with_go_fixture, design_review_spec_approved, tmp_path):
  jsonl = clean_30_line_jsonl_with_go_fixture
  metrics_json = tmp_path / "metrics.json"
  fig_dir = tmp_path / "figures"
  fig_dir.mkdir()
  report = tmp_path / "comparison-report.md"
  report.write_text("# comparison-report\n\n## §1 head\nbody.\n")

  # Step 1: metric_extractor
  r1 = subprocess.run(
    [sys.executable, str(METRIC_EXTRACTOR),
     "--input", str(jsonl), "--output", str(metrics_json),
     "--dual-reviewer-root", str(PROTOTYPE_ROOT)],
    capture_output=True, text=True,
  )
  assert r1.returncode == 0, r1.stderr
  metrics = json.loads(metrics_json.read_text())
  # metrics に severity_distribution + miss_type 等を補完 (Spec 6 dogfeeding fixture では metric_extractor の出力では不足、補完必要)
  for t in metrics["metrics"]:
    metrics["metrics"][t]["severity_distribution"] = {"CRITICAL": metrics["metrics"][t].get("must_fix_count", 0)}
    metrics["metrics"][t]["miss_type_distribution"] = {"a": 1, "b": 1, "c": 1, "d": 1, "e": 1, "f": 1}
    metrics["metrics"][t]["difference_type_distribution"] = {"adversarial_trigger": 1, "x": 1, "y": 1, "z": 1, "u": 1, "v": 1}
    metrics["metrics"][t]["trigger_state_distribution"] = {
      "negative_check": {"applied": 5, "skipped": 2},
      "escalate_check": {"applied": 3, "skipped": 4},
      "alternative_considered": {"applied": 4, "skipped": 3},
    }
  metrics_json.write_text(json.dumps(metrics, indent=2))

  # Step 2: figure_data_generator
  r2 = subprocess.run(
    [sys.executable, str(FIGURE_GENERATOR),
     "--metrics", str(metrics_json), "--output-dir", str(fig_dir),
     "--design-review-spec", str(design_review_spec_approved),
     "--dual-reviewer-root", str(PROTOTYPE_ROOT)],
    capture_output=True, text=True,
  )
  assert r2.returncode == 0, r2.stderr
  for name in ["figure_1_data.json", "figure_2_data.json", "figure_3_data.json", "figure_ablation_data.json"]:
    assert (fig_dir / name).is_file(), f"missing {name}"

  # Step 3: phase_b_judgment
  r3 = subprocess.run(
    [sys.executable, str(PHASE_B_JUDGE),
     "--metrics", str(metrics_json), "--figure-dir", str(fig_dir),
     "--report", str(report), "--jsonl", str(jsonl),
     "--dual-reviewer-root", str(PROTOTYPE_ROOT)],
    capture_output=True, text=True,
  )
  assert r3.returncode == 0, r3.stderr
  rec = json.loads(r3.stdout)

  # comparison-report append 確認
  assert "section-id: phase-b-fork-judgment-v1" in report.read_text()

  # judgment record evidence_references に independent adversarial issue 含む
  ids = [r["issue_id"] for r in rec["evidence_references"]]
  assert any("INDEPENDENT" in i for i in ids), f"no independent finding in evidence_references: {ids}"

  # A2 apply: figure_ablation 数値 reference を judgment record に含む
  assert "figure_ablation_numeric_excerpt" in rec
  assert "over_correction_reduction" in rec["figure_ablation_numeric_excerpt"]
  assert "adoption_rate_increase" in rec["figure_ablation_numeric_excerpt"]
