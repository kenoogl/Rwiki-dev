# implementation conformance review

_実施日: 2026-05-19_
_レビュー種別: implementation conformance review（独立適合レビュー。実装者とは別プロセス・別視点）_
_対象 feature: dual-reviewer-evaluation_
_reviewed commit: `ef5b6b694917ca482c13d7d62cf0b6303c2bf636`_
_review focus: 既存 evaluation 実装が現行承認仕様（requirements 1〜10／design 495 行／tasks 1〜9）へ適合し、かつ直近スクラッチ再実装された runtime の新成果物契約（review_case foundation スキーマ／comparison_eligibility_note runtime 所有 6 項目／validator_status 4 値・evidence_class・review_mode 語彙／runtime_summary 非依存）を正しく consume するかを独立確認する_
_正本: docs/coordination/implementation-conformance-review.md_

本証跡は生証跡として不変扱いとする。本レビューにおいてコード・spec・design・requirements・tasks・基盤資産は一切変更していない（点検と所見記録のみ）。検証スモークが生成した untracked derived output（`experiments/analysis/` 一時生成物。HEAD 非追跡・raw/spec/コードでない再生成物）は点検後に除去し作業ツリーをレビュー前状態へ戻した。前回 runtime 証跡（`dual-reviewer-runtime/.../implementation-conformance-review-2026-05-19.md`）は鵜呑みにせず独立判断した。

## 1. review scope

- review type: `implementation conformance review`
- reviewed branch: `claude/v2-acquisition-code-mod`
- reviewed commit: `ef5b6b694917ca482c13d7d62cf0b6303c2bf636`
- reviewed feature: `dual-reviewer-evaluation`（基盤確定済み契約 `runtime/foundation/`・`runtime/schemas/`、および runtime 確定済み契約 `runtime/execution_v2/contracts/comparison_eligibility_note.schema.json`・runtime `ReviewCaseProjector` 投影規約・`scripts/track_runs/contracts/` を consumer 前提とし、乖離は評価側で評価）
- review focus:
  - requirements 1〜10 受入・design 構成要素・tasks 1〜9 完了条件を既存実装が漏れなく満たすか
  - 評価が runtime 新契約どおり読むか（review_case foundation スキーマ前提／comparison_eligibility_note runtime 所有 6 項目／validator_status 4 値・evidence_class・review_mode 語彙の非再定義／runtime_summary 非依存）
  - 旧 runtime 契約・旧命名・撤廃済み資産への依存残存
  - 基盤契約適合（foundation schema/語彙の非再定義）
  - 静的・スモーク・無回帰
- 点検対象とした実装の所在:
  - `scripts/evaluation/{admission_evaluator,analysis_manifest_writer,caveat_builder,caveat_writer,classification_engine,classification_writer,comparison_builder,comparison_writer,import_register_writer,imported_bundle_loader,local_run_loader,metric_extractor,metric_writer}.rb`（13 ファイル・いずれも 2026-05-13 付）
  - 評価エントリ：`scripts/{intake_local_run,intake_imported_bundle,admit_imported_bundle,classify_evaluation_input,extract_evaluation_metrics,build_evaluation_comparisons,build_evaluation_caveats,select_evaluation_run_set,rebuild_evaluation_analysis_from_runs,validate_evaluation_pipeline}.rb`
  - テスト：`tests/evaluation/` は**不在**。fixtures は `tests/fixtures/evaluation/`（local_runs / imported_bundles / outputs）

## 2. validation rerun

- rerun commands:
  - `ruby -c` 構文検査：`scripts/evaluation/` 全 13 ファイル＋評価エントリ 10 ファイル
  - `ruby scripts/validate_evaluation_pipeline.rb`
  - `ruby scripts/rebuild_evaluation_analysis_from_runs.rb`（valid/invalid/exploratory fixture 3 件）
  - `ruby tests/foundation/test_foundation_contracts.rb`（無回帰確認）
  - `tests/runtime/test_*.rb` 15 ファイル（無回帰確認）
  - runtime 実体契約照合：`runtime/execution_v2/writers/review_case_projector.rb`・`runtime/execution_v2/decisions/decision_units.rb`・`runtime/schemas/review_case.schema.json`・`runtime/execution_v2/contracts/comparison_eligibility_note.schema.json` と評価読取コードの突き合わせ
  - `runtime_summary` 依存の repo 全文検索（評価スコープ）
