---
name: dr-design
description: design phase 10 ラウンド V4 review skill。Step A (primary detection 5 重検査 + 自動深掘り) → Step B (adversarial subagent dispatch with forced_divergence + V4 §1.5 fix-negation) → Step C (judgment subagent via dr-judgment skill) → Step D (integration + V4 §2.5 三ラベル提示 user 提示) を Round 1-10 sequential 実行。3 系統 (single / dual / dual+judgment) treatment 切替対応 + Round 開始時 dr-log open invoke + Round 終端 flush invoke (A1 fix integration、1 line/session JSONL append-only 担保)。
---

# dr-design Skill (design phase orchestrator)

## 概要 (Overview)

`dr-design` skill は design phase の V4 review (10 ラウンド × Step A/B/C/D pipeline) を orchestrate する Claude Code skill。foundation Layer 1 framework + 本 spec Layer 2 design extension の動的 attach、bias 抑制 quota event-triggered 発動、Phase 1 escalate 3 メタパターン照合、escalate 必須条件 5 種 Step 1b-v + Step 1c 適用を統合実行。Req 1.1-1.9 + 5.1-5.7 + 6.4 + 7.1 + 7.2 + 7.5 に対応。

## 起動規約 (Invocation)

```
python3 scripts/dual_reviewer_prototype/skills/dr-design/orchestrator.py \
  --target-design-md <target_design_md_absolute_path> \
  --dual-reviewer-root <foundation_install_location_absolute_path> \
  --config-yaml-path <target_project_dual_reviewer_config_yaml_absolute_path> \
  --treatment <single|dual|dual+judgment>
```

起動引数:

- `--target-design-md` (必須): review 対象 design.md の absolute path
- `--dual-reviewer-root` (必須): foundation install location の absolute path (`scripts/dual_reviewer_prototype/`)
- `--config-yaml-path` (必須): target project `.dual-reviewer/config.yaml` の absolute path (`primary_model` / `adversarial_model` / `judgment_model` 取得用)
- `--treatment` (必須): 3 系統指定 = `single` | `dual` | `dual+judgment` (3 系統対照実験用、Decision 6 prep)

## 動作 (Behavior)

### 10 Round sequential orchestration (Req 1.9)

各 Round (1-10) で Step A → B → C → D 順次実施:

1. **Round 開始時**: dr-log `open(session_id, treatment, round_index, design_md_commit_hash, target_spec_id, config_yaml_path)` invoke (A1 fix integration)
2. **Step A (primary detection)**: primary_reviewer subagent (= Opus、`config.yaml` `primary_model`) を Claude Code Agent tool で fresh state dispatch (= orchestrator bias contamination 排除、Decision 6 整合)
3. **Step B (adversarial review)**: adversarial subagent (Sonnet、`config.yaml` `adversarial_model`) を Claude Code Agent tool で dispatch
4. **Step C (judgment)**: dr-judgment skill を Claude Code skill invocation で起動
5. **Step D (integration)**: primary + adversarial + judgment yaml merge + V4 §2.5 三ラベル提示 user 提示
6. **Round 終端**: dr-log `flush(session_id)` invoke (1 line/session JSONL)

### Step A: primary detection (Req 1.2)

primary_reviewer subagent (Opus、Agent tool dispatch、fresh state) で実行 (Decision 6 整合):

- **Step 1a**: 軽微検出
- **Step 1b**: 構造的検出 5 重検査
  1. **二重逆算**: 仕様 → 設計の逆算 + 設計 → 仕様の逆算
  2. **Phase 1 パターンマッチング**: foundation `./patterns/seed_patterns.yaml` + Layer 3 `extracted_patterns.yaml` 照合 + Layer 2 `phase1_metapatterns` 3 件 (規範範囲先取り / 構造的不均一 / 文書 vs 実装不整合) 必ず照合
  3. **dev-log patterns 照合**: foundation seed_patterns + Layer 3 extracted_patterns 二層
  4. **自己診断**: primary 自己 evaluation
  5. **内部論理整合**: design 内 cross-reference + dependency 整合
