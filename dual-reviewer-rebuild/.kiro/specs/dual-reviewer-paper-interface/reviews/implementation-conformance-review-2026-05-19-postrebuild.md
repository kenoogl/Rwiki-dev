# implementation conformance review（再実装後・独立）

_実施日: 2026-05-19_
_レビュー種別: implementation conformance review（再実装後・独立適合レビュー。実装者とは別プロセス・別視点）_
_対象 feature: dual-reviewer-paper-interface_
_reviewed commit: `9766febb`（再実装は本コミット基底の隔離 worktree 上に未コミットで存在）_
_review focus: dual-reviewer-paper-interface のスクラッチ再実装が現行承認仕様（requirements 1〜6／design 349 行／tasks 1〜9・§6 Completion Criteria）へ構造適合し、再実装済み evaluation の新成果物契約（`treatments_present`/`treatment_aggregates`/`selected_overlay`／`caveats`/`caveats_by_class`／exclusion `total_excluded`/`population_separation`／`run_classification_index` entries／`StalenessPropagator` 伝播契約）と foundation `evidence_class`/`review_mode` 語彙を正しく consume し、前回 finding 10 件（P1=6/P2=3/P3=1、全件 handback A）が解消したかを独立確認する_
_正本: docs/coordination/implementation-conformance-review.md_

本証跡は生証跡として不変扱いとする。本レビューにおいてコード・spec・design・requirements・tasks・基盤資産・fixture は一切変更していない（点検と所見記録のみ）。検証は隔離 git worktree（`agent-a1b50f2c1238263bf`、ブランチ `worktree-agent-a1b50f2c1238263bf`、ベース `9766febb`）内で行い、worktree 内ファイルは Bash の `cat`/`grep` で閲覧した。テストは tmpdir（`Dir.mktmpdir`）または版固定 fixture を入力とし、`experiments/`・`learning/` 実体への一時生成物は作られていない（`git status --short` で `experiments/`・`learning/` に差分ゼロを独立確認。untracked は `paper/`・`scripts/paper_interface/v2/`・`tests/paper_interface/` の 3 新設のみ）。前回証跡（`implementation-conformance-review-2026-05-19.md`）および実装者申告は鵜呑みにせず独立判断した。

reviewed commit `9766febb` は承認済み spec＋波0版固定 fixture を含むベースを指す。本レビューが点検したスクラッチ再実装（`scripts/paper_interface/v2/*` 9 ファイル・`tests/paper_interface/` 8 ファイル・`tests/fixtures/paper_interface/`・`paper/` skeleton。いずれも 2026-05-19 付）は worktree 上に未コミットで存在する。post-rebuild レビューの性質上、点検対象は worktree の再実装状態であり、reviewed commit はその基底点として記録する。

## 1. review scope

- review type: `implementation conformance review`（再実装後）
- reviewed branch: `worktree-agent-a1b50f2c1238263bf`（ベース `claude/v2-acquisition-code-mod` の `9766febb`）
- reviewed commit: `9766febb`（再実装は本コミット基底の隔離 worktree 上に存在）
- reviewed feature: `dual-reviewer-paper-interface`（基盤確定済み契約 `runtime/foundation/metadata_contract.yaml`・`runtime/schemas/review_case.schema.json`、再実装済み evaluation `scripts/evaluation/{comparison_builder,caveat_builder,exclusion_report_builder,classification_engine,staleness_propagator,classification_writer}.rb` を consumer 前提とし、乖離は paper 側で評価）
- review focus:
  - requirements 1〜6 受入・design 全構成要素・tasks 1〜9 完了条件・§6 Completion Criteria を再実装が漏れなく満たすか
  - 前回 finding 10 件（F1 caveat_register キー不一致／F2 comparison キー不一致／F3 evidence_register 10 フィールド・evidence_class 束縛・構造化参照欠落／F4 review-mode 混在検知・置換系譜欠落／F5 決定的テスト全面不在／F6 stale 再生成欠落／F7 self-improvement adoption 不一致／F8 exclusion 実体意味不整合／F9 `paper/` skeleton 不在／F10 claim taxonomy ハードコード）の解消
  - paper が版固定 fixture（評価新契約の実キー構造）を正しく consume するか・旧 v1 契約／旧命名／撤廃資産依存残存ゼロ・require 閉包独立
  - evaluation output を一次入力にし生 run を直読しない Downstream Handoff 境界
  - foundation `evidence_class`/`review_mode` 非再定義・`maturity_label` の evidence_class 束縛規則（design Evidence Register Model §1）
  - 静的・決定的テスト・無回帰（foundation/runtime/evaluation/self_improvement/governance）・fixture が実出力形を仮装していないか
