# Dual-Reviewer Rebuild Plan

_作成日: 2026-05-08_
_目的: `Rwiki-dev` から review system 再構築を切り出す際の初期方針を固定する_
_位置付け: 旧 repo 側の整理文書。新 repo 側の正式 SSoT ではないが、その雛形として使う_

## 1. 背景

本 directory では以下 3 系統が同時進行し、責務境界が曖昧化した。

- `Rwiki` 本体の仕様駆動開発
- `dual-reviewer` review system の設計・実装
- review system の評価・論文化・evidence 収集

前回の失敗要因は主に実装欠陥ではなく、運用境界の設計不良だった。

- LLM の振る舞いを拘束する prompt / memory / policy の一部が project directory 外にあり、deploy 対象と実行条件が一致しなかった
- data acquisition plan が途中で複数回変動し、run 条件と git 操作が混線した
- 実験系 branch と通常開発 branch の境界が弱く、採取済み data の信頼性を維持できなかった
- 研究用の narrative と runtime contract が同一 repo 内で混ざり、SSoT が不明瞭になった

このため、review system の再構築は既存 directory の延長ではなく、新 directory への切り出しで進める。

## 2. 再構築の目的

新 repo で最初に達成すべき目的は以下である。

- repo を clone しただけで、同一 prompt / policy / schema / protocol で review system を再実行できる状態を作る
- 実装、runtime、evaluation、paper input の責務境界を明示する
- data acquisition を protocol version 単位で固定し、途中変更を run metadata から追跡可能にする
- `cc-sdd` ベースの spec-driven development を維持したまま、research artifact と production artifact を分離する
- review session の記録と内部動作 evidence を用いて、dual-reviewer の精度を継続的に改善できる仕組みを組み込む
- 人が system 全体像を理解できるよう、intent を仕様群より上位の層として明文化し、intent から spec への流れを追跡可能にする

## 3. 新 Repo の基本方針

### 3.1 repository policy

- review system 再構築の主作業は新 repo で行う
- 現 repo は archive / reference / evidence source として保持する
- 旧 repo からは「必要最小限の spec / implementation / test / analysis tool」のみ持ち出す
- 旧 repo の log、途中メモ、達成判定、暫定数値は原則コピーせず reference 扱いとする

### 3.2 reproducibility policy

- prompt / memory / policy / rubric / schema / protocol / validator は原則すべて repo 内に配置する
- repo 外 memory 依存、手元環境依存、暗黙 prompt 依存を禁止する
- 各 run は protocol version、prompt version、target artifact hash、treatment、model config を必須記録する
- 採取済み raw log を後編集しない
- 修正や再集計は派生 artifact として出力し、原 data は immutable に保つ
- review 結果だけでなく、内部判定過程、override、counter-evidence、skip 理由も改善入力として保存する

### 3.3 development policy

- `cc-sdd` を継続する
- intent を spec より上位の入力として管理する
- spec が SSoT、implementation は spec に従属、evaluation は consumer、paper は派生利用とする
- spec phase と experiment phase を混同しない
- self-improvement は ad-hoc な memory 更新ではなく、evidence に基づく spec / prompt / policy 改訂として扱う

### 3.4 intent policy

- intent は「なぜこの system が必要か」「どの failure を再発防止対象とするか」「何を最適化しないか」を記述する
- intent は requirements の代替ではなく、requirements を導く上位文書とする
- 各 spec は対応する intent を参照し、その spec がどの intent を実装するかを明示する
- intent が変更された場合は、影響を受ける spec を再点検する

### 3.5 deployment policy

- deploy 形態を先に固定し、その deploy 前提に合わせて repo 構造と runtime contract を決める
- local-only 実行、他 repo への組込み、CLI 配布のどれを主対象とするかを明示する
- deploy 形態ごとに許容する repo 外依存を明示し、暗黙依存を禁止する

### 3.6 trust-boundary policy

