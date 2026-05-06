# memory 移行準備 — 次セッション handoff

_作成: 2026-05-06 (= 56th セッション末)_
_目的: 次セッション開始時の memory 移行作業の前提資料_
_背景: dual-reviewer を独立 repo 化する Phase B-1.0 release prep の prerequisite として、user global memory 内の dual-reviewer 関連 file を project 内に移行_
_position: paper-submission-plan.md v1.0 の prerequisite work、memory 移行完了後に Batch F 着手の流れ_

---

## 1. 移行作業の目的

### Why now
- Phase A 完走 (= SES 2026 submission + post-SES Phase A 残 work) → Phase B-1.0 release prep (= 独立 repo 化) の前段で、dual-reviewer methodology の知識資産 (= memory) が user global location に分散している状態を解消
- 独立 repo 化時に memory も同梱 = methodology 知識の自己完結性確保
- 移行先 path = `.kiro/methodology/v4-validation/research-memory/` (= prep stage、Rwiki 内維持で並行運用)

### 段階的 plan
- **段階 1 (= 次セッション)**: file 物理移行 (= copy) + index 整備 + Rwiki context decoupling
- **段階 2 (= Phase B-1.0)**: independent repo 抽出時に research-memory ごと extract
- **段階 3 (= Phase B-1.x)**: user global memory 元 file 削除 (= 並行運用解消)

---

## 2. memory 棚卸し結果 (= 5/6 時点)

### 累計
- **47 file / 3548 line** in `/Users/keno/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/`
- うち **17 file が Rwiki context 言及** (= 移行時 decoupling 必要)

### Category 別

#### Category 1 = dual-reviewer 方法論本体 (= 移行対象、25 file)
V3/V4 protocol / design review patterns / subagent dispatch / review judgment / round structure 等の dual-reviewer 方法論固有の知識:

- `feedback_design_review.md`
- `feedback_design_review_mechanical.md`
- `feedback_design_review_v3_adversarial_subagent.md`
- `feedback_design_review_v3_consolidated.md`
- `feedback_design_review_v3_generalization_design.md`
- `feedback_review_v4_necessity_judgment.md`
- `feedback_review_judgment_patterns.md`
- `feedback_review_rounds.md`
- `feedback_review_step_redesign.md`
- `feedback_no_round_batching.md`
- `feedback_review_log_template.md`
- `feedback_dual_reviewer_3_concept_separation.md`
- `feedback_dual_reviewer_monitor_only.md`
- `feedback_v3_adoption_lessons_phase_a.md`
- `feedback_v4_design_phase_3spec_completion.md`
- `feedback_v4_redo_lessons.md`
- `feedback_self_review_skill_skip.md`
- `feedback_design_decisions_record.md`
- `feedback_subagent_dispatch_pattern.md`
- `feedback_deepdive_autoadopt.md`
- `feedback_main_merge_3req_audit.md`
- `feedback_design_spec_roundtrip.md`
- `feedback_adjacent_sync_direction.md`
- `feedback_cross_spec_review_pattern.md`
- `feedback_claim_d_evidence_disambiguation.md`

#### Category 2 = paper / research methodology (= 移行対象、8 file)
論文化計画 / treatment policy / Claim D disambiguation / cost evidence 等の paper 軸 knowledge:

- `feedback_finding_4elements.md` (= research methodology)
- `project_treatment_design_md_state_policy.md`
- `project_a23_substitute_with_a376.md`
- `project_a3_plan_triangulation_defense.md`
- `project_dual_reviewer_actual_cost.md`
- `reference_paper_data_acquisition_plan.md`
- `user_paper_rigor_preference.md`
- `user_paper_timeline_conservative_preference.md`

#### Category 3 = 一般 user/feedback 規律 (= 残留対象、12 file)
dual-reviewer 非依存の collaboration / communication / commit / SSoT 規律:

- `feedback_explanation_with_context.md`
- `feedback_response_quality_rules.md`
- `feedback_approval_required.md`
- `feedback_avoid_unnecessary_confirmation.md`
- `feedback_choice_presentation.md`
- `feedback_dominant_dominated_options.md`
- `feedback_commit_log_sequencing.md`
- `feedback_reactive_rewriting_model.md`
- `feedback_multi_file_dependency_precheck.md`
- `feedback_todo_archive_pattern.md`
- `feedback_todo_ssot_verification.md`
- `feedback_ssot_structural_decision_check.md`

