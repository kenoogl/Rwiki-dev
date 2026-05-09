# dual-reviewer v1 user guide

## 1. このガイドの役割

この文書は、`dual-reviewer` v1 を
LLM をフロントエンドにした対話型 review system として使う人向けのガイドである。

ここで説明するのは主に次である。

- この system が何をするものか
- ユーザーが会話で何を依頼するのか
- どこで人間が判断し、どこで system が artifact を残すのか

## 2. 最初に知っておくこと

### 2.1 仕様駆動開発とは何か

この repo では、いきなりコードを書くのではなく、
先に仕様を段階的に固めてから実装へ進む。
これをここでは「仕様駆動開発」と呼ぶ。

流れは大まかに次である。

1. 何のために作るのかを決める
2. 何を満たすべきかを決める
3. どう設計するかを決める
4. どの順で実装するかを決める
5. 実装し、review して修正する

`dual-reviewer` は、この流れの中で
特に複雑になりやすい review と修正を助ける system である。

### 2.2 よく出る用語

- `intent`
  - なぜこの system が必要か、何を目的とし、何を目的にしないかを書く最上位文書
- `requirements`
  - system が満たすべき条件を書く文書
- `design`
  - requirements をどういう構造や責務分担で実現するかを書く文書
- `tasks`
  - 実装作業をどう分解し、どういう順で進めるかを書く文書
- `implementation`
  - 実際のコードや artifact を作る段階
- `review`
  - 文書や実装を点検し、問題点や修正点を見つけること
- `finding`
  - review の結果として見つかった指摘事項
- `artifact`
  - repo 内に保存される成果物や記録。文書、schema、log、report などを含む
- `gate`
  - 次の段階へ進んでよいかを確認するチェックポイント

### 2.3 dual-reviewer が主に扱う局面

初見の人は、`dual-reviewer` を「全部自動で書いてくれる system」と考えない方がよい。

主な役割は次である。

- 複雑になった仕様文書を読み、問題点を洗い出す
- 修正がどこまで波及するかを整理する
- review と修正の過程を evidence として残す

## 3. このアプリの目的

`dual-reviewer` v1 は、仕様駆動開発の review を
単なる会話ではなく、再現可能な artifact と workflow で扱うための system である。

そもそもの意図は、仕様駆動開発の下流工程で人間の認知負荷が急増する問題を緩和することにある。
特に次の局面を主対象にする。

- `design`
  - section 間依存、責務境界、state、failure mode が増える
- `tasks`
  - 実装順序、抜け漏れ、検証順、shared ownership が複雑になる
- 一部の `requirements`
  - feature 間の接続や scope drift が濃くなり、上流意図とのズレが見えにくくなる

つまり、この system は「人が detail を読めなくなる前に代わって考えるもの」ではなく、
「人が保持しづらくなった構造、依存、手戻り経路を対話的に補助するもの」である。

利用者の視点では、これは

- spec や review 対象を読ませる
- review を依頼する
- 指摘を受け取る
- 必要なら修正させる
- その過程を evidence として残す

ための対話型 assistant である。

## 4. ユーザーから見た使い方

この system は、基本的にユーザーが LLM に対して
対話的に依頼しながら使う。

典型的な依頼は次である。

- 「この spec を review して」
- 「design と tasks の整合を見て」
- 「open finding を修正して」
- 「修正後に conformance review をやり直して」
- 「今回の review を report にまとめて」

重要なのは、ユーザーが shell command を覚えることではない。
ユーザーは review したい対象、直したい点、欲しい evidence を会話で指定する。

このとき system は、単に文章を要約するのではなく、

- いまどの `spec phase` にいるか
- 何が下流へ波及するか
- どの gate を通すべきか
- どの evidence を残すべきか

を workflow として扱う。

## 5. 対話の基本パターン

### 4.1 review を始めるとき

ユーザーは、何を review したいかを伝える。

例:

- `foundation の shared contract を review して`
- `runtime と evaluation の境界を見て`
- `この branch の prototype を棚卸しして`

system 側は、必要な文書や artifact を読み、
review finding を返し、必要なら repo に review artifact を残す。

### 4.2 修正を依頼するとき

ユーザーは、finding をどう扱うかを伝える。

例:

- `この 3 点を直して`
- `workflow 側を先に補強して`
- `spec 起票からやり直して`

system 側は、workflow rule に従って

- どの phase に戻るか
- どの文書やコードを直すか
- どの gate を再実施するか

を判断して進める。

### 4.3 完了確認をするとき

ユーザーは、何が完了したかを確認する。

例:

- `implementation conformance review は終わったか`
- `v1 は完成したか`
- `evidence は残っているか`

system 側は、`workflow-gate-status`、review artifact、coordination log を見て答える。

## 4.5 workflow はどう動くか

この system の workflow は、何か問題が見つかったときに
LLM と人間の両方へ「次に何をすべきか」をガイドする。

基本動作は次である。

1. 問題を検出する
2. `A/B/C/D` の handback を判定する
3. 戻る phase を決める
4. 正本 artifact を更新する
5. 該当 gate を再実施する
6. 状態と evidence を残す

`A/B/C/D` は次を意味する。

- `A`
  - task-local adjustment
- `B`
  - design handback
- `C`
  - requirements handback
- `D`
  - intent handback

このため、利用者から見ると dual-reviewer は
「review assistant」であると同時に、
「仕様駆動開発の修正手続きを迷わず進めるための workflow guide」でもある。

## 6. ユーザーが期待してよいこと

v1 では、ユーザーは次を期待してよい。

