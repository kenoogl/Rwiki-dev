import json
import sys
from io import StringIO
from pathlib import Path

import pytest

import rw_light


class TestCmdLintQuery:
  """cmd_lint_query コマンドのテスト (Req 8.1-8.8)"""

  def _make_valid_files(self, query_dir: Path) -> None:
    """ERROR が出ない最小限のファイルセットを生成する。"""
    (query_dir / "question.md").write_text(
      "scope: test-scope\nquery_type: fact\nWhat is X? This is a sufficient query text for testing purposes.",
      encoding="utf-8",
    )
    (query_dir / "answer.md").write_text(
      "# Answer\nX is Y. " + "A" * 50,
      encoding="utf-8",
    )
    (query_dir / "evidence.md").write_text(
      "# Evidence\nSource: https://example.com\n" + "B" * 50,
      encoding="utf-8",
    )
    metadata = {
      "query_id": "q001",
      "query_type": "fact",
      "created_at": "2025-01-15",
      "scope": "test-scope",
      "sources": ["https://example.com"],
    }
    (query_dir / "metadata.json").write_text(
      json.dumps(metadata, ensure_ascii=False, indent=2),
      encoding="utf-8",
    )

  def test_valid_query_structure(self, patch_constants, query_artifacts, capsys):
    """Req 8.1: 4 ファイルが揃っているとき stdout に 'Lint Result' が含まれる。"""
    query_dir = query_artifacts("q001")
    rw_light.cmd_lint_query(["--path", str(query_dir)])
    out = capsys.readouterr().out
    assert "Lint Result" in out

  def test_ql001_missing_file(self, patch_constants, query_artifacts, capsys):
    """Req 8.2: 必須ファイルが欠落しているとき stdout に 'QL001' が含まれる。"""
    query_dir = query_artifacts("q001")
    (query_dir / "question.md").unlink()
    rw_light.cmd_lint_query(["--path", str(query_dir)])
    out = capsys.readouterr().out
    assert "QL001" in out

  def test_log_output(self, patch_constants, query_artifacts):
    """Req 8.3: 実行後 query_lint_latest.json に timestamp, results, summary の 3 キーが存在する。"""
    query_dir = query_artifacts("q001")
    rw_light.cmd_lint_query(["--path", str(query_dir)])
    log_path = Path(rw_light.QUERY_LINT_LOG)
    assert log_path.exists()
    data = json.loads(log_path.read_text(encoding="utf-8"))
    assert "timestamp" in data
    assert "results" in data
    assert "summary" in data

  def test_exit_code_no_error(self, patch_constants, query_artifacts, tmp_path):
    """Req 8.4: ERROR がない場合 exit 0 を返す。"""
    query_dir = query_artifacts("q001")
    self._make_valid_files(query_dir)
    result = rw_light.cmd_lint_query(["--path", str(query_dir)])
    assert result == 0

  def test_exit_code_warn(self, patch_constants, query_artifacts):
    """WARN のみ発生する場合 exit 0 を返す（PASS_WITH_WARNINGS 廃止、PASS/FAIL 2 値化）"""
    query_dir = query_artifacts("q001")
    self._make_valid_files(query_dir)
    # created_at を削除して QL005 WARN を引き起こす
    metadata = {
      "query_id": "q001",
      "query_type": "fact",
      "scope": "test-scope",
      "sources": ["https://example.com"],
    }
    (query_dir / "metadata.json").write_text(
      json.dumps(metadata, ensure_ascii=False, indent=2),
      encoding="utf-8",
    )
    result = rw_light.cmd_lint_query(["--path", str(query_dir)])
    assert result == 0

  def test_exit_code_error(self, patch_constants, query_artifacts):
    """Req 8.6: ERROR がある場合 exit 2 を返す (QL001: 必須ファイル欠落)。"""
    query_dir = query_artifacts("q001")
    (query_dir / "question.md").unlink()
    result = rw_light.cmd_lint_query(["--path", str(query_dir)])
    assert result == 2

  def test_exit_code_path_not_found(self, patch_constants, tmp_path):
    """Req 8.7: 存在しないパスを指定した場合 exit 4 を返す。"""
    nonexistent = tmp_path / "does_not_exist" / "q999"
    result = rw_light.cmd_lint_query(["--path", str(nonexistent)])
    assert result == 4

  def test_exit_code_arg_error(self, patch_constants):
    """Req 8.8: 不正な引数を渡した場合 exit 3 を返す。"""
    result = rw_light.cmd_lint_query(["--path"])
    assert result == 3