- result summary:
  - `ruby -c`：評価実装 13＋エントリ 10 全件 `Syntax OK`（SYNTAX FAIL ゼロ）
  - `validate_evaluation_pipeline.rb`：`evaluation pipeline validation passed`（pass）。ただし入力 fixture が runtime 実体出力形と乖離（Finding 1/2 参照）し、適合の傍証にならない
  - `rebuild_evaluation_analysis_from_runs.rb`：3 fixture で完走（reconstructed 3 run・treatment_comparison_status=invalid）。同上の fixture 乖離により実 runtime 適合の保証なし
  - `tests/foundation/test_foundation_contracts.rb`：8 runs / 107 assertions / 0 failures（無回帰。評価点検で触っていない傍証）
  - `tests/runtime/`：15 ファイル全 clean（0 failures/0 errors。無回帰）
  - `runtime_summary` 依存：評価スコープに参照ゼロ（中心問い 2「runtime_summary 非依存」は**適合**）

## 3. findings

### Finding 1 `P1`

- title: 評価が読む `review_case.json` の validation 参照キーが runtime 実体投影規約と不一致（runtime 新契約 consume の構造的欠落）
- 所在: `scripts/evaluation/local_run_loader.rb`（review_case 取込）／`scripts/evaluation/metric_extractor.rb:9-11`／runtime 実体 `runtime/execution_v2/writers/review_case_projector.rb:68-72`／`runtime/schemas/review_case.schema.json:52-58`／fixture `tests/fixtures/evaluation/local_runs/*/review_case.json`
- 現状: runtime `ReviewCaseProjector#project` は foundation `review_case.schema.json` 準拠で `"validation_refs" => {"validator_result_ref", "invalidation_marker_refs"}` を出力する（A-5 投影規約・runtime 所有正本）。一方 evaluation fixture は `"validation_artifacts" => {"validator_result_refs", "invalidation_marker_refs"}` という旧命名（複数形・別キー）を持ち、評価コードはこの fixture 形でしか駆動検証されていない。`metric_extractor` は `review_case.fetch("findings")` 等は読むが `validation_refs` を読まず、`validator_result` を別ファイル `validation/validator_result.json` 直読に依存しており、review_case の foundation スキーマ前提読取（中心問い 2）が成立していない。
- 問題: 評価が「review_case を foundation スキーマ前提で読む」という runtime 新契約の中心要件を満たさない。実 runtime 出力（`validation_refs`）を入力した場合、評価は review_case 内 validation 参照を解決できない。fixture が非 runtime 形に手作りされているため smoke は緑だが、実 runtime 連携時に破綻する隠れ不適合（境界条件 §5.2 silent fixture 依存）。
- 推奨対応: 評価の review_case 取込・metric 抽出を runtime 実体投影規約（`validation_refs`／foundation `review_case.schema.json` required 5 項目）へ追随させ、fixture を runtime `ReviewCaseProjector` 出力形へ再生成する。
- handback class: A（task-local。runtime/foundation 契約は確定済み＝正。乖離は評価実装の追随漏れであり評価側修正で吸収可能。設計境界・要件は不変）
- impact severity: P1（runtime 新契約 consume の構造的不適合。smoke pass でも実連携で破綻）
- status: open / disposition=`fix-before-next-feature`

### Finding 2 `P1`

