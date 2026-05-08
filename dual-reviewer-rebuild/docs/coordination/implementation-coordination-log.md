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

implementation 中の手戻りは、少なくとも次の 3 区分で判定する。

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

### 判定原則

- task の意図を変えないなら `A`
- task の意図は維持できるが設計境界を直す必要があるなら `B`
- そもそも contract が不足しているなら `C`

判定に迷う場合は、より上流へ戻す側に倒す。

## 4. 記録フォーマット

各 coordination entry では次を残す。

- 日付
- 対象 feature
- 対象 task
- touched artifacts
- blocker
- handback class (`A` / `B` / `C`)
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
