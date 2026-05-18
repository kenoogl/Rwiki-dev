# Tasks

## 1. この文書の役割

この文書は `dual-reviewer-runtime` を implementation 可能な作業単位へ落とした task plan である。承認済み requirements.md（Requirement 1〜9、Requirement 10 は削除済み）と design.md から全面再導出した。

`runtime` は foundation contract の consumer であり、review session を実行して evaluation / self-improvement / paper-interface に evidence を渡す producer である。本 task は次の順で作る。

- code / run directory skeleton
- session controller（lifecycle・入力・軸分離）
- Step A/B/C/D executors（treatment × step 実行）
- prompt resolution
- decision unit と human sign-off
- evidence writing（raw / derived 分離、review_case 正本、failure_observation）
- validator integration と Run Close Boundary
- invalidation handling と triage note
- portable evidence bundle export
- phase-aware review profiles
- テスト（design Testability Seams 準拠）

## 2. 実装順序

1. code / run directory skeleton を確定する
2. session controller（run lifecycle・session inputs・run_manifest field set・phase/treatment 軸）
3. prompt resolution model（step executor の入力前提を先に確定）
4. Step A/B/C/D executors と treatment × step 実行マトリクス
5. decision unit model と human sign-off record
6. evidence writing model（raw/derived 分離、review_case 正本、failure_observation）
7. validator integration と Run Close Boundary
8. invalidation handling と invalid-run triage
9. portable evidence bundle export
10. phase-aware review profiles
11. テストと testability seams

理由（design「Architecture」「Interfaces to Downstream Features」より）:

- controller と step executor がないと evidence を emit できない
- validator integration がないと valid/invalid 分岐ができず evaluation が consume できない
- export は close / validation 後の別工程のため後段に置く

## 3. Tasks

### Task 1: code / run directory skeleton を確定する

根拠: Requirement 1 受入 6、design「Runtime Artifact Layout」「File Placement for v2 Runtime Core」。

作業:

- 1 run の正本ディレクトリ構造を固定する（design「Runtime Artifact Layout」）。
  - `experiments/runs/<run_id>/run_manifest.yaml`
  - `review_case.json`
  - `steps/step_{a_primary_detection,b_adversarial_review,c_judgment,d_integration}.json`
  - `decisions/{decision_units.json,human_signoff.json}`
  - `failures/failure_observation.json`
  - `v2/{review_artifact.json,metric_snapshot.json,trace_note.json,signal_linkage_note.json}`
  - `validation/{validator_result.json,invalidation_markers.json}`
  - `derived/{runtime_summary.json,comparison_eligibility_note.json,invalid_run_triage_note.json}`
- runtime code 配置を固定する（design「File Placement for v2 Runtime Core」）。
  - `runtime/execution_v2/{manifests,analyzers,decisions,writers,contracts}/`
  - `scripts/{protocol_runners,track_runs}/`

完了条件:

- 1 run の artifact layout を説明できる（design Completion Criteria 第 1 項）
- analyzer / downstream 変換 / manifest logic を混在させない配置規約が読める（design「File Placement」ルール）

### Task 2: session controller を作る

根拠: Requirement 1（受入 1〜6）、Requirement 8（受入 1・3・5）、design「Session Model §1〜§3」「Run Manifest Field Set」「Reference-Free Runtime Entry Principle」。

作業:

- run lifecycle を `created` → `in_progress` → `closed` / `orchestration_failed` で実装する。`closed` は raw evidence 凍結のみを意味し validity を意味しないことを明示する（design §1）。
- session inputs を run 開始時に固定し run 中に上書きしない（design §2）。`run_manifest.yaml` の開始時固定群（`run_id` / `target_id` / `target_artifact_hash` / `source_repository_id` / `source_revision` / `phase_profile` / `treatment` / `review_mode` / `protocol_version` / `runtime_version` / `prompt_set_version` / `schema_set_version` / `config_version` / `config_hash` / operator identity / `started_at`）と実行中更新群（`run_status` / `validator_status` / `human_signoff_status` / `evidence_class` / `closed_at`）を分けて記録する。
- metadata の語彙・責務分離は foundation §Run Metadata Contract を継承し再定義しない（design「Run Manifest Field Set」）。
- `evidence_class` は run close 時に初期値 `candidate` を記録し、確定遷移は foundation 契約に従う検証・承認結果に委ねる（design §2、foundation 要件 6 受入 2・8）。
- `phase_profile`（`intent` / `requirements` / `design` / `tasks`）と `treatment`（`single` / `dual` / `dual+judgment`）を独立軸として扱う（Requirement 8 受入 5、design §3）。
- reference-free entry: generic runtime code が特定 case の basename / case id を hidden default にしない。case manifest か明示入力群のみ受ける（design「Reference-Free Runtime Entry Principle」「Generic Protocol Entrypoint Rule」、`case_manifest_ref` 無し時は track 必須入力を明示、両方無しは fail fast）。
- case manifest の base 必須項目（`case_id` / `track` / `source_refs` / `case_manifest_ref`）と track 別必須項目を `runtime/execution_v2/manifests/` で固定する（design「Case Manifest and Heuristic Resolution Model」）。

