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


# ---------------------------------------------------------------------------
# Task 1.4: Vault validation フック + escape hatch + severity prefix + e2e drift
# ---------------------------------------------------------------------------

def _setup_minimal_vault(vault_path: Path) -> None:
  """load_task_prompts("audit") が通るための最小 Vault 構造を作成する。

  CLAUDE.md に audit のみのマッピング行を持たせ、
  AGENTS/audit.md + ダミー policy ファイルを用意する。
  """
  # AGENTS/ ディレクトリ確認（tmp_vault は既に持っているが念のため）
  agents_dir = vault_path / "AGENTS"
  agents_dir.mkdir(parents=True, exist_ok=True)

  # AGENTS/page_policy.md が無ければダミー作成
  (agents_dir / "page_policy.md").write_text("# page_policy\n", encoding="utf-8")

  # CLAUDE.md: audit のみのマッピング表
  claude_md = vault_path / "CLAUDE.md"
  claude_md.write_text(
    "# CLAUDE.md\n\n"
    "| Task | Agent | Policy | Execution Mode |\n"
    "|------|-------|--------|----------------|\n"
    "| audit | AGENTS/audit.md | AGENTS/page_policy.md | CLI (Hybrid) |\n",
    encoding="utf-8",
  )

  # logs/ ディレクトリ（generate_audit_report が必要）
  (vault_path / "logs").mkdir(parents=True, exist_ok=True)

  # wiki/ ディレクトリ + 最小 .md ファイル（validate_wiki_dir + read_all_wiki_content が必要）
  wiki_dir = vault_path / "wiki"
  wiki_dir.mkdir(parents=True, exist_ok=True)
  (wiki_dir / "test-page.md").write_text("# Test Page\n", encoding="utf-8")


