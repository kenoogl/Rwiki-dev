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


@pytest.fixture
def lint_json(vault_path: Path) -> Callable[[dict], Path]:
  """lint_latest.json を vault_path / "logs" / "lint_latest.json" に生成するファクトリ。
  rw_light.LINT_LOG は参照しない（patch_constants 非依存にするため）。
  引数: (data: dict) — timestamp, files, summary の 3 キー構造。
  書き込んだ Path を返す。"""
  import json

  def _make(data: dict) -> Path:
    log_path = vault_path / "logs" / "lint_latest.json"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return log_path

  return _make


@pytest.fixture
def query_artifacts(vault_path: Path) -> Callable[[str], Path]:
  """指定 query_id で vault_path / "review" / "query" / <query_id>/ に
  question.md, answer.md, evidence.md, metadata.json を生成。
  rw_light.QUERY_REVIEW は参照しない（patch_constants 非依存にするため）。
  クエリディレクトリの Path を返す。"""
  import json

  def _make(query_id: str) -> Path:
    query_dir = vault_path / "review" / "query" / query_id
    query_dir.mkdir(parents=True, exist_ok=True)
    (query_dir / "question.md").write_text("# Question\nWhat is X?", encoding="utf-8")
    (query_dir / "answer.md").write_text("# Answer\nX is Y.", encoding="utf-8")
    (query_dir / "evidence.md").write_text("# Evidence\nSource: Z.", encoding="utf-8")
    metadata = {
      "query_id": query_id,
      "query_type": "factual",
      "created_at": "2025-01-15",
    }
    (query_dir / "metadata.json").write_text(
      json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    return query_dir

  return _make


# 排他制約: mock_templates と patch_constants は同一テストで併用しない。
# 両フィクスチャが rw_light.DEV_ROOT をパッチするため、後から適用された方が勝ち、
# 挙動が不定になる。test_init.py は mock_templates のみ使用し、
# 他のテストファイルは patch_constants のみ使用する設計とする。
@pytest.fixture
def mock_templates(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
  """tmp_path / "templates"/ にモックテンプレートを作成し、
  rw_light.DEV_ROOT を tmp_path にパッチする。
  - templates/CLAUDE.md: 最小限のテキスト
  - templates/.gitignore: 最小限のテキスト
  - templates/AGENTS/: ダミー .md ファイル 2 個
  - scripts/rw_light.py: ダミーファイル（cmd_init の os.stat チェック対策）
  テンプレートルート (tmp_path / "templates") の Path を返す。"""
  tmpl_root = tmp_path / "templates"
  tmpl_root.mkdir(parents=True, exist_ok=True)

  (tmpl_root / "CLAUDE.md").write_text("# CLAUDE\nTest kernel", encoding="utf-8")
  (tmpl_root / ".gitignore").write_text("*.pyc\n.DS_Store\n", encoding="utf-8")

  agents_dir = tmpl_root / "AGENTS"
  agents_dir.mkdir(parents=True, exist_ok=True)
  (agents_dir / "agent_a.md").write_text("# Agent A\nDummy agent.", encoding="utf-8")
  (agents_dir / "agent_b.md").write_text("# Agent B\nDummy agent.", encoding="utf-8")

  scripts_dir = tmp_path / "scripts"
  scripts_dir.mkdir(parents=True, exist_ok=True)
  (scripts_dir / "rw_light.py").write_text("# dummy\n", encoding="utf-8")

  monkeypatch.setattr(rw_light, "DEV_ROOT", str(tmp_path))

  return tmpl_root