完了条件:

- run close と validation の順序を説明できる（design Completion Criteria 第 2 項）
- run 開始固定入力が `run_manifest.yaml` に記録され run 中不変

### Task 3: Step A/B/C/D executors と treatment × step 実行を作る

根拠: Requirement 1（受入 1〜4）、Requirement 2（受入 1〜5）、design「Step Execution Model」「Treatment × Step Execution Matrix」。

作業:

- Step A（`primary_detection`）/ B（`adversarial_review`）/ C（`judgment`）/ D（`integration`）を canonical 順序で実行する（Requirement 1 受入 1、design Step Execution Model）。
- step transition を run record に明示する（Requirement 1 受入 2）。
- treatment を first-class run attribute として記録し（Requirement 2 受入 1）、最低 `single` / `dual` / `dual+judgment` を支援する（受入 2）。
- treatment × step 実行マトリクスを正本どおり実装する（design 表）。`single`=A executed/B,C skipped/D executed、`dual`=A,B executed/C skipped/D executed、`dual+judgment`=全 executed。
- 実行状態 3 値 `executed` / `skipped` / `reduced` を定義し、`skipped`・`reduced` step は marker record（`step_id` / `step_name` / `execution_state` / `reason` / `treatment`）を残す（Requirement 2 受入 3・4、design）。`reduced` は現行 3 treatment 未使用だが将来語彙として定義。
- 設計上の意図的 skip と事故的欠落を run record だけで区別する（Requirement 1 受入 4、Requirement 2 受入 5）。
- Step B forced-divergence: 最終同意時も独立した反証を必ず試行し、各 finding の `adversarial_outcome` に `counter_evidence_raised` / `no_counter_evidence_after_challenge` / `not_assessed` を必ず設定する（Requirement 1 受入 4 ＝ foundation 要件 1 受入 4、design Step B）。
- Step D 統合は追加 LLM 呼び出しなしの機械手順（design Step D の 6 手順）。decision units（proposed_action 付き・human_decision 未確定）と run close readiness signal を出力する。accepted/rejected/deferred は Step D 出力ではなく後段 sign-off 結果（design Step D 末尾）。
- 注記：本 Task は規模が大きいため、実装着手時にサブタスク分解（Step A/B、Step C、Step D 統合）を検討する。分解は実装判断に委ね、過剰分割は避ける。

完了条件:

- 各 treatment で実行/skip/reduced が run record から一意に読める
- Step D が言語モデル非依存の機械統合として入出力対応で検証できる（design Testability Seams 第 4 項）
- Step A/B/C/D と treatment×step matrix が Task 11 の決定的検証ケースで pass する

### Task 4: prompt resolution model を作る

根拠: Requirement 3（受入 1〜5）、Requirement 8 受入 6、design「Prompt Resolution Model」「Role and Step Mapping」「Prompt Identity Recording」。

作業:

- prompt body を code 内に持たず、repo-contained path resolution で読む（Requirement 3 受入 1・5）。
- resolution order: foundation canonical prompt path → runtime-owned role/phase override path → ambiguous なら explicit failure（design）。runtime が override resolution policy を所有する（Requirement 8 受入 6、foundation placement/identity は保持）。
- role × step 対応を正本どおり実装（Step A=`primary_reviewer` / B=`adversarial_reviewer` / C=`judgment_reviewer` / D=role なし）。foundation 抽象ロール名を継承（design Role and Step Mapping）。
- 各 step record に prompt identity（`prompt_artifact_path` / `prompt_id` / `prompt_version` / `role`）を記録する（Requirement 3 受入 2・3、design Prompt Identity Recording）。
- 必須 prompt を一意に解決できない run は fail または invalid mark（Requirement 3 受入 4）。

完了条件:

- replay 時に「同 step だが prompt 違い」を判別できる
- repo 外 prompt source に steady-state 依存しない

