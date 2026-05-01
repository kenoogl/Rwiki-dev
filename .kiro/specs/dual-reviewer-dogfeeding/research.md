# Research & Design Decisions — dual-reviewer-dogfeeding

## Summary

- **Feature**: `dual-reviewer-dogfeeding`
- **Discovery Scope**: Extension (foundation + design-review consumer + Spec 6 適用、Light/Medium discovery)、consumer-only spec (新規 skill / framework 実装一切なし)
- **Key Findings**:
  1. consumer-only spec、foundation + design-review skill を invoke のみ
  2. Spec 6 = dogfeeding target、本 spec と並走、Spec 6 design 内容自体策定は Spec 6 spec 責務
  3. 30 review session = 10 Round × 3 系統、cost 3 倍 (判定 7-C)
  4. 3 系統 step 構成異なる: single (A only) / dual (A+B、judgment skip) / dual+judgment (A+B+C+D)
  5. dr-design treatment flag = design-review revalidation trigger (本 spec が consumer-driven contract で要請)
  6. metric 抽出 12 軸 + figure data 4 種 + Phase B fork 5 条件
  7. Spec 6 design approve = 確認条件 (本 spec が強制せず、責務境界整合)
  8. 8 月 timeline failure 基準 = 8 月末日 figure 1-3 + ablation evidence 完了未達
  9. Operational Protocol + Research Script Hybrid pattern 採用 (SKILL.md 不要、一回限り manual session)
  10. design-review revalidation triggers 3 件 (treatment flag + timestamp 必須付与 + commit_hash payload 受領)

## Research Log

### Topic: Foundation + Design-Review Integration Contract

- **Context**: 本 spec が foundation + design-review に依存する consumer-only spec、両 upstream design (foundation v1.1 + design-review v1.1) を contract source として import
- **Sources Consulted**:
  - foundation/design.md v1.1 (commit `2e5637d`)
  - design-review/design.md v1.1 (commit `76a1eb1`)
  - foundation/research.md v1.0 + design-review/research.md v1.0
- **Findings**:
  - foundation install location = `scripts/dual_reviewer_prototype/` (foundation 設計決定 5 + 1)
  - 4 skills (dr-init + dr-design + dr-log + dr-judgment) の skill invocation 規約整合
  - 共通 schema 2 軸並列 + foundation Req 3.6 consumer 拡張 mechanism 利用 (`additionalProperties: true` default)
  - design-review v1.1 = treatment flag 未対応 = 本 spec が revalidation trigger 要請 (Decision 3 + 6)
- **Implications**: 本 spec Python script (metric_extractor + figure_data_generator + phase_b_judgment) は foundation schemas/ + dr-log JSONL output を input source として使用、新規 schema 定義不要

### Topic: 3 系統対照実験 Treatment Branching

- **Context**: V4 §1.2 option C = primary + adversarial + judgment 3 subagent 構成、3 系統で step 構成を切替
- **Sources Consulted**:
  - V4 protocol §4.4 ablation framing
  - dogfeeding/requirements.md Req 2 全 7 AC
  - design-review/design.md dr-design + dr-log + dr-judgment Service Interface
- **Findings**:
  - single 系統: Step A only、judgment / adversarial dispatch 全 skip、user 提示省略 (research baseline)
  - dual 系統 (V3 構成): Step A + B、Step C/D は merge のみ、user 提示省略 (research baseline、wall-clock 公平 measurement)
  - dual+judgment 系統 (V4 完全構成): Step A + B + C + D、V4 §2.5 三ラベル提示 + user 判断
  - treatment flag = `--treatment={single|dual|dual+judgment}` で dr-design CLI 指定、design-review revalidation trigger
- **Implications**: ablation framing 公平性 = wall-clock + 採択率 + 過剰修正比率 metric 比較で 3 系統対照実験が成立 (V4 §4.4 整合)

### Topic: Metric Extraction + Figure Data + Phase B Fork Judgment Pipeline

- **Context**: 30 review session JSONL → 12 軸 metric → figure 1-3 + ablation data → Phase B fork 5 条件評価 → comparison-report 追記 の sequential pipeline 設計
- **Sources Consulted**:
  - dogfeeding/requirements.md Req 4 (12 軸 metric) + Req 5 (figure 4 種) + Req 6 (Phase B fork 5 条件)
  - V4 protocol §4.1 (比較指標) + §4.3 (H1-H4 仮説)
  - comparison-report.md (既存、append target)
