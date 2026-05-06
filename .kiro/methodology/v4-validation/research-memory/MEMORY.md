# research-memory MEMORY.md

_dual-reviewer methodology 研究 memory index、2026-05-06 (= 57th セッション) 移行_
_配置: `.kiro/methodology/v4-validation/research-memory/methodology/` 配下 25 file copy 済_
_位置付け: Phase B-1.0 独立 repo 化の prerequisite、現在は Rwiki と並行運用_

## active 必読 (= 確実に必要、運用で頻参照される core 4 file)

- [dual-reviewer 3 概念分離](methodology/feedback_dual_reviewer_3_concept_separation.md) — dr-* skill / V4 protocol / Level 6 の scope と適用 phase 区別、混同防止
- [設計レビュー 10 観点 SSoT](methodology/feedback_design_review.md) — 設計 phase レビューの structure SSoT (= 10 ラウンド網羅実施 + 一括処理禁止)
- [review log template](methodology/feedback_review_log_template.md) — Round 提示 + 完了報告の統一 structure
- [finding 4 要素](methodology/feedback_finding_4elements.md) — finding を「箇所 / 現状 / 問題 / 修正後」の 4 要素で書く、抽象 1 行禁止

## dormant (= 列挙しない)

`methodology/` 配下に上記 active 4 file 以外に **21 file** copy 済。本 index には列挙せず、必要が出たときに `ls methodology/` or grep で発見する運用。出番あれば user 判断で active 必読層へ昇格、出番なければ段階 3 (= Phase B-1.x) で削除候補。

## user global 残留 (= 本 research-memory に未移行)

dual-reviewer 方法論本体以外の memory file は user global (`/Users/keno/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/`) 配下に残置:

- **Phase A 限定の暫定規律 (= 1 file)**: `feedback_dual_reviewer_monitor_only.md` (= 論文実験期間限定、独立 repo 化時の一般使用には不要)
- **論文 project 固有 context (= 7 file)**: treatment_design_md_state_policy / a23_substitute / a3_plan_triangulation / dual_reviewer_actual_cost / paper_data_acquisition_plan / paper_rigor_preference / paper_timeline_conservative_preference
- **一般規律 (= 12 file、Cat 3)**: explanation_with_context / response_quality_rules / approval_required / 他 9 file
- **Rwiki specific (= 4 file、Cat 4)**: rwiki_v2_mvp_first / severity_system / exit_code_ambiguity / call_claude_timeout

## 観測 protocol (= 要不要判定の base data 採取)

移行作業完了後 N 週間 (= 5-10 session) で JSONL transcript から research-memory/methodology/ への Read tool target を file 別集計:

- Read >= 1 + active 必読 = 継続必須 (= 確実 active)
- Read >= 1 + active 必読なし = active 必読層昇格候補 (= dormant の中で出番が出た file)
- Read = 0 + active 必読なし + 自然言語 mention なし = 段階 3 削除候補

集計手法 = 48-56 session 抽出と同手順 (= JSONL parser、tool_use Read filter)。

## 並行運用 SSoT 規律

- **SSoT = 本 research-memory/** (= 移行後)、user global 元 file は archive 扱い
- top-level MEMORY.md は active 必読層 2 file path 切替済 + ARCHIVED 層に migration record 記載済
- 段階 3 (= Phase B-1.x) で user global の methodology/ 25 file のみ削除予定 (= paper context + Cat 3 + Cat 4 + top-level MEMORY.md は user global に残る)

## 関連 reference

- `../memory-migration-prep.md` v1.0 — 移行作業 handoff document
- `../paper-submission-plan.md` v1.0 — 上位 plan、本作業完了後に Batch F 着手
- `/Users/keno/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/MEMORY.md` — top-level index (= 並行運用)

## 変更履歴

- **v1.0** (2026-05-06 57th セッション): 本 file 初版。25 file 移行 + index 作成。当初実装で active 4 + 参照層 18 + ARCHIVED 3 = **25 file 全 index 化**したが、これは user 指示 (= 「現時点で確実に必要なものだけ」) 違反。即修正で v1.1 へ。
- **v1.1** (2026-05-06 57th セッション、user 指摘で修正): index = active 必読 4 file のみ、残り 21 file は dormant 化 (= 列挙しない)。Step 4 (= Rwiki context decoupling) は段階 2 (= 独立 repo 抽出時) defer (= 上位文書 paper-submission-plan / data-acquisition-plan / dev_log で Rwiki context は SSoT 化済、並行運用中は redundant copy で機能影響なし)。
