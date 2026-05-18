# implementation conformance review（再実装後・独立）

_実施日: 2026-05-19_
_レビュー種別: implementation conformance review（再実装後・独立適合レビュー。実装者とは別プロセス・別視点）_
_対象 feature: dual-reviewer-evaluation_
_reviewed commit: `ef5b6b694917ca482c13d7d62cf0b6303c2bf636`_
_review focus: dual-reviewer-evaluation のスクラッチ再実装が現行承認仕様（requirements 1〜10／design 495 行／tasks 1〜9・§6 Completion Criteria）へ構造適合し、直近スクラッチ再実装された runtime の新成果物契約（review_case foundation スキーマ／comparison_eligibility_note runtime 所有 6 項目／validator_status・evidence_class・review_mode・human_signoff_status 語彙／runtime_summary 非依存）を正しく consume し、前回 finding 10 件（致命4/重要5/軽微1、全件 handback A）が解消したかを独立確認する_
_正本: docs/coordination/implementation-conformance-review.md_

本証跡は生証跡として不変扱いとする。本レビューにおいてコード・spec・design・requirements・tasks・基盤資産は一切変更していない（点検と所見記録のみ）。検証スモークが生成した untracked derived output（`experiments/analysis/` 一時生成物・`experiments/analysis/imports/` register。HEAD 非追跡・raw/spec/コードでない再生成物）は点検後に除去し作業ツリーをレビュー前状態へ戻した。前回証跡（`implementation-conformance-review-2026-05-19.md`）および直近 runtime 再実装後証跡は鵜呑みにせず独立判断した。

なお reviewed commit `ef5b6b69` は旧 v1 評価実装時点を指す。本レビューが点検したスクラッチ再実装（`scripts/evaluation/*` の 2026-05-19 付ファイル群・`tests/evaluation/` 10 ファイル・runtime 実体出力形 fixture）は作業ツリー上に未コミットで存在する。post-rebuild レビューの性質上、点検対象は作業ツリーの再実装状態であり、reviewed commit はその基底点として記録する。

## 1. review scope

- review type: `implementation conformance review`（再実装後）
- reviewed branch: `claude/v2-acquisition-code-mod`
- reviewed commit: `ef5b6b694917ca482c13d7d62cf0b6303c2bf636`（再実装は本コミット基底の作業ツリー上に存在）
- reviewed feature: `dual-reviewer-evaluation`（基盤確定済み契約 `runtime/foundation/`・`runtime/schemas/`、runtime 確定済み契約 `runtime/execution_v2/contracts/comparison_eligibility_note.schema.json`・`runtime/execution_v2/contracts/treatment_matrix.rb`・runtime `ReviewCaseProjector`/`DecisionUnits` 投影規約を consumer 前提とし、乖離は評価側で評価）
- review focus:
  - requirements 1〜10 受入・design 構成要素・tasks 1〜9 完了条件・§6 Completion Criteria を再実装が漏れなく満たすか
  - 前回 finding 10 件の解消（review_case foundation `validation_refs`／`human_decision_ref` runtime 実体解決／決定的検証テスト／撤廃 review_mode 語彙非依存／設計スキップ弁別／version uniformity／staleness 伝播／review-mode 直交軸／analysis skeleton／eligibility note consume）
  - 評価が runtime 新契約どおり consume するか（fixture が実 runtime 出力形か含む）
  - raw 不変・analysis artifact 分離
  - 静的・スモーク・無回帰・end-to-end パイプライン
- 点検対象とした実装の所在:
  - `scripts/evaluation/` 18 ファイル（再実装本体 15 件は 2026-05-19 付。旧 v1 残存 3 件 `metric_writer.rb`/`classification_writer.rb`/`comparison_writer.rb` は 2026-05-13 付で未書き換え）
  - 評価エントリ：`scripts/{intake_local_run,intake_imported_bundle,admit_imported_bundle,classify_evaluation_input,extract_evaluation_metrics,build_evaluation_comparisons,build_evaluation_caveats,select_evaluation_run_set,rebuild_evaluation_analysis_from_runs,validate_evaluation_pipeline,write_analysis_manifest}.rb`（11 件）
  - テスト：`tests/evaluation/test_*.rb`（10 ファイル）、fixture `tests/fixtures/evaluation/`（実 runtime 出力形に再生成済み）

## 2. validation rerun

