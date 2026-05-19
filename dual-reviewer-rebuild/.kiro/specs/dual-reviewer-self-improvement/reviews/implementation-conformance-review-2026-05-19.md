# implementation conformance review（独立）

_実施日: 2026-05-19_
_レビュー種別: implementation conformance review（独立適合レビュー。実装者とは別プロセス・別視点）_
_対象 feature: dual-reviewer-self-improvement_
_reviewed commit: `9b586932a3a4ee112eeacd5b6a08362a8febe73b`_
_review focus: 既存の self-improvement 実装が現行承認仕様（requirements 1〜8／design 526 行／tasks 1〜9・§6 Completion Criteria）へ構造適合し、直近スクラッチ再実装された evaluation／runtime の新成果物契約（AnalysisLayout 正本配置・実 runtime 出力 shape・撤廃語彙非依存・`derived/runtime_summary.json` 非依存）を正しく consume するかを独立検証する_
_正本: docs/coordination/implementation-conformance-review.md / docs/reviews/templates/implementation-conformance-review-template.md_

本証跡は生証跡として不変扱いとする。本レビューにおいてコード・spec・design・requirements・tasks・基盤資産は一切変更していない（点検と所見記録のみ）。検証スモークが生成・改変した `learning/` 配下の derived output（tracked artifact の改変・untracked 生成物。HEAD 非追跡 or 再生成物であり raw/spec/コードでない）は点検後に `git checkout -- learning/` + `git clean -fdq learning/` で除去し作業ツリーをレビュー前状態へ戻した。`experiments/` は汚していない（一時 repo コピーへ rebuild した）。前回 evaluation／runtime の再実装後証跡は鵜呑みにせず独立判断した。

self-improvement の実装本体・エントリは全ファイルが 2026-05-13 付であり、現行承認仕様の再承認（spec.json: requirements/design/tasks alignment completed = 2026-05-16〜2026-05-18）および evaluation／runtime のスクラッチ再実装（2026-05-19）より前である。したがって現行承認仕様および evaluation／runtime 新契約への適合は保証されない前提で独立検証した。

## 1. review scope

- review type: `implementation conformance review`
- reviewed branch: `claude/v2-acquisition-code-mod`
- reviewed commit: `9b586932a3a4ee112eeacd5b6a08362a8febe73b`
- reviewed feature: `dual-reviewer-self-improvement`（基盤確定済み契約 `runtime/foundation/`・`runtime/schemas/`、runtime スクラッチ再実装確定契約、evaluation スクラッチ再実装確定契約 `scripts/evaluation/{local_run_loader,classification_engine,analysis_layout}.rb` を consumer 前提とし、乖離は self-improvement 側で評価）
- review focus:
  - requirements 1〜8 受入・design 構成要素・tasks 1〜9 完了条件・§6 Completion Criteria を既存実装が漏れなく満たすか
  - self-improvement が evaluation／runtime 新契約どおり consume するか（AnalysisLayout 正本配置・実 runtime 出力 shape・`invalid_run_triage_note`／`failure_observation`・撤廃語彙非依存・`runtime_summary` 非依存）
  - 決定的検証テスト（Task 9）の有無
  - raw 不変・静的・スモーク・無回帰
- 点検対象とした実装の所在:
  - `scripts/self_improvement/` 15 ファイル（全件 2026-05-13 付・旧 v1。スクラッチ再実装されていない）
  - self-improvement エントリ：`scripts/{build_self_improvement_signal_inventory,build_self_improvement_pattern_candidates,build_self_improvement_proposals,build_self_improvement_backtests,build_self_improvement_remediation_templates,intake_self_improvement_signals,prepare_self_improvement_replay_inputs,record_self_improvement_decision,record_self_improvement_rollback,validate_self_improvement_pipeline}.rb`（10 件・全件 2026-05-13 付）
  - テスト：`tests/self_improvement/` は**不在**。`tests/fixtures/self_improvement/` は proposals/rollback fixture のみ（runner なし）

