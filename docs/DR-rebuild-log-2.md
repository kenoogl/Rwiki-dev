# dual-reviewer-rebuild 2



```
作業対象は /Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild です。
tasks-approved まで完了済みなので、foundation implementation の Task 1-3 から再開してください。
```

```
参照先:
- /Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md
- /Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/tasks.md
- /Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-foundation/design.md
- /Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/phase-and-feature-dependency-map.md
```

```
spec と review は完了しており、次は implementation coordination を守りつつ foundation の shared contract 実装に入る段階です。
```

foundation の Task 1-3 を実装しました。`runtime/` 配下の shared asset skeleton を固定し、run metadata の正本を [metadata_contract.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/foundation/metadata_contract.yaml:1) に追加、shared schema 5 点を [review_case.schema.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/schemas/review_case.schema.json:1)、[finding.schema.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/schemas/finding.schema.json:1)、[impact_score.schema.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/schemas/impact_score.schema.json:1)、[failure_observation.schema.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/schemas/failure_observation.schema.json:1)、[necessity_judgment.schema.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/schemas/necessity_judgment.schema.json:1) に作成しました。implementation coordination も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:132) に記録済みです。

補足として、`necessity_judgment` の 5-field は spec 上で名称未固定だったため、初版では neutral な英語ラベルで concrete 化しています。ここだけは downstream 実装を本格化する前に見直し余地がありますが、Task 1-3 の範囲では handback 不要と判断しました。

検証は `jq` による全 JSON schema の parse と、Ruby `YAML.load_file` による `metadata_contract.yaml` の parse まで実施済みです。fixtures / schema validation の追加は Task 7-8 側です。



```
次は？
```

次は foundation の残りを順に進めるのが正しいです。依存順は崩さず、Task 4-6 に入ります。

1. Task 4: shared prompt artifacts
   [runtime/prompts/judgment/](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/prompts/judgment) に judgment prompt の canonical artifact を作り、frontmatter の identity rule を固めます。

2. Task 5: pattern and terminology assets
   [runtime/patterns/](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/patterns) と [runtime/config/](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/config) に `seed_patterns.yaml`、`fatal_patterns.yaml`、`terminology.yaml.template` を入れます。

3. Task 6: validator-facing contracts
   [runtime/validators/contracts/](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/validators/contracts) に `validator_result.schema.json`、`invalidation_marker.schema.json`、`review_mode_vocab.yaml` を追加します。

この順なら runtime / evaluation の実装前提が揃います。続けるならそのまま Task 4 から着手します。



```
レポジトリにコミットしたいが、Rwikiのレポで作業中。どうするのがよいか
```

いまの状況なら、いちばん実務的なのは `Rwiki` 本体の repo の中で、`dual-reviewer-rebuild/` だけを scoped commit するやり方です。

理由は単純で、`dual-reviewer-rebuild` は現状 `Rwiki` 配下の作業ツリーとして存在していて、別 repo として独立していない可能性が高いからです。この場合は無理に分離せず、`Rwiki` 側で専用ブランチを切って、そのディレクトリ配下だけを commit するのが安全です。親 repo の unrelated change は混ぜないように、`git add dual-reviewer-rebuild/...` のように path を限定します。

選択肢は3つです。

1. `Rwiki` の同一 repo で専用ブランチを切る
   `codex/dual-reviewer-foundation` のような branch を作り、`dual-reviewer-rebuild/` だけ commit する。
   もっとも手間が少なく、今すぐ進めやすいです。

2. `dual-reviewer-rebuild` を独立 repo にする
   将来的に完全分離したいならありですが、今やると履歴整理や remote 設定が増えて implementation の流れを止めます。

3. `git subtree` / `submodule` にする
   長期的には成立しますが、今の段階では過剰です。foundation 実装を進める前提としては重いです。

当面の推奨は `1` です。つまり:

- `Rwiki` repo root で新規 branch を作る
- `dual-reviewer-rebuild/` のみ stage する
- その scope だけ commit する

必要なら次の手順でそのまま私がブランチ作成から commit まで進めます。



```
1で進めてください
```

`Rwiki` 本体 repo 上で `codex/dual-reviewer-foundation` を作成し、`dual-reviewer-rebuild/` だけを 1 commit にまとめました。commit は `f77e190` (`Add dual-reviewer rebuild foundation baseline`) です。

注意点として、親 repo にはまだ今回の commit に含めていない変更が残っています。具体的には `.claude/settings.local.json`、`docs/dual-reviewer-log-10.md`、`docs/dual-reviewer-rebuild-plan.md` です。今回の commit には混ぜていません。

次にやるなら `git push origin codex/dual-reviewer-foundation` です。必要ならそのまま push まで進めます。

::git-stage{cwd="/Users/Daily/Development/Rwiki-dev"}
::git-commit{cwd="/Users/Daily/Development/Rwiki-dev"}
::git-create-branch{cwd="/Users/Daily/Development/Rwiki-dev" branch="codex/dual-reviewer-foundation"}



```
push
```

`codex/dual-reviewer-foundation` を push しました。tracking も設定済みです。

PR 作成リンクは [こちら](https://github.com/kenoogl/Rwiki-dev/pull/new/codex/dual-reviewer-foundation) です。

::git-push{cwd="/Users/Daily/Development/Rwiki-dev" branch="codex/dual-reviewer-foundation"}



```
次は？
```

次は `dual-reviewer-foundation` の Task 4-6 です。いま push 済みなので、実装をそのまま続けるならこの順が妥当です。

1. Task 4
   [runtime/prompts/judgment/](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/prompts/judgment) に judgment prompt artifact を追加して、frontmatter の `prompt_id` / `version` / `role` / `step` / `language` / `source_ref` を固定する。

2. Task 5
   [runtime/patterns/](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/patterns) と [runtime/config/](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/config) に `seed_patterns.yaml`、`fatal_patterns.yaml`、`terminology.yaml.template` を追加する。

3. Task 6
   [runtime/validators/contracts/](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/validators/contracts) に `validator_result.schema.json`、`invalidation_marker.schema.json`、`review_mode_vocab.yaml` を追加する。

実装優先ならこのまま Task 4 から着手します。PR を先に切るなら、いまの baseline commit を土台にして、その後同じ branch に追加していく形で問題ありません。



```
PR を切るとは？
```

PR は Pull Request です。いま push した `codex/dual-reviewer-foundation` を、ベース branch に取り込むためのレビュー依頼です。

今回の文脈では、`Rwiki-dev` の GitHub 上で:

- base: たとえば `main` や作業元 branch
- compare: `codex/dual-reviewer-foundation`

を指定して、「この branch の変更を取り込みたい」と出すものです。

使う理由は主に3つです。

- 変更単位を明確に切れる
- commit 群に対してレビューや記録を残せる
- foundation baseline の時点を後で参照しやすい

ただし、今すぐ PR が必須とは限りません。まだ foundation Task 4-6 を同じ branch で積むなら、先に実装を進めてから 1 本の PR にまとめるほうが自然です。逆に「baseline 作成」と「foundation contract 実装」を分けて見たいなら、今の時点で PR を切る意味があります。

要するに選択肢は2つです。

1. いま PR を作る
   baseline 作成を独立した変更セットとして確定する

2. まだ作らない
   この branch で Task 4-6 まで進めてからまとめて PR にする

今の進め方なら `2` のほうが実務的です。



```
先に実装
```

Task 4-6 まで実装しました。prompt identity contract を [frontmatter_contract.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/prompts/shared/frontmatter_contract.yaml:1) に追加し、judgment prompt の canonical artifact を [judgment_reviewer.prompt.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/prompts/judgment/judgment_reviewer.prompt.md:1) に作成しました。pattern/config assets は [seed_patterns.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/patterns/seed_patterns.yaml:1)、[fatal_patterns.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/patterns/fatal_patterns.yaml:1)、[config.yaml.template](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/config/config.yaml.template:1)、[terminology.yaml.template](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/config/terminology.yaml.template:1) に追加し、validator-facing contracts は [invalidation_marker.schema.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/validators/contracts/invalidation_marker.schema.json:1)、[validator_result.schema.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/validators/contracts/validator_result.schema.json:1)、[review_mode_vocab.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/validators/contracts/review_mode_vocab.yaml:1) に追加しました。

implementation coordination も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:155) に追記済みです。`tasks.md` の `terminology_template.yaml` と design の `terminology.yaml.template` の不一致は、design canonical に寄せる `A` 判定で吸収し、同時に requirements 上必要だった `config.yaml.template` も追加しました。検証は JSON schema の `jq` parse と YAML parse まで通しています。

次は foundation の Task 7-8 です。つまり `tests/fixtures/foundation/` に最小 fixture を置いて、その後 schema validation / smoke check を追加する段階です。必要ならそのまま続けます。



```
続けて
```

foundation の Task 7-8 まで完了しました。最小 fixture を [review_case.minimal.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/tests/fixtures/foundation/review_case.minimal.json:1)、[finding.minimal.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/tests/fixtures/foundation/finding.minimal.json:1)、[validator_result.minimal.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/tests/fixtures/foundation/validator_result.minimal.json:1)、[invalidation_marker.minimal.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/tests/fixtures/foundation/invalidation_marker.minimal.json:1) に追加し、mechanical validation を [validate_foundation_contracts.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/validate_foundation_contracts.rb:1) に実装しました。implementation coordination も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:176) に追記済みです。

検証は `ruby scripts/validate_foundation_contracts.rb` で実行し、`foundation contract validation passed` を確認しました。これで foundation tasks は一通り完了です。

次は `dual-reviewer-runtime` の Task 1 以降に入れます。foundation artifact を前提に runtime module skeleton と entrypoint を作る段階です。必要ならそのまま続けます。



```
続けて
```

`dual-reviewer-runtime` の Task 1-8 を最小 end-to-end 実装まで進めました。

中心は [session_controller.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/controller/session_controller.rb:1) です。ここで foundation contract を読み、run 初期化、step artifact 出力、`review_case.json` 集約、decision/sign-off artifact、validator result / invalidation marker、bundle export まで繋いでいます。writer 群は [evidence_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/writers/evidence_writer.rb:1)、validator bridge は [validation_bridge.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/validation/validation_bridge.rb:1)、export は [bundle_exporter.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/export/bundle_exporter.rb:1) に分けました。entrypoint は [run_review_session.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/run_review_session.rb:1) と [export_evidence_bundle.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/export_evidence_bundle.rb:1) です。implementation coordination も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:194) まで更新済みです。

検証は `ruby scripts/run_review_session.rb`、`ruby scripts/export_evidence_bundle.rb`、`ruby scripts/validate_foundation_contracts.rb` で通しています。確認用に生成した `experiments/runs/*` と `exports/*` は削除済みです。

残っている実質的な未充足は、A/B/D の real prompt resolution がまだ deferred placeholder であることと、step 内容が skeleton payload のままであることです。次に進めるなら evaluation 側へ行く前に、runtime の step payload と decision artifact の中身を実データ化するか、この状態で一度 commit するのが自然です。



```
ここでびっくりしたのは実装言語がruby?
```

はい。今回はこちらで Ruby を選びました。ただし、これは repo の正本仕様で固定されていたわけではなく、Task 1-8 を最短で repo 内完結させるための実装上の選択です。

選んだ理由は3つです。

- 既存作業で `ruby` 実行がその場で使えた
- YAML/JSON を標準ライブラリで安全に扱いやすい
- foundation/runtime の今の段階は orchestration と artifact I/O が中心で、まず skeleton を速く閉じる価値が高かった

ただし、驚いたのはもっともです。spec を見る限り runtime の実装言語は未固定で、foundation design にも「validator implementation language と execution entrypoint」は open issue として残っています。なので Ruby で進めるのが唯一の正解、という状態ではありません。

実務的には次のどちらかです。

1. Ruby のまま進める
   いまの skeleton を土台にして runtime/evaluation/self-improvement を揃える。最短です。

2. ここで言語を決め直す
   Python や Node に寄せたいなら、runtime がまだ skeleton 段階の今のほうが切り替えコストは低いです。

もしあなたの想定言語が Python か TypeScript なら、ここで止めてそちらへ寄せる判断は十分合理的です。私はそうするなら、まず `dual-reviewer-runtime` の実装言語を spec か coordination log に明示してから、今の Ruby skeleton を置き換えます。



```
今は、rubyでよい。できたシステムの言語を変えるのはそう難しいことではない。あとで、使われ方などを検討して実装言語は再検討しよう。今はプロトタイプを作るのが優先
```

了解です。現時点では Ruby のまま進める判断で問題ありません。いま必要なのは言語最適化ではなく、artifact shape と運用境界が実際に成立するプロトタイプを早く閉じることです。

次の進め方もその前提でよく、あとで使用形態や周辺 tooling が見えた時点で実装言語を再評価すれば十分です。現状は foundation と runtime の骨格ができたので、次は evaluation に入るのが自然です。runtime が出す `review_case.json`、`validator_result.json`、`invalidation_markers.json` を intake する最小系を作れば、prototype 全体の流れが見えます。

続けるならそのまま `dual-reviewer-evaluation` の Task 1 から入ります。



```
一度コミットしよう
```

commit しました。現在の branch `codex/dual-reviewer-foundation` に `0943943` (`Implement foundation and runtime prototype skeleton`) が追加されています。

親 repo の未関連変更 `.claude/settings.local.json`、`docs/dual-reviewer-log-10.md`、`docs/dual-reviewer-rebuild-plan.md` は今回の commit に含めていません。次はこの commit を push するか、そのまま evaluation 実装に進めるかです。

::git-stage{cwd="/Users/Daily/Development/Rwiki-dev"}
::git-commit{cwd="/Users/Daily/Development/Rwiki-dev"}



```
実装段階でログはとれている？手戻りなどのシグナルはあるか？
```

はい、最低限の実装ログは取れています。現時点の正本は [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:125) で、foundation と runtime の各実装区間が `6.2` から `6.8` まで記録されています。各 entry には対象 task、touched artifacts、handback class、reopen 要否、action、status が入っています。

手戻りシグナルについては、いま見えているものはありますが、まだ重い handback には上がっていません。

- 明示的には全部 `A` 判定です。`B` や `C` の reopen はまだ出ていません。[implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:150) [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:171)
- 仕様ずれの軽微なシグナルはあります。たとえば `terminology_template.yaml` と `terminology.yaml.template` の表記差分は task-local adjustment として吸収しています。[implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:173)
- runtime 側では Step A/B/D の prompt resolution がまだ deferred placeholder です。これは将来の実装埋め残しシグナルです。[implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:250)
- 実装中の不整合も一件ありました。validator の `overall_status` 判定と `closed_at` の扱いにズレが出ましたが、その場で修正して吸収しています。これは coordination log には個別 event として切っていませんが、実質的には `A` の小さな手戻りです。
- blocker は全 entry で `なし` です。[implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:149) [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:170) [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:247)

補足すると、runtime の試走で生成した `experiments/runs/*` や `exports/*` は検証後に消しているので、永続的な「失敗ログ」や「試行錯誤ログ」は今は残していません。残っているのは coordination log と git history です。直近の実装区切りは `f77e190` と `0943943` です。

要するに、
- 実装ログはある
- ただし設計レビュー向けの coordination log が中心
- 手戻りシグナルは軽微なものが出始めている
- まだ spec reopen を要するレベルの `B/C` シグナルは出ていない

もし次段で手戻り観測を強くしたいなら、evaluation に入る前に `implementation-signal register` のような軽量台帳を追加するのは有効です。



```
どういうものか説明して
```

イメージとしては、`implementation-coordination-log` が「判断の記録」なのに対して、`implementation-signal register` は「観測された兆候の台帳」です。

今の log は良いのですが、粒度がやや大きいです。実装中に起きる小さなズレや繰り返し修正は、`B/C` handback になる前だと流れの中で吸収されがちです。そこで別台帳を置いて、軽微でもシグナルとして先に積んでおく、という考え方です。

例えば記録対象はこうです。

- 同じファイルを短時間で何度も触った
- spec wording の解釈で迷いが出た
- placeholder 実装を入れた
- validation で一度落ちて修正した
- task と design の表記差分を吸収した
- downstream 実装前提が曖昧だった
- generated artifact を試作して消した
- 「今は通したが後で設計見直し候補」という点が出た

1 entry はかなり軽くてよいです。例えば:

- date
- feature
- task
- signal_type
- artifact
- description
- immediate_action
- escalation_risk
- status

`signal_type` の例は:

- `placeholder_remaining`
- `spec_wording_mismatch`
- `validation_correction`
- `artifact_shape_uncertainty`
- `downstream_dependency_risk`
- `repeated_touch`
- `temporary_workaround`

`escalation_risk` は `low / medium / high` くらいで十分です。ここで `medium` 以上が複数たまったら、coordination log 側で `B/C` handback を検討する、という運用にできます。

今回の実装だと、例えば次は signal として載せられます。

- Step A/B/D prompt resolution が deferred
- `terminology_template.yaml` と `terminology.yaml.template` の差分吸収
- validator close 判定の一度目のズレ修正
- runtime generated artifact を試走後に削除したこと

