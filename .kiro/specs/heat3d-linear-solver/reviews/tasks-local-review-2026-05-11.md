# 2026-05-11 heat3d-linear-solver tasks local review

## 1. review scope

- review type: `tasks local review`
- reviewed feature: `heat3d-linear-solver`
- reviewed artifact:
  - [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/tasks.md:1)
- review focus:
  - solver-local workspace owner が `main` に逆流していないか
  - boundary payload の allocation site が shared owner と一致しているか
  - foundation 完了前に solver 実装へ入る余地が残っていないか

## 2. findings

### Finding 1

- title: foundation contract completion dependency was implicit
- references:
  - [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/tasks.md:7)
  - [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/tasks.md:13)
  - [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/tasks.md:15)
  - [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/tasks.md:17)
- description:
  - 初稿では `linear-solver` が foundation contract 完了後に着手すべきことと、`BoundaryContributions` を shared allocator から受け取ることが task graph 上で明示されていなかった。
- impact:
  - implementation order を人手で補う必要が生じ、solver 側で boundary payload shape を再定義する余地が残った。
- recommended action:
  - task 1.1 に `heat3d-foundation 1.6` 依存を明記し、task 1.2 に boundary payload の allocation rule を追記する。
- status: `fixed`

## 3. metric snapshot

- `phase_blocking_issue_count`: `1`
- `phase_major_correction_count`: `1`
- `phase_intent_attributed_issue_count`: `0`

## 4. disposition summary

- immediate disposition:
  - solver-local type task に foundation 完了依存を追加し、RHS/coefficient task に boundary payload 受け渡し規則を追記した。
- downstream implication:
  - phase wave では solver/main 間の workspace allocation 境界に集中できる。
- next action:
  - remaining active feature の local tasks review を揃えた後、horizontal tasks review wave へ進む。
