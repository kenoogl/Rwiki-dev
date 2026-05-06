---
name: Self-review skill skip 規律 (採取軸保護)
description: design.md / requirements.md / tasks.md 起草直後の同 session orchestrator が validate-design / validate-gap / validate-impl 等 self-review skill を sequential 実行しない。 A-2 phase 採取軸違反由来
type: feedback
originSessionId: b998815a-3db9-4973-bd6a-9ccb1e07caf1
---
design.md / requirements.md / tasks.md 起草直後に同 session の orchestrator が `/kiro-validate-design` / `/kiro-validate-gap` / `/kiro-validate-impl` 等の self-review skill を sequential 実行しない。

**Why:** (2026-05-02) に A-2 phase sub-step 2 = Spec 6 design.md 起草完了 (1146 行) 直後に user 起動 `/kiro-validate-design` で orchestrator (Opus) が同一 session 内 self-review を実行 (3 critical issue identified + NO-GO 判定)、user 指摘で採取軸違反を identified。起草者と reviewer が同一 LLM session = full context shared = self-review contamination で baseline として価値低い、かつ後続 dr-design 等の subagent fresh review 前提を歪める risk (= orchestrator が contamination 結果を反映して artifact を修正すると pristine state が失われ、dual-reviewer Round 1 input が変質)。subagent context には伝達されないため damage は orchestrator level 限定だが、artifact 修正による sequel risk あり (= primary subagent の fresh review 対象が contaminated baseline に変質)。

**How to apply:**
- **適用 phase**: A-2 / A-3 batch primary (= dual-reviewer evidence acquisition phase)、design.md / requirements.md / tasks.md 起草直後
- **例外 2 件**:
- (a) 別 session / 別 subagent からの validate-* 起動 = 採取軸外として実行可能 (= 本規律は同一 session 内 sequential invocation のみ対象)
- (b) implementation phase 完了後の `/kiro-validate-impl` = dr-design 採取軸とは独立 phase = 適用対象外
- **違反時 handling 4 step**:
- (1) self-review 結果を artifact 修正に反映しない (= 破棄)
- (2) artifact は pristine state 維持
- (3) 違反事実を session log に記録 (= rework_log 対象外、self-report として記録)
- (4) dr-design Round 1 fresh subagent で起動して採取軸復旧

**SSoT**: `data-acquisition-plan.md` v1.4 §7 (新設) + v1.5 で Sub-group analysis 規律と並列 SSoT 化

**関連 memory**: `feedback_dual_reviewer_3_concept_separation.md` (= dual-reviewer skill scope = design phase 専用)
