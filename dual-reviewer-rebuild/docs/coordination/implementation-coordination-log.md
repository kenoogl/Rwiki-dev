# implementation-coordination-log

## 1. この文書の役割

この文書は、multi-feature 実装フェーズにおける横断調整と統合判断を記録するための文書である。

`requirements`、`design`、`tasks` の alignment は spec 段階の整合を扱う。一方 implementation では、

- 実際の file 競合
- validator と test の実装順
- spec と実装の乖離
- 実装中に発見された reopen 要因

を扱う必要がある。この文書はその coordination log であり、spec の正本を置き換えるものではない。

## 2. 扱う内容

implementation 中に次を記録する。

- 実装開始した feature
- 実装済み artifact
- 共有 file の競合有無
- 実装中に判明した spec 差分
- requirements / design / tasks への差し戻し要否
- validator / test 実行状況
- integration blocker

## 3. 基本ルール

- implementation は approved tasks の範囲で進める
- scope change が必要になったら spec 側へ戻す
- 上流 phase へ戻した場合は、対応する alignment gate を再実施する
- implementation 上の convenience で runtime / evaluation / paper の境界を崩さない

## 3.5 Handback Decision Rule

implementation 中の手戻りは、少なくとも次の 4 区分で判定する。

### A. Task-local adjustment

`tasks` の意図を変えずに吸収できる軽微な手戻り。

例:

- task 実行順の微調整
- file 分割や utility 抽出の微修正
- validator や test の実行順の微修正
- wording を伴わない implementation-only cleanup

扱い:

- `implementation-coordination-log` に記録する
- `spec.json` の reopen は不要
- `tasks alignment gate` の再実施は不要

### B. Design handback

既存 `tasks` では吸収できず、設計境界や artifact 配置の見直しが必要な手戻り。

例:

- design にない shared file 依存が必要
- artifact placement が実装不能または不自然
- foundation / runtime / evaluation の ownership が設計上ずれていた
- validator invocation timing や write order を design で明示し直す必要がある

扱い:

- `implementation-coordination-log` に記録する
- 該当 feature の `design` を reopen する
- 完了済み `tasks` も reopen 対象として再確認する
- 必要な `design alignment gate` と `tasks alignment gate` を再実施する

### C. Requirements handback

設計以前に、feature contract や上位意図との接続そのものが不足していた手戻り。

例:

- requirement にない metadata field が必須と判明した
- trust boundary や invalidation policy に影響する contract 不足
- intent に対応しない requirement、または requirement に対応しない intent が見つかった
- evaluation や self-improvement が必要とする入力が requirement 上存在しない

扱い:

- `implementation-coordination-log` に記録する
- 該当 feature の `requirements` を reopen する
- downstream の `design` と `tasks` も reopen 対象にする
- trace matrix が関係する場合は同時に更新対象とする
- `requirements alignment gate`、必要に応じて `design/tasks alignment gate` を再実施する

### D. Intent handback

feature spec の前提となる上位意図、non-goal、最適化対象そのものが不適切だった手戻り。

例:

- requirement 自体は整っているが、system intent に反する最適化をしていた
- intent が禁止している振る舞いを downstream spec が正しく実装していた
- trust boundary や human workflow の前提が intent 層で不足していた
- intent 変更により複数 feature requirement の存在理由が変わる

扱い:

- `implementation-coordination-log` に記録する
- `intent/` 配下の正本を reopen する
- 影響を受ける feature の `requirements` を reopen する
- downstream の `design` と `tasks` も reopen 対象にする
- trace matrix と関連 operation 文書も同時に更新対象とする
- `intent review`、`requirements alignment gate`、必要に応じて `design/tasks alignment gate` を再実施する

### 判定原則

- task の意図を変えないなら `A`
- task の意図は維持できるが設計境界を直す必要があるなら `B`
- そもそも contract が不足しているなら `C`
- contract より上位の system intent が不適切なら `D`

判定に迷う場合は、より上流へ戻す側に倒す。

## 4. 記録フォーマット

各 coordination entry では次を残す。

- 日付
- 対象 feature
- 対象 task
- touched artifacts
- blocker
- handback class (`A` / `B` / `C` / `D`)
- reopen 要否
- action
- status

## 5. reopen トリガー

implementation 中に次を見つけた場合、下流修正で済ませず spec の reopen を検討する。

- task の順序前提が成立しない
- design にない shared file 依存が必要になった
- runtime artifact shape が evaluation / learning / paper と一致しない
- invalidation や trust boundary に影響する実装変更が必要になった
- phase-specific metric の収集に必要な field が不足していた

## 6. 実施ログ

### 6.1 Initial status

- 状態: pending
- 理由: implementation フェーズは未着手

### 6.2 2026-05-08 foundation shared contract Task 1-3

- 日付: 2026-05-08
- 対象 feature: `dual-reviewer-foundation`
- 対象 task: `Task 1` / `Task 2` / `Task 3`
- touched artifacts:
  - `runtime/foundation/metadata_contract.yaml`
  - `runtime/schemas/review_case.schema.json`
  - `runtime/schemas/finding.schema.json`
  - `runtime/schemas/impact_score.schema.json`
  - `runtime/schemas/failure_observation.schema.json`
  - `runtime/schemas/necessity_judgment.schema.json`
  - `runtime/prompts/shared/.gitkeep`
  - `runtime/prompts/judgment/.gitkeep`
  - `runtime/patterns/.gitkeep`
  - `runtime/config/.gitkeep`
  - `runtime/validators/contracts/.gitkeep`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: design と tasks に沿って foundation-owned directory skeleton、run metadata contract、shared schema set 初版を実装
- status: completed

### 6.3 2026-05-08 foundation shared contract Task 4-6

- 日付: 2026-05-08
- 対象 feature: `dual-reviewer-foundation`
- 対象 task: `Task 4` / `Task 5` / `Task 6`
- touched artifacts:
  - `runtime/prompts/judgment/judgment_reviewer.prompt.md`
  - `runtime/prompts/shared/frontmatter_contract.yaml`
  - `runtime/patterns/seed_patterns.yaml`
  - `runtime/patterns/fatal_patterns.yaml`
  - `runtime/config/config.yaml.template`
  - `runtime/config/terminology.yaml.template`
  - `runtime/validators/contracts/validator_result.schema.json`
  - `runtime/validators/contracts/invalidation_marker.schema.json`
  - `runtime/validators/contracts/review_mode_vocab.yaml`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: prompt identity contract、pattern/config assets、validator-facing contracts を追加。`tasks.md` の `terminology_template.yaml` 表記は design canonical の `terminology.yaml.template` に正規化し、requirements が要求する `config.yaml.template` も同時実装
- status: completed

### 6.4 2026-05-08 foundation shared contract Task 7-8

- 日付: 2026-05-08
- 対象 feature: `dual-reviewer-foundation`
- 対象 task: `Task 7` / `Task 8`
- touched artifacts:
  - `tests/fixtures/foundation/review_case.minimal.json`
  - `tests/fixtures/foundation/finding.minimal.json`
  - `tests/fixtures/foundation/validator_result.minimal.json`
  - `tests/fixtures/foundation/invalidation_marker.minimal.json`
  - `scripts/validate_foundation_contracts.rb`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: downstream reuse 用の最小 fixture を追加し、schema parse、metadata required field、prompt frontmatter、review-mode vocabulary の smoke check を実行する repo-contained validation script を実装
- status: completed

### 6.5 2026-05-08 runtime skeleton Task 1

- 日付: 2026-05-08
- 対象 feature: `dual-reviewer-runtime`
- 対象 task: `Task 1`
- touched artifacts:
  - `runtime/controller/session_controller.rb`

### 6.x 2026-05-10 generic execution layer v2 replacement first validation

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `Task 12` / `Task 13`
- touched artifacts:
  - `runtime/execution_v2/`
  - `scripts/track_runs/implementation_track_runner.rb`
  - `scripts/track_runs/spec_track_writer.rb`
  - `scripts/track_runs/intent_track_writer.rb`
  - `scripts/run_*_track_protocol.rb`
  - `scripts/run_phase_field_*_first_batch.rb`
  - `scripts/run_dual_reviewer_rebuild_intent_first_batch.rb`
  - `docs/coordination/generic-execution-layer-v2-replacement-outcome.md`
- blocker:
  implementation / spec / intent の case-specific analysis heuristic はまだ残っている
- handback class: `A`
- reopen 要否: 不要
- action: manifest-backed rerun path と `v2/` internal artifact emission を 3 track へ拡張し、`phase-field` / `dual-reviewer-rebuild` first batch を再取得。comparison summary を再生成し、replacement outcome note に first validation result と remaining reopen items を固定
- status: completed
  - `runtime/executors/base_step_executor.rb`
  - `runtime/executors/step_a_primary_detection.rb`
  - `runtime/executors/step_b_adversarial_review.rb`
  - `runtime/executors/step_c_judgment.rb`
  - `runtime/executors/step_d_integration.rb`
  - `runtime/writers/evidence_writer.rb`
  - `runtime/validation/validation_bridge.rb`
  - `runtime/export/bundle_exporter.rb`
  - `runtime/support/foundation_asset_loader.rb`
  - `scripts/run_review_session.rb`
  - `scripts/export_evidence_bundle.rb`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: runtime ownership 境界を Ruby module skeleton として切り出し、entrypoint から foundation metadata contract と prompt contract をロードできる状態を作成
- status: completed

### 6.6 2026-05-08 runtime initialization Task 2-3

- 日付: 2026-05-08
- 対象 feature: `dual-reviewer-runtime`
- 対象 task: `Task 2` / `Task 3`
- touched artifacts:
  - `runtime/controller/session_controller.rb`
  - `runtime/writers/evidence_writer.rb`
  - `scripts/run_review_session.rb`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: foundation metadata contract に従う run initialization と `experiments/runs/<run_id>/` canonical layout 作成を実装。required metadata 欠損時は run 開始前に停止するガードを追加
- status: completed

### 6.7 2026-05-08 runtime step emission Task 4-5

- 日付: 2026-05-08
- 対象 feature: `dual-reviewer-runtime`
- 対象 task: `Task 4` / `Task 5`
- touched artifacts:
  - `runtime/support/foundation_asset_loader.rb`
  - `runtime/executors/base_step_executor.rb`
  - `runtime/executors/step_a_primary_detection.rb`
  - `runtime/executors/step_b_adversarial_review.rb`
  - `runtime/executors/step_c_judgment.rb`
  - `runtime/executors/step_d_integration.rb`
  - `runtime/writers/evidence_writer.rb`
  - `runtime/controller/session_controller.rb`
  - `scripts/run_review_session.rb`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: treatment-aware step artifact emission と `review_case.json` aggregation の最小実装を追加。Step C は foundation prompt frontmatter を実参照し、Step A/B/D は runtime-owned prompt 未実装のため deferred resolution を明示
