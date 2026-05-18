# implementation conformance review

_実施日: 2026-05-19_
_レビュー種別: implementation conformance review（独立適合レビュー。実装者とは別プロセス・別視点）_
_対象 feature: dual-reviewer-runtime（実行系のスクラッチ再実装）_
_reviewed commit: `1085b3f1bb7495600fa7ffd421b3a1370cbde37f`_
_review focus: スクラッチ再実装が現行承認仕様（再確定設計 §「実装適合差し戻し対応」を含む）へ構造適合し、前回 finding 11 件（手戻り A7/B4）が解消したかを独立確認する_
_正本: docs/coordination/implementation-conformance-review.md / docs/reviews/templates/implementation-conformance-review-template.md_

本証跡は生証跡として不変扱いとする。本レビューにおいてコード・spec・design・requirements・tasks・基盤資産は一切変更していない（点検と所見記録のみ）。前回証跡（`implementation-conformance-review-2026-05-18.md`）は鵜呑みにせず独立判断した。

## 1. review scope

- review type: `implementation conformance review`
- reviewed branch: `claude/v2-acquisition-code-mod`
- reviewed commit: `1085b3f1bb7495600fa7ffd421b3a1370cbde37f`
- reviewed features: `dual-reviewer-runtime`（実行系。基盤確定済み契約 `runtime/foundation/`・`runtime/schemas/`・`runtime/prompts/`・`runtime/validators/contracts/`・`runtime/config/` を consumer 前提とし、乖離は実行系側で評価）
- review focus:
  - 前回 B 群（finding 2/5/6/9）が再確定設計（design §793-802）どおりに解消したか
  - 前回 A 群（finding 1/3/4/7/8/10/11）が解消したか
  - Requirement 1〜9 受入と Task 1〜11 完了条件・§4 Downstream Handoff・§6 Completion Criteria を実装が満たすか
  - 基盤契約適合（review_case 投影規約 A-5・comparison_eligibility_note A-7・runtime_validation_summary T5-A）と撤廃済み旧資産依存残存
  - 静的・スモーク無回帰

### 点検対象とした実装の所在

- `runtime/controller/session_controller.rb`
- `runtime/execution_v2/{analyzers/step_executors.rb, decisions/step_d_integration.rb, decisions/decision_units.rb, prompts/prompt_resolver.rb, validation/validation_bridge.rb, validation/invalidation_handler.rb, writers/*, contracts/*, profiles/*, manifests/*}`
- 実行系所有スクリプト：`scripts/run_review_session.rb`・`scripts/run_{intent,spec,implementation}_track_protocol.rb`・`scripts/track_runs/`（runtime 所有分）・`scripts/bootstrap_reference_free_case.rb`
- テスト：`tests/runtime/test_*.rb`（15 ファイル）

## 2. validation rerun

- rerun commands:
  - `ruby -c` 構文検査：controller 1 件＋`runtime/execution_v2/` 全 `.rb`＋実行系スクリプト 5 件＋`tests/runtime/` 15 件 → 全件 `Syntax OK`（SYNTAX FAIL ゼロ）
  - `tests/runtime/*.rb` 15 ファイル各実行
  - `tests/foundation/test_foundation_contracts.rb`
  - `tests/governance/test_req9_suite.rb`
  - reference-free entry スモーク：`SessionController#start_run` を 3 treatment（single/dual/dual+judgment）で実行＋reference-free fail-fast ガード負例
  - 旧資産依存の live require 閉包解析（live driver `runtime_session_driver.rb` および in-scope 4 スクリプトの transitive require closure）
