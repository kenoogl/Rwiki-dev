# Requirements Document

## Project Description (Input)

dual-reviewer (LLM 設計レビュー方法論 v3 一般化 package) を Layer 1/2/3 三層構造で組み立てるには、phase 横断の framework + project bootstrap + 共通 JSON schema + initial seed (23 事例 + fatal patterns) が揃っている必要がある。これらが先行整備されないと、`dr-design` / `dr-log` skill が単独で機能できず、Phase A-2 (Spec 6 dogfeeding) も実行不可。

ドラフト v0.3 (`.kiro/drafts/dual-reviewer-draft.md`) §2.1 で Layer 1 framework 骨組み確定、§2.9 で 23 事例 retrofit 仕様確定 (`seed_patterns.yaml`、Rwiki 由来)、§2.6 で Chappy P0 採用 3 件確定 (うち `fatal_patterns.yaml` 8 種固定)、§2.10.3 で B-1.0 拡張 schema 3 要素 (`miss_type` / `difference_type` / `trigger_state`) 確定。実装は未着手。

本 spec は dual-reviewer の core 基盤 (Layer 1 framework + `dr-init` skill + 共通 JSON schema + `seed_patterns.yaml` + `fatal_patterns.yaml`) を稼働可能にし、`dual-reviewer-design-review` / `dual-reviewer-dogfeeding` が依存する全要素を提供する。Phase A scope = Rwiki repo 内 prototype 段階、B-1.0 minimum 3 skills のうち `dr-init` 部分を担当。詳細は brief.md (`.kiro/specs/dual-reviewer-foundation/brief.md`) 参照。

## Introduction

dual-reviewer-foundation は dual-reviewer (LLM 設計レビュー方法論 v3 一般化 package) の Layer 1 基盤を提供する。phase 横断の Layer 1 framework + project bootstrap (`dr-init` skill) + 共通 JSON schema + 初期 seed (23 事例 retrofit + 致命級 8 種固定) を整備し、依存 spec である `dual-reviewer-design-review` (Layer 2 design extension + `dr-design` / `dr-log` skill) と `dual-reviewer-dogfeeding` (Spec 6 への適用 + 対照実験) が機能可能になる contract を確立する。Phase A scope (Rwiki repo 内 prototype 段階) で動作し、Phase B 独立 fork は本 spec の対象外。

primary 参照点:

- ドラフト v0.3 = `.kiro/drafts/dual-reviewer-draft.md` §2.1 / §2.6 / §2.9 / §2.10.3 / §3 / §4
- memory = `~/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/feedback_design_review_v3_generalization_design.md` §1-14
- retrofit 元 = `~/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/feedback_review_judgment_patterns.md` (23 事例)

## Boundary Context

- **In scope**:
  - Layer 1 framework 骨組み (Step A/B/C 構造 + bias 抑制 quota + 中程度 granularity の pattern schema)
  - `dr-init` skill (project bootstrap、`.dual-reviewer/` 構造 + `config.yaml` 雛形 + Layer 3 placeholder ディレクトリ生成)
  - 共通 JSON schema 定義 (`review_case` / `finding` / `impact_score` 3 軸 / B-1.0 拡張 schema 3 要素 = `miss_type` / `difference_type` / `trigger_state`)
  - `seed_patterns.yaml` (23 事例 retrofit、Rwiki 固有名詞付きで OK、`origin: rwiki-v2-dev-log`)
  - `seed_patterns_examples.md` (人間可読、各 pattern の具体例)
  - `fatal_patterns.yaml` (致命級 8 種固定: sandbox escape / data loss / privilege escalation / infinite retry / deadlock / path traversal / secret leakage / destructive migration)
  - 上記要素を downstream spec が import / load 可能にする提供 contract