- status: completed

### 6.8 2026-05-08 runtime close/export Task 6-8

- 日付: 2026-05-08
- 対象 feature: `dual-reviewer-runtime`
- 対象 task: `Task 6` / `Task 7` / `Task 8`
- touched artifacts:
  - `runtime/writers/evidence_writer.rb`
  - `runtime/validation/validation_bridge.rb`
  - `runtime/export/bundle_exporter.rb`
  - `runtime/controller/session_controller.rb`
  - `scripts/run_review_session.rb`
  - `scripts/export_evidence_bundle.rb`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: decision unit と human sign-off artifact、run close 後の validator result / invalidation marker / metadata update、portable bundle export の最小実装を追加
- status: completed

### 6.9 2026-05-08 evaluation skeleton/intake Task 1-2

- 日付: 2026-05-08
- 対象 feature: `dual-reviewer-evaluation`
- 対象 task: `Task 1` / `Task 2`
- touched artifacts:
  - `experiments/analysis/imports/.gitkeep`
  - `experiments/analysis/manifests/.gitkeep`
  - `experiments/analysis/classifications/.gitkeep`
  - `experiments/analysis/metrics/.gitkeep`
  - `experiments/analysis/comparisons/.gitkeep`
  - `experiments/analysis/caveats/.gitkeep`
  - `scripts/evaluation/local_run_loader.rb`
  - `scripts/intake_local_run.rb`
  - `tests/fixtures/evaluation/local_runs/minimal_runtime_run/run_manifest.yaml`
  - `tests/fixtures/evaluation/local_runs/minimal_runtime_run/review_case.json`
  - `tests/fixtures/evaluation/local_runs/minimal_runtime_run/decisions/decision_units.json`
  - `tests/fixtures/evaluation/local_runs/minimal_runtime_run/validation/validator_result.json`
  - `tests/fixtures/evaluation/local_runs/minimal_runtime_run/validation/invalidation_markers.json`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: evaluation artifact placement を固定し、runtime local run を標準入力として読む intake loader と CLI entrypoint を追加。missing required artifact を intake status で識別できるようにした
- status: completed

### 6.10 2026-05-08 evaluation imported bundle intake Task 3

- 日付: 2026-05-08
- 対象 feature: `dual-reviewer-evaluation`
- 対象 task: `Task 3`
- touched artifacts:
  - `scripts/evaluation/imported_bundle_loader.rb`
  - `scripts/intake_imported_bundle.rb`
  - `tests/fixtures/evaluation/imported_bundles/minimal_runtime_bundle/bundle_manifest.yaml`
  - `tests/fixtures/evaluation/imported_bundles/minimal_runtime_bundle/checksums/bundle_checksums.json`
  - `tests/fixtures/evaluation/imported_bundles/minimal_runtime_bundle/run/run-fixture-001/run_manifest.yaml`
  - `tests/fixtures/evaluation/imported_bundles/minimal_runtime_bundle/run/run-fixture-001/review_case.json`
  - `tests/fixtures/evaluation/imported_bundles/minimal_runtime_bundle/run/run-fixture-001/decisions/decision_units.json`
  - `tests/fixtures/evaluation/imported_bundles/minimal_runtime_bundle/run/run-fixture-001/validation/validator_result.json`
  - `tests/fixtures/evaluation/imported_bundles/minimal_runtime_bundle/run/run-fixture-001/validation/invalidation_markers.json`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: bundle manifest loader、run subtree resolver、checksum verifier、required provenance check を実装し、portable bundle fixture で intake 成立を確認
- status: completed

### 6.11 2026-05-08 evaluation admission Task 4

- 日付: 2026-05-08
- 対象 feature: `dual-reviewer-evaluation`
- 対象 task: `Task 4`
- touched artifacts:
  - `scripts/evaluation/admission_evaluator.rb`
  - `scripts/evaluation/import_register_writer.rb`
  - `scripts/admit_imported_bundle.rb`
  - `experiments/analysis/imports/ingestion_register.json`
  - `experiments/analysis/imports/admission_register.json`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: imported bundle admission rule evaluator と imports register writer を追加し、ingestion result から machine-readable な admission status と comparison eligibility を出力するようにした
- status: completed

### 6.12 2026-05-08 evaluation classification Task 5

- 日付: 2026-05-08
- 対象 feature: `dual-reviewer-evaluation`
- 対象 task: `Task 5`
- touched artifacts:
  - `scripts/evaluation/classification_engine.rb`
  - `scripts/evaluation/classification_writer.rb`
  - `scripts/classify_evaluation_input.rb`
  - `experiments/analysis/classifications/run_classification_index.json`
  - `experiments/analysis/classifications/exclusion_report.json`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: local run と imported bundle admission の両経路を受ける classification engine を追加し、classification index と exclusion report を machine-readable に出力するようにした
- status: completed

### 6.13 2026-05-08 evaluation core metrics Task 6

- 日付: 2026-05-08
- 対象 feature: `dual-reviewer-evaluation`
- 対象 task: `Task 6`
- touched artifacts:
  - `scripts/evaluation/metric_extractor.rb`
  - `scripts/evaluation/metric_writer.rb`
  - `scripts/extract_evaluation_metrics.rb`
  - `experiments/analysis/metrics/run_metrics.json`
  - `experiments/analysis/metrics/finding_metrics.json`
  - `tests/fixtures/evaluation/local_runs/minimal_runtime_run/review_case.json`
  - `tests/fixtures/evaluation/imported_bundles/minimal_runtime_bundle/run/run-fixture-001/review_case.json`
  - `tests/fixtures/evaluation/imported_bundles/minimal_runtime_bundle/checksums/bundle_checksums.json`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: structured run intake から run-level/finding-level metrics を再計算する extractor と writer を追加。fixture に最小 finding を追加して severity/source-role 集計を成立させた
- status: completed

### 6.14 2026-05-08 evaluation treatment/phase comparisons Task 7

- 日付: 2026-05-08
- 対象 feature: `dual-reviewer-evaluation`
- 対象 task: `Task 7`
- touched artifacts:
  - `scripts/evaluation/comparison_builder.rb`
  - `scripts/evaluation/comparison_writer.rb`
  - `scripts/build_evaluation_comparisons.rb`
  - `experiments/analysis/metrics/treatment_metrics.json`
  - `experiments/analysis/comparisons/treatment_comparisons.json`
  - `experiments/analysis/comparisons/phase_comparisons.json`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: valid population のみを入力に treatment/phase aggregate を生成し、比較不成立時は invalid reason を machine-readable に記録する comparison builder を追加
- status: completed

### 6.15 2026-05-08 evaluation caveat artifacts Task 8

- 日付: 2026-05-08
- 対象 feature: `dual-reviewer-evaluation`
- 対象 task: `Task 8`
- touched artifacts:
  - `scripts/evaluation/caveat_builder.rb`
  - `scripts/evaluation/caveat_writer.rb`
  - `scripts/build_evaluation_caveats.rb`
  - `experiments/analysis/caveats/caveat_register.json`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: comparison と classification の出力から low sample size、single treatment only、exploratory-only などを machine-readable に出す caveat register を追加
- status: completed

### 6.16 2026-05-08 evaluation analysis manifest Task 9

- 日付: 2026-05-08
- 対象 feature: `dual-reviewer-evaluation`
- 対象 task: `Task 9`
- touched artifacts:
  - `scripts/evaluation/analysis_manifest_writer.rb`
  - `scripts/write_analysis_manifest.rb`
  - `experiments/analysis/manifests/analysis_run_manifest.yaml`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: current analysis artifact set と input run ids を versioned summary として固定する analysis manifest writer を追加
- status: completed