### Task 5: decision unit model と human sign-off record を作る

根拠: Requirement 5（受入 1〜5）、design「Decision Unit Model」「Human Sign-off Record」。

作業:

- raw finding をそのまま渡さず decision unit に束ねて提示する（Requirement 5 受入 1、design）。`decisions/decision_units.json` の各 unit は `decision_unit_id` / `finding_refs` / `judgment_refs` / `proposed_action` / `human_decision` / `human_decision_timestamp` / `human_decision_note` を持つ。
- 各 decision unit の human decision outcome を記録する（Requirement 5 受入 2）。human decision absence と明示 defer / reject を区別する（受入 3）。
- `decisions/human_signoff.json` を run レベル正本として作る。`run_id` / `human_signoff_status`（foundation enum `pending`/`approved`/`rejected`/`deferred`）/ `signed_off_by` / `signed_off_at` / `covered_decision_unit_ids` / `signoff_note`。Run Close Boundary の起点で validator 呼び出しより前に書く（Requirement 5 受入 4、Requirement 6 受入 9、design）。
- LLM finding を silent に auto-adopt しない（Requirement 5 受入 5）。

完了条件:

- decision unit が finding と human judgment をどう接続するか説明できる（design Completion Criteria 第 3 項）
- 承認なしに run が closed 扱いにならない

### Task 6: evidence writing model を作る

根拠: Requirement 4（受入 1〜7）、Requirement 7（受入 1〜5）、design「Evidence Writing Model」「`review_case.json`」、設計横断整合ゲート 2026-05-18（実行側 A-5）。

作業:

- evidence を 3 層で書き分ける（raw step `steps/*.json` / human-decision `decisions/*` / v2 internal `v2/*`）。raw step outputs は immutable（Requirement 4 受入 4、design Raw vs Derived Separation）。
- `review_case.json` を唯一の横断正本とする（スキーマは foundation 所有）。`review_artifact.json` は runtime 内部限定 taxonomy-first 表現にとどめ、runtime が `review_artifact.json` → `review_case.json` 投影規約を所有・定義し review_case が常に foundation スキーマ準拠であることを保証する（実行側 A-5 決定、design）。
- finding-level record に source attribution と judgment linkage を出す（Requirement 4 受入 2）。counter-evidence / override 関連 field を該当時に出す（受入 3）。
- review-mode provenance を foundation metadata contract 準拠で出す（Requirement 4 受入 6）。
- review run が failure mode に陥ったとき `failures/failure_observation.json` を foundation `failure_observation` schema 準拠で必ず出す（Requirement 4 受入 7、design）。未使用 schema のまま放置しない。
- replay / proposal 分析に十分な情報を保持し、過圧縮しない（Requirement 4 受入 5、Requirement 7 受入 1〜5）。step-level 境界・prompt/treatment identity を保持し、品質問題と workflow/validation 問題を区別可能にする（Requirement 7 受入 2〜4）。
- `derived/comparison_eligibility_note.json` のスキーマと最小 6 項目（`run_id` / `eligible_for_standard_comparison` / `ineligibility_reason_codes` / `treatment` / `phase_profile` / `generated_at`）を runtime 所有として定義・生成する（評価 A-7 決定。評価は本スキーマに依存し再定義しない＝producer 側責務）。
- `v2/metric_snapshot.json` の生成責務を runtime writer 側に明示する（design layout に存在。未生成の空 artifact を残さない）。
- `scripts/track_runs/contracts/runtime_validation_summary.schema.json` を runtime 所有 contract として定義・固定し、track 間で payload shape を揃える（自己改善 T5-A 決定＝案 A。self-improvement は consumer 依存・再定義しない＝comparison_eligibility_note の A-7 と同型の producer 側責務）。

完了条件:

- downstream 3 feature が runtime のどの artifact を読むか追跡できる（design Completion Criteria 第 4 項）
- `review_case.json` が常に foundation `review_case` schema に準拠する
- `derived/comparison_eligibility_note.json` が A-7 最小 6 項目を満たし runtime 所有スキーマとして生成される
- evidence writing（review_case 正本・投影規約・failure_observation）が Task 11 の決定的検証ケースで pass する
- `runtime_validation_summary.schema.json` が runtime 所有 contract として定義・固定され、self-improvement が consumer 依存で再定義しない（T5-A 案 A）

### Task 7: validator integration と Run Close Boundary を作る

根拠: Requirement 6（受入 1〜9）、design「Validator Integration」「Run Close Boundary」「Validation Outcomes」。

