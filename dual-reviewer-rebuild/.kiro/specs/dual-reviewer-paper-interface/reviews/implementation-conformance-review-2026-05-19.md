# implementation conformance review

_実施日: 2026-05-19_
_レビュー種別: implementation conformance review（独立適合レビュー。実装者とは別プロセス・別視点）_
_対象 feature: dual-reviewer-paper-interface_
_reviewed commit: `8f524f45d9dbae737d22a564f48f950267434919`_
_review focus: 既存 paper-interface 実装が現行承認仕様（requirements 1〜6／design 349 行／tasks 1〜9）へ適合し、かつ直近スクラッチ再実装された evaluation・self-improvement・runtime の新成果物契約（評価 `treatment_comparisons`/`phase_comparisons`/`exclusion_report`/`caveat_register` の新スキーマ、foundation `evidence_class`/`review_mode` 語彙、self-improvement adoption_register 新形）を正しく consume するかを独立確認する_
_正本: docs/coordination/implementation-conformance-review.md_

本証跡は生証跡として不変扱いとする。本レビューにおいてコード・spec・design・requirements・tasks・基盤資産・fixture は一切変更していない（点検と所見記録のみ）。検証スモーク（`validate_paper_interface_pipeline.rb`）は `paper/`・`experiments/analysis/` 不在のため起動直後（tmpdir への `cp_r`）で例外停止し、`experiments/`・`learning/`・`paper/` への一時生成物は一切作られていない（`git status --short` で paper/experiments/learning に差分なしを確認）。前回 evaluation 証跡（同名 `dual-reviewer-evaluation/reviews/...`）の形式に倣ったが、所見は独立判断した。

## 1. review scope

- review type: `implementation conformance review`
- reviewed branch: `claude/v2-acquisition-code-mod`
- reviewed commit: `8f524f45d9dbae737d22a564f48f950267434919`
- reviewed feature: `dual-reviewer-paper-interface`（基盤確定済み契約 `runtime/foundation/`・`runtime/schemas/`、直近スクラッチ再実装済み evaluation `scripts/evaluation/`＋`tests/evaluation/`・self-improvement `scripts/self_improvement/`・runtime `runtime/execution_v2/` を consumer 前提とし、乖離は paper 側で評価）
- review focus:
  - requirements 1〜6 受入・design 構成要素・tasks 1〜9 完了条件を既存実装が漏れなく満たすか
  - paper が「再実装済み evaluation の新しい出力契約」をそのキー名・スキーマで正しく読むか（旧 v1 契約・旧命名・撤廃済み資産への依存残存）
  - evaluation output を一次入力にし生 run を直読しない Downstream Handoff 境界
  - 基盤契約適合（foundation `evidence_class`/`review_mode` 語彙の非再定義・実消費）
  - 静的・スモーク・無回帰（foundation/runtime/evaluation/self_improvement/governance）
- 点検対象とした実装の所在:
  - `scripts/paper_interface/{claim_map_builder,claim_map_writer,evaluation_intake_loader,evidence_register_builder,evidence_register_writer,figure_source_bundle_builder,figure_source_bundle_writer,methodology_note_linkage_builder,methodology_note_linkage_writer,paper_caveat_register_builder,paper_caveat_register_writer,reporting_fragments_builder,reporting_fragments_writer,table_source_bundle_builder,table_source_bundle_writer}.rb`（15 ファイル・いずれも 2026-05-13 付）
  - paper エントリ：`scripts/build_paper_{claim_map,evidence_register,table_source_bundle,figure_source_bundle,caveat_register,reporting_fragments,methodology_note_linkage}.rb`（7 本）＋`scripts/intake_paper_evaluation_outputs.rb`＋`scripts/validate_paper_interface_pipeline.rb`＋`scripts/refresh_analysis_and_paper_from_selection.rb`（いずれも 2026-05-13 付）
  - テスト：`tests/paper_interface/` は**不在**。`tests/fixtures/paper_interface/` は**ファイル不在**（ディレクトリのみ）

## 2. validation rerun

- rerun commands:
  - `ruby -c` 構文検査：`scripts/paper_interface/` 全 15 ＋ paper エントリ 10 ファイル
  - `ruby scripts/validate_paper_interface_pipeline.rb`（paper smoke）
  - `ruby tests/foundation/test_foundation_contracts.rb`（無回帰）
  - `tests/runtime/test_*.rb` 15 ファイル（無回帰）
  - `tests/evaluation/test_*.rb` 10 ファイル（無回帰／consumer 前提契約の確定確認）
  - `tests/self_improvement/test_*.rb` 10 ファイル（無回帰／consumer 前提契約）
  - `ruby tests/governance/test_req9_suite.rb`（無回帰）
  - 新 evaluation 実体契約照合：`scripts/evaluation/{comparison_builder,caveat_builder,exclusion_report_builder,analysis_manifest_writer,staleness_propagator,analysis_layout,classification_engine}.rb`＋writer 群＋`tests/evaluation/` 期待形 と paper 読取コードの突き合わせ
  - 新 self-improvement adoption 契約照合：`scripts/self_improvement/decision_adoption_model.rb` と `methodology_note_linkage_builder.rb` の突き合わせ
  - foundation `review_mode`/`evidence_class` 正本（`runtime/foundation/metadata_contract.yaml`・`runtime/schemas/review_case.schema.json`）と paper の語彙突き合わせ
