# Research & Design Decisions — dual-reviewer-foundation

## Summary

- **Feature**: `dual-reviewer-foundation`
- **Discovery Scope**: New Feature (greenfield prototype) + Extension element (kiro skill 形式 + Rwiki tech stack 整合)
- **Key Findings**:
  - 23 retrofit pattern (`feedback_review_judgment_patterns.md`) は既に primary_group 8 群 (A-H) + secondary 各 2-3 種 = 合計 23 種の構造を持つ → pattern_schema.yaml の primary_groups / secondary_groups 二層 schema で逆算採用 (F-2 確定根拠)
  - Rwiki tech.md severity 体系 (CRITICAL / ERROR / WARN / INFO) と foundation Req 3 AC 4 が一致 → impact_score.severity enum で直接継承 (差分作業なし)
  - JSON Schema Draft 2020-12 は `jsonschema` Python lib (≥4.18) で full support、Phase A prototype = Python 3.10+ 環境と整合 → F-7 確定根拠
  - Claude Code skill 形式 (`.claude/skills/{name}/SKILL.md` + frontmatter `name`/`description`/`allowed-tools`/`argument-hint`) を `.claude/skills/kiro-spec-init/SKILL.md` 等の既存実装で確認 → `dr-init` skill 同形式採用 (Req 6 AC 5 整合)
  - Phase A scope では prototype 配置を `scripts/dual_reviewer_prototype/` (Rwiki structure.md `scripts/` 配下方針整合) に確定、`.kiro/specs/dual-reviewer/prototype/` 案は spec metadata + prototype code 混在で却下

## Research Log

### Topic: 23 retrofit pattern の primary_group / secondary_groups 構造逆算

- **Context**: foundation Req 1 AC 3 = pattern schema を primary_group + secondary_groups の二層構造で定義する必要があるが、具体的 group 数 / 種類数は defer (F-2)。23 retrofit pattern (memory `feedback_review_judgment_patterns.md`) の現実構造を調査して逆算する必要があった。
- **Sources Consulted**: `~/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/feedback_review_judgment_patterns.md` (23 パターンチェックリスト全件)
- **Findings**:
  - 既に 8 群分類が memory 内で確立: A 内部矛盾系 (3 種) / B 実装不可能性 - 逆算系 (3 種) / C 責務境界系 (3 種) / D 規範範囲判断系 (3 種) / E failure - 状態系 (3 種) / F concurrency - timeout 系 (3 種) / G 整合性 - SSoT 系 (3 種) / H 選択肢系 (2 種)
  - 合計: 8 primary group × 平均 2.875 secondary = 23 種、draft v0.3 §2.9 の「8 メタ群 + 中程度 granularity」記述と完全整合
- **Implications**: pattern_schema.yaml の primary_groups = 8 群 (A-H)、secondary_groups = 各群 2-3 種で確定可能。F-2 を確定方針 (`primary_group = 8`、`secondary_groups = 各群 2-3 種、合計 23 種`) として design.md Design Decisions に転写。

### Topic: JSON Schema Draft 版選定

