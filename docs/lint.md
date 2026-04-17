# AGENTS/lint.md

## Purpose

Validate and normalize files under `raw/incoming/`.

## Scope

- Only process files under `raw/incoming/**`

## Levels

### PASS
- Valid structure

### WARN
- Minor issues (e.g., short content, missing optional metadata)

### FAIL
- File is empty
- Required fields cannot be determined
- Structure cannot be safely normalized

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
  - 0 → no FAIL
  - 1 → at least one FAIL

## Contract

- ingest must only proceed if FAIL == 0
- Lint must be deterministic and script-driven