重要なのは、この台帳は「問題が確定した記録」ではなく、「あとで効いてきそうな兆候の蓄積」だという点です。spec を reopen するほどではないが、無視すると後でまとめて効くものを早めに見える化する用途です。

必要なら、この repo に合う最小フォーマットでその register 自体を作れます。



```
はい、作成
```

作成しました。register 本体は [implementation-signal-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-signal-register.md:1) です。役割、coordination log との使い分け、記録フォーマット、escalation ルール、signal type vocabulary を入れた上で、初期 signal を 4 件記録しています。

今入っている初期 signal は次です。

- foundation の terminology template 名の spec wording mismatch  
  [implementation-signal-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-signal-register.md:62)
- runtime の Step A/B/D prompt resolution deferred  
  [implementation-signal-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-signal-register.md:77)
- runtime validator close-path correction  
  [implementation-signal-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-signal-register.md:92)
- generated artifact の試走 cleanup  
  [implementation-signal-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-signal-register.md:106)

`DOCUMENT_INDEX.md` にも coordination 文書として追加済みです。  
[DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md:142)

現状の運用なら、
- task 完了や handback 判定は `implementation-coordination-log`
- 軽微だが後で効きそうな兆候は `implementation-signal-register`

で分ければ十分です。

この 2 ファイルはまだ未コミットです。必要なら続けて commit します。



```
さて、次のタスクは？
```

次は `dual-reviewer-evaluation` の Task 1 です。foundation と runtime の最小 artifact が揃ったので、依存順としてここに入るのが自然です。

具体的には [dual-reviewer-evaluation/tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/tasks.md:34) の `Create analysis directory skeleton` から始めます。その後の流れは次です。

1. Task 1
   analysis directory skeleton を作る

2. Task 2
   local run intake を実装する  
   いま runtime が出す `run_manifest.yaml`、`review_case.json`、`validation/*.json` を読む入口です

3. Task 3
   imported bundle ingestion を実装する  
   いま runtime export が最小実装まであるので、ここに接続できます

いまの時点で一番価値が高いのは Task 2 まで進めて、「runtime が出した run を evaluation が intake できる」ことを確認することです。ここまで通ると prototype の縦の流れが見えます。

進めるなら、そのまま evaluation Task 1-2 から着手します。



```
進めて
```

`dual-reviewer-evaluation` の Task 1-3 まで進めました。

analysis skeleton は [experiments/analysis/](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis) 配下に固定し、local run intake は [local_run_loader.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/evaluation/local_run_loader.rb:1) と [intake_local_run.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/intake_local_run.rb:1) で実装しました。imported bundle ingestion は [imported_bundle_loader.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/evaluation/imported_bundle_loader.rb:1) と [intake_imported_bundle.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/intake_imported_bundle.rb:1) で、bundle manifest、run subtree、checksum、provenance 欠損を読めるようにしています。

fixture も追加しています。local run fixture は [tests/fixtures/evaluation/local_runs/minimal_runtime_run](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/tests/fixtures/evaluation/local_runs/minimal_runtime_run)、bundle fixture は [tests/fixtures/evaluation/imported_bundles/minimal_runtime_bundle](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/tests/fixtures/evaluation/imported_bundles/minimal_runtime_bundle) です。coordination log は [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:273)、signal register は [implementation-signal-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-signal-register.md:119) に反映しました。

検証は `ruby scripts/intake_local_run.rb tests/fixtures/evaluation/local_runs/minimal_runtime_run` と `ruby scripts/intake_imported_bundle.rb tests/fixtures/evaluation/imported_bundles/minimal_runtime_bundle` で通っていて、bundle 側は `ingestion_status: complete` と checksum 全件 `matched` を確認済みです。

次は evaluation Task 4 です。つまり imported bundle の admission decision と `imports/ingestion_register.json` / `imports/admission_register.json` の writer を入れる段階です。



```
続けて
```

evaluation の Task 4 まで進めました。imported bundle admission は [admission_evaluator.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/evaluation/admission_evaluator.rb:1) に入れてあり、`complete + runtime_mediated` を `admitted_standard`、provenance 不足を `admitted_exploratory`、checksum/required artifact 問題を `rejected` に分けます。register writer は [import_register_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/evaluation/import_register_writer.rb:1)、CLI は [admit_imported_bundle.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/admit_imported_bundle.rb:1) です。

検証では `ruby scripts/admit_imported_bundle.rb tests/fixtures/evaluation/imported_bundles/minimal_runtime_bundle` を実行し、`admission_status: admitted_standard` を確認しました。imports register も書けていて、[ingestion_register.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/imports/ingestion_register.json:1) と [admission_register.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/imports/admission_register.json:1) に fixture ベースの 1 entry が入っています。coordination log も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:288) に追記済みです。

次は evaluation Task 5 です。つまり classification engine を入れて、`valid / invalid / exploratory / analysis_blocked` を [run_classification_index.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/classifications) と `exclusion_report.json` に落とす段階です。



```
次へ
```

evaluation の Task 5 まで進めました。classification engine は [classification_engine.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/evaluation/classification_engine.rb:1)、writer は [classification_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/evaluation/classification_writer.rb:1)、CLI は [classify_evaluation_input.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/classify_evaluation_input.rb:1) です。local run と imported bundle admission の両方を受けて、`valid / invalid / exploratory / analysis_blocked` を返し、[run_classification_index.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/classifications/run_classification_index.json:1) と [exclusion_report.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/classifications/exclusion_report.json:1) に出力します。

検証では `ruby scripts/classify_evaluation_input.rb local_run ...` と `ruby scripts/classify_evaluation_input.rb imported_bundle ...` を実行し、どちらも fixture では `valid` になりました。実装ログは [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:301) に追記済みです。

次は evaluation の Task 6 です。つまり `run_metrics.json` と `finding_metrics.json` を作り、`derived/runtime_summary.json` に頼らず structured artifact から core metrics を再計算する段階です。



```
次へ
```

evaluation の Task 6 まで進めました。metrics extractor は [metric_extractor.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/evaluation/metric_extractor.rb:1)、writer は [metric_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/evaluation/metric_writer.rb:1)、CLI は [extract_evaluation_metrics.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/extract_evaluation_metrics.rb:1) です。出力は [run_metrics.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/metrics/run_metrics.json:1) と [finding_metrics.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/metrics/finding_metrics.json:1) に入ります。

検証では `ruby scripts/extract_evaluation_metrics.rb tests/fixtures/evaluation/local_runs/minimal_runtime_run` を実行し、`total_findings=1`、`accepted_findings=1`、`severity_distribution.medium=1`、`source_role_distribution.primary_reviewer=1` を確認しました。`judgment label distribution` は現状の標準入力だけでは label 本体を直接取れないので、`judgment_ref_present` と `unresolved_judgment_labels` の proxy を出しています。この点は [implementation-signal-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-signal-register.md:134) に signal として残しました。implementation log も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:314) に追記済みです。

次は evaluation の Task 7 です。つまり treatment-level metrics と `treatment_comparisons.json` / `phase_comparisons.json` を作り、比較 precondition と invalid comparison reason を machine-readable に残す段階です。



```
次へ
```

evaluation の Task 7 まで進めました。treatment/phase comparison の実装は [comparison_builder.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/evaluation/comparison_builder.rb:1)、writer は [comparison_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/evaluation/comparison_writer.rb:1)、CLI は [build_evaluation_comparisons.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/build_evaluation_comparisons.rb:1) です。出力は [treatment_metrics.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/metrics/treatment_metrics.json:1)、[treatment_comparisons.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/comparisons/treatment_comparisons.json:1)、[phase_comparisons.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/comparisons/phase_comparisons.json:1) に入ります。

検証では `ruby scripts/build_evaluation_comparisons.rb` を実行し、現在の fixture 集合では treatment 比較が `comparison_status: invalid`、`comparison_invalid_reason: ["insufficient_variant_count"]` になることを確認しました。これは想定どおりです。一方で phase comparison は `tasks` slice で成立しており、`overlay_metric_profile: "tasks_overlay_v1"` まで残っています。implementation log も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:327) に追記済みです。

次は evaluation の Task 8 です。つまり `caveat_register.json` を追加して、low sample size や exploratory-only slice などを exclusion とは別軸で保持する段階です。



```
次へ
```

evaluation の Task 8 まで進めました。caveat 生成は [caveat_builder.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/evaluation/caveat_builder.rb:1)、writer は [caveat_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/evaluation/caveat_writer.rb:1)、CLI は [build_evaluation_caveats.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/build_evaluation_caveats.rb:1) です。出力は [caveat_register.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/caveats/caveat_register.json:1) に入ります。

検証では `ruby scripts/build_evaluation_caveats.rb` を実行し、現在の fixture 集合から `single_treatment_only` caveat が生成されることを確認しました。これは treatment 比較が `insufficient_variant_count` で不成立になっている現状と整合しています。implementation log も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:340) に追記済みです。

次は evaluation の Task 9 です。つまり `analysis_run_manifest.yaml` を追加して、`analysis_logic_version`、`input_run_set`、`metric_set_version`、`phase_metric_profile_version`、`comparison_contract_version` を固定する段階です。



```
次へ
```

evaluation の Task 9 まで進めました。analysis manifest は [analysis_manifest_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/evaluation/analysis_manifest_writer.rb:1) と [write_analysis_manifest.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/write_analysis_manifest.rb:1) で生成し、出力は [analysis_run_manifest.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/manifests/analysis_run_manifest.yaml:1) に入ります。

検証では `ruby scripts/write_analysis_manifest.rb` を実行し、`analysis_logic_version: 0.1.0`、`input_run_set: [run-fixture-001]`、`metric_set_version: 0.1.0`、`phase_metric_profile_version: overlay-v1`、`comparison_contract_version: 0.1.0` が入ることを確認しました。implementation log も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:353) に追記済みです。

次は evaluation の Task 10-11 です。つまり
- invalid / `analysis_blocked` を含む evaluation fixture を追加する
- intake / admission / classification / metrics / comparison invalidity の smoke checks をまとめる

この 2 つを入れれば evaluation は一度まとまります。



```
次へ
```

evaluation の Task 10-11 まで完了です。追加した [validate_evaluation_pipeline.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/validate_evaluation_pipeline.rb:1) は実行済みで、`evaluation pipeline validation passed` を確認しました。invalid / `analysis_blocked` fixture も入り、evaluation は一度閉じてよい状態です。

次は依存順どおり `dual-reviewer-self-improvement` の Task 1 です。[phase-and-feature-dependency-map.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/phase-and-feature-dependency-map.md:95) でも、self-improvement は foundation/runtime/evaluation の後続です。最初にやるのは `learning/` 配下の directory skeleton と owner artifact placement の固定です。その次が evaluation outputs を読む signal intake です。

必要ならこのまま self-improvement Task 1 から着手します。



```
開始
```

self-improvement の Task 1 を開始し、完了しました。`learning/` の正本 skeleton を tracked に固定して、欠けていた [backtests](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/learning/backtests) と [rollback](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/learning/rollback) を追加し、各 subdir に `.gitkeep` を置いています。あわせて [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md:142) と [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:362) も更新しました。

次は self-improvement の Task 2 です。runtime / evaluation artifact から `review_quality_signal` / `workflow_failure_signal` / `evidence_quality_signal` を抽出する intake を実装します。



```
次へ
```

self-improvement の Task 2 を実装しました。runtime/evaluation artifact から signal を抽出する intake を [signal_intake.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/signal_intake.rb:1) に追加し、signal class の判定は [signal_class_classifier.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/signal_class_classifier.rb:1) に分離しています。CLI は [intake_self_improvement_signals.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/intake_self_improvement_signals.rb:1) です。verification 用に exploratory fixture も [exploratory_runtime_run](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/tests/fixtures/evaluation/local_runs/exploratory_runtime_run) として追加しました。implementation log は [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:375) に追記済みです。

確認では runtime intake で `valid / invalid / exploratory / analysis_blocked` の maturity を保持できること、evaluation intake で unresolved judgment label と caveat を signal 化できることを確認しています。evaluation 側は local/imported 重複で同一 `run_id` が二重化していたため、intake 内で dedupe も入れました。

次は self-improvement の Task 3 です。`learning/findings/recurring_failure_signals.json` と `learning/findings/workflow_failure_signals.json` の writer を作って、いまの intake を machine-readable inventory に固定する段階です。



```
次へ
```

self-improvement の Task 3 を実装しました。signal inventory writer を [signal_inventory_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/signal_inventory_writer.rb:1)、build CLI を [build_self_improvement_signal_inventory.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/build_self_improvement_signal_inventory.rb:1) に追加し、proposal 前 inventory を [recurring_failure_signals.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/learning/findings/recurring_failure_signals.json:1) と [workflow_failure_signals.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/learning/findings/workflow_failure_signals.json:1) に固定しました。各 entry には `signal_class`、`source_refs`、`validity_context`、`phase_profile`、`treatment`、`run_id`、`signal_value` を残しています。implementation log は [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:388) を更新済みです。

検証は `ruby scripts/build_self_improvement_signal_inventory.rb` で実施し、runtime/evaluation 由来 signal が 2 つの inventory に分離出力されることを確認しました。`workflow_failure` は invalid run の validator/invalidation に限定され、`recurring_failure` 側には exploratory、`analysis_blocked`、judgment unresolved、caveat が残っています。

次は self-improvement の Task 4-5 です。proposal artifact と provenance field を入れて、local run 由来と imported bundle 由来を proposal レベルで区別できるようにします。



```
次へ
```

self-improvement の Task 4-5 を実装しました。proposal 生成は [proposal_builder.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/proposal_builder.rb:1)、provenance 解決は [proposal_provenance_resolver.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/proposal_provenance_resolver.rb:1)、writer は [proposal_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/proposal_writer.rb:1)、CLI は [build_self_improvement_proposals.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/build_self_improvement_proposals.rb:1) です。出力は [proposal_index.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/learning/proposals/proposal_index.json:1) と `learning/proposals/*.yaml` に入ります。

`source_origin`、`source_repository_refs`、`source_admission_refs`、`source_provenance_status` を proposal artifact に持たせています。local runtime signal は `central_local_run`、evaluation 経由で admission register に載る imported signal は `imported_external_bundle` になります。たとえば [proposal-schema-unresolved-judgment-labels-run-fixture-001.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/learning/proposals/proposal-schema-unresolved-judgment-labels-run-fixture-001.yaml:1) は imported provenance と admission 情報を保持し、[proposal-workflow-validator-failed-run-invalid-001.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/learning/proposals/proposal-workflow-validator-failed-run-invalid-001.yaml:1) は central local run として分離されています。implementation log も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:401) に追記済みです。

検証は `ruby scripts/build_self_improvement_proposals.rb` で実施し、8 件の draft proposal を生成しました。次は self-improvement の Task 6 です。`review_case.json`、step artifacts、decision units、validation artifacts を proposal ごとに引く replay input preparation に入れます。



```
self-improvement の Task 6へ
```

self-improvement の Task 6 を実装しました。replay input resolver は [replay_input_resolver.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/replay_input_resolver.rb:1)、CLI は [prepare_self_improvement_replay_inputs.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/prepare_self_improvement_replay_inputs.rb:1) です。proposal の `target_layer` と `required_test_mode` に応じて、`review_case.json`、relevant `steps/*.json`、`decisions/decision_units.json`、validation artifacts を束ねて返します。

Step B / Step C replay を成立させるため、local/imported fixture に最小 step artifacts を追加し、対応する `review_case.step_records` も更新しました。[minimal_runtime_run/steps](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/tests/fixtures/evaluation/local_runs/minimal_runtime_run/steps)、[exploratory_runtime_run/steps](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/tests/fixtures/evaluation/local_runs/exploratory_runtime_run/steps)、[minimal_runtime_bundle/run/run-fixture-001/steps](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/tests/fixtures/evaluation/imported_bundles/minimal_runtime_bundle/run/run-fixture-001/steps) がそれです。bundle checksum も [bundle_checksums.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/tests/fixtures/evaluation/imported_bundles/minimal_runtime_bundle/checksums/bundle_checksums.json:1) で更新済みです。implementation log は [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:414) に追記しました。

検証は `ruby scripts/prepare_self_improvement_replay_inputs.rb proposal-prompt-human-decision-mix-run-exploratory-001` と `... proposal-prompt-human-decision-mix-run-fixture-001` で `replay_readiness: ready` を確認し、Step B / Step C refs が返ることを確認しました。あわせて `ruby scripts/intake_imported_bundle.rb tests/fixtures/evaluation/imported_bundles/minimal_runtime_bundle` を再実行し、step 追加後も checksum が全件 `matched`、`ingestion_status: complete` のままであることを確認しています。

次は self-improvement の Task 7 です。proposal ごとの [learning/backtests](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/learning/backtests) artifact を生成して、`supported / unsupported / inconclusive / untested` を machine-readable に残す段階です。



```
self-improvement の Task 7
```

