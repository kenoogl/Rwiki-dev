# Brief: heat3d-case-model

> 出典: [intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1), [thermal_simulator_spec.md](/Users/Daily/Development/DR-heat3d/spec_seed/thermal_simulator_spec.md:1), [heat3d research.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/research.md:1)

## Problem

MVP 固定ケースの geometry, heating, boundary set, active `z_range` を独立 feature として束ねないと、solver と main が canonical case の責務まで抱え、fixed-case contract が曖昧になる。

## Desired Outcome

- canonical MVP case assembly が固定される
- geometry placement, heating, boundary set が solver から分離される
- main が case-model を入力として使える

## Scope

- **In**:
  - canonical geometry placement
  - material assignment orchestration
  - heating distribution
  - boundary-condition set construction
  - active `z_range` derivation for the selected boundary set
- **Out**:
  - shared primitive definitions
  - linear solve
  - top-level execution orchestration

## Upstream / Downstream

- **Upstream**: `heat3d-foundation`
- **Downstream**: `heat3d-main`
