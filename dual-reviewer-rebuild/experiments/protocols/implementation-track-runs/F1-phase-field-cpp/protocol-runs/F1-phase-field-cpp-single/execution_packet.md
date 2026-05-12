  # execution packet

  ## 1. run header

  - run label: `F1-phase-field-cpp-single`
  - case id: `F1-phase-field-cpp`
  - track: `implementation`
  - review mode: `single_review`
  - runtime review mode: `runtime_mediated`
  - treatment: `single`
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

1. implementation snapshot と upstream spec refs を読む
2. implementation-local issue と upstream spec inconsistency を分離して列挙する
3. runtime 生成済み artifact を参照し、`implementation_review_note.md` を更新する
4. `signal_linkage_note.yaml`, `downstream_rework_log.yaml`, `conformance_review_result.yaml` を埋める

  ## 4. runtime artifacts to inspect

  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/runtime-runs/run-20260510T215435Z-66f7b030/review_case.json`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/runtime-runs/run-20260510T215435Z-66f7b030/decisions/decision_units.json`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/runtime-runs/run-20260510T215435Z-66f7b030/validation/validator_result.json`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/runtime-runs/run-20260510T215435Z-66f7b030/validation/invalidation_markers.json`

  ## 5. protocol artifacts to update

  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/protocol-runs/F1-phase-field-cpp-single/implementation_review_note.md`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/protocol-runs/F1-phase-field-cpp-single/signal_linkage_note.yaml`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/protocol-runs/F1-phase-field-cpp-single/downstream_rework_log.yaml`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/protocol-runs/F1-phase-field-cpp-single/conformance_review_result.yaml`

  ## 6. success check

  1. implementation-local issue と upstream inconsistency が分離されている
  2. disagreement / caveat が保存されている
  3. reopen target が必要時に埋まっている
