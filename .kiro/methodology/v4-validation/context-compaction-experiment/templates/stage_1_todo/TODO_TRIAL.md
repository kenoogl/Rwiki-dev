# TODO_NEXT_SESSION.md (= stage 1 = TODO 縮約版)

_更新: 2026-05-04 45th セッション末_

## 1 段落要約

A-2 phase sub-step 4.27 = treatment=dual Round 8 (cross-spec 整合) 完走 = treatment-dual branch Round 1-8 完走 = A-2.1 残 Round 9-10 (= 2 round、46th-47th 完走想定)。Round 8 = primary 3 件中 1 件採用 + 2 件 skip + adversarial 5 件全件採用 = 全 6 件採用。重要 finding = adversarial 独立 ERROR 2 件 (Spec 7 R13.7→R15.1 / interactive log path Spec 2 SSoT 整合) = primary 完全 miss を adversarial 単独補完 + 同型重複 0 件。45th 末議論 = 5 度連続規律発動失敗の機構分析 + 対策方向案 (α)/(β) 提示済 user 判断保留。

## 状態

- 累計 detect 50 / 採用 38 / skip 8 / 過剰修正比率 16% / Level 6 events 37 件 (R-spec-6-1 ~ R-spec-6-37)
- branch = treatment-dual、endpoint = `49cd6d9`、push 完了
- design.md = 1202 行 (post-Round 8 = `ff8361e`)
- dev_log = 8 lines / rework_log = 37 lines
- methodology 4 文書 SSoT (main 上維持) = data-acquisition-plan v1.7 + evidence-catalog v0.10 + preliminary-paper-report v0.6 + comparison-report v0.1

## 46th セッション着手指示

1. 状態確認 = `git log --oneline -5` (= endpoint `49cd6d9` 確認) + `python3 -m pytest scripts/dual_reviewer_*/tests/ -q` (= 151 tests) + `wc -l .dual-reviewer/dev_log.jsonl .kiro/methodology/v4-validation/rework_log.jsonl` (= 8 / 37 lines)
2. memory 必読 7 件 確認 (= MEMORY.md index 経由、`feedback_explanation_with_context.md` 最重要)
3. **Round 9 着手前の user 判断確認** = 案 (α) (= output 直前 1 軸 self-check) / 案 (β) (= template apply 撤廃 + 概要 turn 廃止) / 別案 のいずれか採用判断
4. sub-step 4.28 = Round 9 (= test 戦略) 着手 = primary + adversarial subagent dispatch、judgment skip
5. 入力 = design_md_commit_hash `ff8361e`、session_id `s-a2-r9-dual-<date>`、rework_log entries R-spec-6-38 から開始
6. 完走目標 = Round 9 最低、可能なら Round 9-10 で treatment=dual 完走

## 規律 (= 主要 8 件)

- 説明文体 (= 1 文 1 fact + 説明動詞 + 接続詞 + 具体例先行 + 等号畳み込み禁止、`feedback_explanation_with_context.md`)
- 1 検出 1 turn 提示 (= 案 (ii) structural 補助、44th 末確定)
- 承認なしで進めない (= visible action は user 確認、`feedback_approval_required.md`)
- log meta 禁止 (= 規律状態説明を log artifact に入れない、`feedback_response_quality_rules.md`)
- 4 step sequential (= design.md fix → hash 取得 → log entry 直接埋込 → log commit、`feedback_commit_log_sequencing.md`)
- treatment branch 上で touch しない main SSoT 規律 (`project_treatment_design_md_state_policy.md`)
- dual-reviewer 自己改善 = Phase A は monitor only (`feedback_dual_reviewer_monitor_only.md`)
- review log template 補助手段化 (= 案 (β) 採用なら役割縮小、`feedback_review_log_template.md`)

## 持ち越し TODO

- Adjacent Sync 5 件継続 (= req R2 AC 追記 / Spec 7 design 整合 / Spec 4 G5 LockHelper / Spec 5 R11.6 SSoT / req L56・L316 + chat-sessions filename Spec 2 SSoT 整合)
- 説明文体規律発動失敗 5 度連続 = 案 (α)/(β) user 判断待ち (= 45th 末持ち越し)
- context-compaction-experiment 計画 v1 起草済 = `.kiro/methodology/v4-validation/context-compaction-experiment/plan.md` 参照、5 trial 実施待機
- monitor script 実装 timing 未確定 (= 41st 由来)
- proxy reviewer 他 LLM 試行 = Phase B-2 待機 (= 41st 由来)
- audit gap-list G2+G4 cosmetic 残 (= Phase A 終端 cleanup 候補)
- working tree user 管理 dev-log file (= 19th 由来継承)
- Spec 6 spec.json phase 更新 (= "requirements-approved" → "design-generated"、user 明示承認必須)
- Spec 4 design 改版要請 TODO (= 27th 由来)
- A-3 + §3.7.6 batch 着手準備 (= A-2 完走後)

## 関連 file

- target = `.kiro/specs/rwiki-v2-perspective-generation/design.md` (= 1202 行 treatment-dual)
- methodology SSoT = `.kiro/methodology/v4-validation/{data-acquisition-plan,evidence-catalog,preliminary-paper-report,comparison-report}.md` (= main branch、treatment branch では touch しない)
- dr-design = `scripts/dual_reviewer_prototype/skills/dr-design/SKILL.md` + `extensions/design_extension.yaml` + `prompts/forced_divergence_prompt.txt`
- 過去 session 履歴 = `TODO_HISTORY_through_40th.md` (= repo 追跡)
