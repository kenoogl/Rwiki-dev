  # execution packet

  ## 1. run header

  - run label: `F3-iot-arduino-dual`
  - case id: `F3-iot-arduino`
  - track: `implementation`
  - review mode: `dual_reviewer_workflow`
  - runtime review mode: `runtime_mediated`
  - treatment: `dual+judgment`
  - operator: `iot-arduino-gate-approved`

  ## 2. inputs to read

  - implementation snapshot ref:
    - `.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-first-snapshot.md`
  - upstream spec refs:
  - `.kiro/specs/iot-arduino-spec/intent.md`
  - `.kiro/specs/iot-arduino-loop-outside-control/requirements.md`
  - `.kiro/specs/iot-arduino-watering-loop/requirements.md`
  - `.kiro/specs/iot-arduino-loop-outside-control/design.md`
  - `.kiro/specs/iot-arduino-watering-loop/design.md`
  - `.kiro/specs/iot-arduino-loop-outside-control/tasks.md`
  - `.kiro/specs/iot-arduino-watering-loop/tasks.md`
  - `/Users/Daily/Development/DR-IoT/intent.md`
  - `/Users/Daily/Development/DR-IoT/仕様.md`
  - governance refs:
  - `dual-reviewer-rebuild/docs/coordination/implementation-conformance-review.md`
  - `dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md`
  - `dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-review-acquisition-preparation.md`
  - `.kiro/specs/iot-arduino-spec/reviews/review-acquisition-gate-summary.md`

  ## 3. execution steps

1. primary reading を作る
2. adversarial pass で counter-hypothesis と caveat を出す
3. judgment で must-fix / should-fix / leave-as-is を分ける
4. reopen target を決め、runtime artifact と protocol note を更新する
5. `implementation_review_note.md`, `signal_linkage_note.yaml`, `downstream_rework_log.yaml`, `conformance_review_result.yaml` を埋める

  ## 4. runtime artifacts to inspect

  - `experiments/protocols/implementation-track-runs/F3-iot-arduino/runtime-runs/run-20260512T013548Z-4f530012/review_case.json`
  - `experiments/protocols/implementation-track-runs/F3-iot-arduino/runtime-runs/run-20260512T013548Z-4f530012/decisions/decision_units.json`
  - `experiments/protocols/implementation-track-runs/F3-iot-arduino/runtime-runs/run-20260512T013548Z-4f530012/validation/validator_result.json`
  - `experiments/protocols/implementation-track-runs/F3-iot-arduino/runtime-runs/run-20260512T013548Z-4f530012/validation/invalidation_markers.json`
  - `experiments/protocols/implementation-track-runs/F3-iot-arduino/runtime-runs/run-20260512T013548Z-4f530012/derived/comparison_eligibility_note.json`
  - `experiments/protocols/implementation-track-runs/F3-iot-arduino/runtime-runs/run-20260512T013548Z-4f530012/derived/invalid_run_triage_note.json`

  ## 5. protocol artifacts to update

  - `experiments/protocols/implementation-track-runs/F3-iot-arduino/protocol-runs/F3-iot-arduino-dual/implementation_review_note.md`
  - `experiments/protocols/implementation-track-runs/F3-iot-arduino/protocol-runs/F3-iot-arduino-dual/signal_linkage_note.yaml`
  - `experiments/protocols/implementation-track-runs/F3-iot-arduino/protocol-runs/F3-iot-arduino-dual/downstream_rework_log.yaml`
  - `experiments/protocols/implementation-track-runs/F3-iot-arduino/protocol-runs/F3-iot-arduino-dual/conformance_review_result.yaml`

  ## 6. success check

  1. implementation-local issue と upstream inconsistency が分離されている
  2. disagreement / caveat が保存されている
  3. reopen target が必要時に埋まっている