- **Context**: foundation Req 3 AC 9 = JSON Schema Draft 標準形式で表現する必要があるが、Draft 2020-12 / Draft-07 等の選定は defer (F-7)。最新 stable + Python validator サポートで判断。
- **Sources Consulted**: `jsonschema` Python lib documentation (https://python-jsonschema.readthedocs.io/、library 内蔵 metaschema)
- **Findings**:
  - Draft 2020-12 は最新 stable、`jsonschema` Python lib は v4.18 以降で full support
  - Draft-07 は legacy だが幅広いサポート、Draft 2020-12 は新機能 (`unevaluatedProperties` / `$dynamicRef` / `prefixItems`) で型表現力高い
  - Phase A prototype は新規実装で legacy compatibility 制約なし → 最新採用
- **Implications**: F-7 = Draft 2020-12 確定。全 schema file の `$schema` field に `https://json-schema.org/draft/2020-12/schema` を declare。

### Topic: `phase1_meta_pattern` JSON Schema 表現方式

- **Context**: foundation Req 3 AC 10 = `phase1_meta_pattern` を 3 値 enum + null の optional field として定義、escalate 検出 finding にのみ付与、その他は absent (key なし) または null (key あり値 null) のいずれも validator 受容する必要がある。実装方式 (`nullable: true` / `not required`) のいずれを default とするかは defer (F-8)。
- **Sources Consulted**: JSON Schema Draft 2020-12 spec (https://json-schema.org/draft/2020-12/json-schema-core.html)、jsonschema Python lib type system documentation
- **Findings**:
  - Draft 2020-12 では `nullable: true` (OpenAPI 拡張記法) は標準でサポートされず、標準的な null 許容表現は `type: ["string", "null"]` の union 表現
  - `not required` (= optional field) と上記 union 型は併用可能、両方適用すれば「key absent (not required) も値 null (union type) も両方 valid」を実現
  - jsonschema Python lib は両方の表現を受容
- **Implications**: F-8 = `type: ["string", "null"]` union 表現を default、`not required` も併用受容。design.md `extension_fields.schema.json` で具体記法を提示。

### Topic: dr-init skill atomic 操作 + signal handling

- **Context**: foundation Req 2 AC 6 = file system error 時に actionable error + partial 生成物を残さない (atomic 操作 vs 失敗時 cleanup の選択 + SIGINT/SIGTERM 中断 signal 取扱は defer F-5)。Phase A prototype scope で実装可能な atomic 戦略を確定する必要があった。
- **Sources Consulted**: Python `os.rename` atomic guarantee documentation、`signal` module documentation、Rwiki tech.md の subprocess timeout 必須思想
- **Findings**:
  - Posix file system では同 partition 内の `os.rename` は atomic 保証 (POSIX 2008)
  - 戦略: temp directory (`<project>/.dual-reviewer.tmp.<pid>/`) を作成 → 全 artifact 雛形を temp 内に生成 → atomic rename で `.dual-reviewer/` に移動
  - SIGINT / SIGTERM は `signal.signal(SIGINT, handler)` で signal handler 登録、handler 内で temp dir cleanup 後 sys.exit (graceful shutdown)
  - failure mode 列挙: (a) 親ディレクトリ書込権限不足 (Permission denied) / (b) disk full (ENOSPC) / (c) 不正パス (path traversal 試行 / project root 外 path) / (d) 同名 directory 既存で `--force` なし / (e) symlink 干渉 (`.dual-reviewer/` が既存 symlink)
- **Implications**: F-5 = atomic temp + rename 確定、SIGINT/SIGTERM signal handler で cleanup。failure mode 5 種を design.md Error Handling section に列挙。

### Topic: encapsulation 検証基準 (Python project 環境)

- **Context**: foundation Req 6 AC 6 = downstream spec が依存要素を load する場合、internal 実装詳細を露出せず loadable artifact のみ提供する。検証基準は defer (F-9)。Python prototype 環境での実用的な encapsulation 表明方式を確定する必要があった。
- **Sources Consulted**: Python convention (PEP 8 underscore prefix)、`__init__.py` explicit export pattern、import path mechanics
- **Findings**:
  - Python は強制的な access modifier を持たない (Java の `private` / TypeScript の `private` 相当なし)、convention = `_` prefix で internal 表現
  - `__init__.py` で explicit `from ._internal import X` を **書かず**、public API のみ `from .schema_validator import validate_review_case` 等で export → external import 経由では internal 名は reach できない
  - test で `from loader._internal import X` が possible だが、それは test 用 escape hatch として許容、external consumer は `loader/` package を `__init__.py` 経由でのみ使用
  - 検証 = `tests/test_encapsulation.py` で (a) `from loader import <public_name>` が成功 / (b) `dir(loader)` に internal symbol が含まれない / (c) public API 経由のみで全 functional path が完結することを assert
- **Implications**: F-9 = Python `_` prefix private + `__init__.py` explicit export + 既存 import path test。design.md Loader component の Implementation Notes に test strategy 反映。

### Topic: malformed 検出粒度 + error 提供 agent

- **Context**: foundation Req 6 AC 7 = downstream spec が artifact load に失敗した場合、actionable error message (どの artifact が missing / malformed か) を提供する。malformed 検出粒度 (syntax check / schema validation のいずれか) + 具体的 error 提供 agent (dr-init skill / schema validator / runtime のいずれか) は defer (F-10)。
- **Sources Consulted**: jsonschema Python lib `Draft202012Validator.iter_errors()` API、dr-init skill responsibility scope (Req 2 AC 6)
- **Findings**:
  - 粒度: syntax check (yaml/json parse error) のみではユーザーにとって低価値、schema validation (Draft 2020-12 metaschema validate + 同梱 schema 経由 instance validate) で「どの field が schema 違反か」まで報告すれば actionable
  - agent: runtime に検出を任せると downstream skill 各々で実装重複、`dr-init` skill 起動時 (project bootstrap 直後) に同梱 artifact 全件 validate して即座に actionable error を出す方が責務集約
  - error message format: `<artifact_path>` + `<failure mode (yaml_malformed | schema_violation | entry_count_mismatch | etc)>` + `<reason 詳細>` + `<recovery hint>` の 4 要素
- **Implications**: F-10 = schema validation 粒度 + dr-init skill が責任主体。design.md dr-init component の Step 4 (validation) + Loader API `ArtifactLoadError` で error format 規定。

### Topic: 教訓 1-4 の foundation 適用判定

- **Context**: 6th セッション req approve 直前で得た教訓 11 件 (memory `feedback_v3_adoption_lessons_phase_a.md`) のうち、教訓 1-4 を A-0 design phase 開始時に AC 化する具体策が指針として用意されていた。foundation 範囲で組込むべきか Out of Boundary とするか判定。
- **Sources Consulted**: memory `feedback_v3_adoption_lessons_phase_a.md` 全件、foundation requirements.md Out of scope 記述、defer list F-1〜F-10
- **Findings**:
  - 教訓 1 (3 段階 review pattern): Layer 2 design extension への組込 → `dual-reviewer-design-review` 責務 (foundation Out of Scope の "Layer 2 phase extension" 該当)
  - 教訓 2 (Step 1b 5 重検査): design-review Req 3 AC 5 拡張 → `dual-reviewer-design-review` 責務
  - 教訓 3 (cross-spec contract 検証): design-review Req 3 新 AC → `dual-reviewer-design-review` 責務
  - 教訓 4 (defer 集約 process): `dr-init` skill の post-process step または専用 skill (`dr-defer-collect`、B-1.x 候補) → 本 spec scope の `dr-init` には minimum bootstrap のみ、defer 集約 skill 化は B-1.x 以降 (foundation Out of Scope の "B-1.x 拡張 schema 実装" / "cycle automation" 関連)
- **Implications**: 教訓 1-4 すべて foundation Out of Boundary に該当、design.md の Out of Boundary section に明記。判断変更 (例: 教訓 4 を `dr-init` 内に組込) は Revalidation Triggers 該当として扱う。

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Layered artifact provider | foundation = 静的 artifact 群 (yaml/json/markdown) + minimum executable (`dr-init` skill のみ) | portable + declarative + Phase B fork 容易 + reduce executable surface | declarative artifact のみで Layer 1 quota 5 種を表現する難易度 | **採用**。Phase A scope に最適、Layer 2 で executable logic を追加する分離が clean |
| Service-oriented framework | Layer 1 を Python class library として全 quota / pattern matching / Step A/B/C を class hierarchy で表現 | type safety 強、IDE support | Phase A scope の executable surface 過大、generalization (B-1.0 release prep) で multi-language support 困難 | 却下。Phase B-2 で再評価候補だが MVP には overengineering |
| Single mega-skill | Layer 1 + dr-init を 1 つの skill として統合実装 | minimal file count、initial bootstrap 容易 | Layer 2 design extension が Layer 1 framework を独立に reference できない、Boundary 不明確 | 却下。downstream import の独立性が損なわれる |

## Design Decisions

### Decision: yaml + markdown hybrid for Layer 1 framework form (F-1 解決)

- **Context**: foundation Req 1 AC 1 = Step A/B/C 構造の具体提供 form (関数 / class / config / yaml / markdown のいずれか) は design phase で確定する必要があった。
- **Alternatives Considered**:
  1. yaml only — quota / schema は構造化 yaml で表現可能だが、Step A/B/C の workflow 記述は narrative 必要で yaml に押し込むと不自然
  2. markdown only — workflow 記述は markdown が自然だが、quota 5 種 / pattern_schema 8 群を markdown でしか表現できないと machine 検証困難
  3. yaml + markdown hybrid — workflow narrative = markdown / quota / schema = yaml で各々最適 form
- **Selected Approach**: yaml + markdown hybrid。`framework/step_abc.md` (workflow markdown) / `framework/quotas.yaml` (quota yaml) / `framework/pattern_schema.yaml` (schema yaml) / `framework/intervention_framework.md` (markdown) / `framework/extension_points.md` (markdown)
- **Rationale**: Phase A scope = portable + LLM 読込容易、yaml は machine validate / markdown は narrative 表現 = 両者の強みを活かす。defer list 推奨方針 (yaml / markdown 推奨) と整合。
- **Trade-offs**:
  - 利点: 各 form が責務に最適 / portable / LLM (Claude) prompt context として両方読込容易
  - 妥協: file 数増 (5 file)、ただし Phase A scope では minimum 程度
- **Follow-up**: A-1 prototype 実装時に各 file の content draft + Layer 2 design extension からの consume 方式確認

### Decision: pattern_schema primary_group = 8 / secondary 合計 23 (F-2 解決)

- **Context**: 23 retrofit pattern の primary_group 数 / secondary_groups 種類数を defer。具体構造を確定する必要があった。
- **Alternatives Considered**:
  1. primary_group = 5 群、secondary 合計 23 — 階層を浅くしてアクセス性向上だが既存 dev-log 学習 23 種の自然分類と整合せず
  2. primary_group = 8 群、secondary 各 2-3 種 = 23 — `feedback_review_judgment_patterns.md` の現実構造を逆算
  3. primary_group = なし (flat 23 種) — schema 簡素化だが粒度操作不可
- **Selected Approach**: 8 primary_group (A-H) + secondary 各 2-3 種 (合計 23 種)。primary_group naming = `internal_contradiction` / `implementation_infeasibility` / `responsibility_boundary` / `norm_range` / `failure_state` / `concurrency_timeout` / `consistency_ssot` / `option_choice`
- **Rationale**: 既存 dev-log 学習構造の自然採用 + draft v0.3 §2.9 「8 メタ群 + 中程度 granularity」記述と完全整合 + Layer 2 design extension の pattern matching 階層 hint として 8 群レベルで coarse classification 可能
- **Trade-offs**:
  - 利点: 既存 23 retrofit と 1:1 対応、generalization (B-1.0 release prep) でも 8 群構造維持可
  - 妥協: 8 という数の固定性、新 pattern 追加時に 8 群への分類整理コスト発生 (B-1.x で `dr-extract` skill 化時に対応)
- **Follow-up**: A-1 prototype 実装時に `pattern_schema.yaml` で 8 group + 23 secondary 完全列挙

### Decision: prototype 配置 = `scripts/dual_reviewer_prototype/` (draft v0.3 候補確定)

- **Context**: draft v0.3 §3.1 で prototype 配置 = `scripts/dual_reviewer_prototype/` または `.kiro/specs/dual-reviewer/prototype/` 候補のまま未確定。foundation design phase で確定する必要があった。
- **Alternatives Considered**:
  1. `scripts/dual_reviewer_prototype/` — Rwiki structure.md `scripts/` 配下方針 (rw_cli.py 等) 整合、prototype = scripts 配下の Python prototype 性質と一致
  2. `.kiro/specs/dual-reviewer/prototype/` — kiro spec 内に prototype を抱える構造、spec metadata と prototype code 混在
  3. `prototype/` (root) — Phase B fork 時に root から package 化容易、ただし Rwiki 構造への影響大
- **Selected Approach**: `scripts/dual_reviewer_prototype/`
- **Rationale**: (a) Rwiki structure.md `scripts/rw_cli.py` 等の Python script 配下方針整合、(b) `.kiro/specs/...prototype/` だと spec metadata (requirements.md / design.md / tasks.md) と prototype code 混在で kiro 設計と不整合、(c) Phase B fork 時に `scripts/dual_reviewer_prototype/` → 独立 repo `dual-reviewer/` への migration が cp + cleanup で完結
- **Trade-offs**:
  - 利点: Rwiki 構造整合 / Phase B migration 容易 / spec ↔ code 分離 clean
  - 妥協: Rwiki repo に dual-reviewer 用 directory が増えるが、Phase A scope のみ
- **Follow-up**: A-1 prototype 実装開始時に `scripts/dual_reviewer_prototype/` 作成、Phase B fork 時に migration

### Decision: Build vs Adopt = jsonschema + pyyaml (Python lib adopt)

- **Context**: schema validator + yaml loader を build か adopt か。Phase A scope での implementation cost vs maintenance burden を判断。
- **Alternatives Considered**:
  1. jsonschema + pyyaml (adopt) — Python ecosystem standard、Draft 2020-12 full support、active maintenance
  2. ad-hoc validator (build) — 制御細かいが maintenance cost、Draft 2020-12 仕様 full support は coding 困難
  3. cerberus / voluptuous (adopt alternative) — Python validator 候補だが JSON Schema 標準準拠なし、generalization (Phase B 多言語) で互換性損失
- **Selected Approach**: jsonschema + pyyaml adopt
- **Rationale**: Python ecosystem standard、JSON Schema Draft 2020-12 full support、Phase B fork 時にも Python ecosystem 内で持続可能。multi-language support (B-1.3) 時は対応する各言語の jsonschema lib (e.g., `ajv` for JS) で interop 確立可能。
- **Trade-offs**:
  - 利点: low maintenance、standard 準拠、portable
  - 妥協: jsonschema lib version dependency (≥ 4.18 for Draft 2020-12)
- **Follow-up**: A-1 prototype 実装時に `requirements.txt` または `pyproject.toml` に dependency declare

## Risks & Mitigations

- **Risk 1: jsonschema lib の Draft 2020-12 サポート完全性が test cases で失敗するリスク** — `tests/test_schema_validity.py` で 4 schema が metaschema valid + sample data で valid/invalid cases 各 3 例以上 assert することで早期検出
- **Risk 2: Phase B fork 時に固有名詞除去 (Rwiki 用語 → 一般化) が seed_patterns.yaml の 23 entry に影響大** — 本 spec scope では generalization 不要 (Req 4.3) と明示、Phase B-1.0 release prep の責務として分離。foundation の `seed_patterns.yaml` schema は generalization 後の structure と互換 (固有名詞は `rwiki_example` field に局在化)
- **Risk 3: signal handler の race window で SIGINT が atomic rename 直前に発火し、temp dir が project root に残存するリスク** — temp dir 命名に PID + timestamp 含めて collision 防止、再 invoke 時に古い temp dir 検出 → cleanup 提案 + actionable hint で recovery
- **Risk 4: 教訓 4 (defer 集約 process) を foundation `dr-init` に組込みたい誘惑** — defer list 38 事項を「`dr-init` 起動直後に手動 grep する」誘惑が design phase 中に発生する可能性。Out of Boundary に明記 + Revalidation Triggers として記録、A-1 prototype 実装中に「やはり組込めば便利」と気付いた場合は本 spec の boundary 再定義 (= req phase 戻り) を経由する規律で防止

## References

- [JSON Schema Draft 2020-12](https://json-schema.org/draft/2020-12/json-schema-core.html) — schema 標準仕様、F-7 確定根拠
- [jsonschema Python lib documentation](https://python-jsonschema.readthedocs.io/) — Draft 2020-12 validator 採用根拠 (build-vs-adopt)
- memory `~/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/feedback_design_review_v3_generalization_design.md` §1-14 — 一般化 design 全体観
- memory `feedback_v3_adoption_lessons_phase_a.md` — 教訓 1-4 (foundation Out of Boundary 判定根拠)
- memory `feedback_review_judgment_patterns.md` — 23 retrofit pattern の primary_group / secondary 構造逆算 source
- `.kiro/drafts/dual-reviewer-draft.md` v0.3 §2.1 / §2.6 / §2.7 / §2.9 / §2.10.3 / §3 / §4 — 上位文書、本 spec の primary 参照点
- `.kiro/specs/dual-reviewer-design-phase-defer-list.md` F-1〜F-10 — defer 事項の確定方針 mapping (本 design.md Design Decisions section に転写完了)
- Rwiki `.kiro/steering/tech.md` — Severity 4 値 / Python 3.10+ / TDD / 2 スペースインデント 整合点