self-improvement の Task 7 を実装しました。backtest builder は [backtest_builder.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/backtest_builder.rb:1)、writer は [backtest_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/backtest_writer.rb:1)、CLI は [build_self_improvement_backtests.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/build_self_improvement_backtests.rb:1) です。出力は [backtest_index.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/learning/backtests/backtest_index.json:1) と `learning/backtests/<proposal_id>.json` に入ります。

現状の prototype では、`replay` と `manual_review` は入力束や review gate が揃っていても実行器未実装なので `untested`、analysis artifact で substantiation できる `backtest` は `supported`、exploratory 由来の policy proposal は `inconclusive` としています。たとえば [proposal-schema-unresolved-judgment-labels-run-fixture-001.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/learning/backtests/proposal-schema-unresolved-judgment-labels-run-fixture-001.json:1) は `supported`、[proposal-prompt-human-decision-mix-run-exploratory-001.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/learning/backtests/proposal-prompt-human-decision-mix-run-exploratory-001.json:1) は `untested` です。implementation log も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:428) に追記しました。

検証は `ruby scripts/build_self_improvement_backtests.rb` で実行し、8 proposal 分の backtest artifact 生成を確認しました。次は self-improvement の Task 8-9 です。approval/adoption/rejection/rollback register を入れて、proposal loop の履歴側を閉じます。



```
self-improvement の Task 8-9
```

self-improvement の Task 8-9 を実装しました。proposal status の同期は [proposal_status_updater.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/proposal_status_updater.rb:1)、履歴 register の更新は [history_registry.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/history_registry.rb:1) に入れています。CLI は [record_self_improvement_decision.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/record_self_improvement_decision.rb:1) と [record_self_improvement_rollback.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/record_self_improvement_rollback.rb:1) です。register 本体は [adoption_register.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/learning/approved-updates/adoption_register.json:1)、[rejection_register.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/learning/rejected-updates/rejection_register.json:1)、[rollback_register.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/learning/rollback/rollback_register.json:1) を初期化しました。implementation log も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:441) に追記済みです。

確認は本 repo を汚さないよう一時コピー上で実施しています。そこで `approved` と `adopted` が別 entry として `adoption_register.json` に残ること、`rejection_register.json` に `rejection_reason` が入ること、`rollback_register.json` に `adopted_change_ref` と `rollback_trigger_signal_refs` が入ること、さらに proposal index の status が `rejected` / `rolled_back` に更新されることを確認しました。

これで self-improvement は Task 1-9 まで完了です。次は Task 10-12 で、pattern candidate helper、self-improvement fixture、smoke check を追加してこの feature を一度閉じる段階です。



```
Task 10-12
```

self-improvement の Task 10-12 を完了しました。pattern helper は [pattern_candidate_builder.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/pattern_candidate_builder.rb:1) と [pattern_candidate_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/pattern_candidate_writer.rb:1) に入れ、出力は [pattern_candidates.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/learning/findings/pattern_candidates.json:1) です。ここで `project_specific_concrete` と `meta_pattern_candidate` を分け、signal から pattern layer への導線を固定しました。

fixture は [tests/fixtures/self_improvement/proposals](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/tests/fixtures/self_improvement/proposals) に local/imported/workflow proposal を、[rollback_fixture.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/tests/fixtures/self_improvement/rollback/rollback_fixture.json:1) に rollback sample を追加しています。smoke validator は [validate_self_improvement_pipeline.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/validate_self_improvement_pipeline.rb:1) で、一時コピー上で signal intake、proposal provenance、imported evidence preservation、backtest artifact、approval vs adoption distinction、rollback registry を通すようにしました。implementation log も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:454) まで更新済みです。

検証は `ruby scripts/build_self_improvement_pattern_candidates.rb` と `ruby scripts/validate_self_improvement_pipeline.rb` で通っています。これで self-improvement tasks は一通り閉じました。次は依存順どおり paper-interface に入れます。



```
次の作業は？
```

次は `dual-reviewer-paper-interface` です。依存順では foundation → runtime → evaluation → self-improvement の次が paper-interface なので、ここに入るのが自然です。

開始順はたぶん次です。

1. Task 1
   `paper/` 配下の directory skeleton を固定する

2. Task 2-3
   evaluation artifact intake と claim/support mapping の入口を作る  
   ここで `experiments/analysis/` と `learning/` のどの artifact を paper 側が正本入力にするかを concrete にします

3. Task 4 以降
   caveat-preserving な paper-facing bundle / table / figure fragment を作る

いま重要なのは、paper-interface は runtime raw artifact を直接読まず、evaluation output と必要なら self-improvement の adopted history を参照する、という境界を守ることです。なので最初の実装も `experiments/analysis/` と `learning/approved-updates/` を intake する形から始めるのが正しいです。

進めるなら、そのまま paper-interface の Task 1 から着手します。



```
Task 1 から着手
```

paper-interface の Task 1 を開始し、完了しました。`paper/` の正本 skeleton を tracked に固定し、[reports](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/paper/reports)、[tables](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/paper/tables)、[figures](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/paper/figures) に加えて、欠けていた [caveats](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/paper/caveats) を追加しています。各 subdir には `.gitkeep` を置いています。

あわせて [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md:176) と [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:467) も更新しました。

次は paper-interface の Task 2 です。`experiments/analysis/` を読む intake loader を入れて、runtime raw artifact を再読せずに paper 側が必要 input を取れるようにします。



```
Task 2 へ
```

paper-interface の Task 2 を実装しました。evaluation intake loader は [evaluation_intake_loader.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/evaluation_intake_loader.rb:1)、CLI は [intake_paper_evaluation_outputs.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/intake_paper_evaluation_outputs.rb:1) です。必須入力として `analysis_run_manifest.yaml`、`treatment_comparisons.json`、`phase_comparisons.json`、`exclusion_report.json`、`caveat_register.json` を読み、`metrics/*.json` は optional で読みます。これで paper-interface は runtime raw artifact を再読せずに必要 input を得られます。

検証は `ruby scripts/intake_paper_evaluation_outputs.rb experiments/analysis` で実施し、required/optional ともに欠損なし、`intake_status: complete` を確認しました。summary では `analysis_logic_version: 0.1.0`、`treatment_comparison_status: invalid`、`phase_comparison_status: valid`、`caveat_count: 1` が取れています。implementation log も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:480) に追記済みです。

次は paper-interface の Task 3 です。`paper/reports/claim_map.json` を作って、claim と evaluation artifact の対応を central mapping として固定します。



```
Task 3 へ
```

paper-interface の Task 3 を実装しました。claim map の builder は [claim_map_builder.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/claim_map_builder.rb:1)、writer は [claim_map_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/claim_map_writer.rb:1)、CLI は [build_paper_claim_map.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/build_paper_claim_map.rb:1) です。出力は [claim_map.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/paper/reports/claim_map.json:1) に入ります。

現状の claim は 3 本です。phase comparison summary、treatment comparison status、analysis population transparency で、それぞれ `supporting_artifact_refs`、`maturity_label`、`caveat_refs`、`provenance_refs` を持ちます。treatment comparison は `insufficient_variant_count` と caveat を受けて `preliminary`、phase comparison は現状 `mature` です。implementation log も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:493) に追記済みです。

検証は `ruby scripts/build_paper_claim_map.rb` で実施し、`claim_count=3` を確認しました。次は paper-interface の Task 4 です。`paper/reports/evidence_register.json` を作って、analysis manifest と run set provenance を paper-facing registry に固定します。



```
Task 4へ
```

paper-interface の Task 4 を実装しました。evidence register の builder は [evidence_register_builder.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/evidence_register_builder.rb:1)、writer は [evidence_register_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/evidence_register_writer.rb:1)、CLI は [build_paper_evidence_register.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/build_paper_evidence_register.rb:1) です。出力は [evidence_register.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/paper/reports/evidence_register.json:1) に入ります。

今回は `claim_map.json` の supporting artifact を正規化し、各 artifact について `source_analysis_manifest_ref`、`input_run_set_ref`、`maturity_label`、`caveat_refs`、`generated_at` を固定しています。現状は 5 entry で、`phase_comparisons.json` が `mature`、`treatment_comparisons.json` や `exclusion_report.json` は caveat 付きで `preliminary` です。implementation log も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:506) に追記済みです。

検証は `ruby scripts/build_paper_evidence_register.rb` で実施し、`evidence_count=5` を確認しました。次は paper-interface の Task 5 です。`paper/tables/table_source_bundle.json` を作って、表生成前の source selection と field projection を machine-readable に固定します。



```
Task 5へ
```

paper-interface の Task 5 を実装しました。table source bundle の builder は [table_source_bundle_builder.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/table_source_bundle_builder.rb:1)、writer は [table_source_bundle_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/table_source_bundle_writer.rb:1)、CLI は [build_paper_table_source_bundle.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/build_paper_table_source_bundle.rb:1) です。出力は [table_source_bundle.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/paper/tables/table_source_bundle.json:1) に入ります。

今回は `table-analysis-summary-v1` を 1 本作っています。phase/treatment comparison、exclusion report、caveat register、analysis manifest を source にし、どの field を表に投影するかを `field_projection` に明示しました。bundle の maturity は関連 evidence の最も弱いラベルに揃えるので `preliminary`、caveat は `single_treatment_only` を保持しています。implementation log も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:519) に追記済みです。

検証は `ruby scripts/build_paper_table_source_bundle.rb` で実施し、`table_bundle_count=1` を確認しました。次は paper-interface の Task 6 です。`paper/figures/figure_source_bundle.json` を作って、plot grouping / slice / metric selection を machine-readable に固定します。



```
Task 6へ
```

paper-interface の Task 6 を実装しました。figure source bundle の builder は [figure_source_bundle_builder.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/figure_source_bundle_builder.rb:1)、writer は [figure_source_bundle_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/figure_source_bundle_writer.rb:1)、CLI は [build_paper_figure_source_bundle.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/build_paper_figure_source_bundle.rb:1) です。出力は [figure_source_bundle.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/paper/figures/figure_source_bundle.json:1) に入ります。

今回は `figure-phase-treatment-overview-v1` を 1 本作っています。source は `phase_comparisons.json`、`treatment_metrics.json`、`treatment_comparisons.json` で、`plot_contract` に chart family、slice/grouping、metric fields、status annotations を明示しました。maturity は source evidence に合わせて `preliminary`、caveat は `single_treatment_only` を継承しています。implementation log も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:532) に追記済みです。

検証は `ruby scripts/build_paper_figure_source_bundle.rb` で実施し、`figure_bundle_count=1` を確認しました。次は paper-interface の Task 7 です。`paper/caveats/paper_caveat_register.json` を作って、evaluation caveat を paper-facing limitation 単位へ再配置します。



```
Task 7へ
```

paper-interface の Task 7 を実装しました。paper caveat register の builder は [paper_caveat_register_builder.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/paper_caveat_register_builder.rb:1)、writer は [paper_caveat_register_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/paper_caveat_register_writer.rb:1)、CLI は [build_paper_caveat_register.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/build_paper_caveat_register.rb:1) です。出力は [paper_caveat_register.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/paper/caveats/paper_caveat_register.json:1) に入ります。

現状は `single_treatment_only` を paper-facing limitation に再配置していて、`applies_to_claim_refs` には treatment comparison と population transparency の claim、`applies_to_artifact_refs` には table/figure bundle を結びつけています。`limitation_type` は `insufficient_comparison_coverage`、`narrative_note` も付与しています。implementation log も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:545) に追記済みです。

検証は `ruby scripts/build_paper_caveat_register.rb` で実施し、`paper_caveat_count=1` を確認しました。次は paper-interface の Task 8 です。`paper/reports/reporting_fragments.json` を作って、claim summary / limitation note / comparison summary などの manuscript 非依存 fragment を structured に残します。



```
Task 8へ
```

paper-interface の Task 8 を実装しました。reporting fragments の builder は [reporting_fragments_builder.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/reporting_fragments_builder.rb:1)、writer は [reporting_fragments_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/reporting_fragments_writer.rb:1)、CLI は [build_paper_reporting_fragments.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/build_paper_reporting_fragments.rb:1) です。出力は [reporting_fragments.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/paper/reports/reporting_fragments.json:1) に入ります。

現状は 5 fragment です。`comparison_summary` 1 件、`claim_summary` 2 件、`limitation_note` 1 件、`method_note` 1 件で、すべて `source_artifact_refs`、`maturity_label`、`caveat_refs`、`text_stub` を持ちます。phase comparison は caveat なしの `mature`、treatment comparison と population transparency は `preliminary` かつ caveat 付き、method note は analysis manifest 起点です。implementation log も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:558) に追記済みです。

検証は `ruby scripts/build_paper_reporting_fragments.rb` で実施し、`fragment_count=5` を確認しました。次は paper-interface の Task 9 です。self-improvement の adopted history を、performance claim と混同しない `methodology-note` 向け optional linkage として入れます。



```
Task 9
```

paper-interface の Task 9 を実装しました。methodology-note linkage の builder は [methodology_note_linkage_builder.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/methodology_note_linkage_builder.rb:1)、writer は [methodology_note_linkage_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/methodology_note_linkage_writer.rb:1)、CLI は [build_paper_methodology_note_linkage.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/build_paper_methodology_note_linkage.rb:1) です。出力は [methodology_note_linkage.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/paper/reports/methodology_note_linkage.json:1) に入ります。

この path は self-improvement の adopted history を optional に読むだけで、performance claim の support に使わない前提を `claim_support_allowed: false` で固定しています。現状の `learning/approved-updates/adoption_register.json` は空なので、今回の出力も `entries: []` です。つまり linkage path 自体は成立していて、adopted history が将来入った時だけ methodology note に展開されます。implementation log も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:571) に追記済みです。

検証は `ruby scripts/build_paper_methodology_note_linkage.rb` で実施し、`methodology_note_count=0` を確認しました。次は paper-interface の Task 10-11 です。fixture と smoke checks を追加して、この feature も一度閉じる段階です。



```
Task 10-11へ
```

paper-interface の Task 10-11 を完了しました。fixture は [tests/fixtures/paper_interface](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/tests/fixtures/paper_interface) に追加し、minimal claim map、mixed evidence register、mixed paper caveat register、imported evidence provenance sample を置いています。smoke validator は [validate_paper_interface_pipeline.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/validate_paper_interface_pipeline.rb:1) です。

この validator は一時コピー上で intake、claim/evidence register、table/figure bundle、paper caveat register、reporting fragments、methodology-note linkage まで通し、次を確認します。claim map traceability、evidence manifest provenance、table/figure field contract、caveat retention、`no silent strengthening`、methodology-note separation です。実行結果は `paper-interface pipeline validation passed` でした。implementation log も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:584) に追記済みです。

これで paper-interface tasks も一通り閉じました。つまり foundation / runtime / evaluation / self-improvement / paper-interface の全 feature が prototype 実装まで揃った状態です。次の自然な作業は 1 回区切って commit することです。



```
コミット
```

commit しました。branch `codex/dual-reviewer-foundation` に `d20d08c` (`Implement evaluation, self-improvement, and paper-interface prototypes`) が追加されています。

今回の commit には `dual-reviewer-rebuild/` 配下の実装だけを含めています。親 repo にはまだ未コミットの別変更が残っています。`.claude/settings.local.json`、`docs/dual-reviewer-log-10.md`、`docs/DR-rebuild-log-1.md`、`docs/DR-rebuild-log-2.md`、`docs/dual-reviewer-rebuild-plan.md` は今回の commit に含めていません。

次はこの branch を `git push` するか、必要ならその前に軽く見直します。

::git-stage{cwd="/Users/Daily/Development/Rwiki-dev"}
::git-commit{cwd="/Users/Daily/Development/Rwiki-dev"}



```
見直してプッシュしてください
```

見直しでは重大な問題は見つかっていません。`git show --stat HEAD` で commit 範囲を確認し、`ruby scripts/validate_evaluation_pipeline.rb`、`ruby scripts/validate_self_improvement_pipeline.rb`、`ruby scripts/validate_paper_interface_pipeline.rb` を再実行して、いずれも通過しました。

そのうえで `codex/dual-reviewer-foundation` を push 済みです。最新は `d20d08c` (`Implement evaluation, self-improvement, and paper-interface prototypes`) です。親 repo には今回 push に含めていない別変更が引き続き残っています。`.claude/settings.local.json`、`docs/dual-reviewer-log-10.md`、`docs/DR-rebuild-log-1.md`、`docs/DR-rebuild-log-2.md`、`docs/dual-reviewer-rebuild-plan.md` です。

次にやるなら、この branch で PR を切る段階です。

::git-push{cwd="/Users/Daily/Development/Rwiki-dev" branch="codex/dual-reviewer-foundation"}



```
PRはあとで。
```

了解です。PR は保留で問題ありません。branch は push 済みなので、必要になった時点でそのまま切れます。

現時点では `dual-reviewer-rebuild` の prototype 一巡が branch 上に載っている状態です。次に進めるなら、1. review 観点で全体を棚卸しする、2. 実運用寄りの fixture や real payload を厚くする、3. open issue を spec/coordination に戻して整理する、のどれかです。



```
1を実行
```

