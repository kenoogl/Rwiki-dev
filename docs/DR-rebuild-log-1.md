# dual-reviewer-rebuild 1



```
このディレクトリは元々はRwiki（LLMwiki）の開発からスタートした。途中Rwikiの開発のためにレビューシステムの構築を始めた。つまり、2システムの開発がｋのディレクトリで行われている。加えて、レビューシステムの評価も同時に行っている。このため、複雑度があがり、全体を把握することが難しくなっている。さらに、開発途中のレビューシステムのLLM（Claude)の制御がうまくできずに採取したデータの信頼性が失われた経緯がある。そこで、レビューシステムの再構築を行うが、レビューシステムのデプロイ、仕様再検討、レビュー精度のエビデンスデータの蓄積・分析、レビューのターゲット選定などをやり直す。幸いにも、このディレクトリには失敗した履歴が残っている。また、仕様としてはたたき台となるものはある。そこで、君の役割は優秀なソフトウェアエンジニアとして、レビューシステムの再構築を行うことである。まず、全体を把握し、計画を立案セよ。
```

全体を確認した。結論から言うと、このディレクトリは「壊れた実装」より「目的の異なる3系統が強く結合した状態」になっている。

`Rwiki` 本体は v2 リライト中で、主系は [README.md](/Users/Daily/Development/Rwiki-dev/README.md) と [`.kiro/specs/`](</Users/Daily/Development/Rwiki-dev/.kiro/specs>)。レビューシステムは `scripts/dual_reviewer_prototype/` に基盤実装、`scripts/dual_reviewer_dogfeeding/` に評価・分析スクリプト、仕様の正本は [`.kiro/specs/dual-reviewer-foundation/requirements.md`](</Users/Daily/Development/Rwiki-dev/.kiro/specs/dual-reviewer-foundation/requirements.md>)、 [`.kiro/specs/dual-reviewer-design-review/requirements.md`](</Users/Daily/Development/Rwiki-dev/.kiro/specs/dual-reviewer-design-review/requirements.md>)、 [`.kiro/specs/dual-reviewer-dogfeeding/requirements.md`](</Users/Daily/Development/Rwiki-dev/.kiro/specs/dual-reviewer-dogfeeding/requirements.md>) にある。失敗履歴と評価計画は [docs/dual-reviewer-log-10.md](/Users/Daily/Development/Rwiki-dev/docs/dual-reviewer-log-10.md)、 [`.kiro/methodology/v4-validation/data-acquisition-plan.md`](</Users/Daily/Development/Rwiki-dev/.kiro/methodology/v4-validation/data-acquisition-plan.md>)、 [`.kiro/methodology/v4-validation/evidence-catalog.md`](</Users/Daily/Development/Rwiki-dev/.kiro/methodology/v4-validation/evidence-catalog.md>) に濃く残っている。

重要なのは、現行コードは最低限動いていることだ。`scripts/dual_reviewer_prototype/tests` は `113 passed`、`scripts/dual_reviewer_dogfeeding/tests` は `50 passed` だった。したがって再構築対象は主に「LLM 制御」「実験プロトコル」「データ信頼性」「責務分離」であり、全面書き直しではなく、資産を再配置して信頼できる運用線を引き直す仕事になる。

現状の問題は4点に整理できる。  
1. `Rwiki` 開発、レビュー基盤開発、レビュー評価研究が同一 repo で混線している。  
2. 仕様、実装、実験ログ、論文化準備が `.kiro/`、`docs/`、`scripts/` に分散し、SSoT が見えにくい。  
3. 失敗原因は主に LLM の制御不全と運用プロトコルの不安定さで、データの再現性・信頼性を損ねた。  
4. 評価は進んでいるが、研究用データ取得計画と実運用デプロイ計画が分離されていない。

再構築計画は次の順で進めるのが妥当だ。

**Phase 1: 棚卸しと境界の再定義**  
`Rwiki` 本体、レビュー基盤、評価資産、失敗ログを台帳化する。  
成果物:
- レビュー再構築用の資産台帳
- 「何を流用し、何を凍結し、何を廃棄するか」の判定表
- SSoT 一覧

**Phase 2: 仕様の再固定**  
現行 `dual-reviewer` 3 spec をたたき台にして、今回は research-first ではなく operation-first に並べ替える。  
優先して固定するもの:
- レビュー対象
- セッション単位の入出力契約
- LLM 役割分離
- ログ schema
- 判定基準
- デプロイ境界

**Phase 3: 信頼できるデータ取得プロトコルの再設計**  
過去の dogfeeding は参考資料として扱い、再利用できるのは schema・スクリプト・失敗モードだけに限定する。  
ここで新しい「再実験プロトコル」を定義する:
- 実験前状態固定
- commit/hash 固定
- prompt/version 固定
- treatment 定義固定
- 中断・逸脱時の無効化条件
- evidence 出力の保存先固定

**Phase 4: 実装とデプロイの再編**  
`prototype` と `dogfeeding` を「運用系」と「研究系」に分けて再配置する。  
狙い:
- レビュー実行パス
- ログ収集パス
- 分析パス
- Rwiki 本体への依存  
を明示化する。

**Phase 5: 小規模再実験で検証**  
いきなり 30 session を回さず、まず 1 target、少数 round、単一 treatment から再開する。  
そこで再現性、ログ完全性、LLM 制御性を確認してから比較実験に戻す。

次の具体作業としては、私がこの repo 内に「レビュー再構築のための現状整理文書」を作り、  
- 資産台帳  
- 問題構造  
- 再構築方針  
- 実行ロードマップ  
を 1 つの SSoT にまとめるのがよい。そこから仕様改訂と実装再編に入れる。

補足として、未コミット変更は `.claude/settings.local.json` と [docs/dual-reviewer-log-10.md](/Users/Daily/Development/Rwiki-dev/docs/dual-reviewer-log-10.md) にあるので、以後の作業では触らずに進める。次に進めるなら、まずこの現状整理文書を repo 内に作成する。



```
このディレクトリで継続するのか、新たにディレクトリを作成してクリーンに進める方がよいのではないか
```

新規ディレクトリで進める方がよい。少なくとも「レビューシステム再構築の主作業」は切り出すべきだ。

理由は単純で、この repo には 3 種類の関心事が同居している。  
- `Rwiki` 本体の仕様と実装  
- 旧レビューシステムのプロトタイプ  
- 失敗を含む評価・論文化用データ

この状態のまま続けると、過去資産を参照しやすい反面、再構築対象と参考資料の境界がまた曖昧になる。今回の問題はまさにそこにある。特に「失敗した運用の癖」「古い prompt」「途中の判断」が新実装に混入しやすい。

ただし、完全に捨てて新規開始は悪い。過去 repo は evidence archive として価値が高い。なので推奨は二択ではなく、次の分離だ。

1. 現ディレクトリは `archive / reference / evidence source` として保持する。  
2. 新ディレクトリにレビューシステム再構築用の clean repo を作る。  
3. 新 repo には必要最小限だけ移植する。  
移植候補は `dual_reviewer_prototype` の実装、schema、テスト、dogfeeding の分析スクリプト、仕様の確定版。  
4. ログ、論文化メモ、古い失敗履歴は原則コピーせず、参照リンクで扱う。

実務的には、こう分けるのがよい。  
- 旧 repo: `Rwiki-dev` のまま保全  
- 新 repo: 例えば `dual-reviewer-rebuild` または `review-system-rebuild`  
- 新 repo の最初の責務: 仕様固定、実行パス固定、ログ schema 固定、最小デプロイ、最小再実験

例外として、このディレクトリ内で続けてもよいのは「まず 1-2 日で棚卸し文書だけ作る」場合だけだ。その後は切り出した方がいい。再構築までこの場で続けるのは勧めない。

次にやるべきことは、新ディレクトリ移行の設計を先に決めることだ。必要なら次のターンで、`何を持ち出すか / 持ち出さないか / 新 repo の初期構成` を具体化する。



```
方針は了解。前回の失敗の一つは、デプロイし、どのように利用されるかを余り想定していなかったために、LLMの振る舞いを方向付けるプロンプトやメモリをプロジェクトディレクトリ外においてしまったこと、データ取得計画が途中何度も変わり、それが引き金となってリポジトリ操作を誤り、採取したデータの信頼性が失われたこと、LLMの操作が信頼できない挙動となったことが主な原因である。
```

原因整理は妥当で、再構築ではその3点を最初に潰すべきだ。

今回の失敗は、実装不良というより運用境界の設計不良だった。具体的には、
- LLM 制御資産が repo 外にあり、デプロイ対象と実行条件が一致していなかった
- データ取得計画が途中で変動し、実験系と通常開発系の git 操作が混線した
- LLM の行動規律が「その場の運用」に依存し、再現可能なシステム契約になっていなかった

なので新 repo では、最初に次の原則を固定するべきだ。

1. LLM の挙動を方向付ける資産は原則すべて repo 内に置く  
`prompt`、`policy`、`memory`、`rubric`、`session contract`、`log schema` を同梱し、外部依存を禁止する。少なくとも「その repo を clone すれば同じ条件で動く」状態にする。

2. 実験計画は途中変更可能でも、変更履歴が実験データと分離不能にならないようにする  
`protocol/v1` のように版管理し、各 run は「どの protocol version で採取したか」を必ず記録する。途中変更は上書きではなく新 version として扱う。

3. git 運用を開発系と評価系で分ける  
通常実装ブランチと、データ採取専用ブランチ、できれば結果保全用ディレクトリを分ける。採取済み run に後から手を入れない。再集計は別成果物として出す。

4. LLM を信用せず、LLM の出力契約だけを信用する  
自由文を信じるのではなく、
- 必須入力
- 必須出力
- 禁止操作
- 異常時の扱い
- run metadata  
を機械検証できる形にする。LLM の「良さそうな振る舞い」は evidence にしない。

5. デプロイ形態を先に決める  
ローカル運用か、CLI 配布か、他 repo への組込みかで構成は変わる。ここを曖昧にしたまま作ると、また repo 外メモリや手元依存が入り込む。

再構築の最初の成果物はコードではなく、次の3文書にすべきだ。
- `SYSTEM_BOUNDARY.md`
- `EXPERIMENT_PROTOCOL.md`
- `REPRODUCIBILITY_CONTRACT.md`

この3つで、
- 何が repo 内の正本か
- 何が run の固定条件か
- 何をもって有効データとみなすか  
を先に固定する。その後に実装へ入るべきだ。

次は、新 repo の初期ディレクトリ構成と、`repo 内に置くべき LLM 制御資産の一覧` を具体化するのが自然だ。



```
その前にインプットしておくべき情報として、.kiro/methodology/v4-validation/paper-submission-plan.mdに考えている論文化の計画がある。スケジュールは引き直すとして、やるべきことのひな形がある。同じディレクトリに想定するpreliminary-papaer-report.mdがある
```

この2文書は、再構築前に必ず取り込むべき情報だ。ただし、そのまま新プロジェクトの計画書にするのではなく、「使う部分」と「凍結する部分」を分けて扱うべきだ。

[paper-submission-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/v4-validation/paper-submission-plan.md) から取るべきものは、研究作業の分解だ。特に `F/Q/P/S/R` の分け方はよくできている。再構築側に有用なのは主に `F` と `Q` で、
- evidence schema の整備
- path convention の固定
- write protocol の定義
- validation tooling
- 既存データの品質修復
が先に必要だと明示している。これはそのまま再構築の初期フェーズに流用できる。

一方で、この文書のスケジュール、Claim 充足判定、SES 投稿前提の順序は、そのままは使わない方がいい。理由は、現在は「論文化を前に進める」より「再現可能なシステム境界を作る」方が優先だからだ。つまり、この文書は roadmap というより task inventory と見るのが正しい。

[preliminary-paper-report.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/v4-validation/preliminary-paper-report.md) は、再構築で守るべき研究上の論点整理として有用だ。特に残すべきなのは、
- Claim A/B/C/D という評価観点
- internal validity / external validity の区別
- reverse-engineering bias や post-hoc labeling caveat の明示
- ablation をどう読むかの仮説
だ。逆に、個別の readiness 判定や既存数値は、データ信頼性に疑義がある以上、参考値として凍結扱いにすべきだ。

整理すると、新しい repo に持ち込むべきなのは次の3層だ。
- 方法論資産: `F/Q/P/S/R` の作業分解、4 claims、validity threat の観点
- 契約資産: schema、protocol、validation、path convention
- 参考資産: 既存の数値・readiness・議論ログ

持ち込むべきでないのは、
- 既存データを前提にした達成判定
- その時点のスケジュール
- 「この evidence はもう使える」という既成事実化
だ。

実務上は、新 repo でまず以下の3文書を作り、その中にこの2文書の有効部分だけを再定義するのがよい。
- `RESEARCH_SCOPE.md`
- `EVIDENCE_PROTOCOL.md`
- `PAPER_WORK_BREAKDOWN.md`

位置づけは、
- `paper-submission-plan.md` は `PAPER_WORK_BREAKDOWN.md` の素材
- `preliminary-paper-report.md` は `RESEARCH_SCOPE.md` の素材
になる。

次にやるべきことは、この2文書から「新 repo に継承する項目」と「archive に留める項目」を切り出して一覧化することだ。必要なら次のターンで、その切り分け表を作る。



```
もう一つ、調査済みかもしれないが、開発はcc-sddを元に行っている。つまり仕様駆動開発だ。.kiro/specs/dual-reviewer-*というディレクトリに仕様書などがある。
```

把握済みだ。ここは重要で、再構築でも前提に据えるべきだ。

この repo のレビューシステムは単なるプロトタイプ群ではなく、`cc-sdd` ベースの仕様駆動開発として進められている。実際に正本は `scripts/` 側ではなく、 [`.kiro/specs/dual-reviewer-foundation/`](</Users/Daily/Development/Rwiki-dev/.kiro/specs/dual-reviewer-foundation>)、 [`.kiro/specs/dual-reviewer-design-review/`](</Users/Daily/Development/Rwiki-dev/.kiro/specs/dual-reviewer-design-review>)、 [`.kiro/specs/dual-reviewer-dogfeeding/`](</Users/Daily/Development/Rwiki-dev/.kiro/specs/dual-reviewer-dogfeeding>) にある。`requirements.md`、`design.md`、`tasks.md`、`spec.json` が揃っていて、`scripts/dual_reviewer_prototype/` と `scripts/dual_reviewer_dogfeeding/` はその実装・運用側の成果物だ。

これは新ディレクトリに切り出すときの設計にも効く。新 repo では最初から
- `specs/` が正本
- `implementation/` は spec の従属
- `experiments/` は consumer
- `paper/` は派生利用
という境界を明確にすべきだ。前回はこの境界が repo 全体では崩れていた。

なので再構築方針は「新しく作る」ではなく、正確には「cc-sdd の形を保ったまま、研究・運用・実装の責務分離をやり直す」になる。`dual-reviewer-*` の spec 群は、新 repo に移す際の最重要インプットだ。

次に進めるなら、新 repo のディレクトリ設計を `cc-sdd` 前提で起こすべきだ。例えば、
- `specs/dual-reviewer-foundation`
- `specs/dual-reviewer-runtime`
- `specs/dual-reviewer-evaluation`
- `runtime/`
- `experiments/`
- `paper/`
  のように分離する案が考えられる。必要なら次で、この spec 駆動前提の新 repo 構成案を具体化する。





```
これでおそらく最低限のインプットは済んだ筈
```

最低限の前提は揃った。

現時点で確定している重要事項は次の通りだ。  
- 現ディレクトリは `Rwiki` 本体、レビューシステム、評価・論文化作業が混在している  
- レビューシステムは `cc-sdd` ベースの仕様駆動開発で進んでおり、正本は [`.kiro/specs/dual-reviewer-*`](</Users/Daily/Development/Rwiki-dev/.kiro/specs>) にある  
- 前回の主失敗は実装そのものより、repo 外に置いた LLM 制御資産、途中で揺れたデータ取得計画、git 操作と評価運用の混線にある  
- 論文化計画と preliminary report は、再構築後に必要な研究作業の骨格として使えるが、既存の達成判定や数値は凍結扱いにすべき  
- 再構築は現 repo の延長ではなく、新ディレクトリに切り出して進めるのが妥当

次の段階はもう調査ではなく設計だ。具体的には、
1. 新 repo の責務境界を定義する  
2. `cc-sdd` 前提のディレクトリ構成を決める  
3. 旧 repo から持ち出すものと持ち出さないものを確定する  
4. 最初に書くべき SSoT 文書を決める

次はそのまま、「新ディレクトリでの再構築計画」として具体的な repo 構成、spec 構成、移行対象一覧まで落とし込める。



```
進めて
```

再構築計画のたたき台を [docs/dual-reviewer-rebuild-plan.md](/Users/Daily/Development/Rwiki-dev/docs/dual-reviewer-rebuild-plan.md) に作成した。

内容は、新 repo 前提での
- 責務境界
- `cc-sdd` を維持した spec 再編
- 推奨ディレクトリ構成
- 持ち出すもの / 持ち出さないもの
- 最初に書くべき SSoT 文書
- 初期 migration 順序

までを一通り固定している。特に `dual-reviewer-foundation` / `runtime` / `evaluation` / `paper-interface` の 4 spec に再編する方針と、prompt・policy・schema・validator を repo 内完結にする原則を明文化した。

今回は設計文書の追加だけで、テスト実行は不要だった。次はこの文書を基に、新ディレクトリ側の skeleton と最初の 4 文書を起こす段階に進める。



```
dual-reviewerの精度を継続的に向上する自己改善の仕組みも必要。それが、レビュー記録と内部動作のエビデンスである。
```

その通りで、これは再構築の必須要件だ。`dual-reviewer` は一度作って終わりではなく、review 記録と内部挙動 evidence を入力にして精度を上げ続ける仕組みを持つべきだ。

その観点を反映して、[docs/dual-reviewer-rebuild-plan.md](/Users/Daily/Development/Rwiki-dev/docs/dual-reviewer-rebuild-plan.md) を更新した。主な追加点は次の通りだ。
- 再構築目的に「内部動作 evidence を使った継続改善」を明記
- 新 repo に `dual-reviewer-self-improvement` spec を追加
- `learning/` 配下に改善提案と採否履歴を残す構成を追加
- 新規 SSoT として `SELF_IMPROVEMENT_LOOP.md` を追加
- 改善入力、改善対象、提案から backtest、採用、rollback までの基本 loop を明文化
- 「repo 外 memory による恒久補正」や「証拠なしの prompt 追加」を禁止事項として明記

重要なのは、自己改善を単なるメモ追加ではなく、evidence ベースで `spec / prompt / policy / runtime` を更新する正式な loop として扱うことだ。次はこの方針を前提に、新 repo 側で最初に作る `SELF_IMPROVEMENT_LOOP.md` と 5 spec の skeleton を起こす段階に進める。



```
それから、これは人が全容を理解するためのものだが、intent（システム開発の意図）を明文化しておきたい。intentから仕様にどう流れていくのか。
```

それは必要だ。仕様駆動開発だけでは「どう作るか」は残るが、「なぜその仕様にしたか」が散りやすい。なので `intent` を spec より上位の層として置くべきだ。

その方針を [docs/dual-reviewer-rebuild-plan.md](/Users/Daily/Development/Rwiki-dev/docs/dual-reviewer-rebuild-plan.md) に反映した。追加した要点は次の通りだ。
- `intent` を再構築目的と基本方針に明記
- `intent policy` を追加
- 新 repo に `intent/` ディレクトリを追加
- 最初に作る文書として `INTENT.md`、`NON_GOALS.md`、`DESIGN_PRINCIPLES.md`、`TRACEABILITY.md` を追加
- `intent → system boundary → requirements → design → tasks` の流れを明文化
- `TRACEABILITY.md` で intent と spec と runtime/evaluation/paper を結ぶ前提を追加

つまり新 repo では、流れはこうなる。
1. `INTENT.md` で開発意図を書く  
2. `NON_GOALS.md` で切るものを書く  
3. `DESIGN_PRINCIPLES.md` で設計原則に落とす  
4. `SYSTEM_BOUNDARY.md` で責務境界を固定する  
5. その上で `cc-sdd` の spec 群に落とす

次はこの plan をそのまま使って、新ディレクトリ側の `intent/` 文書群と 5 spec skeleton を起こす段階だ。



```
再構築にあたり、他に必要な観点はないか？
```

ある。いま出ている `intent / spec / reproducibility / self-improvement` だけでも骨格は十分強いが、再構築を失敗させないためには、少なくとも次の観点を追加で明示した方がいい。

- `deployment model`
  - どこでどう使うのか。ローカル専用か、他 repo に組み込むのか、CLI 配布か。これが曖昧だとまた repo 外依存が入り込む。

- `operational trust boundary`
  - 何を LLM に任せ、何を機械検証し、何を人間承認に残すか。特に `prompt が決めること` と `validator が決めること` を分ける必要がある。

- `observability`
  - 最終 finding だけでなく、途中の分岐、skip 理由、override、失敗した提案、再試行理由をどこまで残すか。自己改善の前提になる。