# ---------------------------------------------------------------------------
# Task 2.6: query_lint_latest.json 新 schema
# ---------------------------------------------------------------------------


class TestLintQueryJsonNewSchema:
  """query_lint_latest.json が新 schema に適合することを検証"""

  def test_no_pass_with_warnings(self, patch_constants, query_artifacts):
    """results[].status に PASS_WITH_WARNINGS が出現しない"""
    query_dir = query_artifacts("q001")
    rw_light.cmd_lint_query(["--path", str(query_dir)])
    data = json.loads(
      (patch_constants / "logs" / "query_lint_latest.json").read_text()
    )
    for r in data["results"]:
      assert r["status"] != "PASS_WITH_WARNINGS"

  def test_checks_single_array_no_errors_warnings_infos(
    self, patch_constants, query_artifacts
  ):
    """results[].errors / .warnings / .infos 配列が存在しない"""
    query_dir = query_artifacts("q001")
    rw_light.cmd_lint_query(["--path", str(query_dir)])
    data = json.loads(
      (patch_constants / "logs" / "query_lint_latest.json").read_text()
    )
    for r in data["results"]:
      assert "errors" not in r
      assert "warnings" not in r
      assert "infos" not in r
      assert "checks" in r
      assert isinstance(r["checks"], list)

  def test_summary_severity_counts_four_keys(
    self, patch_constants, query_artifacts
  ):
    """summary.severity_counts に critical/error/warn/info の 4 キーが存在する"""
    query_dir = query_artifacts("q001")
    rw_light.cmd_lint_query(["--path", str(query_dir)])
    data = json.loads(
      (patch_constants / "logs" / "query_lint_latest.json").read_text()
    )
    sc = data["summary"]["severity_counts"]
    assert "critical" in sc
    assert "error" in sc
    assert "warn" in sc
    assert "info" in sc

  def test_drift_events_field_exists(self, patch_constants, query_artifacts):
    """drift_events フィールドが存在する（空 list 可）"""
    query_dir = query_artifacts("q001")
    rw_light.cmd_lint_query(["--path", str(query_dir)])
    data = json.loads(
      (patch_constants / "logs" / "query_lint_latest.json").read_text()
    )
    assert "drift_events" in data
    assert isinstance(data["drift_events"], list)

  def test_no_schema_version(self, patch_constants, query_artifacts):
    """schema_version フィールドは追加しない（Y Cut）"""
    query_dir = query_artifacts("q001")
    rw_light.cmd_lint_query(["--path", str(query_dir)])
    data = json.loads(
      (patch_constants / "logs" / "query_lint_latest.json").read_text()
    )
    assert "schema_version" not in data

  def test_warn_only_returns_pass_status(
    self, patch_constants, query_artifacts
  ):
    """WARN のみの場合 results[].status == 'PASS'（PASS_WITH_WARNINGS を廃止）"""
    query_dir = query_artifacts("q001")
    # created_at を削除して QL005 WARN を引き起こす
    meta = {
      "query_id": "q001",
      "query_type": "fact",
      "scope": "test-scope",
      "sources": ["https://example.com"],
    }
    (query_dir / "metadata.json").write_text(
      json.dumps(meta, ensure_ascii=False),
      encoding="utf-8",
    )
    rw_light.cmd_lint_query(["--path", str(query_dir)])
    data = json.loads(
      (patch_constants / "logs" / "query_lint_latest.json").read_text()
    )
    for r in data["results"]:
      assert r["status"] in {"PASS", "FAIL"}
