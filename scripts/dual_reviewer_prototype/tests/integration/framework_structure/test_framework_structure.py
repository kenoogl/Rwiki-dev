# Task 7.4: layer1_framework.yaml structure + content semantic presence test
from pathlib import Path

import yaml

PROTOTYPE_ROOT = Path(__file__).resolve().parents[3]
FRAMEWORK_PATH = PROTOTYPE_ROOT / "framework" / "layer1_framework.yaml"


def test_yaml_parse_succeeds():
  data = yaml.safe_load(FRAMEWORK_PATH.read_text())
  assert isinstance(data, dict)


def test_7_top_level_sections_present():
  data = yaml.safe_load(FRAMEWORK_PATH.read_text())
  expected = {"step_pipeline", "bias_suppression_quota", "pattern_schema", "attach_contract", "chappy_p0", "v4_features", "terminology"}
  present = set(data.keys())
  assert expected.issubset(present), f"missing top-level: {expected - present}"


def test_step_pipeline_step_a_b_c_d_with_sub_steps():
  data = yaml.safe_load(FRAMEWORK_PATH.read_text())
  sp = data["step_pipeline"]
  assert set(sp.keys()) == {"step_a", "step_b", "step_c", "step_d"}
  for step in ["step_a", "step_b", "step_c", "step_d"]:
    assert "sub_steps" in sp[step], f"{step} missing sub_steps"
    assert isinstance(sp[step]["sub_steps"], list)
    assert len(sp[step]["sub_steps"]) > 0


def test_bias_suppression_quota_fundamental_events_and_policy():
  data = yaml.safe_load(FRAMEWORK_PATH.read_text())
  q = data["bias_suppression_quota"]
  assert q["fundamental_events"] == ["formal_challenge", "detection_miss", "phase1_pattern_match"]
  assert q["measurement_policy"] == "post_run_only"


def test_pattern_schema_two_layer_grouping():
  data = yaml.safe_load(FRAMEWORK_PATH.read_text())
  ps = data["pattern_schema"]
  assert ps["structure"] == "two_layer_grouping"
  assert ps["layers"]["primary_group"] == "required"
  assert ps["layers"]["secondary_groups"] == "required"


def test_attach_contract_layer_2_and_layer_3_each_3_fields():
  """P2 apply: layer_2 / layer_3 各 3 要素 = 合計 6 field presence"""
  data = yaml.safe_load(FRAMEWORK_PATH.read_text())
  ac = data["attach_contract"]
  expected_fields = {"entry_point_location", "identifier_format", "failure_signal"}
  assert set(ac["layer_2"].keys()) == expected_fields, f"layer_2: {set(ac['layer_2'].keys())}"
  assert set(ac["layer_3"].keys()) == expected_fields, f"layer_3: {set(ac['layer_3'].keys())}"


def test_attach_contract_override_hierarchy_order_exact():
  data = yaml.safe_load(FRAMEWORK_PATH.read_text())
  ac = data["attach_contract"]
  assert ac["override_hierarchy"]["order"] == ["layer_3", "layer_2", "layer_1"]
  assert ac["override_hierarchy"]["semantics"] == "single_direction_unidirectional"


def test_chappy_p0_3_facilities_present():
  data = yaml.safe_load(FRAMEWORK_PATH.read_text())
  cp = data["chappy_p0"]
  expected = {"fatal_patterns_match", "impact_score", "forced_divergence_prompt"}
  assert set(cp.keys()) == expected


def test_v4_features_5_facilities_present():
  data = yaml.safe_load(FRAMEWORK_PATH.read_text())
  v4 = data["v4_features"]
  expected = {"judgment_subagent_dispatch", "necessity_5_fields", "five_condition_rule", "three_label_classification", "role_separation"}
  assert set(v4.keys()) == expected


def test_v4_role_separation_assignments():
  data = yaml.safe_load(FRAMEWORK_PATH.read_text())
  rs = data["v4_features"]["role_separation"]
  assert rs["step_b_forced_divergence"]["assigned_to"] == "adversarial_reviewer"
  assert rs["step_c_fix_negation"]["assigned_to"] == "judgment_reviewer"


def test_terminology_role_abstractions_exact():
  data = yaml.safe_load(FRAMEWORK_PATH.read_text())
  t = data["terminology"]
  assert t["role_abstractions"] == ["primary_reviewer", "adversarial_reviewer", "judgment_reviewer"]
  assert t["concrete_model_resolution"] == "config_yaml_field"
