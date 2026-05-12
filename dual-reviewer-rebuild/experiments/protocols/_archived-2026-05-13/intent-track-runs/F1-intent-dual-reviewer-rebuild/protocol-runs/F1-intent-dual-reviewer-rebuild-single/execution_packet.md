  # execution packet

  ## 1. run header

  - run label: `F1-intent-dual-reviewer-rebuild-single`
  - case id: `F1-intent-dual-reviewer-rebuild`
  - track: `intent`
  - review mode: `single_review`
  - operator: `intent-bootstrap-pilot`
  - case manifest ref:
    - `experiments/protocols/case_manifests/F1-intent-dual-reviewer-rebuild.yaml`
  - objective:
    - intent bootstrap pilot

  ## 2. inputs to read

  - intent ref:
    - `.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-paper-plan.md`
  - supporting refs:
  - `dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md`
  - `dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md`
  - `dual-reviewer-rebuild/docs/coordination/implementation-conformance-review.md`

  ## 3. execution steps

1. intent を読み、major gap / scope drift 候補を抽出する
2. counter-hypothesis を無理に作らず、未確定点は caveat として残す
3. `intent_review.md` の findings と metric snapshot を埋める
4. `intent_trace_note.yaml` に downstream propagation target を入れる
5. `phase_metric_snapshot.json` と `signal_linkage_note.yaml` を更新する

  ## 4. artifacts to update

  - `experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild/protocol-runs/F1-intent-dual-reviewer-rebuild-single/intent_review.md`
  - `experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild/protocol-runs/F1-intent-dual-reviewer-rebuild-single/intent_trace_note.yaml`
  - `experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild/protocol-runs/F1-intent-dual-reviewer-rebuild-single/phase_metric_snapshot.json`
  - `experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild/protocol-runs/F1-intent-dual-reviewer-rebuild-single/signal_linkage_note.yaml`

  ## 5. success check

  1. disagreement / caveat が消えていない
  2. downstream propagation target が明示されている
  3. `intent_handback_required` が yes/no で埋まっている
