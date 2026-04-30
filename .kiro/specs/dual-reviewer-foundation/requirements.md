# Requirements Document

## Introduction

`dual-reviewer-foundation` は dual-reviewer (LLM 設計レビュー方法論 v3 一般化 package) の core 基盤を提供する spec である。本 spec の成果物 = Layer 1 framework + `dr-init` skill + 共通 JSON schema (2 軸並列) + `seed_patterns.yaml` + `fatal_patterns.yaml` + V4 §5.2 judgment subagent prompt template + 用語 / 多言語 policy。これらが揃って初めて後続 spec (`dual-reviewer-design-review` / `dual-reviewer-dogfeeding`) が単独で機能できる。

Phase A scope = Rwiki repo 内 prototype 段階。B-1.0 minimum 4 skills (`dr-init` / `dr-design` / `dr-log` / `dr-judgment`、V4 protocol §1.2 option C 整合 = 3 subagent 構成 = primary + adversarial + judgment) のうち本 spec は `dr-init` を担当し、残り 3 skills は `dual-reviewer-design-review` で実装される。Phase B 独立 fork は本 spec 対象外。

本 spec は V4 protocol v0.3 final (`.kiro/methodology/v4-validation/v4-protocol.md`) と整合する: Step C (judgment / 修正必要性判定) を Layer 1 framework に組込み、必要性 5-field schema + 5 条件判定ルール + 3 ラベル分類 (must_fix / should_fix / do_not_fix) を共通 schema に取込み、V4 §5.2 judgment subagent dispatch prompt template を foundation portable artifact として配置する。

## Boundary Context

- **In scope** (本 spec で提供):
  - Layer 1 framework (Step A/B/C/D 構造 + bias 抑制 quota + pattern schema + 介入 framework + V4 §1.2 整合)
  - `dr-init` skill (project bootstrap、4 skill 構成想定で `judgment_model` config field 含む)
  - 共通 JSON schema 2 軸並列:
    - (a) 失敗構造観測軸 = `review_case` / `finding` / `impact_score` 3 軸 + B-1.0 拡張 schema (`miss_type` / `difference_type` / `trigger_state`)
    - (b) 修正必要性判定軸 = V4 §1.3 整合 (必要性 5-field + `fix_decision.label` + `recommended_action` + `override_reason`)
  - `seed_patterns.yaml` (23 事例 retrofit、Rwiki dev-log 由来、`origin` field 付き)
  - `fatal_patterns.yaml` (致命級 8 種固定 enum)
  - V4 §5.2 judgment subagent dispatch prompt template (canonical 英語 prompt、foundation portable artifact)
  - 用語抽象化 + 多言語 policy (role 用語 = `primary_reviewer` / `adversarial_reviewer` / `judgment_reviewer` / section 見出し / schema field / prompt 言語)

- **Out of scope** (本 spec 対象外):
  - Layer 2 phase extension (`dual-reviewer-design-review` spec の責務)
  - `dr-design` / `dr-log` / `dr-judgment` skills (`dual-reviewer-design-review` spec の責務 — 本 spec は V4 §5.2 prompt template を portable artifact として配置するのみ、`dr-judgment` skill 実装は別 spec)
  - judgment subagent dispatch logic (Layer 2 `dr-design` / `dr-judgment` skill 実装、本 spec は prompt template の data 提供のみ)
  - B-1.x skills (`dr-tasks` / `dr-requirements` / `dr-impl` / `dr-extract` / `dr-validate` / `dr-update` / `dr-translate`)
  - Run-Log-Analyze-Update cycle automation
  - 並列処理 + 整合性 Round
  - multi-vendor / multi-subagent / hypothesis generator (Phase B-2 以降)
  - B-1.x 拡張 schema (`decision_path` / `skipped_alternatives` / `bias_signal`)
  - Phase B 独立 fork (Rwiki repo 内 prototype 段階のみ)
  - `seed_patterns.yaml` 固有名詞除去 / generalization (Phase B-1.0 release prep)
  - `--lang en` 対応 (Phase B-1.3 で追加)
  - npm package 化 (Phase B-1.0)
  - foundation install location の concrete absolute path (= `scripts/dual_reviewer_prototype/` または `.kiro/specs/dual-reviewer/prototype/` 等) — A-1 prototype 実装時に確定、本 spec の requirements phase では規定しない (brief.md Constraints 整合)。本 requirements 内の「foundation install location」言及は相対 directory 規約 (`patterns/` / `prompts/` / `schemas/`) に対する constraint であり、絶対 path は design phase に defer する.