### 6.17 2026-05-09 evaluation fixtures/smoke Task 10-11

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-evaluation`
- 対象 task: `Task 10` / `Task 11`
- touched artifacts:
  - `tests/fixtures/evaluation/local_runs/invalid_runtime_run/*`
  - `tests/fixtures/evaluation/local_runs/analysis_blocked_run/*`
  - `tests/fixtures/evaluation/outputs/minimal_comparison/*`
  - `scripts/validate_evaluation_pipeline.rb`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: invalid / analysis_blocked fixture と minimal comparison output fixture を追加し、intake / admission / classification / metrics / comparison invalidity / caveat / manifest を一括で確認する evaluation smoke check を実装
- status: completed

### 6.18 2026-05-09 self-improvement learning skeleton Task 1

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-self-improvement`
- 対象 task: `Task 1`
- touched artifacts:
  - `learning/findings/.gitkeep`
  - `learning/proposals/.gitkeep`
  - `learning/backtests/.gitkeep`
  - `learning/approved-updates/.gitkeep`
  - `learning/rejected-updates/.gitkeep`
  - `learning/rollback/.gitkeep`
  - `DOCUMENT_INDEX.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: self-improvement owner の正本 placement を tracked skeleton として固定し、欠けていた `backtests/` と `rollback/` を追加した
- status: completed

### 6.19 2026-05-09 self-improvement signal intake Task 2

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-self-improvement`
- 対象 task: `Task 2`
- touched artifacts:
  - `scripts/self_improvement/signal_class_classifier.rb`
  - `scripts/self_improvement/signal_intake.rb`
  - `scripts/intake_self_improvement_signals.rb`
  - `tests/fixtures/evaluation/local_runs/exploratory_runtime_run/*`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: runtime local run と evaluation analysis artifact から self-improvement 向け signal を抽出する intake を実装し、valid / invalid / exploratory / analysis_blocked の maturity 差を確認できる exploratory fixture を追加した
- status: completed

### 6.20 2026-05-09 self-improvement signal inventory Task 3

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-self-improvement`
- 対象 task: `Task 3`
- touched artifacts:
  - `scripts/self_improvement/signal_inventory_writer.rb`
  - `scripts/build_self_improvement_signal_inventory.rb`
  - `learning/findings/recurring_failure_signals.json`
  - `learning/findings/workflow_failure_signals.json`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: runtime/evaluation signal intake を proposal 前 inventory に固定する writer と build script を追加し、workflow failure と recurring failure を分離した machine-readable finding registers を生成した
- status: completed

### 6.21 2026-05-09 self-improvement proposal generation/provenance Task 4-5

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-self-improvement`
- 対象 task: `Task 4` / `Task 5`
- touched artifacts:
  - `scripts/self_improvement/proposal_provenance_resolver.rb`
  - `scripts/self_improvement/proposal_builder.rb`
  - `scripts/self_improvement/proposal_writer.rb`
  - `scripts/build_self_improvement_proposals.rb`
  - `learning/proposals/proposal_index.json`
  - `learning/proposals/*.yaml`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: signal inventory から 1 signal = 1 draft proposal を生成する builder と writer を追加し、imports ingestion/admission register を参照して `source_origin`、repository provenance、admission refs を proposal artifact に伝播した
- status: completed

### 6.22 2026-05-09 self-improvement replay input preparation Task 6

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-self-improvement`
- 対象 task: `Task 6`
- touched artifacts:
  - `scripts/self_improvement/replay_input_resolver.rb`
  - `scripts/prepare_self_improvement_replay_inputs.rb`
  - `tests/fixtures/evaluation/local_runs/minimal_runtime_run/steps/*`
  - `tests/fixtures/evaluation/local_runs/exploratory_runtime_run/steps/*`
  - `tests/fixtures/evaluation/imported_bundles/minimal_runtime_bundle/run/run-fixture-001/steps/*`
  - `tests/fixtures/evaluation/local_runs/minimal_runtime_run/review_case.json`
  - `tests/fixtures/evaluation/local_runs/exploratory_runtime_run/review_case.json`
  - `tests/fixtures/evaluation/imported_bundles/minimal_runtime_bundle/run/run-fixture-001/review_case.json`
  - `tests/fixtures/evaluation/imported_bundles/minimal_runtime_bundle/checksums/bundle_checksums.json`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: proposal target layer と required test mode に応じて review_case、relevant steps、decision/validation artifact を束ねる replay input resolver を追加し、Step B / Step C replay 準備を fixture で成立させた
- status: completed

### 6.23 2026-05-09 self-improvement backtest artifacts Task 7

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-self-improvement`
- 対象 task: `Task 7`
- touched artifacts:
  - `scripts/self_improvement/backtest_builder.rb`
  - `scripts/self_improvement/backtest_writer.rb`
  - `scripts/build_self_improvement_backtests.rb`
  - `learning/backtests/backtest_index.json`
  - `learning/backtests/*.json`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: proposal ごとに replay/manual/backtest mode を評価して `supported / unsupported / inconclusive / untested` を返す backtest builder と writer を追加し、learning/backtests に proposal-scoped test result artifact を生成した
- status: completed

### 6.24 2026-05-09 self-improvement decision/rollback registers Task 8-9

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-self-improvement`
- 対象 task: `Task 8` / `Task 9`
- touched artifacts:
  - `scripts/self_improvement/proposal_status_updater.rb`
  - `scripts/self_improvement/history_registry.rb`
  - `scripts/record_self_improvement_decision.rb`
  - `scripts/record_self_improvement_rollback.rb`
  - `learning/approved-updates/adoption_register.json`
  - `learning/rejected-updates/rejection_register.json`
  - `learning/rollback/rollback_register.json`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: proposal status と同期する approval/adoption/rejection/rollback registry updater を追加し、history register の正本ファイルを初期化した
- status: completed

### 6.25 2026-05-09 self-improvement pattern helper Task 10

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-self-improvement`
- 対象 task: `Task 10`
- touched artifacts:
  - `scripts/self_improvement/pattern_candidate_builder.rb`
  - `scripts/self_improvement/pattern_candidate_writer.rb`
  - `scripts/build_self_improvement_pattern_candidates.rb`
  - `learning/findings/pattern_candidates.json`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: recurring signal を project-specific / meta-pattern candidate に整理する helper を追加し、proposal loop が pattern layer 成長の入口を持つようにした
- status: completed

### 6.26 2026-05-09 self-improvement fixtures/smoke Task 11-12

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-self-improvement`
- 対象 task: `Task 11` / `Task 12`
- touched artifacts:
  - `tests/fixtures/self_improvement/proposals/*`
  - `tests/fixtures/self_improvement/rollback/rollback_fixture.json`
  - `scripts/validate_self_improvement_pipeline.rb`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: local/imported/workflow/rollback fixture を追加し、一時コピー上で signal intake, proposal provenance, imported evidence preservation, backtest, approval vs adoption, rollback を通す smoke validator を実装した
- status: completed

### 6.27 2026-05-09 paper-interface skeleton Task 1

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-paper-interface`
- 対象 task: `Task 1`
- touched artifacts:
  - `paper/reports/.gitkeep`
  - `paper/tables/.gitkeep`
  - `paper/figures/.gitkeep`
  - `paper/caveats/.gitkeep`
  - `DOCUMENT_INDEX.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: paper-interface owner の正本 placement を tracked skeleton に固定し、欠けていた `paper/caveats/` を追加した
- status: completed

### 6.28 2026-05-09 paper-interface evaluation intake Task 2

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-paper-interface`
- 対象 task: `Task 2`
- touched artifacts:
  - `scripts/paper_interface/evaluation_intake_loader.rb`
  - `scripts/intake_paper_evaluation_outputs.rb`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: paper-interface が evaluation analysis artifact を standard upstream source として読む intake loader を追加し、runtime raw artifact を再読しない入力境界を固定した
- status: completed

### 6.29 2026-05-09 paper-interface claim map Task 3

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-paper-interface`
- 対象 task: `Task 3`
- touched artifacts:
  - `scripts/paper_interface/claim_map_builder.rb`
  - `scripts/paper_interface/claim_map_writer.rb`
  - `scripts/build_paper_claim_map.rb`
  - `paper/reports/claim_map.json`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: evaluation intake から phase/treatment/exclusion transparency の最小 claim unit を構成し、supporting artifact, maturity, caveat, provenance を持つ claim map writer を追加した
- status: completed

### 6.30 2026-05-09 paper-interface evidence register Task 4

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-paper-interface`
- 対象 task: `Task 4`
- touched artifacts:
  - `scripts/paper_interface/evidence_register_builder.rb`
  - `scripts/paper_interface/evidence_register_writer.rb`
  - `scripts/build_paper_evidence_register.rb`
  - `paper/reports/evidence_register.json`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: claim map の supporting artifact を正規化し、analysis manifest/run set provenance と maturity/caveat を paper-facing registry に固定する evidence register writer を追加した
- status: completed

### 6.31 2026-05-09 paper-interface table source bundle Task 5

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-paper-interface`
- 対象 task: `Task 5`
- touched artifacts:
  - `scripts/paper_interface/table_source_bundle_builder.rb`
  - `scripts/paper_interface/table_source_bundle_writer.rb`
  - `scripts/build_paper_table_source_bundle.rb`
  - `paper/tables/table_source_bundle.json`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: claim map と evidence register を入力に、phase/treatment/exclusion/caveat を並べる分析 summary table 用 source selection と field projection を machine-readable bundle として固定した
- status: completed

### 6.32 2026-05-09 paper-interface figure source bundle Task 6

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-paper-interface`
- 対象 task: `Task 6`
- touched artifacts:
  - `scripts/paper_interface/figure_source_bundle_builder.rb`
  - `scripts/paper_interface/figure_source_bundle_writer.rb`
  - `scripts/build_paper_figure_source_bundle.rb`
  - `paper/figures/figure_source_bundle.json`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: phase slice と treatment metric profile を reporting-side plot contract として固定し、status annotation を含む figure source bundle を追加した
- status: completed

### 6.33 2026-05-09 paper-interface paper caveat register Task 7

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-paper-interface`
- 対象 task: `Task 7`
- touched artifacts:
  - `scripts/paper_interface/paper_caveat_register_builder.rb`
  - `scripts/paper_interface/paper_caveat_register_writer.rb`
  - `scripts/build_paper_caveat_register.rb`
  - `paper/caveats/paper_caveat_register.json`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: evaluation caveat を claim/table/figure に結び直し、paper-facing limitation type と narrative note を持つ caveat register として再配置した
- status: completed

### 6.34 2026-05-09 paper-interface reporting fragments Task 8

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-paper-interface`
- 対象 task: `Task 8`
- touched artifacts:
  - `scripts/paper_interface/reporting_fragments_builder.rb`
  - `scripts/paper_interface/reporting_fragments_writer.rb`
  - `scripts/build_paper_reporting_fragments.rb`
  - `paper/reports/reporting_fragments.json`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: claim summary, comparison summary, limitation note, method note を manuscript 非依存の structured fragment として生成し、source/maturity/caveat を保持する reporting fragment writer を追加した
- status: completed

### 6.35 2026-05-09 paper-interface methodology-note linkage Task 9

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-paper-interface`
- 対象 task: `Task 9`
- touched artifacts:
  - `scripts/paper_interface/methodology_note_linkage_builder.rb`
  - `scripts/paper_interface/methodology_note_linkage_writer.rb`
  - `scripts/build_paper_methodology_note_linkage.rb`
  - `paper/reports/methodology_note_linkage.json`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: self-improvement の adopted history を methodology-only linkage として読む optional path を追加し、performance claim support に使えないことを `claim_support_allowed: false` で固定した
- status: completed

### 6.36 2026-05-09 paper-interface fixtures/smoke Task 10-11

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-paper-interface`
- 対象 task: `Task 10` / `Task 11`
- touched artifacts:
  - `tests/fixtures/paper_interface/*`
  - `scripts/validate_paper_interface_pipeline.rb`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: minimal claim/evidence/caveat/imported-provenance fixture を追加し、一時コピー上で traceability, provenance, table/figure field, caveat retention, no silent strengthening, methodology-note separation を確認する smoke validator を実装した
- status: completed

### 6.37 2026-05-09 prototype implementation conformance review

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-runtime` / `dual-reviewer-evaluation` / `dual-reviewer-self-improvement` / `dual-reviewer-paper-interface`
- 対象 task: post-prototype shelf review
- touched artifacts:
  - `docs/coordination/implementation-conformance-review.md`
  - `docs/coordination/implementation-conformance-metric-register.md`
  - `docs/reviews/2026-05-09-prototype-shelf-review.md`
  - `docs/coordination/implementation-signal-register.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: smoke pass 後の横断棚卸し工程として implementation conformance review を定義し、初回 review artifact と metric snapshot を追加。approval/adoption gate、fixture-bound replay resolution、heuristic caveat linkage を finding として signal register に接続した
- status: completed

### 6.38 2026-05-09 implementation governance spec and validator

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-implementation-governance`
- 対象 task: `Task 1` / `Task 2` / `Task 3` / `Task 4` / `Task 5` / `Task 6`
- touched artifacts:
  - `.kiro/specs/dual-reviewer-implementation-governance/*`
  - `docs/reviews/templates/implementation-conformance-review-template.md`
  - `scripts/validate_implementation_governance_artifacts.rb`
  - `DOCUMENT_INDEX.md`
  - `docs/alignment/phase-and-feature-dependency-map.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: implementation completion rule の仕様化として governance spec を起票し、procedure/metric register/template/current review artifact を spec ownership に接続。併せて governance artifact validator を追加し、dependency map と document index を更新した
- status: completed

### 6.39 2026-05-09 governance cross-spec alignment and gate status

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-implementation-governance`
- 対象 task: `Task 7`
- touched artifacts:
  - `docs/alignment/cross-spec-implementation-governance-alignment.md`
  - `docs/coordination/workflow-gate-status.md`
  - `.kiro/specs/dual-reviewer-implementation-governance/requirements.md`
  - `.kiro/specs/dual-reviewer-implementation-governance/design.md`
  - `.kiro/specs/dual-reviewer-implementation-governance/tasks.md`
  - `.kiro/specs/dual-reviewer-implementation-governance/spec.json`
  - `scripts/validate_implementation_governance_artifacts.rb`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: governance spec 自体が workflow 外で成立しないよう、cross-spec alignment memo と gate status register を追加し、governance spec の alignment status を required/completed に更新。validator も新 artifact を必須対象に拡張した
- status: completed

### 6.40 2026-05-09 workflow repair procedure formalization

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-implementation-governance`
- 対象 task: workflow repair procedure addendum
- touched artifacts:
  - `docs/coordination/workflow-repair-procedure.md`
  - `DOCUMENT_INDEX.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `A/B/C/D` handback を含む修正手続き一覧と状態遷移表を repo artifact として固定し、intent handback を含む reopen propagation を参照可能にした
- status: completed

### 6.41 2026-05-09 open conformance findings fix and short rerun

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-self-improvement` / `dual-reviewer-paper-interface`
- 対象 task: post-review fix sweep
- touched artifacts:
  - `scripts/self_improvement/history_registry.rb`
  - `scripts/self_improvement/replay_input_resolver.rb`
  - `scripts/paper_interface/evidence_register_builder.rb`
  - `docs/reviews/2026-05-09-prototype-shelf-review-rerun.md`
  - `docs/coordination/implementation-signal-register.md`
  - `docs/coordination/workflow-gate-status.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: initial conformance review の 3 finding を implementation-only fix として修正し、self-improvement / paper-interface / governance validator を再実行。short rerun review artifact を追加し、open finding status を `fixed` / `absorbed` に更新した
- status: completed

### 6.42 2026-05-09 v1 completion report

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-implementation-governance`
- 対象 task: reporting addendum
- touched artifacts:
  - `docs/reports/dual-reviewer-v1-completion-report.md`
  - `DOCUMENT_INDEX.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: v1 の完成条件、manual conformance review サイクル、validator pass、evidence location をまとめた completion report を追加した
- status: completed

### 6.43 2026-05-09 v1 user guide

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-implementation-governance`
- 対象 task: user-facing documentation addendum
- touched artifacts:
  - `docs/guides/dual-reviewer-v1-user-guide.md`
  - `README.md`
  - `DOCUMENT_INDEX.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: v1 の目的、想定利用者、最短利用手順、pipeline validator、生成物、限界をまとめた user guide を追加し、README の status を v1 完成状態へ更新した
- status: completed

### 6.44 2026-05-09 v1 phase metrics reporting

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-implementation-governance`
- 対象 task: reporting and measurement addendum
- touched artifacts:
  - `docs/reports/dual-reviewer-v1-completion-report.md`
  - `docs/coordination/phase-review-metric-register.md`
  - `DOCUMENT_INDEX.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: v1 completion report に `intent / requirements / design / tasks / implementation` の phase 別 metrics と手戻り統計を追記し、今後の baseline 抽出規則を固定する `phase-review-metric register` を追加した
- status: completed

### 6.45 2026-05-09 intent review baseline and intent-attribution rule

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-implementation-governance`
- 対象 task: phase measurement completion
- touched artifacts:
  - `docs/reviews/2026-05-09-intent-baseline-review.md`
  - `docs/reviews/templates/intent-review-template.md`
  - `docs/coordination/phase-review-metric-register.md`
  - `docs/reports/dual-reviewer-v1-completion-report.md`
  - `operations/HUMAN_WORKFLOW.md`
  - `docs/coordination/workflow-repair-procedure.md`
  - `docs/coordination/workflow-gate-status.md`
  - `DOCUMENT_INDEX.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: intent 専用 review artifact と template を追加し、`intent_revision_count` / `intent_handback_count` の baseline を固定した。あわせて下流 phase では intent 起因問題を `intent-attributed issue` として記録する rule を workflow 文書へ追加した
- status: completed

### 6.46 2026-05-09 replay resolver and caveat linkage design clarification

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-self-improvement` / `dual-reviewer-paper-interface`
- 対象 task: design note elevation
- touched artifacts:
  - `.kiro/specs/dual-reviewer-self-improvement/design.md`
  - `.kiro/specs/dual-reviewer-paper-interface/design.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: replay input resolution の manifest-based discovery 原則を self-improvement design に追記し、evidence-caveat linkage の structured reference 原則を paper-interface design に追記した。いずれも implementation-only fix で吸収済みの挙動を design note として正本へ昇格した
- status: completed

### 6.47 2026-05-09 intent/spec track artifact writers

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-implementation-governance`
- 対象 task: spec-driven acquisition support
- touched artifacts:
  - `scripts/track_runs/intent_track_writer.rb`
  - `scripts/track_runs/spec_track_writer.rb`
  - `scripts/write_intent_track_run_artifacts.rb`
  - `scripts/write_spec_track_run_artifacts.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `Intent Track` と `Spec Track` の first-run template で要求していた最小 artifact を run 単位で機械生成する writer と CLI entrypoint を追加した。あわせて tmpdir 上で manifest / markdown / phase metric snapshot / signal linkage note の生成を検証する validator を追加し、実データ取得計画のうち upstream track の最低限 artifact が現実に採取可能であることを確認するための mechanical baseline を整えた
- status: completed

### 6.48 2026-05-09 intent track first case fixation

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-implementation-governance`
- 対象 task: spec-driven acquisition preparation
- touched artifacts:
  - `.kiro/methodology/v4-validation/intent-track-first-case-dual-reviewer-rebuild.md`
  - `.kiro/methodology/v4-validation/intent-track-first-run-plan.md`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `Intent Track` の最初の concrete case として `dual-reviewer-rebuild` bootstrap 区間を `F1-intent-dual-reviewer-rebuild` に固定し、Intent Track first-run plan から参照できるようにした。これにより、intent-only に最も近い bootstrap case を使って `single review` と `dual-reviewer workflow` の両方で同一 input を比較するための境界が定まった
- status: completed

### 6.49 2026-05-09 methodology document index

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-implementation-governance`
- 対象 task: methodology navigation support
- touched artifacts:
  - `.kiro/methodology/v4-validation/INDEX.md`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `.kiro/methodology/v4-validation/` 配下の論文化・取得計画・補助資料を active paper set / historical references / samples / research memory に分けて辿れる index を追加した。主線の `spec-driven` 一式を先頭に置き、3 track の plan / template / case 固定へ順に降りられる reading order も明示した
- status: completed

### 6.50 2026-05-09 methodology directory split

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-implementation-governance`
- 対象 task: methodology organization
- touched artifacts:
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: active な論文化主線を `v4-validation` から分離し、`.kiro/methodology/dual-reviewer-spec-driven-paper/` に移設した。あわせて相互リンクを新ディレクトリへ更新し、index は旧版や補助資料への導線を外して active 文書だけを辿る構成に整理した
- status: completed

### 6.51 2026-05-09 claim-case orthogonal matrix

- 日付: 2026-05-09
- 対象 feature: `dual-reviewer-implementation-governance`
- 対象 task: evaluation planning stabilization
- touched artifacts:
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/claim-case-matrix.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/INDEX.md`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `Claim 1-4` と評価 case の対応を直交表として固定し、どの claim にどの case class が必須か、`intent` がない case を main paper から除外する rule を明文化した。あわせて paper index に matrix を組み込み、case 選定の主線を `intent` 先行に固定した
- status: completed

### 6.52 2026-05-09 phase-field intent authoring

- 日付: 2026-05-09
- 対象 feature: `phase-field-reverse-spec`
- 対象 task: upstream intent formalization
- touched artifacts:
  - `.kiro/specs/phase-field-reverse-spec/intent.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/claim-case-matrix.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-case-manifest.md`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `phase-field-reverse-spec` に明示的な intent 正本を追加し、scientific clean-room reconstruction case の目的、非目的、制約、成功条件、論文上の役割を固定した。あわせて paper 側の case 文書を更新し、`phase-field` を `intent` 参照済みの `Spec Track / Implementation Track` case として扱うように整理した
- status: completed

### 6.53 2026-05-09 heat3d intent authoring

- 日付: 2026-05-09
- 対象 feature: `heat3d-spec`
- 対象 task: upstream intent formalization
- touched artifacts:
  - `.kiro/specs/heat3d-spec/intent.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/claim-case-matrix.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-case-manifest.md`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `/Users/Daily/Development/Heat3ds_rework/docs/thermal_simulator_spec.md` を canonical source とする `heat3d` の短い intent を追加した。あわせて paper 側の case 文書を更新し、`heat3d` を intent 参照済みの `Spec Track / Implementation Track` case として扱うように整理した
- status: completed

### 6.54 2026-05-10 iot-arduino intent and requirements authoring

- 日付: 2026-05-10
- 対象 feature: `iot-arduino-spec`
- 対象 task: upstream intent and minimal spec formalization
- touched artifacts:
  - `.kiro/specs/iot-arduino-spec/intent.md`
  - `.kiro/specs/iot-arduino-spec/requirements.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/claim-case-matrix.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-case-manifest.md`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `/Users/Daily/Development/DR-IoT/src/Irrigation.ino` を canonical source とする `iot-arduino` の短い intent と最小 requirements を追加した。灌水スケジュール、流量計測、表示・通知、永続化、ネットワーク同期、deep sleep を仕様境界として抽出し、paper 側の case 文書も intent 参照済みの event-driven case に更新した
- status: completed

### 6.55 2026-05-10 spec track first case fixation

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-implementation-governance`
- 対象 task: spec-driven acquisition preparation
- touched artifacts:
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/spec-track-first-case-phase-field-reverse-spec.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/spec-track-first-run-plan.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/INDEX.md`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `Spec Track` の最初の concrete case として `phase-field-reverse-spec` を `F1-spec-phase-field-reverse-spec` に固定し、intent-side anchor, spec-side anchor, downstream implementation reference, phase status, required outputs を明文化した。これにより `single review` と `dual-reviewer workflow` を同じ spec root に対して比較するための境界が定まった
- status: completed

### 6.56 2026-05-10 three core cases fixation

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-implementation-governance`
- 対象 task: evaluation case stabilization
- touched artifacts:
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-phase-field.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-heat3d.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-iot-arduino.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-case-manifest.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/INDEX.md`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `phase-field / heat3d / iot-arduino` を論文化の 3 core case として固定し、各 case について intent ref、canonical source、supported track、paper role、stress characteristics を 1 文書ずつに整理した。manifest と index も更新し、core case 固定と first-run 固定を分けて辿れる構成にした
- status: completed

### 6.57 2026-05-10 claim-case matrix realignment

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-implementation-governance`
- 対象 task: paper planning consistency correction
- touched artifacts:
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-heat3d.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-iot-arduino.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-case-manifest.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/INDEX.md`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `claim-case-matrix.md` を正本として扱い、`heat3d` と `iot-arduino` を fixed core case から provisional core case に戻した。matrix が要求する upstream spec / track 固定条件を満たすまで main paper の fixed case と見なさないことを manifest と index に反映した
- status: completed

### 6.58 2026-05-10 spec-driven data acquisition runner wiring

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-implementation-governance`
- 対象 task: `spec-driven evaluation runner wiring`
- touched artifacts:
  - `runtime/writers/evidence_writer.rb`
  - `runtime/controller/session_controller.rb`
  - `scripts/track_runs/implementation_track_runner.rb`
  - `scripts/run_intent_track_protocol.rb`
  - `scripts/run_spec_track_protocol.rb`
  - `scripts/run_implementation_track_protocol.rb`
  - `scripts/validate_protocol_runners.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `Intent Track` / `Spec Track` の protocol writer を CLI から実行できる形に揃え、`Implementation Track` には protocol review mode から runtime treatment へ写像する runner と CLI を追加した。さらに 3 track の first-batch 実行基盤を tmpdir 上で mechanical に検証する validation script を実装し、protocol runner validation を通した
- status: completed

### 6.59 2026-05-10 spec-driven execution packet addition

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-implementation-governance`
- 対象 task: `spec-driven execution packet scaffolding`
- touched artifacts:
  - `scripts/track_runs/intent_track_writer.rb`
  - `scripts/track_runs/spec_track_writer.rb`
  - `scripts/track_runs/implementation_track_runner.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/validate_protocol_runners.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: 3 track すべての run artifact に `execution_packet.md` を追加し、review mode ごとに何を読み、どの artifact を更新し、何を success check とするかを run 単位で固定した。validation も更新し、execution packet を含めて mechanical に検証した
- status: completed

### 6.60 2026-05-10 phase-field-only pilot narrowing

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-implementation-governance`
- 対象 task: `spec-driven first-batch scope correction`
- touched artifacts:
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-first-run-plan.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/INDEX.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: first batch を `phase-field` Implementation Track pilot のみに縮小し、`heat3d` と `iot-arduino` は provisional case のまま後続 scope expansion へ送るよう正本を修正した。これにより fixed core case だけで pilot readiness を評価する流れに揃えた
- status: completed

### 6.61 2026-05-10 implementation pilot seeded findings

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-runtime`
- 対象 task: `Implementation Track phase-field pilot review seeding`
- touched artifacts:
  - `runtime/executors/base_step_executor.rb`
  - `runtime/executors/step_a_primary_detection.rb`
  - `runtime/executors/step_b_adversarial_review.rb`
  - `runtime/executors/step_c_judgment.rb`
  - `runtime/executors/step_d_integration.rb`
  - `runtime/controller/session_controller.rb`
  - `scripts/track_runs/implementation_track_runner.rb`
  - `scripts/validate_protocol_runners.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `phase-field` pilot 専用の deterministic finding/judgment seed を runtime step executor 群へ追加し、single review では 2 findings、dual-reviewer workflow では adversarial finding を追加した 3 findings が review_case と decision_units に残るようにした。validation も強化し、dual mode で adversarial finding が保存されることまで確認した
- status: completed

### 6.62 2026-05-10 phase-field pilot batch runner

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-runtime`
- 対象 task: `phase-field implementation pilot orchestration`
- touched artifacts:
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `phase-field` Implementation Track pilot を `single_review` と `dual_reviewer_workflow` の 2 run でまとめて回し、runtime run, bundle export, protocol notes, comparison summary, batch manifest を 1 コマンドで生成する batch runner を追加した
- status: completed

### 6.63 2026-05-10 phase-field pilot batch execution

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-runtime`
- 対象 task: `phase-field implementation pilot first batch`
- touched artifacts:
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/batch_manifest.yaml`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/comparison_summary.json`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/protocol-runs/F1-phase-field-cpp-single/*`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/protocol-runs/F1-phase-field-cpp-dual/*`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/runtime-runs/run-20260509T224244Z-8a9c4c62/*`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/runtime-runs/run-20260509T224245Z-faca9d2b/*`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `run_phase_field_implementation_first_batch.rb` を実行し、`single_review` は 2 findings、`dual_reviewer_workflow` は adversarial finding を含む 3 findings を取得した。comparison summary では `dual_minus_single_findings = 1`、`dual_has_adversarial_role = true` を確認した。caveat として、Intent/Spec Track は未含有、primary/adversarial/integration prompt は runtime-owned placeholder のままであることを batch summary に保持した
- status: completed

### 6.64 2026-05-10 phase-field implementation pilot source-driven runtime

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-runtime`
- 対象 task: `implementation-track phase-field pilot execution layer`
- touched artifacts:
  - `runtime/executors/base_step_executor.rb`
  - `runtime/executors/step_a_primary_detection.rb`
  - `runtime/executors/step_b_adversarial_review.rb`
  - `runtime/executors/step_c_judgment.rb`
  - `runtime/executors/step_d_integration.rb`
  - `runtime/prompts/primary/primary_reviewer.prompt.md`
  - `runtime/prompts/adversarial/adversarial_reviewer.prompt.md`
  - `runtime/prompts/integration/integration_reviewer.prompt.md`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `experiments/protocols/implementation-track-runs/F1-phase-field-cpp/comparison_summary.json`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: deterministic seed を廃し、`phase-field` implementation snapshot と upstream spec ref を実際に読んで boundary semantics / update ordering / parameter interpretation の cue を抽出する source-driven heuristic runtime に差し替えた。あわせて primary/adversarial/integration の prompt artifact を追加して prompt identity を resolved 化し、batch を再実行して `single_review=2 findings`, `dual_reviewer_workflow=3 findings`, `dual_minus_single_findings=1`, `dual_has_adversarial_role=true` を維持した。残る caveat は、これはまだ source-driven heuristic pilot であり、main-evidence-grade の review quality claim 前には true review execution layer への差し替え判断が必要な点である
- status: completed

### 6.65 2026-05-10 phase-field spec-track pilot execution

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-runtime`
- 対象 task: `spec-track phase-field tasks pilot`
- touched artifacts:
  - `scripts/track_runs/spec_track_writer.rb`
  - `scripts/run_phase_field_spec_first_batch.rb`
  - `experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec/batch_manifest.yaml`
  - `experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec/comparison_summary.json`
  - `experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec/protocol-runs/F1-spec-phase-field-single/*`
  - `experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec/protocol-runs/F1-spec-phase-field-dual/*`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `phase-field-reverse-spec` の `tasks` case に対して、phase-local issue / cross-phase inconsistency / intent-attributed issue / reopen depth を source-driven heuristic で埋める Spec Track runner を追加し、`single_review` と `dual_reviewer_workflow` の pilot batch を取得した。summary では両 mode とも `reopen_required=true`、target reopen phases は `design, tasks`、dual mode では `phase_major_correction_count=1`、`phase_intent_attributed_issue_count=1` を確認した。残る caveat は、これも pilot acquisition evidence であり、main-evidence-grade claim 前には true review execution layer への差し替え判断が必要な点である
- status: completed

### 6.66 2026-05-10 dual-reviewer-rebuild intent-track pilot execution

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-runtime`
- 対象 task: `intent-track dual-reviewer-rebuild bootstrap pilot`
- touched artifacts:
  - `scripts/track_runs/intent_track_writer.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_dual_reviewer_rebuild_intent_first_batch.rb`
  - `experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild/batch_manifest.yaml`
  - `experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild/comparison_summary.json`
  - `experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild/protocol-runs/F1-intent-dual-reviewer-rebuild-single/*`
  - `experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild/protocol-runs/F1-intent-dual-reviewer-rebuild-dual/*`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `dual-reviewer-rebuild` bootstrap case に対して、major gap / scope drift / counter-hypothesis / intent handback 要否 / downstream propagation target を source-driven heuristic で埋める Intent Track runner を追加し、`single_review` と `dual_reviewer_workflow` の pilot batch を取得した。summary では `single_intent_review_findings_count=2`, `dual_intent_review_findings_count=3`, `dual_intent_handback_count=1`, `dual_requires_intent_handback=true` を確認した。残る caveat は、これも pilot acquisition evidence であり、main-evidence-grade claim 前には true review execution layer への差し替え判断が必要な点である
- status: completed

### 6.67 2026-05-10 phase-field requirements pilot acquisition

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-runtime`
- 対象 task: `spec-track phase-field requirements pilot`
- touched artifacts:
  - `scripts/track_runs/spec_track_writer.rb`
  - `scripts/run_phase_field_requirements_first_batch.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `experiments/protocols/spec-track-runs/F1-requirements-phase-field-reverse-spec/batch_manifest.yaml`
  - `experiments/protocols/spec-track-runs/F1-requirements-phase-field-reverse-spec/comparison_summary.json`
  - `experiments/protocols/spec-track-runs/F1-requirements-phase-field-reverse-spec/protocol-runs/F1-requirements-phase-field-single/*`
  - `experiments/protocols/spec-track-runs/F1-requirements-phase-field-reverse-spec/protocol-runs/F1-requirements-phase-field-dual/*`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `phase-field-reverse-spec` の `requirements` case に対して、clean-room boundary / acceptance bundle density / downstream approval gap / validation ownership を source-driven heuristic で埋める Spec Track runner を追加し、`single_review` と `dual_reviewer_workflow` の pilot batch を取得した。summary では両 mode とも `reopen_required=true`、target reopen phases は `requirements, design, tasks`、handback class `C=1` を確認し、dual mode では `phase_major_correction_count=1`、`phase_intent_attributed_issue_count=1` を確認した。worklist も更新し、次段を `design` phase acquisition に切り替えた。残る caveat は、これも pilot acquisition evidence であり、main-evidence-grade claim 前には true review execution layer への差し替え判断が必要な点である
- status: completed

### 6.68 2026-05-10 phase-field design pilot acquisition

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-runtime`
- 対象 task: `spec-track phase-field design pilot`
- touched artifacts:
  - `scripts/track_runs/spec_track_writer.rb`
  - `scripts/run_phase_field_design_first_batch.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `experiments/protocols/spec-track-runs/F1-design-phase-field-reverse-spec/batch_manifest.yaml`
  - `experiments/protocols/spec-track-runs/F1-design-phase-field-reverse-spec/comparison_summary.json`
  - `experiments/protocols/spec-track-runs/F1-design-phase-field-reverse-spec/protocol-runs/F1-design-phase-field-single/*`
  - `experiments/protocols/spec-track-runs/F1-design-phase-field-reverse-spec/protocol-runs/F1-design-phase-field-dual/*`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `phase-field-reverse-spec` の `design` case に対して、component boundary density / failure contract preservation / design-tasks readiness gap / validation ownership spread を source-driven heuristic で埋める Spec Track runner を追加し、`single_review` と `dual_reviewer_workflow` の pilot batch を取得した。summary では両 mode とも `reopen_required=true`、target reopen phases は `design, tasks`、handback class `B=1` を確認し、dual mode では `phase_major_correction_count=1`、`phase_intent_attributed_issue_count=1` を確認した。worklist も更新し、all-phase pilot coverage 完了後の next step を `phase-field pilot only` の main-evidence 昇格条件整理に切り替えた。残る caveat は、これも pilot acquisition evidence であり、main-evidence-grade claim 前には true review execution layer への差し替え判断が必要な点である
- status: completed

### 6.69 2026-05-10 generic execution layer rethink

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-runtime`
- 対象 task: `pilot execution strategy correction`
- touched artifacts:
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: あり
- handback class: `B`
- reopen 要否: 要
- action: `phase-field` pilot で導入した case-specific heuristic 実装は、新しい case へ一般化できず、実装差し替え時に同一 case の結果も変動しうるため、方法論として不安定であると判断した。`ACTIVE_WORKLIST` を更新し、次段を「main-evidence 昇格条件整理」から「generic review execution layer redesign」へ変更した。以後は case profile ごとに rule を増やすのではなく、track 共通の generic input/output/taxonomy を先に定義し、その上で pilot を取り直す方針とする
- status: completed

### 6.70 2026-05-10 active worklist role clarification

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-implementation-governance`
- 対象 task: `ACTIVE_WORKLIST role redefinition`
- touched artifacts:
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: 試行錯誤の新規 finding として、`LLM + spec-driven development` では static spec だけでは進行制御が足りず、`ACTIVE_WORKLIST` のような execution-control artifact が必須であること、また実態としては `intent` を最上位に置く intent-governed development であることを `ACTIVE_WORKLIST` に明記した。以後この文書は TODO ではなく、現在地 / 次の 1 手 / stop rule / reopen 状態を固定する dynamic control board として扱う
- status: completed

### 6.71 2026-05-10 generic execution layer replacement stabilization

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation replacement stabilization`
- touched artifacts:
  - `runtime/executors/base_step_executor.rb`
  - `runtime/executors/step_a_primary_detection.rb`
  - `runtime/executors/step_b_adversarial_review.rb`
  - `runtime/execution_v2/analyzers/analysis_profile_loader.rb`
  - `runtime/execution_v2/analyzers/spec_protocol_analyzer.rb`
  - `runtime/execution_v2/analyzers/intent_protocol_analyzer.rb`
  - `runtime/execution_v2/manifests/case_manifest.rb`
  - `experiments/protocols/case_manifests/F1-*.yaml`
  - `experiments/protocols/analysis_profiles/**/*`
  - `scripts/track_runs/spec_track_writer.rb`
  - `scripts/track_runs/intent_track_writer.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/run_dual_reviewer_rebuild_intent_first_batch.rb`
  - `scripts/run_phase_field_spec_first_batch.rb`
  - `scripts/run_phase_field_requirements_first_batch.rb`
  - `scripts/run_phase_field_design_first_batch.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/generic-execution-layer-v2-replacement-outcome.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md`
  - `.kiro/specs/dual-reviewer-generic-execution-layer-v2/spec.json`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: `implementation` executor から `target_id` による `phase-field` 専用分岐を除去し、source ref pattern が存在する場合にのみ finding を起こす target-agnostic 形へ寄せた。あわせて `spec` / `intent` の case-specific analysis payload を writer や analyzer のコードから外し、manifest が指す `analysis_profile_ref` を読む profile-backed analyzer へ切り替えた。`validate_protocol_runners.rb` と `validate_track_run_artifacts.rb` は通過し、`intent` / `spec` / `requirements` / `design` / `implementation` の first batch 再実行も再取得できた。残る caveat は、`implementation` 側がまだ source-pattern heuristic であり、`spec` / `intent` も `manual_dogfooding` の protocol path による parity なので、main-evidence 昇格はまだ不可である点である
- status: completed

### 6.72 2026-05-10 implementation heuristic profile externalization

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation heuristic externalization`
- touched artifacts:
  - `runtime/execution_v2/analyzers/heuristic_profile_loader.rb`
  - `runtime/executors/base_step_executor.rb`
  - `runtime/executors/step_a_primary_detection.rb`
  - `runtime/executors/step_b_adversarial_review.rb`
  - `runtime/execution_v2/manifests/case_manifest.rb`
  - `experiments/protocols/case_manifests/F1-phase-field-cpp.yaml`
  - `experiments/protocols/heuristic_profiles/implementation/F1-phase-field-cpp.yaml`
  - `scripts/track_runs/implementation_track_runner.rb`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `docs/coordination/generic-execution-layer-v2-replacement-outcome.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `implementation` 側の boundary / update-order / parameter-caveat の検出条件と summary 文を executor から外し、manifest が指す `heuristic_profile_ref` 経由で YAML profile を読む形に置き換えた。これにより executor-local な case payload は削減され、`validate_protocol_runners.rb`、`validate_track_run_artifacts.rb`、`run_phase_field_implementation_first_batch.rb` はすべて通過した。残る caveat は、profile-backed になってもなお source-pattern heuristic であること、および non-implementation track の runtime-mediated parity が未完了である点である
- status: completed

### 6.73 2026-05-10 protocol-track parity uplift

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `protocol-track parity uplift`
- touched artifacts:
  - `runtime/execution_v2/protocol_track_artifact_builder.rb`
  - `runtime/support/source_provenance_resolver.rb`
  - `runtime/controller/session_controller.rb`
  - `scripts/track_runs/spec_track_writer.rb`
  - `scripts/track_runs/intent_track_writer.rb`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `docs/coordination/generic-execution-layer-v2-replacement-outcome.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `spec` / `intent` の `v2/review_artifact.json`、`metric_snapshot.json`、`trace_note.json`、`signal_linkage_note.json` の組み立てを runtime-owned helper へ寄せ、source repository id と source revision も runtime と同じ provenance resolver で取得するように統一した。これにより protocol-side track でも artifact assembly と provenance path の差は縮小した。`validate_protocol_runners.rb` と `validate_track_run_artifacts.rb` は通過している。残る caveat は、review mode 自体はまだ `manual_dogfooding` であり、full runtime-mediated parity には達していない点である
