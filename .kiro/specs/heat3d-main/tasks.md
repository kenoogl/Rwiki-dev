# Implementation Plan

> `heat3d-main` は canonical MVP の top-level orchestrator である。ここでは root module の final include/export order、runtime field 初期化、solver 呼び出し、log/baseline 出力、end-to-end smoke test を implementation order に落とす。

## 1. Top-level orchestration と reporting path を実装する

- [ ] 1.1 root module finalization と entrypoint を実装する
  - `src/Heat3D.jl` の final include order を `foundation -> linear_solver -> case_model -> main` に固定する。
  - top-level export は `run_canonical_mvp` のみに寄せ、downstream feature の internal helper を root export しない。
  - `src/main/entrypoint.jl` と `src/bin/heat3d_main.jl` を実装する。
  - 観測条件: root module file owner が `main` tasks に固定され、 top-level API が 1 つに閉じる。
  - _Requirements: 1, 3_
  - _Boundary: src/Heat3D.jl, src/main/entrypoint.jl, src/bin/heat3d_main.jl_
  - _Depends: heat3d-foundation 1.6, heat3d-linear-solver 1.5, heat3d-case-model 1.4_

- [ ] 1.2 runtime field 初期化を実装する
  - `initialize_runtime_fields(case)` で `theta` と `mask` を allocate する。
  - fixed-temperature boundary を `foundation.apply_isothermal!` で `theta` と `mask` に反映する。
  - 観測条件: runtime `theta` / `mask` owner が `main` に固定され、`case-model` は run-time field を返さない。
  - _Requirements: 2_
  - _Boundary: Main.FieldInitializer_
  - _Depends: 1.1_

- [ ] 1.3 solver invocation と final result assembly を実装する
  - `run_single_step(case)` で `SolverInput` 構築、elapsed-time 計測、`SolverOutcome` の `SimulationResult` への変換を実装する。
  - MVP pass/fail 判定を solver return 後に実施する。
  - 観測条件: final `SimulationResult` と `MainRunReport` assembly が `main` だけに存在する。
  - _Requirements: 1, 2, 3, 5_
  - _Boundary: Main.RunCoordinator_
  - _Depends: 1.2, heat3d-linear-solver 1.5, heat3d-case-model 1.4_

- [ ] 1.4 text log と baseline probe collector を実装する
  - `emit_run_log(io, case, result)` と `collect_baseline_report(case, theta, result)` を実装する。
  - representative point の座標変換と baseline summary field を固定する。
  - 観測条件: human-readable log と baseline report が canonical MVP の標準出力になる。
  - _Requirements: 3, 4, 5_
  - _Boundary: Main.TextLogEmitter, Main.BaselineProbeCollector_
  - _Depends: 1.3_

- [ ] 1.5 end-to-end smoke test を整備する
  - `build_canonical_case -> initialize_runtime_fields -> run_single_step -> emit_run_log -> collect_baseline_report` の 1 step path を確認する。
  - log 出力、`MainRunReport` shape、MVP pass/fail 判定が揃っているかを見る。
  - 観測条件: review acquisition gate 前に canonical MVP 1 step path が end-to-end で確認できる。
  - _Requirements: 1, 2, 3, 4, 5_
  - _Boundary: main integration smoke test_
  - _Depends: 1.2, 1.3, 1.4, heat3d-linear-solver 1.5, heat3d-case-model 1.4_
