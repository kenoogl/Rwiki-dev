# DESIGN_PRINCIPLES

## 1. この文書の役割

この文書は、`INTENT.md` に書かれた意図を、設計判断へ翻訳するための原則を定義する。

`INTENT.md` は「なぜ」を説明し、`requirements.md` は「何を作るか」を説明する。その中間で、本書は「その意図をどんな判断原則で system に落とすか」を説明する。

再構築では、個々の設計判断が局所最適に流れないように、上位原則を明示しておく必要がある。

artifact naming、status の正本、`phase` 用語の使い分けは [CONVENTIONS.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/CONVENTIONS.md) を前提にする。

## 2. 原則 1: Repo-Contained Runtime

runtime の信頼性に関わる artifact は、原則として repo 内に置く。

対象:

- prompts
- policies
- schemas
- validators
- config templates
- terminology templates
- pattern assets

理由:

- repo 外依存は再現不能性を生む
- deploy 条件と実行条件の不一致が前回の失敗要因だった

設計上の含意:

- runtime-critical behavior を repo 外 memory に逃がさない
- environment variable や local config を使う場合も、明示的 config と metadata 記録を要する

## 3. 原則 2: Protocol First

data collection や評価を始める前に、run contract を定義する。

理由:

- protocol が揺れたまま data を集めると、後から比較不能になる
- self-improvement の入力にも paper の入力にもならない

設計上の含意:

- prompt version
- protocol version
- runtime version
- target artifact hash
- treatment
- operator sign-off

を run metadata の必須項目として扱う。

## 4. 原則 3: Immutable Raw Evidence

raw evidence は収集後に書き換えない。

理由:

- 後修正された raw data は trust を損なう
- invalidation や repair の履歴が消える

設計上の含意:

- raw run output と derived analysis を分離する
- repair、reanalysis、retrofit は別 artifact として保存する
- invalid run であっても削除ではなく invalid marker で扱う

## 5. 原則 4: Trust Boundary Separation

LLM、validator、人間の責務を混同しない。

LLM が担うもの:

- finding 生成
- counter-evidence 生成
- necessity judgment 候補生成

validator が担うもの:

- schema 適合性
- metadata 完備性
- protocol 一貫性
- invalidation 判定の機械部分

人間が担うもの:

- approve / reject / defer
- runtime-affecting change の採否
- ambiguous case の最終判断

理由:

- うまく見える出力を system success と誤認しないため
- 責任境界を曖昧にすると改善不能になるため

## 6. 原則 5: Evidence-Driven Change

system を変える理由は、原則として evidence でなければならない。

evidence とみなすもの:

- review logs
- override patterns
- false positive / false negative 観測
- downstream rework
- repeated invalidation causes

evidence とみなさないもの:

- operator の勘
- 1 回限りの印象
- paper の narrative 上の都合

設計上の含意:

- self-improvement は proposal artifact を経由する
- prompt / policy / runtime / schema の変更理由は追跡可能でなければならない

## 7. 原則 6: Human-Visible Intent

人が system の全体像を辿れることを設計条件にする。

理由:

- review runtime は複雑であり、暗黙設計では維持できない
- 新規 maintainer が意図を追えない system は改善も監査もできない

設計上の含意:

- `intent/` 文書群を最上位に置く
- `TRACEABILITY.md` で intent -> spec -> runtime/evaluation/paper を結ぶ
- major decision を intent に照らして説明できる状態を維持する

## 8. 原則 7: Human Cognition Limit Aware Review

この system は、人間が保持しきれない複雑性を補うために設計する。

理由:

- `intent` や `requirements` はまだ人間が比較的追いやすい
- `design` と `tasks` では detail と依存関係が増え、単独 review の見落としが増える

設計上の含意:

- phase ごとに review emphasis を変えられるようにする
- `design` では構造的一貫性、責務境界、failure mode を重視する
- `tasks` では網羅性、順序依存、検証可能性を重視する
- runtime と evaluation は phase-aware でなければならない

## 9. 原則 8: Boundary Before Convenience

使いやすさよりも先に、責務境界を固める。

理由:

- 便利さを先に最適化すると、また repo 外依存や hidden shortcut が入る
- distribution UX を先行させると foundation がぶれる

設計上の含意:

- packaged CLI や hosted service は後段
- local repository での再現性を最初の acceptance gate にする

## 10. 原則 9: Narrow First, Generalize Later

