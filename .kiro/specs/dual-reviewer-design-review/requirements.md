# Requirements Document

## Introduction

`dual-reviewer-design-review` は dual-reviewer (LLM 設計レビュー方法論 v3 一般化 package) の主 review 機能を提供する spec である。本 spec の成果物 = `dr-design` skill + `dr-log` skill + `dr-judgment` skill + Layer 2 design extension + forced_divergence prompt template (最終文言確定 = 本 spec design phase 責務)。これらが揃って初めて `dual-reviewer-dogfeeding` spec が Spec 6 (rwiki-v2-perspective-generation) design に dual-reviewer prototype を実適用 + 3 系統対照実験を実行できる。

Phase A scope = Rwiki repo 内 prototype 段階。B-1.0 minimum 4 skills (`dr-init` / `dr-design` / `dr-log` / `dr-judgment`、V4 protocol §1.2 option C 整合 = 3 subagent 構成) のうち本 spec は 3 skills (`dr-design` / `dr-log` / `dr-judgment`) を担当し、残 1 skill (`dr-init`) は `dual-reviewer-foundation` spec で実装される前提。

本 spec は V4 protocol v0.3 final (`.kiro/methodology/v4-validation/v4-protocol.md`) と整合する: 3 subagent 構成 (primary + adversarial + judgment) を skill orchestration に組込み、必要性 5-field schema + 5 条件判定ルール (V4 §1.4.1) + semi-mechanical mapping default 7 種 (V4 §1.4.2) + 3 ラベル分類 (must_fix / should_fix / do_not_fix、V4 §1.6) + recommended_action + override_reason を全 finding に必須付与し、forced_divergence (adversarial 担当、結論成立性試行) と修正否定試行 (judgment 担当、V4 §5.2 既存組込、修正 proposal 必要性否定) を役割分離する (判定 5-C 整合)。

## Boundary Context

- **In scope** (本 spec で提供):
  - `dr-design` skill (10 ラウンド orchestration + Layer 2 design extension + adversarial subagent dispatch + judgment subagent dispatch + Chappy P0 全機能 + V4 §1 機能 5 件 + Step 1a/1b/1b-v/1c 分離 + escalate 必須条件 5 種)
  - `dr-log` skill (JSONL 構造化記録 + foundation 提供 共通 JSON schema 2 軸並列 validate)
  - `dr-judgment` skill (V4 §5.2 prompt template 内蔵 + judgment subagent dispatch + 必要性 5-field 評価 + 5 条件判定ルール + semi-mechanical mapping default 7 種 + 3 ラベル分類 + recommended_action + override_reason 出力)
  - Layer 2 design extension (10 ラウンド + Phase 1 escalate 3 メタパターン + design phase 固有 bias 抑制 quota)
  - Foundation Integration (`dual-reviewer-foundation` 提供の Layer 1 framework / 共通 schema 2 軸並列 / seed_patterns.yaml / fatal_patterns.yaml / V4 §5.2 prompt template / override 階層 を import 規約に従い使用)
  - forced_divergence prompt template (最終文言確定、英語固定、本 spec design phase 責務 = foundation Req 7 AC4 整合)
  - Phase A Scope Constraints (3 役 subagent / 単純逐次運用 / B-1.0 minimum schema / sample 1 round 通過レベル / Phase B fork out of scope)

- **Out of scope** (本 spec 対象外):
  - foundation 自体 (`dual-reviewer-foundation` spec、Layer 1 framework + 共通 schema + seed/fatal patterns yaml + V4 §5.2 prompt template + dr-init skill の責務)
  - dogfeeding 適用 (`dual-reviewer-dogfeeding` spec、Spec 6 への実適用 + 3 系統対照実験 = single + dual + dual+judgment)
  - tasks / requirements / implementation phase の review extension (B-1.x で別 spec)
  - cycle automation skills (`dr-extract` / `dr-update`、B-1.2 release lifecycle)
  - multi-vendor support (GPT / Gemini 等、B-2 release lifecycle)
  - hypothesis generator role 3 体構成 (Chappy 保留 1、B-2 以降)
  - B-1.x 拡張 schema (`decision_path` / `skipped_alternatives` / `bias_signal`、自由記述 + 内省、A-2 後半 〜 Phase 3 で実装)
  - 並列処理本格実装 + 整合性 Round 6 task (B-1.x 以降)
  - Phase B 独立 fork (npm package 化 / GitHub repo 公開 / collective learning network)
  - 全 10 ラウンド完走 + 対照実験 (`dual-reviewer-dogfeeding` spec 責務、本 spec の動作確認は sample 1 round 通過レベル)

