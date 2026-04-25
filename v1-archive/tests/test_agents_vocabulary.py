"""tests/test_agents_vocabulary.py — AGENTS + docs の旧語彙残存スキャン (AC 7.6)"""
import re
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).parent.parent

# Migration Notes ブロック内の旧語彙は除外（False positive 防止）
_LEGACY_BLOCK_RE = re.compile(
  r"<!--\s*severity-vocab:\s*legacy-reference\s*-->.*?<!--\s*/severity-vocab\s*-->",
  re.DOTALL,
)

PATTERN_A = re.compile(r"\b(HIGH|MEDIUM|LOW)\b")
PATTERN_B = re.compile(r"^\s*-\s+(high|medium|low)\s*:", re.MULTILINE)
PATTERN_C = re.compile(r"\[(HIGH|MEDIUM|LOW)\]")
# Pattern D: status schema 文字列内の WARN（severity 文脈の合法 WARN と区別）
PATTERN_D = re.compile(r'"(?:PASS\s*\|\s*)?WARN(?:\s*\|\s*(?:PASS|FAIL))+"')

SCAN_DIRS = [
  REPO_ROOT / "templates" / "AGENTS",
  REPO_ROOT / "docs",
]

SCAN_EXTENSIONS = {".md"}


def _strip_legacy_blocks(content: str) -> str:
  return _LEGACY_BLOCK_RE.sub("", content)


def _collect_files() -> list[Path]:
  files = []
  for d in SCAN_DIRS:
    if d.exists():
      for f in d.rglob("*"):
        if f.suffix in SCAN_EXTENSIONS and f.is_file():
          files.append(f)
  return sorted(files)


def _scan_file(path: Path) -> list[tuple[str, str, str]]:
  """(pattern_id, line_or_text, match) のリストを返す"""
  content = path.read_text(encoding="utf-8")
  stripped = _strip_legacy_blocks(content)
  hits = []
  for line_no, line in enumerate(stripped.splitlines(), 1):
    for pid, pat in [("A", PATTERN_A), ("B", PATTERN_B), ("C", PATTERN_C)]:
      m = pat.search(line)
      if m:
        hits.append((pid, f"L{line_no}: {line.strip()[:80]}", m.group()))
  for m in PATTERN_D.finditer(stripped):
    hits.append(("D", m.group()[:80], m.group()))
  return hits


class TestAgentsVocabulary:
  """AGENTS + docs ファイル内の旧語彙残存を静的スキャン (AC 7.6)"""

  def test_templates_agents_no_old_vocabulary(self):
    """templates/AGENTS/ 内に Pattern A/B/C/D の旧語彙が残存しない"""
    agents_dir = REPO_ROOT / "templates" / "AGENTS"
    assert agents_dir.exists(), f"templates/AGENTS/ が存在しない: {agents_dir}"

    violations = []
    for f in sorted(agents_dir.rglob("*.md")):
      hits = _scan_file(f)
      for pid, snippet, match in hits:
        violations.append(f"{f.relative_to(REPO_ROOT)}: Pattern {pid} → {snippet!r}")

    assert violations == [], (
      f"旧語彙 {len(violations)} 件検出:\n" + "\n".join(violations)
    )

  def test_docs_no_old_vocabulary(self):
    """docs/ 内に Pattern A/B/C/D の旧語彙が残存しない（legacy-reference ブロック除外）"""
    docs_dir = REPO_ROOT / "docs"
    assert docs_dir.exists(), f"docs/ が存在しない: {docs_dir}"

    violations = []
    for f in sorted(docs_dir.rglob("*.md")):
      hits = _scan_file(f)
      for pid, snippet, match in hits:
        violations.append(f"{f.relative_to(REPO_ROOT)}: Pattern {pid} → {snippet!r}")

    assert violations == [], (
      f"旧語彙 {len(violations)} 件検出:\n" + "\n".join(violations)
    )

  def test_legacy_block_exclusion_works(self, tmp_path):
    """legacy-reference ブロック内の旧語彙は除外される"""
    f = tmp_path / "test.md"
    f.write_text(
      "# Valid\n\n"
      "<!-- severity-vocab: legacy-reference -->\n"
      "| HIGH | old value |\n"
      "<!-- /severity-vocab -->\n"
      "\nNew content only: ERROR / WARN / INFO\n",
      encoding="utf-8",
    )
    hits = _scan_file(f)
    assert hits == [], f"legacy-reference ブロック内が誤検出: {hits}"

  def test_valid_severity_not_flagged(self, tmp_path):
    """新 4 水準語彙（CRITICAL/ERROR/WARN/INFO）は Pattern A/B/C に引っかからない"""
    f = tmp_path / "test.md"
    f.write_text(
      "| CRITICAL | system integrity |\n"
      "| ERROR | content quality |\n"
      "| WARN | minor issue |\n"
      "| INFO | informational |\n"
      "- status: PASS\n"
      "- status: FAIL\n",
      encoding="utf-8",
    )
    hits = _scan_file(f)
    assert hits == [], f"新語彙が誤検出: {hits}"
