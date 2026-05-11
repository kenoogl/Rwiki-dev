# Requirements Document

> Status: superseded pre-restart draft. この文書は feature decomposition 導入前に起草された旧 draft であり、fresh requirements wave の active input ではない。

## Introduction

本仕様は、3 次元非定常熱伝導シミュレータの Julia 実装を対象とする。実装者は canonical source [thermal_simulator_spec.md](/Users/Daily/Development/DR-heat3d/spec_seed/thermal_simulator_spec.md:1) と [intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1) を参照し、3 次元直交格子上で材料配置、内部発熱、境界条件を与えた温度場の時間発展を計算できる実装を構築する。

本 requirements は `heat3d` を intent-governed development の representative case として downstream artifact に接続するため、MVP の numerical contract、data contract、software boundary、acceptance target を self-contained に固定する。

## Boundary Context

- In scope:
  - 3 次元直交格子上の非定常熱伝導解析
  - X/Y 一様格子、Z 非一様格子
  - セル単位の材料割当、内部発熱、境界条件反映
  - 後退 Euler による 1 ステップ時間積分
  - GS 前処理付き PBiCGSTAB による線形解法
  - Julia 実装とその単体試験
  - 標準出力または `log.txt` へのテキストログ出力
- Out of scope:
  - GUI
  - 可視化
  - CSV 出力
  - 複数ケース一括実行
  - 並列化
  - GPU
  - 外部設定ファイル入力
- Fixed MVP assumptions:
  - 実装言語は Julia
  - MVP は固定ケースのみを扱う
  - 初期温度は `300.0 K`
  - 時間刻みは `Δt = 1000.0 s`
  - 実行ステップ数は `1`

## Requirements

### Requirement 1: 物理モデルと離散化

**Objective:** 熱解析実装者として、canonical source と等価な 3 次元非定常熱伝導の numerical contract を固定したい。downstream design/implementation で支配方程式や stencil 解釈がぶれないように。

#### Acceptance Criteria

1. The simulator shall solve the transient heat conduction equation `∂T/∂t = ∇ · (α ∇T) + q_vol / (ρ Cp)` on a 3D orthogonal grid.
2. The simulator shall treat the cell material properties as `alpha`, `rho`, and `cp`, and shall not require `conductivity` as a primary cell property.
3. The simulator shall discretize the diffusion operator with a 7-point stencil.
4. The simulator shall use uniform spacing in X and Y and a non-uniform grid in Z.
5. The simulator shall compute face diffusivity by harmonic averaging on interior cell faces.
6. The simulator shall use first-order backward Euler for time integration.

### Requirement 2: 格子と配列契約

**Objective:** 実装者として、配列サイズ、インデックス規約、固定 Z 格子を requirements 段階で固定したい。solver, boundary, geometry の配列解釈を一意にするため。

#### Acceptance Criteria

1. The simulator shall represent physical cells as `NX × NY × NZ` and storage arrays as `MX × MY × MZ = (NX+2) × (NY+2) × (NZ+2)`.
2. The simulator shall use guard-cell indexing such that `1` and `N+2` positions are guard cells and `2..N+1` are physical cells along each axis.
3. The simulator shall provide at least the arrays `theta`, `rhs`, `mask`, `rho`, `cp`, `alpha`, `id`, and `qvol` with size `[MX,MY,MZ]`.
4. The simulator shall interpret `mask = 1.0` as an active unknown and `mask = 0.0` as boundary-fixed or excluded from the linear solve.
5. The simulator shall build `dx = Lx / NX` and `dy = Ly / NY` for `Lx = 1.2e-3 m` and `Ly = 1.2e-3 m`.
6. The simulator shall represent the Z grid by boundary coordinates `Z[1..MZ]` and derived representative widths `ΔZ[k]`.
7. For the MVP, the simulator shall use the fixed Z grid with `NZ = 31` and `MZ = 33` exactly as specified in the canonical source.
8. The simulator shall compute the active update range in Z from the top and bottom boundary-condition types such that `z_start` and `z_end` follow the canonical rules for `ISOTHERMAL`, `HEAT_FLUX`, and `CONVECTION`.

### Requirement 3: 材料・ジオメトリ・発熱

**Objective:** 熱解析実装者として、材料割当と発熱分布を fixed case として再現したい。MVP case の geometry と source term が実装ごとに変わらないように。

