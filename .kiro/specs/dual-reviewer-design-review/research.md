# Research & Design Decisions — dual-reviewer-design-review

## Summary

- **Feature**: `dual-reviewer-design-review`
- **Discovery Scope**: Extension (foundation/design.md v1.1 contract を import + Layer 2 + 3 skills 実装、Light/Medium discovery)
- **Key Findings**:
  1. foundation との integration contract 完成 (foundation install location = `scripts/dual_reviewer_prototype/`、relative path 規約 + override 階層 + attach contract 3 要素 + placeholder_resolution rule)
  2. design-review install root = foundation install location 同 directory (A-1 = design+impl 一体解釈整合、Phase B 移行時 1 directory 切り出し容易性)
  3. 3 skill orchestration: dr-design (entry) → adversarial subagent dispatch + dr-judgment skill invoke + dr-log per finding helper、dr-judgment → judgment subagent dispatch
  4. Layer 2 attach contract: entry_point = `extensions/design_extension.yaml`、identifier = `design_extension`、失敗 signal = stderr + non_zero_exit
  5. adversarial subagent 3 task (independent + forced_divergence + V4 §1.5 fix-negation)、judgment subagent 1 task (necessity 評価 + label 分類)
  6. forced_divergence prompt 文言 = brief.md 素案 1 文 + 役割分離明示 3 段落構成、英語固定 (本 spec design phase 確定責務)
  7. dr-log 3 系統対応 (single/dual/dual+judgment) = state field + source field + adversarial_counter_evidence field の variant で実現、同一 skill が動作
  8. judgment subagent dispatch payload = primary findings + adversarial findings + counter_evidence (同一 yaml の別 section) + requirements + design + semi-mechanical mapping defaults 7 種

## Research Log

### Topic: Foundation Integration Contract

- **Context**: foundation/design.md v1.1 が直前確定 (commit `2e5637d`)、本 spec が consumer として contract を import する設計
- **Sources Consulted**:
  - foundation/design.md v1.1 (Architecture / File Structure Plan / Data Models / 設計決定 5 件)
  - foundation/research.md v1.0 (V4 review gate outcomes / Risks & Mitigations)
  - foundation/requirements.md (Req 1 AC5+AC6+AC9 attach contract + override 階層)
  - foundation/spec.json (phase: design-approved 確認)
- **Findings**:
  - foundation install location = `scripts/dual_reviewer_prototype/` (foundation 設計決定 5 + 1 確定済)
  - relative path 規約 = `./patterns/` / `./prompts/` / `./schemas/` / `./framework/` (canonical `./` prefix、Req 5 整合)
  - placeholder_resolution rule = "Layer 2 / Layer 3 consumer が yaml file generation 時または runtime injection で `{layer2_install_root}` / `{target_project_root}` を自身の install root absolute path に文字列置換" (foundation A1 apply で追加された規約、本 spec A5 fix で同規約 install root 基点を Layer 2 yaml 内 path に統一適用)
  - override 階層 = Layer 3 > Layer 2 > Layer 1 単方向 (foundation Req 1 AC9)
- **Implications**: 本 spec 3 skills が foundation install location からの相対 path で foundation artifact (schemas / patterns / prompts / framework) を動的読込、hardcode 禁止規律 (Req 5.1, 5.3-5.6) 全件適用

### Topic: 3 Skill Orchestration Pattern

- **Context**: V4 §1.2 option C 整合 = primary + adversarial + judgment の 3 subagent 構成、各役を dispatch する skill 構成設計
- **Sources Consulted**:
  - V4 protocol §1.2 + §2.4 + §3.3 (dispatch flow)
  - foundation `dr-init` skill format (SKILL.md + Python helper)
  - kiro-* skill (kiro-spec-design 等) format precedent
- **Findings**:
  - **dr-design** = orchestrator entry point、Round 1-10 sequential、各 Round で Step A (primary self) → Step B (adversarial subagent dispatch) → Step C (dr-judgment skill invoke) → Step D (integration + V4 §2.5 user 提示)
  - **dr-log** = per finding helper、JSONL append-only、3 系統対応 schema variant
  - **dr-judgment** = subordinate skill、V4 §5.2 prompt template 動的読込 + judgment subagent dispatch + 必要性 5-field 評価 + 5 条件判定 + 3 ラベル分類 + recommended_action + override_reason
  - subagent dispatch via Claude Code Agent tool (`subagent_type: general-purpose` + `model: sonnet`)
  - skill invocation via Claude Code skill system (kiro-* style)
- **Implications**: 3 skill format = SKILL.md (Claude assistant instructions) + Python helper script (IO-heavy operations: yaml read / JSON Schema validate / JSONL append / prompt load / payload assembly)、foundation `dr-init` 整合