- **Adjacent expectations** (隣接 spec / 既存 system からの期待):
  - `dual-reviewer-foundation` から以下を import する前提: (a) Layer 1 framework (Step A/B/C/D + bias 抑制 quota + pattern schema + override 階層 Layer 3 > Layer 2 > Layer 1) (b) 共通 JSON schema 2 軸並列 (失敗構造観測軸 3 要素 + 修正必要性判定軸 V4 §1.3 整合) (c) `./patterns/seed_patterns.yaml` 23 件 (d) `./patterns/fatal_patterns.yaml` 8 種固定 (e) V4 §5.2 judgment subagent prompt template (foundation portable artifact、`./prompts/judgment_subagent_prompt.txt`) (f) JSON Schema files (`./schemas/` directory)
  - `dual-reviewer-dogfeeding` は本 spec の 3 skills を Spec 6 design に適用 + 3 系統対照実験 (single + dual + dual+judgment) で運用する前提、本 spec は 3 skills の動作可能性確認 (sample 1 round 通過) のみを責務とする
  - 既存 Rwiki spec (Spec 0-7) とは機能的に独立、Spec 6 への実適用は本 spec ではなく `dual-reviewer-dogfeeding` spec で実施 (本 spec は適用 mechanism + skill 動作確認のみ提供)

## Requirements

### Requirement 1: dr-design Skill — 10 ラウンド orchestration + Layer 2 design extension + V4 §1 機能組込

**Objective:** As a dual-reviewer 利用者 (design phase review を実行する spec author), I want `dr-design` skill が 10 ラウンド review を Step A (primary detection) → Step B (adversarial review) → Step C (judgment) → Step D (integration) の V4 §1.2 option C 構造で orchestration してほしい, so that Layer 1 framework が定義する review pipeline + V4 §1 全機能 5 件が design phase の実 review session で稼働する.

#### Acceptance Criteria