- result summary:
  - `tests/runtime/`: 15 ファイル全 PASS。合計 170 runs / 1226 assertions / 0 failures / 0 errors / 0 skips。
  - `tests/foundation/test_foundation_contracts.rb`: 8 runs / 107 assertions / 0 failures。撤廃済み旧資産（`runtime/patterns`・`runtime/validators/contracts/review_mode_vocab.yaml`・`runtime/prompts/{primary,adversarial,integration,shared}`）の不在を機械検証し pass。
  - `tests/governance/test_req9_suite.rb`: 6 runs / 10 assertions / 0 failures。
  - スモーク：3 treatment すべてで run 1 件開始成立（run_manifest.yaml 生成・run_status=`in_progress`）。前回 finding 1 の `initialize_run` 即失敗（`KeyError: review_protocol`）は再現せず。reference-free fail-fast ガードも正常に発火。
  - require 閉包解析：live driver と in-scope 全スクリプトの transitive require closure に旧 `runtime/executors/`・旧 `runtime/validation/validation_bridge.rb`・retired-pattern ファイル（`rule_match_analyzer`/`heuristic_profile_loader`/`common_execution_contract`/`base_analyzer`）は一切含まれない（clean）。
  - 無回帰：前回（11 finding・実行不能）からの回帰なし。むしろ全 finding 解消方向。

## 3. findings

### Finding 1 `P3`

- title: 旧 v1 実装ファイル群が物理削除されず git-tracked のまま残存する（dead code・撤廃済みパターン依存を内包）
- file: `runtime/executors/{base_step_executor,step_a_primary_detection,step_b_adversarial_review,step_c_judgment,step_d_integration}.rb`、`runtime/validation/validation_bridge.rb`、`runtime/writers/evidence_writer.rb`（いずれも 2026-05-13 付・最終変更 commit `84d57543`/`6f6c3db2`）
- references: 本レビュー依頼文脈「旧 v1 ベース実装は破棄」／前回 finding 2/5/6 が指摘した旧 anti-pattern の所在／docs/coordination/implementation-conformance-review.md §5.2「placeholder / 撤廃済み依存の残存」
- description: 新スクラッチ実装は `runtime/execution_v2/`・`runtime/controller/` に置かれ、live require 閉包（`runtime_session_driver.rb`＋in-scope 4 スクリプト＋controller）から旧 `runtime/executors/`・旧 `runtime/validation/validation_bridge.rb`・`runtime/writers/evidence_writer.rb` への参照は一切ない（独立に require closure 解析で確認）。一方これら旧ファイルは git-tracked のまま物理削除されておらず、旧 `validation_bridge.rb` は前回 finding 6 の `asset_loader.metadata_contract.fetch("contract_id")`／`.fetch("required_fields")`／`review_mode_vocabulary` を、旧 `base_step_executor.rb` は前回 finding 4 の frontmatter `prompt_version` キー誤り・前回 finding 5 の `HeuristicProfileLoader`/`RuleMatchAnalyzer` 依存を内包したまま残る。基盤再実装で参照先資産は削除済みのため、これら旧ファイルは require 不能の dead code。
- impact: 即座には壊れない（live path から到達不能で test も green）。ただし撤廃済み anti-pattern を内包する旧実装が repo に同居し、誤って require/復活された場合に前回 finding 群を再導入しうる。traceability/maintainability を弱め、「旧実装は破棄」の宣言と repo 実態が乖離する。
- recommended action: 旧 `runtime/executors/`・旧 `runtime/validation/validation_bridge.rb`・旧 `runtime/writers/evidence_writer.rb` を物理削除（または明示的 deprecated 隔離）。`tests/foundation/test_foundation_contracts.rb` の旧資産不在検証に旧実装ディレクトリも加えると再発防止が機械化される。
- impact severity: P3（即破綻せず。traceability/maintainability 低下）
- handback assessment: A（task-local。設計境界・要件は不変。実装側の cleanup のみで吸収可能）
- status: open / disposition=`fix-in-current-branch`

### Finding 2 `P3`

