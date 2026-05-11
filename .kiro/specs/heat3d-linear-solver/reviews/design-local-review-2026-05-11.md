# 2026-05-11 heat3d-linear-solver design local review

## 1. review scope

- review type: `design local review`
- reviewed feature: `heat3d-linear-solver`
- reviewed artifact:
  - [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/design.md:1)
- review focus:
  - solver の入出力 contract が kernel boundary に閉じているか
  - coefficient / operator / preconditioner の責務分離が明確か
  - application-level timing/reporting を吸収していないか

## 2. findings

### Finding 1

- title: solver return contract mixed kernel diagnostics with final run report
- references:
  - [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/design.md:7)
  - [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/design.md:175)
  - [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/design.md:275)
- description:
  - 初稿では solver facade の返り値を final `SimulationResult` と読める書き方にしており、application-level `elapsed_seconds` まで solver owner に見える余地があった。
- impact:
  - `main` が担うべき elapsed-time measurement と final reporting boundary が曖昧になった。
- recommended action:
  - solver-local output を `SolverOutcome` として切り出し、final `SimulationResult` は `main` で assembly すると明記する。
- status: `fixed`

## 3. metric snapshot

- `phase_blocking_issue_count`: `1`
- `phase_major_correction_count`: `1`
- `phase_intent_attributed_issue_count`: `0`

## 4. disposition summary

- immediate disposition:
  - mermaid、overview、type section、risk sectionを `SolverOutcome` 基準へ修正した。
- downstream implication:
  - `main` は solver diagnostics を受けて final run report を組み立てるだけになり、kernel/application boundary が明確になった。
- next action:
  - remaining active feature の local design review を揃えた後、horizontal design review wave へ進む。