- **Out of scope**:
  - `dr-design` / `dr-log` skill 実装 (`dual-reviewer-design-review` 担当)
  - Layer 2 phase extension (design extension は `dual-reviewer-design-review`、tasks / requirements / implementation extension は B-1.x 別 spec)
  - Spec 6 dogfeeding 適用 + 対照実験 (`dual-reviewer-dogfeeding` 担当)
  - cycle automation (Run-Log-Analyze-Update) — `dr-extract` / `dr-update` は B-1.2
  - 並列処理 + 整合性 Round 6 task 本格実装 (B-1.x 以降)
  - multi-vendor / multi-subagent / hypothesis generator role 3 体構成 (B-2 以降)
  - B-1.x 拡張 schema 実装 (`decision_path` / `skipped_alternatives` / `bias_signal`)
  - generalization (固有名詞除去) / npm package 化 (Phase B-1.0 release prep)
  - forced divergence prompt template (`dual-reviewer-design-review` 内 adversarial subagent prompt の責務)
  - `impact_score` の生成・記録 logic (`dual-reviewer-design-review` 内 `dr-log` skill。本 spec は schema 定義のみ)
  - `--integrate-cc-sdd` flag の本格実装 (B-1.3 担当。B-1.0 では `dr-init` skill placeholder のみで具体実装は本 spec の範囲外)
- **Adjacent expectations**:
  - `dual-reviewer-design-review` は本 spec の Layer 1 framework + 共通 JSON schema + `fatal_patterns.yaml` + `seed_patterns.yaml` を import / load して `dr-design` / `dr-log` skill を実装する
  - `dual-reviewer-dogfeeding` は本 spec + `dual-reviewer-design-review` の prototype を Spec 6 design に適用し対照実験 (single vs dual) を実施する
  - Rwiki 既存 spec (Spec 0-7) と機能的に独立し cross-spec dependency を持たない。Phase A 期間中は Rwiki repo 内 prototype 配置のみで Rwiki spec を改変しない
  - `feedback_review_judgment_patterns.md` (memory) の 23 事例が `seed_patterns.yaml` retrofit 元データの正本

## Requirements

### Requirement 1: Layer 1 framework 骨組み

**Objective:** dual-reviewer prototype 開発者として、phase 横断で再利用可能な framework 骨組みを利用したい。これにより、各 phase extension (design / tasks / req / impl) が共通 base 上で実装でき、bias 抑制と pattern matching が一貫した方法で機能する。

#### Acceptance Criteria