- result summary:
  - `ruby -c`：paper 実装 15 ＋ エントリ 10 全件 `Syntax OK`（SYNTAX FAIL ゼロ）
  - `validate_paper_interface_pipeline.rb`：**起動直後に例外停止（Errno::ENOENT）**。`paper/` directory が repo に不在（Task 1 skeleton 未配置）かつ `experiments/analysis/` も不在（`experiments/_archived-analysis-2026-05-13/analysis/` にアーカイブ退避）であり、tmpdir への `cp_r` 段階で失敗。smoke は適合判定以前に**機能していない**（Finding 1/9 参照）
  - `tests/foundation/test_foundation_contracts.rb`：8 runs / 107 assertions / 0 failures（無回帰。paper 点検で触っていない傍証）
  - `tests/runtime/`：15 ファイル全 clean（0 failures。無回帰）
  - `tests/evaluation/`：10 ファイル全 clean（0 failures。consumer 前提契約確定の確認＝新出力スキーマが正）
  - `tests/self_improvement/`：10 ファイル全 clean（0 failures。consumer 前提契約確定の確認）
  - `tests/governance/test_req9_suite.rb`：6 runs / 10 assertions / 0 failures（無回帰）

## 3. findings

### Finding 1 `P1`

- title: paper が読む evaluation `caveat_register.json` のキーが新 evaluation 実体スキーマと不一致（新契約 consume の構造的欠落）
- 所在: `scripts/paper_interface/evaluation_intake_loader.rb:124,135`（`caveat_register.fetch("entries", [])`）／`scripts/paper_interface/claim_map_builder.rb:28,89,110`（`fetch("caveat_register").fetch("entries", [])`／`entry['caveat_code']`）／`scripts/paper_interface/paper_caveat_register_builder.rb:30,44,50,84`（`evaluation_caveats.fetch("entries")`／`entry.fetch('caveat_code')`／`entry.fetch('affected_scope')`／`entry.fetch('details')`）／新実体 `scripts/evaluation/caveat_builder.rb:41-52`・`scripts/evaluation/caveat_writer.rb:30-35`・`tests/evaluation/test_exclusion_caveat_model.rb:152-183`
- 現状: 直近スクラッチ再実装された evaluation `CaveatBuilder#build` は `{"caveats" => [...], "caveats_by_class" => {...}, "population_collapsed" => false, "population_summary" => {...}}` を出力し、`CaveatWriter#write` がその register 全体をそのまま `caveats/caveat_register.json` に保存する（`tests/evaluation/test_exclusion_caveat_model.rb` が `register["caveats"]`／`register["caveats_by_class"]` を契約として固定）。一方 paper は全箇所で `caveat_register.fetch("entries")` を読み、各 caveat に `caveat_code`/`affected_scope`/`details` を期待する旧 v1 形（`{"entries" => [...]}`）に依存する。`affected_scope` も旧 v1 値（`treatment_comparison`/`phase_comparison`）前提で、新 caveat は `affected_scope` を `global`/`treatment_comparison` 等で出すが分類軸は `caveat_class`（`data_quality`/`runtime_quality`）へ移行している。
- 問題: paper が「evaluation の新 caveat 出力契約をそのキー名・スキーマで読む」中心要件を満たさない。実 evaluation 出力（`caveats` キー）を入力すると `fetch("entries")` が `KeyError` で全 caveat 系 builder（claim_map・paper_caveat_register・reporting_fragments の limitation fragment）が破綻する。fixture が無くスモークも非機能のため隠れた構造的不適合（境界条件 §5.2 silent fixture 依存／§5.3 証跡性）。
- 推奨対応: paper の caveat 取込を新 evaluation 実体（`caveats`/`caveats_by_class`／`caveat_class` 軸）へ追随させ、`tests/evaluation/` 期待形 fixture で決定的検証する。
- handback class: A（task-local。evaluation 新契約は確定済み＝正であり `tests/evaluation` で固定。乖離は paper 実装の追随漏れ。設計境界・要件は不変）
- impact severity: P1（新契約 consume の構造的不適合。実連携で `KeyError` 即破綻）
- status: open / disposition=`fix-before-next-feature`