- `data invalidation policy`
  - どんな条件なら run を無効扱いにするか。途中で protocol が変わった、prompt version が混ざった、target hash がずれた、などの失格条件を先に決めるべきだ。

- `change control`
  - prompt、policy、schema、runtime の変更をどう承認するか。改善提案が出ても、何をもって正式採用とするかの gate が必要だ。

- `human workflow`
  - 利用者がどう操作し、どこで判断し、何を見て承認するか。システムだけでなく、人の使い方も設計対象にしないとまた運用で崩れる。

- `evaluation baseline`
  - 何と比較して良くなったと言うのか。`single / dual / dual+judgment` だけでなく、将来の比較軸追加余地も整理した方がいい。

- `cost and latency budget`
  - 精度改善だけでなく、何倍まで遅くなってよいか、どの程度の token cost を許すか。改善 loop が高価すぎると運用されない。

- `security and sensitivity`
  - review 対象やログに機微情報が入る場合の扱い。保存、再利用、論文化入力への流し込みの境界を決める必要がある。

- `success / stop criteria`
  - 何をもって再構築完了とみなすか。逆に、どの時点で設計を切り直すか。これがないと延々と改善を続ける構造になる。

優先度でいうと、次に補うべきなのはこの4つだ。
- `deployment model`
- `operational trust boundary`
- `data invalidation policy`
- `human workflow`

この4つが固まると、`intent` から `spec` へ落とすときの曖昧さがかなり減る。必要なら次で、この4観点を新 repo の上位文書にどう入れるかまで具体化する。



```
よろしく
```

不足観点を再構築計画に組み込んだ。更新先は [docs/dual-reviewer-rebuild-plan.md](/Users/Daily/Development/Rwiki-dev/docs/dual-reviewer-rebuild-plan.md) だ。

追加したのは主に4系統だ。
- `deployment policy`
- `trust-boundary policy`
- `invalidation policy`
- `human-workflow policy`

それに対応して、新 repo の上位文書として `operations/` 配下を追加した。
- `DEPLOYMENT_MODEL.md`
- `TRUST_BOUNDARY.md`
- `HUMAN_WORKFLOW.md`
- `DATA_INVALIDATION_POLICY.md`

あわせて、`intent → operations → system boundary → specs` という流れに整理した。これで
- なぜ作るか
- どう使うか
- 何を信用するか
- どのデータを無効にするか
- 人がどう関与するか
を spec に落とす前に固定できる。

現時点で、新 repo 着手前の上位設計としてはかなり必要条件が揃った。次はもう文書設計ではなく、実際に新ディレクトリを作って
- `intent/`
- `operations/`
- `.kiro/specs/` の 5 skeleton
を起こす段階に入れる。



```
継続的な精度改善のためには、多くのデータがあるとよい。自分のデータだけでなく、多様な言語・ターゲットのデータがあれば改善に役立つ。それらのデータを集める方法として、GitHubのホストへPRなどで測定データを送ることが考えられる（先の計画かも）
```

その方向は有効だ。ただし、今すぐ入れるべき中核機能ではなく、`Phase 2 以降の学習ネットワーク` として切り分けるべきだ。

理由は明確で、外部データ収集は強力だが、一気に複雑度を上げる。
- データ形式の標準化
- 匿名化や機微情報処理
- 信頼できる run かどうかの検証
- version 差異の吸収
- 悪いデータの混入対策
- 多言語・多ドメイン差の扱い  
を先に決めないと、集めた量がそのままノイズになる。

なので位置づけとしてはこうなる。

1. `Phase 1`
   - 単一 repo 内で再現可能な runtime
   - 厳密な protocol
   - self-improvement loop
   - invalidation policy  
   を固める

2. `Phase 2`
   - 外部 project からの run data 受け入れ
   - 収集フォーマット標準化
   - 提出経路の整備
   - cross-project learning

GitHub 経由で PR を送る案は実務的に良い。特に利点は、
- 提出データが review 可能
- schema validation を CI でかけられる
- provenance が git 履歴で残る
- protocol version ごとの差分を追える
ことだ。

もしこの方向を採るなら、新 repo では将来用に次の設計を最初から入れておくべきだ。
- `contribution data schema`
  - どの run data を受け付けるか
- `submission protocol`
  - どう anonymize し、どう提出するか
- `trust tier`
  - 自分の手元 run、既知 contributor、未知 contributor を分ける
- `compatibility contract`
  - prompt / protocol / runtime version が違うデータをどう扱うか
- `cross-project metadata`
  - 言語、対象、レビュー phase、モデル、treatment、domain など
- `admission / rejection rule`
  - どのデータを学習入力に採用し、どれを弾くか

つまり将来像としては、
- `runtime` がデータを生む
- `evaluation` がその質を測る
- `self-improvement` が改善提案を作る
- `contribution` が外部データを受け取る
という 4 層になる。

現段階の判断としては、
- 構想として採用
- ただし初期再構築のスコープには入れない
- 新 repo では将来のために `external contribution` を見越した schema と metadata 設計だけ入れておく  
のが妥当だ。

必要なら次で、この構想を再構築計画に `Phase 2: federated evidence collection` として追加できる。



```
ここで今後の進め方を教えてください
```

今後の進め方は、調査を終えて「新 repo の立ち上げフェーズ」に入るのが正しい。順序は次の通りだ。

**1. 現 repo では設計を固定する**  
まずは [docs/dual-reviewer-rebuild-plan.md](/Users/Daily/Development/Rwiki-dev/docs/dual-reviewer-rebuild-plan.md) を親文書として扱い、ここにある前提で進める。ここで追加でやるのは大きな調査ではなく、抜け漏れ確認だけで十分だ。

**2. 新ディレクトリを作る**  
新 repo を作成する。ここが再構築の主作業場になる。現 repo は archive / reference に下げる。

**3. 新 repo の上位文書を最初に書く**  
コードより先に、次を初版で置く。
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
- `SELF_IMPROVEMENT_LOOP.md`

**4. `cc-sdd` の spec skeleton を作る**  
少なくとも次の 5 spec を起こす。
- `dual-reviewer-foundation`
- `dual-reviewer-runtime`
- `dual-reviewer-evaluation`
- `dual-reviewer-paper-interface`
- `dual-reviewer-self-improvement`

この段階では `requirements.md` を先に固める。実装移植はまだ後だ。

**5. 旧 repo から移植対象 manifest を作る**  
何を持ち出すかを一覧化する。
- 持ち出す: schema、prompt、prototype 実装、tests、analysis scripts、3 spec
- 持ち出さない: repo 外 memory 前提、既存達成判定、暫定数値、混線した運用知識

**6. foundation から順に移植する**  
順番は固定した方がいい。
1. foundation
2. runtime
3. evaluation
4. self-improvement
5. paper-interface

**7. 小規模 dry-run をやる**  
いきなり大量データ取得には行かない。
- target 1 件
- treatment 1 件
- 少数 round  
で、log 完全性、validator、無効化条件、human workflow を確認する。

**8. dry-run が通ってから本格採取に入る**  
この時点で初めて data acquisition を再開する。外部データ収集や GitHub PR ベースの投稿は、その次のフェーズに置く。

実務的には、次の1手はこれだ。  
- 新ディレクトリを作る  
- そこで `intent/`、`operations/`、`.kiro/specs/` の skeleton を起こす

必要なら次のターンで、その新 repo の初期ファイル構成をそのまま作業単位まで分解して提示する。



```
進めて
```

新ディレクトリ [dual-reviewer-rebuild](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild) を作成し、再構築の初期 skeleton を配置した。

入れたものは、
- 上位文書: [intent](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent), [operations](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations), [SYSTEM_BOUNDARY.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/SYSTEM_BOUNDARY.md), [REPRODUCIBILITY_CONTRACT.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/REPRODUCIBILITY_CONTRACT.md), [EVIDENCE_PROTOCOL.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/EVIDENCE_PROTOCOL.md), [SELF_IMPROVEMENT_LOOP.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/SELF_IMPROVEMENT_LOOP.md), [PAPER_WORK_BREAKDOWN.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/PAPER_WORK_BREAKDOWN.md)
- `cc-sdd` 骨格: [`.kiro/steering/`](</Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/steering>) と [`.kiro/specs/`](</Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs>)
- 5 spec skeleton: `foundation`、`runtime`、`evaluation`、`paper-interface`、`self-improvement`

この状態で、もう新 repo 側で Requirements フェーズを始められる。次の実作業は [dual-reviewer-foundation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/requirements.md) を旧 spec と照合しながら具体化し、移植対象 manifest を作るのが順当だ。

今回は skeleton 作成のみで、テスト実行はしていない。



```
次は？
```

次は `foundation` を固める。順番を崩さない方がいい。

まずやることは3つだ。
1. [dual-reviewer-foundation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/requirements.md) を旧 repo の foundation spec と照合して具体化する  
2. 旧 repo からの移植対象 manifest を作る  
3. `runtime/` に入る最小資産を確定する  
対象は schema、prompt、pattern、config contract

理由は、`runtime` や `evaluation` は `foundation` の contract が固まらないと設計がぶれるからだ。特に今回は
- review state machine
- finding / judgment / review_case schema
- prompt 配置規約
- version metadata
- validator 前提  
を先に固定する必要がある。

次の作業単位としてはこれが妥当だ。
- 旧 [`.kiro/specs/dual-reviewer-foundation/requirements.md`](</Users/Daily/Development/Rwiki-dev/.kiro/specs/dual-reviewer-foundation/requirements.md>) を読み直して、新 repo 側 `requirements.md` に再構築用要件として書き直す
- 同時に `MIGRATION_MANIFEST.md` を新 repo に作り、
  - 持ち出すファイル
  - 参照のみのファイル
  - 持ち出さないファイル  
  を列挙する

その次が `foundation` の design、その後に実ファイル移植だ。

進めるなら、次のターンでこちらで
- `foundation/requirements.md` の具体化
- `MIGRATION_MANIFEST.md` の作成  
まで進める。



```
GO
```

`foundation` の再構築用 requirements を具体化して、あわせて [MIGRATION_MANIFEST.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/MIGRATION_MANIFEST.md) を作成した。

今回進めたのは、
- [dual-reviewer-foundation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/requirements.md) を旧 spec ベースで再定義
- 旧 repo からの移植対象、参照のみ、持ち出さないものを manifest 化

新しい `foundation` requirements は、旧 spec の内容をそのまま写すのではなく、
- review state machine
- role / config abstraction
- shared schema set
- canonical prompt placement
- pattern / terminology assets
- validator-oriented metadata
- repo-contained asset rule  
に絞って、再構築に必要な contract として整理している。

次に進むべきなのは `foundation` の design だ。具体的には、
- `runtime/schemas/` の配置
- `runtime/prompts/` の配置
- `runtime/config/` と `runtime/validators/` の責務
- run metadata の最小フィールド
- invalidation marker の持ち方  
を設計に落とす段階になる。

今回は文書更新のみで、テスト実行はしていない。



```
INTENT.mdはこんなにコンパクトでいいのか
```

短すぎる。今の [INTENT.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/INTENT.md) は placeholder でしかない。

現状の長さでよいのは「骨格を先に作る」段階までで、再構築を本当に進めるには少なくとも次を入れるべきだ。
- 背景
  - なぜ再構築が必要になったか
  - 旧システムのどこで信頼性を失ったか
- 解くべき問題
  - repo 外依存
  - protocol drift
  - runtime と evaluation の混線
  - 人間が全体像を追えない構造
- 目指す状態
  - deploy 可能とは何か
  - 再現可能とは何か
  - 精度改善可能とは何か
- 利用者像
  - 誰が使うのか
  - どの場面で使うのか
  - 何を判断し、何を system に任せるのか
- 非機能要求の根
  - 信頼性
  - 可観測性
  - traceability
  - invalidation
- spec への橋渡し
  - この intent から foundation/runtime/evaluation/self-improvement/paper-interface がどう導かれるか

むしろ `INTENT.md` は、上位文書の中で一番しっかり書くべきだ。`requirements.md` より抽象だが、短文メモで済ませる文書ではない。

今の適切な位置づけはこうだ。
- `INTENT.md` 現状: 見出しだけ置いた最小雛形
- 次に必要な状態: 1,000〜2,000 words 相当の実質的な設計意図文書

次の作業として自然なのは、`INTENT.md` を本文化することだ。進めるならこちらで、
- 旧 repo の失敗要因
- 再構築の目的
- deploy / trust / self-improvement の意図
- spec への接続  
まで含めた初版に拡張する。



```
追記して
```

[INTENT.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/INTENT.md) を placeholder から実質的な初版に拡張した。

追加した内容は、
- 再構築の背景
- 旧 system の失敗要因
- 再構築が解くべき中心問題
- 目指す状態
- 想定利用者
- 何を信頼し、何を信頼しないか
- 何を失敗とみなすか
- 今回最適化しないもの
- intent から operations、spec への流れ
- 各 spec の役割
- 将来像
までを含む。

これで `INTENT.md` は、単なるメモではなく「なぜこの repo が存在するか」を説明できる文書になった。次に自然なのは、これに合わせて [NON_GOALS.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/NON_GOALS.md) と [DESIGN_PRINCIPLES.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/DESIGN_PRINCIPLES.md) も同じ粒度まで厚くすることだ。



```
INTENTは私の考えている主要な部分をカバーしている。次は2文書を厚く書いてください
```

[NON_GOALS.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/NON_GOALS.md) と [DESIGN_PRINCIPLES.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/DESIGN_PRINCIPLES.md) を、placeholder から上位文書として使える粒度まで拡張した。

`NON_GOALS.md` には、
- なぜ non-goals が必要か
- 初期再構築で扱わないもの
- 後回しにするもの
- scope 逸脱とみなす条件
- 各 spec への影響
を入れた。特に `public contribution intake`、`multi-vendor`、`packaged CLI`、`hosted service`、`paper-first optimization` を明確に切っている。

`DESIGN_PRINCIPLES.md` には、
- repo-contained runtime
- protocol first
- immutable raw evidence
- trust boundary separation
- evidence-driven change
- human-visible intent
- boundary before convenience
- narrow first, generalize later
- runtime / evaluation / paper separation
- invalidation is first-class
- improvement without hidden memory
- future learning network is optional
を原則として明文化した。さらに、原則の優先順位と各 spec への影響も追加してある。

これで `intent/` の 3 文書は、再構築の上位入力としてかなり機能する状態になった。次に自然なのは [TRACEABILITY.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/TRACEABILITY.md) を、今の 3 文書と 5 spec に対応づける形に厚くすることだ。



```
次
```

[TRACEABILITY.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/TRACEABILITY.md) を実用レベルまで拡張した。

入れた内容は、
- この文書の役割
- `intent -> operations -> specs -> artifacts -> evidence` の 5 層
- intent と operations の対応
- design principles と各 spec の対応
- non-goals がどこを除外するか
- 5 spec と想定 artifact の対応
- artifact と evidence の対応
- 変更時にどこを見直すべきか
- 現時点で優先して追跡すべき対応関係
までだ。

これで `intent/` の 4 文書は、上位入力として一通り機能する状態になった。次に進むなら、`operations/` の 4 文書も同じ粒度まで厚くするか、あるいはそのまま `foundation` の design に入るかの二択だ。現時点では `foundation` を先に進める方が自然だ。



```
開発途中のリポジトリの扱いをどうするか。仕様書などのレビュープロセスはcc-sddを使うか。コーディングはcodexが担当？
```

整理すると、扱いは二層に分けるのがよい。

開発途中の既存リポジトリは、今後は主作業場ではなく `archive / source reference / migration source` として扱う。つまり、
- 旧 repo では原則として新機能開発を進めない
- 必要なときだけ spec、実装、ログ、評価資産を参照する
- 再構築の正本は新 repo に置く
という運用に切り替えるべきだ。  
例外は、旧 repo 側に「移行計画」「参照メモ」を残す程度で、runtime の再構築そのものは新 repo でやる。

仕様書や review process は、基本的に `cc-sdd` を継続した方がいい。今回の再構築は、むしろ `cc-sdd` をやめる理由がない。前回の問題は spec-driven だったことではなく、spec の上位にある intent と運用境界が弱かったことにある。なので構造はこうなる。
- `intent/` と `operations/` が最上位
- その下で `.kiro/specs/` に `cc-sdd` の spec を置く
- requirements -> design -> tasks の順で進める
- 実装はその下流

コーディングは、原則として Codex が担当でよい。ただし「全部自動でやる」というより、責務分担を明示した方がいい。
- 人間
  - intent
  - non-goals
  - trust boundary の最終判断
  - review / approval
  - spec phase の承認
- Codex
  - 文書下書き
  - spec の具体化
  - 実装
  - validator / schema / script 整備
  - テスト
  - migration 作業
- `cc-sdd` review process
  - requirements / design / tasks 各 phase のゲート
  - human approval を必須にする

要するに、
- 旧 repo は archive
- 新 repo が正本
- spec と review process は `cc-sdd`
- 実装と具体化は Codex
- 最終判断と phase 承認は人間
という運用が最も安定する。

次の実務判断としては、これを新 repo の `HUMAN_WORKFLOW.md` と `DEPLOYMENT_MODEL.md` に明文化するとぶれにくい。必要なら次でその2文書を厚くできる。



```
お願い。その次は戻ってoperation
```

[HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md) と [DEPLOYMENT_MODEL.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/DEPLOYMENT_MODEL.md) を厚くした。

`HUMAN_WORKFLOW.md` では、
- 人間、Codex、`cc-sdd` の役割分担
- 旧 repo と新 repo の使い分け
- 開発 workflow
- review session 実行時の人間関与
- 承認単位
- Codex に委ねる深さ
- 逸脱防止ルール
を明文化した。

`DEPLOYMENT_MODEL.md` では、
- 初期 target を `local-only / single operator / repo-contained runtime` に固定
- deploy 可能とみなす条件
- deploy unit
- 運用前提
- 初期段階で対象外の deploy 形態
- 旧 repo との関係
- 将来拡張
- 各 spec への含意
を整理した。

指定どおり次は `operations` に戻るなら、残りの [TRUST_BOUNDARY.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/TRUST_BOUNDARY.md) と [DATA_INVALIDATION_POLICY.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/DATA_INVALIDATION_POLICY.md) を同じ粒度まで引き上げるのが自然だ。



```
GO
```

[TRUST_BOUNDARY.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/TRUST_BOUNDARY.md) と [DATA_INVALIDATION_POLICY.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/DATA_INVALIDATION_POLICY.md) を厚くした。

`TRUST_BOUNDARY.md` では、
- 何を信頼対象に置くか
- LLM、validator、人間、Codex の責務境界
- generation / validation / approval / adoption の decision point
- trust boundary violation の例
- 各 spec との関係
を明文化した。

`DATA_INVALIDATION_POLICY.md` では、
- valid run の最小条件
- invalid run の類型
- invalidation marker
- invalid run の保存方針
- evaluation / self-improvement / paper-interface での扱い
- 旧 repo 由来 data の扱い
を整理した。

これで `operations/` の 4 文書は、上位運用文書としてかなり揃った。次に戻る先として自然なのは、今まで整えた `intent/` と `operations/` を入力にして、`foundation` の `design.md` を具体化することだ。



```
次のタスクは何？
```

次のタスクは `foundation design` だ。

理由は、上位の `intent/` と `operations/`、それに `foundation requirements` が揃ったので、ここで初めて
- schema をどこに置くか
- prompt をどこに置くか
- config / terminology template をどう持つか
- validator が何を読むか
- run metadata をどう表現するか  
を設計に落とせるからだ。

順番としてはこれが自然だ。
1. [dual-reviewer-foundation/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/design.md) を起こす  
2. `runtime/schemas/`, `runtime/prompts/`, `runtime/config/`, `runtime/validators/` の配置方針を確定する  
3. `review_case` などの schema と required metadata の対応を決める  
4. その後に foundation artifact の実移植に入る

この task の出力は、単なる説明ではなく、実際に移植作業に使える設計文書になるべきだ。  
その次が foundation assets のコピーと validator の最小実装、その後に `runtime requirements` へ進む。

要するに、今の最重要タスクは
- `foundation` の設計を固めること
だ。  
進めるなら次でその `design.md` をこちらで具体化する。



```
foundationを垂直にdesign, taskと処理していくのではなく、foundationのrequirementが終わったら、次は他のフィーチャーのrequirementを全て定義し、必要に応じてフィーチャー間の整合性を取る作業が必要ではないか
```

その判断が正しい。ここで `foundation` だけを垂直に `design -> tasks -> implementation` まで進めるのは早い。

理由は、今回の再構築は単一機能ではなく、少なくとも
- `foundation`
- `runtime`
- `evaluation`
- `paper-interface`
- `self-improvement`
の 5 feature が強く結合しているからだ。`foundation` を深く設計し始めると、
- metadata contract
- invalidation rule
- review output unit
- self-improvement input
- paper-facing export
あたりで、後続 feature の requirement が未定だと手戻りが出る。