1. When user が design phase review を起動した場合, the dr-design skill shall foundation 提供の Layer 1 framework + 本 spec の Layer 2 design extension を import し、Round 1 から Round 10 までを Step A (primary detection) → Step B (adversarial review) → Step C (judgment) → Step D (integration) の V4 §1.2 option C 構造に従って sequential に実行する.
2. The dr-design skill shall, 各ラウンドの Step A (primary detection) で primary_reviewer (= `config.yaml` `primary_model` で指定された model) を使用し、Step 1a (軽微検出) + Step 1b (構造的検出 5 重検査 = 二重逆算 / Phase 1 パターン / dev-log patterns 照合 [= foundation 提供 `seed_patterns.yaml` 23 件 (foundation Req 4 AC1 整合) + Layer 3 `extracted_patterns.yaml` 蓄積分 (Phase A 開始時は空、project cycle で蓄積)] / 自己診断 / 内部論理整合) + Step 1b-v (自動深掘り判定、5 観点 + 5 切り口 negative 視点) を実行する.
3. The dr-design skill shall, 各ラウンドの Step B (adversarial review) で adversarial_reviewer subagent (= `config.yaml` `adversarial_model` で指定された model) を Claude Code Agent tool 経由で dispatch し、独立 Step 1b detection + forced_divergence prompt (Req 6 で確定する英語 prompt template、本 spec install location 直下から動的読み込み) + V4 §1.5 修正否定試行 prompt (英語固定 3 行、本 spec design phase で配置先を確定 = adversarial subagent dispatch 時 inline embed または `prompts/` 配下に別 txt として配置のいずれか、design phase で具体規約を確定) を実行する.
4. The dr-design skill shall, 各ラウンドの Step C (judgment) で `dr-judgment` skill を起動し (Req 3 整合、起動 mechanism = Claude Code skill invocation system 経由 = SKILL.md を持つ skill として invoke、本 spec design phase で具体 invocation pattern を確定)、judgment_reviewer subagent dispatch + 必要性 5-field 評価 + 5 条件判定ルール + 3 ラベル分類 + recommended_action + override_reason 確定を実行する; dr-judgment skill からの judgment 出力 yaml は Req 3 AC8 規定の返却 mechanism (skill stdout 経由 default) で受領し、Step D integration の merge input として直接参照する.
5. The dr-design skill shall, 各ラウンドの Step D (integration) で primary 検出 + adversarial 検出 + judgment subagent 出力 yaml を merge し、**user 提示用に** V4 §2.5 三ラベル提示方式 (must_fix bulk apply default / do_not_fix bulk skip default / should_fix individual review) で構造化する; ここでの「bulk apply / bulk skip default」は user が選択する操作 option を意味し、dr-design skill が自動で apply / skip を実行することを禁止する (V4 §2.5 user oversight 原則整合 = user 判断必須、自動実行は V4 設計核を破壊するため AC レベルで禁止).
6. The dr-design skill shall, Layer 1 framework が定義する bias 抑制 quota (formal challenge / 検出漏れ / Phase 1 同型探索 / 厳しく検証 5 種) を全ラウンドで event-triggered で発動し、Phase 1 escalate 3 メタパターン (規範範囲先取り / 構造的不均一 / 文書 vs 実装不整合) を Step 1b の 5 重検査内で必ず照合する.
7. The dr-design skill shall, Chappy P0 全機能 (foundation 提供の `fatal_patterns.yaml` 8 種強制照合 quota + `impact_score` 3 軸付与 + forced_divergence prompt) を全ラウンドで実行する; ここで Layer 1 framework (foundation 責務) は data + facility を first-class facility として expose し (foundation Req 1 AC7 整合)、Layer 2 design extension (本 spec 責務) は当該 quota を design phase 実行時に invoke する (= provide vs execute の役割分離、foundation Req 5 AC5 整合 = matching logic は本 spec 責務).
8. The dr-design skill shall, escalate 必須条件 5 種 (内部矛盾 / 実装不可能性 / 責務境界 / 規範範囲 / 複数選択肢 trade-off 等) を Step 1b-v 自動深掘り内 + Step 1c judgment 内で必ず適用し、`uncertainty=high` 等の trigger に応じて user 介入機会として escalate する.
9. The dr-design skill shall, Round 1-10 を単純 sequential 運用 (Round 1 → Round 2 → ... → Round 10) で動作させ、並列処理本格実装 + 整合性 Round 6 task は本 spec scope 外とする (B-1.x 以降の別 spec で実装).

### Requirement 2: dr-log Skill — JSONL 構造化記録 + 共通 schema 2 軸並列 validate

**Objective:** As a 論文化 + cycle 学習を行う maintainer, I want `dr-log` skill が全 review session の finding を foundation 提供の共通 JSON schema (2 軸並列) で validate しつつ JSONL 構造化記録してほしい, so that 失敗構造観測軸 (研究 metric) と修正必要性判定軸 (judgment 出力) の両方が後段 analyze (`dr-extract` 等、B-1.x 別 spec) で機械処理可能な形で蓄積される.

#### Acceptance Criteria

