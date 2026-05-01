# test_phase_b_judgment.py — TDD step 1 (Task 4.1、Req 6.1-6.5)

import json
import subprocess
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[3]
DOGFEEDING_DIR = REPO_ROOT / "scripts" / "dual_reviewer_dogfeeding"
JUDGE_PATH = DOGFEEDING_DIR / "phase_b_judgment.py"
PROTOTYPE_ROOT = REPO_ROOT / "scripts" / "dual_reviewer_prototype"


@pytest.fixture
def judge_module():
  sys.path.insert(0, str(DOGFEEDING_DIR))
  import phase_b_judgment
  yield phase_b_judgment
  sys.path.remove(str(DOGFEEDING_DIR))


def _make_jsonl(tmp_path, review_cases: list[dict], filename="dev_log.jsonl"):
  p = tmp_path / filename
  p.write_text("\n".join(json.dumps(rc) for rc in review_cases) + "\n")
  return p


def _make_finding(issue_id, source, severity="ERROR", label="must_fix", state="judged"):
  f = {
    "issue_id": issue_id, "source": source, "finding_text": f"{issue_id} text",
    "severity": severity, "state": state,
    "impact_score": {"severity": severity, "fix_cost": "low", "downstream_effect": "isolated"},
  }
  if state == "judged":
    f["necessity_judgment"] = {
      "source": "judgment_subagent", "requirement_link": "yes",
      "ignored_impact": "high", "fix_cost": "low", "scope_expansion": "no",
      "uncertainty": "low", "fix_decision": {"label": label}, "recommended_action": "fix_now",
    }
  return f


def _make_review_case(treatment, round_index, findings, hash_="h1"):
  return {
    "session_id": f"s-{treatment}-{round_index}",
    "phase": "design", "target_spec_id": "spec6",
    "timestamp_start": "2026-05-01T10:00:00Z", "timestamp_end": "2026-05-01T10:07:00Z",
    "treatment": treatment, "round_index": round_index,
    "design_md_commit_hash": hash_, "findings": findings,
  }


def _mock_metrics_with_severity(severity="CRITICAL"):
  return {
    "version": "1.0", "session_count": 30,
    "treatments": ["dual", "dual+judgment", "single"],
    "rounds": list(range(1, 11)),
    "commit_hash_variance": {"detected": False, "hashes": ["h1"]},
    "metrics": {
      "single": {"detection_count": 20, "must_fix_count": 5, "should_fix_count": 5,
                 "do_not_fix_count": 10, "must_fix_ratio": 0.25, "should_fix_ratio": 0.25,
                 "do_not_fix_ratio": 0.50, "adoption_rate": 0.50,
                 "over_correction_ratio": 0.50, "wall_clock_seconds": 4200,
                 "judgment_override_count": 0, "override_reasons": [],
                 "fatal_patterns_hit": 0, "phase_1_isomorphism_hit": 0,
                 "adversarial_disagreement_count": 0,
                 "severity_distribution": {severity: 5}},
      "dual": {"detection_count": 25, "must_fix_count": 7, "should_fix_count": 8,
               "do_not_fix_count": 10, "must_fix_ratio": 0.28, "should_fix_ratio": 0.32,
               "do_not_fix_ratio": 0.40, "adoption_rate": 0.60,
               "over_correction_ratio": 0.40, "wall_clock_seconds": 8400,
               "judgment_override_count": 0, "override_reasons": [],
               "fatal_patterns_hit": 0, "phase_1_isomorphism_hit": 0,
               "adversarial_disagreement_count": 3,
               "severity_distribution": {severity: 7}},
      "dual+judgment": {"detection_count": 30, "must_fix_count": 12, "should_fix_count": 8,
                        "do_not_fix_count": 10, "must_fix_ratio": 0.40,
                        "should_fix_ratio": 0.27, "do_not_fix_ratio": 0.33,
                        "adoption_rate": 0.67, "over_correction_ratio": 0.33,
                        "wall_clock_seconds": 12600, "judgment_override_count": 4,
                        "override_reasons": ["AC linkage"],
                        "fatal_patterns_hit": 0, "phase_1_isomorphism_hit": 0,
                        "adversarial_disagreement_count": 5,
                        "severity_distribution": {severity: 12}},
    },
  }


# ---------- 5 条件評価 ----------