**ここでauto-compactが入る**

**Findings**

1. [P1] Adoption gate currently allows unapproved proposals to become `adopted`. In [history_registry.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/history_registry.rb:37), `record_adoption` only checks `ensure_approved_or_tested!`, and that helper accepts `draft` and `awaiting_test` statuses at [history_registry.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/history_registry.rb:102). This conflicts with the design’s adoption gate, which says `adopted` requires `approved` plus required test artifact plus repo change/version linkage at [design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/design.md:302). As written, a runtime-affecting proposal can skip human approval and still be recorded as adopted.

2. [P2] Replay input resolution for local runs is hard-coded to four fixture directories, so new local fixtures or alternate run locations will silently fail replay preparation. In [replay_input_resolver.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/replay_input_resolver.rb:64), `central_local_run` resolution only searches `experiments/runs/<run_id>` and four named fixture paths. That works for today’s smoke data, but any additional fixture or generated local run outside those exact paths will return `unresolved_run_root`, which makes replay readiness a false negative.

3. [P2] Paper evidence-to-caveat linkage is based on a filename substring heuristic that does not represent actual artifact scope. In [evidence_register_builder.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/evidence_register_builder.rb:46), caveats are treated as artifact-specific only if the caveat ref string happens to include the artifact basename. Current caveat refs are keyed by caveat code, not artifact filename, so this logic is effectively accidental. The result is unstable caveat attachment in `evidence_register.json`, which weakens the paper-interface traceability guarantees.

**Assumptions / open points**
- I treated this as a review, not a fix pass.
- Smoke validation still passes: evaluation, self-improvement, and paper-interface validators all succeeded.
- I did not find a broader prototype blocker beyond the three issues above, but the first one should be corrected before trusting adoption history.

```
日本語で回答し直して
```

**指摘**
1. [P1] adoption gate が未承認 proposal を `adopted` にできてしまいます。[history_registry.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/history_registry.rb:37) の `record_adoption` は `ensure_approved_or_tested!` だけを見ていますが、この helper は [history_registry.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/history_registry.rb:102) で `draft` と `awaiting_test` も許可しています。一方、spec では `adopted` 条件は `approved` 済みであること、required test artifact があること、repo change が version update に結びつくことです。[design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/design.md:302) このままだと human approval を経ていない runtime-affecting change が adoption register に載りえます。

2. [P2] local run の replay input 解決が fixture 名に強く依存しており、少しデータが増えるだけで偽の `unresolved_run_root` になります。[replay_input_resolver.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/replay_input_resolver.rb:64) では `central_local_run` に対して `experiments/runs/<run_id>` と、4 つの固定 fixture path しか探索していません。現状の smoke には足りますが、新しい fixture や別配置の local run を追加すると replay readiness が不正に `unresolved_run_root` になります。

3. [P2] paper evidence と caveat の紐付けが filename 部分一致のヒューリスティックで、artifact scope を正しく表現していません。[evidence_register_builder.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/evidence_register_builder.rb:46) では caveat ref に artifact basename が含まれるかで artifact-specific かどうかを判定しています。しかし現在の caveat ref は artifact 名ではなく caveat code ベースなので、この判定は実質的に偶然に依存しています。結果として `evidence_register.json` の caveat 付与が不安定で、paper-interface の traceability を弱めます。

**前提 / 補足**
- 今回は修正ではなく review として見ています。
- smoke validation は再実行済みで、evaluation / self-improvement / paper-interface はすべて通っています。
- prototype 全体を止めるほどではありませんが、1 点目は adoption history の信頼性に直結するので先に直すべきです。



```
3点とも対応できるか
```

はい、3点とも対応できます。性質はそれぞれ違いますが、いずれも prototype 段階で十分修正可能です。

1. adoption gate
   これは素直に直せます。`adopted` を `approved` 済み proposal のみに制限し、required test artifact と linked repo change の条件を明示的にチェックする形にすればよいです。3点の中では最優先です。

2. replay input resolution
   これも対応しやすいです。固定 fixture 名の列挙をやめて、`tests/fixtures/evaluation/local_runs/*/run_manifest.yaml` や `experiments/runs/*/run_manifest.yaml` を走査して `run_id` で引く形に変えれば、fixture 追加にも耐えます。

3. evidence-caveat linkage
   これも可能ですが、少しだけ方針を明確にしたほうがよいです。今の basename 部分一致をやめて、claim 側または caveat 側に `applies_to_artifact_refs` のような明示フィールドを持たせ、その参照で結ぶのが正しいです。修正自体は難しくありません。

順番としては `1 -> 2 -> 3` が妥当です。必要ならその順でそのまま修正まで進めます。



```
ちなみに、このレビューは記録されて、エビデンスになる？
```

そのままでは弱いです。会話としては残っていますが、現状の repo 設計上は「実装レビュー結果の正本 artifact」にはなっていません。

いま記録として成立しているのは主に次の2系統です。

- 実装判断の記録
  [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:1)

- 手戻りや不安定点の兆候
  [implementation-signal-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-signal-register.md:1)

今回の 3 指摘は、少なくとも `implementation-signal-register` には落とせます。特に:
- adoption gate が spec と不整合
- replay resolver が fixture hard-code
- evidence-caveat linkage が heuristic 依存

は、どれも明確な implementation signal です。

さらに「レビュー証跡」として強くしたいなら、別に 1 枚 `review note` を切るのがよいです。たとえば:

- `docs/reviews/2026-05-09-prototype-shelf-review.md`

のようなファイルを作って、
- review scope
- reviewed commit
- findings
- severity
- recommended action
- disposition

を残す形です。これなら後で「どの commit に対して何を見たか」が追えます。

実務的には次のどちらかです。

1. 軽く残す
   `implementation-signal-register` に 3 件追加する

2. 証跡として残す
   `docs/reviews/...md` を新設し、今回のレビューを 1 本の review artifact にする

エビデンス性を考えると `2` のほうが良いです。必要ならそのまま review artifact を作り、signal register にもリンクを張ります。



```
さきほどの「eview 観点で全体を棚卸しする」とは、どのような状況で何をしたことに相当するのか
```

ここで言っていた「review 観点で全体を棚卸しする」は、実装をさらに足す前に、いま積み上がった prototype 一式を「仕様に対して危ないところがないか」という観点で横断点検することです。

今回の文脈では、だいたい次をしたことに相当します。

1. 対象範囲を固定する
   どの commit / branch を見るかを決める。今回は `codex/dual-reviewer-foundation` 上の prototype 実装一式です。

2. 動作確認をする
   smoke check を回して、「少なくとも今は壊れていない」ことを確認する。今回は evaluation / self-improvement / paper-interface の validator を再実行しました。

3. 仕様境界を点検する
   通るかどうかではなく、
   - approval と adoption が混線していないか
   - fixture 依存の仮実装が本番前提に化けていないか
   - provenance / caveat / traceability が silent に弱まっていないか
   のような点を見る。今回の 3 指摘はここから出ています。

4. 設計書と照合する
   code だけで判断せず、spec / design / dependency map と見比べて、「この挙動は意図どおりか」を確認する。adoption gate の指摘はこれに当たります。

5. 手戻り候補を抽出する
   今すぐ壊れていなくても、後で効いてくる点を findings として切り出す。つまり「実装修正前の品質監査」に近いです。

なので、これは「コードを書いた」というより、
- 実装済み範囲を対象に
- 検証を再実行し
- 仕様とのズレや将来の破綻点を洗い出し
- 修正優先度をつけた

という作業です。

別の言い方をすると、feature 開発の次にやる「棚卸し」は、
- 実装追加ではない
- 受け入れテストだけでもない
- 仕様準拠性、境界条件、証跡性を見る review

に当たります。今回なら「prototype 一巡後の shelf review」を 1 回入れた、という理解でよいです。



```
仕様準拠性、境界条件、証跡性を見る reviewという観点は、dual-reviewerの当初仕様には入ってなかったと思うが、今回のレビューを見ると必要だよね
```

はい。今回の結果を見る限り、必要です。

もともとの `dual-reviewer` 仕様は、
- artifact を分ける
- phase 依存を守る
- provenance や caveat を落とさない
- approval / adoption を分離する

という構造は持っていました。ですが、「実装がその構造を本当に守っているかを、feature 完了後に横断確認する review step」は、独立した工程としては明文化されていませんでした。そこが今回露出した不足です。

実際、今回見つかった 3 点はどれも、
- テストは通る
- prototype は動く
- でも仕様境界は破りうる

という種類の問題です。これは通常の task 実装や smoke check だけでは拾いきれません。なので、`仕様準拠性 / 境界条件 / 証跡性を見る review` は、実質的に別レイヤの作業として必要です。

整理すると、追加で必要なのは次です。

1. review 工程の明文化
   feature 実装完了後に `prototype shelf review` か `implementation conformance review` を入れる。

2. review artifact の正本化
   `docs/reviews/...md` のような形で、対象 commit、review scope、findings、severity、disposition を残す。

3. signal / coordination との接続
   review で出た指摘を `implementation-signal-register` や handback 判断に接続する。

4. 完了条件の補強
   「task が終わった」だけでなく、「smoke passed + shelf review passed or findings recorded」を区切りにする。

要するに、当初仕様に明示では入っていなかったが、今の prototype 規模と設計厳密さなら、もう必要条件です。

次にやるなら自然なのは2つです。

- 今回のレビューを review artifact として正式に残す
- そのうえで spec / coordination に `implementation conformance review` を追加する

必要ならその 2 つをそのまま作業します。



```
それを測るメトリックの設計も要る
```

要ります。しかも `review を入れる` だけでは足りず、`review が機能しているか` を測るメトリックまで設計しないと、形だけの工程になります。

今回の文脈だと、少なくとも 3 系統に分けるのがよいです。

**1. 仕様準拠性メトリック**
実装が spec/design の制約をどれだけ守れているかを見る指標です。

- `conformance_findings_count`
  1 回の shelf review で見つかった仕様不整合件数
- `severity_weighted_finding_score`
  P1/P2/P3 に重みをつけた合計
- `post-smoke_nonconformance_count`
  smoke passed 後に見つかった不整合件数
- `requirement_coverage_gap_count`
  requirements のうち、実装済みだが review で根拠が弱い項目数

今回の 3 件はまさにここです。特に「smoke は通るが spec 境界を破る」は強いシグナルです。

**2. 境界条件メトリック**
仮実装や fixture 依存、 silent fallback のような壊れ方の兆候を見る指標です。

- `fixture_bound_resolution_count`
  固定 fixture 名や固定 path に依存する解決ロジック件数
- `heuristic_linkage_count`
  basename 部分一致など、構造化参照ではなく heuristic で結んでいる箇所数
- `placeholder_or_deferred_count`
  deferred / placeholder 実装の残数
- `manual_exception_paths_count`
  特例分岐の数
- `unresolved_runtime_refs_rate`
  replay/input resolution で解決失敗する割合

今回の replay resolver と evidence-caveat linkage はここに入ります。

**3. 証跡性メトリック**
あとで「なぜそうなったか」を説明できるかを見る指標です。

- `review_artifact_presence_rate`
  実装区切りごとに review artifact が残っている割合
- `finding_to_signal_link_rate`
  review finding が signal register に接続されている割合
- `finding_to_fix_trace_rate`
  finding から修正 commit / disposition へ辿れる割合
- `artifact_trace_completeness`
  claim / caveat / adoption / rollback が source ref を持つ割合
- `silent_decision_count`
  判断は起きたが coordination / review artifact に残っていない件数

今回の状態だと、会話はあるが review artifact 正本はまだないので、この軸は弱いです。

**運用上は、まず少数で十分です**
最初から増やしすぎると回りません。prototype 段階なら、まずはこの 6 つで足ります。

- `conformance_findings_count`
- `severity_weighted_finding_score`
- `post-smoke_nonconformance_count`
- `fixture_bound_resolution_count`
- `heuristic_linkage_count`
- `review_artifact_presence_rate`

これで、
- 通ったけど危ない実装がどれだけあるか
- その危なさが減っているか
- review が証跡として残っているか

を見られます。

**次に必要なのは定義の固定です**
つまり spec/coordination に、
- metric 名
- 定義
- 算出単位
- 計測タイミング
- 閾値または解釈
を持たせることです。

必要なら次にやるべき作業はこれです。

1. `implementation conformance review` を工程として spec に追加する
2. review artifact テンプレートを作る
3. conformance metric register を作る

この 3 点はセットで入れるのがよいです。



```
作業よろしく
```

review 工程とメトリック設計を追加しました。工程定義は [implementation-conformance-review.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-conformance-review.md:1)、metric 定義台帳は [implementation-conformance-metric-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-conformance-metric-register.md:1) です。これで `task 完了 + smoke pass` の後に、仕様準拠性・境界条件・証跡性を見る `implementation conformance review` を正式工程として扱えます。

あわせて今回の棚卸し自体を review artifact として [2026-05-09-prototype-shelf-review.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/2026-05-09-prototype-shelf-review.md:1) に残し、3 finding を [implementation-signal-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-signal-register.md:149) に signal 化し、[implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:749) に review 実施記録を追加しました。`DOCUMENT_INDEX.md` も更新済みです。[DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md:142)

今回の変更は文書のみで、コード修正はまだ入れていません。次は review artifact に沿って、P1 の adoption gate、続いて replay resolver と evidence-caveat linkage を直す段階です。なお親 repo には今回触っていない既存の未整理変更も引き続き残っています。



```
追加したレビュープロセスはなんと呼ぶのが良いか
```

今の内容なら、第一候補は `implementation conformance review` です。

これがよい理由は、
- code review 一般ではなく、実装が spec / design / boundary / evidence を守っているかを見る
- smoke test や validator pass と区別しやすい
- findings がそのまま `nonconformance` として表現できる

からです。

候補を整理するとこうです。

1. `implementation conformance review`
   いちばん無難です。仕様準拠性を中心に、境界条件と証跡性まで含めやすいです。

2. `prototype shelf review`
   今回やったことのニュアンスには近いですが、少し口語的で、工程名としては弱めです。

3. `implementation integrity review`
   きれいですが、何に対する integrity かが少し広いです。spec 準拠レビューだと一目で分かりにくいです。

4. `post-implementation conformance review`
   正確ですが少し長いです。文書名や会話では冗長です。

実務上のおすすめはこうです。

- 正式名称: `implementation conformance review`
- 通称: `conformance review`
- 今回のような区切りでの呼び方: `prototype conformance review`

つまり、
- 工程名としては `implementation conformance review`
- 個別実施名としては `2026-05-09 prototype conformance review`

にすると運用しやすいです。必要なら、追加した文書名や見出しもこの呼称に揃えて整えます。



```
一通り実装した後に、implementation conformance reviewを追加したことによって、ワークフローのルールに従うと、どうなりますか
```

ルール上は、「一通り実装したら終わり」ではなくなります。`implementation conformance review` を入れたことで、prototype 一巡後にもう 1 段階の品質ゲートが追加された形です。

流れで言うと、今後はこうなります。

1. tasks を実装する
2. smoke validator を通す
3. `implementation conformance review` を実施する
4. finding がなければその区切りを完了扱いにする
5. finding があれば、signal / review artifact / disposition を残し、必要なら修正してから閉じる

つまり completion rule は、すでに追加した [implementation-conformance-review.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-conformance-review.md:108) のとおり、
- task 完了
- relevant smoke validator pass
- conformance review 実施
- finding 0 件、または finding が記録され disposition が付いている

までが 1 セットです。

今回の状態に当てはめると、こう解釈されます。

- 実装一巡は完了している
- smoke も通っている
- conformance review も実施済み
- ただし finding が 3 件ある

なので、「無条件に完了」ではなく、
- review artifact 付きの暫定完了
- ただし open finding を抱えた状態

です。ワークフロー上は破綻していません。なぜなら、finding を artifact として残し disposition も付けているので、completion rule の後半を満たしているからです。

ただし運用上は優先度が分かれます。

- P1 は次 feature へ進む前に直す
- P2 は同一 branch で順次直す
- もし修正で設計境界が変わるなら `B`
- requirement contract 不足なら `C`

今回の 3 件はいまの記録では `A` 扱いですが、修正中に設計見直しが必要と分かれば handback を上げます。

要するに、`implementation conformance review` を追加した後のルールでは、
「実装して動いた」で閉じず、
「実装して動かし、横断 review を通し、finding を処理または記録して初めて区切る」
になります。今回の branch はその新ルールで見ると、`review 済み・finding 付きの完了状態` です。



```
それだと、タスクからのやり直しだけだ。今回は、仕様レベルでの変更ではないか？
```

はい。その指摘は正しいです。今回やったことを厳密に扱うなら、これは単なる task 後の運用追加ではなく、仕様レベルの変更です。

理由は、`implementation conformance review` が次を変えているからです。

- 完了条件
- 実装後の必須工程
- 証跡として残す artifact
- finding 発生時の扱い
- handback 判断の入口

これは「実装のしかた」ではなく、「このプロジェクトで何をもって完了とするか」というルール変更です。つまり workflow contract の変更です。補助資料だけで済ませるには重いです。