- rerun commands:
  - `ruby -c` 構文検査：`scripts/evaluation/` 全 18 ＋評価エントリ 11
  - `tests/evaluation/test_*.rb` 全 10 ファイル
  - `tests/runtime/test_*.rb` 全 15 ファイル（無回帰）
  - `tests/foundation/test_foundation_contracts.rb`（無回帰）
  - `tests/governance/test_req9_suite.rb`（無回帰）
  - `ruby scripts/validate_evaluation_pipeline.rb`
  - `ruby scripts/select_evaluation_run_set.rb --local-runs-root tests/fixtures/evaluation/local_runs`（標準母集団選定が実 runtime 形 fixture で 0 件化しないか）
  - `ruby scripts/rebuild_evaluation_analysis_from_runs.rb <valid> <invalid> <exploratory> <analysis_blocked>`（混在 population の end-to-end パイプライン）
  - `ruby scripts/{classify_evaluation_input,extract_evaluation_metrics,build_evaluation_comparisons,admit_imported_bundle}.rb` の最小起動（実 fixture 入力・クリーンツリー）
  - fixture 実体形の独立確認：全 review_case の `validation_refs` 存在 / `validation_artifacts` 不在 / `human_decision_ref` 値、runtime `DecisionUnits::HUMAN_DECISION_REF`・`ReviewCaseProjector::HUMAN_SIGNOFF_REF` 定数照合
  - `runtime_summary` 依存の評価スコープ全文検索
- result summary:
  - `ruby -c`：評価実装 18 ＋エントリ 11 全件 `Syntax OK`（FAIL ゼロ）
  - `tests/evaluation/`：10 ファイル全 PASS。合計 123 runs / 622 assertions / 0 failures / 0 errors / 0 skips。Task 9 が要求する 4 検証対象（classification・admission／metric 導出／比較可能性・valid population／staleness 伝播）の決定的ケースが `test_classification_model`／`test_metric_model`／`test_comparison_model`／`test_versioning_staleness_model`／`test_completion_criteria`／`test_pipeline_smoke` に存在し pass
  - `tests/runtime/`：15 ファイル全 clean（合計 165 runs / 0 failures / 0 errors。無回帰。評価点検が実行系を触っていない傍証）
  - `tests/foundation/test_foundation_contracts.rb`：8 runs / 107 assertions / 0 failures（無回帰）
  - `tests/governance/test_req9_suite.rb`：6 runs / 10 assertions / 0 failures（無回帰）
  - `validate_evaluation_pipeline.rb`：`evaluation pipeline validation passed`
  - `select_evaluation_run_set.rb`：実 runtime 形 fixture（review_mode=runtime_mediated）で `selected_run_count=3`（standard population が silent に空化しない＝前回 finding 4 解消の機能的傍証）
  - `rebuild_evaluation_analysis_from_runs.rb`（混在 4 population）：完走。`treatment_comparison_status=valid`・`total_excluded=3`・全 downstream artifact 生成（classification index は 4 状態を正しく分離、`in_standard_runtime_comparison_set` が valid/runtime_mediated のみ true）
  - エントリ最小起動：`classify_evaluation_input.rb`／`extract_evaluation_metrics.rb`／`build_evaluation_comparisons.rb` が **クリーンツリーで `Errno::ENOENT` クラッシュ**（Finding 1 参照。`rebuild_*` と全テストは skeleton を先行生成するため pass）。`admit_imported_bundle.rb` は両 bundle で完走
  - fixture 実体形：全 4 review_case が `validation_refs` 保持・`validation_artifacts` 不在・`human_decision_ref="decisions/human_signoff.json"`（`#` フラグメントなし、runtime `DecisionUnits::HUMAN_DECISION_REF`／`ReviewCaseProjector::HUMAN_SIGNOFF_REF` 定数と一致）。`comparison_eligibility_note.json` は runtime 所有 6 項目で生成
  - `runtime_summary` 依存：評価スコープに実依存ゼロ（コメント・ラベル文字列のみ。中心問い「runtime_summary 非依存」適合）

## 3. findings

### Finding 1 `P2`