## 2. validation rerun

- rerun commands:
  - `ruby -c` 構文検査：`scripts/self_improvement/` 全 15 ＋ self-improvement エントリ 10
  - `ruby scripts/validate_self_improvement_pipeline.rb`（自己改善 end-to-end smoke）
  - 一時 repo コピーへ `ruby scripts/rebuild_evaluation_analysis_from_runs.rb`（現行 evaluation 再実装）で `experiments/analysis/` を実 fixture から再生成し、`SignalIntake#load_evaluation_signals` の consume を独立確認
  - `SignalIntake#load_runtime_signals` を全 evaluation fixture（`tests/fixtures/evaluation/local_runs/*`）と `experiments/runs/*` に対し実行し抽出 signal を独立確認
  - 現行 `LocalRunLoader` の REQUIRED/OPTIONAL_ARTIFACTS と signal_intake の `artifacts[...]` 参照キーの突合
  - 撤廃語彙・`runtime_summary` 依存の self-improvement スコープ全文検索
  - エントリ最小起動：`build_self_improvement_{signal_inventory,proposals,backtests}.rb`
  - 無回帰：`tests/runtime/test_*.rb` 全 15 ／`tests/evaluation/test_*.rb` 全 10 ／`tests/foundation/test_foundation_contracts.rb` ／`tests/governance/test_req9_suite.rb`
- result summary:
  - `ruby -c`：self-improvement 実装 15 ＋エントリ 10 全件 `Syntax OK`（SYNTAX FAIL ゼロ）
  - `validate_self_improvement_pipeline.rb`：**FAIL**。`scripts/validate_self_improvement_pipeline.rb:22:in 'assert': missing review quality signal (RuntimeError)`（line 52 の `review_quality_signal` 存在 assertion が現行 evaluation/runtime fixture corpus で不成立。Finding 1）
  - evaluation rebuild→consume：一時 repo で現行 evaluation 再実装が `experiments/analysis/` を正常生成（rc=0、`treatment_comparison_status=valid`・`total_excluded=3`）。AnalysisLayout 正本配置（`classifications/run_classification_index.json`・`metrics/run_metrics.json`・`metrics/finding_metrics.json`・`caveats/caveat_register.json`）と signal_intake 参照パスは一致。だが `SignalIntake#load_evaluation_signals` の抽出は `evidence_quality_signal` 3 件のみ（`analysis_blocked_population_member`／`unresolved_judgment_labels`／`exploratory_population_member`）。`review_quality_signal`（`rejected_finding_cluster`／`deferred_finding_cluster`）はゼロ（現行 fixture の `run_metrics` 全 entry が `rejected_findings=0`／`deferred_findings=0`）
  - runtime signal 抽出：`valid_runtime_run`=signals 0（全 `human_decision="approved"` のため `human_decision_mix` 不発）／`invalid_runtime_run`=`validator_failed`+`invalidation_marker_issued`／`exploratory_runtime_run`=`exploratory_evidence_mode`／`analysis_blocked_run`=`analysis_precondition_gap`／`experiments/runs/*`=signals 0。`review_quality_signal` は runtime 経路でも全 fixture で不発
  - loader 契約突合：現行 `LocalRunLoader` の REQUIRED_ARTIFACTS/OPTIONAL_ARTIFACTS に `invalid_run_triage_note`（`derived/invalid_run_triage_note.json`）と `failure_observation`（`failures/failure_observation.json`）が**不在**。signal_intake は `artifacts["invalid_run_triage_note"]`（58・94-129 行）を参照するが、loader 経由では恒常 `nil`。`failure_observation` は signal_intake で未参照
  - triage note shape：現行 runtime fixture の `invalid_run_triage_note.json` キーは `failed_validator_check_ids`／`invalidation_marker_linkage`。signal_intake は旧 `failed_checks[].check_id`／`invalidation_marker_summary[].linked_check_ids` を期待（旧 v1 shape）
  - 撤廃語彙：self-improvement スコープに `single_review`／`heuristic_profile`／`seed_pattern`／`review_mode_vocab`／`validation_artifacts`／`runtime_summary` の依存ゼロ（中心問い「撤廃語彙・`runtime_summary` 非依存」適合）
  - `human_decision_ref` `#` 分解：signal_intake は `decision_units[].human_decision` を直接読み、runtime 所有 `human_decision_ref="decisions/human_signoff.json"` を `split("#")` しない（適合）
  - エントリ最小起動：3 エントリとも完走（exit 0・artifact 書き出し成功）。ただし**実 repo の tracked `learning/` artifact を改変・untracked 生成**（点検後に復元）。旧コミット済み proposal（`proposal-prompt-human-decision-mix-run-exploratory-001` 等）が削除され別 proposal 集合へ置換 → consume-contract drift の機能的傍証
  - 無回帰：`tests/runtime/`（15 ファイル・0 failures）・`tests/evaluation/`（10 ファイル・0 failures）・`tests/foundation/`（8 runs / 0 failures）・`tests/governance/`（6 runs / 0 failures）。self-improvement 点検が実行系・評価・基盤・統治を触っていない傍証
  - 決定的検証テスト：`tests/self_improvement/` 不在。Task 9 が要求する 4 検証対象（状態機械許可/不許可遷移／provenance 欠落時 proposal 阻止／test mode 3 要素分岐＋result_label 整合／adoption gate 3 条件＋invalidation 起点 rollback）の固定入力→期待出力決定的ケースは**存在しない**