なので、ルールに厳密に従うなら本来はこうです。

1. workflow / governance レイヤの requirements を更新する
2. それに対応する design を更新する
3. そのうえで tasks を更新する
4. その後に conformance review 文書や metric register を実装する

今の状態は、
- 必要性は明確
- 先に補助文書として具体化した
- しかし正本 spec への反映はまだ

という順序です。言い換えると、いま追加したものは「仕様変更案を具体化した先行実装」に近いです。

したがって整理としては次のどちらかです。

1. いまの追加を暫定運用とみなす  
   `docs/coordination/` と `docs/reviews/` は先行導入として扱い、続けて workflow 正本へ昇格する

2. これは仕様変更だと明示する  
   workflow/governance を管理する spec を新設するか、既存の上位文書に `implementation conformance review` を正式ルールとして入れる

実務的には `2` が正しいです。今回の変更は feature spec というより、repo 全体の implementation governance 変更です。だから `dual-reviewer-*` の個別 feature task に戻るというより、上位の workflow contract を 1 つ起こして、そこで requirements/design/tasks を切るべきです。

要するに、
- 「task のやり直し」ではない
- 「workflow 仕様の追加」
- なので本来の正しい置き場は coordination 文書だけではなく、上位 spec

です。

次にやるべきなのは、`implementation governance` か `review governance` のような上位 spec を作り、そこに `implementation conformance review` を正式ルールとして昇格させることです。必要ならその spec 起票から進めます。



```
spec 起票から進めて実装まで終了。その時点で、implementation conformance reviewを実施すると、先に指摘した3点が再び指摘されるか？
```

はい。`implementation governance` の spec を起票して、requirements/design/tasks を通し、その spec 自体の実装まで終えたあとに `implementation conformance review` を実施した場合、コードを直していなければ、その 3 点は再び指摘されます。

理由は単純で、今回の 3 点は workflow 文書の不備ではなく、既存実装の nonconformance だからです。

- adoption gate の不整合
  [history_registry.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/history_registry.rb:37)
- replay resolver の fixture 固定依存
  [replay_input_resolver.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/replay_input_resolver.rb:56)
- evidence-caveat linkage の heuristic 依存
  [evidence_register_builder.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/evidence_register_builder.rb:46)

新しい spec は「そのレビューを正式工程にする」だけで、既存コードの挙動は自動では変えません。なので順序としてはこうです。

1. governance spec を起票して正式化する
2. その spec に基づく artifact / process 実装を入れる
3. 既存の 3 finding を修正する
4. その後に conformance review を再実施する

この 4 までやれば、再 review で 3 点は消える可能性があります。逆に 3 を挟まなければ、review は同じ 3 点を再発見するはずです。つまり、spec 正式化は必要ですが、今回の 3 件に対する closure にはなりません。



```
だとすると、指摘された3点を今修正しなくてもよいね。
```

はい、その判断は成り立ちます。

今回の 3 点は「いますぐ runtime が全く動かない不具合」ではなく、`implementation conformance review` を正式工程にしたときに確実に残件として再検出される nonconformance です。なので順序として、

1. governance / workflow spec を正式化する
2. conformance review を上位ルールとして正本化する
3. そのルールの下で open finding を修正する

と進めるのは合理的です。

ただし、2 点だけ明確にしておくべきです。

- 3 finding は「未修正でよい」のであって、「解消済み」ではありません  
  いまは [2026-05-09-prototype-shelf-review.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/2026-05-09-prototype-shelf-review.md:1) と [implementation-signal-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-signal-register.md:149) に open として残っている、という扱いです。

- governance spec を入れた後の再 review では、コードを直していなければ再指摘されます  
  つまり先送りは可能ですが、消えるわけではありません。

なので次の正しい作業は、3 点の即修正ではなく、`implementation governance` あるいは `review governance` の spec 起票です。そこを正本化してから、open finding を backlog として回収するのが筋です。



```
進めよう。
```

`dual-reviewer-implementation-governance` を spec 起票から実装まで通しました。spec は [requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/requirements.md:1)、[design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/design.md:1)、[tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/tasks.md:1)、[spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/spec.json:1) に追加しました。これで `implementation conformance review` は補助運用ではなく、repo 全体の completion rule を持つ cross-cutting spec になりました。

実装としては、review template を [implementation-conformance-review-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/implementation-conformance-review-template.md:1) に追加し、既存の procedure / metric register / review artifact を governance spec の owner artifact として接続しました。あわせて [validate_implementation_governance_artifacts.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/validate_implementation_governance_artifacts.rb:1) を実装し、`ruby dual-reviewer-rebuild/scripts/validate_implementation_governance_artifacts.rb` で `implementation governance artifact validation passed` を確認しています。依存順と feature 一覧も [phase-and-feature-dependency-map.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/phase-and-feature-dependency-map.md:37) と [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md:94) に反映済みです。

この時点で重要なのは、governance spec を正式化しても既存コードの nonconformance 自体は自動では消えないことです。したがって今ここで `implementation conformance review` を再実施すると、先に記録した 3 点はコード未修正のままなので再び指摘されます。今回閉じたのは workflow contract と review evidence の正本化で、3 finding の解消は次の別作業です。



```
次の作業は？
```

次は、governance spec の下で open finding を回収する実装修正です。順番はこの 3 つでよいです。

1. `P1` adoption gate 修正  
   [history_registry.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/history_registry.rb:37) を直し、`adopted` を `approved` 済み proposal のみに制限し、required test artifact と linked repo change 条件を明示します。

2. `P2` replay resolver の汎化  
   [replay_input_resolver.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/replay_input_resolver.rb:56) の fixture 固定探索をやめて、`run_manifest.yaml` ベースの generic discovery にします。

3. `P2` evidence-caveat linkage の構造化  
   [evidence_register_builder.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/evidence_register_builder.rb:46) の basename heuristic をやめて、artifact-scoped ref で結ぶようにします。

この 3 件を直したあとに、smoke と `implementation conformance review` を短く再実施するのが正しい流れです。進めるなら 1 から着手します。



```
仕様のフィーチャー間調整レビューは必要ないか？
```

必要です。今回の `implementation governance` は cross-cutting spec なので、本来は feature 間調整レビューの対象です。

理由は 2 つです。

1. completion rule が全 feature に波及する  
   `foundation / runtime / evaluation / self-improvement / paper-interface` のどれも、今後は `implementation conformance review` を通って閉じる前提になります。これは単独 feature の内部変更ではありません。

2. dependency map と phase progression を変えている  
   すでに [phase-and-feature-dependency-map.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/phase-and-feature-dependency-map.md:37) で `implementation conformance review` を phase に追加し、`implementation-governance` を post-implementation gate として入れています。これは明確に横断調整事項です。

ただし、既存 5 feature の data contract や artifact ownership を壊してはいないので、重い再設計レビューではなく、軽い cross-spec alignment で足ります。見るべき点は次です。

- 各 feature の完了条件に governance をどう接続するか
- `implementation-governance` が feature spec を置き換えていないか
- `A/B/C` handback と conformance finding の関係が矛盾していないか
- `docs/coordination/` と spec 正本の役割分担が明確か

要するに、必要なのは
- feature logic の再レビューではなく
- governance 追加に対する cross-feature coordination review

です。

次の正しい作業順はこうです。

1. `implementation-governance` の cross-spec alignment memo を追加する
2. 必要なら既存 feature spec に completion rule の参照を最小追記する
3. その後に open finding 3 件の修正へ進む

必要なら、この alignment review 文書をそのまま作ります。



```
事前に取り決めたレビューワークフローのルールに従っているか？
```

完全には従っていません。

従っていた部分はあります。

- spec 起票を先に行った
- `requirements / design / tasks / spec.json` を揃えた
- spec に対応する artifact と validator を実装した
- dependency map と index を更新した

ただし、今回の `implementation-governance` は cross-cutting なので、本来はその後に feature 間調整レビューを入れるべきでした。そこをまだ通していません。つまり不足しているのは主に次です。

- `implementation-governance` 追加に対する cross-spec alignment review
- 必要ならその結果を受けた spec 修正
- その後の `tasks-approved` 相当の横断確認

なので現状の正確な状態は、

- `implementation-governance` の単体 spec と実装はある
- しかし横断レビュー工程は未完了
- したがって「事前に取り決めたレビューワークフローに完全準拠」とは言えない

です。

次にやるべきことは明確で、`implementation-governance` 導入に対する cross-spec alignment memo を作って、既存 5 feature との接続を確認することです。それを通して初めて、今回の governance 追加はルール準拠で閉じたと言えます。



```
dual-reviewerのデプロイ時には、決められたワークフローに遵守して各ゲートを通過し、問題が生じたら、遡って処理を繰り返すというポリシーを進めないと、ワークフローから逸脱して、正しい姿に行き着かないと思う。今回は、まだワークフローを遵守する枠組みがないので、そのとおりに行かないのかもしれない
```

その認識で正しいです。

今回起きたことはまさに、
- 正しい workflow policy は頭の中にある
- しかしそれを拘束する governance artifact と gate が弱かった
- そのため必要性が見えた瞬間に process を補強したが、補強自体を既存 workflow に完全には載せ切れていない

という状態です。

本来あるべき運用は、あなたの言う通りです。

1. 決めた workflow に従って進める
2. 各 gate を通過する
3. 問題が出たら、適切な phase まで戻る
4. reopen 後に再レビューし、再度 gate を通す
5. その履歴自体も evidence として残す

これがないと、局所的には合理的でも、全体としては workflow 逸脱が蓄積します。今回の `implementation-governance` 追加も、必要ではあったが、厳密には「その変更自体を governance された flow に乗せる枠組み」がまだ足りませんでした。

なので、次に必要なのは単なる spec 追加ではなく、「workflow を守らせる workflow」の固定です。最低限、次が要ります。

- gate 一覧の明文化
  `requirements -> design -> tasks -> implementation -> implementation conformance review` を正式 phase として固定する
- reopen rule の明文化
  どの種類の問題が出たら `A/B/C` のどこまで戻るかを固定する
- gate pass artifact の必須化
  各 gate 通過時に何を残すかを固定する
- cross-spec alignment の必須化
  cross-cutting spec は単体 completion で閉じず、横断 gate を通す
- status 管理
  「実装済み」ではなく「どの gate まで通過したか」を状態として持つ

要するに、いまはまだ「正しい workflow を支える governance の一次実装」を始めた段階です。だから完全にはその通りに動いていない。しかし、今見えている不足はかなり明確です。

次の正しい作業は、open finding 修正ではなく、まず `implementation-governance` 自体に対する cross-spec alignment review を行い、「workflow を守る枠組み」まで workflow に載せることです。そこを通してから、各 finding 修正へ進むのが筋です。



```
「workflow を守る枠組み」について対応した後、残りの対応をしよう。忘れないように
```

了解です。優先順を固定します。

次はまず「workflow を守る枠組み」側です。具体的には `implementation-governance` に対する cross-spec alignment review と、必要なら gate / reopen / status の補強を先に処理します。

その後に残件として、今回の 3 finding を回収します。

- adoption gate 修正
- replay resolver の汎化
- evidence-caveat linkage の構造化

この順で進めます。3 件は open finding として review artifact / signal register に残っているので、途中で落ちることはありません。



```
進めて
```

「workflow を守る枠組み」側の補強まで完了しました。`implementation-governance` に対する cross-spec alignment memo を [cross-spec-implementation-governance-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-implementation-governance-alignment.md:1) に追加し、governance 変更自体が workflow 外で成立しないようにしました。あわせて gate 通過状態を残す台帳として [workflow-gate-status.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md:1) を追加し、`completed` と `completed_with_open_findings` を区別しています。

spec 側も補強しており、[requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/requirements.md:91) に workflow gate status / cross-spec alignment 要件を追加、[design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/design.md:19) に status model と alignment model を追加、[tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/tasks.md:22) に Task 7 を追加しました。`spec.json` も alignment required/completed に更新済みです。[spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/spec.json:1)

検証は `ruby dual-reviewer-rebuild/scripts/validate_implementation_governance_artifacts.rb` で再実行し、通過しています。今の workflow 上の次作業は [workflow-gate-status.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md:44) に固定したとおり、open finding 3 件の修正です。忘れずにこの順で進めます。



```
「workflow を守る枠組み」は具体的にはどういう実装か？
```

今回入れた「workflow を守る枠組み」は、要するに「正しい進め方を文章で言うだけでなく、repo 上の artifact と gate 状態として拘束する実装」です。

具体的には 4 層あります。

1. governance spec
   [requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/requirements.md:1)
   [design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/design.md:1)
   [tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/tasks.md:1)

   ここで、
   - implementation のあとに `implementation conformance review` が必須
   - finding は artifact と disposition を伴って残す
   - governance 変更自体も cross-spec alignment を通す
   - `completed_with_open_findings` のような状態を区別する
   という workflow contract を正本化しました。

2. review procedure と metric register
   [implementation-conformance-review.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-conformance-review.md:1)
   [implementation-conformance-metric-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-conformance-metric-register.md:1)

   ここで、
   - いつ review するか
   - 何を見るか
   - finding をどう分類するか
   - 何を metrics として残すか
   を固定しています。

3. gate status と alignment artifact
   [workflow-gate-status.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md:1)
   [cross-spec-implementation-governance-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-implementation-governance-alignment.md:1)

   ここが実質的な拘束です。
   - 今 repo 全体がどの gate まで通ったか
   - open finding が残っているか
   - governance 変更が横断レビューを通過したか
   を明示しています。

   つまり「実装したから完了」ではなく、「今は `implementation conformance review: completed_with_open_findings`」のように状態で持つようにしました。

4. mechanical validation
   [validate_implementation_governance_artifacts.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/validate_implementation_governance_artifacts.rb:1)

   これは workflow 自体の validator です。
   いまは次を確認します。
   - procedure doc がある
   - metric register がある
   - review template がある
   - concrete review artifact がある
   - workflow gate status がある
   - governance alignment memo がある
   - review artifact に required sections / metric keys がある

要するに、今回の実装は
- phase/gate を定義した
- その通過状態を artifact にした
- governance 変更自体も alignment 対象にした
- 最低限 validator で欠落を検出できるようにした

というものです。

まだやっていないのは、「gate を完全自動で進める orchestration」です。現状は
- 人間が進める
- ただし進め方と状態は repo で拘束される
- 欠けている artifact は validator で落ちる

という段階です。これは prototype としては十分筋がよく、次の 3 finding 修正に進める状態です。



```
例えば、designレビュー時にrequirementsへの修正が入ったときに、requrementsのフィーチャー間レビューが走り、そのレビューで他のフィーチャーのrequirementsが修正された場合、その下のdesignにもレビューが入るという階層的なチェックもできているか？
```

まだ完全にはできていません。

いま入っている枠組みでできるのは主に次です。

- `requirements -> design -> tasks -> implementation -> implementation conformance review` という phase 順の明文化
- 上流 phase に修正が入ったら下流 phase を reopen 対象にする、というルールの明文化
- `A/B/C` handback で、どこまで戻るかの原則化
- gate status を artifact として残すこと

これは [phase-and-feature-dependency-map.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/phase-and-feature-dependency-map.md:39) や [cross-spec-design-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-design-alignment.md:143) に入っています。

ただし、あなたが言うような

1. design review 中に requirements 修正が入る
2. requirements の cross-feature review を再実施する
3. その結果、他 feature の requirements も変わる
4. その影響で各 feature の design review も再実施する
5. さらに tasks も reopen する

という階層的な連鎖を、状態遷移として機械的に追うところまでは未実装です。

つまり現状は、

- ルールはある
- どこまで戻すべきかの原則もある
- でも「どの feature のどの phase を reopen し、どの alignment gate を再実施すべきか」を自動または半自動で管理する再帰的 workflow engine にはなっていない

という状態です。

不足しているのは次です。

1. phase reopen propagation の正本
   どの phase の変更が、どの feature のどの下流 phase を reopen するかを表にすること。

2. gate dependency state machine
   `requirements changed -> requirements alignment required -> downstream design invalidated -> design alignment required` のような遷移規則。

3. feature-phase status ledger
   feature ごとに `requirements/design/tasks/implementation/review` の状態を持ち、`completed`, `reopen_required`, `blocked_by_upstream` を管理する台帳。

4. alignment rerun obligations
   「この修正なら requirements alignment だけでよい」「この修正なら design/tasks まで再実施必須」という判定表。

なので答えは、
- 原理上のルールはかなり入った
- でもあなたが言う階層的チェックの運用を厳密に回すには、まだ 1 段足りない
です。

次に必要なのは、`workflow-governance` をもう一段進めて、
`feature x phase` 単位の reopen 伝播ルールと status 台帳を入れることです。これが入ると、今言った階層的チェックにかなり近づきます。



```
このスレッドと、レビューシステム再構築計画で行ってきた手動開発において、この種のワークフローの修正手続きが議論されてきました。それらの動作を抜き出してください。
```

抜き出せる「ワークフロー修正手続きの動作」は、要するに次です。