### Topic: forced_divergence Prompt Final Text

- **Context**: foundation Req 7 AC4 で defer された prompt 最終文言確定 (本 spec Req 6.1 + 6.3 責務)
- **Sources Consulted**:
  - draft v0.3 §2.6 forced divergence 採用根拠
  - brief.md §Approach 素案 1 文
  - V4 protocol §1.5 (修正否定試行 prompt と役割分離)
- **Findings**:
  - 素案 1 文: "Identify one tacit premise of the primary reviewer's reasoning, replace it with a plausible alternative premise, and evaluate whether the same conclusion still holds."
  - 精緻化方向: instruction 段落 + method 段落 + role separation 段落の 3 段落構成
  - 英語固定 (Req 6.2、subagent 安定性 + multi-language 移行性)
  - V4 §1.5 fix-negation prompt と役割分離明示 (Req 6.5)
- **Implications**: forced_divergence prompt = 3 段落構成、判定 5-C (forced_divergence = adversarial 結論成立性試行、fix-negation = judgment 修正必要性否定) 整合

### Topic: 3 系統対照実験対応 (Single/Dual/Dual+Judgment)

- **Context**: dr-log skill が dogfeeding spec の 3 系統対照実験 (single + dual + dual+judgment) で同一実装で動作する schema variant 設計
- **Sources Consulted**:
  - dogfeeding/requirements.md Req 2 (3 系統定義) + Req 3 AC4 (state + source field) + Req 3 AC8 (adversarial_counter_evidence field)
  - foundation finding.schema.json (state field variant + necessity_judgment optional/required)
  - V4 protocol §4.4 ablation framing
- **Findings**:
  - single 系統: state = `detected`、source = `primary_self_estimate`、adversarial_counter_evidence 省略
  - dual 系統: state = `detected`、source = `primary_self_estimate`、adversarial_counter_evidence 必須
  - dual+judgment 系統: state = `judged`、source = `judgment_subagent`、adversarial_counter_evidence 必須
- **Implications**: dr-log skill は state + source + adversarial_counter_evidence を input から explicit に受け取り、auto detection せず caller (dr-design) が明示指定。これにより同一 skill が 3 系統で動作 + ablation framing 整合

### Topic: A-1 Phase Demarcation (Phase A 細分化)

- **Context**: foundation 設計決定 5 = "A-1 = design + implementation phase 一体" 整合性継承
- **Sources Consulted**:
  - foundation/design.md 設計決定 5
  - draft v0.3 §3.1 A-1 (prototype 実装範囲)
- **Findings**:
  - A-1 = foundation + design-review の design phase + implementation phase 一体期間
  - design-review design approve = A-1 design phase 段階完了、続いて A-1 implementation phase で 4 skills + Layer 2 + portable artifact 物理化
  - dogfeeding (A-2) = implementation phase 後、Spec 6 適用 + 3 系統対照実験
- **Implications**: design-review design phase = foundation と並走で design 完了、implementation phase は両 spec 同時進行可能 (3 skills + portable artifact 物理生成 + sample 1 round 通過 test)

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Skill + Configuration Hybrid (採用) | 3 active skills (SKILL.md + Python helper) + Layer 2 yaml + forced_divergence text を foundation install location 同 directory 配置 | foundation との path 規約統一 / Phase B 移行容易 / IO-heavy 処理を Python helper で test 可能 | foundation 配下に design-review artifact 混在、spec 単位 ownership は README 注記で補完 | foundation `dr-init` + kiro-* skill 統一パターン |
| Pure SKILL.md Skills (no Python) | 3 skills を SKILL.md instructions のみ、Python helper なし | kiro-* skill (kiro-spec-design 等) と統一 | dr-log の JSONL append + JSON Schema validate が困難 (IO heavy) | 却下 (IO 要件不適合) |
| Separate Install Location for design-review | `scripts/dual_reviewer_prototype_design_review/` に分離配置 | spec 境界 path で明示 | foundation と path 規約乖離 / Phase B 切り出しで 2 dir 統合必要 | 却下 (Decision 1 = 同 directory 採用) |

## Design Decisions

(design.md「設計決定事項」section と同期記録、以下は research log と互換)

### Decision 1: design-review install root = foundation install location 同 directory

- **Context**: 本 spec の Layer 2 + 3 skills + forced_divergence prompt の install root を foundation 同 directory にするか別 directory にするか
- **Alternatives**:
  1. `scripts/dual_reviewer_prototype/` 同 directory (foundation 配下)
  2. `scripts/dual_reviewer_prototype_design_review/` 別 directory
