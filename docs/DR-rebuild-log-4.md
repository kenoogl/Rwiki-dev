# dual-reviewer-rebuild 4



```
全スレッドの最後の状態がおかしくなったので，新しいスレッドを始める。前回の終わり近くの重要な点は、
ACTIVE_WORKLIST.md (line 1) は、もう単なる TODO ではなく、
LLM + spec-driven development では static spec だけでは足りない
ACTIVE_WORKLIST は execution-control artifact である
実態は intent-governed spec-driven development である
という前提を明示した制御板になっています。特に、
文書の役割
正本の優先順位の補足
現在の前提
stop rule
にその finding を入れました。

あわせて、この finding 自体を方法論上の記録として implementation-coordination-log.md (line 1) にも残しています。次は worklist に従い、case-specific hardcode inventory と generic execution layer 設計の正本化に進むのが筋です。
名称はExecution Control Ledger

現在の正本:
ACTIVE_WORKLIST
dual-reviewer-spec-driven-paper-plan
claim-case-matrix
現在の問題:
case-specific hardcode をやめて generic execution layer を再設計する
このスレッドでやること:
hardcode inventory を作る
```

hardcode inventory を [execution-control-ledger.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/execution-control-ledger.md:1) として追加しました。

内容は、`case-specific hardcode` を `Execution Control Ledger` として正本化し、`remove` 対象と `case manifest へ移すだけでよい固定` を分離しています。P0 は `runtime/executors` と `track_runs/*_writer` にある execution-layer 汚染、P1 は `run_phase_field_*` などの batch wiring です。次はこの ledger を前提に、`Intent / Spec / Implementation` 共通の finding taxonomy と input contract を定義する流れで進められます。

検証は文書追加のみで、テスト実行はしていません。



```
ECLには再設計の前提として、case-specific hardcode を正本化して固定することだけしか書いていないが、その上位概念の仕様再設計を行い、仕様駆動開発を回しv2をつくるという点は織り込まなくて良いか
```

織り込んだ方がよいです。現状の `ECL` は役割が狭く、`hardcode inventory` の正本としては足りますが、なぜそれをやるのかという上位の制御意図が弱いです。

重要なのは、今回の作業目的が単なる `phase-field` hardcode 除去ではなく、

- 上位概念の仕様を再設計する
- その仕様駆動で generic execution layer を作り直す
- その結果として `v2` を作る

という流れにあることです。これが明示されていないと、`ECL` が局所リファクタ台帳に読めてしまい、`ACTIVE_WORKLIST` の
`intent-governed spec-driven development`
という制御板の位置づけとずれます。

整理すると、`ECL` に最低限追加したいのは次の3点です。

1. `ECL` は inventory 文書であって最終目標ではない  
2. inventory の用途は `generic execution layer v2` の仕様再設計入力である  
3. 実装修正は直接やらず、まず上位仕様を再設計してから `requirements/design/tasks` を回して `v2` を作る  

つまり、`ECL` の purpose を
「hardcode を列挙する」
ではなく
「v2 再設計の spec input を固定する」
まで引き上げるべきです。

必要なら次に私がやるべきなのは、[execution-control-ledger.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/execution-control-ledger.md:1) に

- この文書の非目標
- v2 再設計との接続
- spec handback / reopen の位置づけ

を追記して、`ACTIVE_WORKLIST` と整合する形に直すことです。



```
ECLを作成したら、`ACTIVE_WORKLIST`は削除してよいか
```

削除しない方がよいです。`ECL` は `ACTIVE_WORKLIST` の代替ではありません。

役割が違います。

- `ACTIVE_WORKLIST` は execution-control artifact です
- `ECL` は redesign input artifact です

`ACTIVE_WORKLIST` が固定しているのは、

- 今どの段階か
- 次の1手は何か
- 何をやってはいけないか
- どこで止まるか

です。これは作業順序と停止条件の制御板です。

一方 `ECL` が固定しているのは、

- どこに case-specific hardcode があるか
- 何が remove 対象か
- 何が case manifest 側へ移送対象か

です。これは再設計の入力台帳です。

なので関係は置換ではなく分担です。

- `ACTIVE_WORKLIST`: 進行制御の正本
- `ECL`: generic execution layer v2 再設計のための hardcode inventory 正本

むしろ今回の流れでは、`ACTIVE_WORKLIST` の `Current Next Step` が
`hardcode inventory を作る`
で、その成果物の1つが `ECL` です。したがって `ECL` を作ったことで `ACTIVE_WORKLIST` のその項目は前進しますが、文書自体の役割は消えません。

削除してよいのは、少なくとも次の条件を満たした後です。

1. `ACTIVE_WORKLIST` の execution-control 機能が別の制御板に完全移管されている
2. `Current Next Step` と `Stop Rules` を失わずに運用できる
3. `intent-governed spec-driven development` の進行制御正本が別に立っている

現時点ではその状態ではないので、削除は不適切です。必要なのは削除ではなく、`ACTIVE_WORKLIST` 側で