### Finding 2 `P1`

- title: paper が読む evaluation `treatment_comparisons.json`/`phase_comparisons.json` のキーが新 evaluation 実体と不一致
- 所在: `scripts/paper_interface/claim_map_builder.rb:43-92`（`phase_comparisons.fetch("phase_slices")`／`first_slice['phase_profile']`／`treatment_comparisons.fetch("comparison_invalid_reason")`／`comparison_status`）／`scripts/paper_interface/table_source_bundle_builder.rb:41-54`（`phase_slices[].overlay_metric_profile`／`available_treatments`／`available_phases` を field_projection に固定）／`scripts/paper_interface/figure_source_bundle_builder.rb:48-56`（`comparison_invalid_reason` 等の status_annotation）／新実体 `scripts/evaluation/comparison_builder.rb:256-314`・`tests/fixtures/evaluation/outputs/minimal_comparison/{treatment_comparisons,phase_comparisons}.json`
- 現状: 新 `ComparisonBuilder` は treatment 側を `{comparison_status, comparison_invalid_reason, treatments_present, treatment_aggregates}`、phase 側を `{comparison_status, comparison_invalid_reason, phase_slices:[{phase_profile, selected_overlay, run_count, run_ids, treatments_present}]}` で出す。paper は phase slice の `overlay_metric_profile`（新形は `selected_overlay`）、`available_phases`/`available_treatments`（新形は `treatments_present`、`available_phases` は新形に不在）を field_projection・claim 文面・status annotation に固定参照している。旧 fixture `tests/fixtures/evaluation/outputs/minimal_comparison/` は `available_treatments`/`available_phases`/`overlay_metric_profile`/`comparisons` を持つ**旧 v1 形のまま**で、新 `ComparisonBuilder` 出力形（`treatments_present`/`treatment_aggregates`/`selected_overlay`）と乖離している。
- 問題: Requirement 2（paper-facing data contract・provenance linkage）の入力契約が実 evaluation 出力で成立しない。`claim_map_builder` は `phase_comparisons.fetch("phase_slices", [])` を読むため即時例外にはならないが、`first_slice['phase_profile']` 以外の paper 側参照（`overlay_metric_profile`・`available_treatments`・`available_phases`）が実 evaluation 出力に存在せず、table/figure bundle の field_projection と status annotation が実体と不整合の死参照になる。旧 fixture が新契約を仮装しており（過去レビュー中心指摘）、決定的検証の不在で露呈していない。
- 推奨対応: paper の comparison 読取・field_projection・status annotation を新 `ComparisonBuilder` 実体（`treatments_present`/`treatment_aggregates`/`selected_overlay`）へ追随させ、evaluation 新実体出力形 fixture で決定的検証する。
- handback class: A（task-local。evaluation 新 comparison 契約は確定済み＝正。乖離は paper 側追随漏れ）
- impact severity: P1（新契約 consume の構造的不適合。field_projection/status annotation が実体と死参照不整合）
- status: open / disposition=`fix-before-next-feature`

### Finding 3 `P1`