したがって、次の正しい進め方はこうだ。
1. `foundation requirements` を今のように固める  
2. 残り 4 feature の `requirements.md` を先に全部具体化する  
3. feature 間の依存と衝突を cross-spec review する  
4. そこで interface と責務境界を調整する  
5. その後に `design` フェーズへ進む

これは実質的に、再構築版の `multi-spec requirements wave` を先に終わらせる、ということだ。

特に先に揃えるべき requirement の論点は次だ。
- `runtime`
  - review unit
  - approval unit
  - run close contract
  - prompt loading
- `evaluation`
  - valid / invalid separation
  - metrics scope
  - treatment definition
- `self-improvement`
  - proposal unit
  - replay / backtest input
  - adoption / rollback gate
- `paper-interface`
  - evaluation から受け取る artifact
  - runtime に逆流しない境界

そしてその後に必要なのが、あなたの言う「フィーチャー間の整合性を取る作業」だ。これは明確に 1 task として置いた方がいい。例えば、
- `cross-spec requirements alignment`
- `shared contract reconciliation`
- `traceability and interface review`
のような作業として扱うべきだ。

なので次のタスクは `foundation design` ではなく、
- 残り 4 feature の requirements を全部書く
- その後に cross-spec requirements 整合レビューを行う
に切り替えるべきだ。

進めるなら次で、
- `runtime/evaluation/self-improvement/paper-interface` の requirements を具体化する順序
- cross-spec review で見るべき論点  
までまとめて、そのまま requirements wave を始める。



```
その順序で進めて
```

残り 4 feature の requirements を具体化した。更新したのは次だ。
- [dual-reviewer-runtime/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/requirements.md)
- [dual-reviewer-evaluation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/requirements.md)
- [dual-reviewer-paper-interface/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/requirements.md)
- [dual-reviewer-self-improvement/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/requirements.md)

これで `requirements wave` は一通り揃った。今の正しい次タスクは `cross-spec requirements alignment` だ。見るべき論点は主にこれになる。
- foundation の metadata contract と runtime / evaluation の required fields が一致しているか
- runtime の decision unit と human workflow が一致しているか
- evaluation の valid / invalid separation と invalidation policy が一致しているか
- self-improvement の input contract が runtime / evaluation の出力で満たせるか
- paper-interface が runtime / evaluation に逆流していないか

今回は文書更新のみで、テスト実行はしていない。次はこの 5 spec の requirements を横断レビューして、齟齬を洗い出して詰める段階に進める。



```
現状は？
```

現状は、再構築の「上位設計」と「requirements wave」が揃った段階だ。まだ design フェーズには入っていない。

できているものは次の通りだ。
- 新 repo [dual-reviewer-rebuild](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild) を作成済み
- `intent/` の 4 文書を実質的な内容まで拡張済み
- `operations/` の 4 文書を実質的な内容まで拡張済み
- `foundation` の requirements を再構築向けに具体化済み
- 移植対象一覧 [MIGRATION_MANIFEST.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/MIGRATION_MANIFEST.md) を作成済み
- 残り 4 feature
  - `runtime`
  - `evaluation`
  - `paper-interface`
  - `self-improvement`
  の requirements も具体化済み

つまり今は、
- `intent`
- `operations`
- `5 specs の requirements`
が揃っていて、`cc-sdd` でいう multi-spec requirements フェーズを終えつつある状態だ。

まだやっていないことは次だ。
- 5 spec 間の requirements 整合レビュー
- 各 spec の design
- foundation assets の実移植
- runtime / validator / schema の具体実装
- dry-run
- 本格 data acquisition

一言で言えば、今は「設計前の仕様整理が完了し、これから横断整合レビューに入る直前」だ。次の明確なタスクは `cross-spec requirements alignment` になる。



```
次のタスクを実行
```

`cross-spec requirements alignment` を実行した。結果は [docs/cross-spec-requirements-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/cross-spec-requirements-alignment.md) にまとめてある。

今回やったことは 2 つだ。  
1. 5 spec の requirements を横断して shared contract を確認  
2. blocking 級の齟齬をその場で修正

修正した点は次の 3 件。
- `foundation` の `finding` contract に `human decision linkage` を追加  
  対象: [dual-reviewer-foundation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/requirements.md)
- `foundation` の required metadata に `validator status` と `human sign-off status` を追加  
  対象: 同上
- `runtime` が `paper-interface` に直接従属して見える記述を修正し、原則 `evaluation` 経由に変更  
  対象: [dual-reviewer-runtime/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/requirements.md)

現状の結論は、requirements wave の時点での大きな矛盾は解消できていて、残りは design で決めるべき interface detail に整理された。主な残件は、
- exploratory category の formal field
- minimum metric set に必要な field 所在
- replay granularity
の 3 つだ。

次のタスクは `foundation design` に入ることだ。ここで
- run metadata field list
- finding-level human decision linkage の表現
- invalidation marker の持ち方
- schema / prompt / config / validator の配置
を設計に落とすのが自然だ。

今回は文書更新のみで、テスト実行はしていない。



```
現状の作業として、既存のdual-reviewerの機能を再整理し、仕様、設計、タスクにおとす作業をしている。この過程で機能の再検討は行うか？
```

行う。ただし、無制限にはやらない。位置づけは「再整理の過程で必要な範囲に限って再検討する」だ。

今回の作業は単なる書き写しではない。旧 `dual-reviewer` の機能を
- intent
- operations
- specs
の構造に載せ替えているので、その途中で
- この機能は foundation ではなく runtime ではないか
- これは evaluation に置くべきではないか
- これは repo 外依存を前提にしていて現方針と矛盾する
- これは paper convenience 由来で runtime には不要ではないか
のような再検討は必ず入る。

ただし、再検討には境界がある。今やるべき再検討は 3 種だけだ。
- `責務の再配置`
  - どの feature に属するかを見直す
- `contract の再定義`
  - metadata、schema、approval unit、invalidation のような共有境界を見直す
- `初期スコープへの適合確認`
  - local-only、repo-contained、evidence-driven に合わない機能を切る

逆に、今は原則やらない方がいい再検討もある。
- 新しい大機能の追加
- 将来構想を先取りした拡張
- 外部 contribution network の実装前提化
- multi-vendor 最適化
- paper のための機能追加

つまり、
- `再整理に必要な再検討` はやる
- `スコープを広げる再発明` はやらない
という方針になる。

実務上は、各 spec の requirements/design を書くときに、機能ごとに次の 3 分類で扱うのがよい。
- `keep`
  - そのまま残す
- `reshape`
  - 責務や interface を変えて残す
- `drop/defer`
  - 今回は落とすか後段に回す

必要なら次で、この `keep / reshape / drop-defer` の判断表を作って、旧 `dual-reviewer` の主要機能を棚卸しできる。



```
判断表を作成
```

判断表を [feature-disposition-judgment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/feature-disposition-judgment.md) として作成した。

内容は、旧 `dual-reviewer` の主要機能を
- `keep`
- `reshape`
- `drop/defer`
で分類し、それぞれに理由と再構築での扱いを付けたものだ。  
特に、
- pipeline、3 role、schema、treatment 比較、self-improvement loop は `keep`
- `dr-*` 分割、`seed_patterns`、dogfeeding scripts、comparison artifacts、review logs は `reshape`
- repo 外 memory、transcript 依存運用、paper-first 拡張、external contribution、multi-vendor、packaged CLI は `drop/defer`
として整理している。

これで、今後旧 repo から何かを移すときに「そもそも残すのか、形を変えるのか、後回しにするのか」を先に確認できる状態になった。次に自然なのは、この判断表を入力にして `foundation` の design に入ることだ。



```
旧システムのプロンプトはスキルによる実装だったが、今回はどうするか
```

今回は、そのままスキル実装に戻さない方がいい。少なくとも「prompt の正本」はスキルではなく、repo 内の独立 artifact にすべきだ。

理由は明確で、前回問題だったのは prompt が runtime contract ではなく、運用や実行環境に埋まりやすかったことだ。スキル実装の中に prompt を閉じ込めると、
- version 管理が曖昧になる
- diff しにくい
- validator や replay から参照しにくい
- runtime / self-improvement / paper で同じ prompt を追跡しにくい
という欠点が出る。

推奨は 3 層に分ける形だ。
- `runtime/prompts/`
  - prompt 本文の正本を置く
- `runtime/policies/`
  - prompt に埋め込まない判断原則や運用規律を置く
- `runtime/skills/` または runtime code
  - prompt を読み込み、必要な変数を埋めて実行する薄い呼び出し層にする

つまり、
- prompt はデータ
- skill / runtime module は実行器
として分離する。

旧 `dr-design`、`dr-judgment`、`dr-init` 的な単位は残してもいいが、役割は変えるべきだ。
- 旧: スキルの中に prompt と手順が同居
- 新: スキルは orchestration だけ持ち、prompt 本文は外部ファイル参照

実務的には、こうするのがよい。
- `runtime/prompts/judgment/`
- `runtime/prompts/adversarial/`
- `runtime/prompts/primary/`
- `runtime/prompts/shared/`
のように prompt を role / 用途ごとに分ける  
- 各 prompt に version と用途を持たせる  
- runtime は prompt path と version を run metadata に必ず記録する

一方で、完全にスキルを捨てる必要はない。  
もし `cc-sdd` や運用上「人が呼ぶ単位」としてスキルが分かりやすいなら、
- スキル = entrypoint
- prompt = repo 内 asset
- policy = repo 内 asset
- validator = 別層
という構造にすればよい。

結論としては、
- prompt の正本はスキルに埋め込まない
- スキルは薄い orchestration 層として残してよい
- 今回は `prompt as artifact` に切り替える
が妥当だ。

次にやるなら、この方針を `foundation design` か `runtime design` に明文化し、prompt directory 構成まで決めるのが自然だ。



```
このシステムは仕様駆動開発における仕様、設計、タスク各段階のレビュー支援を目的としている。あるいは、intentも入れた方がいいかもしれない。最上流であるintent、次のrequirementあたりまでは、人がなんとか把握できるかもしれないが、設計とタスクになると粒度が細かく、もはや人の認知のレベルを超えてくる。そうしたときに、このdual-reviewerの真価が発揮されると考えている
```

その理解でよいし、むしろ `intent` まで入れた方がいい。

今の整理だと、この system の本質は「LLM 一般の review 支援」ではなく、`cc-sdd` における上流から下流への認知負荷増大を補う review system だ。特に価値が出るのは、あなたの言う通り、
- `intent`
- `requirements`
- `design`
- `tasks`
のうち、後ろ 2 つ、場合によっては `intent -> requirements` の接続部だ。

人間は `intent` や `requirements` までは比較的全体像を保てるが、
- 設計で責務分解、例外、依存、状態遷移が増え
- タスクで変更点、順序、影響範囲、見落とし可能性が爆発する  
ので、ここで認知限界が来る。`dual-reviewer` はその「認知限界を越えた後の見落とし補完装置」として位置づけるのが正確だ。

なので、system intent としてはかなり重要な修正が必要だ。中心命題はたとえばこうなる。
- `dual-reviewer` は、仕様駆動開発において、人間が保持できる全体像と、設計・タスク段階で発生する局所複雑性のギャップを埋めるための review system である
- 特に design / tasks では、人間単独 review では保持しにくい cross-section consistency、責務境界、欠落状態、過剰修正、実装波及を補足する
- 必要なら intent 段階も対象に含めるが、主戦場は design / tasks である

この考え方に立つと、いくつか設計上の含意が出る。
- `intent` を review 対象に含めるなら、`dual-reviewer` は `intent -> requirements` の接続妥当性も見る必要がある
- `design` では、構造的一貫性、責務分離、failure mode、cross-spec 整合が主対象になる
- `tasks` では、変更網羅性、順序依存、抜け漏れ、検証可能性が主対象になる
- `paper-interface` よりも、`runtime` と `evaluation` の主対象 phase を明示した方がいい
- 将来的には `phase-specific review profile` が必要になる

要するに、`dual-reviewer` の真価は「文書を読むこと」ではなく、「人間が保持しきれない複雑性が増えた段階で、複数視点から見落としを補完すること」にある。これは `INTENT.md` の中核に入れるべき内容だ。

次にやるべきなのは、
- `INTENT.md` にこの phase-oriented positioning を追記する
- 必要なら `DESIGN_PRINCIPLES.md` に「human cognition limit aware review」を原則として追加する
- さらに `runtime` / `evaluation` requirements に、phase ごとの主目的差を反映する
ことだ。



```
進めてください
```

phase-oriented な位置づけを反映した。

更新したのは次だ。
- [INTENT.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/INTENT.md)
- [DESIGN_PRINCIPLES.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/DESIGN_PRINCIPLES.md)
- [dual-reviewer-runtime/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/requirements.md)
- [dual-reviewer-evaluation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/requirements.md)

主な反映点は、
- `dual-reviewer` の主戦場を `design` / `tasks` と明記
- `intent` / `requirements` も対象に含めうるが、初期価値証明は後ろ 2 phase に置くと整理
- `human cognition limit aware review` を設計原則として追加
- runtime に `phase-aware review profile` 要件を追加
- evaluation に `phase-aware evaluation` 要件を追加
だ。

これで、system の価値命題が「一般的な review assistant」ではなく「仕様駆動開発で人間の認知限界を超え始める phase を補う review system」としてかなり明確になった。次の自然なタスクは、この位置づけを踏まえて `foundation design` に入るか、あるいは `runtime/evaluation` の cross-spec alignment メモを更新することだ。



```
もう一点、実際の開発には仕様駆動開発の流儀に従う。具体的な開発方法として、1）codexやclaudeのようなLLMが流儀に従い、自分の判断で開発を進める。2）cc-sddやopen spec kitなどのようなフレームワークを援用しながらLLMと協調して開発する。今回の再設計では、どういうスタイルが考えられるか
```

考えられるスタイルは大きく 3 つある。

**1. LLM 主導型**  
`Codex` や `Claude` が、与えられた流儀を内部化して自律的に進める形だ。
長所:
- 速い
- 文脈切替が少ない
- 小規模な変更に強い
短所:
- 流儀逸脱が起きても気づきにくい
- phase gate が曖昧になりやすい
- 人間が後から追跡しにくい

**2. フレームワーク協調型**  
`cc-sdd` や `Open Spec Kit` のような枠組みを明示的に使い、その phase に従って LLM が作業する形だ。
長所:
- 仕様、設計、タスクの境界が明確
- 承認点を作りやすい
- 人間が追いやすい
短所:
- 遅くなりやすい
- 小さな変更にも儀式が増える
- フレームワークに引っ張られて過剰に形式化しやすい

**3. ハイブリッド型**  
上位では `cc-sdd` 的な gate を使い、各 gate の中の具体化と実装は LLM 主導で進める形だ。
長所:
- 統制と速度のバランスがよい
- 人間の approval を保てる
- LLM の強みを活かせる
短所:
- どこまで自律、どこから gate かを決めないと崩れる

今回の再設計では、**3 のハイブリッド型** が最も妥当だ。

理由は単純で、今回作っているのは「LLM を含む system」なので、開発方法まで完全自律に寄せると、再び hidden rule が入りやすい。一方で、全部をフレームワーク手順で縛ると、再構築の速度が落ちる。だから、
- 上位意図と phase gate は `cc-sdd`
- 具体化、文書起草、実装、validator 整備は `Codex`
- 承認と scope change は人間
という分担が一番安定する。

実際の運用はこうなる。

**推奨スタイル**
- `intent/` と `operations/` は人間主導、Codex が下書き
- `.kiro/specs/*` は `cc-sdd` の phase で進める
- `requirements -> design -> tasks` の各 phase は人間承認必須
- 各 phase の中身の具体化は Codex 主導
- implementation は approved tasks の範囲で Codex 主導
- cross-spec 整合レビューは Codex が先に洗い、人間が最終判断

要するに、
- **方法論の骨格は `cc-sdd`**
- **作業実行エンジンは Codex**
- **意思決定と承認は人間**
という三層構造になる。

今回の再設計に即して言うと、次のように整理するとよい。
- `intent` 層: 人間が主、Codex が支援
- `requirements` 層: `cc-sdd` gate、Codex が起草
- `design` 層: `cc-sdd` gate、Codex が具体化
- `tasks` 層: `cc-sdd` gate、Codex が分解
- `implementation` 層: Codex 主導、人間 review
- `evaluation / self-improvement` 層: Codex が分析、人間が採否

結論として、今回の再設計で採るべきスタイルは  
**「`cc-sdd` を骨格にした LLM 協調開発」**  
だ。  
完全自律型でも、完全フレームワーク型でもなく、その中間がよい。

必要なら次で、この方針を [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md) と [DEPLOYMENT_MODEL.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/DEPLOYMENT_MODEL.md) に反映できる。



```
OK
```

了解。現時点の運用方針は、
- 方法論の骨格は `cc-sdd`
- 具体化と実装は Codex 主導
- 承認と scope 判断は人間
というハイブリッド型で進める、で固定してよい。

次に進むなら、この方針を `operations` 文書へ反映するか、そのまま `foundation design` に入るかの二択だ。現状は前者を軽く反映してから `foundation design` に進むのが自然だ。



```
OK
```

開発スタイルの方針を `operations` に反映した。

更新したのは次だ。
- [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md)
- [DEPLOYMENT_MODEL.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/DEPLOYMENT_MODEL.md)

反映した内容は、
- 採用する開発スタイルは「`cc-sdd` を骨格にした LLM 協調開発」
- phase gate は `cc-sdd`
- 各 phase の具体化、文書起草、実装、検証は Codex 主導
- 承認、scope change、deploy 条件変更は人間
- feature 間依存が強いときは vertical 進行より requirements wave / cross-spec review を優先
という整理だ。

これで上位文書としての足場はかなり揃った。次に進むなら、予定どおり `foundation design` に入るのが自然だ。



```
先ほど指示したように、仕様駆動開発であるが、フィーチャーが複数ある場合には、仕様書、設計書、タスクの各フェーズでフィーチャー間の調整するゲートを置く
```

反映した。更新したのは次だ。
- [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md)
- [TRACEABILITY.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/TRACEABILITY.md)

追加した内容は、
- multi-feature 開発では `requirements`、`design`、`tasks` の各 phase 終端に `alignment gate` を置く
- `requirements alignment gate` では shared contract と責務境界を確認
- `design alignment gate` では interface、配置、versioning、integration point を確認
- `tasks alignment gate` では実装順序、依存、shared artifact 移行、test sequencing を確認
- この gate を飛ばして次 phase に進むのは workflow 逸脱とみなす
というものだ。

これで、今回のような multi-feature 再設計で
- 1 feature だけ先に深く進みすぎる
- 共有 contract が後でずれる
という問題を process として防げるようになった。次に進むなら、このルールに従って `design alignment gate` の前段として `foundation design` を起こすのが自然だ。



```
foundation design を起こそう
```

`foundation design` を起こした。追加・更新したのは次だ。

- [design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/design.md)
- [requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/requirements.md)
- [cross-spec-requirements-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/cross-spec-requirements-alignment.md)

今回の design で固めた中身は、`foundation` が持つ shared asset layer だ。具体的には、`runtime/foundation/`、`runtime/schemas/`、`runtime/prompts/`、`runtime/patterns/`、`runtime/config/`、`runtime/validators/contracts/` の配置、`run_status` と `evidence_class` の分離、`finding` における human decision linkage、`step-level within run` を最小 replay 単位とする方針まで落とした。あわせて `phase/profile` と `evidence_class` を requirements にも明示して、design だけが先走らないように揃えてある。

次の自然なタスクは 2 つある。`foundation/tasks.md` を書いて asset 移植単位まで分解するか、その前に multi-feature の `design alignment gate` として `runtime/evaluation` 側 design へ入って shared field の整合を取るかだ。今回はまだ文書設計だけで、テスト実行はしていない。



```
合意した規約に沿って考えるならマルチフィーチャーの設計が先。その前に、この開発では多数のファイルが生成される、どの文書が何でどこにあるのか、インデクスファイルを作り管理して
```

index を作成して、README から辿れるようにした。

追加・更新したのは次だ。
- [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md)
- [README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/README.md)

`DOCUMENT_INDEX.md` には、
- 文書階層
- ルート文書の役割
- `intent/` と `operations/` の正本一覧
- `.kiro/specs/` の feature 一覧と各ファイルの意味
- `docs/` の横断メモ一覧
- `runtime/`, `experiments/`, `learning/`, `paper/` など artifact directory の役割
- 正本と補助資料の区別
- index 自体の更新ルール
を入れてある。

これで、次は合意どおり `foundation` を深掘りせず、マルチフィーチャーの design を横に進める段階に入れる。自然な次タスクは `runtime`、`evaluation`、`self-improvement`、`paper-interface` の `design.md` を順に起こし、その後に `design alignment gate` を実施することだ。



```
順次進める
```

`runtime design` を起こした。更新したのは次だ。
- [dual-reviewer-runtime/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/design.md)
- [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md)

