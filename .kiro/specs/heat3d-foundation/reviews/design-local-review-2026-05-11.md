# 2026-05-11 heat3d-foundation design local review

## 1. review scope

- review type: `design local review`
- reviewed feature: `heat3d-foundation`
- reviewed artifact:
  - [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/design.md:1)
- review focus:
  - shared contract owner としての境界が明確か
  - downstream `linear-solver / case-model / main` に渡す型責務が閉じているか
  - `foundation` 再分割を行わずとも internal seam が残るか

## 2. findings

### Finding 1

- title: final result ownership was underspecified between solver and main
- references:
  - [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/design.md:337)
  - [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/design.md:349)
- description:
  - 初稿では `ResidualHistory` と `SimulationResult` を同じ result contract 節に置いていたが、final run report を `linear-solver` が返すのか `main` が組み立てるのかが曖昧だった。
- impact:
  - `elapsed_seconds` の owner が drift し、`main` と `linear-solver` の reporting boundary が崩れる余地があった。
- recommended action:
  - residual history payload と final `SimulationResult` assembly の owner を分けて明記する。
- status: `fixed`

## 3. metric snapshot

- `phase_blocking_issue_count`: `1`
- `phase_major_correction_count`: `1`
- `phase_intent_attributed_issue_count`: `0`

## 4. disposition summary

- immediate disposition:
  - `ResultContracts` 節を修正し、residual history payload は `linear-solver`、final `SimulationResult` assembly は `main` と明記した。
- downstream implication:
  - `heat3d-linear-solver` は solver-local diagnostics を返し、`heat3d-main` は final run report を組み立てる責務へ寄せられる。
- next action:
  - remaining active feature の local design review を揃えた後、horizontal design review wave へ進む。
