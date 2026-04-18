import os
import sys
from pathlib import Path
from typing import Callable

import pytest

# scripts/ を sys.path に追加（新規テストファイルで個別の sys.path.insert が不要になる）
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))

import rw_light


@pytest.fixture
def vault_path(tmp_path: Path) -> Path:
  """rw_light.VAULT_DIRS に定義された全ディレクトリを tmp_path 上に作成する。
  tmp_path を返す。各テストで独立したディレクトリが提供される。"""
  for d in rw_light.VAULT_DIRS:
    (tmp_path / d).mkdir(parents=True, exist_ok=True)
  return tmp_path


@pytest.fixture
def patch_constants(vault_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
  """rw_light の 17 グローバル定数を vault_path ベースに差し替える。
  対象: ROOT, RAW, INCOMING, LLM_LOGS, REVIEW, SYNTH_CANDIDATES,
        QUERY_REVIEW, WIKI, WIKI_SYNTH, LOGDIR, LINT_LOG,
        QUERY_LINT_LOG, INDEX_MD, CHANGE_LOG_MD, CLAUDE_MD,
        AGENTS_DIR, DEV_ROOT
  vault_path を返す。"""
  monkeypatch.setattr(rw_light, "ROOT", str(vault_path))
  monkeypatch.setattr(rw_light, "RAW", str(vault_path / "raw"))
  monkeypatch.setattr(rw_light, "INCOMING", str(vault_path / "raw" / "incoming"))
  monkeypatch.setattr(rw_light, "LLM_LOGS", str(vault_path / "raw" / "llm_logs"))
  monkeypatch.setattr(rw_light, "REVIEW", str(vault_path / "review"))
  monkeypatch.setattr(rw_light, "SYNTH_CANDIDATES", str(vault_path / "review" / "synthesis_candidates"))
  monkeypatch.setattr(rw_light, "QUERY_REVIEW", str(vault_path / "review" / "query"))
  monkeypatch.setattr(rw_light, "WIKI", str(vault_path / "wiki"))
  monkeypatch.setattr(rw_light, "WIKI_SYNTH", str(vault_path / "wiki" / "synthesis"))
  monkeypatch.setattr(rw_light, "LOGDIR", str(vault_path / "logs"))
  monkeypatch.setattr(rw_light, "LINT_LOG", str(vault_path / "logs" / "lint_latest.json"))
  monkeypatch.setattr(rw_light, "QUERY_LINT_LOG", str(vault_path / "logs" / "query_lint_latest.json"))
  monkeypatch.setattr(rw_light, "INDEX_MD", str(vault_path / "index.md"))
  monkeypatch.setattr(rw_light, "CHANGE_LOG_MD", str(vault_path / "log.md"))
  monkeypatch.setattr(rw_light, "CLAUDE_MD", str(vault_path / "CLAUDE.md"))
  monkeypatch.setattr(rw_light, "AGENTS_DIR", str(vault_path / "AGENTS"))
  monkeypatch.setattr(rw_light, "DEV_ROOT", str(vault_path))
  return vault_path


@pytest.fixture
def fixed_today(monkeypatch: pytest.MonkeyPatch) -> str:
  """rw_light.today を固定日付 '2025-01-15' に差し替える。
  固定日付文字列を返す。"""
  fixed = "2025-01-15"
  monkeypatch.setattr(rw_light, "today", lambda: fixed)
  return fixed


@pytest.fixture
def make_md_file() -> Callable[[Path, dict, str], Path]:
  """指定パスにフロントマター付き MD ファイルを生成するファクトリ。
  引数: (path: Path, meta: dict, body: str)
  path にファイルを書き込み、path を返す。"""
  def _make(path: Path, meta: dict, body: str) -> Path:
    os.makedirs(path.parent, exist_ok=True)
    content = rw_light.build_frontmatter(meta) + body
    path.write_text(content, encoding="utf-8")
    return path
  return _make