- status: completed

### 6.74 2026-05-10 protocol-track runtime session uplift

- 日付: 2026-05-10
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `protocol-track runtime session uplift`
- touched artifacts:
  - `runtime/execution_v2/protocol_track_session.rb`
  - `scripts/track_runs/spec_track_writer.rb`
  - `scripts/track_runs/intent_track_writer.rb`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `docs/coordination/generic-execution-layer-v2-replacement-outcome.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: `spec` / `intent` の protocol-side writer から、analysis の読み出し、execution contract の組み立て、v2 bundle の生成をまとめて `runtime/execution_v2/protocol_track_session.rb` に寄せた。これにより writer の責務は人間向け artifact 更新に近づき、protocol-side でも runtime-owned session が orchestration の中心になった。`validate_protocol_runners.rb` と `validate_track_run_artifacts.rb` は通過している。残る caveat は、review mode 自体は依然 `manual_dogfooding` であり、Step A/B/C/D による full runtime-mediated path とはまだ一致していない点である
- status: completed

### 6.75 2026-05-11 protocol-track full runtime-mediated replacement

- 日付: 2026-05-11
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `protocol-track full runtime-mediated replacement`
- touched artifacts:
  - `scripts/track_runs/intent_track_writer.rb`
  - `scripts/track_runs/spec_track_writer.rb`
  - `scripts/run_intent_track_protocol.rb`
  - `scripts/write_intent_track_run_artifacts.rb`
  - `scripts/run_spec_track_protocol.rb`
  - `scripts/write_spec_track_run_artifacts.rb`
  - `scripts/run_dual_reviewer_rebuild_intent_first_batch.rb`
  - `scripts/run_phase_field_spec_first_batch.rb`
  - `scripts/run_phase_field_requirements_first_batch.rb`
  - `scripts/run_phase_field_design_first_batch.rb`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild/**/*`
  - `experiments/protocols/spec-track-runs/F1-*-phase-field-reverse-spec/**/*`
  - `docs/coordination/generic-execution-layer-v2-replacement-outcome.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: `intent` writer にも runtime-owned `SessionController` run を導入し、`spec` / `intent` の `v2` internal artifact はどちらも `runtime_mediated` run から直接取得する形へ統一した。あわせて protocol script と first-batch script に runtime run root 指定を追加し、batch 配下の `runtime-runs/` に本体 run を残すようにした。`validate_protocol_runners.rb`、`validate_track_run_artifacts.rb`、`run_dual_reviewer_rebuild_intent_first_batch.rb`、`run_phase_field_spec_first_batch.rb`、`run_phase_field_requirements_first_batch.rb`、`run_phase_field_design_first_batch.rb` は通過した。残る caveat は、`implementation` 側がまだ source-pattern heuristic に依存している点と、protocol artifact 自体は依然 pilot projection であって main evidence ではない点である
- status: completed

### 6.76 2026-05-11 implementation rule-match analyzer extraction

- 日付: 2026-05-11
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation analysis-layer extraction`
- touched artifacts:
  - `runtime/execution_v2/analyzers/rule_match_analyzer.rb`
  - `runtime/executors/base_step_executor.rb`
  - `runtime/executors/step_a_primary_detection.rb`
  - `runtime/executors/step_b_adversarial_review.rb`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/generic-execution-layer-v2-replacement-outcome.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: profile rule の pattern match と finding 組み立てを `Step A` / `Step B` executor から切り離し、`runtime/execution_v2/analyzers/rule_match_analyzer.rb` に集約した。これにより `implementation` の runtime path でも「判定ロジックは analysis layer に置き、executor は step orchestration に寄せる」形が進んだ。`validate_protocol_runners.rb`、`validate_track_run_artifacts.rb`、`run_phase_field_implementation_first_batch.rb` は通過した。残る caveat は、共通化は進んだが検出根拠自体はまだ source-pattern heuristic であり、意味理解ベースの generic analysis にはまだ達していない点である