- 点検対象とした実装の所在:
  - `scripts/paper_interface/v2/{paper_layout,reference,analysis_intake,claim_map_builder,evidence_register_builder,bundle_builder,paper_caveat_register_builder,reporting_fragments_builder,separation_rules}.rb`（9 ファイル・2026-05-19 付）
  - `paper/{reports,tables,figures,caveats}/.gitkeep`（skeleton 4 件）
  - テスト：`tests/paper_interface/test_*.rb`（8 ファイル）、版固定 fixture `tests/fixtures/paper_interface/analysis/`（評価実出力形）
  - 旧 v1（`scripts/paper_interface/*.rb` 15・`scripts/build_paper_*.rb` 7）は rm せず放置・未書換（untracked 差分なし＝点検対象外）

## 2. validation rerun

- rerun commands:
  - `ruby -c` 構文検査：`scripts/paper_interface/v2/` 全 9 ＋ `tests/paper_interface/` 全 8
  - `tests/paper_interface/test_*.rb` 全 8 ファイル（決定的テスト本体）
  - `tests/foundation/test_foundation_contracts.rb`（無回帰）
  - `tests/runtime/test_*.rb` 全 15 ファイル（無回帰）
  - `tests/evaluation/test_*.rb` 全 10 ファイル（無回帰／consumer 前提契約確定確認）
  - `tests/self_improvement/test_*.rb` 全 10 ファイル（無回帰）
  - `tests/governance/test_req9_suite.rb`（無回帰）
  - 版固定 fixture 実体契約照合：`tests/fixtures/paper_interface/analysis/` 全 8 ファイルと evaluation 実体 builder（`comparison_builder.rb:248-323`・`caveat_builder.rb:42-154`・`exclusion_report_builder.rb:34-80`・`classification_engine.rb:219-350`・`classification_writer.rb:17-23`・`staleness_propagator.rb:46-70`）出力キーの突き合わせ
  - require 閉包独立の独立確認：`scripts/paper_interface/v2/*.rb` の `require`/`require_relative` 全件抽出、旧 v1（`scripts/paper_interface/*.rb`・`scripts/build_paper_*.rb`）参照ゼロを grep
  - 旧契約残置 grep：`fetch("entries")`/`linked_repo_change_ref`/`decision_state`/`available_treatments`/`available_phases`/`overlay_metric_profile`/`runtime_validation_summary_refs`/`"#{...}#..."` 文字列結合
  - foundation 語彙正本（`metadata_contract.yaml:59,104`・`review_case.schema.json`）と paper 語彙突き合わせ
- result summary:
  - `ruby -c`：v2 実装 9 ＋テスト 8 全件 `Syntax OK`（FAIL ゼロ）
  - `tests/paper_interface/`：8 ファイル全 PASS。合計 **59 runs / 401 assertions / 0 failures / 0 errors / 0 skips**（内訳：claim_map 8/73・evidence_register 10/60・figure_table_bundle 8/65・paper_caveat_register 7/37・paper_layout_and_reference 7/34・reporting_fragments 6/59・separation_rules 8/25・task9_verification_targets 5/48）。実装者申告（59run/401assertion 全緑）と完全一致を独立確認
  - `tests/foundation/test_foundation_contracts.rb`：8 runs / 107 assertions / 0 failures（無回帰）
  - `tests/runtime/`：15 ファイル全 clean（0 failures/0 errors。無回帰）
  - `tests/evaluation/`：10 ファイル全 clean（0 failures。consumer 前提契約確定の確認＝新出力スキーマが正）
  - `tests/self_improvement/`：10 ファイル全 clean（0 failures。無回帰）
  - `tests/governance/test_req9_suite.rb`：6 runs / 10 assertions / 0 failures（無回帰）
  - 版固定 fixture 実体契約：treatment_comparisons（`comparison_status`/`treatments_present`/`treatment_aggregates`）・phase_comparisons（`phase_slices`/`selected_overlay`）・caveat_register（`caveats`/`caveats_by_class`/`population_summary`）・exclusion_report（`entries`=除外のみ/`total_excluded`/`exclusion_counts_by_reason_code`/`population_separation`）・run_classification_index（`entries`内 `classification`/`review_mode`/`in_standard_runtime_comparison_set`/`step_omission_disposition`）・manifest（`analysis_logic_version`/`input_run_set`/`generated_at=2026-01-01T00:00:00Z`）が、いずれも実 evaluation builder 出力キーと一致。`generated_at` 正規化以外は実値（fixture 仮装なし）
  - require 閉包独立：v2 9 ファイルは `require`/`require_relative` が siblings（`analysis_intake`/`reference`）＋ stdlib（json/yaml/pathname/fileutils）のみ。旧 v1・`build_paper_*` 参照ゼロ。テスト 8 ファイルも `v2/` パスのみ require
  - 旧契約残置 grep：実コード依存ゼロ（grep ヒットは全てスクラッチ方針を記すコメント＝「旧 v1 を流用せず破棄」、または `separation_rules.rb:80` の `stale_run_ids` join の正当な文字列補間）

