"""Task 1.3: _validate_agents_severity_vocabulary helper の TDD テスト。

8 ケースをカバーする:
  (a) 新語彙のみの AGENTS/audit.md → PASS（None 返却）
  (b) Pattern A（テーブルセル `| HIGH |` 等）検出 → SystemExit(1) + error message
  (c) Pattern B（サマリーキー `- high:` 等、行頭限定）検出 → SystemExit(1) + error message
  (d) Pattern C（ファインディングブラケット `[HIGH]` 等）検出 → SystemExit(1) + error message
  (e) Pattern A/B/C 混在時 → 全パターン列挙した error message + SystemExit(1)
  (f) Migration Notes ブロック内の旧語彙は除外（PASS）
  (g) 1 MB 超えファイルは SystemExit(1) + error message
  (h) symlink 先が vault-root 外 → SystemExit(1) + `[vault-validation] path escape detected` stderr
"""
import os
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))

import rw_light


# ---------------------------------------------------------------------------
# ヘルパー: AGENTS/audit.md を作成する
# ---------------------------------------------------------------------------

def make_agents_audit_md(vault_path: Path, content: str) -> Path:
  """vault_path/AGENTS/audit.md を作成して Path を返す。"""
  agents_dir = vault_path / "AGENTS"
  agents_dir.mkdir(parents=True, exist_ok=True)
  audit_md = agents_dir / "audit.md"
  audit_md.write_text(content, encoding="utf-8")
  return audit_md


# ---------------------------------------------------------------------------
# test_vault_vocabulary_validation: 8 ケース (a)–(h)
# ---------------------------------------------------------------------------

