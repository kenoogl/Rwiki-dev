"""Tests for cmd_approve — Task 2.7"""
from pathlib import Path
import pytest

import rw_light
import rw_utils


APPROVED_META = {
  "status": "approved",
  "reviewed_by": "reviewer_name",
  "approved": "2025-01-15",
  "promoted": "false",
  "title": "Test Synthesis",
  "source": "test",
  "type": "synthesis_candidate",
}


class TestCmdApprove:

  def test_promotion_to_wiki(
    self, patch_constants, make_md_file, fixed_today, monkeypatch
  ):
    """Req 7.1: 承認済み候補が wiki/synthesis/ に type=synthesis で昇格される"""
    monkeypatch.setattr(rw_utils, "git_path_is_dirty", lambda *args, **kwargs: False)

    vault = patch_constants
    make_md_file(
      vault / "review" / "synthesis_candidates" / "test-synthesis.md",
      APPROVED_META,
      "# Test Synthesis\nContent here.",
    )

    rw_light.cmd_approve()

    wiki_files = list((vault / "wiki" / "synthesis").glob("*.md"))
    assert len(wiki_files) == 1, f"Expected 1 wiki file, got {len(wiki_files)}"
    content = wiki_files[0].read_text(encoding="utf-8")
    assert 'type: "synthesis"' in content

  def test_reject_wrong_status(
    self, patch_constants, make_md_file, fixed_today, monkeypatch
  ):
    """Req 7.2a: status が pending の候補は昇格されない"""
    monkeypatch.setattr(rw_utils, "git_path_is_dirty", lambda *args, **kwargs: False)

    vault = patch_constants
    meta = dict(APPROVED_META)
    meta["status"] = "pending"
    make_md_file(
      vault / "review" / "synthesis_candidates" / "test-synthesis.md",
      meta,
      "# Test Synthesis\nContent here.",
    )

    rw_light.cmd_approve()

    wiki_files = list((vault / "wiki" / "synthesis").glob("*.md"))
    assert len(wiki_files) == 0, f"Expected 0 wiki files, got {len(wiki_files)}"

  def test_reject_empty_reviewed_by(
    self, patch_constants, make_md_file, fixed_today, monkeypatch
  ):
    """Req 7.2b: reviewed_by が空の候補は昇格されない"""
    monkeypatch.setattr(rw_utils, "git_path_is_dirty", lambda *args, **kwargs: False)

    vault = patch_constants
    meta = dict(APPROVED_META)
    meta["reviewed_by"] = ""
    make_md_file(
      vault / "review" / "synthesis_candidates" / "test-synthesis.md",
      meta,
      "# Test Synthesis\nContent here.",
    )

    rw_light.cmd_approve()

    wiki_files = list((vault / "wiki" / "synthesis").glob("*.md"))
    assert len(wiki_files) == 0, f"Expected 0 wiki files, got {len(wiki_files)}"

  def test_reject_invalid_date(
    self, patch_constants, make_md_file, fixed_today, monkeypatch
  ):
    """Req 7.2c: approved が無効な日付の候補は昇格されない"""
    monkeypatch.setattr(rw_utils, "git_path_is_dirty", lambda *args, **kwargs: False)

    vault = patch_constants
    meta = dict(APPROVED_META)
    meta["approved"] = "not-a-date"
    make_md_file(
      vault / "review" / "synthesis_candidates" / "test-synthesis.md",
      meta,
      "# Test Synthesis\nContent here.",
    )

    rw_light.cmd_approve()

    wiki_files = list((vault / "wiki" / "synthesis").glob("*.md"))
    assert len(wiki_files) == 0, f"Expected 0 wiki files, got {len(wiki_files)}"

  def test_reject_already_promoted(
    self, patch_constants, make_md_file, fixed_today, monkeypatch
  ):
    """Req 7.2d: promoted が true の候補は昇格されない"""
    monkeypatch.setattr(rw_utils, "git_path_is_dirty", lambda *args, **kwargs: False)

    vault = patch_constants
    meta = dict(APPROVED_META)
    meta["promoted"] = "true"
    make_md_file(
      vault / "review" / "synthesis_candidates" / "test-synthesis.md",
      meta,
      "# Test Synthesis\nContent here.",
    )

    rw_light.cmd_approve()

    wiki_files = list((vault / "wiki" / "synthesis").glob("*.md"))
    assert len(wiki_files) == 0, f"Expected 0 wiki files, got {len(wiki_files)}"

  def test_candidate_marked_promoted(
    self, patch_constants, make_md_file, fixed_today, monkeypatch
  ):
    """Req 7.3: 昇格後、元候補ファイルに promoted/promoted_at/promoted_to が設定される"""
    monkeypatch.setattr(rw_utils, "git_path_is_dirty", lambda *args, **kwargs: False)

    vault = patch_constants
    candidate_path = vault / "review" / "synthesis_candidates" / "test-synthesis.md"
    make_md_file(candidate_path, APPROVED_META, "# Test Synthesis\nContent here.")

    rw_light.cmd_approve()

    content = candidate_path.read_text(encoding="utf-8")
    assert 'promoted: "true"' in content, "promoted フィールドが true になっていない"
    assert "promoted_at:" in content, "promoted_at フィールドがない"
    assert "promoted_to:" in content, "promoted_to フィールドがない"

  def test_merge_with_existing_wiki(
    self, patch_constants, make_md_file, fixed_today, monkeypatch
  ):
    """Req 7.4: wiki に同名ファイルが存在する場合、セパレータ付き追記でマージされる"""
    monkeypatch.setattr(rw_utils, "git_path_is_dirty", lambda *args, **kwargs: False)

    vault = patch_constants
    make_md_file(
      vault / "review" / "synthesis_candidates" / "test-synthesis.md",
      APPROVED_META,
      "# Test Synthesis\nNew content.",
    )

    # 既存 wiki ファイルを事前作成（tags フィールド含む）
    wiki_file = vault / "wiki" / "synthesis" / "test-synthesis.md"
    wiki_file.parent.mkdir(parents=True, exist_ok=True)
    wiki_file.write_text(
      "---\ntags: [existing_tag]\n---\n# Existing content\n",
      encoding="utf-8",
    )

    rw_light.cmd_approve()

    content = wiki_file.read_text(encoding="utf-8")
    # セパレータ付き追記の確認
    assert "---" in content, "マージセパレータがない"
    assert "Existing content" in content, "既存コンテンツが消えている"
    assert "New content" in content, "新規コンテンツが追記されていない"
    # 既存 tags フィールドが保持されていることを確認（false confidence 防止）
    assert "existing_tag" in content, "既存の tags フィールドが失われている"

  def test_index_updated(
    self, patch_constants, make_md_file, fixed_today, monkeypatch
  ):
    """Req 7.5: 昇格後、index.md に ## synthesis セクションが存在する"""
    monkeypatch.setattr(rw_utils, "git_path_is_dirty", lambda *args, **kwargs: False)

    vault = patch_constants
    make_md_file(
      vault / "review" / "synthesis_candidates" / "test-synthesis.md",
      APPROVED_META,
      "# Test Synthesis\nContent here.",
    )

    rw_light.cmd_approve()

    index_md = vault / "index.md"
    assert index_md.exists(), "index.md が生成されていない"
    content = index_md.read_text(encoding="utf-8")
    assert "## synthesis" in content, "index.md に ## synthesis セクションがない"

  def test_log_md_updated(
    self, patch_constants, make_md_file, fixed_today, monkeypatch
  ):
    """Req 7.6: 昇格後、log.md にエントリが存在する"""
    monkeypatch.setattr(rw_utils, "git_path_is_dirty", lambda *args, **kwargs: False)

    vault = patch_constants
    make_md_file(
      vault / "review" / "synthesis_candidates" / "test-synthesis.md",
      APPROVED_META,
      "# Test Synthesis\nContent here.",
    )

    rw_light.cmd_approve()

    log_md = vault / "log.md"
    assert log_md.exists(), "log.md が生成されていない"
    content = log_md.read_text(encoding="utf-8")
    assert len(content.strip()) > 0, "log.md が空"
    assert "synthesis" in content, "log.md に synthesis エントリがない"

  def test_exit_code(
    self, patch_constants, make_md_file, fixed_today, monkeypatch
  ):
    """Req 7.7: 承認ファイルがあってもなくても exit 0"""
    monkeypatch.setattr(rw_utils, "git_path_is_dirty", lambda *args, **kwargs: False)

    vault = patch_constants

    # 候補なしの場合
    result_empty = rw_light.cmd_approve()
    assert result_empty == 0, f"候補なし時の戻り値が {result_empty}"

    # 候補ありの場合
    make_md_file(
      vault / "review" / "synthesis_candidates" / "test-synthesis.md",
      APPROVED_META,
      "# Test Synthesis\nContent here.",
    )
    result_with = rw_light.cmd_approve()
    assert result_with == 0, f"候補あり時の戻り値が {result_with}"

  def test_dirty_warning(
    self, patch_constants, make_md_file, fixed_today, monkeypatch, capsys
  ):
    """Req 7.8: git_path_is_dirty が True の場合、[WARN] が stdout に出力される"""
    monkeypatch.setattr(rw_utils, "git_path_is_dirty", lambda *args, **kwargs: True)

    patch_constants

    rw_light.cmd_approve()

    captured = capsys.readouterr()
    assert "[WARN]" in captured.out, f"[WARN] が stdout に出力されていない: {captured.out!r}"