- title: in-scope 実行系スクリプト `bootstrap_reference_free_case.rb` が撤廃済み heuristic-profile 概念への参照を残す
- file: `scripts/bootstrap_reference_free_case.rb:9,42-44`、`scripts/track_runs/default_heuristic_profile_ref.rb`
- references: requirements.md Requirement 10「削除済み」（`heuristic_profile_ref`・種パターン照合は v2 で実 LLM へ置換）／design §557「`heuristic_profile_ref` 撤廃」「§574 Generic Fragment Cue Rule（削除済み）」
- description: `bootstrap_reference_free_case.rb`（実行系所有スクリプト・点検対象）は `require_relative "track_runs/default_heuristic_profile_ref"` を持ち、bootstrap 出力で `default {intent,spec,implementation} heuristic: experiments/protocols/heuristic_profiles/<track>/_minimal_template.yaml` を `puts` する。`heuristic_profile_ref`／heuristic-profile 体系は Requirement 10 削除・design §557/§574 で撤廃方針が明文化された旧 v1 取得概念。live require 閉包としては `bootstrap` のみで session 実行系（controller/step executor/validation）には波及しないが、in-scope の実行系スクリプトに撤廃済み概念の生存参照が残る。
- impact: run 実行系の正路（controller→step→validator）には到達せず実害は限定的。ただし「撤廃済み旧資産（heuristic_profile_ref）への依存残存ゼロ」という基盤契約適合の中心問い 4 に対し、in-scope スクリプトでゼロを満たさない。誤誘導（撤廃済み概念がまだ有効に見える bootstrap 出力）の余地。
- recommended action: `bootstrap_reference_free_case.rb` の heuristic-profile 参照・出力行を撤廃し、`scripts/track_runs/default_heuristic_profile_ref.rb` を削除（または v2-acquisition spec への参照に置換）。
- impact severity: P3（実行正路に波及せず。撤廃方針との表面不整合）
- handback assessment: A（task-local。設計は撤廃を既に明記。実装側スクリプトの追随漏れ）
- status: open / disposition=`fix-in-current-branch`

### Finding 3 `P3`

- title: 撤廃済みパターン照合系ファイルが `runtime/execution_v2/` 配下に dead code として同居する
- file: `runtime/execution_v2/analyzers/{rule_match_analyzer,heuristic_profile_loader,base_analyzer,intent_protocol_analyzer,spec_protocol_analyzer,analysis_profile_loader}.rb`、`runtime/execution_v2/contracts/common_execution_contract.rb`
- references: Requirement 10「削除済み」／design §574「Generic Fragment Cue Rule（削除済み）」／前回 finding 5
- description: `rule_match_analyzer.rb:633` は `reusable_seed_patterns`/`project_accumulated_patterns` を読む種パターン照合の残骸、`common_execution_contract.rb:83` は撤廃済み `asset_loader.review_mode_vocabulary` を参照する。これらは `protocol_track_session`/`protocol_track_mediator` 経路に属し、本レビュー対象の session 実行正路（`runtime_session_driver`→controller→`execution_v2/analyzers/step_executors.rb`（LLM seam）→`step_d_integration`→`validation_bridge`）の require 閉包からは独立に除外されていることを独立確認した。新 session 実行は finding 5 再確定どおり `step_executors.rb` の差し替え可能 LLM seam に集約され、これら旧パターン系には到達しない。だが Finding 1 同様、撤廃済み概念のコードが新スクラッチ層と同一 `execution_v2/` 名前空間に物理同居する。
- impact: session 実行正路は clean のため適合判定上は致命でない。撤廃済みパターン照合コードの同居は maintainability/traceability を弱め、`execution_v2/` 配下にあることで「v2 スクラッチ実装の一部」と誤認されうる。
- recommended action: session 実行に使われない旧パターン照合系ファイルを物理削除または `protocol_track` 専用と明示分離し、撤廃済み `review_mode_vocabulary`/`seed_patterns` 参照を解消。
- impact severity: P3（session 実行正路に非到達。同居による誤認・保守性低下）
- handback assessment: A（task-local。設計は撤廃済み。実装の cleanup 漏れ）
- status: open / disposition=`record-and-watch`

## 4. metric snapshot

- `conformance_findings_count`: 3（P1=0 / P2=0 / P3=3）
- `severity_weighted_finding_score`: 3（重み P1=3・P2=2・P3=1 で P1 0件×3 + P2 0件×2 + P3 3件×1 = 0+0+3 = 3）
- `post_smoke_nonconformance_count`: 0（smoke・全テスト pass。3 finding はいずれも live 実行正路に非到達の dead code/補助スクリプト残存であり、smoke 後の機能非適合ではない）
- `fixture_bound_resolution_count`: 0（新実装は path hard-code の旧資産依存を持たない。prompt は `layer1_framework.yaml` `asset_locations`＋frontmatter のみを入力）
- `heuristic_linkage_count`: 0（session 実行正路は撤廃済みパターン照合に依存しない。残存は dead code/補助スクリプトのみで実行 linkage はゼロ）
- `review_artifact_presence_rate`: 1.0（本証跡ファイルを新規作成）
- `finding_to_signal_link_rate`: 0.0（本レビュー時点で signal register への起票は未実施。disposition で追跡）

