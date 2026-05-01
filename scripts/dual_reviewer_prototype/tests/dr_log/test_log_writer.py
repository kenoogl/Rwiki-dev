# test_log_writer.py — dr-log skill helper script unit tests
# Task 6.3 + 6.4 + 6.5 (TDD red 先 → Task 4.2 impl で green)

import json
import sys
import tempfile
from pathlib import Path

import pytest
import yaml

PROTOTYPE_ROOT = Path(__file__).resolve().parents[2]
SCHEMAS_DIR = PROTOTYPE_ROOT / "schemas"
DR_LOG_DIR = PROTOTYPE_ROOT / "skills" / "dr-log"


@pytest.fixture
def log_writer_module():
  """import log_writer as module (Task 4.2 impl 後 import 成功)."""
  sys.path.insert(0, str(DR_LOG_DIR))
  import log_writer
  yield log_writer
  sys.path.remove(str(DR_LOG_DIR))


@pytest.fixture
def temp_target_project(tmp_path):
  """target project with .dual-reviewer/config.yaml + dev_log.jsonl 雛形."""
  dr_dir = tmp_path / ".dual-reviewer"
  dr_dir.mkdir()
  config = dr_dir / "config.yaml"
  config.write_text(yaml.safe_dump({
    "primary_model": "opus",
    "adversarial_model": "sonnet",
    "judgment_model": "sonnet",
    "lang": "ja",
    "dev_log_path": "./dev_log.jsonl",
  }))
  log = dr_dir / "dev_log.jsonl"
  log.touch()
  return tmp_path, config, log


def _valid_finding(state="detected", source_finding="primary", source_necessity=None, with_counter=False):
  finding = {
    "issue_id": "P-1",
    "source": source_finding,
    "finding_text": "test finding",
    "severity": "ERROR",
    "state": state,
    "impact_score": {
      "severity": "ERROR",
      "fix_cost": "low",
      "downstream_effect": "isolated",
    },
  }
  if state == "judged":
    finding["necessity_judgment"] = {
      "source": source_necessity or "judgment_subagent",
      "requirement_link": "yes",
      "ignored_impact": "high",
      "fix_cost": "low",
      "scope_expansion": "no",
      "uncertainty": "low",
      "fix_decision": {"label": "must_fix"},
      "recommended_action": "fix_now",
    }
  if with_counter:
    finding["adversarial_counter_evidence"] = "this is counter evidence"
  return finding


# ---------- Task 6.3: open/append/flush lifecycle + JSONL append-only ----------

def test_open_initializes_session_returns_session_id(log_writer_module, temp_target_project):
  _, config, _ = temp_target_project
  w = log_writer_module.LogWriter(SCHEMAS_DIR)
  sid = w.open(
    session_id="s-1", treatment="dual+judgment", round_index=1,
    design_md_commit_hash="abc123", target_spec_id="dual-reviewer-foundation",
    config_yaml_path=config,
  )
  assert sid == "s-1"


def test_append_then_flush_produces_one_jsonl_line(log_writer_module, temp_target_project):
  _, config, log_path = temp_target_project
  w = log_writer_module.LogWriter(SCHEMAS_DIR)
  w.open(
    session_id="s-1", treatment="dual+judgment", round_index=1,
    design_md_commit_hash="abc123", target_spec_id="foundation",
    config_yaml_path=config,
  )
  w.append("s-1", _valid_finding(state="judged", source_necessity="judgment_subagent", with_counter=True))
  w.flush("s-1")
  lines = log_path.read_text().strip().splitlines()
  assert len(lines) == 1
  obj = json.loads(lines[0])
  assert obj["session_id"] == "s-1"
  assert len(obj["findings"]) == 1


def test_flush_includes_timestamp_start_and_end(log_writer_module, temp_target_project):
  _, config, log_path = temp_target_project
  w = log_writer_module.LogWriter(SCHEMAS_DIR)
  w.open(
    session_id="s-1", treatment="single", round_index=2,
    design_md_commit_hash="def456", target_spec_id="foundation",
    config_yaml_path=config,
  )
  w.append("s-1", _valid_finding(state="detected"))
  w.flush("s-1")
  obj = json.loads(log_path.read_text().strip())
  assert "timestamp_start" in obj
  assert "timestamp_end" in obj
  # ISO8601 format check
  assert "T" in obj["timestamp_start"]


def test_two_sessions_produce_two_jsonl_lines(log_writer_module, temp_target_project):
  _, config, log_path = temp_target_project
  w = log_writer_module.LogWriter(SCHEMAS_DIR)
  for sid in ["s-A", "s-B"]:
    w.open(
      session_id=sid, treatment="dual", round_index=1,
      design_md_commit_hash="x", target_spec_id="foundation",
      config_yaml_path=config,
    )
    w.append(sid, _valid_finding(state="detected", source_finding="primary"))
    w.append(sid, _valid_finding(state="detected", source_finding="adversarial"))
    w.flush(sid)
  lines = log_path.read_text().strip().splitlines()
  assert len(lines) == 2  # 1 line per session_id (A1 grain-correction)
  for line in lines:
    obj = json.loads(line)
    assert len(obj["findings"]) == 2