## 3. findings

新規 conformance finding は検出されなかった（0 件）。

再実装は前回 finding 10 件を構造的に解消し（§6 詳細）、版固定 fixture は実 evaluation builder 出力キーと一致（仮装なし）、Task 9 の 4 検証対象に決定的ケースが存在し pass、require 閉包は旧 v1 から完全独立、foundation 語彙は非再定義、無回帰は foundation/runtime/evaluation/self_improvement/governance 全緑であり、新規の構造的・隠れ非適合は確認されなかった。観察点（finding に至らない）を以下に記す。

- 観察 1（非 finding）: `evidence_register_builder.rb#evidence_class_of` は run_classification_index の `classification` を foundation 語彙へ対応付ける際、`analysis_blocked` を `invalid` 扱い（paper-facing 対象外）にする。design §1「`evidence_class=invalid` は paper-facing 対象外」と整合し、評価が確定済みの `analysis_blocked`（必須入力欠落＝有効評価不能）を paper に載せない保守判断であり適合。foundation `evidence_class` enum の `candidate` は run_classification_index の analysis 確定語彙には現れず（評価が valid/invalid/exploratory/analysis_blocked に確定）、対応漏れではない。
- 観察 2（非 finding）: claim/bundle/fragment の `maturity_label` は run_classification_index 全体から「valid かつ安定比較集合の有無」で算出する集約値であり、evidence_register entry の per-run 束縛とは粒度が異なる。design「Reporting Fragment Model」は fragment 集約を保守表示と明記し per_source_maturity 保持を要求しており、claim/bundle は単一 maturity を持つ design §1 の claim 単位定義に沿う。evidence_register が per-entry で foundation 束縛規則を厳守（test_evidence_register が独立検証）しているため、束縛正本は evidence_register にあり整合。silent strengthening は `separation_rules.rb#silent_strengthening_allowed?` が出典 maturity 上限で機械ゲートし、test_task9_verification_targets target2 が決定的に pass。

## 4. metric snapshot

- `conformance_findings_count`: 0（P1=0 / P2=0 / P3=0）
- `severity_weighted_finding_score`: 0（重み P1=3・P2=2・P3=1。新規 finding ゼロ）
- `post_smoke_nonconformance_count`: 0（決定的テスト 59run/401assertion 全緑の裏で隠れ非適合なし。fixture が実 evaluation builder 出力形のため緑が仮装に依存しない）
- `fixture_bound_resolution_count`: 0（版固定 fixture は実 evaluation builder 出力キーと一致し、`generated_at` 正規化以外は実値。前回 F1/F2/F8 の「旧 fixture が新契約を仮装」構造は解消＝paper 専用 fixture が実出力形）
- `heuristic_linkage_count`: 0（全 `*_ref(s)` が `{ref_type,target_path,target_id}` 構造化参照。basename/`"path#code"` 文字列結合・部分一致依存なし＝前回 F3 の heuristic linkage 解消）
- `review_artifact_presence_rate`: 1.0（本証跡ファイルを新規作成）
- `finding_to_signal_link_rate`: 0.0（新規 finding ゼロのため起票対象なし。disposition で追跡）

## 5. disposition summary

- immediate disposition:
  - `fix-before-next-feature` / `fix-in-current-branch` / `record-and-watch`: 該当なし（新規 finding ゼロ）
  - `reopen-design` / `reopen-requirements` / `reopen-intent`: 該当なし（新規 B/C/D handback なし。要件・design・上位 intent 側の不足は検出されず、前回も今回も乖離は paper 実装側に限局）