## 3. findings

### Finding 1 `P1`

- title: self-improvement smoke validator が現行 evaluation／runtime fixture corpus で構造的に FAIL する（`review_quality_signal` 不成立）
- file: `scripts/validate_self_improvement_pipeline.rb:52`／`scripts/self_improvement/signal_intake.rb:211-244`／`scripts/self_improvement/signal_class_classifier.rb:7-11`／入力 `tests/fixtures/evaluation/local_runs/*`・`experiments/analysis/`（再生成）
- references: tasks §6 Completion Criteria／design「Signal Extraction Model §2」（evaluation 由来 `rejected_finding_cluster`/`deferred_finding_cluster`）／implementation-conformance-review.md §10 completion rule（relevant smoke validator pass）
- description: `validate_self_improvement_pipeline.rb:52` は `all_signals.any? { signal_class == "review_quality_signal" }` を必須 assertion とする。`review_quality_signal` は signal_class_classifier 上 `human_decision_mix`／`rejected_finding_cluster`／`deferred_finding_cluster` のみ。これらは (a) runtime decision_units に rejected/deferred があるか、(b) evaluation `run_metrics` に `rejected_findings>0`/`deferred_findings>0` がある場合のみ発火する。現行 evaluation 再実装の fixture corpus は valid run の decision を全 `approved`、`run_metrics` 全 entry を `rejected_findings=0`/`deferred_findings=0` とするため、runtime 経路・evaluation 経路のどちらからも `review_quality_signal` が一切産出されない。結果、smoke が即 FAIL（`missing review quality signal`）。evaluation/runtime のスクラッチ再実装で fixture corpus が「異議系 decision/finding を含まない」shape に確定したのに対し、self-improvement smoke が旧 fixture corpus（異議系を含む）を前提に書かれた assertion を維持しているため。
- impact: relevant smoke validator が pass しない（completion rule 第 2 項不成立）。self-improvement の中心経路（signal intake → classification → proposal）が、現行確定 evaluation/runtime 契約の標準 fixture では review-quality 改善信号を 1 件も抽出できないことを示す。adopted change のない learning layer であっても、現行契約下で `review_quality_signal` を産出する経路が機能的に存在しないのは仕様（design Signal Extraction Model §2、Input Model §2 valid runs=review quality 改善一次入力）との乖離。
- recommended action: self-improvement 側で (a) evaluation 再実装後の `run_metrics`/decision_units 実 shape を前提に smoke fixture/期待値を再構築する、または (b) `review_quality_signal` 抽出経路（特に valid run からの review-quality 信号定義）を現行 evaluation/runtime 出力 shape に合わせ再設計する。evaluation/runtime 確定契約は正のため修正は self-improvement 側。
- handback assessment: A（task-local。evaluation/runtime の AnalysisLayout・出力 shape・語彙は確定済みで十分。乖離は self-improvement 実装が旧 fixture corpus 前提のまま再実装されていない追随漏れ。requirements/design 境界は不変で self-improvement 側修正のみで吸収可能）
- impact severity: P1（relevant smoke validator が確実に FAIL。中心経路の review-quality 信号抽出が現行確定契約下で機能しない）
- status: open / disposition=`fix-before-next-feature`

