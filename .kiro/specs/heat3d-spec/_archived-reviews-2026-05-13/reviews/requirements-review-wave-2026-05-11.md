# 2026-05-11 heat3d requirements review wave

## 1. review scope

- review type: `requirements review wave`
- reviewed features:
  - [heat3d-foundation/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/requirements.md:1)
  - [heat3d-linear-solver/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/requirements.md:1)
  - [heat3d-case-model/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/requirements.md:1)
  - [heat3d-main/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/requirements.md:1)
- review focus:
  - shared owner の重複有無
  - solver / case-model / main の handoff で必要入力が欠けていないか
  - canonical MVP config の owner が複数 feature に割れていないか

## 2. findings

### Finding 1

- title: solver entry contract omitted `qvol` and `Δt`
- references:
  - [heat3d-linear-solver/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/requirements.md:83)
- description:
  - `heat3d-linear-solver` は RHS 構築を責務に含む一方、solver entry contract に `qvol` と `Δt` が明示されていなかった。
- impact:
  - `heat3d-main` と `heat3d-case-model` の handoff で、RHS 構築に必要な入力が requirements 上は閉じていなかった。
- recommended action:
  - solver entry contract に `qvol` と `Δt` を追加する。
- status: `fixed`

### Finding 2

- title: canonical config ownership was split between `case-model` and `main`
- references:
  - [heat3d-case-model/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/requirements.md:47)
  - [heat3d-main/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/requirements.md:57)
- description:
  - `case-model` が canonical `SimulationConfig` を構築すると書いている一方、`main` も `300 K`, `Δt = 1000 s`, `tolerance = 1.0e-4`, `max_iterations = 8000` を独立 owner のように保持していた。
- impact:
  - default numeric options の owner が割れ、後続 phase で drift する余地があった。
- recommended action:
  - `main` は `case-model` が供給する canonical `SimulationConfig` を消費する立場へ寄せる。
- status: `fixed`

## 3. metric snapshot

- `phase_blocking_issue_count`: `2`
- `phase_recheck_count`: `0`
- `phase_major_correction_count`: `1`
- `phase_intent_attributed_issue_count`: `0`

## 4. disposition summary

- immediate disposition:
  - `heat3d-linear-solver` と `heat3d-main` の requirements wording を修正し、wave-level blocking issue は解消した。
- downstream implication:
  - requirements alignment gate では owner 分担の整合確認に集中できる。
- next action:
  - requirements alignment gate を実施し、human requirements gate の入力境界を固定する。