#### Category 4 = Rwiki v2 project specific (= Rwiki 残留、4 file)
Rwiki 固有 knowledge、dual-reviewer 抽出時に Rwiki に残留:

- `project_rwiki_v2_mvp_first.md`
- `project_severity_system.md`
- `project_exit_code_ambiguity.md`
- `project_call_claude_timeout.md`

#### MEMORY.md (= index、両系統に併存)
- `MEMORY.md` (= top-level、active 必読 + 参照層 + ARCHIVED)
- 移行後 = top-level MEMORY.md は Cat 3+4 + research-memory への reference のみ、research-memory 内 MEMORY.md は Cat 1+2 詳細 index

---

## 3. 移行先 directory 構造

```
.kiro/methodology/v4-validation/research-memory/
├── MEMORY.md                       (= research-memory 内 index)
├── methodology/                    (= Cat 1 dual-reviewer 方法論)
│   ├── feedback_design_review.md
│   ├── feedback_design_review_v3_*.md
│   ├── feedback_review_v4_necessity_judgment.md
│   ├── feedback_review_judgment_patterns.md
│   ├── feedback_review_rounds.md
│   ├── feedback_review_step_redesign.md
│   ├── feedback_no_round_batching.md
│   ├── feedback_review_log_template.md
│   ├── feedback_dual_reviewer_3_concept_separation.md
│   ├── feedback_dual_reviewer_monitor_only.md
│   ├── feedback_v3_*.md
│   ├── feedback_v4_*.md
│   ├── feedback_self_review_skill_skip.md
│   ├── feedback_design_decisions_record.md
│   ├── feedback_subagent_dispatch_pattern.md
│   ├── feedback_deepdive_autoadopt.md
│   ├── feedback_main_merge_3req_audit.md
│   ├── feedback_design_spec_roundtrip.md
│   ├── feedback_adjacent_sync_direction.md
│   ├── feedback_cross_spec_review_pattern.md
│   └── feedback_design_review_mechanical.md
└── paper/                          (= Cat 2 paper / research methodology)
    ├── feedback_finding_4elements.md
    ├── feedback_claim_d_evidence_disambiguation.md
    ├── project_treatment_design_md_state_policy.md
    ├── project_a23_substitute_with_a376.md
    ├── project_a3_plan_triangulation_defense.md
    ├── project_dual_reviewer_actual_cost.md
    ├── reference_paper_data_acquisition_plan.md
    ├── user_paper_rigor_preference.md
    └── user_paper_timeline_conservative_preference.md
```

### sub-directory 分割の根拠
- `methodology/` = V3/V4 protocol + dual-reviewer skill + review pattern (= 独立 repo 抽出時 framework code と並べる)
- `paper/` = 論文化方法論 + treatment policy + Claim D 構成 (= paper draft 期間に集中参照、独立 repo 抽出時に research/ 階層配下へ)

---

## 4. Rwiki context decoupling 必要 file (= 17 file)

`grep -l "Rwiki\|rwiki\|wiki"` で検出した 17 file は移行時 reference frame 修正が必要:

### 修正 pattern A = 「Spec 6」 reference
- 「Spec 6 = rwiki-v2-perspective-generation」が embed されている file
- 修正方針: 「Spec 6 (= exemplary case study spec、本 methodology の dogfooding 適用先)」のように generic frame
- 該当 file (= 大半):
  - `feedback_design_review_v3_adversarial_subagent.md`
  - `feedback_design_review_v3_consolidated.md`
  - `feedback_design_review_v3_generalization_design.md`
  - `feedback_design_review.md`
  - `feedback_design_review_mechanical.md`
  - `feedback_no_round_batching.md`
  - `feedback_review_rounds.md`
  - `feedback_review_judgment_patterns.md`
  - `feedback_v3_adoption_lessons_phase_a.md`
  - `project_treatment_design_md_state_policy.md`