- title: evidence_register / claim_map が design 必須フィールド（`evidence_class`・`review_mode`・`supersedes`/`superseded_by`・`stale`/`stale_reason`/`stale_source_ref`・`provenance_refs` 構造化参照）を所有しない
- 所在: `scripts/paper_interface/evidence_register_builder.rb:29-44`（entry に `evidence_class`/`review_mode`/`supersedes`/`superseded_by`/`stale*` なし。独自 `runtime_validation_summary_refs` を追加）／`scripts/paper_interface/claim_map_builder.rb:53,87,100-105`（`supporting_artifact_refs`/`provenance_refs` が裸パス文字列・`"#{REF}##{code}"` の文字列結合）／requirements.md Requirement 5 受入 6・Requirement 6 受入 1〜5・Requirement 2 受入 6・Requirement 1 受入 5／design「Evidence Register Model §2」「Reference Format §3」「Stale Upstream Regeneration §4」
- 現状: design「Evidence Register Model §2」は evidence_register 各 entry に `artifact_ref`/`source_analysis_manifest_ref`/`input_run_set_ref`/`evidence_class`/`review_mode`/`maturity_label`/`caveat_refs`/`supersedes`/`superseded_by`/`generated_at` を要求し、`maturity_label` を foundation `evidence_class`（valid/invalid/exploratory）に束縛された派生分類（束縛規則：invalid は対象外／exploratory→exploratory／valid は安定比較集合なら mature 否なら preliminary）と定義する。実装の `evidence_register_builder` は `artifact_ref`/`source_analysis_manifest_ref`/`input_run_set_ref`/`runtime_validation_summary_refs`/`maturity_label`/`caveat_refs`/`generated_at` のみで、`evidence_class`・`review_mode`・`supersedes`/`superseded_by` を一切持たず、`maturity_label` は claim 側の `comparison_status=="valid" ? "mature" : "preliminary"` の独自規則で、foundation `evidence_class` 束縛規則を実装していない。design「Reference Format §3」が要求する `{ref_type, target_path, target_id}` 構造化参照も未実装で、`supporting_artifact_refs`/`provenance_refs`/`caveat_refs` は裸パス文字列および `"path#code"` の basename/識別子文字列結合（design §1・§3・Requirement 1 受入 5 が明示的に禁止）。design「Stale Upstream Regeneration §4」が要求する `stale`/`stale_reason`/`stale_source_ref` 標識は evidence_register entry・reporting fragment・bundle manifest のいずれにも皆無。
- 問題: Requirement 5 受入 6（foundation evidence-class 束縛の単一語彙）・Requirement 6 受入 1〜5（review-mode provenance／混在検知 caveat／置換系譜）・Requirement 2 受入 6（stale 上流再生成）・Requirement 1 受入 5（versioned evidence に辿れない artifact 不許可・構造化参照）・design §2/§3/§4 が広範に未充足。foundation `evidence_class`/`review_mode` 語彙の非消費（基盤契約適合の入口が機能しない）。
- 推奨対応: evidence_register を design §2 の 10 フィールドへ拡張し、`maturity_label` を foundation `evidence_class` 束縛規則で導出、`review_mode` を foundation 由来で保持、`supersedes`/`superseded_by` と `stale*` 標識を実装、全 `*_ref(s)` を Reference Format 構造化参照へ移行する。
- handback class: A（task-local。foundation `evidence_class`/`review_mode` 語彙・要件・design は確定済みで十分。paper 側の所有実装漏れ。設計差し戻し不要）
- impact severity: P1（複数要件・design 必須構成要素の構造的欠落。基盤語彙の非消費）
- status: open / disposition=`fix-before-next-feature`

### Finding 4 `P1`

- title: review-mode 混在検知 caveat（Req6 受入 4）と置換系譜（Req5 受入 5・Req6 受入 5）が全く未実装
- 所在: `scripts/paper_interface/`（`review_mode`/`mixed`/`supersedes`/`superseded_by` 参照ゼロ）／requirements.md Requirement 6 受入 4・5、Requirement 5 受入 5／design「Evidence Register Model §3」「Review-Mode in Reporting」
- 現状: design「Review-Mode in Reporting」は (a) `review_mode` を evidence_register に保持、(b) 手動由来と runtime 由来を分離報告、(c) 明示ラベルなしに手動を runtime 産出として提示しない、(d) report set が参照する evidence_register entry の `review_mode` が 2 値以上のとき caveat を機械検知・自動付与、(e) 早期手動→後 runtime の置換系譜を `supersedes`/`superseded_by` で保存、を要求する。paper 実装の全 builder に `review_mode` を読む・混在検知する・caveat を付与する・置換リンクを保持するロジックが一切無い（grep で `review_mode`/`mixed`/`supersedes` 参照ゼロ）。
- 問題: Requirement 6 受入 1〜5・Requirement 5 受入 5・design「Review-Mode in Reporting」全面未充足。手動 dogfooding 証拠が runtime 産出証拠として混入・誤提示されうる（design Test Strategy「混在レビュー実施モードの caveat 検証」が検証不能）。
- 推奨対応: evidence_register に `review_mode` を保持し、report set 内 `review_mode` 2 値以上で paper caveat を自動付与、`supersedes`/`superseded_by` で置換系譜を保存する実装を追加する。
- handback class: A（task-local。要件 6・design は規則を明文化済みで十分。paper 側の所有実装漏れ）
- impact severity: P1（要件 6 中核機能の全面欠落。手動証拠の runtime 証拠誤提示リスク）
- status: open / disposition=`fix-before-next-feature`

### Finding 5 `P1`