**1. 上流修正が入ったら、下流を reopen 対象に戻す**
- 同じ phase に修正が入ったら、その phase の alignment gate を再実施する。
- 上流 phase に修正が入ったら、完了済みの下流 phase も reopen 対象にする。
- これは [phase-and-feature-dependency-map.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/phase-and-feature-dependency-map.md:48) に明文化されています。

**2. 手戻りは `A/B/C` で判定し、戻る深さを変える**
- `A`: task-local adjustment。spec reopen 不要。
- `B`: design handback。`design` を reopen し、完了済み `tasks` も再確認。
- `C`: requirements handback。`requirements` を reopen し、下流 `design` と `tasks` も reopen。
- これは [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:35) にあります。

**3. design 修正が入ったら、局所変更として済ませず正式手順を踏む**
- 修正した feature の `design.md` を更新する。
- `spec.json` を更新する。
  - `updated_at`
  - `custom.reopened.design = true`
  - 必要なら `custom.recheck.upstream_change_pending = true`
  - `custom.recheck.impacted_downstream_phases` に少なくとも `tasks`
- alignment 文書を再確認し、影響論点を追記する。
- 完了済み `tasks` を reopen 扱いに戻す。
- 再確認完了後にのみ `tasks alignment gate` へ進む。
- これは [cross-spec-design-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-design-alignment.md:144) にあります。

**4. tasks の前後でも横断整合レビューをやり直す**
- `tasks.md` に遡上修正が入った場合
- 上流 `design.md` 変更で task 順序や依存が変わる場合
- 上流 `requirements.md` 変更で task の存在理由が変わる場合
- implementation 中に task 分解の誤りが判明し、spec に戻す場合
- このとき `tasks alignment gate` を再実施する。
- これは [cross-spec-tasks-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-tasks-alignment.md:95) にあります。

**5. implementation は approved tasks の範囲でのみ進め、scope change は spec 側へ戻す**
- 実装中に scope change が必要なら spec へ戻す。
- 上流へ戻した場合は、対応する alignment gate を再実施する。
- これは [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:28) にあります。

**6. 問題は会話で流さず、artifact に残す**
- 実装判断は `implementation-coordination-log`
- 軽微な兆候は `implementation-signal-register`
- review finding は `docs/reviews/*.md`
- gate 状態は `workflow-gate-status.md`
- この「記録してから次へ進む」動作が今回のスレッドで補強された部分です。
- 参照:
  - [implementation-signal-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-signal-register.md:1)
  - [workflow-gate-status.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md:1)

**7. 実装完了は smoke pass だけでは閉じず、conformance review を通す**
- `task 完了`
- `relevant smoke validator pass`
- `implementation conformance review 実施`
- `finding 0 件、または finding が disposition 付きで記録済み`
- これで checkpoint close。
- これは [implementation-conformance-review.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-conformance-review.md:108) にあります。

**8. open finding が残る場合は、状態を `completed_with_open_findings` として扱う**
- 「実装済み」ではなく「どの gate まで通ったか」で管理する。
- 3 finding は backlog ではなく explicit evidence として残す。
- これは [workflow-gate-status.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md:19) にあります。

**9. governance 変更そのものも workflow の外で決めない**
- completion rule を変える cross-cutting spec は、単体 spec で閉じず cross-spec alignment を通す。
- alignment memo、gate status、`spec.json` の alignment status 更新が必要。
- これは今回のスレッドで具体化され、[cross-spec-implementation-governance-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-implementation-governance-alignment.md:1) に落ちています。

**10. 元々の再構築計画にあった運用原則**
- intent が変わったら影響 spec を再点検する。
- data acquisition plan を途中で変えるなら protocol version として分離する。
- raw data を後編集せず、修正や再集計は派生 artifact にする。
- 人間の review / approve / reject の位置を system 設計に含める。
- これは [dual-reviewer-rebuild-plan.md](/Users/Daily/Development/Rwiki-dev/docs/dual-reviewer-rebuild-plan.md:64) と [dual-reviewer-rebuild-plan.md](/Users/Daily/Development/Rwiki-dev/docs/dual-reviewer-rebuild-plan.md:86) にあります。

圧縮すると、この workflow 修正手続きの動作は次の 1 行です。  
「問題が見つかったら、`A/B/C` で戻る深さを決め、該当 phase と下流 phase を reopen し、alignment gate を再実施し、状態と証跡を artifact に残してから先へ進む。」

必要なら次に、これを `手続き一覧` と `状態遷移表` の 2 形式に整形できます。



```
お願いします
```

以下の 2 形式で整理します。

**手続き一覧**

1. 問題を検出する  
   実装中、review 中、alignment 中に不整合・不足・境界逸脱を見つける。

2. 問題の種類を判定する  
   `A/B/C` で戻る深さを決める。  
   `A`: task-local adjustment  
   `B`: design handback  
   `C`: requirements handback

3. 影響範囲を特定する  
   どの feature の、どの phase が影響を受けるかを決める。  
   同一 phase 修正ならその phase の gate を再実施。  
   上流 phase 修正なら下流 phase も reopen 対象。

4. 正本を更新する  
   該当する `requirements.md` / `design.md` / `tasks.md` を更新する。  
   必要なら関連する alignment memo も更新する。

5. `spec.json` を更新する  
   少なくとも次を更新する。  
   `updated_at`  
   `custom.reopened.<phase>`  
   `custom.recheck.upstream_change_pending`  
   `custom.recheck.impacted_downstream_phases`

6. 証跡を残す  
   実装判断は [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:1)  
   軽微 signal は [implementation-signal-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-signal-register.md:1)  
   review finding は [docs/reviews/](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews)  
   gate 状態は [workflow-gate-status.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md:1)

7. alignment gate を再実施する  
   `requirements` 修正なら requirements alignment  
   `design` 修正なら design alignment  
   `tasks` 修正なら tasks alignment  
   cross-cutting governance 変更なら cross-spec alignment

8. 下流 phase を再判定する  
   完了済みでも reopen 対象なら閉じた扱いを外し、再確認対象に戻す。

9. implementation を再開する  
   approved / rechecked 済みの phase から先だけ進める。

10. 実装後は conformance review を通す  
   `task 完了`  
   `smoke pass`  
   `implementation conformance review`  
   `finding 0 件 or disposition 付き記録済み`  
   で checkpoint close。

---

**状態遷移表**

| 起点状態                       | 事象                                       | 判定                    | 必須アクション                                               | 次状態                             |
| ------------------------------ | ------------------------------------------ | ----------------------- | ------------------------------------------------------------ | ---------------------------------- |
| `requirements completed`       | requirements 修正発生                      | 上流変更                | requirements 更新、`spec.json` 更新、requirements alignment 再実施、下流 design/tasks reopen | `requirements recheck in_progress` |
| `design completed`             | design review 中に requirements 修正が必要 | `C`                     | requirements へ handback、requirements alignment 再実施、design/tasks reopen | `requirements reopen_required`     |
| `design completed`             | design のみ修正で吸収不能                  | `B`                     | design 更新、`spec.json` 更新、design alignment 再実施、tasks reopen | `design recheck in_progress`       |
| `tasks completed`              | task 順序や依存が変わる                    | `B` または `C`          | 上流 design/requirements を見直し、tasks alignment 再実施    | `tasks reopen_required`            |
| `implementation in_progress`   | task-local 微修正で吸収可能                | `A`                     | coordination log 記録、実装継続                              | `implementation in_progress`       |
| `implementation in_progress`   | 設計境界不足が判明                         | `B`                     | design reopen、design/tasks alignment 再実施                 | `design reopen_required`           |
| `implementation in_progress`   | requirement contract 不足が判明            | `C`                     | requirements reopen、requirements/design/tasks 再実施        | `requirements reopen_required`     |
| `implementation completed`     | smoke 未実施                               | なし                    | relevant smoke validator 実行                                | `smoke in_progress`                |
| `smoke completed`              | conformance review 未実施                  | なし                    | review artifact 作成、finding 記録、metric snapshot 記録     | `conformance review in_progress`   |
| `conformance review completed` | finding なし                               | なし                    | gate status 更新                                             | `completed`                        |
| `conformance review completed` | open finding あり                          | `A/B/C` を付与          | signal/coodination/review artifact へ接続                    | `completed_with_open_findings`     |
| `completed_with_open_findings` | finding 修正着手                           | finding severity に従う | 実装修正、smoke rerun、conformance review short rerun        | `recheck in_progress`              |
| `governance spec introduced`   | cross-cutting completion rule 変更         | cross-spec review 必須  | alignment memo、gate status、`spec.json` alignment 更新      | `governance alignment completed`   |

---

一番重要な遷移だけ文章で言うとこうです。

1. 上流で変えたら下流を reopen する。  
2. reopen したら対応する alignment gate を再実施する。  
3. 実装後は conformance review を通さないと閉じない。  
4. open finding があるなら `completed` ではなく `completed_with_open_findings` にする。

必要なら次に、これをそのまま repo に `WORKFLOW_REPAIR_PROCEDURE.md` のような形で追加できます。



```
2はtask, design, requirementだけだが、intentも候補とならないか
```

はい、なります。`intent` も候補です。むしろ厳密には、戻り先は `A/B/C` の 3 段だけでは足りず、さらに上に `intent` があります。

いまの整理では実装都合で `A/B/C` を中心にしていましたが、これは主に spec フェーズ内の手戻りを扱うための簡略化です。あなたが言う通り、本当に上位意図との不整合が見つかった場合は `requirements` より上に戻る必要があります。

典型例はこうです。

- ある requirement 自体は整っている
- design も tasks も requirement に忠実
- でも、その requirement がそもそも system の目的や非目的に合っていない
- あるいは optimize すべきでないものを optimize している

この場合は `requirements handback` では足りず、`intent handback` です。

なので、状態としては本来こうあるべきです。

1. `A`: task-local adjustment
2. `B`: design handback
3. `C`: requirements handback
4. `D` もしくは別名: intent handback

`intent handback` でやることは次です。

- `intent/` 配下の正本を更新する
- intent と requirements の対応を再点検する
- 影響を受ける feature requirements を reopen する
- その下の design / tasks も連鎖的に reopen する
- requirements alignment からやり直す

つまり連鎖はこうです。

`intent` 修正  
→ `requirements` 再点検  
→ `requirements alignment gate` 再実施  
→ `design` reopen  
→ `design alignment gate` 再実施  
→ `tasks` reopen  
→ `tasks alignment gate` 再実施  
→ implementation 再開

今回の `workflow-gate` 整理には、まだこの `intent handback` が明示では入っていません。なので、今のルールは一段不足しています。

正しく直すなら次にやるべきことは、

- handback taxonomy に `intent handback` を追加する
- `phase-and-feature-dependency-map` に intent 起点の reopen 伝播を追記する
- さきほどの手続き一覧と状態遷移表も `intent` を含む形に更新する

です。これは軽い文書修正ではなく、workflow governance の重要な補完です。必要ならそのまま反映します。



```
反映して
```

反映しました。`intent` を requirements より上の正式な手戻り先として扱うように更新しています。

主な変更は次です。

- handback taxonomy を `A/B/C/D` に拡張  
  `D = intent handback` を追加しました。  
  [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:37)

- `intent` 修正時の連鎖 reopen を phase rule に追加  
  `intent` が変わったら、影響する `requirements/design/tasks`、必要なら `implementation` まで reopen 対象にするよう明文化しました。  
  [phase-and-feature-dependency-map.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/phase-and-feature-dependency-map.md:48)

- governance spec に intent-level handback を追加  
  requirements 側で `A/B/C` だけでなく intent-level handback を扱うようにし、intent change による downstream invalidation も acceptance criteria に入れました。  
  [requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/requirements.md:75)

- design 側に reopen propagation / handback model を追加  
  `intent -> requirements -> design -> tasks` の連鎖 reopen を design 正本にも入れました。  
  [design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/design.md:131)

- conformance review と alignment memo の表現も同期  
  review finding から `D` に上がるケースを記録上も扱えるようにしました。  
  [implementation-conformance-review.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-conformance-review.md:99)  
  [cross-spec-implementation-governance-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-implementation-governance-alignment.md:24)

これでルール上は、
- `A`: task
- `B`: design
- `C`: requirements
- `D`: intent

まで戻せます。次に必要なら、前回出した「手続き一覧」と「状態遷移表」も `D` を含む形で repo 文書として固定できます。



```
はい、固定して
```

固定しました。手続き一覧と状態遷移表の正本補助は [workflow-repair-procedure.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md:1) です。ここに `A/B/C/D` handback、gate 再実施手順、`intent` 起点の連鎖 reopen、checkpoint close 条件までまとめています。

index にも追加済みで、以後は [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md:145) から辿れます。implementation coordination 側にも formalization 記録を追記しました。[implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:799)

これで workflow 修正手続きは、
- rule
- status
- alignment
- repair procedure

の 4 点セットで repo に固定された状態です。次は予定どおり open finding 3 件の実装修正に入れます。



```
「workflow を守る枠組み」を修正するのが先じゃないの？
```

はい。だから先にそれをやっていました。今回ここまでで先に処理したのは、まさに「workflow を守る枠組み」の修正です。

先に入れたものは次です。

- governance spec の起票と実装  
  [dual-reviewer-implementation-governance](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance)

- cross-spec alignment  
  [cross-spec-implementation-governance-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-implementation-governance-alignment.md:1)

- gate 状態台帳  
  [workflow-gate-status.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md:1)

- 修正手続きの固定  
  [workflow-repair-procedure.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md:1)

- `intent` まで含めた handback taxonomy  
  [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:35)

なので、「3 finding を直す前に workflow 側を直す」という順序は、すでにその順で進めています。

ただし、厳密に言うと 2 段あります。

1. 先にやるべき workflow 修正  
   これは今やった範囲です。ルール、alignment、status、repair procedure を repo artifact に固定しました。

2. さらに強い workflow enforcement  
   たとえば
   - feature x phase ごとの reopen をもっと機械的に管理する
   - `spec.json` 群から gate status を自動集計する
   - handback に応じて再実施すべき gate を validator が警告する  
   という半自動 enforcement です。これはまだ未実装です。

今の判断としては、`先にやるべき workflow 修正` は済んでいます。だから次は open finding 3 件の修正に進んでよい段階です。  
もしあなたが言っている「workflow を守る枠組み」が後者の自動 enforcement まで含むなら、そこはまだ残っています。



```
了解。ワークフローの働きとしては、LLMにガイドする、つまり何かをトリガーとして、LLMにやるべきことを教えるというようなものですか
```

はい、かなり近いです。ただし「LLM に指示を出すだけ」より、もう少し強い役割です。

この workflow の働きは 3 層あります。

1. 判断のガイド
   何か起きたときに、
   - これは `A/B/C/D` のどれか
   - どこまで戻るべきか
   - 次にどの gate を通すべきか
   を LLM と人間の両方に教える役割です。

2. 状態の拘束
   ただの助言ではなく、
   - まだ `completed` ではない
   - `completed_with_open_findings` である
   - `requirements recheck` が必要
   のように、「今どの状態か」を固定します。  
   つまり、好きに次へ進ませないための枠です。

3. 証跡の要求
   判断したなら、
   - log に残す
   - signal に残す
   - review artifact に残す
   - gate status を更新する
   という証跡作成まで要求します。

なので、まとめるとこれは
- 何をトリガーに
- 何を判断し
- どこへ戻り
- 何を更新し
- 次に何をするか
を LLM にガイドしつつ、その結果を repo artifact として拘束する仕組みです。

単なるプロンプト上の「おすすめ手順」ではありません。  
理想形では、

- trigger:
  `design` 修正が起きた
- workflow:
  `tasks` を reopen、design alignment を再実施、status 更新
- evidence:
  log / alignment memo / gate status を更新
- next action:
  rechecked 後にのみ implementation 再開

のように動きます。

今の実装段階では、これはまだ「半自動」です。つまり
- LLM に強くガイドする
- validator で欠落をある程度検出する
- ただし完全自動オーケストレーションではない

という状態です。  
将来的に強化するなら、trigger をもっと明示して、`spec.json` や review artifact の変化から「次に必須の手順」を自動で出せるようにする方向です。



```
次にすべきことは？
```

次は open finding 3 件の実装修正です。workflow 側は一度閉じたので、予定どおりコード側に戻れます。

順番はこれで進めるのがよいです。

1. `P1` adoption gate 修正  
   [history_registry.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/history_registry.rb:37)  
   `adopted` を `approved` 済み proposal のみに制限し、required test artifact と linked repo change 条件を明示します。

2. `P2` replay resolver の汎化  
   [replay_input_resolver.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/replay_input_resolver.rb:56)  
   fixture 名の固定列挙をやめて、`run_manifest.yaml` ベースの generic discovery にします。

3. `P2` evidence-caveat linkage の構造化  
   [evidence_register_builder.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/evidence_register_builder.rb:46)  
   basename heuristic をやめて、artifact-scoped ref で結ぶようにします。

その後に、
- relevant smoke validator rerun
- `implementation conformance review` short rerun
- `workflow-gate-status.md` 更新