- title: finding→human decision label 解決ロジックが runtime 実体の `human_decision_ref` 形と不一致（fixture が runtime 出力形を仮装）
- 所在: `scripts/evaluation/metric_extractor.rb:71-79`／runtime 実体 `runtime/execution_v2/writers/review_case_projector.rb:50,133-136,173`（`HUMAN_SIGNOFF_REF = "decisions/human_signoff.json"`）／`runtime/execution_v2/decisions/decision_units.rb:44,157`（`HUMAN_DECISION_REF = "decisions/human_signoff.json"`）／fixture `tests/fixtures/evaluation/local_runs/minimal_runtime_run/review_case.json`（`human_decision_ref: "decisions/decision_units.json#decision-unit-fixture-001"`）
- 現状: runtime 実体は finding の `human_decision_ref` を定数 `"decisions/human_signoff.json"`（run レベル sign-off 正本・`#` フラグメントなし）として出力する。評価 `resolved_judgment_label` は `finding["human_decision_ref"].to_s.split("#", 2).last` で `#` 後の decision_unit_id を取り出し `decision_units` index を引いて `human_decision` を解決する設計。実 runtime 出力に対しては `#` が無く `split` 結果が `"decisions/human_signoff.json"` となり decision_unit_id として解決不能 → judgment label が全件 unresolved になる。fixture は runtime が出さない `decisions/decision_units.json#<id>` 形を手作りしておりこの欠陥を隠蔽している。加えて runtime の judgment ラベル正本は finding の `final_label`（`ReviewCaseProjector#override_fields`）または run レベル `human_signoff.json` 集約であり、評価が前提する「decision_units[*].human_decision を finding ごとに引く」経路は runtime 契約に存在しない。
- 問題: Requirement 3（metric extraction・受入 2/3：構造化証跡からの導出と derivation path 保持）が実 runtime 入力で成立しない。fixture 仮装により決定的検証が runtime 適合を保証していない（証跡性 §5.3・境界条件 §5.2）。
- 推奨対応: 評価の judgment/decision label 解決を runtime 実体（finding `final_label`／run レベル `decisions/human_signoff.json` 集約／`decision_unit_id` linkage）へ整合させ、fixture を runtime `ReviewCaseProjector`＋`DecisionUnits` 出力形へ再生成する。
- handback class: A（task-local。runtime 契約確定済み＝正。評価側の解決ロジック・fixture を runtime 実体へ追随で吸収可能）
- impact severity: P1（metric 中核の label 解決が実 runtime 入力で機能不全。fixture が緑を仮装）
- status: open / disposition=`fix-before-next-feature`

### Finding 3 `P1`

- title: 決定的評価検証テストが全面不在（Task 9 完了条件未達。fixture 駆動 smoke のみ）
- 所在: `tests/evaluation/`（不在）／`scripts/validate_evaluation_pipeline.rb`（assert ベース smoke 1 本のみ）／tasks.md Task 9 完了条件（列挙 4 検証対象に決定的ケース 1 つ以上 pass）
- 現状: tasks.md Task 9 は「classification・admission／metric 導出／比較可能性・valid population／staleness 伝播」の 4 検証対象それぞれに固定入力→期待出力の決定的検証ケースを 1 つ以上要求し、TDD 先行を完了条件とする。実体は `tests/evaluation/` ディレクトリが存在せず、`validate_evaluation_pipeline.rb` の assert スモーク 1 本のみ。staleness 伝播（Req 5.6／Task 8）の検証ケースは皆無。`tests/foundation/`・`tests/runtime/` は存在するが評価専用テストは無い。
- 問題: Task 9 完了条件未達。品質保証（design Completion Criteria・プロジェクト TDD 方針）の構造的欠落。Finding 1/2 の fixture 仮装が検出されなかった根因でもある（決定的・runtime 実体準拠の検証が無い）。
- 推奨対応: runtime 実体出力形 fixture を入力に、4 検証対象の決定的テストを `tests/evaluation/` に新設（TDD 先行）。
- handback class: A（task-local。テスト追加で吸収。設計・要件は不変）
- impact severity: P1（Task 9 完了条件直接未達。証跡性 §5.3 欠落）
- status: open / disposition=`fix-before-next-feature`