- LLM が決めること、validator が決めること、人間が最終承認することを分離する
- prompt が担う判断と schema / validator が担う検証を混同しない
- 「うまく見える出力」ではなく、「contract を満たした出力」だけを system の成功条件にする

### 3.7 invalidation policy

- data の有効条件と無効条件を protocol で先に定義する
- prompt / protocol / target hash / runtime version の不整合が発生した run は invalid として分離する
- invalid data を paper input や self-improvement input に混ぜない

### 3.8 human-workflow policy

- user がどこでレビューし、どこで承認し、どこで reject するかを system 設計に含める
- LLM の提案単位、user の確認単位、run close の単位を揃える
- 人間にしか判断できないポイントを曖昧に隠さない

## 4. 新 Repo の推奨 directory 構成

以下を最小構成とする。

```text
dual-reviewer-rebuild/
├── README.md
├── CLAUDE.md
├── intent/
│   ├── INTENT.md
│   ├── NON_GOALS.md
│   ├── DESIGN_PRINCIPLES.md
│   └── TRACEABILITY.md
├── operations/
│   ├── DEPLOYMENT_MODEL.md
│   ├── TRUST_BOUNDARY.md
│   ├── HUMAN_WORKFLOW.md
│   └── DATA_INVALIDATION_POLICY.md
├── .kiro/
│   ├── steering/
│   └── specs/
│       ├── dual-reviewer-foundation/
│       ├── dual-reviewer-runtime/
│       ├── dual-reviewer-evaluation/
│       ├── dual-reviewer-paper-interface/
│       └── dual-reviewer-self-improvement/
├── runtime/
│   ├── prompts/
│   ├── policies/
│   ├── schemas/
│   ├── skills/
│   ├── config/
│   └── validators/
├── experiments/
│   ├── protocols/
│   ├── runs/
│   ├── analysis/
│   └── fixtures/
├── learning/
│   ├── findings/
│   ├── proposals/
│   ├── approved-updates/
│   └── rejected-updates/
├── paper/
│   ├── reports/
│   ├── figures/
│   └── tables/
├── scripts/
└── tests/
```

## 5. spec 分割方針

既存 `dual-reviewer-*` をそのまま複製するのではなく、責務に沿って再編する。

全 spec は `intent/` 配下の文書群を上位入力として参照する。

### 5.1 `dual-reviewer-foundation`

責務:

- role 定義
- review state machine の共通定義
- finding / judgment / review_case の schema
- prompt template の配置規約
- terminology と config の基本 contract

旧 repo から主に引き継ぐ source:

- `.kiro/specs/dual-reviewer-foundation/`
- `scripts/dual_reviewer_prototype/framework/`
- `scripts/dual_reviewer_prototype/schemas/`
- `scripts/dual_reviewer_prototype/patterns/`
- `scripts/dual_reviewer_prototype/prompts/judgment_subagent_prompt.txt`

### 5.2 `dual-reviewer-runtime`

責務:

- review 実行系の orchestration
- `dr-init` / `dr-design` / `dr-log` / `dr-judgment` 相当機能
- runtime prompt loading
- policy enforcement
- run-close validation

旧 repo から主に引き継ぐ source:

- `.kiro/specs/dual-reviewer-design-review/`
- `scripts/dual_reviewer_prototype/skills/`
- `scripts/dual_reviewer_prototype/extensions/design_extension.yaml`
- `scripts/dual_reviewer_prototype/prompts/forced_divergence_prompt.txt`

### 5.3 `dual-reviewer-evaluation`

責務:

- treatment 定義
- run protocol
- evidence path convention
- metrics extraction
- figure / table data generation
- validity threat と exclusion rule

旧 repo から主に引き継ぐ source:

- `.kiro/specs/dual-reviewer-dogfeeding/`
- `.kiro/methodology/v4-validation/data-acquisition-plan.md`
- `scripts/dual_reviewer_dogfeeding/`