def test_evaluate_5_conditions_all_pass_returns_go(judge_module, tmp_path):
  metrics = _mock_metrics_with_severity("CRITICAL")
  metrics_path = tmp_path / "metrics.json"
  metrics_path.write_text(json.dumps(metrics))

  # JSONL with 完全独立 adversarial finding 1 + Spec 6 fatal 1
  rcs = [
    _make_review_case("dual+judgment", 1, [
      _make_finding("P-1", "primary", severity="CRITICAL", label="must_fix"),
      _make_finding("A-INDEPENDENT-1", "adversarial", severity="CRITICAL", label="must_fix"),
    ]),
  ]
  jsonl = _make_jsonl(tmp_path, rcs)
  result = judge_module.evaluate_5_conditions(metrics, jsonl, spec3_fatal_count=1)
  assert result["a_fatal"] is True   # 1+1=2
  assert result["b_disagreement"] is True  # adversarial_disagreement >=3 in mock metrics
  assert result["c_bias_counter_evidence"] is True
  assert result["d_severity"] is True
  assert result["e_over_correction_improved"] is True
  assert result["decision"] == "go"


def test_evaluate_5_conditions_one_fail_returns_hold(judge_module, tmp_path):
  metrics = _mock_metrics_with_severity("CRITICAL")
  metrics["metrics"]["dual+judgment"]["over_correction_ratio"] = 0.50  # condition e fail
  metrics["metrics"]["dual"]["over_correction_ratio"] = 0.30           # dual better than dj
  metrics_path = tmp_path / "metrics.json"
  metrics_path.write_text(json.dumps(metrics))
  rcs = [_make_review_case("dual+judgment", 1, [
    _make_finding("P-1", "primary", severity="CRITICAL", label="must_fix"),
    _make_finding("A-INDEPENDENT-1", "adversarial", severity="CRITICAL", label="must_fix"),
  ])]
  jsonl = _make_jsonl(tmp_path, rcs)
  result = judge_module.evaluate_5_conditions(metrics, jsonl, spec3_fatal_count=1)
  assert result["e_over_correction_improved"] is False
  assert result["decision"] == "hold"


# ---------- condition (c) 機械評価 4 cases ----------

def test_condition_c_case1_full_independent_adversarial_count_up(judge_module, tmp_path):
  """case 1: adversarial finding が完全独立発見 (= primary 未検出 issue、new issue_id)"""
  rcs = [_make_review_case("dual+judgment", 1, [
    _make_finding("P-1", "primary"),
    _make_finding("A-INDEPENDENT-1", "adversarial"),  # primary issue_id に存在せず
  ])]
  jsonl = _make_jsonl(tmp_path, rcs)
  result = judge_module.evaluate_condition_c(jsonl)
  assert result["bool"] is True
  assert "A-INDEPENDENT-1" in [r["issue_id"] for r in result["evidence_references"]]


def test_condition_c_case2_counter_evidence_no_count_up(judge_module, tmp_path):
  """case 2: adversarial finding が counter_evidence (= primary issue_id 流用)"""
  rcs = [_make_review_case("dual+judgment", 1, [
    _make_finding("P-1", "primary"),
    _make_finding("P-1", "adversarial"),  # primary issue_id 流用 = counter_evidence
  ])]
  jsonl = _make_jsonl(tmp_path, rcs)
  result = judge_module.evaluate_condition_c(jsonl)
  # case 2 単独だと bool false
  assert result["bool"] is False


def test_condition_c_case3_all_counter_evidence_returns_false(judge_module, tmp_path):
  rcs = [
    _make_review_case("dual+judgment", 1, [
      _make_finding("P-1", "primary"),
      _make_finding("P-1", "adversarial"),
    ]),
    _make_review_case("dual+judgment", 2, [
      _make_finding("P-2", "primary"),
      _make_finding("P-2", "adversarial"),
    ]),
  ]
  jsonl = _make_jsonl(tmp_path, rcs)
  result = judge_module.evaluate_condition_c(jsonl)
  assert result["bool"] is False