### Finding 4 `P1`

- title: `select_evaluation_run_set.rb` が撤廃済み review_mode 語彙に依存し、実 runtime manifest を標準母集団選定で 0 件にする
- 所在: `scripts/select_evaluation_run_set.rb:51-57,63,137`（`review_mode_rank`／`allowed_review_modes = ["single_review","dual_review","dual_reviewer_workflow"]`）／foundation canonical review_mode = `manual_dogfooding`/`runtime_mediated`／runtime 実体 manifest（`review_mode: runtime_mediated`）／design「Analysis Population Selection」
- 現状: 標準母集団選定スクリプトの既定許容 review_mode が `single_review`/`dual_review`/`dual_reviewer_workflow`（旧 v1 語彙）であり、`manifest["review_mode"]` 完全一致フィルタ（line 137）に通す。runtime 実体・基盤 canonical は `runtime_mediated`/`manual_dogfooding` であり、実 runtime 出力 manifest はこの既定フィルタに一致せず `selected_run_count=0`（silent に標準母集団が空）。同一リポジトリ内でも `admission_evaluator.rb` は正しく canonical（`runtime_mediated`/`manual_dogfooding`）を使い、評価内で review_mode 語彙が二重定義・不整合。
- 問題: 基盤契約適合（中心問い 4：foundation 語彙の非再定義）違反。design「Analysis Population Selection」（`run_status=closed` 等の selection policy）が実 runtime に対し silent fallback で空集合化（境界条件 §5.2 silent fallback／§5.3 provenance）。Requirement 9 受入 6（review-mode による standard population rule）の入口が機能しない。
- 推奨対応: `select_evaluation_run_set.rb` の review_mode 語彙を foundation canonical（`manual_dogfooding`/`runtime_mediated`）へ統一し、`admission_evaluator` と語彙を一元化する。
- handback class: A（task-local。foundation 語彙は確定済み＝正。評価スクリプトの追随漏れ。評価側修正で吸収可能）
- impact severity: P1（実 runtime 入力で標準母集団が silent に空。基盤語彙再定義違反）
- status: open / disposition=`fix-before-next-feature`

### Finding 5 `P2`

- title: 設計スキップ vs 障害欠損の弁別（`execution_state`）が評価に未実装（Req 2 受入 3・design §4 未充足）
- 所在: `scripts/evaluation/`（`execution_state`/`skipped`/`reduced`/step omission 参照ゼロ）／requirements.md Requirement 2 受入 3／design「Classification Model §4 設計スキップ vs 障害欠損の弁別」／tasks.md Task 3
- 現状: design §4 は runtime の step 実行印（`execution_state` = executed/skipped/reduced、`reason`、`treatment`、Treatment×Step 対応）を参照し設計スキップと障害欠損を弁別すること、設計上の意図的省略を母集団から障害扱いで誤排除しないことを要求する。評価スコープ（`scripts/evaluation/*`・`classify_evaluation_input` 等）に `execution_state`/skipped/reduced を扱うロジックが一切無い（参照は runtime 側 `backfill_runtime_validation_summaries.rb` 等のみ）。`classification_engine` は step 欠損を一律 `required_artifact_missing`→`analysis_blocked` に倒し、treatment 由来の意図的 step 省略を障害扱いで弁別しない。
- 問題: Requirement 2 受入 3／design §4／Task 3 完了条件（設計スキップ弁別）未充足。treatment 別比較で設計上 step を持たない run を誤って障害排除しうる（runtime 要件 2 受入 5 との整合崩れ）。
- 推奨対応: 評価 classification に runtime step 実行印（`execution_state`/`reason`/`treatment`＋Treatment×Step 対応）を参照する設計スキップ／障害欠損弁別を実装する。
- handback class: A（task-local。runtime が `execution_state` を出す契約は確定済み＝正。評価側の弁別実装漏れ。設計境界・要件は十分で実装追加で吸収可能）
- impact severity: P2（現 fixture では露呈しないが実 treatment 比較で母集団誤排除に至る）
- status: open / disposition=`fix-before-next-feature`

