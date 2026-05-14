## active 必読 (= session 開始時 load、0 件)

(後で選定)

## 参照層 (= 必要時 grep / Read で参照、起動時 load なし)

- [Adjacent Sync 方向](feedback_adjacent_sync_direction.md) — 先行 → 後続方向のみ、後続未生成段階で先行を修正する誘惑を抑制
- [4 step sequential commit](feedback_commit_log_sequencing.md) — design.md fix → hash 取得 → log entry 直接埋込 → log commit
- [cross-spec review pattern](feedback_cross_spec_review_pattern.md) — 3 spec 累計 phase 完走後の Group A/B/C 3 分類で structured review
- [design decisions record](feedback_design_decisions_record.md) — design.md 本文「設計決定事項」+ change log の二重記録
- [design review 10 観点](feedback_design_review.md) — 設計フェーズの 10 観点 = 10 ラウンド構造 SSoT
- [v3 consolidated overview](feedback_design_review_v3_consolidated.md) — v3 関連 3 file の統合 overview
- [design ⇄ spec roundtrip 判断](feedback_design_spec_roundtrip.md) — 設計内吸収可能か仕様改版必要かの判断基準
- [dual-reviewer 3 概念分離](feedback_dual_reviewer_3_concept_separation.md) — dr-* skill / V4 protocol / Level 6 の scope と適用 phase
- [Phase A monitor only](feedback_dual_reviewer_monitor_only.md) — paper rigor 維持で Phase A は monitor のみ、改善は Phase B-1.x
- [finding 4 要素](feedback_finding_4elements.md) — 箇所 / 現状 / 問題 / 修正後の 4 要素で書く、抽象 1 行禁止
- [main 統合 + 3 req audit](feedback_main_merge_3req_audit.md) — main 統合（case A 即 merge）+ V3 design phase cleanup + 3 req 整合性 audit
- [round batching 禁止](feedback_no_round_batching.md) — 各ラウンドは独立 turn で Step 1-4 個別実施
- [review judgment patterns 23 種](feedback_review_judgment_patterns.md) — escalate 判定の実例ベース校正リスト
- [review log template](feedback_review_log_template.md) — Round 提示 + 完了報告の統一 template
- [レビュー所見の必要性判定](feedback_review_necessity_judgment.md) — 主役の過剰修正偏りを抑える独立判定 step、5 観点 + 5 条件 + 三ラベル分類
- [review rounds 5 段構成](feedback_review_rounds.md) — 仕様レビューを 5 ラウンドで実施、隣接 spec 波及精査必須
- [review 出力即時保存](feedback_review_save_immediately.md) — 3 役レビューの各役完了時点でファイルに書き出す
- [review Step 1 改修](feedback_review_step_redesign.md) — Step 1a/1b 分割 + 4 重検査（production deploy 逆算など）
- [self-review skill skip](feedback_self_review_skill_skip.md) — 同 session orchestrator は validate-* skill を sequential 実行しない
- [SSoT 構造的決定 check](feedback_ssot_structural_decision_check.md) — 重要決定の運用前に SSoT 文書群を preflight grep
- [wave 手順遵守規律](feedback_wave_procedure_compliance.md) — wave 開始前にワークフロー文書を読む、must-fix 発見時も human gate まで待つ
