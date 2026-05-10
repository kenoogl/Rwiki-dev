  # execution packet

  ## 1. run header

  - run label: `F1-spec-phase-field-single`
  - case id: `F1-spec-phase-field-reverse-spec`
  - track: `spec`
  - review mode: `single_review`
  - reviewed phase: `tasks`
  - operator: `phase-field-spec-pilot`

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

1. tasks を読み、phase-local issue / ambiguity / ordering issue を抽出する
2. adjacent phase と照合し、cross-phase inconsistency を列挙する
3. `reviewed_phase_note.md` と `alignment_artifact.yaml` を埋める
4. `phase_metric_snapshot.json` と `signal_linkage_note.yaml` を更新する

  ## 4. artifacts to update

  - `experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec/protocol-runs/F1-spec-phase-field-single/reviewed_phase_note.md`
  - `experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec/protocol-runs/F1-spec-phase-field-single/alignment_artifact.yaml`
  - `experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec/protocol-runs/F1-spec-phase-field-single/phase_metric_snapshot.json`
  - `experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec/protocol-runs/F1-spec-phase-field-single/signal_linkage_note.yaml`

  ## 5. success check

  1. reopen / recheck depth が埋まっている
  2. phase-local issue と cross-phase inconsistency が分離されている
  3. `intent-attributed issue` が必要時に区別されている