- **Adjacent expectations** (隣接 spec / 既存 system からの期待):
  - `dual-reviewer-design-review` は Layer 2 design extension + `dr-design` / `dr-log` / `dr-judgment` skill を実装するにあたり、本 spec の Layer 1 framework + 共通 JSON schema 2 軸並列 + `seed_patterns.yaml` 23 件 + `fatal_patterns.yaml` 8 種固定 + **V4 §5.2 judgment subagent prompt template** + JSON Schema files (`./schemas/`) を import する前提
  - `dual-reviewer-dogfeeding` は Spec 6 (rwiki-v2-perspective-generation) design に dual-reviewer prototype を適用するにあたり本 spec の `dr-init` skill による project bootstrap + Layer 1 framework + 共通 JSON schema 2 軸並列 + `seed_patterns.yaml` 23 件 + `fatal_patterns.yaml` 8 種固定 + V4 §5.2 judgment subagent prompt template + JSON Schema files (`./schemas/`) を統合使用する前提
  - 既存 Rwiki spec (Spec 0-7) とは機能的に独立 — cross-spec dependency なし、本 spec の成果物が Rwiki spec の AC に影響しない

## Requirements

### Requirement 1: Layer 1 Framework — phase 横断 review 構造の提供

**Objective:** As a dual-reviewer 利用者 (Layer 2 extension 実装者 / dogfeeding 適用者), I want phase 横断で portable な review 構造を Layer 1 framework として提供してほしい, so that 各 phase extension (design / requirements / tasks / implementation) は Layer 1 を base に固有の quota だけ追加すればよい状態になる.

#### Acceptance Criteria