- title: 旧 v1 残存 writer 3 件が `mkpath` を持たず、3 つの standalone 評価エントリがクリーンツリーで `Errno::ENOENT` クラッシュする（前回 finding 9 系統の残置非適合）
- 所在: `scripts/evaluation/metric_writer.rb:44`（`register_path.write` 直前に parent dir 生成なし）／`scripts/evaluation/classification_writer.rb:53`／`scripts/evaluation/comparison_writer.rb:40`（いずれも 2026-05-13 付・スクラッチ再実装で書き換えられていない旧 v1 ファイル）／エントリ `scripts/extract_evaluation_metrics.rb:21`・`scripts/classify_evaluation_input.rb`・`scripts/build_evaluation_comparisons.rb`／対照: 新規 writer `exclusion_report_writer.rb`・`caveat_writer.rb`・`import_register_writer.rb`・`analysis_manifest_writer.rb` は `mkpath`/`mkdir_p` を正しく持つ／`scripts/rebuild_evaluation_analysis_from_runs.rb:66`（`AnalysisLayout.create_skeleton` を先行呼び出しするため救済される）
- 現状: 再実装本体（loader/classification/metric/comparison/staleness 等 15 ファイル）は 2026-05-19 付で全面スクラッチされたが、`metric_writer.rb`／`classification_writer.rb`／`comparison_writer.rb` の 3 writer だけ 2026-05-13 付の旧 v1 のまま残置され、`write_register` が parent directory を作らずに `Pathname#write` する。`rebuild_*` オーケストレータと `tests/evaluation/`（テストは tmpdir に skeleton を先行作成）は `AnalysisLayout.create_skeleton` 経由で `experiments/analysis/{metrics,classifications}/` を先に作るため緑になる。一方、skeleton 未生成のクリーンツリーで standalone エントリ `extract_evaluation_metrics.rb`／`classify_evaluation_input.rb`／`build_evaluation_comparisons.rb` を起動すると `No such file or directory @ rb_sysopen - .../experiments/analysis/metrics/run_metrics.json (Errno::ENOENT)` 等で即クラッシュする。
- 問題: 前回 finding 9 の中心要件「writer mkpath で ENOENT 出さない／skeleton 配置の現存性・可説明性」が、orchestrator 経路では解消（`AnalysisLayout` 新設・冪等 skeleton 生成・`rebuild_*` 先行呼び出し）された一方、**旧 v1 writer を流用した standalone エントリ経路で残置**している。スクラッチ方針（旧 v1 を流用せず作り直す）が writer 3 件で徹底されず、これら旧ファイルが ENOENT を再導入。境界条件 §5.2（実行時生成依存・placeholder 的隠れ）。fixture/orchestrator では緑だが standalone 起動で破綻する隠れ非適合。
- 推奨対応: `metric_writer.rb`／`classification_writer.rb`／`comparison_writer.rb` の `write_register` に新規 writer と同様の parent dir `mkpath`/`mkdir_p` を加える（または 3 standalone エントリに `AnalysisLayout.create_skeleton` 先行呼び出しを加える）。新規 writer 4 件は既に対処済みなので、旧 v1 残存 3 件をスクラッチ方針へ追随させるのが整合的。
- handback class: A（task-local。design の正本配置・`AnalysisLayout` 契約は確定済みで十分、要件・設計境界は不変。旧 v1 writer 残置という評価実装側の追随漏れで、評価側修正のみで吸収可能）
- impact severity: P2（orchestrator/テストでは緑だが standalone エントリ起動で確実にクラッシュ。条件が変わると破綻する隠れ非適合。前回 finding 9 の系統的残置）
- status: open / disposition=`fix-before-next-feature`

## 4. metric snapshot

- `conformance_findings_count`: 1（P1=0 / P2=1 / P3=0）
- `severity_weighted_finding_score`: 2（重み P1=3・P2=2・P3=1：P2 1件×2 = 2）
- `post_smoke_nonconformance_count`: 1（Finding 1 は orchestrator/テスト pass の裏で standalone エントリ起動時にクラッシュする隠れ非適合）
- `fixture_bound_resolution_count`: 0（fixture が実 runtime 出力形へ再生成され、緑が hand-crafted 非 runtime 形に依存しない＝前回 finding 1/2 の fixture 仮装は解消）
- `heuristic_linkage_count`: 0（basename match 等の heuristic linkage なし）
- `review_artifact_presence_rate`: 1.0（本証跡ファイルを新規作成）
- `finding_to_signal_link_rate`: 0.0（本レビュー時点で signal register 起票は未実施。disposition で追跡）

## 5. disposition summary

- immediate disposition:
  - `fix-before-next-feature`: Finding 1（旧 v1 残存 writer 3 件の mkpath 欠落＝standalone エントリ ENOENT。前回 finding 9 系統の残置）
  - `fix-in-current-branch` / `record-and-watch`: 該当なし
  - `reopen-design` / `reopen-requirements` / `reopen-intent`: 該当なし（新規 B/C/D handback なし。要件・設計境界・上位 intent 側の不足は検出されず、乖離は評価実装側に限局）
