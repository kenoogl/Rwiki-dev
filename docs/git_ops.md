# AGENTS/git_ops.md

## Purpose

Define Git operation rules for stable and reproducible workflow states.

## Principles

- raw, review, wiki の更新は**別々に**コミットすること（3層分離）
- A commit defines a stable, reproducible state
- Only committed `raw/` may be used as input for downstream LLM processing

## Rules

- Never commit `raw/incoming/`
- Never mix source-layer commits and knowledge-layer commits
- Do not mix `raw/` ingest updates with `review/` or `wiki/` updates
- `index.md` and `log.md` may accompany knowledge-layer commits
- If commit boundaries are unclear → STOP and ask user

## Commit Types

### ingest commit

- target: `raw/`
- allowed only after successful lint (`FAIL == 0`)
- message: `ingest: ...`

### synthesis commit

- target: `review/`（synthesize タスクの出力先は review/ のみ）
- message: `synthesis: ...`

### synthesize-logs commit

- target: `review/synthesis_candidates/`
- message: `synthesize-logs: ...`

### query commit

- target: `review/query/`
- message: `query: ...`

### approve commit

- target (1): `review/`（promoted フラグ更新）
- target (2): `wiki/`（昇格ノート作成）
- review/ と wiki/ の変更は別々にコミットすること
- may include: `index.md`, `log.md`（wiki/ コミットに含める）
- message: `approve: ...`

### audit

- コミットなし（読み取り専用タスク）

## Committed State Rule

Downstream tasks MUST use only committed files.

- Uncommitted changes MUST NOT be treated as stable input
- If working tree is dirty → warn or stop depending on strictness

## Timing

- Commit raw before LLM processing
- Do not update wiki from uncommitted raw inputs