### Finding 2 `P1`

- title: signal_intake が `invalid_run_triage_note` を現行 evaluation LocalRunLoader 経由で取得できず、workflow signal の triage enrichment が恒常欠落する
- file: `scripts/self_improvement/signal_intake.rb:58,94-129,324-340`／`scripts/evaluation/local_run_loader.rb:27-43`（REQUIRED/OPTIONAL_ARTIFACTS に `invalid_run_triage_note` なし）
- references: 本レビュー中心問い 2（runtime の `derived/invalid_run_triage_note.json` を現行 shape で読むか）／self-improvement design「Replay and Backtest Model §2 Replay Inputs」（validator / invalidation artifacts）／`validate_self_improvement_pipeline.rb:67`（`source_evidence_refs` に `derived/invalid_run_triage_note.json` を含む assertion）
- description: signal_intake は runtime signal を `local_run_loader.load_run(run_root:)` の `run_intake["artifacts"]` から取り、`artifacts["invalid_run_triage_note"]`（58 行）で triage note を読んで `validator_failed`/`invalidation_marker_issued` signal を enrich する（`primary_failure_code`／`failed_check_ids`／`operator_action_hint`／`derived/invalid_run_triage_note.json#...` source ref）。しかし現行 evaluation 再実装の `LocalRunLoader` の REQUIRED_ARTIFACTS / OPTIONAL_ARTIFACTS に `derived/invalid_run_triage_note.json` は含まれない（loader 設計上 `runtime_summary` 同様 convenience artifact を載せない方針）。よって `artifacts["invalid_run_triage_note"]` は loader 経由で恒常 `nil`。triage enrichment 全項目が silent に欠落し、`validate_self_improvement_pipeline.rb:67` の `derived/invalid_run_triage_note.json` 伝播 assertion も不成立。加えて triage note を仮に取得できても、現行 runtime fixture の triage note キーは `failed_validator_check_ids`／`invalidation_marker_linkage` であり、signal_intake が期待する旧 v1 shape（`failed_checks[].check_id`／`invalidation_marker_summary[].linked_check_ids`）と不一致（二重の shape drift）。
- impact: invalid-run workflow 学習（design Input Model §2 invalid runs=workflow/validation 防止一次入力、Requirement 1 受入 2 review-quality vs workflow-failure 弁別）の中核 enrichment が現行契約下で silent に消える。境界条件 §5.2（silent fallback／実行時生成依存）。fixture/orchestrator では assertion 不成立として顕在化するが、enrichment 欠落自体は例外を出さず静かに劣化する隠れ非適合。
- recommended action: self-improvement が `invalid_run_triage_note`（および design Replay Inputs が要求する `failures/failure_observation.json`）を、evaluation LocalRunLoader を介さず runtime の正本配置（`derived/invalid_run_triage_note.json`／`failures/failure_observation.json`）から直接 manifest-based に解決する。併せて triage note の参照キーを現行 runtime fixture shape（`failed_validator_check_ids`／`invalidation_marker_linkage`）へ追随させる。evaluation loader の正本入力境界は確定済みのため修正は self-improvement 側。
- handback assessment: A（task-local。evaluation loader 契約・runtime triage note shape は確定済みで十分。self-improvement が evaluation loader を triage note の供給源と誤前提し、かつ旧 triage shape のまま再実装追随していない実装側の問題。self-improvement 側修正のみで吸収可能）
- impact severity: P1（invalid-run workflow 学習の triage enrichment が現行確定契約下で恒常的に silent 欠落。中心問い 2 不適合）
- status: open / disposition=`fix-before-next-feature`