1. The Layer 1 framework shall, 利用 phase に関わらず, Step A (primary detection) / Step B (adversarial review = 見落とし検出 + 修正否定試行 counter-evidence 生成) / Step C (judgment = 修正必要性判定) / Step D (integration) を core review pipeline として常時 expose し、V4 protocol §1.2 option C (3 subagent 構成 = `primary_reviewer` + `adversarial_reviewer` + `judgment_reviewer`) を整合する.
2. The Layer 1 framework shall, event-triggered な bias 抑制 quota mechanism として `formal_challenge` / `detection_miss` / `phase1_pattern_match` を fundamental events に含めた基盤を提供し、phase-specific quota の追加余地を Layer 2 extension に残す.
3. The Layer 1 framework shall, pattern schema を `primary_group` + `secondary_groups` の二層 grouping + 中程度 granularity で定義し、domain-specific patterns と meta-pattern groups が単一 schema に共存できる構造を提供する.
4. While 介入 framework が有効な間、the Layer 1 framework shall pre-run Tier 比率 target を一切設定せず (Goodhart's Law 回避)、event-triggered quota のみを介入 trigger とし、Tier 比率は post-run measurement only として記録する.
5. The Layer 1 framework shall, Layer 2 extension が phase 固有 quota を追加するための contract を Layer 1 内部構造を変更せずに拡張可能な形で公開する; contract には最低限 (a) attach 対象 entry-point file の location 規約、(b) entry-point file の identifier 形式、(c) attach 失敗時の signal 規定 の 3 要素を含める.
6. The Layer 1 framework shall, Layer 3 (project 固有) integration point として project 固有 patterns / terminology entries / dev-log archives が Layer 1 / Layer 2 を改変せず attach できる接続口を、AC 5 の contract と同一の interface 形式 (attach 対象 location 規約 + identifier 形式 + 失敗 signal) で定義する.
7. Where Chappy P0 採用 3 件 (`fatal_patterns.yaml` 強制照合 / `forced_divergence` prompt 1 行 / `impact_score` 3 軸) が Layer 1 scope に含まれる場合, the Layer 1 framework shall それらを first-class facility として任意の Layer 2 extension から到達可能な形で expose する.
8. Where V4 protocol §1 機能 (judgment subagent dispatch + 必要性 5-field schema + 5 条件判定ルール + 3 ラベル分類 + 修正否定試行 prompt の役割分離) が Layer 1 scope に含まれる場合, the Layer 1 framework shall それらを first-class facility として任意の Layer 2 extension から到達可能な形で expose し、Step B の `forced_divergence` (= 結論成立性試行、`adversarial_reviewer` 担当) と Step C の修正否定試行 (= 修正 proposal 必要性否定、`judgment_reviewer` prompt 末尾組込) の役割分離を framework definition で明示する.
9. Where 同一 identifier が AC 5 (Layer 2 extension) の attach 対象 と AC 6 (Layer 3 project 固有) の attach 対象 に共存する場合, the Layer 1 framework shall override 解決順位を Layer 3 > Layer 2 > Layer 1 の固定順序で規定し、衝突解決 semantics を first-class facility として expose する (= Layer 3 entry が Layer 2 entry を override し、Layer 2 entry が Layer 1 default を override する単方向順位).

### Requirement 2: dr-init Skill — project bootstrap

**Objective:** As a dual-reviewer 新規利用者, I want `dr-init` skill で project に dual-reviewer の最低限の作業空間を bootstrap してほしい, so that 後続 skill (`dr-design` / `dr-log` / `dr-judgment` 等) が前提とする ディレクトリ構造 + 設定 + Layer 3 placeholder が手作業なしで揃う.

#### Acceptance Criteria

1. When user が target project root で `dr-init` を起動した場合, the dr-init skill shall `.dual-reviewer/` directory を新規生成し、Layer 3 artifact (`extracted_patterns.yaml` / `terminology.yaml` / dev-log JSONL location) 用 placeholder を内部に配置し、success 時 exit 0 を返し生成された `.dual-reviewer/` directory の absolute path を stdout に 1 行で報告する.
2. When the dr-init skill が `.dual-reviewer/config.yaml` を生成する場合, the config.yaml shall 最低限 `primary_model` / `adversarial_model` / `judgment_model` / `lang` / `dev_log_path` 5 field を含み、project-level default 値で populate された状態で書き出される (V4 protocol §1.2 option C 整合 = 3 subagent 構成 = primary + adversarial + judgment); `primary_model` / `adversarial_model` / `judgment_model` の default 値は具体的 model identifier の placeholder 文字列 (例: `<primary-model>` / `<adversarial-model>` / `<judgment-model>`) で populate され、concrete model identifier への解決は本 spec の design phase または使用者 (project bootstrap 後の手動設定) で確定する; `lang` の default 値は `ja` (Phase A scope = 日本語 seed / Rwiki 由来) とする; `dev_log_path` の default 値は `.dual-reviewer/dev_log.jsonl` とし (= AC1 で配置される Layer 3 placeholder の dev-log JSONL location と整合)、Layer 2 skill (特に `dr-log`) が JSONL append target path として動的読込で参照する.
3. If target project root に既に `.dual-reviewer/` directory が存在する場合, the dr-init skill shall 既存 file を一切上書きせず、conflict を user に報告し、partial write を発生させない.
4. Where user が `--lang ja` option を渡した場合, the dr-init skill shall `config.yaml` に `lang: ja` を設定する.
5. If user が `--lang en` option (or `ja` 以外の任意言語) を渡した場合, the dr-init skill shall 当該起動を out of Phase A scope として reject し、non-zero exit signal + Phase B-1.3 への参照 message を user に報告する.
6. If the dr-init skill が bootstrap を完了できない場合 (filesystem error / permission denied / partial write 検出), the dr-init skill shall 自身が生成した全 state (config.yaml + Layer 3 placeholder を含む全ファイル / directory) を **all-or-nothing で rollback し** (= 部分的に成功した component も削除し target project root を pre-dr-init state に戻す)、failure を non-zero exit signal で報告する; If rollback 自体が完了できない場合 (例: rollback 中の permission denied), the dr-init skill shall non-zero exit signal を返した上で、削除に失敗した残存 file / directory list を stderr に enumeration し、user に手動削除指示を提示する (rollback failure の silent fail を禁止).
7. The dr-init skill shall, target project の `.dual-reviewer/` directory 配下以外の任意 file (`CLAUDE.md` / `.kiro/` / source code 等) を改変しない.

### Requirement 3: 共通 JSON Schema — 失敗構造観測軸 + 修正必要性判定軸 (2 軸並列)

**Objective:** As a Layer 2 extension 実装者 (`dr-design` / `dr-log` / `dr-judgment` 実装者), I want 失敗構造観測軸 (B-1.0 拡張 3 要素) + 修正必要性判定軸 (V4 §1.3 整合) を 2 軸並列で canonical な共通 JSON schema として定義してほしい, so that Layer 2 各 skill が同一 schema に対して generate / validate でき、cross-skill consistency が schema レベルで保証される.

#### Acceptance Criteria

1. The schema definition shall, 1 review session の境界を表す `review_case` JSON schema を提供する (session id / phase / target spec id / timestamps を含む).
2. The schema definition shall, 1 検出を表す `finding` JSON schema を提供する (issue id / source = `primary` | `adversarial` / finding text / severity を含む).
3. The schema definition shall, `impact_score` schema を 3 軸で定義し、各軸の enum を以下に固定する: `severity` = `CRITICAL` / `ERROR` / `WARN` / `INFO` の 4 値 (Severity 4 水準 整合)、`fix_cost` = `low` / `medium` / `high` の 3 値、`downstream_effect` = `isolated` / `local` / `cross-spec` の 3 値.
4. The schema definition shall, **失敗構造観測軸** (B-1.0 拡張、研究 metric 用途) として以下 3 要素を定義する: (a) `miss_type` enum 6 値 = `implicit_assumption` / `boundary_leakage` / `spec_implementation_gap` / `failure_mode_missing` / `security_oversight` / `consistency_overconfidence`、(b) `difference_type` enum 6 値 = `assumption_shift` / `perspective_divergence` / `constraint_activation` / `scope_expansion` / `adversarial_trigger` / `reasoning_depth`、(c) `trigger_state` schema = 3 string enum field (`negative_check` / `escalate_check` / `alternative_considered`、各 field は `applied` または `skipped` の 2 値のみを許容).
5. The schema definition shall, **修正必要性判定軸** (V4 protocol §1.3 整合、judgment subagent 出力 schema) として以下 4 要素を定義する: (a) 必要性 5-field = `requirement_link` (`yes` | `indirect` | `no`) / `ignored_impact` (`critical` | `high` | `medium` | `low`) / `fix_cost` (`high` | `medium` | `low`) / `scope_expansion` (`yes` | `no`) / `uncertainty` (`high` | `medium` | `low`)、(b) `fix_decision.label` = `must_fix` | `should_fix` | `do_not_fix` の 3 値、(c) `recommended_action` = `fix_now` | `leave_as_is` | `user_decision` の 3 値、(d) `override_reason` = optional string field (semi-mechanical mapping default を override した時の理由).
6. While 失敗構造観測軸 と 修正必要性判定軸 は同一 finding に並列付与可能である間, the schema definition shall 両軸を独立 namespace で定義し、片軸のみ存在する finding (例: pre-judgment 段階の primary detection-only state) も schema validate 可能とする; consumer spec (例: `dual-reviewer-dogfeeding`) が独自に追加 field (例: 系統識別 `treatment` / `adversarial_counter_evidence` 等) を `review_case` または `finding` object に付与する場合 schema 拡張として許容され、追加 field の schema 定義 + validate 責務は consumer spec 側にあり、foundation schema は core 2 軸 + AC1-AC5 既定 field のみを normative basis として規定する.
7. The schema definition shall, `fix_decision.label` を **judgment subagent (Step 1c) 完了後の finding (= state = `judged` の final output state)** に対し B-1.0 minimum で `required` として mark し、Step 1c 未完了の intermediate state (AC 6 が許容する pre-judgment / detection-only state) と区別する; この区別は schema 内の finding state field (例: `state: detected | judged`) または同等の schema variant 機構で表現する.
8. The schema definition shall, 機械検証可能な形式 (JSON Schema 標準 or 同等) で表現され、Layer 2 skill が schema 違反時に fail-fast 可能な状態とする.
9. While `miss_type` / `difference_type` / `trigger_state` / 必要性 5-field / `fix_decision.label` / `recommended_action` が B-1.0 minimum の拡張 field である間, the schema definition shall それらを B-1.0 compliance に対し `required` として mark し、B-1.x optional 拡張 (`decision_path` / `skipped_alternatives` / `bias_signal`) と区別する.
10. The foundation shall, JSON Schema files (`review_case` / `finding` / `impact_score` / 失敗構造観測軸 / 修正必要性判定軸) を foundation install location 直下の `schemas/` 相対 directory に配置し、Layer 2 skill (特に `dr-log` / `dr-design` / `dr-judgment`) が schema validate 用に locate 可能な状態とする.

### Requirement 4: seed_patterns.yaml — 23 事例 retrofit 同梱

**Objective:** As a Layer 2 extension 実装者 / dogfeeding 適用者, I want Rwiki dev-log 由来の 23 事例を `seed_patterns.yaml` として package 同梱してほしい, so that dual-reviewer の immutable initial knowledge が新規 project 適用時にも transferable な base として機能する.

#### Acceptance Criteria

1. The `seed_patterns.yaml` shall, Rwiki dev-log 由来の retrofit 事例を厳密に 23 件含む (source = memory `feedback_review_judgment_patterns.md` の検証済 23 patterns、source の entry 数と本 AC が乖離した場合は本 AC を normative basis として優先し、source 側を本 AC に合わせて追加 / 削減して 23 件に整合させる).
2. The `seed_patterns.yaml` shall, 各 entry に `origin` field を `rwiki-v2-dev-log` に設定し、seed source を明示する (downstream consumer が initial knowledge と project-specific accumulation を区別可能とする).
3. The `seed_patterns.yaml` shall, 各 entry を Layer 1 framework が定義する pattern schema (`primary_group` + `secondary_groups` 二層 grouping + 中程度 granularity) に準拠させる.
4. Where Phase A scope が適用される場合, the `seed_patterns.yaml` shall Rwiki 固有名詞を entry text に保持してよく、固有名詞除去 / generalization は Phase B-1.0 release prep に defer する.
5. The `seed_patterns.yaml` shall, top-level `version` field を含み, initial commit 後の更新時には `version` field の明示的増分を必須とする (silent edit を禁止、git diff で観察可能).
6. The `seed_patterns.yaml` shall, foundation install location 直下の `patterns/seed_patterns.yaml` 相対 path で co-distribute され, Layer 2 skill が foundation install location のみから locate 可能な状態とする.

### Requirement 5: fatal_patterns.yaml — 致命級 8 種固定

**Objective:** As a Layer 2 extension 実装者 (Chappy P0 強制照合 quota の実装者), I want 致命級 8 種を `fatal_patterns.yaml` として固定 enum で提供してほしい, so that 設計 review において見落とし不可な致命級カテゴリが Layer 1 quota として強制照合可能になる.

#### Acceptance Criteria

1. The `fatal_patterns.yaml` shall, 厳密に 8 件の固定 entry を含む: `sandbox_escape` / `data_loss` / `privilege_escalation` / `infinite_retry` / `deadlock` / `path_traversal` / `secret_leakage` / `destructive_migration`.
2. The `fatal_patterns.yaml` shall, 各 fatal pattern entry に project 言語での description を含み、reviewer が design 内容に対し当該 pattern を認識できる粒度で記述する.
3. The `fatal_patterns.yaml` shall, B-1.0 で **8 件の enum 識別子 (snake_case key) と各 entry の description text を含む全 content** を固定とする (initial commit 後の addition / removal / renaming / description 改変を禁止)、Layer 2 quota 実装が 8-pattern enum を hardcode しても minor revision で破綻しない状態とする; 多言語対応 (description の英語追加等) は Phase B-1.3 多言語対応 release で別 yaml file (例: `fatal_patterns.en.yaml`) を追加する形で対応し、本 yaml の content には影響しない.
4. The `fatal_patterns.yaml` shall, `seed_patterns.yaml` と同一の foundation install location 直下 (`patterns/fatal_patterns.yaml`) 相対 path で co-distribute される.
5. While `fatal_patterns.yaml` が data source である間, the strict mandatory matching quota 自体は Layer 2 (`dual-reviewer-design-review` spec) で実装される — 本 spec は pattern data の提供のみを責務とし、matching logic は責務外.

### Requirement 6: V4 §5.2 Judgment Subagent Prompt Template — foundation portable artifact

**Objective:** As a Layer 2 extension 実装者 (`dr-judgment` skill 実装者), I want V4 protocol §5.2 で確定した canonical 英語 judgment subagent dispatch prompt 全文を foundation install location 直下に portable artifact として配置してほしい, so that downstream `dr-judgment` skill が同一 prompt template を import でき、judgment 評価基準が project / phase 横断で一貫する.

#### Acceptance Criteria

1. The foundation shall, V4 protocol §5.2 で確定した judgment subagent dispatch prompt 全文を foundation install location 直下の `prompts/judgment_subagent_prompt.txt` 相対 path に配置し、Layer 2 skill が foundation install location のみから locate 可能な状態とする.
2. The prompt template shall, V4 protocol §5.2 (`.kiro/methodology/v4-validation/v4-protocol.md` §5.2) と内容上同一 (canonical SSoT 関係) であり、minor 差異 (空白 / 改行) を除き byte-level に整合する; SSoT の sync 参照対象は `v4-protocol.md` §5.2 のみとし、`docs/過剰修正バイアス.md` (= v4-protocol.md の upstream design source) は foundation scope 外として扱う (= foundation の同期責任は v4-protocol.md との 1-hop sync に限定、過剰修正バイアス.md → v4-protocol.md の上流 sync は v4-protocol 管理者の責務).
3. The prompt template shall, 必要性 5-field schema (`requirement_link` / `ignored_impact` / `fix_cost` / `scope_expansion` / `uncertainty`) の評価指示を含む.
4. The prompt template shall, semi-mechanical mapping default 7 種 (V4 §1.4.2: AC linkage direct → `requirement_link=yes` + `ignored_impact=high` 等の 7 ルール) の埋込文字列を含む.
5. The prompt template shall, 5 条件判定ルール (V4 §1.4.1: critical impact / requirement_link+ignored_impact / scope_expansion / fix_cost vs ignored_impact / uncertainty) の順次評価指示を含む.
6. The prompt template shall, 出力 yaml format 規約 (`fix_decision.label` + 必要性 5 fields + `recommended_action` + `override_reason` if any) を含む.
7. The prompt template shall, prompt 言語を英語固定 (single canonical form、subagent 安定性のため) とし、project 言語 (`config.yaml` `lang` field) の影響を受けない.
8. While the prompt template が canonical SSoT である間, the foundation shall content の変更を V4 protocol (= `v4-protocol.md` §5.2) の改訂と同期させ、本 spec 単独での無断改変 (V4 protocol 未更新での内容変更) を禁止する.
9. The foundation shall, downstream `dr-judgment` skill が prompt template を import するための relative path 規約を foundation install location からの相対 path 1 つに固定し (`./prompts/judgment_subagent_prompt.txt`)、複数の location candidate を expose しない.
10. The foundation shall, AC 8 の同期を実装するための具体的 mechanism (例: file header に V4 protocol version 参照を記載 / build script による automated sync / hash 比較による drift detection 等) を本 spec の design phase で確定する.

### Requirement 7: 用語抽象化 + 多言語 Policy + 設定 Abstraction

**Objective:** As a future model 切替 / 多言語展開を見据える maintainer, I want role 用語 / section 見出し / schema field / prompt 言語に対する一貫した抽象化と多言語 policy を foundation で確定してほしい, so that 後続 spec / B-1.x release で model や言語を変更しても spec 側の AC を書き換える必要が出ない.

#### Acceptance Criteria

1. The Layer 1 framework shall, reviewer role を `primary_reviewer` / `adversarial_reviewer` / `judgment_reviewer` の 3 抽象名でのみ参照し, 具体的 model name (`Opus` / `Sonnet` 等) を framework definition 内で使用しない (具体 model 選択は `config.yaml` `primary_model` / `adversarial_model` / `judgment_model` field に defer、V4 protocol §1.2 option C 整合).
2. Where foundation が任意 artifact (config / schema doc / pattern yaml comments) に section heading を生成する場合, the foundation shall 該当 heading を bilingual form (project 言語 + 英語 label) で記述する.
3. The schema field labels shall, transferability のため英語固定とする (`severity` / `miss_type` / `difference_type` / `trigger_state` / `requirement_link` / `ignored_impact` / `fix_decision` / `recommended_action` 等); 該当 field の自由記述 content は project 言語で記述してよい.
4. The Layer 1 framework が提供する prompt template (`forced_divergence` prompt / V4 §5.2 judgment subagent prompt 等) shall, prompt 言語を英語固定 (single canonical form) とし、project 言語に依存しない; subagent 出力言語は document context から auto-detect される; ただし `forced_divergence` prompt の最終文言確定は `dual-reviewer-design-review` spec の design phase 責務であり、本 spec は V4 §5.2 judgment subagent prompt template の portable artifact 配置 (Req 6) のみを責務とし、`forced_divergence` prompt template の content 確定は本 spec の scope 外とする.
5. The `terminology.yaml` placeholder (the dr-init skill が生成) shall, top-level `version` field と空の `entries` list を含み、entry の実体的蓄積は Phase A-2 dogfeeding 以降 (target 30-50 entries は Phase B-1.2 まで延伸) に defer される.