- evidence linkage: 本証跡＝`.kiro/specs/dual-reviewer-paper-interface/reviews/implementation-conformance-review-2026-05-19-postrebuild.md`。新規 finding ゼロ・reopen 連携不要。前回 finding 10 件は全件 handback A（task-local）で、本再実装が paper 側追随として全件解消。
- next action:
  - 結論: dual-reviewer-paper-interface のスクラッチ再実装は **現行承認仕様（requirements 1〜6／design 349 行／tasks 1〜9・§6 Completion Criteria）および evaluation 新契約・foundation 語彙へ構造適合**。前回 finding 10 件（P1=6/P2=3/P3=1・全件 A）は **全 10 件解消を独立確認**（詳細は §6）。版固定 fixture は実 evaluation builder 出力形へ整備され、前回の「旧 fixture が新契約を仮装し決定的検証が不在で不適合が露呈しない」構造は解消。Task 9 の 4 検証対象（証拠追跡性／無声昇格／混在 review_mode caveat／陳腐化再生成）の決定的ケースが新設され pass。新規 finding はゼロ。
  - 手戻り種別の総括: 新規 A/B/C/D いずれもゼロ。design・要件・上位 intent は evidence_register 10 フィールド・束縛規則・review-mode 混在検知・置換系譜・stale 再生成・構造化参照・claim unit を明文化済みで十分であり、前回も今回も不足は paper 実装側に限局（前回 A=10 件→今回スクラッチ再実装で全解消）。
  - 推奨: **GO 可**。設計差し戻し不要（B/C/D ゼロ。要件・design は十分）。前回「要手戻り（GO 不可）・スクラッチ再実装推奨」は妥当な判断であり、再実装は前回 10 finding を構造的に解消した。基盤・実行系・評価・自己改善と同様、論文インターフェースのスクラッチ再実装＋実 evaluation 出力形 fixture での TDD 先行で適合を達成。`tests/foundation`（8 runs/0 failures）・`tests/runtime`（15 clean）・`tests/evaluation`（10 clean）・`tests/self_improvement`（10 clean）・`tests/governance`（6 runs/0 failures）は無回帰で、paper 再実装が他機能を壊していないことの傍証。コミット・push は明示承認後に行う（本レビューは点検と所見記録のみ）。

## 6. 前回 finding 10 件の解消状況

前回証跡（`implementation-conformance-review-2026-05-19.md`、P1=6/P2=3/P3=1、全件 handback A）に対する本レビューの独立判定。

