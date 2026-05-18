# Tasks

## 1. この文書の役割

この文書は `dual-reviewer-self-improvement` を implementation 可能な作業単位へ落とした task plan である。承認済み requirements.md（Requirement 1〜8）と design.md から全面再導出した。

`self-improvement` は runtime evidence と evaluation analysis を入力にして runtime / prompt / policy / schema / workflow を evidence-driven に改善する learning layer である。runtime の一部ではなく、evidence を読んで改善候補を formal artifact に変換する。本 task は次の順で作る。

- `learning/` directory skeleton と schema versioning
- signal intake と input 分類（valid / invalid / exploratory、provenance）
- signal extraction（runtime / evaluation 由来、pattern 抽出、findings artifact）
- proposal model（unit / target layer / state machine / normalization）
- replay / backtest model（test mode 分岐、入力、result artifact）
- decision / adoption model（approval gate / adoption register / rejection）
- rollback model（supersession 区別、invalidation 起点 rollback）
- paper narrative 分離
- テスト

## 2. 実装順序

1. `learning/` directory skeleton と schema versioning を確定する
2. input model（3 class、valid/invalid/exploratory、provenance 必須、manual→runtime handoff）
3. signal extraction（runtime/evaluation signal、pattern candidate、findings/templates artifact）
4. proposal model（unit、target layer、state machine、normalization）
5. replay / backtest model（test mode 選択、入力、result artifact）
6. decision / adoption model（approval gate、adoption register、rejection register）
7. rollback model（supersession 区別、invalidation 起点 rollback）
8. paper narrative 分離の強制
9. テスト

理由（design「Architecture」より）:

- signal intake → proposal がないと test / decision が成立しない
- adoption は test gate と version update を前提とする
- rollback は invalidation 契約を起点とするため decision/adoption 確定後に置く

## 3. Tasks

### Task 1: `learning/` directory skeleton と schema versioning を作る

根拠: design「Learning Artifact Layout」「Schema Versioning」、Requirement 2 受入 5、Requirement 5 受入 5。

作業:

- 正本出力先を固定する（design「Learning Artifact Layout」）。
  - `findings/{recurring_failure_signals.json,workflow_failure_signals.json,pattern_candidates.json}`
  - `proposals/{proposal_index.json,<proposal_id>.yaml}`
  - `backtests/{backtest_index.json,<proposal_id>.json}`
  - `templates/workflow_remediation_templates.json`
  - `approved-updates/adoption_register.json`
  - `rejected-updates/rejection_register.json`
  - `rollback/rollback_register.json`
- `learning/` 配下の全 artifact に `schema_version` field を持たせ、foundation 要件 3 受入 3 の versioning 規約（版管理スキーマ、silent 非互換編集禁止）に接続する（design Schema Versioning）。非互換変更時は `schema_version` を上げ既存 artifact を旧 version のまま解釈可能に保つ。スキーマ所有は self-improvement 側、foundation 規約には接続宣言のみ（foundation 修正不要）。

完了条件:

- proposal / backtest / adoption / rollback artifact の所在を説明できる（design Completion Criteria 第 2 項）
- 長期保存 artifact が version 差があっても読める

### Task 2: input model を作る

根拠: Requirement 1（受入 1〜6）、Requirement 7（受入 1〜5）、Requirement 8（受入 1〜5）、design「Input Model §1〜§2.5」「v2 Supporting Inputs」。

作業:

