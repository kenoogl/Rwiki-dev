# Task 7.4: 修正否定試行 prompt vs forced_divergence prompt 役割分離 test
# judgment subagent prompt (foundation) = 修正否定試行 (= V4 §5.2 fix-negation、修正 proposal 必要性否定)
# adversarial subagent dispatch payload = forced_divergence (= 結論成立性試行、暗黙前提別前提置換) + V4 §1.5 fix-negation 3 行 (judgment 用とは別)
# 2 prompt content が別物 + 役割分離 keyword presence

from pathlib import Path

import pytest

PROTOTYPE_ROOT = Path(__file__).resolve().parents[4]
JUDGMENT_PROMPT = PROTOTYPE_ROOT / "prompts" / "judgment_subagent_prompt.txt"
FORCED_DIVERGENCE_PROMPT = PROTOTYPE_ROOT / "prompts" / "forced_divergence_prompt.txt"
DR_DESIGN_SKILL_MD = PROTOTYPE_ROOT / "skills" / "dr-design" / "SKILL.md"


def test_judgment_prompt_is_distinct_from_forced_divergence_prompt():
  """2 prompt content が別物 (= byte-level 異なる)"""
  judgment = JUDGMENT_PROMPT.read_text(encoding="utf-8")
  forced = FORCED_DIVERGENCE_PROMPT.read_text(encoding="utf-8")
  assert judgment != forced


def test_judgment_prompt_mentions_fix_negation_for_judgment_role():
  """judgment prompt は judgment 用 fix-negation (修正必要性否定) role を担う

  judgment prompt は 5 fields 評価 + 5 rules + override_reason の judgment-only 観点。
  "fix-negation" keyword は本 prompt 自体には含まれないが、「Apply 5 judgment rules」+「override defaults」
  の組合せが修正必要性否定の judgment 観点を表現。
  """
  text = JUDGMENT_PROMPT.read_text(encoding="utf-8")
  assert "judgment-only subagent" in text
  assert "5 judgment rules in order" in text
  # judgment 用 = 5 条件評価 = uncertainty=high → escalate
  assert "uncertainty=high" in text


def test_forced_divergence_prompt_mentions_conclusion_validity_not_fix_necessity():
  """forced_divergence prompt は結論成立性試行 (= primary's conclusions の validity 試行) role を担う"""
  text = FORCED_DIVERGENCE_PROMPT.read_text(encoding="utf-8")
  assert "forced divergence" in text.lower() or "forced-divergence" in text.lower()
  assert "validity of the conclusion" in text
  # 役割分離明示: "It is distinct from the fix-negation task assigned to the judgment subagent"
  assert "fix-negation" in text
  assert "judgment subagent" in text
  assert "distinct from" in text


def test_skill_md_wires_adversarial_payload_with_forced_divergence_and_v4_15():
  """dr-design SKILL.md で adversarial dispatch payload に forced_divergence + V4 §1.5 fix-negation 両方含むことを明示"""
  text = DR_DESIGN_SKILL_MD.read_text(encoding="utf-8")
  # adversarial section 内に両 prompt 言及
  assert "forced_divergence" in text.lower() or "forced divergence" in text.lower()
  assert "fix-negation" in text or "fix negation" in text.lower()
  # adversarial subagent dispatch payload 言及
  assert "adversarial subagent dispatch" in text.lower() or "adversarial review" in text.lower()
  # judgment skill invocation 別 step 言及 (= role 分離 wiring)
  assert "Step C" in text and "dr-judgment" in text


def test_skill_md_role_separation_explicit_keyword():
  """dr-design SKILL.md 内 役割分離 explicit mention (judgment vs adversarial)"""
  text = DR_DESIGN_SKILL_MD.read_text(encoding="utf-8")
  assert "役割分離" in text or "role separation" in text.lower() or "judgment_reviewer" in text or "別" in text
