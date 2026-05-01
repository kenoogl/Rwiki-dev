# Task 7.5: JSON Schema 複合条件 validation test ($ref + allOf + if/then mixed)
# **本タスクが cross-file $ref resolver 設定の責務を持つ** (Task 6.3 は単一 schema 完結 validate に責務限定、A4 apply)
import json
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator
from jsonschema.exceptions import ValidationError
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012

PROTOTYPE_ROOT = Path(__file__).resolve().parents[3]
SCHEMAS_DIR = PROTOTYPE_ROOT / "schemas"
SCHEMA_NAMES = ["review_case", "finding", "impact_score", "failure_observation", "necessity_judgment"]


def _load_all_schemas():
  return {f"{n}.schema.json": json.load(open(SCHEMAS_DIR / f"{n}.schema.json")) for n in SCHEMA_NAMES}


def _make_registry(schemas):
  """jsonschema.Registry に 5 schema を登録 (URI = `<name>.schema.json`、$ref と整合)"""
  registry = Registry()
  for uri, schema in schemas.items():
    resource = Resource.from_contents(schema, default_specification=DRAFT202012)
    registry = registry.with_resource(uri=uri, resource=resource)
  return registry


# ---------- finding state variant: detected / judged + cross-file $ref 解決 ----------

def test_finding_state_detected_no_necessity_passes_with_full_ref_resolve():
  """valid sample 1: state: detected without necessity_judgment → pass"""
  schemas = _load_all_schemas()
  registry = _make_registry(schemas)
  validator = Draft202012Validator(schemas["finding.schema.json"], registry=registry)
  sample = {
    "issue_id": "x1",
    "source": "primary",
    "finding_text": "first finding",
    "severity": "ERROR",
    "state": "detected",
    "impact_score": {
      "severity": "ERROR",
      "fix_cost": "low",
      "downstream_effect": "isolated",
    },
  }
  validator.validate(sample)


def test_finding_state_judged_with_necessity_passes():
  """valid sample 2: state: judged with necessity_judgment (必要性 5-field + fix_decision.label) → pass"""
  schemas = _load_all_schemas()
  registry = _make_registry(schemas)
  validator = Draft202012Validator(schemas["finding.schema.json"], registry=registry)
  sample = {
    "issue_id": "x2",
    "source": "adversarial",
    "finding_text": "second finding",
    "severity": "CRITICAL",
    "state": "judged",
    "impact_score": {
      "severity": "CRITICAL",
      "fix_cost": "high",
      "downstream_effect": "cross-spec",
    },
    "necessity_judgment": {
      "source": "judgment_subagent",
      "requirement_link": "yes",
      "ignored_impact": "high",
      "fix_cost": "low",
      "scope_expansion": "no",
      "uncertainty": "low",
      "fix_decision": {"label": "must_fix"},
      "recommended_action": "fix_now",
    },
  }
  validator.validate(sample)


def test_finding_state_judged_without_necessity_fails():
  """invalid sample: state: judged without necessity_judgment → fail"""
  schemas = _load_all_schemas()
  registry = _make_registry(schemas)
  validator = Draft202012Validator(schemas["finding.schema.json"], registry=registry)
  sample = {
    "issue_id": "x3",
    "source": "primary",
    "finding_text": "third finding",
    "severity": "ERROR",
    "state": "judged",
    "impact_score": {
      "severity": "ERROR",
      "fix_cost": "low",
      "downstream_effect": "isolated",
    },
  }
  with pytest.raises(ValidationError):
    validator.validate(sample)


# ---------- $ref chain (review_case → finding → impact_score / failure_observation / necessity_judgment) ----------

def test_review_case_full_ref_chain_resolution():
  """$ref 解決 chain: review_case sample が finding array 経由で全 nested $ref を解決"""
  schemas = _load_all_schemas()
  registry = _make_registry(schemas)
  validator = Draft202012Validator(schemas["review_case.schema.json"], registry=registry)

  sample = {
    "session_id": "session_001",
    "phase": "design",
    "target_spec_id": "dual-reviewer-foundation",
    "timestamp_start": "2026-05-01T12:00:00Z",
    "timestamp_end": "2026-05-01T13:00:00Z",
    "trigger_state": {
      "negative_check": "applied",
      "escalate_check": "applied",
      "alternative_considered": "skipped",
    },
    "findings": [
      {
        "issue_id": "i1",
        "source": "primary",
        "finding_text": "first issue",
        "severity": "ERROR",
        "state": "judged",
        "impact_score": {
          "severity": "ERROR",
          "fix_cost": "low",
          "downstream_effect": "isolated",
        },
        "failure_observation": {
          "miss_type": "implicit_assumption",
          "difference_type": "assumption_shift",
          "trigger_state": {
            "negative_check": "applied",
            "escalate_check": "applied",
            "alternative_considered": "applied",
          },
        },
        "necessity_judgment": {
          "source": "judgment_subagent",
          "requirement_link": "yes",
          "ignored_impact": "high",
          "fix_cost": "low",
          "scope_expansion": "no",
          "uncertainty": "low",
          "fix_decision": {"label": "must_fix"},
          "recommended_action": "fix_now",
        },
      }
    ],
  }
  validator.validate(sample)


def test_review_case_invalid_nested_finding_severity_fails():
  """nested $ref chain で findings[0].severity が enum 違反 → fail (= $ref が正しく解決されていることの証明)"""
  schemas = _load_all_schemas()
  registry = _make_registry(schemas)
  validator = Draft202012Validator(schemas["review_case.schema.json"], registry=registry)

  sample = {
    "session_id": "x",
    "phase": "design",
    "target_spec_id": "x",
    "timestamp_start": "2026-05-01T12:00:00Z",
    "findings": [
      {
        "issue_id": "i1",
        "source": "primary",
        "finding_text": "x",
        "severity": "INVALID_SEVERITY",  # enum 違反
        "state": "detected",
        "impact_score": {
          "severity": "ERROR",
          "fix_cost": "low",
          "downstream_effect": "isolated",
        },
      }
    ],
  }
  with pytest.raises(ValidationError):
    validator.validate(sample)