- input を 3 class に分ける: `review_quality_signal` / `workflow_failure_signal` / `evidence_quality_signal`（Requirement 1 受入 1・2、design §1）。
- valid runs=review quality 改善一次入力、invalid runs=workflow/validation/contamination 防止一次入力、exploratory runs=hypothesis seed のみ（adoption 根拠としては弱い）として扱い、distinction を保持する（Requirement 1 受入 3、design §2、Decision 2）。proposal artifact はどの input class とどの evidence maturity に依拠するか必ず記録する。
- 未記録の operator intuition / 通常編集 history を十分な入力にしない（Requirement 1 受入 4、Requirement 7 受入 3）。
- 入力 evidence → proposal の provenance を保持する（Requirement 1 受入 5）。必須 provenance が欠落/断絶時は proposal 生成を阻止する（Requirement 1 受入 6、foundation 要件 6 と整合、design §2）。
- review-mode provenance を保持し manual dogfooding と runtime-mediated を proposal 生成時に区別する（Requirement 7 受入 1・2）。manual dogfooding evidence が runtime-quality 等価を含意せず workflow/requirement 改善を motivate できるようにする（受入 4）。
- manual→runtime handoff boundary を保存する（Requirement 7 受入 5、design §2.5）。上書きは非破壊で `superseded_by` / `supersession_reason` / `supersession_at` を記録し、先行側に `supersedes` と `source_origin=manual_review_record` を保持する。
- imported external bundle 由来か central local run 由来かを保持し、imported 時は source repository identity / source revision / evaluation 側 admission status を保持する（Requirement 8 受入 1〜3）。provenance 不足 imported evidence を admitted standard comparison evidence と等価扱いしない（受入 5）。
- v2 supporting input（`run_manifest.yaml` / `v2/signal_linkage_note.json` / `v2/trace_note.json` / `derived/comparison_eligibility_note.json`）は signal extraction を助ける補助入力とし、読めなくても基本 flow が維持される設計にする（design §1.5）。

完了条件:

- valid / invalid / exploratory の signal をどう使い分けるか説明できる（design Completion Criteria 第 1 項）
- provenance 欠落時に proposal 生成が阻止される

### Task 3: signal extraction model を作る

根拠: Requirement 1 受入 5、design「Signal Extraction Model §1〜§4」「Proposal Normalization Rules」。

作業:

- runtime 由来 signal（repeated defer clusters / high reject concentration / frequent skip-marker misuse / repeated invalidation categories / repeated signal linkage）を抽出する（design §1）。
- evaluation 由来 signal（treatment-specific quality drop / phase-specific caveat concentration / low acceptance ratio in design・tasks / repeated analysis_blocked / repeated comparison-ineligible reasons）を抽出する（design §2）。
- `findings/recurring_failure_signals.json` を proposal 前 inventory として作る。findings/ と templates/ の required field を実装する（design §4）。signal エントリは `signal_id` / `signal_type` / `source_evidence_refs` / `occurrence_count` / `first_seen_run_ref` / `last_seen_run_ref` / `summary`、pattern candidate は `candidate_id` / `abstraction_level` / `source_signal_refs` / `summary`、template は `template_id` / `failure_mode` / `checklist` / `recommended_action` / `source_pattern_refs`。proposal の `source_evidence_refs` から findings、runtime/evaluation evidence まで機械的に辿れるようにする（Requirement 1 受入 5）。
- project-specific pattern 抽出 flow（recurring signal 抽出 → pattern candidate 整理 → meta-pattern 抽象化 → proposal/pattern asset 改訂接続）を実装する（design §3）。project-specific concrete と meta-pattern candidate を区別する。安定時に operator-facing remediation template を `learning/templates/workflow_remediation_templates.json` に派生させる。runtime validation summary は `scripts/track_runs/contracts/runtime_validation_summary.schema.json` を canonical contract とし track 間で payload shape を揃える。
- proposal normalization rules を実装する（design §2.5）。同一 run の closely-coupled workflow failure signal は 1 proposal に統合可（例 `validator_failed` + `invalidation_marker_issued`）、aggregate caveat signal は caveat code ごとに proposal identity を分ける。

完了条件:

- signal inventory が proposal 前に整理され出所連鎖が辿れる
- 同一 remediation surface を分断せず aggregate caveat を過併合しない

### Task 4: proposal model を作る

根拠: Requirement 2（受入 1〜5）、Requirement 4 受入 1、design「Proposal Model §1〜§4」。

作業:

- proposal を 1 改善仮説 = 1 artifact とする。`learning/proposals/<proposal_id>.yaml` は `proposal_id` / `status` / `target_layer` / `motivation_class` / `source_evidence_refs` / `source_origin` / `source_repository_refs` / `source_admission_refs` / `problem_statement` / `proposed_change_summary` / `expected_benefit` / `possible_risks` / `required_test_mode` / `created_at` を持つ（Requirement 2 受入 1・3・4、design §1）。
- `target_layer` enum を `prompt` / `policy` / `schema` / `runtime` / `workflow` で実装する（Requirement 2 受入 2、design §2）。`source_origin` enum を `central_local_run` / `imported_external_bundle` / `manual_review_record` で実装する。
- proposal state machine を実装する（design §3、Requirement 4 受入 1）。状態 `draft` / `awaiting_test` / `tested` / `approved` / `rejected` / `adopted` / `rolled_back`。許可遷移は design §3 の正本どおり（draft→awaiting_test / draft→rejected / awaiting_test→tested / tested→approved / tested→rejected / approved→adopted / approved→rejected / adopted→rolled_back）。終端は `rejected` と `rolled_back`。それ以外の遷移（draft→adopted 直行等）は許可しない。
- accepted と rejected proposal を first-class record として保持する（Requirement 2 受入 5）。
- review prioritization notes を補助規約として実装する（design §4、workflow > schema/evidence > prompt/policy、exploratory-only 由来は hold 候補、comparison impossibility 系 caveat を cautionary caveat より先に review 可）。

完了条件:

- proposal が target layer / motivation を曖昧にせず構造化される
- 不正遷移が state machine で禁止される

### Task 5: replay / backtest model を作る

根拠: Requirement 3（受入 1〜7）、design「Replay and Backtest Model §1〜§4」。

作業:

- proposal ごとに `required_test_mode`（`replay` / `backtest` / `manual_review`）を持たせる（design §1）。replay=recorded run evidence への再実行、backtest=existing derived results への軽量検証と定義する（Requirement 3 受入 6）。test mode 分岐を変更規模・リスク水準・対象レイヤーの 3 要素で判定する（Requirement 3 受入 1・6）。
- replay/backtest 入力は concrete run evidence を参照させる（Requirement 3 受入 2）。replay 最低入力=`review_case.json` / relevant `steps/*.json` / decision units / validator・invalidation artifacts / `run_manifest.yaml`（optional: `v2/trace_note.json` / `v2/signal_linkage_note.json`）。Step B・Step C 挙動に関わる proposal は step-level replay を必須にする（design §2）。local run root 解決は fixture 名/固定 path 列挙に依存せず `run_manifest.yaml` と `run_id` を canonical anchor として manifest-based discovery で解決する（replay readiness の false negative 防止）。
- backtest 最低入力=`run_classification_index.json` / `run_metrics.json` / `finding_metrics.json` / `caveat_register.json`（optional: `derived/comparison_eligibility_note.json`）（design §3）。
- test result artifact `learning/backtests/<proposal_id>.json` を作る。`proposal_id` / `test_mode` / `input_refs` / `input_origin_refs` / `result_label` / `observed_effect` / `risk_observations` / `tested_at` / `foundation_run_metadata_ref`（Requirement 3 受入 7：foundation 要件 6 実行メタデータ契約に束縛し独立に検証・無効化可能）。result artifact を raw run evidence と別 artifact として保持する（受入 3）。`result_label` enum=`supported` / `unsupported` / `inconclusive` / `untested`。
- proposal unsupported と proposal untested を区別する（Requirement 3 受入 4）。anecdotal plausibility を backtest evidence と等価扱いしない（受入 5）。imported external bundle を replay 入力に使う場合も元の source_repository_id / source_revision / admission_status を proposal と backtest artifact に残す。

完了条件:

- replay 必須 / backtest 十分の分岐が 3 要素で判定される
- test result artifact が foundation 実行メタデータ契約に束縛され独立検証・無効化可能

### Task 6: decision / adoption model を作る

根拠: Requirement 4（受入 1〜5）、design「Decision and Adoption Model §1〜§3」。

作業:

- approval gate を実装する（prompt / policy / schema / runtime-affecting workflow change に human approval 必須）（Requirement 4 受入 2、design §1）。`approved` は採否判断であり repo change が入ったことをまだ意味しない。
- adoption gate を実装する。`adopted` 条件=proposal が approved かつ required test artifact 存在かつ repo change が version update と結びつく（Requirement 4 受入 4、design §2、Decision 3）。`approved-updates/adoption_register.json` に `proposal_id` / `adopted_change_ref` / `version_update_ref` / `approval_ref` / `test_artifact_ref` / `adopted_at` を記録し proposal と repo change を結ぶ（Requirement 4 受入 3）。
- rejection model を実装する。`rejected-updates/rejection_register.json` に `proposal_id` / `rejection_reason` / `rejected_at` / `reviewer_note`。rejection を invisible discard でなく preserved outcome として残す（Requirement 4 受入 5、design §3）。