### 修正 pattern B = 「Rwiki v2 MVP first」 reference
- Rwiki MVP scope を前提とする file
- 修正方針: dual-reviewer 一般概念に書き換え、Rwiki context は parenthesis に
- 該当 file:
  - `feedback_adjacent_sync_direction.md`
  - `feedback_design_spec_roundtrip.md`
  - `feedback_todo_ssot_verification.md`
  - `feedback_todo_archive_pattern.md`

### 修正 pattern C = paper rigor / timeline (= 修正最小)
- paper 戦略 preference は dual-reviewer paper 文脈に embed
- 修正方針: そのまま移行可能、Rwiki context が薄い
- 該当 file:
  - `user_paper_rigor_preference.md`
  - `project_rwiki_v2_mvp_first.md` (= ただし Cat 4 残留対象、移行しない)
  - `project_exit_code_ambiguity.md` (= ただし Cat 4 残留対象)
  - `project_call_claude_timeout.md` (= ただし Cat 4 残留対象)

### 修正 cost 試算
- pattern A: 10 file × 1-3 reference each ≈ 20-30 reference 修正、cost 1-2 hour
- pattern B: 4 file × 1-2 reference each ≈ 5-8 reference 修正、cost 0.5 hour
- pattern C: 1 file × 1-2 reference ≈ 1-2 reference 修正、cost 0.2 hour
- **合計 decoupling cost = 1.7-2.7 hour ≈ 0.5 calendar day**

---

## 5. step-by-step procedure (= 次セッション)

### Step 1: directory 整備 (= 0.1 day)
- `mkdir -p .kiro/methodology/v4-validation/research-memory/methodology/`
- `mkdir -p .kiro/methodology/v4-validation/research-memory/paper/`

### Step 2: file copy (= 0.2 day)
- Cat 1 (= 25 file) を `methodology/` にcopy (= cp、元 file 維持)
- Cat 2 (= 8 file) を `paper/` にcopy

### Step 3: research-memory 内 MEMORY.md index 作成 (= 0.1 day)
- 構成: active 必読 (= dual-reviewer 関連 5-7 件) + 参照層 (= 残り) + Rwiki context note
- 各 entry: file path + 1 line description

### Step 4: Rwiki context decoupling (= 0.5 day)
- pattern A (= 10 file): Spec 6 reference を generic frame
- pattern B (= 4 file): Rwiki MVP context を parenthesis
- pattern C (= 1 file): minor adjust
- **修正は移行 file (= research-memory/ 配下) のみ**、user global 元 file は touch しない (= 並行運用)

### Step 5: top-level MEMORY.md update (= 0.1 day)
- `active 必読` 層: dual-reviewer 関連 entry を research-memory/ への reference に切替
- `## ARCHIVED / CONSOLIDATED` 層: 「dual-reviewer 関連 memory は research-memory/ に移行済 (2026-05-XX)」記載

### Step 6: validation (= 0.1 day)
- 移行漏れ check: `diff <(ls Cat1+2 file) <(ls research-memory 配下)` で完全一致確認
- decoupling 整合: `grep -i "Rwiki\|rwiki\|wiki"` で残留 reference 確認 (= pattern A/B/C 想定外箇所抽出)
- index 完全性: research-memory/MEMORY.md が 33 file 全部 list
- 文書間 reference 整合: data-acquisition-plan / preliminary-paper-report / evidence-catalog から memory 引用箇所の path 整合性 check

### 累計 cost
- Step 1+2+3+5+6 = 0.6 day
- Step 4 (= decoupling) = 0.5 day
- **合計 = 1.1 calendar day** (= 1 work day 弱)

---

## 6. 完了後の Batch F 着手 (= paper-submission-plan v1.0 整合)

memory 移行完了後、SES schedule の Batch F 着手:

- **5/7 (= 移行作業 day)**: memory 移行 + research-memory/ 整備
- **5/8-5/9**: Batch F-1 + F-2 + Q-1〜Q-3 (= schema 起草 + path convention + rework_log 修復)
- **5/10**: Batch F-3 + F-4 + F-5 (= write protocol + validation tooling + §3.7.6.1 re-validate)
- **5/11-5/12**: Batch P-1〜P-7 (= cross-spec narrative + figure rendering + comparison-report v0.5 §14)
- **5/13 以降**: Week 2 paper main body draft

