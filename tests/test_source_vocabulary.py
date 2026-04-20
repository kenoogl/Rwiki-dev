"""tests/test_source_vocabulary.py — ソースコード + テストの旧語彙残存スキャン (AC 7.7)"""
import re
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).parent.parent

# スキャン対象
SCAN_SOURCE = [REPO_ROOT / "scripts" / "rw_cli.py"]
SCAN_TESTS = [
  p for p in (REPO_ROOT / "tests").glob("test_*.py")
  if p.name not in {"test_source_vocabulary.py", "test_agents_vocabulary.py"}
]

# スキャン除外: CHANGELOG / docs は旧値言及が必須のため除外
EXCLUDE_DIRS = {REPO_ROOT / "docs", REPO_ROOT / ".kiro"}

# CHANGELOG.md は除外（旧値言及が必須）
EXCLUDE_FILES = {REPO_ROOT / "CHANGELOG.md"}

# Pattern: PASS_WITH_WARNINGS
PASS_WITH_WARNINGS_RE = re.compile(r"PASS_WITH_WARNINGS")
# Pattern: status 位置の WARN（文字列リテラル "WARN" が status として扱われる文脈）
# 関数内の severity 集計 WARN は合法なので、status 比較文脈のみ検出
STATUS_WARN_RE = re.compile(r'status\s*[=!]=\s*["\']WARN["\']|["\']WARN["\']\s*[=!]=\s*status')
# Pattern: 旧 exit code semantics（rw lint / rw audit の FAIL を exit 1 として扱う文字列）
# "return 1" は合法（runtime error）なので除外、"== 1" の FAIL チェックのみ検出
OLD_EXIT_1_FAIL_RE = re.compile(r'assert\s+result\s*==\s*1\s*#.*FAIL|assert\s+rc\s*==\s*1\s*#.*FAIL')


def _scan_for_pattern(content: str, pattern: re.Pattern, filename: str) -> list[str]:
  hits = []
  for line_no, line in enumerate(content.splitlines(), 1):
    if pattern.search(line):
      hits.append(f"{filename}:L{line_no}: {line.strip()[:100]}")
  return hits


class TestSourceVocabulary:
  """scripts/rw_light.py と tests/ に旧語彙が残存しないことを検証 (AC 7.7)"""

  def test_no_pass_with_warnings_in_source(self):
    """scripts/rw_light.py に PASS_WITH_WARNINGS が残存しない"""
    violations = []
    for path in SCAN_SOURCE:
      if path.exists():
        content = path.read_text(encoding="utf-8")
        violations.extend(_scan_for_pattern(content, PASS_WITH_WARNINGS_RE, str(path.relative_to(REPO_ROOT))))
    assert violations == [], f"PASS_WITH_WARNINGS 残存 {len(violations)} 件:\n" + "\n".join(violations)

  def test_no_pass_with_warnings_in_tests(self):
    """tests/ に PASS_WITH_WARNINGS が残存しない（コメント・docstring・旧値言及除く）"""
    violations = []
    for path in SCAN_TESTS:
      content = path.read_text(encoding="utf-8")
      for line_no, line in enumerate(content.splitlines(), 1):
        if PASS_WITH_WARNINGS_RE.search(line):
          stripped = line.strip()
          # 廃止通知・非出力確認・!= 比較は許容（"廃止", "出現しない", "abolish", "!= "）
          if any(kw in stripped for kw in ["廃止", "出現しない", "abolish", "!= "]):
            continue
          violations.append(f"{path.relative_to(REPO_ROOT)}:L{line_no}: {stripped[:100]}")
    assert violations == [], f"PASS_WITH_WARNINGS 残存 {len(violations)} 件:\n" + "\n".join(violations)

  def test_no_status_warn_comparison_in_source(self):
    """scripts/rw_light.py に status == 'WARN' 等の比較が残存しない"""
    violations = []
    for path in SCAN_SOURCE:
      if path.exists():
        content = path.read_text(encoding="utf-8")
        violations.extend(_scan_for_pattern(content, STATUS_WARN_RE, str(path.relative_to(REPO_ROOT))))
    assert violations == [], f"status WARN 比較残存 {len(violations)} 件:\n" + "\n".join(violations)

  def test_no_old_exit_1_fail_assertion_in_tests(self):
    """tests/ に旧 FAIL=exit1 アサーション（assert result == 1 # FAIL 等）が残存しない"""
    violations = []
    for path in SCAN_TESTS:
      content = path.read_text(encoding="utf-8")
      violations.extend(_scan_for_pattern(content, OLD_EXIT_1_FAIL_RE, str(path.relative_to(REPO_ROOT))))
    assert violations == [], f"旧 FAIL exit 1 アサーション残存 {len(violations)} 件:\n" + "\n".join(violations)
