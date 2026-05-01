# test_orchestrator.py — dr-design skill helper script unit tests
# Task 6.1 + 6.2 (TDD red 先 → Task 5.2 impl で green)

import sys
from pathlib import Path

import pytest
import yaml

PROTOTYPE_ROOT = Path(__file__).resolve().parents[2]
DR_DESIGN_DIR = PROTOTYPE_ROOT / "skills" / "dr-design"


@pytest.fixture
def orchestrator_module():
  sys.path.insert(0, str(DR_DESIGN_DIR))
  import orchestrator
  yield orchestrator
  sys.path.remove(str(DR_DESIGN_DIR))


# ---------- Task 6.1: Layer 1/2 yaml load + Round 1-10 sequential ----------

def test_load_frameworks_returns_layer1_and_layer2(orchestrator_module):
  layer1, layer2 = orchestrator_module.load_frameworks(PROTOTYPE_ROOT)
  assert isinstance(layer1, dict)
  assert isinstance(layer2, dict)
  # foundation Layer 1 framework は 7 top-level
  assert "version" in layer1
  # 本 spec Layer 2 extension は attach_identifier=design_extension
  assert layer2["metadata"]["attach_identifier"] == "design_extension"


def test_load_frameworks_missing_layer_raises(orchestrator_module, tmp_path):
  with pytest.raises(FileNotFoundError):
    orchestrator_module.load_frameworks(tmp_path)


def test_iterate_rounds_returns_round_index_1_to_10_in_order(orchestrator_module):
  _, layer2 = orchestrator_module.load_frameworks(PROTOTYPE_ROOT)
  rounds = list(orchestrator_module.iterate_rounds(layer2))
  assert len(rounds) == 10
  indices = [r["round_index"] for r in rounds]
  assert indices == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]


def test_resolve_foundation_path_joins_with_base_root(orchestrator_module):
  result = orchestrator_module.resolve_foundation_path(PROTOTYPE_ROOT, "./patterns/fatal_patterns.yaml")
  assert result == PROTOTYPE_ROOT / "patterns" / "fatal_patterns.yaml"


def test_load_forced_divergence_prompt_returns_3_paragraph_text(orchestrator_module):
  text = orchestrator_module.load_forced_divergence_prompt(PROTOTYPE_ROOT)
  assert "forced divergence" in text.lower() or "forced-divergence" in text.lower()
  assert "fix-negation" in text
  paragraphs = [p.strip() for p in text.split("\n\n") if p.strip()]
  assert len(paragraphs) == 3


def test_load_fatal_patterns_returns_8_enum(orchestrator_module):
  patterns = orchestrator_module.load_fatal_patterns(PROTOTYPE_ROOT)
  assert isinstance(patterns, list)
  assert len(patterns) == 8


def test_load_seed_patterns_returns_version_and_entries(orchestrator_module):
  data = orchestrator_module.load_seed_patterns(PROTOTYPE_ROOT)
  assert "version" in data
  assert "patterns" in data or "primary_groups" in data or "primary_group" in data or "patterns_by_primary_group" in data


# ---------- Task 6.2: 5 重検査 logic ----------

def test_step_1b_5_layer_checklist_returns_5_layers(orchestrator_module):
  _, layer2 = orchestrator_module.load_frameworks(PROTOTYPE_ROOT)
  layers = orchestrator_module.step_1b_5_layer_checklist(layer2)
  assert isinstance(layers, list)
  assert len(layers) == 5
  # 5 layers: 二重逆算 / Phase 1 patterns / dev-log patterns / 自己診断 / 内部論理整合
  joined = " ".join(layers).lower()
  assert "phase 1" in joined or "phase1" in joined
  assert "dev-log" in joined or "dev_log" in joined or "seed_pattern" in joined or "extracted_pattern" in joined


# ---------- treatment 3 系統 切替 ----------

def test_treatment_step_skip_logic_single(orchestrator_module):
  result = orchestrator_module.treatment_step_skip_logic("single")
  assert result["step_b"] is True  # skip
  assert result["step_c"] is True  # skip


def test_treatment_step_skip_logic_dual(orchestrator_module):
  result = orchestrator_module.treatment_step_skip_logic("dual")
  assert result["step_b"] is False  # exec
  assert result["step_c"] is True   # skip


def test_treatment_step_skip_logic_dual_judgment(orchestrator_module):
  result = orchestrator_module.treatment_step_skip_logic("dual+judgment")
  assert result["step_b"] is False  # exec
  assert result["step_c"] is False  # exec


def test_treatment_step_skip_logic_invalid_raises(orchestrator_module):
  with pytest.raises(ValueError):
    orchestrator_module.treatment_step_skip_logic("invalid_treatment")


# ---------- adversarial counter_evidence decompose ----------

def test_decompose_counter_evidence_by_issue_id(orchestrator_module):
  adversarial_yaml = yaml.safe_dump({
    "findings": [{"issue_id": "A-1"}, {"issue_id": "A-2"}],
    "counter_evidence": [
      {"issue_id": "A-1", "argument": "this might not be necessary because X"},
      {"issue_id": "A-2", "argument": "this might not be necessary because Y"},
    ],
  })
  result = orchestrator_module.decompose_counter_evidence(adversarial_yaml)
  assert "A-1" in result
  assert "A-2" in result
  assert "X" in result["A-1"]
  assert "Y" in result["A-2"]
