# Task 6.3: JSON Schema unit validation (5 schema 各 valid + invalid sample)
# 本タスクは単一 schema 完結 validate に責務限定 (cross-file $ref 解決は Task 7.5、A4 apply)。
import json
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator
from jsonschema.exceptions import ValidationError

SCHEMAS_DIR = Path(__file__).resolve().parents[2] / "schemas"


def load_schema(name):
  return json.load(open(SCHEMAS_DIR / f"{name}.schema.json"))


# ---------- schema 自身の validity ----------

def test_all_schemas_are_valid_draft_2020_12():
  for n in ["review_case", "finding", "impact_score", "failure_observation", "necessity_judgment"]:
    schema = load_schema(n)
    Draft202012Validator.check_schema(schema)
    assert schema["$schema"] == "https://json-schema.org/draft/2020-12/schema"


# ---------- impact_score: 単独 schema (外部 $ref なし) ----------

def test_impact_score_valid_sample():
  schema = load_schema("impact_score")
  sample = {"severity": "ERROR", "fix_cost": "low", "downstream_effect": "isolated"}
  Draft202012Validator(schema).validate(sample)


def test_impact_score_invalid_severity_enum():
  schema = load_schema("impact_score")
  sample = {"severity": "INVALID", "fix_cost": "low", "downstream_effect": "isolated"}
  with pytest.raises(ValidationError):
    Draft202012Validator(schema).validate(sample)


def test_impact_score_missing_required_field():
  schema = load_schema("impact_score")
  sample = {"severity": "ERROR", "fix_cost": "low"}  # downstream_effect 欠落
  with pytest.raises(ValidationError):
    Draft202012Validator(schema).validate(sample)


def test_impact_score_invalid_type():
  schema = load_schema("impact_score")
  sample = {"severity": 123, "fix_cost": "low", "downstream_effect": "isolated"}
  with pytest.raises(ValidationError):
    Draft202012Validator(schema).validate(sample)


# ---------- failure_observation: 内部 $ref `#/$defs/trigger_state` のみ ----------

def test_failure_observation_valid_sample():
  schema = load_schema("failure_observation")
  sample = {
    "miss_type": "implicit_assumption",
    "difference_type": "assumption_shift",
    "trigger_state": {
      "negative_check": "applied",
      "escalate_check": "skipped",
      "alternative_considered": "applied",
    },
  }
  Draft202012Validator(schema).validate(sample)


def test_failure_observation_invalid_miss_type():
  schema = load_schema("failure_observation")
  sample = {
    "miss_type": "INVALID_MISS",
    "difference_type": "assumption_shift",
    "trigger_state": {
      "negative_check": "applied",
      "escalate_check": "skipped",
      "alternative_considered": "applied",
    },
  }
  with pytest.raises(ValidationError):
    Draft202012Validator(schema).validate(sample)


def test_failure_observation_invalid_trigger_state_field():
  schema = load_schema("failure_observation")
  sample = {
    "miss_type": "implicit_assumption",
    "difference_type": "assumption_shift",
    "trigger_state": {
      "negative_check": "INVALID",  # not applied/skipped
      "escalate_check": "skipped",
      "alternative_considered": "applied",
    },
  }
  with pytest.raises(ValidationError):
    Draft202012Validator(schema).validate(sample)


def test_failure_observation_missing_trigger_state():
  schema = load_schema("failure_observation")
  sample = {"miss_type": "implicit_assumption", "difference_type": "assumption_shift"}
  with pytest.raises(ValidationError):
    Draft202012Validator(schema).validate(sample)


# ---------- necessity_judgment: 単独 schema (外部 $ref なし) ----------

def test_necessity_judgment_valid_sample():
  schema = load_schema("necessity_judgment")
  sample = {
    "source": "judgment_subagent",
    "requirement_link": "yes",
    "ignored_impact": "high",
    "fix_cost": "low",
    "scope_expansion": "no",
    "uncertainty": "low",
    "fix_decision": {"label": "must_fix"},
    "recommended_action": "fix_now",
  }
  Draft202012Validator(schema).validate(sample)


def test_necessity_judgment_invalid_fix_decision_label():
  schema = load_schema("necessity_judgment")
  sample = {
    "source": "judgment_subagent",
    "requirement_link": "yes",
    "ignored_impact": "high",
    "fix_cost": "low",
    "scope_expansion": "no",
    "uncertainty": "low",
    "fix_decision": {"label": "INVALID"},
    "recommended_action": "fix_now",
  }
  with pytest.raises(ValidationError):
    Draft202012Validator(schema).validate(sample)


