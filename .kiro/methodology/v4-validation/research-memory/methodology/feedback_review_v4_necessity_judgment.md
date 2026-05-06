---
name: V4 protocol 確定経緯 + 必要性判定 step
description: V4 protocol v0.3 final 確定経緯 (7th 末 V3 過剰修正 bias 50% 顕在化 → V4 = Step 1c 必要性判定 + judgment subagent dispatch + 5 条件判定ルール + 3 ラベル分類 追加) と適用規律
type: feedback
originSessionId: 4c67776f-efa3-4a91-a1d7-36330ad3c35b
---
V4 protocol = V3 protocol (5 ラウンド + adversarial subagent 統合) + 修正必要性判定 step (Step 1c) を体系的に追加した派生 protocol。design phase review で必ず適用する。

**Why:** 2026-04-30 7th セッション末で V3 protocol 適用結果 (foundation design phase 6 件検出 + retroactive judgment) で過剰修正 bias 50% (do_not_fix 比率) が構造的に顕在化 = V3 検出機能は機能するが「修正必要性 judgment」step 欠落で primary completeness bias が修正提案を増産。V4 protocol は judgment subagent dispatch + 必要性 5-field 評価 + 5 条件判定ルール + 3 ラベル分類で primary should_fix bias を suppress する装置。

**Evidence (12th 末累計、3 spec 連続改善で構造的有効性実証)**:

- foundation design (12th): 検出 16 / must_fix 0 / should_fix 3 / do_not_fix 13 = 採択率 0% / 過剰修正比率 81.25% / V4 修正否定 prompt 機能 90% (primary 9/10 件が judgment で do_not_fix へ整合)
- design-review design (12th): 検出 17 / must_fix 4 (1 false positive) / should_fix 3 / do_not_fix 10 = 採択率 23.5% / 過剰修正比率 58.8%
- dogfeeding design (12th): 検出 15 / must_fix 3 / should_fix 6 / do_not_fix 6 = 採択率 20.0% / 過剰修正比率 40.0%
- 3 spec 連続: 81.25% → 58.8% → 40.0% = -41.25pt 連続改善

**How to apply:**

## V4 protocol 構造 (v0.3 final、`.kiro/methodology/v4-validation/v4-protocol.md` 参照)

- **Step A (primary detection)**: Opus が 5 重検査 (二重逆算 / Phase 1 patterns / dev-log 23 patterns / 自己診断 / 内部論理整合)
- **Step B (adversarial review)**: Sonnet subagent dispatch、独立 detection + V4 §1.5 修正否定試行 + forced_divergence (= adversarial 担当 3 task)
- **Step C (judgment)**: Sonnet judgment subagent dispatch、V4 §5.2 prompt template 適用、必要性 5-field 評価 + 5 条件判定ルール + 3 ラベル分類 + recommended_action + override_reason
- **Step D (integration)**: primary が merge + V4 §2.5 三ラベル提示 (must_fix bulk apply / do_not_fix bulk skip / should_fix individual review)

## 必要性 5-field schema (V4 §1.3、judgment subagent 出力)

各 finding に必須付与:
- `requirement_link`: yes (AC 直接) | indirect (関連) | no (紐付きなし)
- `ignored_impact`: critical (system breaks) | high (function-blocking) | medium (degraded) | low (cosmetic)
- `fix_cost`: high (cross-spec / schema 変更) | medium | low (1 file ≤5 行)
- `scope_expansion`: yes (spec scope 拡張) | no
- `uncertainty`: high (judgment unclear) | medium | low

semi-mechanical mapping default 7 種 (V4 §1.4.2) を judgment subagent prompt に埋込、subjective bias を抑制。override 時は `override_reason` 必須記録。

## 5 条件判定ルール (V4 §1.4.1、順次評価、最強条件 wins)

1. critical impact → must_fix
2. requirement_link=yes AND ignored_impact>=high → must_fix
3. scope_expansion=yes AND not critical → do_not_fix or escalate
4. fix_cost > ignored_impact → do_not_fix-leaning
5. uncertainty=high → escalate (mapped to should_fix + recommended_action: user_decision、design-review Req 3 AC5 整合)

## 3 ラベル分類 + V4 §2.5 user 提示方式

- `must_fix`: bulk apply default (user は念のため確認したい case のみ individual review 選択)
- `do_not_fix`: bulk skip default (LLM 単独で skip 確定せず user 異議申し立て機会確保)
- `should_fix`: 全件 user 提示、user が「全件 apply / 全件 skip / individual review」3 択

## 適用 timing

- design phase review で必ず適用 (foundation + design-review + dogfeeding 3 spec design phase で連続適用済 = 3 spec 連続改善 evidence)
- req phase でも適用 (req phase V4 redo broad で 3 spec 完走済、9th-10th セッション)
- review gate 通過後の 3 spec cross-spec review でも Group A/B/C 分類で integrity check (12th 末で適用)

## False positive 対応

judgment subagent が must_fix 判定したが primary 再検討で false positive と判断する case あり (12th design-review A3 = trigger_state 型矛盾、Req 文言「3 string enum field」解釈問題)。V4 §2.5 user 個別 review で skip 確定可能。primary 注記として false positive 可能性を明示提示。

## 関連 reference

- V4 protocol v0.3 final: `.kiro/methodology/v4-validation/v4-protocol.md`
- V3 baseline: `.kiro/methodology/v4-validation/v3-baseline-summary.md`
- comparison-report: `.kiro/methodology/v4-validation/comparison-report.md`
- evidence-catalog: `.kiro/methodology/v4-validation/evidence-catalog.md`
- 関連 memory: `feedback_design_review_v3_adversarial_subagent.md` (V3 試験運用 evidence、本 V4 が一般化対象) / `feedback_v3_adoption_lessons_phase_a.md` (V3 適用教訓) / `feedback_review_step_redesign.md` (Step 1b 5 重検査) / `feedback_review_judgment_patterns.md` (dev-log 23 patterns)