memory 移行 1 day + paper-submission-plan の Week 1 schedule 7 day = 8 day 累計 → 5/14 完了想定で Week 2 着手は 5/15 にずれる。

ただし memory 移行が 1 day で fit すれば paper-submission-plan の 5/13 paper main body draft 開始に間に合う配分も可能 (= 並走運用)。

---

## 7. 次セッション開始時 checklist

### 着手前確認
- [ ] 本 file (`memory-migration-prep.md`) を起動時に Read
- [ ] `paper-submission-plan.md` v1.0 を起動時に Read (= context recovery)
- [ ] user global MEMORY.md `active 必読` 層を起動時に load (= default)

### 確認事項 (= user 判断)
- [ ] memory 移行 vs paper Batch F 着手の順序 (= 移行先行で承認確認)
- [ ] research-memory/ directory 配置承認 (= `.kiro/methodology/v4-validation/research-memory/` で OK か)
- [ ] sub-directory 分割 (= `methodology/` + `paper/`) 承認 vs flat 構造
- [ ] decoupling 範囲 (= 17 file pattern A/B/C 全部修正 vs 一部 minimal)
- [ ] user global 元 file の削除 timing (= 並行運用維持 vs 即時削除)

### 着手承認後
- TaskCreate で memory 移行 task 6 件追加 (= Step 1-6)
- Step 1 から順次実施
- 完了後 Batch F-1 着手

---

## 8. 留意点

### 段階的 plan 維持
- 次セッション = 段階 1 (= file 物理移行 + decoupling) のみ
- 段階 2 (= independent repo 抽出) は Phase B-1.0、本セッションでは触らない
- 段階 3 (= user global 元 file 削除) は Phase B-1.x 以降、安全側

### 並行運用 risk
- user global memory + research-memory/ の 2 重管理 → どちらが SSoT か明示要
- **SSoT = research-memory/** (= 移行後)、user global 元 file は archive 扱い
- top-level MEMORY.md `## ARCHIVED / CONSOLIDATED` 層で明示

### memory load behavior 不確定
- Claude Code が research-memory/ 配下を auto-load するか不明 (= 通常 user global memory 直配下のみ load 想定)
- 対処: top-level MEMORY.md の `active 必読` entry を research-memory/ への relative reference に変更
- alt: research-memory/ 配下の重要 file (= active 必読 5-7 件) を user global にも symlink (= ただし 2 重管理悪化)
- **要次セッション開始時に検証**

### memory 内容自体の改版
- 段階 1 では「移行のみ + decoupling のみ」、内容自体の update / consolidate は行わない (= scope 拡張防止)
- 内容改版は段階 2 以降に defer

---

## 9. 関連 reference

- `paper-submission-plan.md` v1.0 (= 本 file の上位 plan、移行完了後に Batch F 着手)
- `data-acquisition-plan.md` v1.9 (= Phase A scope + Timeline、memory 移行は plan 内 prerequisite work)
- `/Users/keno/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/` (= 元 memory 配置、47 file / 3548 line)
- `MEMORY.md` (= top-level index、移行後に reference 切替)
- 49th セッション議論 (= memory 移行案の保留経緯、本 file 作成の元議論)

---

## 10. 変更履歴

- **v1.0** (2026-05-06 56th セッション末): 本 file 初版 = 次セッション memory 移行作業の前提資料。47 file / 3548 line の memory を 4 category に分類 (= Cat 1 dual-reviewer 方法論 25 file + Cat 2 paper methodology 8 file = 33 file 移行対象、Cat 3 一般規律 12 file + Cat 4 Rwiki specific 4 file = 16 file 残留対象)。移行先 = `.kiro/methodology/v4-validation/research-memory/methodology/` + `paper/`、decoupling 必要 file 17 件 (= Rwiki context reference)、累計 cost 1.1 calendar day。Phase B-1.0 release prep の prerequisite として位置付け、独立 repo 化時に research-memory ごと extract 想定。本 v1.0 自体は methodology meta-document (= Level 6 記録対象外)。
