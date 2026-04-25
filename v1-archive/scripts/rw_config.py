"""rw_config — 全グローバル定数（パス・ドメイン）の単一ソース。

他のサブモジュール（rw_utils, rw_prompt_engine, rw_audit, rw_query, rw_cli）から
`import rw_config` + `rw_config.<NAME>` 形式で参照する。`from rw_config import <NAME>` は
禁止（Req 3.2: テスト monkeypatch が効かなくなるため）。

このモジュールは他のどのサブモジュールも import しない（DAG 最下層）。
"""
import os
from pathlib import Path

ROOT = os.getcwd()

RAW = os.path.join(ROOT, "raw")
INCOMING = os.path.join(RAW, "incoming")
LLM_LOGS = os.path.join(RAW, "llm_logs")

REVIEW = os.path.join(ROOT, "review")
SYNTH_CANDIDATES = os.path.join(REVIEW, "synthesis_candidates")
QUERY_REVIEW = os.path.join(REVIEW, "query")

WIKI = os.path.join(ROOT, "wiki")
WIKI_SYNTH = os.path.join(WIKI, "synthesis")

LOGDIR = os.path.join(ROOT, "logs")
LINT_LOG = os.path.join(LOGDIR, "lint_latest.json")
QUERY_LINT_LOG = os.path.join(LOGDIR, "query_lint_latest.json")

INDEX_MD = os.path.join(ROOT, "index.md")
CHANGE_LOG_MD = os.path.join(ROOT, "log.md")
CLAUDE_MD = os.path.join(ROOT, "CLAUDE.md")
AGENTS_DIR = os.path.join(ROOT, "AGENTS")

ALLOWED_QUERY_TYPES = {"fact", "structure", "comparison", "why", "hypothesis"}

INFERENCE_PATTERNS = [
    r"考えられる",
    r"示唆される",
    r"推測される",
    r"おそらく",
    r"可能性がある",
    r"と思われる",
    r"\blikely\b",
    r"\bsuggests?\b",
    r"\bmay\b",
    r"\bcould\b",
]

EVIDENCE_SOURCE_PATTERNS = [
    r"^source\s*:",
    r"^file\s*:",
    r"^page\s*:",
    r"^path\s*:",
    r"\[\[.+\]\]",
]

VAULT_DIRS = [
    "raw/incoming/articles",
    "raw/incoming/papers/zotero",
    "raw/incoming/papers/local",
    "raw/incoming/meeting-notes",
    "raw/incoming/code-snippets",
    "raw/articles",
    "raw/papers/zotero",
    "raw/papers/local",
    "raw/meeting-notes",
    "raw/code-snippets",
    "raw/llm_logs",
    "review/synthesis_candidates",
    "review/query",
    "wiki/concepts",
    "wiki/methods",
    "wiki/projects",
    "wiki/entities/people",
    "wiki/entities/tools",
    "wiki/synthesis",
    "logs",
    "scripts",
    "AGENTS",
]

DEV_ROOT = str(Path(__file__).resolve().parent.parent)

LARGE_WIKI_THRESHOLD = 150

_VALID_SEVERITIES = {"CRITICAL", "ERROR", "WARN", "INFO"}
_FAIL_SEVERITIES = {"CRITICAL", "ERROR"}