- 前回 F1（P1・A）caveat_register 新契約 consume：**解消**。`paper_caveat_register_builder.rb:48-49` が `caveat_register["caveats"]` を読む（旧 `fetch("entries")` 非依存）。`claim_map_builder.rb:128-129`・`bundle_builder.rb:146`・`reporting_fragments_builder.rb:142` も `cr["caveats"]` を読む。`affected_scope` は新実体の `global`/`treatment_comparison`/`phase_comparison` を構造化参照化（`paper_caveat_register_builder.rb:110-127`）。版固定 caveat_register fixture が実 `caveat_builder.rb:42-154` 出力（`caveats`/`caveats_by_class`/`population_collapsed`/`population_summary`、各 caveat `caveat_code`/`caveat_class`/`severity`/`details`/`affected_scope`）と一致を独立確認。`test_paper_caveat_register` 7 runs pass。
- 前回 F2（P1・A）treatment/phase_comparisons 新契約 consume：**解消**。`claim_map_builder.rb:36,46` が `treatments_present`／`phase_slices[].phase_profile`、`bundle_builder.rb:40-61` の field_projection が `treatments_present`/`treatment_aggregates.*`/`phase_slices.selected_overlay`/`phase_slices.treatments_present` を参照（旧 `available_treatments`/`available_phases`/`overlay_metric_profile` 死参照を排除）。版固定 fixture が実 `comparison_builder.rb:258-323` 出力キーと一致。`test_claim_map` 8 runs・`test_figure_table_bundle` 8 runs pass。
- 前回 F3（P1・A）evidence_register 10 フィールド・evidence_class 束縛・構造化参照：**解消**。`evidence_register_builder.rb:45-60` が design §2 の 10 フィールド（`artifact_ref`/`source_analysis_manifest_ref`/`input_run_set_ref`/`evidence_class`/`review_mode`/`maturity_label`/`caveat_refs`/`supersedes`/`superseded_by`/`generated_at`）＋ stale 3 標識を所有。`maturity_label`（:157-165）は foundation `evidence_class` 束縛規則（invalid 除外／exploratory→exploratory／valid は安定比較集合なら mature 否なら preliminary）を実装。`reference.rb` が `{ref_type,target_path,target_id}` 構造化参照を提供し全 builder が使用（裸パス・`"path#code"` 結合・basename 部分一致なし）。`test_evidence_register` の `test_entry_has_all_ten_fields`/`test_maturity_label_bound_to_evidence_class`/`test_all_refs_are_structured` 含む 10 runs pass。
- 前回 F4（P1・A）review-mode 混在検知 caveat・置換系譜：**解消**。`evidence_register_builder.rb:68-71` が `mixed_review_modes?`（review_mode 2 値以上検知）、:75-86 が `mixed_review_mode_caveat`（自動付与素材）、:91-99 が `link_supersession`（`supersedes`/`superseded_by` 双方向・破壊的更新せず複製返し）。`paper_caveat_register_builder.rb:82-104` が混在 caveat を `methodological_limitation` で paper caveat へ取込。`test_evidence_register` の `test_mixed_review_mode_detection`/`test_supersession_lineage_linking`、`test_task9_verification_targets` target3 が決定的 pass。
- 前回 F5（P1・A）決定的検証テスト全面不在（Task 9 完了条件）：**解消**。`tests/paper_interface/` に 8 ファイル新設（59 runs / 401 assertions / 0 failures）。`test_task9_verification_targets.rb` が 4 検証対象（target1 証拠追跡性の machine 解決／target2 無声昇格不許可／target3 混在 review_mode caveat／target4 stale 再生成）の固定入力→期待出力ケースを保持し pass。版固定 評価実出力 fixture を入力にする（TDD 先行・実体準拠）。
- 前回 F6（P1・A）stale 再生成・新 StalenessPropagator 接続：**解消**。`separation_rules.rb:69-89` `apply_staleness` が新 evaluation `StalenessPropagator#evaluate` 出力（`stale`/`disposition`/`stale_run_ids`/`propagation_source`/`stale_marker_refs`）を入力起点に paper-facing artifact へ `stale`/`stale_reason`/`stale_source_ref`（構造化参照）を付与、:92-94 `regeneration_required?` が `stale=true` を再生成対象として検出。実 `staleness_propagator.rb:46-70` 出力キーと一致を独立確認。`test_separation_rules`・`test_task9_verification_targets` target4 が決定的 pass。
- 前回 F7（P2・A）self-improvement adoption 契約不一致：**解消**。旧 `methodology_note_linkage_builder.rb`（`decision_state=="adopted"`/`linked_repo_change_ref` 旧依存）を流用せず破棄。`separation_rules.rb:56-63` `classify_self_improvement_reference` が `adopted_change_ref` を入力に受け、`allowed_role="methodology_note"`・`usable_as_primary_performance_claim=false`・`usable_as_claim_support_artifact=false` を返す（design §3 Self-Improvement Independence・Downstream Handoff 遵守）。旧 `decision_state`/`linked_repo_change_ref` 参照ゼロ（grep 確認）。`test_separation_rules` 8 runs pass。
- 前回 F8（P2・A）exclusion_report 実体意味不整合：**解消**。`claim_map_builder.rb:57` が `er['total_excluded']` を読み（旧 `entries.any?{classification!="valid"}` の意味乖離判定を排除）、`bundle_builder.rb:71-80` の field_projection が `total_excluded`/`exclusion_counts`/`exclusion_counts_by_reason_code`/`population_separation.*`/`entries.*` を消費。版固定 exclusion_report fixture が実 `exclusion_report_builder.rb:34-80`（entries=除外のみ・`total_excluded`・`population_separation`）と一致。`test_claim_map`/`test_figure_table_bundle` pass。
- 前回 F9（P2・A）`paper/` skeleton 不在：**解消**。`paper/{reports,tables,figures,caveats}/.gitkeep` 4 件を worktree に配置（design「Paper Artifact Layout」正本配置）。`paper_layout.rb:19-55` が正本パス定数＋`materialize_skeleton`（冪等 mkdir_p＋`.gitkeep`）を所有し、`paper_caveat_basedir="paper/caveats"`（experiments/analysis/ と別基準＝衝突しない）を明示。`test_paper_layout_and_reference` 7 runs pass。raw evidence・core evaluation output と分離（Requirement 2 受入 3）。
- 前回 F10（P3・A）claim taxonomy 3 固定ハードコード：**解消**。`claim_map_builder.rb:30-61` が `CLAIM_DESCRIPTORS`（claim_id／source_keys／text_proc のデータ駆動宣言列挙）で claim を一般 mapping 単位として再構成（埋め込み分岐をデータ化）。design §1 Claim Unit（identifier＋明示的 evidence source 結合）と整合し、固定 3 メソッド分岐の旧構造を排除。`test_claim_map` 8 runs pass。

