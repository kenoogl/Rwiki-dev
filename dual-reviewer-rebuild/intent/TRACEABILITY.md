# TRACEABILITY

## 1. この文書の役割

この文書は、`dual-reviewer-rebuild` における上位意図と下位実装の対応関係を追跡するための文書である。

`INTENT.md`、`NON_GOALS.md`、`DESIGN_PRINCIPLES.md` が上位方針を定めても、それがどの `operations` 文書やどの spec に落ちているかが追えなければ、設計変更時に整合性が崩れる。したがって本書は、意図から spec、spec から artifact、artifact から evidence までの橋渡しを担う。

本書の目的は次の 3 つである。

- 上位意図がどの文書・spec・artifact に実装されるかを明示する
- 設計変更時に、どこを見直す必要があるかを特定できるようにする
- runtime、evaluation、paper の責務混線を防ぐ

## 2. traceability の単位

本 repo では、traceability を以下の 5 層で扱う。

1. `intent`
2. `operations`
3. `specs`
4. `artifacts`
5. `evidence`

意味:

- `intent` = なぜ作るか、何を避けるか、どんな原則で設計するか
- `operations` = deploy、trust、human workflow、data invalidation の運用境界
- `specs` = feature-level requirements / design / tasks
- `artifacts` = runtime files、schemas、prompts、validators、analysis scripts
- `evidence` = run logs、metrics、improvement proposals、paper-facing reports

補足:

- manual review 自体も `intent -> requirements -> design -> tasks` の順で下流へ流れる
- 各 review stage の内部では feature 横断の review wave を形成する
- したがって traceability は artifact だけでなく、review progression に対しても上流から下流への依存を持つ

## 3. 基本ルール

- 各 major intent は、少なくとも 1 つ以上の `operations` 文書または `spec` に結びつく
- 各 `spec` は、どの intent を実装しているか説明できなければならない
- 各 feature の `requirements` は、どの intent 命題を受けているか説明できなければならない
- 各 runtime-critical artifact は、対応する spec を説明できなければならない
- 各 evidence artifact は、依拠する protocol / prompt / runtime version を追えなければならない
- paper-facing artifact は runtime rule の正本になってはならない
- 上流文書または既存 spec に遡上修正が入った場合は、対応 phase の cross-spec alignment を再実施しなければならない
- 上位 phase の修正は、完了済みの下流 phase を reopen し、再チェック対象に戻す
- implementation 中に spec 差分や shared artifact 競合が見つかった場合は、implementation coordination log に記録し、必要なら上流 phase を reopen する

## 3.5 Intent-to-Requirements Trace Matrix

本 repo では、`INTENT.md` の主要命題と各 feature の `requirements` の対応を追跡するために、別途 trace matrix を持つことができる。

この matrix を作る場合、役割は次の通りとする。

- `TRACEABILITY.md`
  - traceability の原則と層構造を定義する正本
- `intent-to-requirements-trace-matrix.md`
  - 主要 intent 命題と individual requirement の具体対応を記録する補助的正本

matrix は単なる説明メモではなく、上位意図から requirement への流れを監査するための運用文書として扱う。

更新必須トリガー、更新不要ケース、運用ルールの正本は [intent-to-requirements-trace-matrix.md](../docs/traceability/intent-to-requirements-trace-matrix.md) に置く。

本書では次のみを固定ルールとする。

- trace matrix の更新なしに `intent` または `requirements` の意味変更を確定扱いしてはならない
- trace matrix 更新後は、必要に応じて `requirements alignment gate` を再実施する
- trace matrix に `gap` または `deferred` が残る場合は、その理由を明記する

## 4. intent -> operations 対応

### 4.1 再現可能な runtime を作る

対応先:

- `operations/DEPLOYMENT_MODEL.md`
- `operations/TRUST_BOUNDARY.md`
- `operations/DATA_INVALIDATION_POLICY.md`
- `REPRODUCIBILITY_CONTRACT.md`
- `SYSTEM_BOUNDARY.md`

