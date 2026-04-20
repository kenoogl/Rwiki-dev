"""Tests for cmd_synthesize_logs — Task 2.6"""
import os
from pathlib import Path
import pytest

import rw_light
import rw_prompt_engine
import rw_utils


MOCK_JSON = (
  '{"topics": [{"title": "Test Topic", "summary": "要約", "decision": "判断",'
  ' "reason": "理由", "alternatives": "代替案", "reusable_pattern": "パターン",'
  ' "tags": ["test"]}]}'
)


def mock_claude_ok(log_path):
  return MOCK_JSON


class TestCmdSynthesizeLogs:

  def test_candidate_file_created(
    self, patch_constants, make_md_file, fixed_today, monkeypatch
  ):
    """Req 6.1: llm_logs/ の .md ファイルから synthesis_candidates/ に候補ファイルが生成される"""
    monkeypatch.setattr(rw_utils, "git_path_is_dirty", lambda *args, **kwargs: False)
    monkeypatch.setattr(rw_prompt_engine, "call_claude_for_log_synthesis", mock_claude_ok)

    vault = patch_constants
    make_md_file(
      vault / "raw" / "llm_logs" / "sample.md",
      {"title": "Sample Log"},
      "Some log content here.",
    )

    rw_light.cmd_synthesize_logs()

    candidates = list((vault / "review" / "synthesis_candidates").glob("*.md"))
    assert len(candidates) == 1, f"Expected 1 candidate, got {len(candidates)}"

  def test_empty_llm_logs(self, patch_constants, monkeypatch, capsys):
    """Req 6.2: llm_logs/ が空の場合、exit 0 で候補ファイルなし"""
    monkeypatch.setattr(rw_utils, "git_path_is_dirty", lambda *args, **kwargs: False)

    vault = patch_constants
    result = rw_light.cmd_synthesize_logs()

    assert result == 0
    candidates = list((vault / "review" / "synthesis_candidates").glob("*.md"))
    assert len(candidates) == 0

  def test_log_md_updated(
    self, patch_constants, make_md_file, fixed_today, monkeypatch
  ):
    """Req 6.3: 候補生成後に CHANGE_LOG_MD にエントリが存在する"""
    monkeypatch.setattr(rw_utils, "git_path_is_dirty", lambda *args, **kwargs: False)
    monkeypatch.setattr(rw_prompt_engine, "call_claude_for_log_synthesis", mock_claude_ok)

    vault = patch_constants
    make_md_file(
      vault / "raw" / "llm_logs" / "sample.md",
      {"title": "Sample Log"},
      "Some log content here.",
    )

    rw_light.cmd_synthesize_logs()

    log_md = vault / "log.md"
    assert log_md.exists(), "log.md が生成されていない"
    content = log_md.read_text(encoding="utf-8")
    assert "synthesis candidate generated" in content

  def test_candidate_frontmatter(
    self, patch_constants, make_md_file, fixed_today, monkeypatch
  ):
    """Req 6.4: 候補ファイルに必要なフロントマターが含まれる"""
    monkeypatch.setattr(rw_utils, "git_path_is_dirty", lambda *args, **kwargs: False)
    monkeypatch.setattr(rw_prompt_engine, "call_claude_for_log_synthesis", mock_claude_ok)

    vault = patch_constants
    make_md_file(
      vault / "raw" / "llm_logs" / "sample.md",
      {"title": "Sample Log"},
      "Some log content here.",
    )

    rw_light.cmd_synthesize_logs()

    candidates = list((vault / "review" / "synthesis_candidates").glob("*.md"))
    assert len(candidates) == 1
    content = candidates[0].read_text(encoding="utf-8")

    assert "title:" in content
    assert "source:" in content
    assert "synthesis_candidate" in content
    assert "pending" in content
    assert "2025-01-15" in content

  def test_error_continues_processing(
    self, patch_constants, make_md_file, fixed_today, monkeypatch, capsys
  ):
    """Req 6.5: エラーが発生しても次ファイルの処理を継続する（Exception と invalid JSON の 2 パターン）"""
    monkeypatch.setattr(rw_utils, "git_path_is_dirty", lambda *args, **kwargs: False)

    vault = patch_constants
    # 2 ファイル配置（アルファベット順で 1 番目がエラーになるよう命名）
    make_md_file(
      vault / "raw" / "llm_logs" / "a_first.md",
      {"title": "First Log"},
      "First log content.",
    )
    make_md_file(
      vault / "raw" / "llm_logs" / "b_second.md",
      {"title": "Second Log"},
      "Second log content.",
    )

    # パターン 1: Exception 送出
    call_count = {"n": 0}

    def mock_raise_then_ok(log_path):
      call_count["n"] += 1
      if call_count["n"] == 1:
        raise Exception("synthesis error")
      return MOCK_JSON

    monkeypatch.setattr(rw_prompt_engine, "call_claude_for_log_synthesis", mock_raise_then_ok)

    rw_light.cmd_synthesize_logs()
    captured = capsys.readouterr()

    assert "[FAIL]" in captured.out
    assert "[READ]" in captured.out
    assert call_count["n"] == 2  # 2 ファイルとも処理された

    # パターン 2: invalid JSON 返却
    call_count2 = {"n": 0}

    def mock_invalid_then_ok(log_path):
      call_count2["n"] += 1
      if call_count2["n"] == 1:
        return "invalid json"
      return MOCK_JSON

    # 候補ファイルを削除してリセット
    for f in (vault / "review" / "synthesis_candidates").glob("*.md"):
      f.unlink()

    monkeypatch.setattr(rw_prompt_engine, "call_claude_for_log_synthesis", mock_invalid_then_ok)

    rw_light.cmd_synthesize_logs()
    captured2 = capsys.readouterr()

    assert "[FAIL]" in captured2.out
    assert call_count2["n"] == 2

  def test_exit_code_all_fail(
    self, patch_constants, make_md_file, monkeypatch
  ):
    """Req 6.6: 全ファイルが FAIL でも exit 0"""
    monkeypatch.setattr(rw_utils, "git_path_is_dirty", lambda *args, **kwargs: False)
    monkeypatch.setattr(
      rw_prompt_engine,
      "call_claude_for_log_synthesis",
      lambda p: (_ for _ in ()).throw(Exception("always fails")),
    )

    vault = patch_constants
    make_md_file(
      vault / "raw" / "llm_logs" / "sample.md",
      {"title": "Sample Log"},
      "Some log content.",
    )

    result = rw_light.cmd_synthesize_logs()
    assert result == 0

  def test_skip_existing_candidate(
    self, patch_constants, make_md_file, fixed_today, monkeypatch, capsys
  ):
    """Req 6.7: synthesis_candidates/ に同名ファイルが存在する場合スキップ"""
    monkeypatch.setattr(rw_utils, "git_path_is_dirty", lambda *args, **kwargs: False)
    monkeypatch.setattr(rw_prompt_engine, "call_claude_for_log_synthesis", mock_claude_ok)

    vault = patch_constants
    make_md_file(
      vault / "raw" / "llm_logs" / "sample.md",
      {"title": "Sample Log"},
      "Some log content.",
    )

    # "Test Topic" → slugify → "test-topic"
    existing_path = vault / "review" / "synthesis_candidates" / "test-topic.md"
    original_content = "# existing content\nDo not overwrite."
    existing_path.write_text(original_content, encoding="utf-8")

    rw_light.cmd_synthesize_logs()
    captured = capsys.readouterr()

    assert "[SKIP]" in captured.out
    # 既存ファイルの内容が変わっていない
    assert existing_path.read_text(encoding="utf-8") == original_content

  def test_dirty_warning(self, patch_constants, monkeypatch, capsys):
    """Req 6.8: git_path_is_dirty が True のとき [WARN] が出力される"""
    monkeypatch.setattr(rw_utils, "git_path_is_dirty", lambda *args, **kwargs: True)

    rw_light.cmd_synthesize_logs()
    captured = capsys.readouterr()

    assert "[WARN]" in captured.out

  def test_slug_collision_within_response(
    self, patch_constants, make_md_file, fixed_today, monkeypatch
  ):
    """False confidence 防止: slug 衝突時は 1 つ目が作成され 2 つ目がスキップされる"""
    monkeypatch.setattr(rw_utils, "git_path_is_dirty", lambda *args, **kwargs: False)

    collision_json = (
      '{"topics": ['
      '{"title": "Python Guide", "summary": "s1", "decision": "d1",'
      ' "reason": "r1", "alternatives": "a1", "reusable_pattern": "p1", "tags": []},'
      '{"title": "Python: Guide!", "summary": "s2", "decision": "d2",'
      ' "reason": "r2", "alternatives": "a2", "reusable_pattern": "p2", "tags": []}'
      "]}"
    )
    monkeypatch.setattr(
      rw_prompt_engine, "call_claude_for_log_synthesis", lambda p: collision_json
    )

    vault = patch_constants
    make_md_file(
      vault / "raw" / "llm_logs" / "sample.md",
      {"title": "Sample Log"},
      "Some log content.",
    )

    rw_light.cmd_synthesize_logs()

    candidates = list((vault / "review" / "synthesis_candidates").glob("*.md"))
    assert len(candidates) == 1, (
      f"slug 衝突で 1 ファイルのみ生成されるべきだが {len(candidates)} ファイルが存在する"
    )
