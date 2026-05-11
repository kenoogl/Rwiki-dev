# 2026-05-11 heat3d-foundation requirements local review

## 1. review scope

- review type: `requirements local review`
- reviewed feature: `heat3d-foundation`
- reviewed artifact:
  - [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/requirements.md:1)
- review focus:
  - downstream `linear-solver / case-model / main` に渡す shared contract の欠落有無
  - canonical source に対する numerical ambiguity の有無
  - case-model responsibility へ漏れる material-assignment ambiguity の有無

## 2. findings

### Finding 1

- title: `ΔZ` derivation was underspecified
- references:
  - [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/requirements.md:73)
- description:
  - 旧 draft は `ΔZ[k]` を canonical rule から導くとだけ書いており、`0.5 * (Z[k+1] - Z[k-1])` と両端半減 rule が抜けていた。
- impact:
  - `heat3d-linear-solver` が別の Z-face coefficient を採る余地があった。
- recommended action:
  - exact formula を requirements に明記する。
- status: `fixed`

### Finding 2

- title: active `z_range` mapping was not explicit
- references:
  - [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/requirements.md:78)
- description:
  - 旧 draft は `z_start / z_end` を boundary type から導くとだけ書いており、`ISOTHERMAL -> 3/NZ` と `HEAT_FLUX or CONVECTION -> 2/NZ+1` の対応が抜けていた。
- impact:
  - `case-model` と `linear-solver` の active Z range がずれる余地があった。
- recommended action:
  - exact mapping を requirements に明記する。
- status: `fixed`

### Finding 3

- title: resin fallback after ordered assignment was implicit
- references:
  - [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/requirements.md:102)
- description:
  - ordered primitive applicationの後に未割当セルを `resin` で埋める rule が暗黙で、case-model の最終 fill responsibility が弱かった。
- impact:
  - `id != 0` 保証を requirements だけでは閉じられなかった。
- recommended action:
  - ordered assignment 後の `resin` fill を shared contract に追加する。
- status: `fixed`

## 3. metric snapshot

- `phase_blocking_issue_count`: `3`
- `phase_major_correction_count`: `1`
- `phase_intent_attributed_issue_count`: `0`

## 4. disposition summary

- immediate disposition:
  - requirements wording を修正し、feature-local review の blocking issue は解消した。
- downstream implication:
  - `heat3d-linear-solver` は exact `ΔZ` / `z_range` contract を前提にできる。
  - `heat3d-case-model` は final `resin` fill responsibility を shared contract として参照できる。
- next action:
  - remaining active feature の requirements draft と local review を揃える。