説明:

- repo-contained で deploy するための前提は deployment model に落ちる
- 何を system success とみなすかは trust boundary に落ちる
- valid / invalid を分離する条件は invalidation policy に落ちる

### 4.2 protocol drift を防ぐ

対応先:

- `operations/DATA_INVALIDATION_POLICY.md`
- `REPRODUCIBILITY_CONTRACT.md`
- `EVIDENCE_PROTOCOL.md`
- `dual-reviewer-foundation`
- `dual-reviewer-evaluation`

説明:

- drift 防止は metadata と invalidation 条件の両方で担保する
- foundation が required fields を定義し、evaluation がそれを使って除外する

### 4.3 runtime と evaluation / paper の混線を防ぐ

対応先:

- `SYSTEM_BOUNDARY.md`
- `PAPER_WORK_BREAKDOWN.md`
- `dual-reviewer-evaluation`
- `dual-reviewer-paper-interface`

説明:

- system boundary で責務境界を固定する
- paper-facing output は paper-interface に限定する

### 4.4 review 記録と内部挙動から継続改善する

対応先:

- `SELF_IMPROVEMENT_LOOP.md`
- `dual-reviewer-self-improvement`
- `dual-reviewer-foundation`
- `dual-reviewer-evaluation`

説明:

- foundation が logs の土台 schema を定義する
- evaluation が measurable な形に整える
- self-improvement が proposal loop に変換する

### 4.5 人が全体像を理解できるようにする

対応先:

- `intent/INTENT.md`
- `intent/NON_GOALS.md`
- `intent/DESIGN_PRINCIPLES.md`
- `SYSTEM_BOUNDARY.md`
- 本書自身

説明:

- 人間理解可能性は runtime 機能だけではなく文書構造そのものの責務である

## 5. design principles -> specs 対応

### 5.1 Repo-Contained Runtime

主対応 spec:

- `dual-reviewer-foundation`
- `dual-reviewer-runtime`

反映先 artifact:

- `runtime/prompts/`
- `runtime/policies/`
- `runtime/schemas/`
- `runtime/config/`
- `runtime/validators/`

### 5.2 Protocol First

主対応 spec:

- `dual-reviewer-foundation`
- `dual-reviewer-evaluation`

反映先 artifact:

- `REPRODUCIBILITY_CONTRACT.md`
- `EVIDENCE_PROTOCOL.md`
- run metadata schema

### 5.3 Immutable Raw Evidence

主対応 spec:

- `dual-reviewer-evaluation`
- `dual-reviewer-self-improvement`

反映先 artifact:

- `experiments/runs/`
- `experiments/analysis/`
- invalidation markers
- proposal artifacts

### 5.4 Trust Boundary Separation

主対応 spec:

- `dual-reviewer-runtime`
- `dual-reviewer-foundation`

反映先 artifact:

- `operations/TRUST_BOUNDARY.md`
- validators
- review output contract

### 5.5 Evidence-Driven Change

主対応 spec:

- `dual-reviewer-self-improvement`
- `dual-reviewer-evaluation`

反映先 artifact:

- `learning/proposals/`
- `learning/approved-updates/`
- `learning/rejected-updates/`

### 5.6 Runtime / Evaluation / Paper Separation

主対応 spec:

- `dual-reviewer-runtime`
- `dual-reviewer-evaluation`
- `dual-reviewer-paper-interface`

反映先 artifact:

- `runtime/`
- `experiments/`
- `paper/`

## 6. non-goals -> exclusion 対応

### 6.1 public contribution intake は初期対象外

影響:

- `dual-reviewer-evaluation` に external ingestion requirement を入れない
- `dual-reviewer-self-improvement` は repo 内 evidence だけを初期入力とする

### 6.2 multi-vendor collective learning は初期対象外

影響:

- `dual-reviewer-foundation` は role 抽象名までに留める
- `dual-reviewer-runtime` に vendor federation logic を入れない

### 6.3 packaged CLI / hosted service は初期対象外

