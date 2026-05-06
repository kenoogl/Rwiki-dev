---
name: 設計レビュー方法論 v3 統合 memory (= 旧 3 file 統合 overview、41st 末整理)
description: v3 (= adversarial subagent 統合) 関連 3 file の統合 overview。各 file の核心規律 + 関係性 + 累計 evidence を整理、詳細 historical content は旧 3 file (= adversarial_subagent / generalization_design / adoption_lessons_phase_a) に残置参照
type: feedback
originSessionId: 7123f852-a334-4449-bbfe-5ff60f9ae420
---
本 memory は v3 (= 旧 10 ラウンド + adversarial subagent 統合) 関連 3 file の統合 overview。v3 は v4 (= judgment subagent + necessity 5-field) で carry over されており、現在は v4 default。本 file は v3 の核心 (= adversarial subagent 統合の有効性 evidence + Layer 1/2/3 三層構造 + Phase A/B/C 段階展開) を整理。

**統合元 3 file (詳細 historical content として残置参照)**:
- `feedback_design_review_v3_adversarial_subagent.md` (= Spec 3 試験運用 + req phase 3 spec 適用 + 累計 evidence 詳細)
- `feedback_design_review_v3_generalization_design.md` (= dual-reviewer package 完全設計 + Chappy 外部レビュー + 14 sections 詳細)
- `feedback_v3_adoption_lessons_phase_a.md` (= 適用教訓 11 件 + 反映 timing 詳細)

## v3 方法論の核心構造

各 Round で 3 ステップ実施:
- **Step A**: LLM 主体検出 (= Opus 4.7、Step 1a/1b/1b-v、5 重検査 + 自動深掘り、`feedback_review_step_redesign.md` 規律遵守)
- **Step B**: adversarial subagent (= Sonnet 4.6、`Agent` tool で general-purpose subagent 起動) で independent 審査 (= LLM 主体の easy wins 偏向 / 自動採択偏向を抑制)
- **Step C**: 検出統合 + user 報告 (= 一致部分 user 確認のみ、disagreement / subagent 追加検出は user 仲裁判断)

→ v4 では Step C 後に **Step D = judgment subagent dispatch** + **necessity 5-field 評価** が追加 = `feedback_review_v4_necessity_judgment.md` 参照

## 核心 evidence (= bias 共有疑念に対する反証決定的蓄積)

全プロジェクト累計 (Spec 3 + foundation + design-review + dogfeeding + 41st 末 treatment=dual 含む):
- **致命級独立発見** (= subagent 由来): **12 件以上**
- **Phase 1 同型 3 種全該当** (= Spec 0 R4 / Spec 1 R5 / Spec 1 R7 escalate パターン): **17 度以上達成**
- **disagreement** (= LLM 主体 ≠ subagent): **17 件以上**
- **致命級独立発見 sample**: Round 7 symlink follow 攻撃 (LLM 主体完全見落とし) / Round 1 R1-03 metric 論理欠陥 / Round 4 SA-01 cross-mode race condition 等

→ 「同モデル偏向共有では発見不可能な検出」が複数回再現 = adversarial subagent の独立検出能力 evidence の決定的蓄積

## Layer 構造 (= dual-reviewer package design)

3 層構造 (詳細は `feedback_design_review_v3_generalization_design.md` §2 + foundation `framework/layer1_framework.yaml` 参照):
- **Layer 1**: phase 横断 framework (= 全 phase 共通の Step A/B/C/D pipeline、bias quota、escalate 必須条件 5 種)
- **Layer 2**: phase 別 extension (= design / req / tasks / impl 各 phase 固有の round / metapattern / quota)
- **Layer 3**: project 固有 (= terminology / extracted_patterns / config)

override 階層 = Layer 3 > Layer 2 > Layer 1。

## Phase A/B/C 段階展開 (= dual-reviewer 開発 roadmap)

- **Phase A** (Rwiki 内試験運用): 現在進行中 = A-0 spec 策定 + A-1 prototype 実装 + A-2 Spec 6 dogfeeding + A-3 + §3.7.6 batch (= triangulation evidence)
- **Phase A 細分化**: A-0 (spec 策定) / A-1 (prototype 3 skills minimum) / A-2 (Spec 6 dogfeeding) / A-3 (B-1.0 統合判断 = Phase A 終端、現在 §3.7.6 で Claim D primary evidence 代替)
- **Phase B** (Spec 6 approve 後独立 fork): B-1 = Claude family rotation / B-2 = multi-vendor + 並列 multi-subagent / B-3 = default 化
- **Phase C** (dogfooding): 別 project への適用展開

## 累計教訓 11 件 essence (= 詳細は `feedback_v3_adoption_lessons_phase_a.md` 参照)