### 5.4 `dual-reviewer-paper-interface`

責務:

- evaluation outputs を論文化入力へ変換する contract
- figures / tables / report fragments の required fields
- claim mapping
- caveat / limitations の tracking

旧 repo から主に引き継ぐ source:

- `.kiro/methodology/v4-validation/paper-submission-plan.md`
- `.kiro/methodology/v4-validation/preliminary-paper-report.md`
- `.kiro/methodology/v4-validation/evidence-catalog.md`
- `.kiro/methodology/v4-validation/comparison-report.md`

注:

- これは論文そのものを書く spec ではない
- runtime / evaluation の output を paper-ready artifact に変換する interface spec として扱う

### 5.5 `dual-reviewer-self-improvement`

責務:

- review log と internal behavior evidence の収集対象定義
- 改善候補の抽出ルール
- prompt / policy / schema / runtime 変更提案の審査フロー
- 改善採用時の versioning と backtest
- 改善失敗時の rollback 条件

旧 repo から主に引き継ぐ source:

- `docs/dual-reviewer-log-*.md`
- `docs/過剰修正バイアス.md`
- `docs/レビューシステム検討.md`
- `.kiro/methodology/v4-validation/evidence-catalog.md`
- `.kiro/methodology/v4-validation/comparison-report.md`

注:

- self-improvement は「memory を増やすこと」ではない
- evidence に基づいて runtime contract を見直す仕組みとして formalize する

## 6. 持ち出すもの / 持ち出さないもの

### 6.1 持ち出すもの

- `dual-reviewer` 3 spec の requirements / design / tasks
- prototype 実装本体
- schema files
- prompt templates
- tests
- dogfeeding analysis scripts
- data quality / paper planning 文書のうち、作業分解と protocol に関わる部分
- review log から改善パターンを抽出するための一次資料

### 6.2 reference 扱いにするもの

- `docs/dual-reviewer-log-*.md`
- `docs/レビューシステム検討.md`
- `docs/過剰修正バイアス.md`
- `docs/設計レビュー機械式.md`
- `comparison-report.md`
- `preliminary-paper-report.md`
- `evidence-catalog.md`

扱い方:

- 新 repo には全文コピーしない
- 必要箇所のみ要約して再定義する
- 既存数値や readiness 判定は provisional / frozen 扱いにする

### 6.3 持ち出さないもの

- repo 外 memory 前提
- user local transcript を暗黙前提にした運用知識
- 過去 run の達成判定をそのまま流用すること
- `Rwiki` 固有事情に強く依存する path / naming / branch 規律の一部

## 7. 新 Repo で最初に書く SSoT 文書

まず `intent/` 文書群を最上位に置く。

### 7.0 `intent/` 文書群

- `INTENT.md`
- `NON_GOALS.md`
- `DESIGN_PRINCIPLES.md`
- `TRACEABILITY.md`

役割:

- `INTENT.md` は system 開発の意図、背景、解きたい問題、避けたい失敗を書く
- `NON_GOALS.md` は今回あえて最適化しないもの、切るものを書く
- `DESIGN_PRINCIPLES.md` は intent を設計判断へ翻訳する原則を書く
- `TRACEABILITY.md` は intent → spec → runtime / evaluation / paper の対応を追跡する

### 7.0.5 `operations/` 文書群

- `DEPLOYMENT_MODEL.md`
- `TRUST_BOUNDARY.md`
- `HUMAN_WORKFLOW.md`
- `DATA_INVALIDATION_POLICY.md`

役割:

- `DEPLOYMENT_MODEL.md` は system をどこでどう使うか、その deploy 形態を記述する
- `TRUST_BOUNDARY.md` は LLM、validator、人間の責務境界を書く
- `HUMAN_WORKFLOW.md` は user の操作単位、承認単位、review 単位を書く
- `DATA_INVALIDATION_POLICY.md` は run が有効か無効かの判定条件を書く