#### Acceptance Criteria

1. The simulator shall provide the material table with IDs `1..7` and the canonical values for `alpha`, `rho`, and `cp`.
2. The simulator shall ensure every physical cell ends with exactly one material ID.
3. The simulator shall assign any unfilled physical cell to `resin`.
4. The simulator shall construct the canonical geometry consisting of substrate, three silicon layers, heatsink, power-grid blocks, TSVs, and solder bumps.
5. The simulator shall determine shape inclusion using the canonical volume rules: `50%` volume threshold for cuboids and sampling-based `50%` inclusion for cylinders and spheres.
6. For the MVP, the simulator shall use sampling count `50` on each axis for cylinder and sphere inclusion tests.
7. The simulator shall apply material assignment in the fixed order: `power grid -> TSV -> plate layers -> solder bumps -> resin`.
8. The simulator shall set `qvol = Q_src` only for cells with `id == 7`, with `Q_src = 1.6e11 W/m^3`.
9. The simulator shall set `qvol = 0` for all cells whose material ID is not `7`.

### Requirement 4: 境界条件の表現と反映

**Objective:** 実装者として、3 種の境界条件を同じ data contract で扱いたい。solver と boundary 処理の責務境界を固定し、符号解釈のぶれを防ぐため。

#### Acceptance Criteria

1. The simulator shall support exactly three boundary-condition types: `ISOTHERMAL`, `HEAT_FLUX`, and `CONVECTION`.
2. Each boundary face shall carry the attributes `type`, `temperature`, `heat_flux`, `heat_transfer_coefficient`, and `ambient_temperature`, and unused attributes may be stored as zero.
3. For the MVP, the simulator shall build the fixed boundary set: `x_minus`, `x_plus`, `y_minus`, `y_plus` as `CONVECTION(h=5.0, T_amb=300.0)`, `z_minus` as `ISOTHERMAL(T=300.0)`, and `z_plus` as `HEAT_FLUX(q=100000.0)`.
4. When applying an isothermal boundary, the simulator shall mark the boundary region as masked out and shall enforce the adjacent physical-cell temperature to the specified temperature.
5. When applying a heat-flux boundary, the simulator shall mark the boundary region as masked out and shall add the boundary contribution to the RHS.
6. When applying a convection boundary, the simulator shall mark the boundary region as masked out and shall reflect both the diagonal coefficient contribution and ambient-temperature RHS contribution.
7. The simulator shall apply the canonical sign convention such that minus-side faces contribute positive inward flux and plus-side faces treat positive flux as outward loss with negative contribution.

### Requirement 5: 線形系構築と反復解法

**Objective:** 実装者として、backward Euler の 1 ステップ更新を canonical solver contract で解きたい。RHS, diagonal contribution, residual check の解釈が downstream で変質しないように。

#### Acceptance Criteria

1. The simulator shall initialize all cells to `300.0 K` before the first time step.
2. For the MVP, the simulator shall execute exactly one time step with `Δt = 1000.0 s`.
3. The simulator shall construct the RHS for each active cell as `rhs = - ( T_old / Δt + (qvol + q_boundary) / (ρ Cp) )`.
4. The simulator shall compute X and Y face coefficients using harmonic-averaged diffusivity divided by `dx^2` and `dy^2`.
5. The simulator shall compute Z face coefficients using the canonical non-uniform-grid relation based on `ΔZ[k]` and neighbor distance.
6. For a convection boundary adjacent cell, the simulator shall add the canonical convection contribution to the diagonal term and shall reflect the ambient-temperature term in the RHS.
7. The simulator shall implement `PBiCGSTAB` as the required MVP linear solver.
8. The simulator shall implement a GS smoother as the required MVP preconditioner.
9. The solver interface shall accept at least `theta`, `rhs`, `alpha`, `rho`, `cp`, `mask`, `dx`, `dy`, `Z`, `ΔZ`, `z_range`, boundary-derived coefficients, `tolerance`, and `max_iterations`.
10. The solver shall return updated `theta`, `iterations`, `final_residual`, and `converged`.
11. The solver shall use `max_iterations = 8000`, `tolerance = 1.0e-4`, and relative residual `residual_rms / initial_residual_rms` as the convergence criterion.
12. The solver shall declare convergence only when `relative_residual < tolerance`.