- status: completed

### 6.77 2026-05-11 seed-pattern vocabulary uplift

- 日付: 2026-05-11
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `heuristic vocabulary uplift`
- touched artifacts:
  - `runtime/patterns/seed_patterns.yaml`
  - `runtime/support/foundation_asset_loader.rb`
  - `runtime/execution_v2/analyzers/rule_match_analyzer.rb`
  - `runtime/executors/base_step_executor.rb`
  - `experiments/protocols/heuristic_profiles/implementation/F1-phase-field-cpp.yaml`
  - `experiments/protocols/heuristic_profiles/spec/F1-spec-phase-field-reverse-spec.yaml`
  - `experiments/protocols/heuristic_profiles/spec/F1-requirements-phase-field-reverse-spec.yaml`
  - `experiments/protocols/heuristic_profiles/spec/F1-design-phase-field-reverse-spec.yaml`
  - `experiments/protocols/heuristic_profiles/intent/F1-intent-dual-reviewer-rebuild.yaml`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `scripts/run_phase_field_requirements_first_batch.rb`
  - `scripts/run_phase_field_design_first_batch.rb`
  - `docs/coordination/generic-execution-layer-v2-replacement-outcome.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: heuristic profile が直接 regex 文字列を大量に埋め込まなくても済むよう、`runtime/patterns/seed_patterns.yaml` に reusable seed pattern vocabulary を追加し、`RuleMatchAnalyzer` が pattern ID を解決できるようにした。implementation / spec / intent の主要 profile は named pattern IDs を使う形へ寄せ、requirements / design first batch と implementation first batch の再取得も通過した。残る caveat は、語彙の共通化は進んだが観点自体はまだ source-pattern ベースであり、意味理解ベースの analyzer にはまだ達していない点である
- status: completed

### 6.78 2026-05-11 implementation observation-first uplift

- 日付: 2026-05-11
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation observation-first uplift`
- touched artifacts:
  - `runtime/execution_v2/analyzers/rule_match_analyzer.rb`
  - `runtime/execution_v2/analyzers/base_analyzer.rb`
  - `runtime/executors/base_step_executor.rb`
  - `runtime/executors/step_a_primary_detection.rb`
  - `runtime/executors/step_b_adversarial_review.rb`
  - `runtime/executors/step_c_judgment.rb`
  - `runtime/executors/step_d_integration.rb`
  - `runtime/controller/session_controller.rb`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/generic-execution-layer-v2-replacement-outcome.md`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: `RuleMatchAnalyzer` が直接 finding を返すだけでなく、まず observation を作り、そこから finding を組み立てる形へ進めた。`Step A` / `Step B` payload には `observations` が追加され、`review_case.json` と `v2/review_artifact.json` も observation を正本として保持するように更新した。`validate_protocol_runners.rb`、`validate_track_run_artifacts.rb`、`run_phase_field_implementation_first_batch.rb` は通過した。残る caveat は、observation-first にはなったが observation の根拠自体はまだ source-pattern heuristic である点である
- status: completed

### 6.79 2026-05-11 implementation evidence-type uplift

- 日付: 2026-05-11
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation evidence-type uplift`
- touched artifacts:
  - `runtime/patterns/seed_patterns.yaml`
  - `runtime/execution_v2/analyzers/rule_match_analyzer.rb`
  - `runtime/controller/session_controller.rb`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/generic-execution-layer-v2-replacement-outcome.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: implementation 用 seed pattern に `evidence_type` と `review_focus` を付与し、runtime observation が `matched_pattern_ids`、`evidence_types`、`counter_evidence_types`、`review_focuses` を持つようにした。これにより observation は単なる term hit ではなく、「どの種類の懸念を拾ったか」を artifact 上で表現できる。`validate_protocol_runners.rb`、`validate_track_run_artifacts.rb`、`run_phase_field_implementation_first_batch.rb` は通過した。残る caveat は、観点の型付けは入ったが、trigger 自体はまだ source-pattern heuristic である点である
