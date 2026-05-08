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