- **Step 1b-v**: 自動深掘り (5 観点 + 5 切り口 negative 視点 強制発動)

### Step B: adversarial review (Req 1.3-1.4)

adversarial subagent dispatch payload:

1. **independent Step 1b detection** (= primary とは独立に 5 重検査再実施)
2. **forced_divergence prompt** (= 本 spec `./prompts/forced_divergence_prompt.txt` 末尾追加、3 段落構成 = Instruction + Method + Role separation、結論成立性試行)
3. **V4 §1.5 fix-negation prompt** (= 英語固定 3 行 inline embed、Decision 3、修正提案 counter-evidence)

#### 役割分離 (Role separation、judgment vs adversarial)

判定 5-C 整合の役割分離規律:

- **judgment_reviewer** (Step C、dr-judgment skill): 修正否定試行 (= V4 §5.2 fix-negation、修正 proposal 必要性否定) を担当。foundation `./prompts/judgment_subagent_prompt.txt` 経由
- **adversarial_reviewer** (Step B、本 skill): forced_divergence (= 結論成立性試行、暗黙前提別前提置換) + V4 §1.5 fix-negation 3 行 inline (= 修正提案 counter-evidence) を担当。本 spec `./prompts/forced_divergence_prompt.txt` + SKILL.md inline embed

両者の intent は **別物** = judgment は「修正必要性否定」、adversarial forced_divergence は「結論成立性試行」(別 task = 別 prompt)。SKILL.md instructions で両 prompt が adversarial dispatch payload には含まれ、judgment dispatch payload には含まれない wiring を厳守。

#### V4 §1.5 fix-negation prompt sync header 3 行 (Decision 3 整合、SKILL.md 内 inline 配置)

```
# canonical-source: docs/過剰修正バイアス.md §3 (or .kiro/methodology/v4-validation/v4-protocol.md §1.5)
# v4-protocol-version: 0.3
# sync-policy: byte-level integrity, manual sync at v4-protocol revision
For each proposed fix, argue why it may not be necessary.
Classify it as must_fix, should_fix, or do_not_fix.
Prefer do_not_fix when the issue is speculative, expands scope, or lacks requirement linkage.
```

(本文 3 行 = V4 §5.1 byte-level copy)

### Step C: judgment (Req 1.4 + 1.8)

dr-judgment skill invocation:

- payload: primary findings + adversarial findings + adversarial_counter_evidence + requirements_text + design_text
- judgment_reviewer subagent (Sonnet、`config.yaml` `judgment_model`) 経由で 5 条件判定 + 3 ラベル分類

### Step D: integration (Req 1.5)

- primary + adversarial + judgment yaml id-based merge (issue_id key で join、namespace prefix `P-<n>` / `A-<n>` で disambiguate)
- V4 §2.5 三ラベル提示 (must_fix bulk apply default / do_not_fix bulk skip default / should_fix individual review) を user 提示用に構造化
- **自動 apply / skip 禁止**: V4 §2.5 user oversight 原則整合、user 判断必須

### 3 系統 treatment 切替 (Decision 6 prep)

| treatment | Step A | Step B | Step C | Step D output |
|-----------|--------|--------|--------|---------------|
| single | exec | skip | skip | primary 検出のみ user 提示 |
| dual | exec | exec | skip | primary + adversarial 検出 user 提示 |
| dual+judgment | exec | exec | exec | primary + adversarial + judgment 結果 user 提示 (V4 完全) |

#### A-2.1 3 系統対照実験 design.md state policy (data-acquisition-plan v1.7 §3.6 B4 + §4 A-2.1 branch 戦略 整合)

A-2.1 Spec 6 design phase 30 review session (= 3 系統 × 10 round) では、paper rigor 確保 + confounding 排除のため、全 treatment が **pristine state を起点**として独立 branch で完走する規律を必ず適用:

- 各 treatment は pristine state commit (= Spec 6 design.md 起草直後 state、A-2 phase sub-step 2 終端) を起点として new branch 派生
- 累積修正 state (= 他 treatment 完走後の design.md) を起点として複数 treatment を回すことを禁止 (= prior treatment による事前修正と current treatment 単独 effect の交絡 = V4 各 layer の機能寄与 quantify 不能)
- 各 treatment branch は独立 commit history を保持、main 進行に影響なし
- Level 6 events は各 treatment 別 file (例: `rework_log_treatment_single.jsonl`) または別 sub-group key で記録 = main の rework_log.jsonl と confound 回避
- 30 review session 完走後に 3 branch 統合分析 = comparison-report v0.2 final 集約 (= ablation figure data 成立)
- Spec 6 design.md 最終 state は main の treatment=dual+judgment 結果を採用、他 2 treatment branch は paper data source archive として delete 禁止

### bias 抑制 quota event-triggered 発動

- formal challenge / 検出漏れ / Phase 1 同型探索 / 厳しく検証 5 種 (Layer 2 `bias_suppression_quota_design_specific` 4 件) を適切な event で発動
- Chappy P0 全機能 (foundation `fatal_patterns.yaml` 8 種強制照合 + `impact_score` 3 軸付与 + forced_divergence prompt) を invoke
- escalate 必須条件 5 種 (内部矛盾 / 実装不可能性 / 責務境界 / 規範範囲 / 複数選択肢 trade-off) Step 1b-v + Step 1c 両方適用

### target design.md commit hash 取得 (A2 fix、reproducibility)

`git rev-parse HEAD -- <target_design_md_path>` で commit hash 取得 → dr-log invocation `open(...)` payload `design_md_commit_hash` 付与 (dogfeeding spec Req 3.7 整合)。

### adversarial counter_evidence decompose (A6 fix、dual / dual+judgment 系統)

adversarial 出力 yaml の `counter_evidence` section を issue_id 単位 decompose → 各 finding object の `adversarial_counter_evidence` field 付与。

### Layer 3 terminology attach 整合 (Req 5.7)

foundation `terminology.yaml` placeholder = Layer 3 entries は override 階層 (Layer 3 > Layer 2 > Layer 1) で本 spec terminology を override 可能。

## 出力 (Output)

### Success (exit 0)

stdout に Step D integration yaml (V4 §2.5 三ラベル提示):

```yaml
must_fix:
  - issue_id: P-1
    finding_text: "..."
should_fix:
  - issue_id: P-2
    finding_text: "..."
do_not_fix:
  - issue_id: A-1
    finding_text: "..."
```

### Failure (non-zero exit)

| exit code | failure |
|-----------|---------|
| 1 | Layer 1/2 read fail |
| 2 | adversarial dispatch fail |
| 3 | dr-judgment invoke fail |
| 4 | dr-log invoke fail (warning, not abort、A4 fix 整合) |

## helper script 責務範囲 (P4 + A3 fix 整合)

`orchestrator.py` の責務 (P4 apply、design.md L420-424 + L460-466 整合):

- **担う**: Layer 1/2 yaml load + foundation patterns yaml load + forced_divergence prompt load + 5 重検査 helper + path resolution + commit hash 取得 + counter_evidence decompose + treatment switch
- **担わない**: adversarial subagent dispatch 本体 (= Claude assistant が SKILL.md instructions に従って Agent tool 経由実行) + V4 §1.5 fix-negation prompt の Python 側 file read / regex extract (= SKILL.md inline 配置のみ)

## 関連 reference (References)

- foundation `framework/layer1_framework.yaml` (Step A/B/C/D pipeline 定義)
- foundation `patterns/seed_patterns.yaml` (Phase 1 patterns + dev-log patterns 照合 source)
- foundation `patterns/fatal_patterns.yaml` (Chappy P0 8 種 enum)
- foundation `prompts/judgment_subagent_prompt.txt` (V4 §5.2、Step C で dr-judgment 経由読込)
- 本 spec `extensions/design_extension.yaml` (Layer 2 design extension)
- 本 spec `prompts/forced_divergence_prompt.txt` (Step B adversarial 末尾追加)
- design.md §dr-design Skill (Service Interface 定義)