1. When the dr-design skill が finding を生成した場合, the dr-log skill shall 各 finding に対し foundation 提供の共通 schema (`review_case` / `finding` / `impact_score` 3 軸 + 失敗構造観測軸 3 要素 + 修正必要性判定軸 V4 §1.3 整合) で schema validate を実行し、validate 失敗時は fail-fast (non-zero exit signal + error report) する.
2. The dr-log skill shall, foundation install location 直下の `schemas/` 相対 directory (foundation Req 3 AC10 整合) から JSON Schema files を動的に読み込み、validate に使用する (hardcode 禁止).
3. The dr-log skill shall, 全 finding に対し finding state に応じて以下を付与する: (a) **`detected` state 全 finding 共通 (judgment subagent 起動前または起動なし運用)**: `impact_score` 3 軸 (`severity` 4 値 / `fix_cost` 3 値 / `downstream_effect` 3 値) + 失敗構造観測軸 (`miss_type` 6 enum / `difference_type` 6 enum / `trigger_state` 3 string enum field) を必須付与し、修正必要性判定軸 (必要性 5-field + `fix_decision.label` + `recommended_action` + `override_reason`) は省略可能とする (foundation Req 3 AC6 整合 = pre-judgment / detection-only state も schema validate 可能). (b) **`judged` state finding (judgment subagent 完了後)**: 上記 (a) の field 群に加え、修正必要性判定軸 (必要性 5-field + `fix_decision.label` + `recommended_action` + `override_reason` if any) を必須付与する (foundation Req 3 AC7 整合 = judged state では `fix_decision.label` required).
4. The dr-log skill shall, JSONL 形式で append-only に dev-log JSONL location 配下に記録し、1 review session = 1 line + 1 review_case object を厳守する; 具体 JSONL append target path は foundation `dr-init` skill が生成する `config.yaml` の `dev_log_path` field (= foundation `dr-init` skill が `.dual-reviewer/` directory 配下の Layer 3 placeholder location を expose、具体 path 規約は foundation design phase または `dr-init` 実装時に確定) から動的に読み取る (hardcode 禁止).
5. The dr-log skill shall, primary 自己ラベリング (`miss_type` / `trigger_state`) と adversarial 自己ラベリング (`difference_type`) を skill prompt template に組込み、各 finding 生成時に必ず 3 要素を付与する; LLM 自己診断の信頼性は aggregate 統計として意味あり、個別精度は完全信頼不可であることを log skill の責務範囲外として扱う.
6. The dr-log skill shall, schema validate 失敗時の error report で finding ID + 違反 field + 期待 enum 値 + 実際の値 を stdout に enumeration し、user が修復可能な情報を提供する.
7. The dr-log skill shall, judgment subagent を起動しない運用 (= `dual-reviewer-dogfeeding` spec 3 系統対照実験のうち single 系統 = primary のみ運用 / dual 系統 = primary + adversarial で judgment 起動なし運用) において、finding の state を `detected` として JSONL に記録し、修正必要性判定軸 (`fix_decision.label` / `recommended_action` / `override_reason`) を省略 (または primary 自己 estimate として `source: primary_self_estimate` を付与) した状態で schema validate 可能な状態を維持する; これにより 3 系統対照実験 (single + dual + dual+judgment) で同一 dr-log skill を共有でき、3 系統間で比較可能な JSONL log structure を提供する (foundation Req 3 AC6 整合).

### Requirement 3: dr-judgment Skill — V4 §5.2 prompt template 内蔵 + judgment subagent dispatch + 5 条件判定 + 3 ラベル分類

**Objective:** As a Step 1c (修正必要性判定) を実行する dr-design skill から起動される subordinate skill, I want `dr-judgment` skill が V4 §5.2 prompt template を foundation portable artifact から動的に import + judgment subagent dispatch + 必要性 5-field 評価 + 5 条件判定ルール + 3 ラベル分類 + recommended_action + override_reason 出力を担当してほしい, so that judgment 評価基準が project / phase 横断で一貫し、修正否定試行 (judgment 用、V4 §1.5) と forced_divergence (adversarial 用、本 spec Req 6) の役割分離 (判定 5-C) が skill レベルで保証される.

#### Acceptance Criteria