作業:

- Run Close Boundary の順序を厳守する: Step D 完了 → human sign-off artifact 書込 → raw evidence freeze → validator invocation → `validator_result.json` 保存（Requirement 6 受入 9、design）。validator 結果が human decision に先行しない。
- run close 成立後に invalidation marker 付与 → `invalid_run_triage_note.json` 生成 → `run_manifest.yaml`・`review_case.json` metadata 更新の順を崩さない（design Run Close Boundary）。
- validator status を foundation 所有の正準 enum（`not_run` / `passed` / `failed` / `blocked`、foundation Task 3 が所有）をそのまま伝播し、実行側で再定義・丸め・別トークン化をしない（Requirement 6 受入 2、design Validation Outcomes）。`blocked` をそのまま伝播し insufficiency detail を併記する。
- validator failure と orchestration failure を区別する（Requirement 6 受入 4）。required validation 失敗時に downstream「valid run」扱いを防ぐ（受入 5）。
- runtime-produced evidence を canonical runtime-mediated review mode で mark する（Requirement 6 受入 6）。
- validation/invalidation が workflow failure を示すとき machine-readable invalid-run triage artifact を出す（Requirement 6 受入 7）。failed checks・invalidation marker・remediation hint の linkage を保持する（受入 8）。

完了条件:

- run close と validation の順序を説明できる（design Completion Criteria 第 2 項）
- `blocked` が final metadata まで丸めなしで伝播する
- Run Close Boundary 順序と validator 伝播が Task 11 の決定的検証ケースで pass する

### Task 8: invalidation handling と invalid-run triage を作る

根拠: Requirement 6（受入 3・7・8）、design「Invalidation Handling」。

作業:

- invalidation を raw evidence 編集ではなく `validation/invalidation_markers.json` への追加で表現する（Requirement 6 受入 3、design）。
- runtime 自動 marker（missing required artifact / unresolved prompt identity / run close without sign-off / treatment-step mismatch）を出す。人間判断要のもの（contamination・hidden intervention）は human-issued marker として同形式に追加する。
- invalid run 時に `derived/invalid_run_triage_note.json` を生成する（primary failure code / failed validator check ids / invalidation marker linkage / operator action hint）。self-improvement / protocol review の正規補助入力として使える形にする（design）。

完了条件:

- invalid 判定が raw evidence を汚さず別 artifact に分離されている
- triage note が failure 再発分析の補助入力として読める

### Task 9: portable evidence bundle export を作る

根拠: Requirement 9（受入 1〜5）、design「Portable Evidence Bundle Export」。

作業:

- export は close / validation 後の別工程とし run 実行に含めない（Requirement 9 受入 4、design Export Boundary）。
- raw run directory の意味を書き換えず bundle copy を作る（受入 1）。missing provenance を暗黙補完しない、central-side admission を済ませたことにしない（design）。
- bundle 構造 `exports/<bundle_id>/{bundle_manifest.yaml,run/<run_id>/...,checksums/bundle_checksums.json}` を作る。`bundle_manifest.yaml` は `bundle_id` / `run_id` / `source_repository_id` / `source_revision` / `review_mode` / `exported_at` / `export_runtime_version` / `included_artifact_refs` を持つ（Requirement 9 受入 2・3、design Bundle Shape）。
- bundle の意味再構成に repo 外 hidden memory を要さない（受入 5）。runtime 正本は `experiments/runs/<run_id>/` のままとする。

完了条件:

- export が raw run の意味を書き換えず provenance を保持する
- bundle が admission 判定と区別されている

### Task 10: phase-aware review profiles を作る

根拠: Requirement 8（受入 1〜5）、design「Phase-Aware Review Profiles」。※ Requirement 8 受入 6（prompt override 所有）は Task 4 が担当。

作業:

- `intent` / `requirements` / `design` / `tasks` の explicit phase/profile 選択を支援する（Requirement 8 受入 1）。
- profile ごとの emphasis を runtime-owned profile configuration に置く（design、foundation に戻さない）。初版 emphasis: intent=goal ambiguity/non-goal leakage、requirements=scope drift/requirement inconsistency、design=responsibility boundary/dependency mismatch/failure mode omission、tasks=coverage gap/ordering risk/unverifiable task decomposition。
- canonical Step A/B/C/D state machine を変えずに emphasis を切り替える（Requirement 8 受入 2）。`design`/`tasks` は upstream より強い構造・依存指向 review にする（受入 4）。
- 使用 phase/profile を run metadata に保持する（受入 3）。treatment 選択と phase/profile 選択を区別する（受入 5）。

