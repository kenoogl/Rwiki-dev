# Research & Design Decisions — dual-reviewer-foundation

## Summary

- **Feature**: `dual-reviewer-foundation`
- **Discovery Scope**: New Feature (greenfield methodology package、Phase A scope = Rwiki repo 内 prototype 段階) with extensive internal-context integration (V4 protocol + draft v0.3 + Chappy review + audit gap-list)
- **Key Findings**:
  1. canonical design source = draft v0.3 (`dual-reviewer-draft.md`) + V4 protocol v0.3 final + Chappy P0 採用 3 件 + audit gap-list (G1-G4)
  2. 責務分離 = foundation (Layer 1 + dr-init + 共通 schema + seed/fatal patterns + V4 §5.2 prompt + 多言語 policy) / design-review (Layer 2 + 3 review skills) / dogfeeding (Spec 6 適用 + 3 系統対照実験)
  3. install location 確定責務 = foundation design phase (= A-1 prototype の design 部分) で `scripts/dual_reviewer_prototype/` に確定
  4. source field 2 階層 disambiguate: `finding.source` (検出 source) vs `necessity_judgment.source` (判定 source)、別 schema の nested location で混在しない
  5. JSON Schema Draft 2020-12 標準採用 (Req 3 AC8 整合) + yaml 1.2 + Claude Code SKILL.md format

## Research Log

### Topic: V4 Protocol v0.3 Final Integration

- **Context**: 7th セッション末で確定した V4 protocol v0.3 final を design phase に適用する際の構造的取込方法
- **Sources Consulted**:
  - `.kiro/methodology/v4-validation/v4-protocol.md` v0.3 final
  - `.kiro/methodology/v4-validation/comparison-report.md` (req phase V4 redo broad evidence、3 spec 完走)
  - `.kiro/methodology/v4-validation/evidence-catalog.md` v0.3 (V3 baseline / V4 attempt 1 / V4 redo broad の所在)
- **Findings**:
  - V4 §1.2 option C = 3 subagent 構成 (primary + adversarial + judgment) を Layer 1 framework に first-class facility として expose
  - V4 §1.5 修正否定試行 = adversarial subagent 担当 (counter-evidence 生成)、V4 §5.2 prompt template は judgment subagent 用 (修正必要性判定)
  - V4 §1.3-1.4 = 必要性 5-field schema + 5 条件判定ルール + 3 ラベル分類 + semi-mechanical mapping default 7 種を共通 schema (修正必要性判定軸) に取込
  - V4 §5.2 prompt template canonical SSoT = `v4-protocol.md` §5.2、本 spec は portable artifact として byte-level 整合した copy を `prompts/judgment_subagent_prompt.txt` に配置
- **Implications**: Layer 1 framework definition yaml に `step_pipeline` (Step A/B/C/D 構造) + `v4_features` (V4 §1 機能 5 件) + `chappy_p0` (Chappy 採用 3 件) section を組込み、consumer Layer 2 が import 経由で参照する architecture を確定

### Topic: Audit Gap-List (G1-G4) Resolution Strategy

- **Context**: 11th セッション末に main 統合後の 3 req 整合性 audit で識別された 4 件の soft gap (G1-G4) を design phase でどう解消するか
- **Sources Consulted**:
  - `.kiro/methodology/v4-validation/evidence-catalog.md` §3.9 (audit gap-list 詳細)
  - foundation requirements.md (Req 3 AC2 / AC6, Req 7 AC1)
  - design-review requirements.md (Req 5 AC2)
- **Findings**:
  - **G1** (`source` field naming overlap): foundation Req 3 AC2 `finding.source` (primary | adversarial、検出 source) と design-review Req 2 AC7 / dogfeeding Req 3 AC4 `source: primary_self_estimate | judgment_subagent` (判定 source) が同名 field semantic overlap → 別 schema nested location で disambiguate
  - **G2** (`judgment_reviewer` vs "judgment subagent" 用語揺れ): cosmetic、role 抽象名 = `judgment_reviewer` (Req 7 AC1) + V4 protocol context での "judgment subagent" 並列容認 (audit-list 既決定方針)
  - **G3** (foundation install location 確定 timing): foundation Boundary Context "A-1 prototype 実装時に確定" + design-review Req 5 AC2 "本 spec design phase で確定" → A-1 = design+impl 一体 phase と解釈、本 design phase で `scripts/dual_reviewer_prototype/` 確定 (設計決定 5)
  - **G4** (relative path canonical form): cosmetic、`./` prefix で統一 (foundation requirements 既存表記と整合)
- **Implications**: design phase で G1 + G3 を実体的に解決 (設計決定 2 + 5)、G2 + G4 は cosmetic で並列容認 (Phase A 終端 cleanup 候補)