1. When the dr-design skill が Step 1c judgment を起動した場合, the dr-judgment skill shall foundation install location 直下の `prompts/judgment_subagent_prompt.txt` (foundation Req 6 AC1, AC9 整合) から V4 §5.2 prompt template 全文を動的に読み込み (hardcode 禁止)、judgment_reviewer subagent dispatch payload に embed する.
2. The dr-judgment skill shall, dispatch payload に primary 検出全 issue list + adversarial 検出全 issue list + adversarial counter-evidence (V4 §1.5 修正否定試行出力) + 当該 spec の requirements.md 全文 + (design phase の場合) design.md 全文 + foundation Req 6 AC4 整合の semi-mechanical mapping default 7 種 を含める; ここで「adversarial 検出全 issue list」と「adversarial counter-evidence」は adversarial subagent が 1 回の dispatch で同一 yaml 出力の **別 section** として返却する (= 2 回 dispatch は scope 外、single dispatch で 2 役割の output を分離 section で返す形式).
3. The dr-judgment skill shall, judgment_reviewer subagent (= `config.yaml` `judgment_model` で指定された model) を Claude Code Agent tool 経由で dispatch する.
4. The dr-judgment skill shall, judgment subagent 出力を V4 §1.6 yaml format で受領し、各 issue に対し `fix_decision.label` (must_fix | should_fix | do_not_fix) + 必要性 5-field (`requirement_link` / `ignored_impact` / `fix_cost` / `scope_expansion` / `uncertainty`) + `recommended_action` (fix_now | leave_as_is | user_decision) + `override_reason` (semi-mechanical mapping default override 時) が付与されていることを foundation 提供 schema で validate する.
5. The dr-judgment skill shall, 5 条件判定ルール (V4 §1.4.1 = critical impact / requirement_link+ignored_impact / scope_expansion / fix_cost vs ignored_impact / uncertainty) を順次評価し、最強条件で `fix_decision.label` を確定するよう judgment subagent prompt 内で明示する; ここで V4 §1.4.1 の `escalate` outcome (= uncertainty=high 等の trigger に応じる user 介入要請) は foundation `fix_decision.label` 3 値 enum (`must_fix` / `should_fix` / `do_not_fix`、foundation Req 3 AC5 整合) との整合のため `should_fix` + `recommended_action: user_decision` の組合せにマッピングして JSONL 記録する (= `escalate` を独立 label 値として schema 拡張せず、既存 3 値 + recommended_action で表現する; foundation 側で `fix_decision.label` enum に `escalate` を 4 値目として追加する判断は本 spec 範囲外で Step 5 cross-spec review で別途検討する).
6. The dr-judgment skill shall, semi-mechanical mapping default 7 種 (V4 §1.4.2) を judgment subagent prompt 内に保持し、subagent が default を override した場合は `override_reason` field に理由文字列を必須記録するよう prompt 内で明示する.
7. The dr-judgment skill shall, 修正否定試行 prompt (V4 §5.2 内既存組込、judgment 用) を judgment subagent prompt の必要性評価 step に保持し、Step 1c で primary 提案 fix の必要性否定を judgment subagent が実施できる状態を維持する; これは Step B (adversarial 担当) の forced_divergence (= 結論成立性試行、本 spec Req 6) とは役割分離される (判定 5-C 整合).
8. The dr-judgment skill shall, judgment subagent 出力 yaml を dr-design skill (Step D integration) に返却する; 返却 mechanism は judgment subagent 出力 yaml block を skill stdout に書き出し、dr-design skill が呼び出しコンテキストで stdout を直接読み取る方式を default とする (代替として一時ファイル path を引数で渡す方式も許容、本 spec design phase で具体 mechanism を確定); 返却された yaml により dr-log skill が JSONL 構造化記録 (修正必要性判定軸、`judged` state finding) として該当 finding に必須付与する状態を保証する.

### Requirement 4: Layer 2 Design Extension — 10 ラウンド + Phase 1 escalate 3 メタパターン + design phase 固有 bias 抑制 quota

