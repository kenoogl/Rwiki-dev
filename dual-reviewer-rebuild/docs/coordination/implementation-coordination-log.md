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