- evidence linkage: 本証跡＝`.kiro/specs/dual-reviewer-evaluation/reviews/implementation-conformance-review-2026-05-19-postrebuild.md`。新規 finding 1 件は handback class A（task-local。旧 v1 writer 残置の追随漏れ）。reopen 連携は不要。
- next action:
  - 結論: dual-reviewer-evaluation のスクラッチ再実装は **現行承認仕様（requirements 1〜10／design／tasks 1〜9・§6 Completion Criteria）および runtime 新契約へ構造適合**。前回 finding 10 件（致命4/重要5/軽微1・全件 A）は **全 10 件解消を独立確認**（詳細は §6）。fixture は実 runtime 出力形へ再生成され、前回の「fixture 仮装による smoke 緑」構造は解消。Task 9 の決定的検証テスト（4 検証対象）が新設され pass。新規 finding は 1 件のみ（P2／handback A／前回 finding 9 系統の旧 v1 writer 残置による standalone エントリ ENOENT）。
  - 手戻り種別の総括: A=1件（task-local。確定済み foundation/runtime 契約は正、評価実装の旧 v1 残置追随漏れ）/ B=0 / C=0 / D=0。
  - 推奨: **GO 可（条件付き）**。設計差し戻し不要（B/C/D ゼロ。要件・設計は十分）。Finding 1 は本ブランチ内 task-local 修正（旧 v1 writer 3 件に mkpath 追加 or 3 エントリに skeleton 先行生成）で吸収可能（reopen 不要）。前回 GO 不可・スクラッチ再実装推奨は妥当な判断であり、再実装は前回 10 finding を構造的に解消した。残 1 finding はスクラッチ方針が writer 3 件で未徹底だった残置であり、次の小修正波で旧 v1 writer をスクラッチ方針へ追随させることを推奨。

## 6. 前回 finding 10 件の解消状況

前回証跡（`implementation-conformance-review-2026-05-19.md`、致命4/重要5/軽微1、全件 handback A）に対する本レビューの独立判定。

