# implementation-signal-register

## 1. この文書の役割

この文書は、implementation 中に観測された軽微なズレ、未確定リスク、暫定対応を
`B/C` handback に上がる前の signal として蓄積するための台帳である。

`implementation-coordination-log` が「判断と処理の記録」を残すのに対し、
本書は「まだ判断し切っていない兆候」を先に見える化する。

本書は spec の正本ではなく、reopen 判定の補助資料である。

## 2. 使い分け

- `implementation-coordination-log`
  - task 完了、handback class、reopen 要否、blocker の判断を残す
- `implementation-signal-register`
  - placeholder
  - wording mismatch
  - validation correction
  - temporary workaround
  - downstream dependency uncertainty
  - repeated touch
  のような軽微 signal を残す

## 3. 記録フォーマット

各 signal entry では次を残す。

- 日付
- feature
- task
- signal_type
- artifacts
- description
- immediate_action
- escalation_risk (`low` / `medium` / `high`)
- status (`open` / `watch` / `absorbed` / `escalated`)

## 4. escalation ルール

次のいずれかに当てはまる場合、`implementation-coordination-log` 側で
`B` または `C` handback を検討する。

- 同一 signal_type が同一 feature で繰り返し発生する
- `medium` 以上の signal が複数 task をまたいで残る
- downstream 実装開始時に unresolved のまま残る
- trust boundary、invalidation、provenance、schema shape に波及する

## 5. signal type vocabulary

- `placeholder_remaining`
- `spec_wording_mismatch`
- `validation_correction`
- `artifact_shape_uncertainty`
- `downstream_dependency_risk`
- `temporary_workaround`
- `generated_artifact_cleanup`
- `implementation_nonconformance`
- `fixture_bound_resolution`
- `heuristic_traceability_linkage`

## 6. 実施ログ

### 6.1 2026-05-08 foundation terminology template naming mismatch

- 日付: 2026-05-08
- feature: `dual-reviewer-foundation`
- task: `Task 4` / `Task 5` / `Task 6`
- signal_type: `spec_wording_mismatch`
- artifacts:
  - `.kiro/specs/dual-reviewer-foundation/tasks.md`
  - `.kiro/specs/dual-reviewer-foundation/design.md`
  - `runtime/config/terminology.yaml.template`
- description: `tasks.md` の `terminology_template.yaml` 表記と design canonical の `terminology.yaml.template` が不一致だった。
- immediate_action: design canonical に寄せて実装し、coordination log に task-local adjustment として記録。
- escalation_risk: `low`
- status: `absorbed`

### 6.2 2026-05-08 runtime deferred prompt resolution for non-judgment steps

- 日付: 2026-05-08
- feature: `dual-reviewer-runtime`
- task: `Task 4` / `Task 5`
- signal_type: `placeholder_remaining`
- artifacts:
  - `runtime/executors/step_a_primary_detection.rb`
  - `runtime/executors/step_b_adversarial_review.rb`
  - `runtime/executors/step_d_integration.rb`
- description: Step A/B/D の prompt identity は runtime-owned prompt 未実装のため deferred placeholder で残している。
- immediate_action: Step C のみ foundation prompt を実参照し、A/B/D は placeholder として明示。
- escalation_risk: `medium`
- status: `watch`

### 6.3 2026-05-08 runtime validator close-path correction

- 日付: 2026-05-08
- feature: `dual-reviewer-runtime`
- task: `Task 6` / `Task 7`
- signal_type: `validation_correction`
- artifacts:
  - `runtime/validation/validation_bridge.rb`
  - `runtime/controller/session_controller.rb`
- description: 初回実行で `closed_at` を含まない pre-close metadata を validator に渡しており、close path の整合を 1 回修正した。
- immediate_action: close 前に validation 用 metadata snapshot を構築し、validator overall status 判定を failed check 依存に修正。
- escalation_risk: `low`
- status: `absorbed`

### 6.4 2026-05-08 runtime generated artifact trial cleanup

- 日付: 2026-05-08
- feature: `dual-reviewer-runtime`
- task: `Task 2` - `Task 8`
- signal_type: `generated_artifact_cleanup`
- artifacts:
  - `experiments/runs/`
  - `exports/`
- description: runtime end-to-end 試走で generated artifact を複数回作成し、検証後に手動 cleanup した。
- immediate_action: generated run/export artifact は commit 対象から外し、repo tree を clean state に戻した。
- escalation_risk: `low`
- status: `watch`

