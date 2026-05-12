# 2026-05-11 heat3d design review wave

## 1. review scope

- review type: `design review wave`
- reviewed features:
  - [heat3d-foundation/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/design.md:1)
  - [heat3d-linear-solver/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/design.md:1)
  - [heat3d-case-model/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/design.md:1)
  - [heat3d-main/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/design.md:1)
- review focus:
  - shared contract owner の重複有無
  - feature 間 handoff object の shape が一意に決まっているか
  - tasks phase に渡すために必要な concrete type / return contract が閉じているか

## 2. findings

### Finding 1

- title: boundary contribution payload contract was split between `foundation` and `linear-solver`
- references:
  - [heat3d-foundation/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/design.md:27)
  - [heat3d-foundation/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/design.md:187)
  - [heat3d-linear-solver/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/design.md:27)
  - [heat3d-linear-solver/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/design.md:199)
- description:
  - 初稿では `foundation` が boundary helper を持ちながら、その返却 payload shape は `linear-solver` 側の `BoundaryTerms` でも再定義されていた。
- impact:
  - boundary-derived RHS / diagonal term の owner が割れ、tasks phase で duplicate type を実装する余地があった。
- recommended action:
  - shared payload shape を `foundation.BoundaryContributions` に一本化し、`linear-solver` はそれを消費する立場へ寄せる。
- status: `fixed`

### Finding 2

- title: top-level return contract was ambiguous between `SimulationResult` and baseline summary
- references:
  - [heat3d-main/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/design.md:5)
  - [heat3d-main/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/design.md:113)
  - [heat3d-main/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/design.md:137)
- description:
  - 初稿では `run_canonical_mvp()` の返り値が `NamedTuple` とだけ書かれており、`SimulationResult` と `BaselineReport` をどう束ねるかが曖昧だった。
- impact:
  - tasks / implementation で top-level API を場当たりで決める余地が残っていた。
- recommended action:
  - final return contract を `MainRunReport` として定義し、`SimulationResult` と `BaselineReport` の束ね方を固定する。
- status: `fixed`

### Finding 3

- title: named workspace structs were referenced but not concretized
- references:
  - [heat3d-foundation/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/design.md:27)
  - [heat3d-foundation/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/design.md:223)
  - [heat3d-linear-solver/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/design.md:27)
  - [heat3d-linear-solver/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/design.md:170)
- description:
  - `FieldBuffers` と `SolverState` が boundary/ownership の説明には出ていたが、具体 shape が設計書に存在しなかった。
- impact:
  - tasks phase で allocator と workspace shape を任意解釈する余地があった。
- recommended action:
  - `FieldBuffers` と `SolverState` を concrete struct として design に追加する。
- status: `fixed`

## 3. metric snapshot

- `phase_blocking_issue_count`: `3`
- `phase_recheck_count`: `0`
- `phase_major_correction_count`: `3`
- `phase_intent_attributed_issue_count`: `0`

## 4. disposition summary

- immediate disposition:
  - boundary payload contract を `foundation` 起点へ一本化し、`main` の return contract と workspace struct 定義を具体化した。
- downstream implication:
  - design alignment gate では owner boundary と tasks-level carry-over point の確認に集中できる。
- next action:
  - design alignment gate を実施し、human design gate input を固定する。