- title: 決定的 paper-interface 検証テストが全面不在（Task 9 完了条件未達。スモークも非機能）
- 所在: `tests/paper_interface/`（**不在**）／`tests/fixtures/paper_interface/`（ファイル不在）／`scripts/validate_paper_interface_pipeline.rb`（起動例外で非機能）／tasks.md Task 9 完了条件（列挙 4 検証対象に決定的ケース 1 つ以上 pass・TDD 先行）
- 現状: tasks.md Task 9 は「証拠追跡性の機械検証／無声昇格の検出／混在 review_mode caveat／陳腐化再生成」の 4 検証対象それぞれに固定入力→期待出力の決定的検証ケースを 1 つ以上要求し TDD 先行を完了条件とする。実体は `tests/paper_interface/` ディレクトリが存在せず、`tests/fixtures/paper_interface/` はディレクトリのみでファイル皆無。唯一の検証手段 `validate_paper_interface_pipeline.rb` は `paper/`・`experiments/analysis/` 不在で起動直後に例外停止し、適合判定以前に機能していない。
- 問題: Task 9 完了条件未達（決定的検証ケース 0／TDD 先行不在）。design Test Strategy 4 点が検証不能。Finding 1〜4・6〜10 の不適合が検出されなかった根因（決定的・実体準拠の検証が無い）。
- 推奨対応: evaluation/self-improvement 新実体出力形 fixture を入力に、4 検証対象（証拠追跡性／無声昇格／混在 review_mode caveat／陳腐化再生成）の決定的テストを `tests/paper_interface/` に新設（TDD 先行）。
- handback class: A（task-local。テスト追加で吸収。設計・要件は不変）
- impact severity: P1（Task 9 完了条件直接未達。証跡性 §5.3 欠落・スモーク非機能）
- status: open / disposition=`fix-before-next-feature`

### Finding 6 `P1`

- title: stale upstream regeneration（Req2 受入 6・design §4）が全く未実装。新 evaluation `StalenessPropagator` の伝播契約と非接続
- 所在: `scripts/paper_interface/`（`stale`/`stale_reason`/`stale_source_ref`/`rederivation` 参照ゼロ）／新実体 `scripts/evaluation/staleness_propagator.rb:33-72`（`stale`/`stale_run_ids`/`rederivation_required`/`propagation_source`/`affected_derived_artifacts`/`stale_marker_refs` を出す）／requirements.md Requirement 2 受入 6／design「Stale Upstream Regeneration §4」「Test Strategy」
- 現状: 直近スクラッチ再実装された evaluation `StalenessPropagator#evaluate` は run 事後 invalidate 時に `{stale, disposition:"rederive_required", stale_run_ids, rederivation_required:true, propagation_source, affected_derived_artifacts, stale_marker_refs}` を出し、foundation 無効化伝播義務を入力起点とする伝播契約を確定している。design §4 は paper-facing artifact（evidence_register entry・reporting fragment・bundle manifest）に `stale`/`stale_reason`/`stale_source_ref` 標識を持たせ、`stale=true` を再生成対象とし、付与は上流 evaluation 由来陳腐化伝播を受けて行うことを要求。paper 実装に陳腐化標識・伝播受信・再生成対象判定が一切無く、新 evaluation `StalenessPropagator` 出力を consume する経路も皆無。
- 問題: Requirement 2 受入 6・design §4・design Test Strategy「陳腐化再生成の確認」未充足。新 evaluation staleness 伝播契約（確定済み＝正）と未接続。invalidate された run の上に古い paper-facing artifact が silent 据え置きされうる（証跡性 §5.3・foundation 無効化伝播義務の paper 側未接続）。
- 推奨対応: paper-facing artifact に `stale`/`stale_reason`/`stale_source_ref` を持たせ、新 evaluation `StalenessPropagator` の `stale_run_ids`/`propagation_source`/`stale_marker_refs` を入力起点に陳腐化伝播を受信、`stale=true` を再生成対象として検出する実装を追加する。
- handback class: A（task-local。evaluation staleness 伝播契約・foundation 無効化伝播義務・要件 2 受入 6 は確定済みで十分。paper 側の伝播受信実装漏れ）
- impact severity: P1（要件 2 受入 6 の全面欠落。新 evaluation 伝播契約と非接続。陳腐化 paper artifact が silent 据え置き）
- status: open / disposition=`fix-before-next-feature`

### Finding 7 `P2`