## 5. disposition summary

- immediate disposition:
  - `fix-in-current-branch`: Finding 1（旧 v1 実装ファイル物理削除）・Finding 2（bootstrap スクリプトの heuristic-profile 参照撤廃）
  - `record-and-watch`: Finding 3（`execution_v2/` 配下の旧パターン照合 dead code 隔離）
  - `fix-before-next-feature`: 該当なし
  - `reopen-design` / `reopen-requirements` / `reopen-intent`: 該当なし（新規 B/C/D handback なし）
- evidence linkage: 本証跡＝`.kiro/specs/dual-reviewer-runtime/reviews/implementation-conformance-review-2026-05-19.md`。新規 finding 3 件はすべて handback class A（task-local cleanup）であり reopen 連携は不要。
- next action:
  - 結論: 実行系スクラッチ再実装は **現行承認仕様（再確定設計を含む）へ構造適合**。前回 finding 11 件（A7/B4）は全件解消を独立確認した。新規 finding は 3 件、すべて P3・handback class A（撤廃済み旧 v1 ファイル/スクリプトの物理削除漏れであり、実行正路・適合判定には非到達の dead code/補助残存）。
  - 手戻り種別の総括: A=3件（task-local cleanup）/ B=0 / C=0 / D=0。基盤確定済み契約は正であり、要件・設計境界・上位 intent 側の不足は検出されなかった。
  - 推奨: **GO 可**。残 3 finding（P3/A）は本ブランチ内 cleanup で吸収（reopen 不要）。下流（evaluation/self-improvement/paper-interface）への handoff artifact は §4 Downstream Handoff どおり整備済みで前進可。Finding 1〜3 は次の小修正波で旧ファイル/参照を物理削除し、`tests/foundation/test_foundation_contracts.rb` の旧資産不在検証に旧実装ディレクトリを追加して再発防止を機械化することを推奨。

## 6. 前回 finding 11 件（手戻り A7/B4）の解消状況

前回証跡（2026-05-18）の 11 finding に対する本レビューの独立判定。

### B 群（設計差し戻し→再確定後の実装適合）

- 前回 finding 2（P1・B）prompt 解決の構造的付け替え：**解消**。`runtime/execution_v2/prompts/prompt_resolver.rb` は再確定設計どおり `layer1_framework.yaml` `asset_locations.prompts`＋各 prompt frontmatter（`prompt_id`/`version`/`role`/`step`/`language`/`source_ref`）を唯一入力とし、frontmatter キーは正しく `version`、resolution order 1=canonical／2=runtime 所有 override／3=ambiguous fail、Step D は role=nil（prompt 不要）。撤廃済み `prompts/shared/frontmatter_contract.yaml` 等は非参照。`test_prompt_resolver.rb` 7 runs pass。
- 前回 finding 5（P1・B）Step 実行の実 LLM 化・v2-acquisition 責務境界：**解消**。`runtime/execution_v2/analyzers/step_executors.rb` は差し替え可能 LLM seam（`MockSeam` 既定／DI で `FixedSeam` 注入）1 点に集約。runtime は role×step→prompt 解決と evidence emit のみ所有、取得方式は seam で吸収（前方依存なし）。session 実行正路は旧 `RuleMatchAnalyzer`/種パターンに到達しない（require 閉包で独立確認）。`test_step_executors.rb` 13 runs pass。
- 前回 finding 6（P1・B）validation 層の基盤新契約付け替え：**解消**。`runtime/execution_v2/validation/validation_bridge.rb` は `metadata_contract.yaml` `fields:` を正本入力に `required: true` を機械抽出（ハードコード必須リストなし）、`validator_status` は `canonical_ownership.validator_status`（not_run/passed/failed/blocked）参照で 4 値丸めなし伝播・enum 外明示拒否、`review_mode` は契約 enum 参照、runtime 再定義なし。旧 `contract_id`/`required_fields`/`review_mode_vocab` 非参照。`test_validation_bridge.rb` 16 runs pass。
- 前回 finding 9（P2・B）run close 順序保証：**解消**。`session_controller.rb` の `RunSession` が単一起動点 `invoke_validator` に集約、前提 3 条件（step_d_complete/human_signoff_written/raw_evidence_frozen）未充足・多重起動を `enforce_close_boundary_preconditions!` で検知し fail-closed（`orchestration_failed`）＋invalidation marker。順序 Step D→sign-off→freeze→validator→close を構造で強制、freeze marker artifact を observable に。`test_run_close_boundary_integration.rb` 9 runs pass（double invocation 禁止・前提未充足非到達・blocked/not_run 丸めなし伝播・fail-closed marker・post-close 順序を独立検証）。

