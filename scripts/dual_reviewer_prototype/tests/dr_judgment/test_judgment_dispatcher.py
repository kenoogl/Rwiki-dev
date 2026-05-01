# test_judgment_dispatcher.py — dr-judgment skill helper script unit tests
# Task 6.6 (TDD red 先 → Task 3.2 impl で green)

import json
import subprocess
import sys
from pathlib import Path

import pytest
import yaml

PROTOTYPE_ROOT = Path(__file__).resolve().parents[2]
PROMPTS_DIR = PROTOTYPE_ROOT / "prompts"
SCHEMAS_DIR = PROTOTYPE_ROOT / "schemas"
DR_JUDGMENT_DIR = PROTOTYPE_ROOT / "skills" / "dr-judgment"
DISPATCHER_PATH = DR_JUDGMENT_DIR / "judgment_dispatcher.py"


@pytest.fixture
def dispatcher_module():
  """import judgment_dispatcher as module (Task 3.2 impl 後 import 成功)."""
  sys.path.insert(0, str(DR_JUDGMENT_DIR))
  import judgment_dispatcher
  yield judgment_dispatcher
  sys.path.remove(str(DR_JUDGMENT_DIR))


def test_load_judgment_prompt_returns_v4_5_2_content(dispatcher_module):
  prompt = dispatcher_module.load_judgment_prompt(PROTOTYPE_ROOT)
  assert "judgment-only subagent" in prompt
  assert "V4 review protocol" in prompt
  assert "5 judgment rules in order" in prompt
  assert "uncertainty=high" in prompt


def test_load_judgment_prompt_file_not_found_raises(dispatcher_module, tmp_path):
  with pytest.raises(FileNotFoundError):
    dispatcher_module.load_judgment_prompt(tmp_path)


def test_semi_mechanical_mapping_defaults_has_7_rules(dispatcher_module):
  defaults = dispatcher_module.SEMI_MECHANICAL_MAPPING_DEFAULTS
  assert isinstance(defaults, list)
  assert len(defaults) == 7
  conditions = [d["condition"] for d in defaults]
  assert any("AC linkage direct" in c for c in conditions)
  assert any("AC linkage indirect" in c for c in conditions)
  assert any("security/data_loss/sandbox_escape" in c for c in conditions)
  assert any("Otherwise" in c for c in conditions)


def test_assemble_payload_design_phase_includes_design_text(dispatcher_module):
  payload = dispatcher_module.assemble_payload(
    primary_findings=[{"issue_id": "P-1"}],
    adversarial_findings=[{"issue_id": "A-1"}],
    adversarial_counter_evidence=[{"issue_id": "A-1", "counter": "x"}],
    requirements_text="req text",
    design_text="design text",
  )
  assert payload["primary_findings"] == [{"issue_id": "P-1"}]
  assert payload["adversarial_findings"] == [{"issue_id": "A-1"}]
  assert payload["adversarial_counter_evidence"] == [{"issue_id": "A-1", "counter": "x"}]
  assert payload["requirements_text"] == "req text"
  assert payload["design_text"] == "design text"
  assert len(payload["semi_mechanical_mapping_defaults"]) == 7


def test_assemble_payload_req_phase_omits_design_text(dispatcher_module):
  payload = dispatcher_module.assemble_payload(
    primary_findings=[],
    adversarial_findings=[],
    adversarial_counter_evidence=[],
    requirements_text="req text",
  )
  assert "design_text" not in payload
  assert payload["requirements_text"] == "req text"


def test_validate_judgment_output_valid_passes(dispatcher_module):
  yaml_str = yaml.safe_dump([{
    "source": "judgment_subagent",
    "requirement_link": "yes",
    "ignored_impact": "high",
    "fix_cost": "low",
    "scope_expansion": "no",
    "uncertainty": "low",
    "fix_decision": {"label": "must_fix"},
    "recommended_action": "fix_now",
  }])
  entries = dispatcher_module.validate_judgment_output(yaml_str, SCHEMAS_DIR)
  assert len(entries) == 1
  assert entries[0]["fix_decision"]["label"] == "must_fix"


def test_validate_judgment_output_invalid_label_raises(dispatcher_module):
  import jsonschema
  yaml_str = yaml.safe_dump([{
    "source": "judgment_subagent",
    "requirement_link": "yes",
    "ignored_impact": "high",
    "fix_cost": "low",
    "scope_expansion": "no",
    "uncertainty": "low",
    "fix_decision": {"label": "INVALID_LABEL"},
    "recommended_action": "fix_now",
  }])
  with pytest.raises(jsonschema.ValidationError):
    dispatcher_module.validate_judgment_output(yaml_str, SCHEMAS_DIR)


def test_validate_judgment_output_missing_required_field_raises(dispatcher_module):
  import jsonschema
  yaml_str = yaml.safe_dump([{
    "source": "judgment_subagent",
    "requirement_link": "yes",
    # missing other required fields
  }])
  with pytest.raises(jsonschema.ValidationError):
    dispatcher_module.validate_judgment_output(yaml_str, SCHEMAS_DIR)


def test_apply_escalate_mapping_uncertainty_high_overwrites_to_should_fix_user_decision(dispatcher_module):
  entry = {
    "source": "judgment_subagent",
    "requirement_link": "no",
    "ignored_impact": "low",
    "fix_cost": "high",
    "scope_expansion": "no",
    "uncertainty": "high",
    "fix_decision": {"label": "do_not_fix"},
    "recommended_action": "leave_as_is",
  }
  out = dispatcher_module.apply_escalate_mapping(entry)
  assert out["fix_decision"]["label"] == "should_fix"
  assert out["recommended_action"] == "user_decision"


def test_apply_escalate_mapping_uncertainty_low_unchanged(dispatcher_module):
  entry = {
    "source": "judgment_subagent",
    "requirement_link": "yes",
    "ignored_impact": "high",
    "fix_cost": "low",
    "scope_expansion": "no",
    "uncertainty": "low",
    "fix_decision": {"label": "must_fix"},
    "recommended_action": "fix_now",
  }
  out = dispatcher_module.apply_escalate_mapping(entry)
  assert out["fix_decision"]["label"] == "must_fix"
  assert out["recommended_action"] == "fix_now"


def test_cli_main_exit_0_on_success(tmp_path):
  config_yaml = tmp_path / "config.yaml"
  config_yaml.write_text("dev_log_path: ./dev_log.jsonl\njudgment_model: sonnet\n")
  result = subprocess.run(
    [
      sys.executable, str(DISPATCHER_PATH),
      "--dual-reviewer-root", str(PROTOTYPE_ROOT),
      "--config-yaml-path", str(config_yaml),
    ],
    capture_output=True, text=True,
  )
  assert result.returncode == 0, result.stderr


def test_cli_main_exit_1_on_prompt_read_fail(tmp_path):
  config_yaml = tmp_path / "config.yaml"
  config_yaml.write_text("dev_log_path: ./dev_log.jsonl\njudgment_model: sonnet\n")
  fake_root = tmp_path / "fake_root"
  fake_root.mkdir()
  result = subprocess.run(
    [
      sys.executable, str(DISPATCHER_PATH),
      "--dual-reviewer-root", str(fake_root),
      "--config-yaml-path", str(config_yaml),
    ],
    capture_output=True, text=True,
  )
  assert result.returncode == 1, result.stdout + result.stderr