### Finding 3 `P1`

- title: Task 9 が要求する self-improvement 決定的検証テストが不在（品質保証欠落）
- file: `tests/self_improvement/`（ディレクトリ不在）／`tests/fixtures/self_improvement/`（fixture のみ・runner なし）
- references: tasks Task 9 完了条件（4 検証対象それぞれに固定入力→期待出力の決定的検証ケースが 1 つ以上存在し pass）／design Completion Criteria／プロジェクト開発方針（TDD）／implementation-conformance-review.md §5.3 証跡性
- description: tasks Task 9 は「列挙 4 検証対象（状態機械の許可/不許可遷移／provenance 欠落時 proposal 阻止／test mode 3 要素分岐＋result_label 整合／adoption gate 3 条件＋invalidation 起点 rollback）それぞれに固定入力→期待出力の決定的検証ケースが 1 つ以上存在し pass する」を完了条件とする。`tests/` 配下に `self_improvement/` ディレクトリは存在せず、`tests/fixtures/self_improvement/` には proposals/rollback の fixture データのみで実行 runner（`test_*.rb`）が一切ない。proposal state machine の不許可遷移禁止、provenance 欠落時 proposal 阻止（Requirement 1 受入 6・design Input Model §2）、test mode 3 要素分岐、adoption gate 3 条件、invalidation 起点 rollback（Requirement 5 受入 6）のいずれも決定的に検証されていない。唯一の機械検証は `validate_self_improvement_pipeline.rb`（end-to-end smoke）だが、これは Finding 1 で FAIL し、かつ Task 9 が要求する固定入力→期待出力の決定的ケース集合ではない。
- impact: Task 9 完了条件が満たされない（証跡性 §5.3）。state machine 不正遷移禁止・provenance gate・adoption gate・invalidation 起点 rollback という contract-critical な振る舞いが回帰検証なしで、現行 evaluation/runtime 契約への適合を機械的に保証できない。evaluation 再実装が Task 9 の 4 検証対象決定的テストを新設して GO 可となった経緯（evaluation 証跡 §6）と対照的に、self-improvement は当該保証が構造的に欠落。
- recommended action: tasks Task 9 の 4 検証対象に対し、現行 evaluation/runtime 出力 shape を入力にした固定入力→期待出力の決定的テストを `tests/self_improvement/` に新設し pass させる（TDD 先行）。
- handback assessment: A（task-local。要件・設計境界は十分でテスト不足は実装側の品質保証欠落。self-improvement 側でテスト新設すれば吸収可能）
- impact severity: P1（contract-critical 振る舞いの決定的検証が皆無。Task 9 完了条件不成立。適合を機械保証できない）
- status: open / disposition=`fix-before-next-feature`

## 4. metric snapshot

- `conformance_findings_count`: 3（P1=3 / P2=0 / P3=0）
- `severity_weighted_finding_score`: 9（重み P1=3・P2=2・P3=1：P1 3件×3 = 9）
- `post_smoke_nonconformance_count`: 3（Finding 1 は smoke 自体が FAIL、Finding 2 は smoke assertion 不成立かつ silent enrichment 欠落、Finding 3 は決定的検証不在＝smoke では捕捉不能の保証欠落）
- `fixture_bound_resolution_count`: 1（self-improvement 実装が旧 fixture corpus＝異議系 decision/finding を含む前提のまま再実装追随しておらず、現行 evaluation 確定 fixture で破綻：Finding 1）
- `heuristic_linkage_count`: 0（撤廃語彙・heuristic linkage への依存は self-improvement スコープに残存せず）
- `review_artifact_presence_rate`: 1.0（本証跡ファイルを新規作成）
- `finding_to_signal_link_rate`: 0.0（本レビュー時点で signal register 起票は未実施。disposition で追跡）