今回の design では、`1 run = 1 directory` の artifact layout、`Step A/B/C/D` の実行境界、`treatment` と `phase_profile` の分離、`decision unit` による human judgment 連携、`freeze -> validate -> annotate` の run close 順序まで固定した。これで runtime が downstream に渡す evidence の形がかなり明確になった。

次はこの runtime を受ける [dual-reviewer-evaluation/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/design.md) を起こす段階だ。今回は文書設計のみで、テスト実行はしていない。



```
次へ
```

`evaluation design` を起こした。更新したのは次だ。
- [dual-reviewer-evaluation/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/design.md)
- [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md)

今回の design では、`experiments/runs/` と `experiments/analysis/` を明確に分け、`valid / invalid / exploratory / analysis_blocked` の分類、3 tier の metric model、`exclusion_report` と `caveat_register` を first-class artifact として定義した。これで evaluation は raw run を触らずに downstream 向け analysis output を出せる形になった。

次は [dual-reviewer-self-improvement/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/design.md) に進む。ここで proposal、backtest、approval、rollback の artifact flow を固める。



```
次は？
```

次は `self-improvement design` だ。

順番として自然な理由は、いま
- `foundation` が shared contract を持ち
- `runtime` が raw evidence を作り
- `evaluation` が analysis artifact を作る  
ところまで揃ったからだ。次に `self-improvement` を書くと、
- 何を改善入力として受けるか
- proposal をどこに保存するか
- replay / backtest が何を読むか
- approve / reject / rollback をどう記録するか  
を、前の 2 feature に接続した形で決められる。

その次が `paper-interface design`、その後に `design alignment gate` になる。つまり進行順は、
1. `self-improvement design`
2. `paper-interface design`
3. multi-feature `design alignment gate`
4. その後に tasks wave

進めるなら、このまま `self-improvement design` を起こす。



```
次へ
```

`self-improvement design` を起こした。更新したのは次だ。
- [dual-reviewer-self-improvement/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/design.md)
- [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md)

今回の design では、`learning/` 配下の artifact layout、`review_quality / workflow_failure / evidence_quality` の input class、proposal unit、`replay / backtest / manual_review` の test mode、`approved` と `adopted` の分離、rollback registry まで固定した。これで改善 loop が ad-hoc なメモ追加ではなく、proposal ベースの formal flow になった。

次は [dual-reviewer-paper-interface/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/design.md) を起こす段階だ。design wave をこれで揃え、その後に `design alignment gate` を実施する。



```
次へ
```

`paper-interface design` を起こした。更新したのは次だ。
- [dual-reviewer-paper-interface/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/design.md)
- [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md)

これで design wave は 5 feature 分ひと通り揃った。`paper-interface` では、`claim_map.json`、`evidence_register.json`、figure/table bundle、paper-facing caveat register を定義し、paper layer が evaluation の consumer に徹する構造を固定した。runtime や evaluation の rule を paper 都合で逆流的に変えない境界も明文化してある。

次は `design alignment gate` だ。ここで 5 feature を横断して、
- artifact placement
- metadata / field naming
- valid / invalid / exploratory の扱い
- replay / backtest / paper への受け渡し
- versioning と authority boundary  
を確認して、齟齬を潰してから tasks wave に進む。



```
次は調整
```

`design alignment gate` を実行して、結果を [cross-spec-design-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/cross-spec-design-alignment.md) にまとめた。あわせて small fix を 2 件入れてある。

更新したのは次だ。
- [docs/cross-spec-design-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/cross-spec-design-alignment.md)
- [dual-reviewer-runtime/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/design.md)
- [dual-reviewer-paper-interface/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/design.md)
- [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md)

今回の調整で揃えたのは、`raw evidence / analysis / learning / paper` の保存境界、`run-level sign-off` と `finding-level decision` の分離、`maturity label` と `caveat` の分離だ。残件は `runtime-owned profile configuration` の置き場、`evaluation` の最小 metric set の最終確定、`proposal` と repo version update の接続などで、tasks フェーズで詰める detail に落ちた。

次は合意した手順どおり `tasks wave` に入る。順序としては、まず [dual-reviewer-foundation/tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/tasks.md) を再構築方針に合わせて具体化し、その後 `runtime`、`evaluation`、`self-improvement`、`paper-interface` の tasks を横に揃え、最後に `tasks alignment gate` を行うのが自然だ。今回は文書調整のみで、テスト実行はしていない。



```
DOCUMENT_INDEX.mdのリンクが更新されていない
```

`DOCUMENT_INDEX.md` のリンクを更新した。主な修正は 2 点だ。

- `.kiro/specs/` の一覧を、directory リンクではなく各 feature の `requirements.md`、`design.md`、`tasks.md` へ直接飛べる表に変更
- 読み順に [cross-spec-requirements-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/cross-spec-requirements-alignment.md) と [cross-spec-design-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/cross-spec-design-alignment.md) を追加

更新先は [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md) だ。これで spec 正本と alignment 文書へ直接辿れるようになった。



```
具体的に、9. [docs/cross-spec-requirements-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/cross-spec-requirements-alignment.md)のリンクが辿れない
```

その箇所を修正した。原因はリンク先ではなく、リンクラベルに `docs/...` の path 文字列をそのまま入れていたことだと思われる。

現在は [cross-spec-requirements-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/cross-spec-requirements-alignment.md) と [cross-spec-design-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/cross-spec-design-alignment.md) の形に直してある。これで辿れるはずだ。



```
次は
```

次は `tasks wave` に入る。

順序は合意した通りでよい。
1. [dual-reviewer-foundation/tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/tasks.md) を再構築方針に合わせて具体化する
2. その後に `runtime`、`evaluation`、`self-improvement`、`paper-interface` の `tasks.md` を順に起こす
3. 最後に `tasks alignment gate` を実施して、実装順序、共有 artifact 移行、test sequencing を揃える

いま一番自然なのは `foundation tasks` から始めることだ。ここで
- shared asset の実移植単位
- schema / prompt / pattern / validator contract の作成順
- metadata contract の具体 artifact 化
をタスクに落とす。進めるならそのまま `foundation/tasks.md` を更新する。



```
その前に確認。システムの有効性を評価する指標はどうなっている？
```

現状は「評価指標の枠組みは定義済み、最終指標セットは未確定」だ。

いま `evaluation` で入っているのは、[requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/requirements.md) と [design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/design.md) にある次の骨格だ。

1. 前提指標
- `valid / invalid / exploratory` の分離
- exclusion 件数と理由
- caveat の保持

2. 比較軸
- treatment 比較
  - `single`
  - `dual`
  - `dual+judgment`
- phase 比較
  - `intent`
  - `requirements`
  - `design`
  - `tasks`

3. 現在の最小 metric set
- run-level
  - `total findings`
  - `accepted findings`
  - `rejected findings`
  - `deferred findings`
  - `validation outcome`
- finding-level
  - `severity distribution`
  - `source-role distribution`
  - `judgment label distribution`
- treatment-level
  - `findings per run`
  - `acceptance ratio`
  - `judgment invocation coverage`

ただし、これはまだ「初版 minimum metric set」だ。[cross-spec-design-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/cross-spec-design-alignment.md) にも残件として書いた通り、`treatment-level metric の必須集合` はまだ最終確定していない。

重要なのは、現状の指標は主に
- system が比較可能な形で動いているか
- `dual-reviewer` が `single` より多く・違う性質の指摘を出しているか
- `design/tasks` で価値が高そうか
を見るためのものだという点だ。  
一方で、まだ弱いのは「真の有効性」の中心指標だ。たとえば、
- 人間 review または後続修正を基準にした precision 相当
- missed issue を含む recall 相当
- accepted finding の実害回避寄与
- 過剰修正の抑制量
- コスト / latency あたりの有効性
は、まだ設計に十分落ちていない。

つまり現状の整理はこうなる。
- できている: 比較実験用の構造、分類、最小集計
- まだ未確定: 「有効だった」と最終主張するための本命指標

次にやるべきことは、`evaluation tasks` に入る前に、有効性指標を次の3群に整理して固定することだ。
- 品質指標
  - precision 相当、recall 相当、過剰修正抑制
- 運用指標
  - valid run rate、analysis blocked rate、sign-off completion
- 効率指標
  - time / cost / finding あたりの効率

必要なら次で、この「有効性評価指標セット」を明文化して `evaluation` spec に追記する。



```
追記。それと、現在の指標はdesign中心に決められた経緯があるはず。requirements, tasks, impl, intentへの適用。各フェーズで異なる指標になるかもしれない
```

追記した。更新したのは次だ。
- [dual-reviewer-evaluation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/requirements.md)
- [dual-reviewer-evaluation/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/design.md)
- [INTENT.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/INTENT.md)

反映したポイントは2つある。

1. 現在の metric 骨格は `design` 中心の経緯を持つことを明記した。  
2. 各 phase で有効性指標が変わりうる前提を入れた。  
`evaluation` では新たに `Phase-Specific Effectiveness Metrics` を requirements に追加し、design では
- 共通の `core metric layer`
- phase ごとの `overlay metric layer`
の 2 層で考える方針にした。

現時点の整理としては、
- 共通指標は残す
- ただし `intent`、`requirements`、`design`、`tasks`、将来の `implementation-oriented review` で主指標は変わりうる
- その selection を derived artifact に明示する
という形になった。

次にやるべきは、`evaluation` の tasks に入る前に、phase ごとの overlay 指標の初版を具体化することだ。これを先にやると、後の tasks や実験計画がぶれにくい。



```
run-level / finding-level / treatment-level metric の違いは何？
```

違いは「何を1単位として測るか」だ。

- `run-level metric`
  - 1回の review session 全体を1単位として測る
  - 例: `total findings`, `accepted findings`, `validation outcome`
  - 見たいもの: その run 全体がどうだったか

- `finding-level metric`
  - 個々の指摘を1単位として測る
  - 例: `severity distribution`, `source-role distribution`, `judgment label distribution`
  - 見たいもの: どんな種類の指摘が出たか、質や性質はどうか

- `treatment-level metric`
  - `single` / `dual` / `dual+judgment` のような実験条件を単位として測る
  - 例: `findings per run`, `acceptance ratio`, `judgment invocation coverage`
  - 見たいもの: どの treatment が相対的に有効か

整理すると、
- `run-level` は「1回ごとの出来」
- `finding-level` は「指摘1件ごとの性質」
- `treatment-level` は「条件群どうしの比較」
になる。

たとえば `dual+judgment` が良かったかを見るとき、
- run-level では「1 run あたり accepted findings が多いか」
- finding-level では「critical な finding が増えたか」
- treatment-level では「`single` より acceptance ratio が高いか」
をそれぞれ見る。

さらに言うと、これらは競合ではなく階層が違う。  
`treatment-level` の比較は、下で `run-level` や `finding-level` を集約して作る。



```
つまり、あるエビデンスを異なる視点から見た場合のインデクスのようなもの？
```

概ねその理解でよい。

ただし、単なる「別視点のラベル」より少し強い。  
これは同じ evidence を、**集約単位の違う3つの窓から見る**ための区分だ。

- `finding-level`
  - 個々の指摘を見る窓
- `run-level`
  - その指摘群を含む1回の review session 全体を見る窓
- `treatment-level`
  - 複数 run をまとめて、実験条件ごとの差を見る窓

つまり同じ raw evidence から出発するが、
- 1件の finding に注目するか
- 1回の run に注目するか
- 条件群全体に注目するか
で index を切り替えている。

イメージとしては、
- raw evidence = 元データ
- `finding-level / run-level / treatment-level` = その元データへの異なる集約ビュー
だ。

なので「異なる視点から見たインデクス」という言い方で大きくは間違っていない。より正確には、  
**同じ evidence に対する異なる分析粒度のインデクス**  
と言うのが近い。



```
元になる正本のエビデンスはどうやって収集保持する？
```

正本の evidence は、`runtime` が 1 run ごとに生成する raw artifact を基準に収集・保持する。

中心になるのは [dual-reviewer-runtime/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/design.md) で定義した `experiments/runs/<run_id>/` だ。ここに raw evidence を保存し、後段の `evaluation`、`self-improvement`、`paper-interface` は原則これを直接改変しない。

保持の基本形はこうなる。
- `run_manifest.yaml`
  - run metadata の正本
- `review_case.json`
  - machine-readable な run 全体の正本
- `steps/*.json`
  - Step A/B/C/D の step-level raw evidence
- `decisions/decision_units.json`
  - finding と human decision の接続
- `decisions/human_signoff.json`
  - run-level sign-off
- `validation/validator_result.json`
  - validator 結果
- `validation/invalidation_markers.json`
  - invalidation 情報

重要なのは 3 原則だ。
1. raw evidence は `experiments/runs/` に保存する  
2. raw evidence は immutable とする  
3. validation や invalidation は上書きではなく別 artifact として重ねる  

つまり、収集は runtime 実行時に行い、保持は `run_id` 単位の directory に閉じ込める。  
その上で、
- `evaluation` は `experiments/analysis/` に派生物を作る
- `self-improvement` は `learning/` に proposal や backtest を作る
- `paper-interface` は `paper/` に reporting artifact を作る  
という分離になる。

要するに、正本 evidence の収集保持は  
**`runtime` が `experiments/runs/<run_id>/` に raw artifact を凍結保存することで行う**  
という設計だ。



```
具体的に各jsonファイル、yamlファイルに記載すべき内容や構造についてはどの段階で決めるか？
```

それは主に `design` で決め、`tasks` で実装単位に固定し、最終的に implementation で schema と template に落とす。

段階ごとに分けるとこうなる。

1. `requirements`
- 何の artifact が必要か
- 何を表現できなければならないか
- 必須の概念は何か  
を決める段階だ。  
例:
- `review_case` が必要
- `finding` に human decision linkage が必要
- metadata に `phase_profile` と `evidence_class` が必要

この段階では、まだ各 JSON/YAML の厳密な shape までは決めきらない。

2. `design`
- どのファイルを作るか
- どこに置くか
- top-level structure をどうするか
- 必須 field、enum、参照関係をどうするか  
を決める段階だ。

つまり、**各 json / yaml の内容と構造を具体化する中心段階** がここだ。  
たとえば今やっているのはまさにこれで、
- `run_manifest.yaml`
- `review_case.json`
- `decision_units.json`
- `validator_result.json`
- `claim_map.json`
- `proposal.yaml`
の役割と最低限の field を設計している。

3. `tasks`
- その設計をどういう順で実ファイル化するか
- どの schema を先に作るか
- validator とテストをどう組むか  
を決める段階だ。

この段階では、
- `review_case.schema.json` を作る
- `metadata_contract.yaml` を作る
- `invalidation_marker.schema.json` を作る  
のように、実装作業単位へ落とす。

4. implementation
- 実際に `.schema.json` や `.yaml` を書く
- サンプルデータや validator を通す
- 必要なら design に戻って微修正する  
段階だ。

要するに、
- **requirements**: 必要性を決める
- **design**: 構造を決める
- **tasks**: 作業順序を決める
- **implementation**: 実ファイルにする

なので、あなたの質問に直接答えると、  
**各 JSON/YAML ファイルに何を書くか、どういう構造にするかは design フェーズで決めるのが基本** だ。  
そのうえで multi-feature 開発なので、個別 design だけでなく `design alignment gate` で feature 間整合も取る必要がある。



```
先ほど、requirementに遡って修正が入ったと思うが、その場合、フィーチャー間の調整チェックはしたか？
```

厳密には、修正直後には full のフィーチャー間調整チェックはしていなかった。`evaluation` と `INTENT` の局所整合だけ見て反映していた。

ただ、いま横断確認は実施した。見た範囲は、
- [dual-reviewer-evaluation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/requirements.md)
- [dual-reviewer-evaluation/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/design.md)
- [INTENT.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/INTENT.md)
- 既存の [cross-spec-requirements-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/cross-spec-requirements-alignment.md)
- [cross-spec-design-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/cross-spec-design-alignment.md)
- 関連する `foundation` / `runtime` / `self-improvement` design

確認結果としては、blocking な矛盾は出ていない。理由は、今回の修正が
- `evaluation` に phase-specific metrics を導入する
- `INTENT` に phase ごとで有効性指標が変わりうることを明記する
という拡張であって、既存の shared contract
- `phase_profile`
- `treatment`
- `run_status`
- `evidence_class`
- runtime artifact layout  
を壊していないからだ。

現時点の残件は矛盾ではなく、未確定事項だ。
- phase-specific overlay metric の初版確定
- `implementation-oriented review` を正式な phase として扱うかどうか
- その場合 `phase_profile` enum に入れるか、別 profile 扱いにするか

要するに、
- 修正直後には full チェック未実施
- 今は横断確認済み
- blocking inconsistency はなし
- ただし `implementation-oriented review` の位置づけは次の設計判断として残っている

必要なら次で、この点を alignment 文書にも追記する。



```
遡上して修正するパターンは必ず発生する。そのゲーティングとして、フィーチャー間の調整チェックを強制すること
```

強制ルールとして反映した。更新したのは次だ。
- [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md)
- [TRACEABILITY.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/TRACEABILITY.md)

入れた内容は、
- 後続 phase に進んだ後でも、`intent`、`operations`、`requirements`、`design`、`tasks` に遡上修正が入ったら、対応する cross-spec alignment を必ず再実施する
- `requirements` 修正なら `requirements alignment gate`
- `design` 修正なら `design alignment gate`
- `tasks` 修正なら `tasks alignment gate`
- `intent/operations` 修正でも、影響先 phase に応じて再調整を必須にする
- 再調整未実施のまま次 phase へ進むのは workflow 逸脱とみなす
というものだ。

これで今後は「局所修正したが横断整合は見ていない」という状態を process 上で禁止できる。



```
当然、上位フェーズに修正が入ったら、終了済みの下流フェーズも再チェック
```

そのルールとして反映した。更新したのは次だ。
- [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md)
- [TRACEABILITY.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/TRACEABILITY.md)

追加した要点は明確だ。
- 上位フェーズに修正が入ったら、下流フェーズは「完了済み」のままにしない
- `requirements` 修正なら、完了済みの `design/tasks` も reopen して再確認
- `design` 修正なら、完了済みの `tasks` も reopen して再確認
- `intent/operations` 修正なら、影響下の `requirements/design/tasks` を reopen して再確認
- 再確認が終わるまで下流フェーズは確定扱いしない

これで、遡上修正が入ったときに「該当文書だけ直して先へ進む」ことを process 上で禁止できる。



```
cc-sddの流儀だとspec.jsonで管理することになっているね
```

その通りだ。`cc-sdd` の流儀に従うなら、phase 状態や承認状態は最終的に `spec.json` で管理するのが正しい。

今までこちらが主に触っていたのは
- `requirements.md`
- `design.md`
- `tasks.md`
- alignment 文書
だったが、process を厳密に回すなら、遡上修正で phase を reopen した事実も `spec.json` に反映すべきだ。

実務上は少なくとも次を `spec.json` で持つのがよい。
- 現在 phase
- requirements/design/tasks の承認状態
- reopen 状態
- 最後に通した alignment gate
- 上流修正の影響で再確認待ちかどうか

特に今回あなたが入れたルールと整合させるなら、
- 上位 phase 修正
- 下流 phase reopen
- 再調整未完了  
を `spec.json` で見える化しないと、文書だけでは運用漏れが出る。

なので次にやるべきことは 2 つだ。
1. `spec.json` の管理項目を確認する  
2. 今決めた reopen / recheck ルールを `spec.json` 運用に反映する

必要なら次で、各 feature の `spec.json` を確認して、今回の workflow に合う管理方式へ揃える。



```
揃えて
```

`spec.json` を5 feature すべてで揃えた。

更新したのは次だ。
- [foundation/spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/spec.json)
- [runtime/spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/spec.json)
- [evaluation/spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/spec.json)
- [paper-interface/spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/spec.json)
- [self-improvement/spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/spec.json)

揃えた内容は共通で、
- `phase`
- `approvals.requirements/design/tasks`
  - `generated`
  - `approved`
  - `reopened`
  - `last_updated`
- `alignment.requirements/design/tasks`
  - `required`
  - `status`
  - `last_checked`
  - `note`
- `recheck`
  - `upstream_change_pending`
  - `impacted_downstream_phases`
  を持つ形にしてある。

現状は全 feature で
- `phase = design`
- `requirements/design = generated`
- `tasks = pending`
- `requirements/design alignment = completed`
- `tasks alignment = pending`
として記録した。

次から遡上修正が入ったら、この `spec.json` 側でも
- `reopened = true`
- `upstream_change_pending = true`
- `impacted_downstream_phases` の更新  
までセットでやるのが正しい運用になる。



```
ただし、cc-sddでも読める形にしておかないといけない。既に実行済みの例は.kiro/specs/rwiki-v2-foundation/spec.jsonにある
```

その点を反映して、`cc-sdd` が読めるコア形に揃え直した。

