# Implementation Plan

> `heat3d-linear-solver` は backward Euler 1 step の numerical kernel を実装する。`foundation` が fixed した shared contract を入力に取り、`case-model` や `main` に physics owner が逆流しないよう、solver-local workspace と convergence logic をこの feature で閉じる。

## 1. Solver-local type と kernel pipeline を実装する

- [ ] 1.1 solver-local type と workspace allocator を実装する
  - `SolverInput`, `CoefficientWorkspace`, `SolverState`, `SolverOutcome` を `src/linear_solver/types.jl` に実装する。
  - `allocate_coefficient_workspace(shape)` と `allocate_solver_state(shape)` を `linear-solver` の owner API として置く。
  - 観測条件: coefficient と iterative state の allocation site が solver feature に固定され、`main` が内部 vector 群を再定義しない。
  - _Requirements: 1, 4_
  - _Boundary: LinearSolver.Types_
  - _Depends: heat3d-foundation 1.6_

- [ ] 1.2 RHS builder と coefficient builder を実装する
  - `build_rhs!` で `theta`, `qvol`, `rho`, `cp`, `dt`, `BoundaryContributions.rhs_term` を使う。
  - `BoundaryContributions` は `foundation.allocate_boundary_contributions(shape)` で 1 step ごとに確保された payload を受け取る前提にする。
  - `build_coefficients!` で x/y/z face coefficient と convection 由来 diagonal を構築する。
  - 観測条件: boundary-derived RHS / diagonal term が `foundation.BoundaryContributions` からそのまま消費される。
  - _Requirements: 1, 2_
  - _Boundary: LinearSolver.RHSBuilder, LinearSolver.CoefficientBuilder_
  - _Depends: 1.1_

- [ ] 1.3 operator kernel と GS preconditioner を実装する
  - `apply_operator!` を dense 3D array loop で実装する。
  - `gs_sweep!` を `mask` と active `z_range` に従って実装する。
  - 観測条件: unknown set 判定と preconditioner sweep が solver feature 内で閉じる。
  - _Requirements: 2, 3_
  - _Boundary: LinearSolver.OperatorKernel, LinearSolver.GaussSeidelPreconditioner_
  - _Depends: 1.1, 1.2_

- [ ] 1.4 PBiCGSTAB loop と residual evaluator を実装する
  - `solve!` で iteration loop、relative residual、`ResidualHistory` 生成、`SolverOutcome` assembly を実装する。
  - `solve!` 開始時に `foundation.allocate_boundary_contributions(shape)`, `allocate_coefficient_workspace(shape)`, `allocate_solver_state(shape)` を呼び、1 step 用 workspace lifecycle を solver feature 内で閉じる。
  - convergence failure 時も `iterations`, `final_residual`, `converged` を埋めて返す。
  - 観測条件: `main` は `SolverOutcome` を受け取るだけで residual history を再計算しない。
  - _Requirements: 4_
  - _Boundary: LinearSolver.PBiCGSTABSolver, LinearSolver.ResidualEvaluator_
  - _Depends: 1.1, 1.2, 1.3_

- [ ] 1.5 solver 単体 smoke test を整備する
  - `build_rhs!`, `build_coefficients!`, `apply_operator!`, `solve!` を最小ケースで確認する。
  - deterministic な 1 step solve と residual monotonicity の最低限確認を置く。
  - 観測条件: `main` を介さなくても solver contract の破綻を検出できる。
  - _Requirements: 5_
  - _Boundary: linear-solver tests_
  - _Depends: 1.2, 1.3, 1.4_