## 5. disposition summary

- immediate disposition:
  - `fix-before-next-feature`: Finding 1（smoke が現行 evaluation/runtime fixture corpus で構造的 FAIL）・Finding 2（`invalid_run_triage_note` の loader 経由取得不能＋triage shape drift）・Finding 3（Task 9 決定的検証テスト不在）
  - `fix-in-current-branch` / `record-and-watch`: 該当なし
  - `reopen-design` / `reopen-requirements` / `reopen-intent`: 該当なし（新規 B/C/D handback なし。evaluation/runtime/foundation 確定契約は正であり、要件・設計境界・上位 intent 側の不足は検出されず、乖離はすべて self-improvement 実装側に限局）
- evidence linkage: 本証跡＝`.kiro/specs/dual-reviewer-self-improvement/reviews/implementation-conformance-review-2026-05-19.md`。新規 finding 3 件はすべて handback class A（task-local。旧 v1 実装が現行承認仕様再承認・evaluation/runtime スクラッチ再実装より前で、再実装追随がなされていないことに起因）。reopen 連携は不要だが、disposition は全件 `fix-before-next-feature`。
- next action:
  - 結論: 既存の self-improvement 実装は全ファイルが旧 v1（2026-05-13 付）で、現行承認仕様の再承認および evaluation／runtime スクラッチ再実装より前であり、**現行承認仕様および evaluation／runtime 新契約へは未適合**。撤廃語彙・`runtime_summary` 非依存・`human_decision_ref` `#` 非分解・AnalysisLayout 正本パス整合は満たすが、(1) 中心経路の `review_quality_signal` が現行確定 fixture corpus で一切産出されず relevant smoke validator が構造的に FAIL、(2) `invalid_run_triage_note` が evaluation LocalRunLoader 経由で恒常取得不能かつ triage note shape も旧 v1 のまま drift、(3) Task 9 の 4 検証対象決定的テストが皆無、という致命 3 件を確認した。
  - 手戻り種別の総括: A=3件（task-local。確定済み evaluation/runtime/foundation 契約は正、self-improvement 実装の再実装追随漏れ）/ B=0 / C=0 / D=0。
  - 推奨: **GO 不可。要手戻り（スクラッチ再実装推奨）**。設計差し戻しは不要（B/C/D ゼロ。requirements 1〜8・design 526 行・tasks 1〜9 は十分で、evaluation/runtime/foundation 確定契約も正）。乖離はすべて self-improvement 実装側に限局し handback class はすべて A。ただし旧 v1 実装は (a) smoke が構造的に FAIL、(b) invalid-run triage enrichment が silent 欠落、(c) 決定的検証テスト皆無、と基盤・実行系・評価で先行した「旧 v1 実装が現行承認仕様未適合 → スクラッチ再実装」と同型の状況であり、点 fix の積み増しより**承認済み仕様＋現行 evaluation/runtime 確定契約からの self-improvement スクラッチ再実装**（Task 9 決定的テスト先行の TDD、現行 evaluation 出力 shape を入力にした smoke/fixture 再構築、`invalid_run_triage_note`/`failure_observation` の runtime 正本配置からの直接 manifest-based 解決）を推奨する。reopen は不要（A 群のみ、設計・要件・intent は不変）。

## 6. 検証対象別 適合判定（独立）

