# INTENT

## 1. この文書の役割

この文書は、`dual-reviewer-rebuild` がなぜ必要かを人間が理解するための最上位文書である。

ここでは feature 要件や実装方式ではなく、以下を明文化する。

- なぜ再構築するのか
- 何を失敗とみなすのか
- 何を成立させたいのか
- その意図がどの spec に流れていくのか

`requirements.md` は「何を作るか」を定義するが、その前に本書は「なぜそういう system が必要か」を定義する。

## 2. 背景

### 2.1 v1 取得処理の汚染発見（現在の背景）

dual-reviewer の v1 取得処理は、規則ファイル照合と固定 prompt の組み合わせとして実装されていた。運用中の検証で、次の 5 層の事前設定が観測結果を縛っていることが判明した。

1. 主役・敵対役・判断役のプロンプトに具体トピックが書き込まれていた。
2. ヒューリスティック規則ファイルの方針が「主役 1〜2 件、敵対役 0〜1 件」と件数を上限固定していた。
3. 各ケースの規則ファイルが共通の三つ組語彙を持っていた。
4. Ruby ランタイム層が規則ファイルを決定論的に照合して発見を生成していた。
5. 論文計画書に観測結果が先取りで書かれていた。

その結果、3 領域・3 言語・改修反復にわたって「単独 2 件・二重 3 件・二重+判断 3 件」という偽の規則性が観測された。これは LLM レビューの本質的な性質ではなく、規則設計の帰結である。

v1 の取得結果は archive に分離済みであり、v2 では実 LLM 呼び出しに置き換えた取得処理で真の値を観測する。

### 2.2 旧 repo からの再構築（歴史的経緯）

`dual-reviewer` は旧 repo（review runtime、評価スクリプト、比較実験、論文化準備、失敗履歴）を起点に再構築された。旧実装は「動く prototype」としての価値はあったが、prompt や policy の repo 外散在、データ取得計画の揺れ、責務境界の崩れ、意図層の弱さなど、system 境界と運用境界の設計に課題があった。本 system は、これを移植ではなく再現性・可観測性・自己改善性を持つ runtime として作り直すことを目的とする。

加えて、本再構築は `dual-reviewer` の最初の適用対象でもある。すなわち本 repo では、review system を作るだけでなく、意図駆動開発の `intent`、`requirements`、`design`、`tasks` を対象に、その方法論を手動で適用しながら system を育てる。

## 3. 再構築が解くべき中心問題

### 3.1 再現可能性の欠如

旧 repo の system では、repo 外 memory や operator の暗黙知に依存する部分があった。この状態では、ある run がなぜその出力になったのかを第三者が再現できない。再構築では、clone 直後に同一 prompt / policy / schema / protocol で同じ review runtime を起動できることを最低条件にする。

### 3.2 実験条件の drift

review system は評価しながら進化させる必要があるが、進化の途中で protocol が曖昧に変わると、採取済み data の意味が崩れる。再構築では、run ごとに protocol version、prompt version、runtime version、target artifact hash を固定し、条件の異なる run が混ざらないようにする。

### 3.3 runtime と evaluation の混線

旧 repo の system では、runtime 改善、比較評価、論文化準備が近接しすぎていた。研究上は便利でも、system としては危険である。再構築では、runtime、evaluation、paper input を分離し、paper の都合で runtime rule を先に変えない構造にする。

### 3.4 自己改善の非形式性

review system の精度を上げるには、review 記録と内部挙動 evidence を継続的に分析し、改善を反映する必要がある。しかし改善が ad-hoc な memory 追加や operator の運用改善に留まると、system として進歩が蓄積しない。再構築では、自己改善を formal な proposal -> backtest -> approve/reject -> version update の loop にする。

### 3.5 全体像の不可視性

旧 repo には大量の spec、log、draft、script が存在するが、それらの背後にある「なぜこう設計されたのか」が分散していた。再構築では、intent を spec より上位に置き、人が system を理解するための入口を作る。

### 3.6 取得処理の事前設定への退行

LLM レビューを謳う system が、実際には規則ファイル照合や固定 prompt の単純写像になっていると、件数構成や論点が観測前に決まり、レビュー方式の差を測ることができなくなる。再構築では、取得処理が実 LLM 呼び出しに基づくこと、prompt や規則ファイルなどの事前設定が観測結果を縛らないことを最低条件にする。

## 4. この system が目指す状態

再構築後の `dual-reviewer` は、単なる研究用スクリプト群ではなく、次の性質を持つ system を目指す。

また、この system は単なる汎用 review assistant ではない。主たる対象は意図駆動開発における複雑性の増大であり、特に人間の認知負荷が急増する phase を補うことに価値がある。

### 4.1 deploy 可能である

ここでいう deploy 可能とは、少なくとも local repository 上で、repo 内 artifact だけを用いて review runtime を起動できることを意味する。operator の手元事情や hidden memory に依存しないことが条件である。

### 4.2 再現可能である

