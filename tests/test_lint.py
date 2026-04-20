"""tests/test_lint.py — cmd_lint コマンドのテスト (Req 4.1–4.8)"""
import json
from pathlib import Path

import pytest

import rw_cli
import rw_utils


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

    rc = rw_cli.cmd_lint()

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
    """空ファイルは FAIL で exit 2（新体系: FAIL → exit 2）。"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    empty_file = articles_dir / "empty.md"
    empty_file.write_text("", encoding="utf-8")

    rc = rw_cli.cmd_lint()

    captured = capsys.readouterr()
    assert rc == 2
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

    rc = rw_cli.cmd_lint()

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
    rc = rw_cli.cmd_lint()

    captured = capsys.readouterr()
    assert rc == 0
    assert "PASS" in captured.out

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

    rw_cli.cmd_lint()

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
    """FAIL ファイルが 1 件以上存在する場合は exit 2（新体系: FAIL → exit 2）。"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    (articles_dir / "empty.md").write_text("", encoding="utf-8")

    rc = rw_cli.cmd_lint()

    assert rc == 2

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

    rc = rw_cli.cmd_lint()

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

    rw_cli.cmd_lint()

    written = md_file.read_text(encoding="utf-8")
    meta, _ = rw_utils.parse_frontmatter(written)
    assert "title" in meta
    assert "source" in meta
    # articles/ ディレクトリから source が推論される
    assert meta["source"] == rw_utils.infer_source_from_path(str(md_file))
    assert "added" in meta
    assert meta["added"] == fixed_today


# ---------------------------------------------------------------------------
# Task 2.9: cmd_lint FAIL → exit 2
# ---------------------------------------------------------------------------


class TestLintExit2OnFail:
  """cmd_lint の exit code 3 値契約を検証"""

  def test_exit_2_on_fail(self, patch_constants, fixed_today):
    """FAIL（空ファイル）→ exit 2"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    (articles_dir / "empty.md").write_text("", encoding="utf-8")

    rc = rw_cli.cmd_lint()

    assert rc == 2

  def test_exit_0_on_pass(self, patch_constants, make_md_file, fixed_today):
    """PASS → exit 0"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    make_md_file(articles_dir / "good.md", {}, "a" * 120)

    rc = rw_cli.cmd_lint()

    assert rc == 0


# ---------------------------------------------------------------------------
# Task 2.5: cmd_lint stdout 4 水準表示
# ---------------------------------------------------------------------------


class TestLintStdout4Tier:
  """cmd_lint stdout が 4 水準併記 + status を表示することを検証"""

  def test_summary_line_has_4_tiers(
    self,
    patch_constants: Path,
    make_md_file,
    fixed_today: str,
    capsys,
  ) -> None:
    """stdout summary 行に CRITICAL/ERROR/WARN/INFO の 4 水準件数と status が含まれる"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    make_md_file(articles_dir / "good.md", {}, "a" * 120)

    rw_cli.cmd_lint()

    captured = capsys.readouterr()
    assert "CRITICAL" in captured.out
    assert "ERROR" in captured.out
    assert "WARN" in captured.out
    assert "INFO" in captured.out
    assert "PASS" in captured.out

  def test_status_shown_when_all_pass(
    self,
    patch_constants: Path,
    make_md_file,
    fixed_today: str,
    capsys,
  ) -> None:
    """問題 0 件（全 PASS）でも status 行が表示される（AC 5.5 境界）"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    make_md_file(articles_dir / "good.md", {}, "a" * 120)

    rw_cli.cmd_lint()

    captured = capsys.readouterr()
    assert "PASS" in captured.out

  def test_status_shown_when_no_files(
    self,
    patch_constants: Path,
    fixed_today: str,
    capsys,
  ) -> None:
    """対象 0 件でも status（PASS）が表示される（AC 5.5 境界）"""
    rw_cli.cmd_lint()

    captured = capsys.readouterr()
    assert "PASS" in captured.out

  def test_status_fail_shown_in_stdout(
    self,
    patch_constants: Path,
    fixed_today: str,
    capsys,
  ) -> None:
    """ERROR ファイルがある場合は stdout に FAIL が表示される"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    (articles_dir / "empty.md").write_text("", encoding="utf-8")

    rw_cli.cmd_lint()

    captured = capsys.readouterr()
    assert "FAIL" in captured.out

  def test_warn_status_not_in_summary_line(
    self,
    patch_constants: Path,
    fixed_today: str,
    capsys,
  ) -> None:
    """WARN が status 位置に出現しない（WARN は severity 水準として件数表示のみ）"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    (articles_dir / "short.md").write_text("hi\n", encoding="utf-8")

    rw_cli.cmd_lint()

    captured = capsys.readouterr()
    # stdout summary 行の status は PASS のはず
    # "lint: ... — WARN" という形式は出ないこと
    assert "— WARN" not in captured.out