- requirements 1〜8 受入：撤廃語彙非依存・`source_origin` enum・proposal artifact 構造・state は実装上存在するが、Requirement 1 受入 2（review-quality vs workflow-failure 弁別）の review-quality 経路が現行確定 fixture で機能せず（Finding 1）、Requirement 1 受入 5（入力 evidence→proposal の provenance 連鎖、`derived/invalid_run_triage_note.json` 伝播）が loader 制約で silent 断絶（Finding 2）。決定的検証不在のため受入の機械的充足は未保証（Finding 3）。
- design 構成要素：Learning Artifact Layout・Proposal Model・state machine・Replay/Backtest Model・Decision/Adoption・Rollback の各 component は実装上存在し、Signal Extraction Model のパス（AnalysisLayout 正本配置）も整合。ただし Signal Extraction Model §2（evaluation 由来 review-quality 信号）と Replay Inputs（triage/validation artifacts）の consume が現行 evaluation/runtime 確定 shape と乖離。
- tasks 1〜9 完了条件・§6 Completion Criteria：Task 9 完了条件（4 検証対象決定的ケース存在し pass）が不成立（Finding 3）。implementation-conformance-review.md §10 completion rule 第 2 項（relevant smoke validator pass）が不成立（Finding 1）。
- evaluation／runtime 新契約 consume：AnalysisLayout 正本パス（`classifications/run_classification_index.json`・`metrics/{run_metrics,finding_metrics}.json`・`caveats/caveat_register.json`）整合・`run_classification_index`/`run_metrics`/`finding_metrics` の entry shape は signal_intake 参照キーと一致・`derived/runtime_summary.json` 非依存・撤廃語彙非依存・`human_decision_ref` `#` 非分解は**適合**。一方 `invalid_run_triage_note` を evaluation LocalRunLoader 経由で読もうとして恒常欠落（Finding 2）・triage note 内部キーが旧 v1 shape のまま・`review_quality_signal` 抽出が現行 fixture corpus で不発（Finding 1）は**不適合**。
- 基盤契約適合・raw 不変：self-improvement は foundation/runtime/evaluation の schema/語彙を再定義せず（`runtime_validation_summary.schema.json` を runtime 所有として再定義しない）、撤廃済み資産（heuristic_profile_ref・seed pattern 等）への依存も残存しない。raw（`experiments/runs/`・analysis）を mutate しない（点検中の `learning/` 改変は self-improvement の正本出力先であり raw でない。点検後復元済み）。この点は適合。
- 無回帰：`tests/runtime/`（15・0 failures）・`tests/evaluation/`（10・0 failures）・`tests/foundation/`（0 failures）・`tests/governance/`（0 failures）。self-improvement 点検が実行系・評価・基盤・統治を触っていない傍証。

### 総括

既存 self-improvement 実装は旧 v1（2026-05-13）であり、現行承認仕様再承認（2026-05-16〜18）および evaluation／runtime スクラッチ再実装（2026-05-19）より前で、現行承認仕様＋evaluation/runtime 新契約へは未適合。撤廃語彙・`runtime_summary` 非依存・`human_decision_ref` `#` 非分解・AnalysisLayout 正本パス整合は満たすが、致命 3 件（smoke 構造的 FAIL／triage enrichment silent 欠落＋shape drift／Task 9 決定的テスト皆無）を独立に確認した。全 finding は handback class A（self-improvement 実装側の再実装追随漏れ、確定済み evaluation/runtime/foundation 契約は正）。設計・要件・上位 intent 側の不足は検出されず B/C/D はゼロ。

**判定: GO 不可（要手戻り）。設計差し戻し不要（B/C/D ゼロ）。基盤・実行系・評価で先行した「旧 v1 未適合 → スクラッチ再実装」と同型であり、承認済み仕様＋現行 evaluation/runtime 確定契約からの self-improvement スクラッチ再実装（Task 9 決定的テスト先行 TDD・現行 evaluation 出力 shape での smoke/fixture 再構築・triage/failure artifact の runtime 正本配置からの直接解決）を推奨。reopen 不要（A 群のみ）。**