各 run について、使用した protocol、prompt、runtime version、target hash、treatment、operator sign-off が追跡できることを意味する。出力の良し悪し以前に、run 条件が追えなければ evidence として採用しない。

### 4.3 可観測である

最終 finding だけでなく、counter-evidence、override、skip 理由、invalidity marker まで記録されることを意味する。後から「なぜその判断になったのか」を辿れない system は改善できない。

### 4.4 改善可能である

精度改善が人の勘ではなく evidence に基づいて行われることを意味する。改善の単位は prompt 変更、policy 変更、schema 変更、runtime 変更として明示され、どの evidence を根拠に採用したかが追跡できる必要がある。

### 4.5 人が理解可能である

新しい maintainer や利用者が、intent、境界、workflow、spec の関係を追えることを意味する。system の利用と改善が、一部の operator の経験則に閉じないことが重要である。

### 4.6 phase ごとの複雑性増大に対応できる

人間は `intent` や `requirements` の段階では、まだ全体像を比較的保持しやすい。しかし `design` や `tasks` に進むと、

- detail の増加
- section 間依存の増加
- 責務境界の細分化
- failure mode の増加
- 実装波及の複雑化

によって、単独 review では見落としや過剰修正が生じやすくなる。

`dual-reviewer` は、この複雑性増大局面で人間の認知を補う review system である。特に `design` と `tasks` を高価値 phase とみなす。

初期段階では、この価値仮説をまず本 repo 自身に対して検証する。つまり `dual-reviewer` は外部 project に適用される前に、この再構築の spec 群に対して手動運用される dogfooding 対象となる。

### 4.7 取得処理が事前設定の写像にならない

review の取得処理は、規則ファイル照合や固定 prompt の単純写像ではなく、実 LLM の判断に基づいて発見と判断を生成する。prompt、policy、規則ファイルなどの事前設定は、取得対象や入力範囲の固定には使ってよいが、観測結果（発見の件数、内容、構造）を縛ってはならない。

## 5. 想定利用者

この system は、少なくとも初期段階では以下の利用者を想定する。

- review runtime を開発・保守する maintainer
- review session を実行し、承認や reject を行う operator
- evidence を分析して比較評価や改善提案を行う evaluator
- 論文化や外部共有のために paper-facing artifact を整備する author

同一人物が複数の役割を兼ねてもよいが、system 上の責務は分けて扱う。特に、

- LLM が出力すること
- validator が検証すること
- human が承認すること

は明示的に分離する。

## 6. 主対象 phase

この system は将来的には `intent`、`requirements`、`design`、`tasks` を review 対象に含めうる。ただし初期再構築において、特に価値が高いのは `design` と `tasks` である。

### 6.1 `intent`

- 方向づけの層
- 人間がまだ全体像を保持しやすい
- review 対象に含める価値はあるが、主戦場ではない

### 6.2 `requirements`

- intent と feature contract の接続層
- scope drift や non-goal 侵食の検出には重要
- ここも比較的人間が追いやすい

### 6.3 `design`

- 主要な高価値 phase
- cross-spec consistency、責務境界、state transition、failure mode が密になり、人間の認知限界に近づく

### 6.4 `tasks`

- 主要な高価値 phase
- 網羅性、順序依存、抜け漏れ、検証可能性の問題が顕在化しやすい

したがって初期再構築では、`design` / `tasks` を中心に価値を証明しつつ、`intent` / `requirements` にも拡張可能な構造を保つ。

ただしここで注意すべきなのは、system の有効性指標が review phase/profile ごとに同じとは限らないことだ。現時点の metric 骨格は `design` を中心に考えた経緯を持つが、`intent`、`requirements`、`design`、`tasks`、将来の `implementation-oriented review` では「何をもって有効とみなすか」が変わりうる。

したがって再構築では、

- 共通比較に使う core metrics
- review phase/profile ごとに異なる phase-specific effectiveness metrics

を分けて扱う必要がある。

この原則そのものは本書で持ち、具体的な overlay metric の初版、derived artifact への表現、comparison contract への反映は `dual-reviewer-evaluation` spec を正本とする。

## 7. 何を信頼し、何を信頼しないか

この system は、LLM の自然言語出力そのものを無条件には信頼しない。信頼の単位は以下である。

### 6.1 信頼するもの

- version が記録された repo 内 artifact
- schema に適合した structured evidence
- protocol 一貫性を満たした run metadata
- explicit な human approval / reject / defer
- invalidation policy に従って有効と判定された data

### 6.2 信頼しないもの

- repo 外 memory に依存した恒久補正
- prompt version 不明の挙動
- 条件が揺れた run の集計結果
- paper narrative の都合で後付け整理された runtime 判断
- operator の暗黙知だけで再現されるルール

## 8. 何を失敗とみなすか

再構築では、単に model が miss したことだけを失敗とみなさない。system failure とみなすのは主に以下である。

- 同じ repo から同じ条件で run を再現できない
- run validity を機械的に判定できない
- invalid data が valid data と混在する
- review 判断の根拠が追跡できない
- 改善提案が evidence ではなく運用の勘で採用される
- paper 作業が runtime contract を汚染する
- 人が system 全体像を説明できない
- `design` / `tasks` の複雑性増大局面で、review system が認知補完装置として機能しない