- **Selected Approach**: Alternative 1
- **Rationale**: A-1 = design+impl 一体整合 / consumer relative path 規約統一 / Phase B 移行時 1 directory 切り出し
- **Trade-offs**: foundation と design-review artifact 混在の semantic 弱化、README 注記で補完
- **Follow-up**: implementation phase で README に "skills/dr-init = foundation、skills/{dr-design, dr-log, dr-judgment} = design-review" 注記

### Decision 2: forced_divergence prompt 文言 = 3 段落構成 (英語固定)

- **Context**: Req 6.1 + 6.3 で本 spec design phase 確定責務、文言精緻化レベル選択
- **Alternatives**:
  1. brief.md 素案 1 文のみ
  2. 1 文 + role separation 2 段落
  3. 1 文 + method + role separation 3 段落
- **Selected Approach**: Alternative 3
- **Rationale**: subagent 安定性 + 判定 5-C (forced_divergence vs fix-negation) 役割分離 prompt 内明示
- **Trade-offs**: prompt token cost 微増、明示性 trade
- **Follow-up**: sample 1 round 通過 test で adversarial 独立 detection 阻害確認

### Decision 3: V4 §1.5 fix-negation prompt 配置 = adversarial dispatch payload inline embed

- **Context**: foundation Req 1 AC3 + 本 spec Req 6.4 で配置先確定責務 (inline embed or 別 txt)
- **Alternatives**:
  1. adversarial subagent dispatch payload inline embed
  2. 別 txt file `prompts/v4_fix_negation_prompt.txt`
- **Selected Approach**: Alternative 1
- **Rationale**: V4 §1.5 prompt 3 行のみ + foundation portable artifact 対象外 / V4 §5.2 と同様 v4-protocol.md SSoT sync は dr-design SKILL.md 内 sync header で対応可
- **Trade-offs**: V4 §1.5 prompt の sync 漏れリスク (mitigations: dr-design SKILL.md sync header 規約)
- **Follow-up**: implementation phase で SKILL.md sync header 配置確認

### Decision 4: 3 skill format = Claude Code SKILL.md + Python helper script

- **Context**: foundation `dr-init` 整合 vs kiro-* skill (SKILL.md only) の選択
- **Alternatives**:
  1. SKILL.md + Python helper (foundation 整合)
  2. SKILL.md only
- **Selected Approach**: Alternative 1
- **Rationale**: dr-log JSONL + schema validate が Python 必要 / dr-design + dr-judgment helper script で test 可能性向上 / kiro-* skill は IO 処理伴わない、本 spec 3 skill は IO heavy
- **Trade-offs**: skill hybrid 形式、foundation `dr-init` で同 pattern 採用済
- **Follow-up**: implementation phase で SKILL.md / helper 責務境界明示

### Decision 5: dr-judgment 出力受領 mechanism = stdout default

- **Context**: Req 3.8 で stdout default + 一時 file 代替の 2 択明示
- **Alternatives**:
  1. skill stdout に yaml block 書出 (default)
  2. 一時 file path 引数渡し
- **Selected Approach**: Alternative 1
- **Rationale**: kiro-* + foundation `dr-init` 整合 / 一時 file 管理 cost なし
- **Trade-offs**: 大量 finding で stdout buffer 圧迫リスク (Phase A scope sample 1 round では問題なし)
- **Follow-up**: dogfeeding spec の多 finding 検証で stdout buffer test、必要なら一時 file path 切替

## V4 Review Gate Outcomes

本 design phase で V4 protocol §3.3 step 7 を適用、以下を実施:

- **Step 1a + 1b primary detection** (Opus): 10 件検出 (P1-P10)
- **Step 1b parallel adversarial detection** (Sonnet subagent): 7 件独立検出 (A1-A7) + V4 §1.5 修正否定試行 counter-evidence 生成
- **Step 1c judgment subagent dispatch** (Sonnet judgment subagent): 17 件全 V4 §5.2 prompt 適用、必要性 5-field 評価 + 5 条件判定 + 3 ラベル分類
- **Step 2 user 判断** (V4 §2.5 三ラベル提示方式): user **B 採択** = A3 false positive skip + 残 must_fix 3 件 (A1+A5+A6) bulk apply + should_fix 3 件 (P4+A2+A4) 全 apply + do_not_fix 10 件 (P1-P3, P5-P10, A7) bulk skip = 計 6 apply + 11 skip
- **Step 3 適用**: 6 件 (A1+A5+A6+P4+A2+A4) を design.md に Edit 適用、Change Log v1.1 で記録

