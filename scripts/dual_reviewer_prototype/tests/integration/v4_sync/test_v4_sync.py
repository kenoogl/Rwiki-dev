# Task 7.3: V4 §5.2 prompt sync byte-level diff test
# 本 spec 単独改変禁止 enforcement (= V4 protocol 改訂以外の本文変更が test fail で検出される)
import re
from pathlib import Path

PROTOTYPE_ROOT = Path(__file__).resolve().parents[3]
PROMPT_PATH = PROTOTYPE_ROOT / "prompts" / "judgment_subagent_prompt.txt"

# v4-protocol.md は repo root 配下に存在 (= prototype の 2 階層上 = Rwiki-dev/)
REPO_ROOT = PROTOTYPE_ROOT.parents[1]
V4_PROTOCOL = REPO_ROOT / ".kiro" / "methodology" / "v4-validation" / "v4-protocol.md"


def test_sync_header_3_lines_exact_match():
  lines = PROMPT_PATH.read_text().splitlines()
  expected = [
    "# canonical-source: .kiro/methodology/v4-validation/v4-protocol.md §5.2",
    "# v4-protocol-version: 0.3",
    "# sync-policy: byte-level integrity, manual sync at v4-protocol revision",
  ]
  assert lines[:3] == expected, f"sync header mismatch: {lines[:3]}"


def _extract_v4_section_5_2_body():
  content = V4_PROTOCOL.read_text()
  # `### §5.2` 見出しの後の最初の ``` ... ``` block を抽出
  m = re.search(r"### §5\.2.*?\n```\n(.*?)\n```", content, flags=re.DOTALL)
  assert m, "§5.2 prompt block not found in v4-protocol.md"
  return m.group(1)


def _normalize_whitespace(s):
  """空白 / 改行 normalize (Req 6.2: byte-level に整合 (minor 差異 = 空白 / 改行 を除き))"""
  return re.sub(r"\s+", " ", s).strip()


def test_prompt_body_byte_level_match_with_v4_protocol_5_2():
  v4_body = _extract_v4_section_5_2_body()
  prompt_lines = PROMPT_PATH.read_text().splitlines()
  prompt_body = "\n".join(prompt_lines[3:])  # header 3 行 skip

  v4_norm = _normalize_whitespace(v4_body)
  prompt_norm = _normalize_whitespace(prompt_body)

  assert v4_norm == prompt_norm, (
    f"prompt body diverged from v4-protocol.md §5.2 (whitespace-normalized).\n"
    f"v4 length={len(v4_norm)}, prompt length={len(prompt_norm)}"
  )


def test_prompt_body_contains_required_v4_5_2_features():
  """V4 §5.2 仕様準拠の必須 feature presence (必要性 5-field + semi-mechanical mapping default 7 種 + 5 条件判定ルール + 出力 yaml format 規約)"""
  body = "\n".join(PROMPT_PATH.read_text().splitlines()[3:])
  # 必要性 5-field
  for field in ["requirement_link", "ignored_impact", "fix_cost", "scope_expansion", "uncertainty"]:
    assert field in body, f"missing 5-field: {field}"
  # 5 条件判定ルール (5 rules in order)
  assert "5 judgment rules" in body or "judgment rules in order" in body
  # semi-mechanical mapping
  assert "semi-mechanical mapping" in body
  # 出力 yaml format
  assert "yaml" in body.lower()
  # fix_decision.label 言及
  assert "fix_decision" in body