def test_necessity_judgment_missing_required():
  schema = load_schema("necessity_judgment")
  sample = {
    "source": "judgment_subagent",
    "requirement_link": "yes",
    # 必要性 5-field の他 4 個欠落
    "fix_decision": {"label": "must_fix"},
    "recommended_action": "fix_now",
  }
  with pytest.raises(ValidationError):
    Draft202012Validator(schema).validate(sample)


# ---------- finding: 単独 schema 完結 validate (cross-file $ref を strip) ----------

def _finding_schema_local():
  """finding schema の cross-file $ref を generic object に置換 (本 task 単独 validate 限定、Task 7.5 で full $ref resolve)"""
  schema = load_schema("finding")
  schema = json.loads(json.dumps(schema))
  for prop in ["impact_score", "failure_observation", "necessity_judgment"]:
    if prop in schema["properties"]:
      schema["properties"][prop] = {"type": "object"}
  return schema


def test_finding_state_detected_without_necessity_judgment_passes():
  schema = _finding_schema_local()
  sample = {
    "issue_id": "x1",
    "source": "primary",
    "finding_text": "sample finding",
    "severity": "ERROR",
    "state": "detected",
    "impact_score": {},
  }
  Draft202012Validator(schema).validate(sample)


def test_finding_state_judged_without_necessity_judgment_fails():
  schema = _finding_schema_local()
  sample = {
    "issue_id": "x1",
    "source": "primary",
    "finding_text": "sample finding",
    "severity": "ERROR",
    "state": "judged",
    "impact_score": {},
  }
  with pytest.raises(ValidationError):
    Draft202012Validator(schema).validate(sample)


def test_finding_state_judged_with_necessity_judgment_passes():
  schema = _finding_schema_local()
  sample = {
    "issue_id": "x1",
    "source": "primary",
    "finding_text": "sample finding",
    "severity": "ERROR",
    "state": "judged",
    "impact_score": {},
    "necessity_judgment": {},
  }
  Draft202012Validator(schema).validate(sample)


def test_finding_invalid_source_enum():
  schema = _finding_schema_local()
  sample = {
    "issue_id": "x1",
    "source": "INVALID",
    "finding_text": "sample",
    "severity": "ERROR",
    "state": "detected",
    "impact_score": {},
  }
  with pytest.raises(ValidationError):
    Draft202012Validator(schema).validate(sample)


def test_finding_invalid_severity_enum():
  schema = _finding_schema_local()
  sample = {
    "issue_id": "x1",
    "source": "primary",
    "finding_text": "sample",
    "severity": "FATAL",
    "state": "detected",
    "impact_score": {},
  }
  with pytest.raises(ValidationError):
    Draft202012Validator(schema).validate(sample)


# ---------- review_case: 単独 schema 完結 validate (cross-file $ref を strip) ----------

def _review_case_schema_local():
  schema = load_schema("review_case")
  schema = json.loads(json.dumps(schema))
  if "trigger_state" in schema["properties"]:
    schema["properties"]["trigger_state"] = {"type": "object"}
  if "findings" in schema["properties"]:
    schema["properties"]["findings"] = {"type": "array"}
  return schema


def test_review_case_valid_sample():
  schema = _review_case_schema_local()
  sample = {
    "session_id": "session_001",
    "phase": "design",
    "target_spec_id": "dual-reviewer-foundation",
    "timestamp_start": "2026-05-01T12:00:00Z",
    "findings": [],
  }
  Draft202012Validator(schema).validate(sample)


def test_review_case_invalid_phase_enum():
  schema = _review_case_schema_local()
  sample = {
    "session_id": "session_001",
    "phase": "INVALID_PHASE",
    "target_spec_id": "x",
    "timestamp_start": "2026-05-01T12:00:00Z",
    "findings": [],
  }
  with pytest.raises(ValidationError):
    Draft202012Validator(schema).validate(sample)


def test_review_case_missing_required():
  schema = _review_case_schema_local()
  sample = {"session_id": "x", "phase": "design"}
  with pytest.raises(ValidationError):
    Draft202012Validator(schema).validate(sample)


# ---------- B-1.0 required mark 確認 (失敗構造観測軸 3 要素 + 必要性 5-field + fix_decision.label) ----------

def test_b1_0_required_failure_observation_3_axes():
  schema = load_schema("failure_observation")
  assert {"miss_type", "difference_type", "trigger_state"}.issubset(set(schema["required"]))


def test_b1_0_required_necessity_5_fields():
  schema = load_schema("necessity_judgment")
  required = set(schema["required"])
  expected = {"requirement_link", "ignored_impact", "fix_cost", "scope_expansion", "uncertainty"}
  assert expected.issubset(required)


def test_b1_0_required_fix_decision_label():
  schema = load_schema("necessity_judgment")
  fd = schema["properties"]["fix_decision"]
  assert "label" in fd["required"]