# ---------------------------------------------------------------------------
# Task 2.4: lint_latest.json 新 schema
# ---------------------------------------------------------------------------


class TestLintJsonNewSchema:
  """lint_latest.json が新 schema に適合することを検証"""

  def test_top_level_status_pass(
    self,
    patch_constants: Path,
    make_md_file,
    fixed_today: str,
  ) -> None:
    """PASS ファイルのみ → top-level status == 'PASS'"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    make_md_file(articles_dir / "good.md", {}, "a" * 120)

    rw_cli.cmd_lint()

    data = json.loads((patch_constants / "logs" / "lint_latest.json").read_text())
    assert data["status"] == "PASS"

  def test_top_level_status_fail(
    self,
    patch_constants: Path,
    fixed_today: str,
  ) -> None:
    """空ファイル（ERROR）→ top-level status == 'FAIL'"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    (articles_dir / "empty.md").write_text("", encoding="utf-8")

    rw_cli.cmd_lint()

    data = json.loads((patch_constants / "logs" / "lint_latest.json").read_text())
    assert data["status"] == "FAIL"

  def test_file_status_two_values_only(
    self,
    patch_constants: Path,
    make_md_file,
    fixed_today: str,
  ) -> None:
    """files[].status は PASS または FAIL のみ（WARN は出現しない）"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    make_md_file(articles_dir / "good.md", {}, "a" * 120)
    (articles_dir / "short.md").write_text("hi\n", encoding="utf-8")  # WARN check
    (articles_dir / "empty.md").write_text("", encoding="utf-8")       # ERROR

    rw_cli.cmd_lint()

    data = json.loads((patch_constants / "logs" / "lint_latest.json").read_text())
    for f in data["files"]:
      assert f["status"] in {"PASS", "FAIL"}, f"files status must be PASS/FAIL, got {f['status']}"

  def test_summary_severity_counts_four_keys(
    self,
    patch_constants: Path,
    make_md_file,
    fixed_today: str,
  ) -> None:
    """summary.severity_counts に critical/error/warn/info の 4 キーが存在する"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    make_md_file(articles_dir / "good.md", {}, "a" * 120)

    rw_cli.cmd_lint()

    data = json.loads((patch_constants / "logs" / "lint_latest.json").read_text())
    sc = data["summary"]["severity_counts"]
    assert "critical" in sc
    assert "error" in sc
    assert "warn" in sc
    assert "info" in sc

  def test_summary_no_warn_key(
    self,
    patch_constants: Path,
    make_md_file,
    fixed_today: str,
  ) -> None:
    """summary に 'warn' キーは存在しない（severity_counts に移行済み）"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    make_md_file(articles_dir / "good.md", {}, "a" * 120)

    rw_cli.cmd_lint()

    data = json.loads((patch_constants / "logs" / "lint_latest.json").read_text())
    assert "warn" not in data["summary"]

  def test_drift_events_field_exists(
    self,
    patch_constants: Path,
    make_md_file,
    fixed_today: str,
  ) -> None:
    """drift_events フィールドが存在する（空 list 可）"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    make_md_file(articles_dir / "good.md", {}, "a" * 120)

    rw_cli.cmd_lint()

    data = json.loads((patch_constants / "logs" / "lint_latest.json").read_text())
    assert "drift_events" in data
    assert isinstance(data["drift_events"], list)

  def test_severity_counts_values(
    self,
    patch_constants: Path,
    make_md_file,
    fixed_today: str,
  ) -> None:
    """WARN ファイル 1 件 + ERROR ファイル 1 件 → severity_counts が正確"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    (articles_dir / "short.md").write_text("hi\n", encoding="utf-8")   # WARN
    (articles_dir / "empty.md").write_text("", encoding="utf-8")        # ERROR

    rw_cli.cmd_lint()

    data = json.loads((patch_constants / "logs" / "lint_latest.json").read_text())
    sc = data["summary"]["severity_counts"]
    assert sc["error"] == 1
    assert sc["warn"] == 1
    assert sc["critical"] == 0
    assert sc["info"] == 0

  def test_no_schema_version(
    self,
    patch_constants: Path,
    make_md_file,
    fixed_today: str,
  ) -> None:
    """schema_version フィールドは追加しない（Y Cut）"""
    articles_dir = patch_constants / "raw" / "incoming" / "articles"
    articles_dir.mkdir(parents=True, exist_ok=True)
    make_md_file(articles_dir / "good.md", {}, "a" * 120)

    rw_cli.cmd_lint()

    data = json.loads((patch_constants / "logs" / "lint_latest.json").read_text())
    assert "schema_version" not in data
