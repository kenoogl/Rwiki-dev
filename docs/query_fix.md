## AGENTS/query_fix.md

## Purpose

Repair existing query artifacts using lint results.

You are given:

- existing query artifacts
- lint output from `rw lint query`

Your job is to fix the artifacts with minimal necessary edits.

Do NOT rewrite everything unless necessary.

## Repair Rules

### 1. Respect the existing content

- preserve valid content
- only fix the issues reported by lint
- avoid introducing new unsupported claims

---

### 2. Maintain Fact–Evidence Separation

- `answer.md` = explanation
- `evidence.md` = excerpts with source info

Do NOT merge them.

---

### 3. Never Invent Missing Evidence

If lint says evidence is insufficient:

- add only evidence actually found in wiki
- otherwise weaken the answer
- or mark interpretation as `[INFERENCE]`

Do NOT fabricate support.

---

### 4. Typical Fixes

#### If QL002
Add explicit query text to `query.md`

#### If QL004
Add explicit scope to `query.md` and/or `metadata.json`

#### If QL006
Expand `answer.md` so it is non-empty and meaningful

#### If QL008
Add actual evidence excerpts to `evidence.md`

#### If QL009
Add `source:` lines to each evidence block

#### If QL011
Add `[INFERENCE]` markers where interpretation exists

#### If QL017
Add required keys to `metadata.json`

#### Additional Fix Targets

- QL003: fix or add valid query_type
- QL005: add created_at
- QL007: improve structure
- QL010: increase evidence coverage if needed

---

## Output Mode

Return the corrected contents for:

- `query.md`
- `answer.md`
- `evidence.md`
- `metadata.json`

Only modify files that need changes.
If a file is already fine, keep it unchanged.

---

## Final Check

Before finishing, ensure:

- all required files remain present
- no file is empty
- evidence has source info
- required metadata exists
- unsupported interpretation is marked `[INFERENCE]`

---

## Design Principle

repair minimally, preserve traceability, never hide uncertainty

## Severity Level

`rw query fix` は内部 lint の status（`checks[]` 内の CRITICAL/ERROR）で FAIL を判定します。post-fix lint FAIL → exit 2。

詳細: [developer-guide.md §Severity Vocabulary](developer-guide.md#6-severity-vocabulary)