- **Findings**:
  - 12 軸 metric = 検出件数 / 3 ラベル件数+比率 / 採択率 / 過剰修正比率 / adversarial 修正否定 disagreement / judgment subagent disagreement / judgment override / wall-clock cost 倍率 / Phase 1 同型 hit rate / fatal_patterns 8 種 hit 件数
  - figure 4 種 = miss_type 分布 / difference_type 分布 + forced_divergence 効果 / trigger_state 発動率 / dual vs dual+judgment ablation
  - Phase B fork 5 条件 = 致命級発見 ≥ 2 / disagreement ≥ 3 / bias 共有反証 evidence / impact_score 分布 / 過剰修正比率改善
  - condition (c) 機械評価 logic = JSONL の `source: adversarial` finding で primary 未検出 issue_id ≥ 1 件 (A2 fix で本 design 確定)
- **Implications**: 3 Python script (metric_extractor → figure_data_generator → phase_b_judgment) sequential 実行 + idempotent + comparison-report append-only

### Topic: 8 月 Timeline Failure 基準

- **Context**: Req 2.6 (b) で 8 月 timeline failure 基準明示 (Phase B fork hold 判定の補助根拠)
- **Sources Consulted**:
  - draft v0.3 §3.5 8 月までの論文化ロードマップ
  - dogfeeding/requirements.md Req 2.6 (b) + Req 6.4
- **Findings**:
  - 8 月末日 figure 1-3 + ablation evidence 完了が timeline 達成基準
  - Spec 6 design approve は本 spec 確認条件 (Spec 6 spec 責務、本 spec が強制せず)
  - 未達時 = Phase B fork hold 判定の補助根拠として comparison-report 併記
- **Implications**: phase_b_judgment.py が 8 月末日 timeline check + figure data 完了状態確認 logic 実装 (Decision 5 整合)

### Topic: Physical Layout Selection (X1 採用)

- **Context**: dogfeeding Python script 配置 location 確定 (本 spec design phase 責務、Req 4.6 + 5.6 path 規約)
- **Sources Consulted**: foundation 設計決定 1 (X1 採用 = `scripts/dual_reviewer_prototype/`)、Rwiki `.kiro/steering/structure.md`
- **Findings**:
  - 候補 X1: `scripts/dual_reviewer_dogfeeding/` (prototype 本体と分離、研究 artifact 独立)
  - 候補 X3: `.kiro/methodology/v4-validation/scripts/` (methodology directory 内集約)
  - X1 採用根拠: scripts/ 配下 code 慣例 + 命名統一 (`scripts/dual_reviewer_*/`) + Phase B 移行時 dogfeeding 研究 artifact = Rwiki repo 残置 + prototype 切り出し独立
  - user 判断: X1 採用
- **Implications**: `scripts/dual_reviewer_dogfeeding/` 配下に 3 Python script + tests/ + README.md 配置

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Operational Protocol + Research Script Hybrid (採用) | 操作手順書 (design.md 内記述) + 3 Python script (metric_extractor + figure_data_generator + phase_b_judgment) | 一回限り session に適切、SKILL.md 形式不要 | 自動化対象外 (CI 統合は B-1.x 以降) | foundation `dr-init` + design-review SKILL.md パターンとの違い明示 |
| SKILL.md format Hybrid | 全 component を Claude Code skill として実装 | foundation + design-review 統一性 | 一回限り session に過剰、SKILL.md repeated invocation 想定不整合 | 却下 |
| Pure Python Package | 全 component を Python package 化 | type safety + import 整合 | Phase A scope 過剰、scope 拡張 | 却下 |

## Design Decisions

(design.md「設計決定事項」section と同期記録)

### Decision 1: dogfeeding scripts location = `scripts/dual_reviewer_dogfeeding/` (X1 採用)

- **Selected**: Alternative 1 (X1 = `scripts/dual_reviewer_dogfeeding/`)
- **Rationale**: scripts/ 配下 code 慣例 + 命名統一 + Phase B 切り出し独立性
- **Trade-offs**: methodology evidence と script の単一 namespace 集約 sacrifice、許容
- **Follow-up**: implementation phase で directory 生成 + tests/ + README.md

### Decision 2: Operational Protocol + Research Script Hybrid (SKILL.md 形式不要)

- **Selected**: Alternative 1 (Hybrid)
- **Rationale**: 一回限り session、自動化対象外、SKILL.md は repeated invocation 想定不整合
- **Trade-offs**: SKILL.md による Claude assistant 起動 UX 失われる
- **Follow-up**: README.md (3 script 連携手順 + dogfeeding session 全体フロー) を `scripts/dual_reviewer_dogfeeding/README.md` に配置

### Decision 3: dr-design Treatment Flag Contract = design-review revalidation trigger

