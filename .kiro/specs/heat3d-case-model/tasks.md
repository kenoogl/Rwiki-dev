# Implementation Plan

> `heat3d-case-model` は canonical MVP の geometry, material assignment, heat source, boundary set を deterministic に組み立てる。ここでは constants の owner と assembled bundle の shape を implementation order に落とし、`main` が再解釈なしで solver に渡せる状態まで作る。

## 1. Canonical case assembly pipeline を実装する

- [ ] 1.1 `AssembledCase` と canonical config / boundary set builder を実装する
  - `AssembledCase` を `src/case_model/types.jl` に実装する。
  - `build_canonical_config()` と `build_canonical_boundary_set()` を canonical owner API として実装する。
  - 観測条件: numeric defaults と boundary set construction が `case-model` だけに存在する。
  - _Requirements: 1, 3, 4_
  - _Boundary: CaseModel.Types, CanonicalConfigBuilder, BoundarySetBuilder_
  - _Depends: heat3d-foundation 1.6_

- [ ] 1.2 geometry recipe と material field build を実装する
  - `build_geometry_recipe()` で primitive order を固定する。
  - `build_material_fields(grid, recipe)` で `id -> alpha/rho/cp` を構築する。
  - `FieldBuffers` は `foundation.allocate_field_buffers(shape)` で確保し、case assembly scratch としてのみ使う。canonical runtime path では `theta` と `mask` を含む state container としては使わない。
  - 観測条件: material assignment order と resin fill rule が 1 か所に閉じる。
  - _Requirements: 2, 4_
  - _Boundary: GeometryRecipeBuilder, MaterialAssignmentEngine_
  - _Depends: 1.1_

- [ ] 1.3 heat source と assembled case bundling を実装する
  - `build_heat_source!` で `qvol` を埋める。
  - `build_canonical_case()` で `config -> grid -> recipe -> material fields -> qvol -> boundary_set -> z_range` の順に assembly する。
  - `FieldBuffers` は assembly 中に展開し、返却時には `AssembledCase` の individual field へ unpack して保持する。
  - 観測条件: `AssembledCase` が `grid`, `id`, `alpha`, `rho`, `cp`, `qvol`, `boundary_set`, `z_range` を揃えた immutable input になる。
  - _Requirements: 3, 4_
  - _Boundary: HeatSourceBuilder, CaseAssembler_
  - _Depends: 1.1, 1.2_

- [ ] 1.4 case-model smoke test を整備する
  - canonical config constant、material id coverage、nonempty active `z_range`、`AssembledCase` field shape を確認する。
  - representative geometry recipe が deterministic に再生成されることを確認する。
  - 観測条件: assembled bundle shape の drift が main 実装前に検出できる。
  - _Requirements: 1, 2, 3, 4_
  - _Boundary: case-model tests_
  - _Depends: 1.1, 1.2, 1.3_
