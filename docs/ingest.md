# AGENTS/ingest.md

## Purpose

Define the ingest process from raw/incoming/ to raw/.

---

## Flow

1. Run lint
2. If FAIL exists → STOP
3. Move files from raw/incoming/ to raw/
4. Commit changes

---

## Rules

- Only process files under raw/incoming/
- Preserve directory structure
- Do not modify content meaning
- Do not overwrite existing files in raw/
- If conflict occurs → STOP and ask user

- Do not touch wiki/
- Do not commit raw/incoming/

- Ingest defines the transition from unverified to verified state
- Only committed raw/ is valid input for downstream processing

- Ingest MUST NOT trigger synthesis or wiki updates

- If target path already exists in raw/ → STOP

- Do NOT overwrite existing files
- Report conflicting file paths to the user
- Commit MUST occur only after all files are successfully moved
- Partial ingest is not allowed

---

## Output

- Files are placed in raw/
- Git commit is created

## Severity Level

`rw ingest` は severity を発行しません。上流 `rw lint` の結果（top-level `status == "FAIL"` または `summary.fail > 0`）を確認し、FAIL の場合は **exit 1**（precondition failure）で中断します。

詳細: [developer-guide.md §Exit Code Semantics](developer-guide.md#7-exit-code-semantics)

## Related

- lint → AGENTS/lint.md
- git rules → AGENTS/git_ops.md