までやるのが正しい流れです。進めるなら 1 から着手します。



```
進めてください
```

open finding 3 件を修正し、short rerun まで閉じました。

コード修正は [history_registry.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/history_registry.rb:37)、[replay_input_resolver.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/replay_input_resolver.rb:56)、[evidence_register_builder.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/evidence_register_builder.rb:21) です。adoption は `approved` 限定にし、local run discovery は `run_manifest.yaml` ベース探索へ変更し、evidence-caveat linkage は basename heuristic を廃止して claim の構造化参照に戻しました。

workflow 側も更新済みです。short rerun artifact を [2026-05-09-prototype-shelf-review-rerun.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/2026-05-09-prototype-shelf-review-rerun.md:1) に追加し、[implementation-signal-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-signal-register.md:149) の 3 signal は `absorbed`、[workflow-gate-status.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md:21) は `implementation conformance review: completed` に更新しました。coordination log も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:810) に追記しています。

検証は `ruby dual-reviewer-rebuild/scripts/validate_self_improvement_pipeline.rb`、`ruby dual-reviewer-rebuild/scripts/validate_paper_interface_pipeline.rb`、`ruby dual-reviewer-rebuild/scripts/validate_implementation_governance_artifacts.rb` を再実行し、すべて通過しました。次は必要ならここでコミットです。



```
コミット
```

commit しました。branch `codex/dual-reviewer-foundation` に `d333b8f` (`Add implementation governance and fix review findings`) が追加されています。

内容は 2 本立てで、`implementation-governance` spec と workflow artifact 群の追加、それに続く open finding 3 件の修正と short rerun までを含みます。親 repo の `dual-reviewer-rebuild/` 以外の変更は今回の commit に混ぜていません。

::git-stage{cwd="/Users/Daily/Development/Rwiki-dev"}
::git-commit{cwd="/Users/Daily/Development/Rwiki-dev"}





```
次は？
```

次は 2 つあります。

1. この commit を push する  
   branch 上の最新状態をリモートに反映する段階です。

2. ここで一度レビュー区切りを作る  
   いまは
   - prototype 一巡
   - implementation governance 導入
   - open finding 修正
   - conformance rerun 完了
   まで閉じているので、PR を後で切る前提でも、変更要約を整える価値があります。

実装をさらに進めるなら、その前に「次に何を作るか」を決める段階です。現状の大きな未処理は workflow ではなく、prototype を次の利用段階へ進める話になります。なので実務上は、まず `git push` が自然です。



```
プッシュ
```

`codex/dual-reviewer-foundation` を push しました。最新は `d333b8f` (`Add implementation governance and fix review findings`) です。

今回の push で、implementation governance の spec / workflow artifact / open finding 修正 / conformance rerun までリモートに反映されています。

::git-push{cwd="/Users/Daily/Development/Rwiki-dev" branch="codex/dual-reviewer-foundation"}



```
implementation conformance reviewを実施したか？
```

はい、実施しています。しかも 2 回あります。

1. 初回 review  
   [2026-05-09-prototype-shelf-review.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/2026-05-09-prototype-shelf-review.md:1)  
   ここで 3 finding を記録しました。

2. 修正後の short rerun  
   [2026-05-09-prototype-shelf-review-rerun.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/2026-05-09-prototype-shelf-review-rerun.md:1)  
   ここで 3 finding の修正確認を行い、新規 finding なしで閉じています。

状態台帳も更新済みで、[workflow-gate-status.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md:21) では `implementation conformance review: completed` です。implementation coordination にも記録があります。[implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:749) [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:810)

要するに、初回で指摘し、修正し、short rerun まで済ませています。



```
そうすると、dual-reviewerの最初のバージョンが完成ですね。
```

はい。現時点ではそう言ってよいです。

厳密には、「dual-reviewer の最初の prototype version」が、
- spec
- implementation
- governance
- conformance review
- finding 修正
- rerun

まで通って閉じた状態です。`workflow-gate-status.md` 上でも `implementation conformance review: completed` になっているので、少なくともこの再構築ラウンドの v1 は成立しています。  
参照: [workflow-gate-status.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md:21)

ただし、これは「研究・運用に向けた最初の完成版」であって、「最終版」ではありません。次はこの v1 を基準に、
- version tag / release 相当の区切りを作る
- PR を切る
- 実利用または小規模再実験へ入る
- 次の improvement cycle を回す

の段階です。

必要なら次は、`v1` としてどう名付けてどこに記録するかまで整えます。



```
完成ということは、dual-reviewerの手続きにしたがって、マニュアルで1回、コードレビューを通したことになる。その過程のエビデンスも残っている。
```

はい、その理解で合っています。

今回の `v1` 完成は、単にコードが揃ったという意味ではなく、

- `dual-reviewer` の仕様と workflow に従って
- 手動で 1 回 implementation conformance review を実施し
- finding を記録し
- 修正し
- short rerun で閉じた

という 1 サイクルを通した、という意味です。

その過程の evidence も repo に残っています。

- 初回 review artifact  
  [2026-05-09-prototype-shelf-review.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/2026-05-09-prototype-shelf-review.md:1)

- 修正後 rerun  
  [2026-05-09-prototype-shelf-review-rerun.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/2026-05-09-prototype-shelf-review-rerun.md:1)

- review procedure と metric rule  
  [implementation-conformance-review.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-conformance-review.md:1)  
  [implementation-conformance-metric-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-conformance-metric-register.md:1)

- gate 状態  
  [workflow-gate-status.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md:1)

- coordination / signal 履歴  
  [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:1)  
  [implementation-signal-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-signal-register.md:1)

つまり、「manual で 1 回 review を通した」「その結果と修正履歴が evidence として残っている」は、どちらも成立しています。



```
では、そのデータを使って、レポートができますね。
```

はい、できます。

ただし、今あるデータで自然に書けるレポートはまず「dual-reviewer v1 の構築と manual review サイクルの成立報告」です。つまり、

- v1 をどういう spec / workflow で構築したか
- implementation conformance review をどう実施したか
- どんな finding が出たか
- どう修正して rerun で閉じたか
- その evidence が repo にどう残っているか

をまとめる形です。

使える一次資料は揃っています。

- review artifact  
  [2026-05-09-prototype-shelf-review.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/2026-05-09-prototype-shelf-review.md:1)  
  [2026-05-09-prototype-shelf-review-rerun.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/2026-05-09-prototype-shelf-review-rerun.md:1)

- workflow / governance  
  [implementation-conformance-review.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-conformance-review.md:1)  
  [workflow-gate-status.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md:1)  
  [workflow-repair-procedure.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md:1)

- 実装履歴  
  [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:1)  
  [implementation-signal-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-signal-register.md:1)

なので、少なくとも
- system build report
- process validation report
- manual conformance review report

は書けます。

一方で、「dual-reviewer の性能が高い」という評価レポートを書くには、実ターゲットに対する review run データをもう少し集める必要があります。今あるのは主に prototype 構築と workflow 成立の evidence です。

次にやるなら、まずこの evidence を使って `v1 completion report` を作るのが自然です。必要ならそのレポートをこの repo に起こします。



```
レポートを起こしてください。
```

レポートを起こしました。完成報告は [dual-reviewer-v1-completion-report.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reports/dual-reviewer-v1-completion-report.md:1) です。

内容は、
- v1 の完成条件
- 通過した workflow gate
- manual `implementation conformance review` の 1 サイクル
- 初回 finding と修正後 rerun
- validator 実行状況
- evidence の所在
- v1 の意味と次段

までを 1 枚にまとめています。`DOCUMENT_INDEX.md` にも追加済みで、[implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:823) に記録しました。

次は必要なら、この report も含めてコミットです。



```
とりあえず、コミット
```

commit しました。branch `codex/dual-reviewer-foundation` に `370e0e4` (`Add v1 completion report`) が追加されています。

この commit には v1 completion report と、それに伴う `DOCUMENT_INDEX.md`、`implementation-coordination-log.md` の更新だけを含めています。

::git-stage{cwd="/Users/Daily/Development/Rwiki-dev"}
::git-commit{cwd="/Users/Daily/Development/Rwiki-dev"}



```
V1のユーザーガイドを作成しよう。このアプリの目的、使い方
```

V1 のユーザーガイドを追加しました。利用者向けの主文書は [dual-reviewer-v1-user-guide.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/guides/dual-reviewer-v1-user-guide.md:1) です。

内容は、
- このアプリの目的
- 想定利用者
- v1 でできること
- 最短の使い方
- pipeline ごとの validator 実行方法
- 生成物の場所
- v1 の限界
- 困ったときの参照先

までをまとめています。あわせて [README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/README.md:1) の status を現状に合わせて更新し、[DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md:155) に guide を追加しました。implementation coordination にも記録済みです。[implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:836)

必要なら次はこれもコミットします。



```
これを使うユーザーはLLMをフロントエンドとして、対話的に使う筈。その観点からはユーザーガイドではなく、コマンド説明書になっている
```

その指摘どおりなので、ガイドを書き直しました。いまの [dual-reviewer-v1-user-guide.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/guides/dual-reviewer-v1-user-guide.md:1) は、コマンド中心ではなく、

- LLM をフロントエンドにした対話型 system であること
- ユーザーが会話で何を依頼するか
- 人間がどこで判断するか
- 対話の裏でどんな artifact が残るか
- 典型的な利用シナリオ

を中心にした構成に直しています。

コマンドは消してはいませんが、`maintainer 向け補足` に下げました。つまり位置づけを
- ユーザーガイドの中心: 対話利用
- コマンド: backend / validation entrypoint
に変えています。

まだ未コミットなので、よければこの修正版をコミットします。



```
そもそもの意図として、仕様駆動開発における下流工程（設計・タスク生成、一部仕様も含む）において、記述や詳細度が複雑になり、人の認知負荷が高まる問題を緩和するためのもの。この要点を入れる。また、仕様駆動開発のシナリオとワークフローの動作を加筆
```

要点を反映しました。[dual-reviewer-v1-user-guide.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/guides/dual-reviewer-v1-user-guide.md:1) では、目的を

- 仕様駆動開発の下流工程
- 特に `design` と `tasks`
- 一部 `requirements`

で detail と依存が増えて人の認知負荷が高まる問題を緩和すること、と明示しました。

あわせて、
- dual-reviewer が workflow guide としてどう動くか
- `A/B/C/D` handback をどう扱うか
- 仕様駆動開発の通常フローでどう使うか
- `design/tasks` の複雑化局面でどう使うか

も加筆しています。これで「コマンド説明書」ではなく、「対話的に何のために使う system か」がかなり前に出た形になっています。

必要ならこの修正版もコミットします。



```
仕様駆動開発の説明が冒頭にあり、そこで用語の定義が必要。初見の人にはわからない説明書になっている
```

その点はその通りなので、冒頭を直しました。[dual-reviewer-v1-user-guide.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/guides/dual-reviewer-v1-user-guide.md:1) に最初に次を追加しています。

- 仕様駆動開発とは何か
- この repo での進行順
- `intent / requirements / design / tasks / implementation / review / finding / artifact / gate` の用語定義
- dual-reviewer が主に扱う局面

これで初見の人でも、前提を知らないまま `design` や `tasks` の話に入らずに読める構成になりました。

必要なら次は、この修正版ガイドもコミットします。



```
ユーザーガイドはまだ修正が必要だが、一旦個々で閉じよう。
```

了解です。ユーザーガイドは未完成のままでも、いったんここで区切れます。

現状の到達点は、
- dual-reviewer v1 完成
- implementation governance 導入
- conformance review 1 サイクル通過
- completion report 作成
- user guide はドラフトあり、要修正

という状態です。次に再開するときは、ユーザーガイドの続きを独立タスクとして扱えば十分です。必要ならここでこの会話を終えて構いません。



```
レポートに戻るが、知りたいことは、intent/requirements/design/task/implの各段階で、どのようなメトリックがとれたか（つまり、問題があったか）その統計情報、手戻りが発生したか、軽微な修正か、重大な修正か、など
```

はい。いま残っている evidence から、かなりの部分はレポート化できます。ただし phase ごとに粒度が違います。`implementation` は統計化しやすく、`intent` は現状まだ定性的です。

現時点で引ける値を整理するとこうです。

| phase            | 取れる主指標                 |                        現在値 | 根拠                                                         |
| ---------------- | ---------------------------- | ----------------------------: | ------------------------------------------------------------ |
| `intent`         | 明示的 finding 数            |                        未計測 | 専用 review artifact なし                                    |
| `requirements`   | blocking 級矛盾数            |                             3 | [cross-spec-requirements-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-requirements-alignment.md:150) |
| `requirements`   | 修正反映後 recheck           |                      実施済み | [cross-spec-requirements-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-requirements-alignment.md:165) |
| `design`         | blocking 級齟齬数            |                             2 | [cross-spec-design-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-design-alignment.md:138) |
| `design`         | 残る open alignment points   |                             4 | [cross-spec-design-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-design-alignment.md:79) |
| `tasks`          | blocking ordering conflict   |                             0 | [cross-spec-tasks-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-tasks-alignment.md:131) |
| `tasks`          | alignment 中の修正点         |                             2 | [cross-spec-tasks-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-tasks-alignment.md:128) |
| `implementation` | coordination entry 数        |                            42 | [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:153) 以降 |
| `implementation` | handback class `A/B/C/D`     |         `A=42, B=0, C=0, D=0` | 同上                                                         |
| `implementation` | reopen 要否 `不要`           |                         42/42 | 同上                                                         |
| `implementation` | signal entry 数              |                             9 | [implementation-signal-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-signal-register.md:60) 以降 |
| `implementation` | signal status                | `absorbed=5, watch=4, open=0` | 同上                                                         |
| `implementation` | signal risk                  |     `high=1, medium=5, low=3` | 同上                                                         |
| `impl review`    | 初回 conformance findings    |                             3 | [2026-05-09-prototype-shelf-review.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/2026-05-09-prototype-shelf-review.md:28) |
| `impl review`    | 初回 severity weighted score |                             7 | 同 review artifact                                           |
| `impl review`    | rerun findings               |                             0 | [2026-05-09-prototype-shelf-review-rerun.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/2026-05-09-prototype-shelf-review-rerun.md:20) |
| `impl review`    | gate status                  |                   `completed` | [workflow-gate-status.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md:21) |

読み方としては次です。

- `requirements`
  大きな矛盾が 3 件あり、review wave 中に修正されています。つまりこの phase では「問題あり、ただし gate 前に吸収」です。
- `design`
  blocking 級齟齬 2 件を修正しています。こちらも「問題あり、修正後に次段へ進行」です。
- `tasks`
  blocking conflict は 0 です。つまり設計後の実装順序は大崩れしていません。ただし alignment 中の task-level 修正は 2 件あります。
- `implementation`
  手戻りは多くありましたが、すべて `A` 扱いで吸収しています。`B/C/D` は発生していません。
- `implementation conformance review`
  初回で 3 finding、rerun で 0 まで落ちています。これは v1 の品質閉路が 1 回回ったことを示します。

重要な限界もあります。

- `intent` はまだ「問題が何件あったか」を数える専用 artifact がありません。
- `requirements/design/tasks` も phase ごとの metric register はなく、alignment memo から手で拾っている状態です。
- なので現状は「phase ごとに完全に機械集計できる」わけではなく、「report に十分な evidence はあるが、集計は半手動」です。

自然な次作業は 2 つです。

1. いまの report にこの phase 別 metrics 節を追記する  
2. 今後に備えて `phase-review-metric register` を追加し、`intent/requirements/design/tasks/implementation` を同じ形式で数えられるようにする

必要なら、まず `dual-reviewer-v1-completion-report.md` にこの表をそのまま追加します。



```
はい、その2点を進めます
```

2 点とも反映しました。

[dual-reviewer-v1-completion-report.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reports/dual-reviewer-v1-completion-report.md:1) に、`intent / requirements / design / tasks / implementation` の phase 別 metrics と手戻り統計を追加しました。v1 baseline として、`requirements=blocking 3件`、`design=blocking 2件`、`tasks=blocking conflict 0件`、`implementation=coordination 42件 / handback Aのみ / signal 9件 / initial conformance findings 3件 -> rerun 0件` を明示しています。

今後の集計ルールは [phase-review-metric-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/phase-review-metric-register.md:1) に固定しました。どの phase で何を `blocking issue`、`minor adjustment`、`major correction`、`recheck` と数えるか、v1 ではどの artifact から baseline を引いたかも書いてあります。

関連して [DOCUMENT_INDEX.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/DOCUMENT_INDEX.md:150) と [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:883) も更新済みです。

補足すると、`intent` はまだ専用 review artifact がないので `未計測` のままです。`requirements / design / tasks` も現状は alignment memo 由来の semi-manual aggregation です。次にやるなら、これを機械集計できる最小 field を alignment artifact 側に追加する段階です。



```
intentには定量的な指標が必要だろうか
```

はい、必要です。ただし `requirements` や `implementation` と同じ種類の定量化ではありません。