### Finding 6 `P2`

- title: protocol/prompt version uniformity の比較可能性条件（Req 2 受入 6）が comparison builder に未実装
- 所在: `scripts/evaluation/comparison_builder.rb`（version/uniform/protocol/prompt 参照ゼロ）／requirements.md Requirement 2 受入 6／design「Comparison Model §1」（"protocol/runtime/prompt/schema version が比較可能"）／tasks.md Task 5
- 現状: Requirement 2 受入 6 は per-run metadata が全て揃っていても protocol-version／prompt-version が混在する comparison set を検出・報告することを要求する。design §1 も比較前に "protocol/runtime/prompt/schema version が比較可能" の確認を要求。`comparison_builder.rb` は treatment と phase_profile でのみ group 化し、version 一様性検査・version 混在検出・`comparison_invalid_reason` への version 混在計上が一切無い。`comparison_eligibility_note` の不可理由尊重ロジックも `build` に存在しない（local_run_loader が optional 読込するだけで comparison で参照されない）。
- 問題: Requirement 2 受入 6（version uniformity 検出）・受入 5（mismatch 検出報告）・design §1 比較可能性条件未充足。version 混在 set を valid 比較として誤集約しうる（証跡性 §5.3）。
- 推奨対応: comparison builder に protocol/prompt/runtime/schema version 一様性検査と version 混在 `comparison_invalid_reason`、`comparison_eligibility_note`（runtime 所有 6 項目）尊重を実装する。
- handback class: A（task-local。要件・設計は version uniformity を明記済みで十分。実装追加で吸収可能）
- impact severity: P2（version 混在比較を誤って valid 集約しうる。現 fixture では未露呈）
- status: open / disposition=`fix-before-next-feature`

### Finding 7 `P2`

- title: 事後 invalidate → derived artifact stale 化／再導出（Req 5 受入 6・Task 8）が未実装
- 所在: `scripts/evaluation/`・`scripts/rebuild_evaluation_analysis_from_runs.rb`（stale/re-derive 参照ゼロ）／requirements.md Requirement 5 受入 6／design「Versioning Model」（"参照していた run が事後に invalidate された場合 stale フラグ付けまたは再導出"）／tasks.md Task 8 完了条件
- 現状: design Versioning Model と Task 8 完了条件は、参照 run が事後 invalidate された場合に当該 run を入力に含む derived artifact を stale フラグ化または再導出すること（foundation 無効化伝播義務を入力起点）を要求する。評価スコープに stale 判定・stale フラグ・再導出トリガのロジックが皆無。`analysis_manifest_writer.rb` は `analysis_logic_version`/`input_run_set`/version 群を記録するが、invalidation 伝播・staleness 追跡フィールドを持たない。`rebuild_*` は毎回全再生成するのみで「invalidate された run を含む既存 derived の stale 化」を扱わない。Task 9 が要求する staleness 伝播の決定的検証ケースも不在（Finding 3 と連動）。
- 問題: Requirement 5 受入 6・design Versioning Model・Task 8 完了条件未充足。invalidate された run の上に古い derived output が silent 据え置きされうる（証跡性 §5.3・foundation 無効化伝播義務の入力起点未接続）。
- 推奨対応: derived artifact に入力 run set と invalidation 伝播リンクを持たせ、事後 invalidate 検知時の stale フラグ／再導出を実装、Task 9 に staleness 決定的検証を追加する。
- handback class: A（task-local。foundation 無効化伝播義務・要件 5 受入 6 は確定済みで十分。評価側の伝播実装漏れ）
- impact severity: P2（事後 invalidate 時に古い derived が stale 化されず据え置き。長期 provenance を弱める）
- status: open / disposition=`fix-before-next-feature`