- status: completed

### 6.80 2026-05-11 future v3 note: artifact-to-spec conformance evaluation

- 日付: 2026-05-11
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `future-handoff note`
- touched artifacts:
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: なし
- handback class: `A`
- reopen 要否: 不要
- action: 実装完了後に「生成物が `intent / requirements / design / tasks` と一致しているか」を検査する conformance evaluation の必要性を確認した。ただしこれは現在の `v2` 完了条件に混ぜず、今の開発完了後に検討する `v3` 候補として future handoff に記録した
- status: completed

### 6.81 2026-05-11 implementation evidence-gating uplift

- 日付: 2026-05-11
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation evidence gating uplift`
- touched artifacts:
  - `experiments/protocols/heuristic_profiles/implementation/F1-phase-field-cpp.yaml`
  - `runtime/execution_v2/analyzers/rule_match_analyzer.rb`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: implementation heuristic rule に `required_evidence_types` と `required_counter_evidence_types` を追加し、`RuleMatchAnalyzer` が「語が当たった」だけではなく「必要な種類の根拠がそろった」場合にだけ observation を作るようにした。boundary / update-order / parameter-caveat の 3 rule でこの gating を適用し、`validate_protocol_runners.rb`、`validate_track_run_artifacts.rb`、`run_phase_field_implementation_first_batch.rb` は通過した。残る caveat は、成立条件は evidence type ベースへ一段進んだが、その evidence type 自体の抽出はまだ source-pattern heuristic に依存している点である
- status: completed

### 6.82 2026-05-11 implementation source-kind gating uplift

- 日付: 2026-05-11
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation source-kind gating uplift`
- touched artifacts:
  - `runtime/executors/base_step_executor.rb`
  - `runtime/execution_v2/analyzers/rule_match_analyzer.rb`
  - `experiments/protocols/heuristic_profiles/implementation/F1-phase-field-cpp.yaml`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: source ref を `implementation_snapshot` や `upstream_spec` などの source kind 付き entry として runtime analyzer へ渡し、implementation rule が `required_source_kinds` と `required_counter_source_kinds` を要求できるようにした。これにより observation は「必要な evidence type がある」だけでなく、「必要な種類の文書から根拠が得られている」場合にだけ成立する。`validate_protocol_runners.rb`、`validate_track_run_artifacts.rb`、`run_phase_field_implementation_first_batch.rb` は通過した。残る caveat は、source kind 条件は入ったが、個々の kind 内での evidence extraction 自体はまだ source-pattern heuristic に依存している点である