既存例 [rwiki-v2-foundation/spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/rwiki-v2-foundation/spec.json) に合わせて、各 `spec.json` を次の形にした。
- `feature_name`
- `created_at`
- `updated_at`
- `language`
- `phase`
- `approvals`
  - `requirements.generated/approved`
  - `design.generated/approved`
  - `tasks.generated/approved`
- `ready_for_implementation`

その上で、こちらが追加で管理したい reopen / alignment / recheck 情報は、`custom` 配下に退避した。これなら
- `cc-sdd` が見るであろう主要キーは既存例と同形
- こちらの運用情報も失わない
という両立になる。

更新したのは次だ。
- [foundation/spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/spec.json)
- [runtime/spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/spec.json)
- [evaluation/spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/spec.json)
- [paper-interface/spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/spec.json)
- [self-improvement/spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/spec.json)

現状の phase は全 feature で `design-generated` にしてある。まだ human approval は通していないので、`approved` はすべて `false`、`ready_for_implementation` も `false` だ。



```
docs/レビューシステム検討.mdにレビューシステム開発初期の頃に議論した経緯がある。参考になりそうなものはあるか
```

ある。かなりある。特にいまの再構築に直接効く論点がいくつか明確に見える。

有用度が高いものは次だ。

- 一般化可能部分と project 固有部分の 3 層分離
  - [docs/レビューシステム検討.md](/Users/Daily/Development/Rwiki-dev/docs/レビューシステム検討.md)
  - `Layer 1 = 完全一般`, `Layer 2 = メタパターン`, `Layer 3 = project 固有` という整理は、そのまま今の `foundation / runtime / learning` 分離に使える
  - 特に「project 固有知識はログから抽出してスキーマ化する」という方向性は、今の self-improvement と pattern asset 設計に直結する

- 23 パターンをメタ群へ抽象化する発想
  - これは単なる昔話ではなく、`seed_patterns.yaml` や将来の pattern schema の設計根拠になる
  - 「具体事例は project 固有、メタ群は一般化可能」という区別は再利用価値が高い

- ログ -> 抽出 -> スキーマ化 のパイプライン案
  - review session ログを構造化し、そこから escalate 事例を抽出し、pattern schema に落とす案はかなり有用
  - これは今の `learning/findings/` と `learning/proposals/` の間に入る前処理として再利用できる

- 10 ラウンド並列化 + 整合性ラウンドの議論
  - 今回の再構築ではまだ runtime 最小構成が先だが、将来の performance 改善案として価値がある
  - ただし現段階では実装要件ではなく、`Phase 2` 以降の拡張候補として扱うのが妥当

- 人間 gate を残すべきという結論
  - これは今の `TRUST_BOUNDARY.md` や `HUMAN_WORKFLOW.md` と整合していて、方針確認として有効

一方で、そのまま持ち込まない方がよいものもある。

- `memory` 中心の実装前提
  - 今回は repo 外 memory を排除する方針なので、そのままは使わない
- Rwiki 固有の round 設計や spec 番号ベースの具体例
  - reference としては有用だが、正本にはしない
- 設計レビュー中心の前提
  - 今回は `intent / requirements / tasks / 将来の implementation-oriented review` まで含めるため、そのまま一般理論化しない

要するに、この文書から持ち出すべき核は3つだ。
- 一般層 / メタ層 / project 固有層の分離
- ログから固有知識を抽出して schema 化する発想
- 並列 review と整合性ラウンドの将来構想

必要なら次で、この文書から「新 repo に継承する論点一覧」を [docs/](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs) に1枚まとめる。



```
はい
```

初期議論から継承する論点をまとめた。追加したのは次だ。
- [legacy-discussion-carryover.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/legacy-discussion-carryover.md)
- [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md)

この memo では、
- 3 層分離
  - 一般層 / メタ層 / project 固有層
- ログから知識を抽出して schema 化する発想
- 23 パターンのメタ群化の原則
- human-in-the-loop を残す判断
- 将来の並列化構想
を「継承する論点」として整理した。

一方で、
- repo 外 memory 中心の実装
- Rwiki 固有 round や spec 番号への依存
- design 固定の評価観
は「今回は採用しない前提」として切り分けてある。これで legacy 議論を参照しつつ、正本にそのまま混入するのを防げる。



```
現在の案に即採用のものは？
```

即採用なのは次の4点だ。

- 3 層分離
  - 一般層 / メタ層 / project 固有層
  - これはすでに `foundation / pattern assets / learning` の考え方に入っている

- project 固有知識はログから抽出して artifact 化する
  - repo 外 memory ではなく、`experiments/runs/` と `learning/` から抽出して蓄積する方針
  - これは self-improvement と pattern schema 設計の前提になる

- 具体パターンとメタパターンを分ける
  - 具体事例は project 固有
  - 抽象化したメタ群は再利用候補
  - これは今後 `seed_patterns.yaml` や pattern schema を作るときに即使う考え方だ

- human-in-the-loop を残す
  - 完全自動承認に寄せず、人間 gate を残す
  - これはすでに `TRUST_BOUNDARY.md` と `HUMAN_WORKFLOW.md` に反映済み

逆に、今すぐは採らないが将来候補なのは、
- 10 ラウンド並列化
- portable starter kit 化
だ。

つまり、即採用は
- `構造の分離`
- `知識抽出の方向`
- `パターンの二層化`
- `人間 gate`
の4つだ。



```
では、順次4つの項目を整合させながら採り入れよう
```

4項目を現行案へ採用する形で反映した。更新したのは次だ。
- [DESIGN_PRINCIPLES.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/DESIGN_PRINCIPLES.md)
- [dual-reviewer-foundation/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/design.md)
- [dual-reviewer-self-improvement/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/design.md)
- [legacy-discussion-carryover.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/legacy-discussion-carryover.md)

反映内容はこうだ。

- 3 層分離
  - `general / meta / project-specific` を設計原則に追加した
- project 固有知識は evidence から抽出
  - self-improvement design に `Project-Specific Pattern Extraction` を追加した
- 具体パターンとメタパターンの分離
  - foundation design に、pattern asset を layer で分けて扱う考え方を追加した
- human-in-the-loop
  - これはすでに運用文書に入っていたので、今回の採用項目として legacy memo 側に明示した

この4つはもう「参考」ではなく、現行の設計原則として扱ってよい状態になった。次に進むなら、この採用方針を前提に `tasks wave`、特に `foundation tasks` と `self-improvement tasks` を具体化するのが自然だ。



```
指針に従えば、designでの修正がはいったら、どうする？
```

`design` に修正が入ったら、`design phase` を reopen して、`design alignment gate` を再実施する。

さらに、その修正が下流に影響するので、
- 完了済みの `tasks` は確定扱いを外す
- `tasks` も reopen 対象として再確認する  
が必要になる。

流れはこうだ。
1. 修正した `design.md` を更新する  
2. 該当 feature の `spec.json` で
   - `updated_at` を更新
   - 必要なら `custom.reopened.design = true`
   - 下流影響があるなら `custom.recheck.upstream_change_pending = true`
   - `custom.recheck.impacted_downstream_phases` に `tasks` を入れる  
3. `cross-spec-design-alignment.md` を再確認または更新する  
4. 影響がある `tasks` を reopen して見直す  
5. その後で `tasks alignment gate` をやり直す  
6. 再確認が終わるまで次に進まない

要するに、`design` 修正は
- その feature だけのローカル修正で終わらせない
- 横断整合を再確認する
- 下流 `tasks` も再チェックする  
という扱いになる。



```
実行
```

実行した。`design` 修正時の再開手順を repo に固定した。

更新したのは次だ。
- [cross-spec-design-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/cross-spec-design-alignment.md)
- [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md)

追加した `Design Reopen Procedure` では、
1. `design.md` を更新
2. `spec.json` を更新
   - `updated_at`
   - `custom.reopened.design = true`
   - 必要なら `custom.recheck.upstream_change_pending = true`
   - `custom.recheck.impacted_downstream_phases` に `tasks`
3. この alignment 文書を再確認・追記
4. 完了済み `tasks` を reopen
5. 再確認後にのみ `tasks alignment gate` へ進む
という手順を明文化した。

これで「design を直したが、下流や横断整合は見ていない」を process 上で禁止できる。



```
同様な文書をreqquirements, tasks, implの各フェーズでも必要か
```

必要だ。少なくとも `requirements`、`design`、`tasks` には必要で、`implementation` は少し性質が違うが、対応する横断記録はあった方がいい。

整理するとこうなる。

- `requirements`
  - 必須
  - shared contract、責務境界、指標前提がずれやすい
  - すでに [cross-spec-requirements-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/cross-spec-requirements-alignment.md) がある

- `design`
  - 必須
  - artifact 配置、metadata、受け渡し境界がずれやすい
  - すでに [cross-spec-design-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/cross-spec-design-alignment.md) がある

- `tasks`
  - 必須
  - 実装順序、共有 artifact の移行タイミング、test sequencing が衝突しやすい
  - まだ未作成なので、`cross-spec-tasks-alignment.md` を作るべき

- `implementation`
  - ある方がよい
  - ただし `requirements/design/tasks` と同じ性格ではない
  - ここで見るのは「仕様整合」より
    - 実装進捗
    - shared file の競合
    - validator/test の実装順
    - spec.json 状態
    - reopen の発生
    になる

だから `implementation` では、名前も少し変えた方がいい。例えば、
- `cross-spec-implementation-integration.md`
または
- `implementation-coordination-log.md`
のような文書が適切だ。

結論としては、
- `requirements / design / tasks` は phase ごとの alignment 文書を持つべき
- `implementation` も必要だが、alignment memo というより coordination / integration log として持つのが自然  
となる。

次にやるなら、
1. `cross-spec-tasks-alignment.md` の skeleton を作る
2. `implementation-coordination-log.md` の skeleton も先に作る
  の順がよい。



```
実行
```

追加した。新しく作ったのは [cross-spec-tasks-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/cross-spec-tasks-alignment.md) と [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/implementation-coordination-log.md) で、`tasks` は alignment memo、`implementation` は coordination log として役割を分けた。

あわせて [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md)、[HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md)、[TRACEABILITY.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/TRACEABILITY.md) も更新し、`design` 文書に `tasks` 記録を混在させる古い記述を除去した。これで phase ごとの横断管理先は次で固定された。

- `requirements`: [cross-spec-requirements-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/cross-spec-requirements-alignment.md)
- `design`: [cross-spec-design-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/cross-spec-design-alignment.md)
- `tasks`: [cross-spec-tasks-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/cross-spec-tasks-alignment.md)
- `implementation`: [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/implementation-coordination-log.md)

次は予定どおり `tasks wave` に入ってよい。最初は [dual-reviewer-foundation/tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/tasks.md) の具体化から進めるのが自然だ。



```
ここで、1回立ち止まろう。当初のリビルドから、いくつかの観点で機能が追加された。少なくともrequirementsレベルでの整合はとったが、INTENTからrequirementsへの流れが追えるか？
```

現状は、**粗い粒度では追えるが、requirements 単位ではまだ弱い**。

追える部分はある。  
- `INTENT` の「再現可能性」は [dual-reviewer-foundation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/requirements.md) の metadata / repo-contained / prompt traceability に落ちている  
- 「runtime と evaluation / paper の分離」は [dual-reviewer-runtime/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/requirements.md)、[dual-reviewer-evaluation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/requirements.md)、[dual-reviewer-paper-interface/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/requirements.md) に落ちている  
- 「自己改善の形式化」は [dual-reviewer-self-improvement/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/requirements.md) に落ちている  
- 「phase ごとの価値差」は [dual-reviewer-runtime/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/requirements.md) の phase-aware profile と [dual-reviewer-evaluation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/requirements.md) の phase-aware / phase-specific metrics に反映されている

ただし弱い点がある。  
今の [TRACEABILITY.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/TRACEABILITY.md) は `intent -> spec` の対応まではあるが、**`intent の節 -> 各 requirement` の 1対多対応表** にはなっていない。なので、
- `INTENT` に後から足した観点が、どの requirement に入ったか
- 逆に、ある requirement がどの intent を受けているか
を機械的には追いにくい。

結論としては、**方向としては追えるが、監査可能な形ではまだ不十分**だ。  
次にやるべきは、`INTENT -> requirements trace matrix` を作ることだ。形としては、
- `INTENT` の主要命題
- 対応する spec
- 対応する requirement
- 対応の種類
  - `direct`
  - `supporting`
  - `deferred`
- ギャップ有無

を1枚にするのがよい。これを作れば、今回追加された観点まで含めて流れを明示できる。



```
作成するのはいいが、改変があるたびにアップデートしないと、間違った情報を見ることになる。アップデートすべきトリガーを書いておく
```

更新トリガーを明文化した。反映先は [TRACEABILITY.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/TRACEABILITY.md)、[HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md)、[DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md) だ。

主な内容は、
- `INTENT.md` の主要命題変更
- `NON_GOALS.md` / `DESIGN_PRINCIPLES.md` の requirement 影響変更
- `operations/` 変更で requirement 前提が変わる場合
- いずれかの `requirements.md` の追加・削除・統合・意味変更
- feature の新設・統合・廃止
- requirements alignment による責務移管
- implementation 中に requirement 不足や intent 未接続 requirement が見つかった場合

を、trace matrix 更新必須トリガーとして固定したことだ。逆に typo 修正や design/tasks のみの変更など、更新不要なケースも分けてある。

これで matrix を作っても stale になりにくい。次にやるなら、そのルールに従う `intent-to-requirements-trace-matrix.md` 自体を作る段階に進める。



```
他にもトリガーを記載すべき文書はあるか？
```

ある。少なくとも次の4か所には入れておいた方がいい。

- 各 feature の `spec.json`
  - `requirements` が reopen された理由として、`trace matrix update required` を持てるようにする
  - そうしないと `cc-sdd` 側の phase 状態と trace matrix の更新義務が分離する

- `docs/cross-spec-requirements-alignment.md`
  - requirements alignment の結果として matrix 更新が必要になった場合を明記する
  - ここは trigger の発火源になりやすい

- 将来作る `intent-to-requirements-trace-matrix.md` 本体
  - 文書冒頭に「この文書を更新すべきトリガー」を自分で持たせるべき
  - 参照先だけに書くと運用漏れが出る

- `README.md`
  - 詳細な trigger 一覧までは不要だが、「intent / requirements を変えたら trace matrix を更新する」という入口レベルの注意は入れた方がよい

優先度を付けるとこうだ。
1. `intent-to-requirements-trace-matrix.md`
2. `cross-spec-requirements-alignment.md`
3. 各 `spec.json`
4. `README.md`

逆に、今すぐ必須ではないのは
- `design` / `tasks` alignment 文書
- `implementation-coordination-log`
だ。ここにも波及しうるが、trace matrix の更新義務そのものは `requirements` 周辺で管理する方が自然だ。

次に進めるなら、
- `intent-to-requirements-trace-matrix.md` を作る
- 同時に `cross-spec-requirements-alignment.md` と各 `spec.json` に trigger 連動を反映する
のがよい。





```
OK
```

反映した。新しく [intent-to-requirements-trace-matrix.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/intent-to-requirements-trace-matrix.md) を作成し、`INTENT` の主要命題と各 feature の requirement の対応を `direct / supporting / deferred / gap` で追えるようにした。

あわせて、
- [cross-spec-requirements-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/cross-spec-requirements-alignment.md)
- [README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/README.md)
- [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md)
- 5つの [`spec.json`](</Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs>)
を更新して、trace matrix 更新義務を requirements 周辺の運用に接続した。`spec.json` には `custom.traceability` を追加し、matrix の更新要否を feature ごとに持てるようにしてある。

これで `INTENT -> requirements` は「追える」だけでなく、変更時にどこを更新すべきかも管理できる状態になった。次に進むなら、この matrix を一度基準にして、追加された観点の取りこぼしがないかを改めて点検するのが自然だ。



```
さて、ここで仕様・設計あたりまで進んできているが、既にリファクタリングした方がよい部分はないか
```

ある。実装前の今、文書構造として先に整理した方がよいものが少なくとも4点ある。

1. [intent-to-requirements-trace-matrix.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/intent-to-requirements-trace-matrix.md) の `Requirement` 列に requirements 以外が混ざっている  
`runtime と evaluation / paper の混線を防ぐ` の行で `runtime` 側が `Adjacent expectations` を参照している。これは matrix の contract を崩す。matrix は `requirements` への流れを追う文書なので、参照先は requirement 単位に限定した方がいい。必要なら runtime に明示 requirement を追加するべきだ。

2. trace matrix の更新トリガーが分散し始めている  
いま trigger は [TRACEABILITY.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/TRACEABILITY.md)、[HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md)、[intent-to-requirements-trace-matrix.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/intent-to-requirements-trace-matrix.md)、[README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/README.md) に重複している。このままだと将来ずれる。正本を 1 か所に固定し、他は参照だけにした方がいい。

3. `phase-specific metrics` の説明が上位と下位で重複している  
[INTENT.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/INTENT.md) と [dual-reviewer-evaluation/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/design.md) の両方で、phase ごとに何を測るかをかなり詳細に書いている。これは drift しやすい。`INTENT` は価値命題だけに寄せ、具体的な phase overlay の初版は evaluation spec 側に集約した方が保守しやすい。

4. status 管理の所在が二重化している  
`DOCUMENT_INDEX.md` の status 表現、各 `spec.json` の phase / approvals / traceability、alignment memo の current state がそれぞれ status を持っている。現状でも意味は通るが、更新漏れの温床になる。進行状態の正本は `spec.json`、文書側は説明に留める、と割り切った方がいい。

軽めの改善候補もある。

- [TRACEABILITY.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/TRACEABILITY.md) は原則と matrix 運用が同居しているので、少し肥大化している
- [dual-reviewer-foundation/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/design.md) の 3 層説明と [legacy-discussion-carryover.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/legacy-discussion-carryover.md) の carryover 説明もやや重複している

優先順位を付けるなら、先にやるべきは次の2つだ。  
- trace matrix を requirement-only に正す  
- trace matrix trigger の正本を 1 か所に寄せる

この2つは構造上の不整合なので、tasks wave に入る前に直した方がよい。



```
順次修正
```

1段目の修正を入れた。

- [intent-to-requirements-trace-matrix.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/intent-to-requirements-trace-matrix.md) を `requirements` 専用に修正した
- [TRACEABILITY.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/TRACEABILITY.md)、[HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md)、[README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/README.md) を、trigger 正本を matrix 本体へ寄せる形に直した

具体的には、
- `Adjacent expectations` や `Introduction / Boundary Context` を matrix から外した
- `runtime と evaluation / paper の混線` は `runtime Requirement 4`、`evaluation Requirement 5`、`paper-interface Requirement 4` で受ける形に整理した
- `人が system 全体像を理解できる` も foundation の `Requirement 2` と `Requirement 3` に寄せた
- 外部 evidence intake 非対象は `deferred` として requirement 不在を明示した
- trace matrix 更新トリガーの正本は matrix 本体 `2. 更新必須トリガー` に一本化した

これで最初の2件、
- trace matrix を requirement-only にする
- trigger の正本を 1 か所に寄せる
は解消した。

次は、指摘した3つ目の `phase-specific metrics` の重複整理に進むのが自然だ。



```
他にリファクタリングの観点はないか
```

ある。今すぐ必須ではないが、実装前に見直す価値が高いものがいくつかある。

1. `status` の正本をさらに明確化する  
いま進行状態は `spec.json`、alignment memo、`DOCUMENT_INDEX.md` に分散している。`spec.json` を唯一の status 正本にして、他文書は「説明のみ」に寄せた方が更新漏れが減る。

2. `requirements` と `design` の責務境界をもう少し締める  
一部の spec では、requirements にかなり設計寄りの含意が入っている。特に evaluation は metric overlay の説明が design にも intent にもある。  
原則を強めるなら、
- requirements: 何を満たすべきか
- design: どう表現し、どう配置するか
にさらに寄せたい。

3. `docs/` の横断文書を分類し直す  
いま `docs/` に
- alignment
- migration
- legacy
- traceability matrix
- coordination log
が同居している。  
将来的に増えるなら、
- `docs/alignment/`
- `docs/migration/`
- `docs/legacy/`
- `docs/traceability/`
くらいに分けた方が見通しがよい。

4. `foundation` と `runtime` の境界を再点検する  
今は概ねよいが、phase/profile や step identity の一部は foundation に置くか runtime に置くかでまだ揺れやすい。  
原則として、
- foundation = 全 feature 共通 contract
- runtime = 実行責務
をもう一段厳密にしておくと後で楽になる。

5. `deferred` と `gap` の扱いを統一する  
trace matrix では両方あるが、他文書では明示されていない。  
- `deferred`: 意図的に今やらない
- `gap`: 本来あるべきだが未対応
を repo 全体で同じ意味に固定した方がよい。

6. `phase` という語の使い分けを整理する  
今は
- `cc-sdd` phase
- reviewed phase/profile
- run lifecycle
が全部 phase 系の語で出る。混線しやすい。  
用語を分けるなら、
- `spec phase`
- `review phase/profile`
- `run status`
のように固定した方が安全だ。

