# Brief: dual-reviewer-foundation

> 出典: `.kiro/drafts/dual-reviewer-draft.md` v0.3 §2.1 / §2.7 / §2.9 / §2.10.3 / §3 / §4 (V4 protocol §1.2 整合 reflect)

## Problem

dual-reviewer (LLM 設計レビュー方法論 v3 一般化 package) を Layer 1/2/3 三層構造で組み立てるには、phase 横断の framework + project bootstrap + 共通 JSON schema + initial seed (23 事例 + fatal patterns) が揃っている必要がある。これらが先行整備されないと、`dr-design` / `dr-log` skill が単独で機能できず、Phase A-2 (Spec 6 dogfeeding) も実行不可。

## Current State

- ドラフト v0.2 §2.1 で Layer 1 framework 骨組み確定 (Step A/B/C 構造 + bias 抑制 quota + pattern schema + 介入 framework)
- ドラフト v0.2 §2.9 で 23 事例 retrofit 仕様確定 (`seed_patterns.yaml`、Rwiki 由来、固有名詞付きで OK)
- ドラフト v0.2 §2.6 で Chappy P0 採用 3 件確定、うち `fatal_patterns.yaml` 8 種固定確定
- ドラフト v0.2 §2.10.3 で B-1.0 拡張 schema (`miss_type` / `difference_type` / `trigger_state`) の 3 要素確定
- 実装は未着手 = 全要素を本 spec で実装する

## Desired Outcome

dual-reviewer の core 基盤が稼働可能な状態:

- Layer 1 framework (Step A/B/C + bias 抑制 quota + pattern schema) が単体動作可能
- `dr-init` skill が project bootstrap (`.dual-reviewer/` 構造 + config 雛形生成) を実行可能
- 共通 JSON schema (review_case / finding / impact_score / B-1.0 拡張 schema) が validate 可能
- `seed_patterns.yaml` (23 事例 retrofit) と `fatal_patterns.yaml` (8 種固定) が同梱され読み込み可能
- `dual-reviewer-design-review` / `dual-reviewer-dogfeeding` が依存する全要素を提供

## Approach