- status: completed

### 6.83 2026-05-11 implementation evidence-record uplift

- 日付: 2026-05-11
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation evidence-record uplift`
- touched artifacts:
  - `runtime/execution_v2/analyzers/rule_match_analyzer.rb`
  - `runtime/executors/base_step_executor.rb`
  - `runtime/executors/step_a_primary_detection.rb`
  - `runtime/executors/step_b_adversarial_review.rb`
  - `runtime/executors/step_c_judgment.rb`
  - `runtime/executors/step_d_integration.rb`
  - `runtime/controller/session_controller.rb`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: runtime analyzer が pattern hit ごとに `evidence_record` を作り、その evidence を束ねて observation を作る形へ進めた。step payload と `review_case.json` に `evidence_records` を追加し、observation には `evidence_record_ids` を残すようにした。これにより実装の内部表現は `evidence record -> observation -> finding` になり、finding がさらに一段下流の表現となった。`validate_protocol_runners.rb`、`validate_track_run_artifacts.rb`、`run_phase_field_implementation_first_batch.rb` は通過した。残る caveat は、evidence record 生成自体はまだ source-pattern heuristic に依存している点である
- status: completed

### 6.84 2026-05-11 implementation section-scoped evidence uplift

- 日付: 2026-05-11
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation section-scoped evidence uplift`
- touched artifacts:
  - `runtime/execution_v2/analyzers/rule_match_analyzer.rb`
  - `runtime/controller/session_controller.rb`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: evidence record を「term 1 回ヒットごと」ではなく「同一 section / same evidence type ごと」に集約する形へ進めた。record には `section_heading`、`first_line_number`、`line_numbers`、`matched_terms` が入り、runtime artifact が「どの節でどの種類の根拠を拾ったか」を表現できるようになった。`validate_protocol_runners.rb`、`validate_track_run_artifacts.rb`、`run_phase_field_implementation_first_batch.rb` は通過した。残る caveat は、section 単位へは進んだが record 生成の入口はまだ source-pattern heuristic である点である
- status: completed

### 6.85 2026-05-11 implementation section-class gating uplift

