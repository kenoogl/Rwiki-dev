# 2026-05-11 heat3d-main tasks local review

## 1. review scope

- review type: `tasks local review`
- reviewed feature: `heat3d-main`
- reviewed artifact:
  - [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/tasks.md:1)
- review focus:
  - root module owner と top-level API owner が一意か
  - `run_single_step` 着手前に必要な cross-feature blocker が見えているか
  - end-to-end smoke test が実装順の最後に置かれているか

## 2. findings

### Finding 1

- title: end-to-end implementation blockers were only partially encoded
- references:
  - [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/tasks.md:7)
  - [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/tasks.md:14)
  - [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/tasks.md:24)
  - [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/tasks.md:30)
  - [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/tasks.md:40)
  - [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/tasks.md:46)
- description:
  - 初稿では root module finalization の external dependency は書かれていたが、`run_single_step` と end-to-end smoke test の blocker が task graph に十分現れていなかった。
- impact:
  - `main` 実装が solver/case-model completion 前に進んでいるように読め、phase wave で implementation order を再解釈する余地があった。
- recommended action:
  - task 1.3 と 1.5 に `heat3d-linear-solver 1.5`, `heat3d-case-model 1.4` 依存を明記する。
- status: `fixed`

## 3. metric snapshot

- `phase_blocking_issue_count`: `1`
- `phase_major_correction_count`: `1`
- `phase_intent_attributed_issue_count`: `0`

## 4. disposition summary

- immediate disposition:
  - run coordinator と end-to-end smoke test に cross-feature blocker を追加し、`main` の task graph を implementation order と一致させた。
- downstream implication:
  - phase wave では shared root file と shared allocator の migration timing を横断で確認できる。
- next action:
  - remaining active feature の local tasks review を揃えた後、horizontal tasks review wave へ進む。
