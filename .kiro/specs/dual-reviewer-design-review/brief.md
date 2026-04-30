# Brief: dual-reviewer-design-review

> 出典: `.kiro/drafts/dual-reviewer-draft.md` v0.3 §2.1 / §2.3 / §2.6 / §2.7 / §2.10 / §3 / §4 (V4 protocol §1.2 整合 + judgment subagent + 3 役構成 reflect)

## Problem

dual-reviewer の主機能 = 設計 phase の 10 ラウンド review を **3 subagent 構成** (primary + adversarial + judgment、V4 protocol §1.2 整合) で実行 + Chappy P0 3 件 (`fatal_patterns.yaml` 強制照合 / forced divergence prompt / `impact_score`) + V4 protocol §1 機能 5 件 (judgment subagent / 必要性 5-field schema / 5 条件判定ルール / 3 ラベル分類 + recommended_action / 修正否定試行 prompt) 組込 + JSONL 構造化記録 (`impact_score` 3 軸 + 失敗構造観測軸 3 要素 + 修正必要性判定軸 V4 §1.3 整合)。`dual-reviewer-foundation` の Layer 1 を活用しつつ Layer 2 design extension を実装し、Spec 6 dogfeeding で運用可能なレベルの **4 skill prototype** を構築する必要。

## Current State

- ドラフト v0.3 §2.1 で Layer 2 design extension 仕様確定 (10 ラウンド + Phase 1 escalate 3 メタパターン + Step A/B/C/D 構造 V4 §1.2 整合)
- ドラフト v0.3 §2.6 で Chappy P0 3 件採用確定 (`fatal_patterns.yaml` 強制照合 / `impact_score` 3 軸 / forced divergence prompt) + V4 protocol との役割分離確定 (forced divergence は adversarial、修正否定試行は judgment subagent)
- ドラフト v0.3 §2.7 で Quota 設計確定 (event-triggered 介入の核)
- ドラフト v0.3 §2.10.3 で 拡張ログ schema 2 軸並列確定 (失敗構造観測軸 3 要素 + 修正必要性判定軸 V4 §1.3 整合)
- ドラフト v0.3 §4.1 で B-1.0 minimum 4 skills 確定 (`dr-init` + `dr-design` + `dr-log` + `dr-judgment`、V4 protocol §1.2 整合)
- ドラフト v0.3 §4.3 で V4 protocol §1 機能 5 件確定 (judgment subagent / 必要性 5-field schema / 5 条件判定ルール / 3 ラベル分類 / 修正否定試行 prompt)
- `dual-reviewer-foundation` spec で共通 schema (2 軸並列) + Layer 1 framework + seed/fatal patterns yaml + V4 §5.2 prompt template 整備予定
- `dr-design` / `dr-log` / `dr-judgment` skill は未実装

## Desired Outcome

dual-reviewer の主 review 機能が稼働可能な状態:

- `dr-design` skill が 10 ラウンド orchestration + adversarial subagent dispatch + judgment subagent dispatch (= `dr-judgment` skill 起動) + Chappy P0 全機能 + V4 protocol §1 機能を実行
- `dr-log` skill が JSONL 構造化記録 (`impact_score` 3 軸 + 失敗構造観測軸 3 要素 + 修正必要性判定軸 V4 §1.3 整合) を全 finding に必須付与
- `dr-judgment` skill が V4 §5.2 prompt template 内蔵で primary + adversarial 検出結果 + counter-evidence を input に必要性 5-field 評価 + 5 条件判定ルール適用 + 3 ラベル分類確定 + recommended_action 出力
- Layer 2 design extension が 10 ラウンド + escalate 必須条件 + Phase 1 escalate 3 メタパターン + Step 1c (judgment) を実装
- Spec 6 dogfeeding (`dual-reviewer-dogfeeding` spec) に適用可能なレベル (sample 1 round 通過確認まで) で動作

## Approach

- `dr-design` skill = Layer 2 design extension 実装 + 10 ラウンド orchestration + adversarial subagent dispatch + judgment subagent dispatch (= `dr-judgment` skill 起動) + Chappy P0 全機能 (`fatal_patterns.yaml` 強制照合 quota + forced divergence prompt template) + V4 protocol §1 機能 (必要性 5-field 評価結果 受領 + 3 ラベル分類確定) + Step 1a/1b/1c (judgment) 分離 + Step 1b-v 自動深掘り 5 切り口 + escalate 必須条件 5 種
- forced divergence prompt 文言素案 (adversarial 用): "Identify one tacit premise of the primary reviewer's reasoning, replace it with a plausible alternative premise, and evaluate whether the same conclusion still holds." (本 spec design phase で最終確定、英語固定 = foundation V4 §5.3 整合)
- `dr-judgment` skill = V4 protocol §5.2 prompt template (judgment subagent dispatch prompt 全文、英語固定、foundation portable artifact から import) を内蔵 + judgment subagent 起動 + 必要性 5-field 評価 + 5 条件判定ルール (V4 §1.4.1) 適用 + semi-mechanical mapping default 7 種 (V4 §1.4.2) + 3 ラベル分類 + recommended_action + `override_reason` 出力 (= V4 §1.6 yaml schema)
- `dr-log` skill = JSONL 構造化記録 + `impact_score` 3 軸 schema + 失敗構造観測軸 3 要素 (`miss_type` / `difference_type` / `trigger_state`) + 修正必要性判定軸 (V4 §1.3 必要性 5-field + `fix_decision.label` + `recommended_action` + `override_reason`) + foundation 提供の共通 schema (2 軸並列) を validate に使用
- subagent dispatch = Claude Code Agent tool で primary (Opus) / adversarial (Sonnet) / judgment (Sonnet) を `model` parameter で切替、API コール不要 (subagent 構成段階 B-1、V4 §1.2 option C 採用)