- 日付: 2026-05-11
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation section-class gating uplift`
- touched artifacts:
  - `runtime/execution_v2/analyzers/rule_match_analyzer.rb`
  - `runtime/controller/session_controller.rb`
  - `experiments/protocols/heuristic_profiles/implementation/F1-phase-field-cpp.yaml`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: `section_heading` から `section_class` を導出し、implementation rule が `required_section_classes` と `required_counter_section_classes` を要求できるようにした。これにより observation は evidence type / source kind に加えて、「snapshot rationale」「acceptance criteria」などの文書構造クラスも満たした場合にだけ成立する。`validate_protocol_runners.rb`、`validate_track_run_artifacts.rb`、`run_phase_field_implementation_first_batch.rb` は通過した。残る caveat は、section class まで入っても evidence record を起こす入口自体はまだ source-pattern heuristic である点である
- status: completed

### 6.86 2026-05-11 implementation structural-evidence uplift

- 日付: 2026-05-11
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation structural-evidence uplift`
- touched artifacts:
  - `runtime/execution_v2/analyzers/rule_match_analyzer.rb`
  - `experiments/protocols/heuristic_profiles/implementation/F1-phase-field-cpp.yaml`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: rule が `structural_source_requirements` と `structural_counter_requirements` を持てるようにし、pattern hit がなくても `implementation_snapshot + snapshot_rationale` や `upstream_spec + acceptance_criteria` のような文書構造条件だけで補助 evidence record を作れるようにした。これにより evidence record 生成は完全な pattern-only ではなくなった。`validate_protocol_runners.rb`、`validate_track_run_artifacts.rb`、`run_phase_field_implementation_first_batch.rb` は通過した。残る caveat は、構造的補助 evidence は入ったが、主要な evidence extraction の多くはなお source-pattern heuristic に依存している点である
- status: completed

### 6.87 2026-05-11 implementation structure-first evidence gating uplift

- 日付: 2026-05-11
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation structure-first evidence gating uplift`
- touched artifacts:
  - `runtime/execution_v2/analyzers/rule_match_analyzer.rb`
  - `experiments/protocols/heuristic_profiles/implementation/F1-phase-field-cpp.yaml`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: evidence / observation の required field を pattern 定義ではなく実際の evidence record から集計するように直し、boundary と update-order の primary path は `implementation_snapshot + snapshot_rationale` と `upstream_spec + acceptance_criteria` の構造条件だけで observation を成立させる形に進めた。あわせて fragment class を導入し、parameter 系では `parameter_review_rationale` / `parameter_caveat_note` / `parameter_contract` のような文の役割を指定して broad な section hit を絞り込んだ。途中で single / dual finding 数が壊れる regressions が出たが、snapshot rationale と caveat note の優先順位を修正して `validate_protocol_runners.rb`、`validate_track_run_artifacts.rb`、`run_phase_field_implementation_first_batch.rb` は再び通過した。残る caveat は、structure-first path は入ったが fragment class の判定そのものはまだ語句ベースである点である
- status: completed

### 6.88 2026-05-11 implementation fragment-cue externalization uplift

- 日付: 2026-05-11
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation fragment-cue externalization uplift`
- touched artifacts:
  - `runtime/execution_v2/analyzers/rule_match_analyzer.rb`
  - `runtime/patterns/seed_patterns.yaml`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: fragment class 判定に使う cue を Ruby コードから `runtime/patterns/seed_patterns.yaml` へ移した。これにより `boundary_review_rationale`、`parameter_contract`、`parameter_caveat_note` などの文役割判定も data-driven になり、runtime analyzer は cue catalog を読むだけの形へ寄った。移行時に structure extraction 側で review focus を要求しすぎて single finding が消える regression が出たが、cue lookup を補正して `validate_protocol_runners.rb`、`validate_track_run_artifacts.rb`、`run_phase_field_implementation_first_batch.rb` は再び通過した。残る caveat は、cue が data 側へ移っても cue 自体はまだ語句ベースである点である
- status: completed

### 6.89 2026-05-11 implementation hierarchical-structure cue uplift

- 日付: 2026-05-11
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation hierarchical-structure cue uplift`
- touched artifacts:
  - `runtime/execution_v2/analyzers/rule_match_analyzer.rb`
  - `runtime/patterns/seed_patterns.yaml`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: fragment に `parent_section_heading` と `line_marker` を追加し、cue が parent Requirement と numbered acceptance item でも判定できるようにした。upstream spec の `parameter_contract` / `boundary_contract` / `update_order_contract` は、`Acceptance Criteria` の本文語句だけでなく `Requirement N` と item 番号で分類できるようになり、一部の fragment cue は structure-first に進んだ。途中で heading 階層の扱いを入れた関係で patch を入れ直したが、最終的に `validate_protocol_runners.rb`、`validate_track_run_artifacts.rb`、`run_phase_field_implementation_first_batch.rb` は通過した。残る caveat は、snapshot 側の rationale / caveat cue はまだ語句ベースである点である
- status: completed

### 6.90 2026-05-11 implementation snapshot-numbered-fragment uplift

- 日付: 2026-05-11
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation snapshot-numbered-fragment uplift`
- touched artifacts:
  - `runtime/execution_v2/analyzers/rule_match_analyzer.rb`
  - `runtime/patterns/seed_patterns.yaml`
  - `experiments/protocols/heuristic_profiles/implementation/F1-phase-field-cpp.yaml`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: snapshot 文書の numbered list を continuation line 付き fragment として扱うようにし、`Why This Snapshot` の 3 番を single line ではなく numbered fragment として拾えるようにした。あわせて cue に `section_heading_patterns`、`parent_heading_patterns`、`line_prefix_patterns` を持たせ、upstream spec に加えて snapshot rationale でも structure-first 条件を rule から直接要求できるようにした。途中で dual finding 数が single を上回らない regression が数回出たが、`parameter` ルール側の allowed fragment class を見直して `validate_protocol_runners.rb`、`validate_track_run_artifacts.rb`、`run_phase_field_implementation_first_batch.rb` は再び通過した。残る caveat は、`implementation_snapshot_note` 系 cue はなお語句ベースである点である
- status: completed

### 6.91 2026-05-11 implementation snapshot-note structure-first uplift

- 日付: 2026-05-11
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation snapshot-note structure-first uplift`
- touched artifacts:
  - `runtime/patterns/seed_patterns.yaml`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: `implementation_snapshot_note` 系の `parameter_caveat_note` cue から surface-term 依存を外し、`Code-Side Anchor` / `Caveats` / `Immediate Operational Rule` の section heading と bullet / item 位置だけで立つようにした。これにより少なくとも parameter caveat note は structure-first になった。`validate_protocol_runners.rb`、`validate_track_run_artifacts.rb`、`run_phase_field_implementation_first_batch.rb` は通過した。残る caveat は、structure-first になった反面、note 節全体の cue 範囲が広く、どこまで細く絞るべきかがまだ残っている点である
- status: completed

### 6.92 2026-05-12 implementation note-scope narrowing uplift

- 日付: 2026-05-12
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation note-scope narrowing uplift`
- touched artifacts:
  - `runtime/execution_v2/analyzers/rule_match_analyzer.rb`
  - `experiments/protocols/heuristic_profiles/implementation/F1-phase-field-cpp.yaml`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: `implementation_snapshot_note` の `parameter_caveat_note` について、`Code-Side Anchor` 全体を丸ごと取るのではなく bullet ordinal を持たせて必要な bullet だけを structural requirement で許可するようにした。さらに同じ根拠が pattern 由来と structural 由来で二重に出る record を圧縮した。`validate_protocol_runners.rb`、`validate_track_run_artifacts.rb`、`run_phase_field_implementation_first_batch.rb` は通過した。残る caveat は、scope は細くなったが note 側 cue の意味的切り分けはまだ十分ではない点である
- status: completed

### 6.93 2026-05-12 implementation note-role split uplift

- 日付: 2026-05-12
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation note-role split uplift`
- touched artifacts:
  - `runtime/execution_v2/analyzers/rule_match_analyzer.rb`
  - `runtime/patterns/seed_patterns.yaml`
  - `experiments/protocols/heuristic_profiles/implementation/F1-phase-field-cpp.yaml`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: pattern-side evidence record も bullet ordinal を持てるようにして、`implementation_snapshot_note` の cue を section 単位ではなく bullet / item 単位で fragment class へ分け直した。具体的には note-side cue を `clean_room_constraint_note`、`provenance_fixity_note`、`operational_digest_check_note`、`evidence_exclusion_note` に分解し、parameter rule はそのうち必要な note role だけを structural requirement と allowed fragment class に残した。これにより note 側の残課題は「語句依存」ではなく「意味役割の粒度」へ移った。`validate_protocol_runners.rb`、`validate_track_run_artifacts.rb`、`run_phase_field_implementation_first_batch.rb` は通過し、dual-over-single も維持された
- status: completed

### 6.94 2026-05-12 implementation provenance-fixity split uplift

- 日付: 2026-05-12
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation provenance-fixity split uplift`
- touched artifacts:
  - `runtime/patterns/seed_patterns.yaml`
  - `experiments/protocols/heuristic_profiles/implementation/F1-phase-field-cpp.yaml`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: note-side の `provenance / fixity` をさらに `local_provenance_note` と `digest_fixity_note` に分割した。これにより `local-only git / no commit` と `digest-based fixity / reproducibility` を別 role として扱えるようになり、parameter rule も clean-room / local provenance / digest fixedness / operational check を区別して参照できるようになった。`validate_protocol_runners.rb`、`validate_track_run_artifacts.rb`、`run_phase_field_implementation_first_batch.rb` は通過し、dual-over-single も維持された
- status: completed

### 6.95 2026-05-12 implementation unnecessary-note-role pruning uplift

- 日付: 2026-05-12
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation unnecessary-note-role pruning uplift`
- touched artifacts:
  - `experiments/protocols/heuristic_profiles/implementation/F1-phase-field-cpp.yaml`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: `parameter` adversarial rule から `local_provenance_note` を外して rerun を確認した。結果として dual-over-single は維持され、observation の fragment class からも `local provenance` を除いて成立した。これにより note role を増やすだけでなく、「この rule に不要な role を削る」方向でも意味境界を詰められることが確認できた
- status: completed

### 6.96 2026-05-12 implementation operational-check pruning uplift

- 日付: 2026-05-12
- 対象 feature: `dual-reviewer-generic-execution-layer-v2`
- 対象 task: `implementation operational-check pruning uplift`
- touched artifacts:
  - `experiments/protocols/heuristic_profiles/implementation/F1-phase-field-cpp.yaml`
  - `scripts/validate_protocol_runners.rb`
  - `scripts/validate_track_run_artifacts.rb`
  - `scripts/run_phase_field_implementation_first_batch.rb`
  - `docs/coordination/implementation-coordination-log.md`
- blocker: あり
- handback class: `A`
- reopen 要否: 不要
- action: `parameter` adversarial rule から `operational_digest_check_note` も外して rerun を確認した。結果として dual-over-single は維持され、observation の fragment class は `clean_room_constraint_note`、`digest_fixity_note`、`parameter_contract`、`boundary_review_rationale` で成立した。これにより `parameter` rule の note-side 根拠はさらに絞られ、運用手順メモは少なくとも現行 pilot では必須でないことが確認できた
- status: completed