- Layer 1 = Step A/B/C/D 構造 (primary detection → adversarial review → judgment → integration、V4 protocol §1.2 整合) + bias 抑制 quota (formal challenge / 検出漏れ / Phase 1 同型探索) + 中程度 granularity の pattern schema を skeleton 実装
- `dr-init` = project bootstrap、`.dual-reviewer/config.yaml` 生成 (`primary_model` / `adversarial_model` / `judgment_model` / `lang` 4 field)、Layer 3 (project 固有) の placeholder ディレクトリ生成
- 共通 JSON schema = 2 軸並列定義: (a) **失敗構造観測軸** = review_case / finding / impact_score 3 軸 (severity / fix_cost / downstream_effect) + B-1.0 拡張 schema (`miss_type` 6 enum / `difference_type` 6 enum / `trigger_state` 3 string enum field) (b) **修正必要性判定軸** = V4 §1.3 整合 (必要性 5-field = `requirement_link` / `ignored_impact` / `fix_cost` / `scope_expansion` / `uncertainty` + `fix_decision.label` (must_fix/should_fix/do_not_fix) + `recommended_action` (fix_now/leave_as_is/user_decision) + `override_reason`)
- `seed_patterns.yaml` = 23 事例 retrofit (`feedback_review_judgment_patterns.md` を yaml schema 化、Rwiki 固有名詞付きで OK、generalization は Phase B-1.0 release prep に統合 #3)
- `fatal_patterns.yaml` = 8 種固定 (sandbox escape / data loss / privilege escalation / infinite retry / deadlock / path traversal / secret leakage / destructive migration)
- V4 §5.2 prompt template = judgment subagent dispatch 用 canonical 英語 prompt 全文を foundation install location 直下に portable artifact として配置 (downstream `dr-judgment` skill が import)

## Scope

- **In**:
  - Layer 1 framework (Step A/B/C/D + bias 抑制 quota + pattern schema、V4 protocol §1.2 整合)
  - `dr-init` skill (project bootstrap、4 skill 構成想定で `judgment_model` config field 含む)
  - 共通 JSON schema 2 軸並列: (a) 失敗構造観測軸 (review_case / finding / impact_score 3 軸 + B-1.0 拡張 schema 3 要素) (b) 修正必要性判定軸 (V4 §1.3 必要性 5-field + `fix_decision.label` + `recommended_action` + `override_reason`)
  - `seed_patterns.yaml` (23 事例 retrofit、Rwiki 固有名詞付きで OK)
  - `fatal_patterns.yaml` (致命級 8 種固定)
  - V4 §5.2 prompt template (judgment subagent 用 canonical 英語 prompt 全文、foundation portable artifact、downstream `dr-judgment` import 元)
- **Out**:
  - `dr-design` skill (`dual-reviewer-design-review` spec)
  - `dr-log` skill (`dual-reviewer-design-review` spec)
  - `dr-judgment` skill (`dual-reviewer-design-review` spec、本 spec は V4 §5.2 prompt template の foundation portable artifact 配置のみ責務、skill 実装は別 spec)
  - Layer 2 phase extension (design / tasks / req / impl)
  - B-1.x skills (`dr-tasks` / `dr-requirements` / `dr-impl` / `dr-extract` / `dr-validate` / `dr-update` / `dr-translate`)
  - cycle automation (Run-Log-Analyze-Update)
  - 並列処理 + 整合性 Round
  - multi-vendor / multi-subagent / hypothesis generator (B-2 以降)
  - B-1.x 拡張 schema (`decision_path` / `skipped_alternatives` / `bias_signal`)

## Boundary Candidates

- Layer 1 framework 骨組み (本 spec) と Layer 2 phase extension (design extension は `dual-reviewer-design-review` spec、他 phase extension は B-1.x で別 spec) の境界
- project 共通 (foundation) と review-specific (design-review) の境界
- `seed_patterns.yaml` データ (本 spec) と pattern matching ロジック (design extension 内、`dual-reviewer-design-review` spec) の境界
- 共通 JSON schema 定義 (本 spec) と JSONL 記録 logic (`dr-log` skill、`dual-reviewer-design-review` spec) の境界

## Out of Boundary

- review 実行ロジック (`dual-reviewer-design-review` spec の `dr-design`)
- JSONL 記録ロジック (`dual-reviewer-design-review` spec の `dr-log`)
- dogfeeding 適用 (`dual-reviewer-dogfeeding` spec)
- Phase B 独立 fork (本 spec の対象外、Rwiki repo 内 prototype 段階のみ)
- generalization (固有名詞除去、Phase B-1.0 release prep)
- npm package 化 (Phase B-1.0)

## Upstream / Downstream

- **Upstream**: なし (foundation = 依存なし)
- **Downstream**: `dual-reviewer-design-review` / `dual-reviewer-dogfeeding`

## Existing Spec Touchpoints

- **Extends**: なし
- **Adjacent**: 既存 Rwiki spec (Spec 0-7) と機能的に独立、参照しない (dual-reviewer は Rwiki と独立した方法論 package)。Phase A 期間中は Rwiki repo 内に prototype 配置するが、cross-spec dependency なし

## Constraints

- Phase A scope = Rwiki repo 内 prototype 段階、Phase B 独立 fork は本 spec 対象外
- 配置: `scripts/dual_reviewer_prototype/` または `.kiro/specs/dual-reviewer/prototype/` (A-1 prototype 実装時に確定)
- 23 事例 retrofit は Rwiki 固有名詞付きで OK (generalization は Phase B-1.0 release prep に統合、#3 採用)
- B-1.0 minimum scope (4 skills の 1 つ = `dr-init`)、残り 6 skills は B-1.x 段階追加 (4 skills = `dr-init` + `dr-design` + `dr-log` + `dr-judgment`、V4 protocol §1.2 整合)
- subagent 構成 = 3 役 (`primary_reviewer` Opus + `adversarial_reviewer` Sonnet + `judgment_reviewer` Sonnet、V4 §1.2 option C)
- `terminology.yaml` seed entries 蓄積は A-2 dogfeeding 中、目標 30-50 は B-1.2 まで延伸