完了条件:

- state machine を変えずに profile emphasis が切り替わる
- 使用 profile が run metadata から追跡できる

### Task 11: テストと testability seams を用意する

根拠: design「Testability Seams」「Completion Criteria」。詳細テスト計画は本タスク工程で策定する。

作業:

- 言語モデル差し替え点: 各 step executor の LLM 呼び出しを差し替え可能境界とし、固定応答で決定的に検証する。
- 検証ブリッジ起動点: validator 呼び出しを Run Close Boundary の単一起動点に集約し、入力（凍結後 raw evidence）と出力（`validator_result.json`）で単体検証する。
- ステップ入出力分離点: 各 step executor を入力（前 step 出力・prompt artifact・config）と出力（`steps/*.json`）で分離し前後 step なしで単体検証する。
- 決定単位生成検証: Step D の機械統合に固定 Step A/B/C 出力を与え入出力対応で検証する。
- TDD: 期待入出力に基づき先にテストを用意し失敗を確認してから実装する（プロジェクト開発方針）。

完了条件:

- 4 つの testability seam（言語モデル差し替え／検証ブリッジ起動点／ステップ入出力分離／Step D 機械統合）それぞれに、固定入力 → 期待出力の決定的検証ケースが 1 つ以上存在し pass する（着手前にこの客観基準を確定。TDD で先行）
- design Testability Seams 4 点が検証できる
- Completion Criteria（artifact layout 説明・close 順序説明・decision unit 接続説明・downstream 追跡）を満たす

## 4. Downstream Handoff

runtime tasks 完了後に downstream が読んでよい artifact（design「Interfaces to Downstream Features」）。

- evaluation: `run_manifest.yaml` / `review_case.json` / `decisions/decision_units.json` / `validation/validator_result.json` / `validation/invalidation_markers.json` / `derived/comparison_eligibility_note.json`（`derived/runtime_summary.json` には依存させない）
- self-improvement: step files / decision units / validator・invalidation artifacts / `derived/invalid_run_triage_note.json` / `failures/failure_observation.json`（特に Step B・Step C を replay 入力に。optional 補助: `v2/signal_linkage_note.json` / `v2/trace_note.json`）
- paper-interface: runtime から直接 raw step file を読ませず原則 evaluation 出力経由。paper convenience のために artifact shape を変えない

## 5. Blocking Dependencies

`foundation` tasks 完了までは次の runtime task が blocked（phase-and-feature-dependency-map §5.3）。

- Task 1 の `review_case.json` concrete storage（foundation schema 確定が前提）
- Task 6 の foundation schema 準拠 evidence emission
- Task 7 の foundation canonical validator-status 語彙伝播
- Task 9 の portable bundle（foundation provenance field 確定が前提）

### 5.1 Task 間依存グラフ（§2 から導出。並列可を明示）

- Task 1（skeleton）→ Task 2（controller）が起点。
- Task 2 → Task 4（prompt resolution）→ Task 3（step executors。Task 4 の prompt 解決契約を前提）。
- Task 3 → Task 5（decision unit）→ Task 6（evidence writing）→ Task 7（validator/close）→ Task 8（invalidation/triage）。
- Task 9（portable export）は Task 7（close）後。
- Task 10（phase profile）は Task 2 後に着手可で Task 3〜8 と並列可。
- Task 11（テスト）は全 Task と並走（TDD 先行）。
- 外部前提：Task 1/6/7/9 は foundation tasks 完了が blocking（上記）。

### 5.2 失敗時の巻き戻し単位

Task 1〜5・10 は task-local 吸収。Task 6/7/9 で foundation 契約不足が判明したら handback class C で foundation へ戻す。実行時の invalidation は raw evidence を編集せず marker 追加で表現し、巻き戻しは raw 不変を維持（design Decision 3、Task 8）。

## 6. Completion Criteria

design「Completion Criteria」に従い、少なくとも次を満たすとき本 task plan は有効とみなす。

- 1 run の artifact layout を説明できる
- run close と validation の順序（Step D → human sign-off → validator → close）を説明できる
- decision unit が finding と human judgment をどう接続するか説明できる
- downstream 3 feature が runtime のどの artifact を読むか追跡できる
- `review_case.json` が foundation `review_case` schema に常時準拠し、`review_artifact.json` 投影規約を runtime が所有する（実行側 A-5）
