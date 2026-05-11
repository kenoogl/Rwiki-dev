# implementation evidence summary

> derived artifact only. source of truth remains the implementation files under `/Users/Daily/Development/DR-heat3d`, validation command output, and workflow trace.

_作成: 2026-05-11_  
_status: implementation completed v0.1_

## 1. scope

- coding target:
  - `/Users/Daily/Development/DR-heat3d`
- package root:
  - [/Users/Daily/Development/DR-heat3d/Project.toml](/Users/Daily/Development/DR-heat3d/Project.toml:1)
- root module:
  - [/Users/Daily/Development/DR-heat3d/src/Heat3D.jl](/Users/Daily/Development/DR-heat3d/src/Heat3D.jl:1)

## 2. implemented feature slices

- foundation:
  - [/Users/Daily/Development/DR-heat3d/src/foundation/types.jl](/Users/Daily/Development/DR-heat3d/src/foundation/types.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/foundation/grid.jl](/Users/Daily/Development/DR-heat3d/src/foundation/grid.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/foundation/materials.jl](/Users/Daily/Development/DR-heat3d/src/foundation/materials.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/foundation/geometry_primitives.jl](/Users/Daily/Development/DR-heat3d/src/foundation/geometry_primitives.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/foundation/boundary_support.jl](/Users/Daily/Development/DR-heat3d/src/foundation/boundary_support.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/foundation/result_contracts.jl](/Users/Daily/Development/DR-heat3d/src/foundation/result_contracts.jl:1)
- linear solver:
  - [/Users/Daily/Development/DR-heat3d/src/linear_solver/types.jl](/Users/Daily/Development/DR-heat3d/src/linear_solver/types.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/linear_solver/rhs_builder.jl](/Users/Daily/Development/DR-heat3d/src/linear_solver/rhs_builder.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/linear_solver/coefficient_builder.jl](/Users/Daily/Development/DR-heat3d/src/linear_solver/coefficient_builder.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/linear_solver/operator_kernel.jl](/Users/Daily/Development/DR-heat3d/src/linear_solver/operator_kernel.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/linear_solver/residuals.jl](/Users/Daily/Development/DR-heat3d/src/linear_solver/residuals.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/linear_solver/gs_preconditioner.jl](/Users/Daily/Development/DR-heat3d/src/linear_solver/gs_preconditioner.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/linear_solver/pbicgstab.jl](/Users/Daily/Development/DR-heat3d/src/linear_solver/pbicgstab.jl:1)
- case-model:
  - [/Users/Daily/Development/DR-heat3d/src/case_model/types.jl](/Users/Daily/Development/DR-heat3d/src/case_model/types.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/case_model/canonical_config.jl](/Users/Daily/Development/DR-heat3d/src/case_model/canonical_config.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/case_model/geometry_recipe.jl](/Users/Daily/Development/DR-heat3d/src/case_model/geometry_recipe.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/case_model/material_assignment.jl](/Users/Daily/Development/DR-heat3d/src/case_model/material_assignment.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/case_model/heat_source.jl](/Users/Daily/Development/DR-heat3d/src/case_model/heat_source.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/case_model/boundary_sets.jl](/Users/Daily/Development/DR-heat3d/src/case_model/boundary_sets.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/case_model/assemble_case.jl](/Users/Daily/Development/DR-heat3d/src/case_model/assemble_case.jl:1)
- main:
  - [/Users/Daily/Development/DR-heat3d/src/main/field_initializer.jl](/Users/Daily/Development/DR-heat3d/src/main/field_initializer.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/main/run_coordinator.jl](/Users/Daily/Development/DR-heat3d/src/main/run_coordinator.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/main/text_log_emitter.jl](/Users/Daily/Development/DR-heat3d/src/main/text_log_emitter.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/main/baseline_probes.jl](/Users/Daily/Development/DR-heat3d/src/main/baseline_probes.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/main/entrypoint.jl](/Users/Daily/Development/DR-heat3d/src/main/entrypoint.jl:1)
  - [/Users/Daily/Development/DR-heat3d/src/bin/heat3d_main.jl](/Users/Daily/Development/DR-heat3d/src/bin/heat3d_main.jl:1)
- tests:
  - [/Users/Daily/Development/DR-heat3d/test/runtests.jl](/Users/Daily/Development/DR-heat3d/test/runtests.jl:1)

## 3. implementation rework log

| seq | class | file | issue | disposition |
|---|---|---|---|---|
| 1 | `package metadata` | [/Users/Daily/Development/DR-heat3d/Project.toml](/Users/Daily/Development/DR-heat3d/Project.toml:1) | Julia 1.12 で `LinearAlgebra` / `Printf` が依存宣言されておらず precompile が失敗した | fixed |
| 2 | `module boundary` | [/Users/Daily/Development/DR-heat3d/src/Heat3D.jl](/Users/Daily/Development/DR-heat3d/src/Heat3D.jl:1) | feature 分割後の submodule export/import が不足し、`GridData` などの shared contract が下流 module で見えなかった | fixed |
| 3 | `shared contract` | [/Users/Daily/Development/DR-heat3d/src/foundation/geometry_primitives.jl](/Users/Daily/Development/DR-heat3d/src/foundation/geometry_primitives.jl:1) | guard cell の `id` が `0` のままで、material property mapping が `KeyError` を出した | fixed |

## 4. validation

- command:
  - `julia --project=. test/runtests.jl`
- workdir:
  - `/Users/Daily/Development/DR-heat3d`
- result:
  - `passed`

validated groups:

- `grid and boundary contract`
- `case-model contract`
- `solver invariants`
- `main integration`

## 5. counted observations

- `implementation_blocking_issue_count: 3`
- `implementation_major_correction_count: 3`
- `implementation_recheck_count: 1`
- `upstream_phase_reopen_required_count: 0`
- `review_acquisition_rerun_required_count: 0`

## 6. residual gap

- current implementation evidence の primary validation は unit/smoke 中心である
- canonical-scale condition の run は別途実行できているが、main paper では admission gate ではなく supplementary behavioral evidence として扱う
- したがって、`code exists and passes reduced validation` と `reference behavior is adequately constrained` は区別して読む必要がある

## 7. operational reading

今回の implementation では、requirements/design/tasks へ遡る reopen は発生しなかった。手戻りはすべて implementation local に閉じ、package metadata、module boundary、guard-cell material contract の 3 件で止まった。
