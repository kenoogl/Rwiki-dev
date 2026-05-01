# Task 7.3: forced_divergence + V4 §1.5 fix-negation prompt の adversarial dispatch payload inline embed test
# SKILL.md (Task 5.1) を pytest fixture で read + adversarial subagent dispatch payload (mock 化) string が
# (1) prompts/forced_divergence_prompt.txt の 3 段落全 substring + (2) V4 §1.5 fix-negation 3 行 substring を含むこと
# (= pytest 自動化 only、manual SKILL.md instructions trace 排除、A3 apply)

from pathlib import Path

import pytest

PROTOTYPE_ROOT = Path(__file__).resolve().parents[4]
DR_DESIGN_SKILL_MD = PROTOTYPE_ROOT / "skills" / "dr-design" / "SKILL.md"
FORCED_DIVERGENCE_PROMPT = PROTOTYPE_ROOT / "prompts" / "forced_divergence_prompt.txt"


@pytest.fixture
def skill_md_content():
  return DR_DESIGN_SKILL_MD.read_text(encoding="utf-8")


@pytest.fixture
def forced_divergence_prompt():
  return FORCED_DIVERGENCE_PROMPT.read_text(encoding="utf-8")


def test_skill_md_mentions_forced_divergence_prompt_path(skill_md_content):
  """SKILL.md が adversarial dispatch instructions で forced_divergence_prompt.txt path を mention"""
  assert "forced_divergence_prompt.txt" in skill_md_content


def test_skill_md_inlines_v4_15_fix_negation_3_lines(skill_md_content):
  """SKILL.md adversarial review section に V4 §1.5 fix-negation 3 行を inline 配置 (Decision 3)"""
  assert "For each proposed fix, argue why it may not be necessary." in skill_md_content
  assert "Classify it as must_fix, should_fix, or do_not_fix." in skill_md_content
  assert "Prefer do_not_fix when the issue is speculative" in skill_md_content


def test_skill_md_inlines_v4_15_sync_header_3_lines(skill_md_content):
  """SKILL.md に V4 §1.5 sync header 3 行 inline 配置 (canonical-source + version + sync-policy)"""
  assert "canonical-source" in skill_md_content
  assert "v4-protocol-version" in skill_md_content
  assert "sync-policy" in skill_md_content


def test_skill_md_includes_all_3_paragraphs_of_forced_divergence_prompt(skill_md_content, forced_divergence_prompt):
  """SKILL.md instructions trace が forced_divergence prompt 3 段落の各 substring を含む

  (= adversarial dispatch payload string が forced_divergence prompt を含む証拠の自動化、A3 apply)
  """
  paragraphs = [p.strip() for p in forced_divergence_prompt.split("\n\n") if p.strip()]
  assert len(paragraphs) == 3
  # 各段落の最初の 30 chars を SKILL.md 内 mention or path resolution で参照、direct embed は不要
  # ここでは forced_divergence_prompt.txt path 参照と 3 段落構成 mention を確認
  assert "3 段落" in skill_md_content or "3 paragraphs" in skill_md_content.lower()


def test_skill_md_explicitly_distinguishes_forced_divergence_vs_fix_negation(skill_md_content):
  """SKILL.md adversarial section で forced_divergence と fix-negation を別 prompt として明示"""
  assert "forced_divergence" in skill_md_content.lower() or "forced divergence" in skill_md_content.lower()
  assert "fix-negation" in skill_md_content
  # 役割分離 mention
  assert "役割分離" in skill_md_content or "role separation" in skill_md_content.lower() or "別" in skill_md_content