- title: methodology_note_linkage が新 self-improvement adoption_register 契約と不一致（旧 `linked_repo_change_ref`/`decision_state=="adopted"` 依存）
- 所在: `scripts/paper_interface/methodology_note_linkage_builder.rb:21,29,31`（`entry["decision_state"] == "adopted"`／`entry["linked_repo_change_ref"]`）／新実体 `scripts/self_improvement/decision_adoption_model.rb:174-179`（`adopt` は `proposal_id`/`adopted_change_ref`/`version_update_ref`/`approval_ref`/`test_artifact_ref`/`adopted_at` を出す）／`learning/approved-updates/adoption_register.json`（on-disk は旧形 `decision_state:"approved"`/`linked_repo_change_ref:null`）
- 現状: 直近スクラッチ再実装された self-improvement `DecisionAdoptionModel#adopt` は adoption entry を `proposal_id`/`adopted_change_ref`/`version_update_ref`/`approval_ref`/`test_artifact_ref`/`adopted_at`（Req4 受入 3・4 の正本）で出す。paper の `methodology_note_linkage_builder` は `decision_state == "adopted"` で filter し `linked_repo_change_ref` を読む旧 v1 契約に依存。新 self-improvement は `decision_state`/`linked_repo_change_ref` を adopted entry に出さない（`adopted_change_ref` へ移行）。on-disk `adoption_register.json` も旧形 1 件（`decision_state:"approved"`・`linked_repo_change_ref:null`）で新実体出力形でない。
- 問題: design「Self-Improvement Independence」「Interfaces / Self-Improvement」の system revision history 参照が実 self-improvement 出力で成立しない。新 adopted entry を入力すると `decision_state == "adopted"` が常に false となり methodology note が常時空（silent fallback）。Downstream Handoff（self-improvement adopted history を methodology note 参照に留める）契約と実体が不整合。
- 推奨対応: methodology_note_linkage を新 self-improvement adoption 実体（`adopted_change_ref`／adopted 判定基準）へ追随させ、新 self-improvement 出力形 fixture で決定的検証する。
- handback class: A（task-local。self-improvement 新 adoption 契約は確定済み＝正。paper 側の追随漏れ）
- impact severity: P2（実 self-improvement 入力で methodology note が silent に常時空。現状は decision_state 旧形 on-disk のため未露呈）
- status: open / disposition=`fix-before-next-feature`

### Finding 8 `P2`

- title: paper が evaluation `exclusion_report.json` の旧 entry 形に依存（新 `ExclusionReportBuilder` の reason_codes/reason_details 軸を消費しない）
- 所在: `scripts/paper_interface/claim_map_builder.rb:78-79`（`exclusion_report.fetch("entries").any? { |e| e["classification"] != "valid" }`）／`scripts/paper_interface/table_source_bundle_builder.rb:49`（field_projection に `entries[].run_id`/`entries[].classification`/`entries[].reason_codes` を固定）／新実体 `scripts/evaluation/exclusion_report_builder.rb:25-66`（`{entries:[{run_id,classification,reason_codes,reason_details,phase_profile,treatment}], total_excluded, exclusion_counts, exclusion_counts_by_reason_code, population_separation}`。valid は entries に出さない）
- 現状: 新 `ExclusionReportBuilder#build` は除外（非 valid）run のみ entries に出し（valid は除外でないため entries 不在）、`total_excluded`/`exclusion_counts`/`exclusion_counts_by_reason_code`/`population_separation` を付す。paper の `claim_map_builder` は `exclusion_report.fetch("entries").any? { |e| e["classification"] != "valid" }` で「非 valid が含まれるか」を判定するが、新実体は valid を entries に出さないため、除外 run があれば entries は常に非 valid のみとなり判定ロジックが実体意味と乖離（「valid のみか」を誤検出しうる）。新規 `total_excluded`/`population_separation` 等の構造化集計も table field_projection に反映されず死参照。
- 問題: Requirement 1 受入 3（direct/caveated 区別）・design「Analysis Population」消費が新 exclusion 実体意味で不正確。新 evaluation exclusion 契約の構造化集計を消費しない（証跡性 §5.3）。
- 推奨対応: paper の exclusion 判定を新 `ExclusionReportBuilder` 実体意味（entries=除外のみ・`total_excluded`/`population_separation`）へ整合させ、field_projection を新キーへ追随、決定的検証する。
- handback class: A（task-local。evaluation 新 exclusion 契約は確定済み＝正。paper 側の意味追随漏れ）
- impact severity: P2（実 evaluation 入力で population 透明性判定が不正確。現 fixture/スモーク非機能で未露呈）
- status: open / disposition=`fix-before-next-feature`

### Finding 9 `P2`

- title: `paper/` directory skeleton が HEAD に不在（Task 1 完了条件の現存性が確認不能）。スモークの構造的非機能の一因
- 所在: `git ls-files paper/`（追跡ファイルゼロ）／`scripts/validate_paper_interface_pipeline.rb:33-35`（`%w[experiments learning paper]` を `cp_r`）／tasks.md Task 1 完了条件（paper-facing artifact が `paper/` 配下に分離）／design「Paper Artifact Layout」
- 現状: design「Paper Artifact Layout」と Task 1 は `paper/{reports/{claim_map.json,evidence_register.json,reporting_fragments.json},tables/table_source_bundle.json,figures/figure_source_bundle.json,caveats/paper_caveat_register.json}` を正本出力先 skeleton として固定する。HEAD に `paper/` の追跡 skeleton（`.gitkeep` 含む）が皆無。スモーク `validate_paper_interface_pipeline.rb` は source repo の `paper/` を tmpdir へ `cp_r` する設計のため、`paper/` 不在で起動直後に Errno::ENOENT 停止（Finding 5 のスモーク非機能の直接原因の一つ）。加えて `experiments/analysis/` も不在（`experiments/_archived-analysis-2026-05-13/analysis/` にアーカイブ退避）で、仮に `paper/` を作っても intake 段階で破綻する。
- 問題: Task 1 完了条件「paper-facing artifact が `paper/` 配下に分離されている／caveat がどこに残るか説明できる」の現存証跡が repo に無い。design 正本配置と repo 実態の乖離。境界条件 §5.2（実行時生成依存／placeholder の隠れ）。
- 推奨対応: `paper/` 正本 skeleton（`.gitkeep`）を repo に配置するか、Task 1 を「実行時生成で skeleton を満たす」と明記し整合させ、スモークの入力前提（`experiments/analysis/` 含む）を実行可能にする。
- handback class: A（task-local。設計の正本配置は確定済み。skeleton 配置または配置追随で吸収可能。判定迷いは保守規律で上流寄せだが、設計記述は配置を明示済みで欠落は実装/repo 側のため A）
- impact severity: P2（Task 1 完了条件の現存証跡欠落。スモーク非機能の一因。provenance/可説明性を弱める）
- status: open / disposition=`fix-in-current-branch`

