# Brief: heat3d-linear-solver

> 出典: [intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1), [thermal_simulator_spec.md](/Users/Daily/Development/DR-heat3d/spec_seed/thermal_simulator_spec.md:1), [heat3d research.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/research.md:1)

## Problem

backward Euler の 1 ステップ更新を解く numerical kernel を独立 feature として固定しないと、RHS、係数構築、GS、PBiCGSTAB、収束判定が main や case model と混ざり、review boundary が曖昧になる。

## Desired Outcome

- RHS construction と coefficient contract が固定される
- GS preconditioner と PBiCGSTAB contract が固定される
- residual / convergence contract が固定される

## Scope

- **In**:
  - RHS construction
  - face coefficient construction
  - boundary-derived coefficient incorporation
  - matrix-vector application
  - GS preconditioning
  - PBiCGSTAB
  - residual / convergence evaluation
- **Out**:
  - shared grid/material/boundary definitions
  - fixed case assembly
  - top-level execution orchestration

## Upstream / Downstream

- **Upstream**: `heat3d-foundation`
- **Downstream**: `heat3d-main`
