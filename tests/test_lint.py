"""tests/test_lint.py — cmd_lint コマンドのテスト (Req 4.1–4.8)"""
import json
from pathlib import Path

import pytest

import rw_light


class TestCmdLint:
  """cmd_lint の 8 テスト (Req 4.1–4.8)"""

  # ------------------------------------------------------------------
  # Req 4.1  PASS 判定
  # ------------------------------------------------------------------
  def test_pass_judgment(
    self,
    patch_constants: Path,
    make_md_file,
    fixed_today: str,
    capsys,
  ) -> None:
    """十分な内容のファイルは PASS で exit 0。"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    body = "x" * 120  # 100 文字超
    make_md_file(articles_dir / "good.md", {}, body)

    rc = rw_light.cmd_lint()

    captured = capsys.readouterr()
    assert rc == 0
    assert "[PASS]" in captured.out

  # ------------------------------------------------------------------
  # Req 4.2  FAIL 判定
  # ------------------------------------------------------------------
  def test_fail_judgment(
    self,
    patch_constants: Path,
    fixed_today: str,
    capsys,
  ) -> None:
    """空ファイルは FAIL で exit 1。"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    empty_file = articles_dir / "empty.md"
    empty_file.write_text("", encoding="utf-8")

    rc = rw_light.cmd_lint()

    captured = capsys.readouterr()
    assert rc == 1
    assert "[FAIL]" in captured.out

  # ------------------------------------------------------------------
  # Req 4.3  WARN 判定
  # ------------------------------------------------------------------
  def test_warn_judgment(
    self,
    patch_constants: Path,
    fixed_today: str,
    capsys,
  ) -> None:
    """補完後のテキストが 80 文字未満のファイルは WARN で exit 0。"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    # フロントマターなし・短い本文（ensure_basic_frontmatter 補完後も 80 文字未満）
    short_file = articles_dir / "x.md"
    short_file.write_text("hi\n", encoding="utf-8")

    rc = rw_light.cmd_lint()

    captured = capsys.readouterr()
    assert rc == 0
    assert "[WARN]" in captured.out

  # ------------------------------------------------------------------
  # Req 4.4  空ディレクトリ
  # ------------------------------------------------------------------
  def test_empty_incoming(
    self,
    patch_constants: Path,
    fixed_today: str,
    capsys,
  ) -> None:
    """incoming/ にファイルがない場合は exit 0 でサマリー全 0。"""
    rc = rw_light.cmd_lint()

    captured = capsys.readouterr()
    assert rc == 0
    assert "{'pass': 0, 'warn': 0, 'fail': 0}" in captured.out

  # ------------------------------------------------------------------
  # Req 4.5  JSON ログ
  # ------------------------------------------------------------------
  def test_json_log_output(
    self,
    patch_constants: Path,
    make_md_file,
    fixed_today: str,
  ) -> None:
    """cmd_lint 実行後、lint_latest.json に timestamp/files/summary の 3 キーが存在する。"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    make_md_file(articles_dir / "article.md", {}, "a" * 120)

    rw_light.cmd_lint()

    log_path = patch_constants / "logs" / "lint_latest.json"
    assert log_path.exists(), "lint_latest.json が生成されていない"
    data = json.loads(log_path.read_text(encoding="utf-8"))
    assert "timestamp" in data
    assert "files" in data
    assert "summary" in data

  # ------------------------------------------------------------------
  # Req 4.6  exit 1 (FAIL あり)
  # ------------------------------------------------------------------
  def test_exit_code_fail(
    self,
    patch_constants: Path,
    fixed_today: str,
  ) -> None:
    """FAIL ファイルが 1 件以上存在する場合は exit 1。"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    (articles_dir / "empty.md").write_text("", encoding="utf-8")

    rc = rw_light.cmd_lint()

    assert rc == 1

  # ------------------------------------------------------------------
  # Req 4.7  exit 0 (FAIL なし)
  # ------------------------------------------------------------------
  def test_exit_code_no_fail(
    self,
    patch_constants: Path,
    make_md_file,
    fixed_today: str,
  ) -> None:
    """PASS + WARN のみ（FAIL なし）の場合は exit 0。"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    # PASS ファイル
    make_md_file(articles_dir / "pass.md", {}, "p" * 120)
    # WARN ファイル（短い本文）
    (articles_dir / "w.md").write_text("hi\n", encoding="utf-8")

    rc = rw_light.cmd_lint()

    assert rc == 0

  # ------------------------------------------------------------------
  # Req 4.8  フロントマター書き戻し
  # ------------------------------------------------------------------
  def test_frontmatter_written_back(
    self,
    patch_constants: Path,
    fixed_today: str,
  ) -> None:
    """フロントマターなしのファイルに lint を実行すると title/source/added が書き込まれる。"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    md_file = articles_dir / "no_front.md"
    # フロントマターなし・十分な本文
    md_file.write_text("b" * 120, encoding="utf-8")

    rw_light.cmd_lint()

    written = md_file.read_text(encoding="utf-8")
    meta, _ = rw_light.parse_frontmatter(written)
    assert "title" in meta
    assert "source" in meta
    # articles/ ディレクトリから source が推論される
    assert meta["source"] == rw_light.infer_source_from_path(str(md_file))
    assert "added" in meta
    assert meta["added"] == fixed_today