**Objective:** As a Layer 1 framework に design phase 固有の規範を追加する maintainer, I want Layer 2 design extension が foundation Layer 1 contract (foundation Req 1 AC5 整合) に従って attach し、10 ラウンド + Phase 1 escalate 3 メタパターン + design phase 固有 bias 抑制 quota を Layer 1 framework を改変せず追加してほしい, so that design phase review が Layer 1 base に固有の構造化規範を適用できる.

#### Acceptance Criteria

1. The Layer 2 design extension shall, foundation Req 1 AC5 が定義する Layer 2 attach contract (attach 対象 entry-point file の location 規約 + identifier 形式 + 失敗 signal の 3 要素) に準拠して foundation Layer 1 framework に attach する.
2. The Layer 2 design extension shall, 10 ラウンド (Round 1-10) の review 観点を以下で固定する: Round 1 (規範範囲確認) / Round 2 (一貫性) / Round 3 (実装可能性 + アルゴリズム + 性能 統合) / Round 4 (責務境界) / Round 5 (失敗モード + 観測 統合) / Round 6 (concurrency / timing) / Round 7 (security) / Round 8 (cross-spec 整合) / Round 9 (test 戦略) / Round 10 (運用) (memory `feedback_design_review.md` 中庸統合版整合); 各ラウンドの観点は foundation Layer 1 framework が定義する pattern schema (`primary_group` + `secondary_groups`、foundation Req 1 AC3 整合) の `primary_group` entry として定義し、foundation `seed_patterns.yaml` 23 件 entry を該当 Round に関連付ける (具体 mapping は本 spec design phase で確定).
3. The Layer 2 design extension shall, Phase 1 escalate 3 メタパターン (規範範囲先取り / 構造的不均一 / 文書 vs 実装不整合) を Step 1b 5 重検査の `ii. Phase 1 パターンマッチング` で必ず照合する.
4. The Layer 2 design extension shall, design phase 固有 bias 抑制 quota (formal challenge / 検出漏れ / Phase 1 同型探索 / 厳しく検証 5 種) を Layer 1 framework の base quota に追加する形で expose し、Chappy P0 quota (`fatal_patterns.yaml` 強制照合 / `impact_score` / forced_divergence) は foundation Layer 1 が data + facility を expose し (foundation Req 1 AC7) Layer 2 が design phase 実行時に invoke する provide vs execute の役割分離に従って実行する (Req 1 AC7 整合、foundation Req 5 AC5 整合 = matching logic は本 spec 責務).
5. The Layer 2 design extension shall, escalate 必須条件 5 種 (memory `feedback_review_step_redesign.md` 整合 = 内部矛盾 / 実装不可能性 / 責務境界 / 規範範囲 / 複数選択肢 trade-off) を Step 1b-v (自動深掘り) と Step 1c (judgment) の両方で必ず適用する.
6. The Layer 2 design extension shall, foundation Layer 1 framework の definition file を改変せず、design phase 固有 quota / pattern を additional layer として attach する (= Layer 1 framework は不変、Layer 2 のみが新規追加).
7. While Layer 2 design extension が Layer 3 (project 固有 patterns / terminology / dev-log) と共存する場合, the Layer 2 design extension shall foundation Req 1 AC9 が定義する override 階層 (Layer 3 > Layer 2 > Layer 1) に従って、Layer 3 entry が Layer 2 entry を override 可能な状態を維持する.

### Requirement 5: Foundation Integration — 共通 schema / seed/fatal patterns / V4 §5.2 prompt の import 規約

**Objective:** As a `dual-reviewer-foundation` の consumer, I want 本 spec の 3 skills + Layer 2 design extension が foundation 提供の全 artifact (Layer 1 framework / 共通 schema 2 軸並列 / seed_patterns.yaml / fatal_patterns.yaml / V4 §5.2 judgment subagent prompt template / JSON Schema files) を foundation 確定の install location 規約 + override 階層に従って動的に import してほしい, so that foundation との contract が明確になり、foundation の minor revision で本 spec が破綻しない.