7. `artifact` 命名規則を早めに決める  
JSON/YAML が増えるので、
- `*_manifest`
- `*_index`
- `*_register`
- `*_result`
- `*_summary`
の使い分けを先に決めると、実装時に崩れにくい。

優先度で言うと、次に効くのはこの3つだ。
- `status` 正本の一元化
- `phase` 用語の整理
- `artifact` 命名規則の固定

これらは tasks wave に入る前にやると効果が大きい。



```
今やろう
```

やった。共通規約を [CONVENTIONS.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/CONVENTIONS.md) に切り出して、次の3点を正本化した。

- status の正本は各 feature の `spec.json`
- `phase` は `spec phase` / `review phase/profile` / `run status` に分けて使う
- artifact 命名規則は `*_manifest` / `*_index` / `*_register` / `*_result` / `*_summary` で固定する

あわせて [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md)、[README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/README.md)、[DESIGN_PRINCIPLES.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/DESIGN_PRINCIPLES.md)、[HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md) を更新し、この規約を参照する形にそろえた。

これで、さっき挙げた3観点
- status 正本の一元化
- phase 用語の整理
- artifact naming 規則の固定
は一通り片付いた。次に進むなら、残る候補は `phase-specific metrics` の重複整理か、`docs/` の分類整理になる。



```
次の処理
```

次の整理を入れた。`phase-specific metrics` の重複はかなり減った。

- [INTENT.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/INTENT.md)
- [dual-reviewer-evaluation/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/design.md)
- [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md)

具体的には、
- `INTENT` は「phase ごとに主指標が変わりうる」という価値命題だけを保持
- 各 phase の具体的な overlay metric 例や表現方法は `evaluation` spec を正本に集約
- `DOCUMENT_INDEX` にも、その役割分担を明示

これで `INTENT` と `evaluation` の責務境界はかなり明確になった。次に手を入れるなら、残るリファクタリング候補は `docs/` の分類整理か、`foundation` と `runtime` の境界再点検だ。



```
次へ
```

`foundation` と `runtime` の境界を締めた。更新したのは次だ。

- [dual-reviewer-foundation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/requirements.md)
- [dual-reviewer-runtime/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/requirements.md)
- [dual-reviewer-foundation/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/design.md)
- [dual-reviewer-runtime/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/design.md)

主に明確にしたのは、
- foundation は `shared contract` の所有者であり、実行責務は持たない
- runtime は foundation contract の consumer であり、concrete execution を所有する
- `treatment` ごとの step 実行有無
- `phase/profile` ごとの review emphasis
- run directory layout
- step file naming
- prompt override resolution order
- evidence write / validation invocation timing

は runtime 側の責務だ、という点だ。

これで architecture 上の揺れはかなり減った。次に残るリファクタリング候補は、`docs/` の分類整理くらいだ。



```
次へ。整理するとリンク修正も必要かも
```

`docs/` を分類整理して、リンクも追随させた。新しい構成は次だ。

- `docs/alignment/`
- `docs/coordination/`
- `docs/traceability/`
- `docs/migration/`
- `docs/legacy/`

移動した文書は、たとえば
- [cross-spec-requirements-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-requirements-alignment.md)
- [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md)
- [intent-to-requirements-trace-matrix.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/traceability/intent-to-requirements-trace-matrix.md)
- [feature-disposition-judgment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/migration/feature-disposition-judgment.md)
- [legacy-discussion-carryover.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/legacy/legacy-discussion-carryover.md)

だ。あわせて [README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/README.md)、[CONVENTIONS.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/CONVENTIONS.md)、[DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md)、[TRACEABILITY.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/TRACEABILITY.md)、[HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md) などの参照も更新した。旧パス参照は機械確認で残っていない。

次に進むなら、リファクタリング観点としてはだいぶ主要なものを片付けたので、`tasks wave` に戻ってよい状態だ



```
さて、リファクタリングは終わったかな？
```

主要なものは一通り終わった、と見てよい。

片付けたものは次だ。
- `intent -> requirements` traceability の明確化
- trace matrix の trigger 正本化
- `status` 正本を `spec.json` に一元化
- `phase` 用語の整理
- artifact naming 規則の固定
- `foundation` と `runtime` の境界明確化
- `phase-specific metrics` の責務分離
- `docs/` の分類整理とリンク修正

つまり、**実装前に構造的に直すべきもの**はかなり処理できている。

ただし、完全に「もう見直し不要」という意味ではない。残るのは主に次のような、実装に入ってからでないと固まりきらない類だ。
- `tasks wave` を書いたときの task 粒度の揺れ
- JSON/YAML schema の具体 field 設計時の naming 微修正
- `spec.json` 運用が実際に回り始めた後の status 項目の過不足
- evaluation の minimum metric set の最終確定

なので結論は、
- **上位文書と spec 構造のリファクタリングは概ね完了**
- **残りは implementation 準備や tasks 具体化の中で出る局所調整**
だ。

今の段階では、これ以上リファクタリングを続けるより、`tasks wave` に進む方がよい。



```
ところで、現在dual-reviewerを開発しているのだが、このシステム自体もマニュアルでその方法論を適用していくことにしよう
```

方針として反映した。更新したのは次だ。

- [INTENT.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/INTENT.md)
- [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md)
- [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md)

追加した内容は、
- この再構築そのものを `dual-reviewer` の最初の適用対象とする
- 初期段階では完全自動運用ではなく、方法論を手動適用する
- `intent / requirements / design / tasks` を本 repo 自身の review phase/profile として扱う
- そこで得た failure や見落としを spec 修正や self-improvement input に戻す

というものだ。

これで、この repo は「dual-reviewer を作る repo」であると同時に、「dual-reviewer 方法論を最初に手動検証する repo」という位置づけになった。次に進むなら、この前提で `tasks wave` に戻るのが自然だ。



```
いや、実はinetnt, requirements, designのレビューをしてないよね
```

していない。少なくとも、`dual-reviewer` の方法論を明示的に適用した review としては、まだやっていない。

今までやっていたのは主に次だ。
- 文書の起草
- phase 間の整合確認
- feature 間の alignment
- リファクタリング
- traceability 整備

これは品質向上には効いているが、あなたの言う意味での
- `intent review`
- `requirements review`
- `design review`
を、`dual-reviewer` 的な観点で独立した review activity として回したわけではない。

つまり現状は、
- `intent` は書いた
- `requirements` は揃えた
- `design` は揃えた
- しかしそれらを review 対象として正式に点検した記録はない
という状態だ。

この意味で、さっき入れた「本 repo 自身へ手動適用する」という方針は、まだ将来形であって、実績ではない。

次にやるべきことは明確だ。  
`manual dogfooding review wave` を起こすべきだ。

順序はこうなる。
1. `intent review`
2. `requirements review`
3. `design review`

そして各レビューで、
- finding
- concern
- contradiction
- ambiguity
- defer
を記録する。  
その結果、修正が入れば、
- 該当 phase を reopen
- 必要な alignment gate を再実施
になる。

要するに、今の認識は正しい。  
**仕様や設計は整えたが、まだ review していない。**  
次のタスクは、文書作成ではなく `manual review wave` だ。



```
現段階では自動記録の仕組みはないので、マニュアル（あなた）で記録していくしかない。記録としての正本があれば、あとでメトリックは拾えるか？
```

拾える。正本としての記録が一貫していれば、後から多くのメトリックは抽出できる。

ただし条件がある。  
必要なのは「人が読める記録」ではなく、**後で集計可能な形で揃った手動記録**だ。

最低限、各 manual review で次を正本として残せばよい。
- review 対象
  - `intent` / `requirements` / `design`
  - feature 名
  - 文書パス
  - version / date
- review 条件
  - reviewer
  - review date
  - review mode
    - `manual-dual-reviewer-inspired` など
- finding 単位
  - `finding_id`
  - severity
  - category
  - summary
  - rationale
  - affected section
  - suggested action
  - status
    - accepted / rejected / deferred
- review 結果
  - sign-off
  - unresolved concerns
  - reopen 要否
  - downstream recheck 要否

この粒度で残せば、後から少なくとも次は拾える。
- finding 数
- severity 分布
- category 分布
- accepted / rejected / deferred 比率
- phase 別の指摘傾向
- feature 別の問題集中
- reopen 発生率
- unresolved concern 数

逆に、後から拾いにくいのはこれだ。
- 本当の recall
- missed issue 数
- 実害回避量
- review 時間あたり効率  
これらは追加記録が要る。

なので今の段階では、
- 自動記録はない
- でも manual review log を正本として揃えれば、かなりのメトリックは後から取れる
- 重要なのは、今から記録フォーマットを固定すること
になる。

次にやるべきは、`manual review record` の正本フォーマットを作ることだ。  
例えば `reviews/manual/` 配下に
- review session manifest
- finding log
- review summary  
の形を定めれば、そのまま後の metric 抽出元にできる。



```
そう。その点。フォーマットを作ろう！
```

manual review 記録フォーマットを作った。正本は [reviews/manual/README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/README.md) で、保存先と3点セットを定義している。

追加した template は次だ。
- [review_session_manifest.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/templates/review_session_manifest.yaml)
- [finding_register.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/templates/finding_register.json)
- [review_summary.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/templates/review_summary.yaml)

これで、1 review session ごとに
- session 条件
- finding 単位の structured record
- sign-off / reopen / unresolved concern の summary

を正本として残せる。後から少なくとも、
- finding 数
- severity / category 分布
- accepted / rejected / deferred 比率
- reopen 発生率
- unresolved concern 数

は拾える状態だ。あわせて [EVIDENCE_PROTOCOL.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/EVIDENCE_PROTOCOL.md)、[DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md)、[CONVENTIONS.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/CONVENTIONS.md) にも manual review 記録の位置づけを反映した。

次は、この format で最初の `intent review` セッションを実際に起こす段階に進める。



```
implフェーズの実装手戻りなどはどうする？
```

そこは分けて扱うのがよい。

`implementation` の手戻りには少なくとも 2 種ある。  
- `spec 内で吸収できる軽微な実装手戻り`
  - task 順序の修正
  - file 分割の修正
  - validator 実装順の修正
- `上流へ戻すべき手戻り`
  - requirement 不足
  - design 境界の誤り
  - artifact contract 不整合
  - traceability 欠落

前者は [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md) に記録する。  
後者は、
1. `implementation-coordination-log` に記録  
2. 該当 spec を reopen  
3. 必要な alignment gate を再実施  
4. 必要なら manual review record も追加  
で処理する。

つまり役割分担はこうだ。  
- `implementation-coordination-log`
  - 実装中の手戻り、blocker、競合、差し戻し要否の一次記録
- `spec.json`
  - reopen 状態の正本
- `cross-spec-*.md`
  - 上流へ戻した後の整合確認記録
- `reviews/manual/`
  - 手戻り原因そのものを review finding として残したい場合の正本

実務ルールとしては、`implementation` で手戻りが出たらまず次を判定すべきだ。  
- task 調整で閉じるか
- design reopen が必要か
- requirements reopen まで要るか

必要なら次で、`implementation handback / reopen decision rule` を文書化できる。



```
文書化しよう
```

文書化した。正本は [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md) で、`Handback Decision Rule` を追加している。

区分は 3 つだ。
- `A. task-local adjustment`
- `B. design handback`
- `C. requirements handback`

判定原則も固定した。
- task の意図を変えないなら `A`
- task の意図は維持できるが設計境界を直す必要があるなら `B`
- そもそも contract が不足しているなら `C`

あわせて [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md) からこの規則を参照するようにし、[CONVENTIONS.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/CONVENTIONS.md) にも 3 区分を追記した。これで implementation の手戻りは、どこまで上流へ返すかを一貫して判断できる。



```
manual review recordとしては他に必要ないか
```

ある。今の 3 点セットで最低限は足りるが、後で困りやすい項目がいくつかある。

優先度が高いのは次だ。
- `review_basis`
  - 何を根拠に見たか
  - `intent refs`, `requirements refs`, `design refs`, `alignment refs`
- `review_question_set`
  - その review で何を点検したか
  - 例: `ambiguity`, `contradiction`, `missing contract`, `boundary drift`
- `finding_category taxonomy`
  - category の候補を固定
  - 例: `ambiguity`, `contradiction`, `missing_requirement`, `boundary_error`, `traceability_gap`, `metric_gap`
- `decision timestamps`
  - accepted / rejected / deferred にした時刻
- `fix linkage`
  - どの finding がどの修正に対応したか
  - file path, section, commit or doc update ref
- `reopen linkage`
  - どの finding が `requirements/design/tasks` reopen を引いたか
- `alignment impact`
  - cross-spec alignment 再実施が必要かどうか
- `confidence`
  - finding への確信度
  - 後でノイズを見分けやすい
- `manual_effort`
  - review 開始終了時刻だけでなく、おおよその effort
  - 後で効率を見る材料になる

将来の metric 抽出を考えると、特に重要なのはこの4つだ。
- `category taxonomy`
- `fix linkage`
- `reopen linkage`
- `alignment impact`

これがあると、
- どの種類の問題が多いか
- どの問題が実際に修正されたか
- どの phase で手戻りが起きたか
- cross-spec へ波及しやすい問題は何か
を後で拾いやすい。

逆に、今はまだ不要でもよいものはある。
- 厳密な time tracking
- reviewer 間一致率
- full transcript
- token / cost

結論としては、現状フォーマットは `最低限`。  
より良くするなら次に追加すべきは、
- `category` の固定語彙
- `fix / reopen / alignment` の linkage
- `review question set`
だ。  
必要なら次で template にその3系統を追記する。



```
追記
```

追記した。更新したのは次だ。

- [reviews/manual/README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/README.md)
- [review_session_manifest.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/templates/review_session_manifest.yaml)
- [finding_register.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/templates/finding_register.json)
- [review_summary.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/templates/review_summary.yaml)

追加した主な項目は、
- `review_basis`
- `review_question_set`
- 推奨 `category taxonomy`
- `confidence`
- `fix_linkage`
- `reopen_linkage`
- `alignment_impact`
- `category_counts`
- `manual_effort`

これで manual review record は、単なるメモではなく、後から
- category 分布
- 修正への反映率
- reopen 発生
- alignment 再実施要否
- effort
まで拾いやすい形になった。次はこの format で最初の `intent review` セッションを実際に作る段階だ。



```
リンク先情報は絶対パスがいいのか相対パスがいいのか？
```

正本記録としては、**相対パスがよい**。表示用リンクは絶対パスでもよいが、record の中身は相対に寄せる方が安全だ。

理由は3つある。
- repo を移動・複製しても壊れにくい
- 他環境でも再利用しやすい
- git 管理下の artifact として自然

絶対パスが向いているのは、
- このチャット内での参照
- 人に今すぐ開いてもらうリンク
だけだ。

なので方針としてはこうするのがよい。
- repo 内の YAML / JSON 記録
  - 相対パス
  - 例: `intent/INTENT.md`, `.kiro/specs/dual-reviewer-foundation/requirements.md`
- この会話で示すリンク
  - 絶対パス
- 必要なら補助的に `repo_root_id` や `workspace_name` を manifest に持つ

特に manual review record は後で機械処理したいので、絶対パス固定は避けた方がいい。  
次にやるなら、template 内の `file` や `refs` を相対パスに直すのがよい。



```
相対パスに修正し、記録時の注意も書いておく
```

相対パスに修正した。更新したのは次だ。

- [reviews/manual/README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/README.md)
- [review_session_manifest.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/templates/review_session_manifest.yaml)
- [finding_register.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/templates/finding_register.json)

方針としては、
- record の正本には repo root 基準の相対パスを使う
- 絶対パスはこのチャットの案内専用
- `../` を多用した session directory 基準は避ける

で固定した。`README` にはその注意と具体例も追記してある。これで manual review record は repo 移動後も壊れにくい。



```
これで、マニュアルレビューの準備は整ったか？必要なデータは拾える？？
```

概ね整った。少なくとも、**今から manual review を始めても、後でかなりのデータは拾える**状態だ。

揃ったものは次だ。
- session 条件
  - `review_session_manifest.yaml`
- finding 単位記録
  - `finding_register.json`
- sign-off / reopen / unresolved concern
  - `review_summary.yaml`
- 補助情報
  - `review_basis`
  - `review_question_set`
  - `category taxonomy`
  - `confidence`
  - `fix_linkage`
  - `reopen_linkage`
  - `alignment_impact`
  - `manual_effort`

この構成なら、後から少なくとも次は拾える。
- phase 別 review 件数
- finding 数
- severity 分布
- category 分布
- accepted / rejected / deferred / open の比率
- reopen 発生率
- alignment 再実施の発生率
- fix まで到達した finding の比率
- unresolved concern 数
- 手動 review の所要時間の概算

一方で、まだそのままでは弱いか、取れないものもある。
- true recall
- missed issue 数
- review quality の ground truth
- reviewer 間一致率
- cost/token 系
- 自動 runtime と manual review の厳密比較

ただ、これは今の段階では十分だ。  
「manual dogfooding の記録を正本として残し、後から metrics を拾う」という目的には足りている。

結論としては、
- **manual review を始める準備は整った**
- **必要なデータの多くは拾える**
- **ただし高級な評価指標は別途 ground truth や比較設計が要る**
だ。

次は、最初の `intent review` セッションを 1 件起こして、実際にこのフォーマットで記録を始める段階に進める。



```
では進めよう
```

最初の `intent review` セッションを起こした。記録は次に置いた。

- [review_session_manifest.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-intent-review-20260508-001/review_session_manifest.yaml)
- [finding_register.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-intent-review-20260508-001/finding_register.json)
- [review_summary.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-intent-review-20260508-001/review_summary.yaml)

今回は 2 件の open finding を記録した。要点は、
- manual dogfooding review を通常の文書編集とどう区別するかが、`INTENT` 上まだ弱い
- manual evidence から runtime-mediated evidence へ、いつどう移るかの境界がまだ曖昧
というものだ。

この session は `signoff_status: pending`、`reopen_required: true`、`downstream_recheck_required: true` で閉じてある。次はこの finding を受けて、`INTENT` か `requirements` 側へ修正を入れるかを決める段階だ。



```
次へ
```

次を進めた。

`INTENT` の finding 2 件を採用し、[INTENT.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/INTENT.md) に
- valid な manual dogfooding review の最低条件
- manual evidence と runtime-mediated evidence を混在させない方針
- Phase 1 の manual dogfooding から後続 runtime-mediated review への handoff 意図

を追記した。

あわせて downstream requirements にも落とした。
- [dual-reviewer-evaluation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/requirements.md): `Requirement 9: Review-Mode Distinction`
- [dual-reviewer-self-improvement/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/requirements.md): `Requirement 7: Manual-vs-Runtime Evidence Provenance`
- [dual-reviewer-paper-interface/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/requirements.md): `Requirement 6: Review-Mode Provenance in Reporting`

さらに、
- [cross-spec-requirements-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-requirements-alignment.md)
- [intent-to-requirements-trace-matrix.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/traceability/intent-to-requirements-trace-matrix.md)

も更新し、manual review record 側の初回 session は accepted に更新した。
- [finding_register.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-intent-review-20260508-001/finding_register.json)
- [review_summary.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-intent-review-20260508-001/review_summary.yaml)

requirements を変更したので、影響 feature の `spec.json` は reopen / recheck 状態にしてある。
- [evaluation/spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/spec.json)
- [self-improvement/spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/spec.json)
- [paper-interface/spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/spec.json)

現状の次タスクは明確で、`requirements` 変更を受けた `design` の再確認だ。特に `evaluation`、`self-improvement`、`paper-interface` の design に review-mode provenance をどう artifact 化するかを入れる段階に進む。



```
次は？
```

次は `design handback` だ。

今回 `requirements` に
- manual dogfooding evidence と runtime-mediated evidence の区別
- review-mode provenance
- handoff boundary
を追加したので、下流の `design` が未追随の状態になっている。

対象はこの3つだ。
- [dual-reviewer-evaluation/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/design.md)
- [dual-reviewer-self-improvement/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/design.md)
- [dual-reviewer-paper-interface/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/design.md)

ここでやるべきことは、
1. `review_mode` をどの artifact に持たせるか決める  
2. manual review record と runtime evidence の接続点を決める  
3. mixed review mode をどう derived artifact に残すか決める  
4. その後に `design alignment gate` を再実施する

順番としては、
- まず `evaluation design`
- 次に `self-improvement design`
- 次に `paper-interface design`
- 最後に `cross-spec-design-alignment.md` 更新
が自然だ。



```
いや、レビュー段階も水平展開だろう。
```

その通りだ。ここでも vertical に 1 feature ずつ進めるべきではない。

今回の変更は `manual dogfooding evidence` と `review_mode provenance` という**横断的な要求**なので、次も `design wave` として水平展開するのが正しい。

順序はこうなる。
1. `evaluation` / `self-improvement` / `paper-interface` の design 変更点を洗い出す  
2. 3 feature の `design.md` を一通り更新する  
3. その後に `design alignment gate` を再実施する  
4. 必要なら `spec.json` の reopen 状態を解消する