- **Selected**: Alternative 1 (treatment flag = consumer-driven contract、design-review revalidation 要請)
- **Rationale**: clean responsibility separation、wrapper duplicate 回避、ablation 公平性確保
- **Trade-offs**: design-review revalidation cycle 発生
- **Follow-up**: 本 spec design approve 完了時 implication 通知 (design-review/design.md v1.2)

### Decision 4: comparison-report.md = append-only extension

- **Selected**: Alternative 1 (append-only)
- **Rationale**: research evidence 累積 file、既存 §1-11 改変なし (revisionism risk 回避)
- **Trade-offs**: comparison-report 1 file 長文化
- **Follow-up**: section ID = `phase-b-fork-judgment-v1` 固定 (P5 fix)

### Decision 5: 8 月 timeline failure 基準 = "8 月末日 figure 1-3 + ablation evidence 完了"

- **Selected**: Alternative 1 (figure data 完了基準)
- **Rationale**: 論文 8 月ドラフト提出 = figure data input 必須 / Spec 6 approve は Spec 6 責務 (責務境界整合)
- **Trade-offs**: Spec 6 進捗 caveat 別途併記
- **Follow-up**: phase_b_judgment.py 内 timeline check logic 実装

### Decision 6: design-review revalidation triggers 集約 (3 件)

- **Triggers**:
  1. dr-design `--treatment` flag 対応 (Decision 3 + P1 fix Step A/B/C/D 切替動作 + user 提示 skip/実行)
  2. dr-log `timestamp_start` / `timestamp_end` JSONL 必須付与 (A3 fix)
  3. dr-log Service Interface に `--design-md-commit-hash` payload 受領追加 (P2 fix)
- **対応 timing**: 本 spec design approve → design-review revalidation cycle → design-review v1.2 → 本 spec implementation phase 直前
- **Rationale**: consumer-driven contract clean separation
- **Trade-offs**: revalidation cycle 発生、本 spec scope 内責務 (contract 確定まで)
- **Follow-up**: 本 spec design approve commit message + research.md References + design-review に implication 通知

## V4 Review Gate Outcomes

V4 protocol §3.3 step 7 を本 design phase に適用、以下を実施:

- **Step 1a + 1b primary detection** (Opus): 10 件検出 (P1-P10)
- **Step 1b parallel adversarial detection** (Sonnet subagent): 5 件独立検出 (A1-A5) + V4 §1.5 修正否定試行 counter-evidence
- **Step 1c judgment subagent dispatch** (Sonnet judgment subagent): 15 件全 V4 §5.2 prompt 適用、必要性 5-field 評価 + 5 条件判定 + 3 ラベル分類
- **Step 2 user 判断** (V4 §2.5 三ラベル提示方式): user **A 採択** = must_fix 3 件 + should_fix 6 件 全 apply + do_not_fix 6 件 bulk skip = 9 apply + 6 skip
- **Step 3 適用**: 9 件 (P1+A1+A2+P2+P4+P5+P10+A3+A5) を design.md に Edit 適用 + Decision 6 追加 (design-review revalidation triggers 集約)、Change Log v1.1 で記録

V4 metric:
- 検出件数: 15 件 (primary 10 + adversarial 5)
- 採択率 (must_fix 比率): **20.0%** (3/15)
- 過剰修正比率 (do_not_fix 比率): **40.0%** (6/15)
- should_fix 比率: **40.0%** (6/15)
- judgment override 件数: 3 件 (P3 / P9 / A4 で ignored_impact downgrade)
- primary↔judgment disagreement: 4 件 (P1 WARN→must_fix, P2 INFO→should_fix, P4 INFO→should_fix, P10 WARN→should_fix)
- adversarial↔judgment agreement: 高 (must_fix 3 件全 adversarial ERROR/WARN と一致、A2 ERROR は disagreement 1 件 = adversarial counter で do_not_fix 推奨 → judgment must_fix 維持)
- subagent wall-clock: ~244s (adversarial 122s + judgment 122s、3 spec で最短、context 累積 efficiency)

### 3 spec 累計 V4 metric trend

| metric | foundation | design-review | dogfeeding | trend |
|--------|------------|---------------|------------|-------|
| 検出件数 | 16 | 17 | 15 | 安定 (15-17) |
| 採択率 | 0% | 23.5% | 20.0% | foundation 0 → 大幅改善 (+20-23pt) |
| 過剰修正比率 | 81.25% | 58.8% | 40.0% | **連続改善** (-22pt → -19pt) |
| should_fix 比率 | 18.75% | 17.6% | 40.0% | dogfeeding で escalate 増 (consumer 視点で context-dependent decisions 多) |
| subagent wall-clock | ~293s | ~255s | ~244s | **連続短縮** (-38s → -11s、context 累積 efficiency) |