- 前回 Finding 1（P1・A）review_case を foundation `validation_refs` で読む：**解消**。`local_run_loader.rb:162-174` が `review_case["validation_refs"]`（`validator_result_ref`／`invalidation_marker_refs`）を読む。旧 `validation_artifacts` 命名非依存。全 4 fixture が `validation_refs` 保持・`validation_artifacts` 不在を独立確認。`runtime/schemas/review_case.schema.json` required 5 項目（`review_case_id`/`metadata`/`step_records`/`findings`/`validation_refs`）と整合。`test_intake_model.rb` 14 runs pass。
- 前回 Finding 2（P1・A）`human_decision_ref` を runtime 実体で解決・`#` 分解しない・捏造しない：**解消**。`metric_extractor.rb:177-231` が finding を `decision_unit_id` → `decisions/decision_units.json` の `decision_units[].human_decision` で解決し、`human_signoff.json` の `covered_decision_unit_ids` かつ `human_signoff_status` 終端のもののみ計上。`human_decision_ref`（`"decisions/human_signoff.json"`・`#` なし・run レベル pointer）を `split("#")` で分解しない。`TERMINAL_DECISIONS=approved/rejected/deferred` 外を `nil`（捏造しない）。fixture の `human_decision_ref` 値が runtime `DecisionUnits::HUMAN_DECISION_REF`／`ReviewCaseProjector::HUMAN_SIGNOFF_REF` 定数と一致を独立確認。`test_metric_model.rb` 17 runs pass。
- 前回 Finding 3（P1・A）決定的検証テスト存在（Task 9 完了条件）：**解消**。`tests/evaluation/` に 10 ファイル新設（123 runs / 622 assertions / 0 failures）。Task 9 の 4 検証対象（classification・admission／metric 導出／比較可能性・valid population／staleness 伝播）の固定入力→期待出力ケースが存在し pass。実 runtime 出力形 fixture を入力にする。
- 前回 Finding 4（P1・A）撤廃 review_mode 語彙非依存・実 runtime manifest で標準母集団 0 件化しない：**解消**。`classification_engine.rb:31-32` が canonical（`runtime_mediated`/`manual_dogfooding`）のみ。`select_evaluation_run_set.rb:38-46` が旧撤廃語彙（single_review 等）を canonical へ正規化し再定義しない。`population_selector.rb:60-71` が `validation_refs.validator_result_ref` で protocol-facing summary を判定（runtime_summary 非依存）。実 runtime 形 fixture で `selected_run_count=3`（silent 0 件化せず）を実証。
- 前回 Finding 5（P2・A）`execution_state`/`reason`/`treatment` で設計スキップ vs 障害欠損弁別：**解消**。`classification_engine.rb:263-317` が runtime 所有 `TreatmentMatrix`（Treatment×Step 正本・評価は再定義せず参照）を用い、`review_case.step_records` の `step_status` を観測印として、expected=executed の欠落を `failure_gap`、treatment 由来省略を `design_skip` に弁別。`test_classification_model.rb` 18 runs pass。
- 前回 Finding 6（P2・A）protocol/prompt version uniformity 比較可能性条件・混在検出：**解消**。`comparison_builder.rb:42-52,213-220` が `protocol_version`/`prompt_set_version`/`runtime_version`/`schema_set_version` の混在を per-run metadata 完備でも検出し `mixed_*_version` を `comparison_invalid_reason` に出して aggregate しない。`test_comparison_model.rb` 19 runs pass。
- 前回 Finding 7（P2・A）事後 invalidate→derived stale 化/再導出・foundation 無効化伝播起点・raw 非編集：**解消**。`staleness_propagator.rb` を新設。`manifest.input_run_set` に事後 invalidate run が含まれると `stale=true`／`rederivation_required=true`／`leave_unchanged=false`／`propagation_source`（既定 `foundation_invalidation_propagation`）／`raw_mutation=false`。`affected_derived_artifacts` は derived のみ（`experiments/runs/` 不参照）。`test_versioning_staleness_model.rb` 9 runs pass。
- 前回 Finding 8（P2・A）review-mode と run-validity 直交軸・所有規則：**解消**。`classification_engine.rb:218-261` が有効性分類と review-mode を直交化（review_mode を分類理由にしない）。manual_dogfooding を Phase-1 separate slice として `in_standard_runtime_comparison_set=false`、runtime_mediated valid のみ標準集団。`comparison_builder.rb:127-145` が `in_standard_runtime_comparison_set` を尊重し silent 混入防止。rebuild 実証でも分離を確認。
- 前回 Finding 9（P2・A）skeleton/配置・writer mkpath で ENOENT 出さない：**部分解消（残置 finding 1 として再起票）**。`AnalysisLayout`（`analysis_layout.rb`）を新設し正本配置を機械列挙、`create_skeleton` が冪等 mkpath＋`.gitkeep` 生成、`rebuild_*:66` が先行呼び出し。新規 writer 4 件は mkpath を持つ。**ただし**旧 v1 残存 writer 3 件（`metric_writer`/`classification_writer`/`comparison_writer`）に mkpath が無く、standalone エントリ 3 件がクリーンツリーで ENOENT クラッシュ（本レビュー Finding 1）。orchestrator 経路は解消、standalone 経路に系統的残置。なお `experiments/analysis/` 正本 skeleton は HEAD 未追跡のままで、現存性は実行時生成依存（`AnalysisLayout.create_skeleton`）で担保される設計に変更された。
- 前回 Finding 10（P3・A）comparison_eligibility_note を runtime 所有 6 項目で consume・再定義しない：**解消**。`local_run_loader.rb:56-60,178-185` が runtime 所有 6 項目（`run_id`/`eligible_for_standard_comparison`/`ineligibility_reason_codes`/`treatment`/`phase_profile`/`generated_at`）のみ依存し再定義しない。`comparison_builder.rb:103-120` が `eligible_for_standard_comparison=false` の不可理由を比較前に先に尊重し標準比較から除外（design §1）。fixture も 6 項目で生成。`runtime/execution_v2/contracts/comparison_eligibility_note.schema.json` required 6 項目と整合。

### 総括

前回 10 finding（致命4/重要5/軽微1、全件 handback A）に対し、**9 件は完全解消、1 件（前回 Finding 9）は orchestrator 経路で解消・standalone エントリ経路に系統的残置**を独立に確認した。fixture は実 runtime 出力形（`validation_refs`／`human_decision_ref="decisions/human_signoff.json"`／撤廃 `validation_artifacts` 不在／runtime 所有 6 項目 eligibility note）へ再生成され、前回の「fixture 仮装による smoke 緑」構造は解消。Task 9 の 4 検証対象決定的テストが新設され pass。新規 finding は 1 件（P2／handback A／旧 v1 残存 writer 3 件の mkpath 欠落＝前回 Finding 9 の standalone 経路残置）で、要件・設計境界・上位 intent 側の不足は検出されず、乖離は評価実装側に限局（B/C/D ゼロ）。`tests/runtime/`（15 ファイル clean）・`tests/foundation/`（0 failures）・`tests/governance/`（0 failures）は無回帰で、評価点検が実行系・基盤を触っていない傍証。

**判定: 現行承認仕様および runtime 新契約へ構造適合（GO 可・条件付き）。残 1 finding（P2/A・旧 v1 writer 残置の mkpath 欠落）は本ブランチ内 task-local 修正で吸収（設計差し戻し不要・reopen 不要）。スクラッチ再実装は前回 10 finding を構造的に解消しており妥当。**