### Finding 8 `P2`

- title: review-mode と run-validity の直交軸扱い・manual dogfooding の標準母集団 Phase-1 除外規則（Req 1 受入 6／Req 9 受入 2・4・5・6）が local run classification に未所有
- 所在: `scripts/evaluation/classification_engine.rb`（local run 経路に review_mode 参照ゼロ）／requirements.md Requirement 1 受入 6・Requirement 9 受入 2/4/5/6／design「Classification Model §2 末尾」「直交独立軸」／tasks.md Task 3
- 現状: design は有効性分類（valid/invalid/exploratory）と review-mode（manual_dogfooding/runtime_mediated）を直交独立軸とし、review-mode による標準集団切り分けを分類とは別の slice 操作として評価が所有することを要求（Req 9 受入 6：manual dogfooding は Phase 1 evidence、明示 separate slice でない限り standard runtime-mediated comparison set から除外）。`classification_engine#classify_local_run`／`classify_from_metadata` は validator_status/evidence_class/invalidation のみで分類し、`review_mode` を読まず、manual_dogfooding の標準母集団除外規則・mixed review-mode の保持・直交 slice を所有しない（imported bundle の `admission_evaluator` のみ部分対応）。`comparison_builder` も review-mode slice・mixed mode 注記を持たない。
- 問題: Requirement 1 受入 6（直交軸・manual dogfooding を review-mode 理由で invalid 誤分類しない／その逆の標準母集団混入防止）・Requirement 9 受入 2/4/5/6・Task 3 完了条件（直交軸扱い）未充足。local run の manual dogfooding が標準 runtime-mediated 比較に silent 混入しうる。
- 推奨対応: classification を review-mode 直交化し、manual dogfooding の Phase-1 標準母集団除外規則と mixed review-mode 保持を評価が所有、comparison に review-mode slice を実装する。
- handback class: A（task-local。要件 9・design は規則を明文化済みで十分。評価側の所有実装漏れ）
- impact severity: P2（manual dogfooding が標準比較に silent 混入しうる。現 fixture 全 runtime_mediated で未露呈）
- status: open / disposition=`fix-before-next-feature`

### Finding 9 `P2`

- title: `experiments/analysis/` 正本 skeleton が HEAD に不在（Task 1 完了条件の現存性が確認不能・アーカイブ退避）
- 所在: `git ls-files experiments/`（`experiments/analysis/` 配下に追跡ファイルなし。`experiments/_archived-analysis-2026-05-13/analysis/...` にのみ存在）／tasks.md Task 1 完了条件（derived output が `experiments/analysis/` に分離）／design「Analysis Artifact Layout」
- 現状: design「Analysis Artifact Layout」と Task 1 は `experiments/analysis/{imports,manifests,classifications,metrics,comparisons,caveats}/` を正本出力先 skeleton として固定する。HEAD には `experiments/analysis/` の追跡 skeleton（`.gitkeep` 含む）が無く、相当物は `experiments/_archived-analysis-2026-05-13/analysis/` にアーカイブ退避されている。`rebuild_*`/writers は実行時に `FileUtils.mkdir_p` で生成する設計のため smoke は通るが、Task 1 完了条件「raw run と analysis artifact の境界を（固定された正本配置として）説明できる／分離されている」の現存証跡が repo に無い。
- 問題: Task 1 完了条件の現存性が確認不能（実行時生成依存）。design 正本配置と repo 実態の乖離。境界条件 §5.2（placeholder/実行時生成依存の隠れ）。
- 推奨対応: `experiments/analysis/` 正本 skeleton（`.gitkeep`）を repo に復元するか、Task 1 を「実行時生成で skeleton を満たす」と明記し整合させる（後者なら設計記述側調整＝B 寄りだが、現状は実装/配置の追随漏れと判断し A）。
- handback class: A（task-local。設計の正本配置は確定済み。skeleton 復元または配置追随で吸収可能。判定迷いは保守規律で上流寄せだが、設計記述は配置を明示済みで欠落は実装/repo 側のため A 据え置き）
- impact severity: P2（Task 1 完了条件の現存証跡欠落。実行時生成で機能はするが provenance/可説明性を弱める）
- status: open / disposition=`fix-in-current-branch`