### 総括

前回 10 finding（P1=6/P2=3/P3=1、全件 handback A）に対し、**10 件全件の完全解消**を独立に確認した。版固定 fixture は実 evaluation builder 出力形（`caveats`/`caveats_by_class`／`treatments_present`/`treatment_aggregates`／`selected_overlay`／exclusion `total_excluded`/`population_separation`／run_classification_index entries／manifest `generated_at=2026-01-01T00:00:00Z` 正規化のみ）へ整備され、前回の「旧 evaluation fixture が新契約を仮装し決定的検証不在で不適合が露呈しない」構造は解消。Task 9 の 4 検証対象決定的テストが新設され pass。新規 finding はゼロで、要件・design・上位 intent 側の不足は検出されず、乖離は前回も今回も paper 実装側に限局（前回 A=10 件 → スクラッチ再実装で全解消、新規 B/C/D ゼロ）。require 閉包は旧 v1（`scripts/paper_interface/*.rb` 15・`scripts/build_paper_*.rb` 7、放置・未書換）から完全独立、foundation `evidence_class`/`review_mode` 語彙は非再定義（対応のみ）、Downstream Handoff 境界（evaluation output を一次入力・生 run 直読なし・`AnalysisIntake#require_evaluation_output!` が生ログフォールバックを禁止）を遵守。`tests/foundation`（8 runs/0 failures）・`tests/runtime`（15 clean）・`tests/evaluation`（10 clean）・`tests/self_improvement`（10 clean）・`tests/governance`（6 runs/0 failures）は無回帰で、paper 再実装が基盤・実行系・評価・自己改善を壊していない傍証。

## 6'. 検証コマンド結果（要点）

- `ruby -c`：v2 実装 9 ＋テスト 8、全件 `Syntax OK`（FAIL ゼロ）
- `tests/paper_interface/`：8 ファイル全 PASS。59 runs / 401 assertions / 0 failures / 0 errors / 0 skips（実装者申告と一致を独立確認）
- `tests/foundation/test_foundation_contracts.rb`：8 runs / 107 assertions / 0 failures（無回帰）
- `tests/runtime/test_*.rb`：15 ファイル全 clean（0 failures。無回帰）
- `tests/evaluation/test_*.rb`：10 ファイル全 clean（0 failures。consumer 前提契約確定の確認）
- `tests/self_improvement/test_*.rb`：10 ファイル全 clean（0 failures。無回帰）
- `tests/governance/test_req9_suite.rb`：6 runs / 10 assertions / 0 failures（無回帰）
- 版固定 fixture：実 evaluation builder 出力キーと一致・`generated_at` 正規化以外は実値（仮装なし）
- require 閉包独立：v2 9 ファイルは siblings＋stdlib のみ require、旧 v1・`build_paper_*` 参照ゼロ
- 一時生成物：`experiments/`・`learning/` 差分ゼロ（untracked は `paper/`・`scripts/paper_interface/v2/`・`tests/paper_interface/` の 3 新設のみ。worktree をレビュー前状態へ維持）

**判定: 現行承認仕様（requirements 1〜6／design／tasks 1〜9・§6）および evaluation 新契約・foundation 語彙へ構造適合（GO 可）。前回 finding 10 件（P1=6/P2=3/P3=1・全件 A）は全 10 件解消を独立確認。新規 finding ゼロ（P1/P2/P3 すべて 0、severity_weighted_finding_score=0、handback B/C/D ゼロ）。設計差し戻し不要・reopen 不要。スクラッチ再実装は前回 10 finding を構造的に解消しており妥当。**
