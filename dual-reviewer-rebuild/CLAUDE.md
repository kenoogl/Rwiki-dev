# dual-reviewer-rebuild Working Notes

## 親規律の差分上書き

- 親 `Rwiki-v2-code-mod/CLAUDE.md` の `/kiro-*` 系コマンドおよび `.kiro/specs/` 直下への参照は、本サブツリー配下の作業には適用しない。本サブツリーは独自の intent 駆動ワークフローを用い、`dual-reviewer-rebuild/.kiro/specs/` を参照先とする。

## セッション開始時の必読

本サブツリー配下で作業を始める際、最初に [operations/WORKFLOW_OVERVIEW.md](operations/WORKFLOW_OVERVIEW.md) を読む。ワークフロー全体像と文書構造マップ（HUMAN_WORKFLOW.md / REVIEW_PROTOCOL.md / 規律ファイル群への入り口）が記載されている。詳細は必要に応じて部分読み（grep + Read offset/limit）で参照する。

## Development Mode

- This repository uses an intent-driven workflow.
- `intent/` and `operations/` are upstream inputs to `.kiro/specs/`.
- Runtime changes must be traceable to evidence and spec updates.

## Core Rules

- Keep prompts, policies, schemas, and validators inside the repo.
- 外部記憶に依存しない（個人の応答品質規律は対象外）
- Treat raw evidence as immutable.
- Route behavior changes through spec updates, not ad-hoc prompt edits.

## Current Priority

1. Fix upper-layer documents.
2. Write requirements for the 5 specs.
3. Migrate foundation artifacts.

## Paths

- Memory: `.kiro/memory/MEMORY.md`