3 spec 累計で過剰修正比率が連続改善 (81% → 59% → 40%)、V4 protocol 構造的有効性 + design phase ablation framing が 3 spec 連続再現で実証。H1 ≤ 20% は dogfeeding で接近 (40%、まだ未達だが改善方向)、H3 ≥ 50% も 3 spec で 0% → 23.5% → 20.0% で改善方向。最終 comparison-report (Phase A 終端時、A-2 dogfeeding 実完走後) で req+design 累計集計予定。

## Risks & Mitigations

- **Risk 1**: dr-design treatment flag 対応の design-review revalidation cycle 発生 = 本 spec design approve → design-review v1.2 → 本 spec implementation phase 順序遵守必要 → 本 spec implementation phase 着手前 design-review revalidation 完了確認
- **Risk 2**: A2 fix の condition (c) 機械評価 logic が JSONL log content 依存 = adversarial subagent 出力 yaml format が V4 §1.5 prompt 規定通りでない場合 logic 失敗 → V4 §1.5 prompt format check + adversarial 出力 schema validate を implementation phase で test
- **Risk 3**: Spec 6 並走による design.md commit hash 変動 = ablation 公平性損失 → P10 fix で Round 開始時 commit hash 固定推奨手順、metric_extractor で variance 検出 + comparison-report 併記
- **Risk 4**: 30 review session の wall-clock cost (cost 3 倍) が user manual flow で疲労 = 8 月 timeline failure 基準 (Decision 5) で監視 + Phase B fork hold 判定の補助根拠化
- **Risk 5**: phase_b_judgment.py の comparison-report.md append が既存 §1-11 を破壊する risk → P5 fix で section ID idempotent + append-only enforcement
- **Risk 6**: figure data file structure (P4 fix で minimum 6 field 規約) が論文 figure 描画側 (Phase 3 別 effort) と乖離 = implementation phase で論文 figure 構造 review + 必要に応じて design fix
- **Risk 7**: 8 月 timeline failure 時 (Decision 5) = Phase B fork hold + 追加 dogfeeding 範囲記述 (本 spec scope 外、別 spec 責務) → comparison-report 併記で透明性確保

## References

- foundation/design.md v1.1 (commit `2e5637d`) — upstream Layer 1 + 共通 schema + portable artifact
- foundation/research.md v1.0
- foundation/requirements.md (V4 redo broad approved)
- design-review/design.md v1.1 (commit `76a1eb1`) — upstream 3 skills + Layer 2 + forced_divergence prompt + Foundation Integration、本 spec が treatment flag + timestamp 必須付与 + commit_hash payload 受領を revalidation trigger として要請
- design-review/research.md v1.0
- design-review/requirements.md (V4 redo broad approved)
- `.kiro/methodology/v4-validation/v4-protocol.md` v0.3 final
- `.kiro/methodology/v4-validation/comparison-report.md` v0.1 (req phase V4 redo broad evidence + 本 spec が Phase B fork 判定 §12 を append、section ID = `phase-b-fork-judgment-v1`)
- `.kiro/methodology/v4-validation/evidence-catalog.md` v0.3 (V3 baseline + V4 attempt 1 + V4 redo broad、本 spec evidence 追加)
- `.kiro/methodology/v4-validation/data-acquisition-plan.md` (Phase 2 達成項目 checkbox 更新対象)
- `.kiro/drafts/dual-reviewer-draft.md` v0.3 (canonical design source)
- `.kiro/specs/dual-reviewer-dogfeeding/{brief.md, requirements.md}` (V4 redo broad approved)
- `.kiro/specs/rwiki-v2-perspective-generation/` (Spec 6、本 spec dogfeeding target、並走 spec)
- `.kiro/steering/{product.md, tech.md, structure.md}` (Rwiki 既存規約、TDD 規律 + Severity 4 水準 + 2 スペースインデント)
- memory `feedback_design_review_v3_adversarial_subagent.md` (V3 試験運用 evidence、本 spec が一般化対象)
- memory `feedback_review_v4_necessity_judgment.md` (未起草、12th 以降記録予定)
- memory `feedback_design_decisions_record.md` — ADR 代替 design.md 本文 + change log 二重記録
- memory `feedback_choice_presentation.md` — 物理 layout 選択時 concrete tree + 比較表 + 判断軸 (本 spec で X1 vs X3 適用)
- JSON Schema Draft 2020-12 — schema standard

## Change Log

- **v1.0** (2026-05-01 12th セッション、本 file 初版): A-1 design phase (dogfeeding) 完了時の research log + 6 design decisions + V4 review gate outcomes (15 件検出、9 件 apply / 6 件 skip) + 3 spec 累計 V4 metric trend (過剰修正比率 連続改善 81% → 59% → 40%) + risks + references を集約