その上で、以下の SSoT を起こす。

### 7.1 `SYSTEM_BOUNDARY.md`

定義するもの:

- repo の責務
- repo 外依存の禁止範囲
- runtime / experiments / paper の境界
- immutable artifact と mutable artifact の区別

### 7.2 `REPRODUCIBILITY_CONTRACT.md`

定義するもの:

- run 実行に必要な metadata
- prompt / policy / protocol versioning
- raw log の immutable rule
- rerun、reanalysis、repair の区別

### 7.3 `EVIDENCE_PROTOCOL.md`

定義するもの:

- evidence directory layout
- run close 時の append contract
- validation rule
- exclusion criteria
- invalid run の扱い

### 7.4 `PAPER_WORK_BREAKDOWN.md`

定義するもの:

- 旧 `F/Q/P/S/R` を再配置した作業分解
- 研究作業と runtime 作業の依存関係
- claim A/B/C/D と required evidence の対応

### 7.5 `SELF_IMPROVEMENT_LOOP.md`

定義するもの:

- どの evidence を改善入力とみなすか
- 改善候補の分類
- prompt / policy / runtime / schema のどこを変更対象にするか
- 改善提案の採否判定
- backtest と rollback の手順

### 7.6 intent から spec への流れ

新 repo では以下の順に具体化する。

1. `intent/INTENT.md`
2. `intent/NON_GOALS.md`
3. `intent/DESIGN_PRINCIPLES.md`
4. `operations/DEPLOYMENT_MODEL.md`
5. `operations/TRUST_BOUNDARY.md`
6. `operations/HUMAN_WORKFLOW.md`
7. `operations/DATA_INVALIDATION_POLICY.md`
8. `SYSTEM_BOUNDARY.md`
9. `.kiro/specs/*/requirements.md`
10. `.kiro/specs/*/design.md`
11. `.kiro/specs/*/tasks.md`

意味:

- intent が「何を目指すか」を規定する
- non-goals が「何を切るか」を規定する
- design principles が intent を設計判断へ翻訳する
- operations 文書群が deploy / trust / human use / invalidation を固定する
- system boundary が責務と依存境界を固定する
- requirements 以降で初めて feature / contract レベルへ落とす

## 8. 初期 migration の順序

### Step 1

- 新 repo を作成する
- `cc-sdd` 用の `.kiro/steering/` と `.kiro/specs/` 骨格を作る

### Step 2

- `intent/INTENT.md`
- `intent/NON_GOALS.md`
- `intent/DESIGN_PRINCIPLES.md`
- `intent/TRACEABILITY.md`
- `operations/DEPLOYMENT_MODEL.md`
- `operations/TRUST_BOUNDARY.md`
- `operations/HUMAN_WORKFLOW.md`
- `operations/DATA_INVALIDATION_POLICY.md`
- `SYSTEM_BOUNDARY.md`
- `REPRODUCIBILITY_CONTRACT.md`
- `EVIDENCE_PROTOCOL.md`
- `PAPER_WORK_BREAKDOWN.md`
- `SELF_IMPROVEMENT_LOOP.md`

を作成して上位意図と境界を固定する

### Step 3

- `dual-reviewer-foundation` spec を移植し、schema / prompt / config contract を repo 内完結化する

### Step 4

- `dual-reviewer-runtime` spec を移植し、prototype 実装を整理する

### Step 5

- `dual-reviewer-evaluation` spec を移植し、run protocol と metrics pipeline を再定義する

### Step 6

- `dual-reviewer-self-improvement` spec を起こし、review 記録から改善提案を生成する loop を定義する

### Step 7

- 小規模 dry-run を行う
- target 1 件、treatment 1 件、少数 round で log 完全性と validator の動作を確認する

### Step 8

- その後にのみ本格 data acquisition に入る

## 9. 直近の具体アクション

新 repo 着手時に最初の 1-2 日で行う作業は以下を推奨する。