def test_condition_c_case4_one_independent_returns_true(judge_module, tmp_path):
  rcs = [
    _make_review_case("dual+judgment", 1, [
      _make_finding("P-1", "primary"),
      _make_finding("P-1", "adversarial"),  # case 2
    ]),
    _make_review_case("dual+judgment", 2, [
      _make_finding("P-2", "primary"),
      _make_finding("A-NEW", "adversarial"),  # case 1
    ]),
  ]
  jsonl = _make_jsonl(tmp_path, rcs)
  result = judge_module.evaluate_condition_c(jsonl)
  assert result["bool"] is True
  assert "A-NEW" in [r["issue_id"] for r in result["evidence_references"]]


# ---------- comparison-report append idempotent ----------

def test_append_to_report_creates_section_when_absent(judge_module, tmp_path):
  report = tmp_path / "comparison-report.md"
  report.write_text("# comparison-report\n\n## §1 head\n\nbody.\n")
  judge_module.append_judgment_to_report(report, judgment_record={"decision": "go", "evidence_references": []})
  text = report.read_text()
  assert "<!-- section-id: phase-b-fork-judgment-v1 -->" in text
  assert "Phase B fork" in text


def test_append_to_report_idempotent_on_existing_section(judge_module, tmp_path):
  report = tmp_path / "comparison-report.md"
  initial = "# comparison-report\n\n## §12 Phase B fork\n<!-- section-id: phase-b-fork-judgment-v1 -->\nexisting body.\n"
  report.write_text(initial)
  judge_module.append_judgment_to_report(report, judgment_record={"decision": "go", "evidence_references": []})
  # idempotent: 既存 detect で append skip
  assert report.read_text() == initial


# ---------- V4 仮説検証 + evidence_references ----------

def test_v4_hypotheses_field_in_judgment_record(judge_module, tmp_path):
  metrics = _mock_metrics_with_severity("CRITICAL")
  metrics_path = tmp_path / "metrics.json"
  metrics_path.write_text(json.dumps(metrics))
  rcs = [_make_review_case("dual+judgment", 1, [
    _make_finding("P-1", "primary", severity="CRITICAL"),
    _make_finding("A-INDEPENDENT-1", "adversarial", severity="CRITICAL"),
  ])]
  jsonl = _make_jsonl(tmp_path, rcs)
  rec = judge_module.build_judgment_record(metrics, jsonl, spec3_fatal_count=1)
  assert "v4_hypotheses" in rec
  assert "h1_over_correction" in rec["v4_hypotheses"]
  assert "h3_adoption_rate" in rec["v4_hypotheses"]
  assert "h4_wall_clock" in rec["v4_hypotheses"]


def test_evidence_references_include_issue_ids(judge_module, tmp_path):
  metrics = _mock_metrics_with_severity("CRITICAL")
  rcs = [_make_review_case("dual+judgment", 5, [
    _make_finding("P-1", "primary", severity="CRITICAL"),
    _make_finding("A-INDEPENDENT-X", "adversarial", severity="CRITICAL"),
  ])]
  jsonl = _make_jsonl(tmp_path, rcs)
  rec = judge_module.build_judgment_record(metrics, jsonl, spec3_fatal_count=1)
  ids = [r["issue_id"] for r in rec["evidence_references"]]
  assert "A-INDEPENDENT-X" in ids


# ---------- CLI ----------

def test_cli_main_produces_stdout_judgment_record(tmp_path):
  metrics = _mock_metrics_with_severity("CRITICAL")
  metrics_path = tmp_path / "metrics.json"
  metrics_path.write_text(json.dumps(metrics))
  rcs = [_make_review_case("dual+judgment", 1, [
    _make_finding("P-1", "primary", severity="CRITICAL"),
    _make_finding("A-INDEPENDENT-1", "adversarial", severity="CRITICAL"),
  ])]
  jsonl = _make_jsonl(tmp_path, rcs)
  figure_dir = tmp_path / "fig"
  figure_dir.mkdir()
  report = tmp_path / "comparison-report.md"
  report.write_text("# comparison-report\n")
  result = subprocess.run(
    [sys.executable, str(JUDGE_PATH),
     "--metrics", str(metrics_path), "--figure-dir", str(figure_dir),
     "--report", str(report), "--jsonl", str(jsonl),
     "--dual-reviewer-root", str(PROTOTYPE_ROOT)],
    capture_output=True, text=True,
  )
  assert result.returncode == 0, result.stderr
  rec = json.loads(result.stdout)
  assert "decision" in rec
  assert "v4_hypotheses" in rec