#### Acceptance Criteria

1. The 3 skills (`dr-design` / `dr-log` / `dr-judgment`) shall, foundation install location からの相対 path で foundation artifact を locate する: `./patterns/seed_patterns.yaml` / `./patterns/fatal_patterns.yaml` / `./prompts/judgment_subagent_prompt.txt` / `./schemas/<schema_name>.json` (foundation Req 4 AC6 / Req 5 AC4 / Req 6 AC1 + AC9 / Req 3 AC10 の canonical path form `./` 付き表記に整合).
2. The 3 skills shall, foundation install location の concrete absolute path を本 spec の design phase で確定する (foundation Boundary Context = 「foundation install location は A-1 prototype 実装時に確定」を継承、本 spec は consumer 視点で path 規約のみを継承).
3. The dr-design skill shall, foundation の `seed_patterns.yaml` の `version` field を起動時に読み込み (hardcode 禁止)、内部 quota / pattern matching に反映する (foundation Req 4 AC5 整合 = silent edit 検出は本 spec 対象外、foundation 責務).
4. The dr-design skill shall, foundation の `fatal_patterns.yaml` 8 種 enum を yaml file から動的に読み込む (foundation Req 5 AC3 で content 固定が保証されるため、minor revision で破綻しない前提だが yaml read 自体は必須、hardcode 禁止).
5. The dr-judgment skill shall, foundation の V4 §5.2 prompt template を `prompts/judgment_subagent_prompt.txt` から動的に読み込む (foundation Req 6 AC1 + AC9 整合、hardcode 禁止).
6. The dr-log skill shall, foundation の JSON Schema files を `schemas/` directory 直下から動的に読み込み、validate に使用する (foundation Req 3 AC10 整合、hardcode 禁止).
7. While foundation が `terminology.yaml` placeholder を生成する場合 (foundation Req 7 AC5 整合), the 3 skills shall Layer 3 project 固有 terminology entries を foundation Layer 1 contract (foundation Req 1 AC6) に従って attach 可能な状態を維持し、override 階層 (foundation Req 1 AC9 = Layer 3 > Layer 2 > Layer 1) で Layer 3 entry が Layer 2 design extension の terminology を override 可能とする.

### Requirement 6: forced_divergence Prompt Template — design phase 確定責務 (foundation Req 7 AC4 委任)

**Objective:** As a foundation Req 7 AC4 で defer された forced_divergence prompt の最終文言確定責務を持つ本 spec, I want forced_divergence prompt template の最終文言を本 spec の design phase で確定し、英語固定 + adversarial subagent prompt 末尾に組込む形式で `dr-design` skill から adversarial subagent dispatch 時に渡してほしい, so that forced_divergence (adversarial 担当、結論成立性試行) と修正否定試行 (judgment 担当、V4 §1.5、修正 proposal 必要性否定) の役割分離 (判定 5-C) が prompt レベルで保証される.

#### Acceptance Criteria

1. The forced_divergence prompt template shall, 本 spec の design phase で最終文言を確定する (foundation Req 7 AC4 で本 spec scope に defer された責務を本 spec が引き受ける).
2. The forced_divergence prompt template shall, 英語固定 (single canonical form) で記述され、subagent 安定性 + multi-language 移行性を保証する (foundation Req 7 AC4 の prompt 言語 policy 整合).
3. The forced_divergence prompt template shall, 素案 base として "Identify one tacit premise of the primary reviewer's reasoning, replace it with a plausible alternative premise, and evaluate whether the same conclusion still holds." (brief.md §Approach 整合) を採用しつつ、本 spec の design phase で必要に応じて精緻化する.
4. The forced_divergence prompt template shall, adversarial_reviewer subagent prompt の末尾に追加される形式で `dr-design` skill から Step B dispatch 時に渡され、adversarial 独立 detection + V4 §1.5 修正否定試行 と並列に実行される; V4 §1.5 修正否定試行 prompt (英語固定 3 行、Req 1 AC3 整合) の配置先 (adversarial subagent dispatch 時 inline embed または本 spec install location 直下に別 txt として配置のいずれか) は本 spec design phase で具体規約を確定する.
5. The forced_divergence prompt template shall, primary 提案 fix の必要性否定 (V4 §1.5 修正否定試行、judgment 用) と異なる役割を担う (= 結論成立性試行、暗黙前提を別前提に置換した場合に同じ結論が成立するかの試行) ことを prompt 文中で明示する.
6. The forced_divergence prompt template shall, 本 spec の install location 直下に portable artifact として配置される (例: `prompts/forced_divergence_prompt.txt`、design phase で具体 path 規約を確定); foundation install location とは独立した本 spec の install location に配置し、foundation portable artifact (V4 §5.2 prompt) との混在を避ける.