- `hardcode inventory: completed`
- `next: generic execution layer v2 の上位仕様再設計`

のように進行状態を更新することです。



```
つまり、ECLとその実行実態のACTIVE_WORKLISTはセットで運用ということか
```

はい。その理解でよいです。

ただし完全に対等な 2 枚看板ではなく、関係は少し非対称です。

- `ACTIVE_WORKLIST` は実行制御の正本です
- `ECL` はその中の一作業束に対する設計入力の正本です

つまり運用上はセットですが、上下関係としては

1. `ACTIVE_WORKLIST` が「今なにをやるか」「どこで止まるか」を決める
2. `ECL` が「generic execution layer v2 再設計のために、何を除去・移送対象として扱うか」を固定する

という形です。

言い換えると、

- `ACTIVE_WORKLIST` なしの `ECL` は、台帳として存在しても実行順序を制御できない
- `ECL` なしの `ACTIVE_WORKLIST` は、次の再設計入力が曖昧になる

ので、現段階ではセット運用が自然です。

実務上の整理はこうです。

- `ACTIVE_WORKLIST`: control board
- `ECL`: redesign ledger
- 次に作るべきもの: generic execution layer v2 の上位仕様

なので次フェーズでは、`ACTIVE_WORKLIST` が次の一手を指し、`ECL` がその仕様再設計の入力台帳として参照される、という運用になります。



```
では、確認。次にすべきことは？
```

次にすべきことは、`ECL` を入力として **generic execution layer v2 の上位仕様を正本化すること** です。

順序で言うと次です。

1. `ACTIVE_WORKLIST` を更新する  
`hardcode inventory completed` を反映し、`Current Next Step` を `generic execution layer v2 の上位仕様再設計` に進める。

2. `ECL` を v2 再設計入力として位置づけ直す  
単なる inventory ではなく、
`何を execution layer から追い出すか`
`何を case manifest 層へ移すか`
の制約台帳として固定する。

3. v2 の上位仕様を書く  
少なくとも次を定義する。
- track 共通の役割分解
- `intent/spec/implementation` ごとの input contract
- finding taxonomy
- analyzer と writer の分離
- case manifest 層と execution layer 層の境界

4. その後に spec-driven で落とす  
v2 用の `requirements` → `design` → `tasks` に落として実装へ進む。

要するに、次の1手は `コード修正` ではなく、**generic execution layer v2 の概念仕様を書くこと** です。必要なら次にその仕様文書の初版をこちらで作れます。



```
進めて
```

`generic execution layer v2` の上位仕様を [generic-execution-layer-v2-spec.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/generic-execution-layer-v2-spec.md:1) として追加しました。内容は、`Case Manifest / Analysis / Decision / Writer` の4層分離、3 track の input contract、finding taxonomy、`ECL` との関係、そして `requirements/design/tasks` に落とす次段の spec-driven path まで固定しています。

あわせて [execution-control-ledger.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/execution-control-ledger.md:1) を `v2 redesign input ledger` として位置づけ直し、[ACTIVE_WORKLIST.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md:1) の `Current Next Step` を `v2` 仕様正本化後の `requirements/design/tasks` へ進める形に更新しました。`INDEX.md` にもこの3文書の接続を追加しています。

テスト実行はしていません。次はこの v2 上位仕様を受けて、`requirements` 初版を起こす段階です。



```
リンクがurlになっている。おかしいぞ。相対パスだろ
```

この環境では意図的です。リンク先は相対ではなく絶対パスで出しています。

理由は、この Codex app のレンダラ側仕様で、workspace ファイル参照は相対パスではなく絶対パスを使う前提だからです。たとえば今回の正しい形式は

- [generic-execution-layer-v2-spec.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/generic-execution-layer-v2-spec.md:1)

です。

相対パス表記そのものが必要なら本文中では併記できます。今回の対象は

- `.kiro/methodology/dual-reviewer-spec-driven-paper/generic-execution-layer-v2-spec.md`
- `.kiro/methodology/dual-reviewer-spec-driven-paper/execution-control-ledger.md`
- `.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md`

です。



```
ECLがアップデートされていない
```

その指摘は正しいです。冒頭の `purpose` は更新されていましたが、本文としては `ECL` がまだ「inventory 文書」に寄っていて、`ACTIVE_WORKLIST` との関係と `v2` 仕様への handoff が弱い状態でした。

今、[execution-control-ledger.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/execution-control-ledger.md:1) に次を追加しました。

- `この文書単体では進行制御を担わない`
- `ACTIVE_WORKLIST` が control board、`ECL` は redesign input artifact である
- `ECL` の非目標
- `generic-execution-layer-v2-spec` への handoff 論点
- inventory 完了後に v2 仕様へ進むこと

これで `ECL` 自体が、単なる hardcode 一覧ではなく `v2` 再設計入力台帳として読める状態になっています。次に進むなら、そのまま `v2 requirements` 初版を起こす段階です。



```

```