影響:

- deployment model は local-only から始める
- `runtime` 設計で配布 UX を優先しない

### 6.4 paper-first optimization は対象外

影響:

- `dual-reviewer-paper-interface` は consumer であり producer ではない
- paper 都合の field 追加を foundation に逆流させない

## 7. specs -> artifact 対応

### 7.1 `dual-reviewer-foundation`

想定 artifact:

- `runtime/schemas/*`
- `runtime/prompts/judgment_*`
- `runtime/config/*`
- `runtime/policies/` の一部共通定義

### 7.2 `dual-reviewer-runtime`

想定 artifact:

- `runtime/skills/*`
- orchestration code
- run close validation hooks

### 7.3 `dual-reviewer-evaluation`

想定 artifact:

- `experiments/protocols/*`
- `experiments/analysis/*`
- metrics and figure generators

### 7.4 `dual-reviewer-paper-interface`

想定 artifact:

- `paper/reports/*`
- `paper/figures/*`
- `paper/tables/*`

### 7.5 `dual-reviewer-self-improvement`

想定 artifact:

- `learning/findings/*`
- `learning/proposals/*`
- replay / backtest support scripts

## 8. artifacts -> evidence 対応

artifact が生成または参照する evidence の系統を分ける。

### 8.1 runtime artifacts

主に生成する evidence:

- review_case logs
- finding records
- judgment records
- metadata records

### 8.2 evaluation artifacts

主に生成する evidence:

- validity reports
- metrics summaries
- exclusion reports
- figure/table intermediate data

### 8.3 self-improvement artifacts

主に生成する evidence:

- recurring failure findings
- improvement proposals
- backtest results
- approval / rejection records

### 8.4 paper-interface artifacts

主に生成する evidence:

- report fragments
- paper-facing tables
- figure outputs

## 9. 変更時の参照手順

### 9.1 intent が変わるとき

見直すもの:

- `operations/`
- 影響する spec requirements
- `SYSTEM_BOUNDARY.md`
- 本書
- 影響 phase に応じた cross-spec alignment 文書

### 9.2 operations が変わるとき

見直すもの:

- 対応する spec requirements / design
- validators
- run metadata contract
- invalidation policy と evaluation pipeline
- 影響 phase に応じた cross-spec alignment 文書

### 9.3 spec が変わるとき

見直すもの:

- 対応 artifact
- 対応 tests
- 対応 evidence contract
- 必要なら上位 intent / principles との整合
- multi-feature の場合は同 phase の他 feature spec との alignment gate 対象

補足:

- `requirements.md` を修正したら `cross-spec-requirements-alignment.md` を再確認または更新する
- `design.md` を修正したら `cross-spec-design-alignment.md` を再確認または更新する
- `tasks.md` を修正したら将来の `cross-spec-tasks-alignment.md` を再確認または更新する
- `intent/operations` の修正は、影響下にある完了済み `requirements/design/tasks` を reopen して再確認する

### 9.4 paper 側の都合で変更したくなったとき

手順:

1. まず paper-interface だけで吸収できるか検討する
2. 無理なら evaluation の変更で足りるか検討する
3. foundation / runtime を変える場合は intent と principles に照らして正当化できるか確認する

## 10. 現時点の traceability 上の優先確認点

現時点で特に追跡を強く意識すべきなのは以下である。

- `foundation` requirement と旧 schema / prompt / pattern assets の対応
- `runtime` requirement と旧 `dr-*` skill 群の対応
- `evaluation` requirement と旧 dogfeeding scripts の対応
- `self-improvement` requirement と旧 review logs / comparison artifacts の対応
- `paper-interface` requirement と旧 paper planning artifacts の対応

## 11. この文書の完成条件

本書は、少なくとも以下を満たすときに有効とみなす。

- 上位意図から spec への流れを maintainer が説明できる
- spec 変更時に、見直すべき下位 artifact と上位文書を特定できる
- runtime、evaluation、paper の責務が本書上で混線していない