### Requirement 7: Phase A Scope Constraints — 3 役 subagent / 単純逐次運用 / B-1.0 minimum / sample 1 round 通過レベル

**Objective:** As a Phase A scope (Rwiki repo 内 prototype 段階) を厳守する maintainer, I want 本 spec の 3 skills + Layer 2 design extension が Phase A scope の制約 (3 役 subagent / 単純逐次運用 / B-1.0 minimum schema / sample 1 round 通過レベル / Phase B fork out of scope) を Constraints として要件化してほしい, so that scope creep が AC レベルで抑制され、Phase B 独立 fork / B-1.x 機能 / B-2 multi-vendor 機能を本 spec に混入させない.

#### Acceptance Criteria

1. The 3 skills shall, subagent 構成を 3 役 (primary_reviewer / adversarial_reviewer / judgment_reviewer、V4 §1.2 option C 整合) に限定し、Claude family rotation (B-1.1 opt-in) / multi-vendor support (B-2) / hypothesis generator role 3 体構成 (B-2、Chappy 保留 1) は本 spec scope 外とする (foundation `config.yaml` 4 field 整合).
2. The 3 skills shall, Round 1-10 を単純 sequential 運用 (並列処理本格実装 + 整合性 Round 6 task は B-1.x 以降) で動作させ、並列実行 / fall back trigger 5 条件 / 派生 Round 再実行は本 spec scope 外とする.
3. The 3 skills shall, B-1.0 minimum schema (失敗構造観測軸 3 要素 + 修正必要性判定軸 V4 §1.3 整合) のみを必須付与とし、B-1.x 拡張 schema (`decision_path` / `skipped_alternatives` / `bias_signal`、自由記述 + 内省) は本 spec 対象外とする.
4. The 3 skills の動作確認終端条件 shall, sample 1 round (= Round 1 のみ) を `dual-reviewer-dogfeeding` spec が指定する Spec 6 (rwiki-v2-perspective-generation) design に適用して通過することとし、全 10 ラウンド完走 + 3 系統対照実験 (single + dual + dual+judgment) は `dual-reviewer-dogfeeding` spec 責務として本 spec scope 外とする; ここで「sample 1 round 通過」の pass criteria は (a) Round 1 を Step A (primary detection) → Step B (adversarial review) → Step C (judgment) → Step D (integration) 全て完了 + (b) dr-log skill が JSONL に最低 1 entry を foundation 提供 schema (失敗構造観測軸 3 要素 + 修正必要性判定軸) で validate 成功で記録 + (c) dr-design skill が Step 2 user 提示用に V4 §2.5 三ラベル提示 yaml (must_fix / should_fix / do_not_fix の分類済み出力) を stdout に出力 の 3 条件を全て満たすこととする.
5. While Phase A scope = Rwiki repo 内 prototype 段階である間, the 3 skills shall Phase B 独立 fork (npm package 化 / GitHub repo 公開 / collective learning network) を本 spec scope 外とし、本 spec の成果物は Rwiki repo 内 prototype 配置 (例: `scripts/dual_reviewer_prototype/` または `.kiro/specs/dual-reviewer/prototype/`、A-1 prototype 実装時に確定 = foundation Boundary Context 整合) のみを対象とする.
