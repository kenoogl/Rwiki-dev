  # execution packet

  ## 1. run header

  - run label: `F1-phase-field-cpp-r2-dual-only`
  - case id: `F1-phase-field-cpp-r2`
  - track: `implementation`
  - review mode: `dual_review`
  - runtime review mode: `runtime_mediated`
  - treatment: `dual`
  - operator: `phase-field-pilot-r2`

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
3. judgment なしで reopen target を決め、runtime artifact と protocol note を更新する
4. `implementation_review_note.md`, `signal_linkage_note.yaml`, `downstream_rework_log.yaml`, `conformance_review_result.yaml` を埋める

  ## 4. runtime artifacts to inspect

  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp-r2/runtime-runs/run-20260512T124939Z-0b72fa40/review_case.json`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp-r2/runtime-runs/run-20260512T124939Z-0b72fa40/decisions/decision_units.json`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp-r2/runtime-runs/run-20260512T124939Z-0b72fa40/validation/validator_result.json`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp-r2/runtime-runs/run-20260512T124939Z-0b72fa40/validation/invalidation_markers.json`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp-r2/runtime-runs/run-20260512T124939Z-0b72fa40/derived/comparison_eligibility_note.json`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp-r2/runtime-runs/run-20260512T124939Z-0b72fa40/derived/invalid_run_triage_note.json`

  ## 5. protocol artifacts to update

  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp-r2/protocol-runs/F1-phase-field-cpp-r2-dual-only/implementation_review_note.md`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp-r2/protocol-runs/F1-phase-field-cpp-r2-dual-only/signal_linkage_note.yaml`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp-r2/protocol-runs/F1-phase-field-cpp-r2-dual-only/downstream_rework_log.yaml`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp-r2/protocol-runs/F1-phase-field-cpp-r2-dual-only/conformance_review_result.yaml`

  ## 6. success check

  1. implementation-local issue と upstream inconsistency が分離されている
  2. disagreement / caveat が保存されている
  3. reopen target が必要時に埋まっている