### Finding 10 `P3`

- title: claim ID taxonomy が 3 固定 claim にハードコードされ design「Claim Unit」の汎用 mapping 単位として機能しない
- 所在: `scripts/paper_interface/claim_map_builder.rb:30-92`（`build_phase_claim`/`build_treatment_claim`/`build_exclusion_claim` の 3 entry 固定。`claim_id` が `claim-phase-comparison-summary` 等の文字列定数）／design「Claim Mapping Model §1 Claim Unit」「Open Issues（claim ID taxonomy をどこまで formalize するか）」
- 現状: design §1 は claim を「claim-to-evidence 対応付けの単位となる paper-facing 言明（最低限 identifier と明示的 evidence source 結合を持つ）」と定義し、claim ID taxonomy 形式化範囲は tasks alignment gate で詰める open issue。実装は phase/treatment/exclusion の 3 entry を固定生成し、claim text も `if comparison_status == "valid"` 等の埋め込み分岐で、claim を一般的な mapping 単位として扱う構造になっていない（taxonomy も formalize されていない）。
- 問題: design「Claim Unit」の単位汎用性・Open Issue（taxonomy 形式化）が実装に反映されず、claim が固定 3 種に閉じている。即破綻ではないが拡張性・traceability を弱める。
- 推奨対応: claim ID taxonomy の形式化範囲（alignment gate で確定済み範囲）に沿って claim を一般 mapping 単位として再構成する。
- handback class: A（task-local。design は Claim Unit を明文化済み・taxonomy 範囲は alignment gate 解決対象。paper 側の汎用化実装に閉じる）
- impact severity: P3（即破綻せず traceability/拡張性を弱める）
- status: open / disposition=`fix-in-current-branch`

## 4. metric snapshot

- `conformance_findings_count`: 10（P1=6 / P2=3 / P3=1）
- `severity_weighted_finding_score`: 25（重み P1=3・P2=2・P3=1：P1 6件×3 + P2 3件×2 + P3 1件×1 = 18+6+1 = 25）
- `post_smoke_nonconformance_count`: 10（スモークが起動例外で非機能のため適合を一切保証していない。全 finding がスモーク通過の裏でなく、スモーク自体が機能しない状態で確認された）
- `fixture_bound_resolution_count`: 0（paper 専用 fixture が皆無。旧 evaluation fixture `tests/fixtures/evaluation/outputs/` も新 evaluation 実体と乖離＝Finding 2 で言及。paper の正当性を担保する hand-crafted fixture すら存在しない）
- `heuristic_linkage_count`: 1（Finding 3：`*_ref` が `"path#code"` の文字列結合・basename/識別子部分一致依存で Reference Format 構造化参照未実装）
- `review_artifact_presence_rate`: 1.0（本証跡ファイルを新規作成）
- `finding_to_signal_link_rate`: 0.0（本レビュー時点で signal register への起票は未実施。disposition で追跡）

## 5. disposition summary

- immediate disposition:
  - `fix-before-next-feature`: Finding 1（caveat_register キー不一致）・Finding 2（comparison キー不一致）・Finding 3（evidence_register 必須フィールド欠落・構造化参照未実装）・Finding 4（review-mode 混在検知/置換系譜全面欠落）・Finding 5（決定的テスト全面不在・スモーク非機能）・Finding 6（stale 再生成全面欠落・新 staleness 契約と非接続）・Finding 7（self-improvement adoption 契約不一致）・Finding 8（exclusion 実体意味の不整合）
  - `fix-in-current-branch`: Finding 9（`paper/` skeleton 不在）・Finding 10（claim ID taxonomy ハードコード）
  - `reopen-design` / `reopen-requirements` / `reopen-intent`: 該当なし（新規 B/C/D handback なし。要件・design・上位 intent 側の不足は検出されず、乖離は全て paper 実装側）
