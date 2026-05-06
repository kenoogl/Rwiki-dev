---
name: 案 3 広義 redo の教訓 + V4 brief V4 整合化 prerequisite
description: V4 attempt 1 (V3 scope 半端 ablation) で過剰修正比率 72.7% 悪化 → 案 3 広義 redo (brief / draft / requirements 全 V4 整合) で foundation req 36.8% に改善した教訓
type: feedback
originSessionId: 4c67776f-efa3-4a91-a1d7-36330ad3c35b
---
V4 protocol を partial scope (= V3 整合 source documents で V4 適用) で適用すると逆効果 (= 過剰修正比率 V3 baseline より悪化)。V4 適用前に source documents (brief.md / draft.md / requirements.md) 全 V4 整合化が prerequisite。

**Why:** V4 protocol は document layer 全 V4 整合前提で機能。partial 適用 (V3 brief.md + V4 protocol = scope mismatch) では judgment subagent が AC 文言と V4 機能を紐付けられず do_not_fix 多発。

**Evidence (V4 attempt 1 vs 案 3 広義 redo の比較)**:

- V4 attempt 1 (8th 前半、archive `archive/v4-redo-attempt-1-v3-scope` commit `e8ca94a`):
  - foundation req に V4 protocol 適用、ただし brief.md / draft.md は V3 整合のまま
  - 検出 22 件 / must_fix 5 / should_fix 1 / do_not_fix 16 = 採択率 22.7% / **過剰修正比率 72.7%** (V3 baseline 50% より悪化)
  - 結論: brief.md V4 整合化が前提条件、partial 適用は archive
- 案 3 広義 redo (8th 末 - 11th、main 統合済 commit `bcd604f`):
  - brief.md / draft.md / requirements.md 全 V4 整合化 + V4 protocol 適用
  - foundation req 36.8% (V3 baseline 50% から -13.2pt 改善) / design-review req 25.0% (-25pt) / dogfeeding req 44.4% (-5.6pt)
  - 結論: 案 3 広義 redo で V4 protocol 効果確実

**How to apply:**

## V4 protocol 適用前提条件

V4 protocol を新規 spec / 既存 spec に適用する前に:

1. **brief.md V4 整合化**: V4 protocol §1 機能 5 件 (judgment subagent / 必要性 5-field / 5 条件判定 / 3 ラベル分類 + recommended_action / 修正否定試行 prompt) + Chappy P0 採用 3 件 (`fatal_patterns.yaml` / `impact_score` / forced_divergence) を brief 内に文言反映
2. **draft.md V4 整合化** (適用 spec が draft 持つ場合): draft v0.3 (本 dual-reviewer-draft.md) 整合の §1.2 / §2.5 / §2.6 / §2.10.3 / §3.1 / §4.1 / §4.3 / §4.6 改訂
3. **requirements.md V4 整合化**: 全 Req AC が V4 protocol §1 機能を AC レベルで明示

## 案 3 広義 redo の Step 構造 (8th 末 - 11th)

- Step 0: brief V4 整合化 + draft V4 整合化 (8th 末)
- Step 1-3: foundation / design-review / dogfeeding requirements V4 整合化 (8th 末)
- Step 4: 各 spec の Stage 1-4 (= 各 spec req review の 4 stage) を V4 protocol 下で実施 (9th-10th)
- Step 5: cross-spec review 統合改版 (10th、12 implication 全処理 = apply 8 / 自動解消 3 / resolved 2 / cosmetic 1)
- Step 6: 中間 comparison-report 起草 (10th)
- approve + main 統合 + audit (11th)

## 「partial 適用」を避ける具体ルール

- 既存 V3 整合 spec に V4 protocol を post-hoc 適用しない (= V3 evidence は archive で保持、新規 V4 適用は brief/draft/requirements 全整合の上で実施)
- 半端 ablation (= part of documents だけ V4 整合) は archive 候補、main には統合しない
- archive 操作: `archive/{prefix}-{description}-{date}` branch + tag で完全保全 (V3 endpoint = `archive/v3-foundation-design-7th-session`、V4 attempt 1 = `archive/v4-redo-attempt-1-v3-scope`、V4 redo broad merged = `archive/v4-redo-broad-merged-2026-05-01`)

## 関連 reference

- V4 attempt 1 archive: branch `archive/v4-redo-attempt-1-v3-scope` (commit `e8ca94a`)
- V4 redo broad endpoint: 12th 末 main commit `aa40934`
- comparison-report.md (req phase V4 redo broad evidence)
- evidence-catalog.md §2 (V4 attempt 1) + §3 (V4 redo broad)
- 関連 memory: `feedback_review_v4_necessity_judgment.md` (V4 protocol 確定経緯) / `feedback_v4_design_phase_3spec_completion.md` (12th 末 3 spec design phase 連続完走)
