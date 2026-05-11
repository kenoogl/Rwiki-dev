# Implementation Plan

> `heat3d-foundation` は active feature 群の最上流であり、shared contract と shared helper の owner である。ここで fixed する実装順は downstream feature が同じ型、同じ格子、同じ境界 payload を前提に実装できることを優先する。

## 1. Foundation module skeleton と shared contract を実装する

- [ ] 1.1 `foundation` module 群を作成する
  - `src/foundation/types.jl`, `grid.jl`, `materials.jl`, `geometry_primitives.jl`, `boundary_support.jl`, `result_contracts.jl` を追加する。
  - root module の final include/export order は `heat3d-main` が owner であり、この task では foundation file 群の物理配置だけを固定する。
  - 観測条件: foundation file 群の物理配置が `types -> result_contracts -> grid -> materials -> geometry_primitives -> boundary_support` 順で読める。
  - _Requirements: 1, 2, 6, 7_
  - _Boundary: src/foundation/*_

- [ ] 1.2 shared type と result contract を実装する
  - `Material`, `BoundaryCondition`, `BoundaryConditionSet`, `BoundaryContributions`, `SimulationConfig`, `GridShape`, `GridData`, `FieldBuffers`, `ResidualHistory`, `SimulationResult` を `types.jl` と `result_contracts.jl` に配置する。
  - `FieldBuffers` は canonical path で直接返却しない shared container として実装し、case assembly 側が scratch として利用できる形にする。
  - 観測条件: shared struct 群の field 名と型が design で固定した contract と一致する。
  - _Requirements: 1, 2, 7_
  - _Boundary: Foundation.Types, Foundation.ResultContracts_
  - _Depends: 1.1_

- [ ] 1.3 grid helper を実装する
  - `build_grid(config)` で `NX/NY/NZ` と `MX/MY/MZ`、`dx/dy`、固定 Z ベクトル、`delta_z` を構築する。
  - `compute_active_z_range(config, boundary_set)` で active `z_range` を一意に返す。
  - 観測条件: guard cell shape と active `z_range` の判定規則が 1 か所に閉じ、downstream が再計算しない。
  - _Requirements: 2, 3_
  - _Boundary: Foundation.Grid_
  - _Depends: 1.2_

- [ ] 1.4 material catalog と geometry primitive helper を実装する
  - canonical material table (`id = 1..7`) と property lookup を `materials.jl` に実装する。
  - `contains_box`, `contains_cylinder`, `contains_sphere`, `assign_materials!` を `geometry_primitives.jl` に実装する。
  - 観測条件: material id table と ordered assignment helper が `case-model` から再定義なしで呼べる。
  - _Requirements: 4, 5_
  - _Boundary: Foundation.MaterialCatalog, Foundation.GeometryPrimitives_
  - _Depends: 1.2, 1.3_

- [ ] 1.5 boundary support と shared allocator を実装する
  - `apply_isothermal!`, `boundary_flux_term`, convection / heat-flux 用 helper を `boundary_support.jl` に実装する。
  - `allocate_field_buffers(shape)` と `allocate_boundary_contributions(shape)` を foundation 側に置き、shared owner が allocation shape を固定する。
  - `allocate_field_buffers(shape)` の consumer は `case-model`、`allocate_boundary_contributions(shape)` の consumer は `linear-solver` として固定する。
  - 観測条件: `BoundaryContributions` の allocation site が foundation helper に固定され、solver 側が payload shape を再解釈しない。
  - _Requirements: 1, 2, 6_
  - _Boundary: Foundation.BoundarySupport_
  - _Depends: 1.2, 1.3_

- [ ] 1.6 foundation smoke test を整備する
  - type field 名、guard cell shape、material table size、active `z_range`、boundary payload shape を確認する最小 unit test を追加する。
  - downstream feature が依存できる shared contract baseline を固定する。
  - 観測条件: foundation 単体 test で contract drift が検出できる。
  - _Requirements: 1, 2, 3, 4, 5, 6, 7_
  - _Boundary: foundation tests_
  - _Depends: 1.2, 1.3, 1.4, 1.5_
