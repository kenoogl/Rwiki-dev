# dual-reviewer-rebuild Working Notes

## 親規律の差分上書き

- 親 `Rwiki-v2-code-mod/CLAUDE.md` の `/kiro-*` 系コマンドおよび `.kiro/specs/` 直下への参照は、本サブツリー配下の作業には適用しない。本サブツリーは独自の intent 駆動ワークフローを用い、`dual-reviewer-rebuild/.kiro/specs/` を参照先とする。

## Development Mode

- This repository uses an intent-driven workflow.
- `intent/` and `operations/` are upstream inputs to `.kiro/specs/`.
- Runtime changes must be traceable to evidence and spec updates.

## Core Rules

- Keep prompts, policies, schemas, and validators inside the repo.
- Do not rely on repo-external memory for steady-state behavior.
- Treat raw evidence as immutable.
- Route behavior changes through spec updates, not ad-hoc prompt edits.

## Current Priority

1. Fix upper-layer documents.
2. Write requirements for the 5 specs.
3. Migrate foundation artifacts.