- repo 名を確定する
- `.kiro/specs/` の 5 spec skeleton を作る
- `intent/` の 4 文書初版を書く
- `operations/` の 4 文書初版を書く
- `SYSTEM_BOUNDARY.md` 初版を書く
- `REPRODUCIBILITY_CONTRACT.md` 初版を書く
- `EVIDENCE_PROTOCOL.md` 初版を書く
- `SELF_IMPROVEMENT_LOOP.md` 初版を書く
- 旧 repo から移植対象 file の manifest を作る
- prompt / schema / validator を repo 内へ集約する

## 10. 自己改善 loop の基本要件

self-improvement は runtime の外にある人手メモではなく、repo 内で追跡可能な loop として扱う。

### 10.1 改善入力

- review_case log
- finding 単位の採否結果
- judgment override
- adversarial counter-evidence
- do_not_fix / should_fix / must_fix の分布
- false positive / false negative の事後観測
- user が reject した提案の理由
- implementation phase での downstream rework

### 10.2 改善対象

- prompt wording
- policy / rubric
- severity mapping
- escalation rule
- evidence schema
- runtime orchestration

### 10.3 改善の流れ

- run evidence から anomaly / recurring failure / bias pattern を抽出する
- 改善仮説を `learning/proposals/` に記録する
- proposal ごとに対象 component と期待効果を明記する
- 小規模 backtest または replay で effect を確認する
- 採用されたものだけを spec / prompt / runtime に反映する
- 反映後は version を更新し、どの run から適用したかを追跡可能にする

### 10.4 禁止事項

- 証拠なしの prompt 追加
- repo 外 memory による恒久補正
- 過去 run を上書きして改善効果があったように見せること
- paper narrative の都合で runtime rule を先に変更すること

## 11. intent 文書に最低限含めるべき内容

### 11.1 `INTENT.md`

- なぜ dual-reviewer を再構築するのか
- どの failure を再発防止対象とするのか
- deploy 可能と言える状態をどう定義するのか
- 誰が何のために使うのか

### 11.2 `NON_GOALS.md`

- 今回は扱わない phase / deployment / model diversity
- 研究的に面白くても当面切るもの
- paper の都合で混ぜないもの

### 11.3 `DESIGN_PRINCIPLES.md`

- repo 内完結
- protocol first
- immutable raw evidence
- self-improvement by evidence
- spec-driven change only

### 11.4 `TRACEABILITY.md`

- intent 項目ごとに対応する spec を結ぶ
- spec ごとに対応する runtime artifact を結ぶ
- evaluation と paper input がどの spec / intent に基づくかを結ぶ

### 11.5 `DEPLOYMENT_MODEL.md`

- local-only か、embedded か、CLI 配布か
- 想定 user と利用場面
- deploy 単位と version 配布単位
- repo 外依存を許す範囲

### 11.6 `TRUST_BOUNDARY.md`

- LLM が担う判断
- validator が担う検証
- user が担う最終承認
- 失敗時にどこで停止させるか

### 11.7 `HUMAN_WORKFLOW.md`

- review 開始手順
- finding 提示単位
- approval / reject / defer の操作単位
- run close と sign-off の条件

### 11.8 `DATA_INVALIDATION_POLICY.md`

- invalid run の条件
- mixed-version run の扱い
- target 改変後の run の扱い
- invalid data を残す場所と再利用禁止ルール

## 12. 旧 Repo との関係

現 repo は今後も重要である。

- 失敗履歴の一次資料
- 旧 spec の SSoT
- analysis script の source
- paper narrative の素材

ただし、再構築の実作業場ではない。新 repo 側では現 repo を archive / source reference としてのみ扱う。

## 13. 補足

本計画は「新 repo をどう始めるか」を定義する文書であり、runtime detail や paper schedule の確定版ではない。新 repo 作成後、`cc-sdd` の Requirements フェーズで改めて formalize する。