### Requirement 6: ソフトウェア構成と実行入口

**Objective:** 実装者として、MVP を新規ディレクトリから self-contained に立ち上げたい。module 分割、case construction、main entrypoint の最低責務を固定するため。

#### Acceptance Criteria

1. The implementation shall use the canonical project structure with `src/` and `test/`, containing at least `types.jl`, `grid.jl`, `materials.jl`, `geometry.jl`, `boundary.jl`, `solver.jl`, `case_model.jl`, `main.jl`, and `test/runtests.jl`.
2. `types.jl` shall define the data structures needed for material properties, boundary conditions, simulation configuration, simulation result, and work buffers.
3. `grid.jl` shall provide functions to build the X/Y grid, build the fixed Z grid, compute `ΔZ`, and compute the active Z range.
4. `materials.jl` shall provide the material table and the mapping from material ID to cell properties.
5. `geometry.jl` shall provide the shape-inclusion logic and material-ID array construction.
6. `boundary.jl` shall provide boundary-condition construction and application to `mask`, `theta`, and boundary contributions.
7. `solver.jl` shall provide RHS construction, matrix-vector application, residual evaluation, GS preconditioning, and PBiCGSTAB.
8. `case_model.jl` shall build the fixed MVP case including grid, materials, geometry, heating, and boundary conditions.
9. `main.jl` shall build the case, run preprocessing, execute the one-step solve, and emit the canonical text log.
10. The MVP shall not require an external configuration file or CLI arguments.

### Requirement 7: ログ出力と結果返却

**Objective:** 実装者および検証担当として、数値実行の最小観測点を固定したい。初回 baseline 固定と後続回帰に必要な値を取得できるように。

#### Acceptance Criteria

1. The simulator shall write the canonical execution log either to standard output or to `log.txt`.
2. The execution log shall include grid size, `dx`, `dy`, `Δt`, solver name, tolerance, per-iteration residuals, final `theta min`, final `theta max`, final `L2 norm`, and elapsed execution time.
3. Each iteration-residual log line shall use the canonical two-column form `<iteration> <residual_in_scientific_notation>`.
4. The returned `SimulationResult` shall contain at least `theta`, `iterations`, `final_residual`, `converged`, and `elapsed_seconds`.
5. The first accepted MVP run shall fix a regression baseline containing `theta_min`, `theta_max`, three representative temperatures, final residual, and iteration count.
6. The three representative regression temperatures shall be taken from the canonical point classes: center point, TSV-near point, and upper-surface-center-near point.

### Requirement 8: 受け入れ試験

**Objective:** 検証担当として、外部参照なしで pass/fail を判定したい。tasks と implementation verification の最終 target を requirements 段階で固定するため。

#### Acceptance Criteria

1. Unit tests shall verify `compute_z_range(ISOTHERMAL, HEAT_FLUX, NZ=31) == [3, 32]`.
2. Unit tests shall verify `compute_z_range(HEAT_FLUX, ISOTHERMAL, NZ=31) == [2, 31]`.
3. Unit tests shall verify the fixed Z grid has `MZ = 33` and is strictly increasing.
4. Unit tests shall verify that after material assignment every physical cell satisfies `id != 0`.
5. Unit tests shall verify that only cells with `id == 7` have `qvol = Q_src`.
6. Unit tests shall verify that after applying an isothermal boundary, cells adjacent to that face are fixed at `300.0 K`.
7. In a conservation test with uniform material, uniform initial temperature `300 K`, zero heating, and all-isothermal `300 K` boundaries, the simulator shall keep all cells within `300 K ± 1e-10` after one step.
8. In a heating-response test with uniform material, effectively adiabatic boundaries, and only one heated center cell, the simulator shall raise the heated-cell temperature above the initial value and shall not produce negative temperatures or `NaN`.
9. In the canonical MVP case `NX=240, NY=240, NZ=31`, the simulator shall complete without abnormal termination.
10. In the canonical MVP case, the solver shall finish within `8000` iterations.
11. In the canonical MVP case, `final_residual` shall be less than `1.0e-4`.
12. In the canonical MVP case, the result shall satisfy `theta_min >= 250.0`, `theta_max <= 2000.0`, and `theta_max > theta_min`.
