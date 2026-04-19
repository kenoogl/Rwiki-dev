import os
import subprocess
from pathlib import Path

import pytest
import rw_light


class TestCmdIngest:
  """cmd_ingest コマンドのテスト (Req 5.1-5.8)"""

  def test_file_moved_to_raw(self, patch_constants, make_md_file, lint_json, monkeypatch):
    """Req 5.1: ファイルが incoming/ から raw/ に移動される"""
    lint_json({
      "timestamp": "2025-01-15",
      "files": [],
      "summary": {"pass": 1, "warn": 0, "fail": 0},
    })
    vault = patch_constants
    src = vault / "raw" / "incoming" / "articles" / "test.md"
    make_md_file(src, {"title": "Test Article", "source": "web"}, "# Test\nBody text here.")
    assert src.exists()

    monkeypatch.setattr(rw_light, "git_commit", lambda paths, msg: None)

    rw_light.cmd_ingest()

    dst = vault / "raw" / "articles" / "test.md"
    assert dst.exists(), f"移動先 {dst} にファイルが存在しない"
    assert not src.exists(), f"移動元 {src} がまだ存在する"

  def test_empty_incoming(self, patch_constants, lint_json, monkeypatch):
    """Req 5.2: incoming/ が空の場合 exit 0"""
    lint_json({
      "timestamp": "2025-01-15",
      "files": [],
      "summary": {"pass": 0, "warn": 0, "fail": 0},
    })
    monkeypatch.setattr(rw_light, "git_commit", lambda paths, msg: None)

    result = rw_light.cmd_ingest()

    assert result == 0

  def test_git_commit_called(self, patch_constants, make_md_file, lint_json, monkeypatch):
    """Req 5.3: ファイル移動成功後に git_commit が呼ばれる"""
    lint_json({
      "timestamp": "2025-01-15",
      "files": [],
      "summary": {"pass": 1, "warn": 0, "fail": 0},
    })
    vault = patch_constants
    src = vault / "raw" / "incoming" / "articles" / "commit_test.md"
    make_md_file(src, {"title": "Commit Test", "source": "web"}, "# Commit Test\nBody.")

    calls = []

    def mock_git_commit(paths, msg):
      calls.append((paths, msg))

    monkeypatch.setattr(rw_light, "git_commit", mock_git_commit)

    rw_light.cmd_ingest()

    assert len(calls) == 1, "git_commit が呼ばれていない"

  def test_fail_blocks_ingest(self, patch_constants, make_md_file, lint_json, monkeypatch):
    """Req 5.4: lint に FAIL がある場合 exit 1 でファイルが移動されない"""
    lint_json({
      "timestamp": "2025-01-15",
      "files": [],
      "summary": {"pass": 0, "warn": 0, "fail": 1},
    })
    vault = patch_constants
    src = vault / "raw" / "incoming" / "articles" / "blocked.md"
    make_md_file(src, {"title": "Blocked", "source": "web"}, "# Blocked\nBody.")

    monkeypatch.setattr(rw_light, "git_commit", lambda paths, msg: None)

    result = rw_light.cmd_ingest()

    assert result == 1
    assert src.exists(), "FAIL があるのにファイルが移動された"

  def test_git_commit_failure(self, patch_constants, make_md_file, lint_json, monkeypatch):
    """Req 5.5: git_commit が CalledProcessError を送出した場合 exit 1"""
    lint_json({
      "timestamp": "2025-01-15",
      "files": [],
      "summary": {"pass": 1, "warn": 0, "fail": 0},
    })
    vault = patch_constants
    src = vault / "raw" / "incoming" / "articles" / "git_fail.md"
    make_md_file(src, {"title": "Git Fail", "source": "web"}, "# Git Fail\nBody.")

    def failing_git_commit(paths, msg):
      raise subprocess.CalledProcessError(1, "git commit")

    monkeypatch.setattr(rw_light, "git_commit", failing_git_commit)

    result = rw_light.cmd_ingest()

    assert result == 1

  def test_lint_not_run(self, patch_constants, monkeypatch):
    """Req 5.6: lint_latest.json が存在しない場合 FileNotFoundError が発生する"""
    # lint_json フィクスチャを使わず lint_latest.json を作成しない
    monkeypatch.setattr(rw_light, "git_commit", lambda paths, msg: None)

    with pytest.raises(FileNotFoundError):
      rw_light.cmd_ingest()

  def test_duplicate_destination(self, patch_constants, make_md_file, lint_json, monkeypatch):
    """Req 5.7: 移動先に同名ファイルが既存の場合 RuntimeError が発生する"""
    lint_json({
      "timestamp": "2025-01-15",
      "files": [],
      "summary": {"pass": 1, "warn": 0, "fail": 0},
    })
    vault = patch_constants
    incoming_file = vault / "raw" / "incoming" / "articles" / "dup.md"
    make_md_file(incoming_file, {"title": "Dup", "source": "web"}, "# Dup\nBody.")

    # 移動先にも同名ファイルを配置
    dst = vault / "raw" / "articles" / "dup.md"
    os.makedirs(dst.parent, exist_ok=True)
    dst.write_text("# Existing\nExisting content.", encoding="utf-8")

    monkeypatch.setattr(rw_light, "git_commit", lambda paths, msg: None)

    with pytest.raises(RuntimeError):
      rw_light.cmd_ingest()

  def test_rollback_on_error(self, patch_constants, make_md_file, lint_json, monkeypatch):
    """Req 5.8: 移動実行中エラー発生時に既に移動したファイルがロールバックされる"""
    lint_json({
      "timestamp": "2025-01-15",
      "files": [],
      "summary": {"pass": 1, "warn": 0, "fail": 0},
    })
    vault = patch_constants
    # file1 と file2 を incoming に配置（アルファベット順で file1 が先に処理されるようにする）
    file1_src = vault / "raw" / "incoming" / "articles" / "afile1.md"
    file2_src = vault / "raw" / "incoming" / "articles" / "bfile2.md"
    make_md_file(file1_src, {"title": "File1", "source": "web"}, "# File1\nBody.")
    make_md_file(file2_src, {"title": "File2", "source": "web"}, "# File2\nBody.")

    # shutil.move を 2 番目の呼び出しでエラーを起こすようにモック
    original_move = rw_light.shutil.move
    call_count = [0]

    def failing_move(src, dst):
      call_count[0] += 1
      if call_count[0] == 2:
        raise OSError("test error")
      original_move(src, dst)

    monkeypatch.setattr(rw_light.shutil, "move", failing_move)
    monkeypatch.setattr(rw_light, "git_commit", lambda paths, msg: None)

    # execute_ingest_moves が例外を再 raise する
    with pytest.raises(Exception):
      rw_light.cmd_ingest()

    # file1 がロールバックされ元の位置に戻っているべき
    assert file1_src.exists(), f"file1 ({file1_src}) がロールバックされていない"
    file1_dst = vault / "raw" / "articles" / "afile1.md"
    assert not file1_dst.exists(), f"file1 の移動先 ({file1_dst}) がまだ存在する"