### A 群（task-local 解消）

- 前回 finding 1（P1・A）run 開始即失敗：**解消**。`config.fetch("review_protocol")` 相当は存在せず、入力は kwarg 契約（`start_run`）。スモークで 3 treatment すべて run 開始成立（manifest 生成・`in_progress`）。
- 前回 finding 3（P1・A）controller↔executor 引数契約不一致：**解消**。`StepExecutors` は `run_step_a/b/c` の明示 kwarg API、`StepDIntegration#integrate` も kwarg。controller は lifecycle のみ所有し executor 呼び出しは driver が kwarg で接続（`runtime_session_driver` 経由）。`test_end_to_end_smoke.rb` 5 runs pass で 3 treatment 通し検証。
- 前回 finding 4（P1・A）prompt path/identity 不整合：**解消**。Step B は `asset_locations` 経由で `adversarial_review` を解決、Step D は role=nil で prompt 不要、frontmatter キーは `version`。基盤 prompt 配置（`runtime/prompts/{primary_detection,adversarial_review,judgment}/`）と整合。
- 前回 finding 7（P2・A）validator_status 丸め：**解消**。`validation_bridge`/`SessionController::VALIDATOR_STATUSES` ともに 4 値を丸めず、enum 外は `ArgumentError` で明示拒否。`blocked`/`not_run` の final metadata 伝播を `test_run_close_boundary_integration.rb` で確認。
- 前回 finding 8（P2・A）human_signoff 6 フィールド：**解消**。`RunSession#write_human_signoff` は design 正本 6 フィールド（`run_id`/`human_signoff_status`/`signed_off_by`/`signed_off_at`/`covered_decision_unit_ids`/`signoff_note`）を出力。`test_decision_units.rb` 16 runs pass。
- 前回 finding 10（P3・A）Step B `adversarial_outcome` 必須設定：**解消**。`step_executors.rb` `run_step_b` が各 assessment の `adversarial_outcome`∈{counter_evidence_raised, no_counter_evidence_after_challenge, not_assessed} を必須検証し未設定を `StepExecutionError`。
- 前回 finding 11（P3・A）testability seam 決定的検証ケース不在：**解消**。`test_testability_seams.rb` が 4 seam（言語モデル差し替え／検証ブリッジ起動点／ステップ入出力分離／Step D 機械統合）それぞれに固定入力→期待出力の決定的ケースを持ち、5 runs pass。集約宣言テストで 4 seam とメソッドの対応を機械確認。

### 総括

前回 11 finding（致命6/重要3/軽微2、A7/B4）は **全 11 件解消**（B 群 4 件は再確定設計どおり構造的に解消、A 群 7 件は task-local に解消）を独立に確認した。新規 finding は 3 件（すべて P3／handback A／旧 v1 dead code・補助スクリプトの物理削除漏れ）で、実行正路・適合判定には非到達。要件 1〜9・Task 1〜11 完了条件・§6 Completion Criteria・§4 Downstream Handoff・基盤契約適合（A-5/A-7/T5-A）はテストと独立点検で満たすことを確認した。

**判定: 現行承認仕様に構造適合（GO 可）。残 3 finding は本ブランチ内 task-local cleanup（reopen 不要）。**