見るべき共通論点は明確だ。
- `review_mode` をどの artifact に持つか
- manual review record と runtime evidence をどう区別するか
- mixed mode を derived artifact でどう表すか
- self-improvement が manual evidence をどう扱うか
- paper-facing artifact で mode provenance をどう残すか

つまり次のタスクは、  
**manual/runtime distinction に関する multi-feature design review wave**  
になる。

進めるなら次で、
- 3 feature の design 修正案を横に入れる
- そのまま `cross-spec-design-alignment.md` まで更新する。



```
いや、まだinetntのレビューが終了した段階なので、次はrequirementsのレビュー段階だろう。
```

その通りだ。今やるべきは `design handback` ではなく、**manual requirements review wave** だ。

流れを整理すると、
- `intent review` は 1 回回した
- その finding を反映して `INTENT` と一部 `requirements` を修正した
- しかし、その後の `requirements` 自体を review していない

したがって次は、
1. `requirements review`
2. その finding を反映
3. 必要なら requirements alignment 再実施
4. その後に初めて design review へ進む
が正しい。

しかもここも vertical ではなく horizontal にやるべきだ。  
対象は少なくとも次の 5 spec。
- [foundation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/requirements.md)
- [runtime/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/requirements.md)
- [evaluation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/requirements.md)
- [self-improvement/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/requirements.md)
- [paper-interface/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/requirements.md)

この review wave で見るべき共通観点は、
- `INTENT` とちゃんと接続しているか
- feature 境界が明確か
- manual/runtime distinction が requirements に十分落ちているか
- `deferred` と `gap` が混ざっていないか
- 下流 design に必要な contract が不足していないか

つまり次タスクは、  
**manual requirements review wave**  
だ。  
進めるなら、まずこの 5 本を review 対象として 1 session にするか、`foundation/runtime` と `evaluation/self-improvement/paper-interface` に分けるかを決めて、record を起こす。



```
レビューもintentから段階的かつ水平的に下流へ流れる点を記録しておく
```

記録した。反映先は次だ。

- [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md)
- [reviews/manual/README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/README.md)
- [TRACEABILITY.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/TRACEABILITY.md)
- [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md)

追加した要点は、
- manual review も `intent -> requirements -> design -> tasks` と段階的に流す
- 各 stage の内部では feature を水平展開して review wave を作る
- 上流 stage に修正が入ったら、下流 stage の review は未確定扱いに戻す
- manual review record でも `reviewed_spec_phase` と `reviewed_feature` の使い分けでその流れを表す

これで、「spec 作成だけでなく review も上流から下流へ、かつ stage 内では横断的に進める」という方法論が文書上も固定された。次はその原則どおり、`requirements review wave` を起こす段階だ。



```
次へ進もう
```

`requirements review wave` を起こした。記録は次に置いた。

- [review_session_manifest.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-requirements-review-20260508-001/review_session_manifest.yaml)
- [finding_register.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-requirements-review-20260508-001/finding_register.json)
- [review_summary.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-requirements-review-20260508-001/review_summary.yaml)

今回は 2 件の open finding を記録した。

- `high`: review-mode provenance を downstream が要求しているのに、`foundation/runtime` 側に共有 contract がない  
- `medium`: manual dogfooding evidence から runtime-mediated evidence へ移る handoff rule の ownership が requirements 上まだ曖昧

現状この session は `signoff_status: pending`、`reopen_required: true` で閉じてある。次はこの 2 finding を採用するか判断し、採用するなら requirements handback と alignment 再実施に進む段階だ。



```
判断しよう
```

2件とも採用すべきだ。

`f001` は `high` のままでよい。これは単なる wording 問題ではなく、`evaluation / self-improvement / paper-interface` が依存する shared contract が上流にないという欠落だ。放置すると design で各 feature が別々に `review_mode` を持ち始め、後で field 名や語彙が割れる。

`f002` も採用すべきだ。重要度は `medium` で妥当だが、実質的には `requirements` で owner を決める必要がある。manual evidence と runtime-mediated evidence の handoff rule が曖昧なままだと、評価母集団、proposal 入力、reporting の境界が全部ぶれる。

したがって判断はこうなる。
- `manual-requirements-review-20260508-001-f001`: `accepted`
- `manual-requirements-review-20260508-001-f002`: `accepted`

次の実務処理は、
1. `foundation` に `review_mode provenance` の shared contract を追加
2. `runtime` にその provenance を evidence に残す requirement を追加
3. `evaluation` か `operations` のどちらかで handoff rule の owner を明示
4. `cross-spec-requirements-alignment.md` を更新
5. review record を accepted に更新

このまま進めるなら、次は requirements handback を実施する。



```
OK
```

requirements handback を反映した。

今回入れた変更は次だ。
- [foundation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/requirements.md)
  - `review mode` を metadata contract に追加
  - manual / runtime を区別する canonical vocabulary を追加
- [runtime/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/requirements.md)
  - runtime-produced evidence に review-mode provenance を残す requirement を追加
  - runtime-mediated mode を downstream 推定に頼らず明示する requirement を追加
- [evaluation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/requirements.md)
  - manual dogfooding は standard runtime comparison population から default 除外する owner を evaluation に明示
- [DATA_INVALIDATION_POLICY.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/DATA_INVALIDATION_POLICY.md)
  - manual/runtime mixed mode を default で混ぜない運用を追記
- [cross-spec-requirements-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-requirements-alignment.md)
- [intent-to-requirements-trace-matrix.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/traceability/intent-to-requirements-trace-matrix.md)

manual requirements review の記録も accepted に更新した。
- [finding_register.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-requirements-review-20260508-001/finding_register.json)
- [review_summary.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-requirements-review-20260508-001/review_summary.yaml)

また、requirements が変わったので 5 feature の `spec.json` を reopen / recheck 状態にそろえた。これで現在の正本上は「design 再確認待ち」になっている。

次は方法論どおり、horizontal な `design review wave` に進む段階だ。



```
次は
```

次は `design review wave` だ。

順序としては正しい流れになる。
1. `intent review` 済み
2. `requirements review wave` 済み
3. その handback を requirements に反映済み
4. いま 5 feature の `spec.json` は design 再確認待ち

したがって次は、**horizontal に design を review** する。

対象は 5 本だ。
- [foundation/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/design.md)
- [runtime/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/design.md)
- [evaluation/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/design.md)
- [self-improvement/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/design.md)
- [paper-interface/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/design.md)

今回の review で見るべき主論点は明確だ。
- `review_mode` をどの artifact にどう持つか
- manual review record と runtime-produced evidence の shared field mapping
- manual dogfooding と runtime-mediated evidence の handoff が design に落ちているか
- mixed review mode を derived artifact / reporting artifact でどう表現するか
- foundation / runtime / evaluation / self-improvement / paper-interface の ownership が割れていないか

つまり次タスクは、  
**manual-review distinction を含む design review wave の記録を起こすこと**  
になる。



```
requirementsのフィーチャー間調整は？
```

必要だし、今回の handback 後は**再実施済みとして記録すべき段階**だ。

整理すると、
- 最初の `requirements alignment` は一度やっていた
- その後 `intent review` と `requirements review wave` で requirements に変更が入った
- ルール上、これは `requirements alignment gate` 再実施のトリガー

つまり、今の正しい状態は
- requirements は更新済み
- design に進む前に、**更新後 requirements の feature 間調整をもう一度通す**
だ。

今回の handback で再確認すべき論点は主にこれだ。
- `review_mode` の shared owner は foundation で十分か
- runtime が review-mode provenance を残す requirement で downstream needs を満たせるか
- evaluation が standard comparison population の owner になる整理で、self-improvement / paper-interface と矛盾しないか
- manual dogfooding evidence と invalidation policy の境界が曖昧でないか
- trace matrix 上の新しい対応が requirements 境界と一致しているか

要するに、**次は design review wave の前に、requirements alignment recheck** が入るのが正しい。

進めるなら次で、
- `cross-spec-requirements-alignment.md` に再実施ログを追記
- 必要なら small fix を入れる
- その後で design review wave に進む
の順になる。



```
君は、このフィーチャー間の調整チェックを見逃したね
```

その通りだ。見逃した。

今回の正しい手順は、
1. `requirements review wave`
2. requirements handback 反映
3. **requirements alignment gate 再実施**
4. その後に `design review wave`
だった。

こちらは 3 を明示的に挟まずに、次を `design review wave` と案内していた。これは、いま決めている workflow から外れている。問題は軽くなくて、今回追加した
- `review_mode`
- manual/runtime distinction
- handoff owner
は shared contract そのものなので、feature 間調整を飛ばして下流へ進むべきではなかった。

したがって、今やるべきことは明確だ。
- まず `requirements alignment recheck` を実施する
- その結果を [cross-spec-requirements-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-requirements-alignment.md) に追記する
- 必要なら追加修正する
- その後に初めて `design review wave` へ進む

これは workflow 上の是正として記録しておいた方がいい。必要なら、この見逃し自体を implementation ではなく process finding として manual review log か coordination log に残してもよい。

次は `requirements alignment recheck` を実行する。



```
ワークフローの是正が必要だね。記録しておいて。次は requirements alignment recheck を実行
```

是正を記録したうえで、`requirements alignment recheck` を実施した。

更新したのは次だ。
- [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md)
- [reviews/manual/README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/README.md)
- [cross-spec-requirements-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-requirements-alignment.md)

是正内容は、
- review wave の finding を反映して同じ `spec phase` の文書が変わった場合
- 次段の review wave に進む前に、その phase の alignment gate を必ず再実施する

という rule を明文化したことだ。

`requirements alignment recheck` の結果としては、
- `review_mode` の shared owner は `foundation`
- runtime-mediated evidence の provenance emitter は `runtime`
- standard runtime comparison population の owner は `evaluation`
- `self-improvement` と `paper-interface` は downstream consumer
- mixed review mode の default exclusion は `DATA_INVALIDATION_POLICY.md` が支える

で整合していて、**blocking な追加矛盾はなし**と判断した。

残件は design-level に落ちた。
- manual review record と runtime-produced evidence の shared field mapping
- review-mode provenance を derived artifact にどう埋めるか
- mixed review mode を reporting でどう見せるか

これで、次に進むべき段階は正しく `design review wave` になる。



```
ここで、確認したことがある。実際に他プロジェクトでのレビューを開始する場合、つまりこのマニュアルレビューを経て、dual-reviewerをデプロイして、新たなエビデンスデータを得て、改善につなげる段階だが、この点はデータがうまくとれて、メトリックを抽出できるように考えられているだろうか
```

部分的には考えられているが、**まだ「実際に他プロジェクトへデプロイして安定的にデータ取得できる」とは言えない**。

できていることはある。  
- evidence の保存先と層分離
  - `experiments/runs/`
  - `experiments/analysis/`
  - `learning/`
  - `paper/`
- runtime で残すべき raw artifact の設計
  - [runtime/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/design.md)
- evaluation で抽出する metric tier の設計
  - [evaluation/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/design.md)
- manual review からでも evidence を残す記録フォーマット
  - [reviews/manual/README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/README.md)
- manual/runtime distinction の requirements
  - [foundation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/requirements.md)
  - [runtime/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/requirements.md)
  - [evaluation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/requirements.md)

ただし、他プロジェクト運用の観点では未確定がまだある。特に重要なのは次だ。  
- `review_mode` を実 artifact にどう埋めるか
- manual review record と runtime-produced evidence の shared field mapping
- 他プロジェクト target に対する `target_id` / `target_artifact_hash` / `phase_profile` の一貫した付与方法
- standard comparison population を作るときの inclusion/exclusion 実装
- metric 抽出スクリプトや validator がまだ実装されていない
- mixed review mode や exploratory run を含む場合の集計ルールは設計止まり

要するに、今の状態はこうだ。  
- **データをどう取るべきかの設計はかなりある**
- **後で何を metric として拾うかの骨格もある**
- **しかし、他プロジェクトで実運用して確実に取り切るための concrete schema / validator / extractor はまだ未完成**

なので判断としては、  
- `考えられているか` → はい  
- `もう安心して他プロジェクト展開できるか` → まだいいえ  
だ。

他プロジェクト投入前に最低限必要なのは次の4点だ。  
1. `review_mode` と shared field mapping を design で確定  
2. runtime/evaluation の schema を実ファイル化  
3. validator と metric extractor の最小実装  
4. 小規模な外部 target 1件で dry-run して、実際に `runs -> analysis -> learning` が通るか確認

つまり、今は「展開前夜」ではなく「展開可能性を高く見積もれる設計段階」だ。次の重要作業は、design review の中でこの deploy-to-external-project 観点を明示的に点検することになる。



```
点検して。前回ここでつまずいたのも敗因の一つ
```

**Findings**

1. `external project deployment` が現行 deploy scope から外れている。  
[DEPLOYMENT_MODEL.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/DEPLOYMENT_MODEL.md:17) は初期 target を `local repository execution / single operator / repo-contained runtime` に固定し、[同:89](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/DEPLOYMENT_MODEL.md:89) で `embedded use from arbitrary other repositories` を対象外にしている。にもかかわらず、次段で「他プロジェクトへデプロイして evidence を集める」ことを想定しているので、この部分は未設計のまま残っている。前回の失敗点だった deploy 境界の曖昧さが、ここではまだ解消し切れていない。

2. 外部プロジェクト由来 evidence の取り込み契約がない。  
[runtime/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/design.md:100) は `experiments/runs/<run_id>/` 配下への保存しか定義しておらず、[evaluation/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/design.md:59) も `experiments/analysis/` を前提に intake している。つまり、別 repo 上で走った review を「どう package して、この repo の standard pipeline に ingest するか」がない。現状だと、外部 evidence は ad-hoc にコピーするしかなく、再現性も provenance も崩れる。

3. cross-project 比較に必要な provenance field が不足している。  
[runtime/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/design.md:154) には `target_id` と `target_artifact_hash` はあるが、`source_repository_id`、`source_revision`、`submission_origin`、`review_mode` の run-level 正規化や、外部 submission 時の identity contract がまだ見えない。複数プロジェクト・複数言語の evidence を後で比較するなら、このままでは metric 集計時に母集団を安全に切れない。

4. `EVIDENCE_PROTOCOL` が薄く、後段の metric extraction を支えるには不足している。  
[EVIDENCE_PROTOCOL.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/EVIDENCE_PROTOCOL.md:3) は evidence class と保存先だけで、required field、schema version、external submission 形式、manual/runtime/external の mode distinction、comparison inclusion rule まで落ちていない。評価設計側は比較条件を要求しているが、[evaluation/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/design.md:233) その前提を満たす protocol がまだ足りない。

**結論**

いまの設計は「この repo 内で manual review と将来の local runtime を回す」には進んでいるが、`他プロジェクトへ deploy -> evidence 取得 -> metric 抽出 -> 改善 loop` という前回つまずいた地点には、まだ到達していない。最大の欠落は `external evidence deployment/ingestion contract` だ。

**次にやるべきこと**

- `deployment` と `runtime/evaluation` の間に `external run submission model` を追加する
- `run_manifest.yaml` の cross-project provenance field を requirements/design に追加する
- `EVIDENCE_PROTOCOL.md` を schema/ingestion/inclusion rule まで拡張する
- その上で `design review wave` にこの論点を finding として正式記録する

このまま進めるなら、次はこの4点を `design review` の主要 finding として起票するのが正しい。



```
基本的には他のローカルで取得したデータをまとめて取り込み、分析、反映という流れかと思うが、どうか
```

その流れでよい。現実的にも、まずはそれが最も安全だ。

つまり基本形は、
1. 各ローカル環境で review を実行する  
2. 各環境で evidence を package する  
3. central 側の repo に取り込む  
4. そこで analysis する  
5. 改善提案を作り、採用判断して runtime/spec に反映する  
になる。

これは今の方針とも整合する。`hosted service` や共有 runtime を先に作る必要がなく、前回の失敗要因だった
- 実行環境の曖昧さ
- hidden memory
- provenance 不明
を抑えやすい。

ただし、その流れにするなら、次の契約が必須だ。
- `export contract`
  - 各ローカルが何を bundle して出すか
- `ingestion contract`
  - central 側が何を受け入れるか
- `provenance contract`
  - どの repo / revision / review mode / protocol version / prompt set で採取したか
- `admission rule`
  - standard comparison に入れる条件
  - exploratory 扱いに落とす条件
  - reject する条件
- `improvement linkage`
  - どの evidence からどの proposal が生まれたか

構造としてはこうなる。
- local collector
  - raw run を作る
- submission bundle
  - portable evidence package
- central ingest
  - validate / classify / import
- central analysis
  - metrics / caveats / comparisons
- learning loop
  - proposal / backtest / adoption

なので結論は、
- 基本方針として正しい
- ただし「他ローカルで取ったデータを持ち寄る」だけでは不十分
- `bundle -> ingest -> validate -> admit` の明示契約が必要
だ。

次に進めるなら、この方針を design finding として固定し、少なくとも
- `external evidence bundle`
- `central ingestion`
の 2 つを spec 上に追加するか、既存 feature に責務として割り当てる判断が必要だ。



```
やろう
```

反映した。今回の整理で、`他のローカルで取得したデータをまとめて取り込み、分析し、改善へ返す` 流れは requirements レベルで正式化された。

主な更新は次だ。
- [DEPLOYMENT_MODEL.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/DEPLOYMENT_MODEL.md)
  - `shared hosted runtime` ではなく、第一拡張を `distributed local collection + central ingestion` と明記
- [EVIDENCE_PROTOCOL.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/EVIDENCE_PROTOCOL.md)
  - portable bundle 原則
  - 最小 cross-project provenance
  - admission 原則
- [foundation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/requirements.md)
  - `source_repository_id` / `source_revision` を支える provenance field naming を追加
- [runtime/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/requirements.md)
  - `Requirement 9: Portable Evidence Bundle Export`
- [evaluation/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/requirements.md)
  - `Requirement 10: External Bundle Ingestion and Admission`
- [self-improvement/requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/requirements.md)
  - `Requirement 8: Imported Evidence Provenance Preservation`

あわせて、[cross-spec-requirements-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-requirements-alignment.md) に再調整結果を追記し、[intent-to-requirements-trace-matrix.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/traceability/intent-to-requirements-trace-matrix.md) も更新した。関連する `spec.json` も requirements 再調整済みの状態に揃えてある。

これで「どう集めるか」の責務分担は見えた。次は `design review wave` で、
- bundle の具体 shape
- central ingest の artifact flow
- imported bundle と in-repo run directory の field mapping
- admission 結果を analysis artifact にどう残すか
を横断的に詰める段階になる。



```
確認。requirementsは全フィーチャーでレビュー終了か？
```

いいえ。`requirements` はまだ全フィーチャーで「レビュー終了」とは言えない。

現状はこうだ。
- 最初の `requirements review wave` は実施済み
- その finding を反映して requirements を修正した
- その後 `requirements alignment recheck` も実施済み
- さらに今回、`distributed local collection + central ingestion` を入れるために requirements を追加修正した

ここが重要で、最後の追加修正は
- `foundation`
- `runtime`
- `evaluation`
- `self-improvement`
に入っている。  
したがって、規約どおりなら **同じ spec phase の review をもう一度回す必要がある**。alignment は再実施したが、manual な `requirements review wave` 自体はまだ再実施していない。

なので正確な状態は、
- `paper-interface`: 今回は requirement 未変更なので比較的安定
- `foundation/runtime/evaluation/self-improvement`: 再レビュー待ち
- `requirements phase` 全体: **sign-off pending**

次にやるべきことは、追加したこの論点に絞った **supplemental requirements review wave** だ。  
レビュー観点は主に次の4つになる。
- export / ingest / admission の責務分担が妥当か
- initial local-only target と矛盾していないか
- provenance field が不足していないか
- public intake を勝手に前倒ししていないか

これを通して初めて、`requirements review` 完了と言える。



```
requirements review 完了を目指す
```

`requirements review` は完了扱いにしてよい状態になった。

今回やったことは次だ。
- supplemental review session を追加  
  - [review_session_manifest.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-requirements-review-20260508-002/review_session_manifest.yaml)
  - [finding_register.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-requirements-review-20260508-002/finding_register.json)
  - [review_summary.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-requirements-review-20260508-002/review_summary.yaml)
- `distributed local collection + central ingestion` 追加後の requirements を repo-wide で再点検
- 新規 finding は `0`
- 5 feature の [spec.json](</Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs>) で `approvals.requirements.approved = true` に更新
- `reopened.requirements = false` に更新

現状の意味は明確で、`requirements` は閉じた。一方で `design` はまだ未承認で、requirements の変更を受けた下流として review 対象のままだ。次は方法論どおり、horizontal な `design review wave` に進む。



```
次に進もう
```

`design review wave` まで完了した。

