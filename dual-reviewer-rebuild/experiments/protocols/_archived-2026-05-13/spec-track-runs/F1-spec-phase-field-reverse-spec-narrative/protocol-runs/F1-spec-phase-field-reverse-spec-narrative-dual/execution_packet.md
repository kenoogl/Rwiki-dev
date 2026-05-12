  # execution packet

  ## 1. run header

  - run label: `F1-spec-phase-field-reverse-spec-narrative-dual`
  - case id: `F1-spec-phase-field-reverse-spec`
  - track: `spec`
  - review mode: `dual_reviewer_workflow`
  - reviewed phase: `tasks`
  - operator: `spec-track-narrative-batch`

  ## 2. inputs to read

  - reviewed phase ref:
    - `.kiro/specs/phase-field-reverse-spec/tasks.md`
  - adjacent phase refs:
  - `.kiro/specs/phase-field-reverse-spec/requirements.md`
  - `.kiro/specs/phase-field-reverse-spec/design.md`
  - alignment refs:
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/spec-track-first-case-phase-field-reverse-spec.md`
  - `dual-reviewer-rebuild/docs/alignment/cross-spec-tasks-alignment.md`

  ## 3. execution steps

1. primary reading で phase-local reading を作る
2. adversarial pass で cross-phase inconsistency 仮説を出す
3. judgment で must-fix / should-fix / leave-as-is を分ける
4. reopen / recheck depth と intent-attributed issue を判定する
5. `reviewed_phase_note.md`, `alignment_artifact.yaml`, `phase_metric_snapshot.json`, `signal_linkage_note.yaml` を更新する

  ## 4. artifacts to update

  - `experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec-narrative/protocol-runs/F1-spec-phase-field-reverse-spec-narrative-dual/reviewed_phase_note.md`
  - `experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec-narrative/protocol-runs/F1-spec-phase-field-reverse-spec-narrative-dual/alignment_artifact.yaml`
  - `experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec-narrative/protocol-runs/F1-spec-phase-field-reverse-spec-narrative-dual/phase_metric_snapshot.json`
  - `experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec-narrative/protocol-runs/F1-spec-phase-field-reverse-spec-narrative-dual/signal_linkage_note.yaml`

  ## 5. success check

  1. reopen / recheck depth が埋まっている
  2. phase-local issue と cross-phase inconsistency が分離されている
  3. `intent-attributed issue` が必要時に区別されている
