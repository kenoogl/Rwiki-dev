"""Task 1.1: conftest.py 新 fixture の存在確認テスト (RED → GREEN)

このファイルは 4 新 fixture の存在・基本動作を検証する。
初回実行（RED）は fixture 未定義のため FixtureLookupError で失敗することを確認。
"""
import json
import os
import subprocess
from pathlib import Path

import pytest


# ----------------------------------------------------------------
# env_normalized: autouse=True のため import だけで動作確認
# ----------------------------------------------------------------
def test_env_normalized_tz(env_normalized):
  """env_normalized が TZ=UTC を設定していること"""
  assert os.environ.get("TZ") == "UTC"


def test_env_normalized_lc_all(env_normalized):
  """env_normalized が LC_ALL=C.UTF-8 を設定していること"""
  assert os.environ.get("LC_ALL") == "C.UTF-8"


# ----------------------------------------------------------------
# tmp_vault
# ----------------------------------------------------------------
def test_tmp_vault_is_directory(tmp_vault):
  """tmp_vault が Path オブジェクトでディレクトリであること"""
  assert isinstance(tmp_vault, Path)
  assert tmp_vault.is_dir()


def test_tmp_vault_has_agents_dir(tmp_vault):
  """tmp_vault / AGENTS ディレクトリが存在すること"""
  agents_dir = tmp_vault / "AGENTS"
  assert agents_dir.is_dir()


def test_tmp_vault_has_audit_md(tmp_vault):
  """tmp_vault / AGENTS / audit.md が存在すること"""
  audit_md = tmp_vault / "AGENTS" / "audit.md"
  assert audit_md.is_file()


def test_tmp_vault_audit_md_has_new_vocabulary(tmp_vault):
  """AGENTS/audit.md が templates/AGENTS/audit.md のコピーであること（ファイルが空でない）"""
  audit_md = tmp_vault / "AGENTS" / "audit.md"
  content = audit_md.read_text(encoding="utf-8")
  assert len(content) > 0


# ----------------------------------------------------------------
# deprecated_agents_vault
# ----------------------------------------------------------------
def test_deprecated_agents_vault_is_directory(deprecated_agents_vault):
  """deprecated_agents_vault が Path オブジェクトでディレクトリであること"""
  assert isinstance(deprecated_agents_vault, Path)
  assert deprecated_agents_vault.is_dir()


def test_deprecated_agents_vault_has_pattern_a(deprecated_agents_vault):
  """Pattern A: テーブルセル '| HIGH |' 等が含まれること"""
  audit_md = deprecated_agents_vault / "AGENTS" / "audit.md"
  content = audit_md.read_text(encoding="utf-8")
  # Pattern A: table cell | HIGH | / | MEDIUM | / | LOW |
  assert "| HIGH |" in content or "| MEDIUM |" in content or "| LOW |" in content


def test_deprecated_agents_vault_has_pattern_b(deprecated_agents_vault):
  """Pattern B: サマリーキー '- high:' 等（行頭限定）が含まれること"""
  audit_md = deprecated_agents_vault / "AGENTS" / "audit.md"
  content = audit_md.read_text(encoding="utf-8")
  import re
  # Pattern B: 行頭 "- high:" / "- medium:" / "- low:"
  assert re.search(r"^- (high|medium|low):", content, re.MULTILINE) is not None


def test_deprecated_agents_vault_has_pattern_c(deprecated_agents_vault):
  """Pattern C: ファインディングブラケット '[HIGH]' 等が含まれること"""
  audit_md = deprecated_agents_vault / "AGENTS" / "audit.md"
  content = audit_md.read_text(encoding="utf-8")
  # Pattern C: [HIGH] / [MEDIUM] / [LOW]
  assert "[HIGH]" in content or "[MEDIUM]" in content or "[LOW]" in content


# ----------------------------------------------------------------
# claude_mock_response
# ----------------------------------------------------------------
def test_claude_mock_response_is_callable(claude_mock_response):
  """claude_mock_response がファクトリ関数（callable）であること"""
  assert callable(claude_mock_response)


def test_claude_mock_response_injects_json(claude_mock_response, monkeypatch):
  """claude_mock_response で注入した JSON 応答が subprocess.run の戻り値に反映されること"""
  import sys

  sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
  import rw_light

  mock_data = {"findings": [{"severity": "ERROR", "message": "test"}]}
  claude_mock_response(json.dumps(mock_data))

  result = rw_light.call_claude("dummy prompt")
  assert json.loads(result) == mock_data


def test_claude_mock_response_custom_stdout(claude_mock_response):
  """claude_mock_response に任意の文字列を渡せること"""
  import sys

  sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
  import rw_light

  claude_mock_response("hello world")
  result = rw_light.call_claude("any prompt")
  assert result == "hello world"