## 9. 何を今回は最適化しないか

この初期再構築では、すぐに大規模・多プロジェクト・多言語・外部共有の最適化を目指さない。まず local repository で信頼できる runtime を成立させる。

したがって、以下は後段に回す。

- public contribution intake
- GitHub PR ベースの外部データ収集
- multi-vendor federation
- packaged CLI distribution
- hosted service 化

これらは将来重要だが、今は foundation を不安定にする要素として扱う。

## 10. 意図から spec への流れ

本書の意図は、そのまま feature spec に落ちるわけではない。以下の段階を経る。

### 9.1 intent 文書群

- `INTENT.md`
- `NON_GOALS.md`
- `DESIGN_PRINCIPLES.md`
- `TRACEABILITY.md`

ここで「なぜ作るか」「何を切るか」「どんな設計原則を持つか」を固定する。

### 9.2 operations 文書群

- `DEPLOYMENT_MODEL.md`
- `TRUST_BOUNDARY.md`
- `HUMAN_WORKFLOW.md`
- `DATA_INVALIDATION_POLICY.md`

ここで「どこで使うか」「何を信頼するか」「人はどう関与するか」「いつ data を無効とみなすか」を固定する。

### 9.3 feature spec 群

- `dual-reviewer-foundation`
- `dual-reviewer-runtime`
- `dual-reviewer-evaluation`
- `dual-reviewer-paper-interface`
- `dual-reviewer-self-improvement`

ここで初めて「何を実装するか」「どの contract を持つか」を requirements/design/tasks に落とす。

## 11. 各 spec に期待する役割

### 10.1 foundation

repo-contained で validator-aware な共通 contract を定義する。再構築の最低層であり、schema、prompt placement、role abstraction、metadata contract を担う。

### 10.2 runtime

foundation の contract 上で実際の review orchestration を提供する。ここで LLM の振る舞いが動くが、その自由度は foundation と operations によって制約される。また phase ごとに異なる review emphasis を扱える必要がある。

### 10.3 evaluation

run の quality を測り、比較可能な metrics を生成する。ただし runtime rule を決める権限は持たない。特に `design` / `tasks` における認知補完効果を観測可能にする必要がある。

### 10.4 self-improvement

review 記録と内部挙動 evidence から改善 proposal を生成し、backtest と approval flow を通して runtime を改善する。

### 10.5 paper-interface

runtime と evaluation が生成した artifact を、論文化や外部説明に使える形へ変換する。ただし paper の都合で runtime contract を変更しない。

## 12.5 本 repo への手動適用

初期再構築では、`dual-reviewer` の方法論をまず本 repo 自身へ手動適用する。

意味:

- `intent` / `requirements` / `design` / `tasks` を review phase/profile の対象とみなす
- 初期の review は runtime の完全自動運用ではなく、人間が手動で方法論を適用する
- その過程で得られる failure、見落とし、改善点を system requirement と self-improvement の入力に戻す

これは本 repo が単なる実装対象ではなく、方法論の最初の検証場でもあることを意味する。

この manual dogfooding review を、通常の文書編集や ad-hoc な推敲と混同してはならない。初期段階で valid な manual review とみなす最低条件は次とする。

- review session ごとの manifest がある
- finding が structured record として残る
- summary に sign-off / reopen / downstream recheck が残る
- review basis と review question set が明示される
- review mode が `manual-dual-reviewer-inspired` として区別される

つまり、manual review であっても evidence として使うには、単なる編集履歴ではなく session 単位の正本記録が必要である。

また、manual dogfooding は恒久運用形ではなく Phase 1 の検証モードである。後続では、runtime-mediated review session が成立した段階で、manual review evidence と runtime-mediated evidence を区別して扱う必要がある。

handoff の意図は次の通りである。

- manual dogfooding
  - 方法論と記録フォーマットの初期検証
- runtime-mediated review
  - review runtime 自体の動作と reproducibility を伴う evidence production

この切替条件の詳細は workflow / evaluation contract 側で定義するが、本書では「manual evidence と runtime-mediated evidence を混在させない」ことを意図として固定する。

## 13. 将来像

最初の目標は local-only で信頼できる review runtime だが、その先には cross-project learning がある。理想的には、多様な言語、多様な target、多様な review case の data が集まり、self-improvement の精度が上がる状態を目指す。

ただし、それは foundation が安定した後の話である。外部 data の intake や GitHub PR ベースの evidence contribution は、Phase 2 以降の拡張として扱う。

## 14. この文書の完成条件

`INTENT.md` は一度書いて終わりではないが、少なくとも以下を満たしている間は有効とみなす。

- maintainer が再構築の理由をこの文書だけで説明できる
- major design decision をこの文書の意図に照らして説明できる
- 各 spec がどの intent を実装しているか追跡できる

この条件を満たせなくなったときは、spec の改訂だけでなく intent の改訂が必要である。
