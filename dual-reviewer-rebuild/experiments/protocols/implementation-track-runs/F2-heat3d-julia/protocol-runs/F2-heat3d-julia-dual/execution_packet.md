  # execution packet

  ## 1. run header

  - run label: `F2-heat3d-julia-dual`
  - case id: `F2-heat3d-julia`
  - track: `implementation`
  - review mode: `dual_reviewer_workflow`
  - runtime review mode: `runtime_mediated`
  - treatment: `dual+judgment`
  - operator: `heat3d-gate-approved`

  ## 2. inputs to read

  - implementation snapshot ref:
    - `.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-julia-implementation-phase-first-snapshot.md`
  - upstream spec refs:
  - `.kiro/specs/heat3d-spec/intent.md`
  - `.kiro/specs/heat3d-spec/brief.md`
  - `.kiro/specs/heat3d-spec/research.md`
  - `.kiro/specs/heat3d-foundation/requirements.md`
  - `.kiro/specs/heat3d-linear-solver/requirements.md`
  - `.kiro/specs/heat3d-case-model/requirements.md`
  - `.kiro/specs/heat3d-main/requirements.md`
  - `.kiro/specs/heat3d-foundation/design.md`
  - `.kiro/specs/heat3d-linear-solver/design.md`
  - `.kiro/specs/heat3d-case-model/design.md`
  - `.kiro/specs/heat3d-main/design.md`
  - `.kiro/specs/heat3d-foundation/tasks.md`
  - `.kiro/specs/heat3d-linear-solver/tasks.md`
  - `.kiro/specs/heat3d-case-model/tasks.md`
  - `.kiro/specs/heat3d-main/tasks.md`
  - `/Users/Daily/Development/DR-heat3d/spec_seed/thermal_simulator_spec.md`
  - governance refs:
  - `dual-reviewer-rebuild/docs/coordination/implementation-conformance-review.md`
  - `dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md`
  - `dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-implementation-preparation.md`
  - `.kiro/specs/heat3d-spec/reviews/implementation-gate-summary.md`

  ## 3. execution steps

1. primary reading を作る
2. adversarial pass で counter-hypothesis と caveat を出す
3. judgment で must-fix / should-fix / leave-as-is を分ける
4. reopen target を決め、runtime artifact と protocol note を更新する
5. `implementation_review_note.md`, `signal_linkage_note.yaml`, `downstream_rework_log.yaml`, `conformance_review_result.yaml` を埋める

  ## 4. runtime artifacts to inspect

  - `experiments/protocols/implementation-track-runs/F2-heat3d-julia/runtime-runs/run-20260511T062535Z-70acf852/review_case.json`
  - `experiments/protocols/implementation-track-runs/F2-heat3d-julia/runtime-runs/run-20260511T062535Z-70acf852/decisions/decision_units.json`
  - `experiments/protocols/implementation-track-runs/F2-heat3d-julia/runtime-runs/run-20260511T062535Z-70acf852/validation/validator_result.json`
  - `experiments/protocols/implementation-track-runs/F2-heat3d-julia/runtime-runs/run-20260511T062535Z-70acf852/validation/invalidation_markers.json`

  ## 5. protocol artifacts to update

  - `experiments/protocols/implementation-track-runs/F2-heat3d-julia/protocol-runs/F2-heat3d-julia-dual/implementation_review_note.md`
  - `experiments/protocols/implementation-track-runs/F2-heat3d-julia/protocol-runs/F2-heat3d-julia-dual/signal_linkage_note.yaml`
  - `experiments/protocols/implementation-track-runs/F2-heat3d-julia/protocol-runs/F2-heat3d-julia-dual/downstream_rework_log.yaml`
  - `experiments/protocols/implementation-track-runs/F2-heat3d-julia/protocol-runs/F2-heat3d-julia-dual/conformance_review_result.yaml`

  ## 6. success check

  1. implementation-local issue と upstream inconsistency が分離されている
  2. disagreement / caveat が保存されている
  3. reopen target が必要時に埋まっている
