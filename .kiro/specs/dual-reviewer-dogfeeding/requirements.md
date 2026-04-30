# Requirements Document

## Introduction

`dual-reviewer-dogfeeding` は dual-reviewer (LLM 設計レビュー方法論 v3 一般化 package) の **prototype 適用 + 対照実験 + Phase B fork 判断** を提供する spec である。本 spec の成果物 = Spec 6 (`rwiki-v2-perspective-generation`) design phase への dual-reviewer prototype 適用 + 全 Round (1-10) × 3 系統対照実験 (single + dual + dual+judgment) 完走 + JSONL log 蓄積 + 比較 metric 抽出 + 論文 figure 1-3 + ablation evidence 用データ生成 + Phase B fork go/hold 判断 + Spec 6 design approve 同時終端。これらが揃って初めて Phase A 終端 = Rwiki v2 design phase 全 8 spec approve 完了 = Phase B-1.0 release prep 移行 trigger が成立する。

Phase A scope = Rwiki repo 内 prototype 段階。本 spec は dual-reviewer prototype の **consumer** 視点のみを担い、prototype 本体の実装責務は前提依存である `dual-reviewer-foundation` (`dr-init` skill + Layer 1 framework + 共通 schema 2 軸並列 + seed/fatal patterns yaml + V4 §5.2 prompt template) と `dual-reviewer-design-review` (`dr-design` / `dr-log` / `dr-judgment` skills + Layer 2 design extension + forced_divergence prompt template) で完結する。本 spec 単独では新規 skill 実装 / framework 拡張を一切行わない。

本 spec は V4 protocol v0.3 final (`.kiro/methodology/v4-validation/v4-protocol.md`) と整合する: 3 系統対照実験 (V4 §4.4 ablation framing 整合 = single = step 1c なし baseline + dual = step 1c なし adversarial baseline + dual+judgment = step 1c あり V4 完全構成) で過剰修正比率改善効果 + judgment subagent 効果を ablation 分離定量化し、V4 protocol H1 (過剰修正比率 ≤ 20%) + H3 (採択率 ≥ 50%) + H4 (wall-clock + 50% 以内) 仮説検証結果を Phase B fork 判断材料として提示する。判定 7-C (cost 3 倍許容、論文 8 月 timeline 厳守) を採用する。

## Boundary Context

- **In scope** (本 spec で提供):
  - Spec 6 (`rwiki-v2-perspective-generation`) design phase への dual-reviewer prototype 適用 (4 skill = `dr-init` + `dr-design` + `dr-log` + `dr-judgment`)
  - 全 Round (1-10) × 3 系統 (single + dual + dual+judgment) 対照実験完走 (= 計 30 review session、cost 約 3 倍、判定 7-C)
  - JSONL log 取得 (B-1.0 minimum schema 2 軸並列 = 失敗構造観測軸 3 要素 + 修正必要性判定軸 V4 §1.3 整合)
  - 比較 metric 抽出 (3 系統各々の検出件数 / 採択率 / 過剰修正比率 / disagreement 数 / wall-clock 等)
  - 論文 figure 用データ生成 (figure 1 = `miss_type` 分布 / figure 2 = `difference_type` 分布 + forced_divergence 効果 / figure 3 = `trigger_state` 発動率 / figure ablation = dual vs dual+judgment で judgment 効果分離)
  - Phase B fork go/hold 判断 (brief.md Approach 5 条件 + V4 protocol H1+H3+H4 仮説検証)
  - Spec 6 design approve 同時終端 (= Rwiki v2 design phase 全 8 spec approve 完了 = Phase A 終端 = Phase B-1.0 release prep 移行 trigger)