### Finding 10 `P3`

- title: `comparison_eligibility_note.json` の fixture と消費経路が不在（runtime 所有 6 項目契約の consume 未検証）
- 所在: `tests/fixtures/evaluation/`（`comparison_eligibility_note.json` 不在）／`scripts/evaluation/local_run_loader.rb:20`（optional 読込のみ）／`scripts/evaluation/comparison_builder.rb`（eligibility note 不参照）／runtime 所有 `runtime/execution_v2/contracts/comparison_eligibility_note.schema.json`（required 6 項目）／design「Classification Model §2 末尾」「Comparison Model §1」
- 現状: 評価は `comparison_eligibility_note.json` を `local_run_loader` の OPTIONAL_ARTIFACTS として読み込むだけで、classification 前の補助判断にも comparison の不可理由尊重にも実際には使用していない（`classification_engine`・`comparison_builder` とも当該キー不参照）。fixture も全く存在せず、runtime 所有 6 項目（`run_id`/`eligible_for_standard_comparison`/`ineligibility_reason_codes`/`treatment`/`phase_profile`/`generated_at`）を最小項目依存で正しく読むことが一度も検証されていない。再定義はしていない（適合方向）が、consume が事実上未接続。
- 問題: 中心問い 2（comparison_eligibility_note を runtime 所有スキーマ 6 項目で読む）が「再定義なし」は満たすが「実際に consume する」は未達。design「§2 末尾／Comparison §1（不可理由を先に尊重）」未接続。
- 推奨対応: runtime 6 項目に依存した eligibility note 読取を classification 補助・comparison 不可理由尊重に接続し、fixture を追加して決定的検証する（Finding 6 と併せて解消可）。
- handback class: A（task-local。runtime 所有スキーマ確定済み＝正。評価側 consume 接続漏れ）
- impact severity: P3（再定義違反ではないが contract consume 未接続・未検証）
- status: open / disposition=`fix-in-current-branch`

## 4. metric snapshot

- `conformance_findings_count`: 10（P1=4 / P2=5 / P3=1）
- `severity_weighted_finding_score`: 23（重み P1=3・P2=2・P3=1：P1 4件×3 + P2 5件×2 + P3 1件×1 = 12+10+1 = 23）
- `post_smoke_nonconformance_count`: 4（Finding 1/2/4 は smoke pass の裏で実 runtime 入力時に破綻する隠れ非適合、Finding 3 は検証不在自体。fixture 仮装により smoke が適合を保証していない）
- `fixture_bound_resolution_count`: 2（Finding 1/2：fixture が runtime 実体出力形と乖離し、評価の正当性が hand-crafted fixture に依存）
- `heuristic_linkage_count`: 0（basename match 等の heuristic linkage は検出されず）
- `review_artifact_presence_rate`: 1.0（本証跡ファイルを新規作成）
- `finding_to_signal_link_rate`: 0.0（本レビュー時点で signal register への起票は未実施。disposition で追跡）

## 5. disposition summary

- immediate disposition:
  - `fix-before-next-feature`: Finding 1・2（runtime review_case 投影規約／human_decision_ref 解決の不一致）・Finding 3（決定的テスト全面不在）・Finding 4（撤廃済み review_mode 語彙）・Finding 5（設計スキップ弁別未実装）・Finding 6（version uniformity 未実装）・Finding 7（staleness 伝播未実装）・Finding 8（review-mode 直交軸／Phase-1 除外未所有）
  - `fix-in-current-branch`: Finding 9（analysis skeleton 不在）・Finding 10（eligibility note consume 未接続）
  - `reopen-design` / `reopen-requirements` / `reopen-intent`: 該当なし（新規 B/C/D handback なし。要件・設計境界・上位 intent 側の不足は検出されず、乖離は全て評価実装側）