完了条件:

- approval と adoption の違いを説明できる（design Completion Criteria 第 3 項）
- adopted change が proposal・version update・approval・test artifact と連結保存される

### Task 7: rollback model を作る

根拠: Requirement 5（受入 1〜6）、design「Rollback Model」。

作業:

- rollback-triggering 条件を定義する（Requirement 5 受入 1）。rollback と supersession を区別する（受入 4、design：supersession=より新しい改善で置換、rollback=有害な採用 change を戻す）。
- `rollback/rollback_register.json` に `proposal_id` / `adopted_change_ref` / `rollback_reason` / `rollback_trigger_signal_refs` / `rolled_back_at` を記録する。reverted behavior を導入した accepted proposal と rollback reason を evidence として保持する（Requirement 5 受入 2・3）。
- failed improvement の history を削除せず次の proposal input につなげる（Requirement 5 受入 5、Decision 4）。
- 採用済み改善の motivating evidence が事後に invalidate された場合、foundation 無効化契約（foundation 要件 6）を起点に再評価または rollback を起動する（Requirement 5 受入 6、design）。成り立たない根拠の上に採用済み change を steady state で残さない。

完了条件:

- rollback が supersession と区別され履歴として保持される
- motivating evidence の事後 invalidate が再評価/rollback を起動する

### Task 8: paper narrative 分離を強制する

根拠: Requirement 6（受入 1〜5）、design「Separation from Paper Narrative」「Interfaces to Other Features」。

作業:

- paper-facing motivation を runtime-affecting proposal の主理由として単独採用しない（Requirement 6 受入 1、design：表整形のため runtime field 変更、論文都合で exploratory を valid 扱い等を禁止）。
- report-layer caveat handling と runtime-layer improvement を区別する（Requirement 6 受入 2）。改善の motivation が runtime quality / workflow quality / evidence quality のどれかを保持する（受入 3）。undocumented narrative-driven change を steady-state behavior に入れない（受入 4）。
- 初期 rebuild で external evidence intake を必須にせず将来互換を保つ（Requirement 6 受入 5）。paper-interface は self-improvement proposal を narrative source としない。adopted changes 履歴は methodology note 参照に留める（design Interfaces）。

完了条件:

- paper convenience 単独では runtime-affecting change が通らない
- 改善 motivation の layer 区別が保持される

### Task 9: テストを用意する

根拠: design「Completion Criteria」、プロジェクト開発方針（TDD）。

作業:

- proposal state machine の許可/不許可遷移を決定的に検証する。
- provenance 欠落時の proposal 生成阻止を検証する。
- test mode 分岐（3 要素）と result_label 整合（untested と awaiting_test→tested 遷移条件）を検証する。
- adoption gate 3 条件・rollback の invalidation 起点起動を検証する。
- TDD: 期待入出力に基づき先にテストを用意し失敗を確認してから実装する。

完了条件:

- design Completion Criteria 4 点（signal 使い分け説明・artifact 所在説明・approval/adoption 区別説明・境界説明）を満たす

## 4. Downstream Handoff

self-improvement は runtime に直接書き戻さない。採用済み proposal を通じて feature change に変換される（design Interfaces）。paper-interface は self-improvement proposal を narrative source として扱わず、adopted changes 履歴を methodology note 参照に留める。

## 5. Blocking Dependencies

phase-and-feature-dependency-map §5.3 に従い、次は先行成果物が固まるまで blocked。

- Task 2/3 は runtime の step-level replay artifact と evaluation の analysis output（classification index / metrics / caveat register）確定が前提
- Task 5 の foundation 実行メタデータ契約（要件 6）確定が前提（backtest artifact 束縛）
- Task 7 の foundation 無効化契約確定が前提（invalidation 起点 rollback）

## 6. Completion Criteria

design「Completion Criteria」に従い、少なくとも次を満たすとき本 task plan は有効とみなす。

- valid / invalid / exploratory の signal をどう使い分けるか説明できる
- proposal、backtest、adoption、rollback artifact の所在を説明できる
- approval と adoption の違いを説明できる
- runtime / evaluation / paper-interface との境界を説明できる
