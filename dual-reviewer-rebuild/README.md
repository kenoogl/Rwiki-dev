# dual-reviewer-rebuild

Review system 再構築用 repository。

## Purpose

- dual-reviewer runtime を repo 内完結で再構築する
- evidence-driven self-improvement loop を formalize する
- evaluation と paper input を runtime から分離する

## Structure

- `intent/` = system intent と非目標
- `operations/` = deploy / trust / workflow / invalidation
- `CONVENTIONS.md` = status / 用語 / naming の共通規約
- `DOCUMENT_INDEX.md` = 文書と主要 artifact の所在 index
- `.kiro/specs/` = `cc-sdd` の spec 正本
- `runtime/` = prompts / policies / schemas / skills / validators
- `experiments/` = protocol / runs / analysis
- `learning/` = 改善提案と採否履歴
- `paper/` = reports / figures / tables

## Status

v1 prototype 完成。manual implementation conformance review と short rerun まで完了。

## Workflow Note

- `intent/` または any `requirements.md` の意味を変えた場合は、trace matrix と requirements alignment を更新する
- trace matrix 更新トリガーの詳細は [intent-to-requirements-trace-matrix.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/traceability/intent-to-requirements-trace-matrix.md) を正本とする
- status の正本は各 feature の `spec.json`