- evidence linkage: 本証跡＝`.kiro/specs/dual-reviewer-evaluation/reviews/implementation-conformance-review-2026-05-19.md`。finding 10 件はすべて handback class A（task-local。runtime/foundation 確定契約は正であり、評価実装の追随・実装漏れ）。reopen 連携は不要。
- next action:
  - 結論: 既存 evaluation 実装は **現行承認仕様（requirements 1〜10／design／tasks 1〜9）および runtime 新契約へ未適合**。実装作業日（2026-05-13）が仕様再承認・runtime スクラッチ再実装より前であり、現行契約への適合は保証されないという前提どおりの結果。runtime_summary 非依存（中心問い 2 の一部）のみ適合。review_case foundation スキーマ前提読取・human_decision_ref 解決・comparison_eligibility_note consume・review_mode 語彙・設計スキップ弁別・version uniformity・staleness 伝播・review-mode 直交軸が未達。
  - 手戻り種別の総括: A=10件（task-local。runtime/foundation 確定契約＝正に対する評価側追随／実装漏れ）/ B=0 / C=0 / D=0。設計・要件・上位 intent は version uniformity・直交軸・設計スキップ弁別・staleness を明文化済みで十分であり、不足は評価実装側に限局。
  - 推奨: **要手戻り（GO 不可）**。**設計差し戻し不要**（B/C/D ゼロ。要件・設計は十分）。**スクラッチ再実装が妥当**：実装が現行承認仕様・runtime 新契約より前の旧前提で書かれ、fixture が runtime 実体出力形を仮装して smoke 緑を作る構造（Finding 1/2/3/4）であり、部分修正より基盤・実行系と同様にスクラッチ再実装＋runtime 実体出力形 fixture での TDD 先行が確実。最低限、(a) review_case を runtime `ReviewCaseProjector` 出力形（foundation `review_case.schema.json` 準拠・`validation_refs`）で読む、(b) human_decision/judgment label 解決を runtime 実体（`final_label`／`decisions/human_signoff.json` 集約）へ整合、(c) review_mode 語彙を foundation canonical（`manual_dogfooding`/`runtime_mediated`）へ統一、(d) 設計スキップ弁別・version uniformity・staleness 伝播・review-mode 直交軸を実装、(e) runtime 実体出力形 fixture で 4 検証対象の決定的テストを TDD 先行で新設。`tests/foundation/`（8 runs/0 failures）・`tests/runtime/`（15 ファイル clean）は無回帰で、評価点検が基盤・実行系を触っていないことの傍証。

## 6. 検証コマンド結果（要点）

- `ruby -c`：評価実装 13＋エントリ 10、全件 `Syntax OK`（FAIL ゼロ）
- `validate_evaluation_pipeline.rb`：`evaluation pipeline validation passed`（pass。ただし fixture が runtime 実体形と乖離し適合の傍証にならない＝Finding 1/2）
- `rebuild_evaluation_analysis_from_runs.rb`（fixture 3 件）：完走・reconstructed 3 run・treatment_comparison_status=invalid（同上の fixture 乖離により実 runtime 適合保証なし）
- `tests/foundation/test_foundation_contracts.rb`：8 runs / 107 assertions / 0 failures（無回帰）
- `tests/runtime/test_*.rb`：15 ファイル全 clean（0 failures / 0 errors。無回帰）
- 評価専用決定的テスト：`tests/evaluation/` **不在**（Finding 3）
- `runtime_summary` 依存：評価スコープに参照ゼロ（中心問い 2「runtime_summary 非依存」適合）

**判定: 現行承認仕様および runtime 新契約に未適合（GO 不可・要手戻り）。手戻り種別は全件 A（評価実装側）。設計差し戻し不要、評価フィーチャーのスクラッチ再実装＋runtime 実体出力形 fixture での TDD 先行を推奨。**