class TestVaultVocabularyValidation:
  """_validate_agents_severity_vocabulary の正常・異常系をすべて検証。"""

  # ------------------------------------------------------------------
  # (a) 新語彙のみ → PASS
  # ------------------------------------------------------------------
  def test_a_new_vocabulary_only_passes(self, tmp_path: Path) -> None:
    """新 4 水準（CRITICAL/ERROR/WARN/INFO）のみ含む AGENTS/audit.md → None 返却。"""
    content = """\
# AGENTS/audit.md

## Summary
- critical: 0
- error: 0
- warn: 0
- info: 0

## Findings
- [CRITICAL] System integrity broken
- [ERROR] Broken link
- [WARN] Orphan page
- [INFO] Missing tag

## Severity Table
| Level    | Meaning             |
|----------|---------------------|
| CRITICAL | Breaks integrity    |
| ERROR    | Reliability issue   |
| WARN     | Quality signal      |
| INFO     | Suggestion          |
"""
    audit_md = make_agents_audit_md(tmp_path, content)
    # _validate_agents_severity_vocabulary が存在し、新語彙のみで None を返す
    result = rw_light._validate_agents_severity_vocabulary(audit_md)
    assert result is None

  # ------------------------------------------------------------------
  # (b) Pattern A（テーブルセル）検出 → SystemExit(1)
  # ------------------------------------------------------------------
  def test_b_pattern_a_table_cell_detected(
    self, tmp_path: Path, capsys: pytest.CaptureFixture
  ) -> None:
    """Pattern A: `| HIGH |` がテーブルセルに出現 → SystemExit(1) + error message。"""
    content = """\
# AGENTS/audit.md

## Severity Table
| Level  | Meaning          |
|--------|------------------|
| HIGH   | Reliability issue|
| MEDIUM | Quality signal   |
"""
    audit_md = make_agents_audit_md(tmp_path, content)
    with pytest.raises(SystemExit) as exc_info:
      rw_light._validate_agents_severity_vocabulary(audit_md)
    assert exc_info.value.code == 1
    captured = capsys.readouterr()
    assert "[agents-vocab-error]" in captured.err
    assert "deprecated severity vocabulary" in captured.err
    # line 番号・pattern_id・violation count を含む
    assert "line " in captured.err
    assert "pattern_A" in captured.err
    assert "violation" in captured.err

  # ------------------------------------------------------------------
  # (c) Pattern B（サマリーキー、行頭）検出 → SystemExit(1)
  # ------------------------------------------------------------------
  def test_c_pattern_b_summary_key_detected(
    self, tmp_path: Path, capsys: pytest.CaptureFixture
  ) -> None:
    """Pattern B: `- high:` がサマリーフィールドに出現 → SystemExit(1) + error message。"""
    content = """\
# AGENTS/audit.md

## Summary
- high: 2
- medium: 1
- low: 0
"""
    audit_md = make_agents_audit_md(tmp_path, content)
    with pytest.raises(SystemExit) as exc_info:
      rw_light._validate_agents_severity_vocabulary(audit_md)
    assert exc_info.value.code == 1
    captured = capsys.readouterr()
    assert "[agents-vocab-error]" in captured.err
    assert "pattern_B" in captured.err
    assert "violation" in captured.err

  # ------------------------------------------------------------------
  # (d) Pattern C（ファインディングブラケット）検出 → SystemExit(1)
  # ------------------------------------------------------------------
  def test_d_pattern_c_bracket_detected(
    self, tmp_path: Path, capsys: pytest.CaptureFixture
  ) -> None:
    """Pattern C: `[HIGH]` ブラケットが出現 → SystemExit(1) + error message。"""
    content = """\
# AGENTS/audit.md

## Findings
- [HIGH] Broken link detected: [[missing-page]]
- [MEDIUM] Orphan page: orphan.md
"""
    audit_md = make_agents_audit_md(tmp_path, content)
    with pytest.raises(SystemExit) as exc_info:
      rw_light._validate_agents_severity_vocabulary(audit_md)
    assert exc_info.value.code == 1
    captured = capsys.readouterr()
    assert "[agents-vocab-error]" in captured.err
    assert "pattern_C" in captured.err
    assert "violation" in captured.err

  # ------------------------------------------------------------------
  # (e) Pattern A/B/C 混在 → 全パターン列挙 + violation count
  # ------------------------------------------------------------------
  def test_e_mixed_patterns_all_listed(
    self, tmp_path: Path, capsys: pytest.CaptureFixture
  ) -> None:
    """Pattern A/B/C が同一ファイルに混在 → 全パターン列挙した error message。"""
    content = """\
# AGENTS/audit.md

## Summary
- high: 1
- medium: 0
- low: 0

## Findings
- [HIGH] Some finding
- [LOW] Minor issue

## Table
| Level | Meaning |
|-------|---------|
| HIGH  | Bad     |
"""
    audit_md = make_agents_audit_md(tmp_path, content)
    with pytest.raises(SystemExit) as exc_info:
      rw_light._validate_agents_severity_vocabulary(audit_md)
    assert exc_info.value.code == 1
    captured = capsys.readouterr()
    err = captured.err
    assert "[agents-vocab-error]" in err
    # 全パターンが列挙される
    assert "pattern_A" in err
    assert "pattern_B" in err
    assert "pattern_C" in err
    # violation count が複数
    import re
    m = re.search(r"detected (\d+) violation", err)
    assert m is not None
    assert int(m.group(1)) >= 3

  # ------------------------------------------------------------------
  # (f) Migration Notes ブロック内の旧語彙は除外 → PASS
  # ------------------------------------------------------------------
  def test_f_migration_notes_block_excluded(self, tmp_path: Path) -> None:
    """Migration Notes ブロック内の旧語彙は検出対象外 → None 返却。"""
    content = """\
# AGENTS/audit.md

## Summary
- critical: 0
- error: 0

<!-- severity-vocab: legacy-reference -->
## Legacy Reference (do not use)
- high: 0
- [HIGH] Old finding
| HIGH | Old level |
<!-- /severity-vocab -->

## Active Findings
- [CRITICAL] Real issue
"""
    audit_md = make_agents_audit_md(tmp_path, content)
    result = rw_light._validate_agents_severity_vocabulary(audit_md)
    assert result is None

  # ------------------------------------------------------------------
  # (g) 1 MB 超えファイル → SystemExit(1) + error message
  # ------------------------------------------------------------------
  def test_g_large_file_raises(
    self, tmp_path: Path, capsys: pytest.CaptureFixture
  ) -> None:
    """1 MB 超えファイルは SystemExit(1) + error message を出力する。"""
    agents_dir = tmp_path / "AGENTS"
    agents_dir.mkdir(parents=True, exist_ok=True)
    audit_md = agents_dir / "audit.md"
    # 1 MB + 1 byte のファイルを作成
    audit_md.write_bytes(b"x" * (1024 * 1024 + 1))
    with pytest.raises(SystemExit) as exc_info:
      rw_light._validate_agents_severity_vocabulary(audit_md)
    assert exc_info.value.code == 1
    captured = capsys.readouterr()
    assert captured.err  # エラーメッセージが stderr に出力される

  # ------------------------------------------------------------------
  # (h) symlink 先が vault-root 外 → SystemExit(1) + path escape detected
  # ------------------------------------------------------------------
  def test_h_symlink_escape_detected(
    self, tmp_path: Path, capsys: pytest.CaptureFixture
  ) -> None:
    """symlink 先が vault-root 外 → SystemExit(1) + `[vault-validation] path escape detected`。"""
    vault_dir = tmp_path / "vault"
    agents_dir = vault_dir / "AGENTS"
    agents_dir.mkdir(parents=True, exist_ok=True)

    # vault 外のファイル
    outside_dir = tmp_path / "outside"
    outside_dir.mkdir(parents=True, exist_ok=True)
    outside_file = outside_dir / "evil.md"
    outside_file.write_text("# Outside\n- high: 0\n", encoding="utf-8")

    # symlink: vault/AGENTS/audit.md → outside/evil.md
    symlink_path = agents_dir / "audit.md"
    symlink_path.symlink_to(outside_file)

    with pytest.raises(SystemExit) as exc_info:
      rw_light._validate_agents_severity_vocabulary(symlink_path)
    assert exc_info.value.code == 1
    captured = capsys.readouterr()
    assert "[vault-validation] path escape detected" in captured.err