今回やったことは次だ。
- manual design review session を作成  
  - [review_session_manifest.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-design-review-20260508-001/review_session_manifest.yaml)
  - [finding_register.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-design-review-20260508-001/finding_register.json)
  - [review_summary.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-design-review-20260508-001/review_summary.yaml)
- 4件の finding を記録し、同一 phase で handback 済み
- 反映先
  - [foundation/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/design.md)
  - [runtime/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/design.md)
  - [evaluation/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/design.md)
  - [self-improvement/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/design.md)
- `cross-spec design alignment` を再実施して追記  
  - [cross-spec-design-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-design-alignment.md)

状態としては、
- `requirements`: approved
- `design`: approved
- `tasks`: 未着手

`spec.json` も 5 feature すべてで `approvals.design.approved = true`、`reopened.design = false` に更新済みだ。ここまでで `spec` 作成と manual review の流れは `design` まで閉じた。次は合意どおり `tasks wave` に進む。順番は `foundation -> runtime -> evaluation -> self-improvement -> paper-interface -> tasks alignment gate` が自然だ。



```
つぎは、タスク生成ですね。生成順について、フィーチャーの依存関係はありますか
```

ある。`tasks` は独立には切れない。大きくは次の依存で見るのがよい。

1. `foundation -> runtime -> evaluation / self-improvement / paper-interface`
- `foundation` は shared contract, metadata, schema, naming の土台
- `runtime` はその contract を使って raw evidence を作る
- `evaluation` は runtime artifact を読む
- `self-improvement` は runtime と evaluation の両方を読む
- `paper-interface` は主に evaluation を読む

2. `runtime <-> evaluation`
- `evaluation` は runtime の artifact shape と provenance field に依存する
- ただし tasks 上は、evaluation 側から runtime へ「この field が必要」という逆要求もある
- なので完全な直列ではなく、`runtime tasks` と `evaluation tasks` の間に shared artifact 確認が必要

3. `evaluation -> self-improvement`
- self-improvement の signal intake, proposal provenance, backtest 入力は evaluation output に依存する
- imported bundle の admission status も evaluation owner なので、self-improvement はその後ろ

4. `evaluation -> paper-interface`
- paper-interface は raw runtime ではなく evaluation output consumer なので、paper-interface tasks は evaluation の後ろに置くのが自然

したがって、生成順はこうするのがよい。
1. `foundation tasks`
2. `runtime tasks`
3. `evaluation tasks`
4. `self-improvement tasks`
5. `paper-interface tasks`
6. `cross-spec tasks alignment`

補足すると、依存の強さは次の通りだ。
- 強依存
  - `foundation -> runtime`
  - `runtime -> evaluation`
  - `evaluation -> self-improvement`
  - `evaluation -> paper-interface`
- 中依存
  - `foundation -> evaluation`
  - `foundation -> self-improvement`
  - `foundation -> paper-interface`

なので `tasks` の生成自体はこの順でよいが、各 tasks を書くときは shared point を意識した方がいい。
- `foundation tasks`
  - metadata contract
  - schema files
  - prompt/pattern placement
- `runtime tasks`
  - run directory
  - bundle export
  - review_mode/provenance emission
- `evaluation tasks`
  - bundle ingest
  - admission register
  - metrics/comparisons
- `self-improvement tasks`
  - proposal provenance
  - imported evidence linkage
- `paper-interface tasks`
  - imported/local distinction を継承した reporting artifact

結論としては、依存関係は明確にある。  
そのため `foundation -> runtime -> evaluation -> self-improvement -> paper-interface` の順で tasks を生成し、最後に横断調整するのが妥当だ。



```
個々で質問して気がついたが、各フェーズとも依存関係がありそうで、まず依存関係を明らかにして順序立てて進める必要があるね。cc-sddでは/kiro-discoveryスキルでそれを担当していたと思う
```

その通りだ。各 phase にも feature 間依存があるので、先に依存マップを固定した方がよい。`/kiro-discovery` 相当の役割として、依存関係と進行順を文書化した。

追加したのは [phase-and-feature-dependency-map.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/phase-and-feature-dependency-map.md) だ。内容は、
- phase 間依存
- review wave の依存
- feature topology
- `hard / interface / review dependency` の区別
- `requirements / design / tasks` 各 wave の推奨順
- `tasks alignment gate` で確認すべき blocking dependency

まで含めている。

あわせて、
- [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md)
- [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md)

も更新し、この dependency map を参照するようにした。

結論として、次の `tasks wave` はこの順で進めるのが正しい。
1. `foundation`
2. `runtime`
3. `evaluation`
4. `self-improvement`
5. `paper-interface`
6. `tasks alignment gate`

次はこの順で、[dual-reviewer-foundation/tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/tasks.md) から起こす。



```
ではタスクを起こしていこう
```

[dual-reviewer-foundation/tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/tasks.md) を起こした。`foundation` は shared contract の土台なので、`directory skeleton -> metadata contract -> schemas -> prompts/patterns -> validator contracts -> fixtures/tests` の順で切ってある。

あわせて [foundation/spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/spec.json) も更新し、`tasks.generated = true` にした。まだ `approved` ではないので、ここから review 対象になる。

次は依存順どおり [dual-reviewer-runtime/tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/tasks.md) を起こす。ここでは `run directory`, `review-mode/provenance emission`, `portable bundle export`, `validator invocation` を中心に分解する。



```
次へ
```

[dual-reviewer-runtime/tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/tasks.md) を起こした。`runtime` は `run metadata -> canonical run directory -> step artifacts -> decision/signoff -> validator integration -> portable bundle export -> fixtures/tests` の順で分解してある。

あわせて [runtime/spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/spec.json) も更新し、`tasks.generated = true` にした。まだ `approved` ではない。

次は依存順どおり [dual-reviewer-evaluation/tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/tasks.md) を起こす。ここでは `portable bundle intake`, `admission`, `classification`, `metrics/comparisons`, `analysis artifacts` を中心に切る。



```
次へ
```

[dual-reviewer-evaluation/tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/tasks.md) を起こした。`evaluation` は `analysis skeleton -> local run intake -> imported bundle ingestion/admission -> classification/exclusion -> metrics -> comparisons -> caveats -> manifest/fixtures/tests` の順で分解してある。

あわせて [evaluation/spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/spec.json) も更新し、`tasks.generated = true` にした。まだ `approved` ではない。

次は依存順どおり [dual-reviewer-self-improvement/tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/tasks.md) を起こす。ここでは `signal intake`, `proposal artifact`, `imported evidence provenance`, `replay/backtest`, `adoption/rollback history` を中心に切る。



```
次へ
```

[dual-reviewer-self-improvement/tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/tasks.md) を起こした。`self-improvement` は `learning skeleton -> signal intake -> proposal/provenance -> replay/backtest -> adoption/rejection/rollback -> fixtures/tests` の順で分解してある。

あわせて [self-improvement/spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/spec.json) も更新し、`tasks.generated = true` にした。まだ `approved` ではない。

次は依存順どおり [dual-reviewer-paper-interface/tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/tasks.md) を起こす。ここでは `claim map`, `evidence register`, `table/figure source bundles`, `caveat-preserving reporting fragments` を中心に切る。



```
続きを
```

[dual-reviewer-paper-interface/tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/tasks.md) を起こした。`paper-interface` は `paper skeleton -> evaluation intake -> claim map/evidence register -> table/figure bundles -> caveat/reporting fragments -> methodology-note linkage -> fixtures/tests` の順で分解してある。

あわせて [paper-interface/spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/spec.json) も更新し、`tasks.generated = true` にした。これで 5 feature すべての `tasks.md` が揃った。

次は合意済みの `tasks alignment gate` だ。ここで
- implementation order
- blocking dependency
- shared artifact migration timing
- validator / schema / prompt の生成順
- test sequencing
- shared file ownership

を横断確認してから implementation に入るのが正しい。



```
次は横断確認
```

横断確認は実施した。結果として、`tasks wave` の依存順は妥当で、blocking 級の衝突は見つからなかった。

今回の確認で見たことは、
- `foundation -> runtime -> evaluation -> self-improvement -> paper-interface` の順序が各 `tasks.md` で一貫しているか
- shared artifact ownership がぶれていないか
- `portable bundle` の handoff が runtime と evaluation で噛み合っているか
- self-improvement と paper-interface が evaluation output 前提になっているか
だ。

その場で 2 点だけ修正した。
- [runtime/tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/tasks.md)
  - downstream handoff に `bundle_checksums.json` を追加
- [evaluation/tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/tasks.md)
  - imported bundle ingestion に checksum verification を追加

記録先は [cross-spec-tasks-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-tasks-alignment.md) だ。あわせて5 featureの [spec.json](</Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs>) も更新し、`tasks alignment` は `completed` にした。`tasks.approved` はまだ上げていないので、状態としては「tasks は生成・横断確認済み、実装前の phase review 待ち」だ。

次は 2 通りある。
- `tasks review wave` を起こして phase を閉じる
- その前に、どの task から実装着手するかを具体化する

方法論に厳密に従うなら、次は `tasks review wave` だ。



```
次に行こう
```

`tasks review wave` まで完了した。記録は次に置いた。

- [review_session_manifest.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-tasks-review-20260509-001/review_session_manifest.yaml)
- [finding_register.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-tasks-review-20260509-001/finding_register.json)
- [review_summary.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-tasks-review-20260509-001/review_summary.yaml)

今回は新規 finding は `0` で、5 feature すべて `tasks-approved` に進めた。対応して各 [spec.json](</Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs>) は
- `phase = tasks-approved`
- `approvals.tasks.approved = true`
- `ready_for_implementation = true`

に更新済みだ。[DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md) の feature status も追随させた。

ここまでで、`intent -> requirements -> design -> tasks` と manual review / alignment gate の流れは一通り閉じた。次は implementation だ。依存順はそのまま、
1. `foundation`
2. `runtime`
3. `evaluation`
4. `self-improvement`
5. `paper-interface`
  で着手するのが正しい。



```
実装の前に、マニュアルレビューで記録したログからmetricsを抽出してまとめてみよう
```

`tasks review wave` まで完了した。記録は次に置いた。

- [review_session_manifest.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-tasks-review-20260509-001/review_session_manifest.yaml)
- [finding_register.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-tasks-review-20260509-001/finding_register.json)
- [review_summary.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-tasks-review-20260509-001/review_summary.yaml)

今回は新規 finding は `0`。5 feature すべてで
- `phase = tasks-approved`
- `approvals.tasks.approved = true`
- `ready_for_implementation = true`

に更新した。`spec.json` が正本として implementation 着手可能を示している。

補足として、横断確認では `portable bundle` の handoff を明確にするために 2 点だけ調整した。
- [runtime/tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/tasks.md)
  - `bundle_checksums.json` を downstream handoff に追加
- [evaluation/tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/tasks.md)
  - imported bundle ingestion に checksum verification を追加

ここまでで `intent -> requirements -> design -> tasks` と manual review / alignment gate の一連は閉じた。次は implementation で、依存順はそのまま
1. `foundation`
2. `runtime`
3. `evaluation`
4. `self-improvement`
5. `paper-interface`
  で進めるのが正しい。

現状は「評価設計はかなり定義済み、実測は manual review 分だけ取れている」という状態だ。

評価設計の正本は [requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/requirements.md) と [design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/design.md) にある。骨格は次の通り。
- `valid / invalid / exploratory / analysis_blocked` の区分
- `run-level / finding-level / treatment-level` の3階層 metric
- `single / dual / dual+judgment` の treatment 比較
- `intent / requirements / design / tasks` の phase-aware 比較
- manual dogfooding と runtime-mediated evidence の分離
- 外部 bundle の `admitted_standard / admitted_exploratory / rejected` 管理

最低限の metric は今こう定義されている。
- run-level: `total findings`, `accepted findings`, `rejected findings`, `deferred findings`, `validation outcome`
- finding-level: `severity distribution`, `source-role distribution`, `judgment label distribution`
- treatment-level: `findings per run`, `acceptance ratio`, `judgment invocation coverage`

ただし未確定もある。[design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/design.md) では、次が残件だ。
- treatment-level minimum metric set の最終確定
- phase-specific overlay metric set の初版確定
- self-improvement 向け必須 field の最終確認

手動レビュー記録から取れている実測値はこうだ。
- review session: 5件
- approved session: 5件
- total findings: 8件
- accepted findings: 8件
- severity: `medium 5`, `high 3`
- category: `missing_design_detail 4`, `ambiguity 2`, `workflow_gap 1`, `missing_requirement 1`
- downstream recheck 発生: 1件
- unresolved concern が残った session: 2件

根拠は各 session の summary。
- [manual-intent-review-20260508-001](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-intent-review-20260508-001/review_summary.yaml)
- [manual-requirements-review-20260508-001](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-requirements-review-20260508-001/review_summary.yaml)
- [manual-requirements-review-20260508-002](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-requirements-review-20260508-002/review_summary.yaml)
- [manual-design-review-20260508-001](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-design-review-20260508-001/review_summary.yaml)
- [manual-tasks-review-20260509-001](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/sessions/manual-tasks-review-20260509-001/review_summary.yaml)

要するに、今のレビュー評価は
- 設計面: 比較枠組みはある
- 実測面: manual review のメトリクスは拾えている
- 未完了: runtime 実行後の自動集計と、phase別の本命指標の確定
という状態だ。

次にやるなら、manual review ログから集計結果を [reviews/manual/](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual) 配下に `json + md` で正式にまとめるのが自然だ。



```
まとめて
```

manual review の集計をまとめた。出力先は次だ。

- [manual_review_metrics_summary.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/manual_review_metrics_summary.md)
- [manual_review_metrics_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/manual_review_metrics_summary.json)

要点だけ言うと、
- session 数: `5`
- approved session: `5`
- total findings: `8`
- accepted findings: `8`
- severity: `medium 5`, `high 3`
- category: `missing_design_detail 4`, `ambiguity 2`, `workflow_gap 1`, `missing_requirement 1`
- downstream recheck 発生: `1`
- unresolved concern を含む session: `2`

補足として、manual effort は `75分` と集計したが、3 session が `duration_minutes: 0` なので参考値に留まる。この点も summary に明記してある。あわせて [reviews/manual/README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/README.md) と [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md) に aggregate artifact の所在を追記した。

次は、この集計結果を `evaluation` 側の phase-specific metric 初版と見比べて、manual review から runtime review に移ったとき何を追加で取るべきかを整理するのが自然だ。



```
これらのデータを見て、どう判断するか？適切？足りない？
```

現時点の目的に対しては、**部分的には適切だが、評価データとしてはまだ足りない**。

適切な点はある。
- review session 単位での記録が揃っている
- finding 数、severity、category、accepted/rejected、downstream recheck は取れている
- `intent -> requirements -> design -> tasks` の review wave を追えている
- manual dogfooding の履歴としては、後から再集計できる形になっている

なので、これは
- 方法論を手で回せたか
- どの phase で問題が出やすいか
- handback や recheck が発生したか
を見るには有効だ。

ただし、`dual-reviewer` の有効性評価としては不足が大きい。主な不足は次だ。
- 比較対象がない
  - `single` vs `dual` vs `dual+judgment` の比較になっていない
- runtime-mediated evidence がない
  - まだ manual review のみ
- recall が分からない
  - 見逃した問題を測れない
- precision も弱い
  - accepted は取れているが、同一作業者 handback なので甘くなりやすい
- cost / latency がない
  - 実運用性を評価できない
- phase-specific metric はまだ粗い
  - 今の集計は finding count 中心で、`intent` や `requirements` の本命指標にはまだ弱い
- effort 記録が不安定
  - `duration_minutes: 0` が混ざる

要するに、このデータは
- **manual dogfooding の process evidence としては適切**
- **system effectiveness evidence としては不十分**
だ。

今の段階で妥当な判断はこうなる。
- `適切か`
  - manual review 記録としては yes
- `足りるか`
  - implementation 前の方法論確認には概ね yes
  - dual-reviewer の性能評価には no

次に追加で必要なのはこの4系統だ。
- runtime-mediated review data
- treatment 比較データ
- phase-specific effectiveness 指標
- cost / latency / effort の安定記録

一番重要なのは、次の実装後に
- 同じ target
- 同じ phase
- 異なる treatment  
で比較できる evidence を取り始めることだ。そこから初めて「dual-reviewer は有効か」に踏み込める。



```
今は、マニュアルでシングルレびゅーですね
```

その通り。今ある記録は、実質的には**manual single review** だ。

`review_mode` は `manual-dual-reviewer-inspired` として記録しているが、実際の運用を見ると、
- reviewer は実質 1 人
- finding と handback を同じ主体が処理
- 役割分離された 2 reviewer の独立出力がない
ので、評価上は `dual` とは見なせない。

したがって、今のデータの正しい位置づけはこうだ。
- 方法論の dogfooding 記録
- manual single-review baseline に近いもの
- structured review recording の初期 evidence

逆に、これをそのまま `dual-reviewer` の性能 evidence と呼ぶのは危ない。  
少なくとも analysis 上は、
- `manual single baseline`
- `manual dual-inspired process`
のどちらで扱うかを明確にした方がいいが、厳密には前者寄りだ。

この認識に立つと、次の含意がある。
- 現在の manual review metrics は baseline 扱いにする
- 将来の runtime `single / dual / dual+judgment` と同列比較しない
- `review_mode` だけでなく、`review_topology` のような区別が必要になる可能性がある

要するに、今の記録は  
**「manual single-review dogfooding evidence」**  
として扱うのが一番正確だ。



```
了解
```

現状の manual review データは、以後 `manual single-review dogfooding baseline` として扱うのが妥当だ。

次に進むなら、
- この位置づけを `reviews/manual/README.md` と `EVIDENCE_PROTOCOL.md` に明記する
- そのうえで implementation に入り、runtime の `single / dual / dual+judgment` evidence を取り始めるの順が自然だ。



```
そうしよう
```

反映した。

更新先は次だ。
- [reviews/manual/README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/reviews/manual/README.md)
- [EVIDENCE_PROTOCOL.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/EVIDENCE_PROTOCOL.md)

固定した内容は、
- manual review 記録は `manual single-review dogfooding baseline`
- method validation と初期 baseline には使う
- runtime の `single / dual / dual+judgment` evidence と同列比較しない
- 両者を同じ分析に入れる場合は distinction を明示する
というものだ。

これで、今ある manual review データの扱いはかなり明確になった。次はその前提で implementation に入り、runtime-mediated evidence を取り始める段階になる。



```
さて実装だが、codexx appでやるか、それともcodex CLIで進めるか
```

今の段階なら、**Codex app で進める方がよい**。

理由は単純だ。
- まだ実装だけでなく、spec / review / coordination log / manual evidence の往復が続く
- `spec.json`、alignment memo、manual review record を見ながら進める必要がある
- 途中で handback や phase reopen が起きても、そのまま文書と実装を往復しやすい
- このスレッド自体が方法論の記録でもある

CLI が向くのは、実装対象がかなり限定されていて、
- 連続でコードを書く
- テストを何度も回す
- 文書修正があまり入らない
段階だ。今回で言うと、`foundation` 実装の途中以降、schema / validator / fixtures を機械的に積むフェーズでは CLI の方が軽快な可能性がある。

なので使い分けはこうするのがよい。
- 今:
  - Codex app
  - 理由: spec と process 管理を伴う初期 implementation
- 後で:
  - foundation/runtime の骨格ができ、実装反復中心になったら CLI へ一部移行してもよい

結論として、**着手は Codex app 推奨**だ。  
少なくとも `foundation` の最初の実装と、implementation coordination の立ち上げまでは app の方が安全だ。



```
では実装に入ろう
```

foundation から実装に入る。まず tasks.md と現在の repo skeleton を確認して、最初の実装単位を shared contract / schema / metadata に絞る。

最初の実装は foundation の Task 1-3 をまとめて進める。shared directory、metadata contract、shared schema の正本を先に作り、downstream が参照できる状態まで持っていく。



```
ちょっとまって、スレッドを切り替えてもいいか？
```

よい。ここまでの状態は repo に残っているので、別スレッドに切り替えて問題ない。

切り替えるなら、次の2点だけ引き継げば十分だ。
- 現在地は [dual-reviewer-rebuild](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild) で、`tasks-approved` まで完了済み
- 次の実装着手点は `foundation` の Task 1-3
  - shared directory
  - `metadata_contract.yaml`
  - shared schema set

必要なら、このスレッドはここで止めて、新スレッドで実装から再開できる。



```
新スレッドから再開するときの始め方は？
```

新スレッドでは、最初にこの2行を渡せば十分だ。

```text
作業対象は /Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild です。
tasks-approved まで完了済みなので、foundation implementation の Task 1-3 から再開してください。
```

余裕があれば、これも添えると速い。

```text
参照先:
- /Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md
- /Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/tasks.md
- /Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/design.md
- /Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/phase-and-feature-dependency-map.md
```

さらに意図を明確にするなら、こう言えばよい。

```text
spec と review は完了しており、次は implementation coordination を守りつつ foundation の shared contract 実装に入る段階です。
```

これで新スレッド側は、ほぼ迷わず再開できる。