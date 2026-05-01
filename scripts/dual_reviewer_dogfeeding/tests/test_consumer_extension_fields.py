# test_consumer_extension_fields.py — Task 6.2: Consumer 拡張 4 field integration
# mock JSONL fixture (30 line) → metric_extractor が 4 field 認識 + foundation schema validate pass
# A6 apply: 4 field 全件 presence assertion (additionalProperties: true 経由の field absence mechanically detect)

import json
import sys
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012

REPO_ROOT = Path(__file__).resolve().parents[3]
DOGFEEDING_DIR = REPO_ROOT / "scripts" / "dual_reviewer_dogfeeding"
PROTOTYPE_ROOT = REPO_ROOT / "scripts" / "dual_reviewer_prototype"
SCHEMAS_DIR = PROTOTYPE_ROOT / "schemas"
SCHEMA_NAMES = ["review_case", "finding", "impact_score", "failure_observation", "necessity_judgment"]


def _make_finding(issue_id, source, label="must_fix", state="judged", with_counter=True):
  f = {
    "issue_id": issue_id, "source": source,
    "finding_text": f"{issue_id} text", "severity": "ERROR", "state": state,
    "impact_score": {"severity": "ERROR", "fix_cost": "low", "downstream_effect": "isolated"},
  }
  if state == "judged":
    f["necessity_judgment"] = {
      "source": "judgment_subagent", "requirement_link": "yes",
      "ignored_impact": "high", "fix_cost": "low", "scope_expansion": "no",
      "uncertainty": "low", "fix_decision": {"label": label}, "recommended_action": "fix_now",
    }
  if with_counter:
    f["adversarial_counter_evidence"] = "counter evidence"
  return f


def _make_review_case(treatment, round_index, hash_, findings):
  return {
    "session_id": f"s-{treatment}-{round_index}", "phase": "design",
    "target_spec_id": "spec6",
    "timestamp_start": "2026-05-01T10:00:00Z", "timestamp_end": "2026-05-01T10:07:00Z",
    "treatment": treatment, "round_index": round_index,
    "design_md_commit_hash": hash_, "findings": findings,
  }


@pytest.fixture
def mock_30_line_jsonl_with_4_fields(tmp_path):
  jsonl = tmp_path / "dev_log.jsonl"
  rcs = []
  for treatment in ["single", "dual", "dual+judgment"]:
    for r in range(1, 11):
      with_counter = treatment in ("dual", "dual+judgment")
      f = _make_finding(f"P-{treatment}-{r}", "primary", with_counter=with_counter)
      rcs.append(_make_review_case(treatment, r, "h1", [f]))
  jsonl.write_text("\n".join(json.dumps(rc) for rc in rcs) + "\n")
  return jsonl


@pytest.fixture
def schema_registry():
  schemas = {f"{n}.schema.json": json.loads((SCHEMAS_DIR / f"{n}.schema.json").read_text()) for n in SCHEMA_NAMES}
  reg = Registry()
  for uri, schema in schemas.items():
    reg = reg.with_resource(uri=uri, resource=Resource.from_contents(schema, default_specification=DRAFT202012))
  return schemas, reg


def test_30_review_cases_all_have_4_consumer_fields_present(mock_30_line_jsonl_with_4_fields):
  """A6 apply: assertIn で key としての presence 明示確認 (30 line 全件)"""
  for line in mock_30_line_jsonl_with_4_fields.read_text().splitlines():
    rc = json.loads(line)
    assert "treatment" in rc, f"treatment field missing in {rc.get('session_id')}"
    assert "round_index" in rc, f"round_index field missing in {rc.get('session_id')}"
    assert "design_md_commit_hash" in rc, f"design_md_commit_hash field missing in {rc.get('session_id')}"
    # adversarial_counter_evidence は finding object 単位 + treatment 値依存
    treatment = rc["treatment"]
    for f in rc["findings"]:
      if treatment in ("dual", "dual+judgment"):
        assert "adversarial_counter_evidence" in f, \
          f"adversarial_counter_evidence missing in {treatment} treatment finding {f.get('issue_id')}"
      # single 系統 finding では省略可 (= 検査しない)


def test_30_review_cases_all_pass_foundation_schema_validation(mock_30_line_jsonl_with_4_fields, schema_registry):
  """foundation review_case.schema.json + finding.schema.json で全 30 line validate pass"""
  schemas, registry = schema_registry
  validator = Draft202012Validator(schemas["review_case.schema.json"], registry=registry)
  for line in mock_30_line_jsonl_with_4_fields.read_text().splitlines():
    rc = json.loads(line)
    validator.validate(rc)


def test_4_field_value_constraints(mock_30_line_jsonl_with_4_fields):
  """treatment ∈ enum + round_index 1..10 + design_md_commit_hash non-empty + counter_evidence string"""
  for line in mock_30_line_jsonl_with_4_fields.read_text().splitlines():
    rc = json.loads(line)
    assert rc["treatment"] in ["single", "dual", "dual+judgment"]
    assert 1 <= rc["round_index"] <= 10
    assert isinstance(rc["design_md_commit_hash"], str) and rc["design_md_commit_hash"]
    if rc["treatment"] in ("dual", "dual+judgment"):
      for f in rc["findings"]:
        assert isinstance(f.get("adversarial_counter_evidence"), str)


def test_metric_extractor_recognizes_30_review_cases_with_4_fields(mock_30_line_jsonl_with_4_fields):
  sys.path.insert(0, str(DOGFEEDING_DIR))
  try:
    import metric_extractor
    metrics = metric_extractor.extract_metrics(mock_30_line_jsonl_with_4_fields)
    assert metrics["session_count"] == 30
    assert sorted(metrics["treatments"]) == ["dual", "dual+judgment", "single"]
    assert metrics["rounds"] == list(range(1, 11))
  finally:
    sys.path.remove(str(DOGFEEDING_DIR))
