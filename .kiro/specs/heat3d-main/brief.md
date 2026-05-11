# Brief: heat3d-main

> 出典: [intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1), [thermal_simulator_spec.md](/Users/Daily/Development/DR-heat3d/spec_seed/thermal_simulator_spec.md:1), [heat3d research.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/research.md:1)

## Problem

top-level entrypoint を独立 feature として切らないと、case construction、solver invocation、logging、baseline observation point が下位 feature と混ざり、implementation boundary が曖昧になる。

## Desired Outcome

- case-model と solver を束ねる実行入口が固定される
- one-step execution, logging, baseline observation point が固定される

## Scope

- **In**:
  - case orchestration
  - solver invocation
  - one-step execution
  - canonical text logging
  - regression-baseline observation points
- **Out**:
  - shared primitive definitions
  - solver internals
  - geometry / heating / boundary assembly internals

## Upstream / Downstream

- **Upstream**: `heat3d-linear-solver`, `heat3d-case-model`
- **Downstream**: なし
