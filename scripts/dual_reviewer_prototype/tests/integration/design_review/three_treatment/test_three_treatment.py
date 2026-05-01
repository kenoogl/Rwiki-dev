# Task 7.5: 3 系統 (single/dual/dual+judgment) で同一 dr-log skill 動作 test
# 系統別 finding (state + source + counter_evidence 異なる) を順次 dr-log に投入、
# JSONL の各 entry が treatment field + correct state + correct source で記録されること

import json
import sys
from pathlib import Path

import pytest
import yaml

PROTOTYPE_ROOT = Path(__file__).resolve().parents[4]
SCHEMAS_DIR = PROTOTYPE_ROOT / "schemas"
DR_LOG_DIR = PROTOTYPE_ROOT / "skills" / "dr-log"
DR_DESIGN_DIR = PROTOTYPE_ROOT / "skills" / "dr-design"


@pytest.fixture
def log_writer_module():
  sys.path.insert(0, str(DR_LOG_DIR))
  import log_writer
  yield log_writer
  sys.path.remove(str(DR_LOG_DIR))


@pytest.fixture
def orchestrator_module():
  sys.path.insert(0, str(DR_DESIGN_DIR))
  import orchestrator
  yield orchestrator
  sys.path.remove(str(DR_DESIGN_DIR))


@pytest.fixture
def temp_target_project(tmp_path):
  dr_dir = tmp_path / ".dual-reviewer"
  dr_dir.mkdir()
  config = dr_dir / "config.yaml"
  config.write_text(yaml.safe_dump({
    "primary_model": "opus", "adversarial_model": "sonnet",
    "judgment_model": "sonnet", "lang": "ja", "dev_log_path": "./dev_log.jsonl",
  }))
  log = dr_dir / "dev_log.jsonl"
  log.touch()
  return tmp_path, config, log


def _make_finding(treatment: str):
  """3 系統別 finding object を組立 (treatment 切替 + 2 層 source field 整合)."""
  base = {
    "issue_id": f"P-{treatment}",
    "source": "primary",  # 検出元 (3 系統共通)
    "finding_text": f"finding for {treatment} system",
    "severity": "ERROR",
    "state": "detected",
    "impact_score": {"severity": "ERROR", "fix_cost": "low", "downstream_effect": "isolated"},
  }
  if treatment == "single":
    return base
  elif treatment == "dual":
    base["adversarial_counter_evidence"] = "dual counter evidence"
    return base
  elif treatment == "dual+judgment":
    base["state"] = "judged"
    base["necessity_judgment"] = {
      "source": "judgment_subagent",
      "requirement_link": "yes", "ignored_impact": "high", "fix_cost": "low",
      "scope_expansion": "no", "uncertainty": "low",
      "fix_decision": {"label": "must_fix"}, "recommended_action": "fix_now",
    }
    base["adversarial_counter_evidence"] = "dual+judgment counter evidence"
    return base


def test_three_treatments_recorded_with_correct_treatment_field(log_writer_module, temp_target_project):
  _, config, log_path = temp_target_project
  w = log_writer_module.LogWriter(SCHEMAS_DIR)
  for t in ["single", "dual", "dual+judgment"]:
    sid = f"s-{t}"
    w.open(
      session_id=sid, treatment=t, round_index=1,
      design_md_commit_hash="x", target_spec_id="foundation",
      config_yaml_path=config,
    )
    w.append(sid, _make_finding(t))
    w.flush(sid)
  lines = log_path.read_text().strip().splitlines()
  assert len(lines) == 3  # 1 line per treatment
  treatments = [json.loads(l)["treatment"] for l in lines]
  assert sorted(treatments) == ["dual", "dual+judgment", "single"]


def test_single_treatment_state_detected_no_counter_evidence(log_writer_module, temp_target_project):
  _, config, log_path = temp_target_project
  w = log_writer_module.LogWriter(SCHEMAS_DIR)
  w.open(
    session_id="s-single", treatment="single", round_index=1,
    design_md_commit_hash="x", target_spec_id="foundation",
    config_yaml_path=config,
  )
  w.append("s-single", _make_finding("single"))
  w.flush("s-single")
  obj = json.loads(log_path.read_text().strip())
  assert obj["treatment"] == "single"
  assert obj["findings"][0]["state"] == "detected"
  assert "adversarial_counter_evidence" not in obj["findings"][0]


def test_dual_treatment_state_detected_with_counter_evidence(log_writer_module, temp_target_project):
  _, config, log_path = temp_target_project
  w = log_writer_module.LogWriter(SCHEMAS_DIR)
  w.open(
    session_id="s-dual", treatment="dual", round_index=1,
    design_md_commit_hash="x", target_spec_id="foundation",
    config_yaml_path=config,
  )
  w.append("s-dual", _make_finding("dual"))
  w.flush("s-dual")
  obj = json.loads(log_path.read_text().strip())
  assert obj["treatment"] == "dual"
  assert obj["findings"][0]["state"] == "detected"
  assert obj["findings"][0]["adversarial_counter_evidence"] == "dual counter evidence"


def test_dual_judgment_state_judged_with_judgment_subagent_source(log_writer_module, temp_target_project):
  _, config, log_path = temp_target_project
  w = log_writer_module.LogWriter(SCHEMAS_DIR)
  w.open(
    session_id="s-dj", treatment="dual+judgment", round_index=1,
    design_md_commit_hash="x", target_spec_id="foundation",
    config_yaml_path=config,
  )
  w.append("s-dj", _make_finding("dual+judgment"))
  w.flush("s-dj")
  obj = json.loads(log_path.read_text().strip())
  assert obj["treatment"] == "dual+judgment"
  assert obj["findings"][0]["state"] == "judged"
  assert obj["findings"][0]["necessity_judgment"]["source"] == "judgment_subagent"
  assert obj["findings"][0]["adversarial_counter_evidence"] == "dual+judgment counter evidence"


def test_treatment_step_skip_logic_aligns_with_dr_log_treatment(orchestrator_module):
  """orchestrator の treatment_step_skip_logic と dr-log の treatment field が同一 enum を共有"""
  for t in ["single", "dual", "dual+judgment"]:
    skip = orchestrator_module.treatment_step_skip_logic(t)
    assert isinstance(skip, dict)
    assert "step_b" in skip and "step_c" in skip
