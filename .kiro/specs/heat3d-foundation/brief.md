# Brief: heat3d-foundation

> 出典: [intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1), [thermal_simulator_spec.md](/Users/Daily/Development/DR-heat3d/spec_seed/thermal_simulator_spec.md:1), [heat3d research.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/research.md:1)

## Problem

`heat3d` の下流 feature が共通に依存する grid / material / geometry / boundary / result contract を 1 か所で固定しないと、solver、case model、main がそれぞれ別の配列規約や境界解釈を持ち込みうる。

## Desired Outcome

- shared types と array contract が固定される
- X/Y/Z grid contract と `z_range` 導出規則が固定される
- material table と geometry/material assignment primitive が固定される
- boundary-condition data contract と application helper contract が固定される

## Scope

- **In**:
  - shared types
  - grid generation contract
  - fixed Z grid contract
  - material table
  - geometry inclusion and assignment primitives
  - boundary-condition types and application helper contract
  - shared result/log contract
- **Out**:
  - linear solve
  - fixed MVP case assembly
  - main orchestration

## Upstream / Downstream

- **Upstream**: `heat3d-spec` intent / canonical source
- **Downstream**: `heat3d-linear-solver`, `heat3d-case-model`, `heat3d-main`