### Topic: Foundation Install Location Selection

- **Context**: 設計決定 5 で A-1 = design+impl 一体 phase = foundation design phase で install location 確定責務、draft v0.3 §3.1 A-1 で 2 候補列挙 (`scripts/dual_reviewer_prototype/` または `.kiro/specs/dual-reviewer/prototype/`)
- **Sources Consulted**:
  - draft v0.3 §3.1 A-1
  - `.kiro/steering/structure.md` (Rwiki 既存 directory 規約)
  - `v1-archive/scripts/` (実装 code 配置パターン precedent)
- **Findings**:
  - 候補 X1 = `scripts/dual_reviewer_prototype/` (Phase A 内 prototype として scripts/ 配下、v1-archive/scripts/ と平行)
  - 候補 X2 = `.kiro/specs/dual-reviewer/prototype/` (新規 dir、3 spec 横断 prototype directory)
  - X1 メリット: Phase B 移行時に丸ごと独立 repo 切り出し可 / Rwiki 既存規約 (v1-archive/scripts/) と整合 / `.kiro/specs/` 慣例維持
  - X2 メリット: dual-reviewer 関連 artifact 集約 / spec ↔ impl 一体性 (ただし新 dir `dual-reviewer/` 作成 = 既存 spec dir 命名規約 deviation)
  - user 判断: X1 採用
- **Implications**: foundation install location = `scripts/dual_reviewer_prototype/` (絶対 path) を design 内で統一参照、consumer skill の relative path locate 規約は `./patterns/` / `./prompts/` / `./schemas/` 形式で統一 (G4 cosmetic 解決と整合)

### Topic: JSON Schema Standard Selection