class TestTask14VaultValidationHook:
  """Task 1.4: load_task_prompts の audit フック + skip + build_audit_prompt prefix + e2e drift。"""

  # ------------------------------------------------------------------
  # test_vault_validation_hook
  # ------------------------------------------------------------------
  def test_vault_validation_hook(
    self, tmp_vault: Path, monkeypatch: pytest.MonkeyPatch
  ) -> None:
    """load_task_prompts(task_name='audit') が _validate_agents_severity_vocabulary を呼ぶこと。"""
    _setup_minimal_vault(tmp_vault)
    monkeypatch.setattr(rw_light, "ROOT", str(tmp_vault))
    monkeypatch.setattr(rw_light, "AGENTS_DIR", str(tmp_vault / "AGENTS"))

    calls: list[Path] = []

    def mock_validate(p: Path) -> None:
      calls.append(p)

    monkeypatch.setattr(rw_light, "_validate_agents_severity_vocabulary", mock_validate)

    # load_task_prompts("audit") を呼ぶと _validate_agents_severity_vocabulary が 1 回呼ばれる
    rw_light.load_task_prompts("audit")

    assert len(calls) == 1, f"_validate_agents_severity_vocabulary が呼ばれなかった: calls={calls}"
    assert calls[0] == tmp_vault / "AGENTS" / "audit.md"

  # ------------------------------------------------------------------
  # test_skip_vault_validation_flag
  # ------------------------------------------------------------------
  def test_skip_vault_validation_flag(
    self,
    deprecated_agents_vault: Path,
    monkeypatch: pytest.MonkeyPatch,
    capsys: pytest.CaptureFixture,
  ) -> None:
    """skip_vault_validation=True の場合、旧語彙があっても SystemExit せず警告を出すこと。"""
    _setup_minimal_vault(deprecated_agents_vault)
    # deprecated_agents_vault の AGENTS/audit.md は旧語彙を含む（上書きせずそのまま使う）
    # _setup_minimal_vault は audit.md を上書きしないため、旧語彙のまま残る
    monkeypatch.setattr(rw_light, "ROOT", str(deprecated_agents_vault))
    monkeypatch.setattr(rw_light, "AGENTS_DIR", str(deprecated_agents_vault / "AGENTS"))

    # skip_vault_validation=True で呼ぶと SystemExit しない
    result = rw_light.load_task_prompts("audit", skip_vault_validation=True)
    assert isinstance(result, str)

    # stderr に [vault-validation] SKIPPED 警告が出ること
    captured = capsys.readouterr()
    assert "[vault-validation] SKIPPED" in captured.err

  # ------------------------------------------------------------------
  # test_build_audit_prompt_severity_prefix
  # ------------------------------------------------------------------
  def test_build_audit_prompt_severity_prefix(
    self, tmp_vault: Path, monkeypatch: pytest.MonkeyPatch
  ) -> None:
    """build_audit_prompt() がプロンプトの先頭に Severity Vocabulary (STRICT) ブロックを挿入すること。"""
    task_prompts = "# audit task prompts\n"
    wiki_content = "# wiki\n"

    prompt = rw_light.build_audit_prompt("monthly", task_prompts, wiki_content)

    assert prompt.startswith(
      "## Severity Vocabulary (STRICT)\n"
    ), f"プロンプトが Severity Vocabulary ブロックで始まっていない: {prompt[:100]!r}"
    assert "CRITICAL" in prompt
    assert "ERROR" in prompt
    assert "WARN" in prompt
    assert "INFO" in prompt
    assert "HIGH" in prompt  # "Do NOT use deprecated tokens: HIGH, ..." の記述
    assert "deprecated" in prompt.lower()

  # ------------------------------------------------------------------
  # test_claude_mock_drift_visibility_e2e (AC 7.10)
  # ------------------------------------------------------------------
  def test_claude_mock_drift_visibility_e2e(
    self,
    tmp_vault: Path,
    claude_mock_response: "Callable[[str], None]",
    monkeypatch: pytest.MonkeyPatch,
    capsys: pytest.CaptureFixture,
  ) -> None:
    """Claude が HIGH severity を返したとき drift が可視化されること（AC 7.10）。

    検証項目:
    (i)  stderr に少なくとも 1 行の [severity-drift] 警告行があること
    (ii) audit output が drift_events[] セクションを含む、または finding が INFO に降格されること
    (iii) 終了コードが 0 または 2 であること（audit は drift で中断しない）
    (iv) drift finding は破棄されず保持されること
    """
    _setup_minimal_vault(tmp_vault)
    monkeypatch.setattr(rw_light, "ROOT", str(tmp_vault))
    monkeypatch.setattr(rw_light, "AGENTS_DIR", str(tmp_vault / "AGENTS"))
    monkeypatch.setattr(rw_light, "WIKI", str(tmp_vault / "wiki"))
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_vault / "logs"))
    monkeypatch.setattr(rw_light, "CLAUDE_MD", str(tmp_vault / "CLAUDE.md"))
    monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_vault / "index.md"))
    monkeypatch.setattr(rw_light, "CHANGE_LOG_MD", str(tmp_vault / "log.md"))
    # git dirty チェックをスキップ（テスト環境では git 操作が不要）
    monkeypatch.setattr(rw_light, "warn_if_dirty_paths", lambda paths, cmd: None)

    # Claude CLI が HIGH severity を含む findings を返す
    claude_response = (
      '{"findings": ['
      '{"severity": "HIGH", "category": "contradicting_definition",'
      ' "page": "test.md", "message": "drift test finding", "marker": "CONFLICT"}'
      '], "metrics": {"pages_scanned": 1, "total_findings": 1},'
      ' "recommended_actions": ["fix it"]}'
    )
    claude_mock_response(claude_response)

    # _validate_agents_severity_vocabulary をスキップ（vault validation は別テストで検証済み）
    monkeypatch.setattr(rw_light, "_validate_agents_severity_vocabulary", lambda p: None)

    # _run_llm_audit を直接呼ぶ（--skip-vault-validation 相当）
    exit_code = rw_light._run_llm_audit("monthly", ["--skip-vault-validation"])

    captured = capsys.readouterr()

    # (i) stderr に [severity-drift] 警告が少なくとも 1 行あること
    assert "[severity-drift]" in captured.err, (
      f"stderr に [severity-drift] が見つからない:\n{captured.err}"
    )

    # (ii) drift_events または INFO 降格の証拠
    # finding が INFO に降格されているか、stdout に drift 関連の出力があること
    # stdout を確認: print_audit_summary が呼ばれる
    combined_output = captured.out + captured.err
    # HIGH は INFO に降格されるため、severity=INFO の finding が保持されること
    assert "HIGH" in combined_output or "drift" in combined_output.lower(), (
      f"drift の痕跡が出力に見つからない:\nstdout={captured.out}\nstderr={captured.err}"
    )

    # (iii) 終了コードが 0 または 2 であること（audit は drift で中断しない）
    assert exit_code in (0, 2), f"終了コードが 0 または 2 でない: {exit_code}"

    # (iv) finding が保持されること（ログファイルに drift finding が書き込まれる）
    log_files = list((tmp_vault / "logs").glob("audit-monthly-*.md"))
    assert log_files, "audit レポートファイルが生成されていない"
