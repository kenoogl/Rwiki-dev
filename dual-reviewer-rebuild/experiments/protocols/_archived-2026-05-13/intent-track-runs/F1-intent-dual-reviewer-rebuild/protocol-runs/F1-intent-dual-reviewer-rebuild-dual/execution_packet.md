  # execution packet

  ## 1. run header

  - run label: `F1-intent-dual-reviewer-rebuild-dual`
  - case id: `F1-intent-dual-reviewer-rebuild`
  - track: `intent`
  - review mode: `dual_reviewer_workflow`
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

1. primary reading を作る
2. adversarial pass で counter-hypothesis と premature closure 候補を出す
3. judgment で must-fix / should-fix / leave-as-is を分ける
4. `D` handback 要否と downstream propagation target を決める
5. `intent_review.md`, `intent_trace_note.yaml`, `phase_metric_snapshot.json`, `signal_linkage_note.yaml` を更新する

  ## 4. artifacts to update

  - `experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild/protocol-runs/F1-intent-dual-reviewer-rebuild-dual/intent_review.md`
  - `experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild/protocol-runs/F1-intent-dual-reviewer-rebuild-dual/intent_trace_note.yaml`
  - `experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild/protocol-runs/F1-intent-dual-reviewer-rebuild-dual/phase_metric_snapshot.json`
  - `experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild/protocol-runs/F1-intent-dual-reviewer-rebuild-dual/signal_linkage_note.yaml`

  ## 5. success check

  1. disagreement / caveat が消えていない
  2. downstream propagation target が明示されている
  3. `intent_handback_required` が yes/no で埋まっている
