# Brief: dual-reviewer-design-review

> 出典: `.kiro/drafts/dual-reviewer-draft.md` v0.3 §2.1 / §2.3 / §2.6 / §2.7 / §2.10 / §3 / §4

## Problem

dual-reviewer の主機能 = 設計 phase の 10 ラウンド review を adversarial subagent 構成で実行 + Chappy P0 機能 (`fatal_patterns.yaml` 強制照合 / forced divergence prompt / `impact_score`) 組込 + JSONL 構造化記録 (`impact_score` 3 軸 + B-1.0 拡張 schema 4 要素)。`dual-reviewer-foundation` の Layer 1 を活用しつつ Layer 2 design extension を実装し、Spec 6 dogfeeding で運用可能なレベルの prototype を構築する必要。

## Current State

- ドラフト v0.3 §2.1 で Layer 2 design extension 仕様確定 (10 ラウンド + Phase 1 escalate 3 メタパターン)
- ドラフト v0.3 §2.6 で Chappy P0 3 件採用確定 (`fatal_patterns.yaml` 強制照合 / `impact_score` 3 軸 / forced divergence prompt)
- ドラフト v0.3 §2.7 で Quota 設計確定 (event-triggered 介入の核)
- ドラフト v0.3 §2.10.3 で B-1.0 拡張 schema 4 要素確定 (`miss_type` / `difference_type` / `trigger_state` / `phase1_meta_pattern`)
- `dual-reviewer-foundation` spec で共通 schema + Layer 1 framework + seed/fatal patterns yaml 整備予定
- `dr-design` / `dr-log` skill は未実装

## Desired Outcome

dual-reviewer の主 review 機能が稼働可能な状態:

- `dr-design` skill が 10 ラウンド orchestration + adversarial subagent dispatch + Chappy P0 全機能を実行
- `dr-log` skill が JSONL 構造化記録 (`impact_score` 3 軸 + B-1.0 拡張 schema 4 要素) を実行
- Layer 2 design extension が 10 ラウンド + escalate 必須条件 + Phase 1 escalate 3 メタパターンを実装
- Spec 6 dogfeeding (`dual-reviewer-dogfeeding` spec) に適用可能なレベル (sample 1 round 通過確認まで) で動作

## Approach

- `dr-design` skill = Layer 2 design extension 実装 + 10 ラウンド orchestration + adversarial subagent dispatch (Claude Code Agent tool、`primary_model` = Opus / `adversarial_model` = Sonnet) + Chappy P0 全機能 (`fatal_patterns.yaml` 強制照合 quota + forced divergence prompt template) + Step 1a/1b 分離 (軽微 / 構造的) + Step 1b-v 自動深掘り 5 切り口 + escalate 必須条件 5 種
- forced divergence prompt 文言素案: "Identify one tacit premise of the primary reviewer's reasoning, replace it with a plausible alternative premise, and evaluate whether the same conclusion still holds." (本 spec design phase で最終確定)
- `dr-log` skill = JSONL 構造化記録 + `impact_score` 3 軸 schema (severity / fix_cost / downstream_effect) + B-1.0 拡張 schema (`miss_type` 6 種 enum / `difference_type` 6 種 enum / `trigger_state` 3 軸 enum object 各 applied | skipped の 2 値 enum / `phase1_meta_pattern` 3 値 enum + null = norm_range_preemption / doc_impl_inconsistency / norm_premise_ambiguity / null、cross-spec contract 補強 field、escalate 検出 finding にのみ付与) + foundation 提供の共通 schema を validate に使用
- subagent dispatch = Claude Code Agent tool で primary (Opus) と adversarial (Sonnet) を `model` parameter で切替、API コール不要 (subagent 構成段階 B-1)

## Scope

- **In**:
  - `dr-design` skill (10 ラウンド orchestration + Layer 2 design extension)
  - `dr-log` skill (JSONL 構造化記録)
  - Chappy P0 3 件全件実装:
    - `fatal_patterns.yaml` 強制照合 quota
    - `impact_score` 3 軸 schema (post-run JSONL)
    - forced divergence prompt template (adversarial subagent prompt の 1 行追加)
  - B-1.0 拡張 schema 4 要素実装 (`miss_type` / `difference_type` / `trigger_state` / `phase1_meta_pattern` の LLM 自己ラベリング prompt + JSONL 記録)
  - Step 1a/1b 分離 + Step 1b-v 自動深掘り 5 切り口
  - escalate 必須条件 5 種 + Phase 1 escalate 3 メタパターン
  - bias 抑制 quota (Layer 1 base 5 種 = formal challenge / 検出漏れ / Phase 1 同型探索 / `fatal_patterns.yaml` 強制照合 / forced divergence は `dual-reviewer-foundation` で定義、Layer 2 design extension で追加 = 厳しく検証 5 種 / escalate 必須条件 5 種。本 spec は継承 + Layer 2 拡張部の発動実装、draft v0.3 §2.7)
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

- **Upstream**: `dual-reviewer-foundation` (Layer 1 framework + 共通 JSON schema + `seed_patterns.yaml` + `seed_patterns_examples.md` + `fatal_patterns.yaml` + `dr-init` skill (`.claude/skills/dr-init/SKILL.md` 形式) に依存)
- **Downstream**: `dual-reviewer-dogfeeding` (本 spec 完成後に Spec 6 適用 + 対照実験)

## Existing Spec Touchpoints

- **Extends**: なし
- **Adjacent**: `dual-reviewer-foundation` (依存元、本 spec が utilizing)、`rwiki-v2-perspective-generation` (Spec 6、本 spec の dogfeeding 対象だが本 spec では実適用しない、`dual-reviewer-dogfeeding` spec で実施)

## Constraints

- Phase A scope = Rwiki repo 内 prototype 段階、Phase B 独立 fork は本 spec 対象外
- subagent 構成 = 単純 dual のみ (Opus + Sonnet)、Claude family rotation / multi-vendor は B-1.x / B-2 で別途
- log schema は B-1.0 minimum 4 要素 (`miss_type` 6 種 enum / `difference_type` 6 種 enum / `trigger_state` 3 軸 enum object 各 applied | skipped の 2 値 enum / `phase1_meta_pattern` 3 値 enum + null = norm_range_preemption / doc_impl_inconsistency / norm_premise_ambiguity / null、cross-spec contract 補強 field、escalate 検出 finding にのみ付与)、B-1.x 自由記述 3 要素は scope 外
- forced divergence prompt の最終文言は本 spec の design phase で確定、ドラフト v0.3 §2.6 の素案を base
- 並列処理は B-1.0 では実装せず単純逐次運用 (並列 + 整合性 Round 6 task は B-1.x 以降)
