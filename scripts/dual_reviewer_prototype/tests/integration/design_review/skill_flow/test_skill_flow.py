# Task 7.1: dr-design → adversarial dispatch → dr-judgment invocation → dr-log per finding flow
# 1 finding mock で Step A/B/C/D 全 flow → JSONL append + judgment yaml dr-design 返却

import json
import sys
from pathlib import Path

import pytest
import yaml

PROTOTYPE_ROOT = Path(__file__).resolve().parents[4]
SCHEMAS_DIR = PROTOTYPE_ROOT / "schemas"
DR_DESIGN_DIR = PROTOTYPE_ROOT / "skills" / "dr-design"
DR_JUDGMENT_DIR = PROTOTYPE_ROOT / "skills" / "dr-judgment"
DR_LOG_DIR = PROTOTYPE_ROOT / "skills" / "dr-log"


@pytest.fixture
def all_modules():
  for d in [DR_DESIGN_DIR, DR_JUDGMENT_DIR, DR_LOG_DIR]:
    sys.path.insert(0, str(d))
  import orchestrator
  import judgment_dispatcher
  import log_writer
  yield orchestrator, judgment_dispatcher, log_writer
  for d in [DR_DESIGN_DIR, DR_JUDGMENT_DIR, DR_LOG_DIR]:
    sys.path.remove(str(d))


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


def test_full_step_abcd_flow_for_one_finding(all_modules, temp_target_project):
  """Step A (primary detect) → B (adversarial mock + counter_evidence) → C (judgment yaml validate) → D (merge into dr-log)"""
  orchestrator, judgment_dispatcher, log_writer_module = all_modules
  _, config_path, log_path = temp_target_project

  # Step A: primary findings (mock)
  primary_findings = [{
    "issue_id": "P-1",
    "source": "primary",
    "finding_text": "design.md L100: ambiguous AC for retry behavior",
    "severity": "ERROR",
    "state": "detected",
    "impact_score": {"severity": "ERROR", "fix_cost": "low", "downstream_effect": "isolated"},
  }]

  # Step B: adversarial findings + counter_evidence (mock yaml)
  adversarial_yaml = yaml.safe_dump({
    "findings": [{"issue_id": "A-1", "source": "adversarial", "text": "missing edge case"}],
    "counter_evidence": [
      {"issue_id": "P-1", "argument": "this might not be necessary because primary's premise is robust"},
    ],
  })
  counter_dict = orchestrator.decompose_counter_evidence(adversarial_yaml)
  assert "P-1" in counter_dict

  # Step C: judgment yaml validate (mock judgment 結果)
  judgment_yaml = yaml.safe_dump([{
    "source": "judgment_subagent",
    "requirement_link": "yes", "ignored_impact": "high", "fix_cost": "low",
    "scope_expansion": "no", "uncertainty": "low",
    "fix_decision": {"label": "must_fix"}, "recommended_action": "fix_now",
  }])
  validated = judgment_dispatcher.validate_judgment_output(judgment_yaml, SCHEMAS_DIR)
  assert len(validated) == 1

  # Step D: merge into dr-log (necessity 付与 + state=judged + counter_evidence 付与)
  primary_findings[0]["state"] = "judged"
  primary_findings[0]["necessity_judgment"] = validated[0]
  primary_findings[0]["adversarial_counter_evidence"] = counter_dict["P-1"]

  w = log_writer_module.LogWriter(SCHEMAS_DIR)
  w.open(
    session_id="s-1", treatment="dual+judgment", round_index=1,
    design_md_commit_hash="test-hash", target_spec_id="foundation",
    config_yaml_path=config_path,
  )
  w.append("s-1", primary_findings[0])
  w.flush("s-1")

  obj = json.loads(log_path.read_text().strip())
  assert obj["findings"][0]["state"] == "judged"
  assert obj["findings"][0]["necessity_judgment"]["fix_decision"]["label"] == "must_fix"
  assert "primary's premise is robust" in obj["findings"][0]["adversarial_counter_evidence"]