## Scope

- **In**:
  - `dr-design` skill (10 ラウンド orchestration + Layer 2 design extension + judgment subagent dispatch)
  - `dr-log` skill (JSONL 構造化記録、2 軸並列 schema)
  - `dr-judgment` skill (V4 §5.2 prompt template 内蔵、judgment subagent 起動 + 必要性 5-field 評価 + 5 条件判定 + 3 ラベル分類 + recommended_action + override_reason 出力)
  - Chappy P0 3 件全件実装:
    - `fatal_patterns.yaml` 強制照合 quota
    - `impact_score` 3 軸 schema (post-run JSONL)
    - forced divergence prompt template (**adversarial** subagent prompt の 1 行追加)
  - V4 protocol §1 機能 5 件全件実装:
    - judgment subagent (= `dr-judgment` skill、V4 §1.2 option C)
    - 必要性 5-field schema (`requirement_link` / `ignored_impact` / `fix_cost` / `scope_expansion` / `uncertainty`、V4 §1.3、semi-mechanical mapping default 7 種付き)
    - 5 条件判定ルール (V4 §1.4.1)
    - 3 ラベル分類 (must_fix / should_fix / do_not_fix、V4 §1.6) + recommended_action
    - 修正否定試行 prompt (judgment subagent prompt 内、V4 §5.2、adversarial の forced divergence と役割分離 = 判定 5-C)
  - 失敗構造観測軸 3 要素実装 (`miss_type` / `difference_type` / `trigger_state` の LLM 自己ラベリング prompt + JSONL 記録)
  - 修正必要性判定軸実装 (`fix_decision.label` + `recommended_action` + `override_reason` を全 finding に必須付与)
  - Step 1a/1b/1c (judgment) 分離 + Step 1b-v 自動深掘り 5 切り口
  - escalate 必須条件 5 種 + Phase 1 escalate 3 メタパターン
  - bias 抑制 quota (formal challenge / 検出漏れ / Phase 1 同型探索 / 厳しく検証 5 種)
- **Out**:
  - foundation (別 spec、Layer 1 framework + 共通 schema + seed/fatal patterns yaml)
  - dogfeeding 適用 (別 spec、Spec 6 への適用 + 対照実験)
  - tasks/req/impl phase extension (B-1.x で別 spec)
  - cycle automation (`dr-extract` / `dr-update`、B-1.2)
  - multi-vendor support (B-2)
  - hypothesis generator role 3 体構成 (B-2)
  - B-1.x 拡張 schema (`decision_path` / `skipped_alternatives` / `bias_signal`)
  - 並列処理 + 整合性 Round 6 task の本格実装 (現状は単純 dual の逐次運用、並列は B-1.x 以降検討)

## Boundary Candidates

- design phase review 実行 (`dr-design`) と log 記録 (`dr-log`) の境界 (本 spec 内で 2 skill に分離)
- Chappy P0 機能 (本 spec) と Chappy 保留機能 (B-2 以降、別 spec) の境界
- Layer 2 design extension (本 spec) と他 phase extension (tasks/req/impl、B-1.x で別 spec) の境界
- B-1.0 拡張 schema (本 spec) と B-1.x 拡張 schema (B-1.x で別 spec) の境界

## Out of Boundary

- tasks phase / requirements phase / implementation phase の review 実行 (B-1.x で別 spec)
- cycle automation (Run-Log-Analyze-Update の自動化、B-1.2)
- multi-vendor support (GPT/Gemini/etc.、B-2 以降)
- hypothesis generator role 3 体構成 (B-2 以降)
- 並列処理本格実装 + 整合性 Round 6 task (B-1.x 以降検討)
- B-1.x 拡張 schema 実装 (`decision_path` / `skipped_alternatives` / `bias_signal`)
- 論文ドラフト執筆 (Phase 3 = 7-8月、別 effort)

## Upstream / Downstream

- **Upstream**: `dual-reviewer-foundation` (Layer 1 framework + 共通 JSON schema + `seed_patterns.yaml` + `fatal_patterns.yaml` に依存)
- **Downstream**: `dual-reviewer-dogfeeding` (本 spec 完成後に Spec 6 適用 + 対照実験)

## Existing Spec Touchpoints

- **Extends**: なし
- **Adjacent**: `dual-reviewer-foundation` (依存元、本 spec が utilizing)、`rwiki-v2-perspective-generation` (Spec 6、本 spec の dogfeeding 対象だが本 spec では実適用しない、`dual-reviewer-dogfeeding` spec で実施)

## Constraints

- Phase A scope = Rwiki repo 内 prototype 段階、Phase B 独立 fork は本 spec 対象外
- subagent 構成 = **3 役** (`primary_reviewer` Opus + `adversarial_reviewer` Sonnet + `judgment_reviewer` Sonnet、V4 §1.2 option C 整合)、Claude family rotation / multi-vendor は B-1.x / B-2 で別途
- forced divergence (adversarial 用) と修正否定試行 (judgment 用、V4 §5.2 既存) は役割分離 (判定 5-C)、prompt 重複なし
- log schema は B-1.0 minimum 2 軸並列 (失敗構造観測軸 = `miss_type` / `difference_type` / `trigger_state` 3 string enum + 修正必要性判定軸 = V4 §1.3 必要性 5-field + `fix_decision.label` + `recommended_action` + `override_reason`)、B-1.x 自由記述 3 要素は scope 外
- forced divergence prompt の最終文言は本 spec の design phase で確定、ドラフト v0.3 §2.6 の素案を base、英語固定 (foundation V4 §5.3 整合)
- 並列処理は B-1.0 では実装せず単純逐次運用 (並列 + 整合性 Round 6 task は B-1.x 以降)