### 即時反映済 (A-0 design phase で確定、設計に組込済)
1. **3 段階 review pattern** を Layer 2 design extension に組込 (= V3 5 ラウンド + cross-spec + 単独 audit + 追加観点)
2. **Step 1b 5 重検査拡張** (= 4 重 + 内部論理整合観点 G 追加)
3. **cross-spec contract 欠陥検出** を design extension AC 化
4. **defer 事項集約 process** 運用化

### 中期反映 (A-1 prototype 実装時)
5. 4 段階 review pattern template を B-1.0 minimum 3 skills に組込
6. statistical 独立性の数学的観点 quota 化

### B-1.x incremental release (長期)
7. req phase V3 default 採用 (B-1.4 `dr-requirements` skill)
8. field 同期漏れ mechanical check skill 化 (B-1.2 `dr-validate`)
9. Reproducibility (multi-run) 機能 (B-1.x or B-2)
10. defer 集約 skill 化 (`dr-defer-collect` or `dr-init` 拡張)

### B-2 以降
11. review pattern 自動化 (= multi-vendor / 並列 multi-subagent 統合)

## 並列処理 + 整合性 Round (= V3 Phase β/γ pattern)

V3 4 段階 review pattern (= req approve 直前 gate template、`feedback_design_review_v3_adversarial_subagent.md` § req phase V3 適用 evidence 参照):
1. **V3 5 ラウンド review** (= Round 1 基本整合性 / Round 2 上位文書照合 / Round 3 本質的観点 / Round 4 B 観点 / Round 5 波及精査)
2. **3 spec 横断 adjacent integrity 再点検** (= cross-spec dependency / contract 欠陥)
3. **各 spec 単独 内部整合性 audit** (= 8 観点 = AC 連番 / Subject / Boundary / field 名 / 用語 / Objective / 内部論理 / 連鎖整合) を parallel subagent で実施
4. **追加観点 audit** (= statistical 独立性 / Reproducibility / defer 集約)

req phase V3 default 採用 (6th セッション 2026-04-30 確定、本 file からの reference として継続)。

## multi-project bias 共有対策 (= Phase B-2 prerequisite)

4 リスク (詳細は `feedback_design_review_v3_generalization_design.md` §7):
1. 同 LLM family 内 bias 共有 (= Opus + Sonnet は Anthropic 同 family、独立性に限界)
2. project 固有用語の漏れ (= terminology.yaml で project 別 override)
3. 採取軸違反 (= self-review skill skip 規律で別 memory 化)
4. statistical 健全性 (= sample size 不足 / cherry-picking risk)

→ Phase B-2 で multi-vendor (= GPT / Gemini etc.) + 並列 multi-subagent で対策

## subagent 再帰多重化 roadmap

- **Phase B-1.0**: Claude family rotation (= Opus / Sonnet / Haiku 切替)
- **Phase B-2**: multi-vendor + 並列 multi-subagent
- **Phase B-3**: default 化 (= 全 phase で multi-subagent 並列)

40th 末議論で **案 2 (orchestrator script 自動化)** = Phase B-1.x roadmap 保持、Phase A 内は run_in_background limited variant のみ、本質的 SDK 経由化は Phase B-1.x 確認。

## 41st 末追加 reference

- **41st 末 treatment=dual Round 1+2 適用**: Round 1 で adversarial が R8.2/R12.4 を独立検出 (= 第 1 系統 main Round 1 と同型再現) + Round 2 で adversarial が R4.5 vs L311 不整合 (A-1) を独立検出 = adversarial 独立検出能力 treatment 横断再現性 evidence 継続蓄積
- **41st 末 hook 削除 + 7 軸 self-check 採用**: 分かりやすい説明 default 化 enforcement (= jargon 軸 + 6 軸非 jargon) は v3/v4 protocol とは独立した user 応答 quality 規律として実装、`feedback_response_quality_rules.md` + `feedback_explanation_with_context.md` 参照

## 関連 memory

- v4 (= 現 default): `feedback_review_v4_necessity_judgment.md` + `feedback_v4_design_phase_3spec_completion.md` + `feedback_v4_redo_lessons.md`
- 旧 10 ラウンド structure: `feedback_design_review.md` (= structure SSoT 継続有効)
- v3 詳細 historical reference: 上記 統合元 3 file
- review step 詳細: `feedback_review_step_redesign.md` (= Step 1a/1b/1b-v + 1c)
- dev-log 23 patterns: `feedback_review_judgment_patterns.md` (= Step 1b-iii 適用)
- escalate 必須条件 5 種: `feedback_review_step_redesign.md` body 参照
- 試験運用報告書: `.kiro/methodology/dogfeeding/spec-3/round_5-10_subagent_adversarial.md` (commit `4703ac4`)