- **Out of scope** (本 spec 対象外):
  - dual-reviewer prototype 本体実装 (`dual-reviewer-foundation` / `dual-reviewer-design-review` の責務)
  - Spec 6 (`rwiki-v2-perspective-generation`) design 内容自体の策定 (Spec 6 spec 自身の責務、本 spec と並走、本 spec は dual-reviewer 適用 + metric 取得のみ)
  - 論文ドラフト執筆 (Phase 3 = 7-8 月別 effort、本 spec は figure 1-3 + ablation 用データ取得のみ)
  - case study 記述 (figure 4-5 qualitative、Phase 3 論文ドラフト責務)
  - B-1.x 拡張 schema (`decision_path` / `skipped_alternatives` / `bias_signal`、自由記述 + 内省) の取得 (A-2 後半 〜 B-1.x で別 spec)
  - multi-vendor 対照実験 (Claude vs GPT vs Gemini 等、B-2 以降)
  - Phase B-1.0 release prep 自体 (固有名詞除去 / npm package 化 / GitHub repo 公開検討、本 spec 完了後の作業 = 元 A-3 統合 #3)
  - Claude family rotation (B-1.1 opt-in)
  - hypothesis generator role 3 体構成 (Chappy 保留 1、B-2 以降)
  - 並列処理本格実装 + 整合性 Round 6 task (B-1.x 以降)

- **Adjacent expectations** (隣接 spec / 既存 system からの期待):
  - `dual-reviewer-foundation` から以下を import する前提: (a) `dr-init` skill (project bootstrap、`config.yaml` 4 field = primary_model / adversarial_model / judgment_model / lang) (b) Layer 1 framework (Step A/B/C/D 構造 + bias 抑制 quota + override 階層 Layer 3 > Layer 2 > Layer 1) (c) 共通 JSON schema 2 軸並列 (失敗構造観測軸 3 要素 + 修正必要性判定軸 V4 §1.3 整合) (d) `./patterns/seed_patterns.yaml` 23 件 (e) `./patterns/fatal_patterns.yaml` 8 種固定 (f) V4 §5.2 judgment subagent prompt template (`./prompts/judgment_subagent_prompt.txt`) (g) JSON Schema files (`./schemas/`)
  - `dual-reviewer-design-review` から以下を import する前提: (a) `dr-design` skill (10 ラウンド orchestration + Layer 2 design extension + Step A/B/C/D V4 §1.2 option C 構造) (b) `dr-log` skill (JSONL 構造化記録 + 共通 schema 2 軸並列 validate + 3 系統対応 = `detected` state / `judged` state 区別、design-review spec Req 2 AC7 整合) (c) `dr-judgment` skill (V4 §5.2 prompt template 動的読込 + judgment subagent dispatch + 5 条件判定 + 3 ラベル分類 + escalate → `should_fix` + `recommended_action: user_decision` mapping、design-review spec Req 3 AC5 整合) (d) forced_divergence prompt template (本 spec design phase 確定済の最終文言、英語固定)
  - `rwiki-v2-perspective-generation` (Spec 6) は本 spec と並走、本 spec の dogfeeding 適用対象 = Spec 6 design phase だが Spec 6 design 内容自体の策定は Spec 6 spec 自身の責務であり、本 spec は dual-reviewer 適用 + metric 取得のみ
  - 既存 Rwiki spec (Spec 0-5/7) とは機能的に独立 — cross-spec dependency なし、本 spec の dogfeeding 対象外

## Requirements

### Requirement 1: Spec 6 Design への dual-reviewer Prototype 適用

**Objective:** As a dual-reviewer prototype の effectiveness 検証 + Phase B fork go/hold 判断を行う maintainer, I want `dual-reviewer-foundation` の `dr-init` skill + `dual-reviewer-design-review` の 3 skills (`dr-design` / `dr-log` / `dr-judgment`) を Spec 6 (`rwiki-v2-perspective-generation`) design phase に適用してほしい, so that Phase A 期間中ペンディング維持の Spec 6 design phase が dual-reviewer prototype の dogfeeding 場として稼働し、prototype 動作 + metric 取得が実 review session で実証される.

#### Acceptance Criteria

1. The dogfeeding session shall, target spec を Spec 6 (`rwiki-v2-perspective-generation`、Phase A 期間中ペンディング維持の Rwiki v2 spec、`/Users/Daily/Development/Rwiki-dev/.kiro/specs/rwiki-v2-perspective-generation/`) に固定し、他 Rwiki spec (Spec 0-5/7) を本 spec の dogfeeding 対象外とする.
2. The dogfeeding session shall, 適用前段階で foundation `dr-init` skill (foundation Req 2 整合) を Spec 6 design 用 working directory で起動し、`.dual-reviewer/` directory + `config.yaml` (4 field = `primary_model` / `adversarial_model` / `judgment_model` / `lang`) + Layer 3 placeholder (`extracted_patterns.yaml` / `terminology.yaml` / dev-log JSONL location) を bootstrap する.
3. The dogfeeding session shall, Round 1-10 を design-review spec Req 4 AC2 で確定する 10 観点 (Round 1 規範範囲確認 / Round 2 一貫性 / Round 3 実装可能性 + アルゴリズム + 性能 統合 / Round 4 責務境界 / Round 5 失敗モード + 観測 統合 / Round 6 concurrency / timing / Round 7 security / Round 8 cross-spec 整合 / Round 9 test 戦略 / Round 10 運用、memory `feedback_design_review.md` 中庸統合版整合) で Spec 6 design に対して実行する.
4. The dogfeeding session shall, design-review spec の `dr-design` skill を Round orchestration の entry point とし、各 Round で Step A (primary detection) → Step B (adversarial review) → Step C (judgment) → Step D (integration) を design-review spec Req 1-3 が定義する protocol で実行する (V4 §1.2 option C 整合).
5. The dogfeeding session shall, dual-reviewer prototype の 4 skills + foundation 提供 artifact (Layer 1 framework / 共通 schema 2 軸並列 / `seed_patterns.yaml` 23 件 / `fatal_patterns.yaml` 8 種 / V4 §5.2 prompt template / JSON Schema files) のみを使用し、本 spec 単独では新規 skill 実装 / framework 拡張 / schema 追加を一切行わない (= consumer 視点のみ).
6. The dogfeeding session shall, prototype 適用時に foundation install location からの相対 path 規約 (`./patterns/` / `./prompts/` / `./schemas/`、foundation Req 3 AC10 / Req 4 AC6 / Req 5 AC4 / Req 6 AC1 + AC9 整合) に従って artifact を locate し、hardcode 禁止を遵守する (design-review spec Req 5 整合).

### Requirement 2: 3 系統対照実験 (single + dual + dual+judgment)

**Objective:** As V4 protocol H1 (過剰修正比率改善) + H3 (採択率改善) + H4 (wall-clock 増加許容範囲) 仮説を ablation evidence で検証する maintainer, I want 全 Round (1-10) を 3 系統 (single + dual + dual+judgment) で対照実験完走してほしい, so that adversarial 構造の効果 (= dual vs single) と judgment subagent 構造の効果 (= dual+judgment vs dual) が段階的に分離定量化され、論文 ablation evidence と Phase B fork 判断材料が同時に取得される.

#### Acceptance Criteria

1. The dogfeeding session shall, 各 Round (1-10) を以下 3 系統で実行する: (a) **single 系統** = `primary_reviewer` (= `config.yaml` `primary_model` で指定された model) のみで Step A 実行、Step B (adversarial) と Step C (judgment) は省略 / (b) **dual 系統 (V3 構成)** = `primary_reviewer` + `adversarial_reviewer` で Step A + Step B 実行、Step C (judgment) は省略 (= judgment subagent dispatch なし、修正必要性判定軸は primary 自己 estimate) / (c) **dual+judgment 系統 (V4 完全構成)** = `primary_reviewer` + `adversarial_reviewer` + `judgment_reviewer` で Step A + Step B + Step C 全実行 (= V4 §1.2 option C 完全運用).
2. The dogfeeding session shall, 3 系統を同一 Round 内で **対照実験として 3 回独立実行** する (= Round 1 を 3 系統で 3 回、Round 2 を 3 系統で 3 回 ... Round 10 を 3 系統で 3 回 = 計 30 review session); 系統間で同一 design.md content を input とすることで ablation 公平性を保証する.
3. The dogfeeding session shall, 修正必要性判定軸 (V4 §1.3 整合 = 必要性 5-field + `fix_decision.label` + `recommended_action` + `override_reason`) を **dual+judgment 系統のみ** judgment subagent 確定値で付与し (= state = `judged`)、single 系統 / dual 系統では primary 自己 estimate (= `source: primary_self_estimate`、design-review spec Req 2 AC7 整合) を `detected` state として付与する.
4. The dogfeeding session shall, 失敗構造観測軸 (B-1.0 拡張 3 要素 = `miss_type` 6 enum / `difference_type` 6 enum / `trigger_state` 3 string enum field) を 3 系統すべてで自己ラベリング付与し、3 系統間の比較を可能にする (= dual / dual+judgment 系統では adversarial 自己ラベリング含む、design-review spec Req 2 AC5 整合).
5. The dogfeeding session shall, dual+judgment 系統で V4 §1.4.1 の `escalate` outcome (= `uncertainty=high` 等の trigger に応じる user 介入要請) が発生した場合、design-review spec Req 3 AC5 が定義する mapping (= `should_fix` + `recommended_action: user_decision`) で JSONL 記録し、`fix_decision.label` 3 値 enum 整合を維持する (foundation Req 3 AC5 整合).
6. While 3 系統対照実験が cost 約 3 倍 (= V3 baseline = 1 系統 dual に対し本 spec = 3 系統) を要求する間, the dogfeeding session shall 判定 7-C (cost 3 倍許容) を採用し、論文 8 月ドラフト提出 timeline (= Phase 2 = 6-7 月期間集中) を厳守する.
7. The dogfeeding session shall, 3 系統対照実験を「ablation 比較」と framing し (V4 protocol §4.4 整合 = single + dual = step 1c なし baseline / dual+judgment = step 1c あり treatment)、「V4 全体が V3 より優れる」と断じる pure independent 比較は本 spec scope 外 (= B-2 multi-vendor + 並列 multi-subagent 段階で別 protocol との比較で実施) と扱う.

### Requirement 3: JSONL Log 取得 (B-1.0 Minimum Schema 2 軸並列)

**Objective:** As 論文化 + cycle 学習 + Phase B fork 判断のための quantitative evidence を蓄積する maintainer, I want 全 Round + 3 系統の finding を foundation 提供 共通 schema (2 軸並列) で JSONL log 構造化記録してほしい, so that 機械処理可能な形で 30 review session 分の evidence が蓄積され、後段 metric 抽出 + figure 用データ生成 + comparison-report 集計が schema validate 済 base 上で実行可能となる.

#### Acceptance Criteria

1. The dogfeeding session shall, 各 Round + 各系統の finding を design-review spec の `dr-log` skill で JSONL 構造化記録する (design-review spec Req 2 整合).
2. The dogfeeding session shall, foundation 提供 共通 schema 2 軸並列 (`review_case` / `finding` / `impact_score` 3 軸 + 失敗構造観測軸 3 要素 + 修正必要性判定軸 V4 §1.3 整合) で全 finding を schema validate する (foundation Req 3 整合、design-review spec Req 2 AC1 整合); validate 失敗時は fail-fast (non-zero exit signal + error report) し、後段 metric 抽出 + figure 用データ生成への schema 不正 finding 流入を防ぐ.
3. The dogfeeding session shall, JSONL log の 1 line = 1 `review_case` object = **1 系統 × 1 Round の boundary** (= 3 系統合算を 1 review_case として扱うことを禁止) で記録し、計 **30 line** (= 10 Round × 3 系統) の base 記録量に達する (各 Round の検出件数次第で `review_case` 内 finding array 数は変動).
4. The dogfeeding session shall, finding の state field を 3 系統に応じて以下で固定する: **single 系統 / dual 系統** = `state: detected` (修正必要性判定軸を **primary 自己 estimate として `source: primary_self_estimate` 付きで必須付与**、これにより Req 4 AC1 の採択率 / 過剰修正比率算出が primary 自己 estimate base で実行可能となる) / **dual+judgment 系統** = `state: judged` (修正必要性判定軸を **judgment subagent 確定値 `source: judgment_subagent` 付きで必須付与**) (foundation Req 3 AC6/AC7 + design-review spec Req 2 AC3 + AC7 整合).
5. The dogfeeding session shall, JSONL log の append target path を `dr-init` skill が生成する `.dual-reviewer/config.yaml` の `dev_log_path` field から動的に読み取る (design-review spec Req 2 AC4 整合、hardcode 禁止).
6. The dogfeeding session shall, 系統識別 field (例: `treatment: single | dual | dual+judgment`) を全 `review_case` object に必須付与し、後段 metric 抽出 + ablation 比較で 3 系統を区別可能とする.
7. The dogfeeding session shall, 各 `review_case` object に Round 識別 field (例: `round_index: 1..10`) + Spec 6 design.md commit hash (= dogfeeding 適用時点の Spec 6 design content snapshot) を必須付与し、後段 reproducibility + cross-round 比較を可能とする; 全 30 review session で記録される commit hash が変動した場合 (= 進行中の Spec 6 design 改修により Round 間で content が異なる場合) は metric 抽出時 (Req 4) に commit hash 変動の有無を必須報告し、変動ありの場合は cross-round 比較に対する公平性 caveat を comparison-report (Req 6 AC4) に併記する.
8. The dogfeeding session shall, **dual 系統 / dual+judgment 系統** で adversarial subagent が V4 §1.5 修正否定試行 prompt 末尾組込により生成する **counter-evidence** (= primary 提案 fix の必要性否定 output、design-review spec Req 3 AC2 整合) を JSONL log の `adversarial_counter_evidence` field として finding ごとに必須記録する; **single 系統** では adversarial dispatch 自体がないため当該 field は省略可とし、3 系統間で同一 dr-log skill を共有しつつ counter-evidence の有無を区別可能な状態を維持する.

### Requirement 4: 比較 Metric 抽出

**Objective:** As V4 protocol §4 比較指標 + 仮説 H1-H4 検証を行う maintainer, I want JSONL log から 3 系統対照実験の比較 metric を抽出してほしい, so that V3 baseline (= 6th セッション dual 系統 evidence) との対比が機械可読 format で確定し、Step 6 中間 comparison-report.md (= `.kiro/methodology/v4-validation/comparison-report.md`) の input として直接使用可能な状態になる.

#### Acceptance Criteria

1. The metric extraction shall, 3 系統各々で以下の base metric を算出する: 検出件数 / `must_fix` 件数 + 比率 / `should_fix` 件数 + 比率 / `do_not_fix` 件数 + 比率 / **検出 → 採択率** (= `must_fix` 比率) / **過剰修正比率** (= `do_not_fix` 比率) (V4 protocol §4.1 整合); single 系統 / dual 系統では primary 自己 estimate base、dual+judgment 系統では judgment subagent 確定値 base で算出する.
2. The metric extraction shall, **dual / dual+judgment 系統で adversarial 修正否定 disagreement 数** (= primary 提案 vs adversarial 修正否定試行の不一致件数、V4 §1.5 prompt 効果) を抽出する (V4 protocol §4.1 整合).
3. The metric extraction shall, **dual+judgment 系統のみで judgment subagent disagreement 数** (= primary 提案 vs judgment subagent 判定の不一致件数) + **judgment subagent override 件数** + 理由分析 (= semi-mechanical mapping default override 評価、V4 §1.4.2 整合) を抽出する (V4 protocol §4.1 整合).
4. The metric extraction shall, 3 系統各々で wall-clock 時間 (Round 1-10 全工程) を記録し、cost 倍率を **V3 baseline (= 7th セッション foundation design 適用 evidence、V4 protocol §4.2 整合 = 検出 6 件 / 採択率 16.7% / 過剰修正比率 50% / wall-clock 420.7 秒、design phase 比較対象として正規) 比 + V4 完全構成 (= dual+judgment 系統) 比** で算出する (V4 protocol §4.1 + H4 仮説 = wall-clock + 50% 以内検証用).
5. The metric extraction shall, **Phase 1 同型 hit rate** (= 規範範囲先取り / 構造的不均一 / 文書 vs 実装不整合 メタパターンの照合 hit 件数) を 3 系統各々で算出する (V4 protocol §4.1 整合).
6. The metric extraction shall, dogfeeding 終了時に metric 集計結果を機械可読 format (JSON または yaml) で生成し、Step 6 中間 comparison-report.md の input として直接使用可能な形式 (V4 protocol §4 整合) とする; 集計 file 配置 path は本 spec design phase で確定する.
7. The metric extraction shall, **`fatal_patterns.yaml` 8 種強制照合 hit 件数** (= foundation Req 5 + design-review spec Req 1 AC7 で実装される Chappy P0 quota 効果) を 3 系統各々で算出する (V4 protocol §4.1 整合).

### Requirement 5: 論文 Figure 用データ生成

**Objective:** As 論文 8 月ドラフト提出を見据える maintainer, I want JSONL log + 比較 metric から論文 figure 1-3 + V4 ablation evidence (figure ablation) 用 data set を生成してほしい, so that figure 1-3 (quantitative + V4 ablation) の数値が確定し、論文ドラフト執筆 Phase 3 (7-8 月、別 effort) で figure 描画 input として直接使える状態になる.

#### Acceptance Criteria

1. The figure data generation shall, **figure 1 用 data** = `miss_type` 6 enum 分布 (= `implicit_assumption` / `boundary_leakage` / `spec_implementation_gap` / `failure_mode_missing` / `security_oversight` / `consistency_overconfidence` の件数 + 比率) を 3 系統各々で算出し、3 系統間の比較を可能とする (brief.md Desired Outcome 整合).
2. The figure data generation shall, **figure 2 用 data** = `difference_type` 6 enum 分布 (= `assumption_shift` / `perspective_divergence` / `constraint_activation` / `scope_expansion` / `adversarial_trigger` / `reasoning_depth` の件数 + 比率) + forced_divergence 効果 (= dual / dual+judgment 系統で `difference_type = adversarial_trigger` の発動件数 + 比率) を算出し、**dual vs single で adversarial 効果分離** を可能とする (brief.md Desired Outcome 整合).
3. The figure data generation shall, **figure 3 用 data** = `trigger_state` 3 string enum field (= `negative_check` / `escalate_check` / `alternative_considered`) の **発動率** (= `applied` 比率 vs `skipped` 比率) を 3 系統各々で算出し、Phase 1 同型 hit rate との対応関係を可能とする (brief.md Desired Outcome 整合).
4. The figure data generation shall, **figure ablation 用 data** (V4 protocol §4.4 整合 = step 1c なし baseline vs step 1c あり treatment) = dual 系統 vs dual+judgment 系統で **過剰修正比率削減効果 + 採択率増加効果 + judgment subagent override 件数 + 必要性判定 quality** (= `override_reason` 内容分析) を算出し、**judgment subagent 効果分離** を可能とする (brief.md Desired Outcome + V4 protocol §4.4 整合).
5. The figure data generation shall, figure 4-5 (case study、qualitative narrative) 用 data 生成を本 spec scope 外とする (brief.md Out of Boundary 整合 = Phase 3 論文ドラフトで別 effort).
6. The figure data generation shall, 各 figure の data file を機械可読 format (JSON または yaml、Req 4 AC6 と同一 format) で出力し、配置 path 規約は本 spec design phase で確定する.

### Requirement 6: Phase B Fork Go/Hold 判断基準

**Objective:** As Phase A 終端時に Phase B 独立 fork (npm package 化 / GitHub repo 公開 / collective learning network) の go/hold 判断を行う maintainer, I want brief.md で確定した 5 条件 + V4 protocol H1+H3+H4 仮説検証を統合した go/hold 判断基準を本 spec 内で AC 化してほしい, so that Phase A 終端時の判断が一貫した criteria で実行され、Phase B-1.0 release prep への移行 trigger が客観的 evidence base で確定する.

#### Acceptance Criteria

1. The Phase B fork judgment shall, 全 Round + 3 系統対照実験完了後 (Req 1 AC1-AC6 達成 + Req 2 AC1-AC7 達成 + Req 3 AC1-AC8 達成 + Req 4 AC1-AC7 達成 + Req 5 AC1-AC6 達成) に以下 5 条件を順次評価する (brief.md Approach + Constraints 整合): (a) **致命級発見 ≥ 2 件 (累積)** (= Spec 3 Round 5-10 dogfeeding 1 件 [外部固定累積値] + 本 spec Spec 6 dogfeeding で ≥ 1 件 [本 spec 制御可能条件として必須]) / (b) **disagreement ≥ 3 件** (= Spec 3 = 2 件 + Spec 6 で 1 件以上検出、forced_divergence disagreement + judgment subagent disagreement 含む) / (c) **bias 共有反証 evidence 確実** (= subagent 独立発見が再現される、= primary が見落とした issue を adversarial が独立検出する事例 ≥ 1 件) / (d) **`impact_score` 分布が minor のみではない** (= `severity` enum で `CRITICAL` または `ERROR` が含まれる finding ≥ 1 件) / (e) **過剰修正比率改善** (= dual+judgment 系統 vs dual 系統で `do_not_fix` 比率減 + `must_fix` 比率増、V4 protocol H1+H3 仮説整合).
2. The Phase B fork judgment shall, 5 条件のうち (a) (b) (c) (d) (e) **すべて達成 → go** (Phase B-1.0 release prep に即移行)、いずれか未達成 → **hold** (V4 protocol 改訂 + 追加 dogfeeding 検討) と判定する.
3. The Phase B fork judgment shall, V4 protocol H1+H3+H4 仮説検証結果 (V4 protocol §4.3 整合) を補助的判断材料として併記する: (a) **H1** = V4 過剰修正比率 ≤ 20% (V3 baseline 50%) / (b) **H3** = V4 検出 → 採択率 ≥ 50% (V3 baseline 16.7%、3 倍改善目標) / (c) **H4** = V4 wall-clock + 50% 以内 (V3 baseline 比、option C subagent +1 個追加分許容).
4. The Phase B fork judgment shall, 判定結果を Step 6 中間 comparison-report.md (= `.kiro/methodology/v4-validation/comparison-report.md`) に記録し、go 判定時は **Phase B-1.0 release prep 移行手順** (= 元 A-3 統合 #3 = 固有名詞除去 / npm package 化 / GitHub repo 公開検討、本 spec scope 外) を併記、hold 判定時は **V4 protocol 改訂候補 + 追加 dogfeeding 範囲記述** を併記する; **追加 dogfeeding の実施自体は本 spec scope 外** (= hold 判定後の追加実施は別 spec 責務、本 spec は hold 判定記録 + 範囲記述のみを責務とする) と明示する.
5. The Phase B fork judgment shall, 判定根拠を JSONL log + 比較 metric + figure 用 data に基づく **client-verifiable evidence** (= 第三者が同一 metric を再算出可能な状態) として記述し、subjective 判断のみによる go/hold 確定を禁止する.

### Requirement 7: Spec 6 Design Approve 同時終端 + Phase A 終端

**Objective:** As Phase A 終端 (= dual-reviewer A-2 完了 = Spec 6 design approve = Rwiki v2 design phase 全 8 spec approve 完了) を達成する maintainer, I want 本 spec の dogfeeding 完了が Spec 6 design approve と同時に成立する責務分離をしてほしい, so that 本 spec scope (dual-reviewer 適用 + metric 取得) と Spec 6 spec scope (Spec 6 design 内容自体の策定) が混同されず、Phase A 終端 = Phase B-1.0 release prep 移行 trigger が一貫した state で確定する.

#### Acceptance Criteria

1. The dogfeeding session shall, Spec 6 design phase の進行を `rwiki-v2-perspective-generation` spec 自身の責務として扱い、本 spec は **dual-reviewer prototype の適用 + metric 取得のみ** を責務とする (= Spec 6 design 内容自体の策定は本 spec scope 外、brief.md Scope 整合).
2. The dogfeeding session shall, 以下を完了状態の必要条件として **全項目達成** を要求する: (a) Spec 6 適用 + dr-init bootstrap + dual-reviewer prototype 動作確認 (Req 1 AC1-AC6) / (b) 全 Round (1-10) × 3 系統対照実験完走 (Req 2 AC1-AC7) / (c) JSONL log 30 line 蓄積 + schema validate 通過 (Req 3 AC1-AC8) / (d) 比較 metric 抽出完了 (Req 4 AC1-AC7) / (e) 論文 figure 用データ生成完了 (Req 5 AC1-AC6) / (f) Phase B fork go/hold 判断記録完了 (Req 6 AC1-AC5).
3. The dogfeeding session shall, **Spec 6 design approve** (= `.kiro/specs/rwiki-v2-perspective-generation/spec.json` `approvals.design.approved: true` 状態) を同時達成条件として要求し、本 spec dogfeeding 完了 = Spec 6 design approve = **Rwiki v2 design phase 全 8 spec approve 完了** = **Phase A 終端** を成立させる.
4. While Phase A scope = Rwiki repo 内 prototype 段階である間, the dogfeeding session の終端 (= A-2 終端 = Phase A 終端) shall **即 Phase B-1.0 release prep** (= 元 A-3 統合 #3 = 固有名詞除去 / npm package 化 / GitHub repo 公開検討、本 spec scope 外) への移行 trigger となる.
5. The dogfeeding session shall, **B-1.x 拡張 schema** (`decision_path` / `skipped_alternatives` / `bias_signal`、自由記述 + 内省) の取得を本 spec scope 外とする (brief.md Out of Boundary 整合 = A-2 後半 〜 B-1.x で別 spec).
6. The dogfeeding session shall, **multi-vendor 対照実験** (Claude vs GPT vs Gemini 等) を本 spec scope 外とする (brief.md Out of Boundary 整合 = B-2 以降).
7. The dogfeeding session shall, 論文ドラフト執筆 (Phase 3 = 7-8 月) + case study 記述 (figure 4-5 qualitative) を本 spec scope 外とし、本 spec は figure 1-3 + ablation evidence 用データ取得のみを責務とする (brief.md Out of Boundary 整合).
