# AGENTS/lint.md

## Purpose

Validate and normalize files under `raw/incoming/`.

## Scope

- Only process files under `raw/incoming/**`

## Severity Level

詳細: [developer-guide.md §Severity Vocabulary](developer-guide.md#6-severity-vocabulary)

| Severity | 条件 | status への影響 |
|----------|------|----------------|
| `ERROR` | 空ファイル、必須フィールド未確定、正規化不可 | FAIL（exit 2） |
| `WARN` | 短すぎる本文、任意メタデータ欠落 | PASS（影響なし） |
| `INFO` | 自動補完通知 | PASS（影響なし） |

## Status（2 値）

| Status | 条件 |
|--------|------|
| `PASS` | ERROR / CRITICAL が 0 件 |
| `FAIL` | ERROR / CRITICAL が 1 件以上 |

## Structure Definition

Valid structure means:
- Markdown file
- Parsable YAML frontmatter
- Required fields present (after autofix)

## Required Fields (frontmatter)

- title
- source
- added

## Auto Fix

- Add frontmatter if missing
- Fill missing fields if determinable
- Normalize formatting

### Constraints

- Do NOT change semantic content
- Do NOT invent unknown metadata
- If value cannot be determined → leave blank or FAIL

## Output

- `logs/lint_latest.json`
- exit code:
  - 0 → PASS（ERROR 0 件）
  - 1 → runtime error / 引数エラー
  - 2 → FAIL（ERROR 1 件以上）

## Contract

- ingest must only proceed if FAIL == 0
- Lint must be deterministic and script-driven