V4 metric:
- 検出件数: 17 件 (primary 10 + adversarial 7)
- 採択率 (must_fix 比率): **23.5%** (4/17、foundation 0% から大幅改善、H3 ≥ 50% 未達)
- 過剰修正比率 (do_not_fix 比率): **58.8%** (10/17、foundation 81.25% から改善、H1 ≤ 20% 未達)
- should_fix 比率: **17.6%**
- judgment override 件数: 8 件
- primary↔judgment disagreement: 7 件 (P1-P10 の WARN/INFO を do_not_fix 確定)
- adversarial↔judgment agreement: 高 (must_fix 4 件全 adversarial ERROR と一致、A3 false positive を primary が re-judge)
- subagent wall-clock: ~255s (adversarial 125s + judgment 130s、foundation ~293s より短縮)

design-review phase の V4 metric は foundation phase より改善方向:
- 採択率 0% → 23.5% (concrete implementation detail = AC 違反検出可能、specific Service Interface design)
- 過剰修正比率 81.25% → 58.8% (consumer 視点 design = AC 直接 trace 可能)
- subagent wall-clock 短縮 (foundation context 既蓄積による prompt efficiency)

V4 構造的有効性 (修正否定 prompt 機能 + adversarial ERROR 検出機能) を design phase 連続 spec で再確認。H1+H3 累計判定は foundation+design-review+dogfeeding の req+design 全 phase 累計 evidence で最終 comparison-report 集計時に判定。

## Risks & Mitigations

- **Risk 1**: A1 fix の session lifecycle mechanism (open/append/flush) が implementation phase で OS-level concurrent invocation race 発生 → Phase A single-session 前提 (Req 7.2)、B-1.x で lock mechanism 検討
- **Risk 2**: A6 fix の counter_evidence decomposition logic が adversarial subagent 出力 yaml format 依存 → V4 §1.5 prompt 規定の yaml format を adversarial subagent が遵守する前提、format drift 発生時 dr-design parsing logic 改修
- **Risk 3**: forced_divergence prompt の 3 段落構成が adversarial subagent の独立 detection を阻害する可能性 → sample 1 round 通過 test で確認、impl phase 微調整可
- **Risk 4**: V4 §1.5 fix-negation prompt の dr-design SKILL.md inline embed = sync 漏れリスク (foundation A6 の P6 と同 pattern) → SKILL.md sync header 3 行で v4-protocol.md §1.5 version 参照、code review レベル enforcement
- **Risk 5**: dr-judgment stdout buffer 圧迫 (大量 finding 時) → Phase A sample 1 round では問題なし、dogfeeding spec の多 finding test で再評価
- **Risk 6**: A3 false positive 判定の risk = primary が judgment subagent 判定を override した形、user 個別判断で skip 確定 = primary↔judgment 解釈乖離が AC 文言 ambiguity に起因。Req 2 AC5 文言「3 string enum field」の解釈確定 (object 内 3 string field) を本 design 内に明示済 (foundation Data Model 整合)、後続 spec で同 pattern 出現時の参考点
- **Risk 7**: Layer 2 yaml の Round-pattern mapping 実体化 implementation phase 委ね = foundation seed_patterns.yaml 実体化と同 timing で確定 (foundation A4 同型)、implementation phase で schema validation 実施

## References

- foundation/design.md v1.1 (commit `2e5637d`) — upstream contract source、Layer 1 framework + 共通 schema + portable artifact + 5 設計決定
- foundation/research.md v1.0 — V4 review gate outcomes + 5 設計決定
- foundation/requirements.md (V4 redo broad approved)
- `.kiro/methodology/v4-validation/v4-protocol.md` v0.3 final
- `.kiro/methodology/v4-validation/comparison-report.md` v0.1 (req phase V4 redo broad evidence)
- `.kiro/methodology/v4-validation/evidence-catalog.md` v0.3 (audit gap-list G1-G4 + V4 evidence 累計)
- `.kiro/drafts/dual-reviewer-draft.md` v0.3 (canonical design source)
- `.kiro/specs/dual-reviewer-design-review/{brief.md, requirements.md}` (V4 redo broad approved)
- `.kiro/specs/dual-reviewer-dogfeeding/requirements.md` (downstream consumer contract)
- `.kiro/steering/{product.md, tech.md, structure.md}` (Rwiki 既存規約)
- memory `feedback_design_review_v3_adversarial_subagent.md` (V3 試験運用 evidence、本 spec 一般化対象)
- memory `feedback_review_v4_necessity_judgment.md` (未起草、12th 以降記録予定)
- memory `feedback_design_decisions_record.md` — ADR 代替 design.md 本文 + change log 二重記録
- memory `feedback_choice_presentation.md` — 選択肢提示規律 (foundation design phase で物理 layout 例外追加済)
- JSON Schema Draft 2020-12 (https://json-schema.org/draft/2020-12) — schema validation 標準

## Change Log

- **v1.0** (2026-05-01 12th セッション、本 file 初版): A-1 design phase (design-review) 完了時の research log + 5 design decisions + V4 review gate outcomes (17 件検出、6 件 apply / 11 件 skip) + risks + references を集約