- **Context**: Req 3 AC8 = "機械検証可能な形式 (JSON Schema 標準 or 同等)" 規定下での具体 standard 選定
- **Sources Consulted**: JSON Schema 公式 (https://json-schema.org/、external 参照)、Python `jsonschema` library (Phase A scope の Python 3.10+ runtime と整合)
- **Findings**:
  - JSON Schema Draft 2020-12 = 現行最新 stable standard
  - Python `jsonschema` library = Draft 2020-12 サポート
  - Build vs Adopt 判断 = adopt (build しない)
- **Implications**: schemas/*.schema.json 全 file 先頭に `"$schema": "https://json-schema.org/draft/2020-12/schema"` 明示、consumer 側 `dr-log` skill が Python `jsonschema` で fail-fast validate 可能

### Topic: dr-init Skill Implementation Form

- **Context**: Req 2 が dr-init skill を実装責務、Phase A scope は Rwiki repo 内 prototype 段階 = npm package 化 scope 外
- **Sources Consulted**:
  - `.claude/skills/kiro-spec-init/` (kiro-* skill 実装パターン precedent)
  - `.claude/skills/kiro-spec-design/` (同)
  - `.kiro/steering/tech.md` (Rwiki Python 3.10+ 規約)
- **Findings**:
  - kiro-* skill = directory + SKILL.md format (Claude Code skill invocation 経由起動)
  - Python script による実装 (Rwiki 既存規約)
  - all-or-nothing rollback semantics (Req 2 AC6) は Python try/except + cleanup pattern で実装可能
- **Implications**: `skills/dr-init/` = SKILL.md (skill definition) + bootstrap.py (Python 実装) の 2 file 構成、kiro-* skill と統一パターン

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Library + Data + Skill Hybrid (採用) | yaml definition (framework) + JSON Schema (validation) + yaml/text data (patterns / prompt) + Python skill (bootstrap) を single install location 配置 | 静的 artifact + 1 active skill = 簡潔 / consumer relative path 規約で locate / Phase B 移行容易 | yaml + JSON 混在で format 多様 (実害なし) | Rwiki 既存規約 (scripts/ + Python + yaml) と整合 |
| Pure Python Package | foundation 全体を Python package 化、yaml/JSON Schema を Python module に embed | type safety + import 整合 | Phase A scope 過剰 (npm package 化未着手段階) / consumer 多言語対応の障害 | 却下 |
| Pure Configuration Files (skill なし) | dr-init skill を別 spec 化、本 spec は data + framework definition のみ | scope 最小化 | dr-init は foundation 責務 (Req 2)、別 spec 化は req 違反 | 却下 |

## Design Decisions

(design.md「設計決定事項」section と同期記録、以下は research log と互換)

### Decision: foundation install location = `scripts/dual_reviewer_prototype/` (audit gap G3 解決)

- **Context**: foundation Boundary Context defer + design-review Req 5 AC2 委任、本 design phase 確定責務
- **Alternatives**:
  1. `scripts/dual_reviewer_prototype/`
  2. `.kiro/specs/dual-reviewer/prototype/`
- **Selected Approach**: Alternative 1
- **Rationale**: Phase B 移行時の丸ごと切り出し性 + Rwiki 既存規約 (v1-archive/scripts/ 平行) + `.kiro/specs/` 慣例維持 (= spec artifact のみ)
- **Trade-offs**: scripts/ pollution リスクは `dual_reviewer_prototype/` 専用 namespace で隔離
- **Follow-up**: implementation phase で directory 生成 + .gitignore 検討

### Decision: source field 2 階層 disambiguate (audit gap G1 解決)

- **Context**: foundation Req 3 AC2 `finding.source` (primary | adversarial) と consumer spec の `source: primary_self_estimate | judgment_subagent` (修正必要性判定軸 context) の同名 field 重複懸念
- **Alternatives**:
  1. nested field 分離 (`finding.source` vs `necessity_judgment.source`)
  2. `finding.source` を `finding.detection_source` に rename (req phase 戻り)
- **Selected Approach**: Alternative 1
- **Rationale**: foundation Req 3 AC6 consumer 拡張 mechanism 範囲内 + req phase 改訂不要 + 別 schema の nested location で混在しない
- **Trade-offs**: source field 名 overlap 残るが、別 namespace + 別 enum 値で disambiguate
- **Follow-up**: consumer skill 実装時に schema 階層を明示参照 (`finding.source` vs `finding.necessity_judgment.source`)

### Decision: V4 §5.2 prompt sync mechanism = header 3 行 manual sync

- **Context**: Req 6.10 で sync mechanism 確定責務
- **Alternatives**:
  1. file header 3 行 manual sync (canonical-source path + version + sync-policy 明示)
  2. automated build script (Phase B-1.0 検討)
  3. hash 比較 drift detection (Phase B-1.0 検討)
- **Selected Approach**: Alternative 1
- **Rationale**: Phase A scope = prototype 段階で automated mechanism は overengineering / header 3 行で SSoT 関係明示 / V4 protocol 改訂 frequency が低 = manual sync 負荷小
- **Trade-offs**: drift detection 自動化なし、改訂時 manual sync 漏れリスクは review レベルで補完
- **Follow-up**: B-1.0 release prep で automated build script 検討

### Decision: dr-init skill format = Claude Code SKILL.md + Python bootstrap.py

- **Context**: Phase A scope = Rwiki repo 内 prototype + Rwiki Python 3.10+ 規約整合
- **Alternatives**:
  1. Claude Code skill format (SKILL.md + Python script)
  2. POSIX shell script のみ
  3. npm package + node CLI (Phase B-1.0)
- **Selected Approach**: Alternative 1
- **Rationale**: kiro-* skill との実装パターン統一 / Rwiki 既存 Python 依存活用 / Claude Code 内起動可能
- **Trade-offs**: Phase B 移行時に Claude Code 依存解除 + npm package 化必要 (B-1.0 で対応)
- **Follow-up**: implementation phase で `skills/dr-init/{SKILL.md, bootstrap.py}` 実装

### Decision: A-1 = design phase + implementation phase 一体 (audit gap G3 補足解釈)

- **Context**: foundation Boundary Context "A-1 prototype 実装時に確定" + design-review Req 5 AC2 "本 spec design phase で確定" 整合性
- **Alternatives**:
  1. A-1 = design + impl 一体
  2. A-1 = impl のみ (req phase 戻り解釈)
- **Selected Approach**: Alternative 1
- **Rationale**: draft v0.3 §3.1 A-1 = "prototype 実装" が design phase 含意 / design-review Req 5 AC2 整合 / install location 確定は design phase 責務範囲
- **Trade-offs**: なし (両解釈一貫する解釈確定)
- **Follow-up**: TODO_NEXT_SESSION.md で「A-1 phase = design+impl 一体」明示記録

## V4 Review Gate Outcomes (Step 1a/1b/1b-v/1c/2/3 統合適用 evidence)

本 design phase で V4 protocol §3.3 step 7 を適用、以下を実施:

- **Step 1a + 1b primary detection** (Opus 私): 10 件検出 (P1-P10)
- **Step 1b parallel adversarial detection** (Sonnet subagent dispatch): 6 件独立検出 (A1-A6) + V4 §1.5 修正否定試行 counter-evidence 生成 (P1-P10 全件分)
- **Step 1c judgment subagent dispatch** (Sonnet judgment subagent): 16 件全 V4 §5.2 prompt 適用、必要性 5-field 評価 + 5 条件判定 + 3 ラベル分類
- **Step 2 user 判断** (V4 §2.5 三ラベル提示方式): user 全 apply 判断 (3 件 should_fix) + bulk skip 判断 (13 件 do_not_fix)
- **Step 3 適用**: 3 件 (P4 + A1 + A5) を design.md に Edit 適用、Change Log v1.1 で記録

V4 metric:
- 検出件数: 16 件 (primary 10 + adversarial 6)
- 採択率 (must_fix 比率): 0% (V4 H3 ≥ 50% 未達、req phase 比悪化、design phase 細部 review 性質反映)
- 過剰修正比率 (do_not_fix 比率): 81.25% (V4 H1 ≤ 20% 大幅未達)
- should_fix 比率: 18.75%
- judgment override 件数: 8 件 (主に requirement_link=yes default の ignored_impact=high downgrade)
- primary↔judgment disagreement: 1 件 (P3 ERROR 想定 → do_not_fix)
- adversarial↔judgment agreement: 5+ 件
- V4 修正否定 prompt 機能 (primary should_fix bias suppression): 9/10 件 = 90% で primary 提案を do_not_fix へ整合

design phase の V4 metric は req phase (foundation 36.8% / design-review 25.0% / dogfeeding 44.4% 過剰修正比率) より H1 大幅未達。要因仮説:
- design phase = 具体実装細部 review = false positive 多発
- design.md に意図的設計判断 (ADR 代替) 多数記録 = primary が "more is better" bias で fix 提案増加
- judgment subagent + adversarial counter-evidence による suppression が機能 → 高 do_not_fix 比率は V4 protocol 効果

V4 protocol 構造的有効性 (修正否定 prompt 機能 90%) は再確認、H1 達成は req+design 両 phase 累計 evidence で再評価必要 (本 spec で append、最終 comparison-report 集計)。

## Risks & Mitigations

- **Risk 1**: V4 §5.2 prompt template の v4-protocol.md §5.2 改訂時 sync 漏れ → manual sync + code review 補完 (B-1.0 で automated detection 検討)
- **Risk 2**: 23 件 seed_patterns 実体が implementation phase で具体化される際、Req 1.3 pattern schema 不整合可能性 → implementation phase で schema validation step 追加 (本 design は構造のみ確定、内容は memory `feedback_review_judgment_patterns.md` 引用源として既存)
- **Risk 3**: foundation install location 変更 (Phase B 移行時の path 移動) → Revalidation Triggers 章記載 + consumer 全 spec の relative path locate 規約 review
- **Risk 4**: dr-init concurrent invocation race (lock なし) → Phase A scope = single-invocation 前提、B-1.0 で再検討
- **Risk 5**: JSON Schema Draft 2020-12 `$ref` + `allOf` + `if/then` 複合条件の validator 実装間差異 → A5 fix で Testing Strategy に確認手順追加、implementation phase で exhaustive validation 実施

## References

- `.kiro/methodology/v4-validation/v4-protocol.md` v0.3 final — V4 protocol 整合の SSoT
- `.kiro/methodology/v4-validation/comparison-report.md` v0.1 — req phase V4 redo broad evidence
- `.kiro/methodology/v4-validation/evidence-catalog.md` v0.3 — V3 baseline / V4 attempt 1 / V4 redo broad の所在 + audit gap-list (G1-G4)
- `.kiro/drafts/dual-reviewer-draft.md` v0.3 — canonical design source (V4 整合済 draft)
- `.kiro/specs/dual-reviewer-foundation/{brief.md, requirements.md}` — V4 redo broad approved
- `.kiro/specs/dual-reviewer-design-review/requirements.md` — consumer spec contract
- `.kiro/specs/dual-reviewer-dogfeeding/requirements.md` — consumer spec contract
- `.kiro/steering/{product.md, tech.md, structure.md}` — Rwiki 既存規約整合参照点
- memory `feedback_design_review_v3_adversarial_subagent.md` — V3 試験運用 evidence (本 spec が一般化対象)
- memory `feedback_review_v4_necessity_judgment.md` (未起草、12th 以降記録予定) — V4 protocol 確定経緯
- memory `feedback_design_decisions_record.md` — ADR 代替の design.md 本文記録方式 + change log の二重記録規律
- memory `feedback_choice_presentation.md` — 物理 layout 選択時の concrete tree + 比較表 + 判断軸 3 点組み (本 design phase で追記済)
- JSON Schema Draft 2020-12 (https://json-schema.org/draft/2020-12) — schemas/*.schema.json 標準準拠

## Change Log

- **v1.0** (2026-05-01 12th セッション、本 file 初版): A-0 → A-1 phase transition design 完了時の research log + 5 design decisions + V4 review gate outcomes + risks + references を集約。
