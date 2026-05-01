# Task 7.2: Foundation install location relative path resolution test
# 3 skill helper script が ./patterns/ + ./prompts/ + ./schemas/ + ./framework/ + ./extensions/design_extension.yaml
# を全 locate 可能、hardcode なし確認 (--dual-reviewer-root CLI arg + DUAL_REVIEWER_ROOT env fallback)

import os
import sys
import subprocess
from pathlib import Path

import pytest

PROTOTYPE_ROOT = Path(__file__).resolve().parents[4]
DR_DESIGN_DIR = PROTOTYPE_ROOT / "skills" / "dr-design"
DR_JUDGMENT_DIR = PROTOTYPE_ROOT / "skills" / "dr-judgment"
DR_LOG_DIR = PROTOTYPE_ROOT / "skills" / "dr-log"


def test_dr_design_orchestrator_locates_all_5_artifacts():
  """orchestrator が patterns/ + prompts/ + schemas/ + framework/ + extensions/ 5 配置全 locate"""
  sys.path.insert(0, str(DR_DESIGN_DIR))
  import orchestrator
  try:
    layer1, layer2 = orchestrator.load_frameworks(PROTOTYPE_ROOT)  # framework/ + extensions/
    fatal = orchestrator.load_fatal_patterns(PROTOTYPE_ROOT)        # patterns/fatal_patterns.yaml
    seed = orchestrator.load_seed_patterns(PROTOTYPE_ROOT)          # patterns/seed_patterns.yaml
    prompt = orchestrator.load_forced_divergence_prompt(PROTOTYPE_ROOT)  # prompts/
    assert layer1 and layer2 and fatal and seed and prompt
  finally:
    sys.path.remove(str(DR_DESIGN_DIR))


def test_dr_judgment_dispatcher_locates_prompt_and_schema():
  """judgment_dispatcher が prompts/judgment_subagent_prompt.txt + schemas/necessity_judgment.schema.json locate"""
  sys.path.insert(0, str(DR_JUDGMENT_DIR))
  import judgment_dispatcher
  try:
    prompt = judgment_dispatcher.load_judgment_prompt(PROTOTYPE_ROOT)
    assert "judgment-only subagent" in prompt
  finally:
    sys.path.remove(str(DR_JUDGMENT_DIR))


def test_dr_log_writer_locates_5_schemas():
  """log_writer が schemas/ 配下 5 schema 全 locate"""
  sys.path.insert(0, str(DR_LOG_DIR))
  import log_writer
  try:
    w = log_writer.LogWriter(PROTOTYPE_ROOT / "schemas")
    # 5 schemas loaded
    assert len(w._schemas) == 5
  finally:
    sys.path.remove(str(DR_LOG_DIR))


def test_resolve_foundation_path_with_explicit_root():
  """resolve_foundation_path が ./ prefix relative path を absolute path に解決"""
  sys.path.insert(0, str(DR_DESIGN_DIR))
  import orchestrator
  try:
    p = orchestrator.resolve_foundation_path(PROTOTYPE_ROOT, "./patterns/fatal_patterns.yaml")
    assert p == PROTOTYPE_ROOT / "patterns" / "fatal_patterns.yaml"
    assert p.is_file()
  finally:
    sys.path.remove(str(DR_DESIGN_DIR))


def test_no_hardcoded_absolute_path_in_helpers():
  """3 skill helper script は absolute path hardcode しない (起動時 CLI arg or env)"""
  for helper_path in [
    DR_DESIGN_DIR / "orchestrator.py",
    DR_JUDGMENT_DIR / "judgment_dispatcher.py",
    DR_LOG_DIR / "log_writer.py",
  ]:
    text = helper_path.read_text(encoding="utf-8")
    # /Users/ や /home/ などの absolute root prefix が helper script 内に hardcode されていないこと
    assert "/Users/" not in text, f"{helper_path} contains hardcoded /Users/"
    assert "/home/" not in text, f"{helper_path} contains hardcoded /home/"
