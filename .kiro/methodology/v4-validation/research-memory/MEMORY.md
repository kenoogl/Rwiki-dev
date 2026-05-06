# research-memory MEMORY.md

_dual-reviewer methodology 研究 memory index、2026-05-06 (= 57th セッション) 移行初版_
_配置: `.kiro/methodology/v4-validation/research-memory/methodology/` 配下 25 file_
_位置付け: Phase B-1.0 独立 repo 化の prerequisite、現在は Rwiki と並行運用_

## active 必読 (= 確実に必要、運用で頻参照される core 4 file)

- [dual-reviewer 3 概念分離](methodology/feedback_dual_reviewer_3_concept_separation.md) — dr-* skill / V4 protocol / Level 6 の scope と適用 phase 区別、混同防止
- [設計レビュー 10 観点 SSoT](methodology/feedback_design_review.md) — 設計 phase レビューの structure SSoT (= 10 ラウンド網羅実施 + 一括処理禁止)
- [review log template](methodology/feedback_review_log_template.md) — Round 提示 + 完了報告の統一 structure
- [finding 4 要素](methodology/feedback_finding_4elements.md) — finding を「箇所 / 現状 / 問題 / 修正後」の 4 要素で書く、抽象 1 行禁止

## 参照層 (= dormant copy、必要時 grep / Read で参照、運用で出番あれば active 層へ昇格検討)

### V3/V4 protocol 詳細 (= 4 file)

- [V3 adversarial subagent 統合](methodology/feedback_design_review_v3_adversarial_subagent.md) — V3 4 phase 構造の起源
- [V3 consolidated](methodology/feedback_design_review_v3_consolidated.md) — V3 11 教訓 essence + reflection timing 整理
- [V3 generalization design](methodology/feedback_design_review_v3_generalization_design.md) — Phase A 全体設計 + Layer 1/2/3 三層構造
- [V4 necessity judgment](methodology/feedback_review_v4_necessity_judgment.md) — V4 judgment subagent + necessity 5-field schema

### review 運用詳細 (= 8 file)

- [review judgment patterns 23 種](methodology/feedback_review_judgment_patterns.md) — 各 round judgment の決定木
- [review rounds 5 構成](methodology/feedback_review_rounds.md) — 仕様レビューの 5 ラウンド構成
- [review step redesign](methodology/feedback_review_step_redesign.md) — Step 1a/1b/1b-v + 1c の改修版
- [no round batching](methodology/feedback_no_round_batching.md) — ラウンド一括処理禁止
- [design review mechanical](methodology/feedback_design_review_mechanical.md) — 機械的 review 規律
- [self-review skill skip](methodology/feedback_self_review_skill_skip.md) — self-review skip 規律
- [subagent dispatch pattern](methodology/feedback_subagent_dispatch_pattern.md) — 周辺 work の subagent 派遣 pattern
- [deepdive autoadopt](methodology/feedback_deepdive_autoadopt.md) — 深掘り検討 + 自動採択方針

### 仕様⇄設計 + cross-spec + adjacent (= 4 file)

- [design spec roundtrip](methodology/feedback_design_spec_roundtrip.md) — 仕様⇄設計 往復改版判断軸
- [design decisions record](methodology/feedback_design_decisions_record.md) — 設計決定の記録方式 (= ADR 代替)
- [adjacent sync direction](methodology/feedback_adjacent_sync_direction.md) — Adjacent Sync 方向性
- [cross-spec review pattern](methodology/feedback_cross_spec_review_pattern.md) — cross-spec review = Group A/B/C 3 分類

### req phase 統合 (= 1 file)

- [main 統合 + 3req audit](methodology/feedback_main_merge_3req_audit.md) — req phase main 統合 + 3 req 整合性 audit プロセス

### Claim D + paper claim evidence (= 1 file)

- [Claim D evidence disambiguation](methodology/feedback_claim_d_evidence_disambiguation.md) — Claim D evidence 3 種別 disambiguate

## ARCHIVED / CONSOLIDATED (= historical reference、通常参照不要)

- [V3 adoption lessons Phase A](methodology/feedback_v3_adoption_lessons_phase_a.md) — **CONSOLIDATED** = 41st 末整理確定、核心は `feedback_design_review_v3_consolidated.md` に統合済、本 file は 11 教訓詳細の historical reference として残置
- [V4 redo lessons](methodology/feedback_v4_redo_lessons.md) — V4 attempt 1 → 案 3 広義 redo の経緯、方法論 evolution の historical record
- [V4 design phase 3spec completion](methodology/feedback_v4_design_phase_3spec_completion.md) — 12-14th 末 6 spec instance 累計 evidence、論文 claim data としての historical record

## user global 残留 (= 本 research-memory に未移行、Rwiki ⇄ 研究 context 共用)

以下の memory file は user global (`/Users/keno/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/`) 配下に残置、本 research-memory には copy しない:

### Phase A 限定の dual-reviewer 運用規律 (= 1 file)

- `feedback_dual_reviewer_monitor_only.md` — Phase A monitor only、論文実験期間中の暫定規律 (= 開発過程のみに必要、独立 repo 化時の dual-reviewer 一般使用には不要)

### 論文 project 固有 context (= 7 file)

- `project_treatment_design_md_state_policy.md` — 3 系統 design.md state policy (= 論文実験 confounding 排除規律)
- `project_a23_substitute_with_a376.md` — A-2.3 substitute 判断 (= 論文論証 path)
- `project_a3_plan_triangulation_defense.md` — A-3 plan triangulation (= 論文論証防御戦略)
- `project_dual_reviewer_actual_cost.md` — treatment 別 cost evidence (= 論文 claim data)
- `reference_paper_data_acquisition_plan.md` — 論文 data 取得 checkbox tracker
- `user_paper_rigor_preference.md` — user の論文厳密性 preference
- `user_paper_timeline_conservative_preference.md` — user の論文 schedule preference

### 一般規律 (= 12 file、Cat 3 user global 残留)

- `feedback_explanation_with_context.md` / `feedback_response_quality_rules.md` / `feedback_approval_required.md` / `feedback_avoid_unnecessary_confirmation.md` / `feedback_choice_presentation.md` / `feedback_dominant_dominated_options.md` / `feedback_commit_log_sequencing.md` / `feedback_reactive_rewriting_model.md` / `feedback_multi_file_dependency_precheck.md` / `feedback_todo_archive_pattern.md` / `feedback_todo_ssot_verification.md` / `feedback_ssot_structural_decision_check.md`

### Rwiki specific (= 4 file、Cat 4 Rwiki 残留)

- `project_rwiki_v2_mvp_first.md` / `project_severity_system.md` / `project_exit_code_ambiguity.md` / `project_call_claude_timeout.md`

## 観測 protocol (= 段階 3 削除判断の base data 採取)

- 移行作業完了 (= Step 6 validation pass) 後、通常運用で N 週間 (= 5-10 session 想定) 経過
- 各 session の JSONL transcript から research-memory/methodology/ への Read tool target を集計
- 判定 matrix:
  - Read >= 1 + active 必読層 = **継続必須** (= 確実 active)
  - Read >= 1 + active 必読層なし = **継続** (= 参照層として現役)、必要に応じて active 必読層へ昇格検討
  - Read = 0 + active 必読層 = **継続必須** (= auto-load で機能、deep-read 稀)
  - Read = 0 + active 必読層なし + 自然言語 mention なし = **archive 候補**、user 判断で段階 3 削除対象
- 集計手法 = 48-56 session 抽出と同手順 (= JSONL parser、tool_use Read filter)

## 並行運用 SSoT 規律

- **SSoT = 本 research-memory/** (= 移行後)、user global 元 file は archive 扱い
- top-level MEMORY.md `## ARCHIVED / CONSOLIDATED` 層に「dual-reviewer 関連 25 file は research-memory/ に移行済 (2026-05-06)」記載済
- 段階 3 (= Phase B-1.x) で user global の methodology/ 25 file 分のみ削除予定 (= paper context + Cat 3 + Cat 4 + MEMORY.md は user global に残る)

## 関連 reference

- `../memory-migration-prep.md` v1.0 — 移行作業 handoff document
- `../paper-submission-plan.md` v1.0 — 上位 plan、本作業完了後に Batch F 着手
- `/Users/keno/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/` — user global memory (= 並行運用)
- `/Users/keno/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/MEMORY.md` — top-level index (= active 必読層 path 切替済)

## 変更履歴

- **v1.0** (2026-05-06 57th セッション): 本 file 初版 = 25 file 移行 (= Cat 1 24 + Cat 2 promoted 1) 完了時点。active 必読 = 4 file (= 3_concept_separation / design_review / review_log_template / finding_4elements)、参照層 = 18 file、ARCHIVED/CONSOLIDATED = 3 file。観測 protocol 規定。並行運用 SSoT 規律明示。
  - **Rwiki context decoupling は段階 2 defer**: handoff §4 default の「Rwiki / Spec 6 references を generic frame 化」作業は本セッションで実施せず、独立 repo 抽出時 (= 段階 2 = Phase B-1.0) に実施。理由: memory file 内の Rwiki references は上位文書 (`paper-submission-plan.md` / `data-acquisition-plan.md` / `docs/dual-reviewer-log-X.md`) で SSoT 化済 = redundant copy、並行運用中は reader が上位文書で canonical 情報取得可能で機能影響ゼロ。真の decoupling は独立 repo 抽出時に上位文書が同梱されなくなる時点で意味を持つ、今実施は premature optimization + 意味毀損 risk (= Phase A roadmap narrative / case study integral 部分の損傷)。