- evidence linkage: 本証跡＝`.kiro/specs/dual-reviewer-paper-interface/reviews/implementation-conformance-review-2026-05-19.md`。finding 10 件はすべて handback class A（task-local。foundation/evaluation/self-improvement/runtime の確定契約は正であり、paper 実装の追随・実装漏れ）。reopen 連携は不要。
- next action:
  - 結論: 既存 paper-interface 実装は **現行承認仕様（requirements 1〜6／design／tasks 1〜9）および evaluation/self-improvement/foundation 新契約へ未適合**。実装作業日（2026-05-13）が仕様再承認・evaluation/self-improvement スクラッチ再実装より前であり、現行契約への適合は保証されないという前提どおりの結果。evaluation `caveat_register`/`comparison`/`exclusion_report` の新スキーマ、foundation `evidence_class`/`review_mode` 語彙、self-improvement adoption 新形、staleness 伝播契約、review-mode 混在検知・置換系譜、構造化参照、`paper/` skeleton、決定的テストが未達。適合の傍証となる箇所は皆無（スモーク非機能）。
  - 手戻り種別の総括: A=10件（task-local。foundation/evaluation/self-improvement/runtime 確定契約＝正に対する paper 側追随／実装漏れ）/ B=0 / C=0 / D=0。design・要件・上位 intent は evidence_register フィールド・review-mode 混在検知・置換系譜・stale 再生成・構造化参照・claim unit を明文化済みで十分であり、不足は paper 実装側に限局。
  - 推奨: **要手戻り（GO 不可）**。**設計差し戻し不要**（B/C/D ゼロ。要件・design は十分）。**スクラッチ再実装が妥当**：実装が現行承認仕様・evaluation/self-improvement 新契約より前の旧 v1 前提で書かれ、paper 専用 fixture も決定的テストも皆無でスモーク自体が非機能（Finding 1〜6/9）であり、部分修正より基盤・実行系・評価・自己改善と同様にスクラッチ再実装＋新 evaluation/self-improvement 実体出力形 fixture での TDD 先行が確実。最低限、(a) evaluation `caveat_register`/`treatment_comparisons`/`phase_comparisons`/`exclusion_report` を新実体スキーマで読む、(b) evidence_register を design §2 の 10 フィールド＋foundation `evidence_class` 束縛 `maturity_label`＋`review_mode` で構築、(c) `*_ref(s)` を Reference Format 構造化参照へ、(d) review-mode 混在検知 caveat・`supersedes`/`superseded_by` 置換系譜・`stale*` 標識と新 evaluation `StalenessPropagator` 受信、(e) self-improvement adoption を新 `adopted_change_ref` 形へ、(f) `paper/` 正本 skeleton 配置、(g) evaluation/self-improvement 新実体出力形 fixture で 4 検証対象の決定的テストを TDD 先行で新設。`tests/foundation`（8 runs/0 failures）・`tests/runtime`（15 clean）・`tests/evaluation`（10 clean）・`tests/self_improvement`（10 clean）・`tests/governance`（6 runs/0 failures）は無回帰で、paper 点検が他機能を壊していないことの傍証。

## 6. 検証コマンド結果（要点）

- `ruby -c`：paper 実装 15 ＋ エントリ 10、全件 `Syntax OK`（FAIL ゼロ）
- `validate_paper_interface_pipeline.rb`：**起動直後 Errno::ENOENT で非機能**（`paper/` 不在＋`experiments/analysis/` 不在。適合の傍証にならない＝Finding 5/9）
- `tests/foundation/test_foundation_contracts.rb`：8 runs / 107 assertions / 0 failures（無回帰）
- `tests/runtime/test_*.rb`：15 ファイル全 clean（0 failures。無回帰）
- `tests/evaluation/test_*.rb`：10 ファイル全 clean（0 failures。consumer 前提契約確定の確認）
- `tests/self_improvement/test_*.rb`：10 ファイル全 clean（0 failures。consumer 前提契約確定の確認）
- `tests/governance/test_req9_suite.rb`：6 runs / 10 assertions / 0 failures（無回帰）
- paper 専用決定的テスト：`tests/paper_interface/` **不在**・`tests/fixtures/paper_interface/` ファイル不在（Finding 5）

**判定: 現行承認仕様および evaluation/self-improvement/foundation 新契約に未適合（GO 不可・要手戻り）。手戻り種別は全件 A（paper 実装側）。設計差し戻し不要、paper-interface フィーチャーのスクラッチ再実装＋新 evaluation/self-improvement 実体出力形 fixture での TDD 先行を推奨。**