### 6.5 2026-05-08 evaluation-local fixture precedes runtime fixture task

- 日付: 2026-05-08
- feature: `dual-reviewer-evaluation`
- task: `Task 1` / `Task 2`
- signal_type: `downstream_dependency_risk`
- artifacts:
  - `tests/fixtures/evaluation/local_runs/minimal_runtime_run/`
  - `.kiro/specs/dual-reviewer-runtime/tasks.md`
  - `.kiro/specs/dual-reviewer-evaluation/tasks.md`
- description: evaluation local intake を先に成立させるため、runtime Task 9 より前に evaluation 側で最小 runtime-shaped fixture を持った。
- immediate_action: fixture は runtime current artifact shape に合わせて限定的に作成し、runtime fixture 正式化時に差分確認対象とする。
- escalation_risk: `medium`
- status: `watch`

### 6.6 2026-05-08 evaluation judgment label metric is proxy-based

- 日付: 2026-05-08
- feature: `dual-reviewer-evaluation`
- task: `Task 6`
- signal_type: `artifact_shape_uncertainty`
- artifacts:
  - `scripts/evaluation/metric_extractor.rb`
  - `runtime/schemas/finding.schema.json`
  - `tests/fixtures/evaluation/local_runs/minimal_runtime_run/review_case.json`
- description: current standard inputs (`review_case.json`, `decision_units.json`, validation artifacts) だけでは judgment label 本体を直接読めないため、`judgment_ref_present` と `unresolved_judgment_labels` を proxy として出している。
- immediate_action: metrics は structured artifact だけで計算しつつ、judgment label distribution は resolved label なしの暫定 shape で保持。
- escalation_risk: `medium`
- status: `watch`

### 6.7 2026-05-09 self-improvement adoption gate allows unapproved adoption

- 日付: 2026-05-09
- feature: `dual-reviewer-self-improvement`
- task: `Task 8` / `Task 9`
- signal_type: `implementation_nonconformance`
- artifacts:
  - `scripts/self_improvement/history_registry.rb`
  - `.kiro/specs/dual-reviewer-self-improvement/design.md`
  - `docs/reviews/2026-05-09-prototype-shelf-review.md`
- description: conformance review で、`record_adoption` が `draft` と `awaiting_test` proposal からも `adopted` を記録できることが見つかった。`approved` と `adopted` の分離条件に反する。
- immediate_action: finding を review artifact と signal に起票し、その後 `approved` status 限定の adoption gate と `linked_repo_change_ref` 必須チェックへ修正。short rerun で validator pass を確認。
- escalation_risk: `high`
- status: `absorbed`

### 6.8 2026-05-09 replay input resolver is fixture-name-bound

- 日付: 2026-05-09
- feature: `dual-reviewer-self-improvement`
- task: `Task 6`
- signal_type: `fixture_bound_resolution`
- artifacts:
  - `scripts/self_improvement/replay_input_resolver.rb`
  - `docs/reviews/2026-05-09-prototype-shelf-review.md`
- description: `central_local_run` の run root 解決が固定 fixture 名の列挙に依存しており、新しい local fixture や別 path の run で false negative を返しうる。
- immediate_action: finding を review artifact と signal に起票し、その後 `run_manifest.yaml` ベースの generic local run discovery へ差し替えた。short rerun で replay pipeline pass を確認。
- escalation_risk: `medium`
- status: `absorbed`

### 6.9 2026-05-09 evidence-caveat linkage is heuristic

- 日付: 2026-05-09
- feature: `dual-reviewer-paper-interface`
- task: `Task 4`
- signal_type: `heuristic_traceability_linkage`
- artifacts:
  - `scripts/paper_interface/evidence_register_builder.rb`
  - `paper/reports/evidence_register.json`
  - `docs/reviews/2026-05-09-prototype-shelf-review.md`
- description: evidence register が caveat ref と artifact basename の部分一致で artifact-specific caveat を判定しており、traceability が構造化参照ではなく heuristic に依存している。
- immediate_action: finding を review artifact と signal に起票し、その後 basename heuristic を廃止して claim の `supporting_artifact_refs` と `caveat_refs` に基づく structured linkage へ修正。short rerun で paper-interface validator pass を確認。
- escalation_risk: `medium`
- status: `absorbed`
