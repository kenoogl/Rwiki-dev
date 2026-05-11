# 2026-05-11 heat3d-main design local review

## 1. review scope

- review type: `design local review`
- reviewed feature: `heat3d-main`
- reviewed artifact:
  - [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/design.md:1)
- review focus:
  - top-level orchestration が physics owner を再定義していないか
  - solver 呼び出し前の runtime field 準備が閉じているか
  - logging / baseline boundary が application concern に留まっているか

## 2. findings

### Finding 1

- title: runtime initialization omitted `mask` creation and isothermal boundary reflection
- references:
  - [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/design.md:150)
  - [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/design.md:160)
  - [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/design.md:178)
- description:
  - 初稿では `theta` 初期化だけを main の責務としており、solver input に必須な `mask` と isothermal boundary reflection の owner が抜けていた。
- impact:
  - `heat3d-linear-solver` の unknown-set contract を top-level で満たせず、case-model か solver に責務が漏れる余地があった。
- recommended action:
  - runtime field initializer を `theta + mask` 初期化へ拡張し、`foundation.apply_isothermal!` の呼び出し責務を main に置く。
- status: `fixed`

## 3. metric snapshot

- `phase_blocking_issue_count`: `1`
- `phase_major_correction_count`: `1`
- `phase_intent_attributed_issue_count`: `0`

## 4. disposition summary

- immediate disposition:
  - `FieldInitializer` と `RunCoordinator` を修正し、`mask` 初期化、isothermal boundary reflection、`SolverOutcome -> SimulationResult` wrapping を明記した。
- downstream implication:
  - `main` は top-level runtime preparation と reporting のみに責務を絞り、physics default や solver internals を再定義しない。
- next action:
  - remaining active feature の local design review を揃えた後、horizontal design review wave へ進む。