def test_flush_includes_treatment_round_index_commit_hash(log_writer_module, temp_target_project):
  _, config, log_path = temp_target_project
  w = log_writer_module.LogWriter(SCHEMAS_DIR)
  w.open(
    session_id="s-1", treatment="dual+judgment", round_index=7,
    design_md_commit_hash="commit-hash-xyz", target_spec_id="foundation",
    config_yaml_path=config,
  )
  w.append("s-1", _valid_finding(state="judged", source_necessity="judgment_subagent", with_counter=True))
  w.flush("s-1")
  obj = json.loads(log_path.read_text().strip())
  assert obj["treatment"] == "dual+judgment"
  assert obj["round_index"] == 7
  assert obj["design_md_commit_hash"] == "commit-hash-xyz"


# ---------- Task 6.4: state field variant validate ----------

def test_append_state_detected_without_necessity_passes(log_writer_module, temp_target_project):
  _, config, _ = temp_target_project
  w = log_writer_module.LogWriter(SCHEMAS_DIR)
  w.open(
    session_id="s-1", treatment="dual", round_index=1,
    design_md_commit_hash="x", target_spec_id="foundation",
    config_yaml_path=config,
  )
  # state=detected で necessity_judgment 省略 → pass
  w.append("s-1", _valid_finding(state="detected"))


def test_append_state_judged_without_necessity_fails(log_writer_module, temp_target_project):
  import jsonschema
  _, config, _ = temp_target_project
  w = log_writer_module.LogWriter(SCHEMAS_DIR)
  w.open(
    session_id="s-1", treatment="dual+judgment", round_index=1,
    design_md_commit_hash="x", target_spec_id="foundation",
    config_yaml_path=config,
  )
  invalid = {
    "issue_id": "P-1",
    "source": "primary",
    "finding_text": "test",
    "severity": "ERROR",
    "state": "judged",  # judged で necessity_judgment 省略 → schema fail
    "impact_score": {"severity": "ERROR", "fix_cost": "low", "downstream_effect": "isolated"},
  }
  with pytest.raises(jsonschema.ValidationError):
    w.append("s-1", invalid)


# ---------- Task 6.5: 3 系統対応 + 2 層 source field ----------

def test_finding_source_layer_independent_of_treatment(log_writer_module, temp_target_project):
  """finding.source (検出元 = primary | adversarial) は 3 系統共通、treatment と独立 (A4 apply)."""
  _, config, log_path = temp_target_project
  w = log_writer_module.LogWriter(SCHEMAS_DIR)
  for treatment in ["single", "dual", "dual+judgment"]:
    sid = f"s-{treatment}"
    w.open(
      session_id=sid, treatment=treatment, round_index=1,
      design_md_commit_hash="x", target_spec_id="foundation",
      config_yaml_path=config,
    )
    w.append(sid, _valid_finding(state="detected", source_finding="primary"))
    w.append(sid, _valid_finding(state="detected", source_finding="adversarial"))
    w.flush(sid)
  lines = log_path.read_text().strip().splitlines()
  for line in lines:
    obj = json.loads(line)
    sources = [f["source"] for f in obj["findings"]]
    assert "primary" in sources and "adversarial" in sources


def test_single_treatment_necessity_source_primary_self_estimate_no_counter(log_writer_module, temp_target_project):
  _, config, log_path = temp_target_project
  w = log_writer_module.LogWriter(SCHEMAS_DIR)
  w.open(
    session_id="s-1", treatment="single", round_index=1,
    design_md_commit_hash="x", target_spec_id="foundation",
    config_yaml_path=config,
  )
  finding = _valid_finding(state="detected", source_finding="primary")
  # single 系統では necessity_judgment は付与しないか primary_self_estimate のみ、counter omit
  w.append("s-1", finding)
  w.flush("s-1")
  obj = json.loads(log_path.read_text().strip())
  assert obj["treatment"] == "single"
  assert "adversarial_counter_evidence" not in obj["findings"][0]


def test_dual_treatment_necessity_source_primary_self_estimate_with_counter(log_writer_module, temp_target_project):
  _, config, log_path = temp_target_project
  w = log_writer_module.LogWriter(SCHEMAS_DIR)
  w.open(
    session_id="s-1", treatment="dual", round_index=1,
    design_md_commit_hash="x", target_spec_id="foundation",
    config_yaml_path=config,
  )
  finding = _valid_finding(state="detected", source_finding="primary", with_counter=True)
  w.append("s-1", finding)
  w.flush("s-1")
  obj = json.loads(log_path.read_text().strip())
  assert obj["treatment"] == "dual"
  assert obj["findings"][0]["adversarial_counter_evidence"] == "this is counter evidence"


def test_dual_judgment_necessity_source_judgment_subagent_with_counter(log_writer_module, temp_target_project):
  _, config, log_path = temp_target_project
  w = log_writer_module.LogWriter(SCHEMAS_DIR)
  w.open(
    session_id="s-1", treatment="dual+judgment", round_index=1,
    design_md_commit_hash="x", target_spec_id="foundation",
    config_yaml_path=config,
  )
  finding = _valid_finding(state="judged", source_necessity="judgment_subagent", with_counter=True)
  w.append("s-1", finding)
  w.flush("s-1")
  obj = json.loads(log_path.read_text().strip())
  assert obj["treatment"] == "dual+judgment"
  assert obj["findings"][0]["necessity_judgment"]["source"] == "judgment_subagent"
  assert obj["findings"][0]["adversarial_counter_evidence"] == "this is counter evidence"