1. The Layer 1 framework shall Step A/B/C 構造 (primary detection → adversarial review → integration) を phase 横断で再利用可能な形式 (具体的提供 form = 関数 / class / config / yaml / markdown のいずれか、design phase で確定) で定義する
2. The Layer 1 framework shall bias 抑制 quota (formal challenge / 検出漏れ / Phase 1 同型探索 / `fatal_patterns.yaml` 強制照合 / forced divergence) を event-triggered 介入として定義し、Tier 比率は post-run measurement only (pre-run target setting は Goodhart's Law 回避のため含めない) と規定する。Layer 1 は quota の存在および採用方針を規定するに留め、forced divergence prompt template の具体生成 logic 等は Layer 2 design extension の責務 (Boundary Out 整合)。Layer 2 design extension は Layer 1 quota を継承し、`厳しく検証 5 種` / `escalate 必須条件 5 種` 等を追加した design phase quota (draft v0.3 §2.7) として発動する
3. The Layer 1 framework shall pattern schema を primary_group + secondary_groups の二層構造 (中程度 granularity、primary_group の数 / secondary_groups の種類数の具体定義は design phase で確定) で定義する
4. Where Layer 2 phase extension が Step A/B/C や quota を拡張する場合, the Layer 1 framework shall extension point (phase 別 hook + quota 追加点) を提供する
5. The Layer 1 framework shall phase 別 review logic を含めない (= Layer 2 phase extension 側の責務)

### Requirement 2: dr-init skill による project bootstrap

**Objective:** dual-reviewer 利用者として、`dr-init` skill を実行するだけで dual-reviewer 配置を準備したい。これにより、project 固有の Layer 3 ディレクトリ + config 雛形が一括生成され、利用者が手動で構造を作る必要がなくなる。skill 配置 path は Req 6 AC 6.5 を参照。

#### Acceptance Criteria

1. When `dr-init` skill が起動される, the dr-init skill shall `.dual-reviewer/` ディレクトリ構造を project ルートに生成する
2. When `dr-init` skill が起動される, the dr-init skill shall `config.yaml` 雛形 (`primary_model` / `adversarial_model` / `language` 等の placeholder 値で記載、project 固有の Layer 3 path 分離構造を含む) を生成する
3. When `dr-init` skill が起動される, the dr-init skill shall Layer 3 placeholder ディレクトリ群 (`extracted_patterns/` / `terminology/` / `dev_log/` / `tier_measurements/`) を生成する (`.gitignore` 更新責務 = Layer 3 placeholder の git 管理方針 = は design phase で確定する)
4. If `.dual-reviewer/` ディレクトリが既存, then the dr-init skill shall 既存ファイルを上書きせず保持し不足分のみ生成する (idempotent、`config.yaml` が既存の場合も上書き禁止 = 保持。`config.yaml` の schema 非互換改版 = upgrade scenario における挙動は design phase で確定する。本 spec scope = single version)
5. The dr-init skill shall 生成した全ファイルおよびディレクトリを標準出力に記録する
6. If `dr-init` skill が file system error (権限不足 / disk full / 不正パス等、具体 failure mode 列挙は design phase で確定する) で生成に失敗, then the dr-init skill shall actionable error message を出力し partial 生成物を残さない (atomic 操作 vs 失敗時 cleanup の選択 + SIGINT / SIGTERM 等の中断 signal 取扱は design phase で確定する)

### Requirement 3: 共通 JSON schema 定義

**Objective:** dual-reviewer 利用者として、`review_case` と `finding` を構造化記録するための共通 JSON schema が定義され、downstream spec が validate に使用できる状態を望む。これにより、`dr-log` skill の JSONL 出力が schema 準拠で検証可能になり、論文用 quantitative evidence (figure 1-3) 取得の前提が整う。

#### Acceptance Criteria

1. The 共通 JSON schema shall `review_case` object を以下 field で定義する: id / phase / timestamp / round / primary_findings (= `finding.id` の配列) / adversarial_findings (= `finding.id` の配列) / integration_result / trigger_state (`trigger_state` は review_case = run level の実行制御状態であり、finding level の `miss_type` / `difference_type` とは異なる粒度。`primary_findings` / `adversarial_findings` の値型 = `finding.id` の配列で、JSONL のフラット構造 = 1 review_case = 1 line + 1 finding = 1 line で外部キー紐付け、`dual-reviewer-design-review` Req 5 AC 5.2 連鎖)
2. The 共通 JSON schema shall `finding` object を以下 field で定義する: id / round / origin / description / impact_score / miss_type / difference_type (severity は impact_score 内に統合する、draft v0.3 §2.6「既存 severity を 3 軸 impact_score に拡張」と整合。`difference_type` は optional field = single mode 実行時の finding は absent 許容 / `origin` field 値範囲 = `primary` / `adversarial` の 2 値 enum / `dual-reviewer-design-review` Req 6 AC 6.6 連鎖)
3. The 共通 JSON schema shall `impact_score` を 3 軸 object (severity / fix_cost / downstream_effect) として定義する
4. The 共通 JSON schema shall `impact_score.severity` を CRITICAL / ERROR / WARN / INFO の 4 値 enum として定義する (Rwiki steering の severity 体系に整合)
5. The 共通 JSON schema shall `impact_score.fix_cost` および `impact_score.downstream_effect` を有限値 enum で表現する (具体 enum 値は design phase で確定する)
6. The 共通 JSON schema shall `miss_type` を 6 値 enum (implicit_assumption / boundary_leakage / spec_implementation_gap / failure_mode_missing / security_oversight / consistency_overconfidence) として定義する
7. The 共通 JSON schema shall `difference_type` を 6 値 enum (assumption_shift / perspective_divergence / constraint_activation / scope_expansion / adversarial_trigger / reasoning_depth) として定義する
8. The 共通 JSON schema shall `trigger_state` を 3 軸 object (negative_check / escalate_check / alternative_considered、各 applied | skipped の 2 値 enum) として定義する
9. The 共通 JSON schema shall JSON Schema Draft 標準形式 (具体版 = Draft 2020-12 / Draft-07 等の選定は design phase で確定) で表現される (jsonschema 等の validator で検証可能)

### Requirement 4: seed_patterns.yaml (23 事例 retrofit)

**Objective:** dual-reviewer 利用者として、Rwiki dev-log 由来の 23 事例 retrofit を初期 seed として package に同梱したい。これにより、Phase A 開始時点で empirical な pattern set が利用可能となり、`dr-design` skill が pattern matching に使用できる。

#### Acceptance Criteria

1. The seed_patterns.yaml shall 23 件の retrofit pattern (`feedback_review_judgment_patterns.md` 由来、entry 数 23 は memory ファイルの実 count を design phase で検証する) を yaml 形式で記載する
2. The seed_patterns.yaml shall 全 entry に `origin: rwiki-v2-dev-log` を付与する
3. The seed_patterns.yaml shall Rwiki 固有名詞を保持する (Phase A scope では generalization 不要、除去は Phase B-1.0 release prep の責務であり本 spec の範囲外)
4. The seed_patterns.yaml shall Layer 1 framework が定義する pattern schema (中程度 granularity + primary_group + secondary_groups) に準拠し、domain tag は付与しない (8 メタ群 + 中程度 granularity で domain 横断、固有性は concrete レベルのみ、draft v0.3 §2.9 規範)
5. The seed_patterns.yaml shall 補足ドキュメント `seed_patterns_examples.md` (各 pattern の人間可読な具体例) と組合せて同梱される
6. Where downstream spec の `dr-design` が pattern matching を実行する場合, the seed_patterns.yaml shall stable file path から load 可能である

### Requirement 5: fatal_patterns.yaml (致命級 8 種固定)

**Objective:** dual-reviewer 利用者として、致命級 8 種 anti-pattern を初期 seed として package に同梱したい。これにより、`dr-design` skill が強制照合 quota (Chappy P0) で必ず参照し、致命級漏れを構造的に防止できる。

#### Acceptance Criteria

1. The fatal_patterns.yaml shall 正確に 8 件の致命級 pattern (sandbox escape / data loss / privilege escalation / infinite retry / deadlock / path traversal / secret leakage / destructive migration) を含む
2. The fatal_patterns.yaml shall 各 pattern について name / description / detection_hints の structured field を含む形式で記載する
3. The fatal_patterns.yaml shall Layer 2 design extension の強制照合 quota で参照可能な形式で表現される (downstream skill の内部参照運用は Layer 2 側責務、本 spec は形式の提供まで)
4. The fatal_patterns.yaml shall pattern 名と detection_hints を domain 横断で機能する記述とする (Rwiki 固有事例の reference は OK)
5. Where downstream spec の `dr-design` が強制照合 quota を実行する場合, the fatal_patterns.yaml shall stable file path から load 可能である
6. The fatal_patterns.yaml shall Phase A 期間中 immutable (8 種固定。将来の変更方針は Phase B-2 での検討事項であり本 spec の規定外)

### Requirement 6: Downstream spec 提供 contract

**Objective:** `dual-reviewer-design-review` および `dual-reviewer-dogfeeding` 開発者として、本 spec が提供する全要素を一貫した interface で import / load したい。これにより、downstream spec が依存解決を機械的に行え、本 spec の internal 実装詳細を知らずに済む。

#### Acceptance Criteria

1. The dual-reviewer-foundation shall Layer 1 framework を stable import path で公開する
2. The dual-reviewer-foundation shall 共通 JSON schema を stable file path で公開する (Phase A scope = single version、版数管理の placeholder のみ)
3. The dual-reviewer-foundation shall seed_patterns.yaml および seed_patterns_examples.md を stable file paths で公開する
4. The dual-reviewer-foundation shall fatal_patterns.yaml を stable file path で公開する
5. The dual-reviewer-foundation shall dr-init skill を `.claude/skills/dr-init/SKILL.md` 形式 (Rwiki repo の `.claude/skills/kiro-*/SKILL.md` と同形式) で公開する (downstream spec から `/dr-init` 起動可能)
6. Where downstream spec が依存要素を load する場合, the dual-reviewer-foundation shall internal 実装詳細を露出せず loadable artifact のみ提供する (encapsulation 検証基準は design phase で確定)
7. If downstream spec が artifact load に失敗, then the dual-reviewer-foundation shall actionable error message (どの artifact が missing / malformed か) を提供する (malformed 検出粒度 = syntax check / schema validation のいずれか、および具体的 error 提供 agent = dr-init skill / schema validator / runtime のいずれか、は design phase で確定する)