- review の依頼に対して、どの artifact を見たかが分かる
- finding が出た場合、修正前と修正後の evidence が残る
- implementation 完了だけでなく、conformance review の通過有無まで確認できる
- workflow 逸脱が起きた場合、どの phase へ戻るべきかを system がガイドする

## 7. ユーザーが判断すべきこと

この system は対話型だが、最終判断を全部自動化しない。

特に人間が持つべき判断は次である。

- 何を review 対象にするか
- spec phase を approve / reject / defer するか
- runtime-affecting 変更を採用するか
- ambiguous な finding をどう扱うか
- invalid data を先へ流すか止めるか

要するに、LLM は review と実装を助けるが、承認の代行者ではない。

## 8. 対話の裏で何が起きるか

ユーザーからは会話に見えるが、system は裏で artifact を残す。

主な出力先は次である。

- review artifact:
  - `docs/reviews/`
- workflow / coordination:
  - `docs/coordination/`
- run / analysis:
  - `experiments/`
- improvement artifact:
  - `learning/`
- paper-facing artifact:
  - `paper/`

つまり、会話で終わらず、後から追跡できる evidence が repo に残ることが v1 の重要な特徴である。

## 9. 典型的な利用シナリオ

### シナリオ 1: spec を review したい

1. ユーザーが `requirements` や `design` の review を依頼する
2. system が関連 spec と alignment 文書を読む
3. finding を返す
4. 必要なら review artifact を残す
5. ユーザーが修正指示または approve / defer を返す

### シナリオ 1.5: design / tasks で複雑さが増えたとき

1. ユーザーが `design が複雑になってきたので棚卸しして` と依頼する
2. system が関連する requirements、design、alignment memo を横断して読む
3. interface ずれ、ownership conflict、手戻り候補を抽出する
4. 必要なら `B` または `C` handback を示す
5. 修正後、どの gate を再実施すべきかまで返す

このシナリオが、v1 の中心的な使い方である。

### シナリオ 2: 仕様駆動開発の通常フローで使う

1. 人間が `intent` や scope を提示する
2. LLM が requirements / design / tasks の具体化を支援する
3. 各 phase で人間が approve / reject / defer する
4. 下流へ進む前に alignment gate を確認する
5. 実装後に `implementation conformance review` を行う

この流れでは、dual-reviewer は各 phase の代行者ではなく、
複雑性が増す局面で review と修正経路の可視化を行う補助者として機能する。

### シナリオ 3: 実装後の棚卸しをしたい

1. ユーザーが prototype 全体の棚卸しを依頼する
2. system が validator を再実行する
3. `implementation conformance review` を行う
4. finding を記録する
5. 必要なら修正し、short rerun を行う

### シナリオ 4: 完成報告を作りたい

1. ユーザーが `completion report を作って` と依頼する
2. system が workflow status、review artifact、coordination log を読む
3. 完成条件と evidence を report にまとめる

## 10. 仕様駆動開発シナリオにおける dual-reviewer の役割

仕様駆動開発全体の中での役割を一言で言うと、

- 上流では scope と intent のズレを見張る
- 下流では detail 増加による認知負荷を補う
- 修正時には、どこまで戻るべきかを workflow として示す

である。

特に `design` と `tasks` で、

- 「この detail が他 section にどう波及するか」
- 「この修正でどの gate をやり直す必要があるか」
- 「この finding は local fix で済むか、requirements まで戻るべきか」

を会話の中で整理できることが、v1 の価値である。

## 11. v1 の限界

v1 は完成 prototype だが、まだ次の制約がある。

- review 実行はまだ sample / manual workflow 前提である
- fully automated orchestration ではない
- 実運用品質の評価 run はこれから蓄積する段階である
- command-line entrypoint は存在するが、利用者の主 interface としては想定していない

## 12. コマンドは誰のためのものか

repo 内の script は主に次の用途のためにある。

- maintainer が pipeline を mechanical に検証する
- system が内部で sample run や validator を実行する
- artifact 生成 path を固定する

したがって、これらは user guide の中心ではなく、
maintainer 向けの補助手段である。

## 13. maintainer 向け補足

必要なら maintainer は次を直接実行できる。

- `ruby dual-reviewer-rebuild/scripts/validate_foundation_contracts.rb`
- `ruby dual-reviewer-rebuild/scripts/run_review_session.rb`
- `ruby dual-reviewer-rebuild/scripts/export_evidence_bundle.rb`
- `ruby dual-reviewer-rebuild/scripts/validate_evaluation_pipeline.rb`
- `ruby dual-reviewer-rebuild/scripts/validate_self_improvement_pipeline.rb`
- `ruby dual-reviewer-rebuild/scripts/validate_paper_interface_pipeline.rb`
- `ruby dual-reviewer-rebuild/scripts/validate_implementation_governance_artifacts.rb`

ただし、これらは user-facing の主操作ではなく、
対話型 workflow を支える backend / validation entrypoint とみなすのが正しい。

## 14. 最初に読むべき文書

1. [README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/README.md:1)
2. [INTENT.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/INTENT.md:1)
3. [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:1)
4. [TRUST_BOUNDARY.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/TRUST_BOUNDARY.md:1)
5. [dual-reviewer-v1-completion-report.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reports/dual-reviewer-v1-completion-report.md:1)
6. [workflow-gate-status.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md:1)

## 15. ひとことで言うと

`dual-reviewer` v1 は、
「LLM と対話しながら review と修正を進め、その過程を repo 内の evidence として残すための system」
である。