`intent` で測りたいのは、「不具合件数」よりも、上位目的が下流に正しく伝わっているかです。なので数えるべきものは、実装ミスではなく intent の伝達失敗や揺れです。

有効なのは次のような指標です。

- `intent_coverage_gap_count`
  intent 命題のうち、requirements に落ちていない件数
- `intent_conflict_count`
  下流 spec が intent と矛盾した件数
- `intent_reinterpretation_count`
  同じ intent を phase ごとに別の意味で読んだ件数
- `intent_handback_count`
  `D` handback が発生した件数
- `intent_trace_break_count`
  trace matrix 上で intent から requirements への接続が切れている件数

一方で、細かくやりすぎる必要はありません。`intent` は件数の多さを見るより、
- 重大なズレがあったか
- どれだけ下流へ伝播したか
- 途中で意味が変質したか

を見るほうが重要です。

なので結論は、
- `intent` にも定量指標は要る
- ただし phase 下流のバグ件数型ではなく、整合性・伝達性・手戻り深さを測る指標にする
です。

最小セットならこれで十分です。

- `intent_coverage_gap_count`
- `intent_conflict_count`
- `intent_handback_count`
- `intent_trace_break_count`

必要なら次に、この 4 つを `phase-review-metric-register.md` に正式追加します。



```
ウォーターフォール式なので、intent_handback_count以外は下流フェーズでのカウントのように思えるが。
```

その通りです。そこは切り分けるべきです。

`intent_coverage_gap_count` や `intent_conflict_count` は、概念としては intent に関する問題ですが、観測される場所は多くの場合 `requirements` 以降です。ウォーターフォール式に見るなら、これらを `intent phase` の指標として持つのは少し不自然です。

整理するとこうです。

- `intent phase` 自体の指標
  intent を定める段階で何回戻ったか、意図の再定義が起きたか
- `downstream phases` における intent 起因の指標
  requirements/design/tasks/implementation review で、「原因が intent にある」と判定された件数

なので、`intent` で純粋に持つべき定量値はかなり少なく、第一候補はあなたの言う通り `intent_handback_count` です。加えるならせいぜい次くらいです。

- `intent_revision_count`
  intent 文書自体の意味変更回数
- `intent_handback_count`
  `D` handback 件数

一方で、先ほど挙げた
- `intent_coverage_gap_count`
- `intent_conflict_count`
- `intent_trace_break_count`

は、`intent` 指標というより
- `requirements` phase で観測された intent 起因問題
- `design` phase で観測された intent 起因問題

として持つほうが自然です。つまり attribution を持たせるべきです。

たとえば形としては、

- `requirements_blocking_issue_count`
- `requirements_intent_attributed_issue_count`
- `design_blocking_issue_count`
- `design_intent_attributed_issue_count`

のようにするほうが、ウォーターフォールの phase model と合います。

要するに、
- `intent phase` の定量値は少ない
- intent に起因する問題は下流 phase 側で数える
- ただし原因分類として `intent-attributed` を付ける

のが正しいです。今の register もこの考え方に寄せて直すのがよいです。



```
その考え方で整理してください。
```

その考え方で整理しました。

[phase-review-metric-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/phase-review-metric-register.md:1) は次の構造に直しています。

- `intent` 自体の指標
  - `intent_revision_count`
  - `intent_handback_count`
- 下流 phase の指標
  - `phase_blocking_issue_count`
  - `phase_nonblocking_open_point_count`
  - `phase_minor_adjustment_count`
  - `phase_major_correction_count`
- 下流 phase での intent 起因問題
  - `phase_intent_attributed_issue_count`

これで、`intent` は「何回 intent を戻したか・改訂したか」を測り、`requirements/design/tasks/implementation` では「その phase で見つかった問題のうち intent 起因のもの」を attribution として数える形になっています。

[dual-reviewer-v1-completion-report.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reports/dual-reviewer-v1-completion-report.md:80) 側の説明も合わせて直していて、`intent` は下流 phase の issue 件数とは分けて扱うこと、intent 起因問題は今後 `intent-attributed issue` として各 phase 側で数えることを明記しました。

現状の v1 baseline では、
- `intent_revision_count`
- `intent_handback_count`
- 各 phase の `intent-attributed issue count`

はまだ `未計測` です。今後これを本当に回すには、`intent` review artifact と、各 phase artifact に原因分類 field を追加するのが次段です。



```
では，追加
```

追加しました。

`intent` 側は [2026-05-09-intent-baseline-review.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/2026-05-09-intent-baseline-review.md:1) を新設し、v1 baseline として `intent_revision_count=0`、`intent_handback_count=0` を固定しました。再利用用の template も [intent-review-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/intent-review-template.md:1) に追加しています。

下流 phase 側は、「intent 起因の問題は `intent` の件数に混ぜず、`requirements / design / tasks / implementation` の `intent-attributed issue` として数える」ルールに揃えました。正本補助は [phase-review-metric-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/phase-review-metric-register.md:1)、workflow 反映は [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:181)、[workflow-repair-procedure.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md:73)、[workflow-gate-status.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md:20) です。completion report も [dual-reviewer-v1-completion-report.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reports/dual-reviewer-v1-completion-report.md:80) に反映済みです。

補足すると、今回の差分には前から未コミットの [dual-reviewer-v1-user-guide.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/guides/dual-reviewer-v1-user-guide.md:1) と [README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/README.md:1) も残っています。必要なら次は、今回の intent/metrics 追加だけに限定して commit するか、user guide 修正も含めてまとめて commit するかを分けます。



```
分けてコミット
```

intent / phase metrics 追加分だけを分けて commit しました。commit は `08252a3` (`Add phase metrics and intent review baseline`) です。

この commit には、phase metrics register、intent baseline review、intent review template、completion report 更新、workflow 文書更新だけを含めています。`README.md` と user guide は含めていません。親 repo 側の他の未整理変更も引き続き未コミットのままです。

::git-stage{cwd="/Users/Daily/Development/Rwiki-dev"}
::git-commit{cwd="/Users/Daily/Development/Rwiki-dev"}



```
次は？
```

次は 2 つあります。

1. この commit を push する  
   `08252a3` をリモートへ反映する。

2. 残してある user guide 系を別 commit で整理する  
   いま未コミットなのは主に [dual-reviewer-v1-user-guide.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/guides/dual-reviewer-v1-user-guide.md:1) と [README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/README.md:1) です。これは intent/metrics とは独立した文書修正として切れます。

順番としては、まず `08252a3` を push してから、user guide の unfinished 分を別 commit にするのが自然です。



```
2
```

README と user guide だけを分けて commit しました。commit は `6eb6c15` (`Add v1 user guide draft`) です。

この commit には [README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/README.md:1) と [dual-reviewer-v1-user-guide.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/guides/dual-reviewer-v1-user-guide.md:1) だけを含めています。親 repo 側の他の未整理変更は引き続き未コミットです。

::git-stage{cwd="/Users/Daily/Development/Rwiki-dev"}
::git-commit{cwd="/Users/Daily/Development/Rwiki-dev"}



```
さて、最初にｖ1がビルドされてから、修正を何度かしました。それらは、ｖ1の仕様書に追記されているでしょうか
```

完全には入っていません。正確には「修正の種類による」です。

入っているもの:
- `implementation conformance review` の追加と workflow gate 化
  - [requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/requirements.md:1)
  - [design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/design.md:1)
- `approved` と `adopted` の分離条件
  - これは後から spec を変えたというより、もともと [dual-reviewer-self-improvement/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/design.md:300) に書かれていて、コードを spec に合わせ直した形です。

spec には新規追記していないもの:
- replay resolver の fixture 固定依存の解消
  - これは実装ローカル修正で、現状は review artifact と signal に残っており、`.kiro/specs/` には明示追記していません。
- evidence-caveat linkage の heuristic 廃止
  - これもコードを design 意図に合わせ直した形で、spec 正本への追加追記はしていません。

spec ではなく workflow / 補助文書に入っているもの:
- `intent review`
- `intent-attributed issue`
- phase 別 metrics
  - [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:173)
  - [phase-review-metric-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/phase-review-metric-register.md:1)
  - [2026-05-09-intent-baseline-review.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/2026-05-09-intent-baseline-review.md:1)

要するに:
- code を spec に合わせた修正はある
- governance 追加は spec に反映済み
- ただし後半で加えた phase metrics / intent review の整理は、まだ主に `operations/` と `docs/` にある
- 厳密に「v1 の仕様書 = `.kiro/specs/*`」とするなら、まだ昇格し切っていない部分がある

次にやるなら自然なのはこれです。
- `dual-reviewer-implementation-governance` spec に `intent review` と `phase-review metrics` を正式追記する
- replay resolver / evidence-caveat linkage について、implementation detail のままでよいか、design note として格上げするかを決める

必要ならその spec 追記をそのまま進めます。



```
dual-reviewer-implementation-governance spec に intent review と phase-review metrics を正式追記する
```

正式追記しました。

`dual-reviewer-implementation-governance` spec の正本には、次を追加しています。

- requirements
  - [requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/requirements.md:107)
  - `Requirement 7: Intent Review and Phase-Review Metrics` を追加
- design
  - [design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/design.md:92)
  - `Stage 0: Intent Review` を追加
  - owner artifact に `phase-review-metric-register` と `intent review template/artifact` を追加
- tasks
  - [tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/tasks.md:165)
  - `Task 8: Formalize intent review and phase-review metrics` を追加
- metadata
  - [spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/spec.json:1)
  - `updated_at` を更新

あわせて validator も spec と整合させました。[validate_implementation_governance_artifacts.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/validate_implementation_governance_artifacts.rb:1) は now
- `phase-review-metric-register`
- `intent-review-template`
- concrete `intent review artifact`

まで検査します。再実行も通っています。

まだ未コミットです。必要ならこの spec 昇格分を次の独立 commit にします。



```
コミット
```

`implementation-governance` spec への正式追記分だけを commit しました。commit は `61f1ce5` (`Formalize intent review in governance spec`) です。

この commit には [requirements.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/requirements.md:1), [design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/design.md:1), [tasks.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/tasks.md:1), [spec.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/spec.json:1), [validate_implementation_governance_artifacts.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/validate_implementation_governance_artifacts.rb:1) だけを含めています。

::git-stage{cwd="/Users/Daily/Development/Rwiki-dev"}
::git-commit{cwd="/Users/Daily/Development/Rwiki-dev"}



```
replay resolver / evidence-caveat linkage について説明して
```

2 つとも、`implementation conformance review` で見つかった「動くが壊れやすい」種類の問題です。

**1. replay resolver**
[replay_input_resolver.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/self_improvement/replay_input_resolver.rb:1) の役割は、self-improvement proposal を backtest / replay するときに、元になった run の artifact を引き当てることです。

問題だったのは、local run の探索先が実質的に固定 fixture 名に縛られていたことです。つまり、
- `experiments/runs/<run_id>`
- 特定の fixture directory 数個

しか見ておらず、新しい fixture や別配置の local run を追加すると、実在する run でも `unresolved_run_root` になりえました。これは replay readiness の false negative です。

修正後は、固定名ではなく `run_manifest.yaml` を持つ local run directory を探索して、そこから `run_id` で引く形にしています。要するに、
- 具体名ベタ書き
から
- manifest ベース discovery
へ変えました。

**2. evidence-caveat linkage**
[evidence_register_builder.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/paper_interface/evidence_register_builder.rb:1) の役割は、paper 側の evidence register を作ることです。ここでは、どの artifact がどの claim を支え、どの caveat が付くかを残します。

問題だったのは、artifact に caveat を付けるときの判定が basename の部分一致ヒューリスティックだったことです。つまり、
- caveat ref の文字列に artifact 名っぽいものが含まれているか

で結んでいました。これは構造化参照ではなく偶然の命名に依存するので、traceability が弱いです。

修正後は、claim 側が持っている
- `supporting_artifact_refs`
- `caveat_refs`

を使って結ぶようにしました。つまり、
- 名前で推測する
から
- claim が宣言している参照で結ぶ
に変えています。

整理すると、
- replay resolver は「run をどう見つけるか」の問題
- evidence-caveat linkage は「caveat を何に紐づけるか」の問題

です。前者は replay/backtest の頑健性、後者は paper traceability の頑健性に効きます。



```
replay resolver / evidence-caveat linkage について、implementation detail のままでよいか、design note として格上げ
```

結論から言うと、両方とも「完全な implementation detail のまま」は弱いです。ただし格上げの重さは違います。

**1. replay resolver**
これは `design note` へ軽く格上げしたほうがよいです。

理由:
- replay input の解決単位は self-improvement の成立条件そのものだから
- `run_id` をどう root artifact に結びつけるかは、単なる探索ロジック以上に replay contract の一部だから
- ただし探索アルゴリズムの細部までは spec に上げる必要はない

入れるべき内容は、
- local run resolution は fixture 名固定に依存しない
- canonical anchor は `run_manifest.yaml` と `run_id`
- replay input preparation は run root discovery を manifest-based に行う

くらいで十分です。  
つまり「実装方法」ではなく「依存してよい解決原則」を design に書く、という扱いです。

**2. evidence-caveat linkage**
これはより強く `design note` へ上げるべきです。

理由:
- これは paper-interface の traceability contract に直接触れている
- heuristic linkage を許すかどうかは implementation choice ではなく evidence model の設計判断だから
- claim / artifact / caveat の関係は downstream reporting quality に波及する

入れるべき内容は、
- caveat linkage は文字列 heuristic ではなく構造化参照で行う
- artifact-specific caveat は claim が持つ `supporting_artifact_refs` と `caveat_refs` を canonical source にする
- basename や filename の部分一致を正本判定に使わない

です。

要するに:
- `replay resolver`: 軽い design note に昇格
- `evidence-caveat linkage`: 明示的な design contract に昇格

必要なら次は、この 2 点をそれぞれ
- `dual-reviewer-self-improvement/design.md`
- `dual-reviewer-paper-interface/design.md`
へ追記します。



```
はい
```

design note として格上げしました。

- `replay resolver`
  - [dual-reviewer-self-improvement/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/design.md:243)
  - local run の replay input 解決は fixture 名固定ではなく、`run_manifest.yaml` と `run_id` を anchor にした manifest-based discovery で行う、と明記しました。
- `evidence-caveat linkage`
  - [dual-reviewer-paper-interface/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/design.md:98)
  - claim-to-evidence / caveat linkage は文字列 heuristic ではなく、claim の `supporting_artifact_refs` と `caveat_refs` に基づく構造化参照を canonical にする、と明記しました。

記録も [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:918) に追加しています。今回は既存実装を design 正本に追認した形なので、validator 追加まではしていません。

まだ未コミットです。必要ならこの design note 昇格分だけを次の独立 commit にします。



```
コミット
```

`replay resolver / evidence-caveat linkage` の design note 昇格分を commit しました。commit は `a1dd925` (`Promote replay and caveat linkage design notes`) です。

この commit には [dual-reviewer-self-improvement/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/design.md:243), [dual-reviewer-paper-interface/design.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/design.md:98), [implementation-coordination-log.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-coordination-log.md:918) だけを含めています。

::git-stage{cwd="/Users/Daily/Development/Rwiki-dev"}
::git-commit{cwd="/Users/Daily/Development/Rwiki-dev"}



```
次にすべきこと
```

次は 3 つありますが、順番としてはこうです。

1. ここまでの未 push commit を push する  
   いま `08252a3`、`6eb6c15`、`61f1ce5`、`a1dd925` がローカルにあります。まず branch をリモートに揃えるのが自然です。

2. user guide の unfinished 部分を詰める  
   draft としては入っていますが、あなたが指摘した通り、まだ改善余地があります。これは v1 完成後の利用導線に直結します。

3. v1 の実運用フェーズに入る  
   つまり、実ターゲットに対して小規模な review run を回し、evaluation artifact を蓄積する段階です。これは「システム構築」から「システム使用」への移行です。

いま一番自然なのは `1` です。構築・spec追記・design note 昇格まで終わっているので、まず push して区切るのがよいです。



```
プッシュしてください
```

`codex/dual-reviewer-foundation` を push しました。最新は `a1dd925` (`Promote replay and caveat linkage design notes`) です。

今回の push で、phase metrics / intent review baseline / governance spec formalization / replay resolver と evidence-caveat linkage の design note 昇格までリモートに反映されています。

::git-push{cwd="/Users/Daily/Development/Rwiki-dev" branch="codex/dual-reviewer-foundation"}



```
Rwikiのメインに未コミットをコミット
```

Rwiki 側の未コミット 5 ファイルを commit しました。commit は `dbda25f` (`Add Rwiki dual-reviewer rebuild logs`) です。

含めたのは `.claude/settings.local.json`、`docs/dual-reviewer-log-10.md`、`docs/DR-rebuild-log-1.md`、`docs/DR-rebuild-log-2.md`、`docs/dual-reviewer-rebuild-plan.md` です。

::git-stage{cwd="/Users/Daily/Development/Rwiki-dev"}
::git-commit{cwd="/Users/Daily/Development/Rwiki-dev"}

