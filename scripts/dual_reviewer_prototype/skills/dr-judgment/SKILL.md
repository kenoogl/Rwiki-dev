---
name: dr-judgment
description: V4 §5.2 judgment subagent dispatch skill。foundation `./prompts/judgment_subagent_prompt.txt` 動的読込 + dispatch payload assemble + 必要性 5-field 評価 + 5 条件判定ルール + 3 ラベル分類 + escalate mapping (uncertainty=high → should_fix + user_decision) を実施。修正否定試行 prompt (V4 §5.2 既存組込、judgment 用、修正 proposal 必要性否定) と forced_divergence prompt (Step B、本 spec 配置、結論成立性試行) は役割分離。
---

# dr-judgment Skill (judgment subagent dispatch)

## 概要 (Overview)

`dr-judgment` skill は V4 §5.2 judgment subagent dispatch を実行する Claude Code skill。primary + adversarial 検出 finding に対し必要性 5-field (requirement_link / ignored_impact / fix_cost / scope_expansion / uncertainty) を評価、5 条件判定ルール (V4 §1.4.1) を順次適用、3 ラベル分類 (must_fix / should_fix / do_not_fix) で出力。Req 1.4 + 1.8 + 3.1-3.8 + 5.1 + 5.5 + 5.7 + 7.1 + 7.4 + 7.5 に対応。

## 起動規約 (Invocation)

```
python3 scripts/dual_reviewer_prototype/skills/dr-judgment/judgment_dispatcher.py \
  --payload-json <path_or_stdin> \
  --dual-reviewer-root <foundation_install_location_absolute_path> \
  --config-yaml-path <target_project_dual_reviewer_config_yaml_absolute_path>
```

起動引数 3 種 (A6 apply、design.md DrJudgmentService Interface L536 整合):

- `--payload-json` (optional, default = stdin): primary findings + adversarial findings + adversarial_counter_evidence + requirements_text + design_text? を含む JSON payload の file path、もしくは `-` で stdin 受領
- `--dual-reviewer-root` (必須): foundation install location の absolute path (`scripts/dual_reviewer_prototype/`)
- `--config-yaml-path` (必須): target project `.dual-reviewer/config.yaml` の absolute path (`judgment_model` 取得用)

## 動作 (Behavior)

### dispatch flow (Claude assistant が SKILL.md instructions に従って実行)

1. **prompt 動的読込**: foundation `./prompts/judgment_subagent_prompt.txt` を `judgment_dispatcher.load_judgment_prompt()` で起動時 read (hardcode 禁止、Req 5.5)
2. **dispatch payload assemble**: `judgment_dispatcher.assemble_payload()` で 6 field 構造化:
    - `primary_findings`: dr-design から渡される primary 検出全 issue list
    - `adversarial_findings`: adversarial subagent 検出全 issue list
    - `adversarial_counter_evidence`: adversarial subagent の V4 §1.5 fix-negation counter-evidence (同一 yaml 出力の **別 section** = adversarial 1 dispatch で 2 役割分離 output)
    - `requirements_text`: 当該 spec の requirements.md 全文 (AC 文言紐付け検証用)
    - `design_text` (optional): design phase の場合のみ design.md 全文
    - `semi_mechanical_mapping_defaults`: V4 §1.4.2 7 種 mapping rule (judgment_dispatcher module-level 定数 inline expose)
3. **judgment subagent dispatch**: Claude Code Agent tool で `subagent_type: general-purpose` + `model: sonnet` (`config.yaml` `judgment_model`) で judgment_reviewer subagent dispatch。prompt template + payload を入力に渡す
4. **修正否定試行 prompt 役割保持**: V4 §5.2 prompt 内既存組込の修正否定試行 (= 修正 proposal 必要性否定、judgment 用) を保持。Step B forced_divergence (= 結論成立性試行、暗黙前提別前提置換、adversarial 担当、本 spec `./prompts/forced_divergence_prompt.txt`) と役割分離維持 (判定 5-C 整合)
5. **5 条件判定ルール 順次評価** (V4 §1.4.1、judgment subagent prompt 内既存):
    1. critical impact → must_fix
    2. requirement_link=yes AND ignored_impact>=high → must_fix
    3. scope_expansion=yes AND not critical → do_not_fix or escalate
    4. fix_cost > ignored_impact → do_not_fix-leaning
    5. uncertainty=high → escalate
6. **escalate mapping**: `judgment_dispatcher.apply_escalate_mapping()` で uncertainty=high → `fix_decision.label=should_fix` + `recommended_action=user_decision` mapping (foundation `fix_decision.label` 3 値 enum 整合、Req 3.5)
7. **出力 yaml validate**: `judgment_dispatcher.validate_judgment_output()` で foundation `./schemas/necessity_judgment.schema.json` (Python `jsonschema.Draft202012Validator`) に対し必要性 5 field + fix_decision.label + recommended_action + override_reason? を validate。validate fail = fail-fast (exit 3)
8. **stdout 出力 (default mechanism、Decision 5)**: judgment yaml block を stdout 書出。代替 (一時 file path 引数) も許容

### override_reason 必須記録

semi-mechanical mapping default 7 種 (V4 §1.4.2) を override する場合、`override_reason` field 必須記録 (Req 3.6)。

### Layer 3 terminology attach 整合

foundation `terminology.yaml` placeholder (foundation Req 7.5 整合) = Layer 3 project 固有 terminology entries は foundation Layer 1 contract (foundation Req 1 AC6) に従い attach、override 階層 (Layer 3 > Layer 2 > Layer 1) で Layer 3 entry が本 spec terminology を override 可能 (Req 5.7)。

## 出力 (Output)

### Success (exit 0)

stdout に judgment yaml block (per finding):

```yaml
- issue_id: P-1
  source: judgment_subagent
  requirement_link: yes
  ignored_impact: high
  fix_cost: low
  scope_expansion: no
  uncertainty: low
  fix_decision: { label: must_fix }
  recommended_action: fix_now
  override_reason: null
```

### Failure (non-zero exit)

| exit code | failure | stderr |
|-----------|---------|--------|
| 1 | prompt read fail | `prompt file not found: <path>` |
| 2 | judgment subagent dispatch fail | `judgment subagent dispatch failed: <error>` |
| 3 | output yaml validate fail | `entry <idx> validation failed: <messages>` |

## helper script 責務範囲 (P4 fix 整合)

`judgment_dispatcher.py` の責務 (P4 apply、design.md L565-568 + L570 整合):

- **担う**: prompt load + payload assemble + output yaml validate + escalate mapping
- **担わない**: judgment subagent dispatch 本体 (= Claude assistant が SKILL.md instructions に従って Agent tool 経由実行)

## 関連 reference (References)

- foundation `prompts/judgment_subagent_prompt.txt` (V4 §5.2 prompt template、本 skill 動的読込 source)
- foundation `schemas/necessity_judgment.schema.json` (出力 yaml validate target)
- 本 spec `prompts/forced_divergence_prompt.txt` (Step B adversarial 担当、役割分離 reference)
- design.md §dr-judgment Skill (Service Interface 定義)
- v4-protocol.md §5.2 (canonical source)
