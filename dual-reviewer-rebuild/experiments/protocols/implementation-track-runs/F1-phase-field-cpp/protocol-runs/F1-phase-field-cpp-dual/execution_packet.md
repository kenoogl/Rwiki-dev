  # execution packet

  ## 1. run header

  - run label: `F1-phase-field-cpp-dual`
  - case id: `F1-phase-field-cpp`
  - track: `implementation`
  - review mode: `dual_reviewer_workflow`
  - runtime review mode: `runtime_mediated`
  - treatment: `dual+judgment`
  - operator: `phase-field-pilot`

  ## 2. inputs to read

  - implementation snapshot ref:
    - `.kiro/methodology/dual-reviewer-spec-driven-paper/phase-field-implementation-phase-first-snapshot.md`
  - upstream spec refs:
  - `.kiro/specs/phase-field-reverse-spec/intent.md`
  - `.kiro/specs/phase-field-reverse-spec/requirements.md`
  - `.kiro/specs/phase-field-reverse-spec/design.md`
  - `.kiro/specs/phase-field-reverse-spec/tasks.md`
  - governance refs:
  - `dual-reviewer-rebuild/docs/coordination/implementation-conformance-review.md`
  - `dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md`
  - `dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md`

  ## 3. execution steps

1. primary reading を作る
2. adversarial pass で counter-hypothesis と caveat を出す
3. judgment で must-fix / should-fix / leave-as-is を分ける
4. reopen target を決め、runtime artifact と protocol note を更新する
5. `implementation_review_note.md`, `signal_linkage_note.yaml`, `downstream_rework_log.yaml`, `conformance_review_result.yaml` を埋める

  ## 4. runtime artifacts to inspect

  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/runtime-runs/run-20260509T225157Z-207549ab/review_case.json`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/runtime-runs/run-20260509T225157Z-207549ab/decisions/decision_units.json`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/runtime-runs/run-20260509T225157Z-207549ab/validation/validator_result.json`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/runtime-runs/run-20260509T225157Z-207549ab/validation/invalidation_markers.json`

  ## 5. protocol artifacts to update

  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/protocol-runs/F1-phase-field-cpp-dual/implementation_review_note.md`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/protocol-runs/F1-phase-field-cpp-dual/signal_linkage_note.yaml`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/protocol-runs/F1-phase-field-cpp-dual/downstream_rework_log.yaml`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/protocol-runs/F1-phase-field-cpp-dual/conformance_review_result.yaml`

  ## 6. success check

  1. implementation-local issue と upstream inconsistency が分離されている
  2. disagreement / caveat が保存されている
  3. reopen target が必要時に埋まっている