最初から広い一般化を狙わない。

理由:

- 広すぎる抽象化は contract を空洞化する
- 現在の use case に対して信頼できる runtime を先に作る方が価値が高い

設計上の含意:

- 抽象 role 名は使う
- しかし deploy target、評価対象、運用条件は狭く固定する
- 将来の多言語、多 target、多 vendor は extension point として残す

## 11. 原則 10: Runtime, Evaluation, Paper の分離

runtime、evaluation、paper-facing output は分ける。

理由:

- 論文化の都合で runtime rule が変わると system trust が崩れる
- runtime の未熟さを paper narrative で埋めるべきではない

設計上の含意:

- runtime は review を動かす
- evaluation はその quality を測る
- paper-interface は結果を伝達用に変換する
- 逆方向の依存を作らない

## 12. 原則 11: Invalidation Is First-Class

invalid run を例外扱いせず、system の一次概念として扱う。

理由:

- 失敗した run を曖昧に保持すると後で混ざる
- invalid data を除外できない system は学習も評価も壊れる

設計上の含意:

- invalidation policy を上位文書として独立させる
- validator failure は明示的に記録する
- invalid run は保存するが、valid data とは別に扱う

## 13. 原則 12: Improvement Without Hidden Memory

精度改善は repo 外 memory の蓄積ではなく、repo 内 artifact の改善として行う。

理由:

- hidden memory は再現できない
- 改善が operator 個人に閉じる

設計上の含意:

- memory 的知見も最終的には prompt / policy / schema / spec に還元する
- steady-state behavior は repo 内 artifact で説明できるようにする

## 14. 原則 13: Future Learning Network Is Optional, Not Foundational

外部 contributor data や GitHub PR ベースの evidence collection は重要だが foundation ではない。

理由:

- foundation が弱いまま外部 data を集めてもノイズしか増えない
- trust tier、compatibility、anonymization の問題が別途必要になる

設計上の含意:

- 初期再構築では local-only を前提にする
- 外部 data collection は Phase 2 以降の拡張として設計余地だけ残す

## 15. 原則 14: General / Meta / Project-Specific Separation

review system の構造と知識は、general layer、meta layer、project-specific layer に分けて扱う。

意味:

- general layer
  - project 横断で共有される review 構造
- meta layer
  - project 横断で再利用可能なメタパターン
- project-specific layer
  - 特定 project のログ、用語、failure history、pattern concrete

理由:

- 一般化可能な review 構造と project 固有知識を混ぜると移植性が落ちる
- project 固有知識を evidence から抽出して蓄積できるようにすると、再構築後の learning loop が資産になる

設計上の含意:

- foundation は general layer を担う
- pattern assets は meta layer と project-specific layer を区別して持つ
- project 固有知識は repo 内 evidence から抽出して artifact 化する
- self-improvement は project 固有 signal を meta pattern 候補へ抽象化できる構造を持つ

## 16. 原則間の優先順位

原則が衝突した場合、基本的に以下を優先する。

1. Repo-contained runtime
2. Protocol first
3. Immutable raw evidence
4. Trust boundary separation
5. Human cognition limit aware review
6. Evidence-driven change
7. Runtime / evaluation / paper separation
8. Convenience and expansion

例:

- 便利でも repo 外 memory を使わない
- 論文化に便利でも invalid data を混ぜない
- 共有しやすくても protocol version 不明の data を受け付けない

## 17. この文書が spec に与える影響

### foundation

- schema、prompt、config、pattern を repo-contained にする
- validator-oriented metadata を要求する

### runtime

- hidden operator memory に依存しない orchestration を設計する
- review output と approval unit を対応させる
- phase-aware review profile を扱えるようにする

### evaluation

- invalidation-aware な metrics pipeline を作る
- valid run と invalid run を混ぜない
- `design` / `tasks` の認知補完効果を測れる余地を残す

### self-improvement

- proposal -> backtest -> approval -> versioning の loop を formalize する
- 感覚的改善を禁止する

### paper-interface

- runtime に逆流しない output 変換契約にする
- paper convenience を runtime rule より下位に置く

## 17. この文書の完成条件

本書は、少なくとも以下を満たすときに有効な設計原則文書とみなす。

- major design decision を本書の原則に照らして説明できる
- spec 間の衝突を本書の優先順位で調停できる
- maintainer が「なぜその設計を採ったか」を本書から説明できる
