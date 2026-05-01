# Implementation Plan

## Overview

`dual-reviewer-design-review` の portable artifact (3 skills [`dr-design` / `dr-log` / `dr-judgment`] + Layer 2 design extension yaml + forced_divergence prompt template) を foundation install location (= `scripts/dual_reviewer_prototype/`) 配下に追加配置する実装計画。Phase A scope = Rwiki repo 内 prototype 段階、Phase B 独立 fork は本 spec scope 外。

**Prerequisite**: `dual-reviewer-foundation` tasks 完走 (= foundation 7 portable artifact 配置済 + Python ランタイム前提確認済)。design-review 成果物は foundation install location 同 dir に追加配置 (Decision 1 整合)。

8 major task / 19 sub-task で構成、Foundation prereqs (Task 1) → Static configuration data (Task 2) → 3 skills implementation (Task 3 dr-judgment / Task 4 dr-log / Task 5 dr-design) → Validation (Task 6 unit / Task 7 integration / Task 8 E2E) の phase 順序。Task 3-4 は parallel-capable (互いに独立、Layer 2/forced_divergence prompt 経由で path resolution)、Task 5 は Task 3+4 完了後依存。

## Tasks

- [ ] 1. Foundation prereqs 確認 + design-review scaffolding
  - foundation tasks 完走確認: `scripts/dual_reviewer_prototype/` + foundation 7 sub-dir (`framework/` / `schemas/` / `patterns/` / `prompts/` / `config/` / `terminology/` / `skills/dr-init/`) + 5 schemas + 2 patterns + judgment_subagent_prompt + config/terminology templates 配置済 confirm
  - 本 spec 用 sub-directory `extensions/` を foundation install location 配下に create
  - tests/ directory 配下に design-review subdirectory (`tests/integration/design_review/`) + `conftest.py` placeholder 配置
  - Python `pyyaml` + `jsonschema>=4.18` (Draft 2020-12 + `Registry` API 対応 version pinned) + `pytest` install 状態 (foundation task 1 で install 済) を確認 (P6 apply、cross-spec 整合で foundation task 1 にも同 version pin 推奨)
  - **foundation install location 解決 mechanism 確定** (Req 5.2): skill invocation 時 absolute path を `--dual-reviewer-root` CLI 引数で渡す default + 環境変数 `DUAL_REVIEWER_ROOT` fallback (design.md L773 整合)。3 skill helper script は path resolution helper utility (例: `resolve_foundation_path(base_root, relative)`) を共有
  - **Foundation 改変禁止 invariant** (Req 4.6 整合): 本 spec tasks 期間中、foundation 配下 (`framework/` / `schemas/` / `patterns/` / `prompts/judgment_subagent_prompt.txt` / `config/` / `terminology/` / `skills/dr-init/`) の改変禁止、新規追加は本 spec 配下 (`extensions/` / `prompts/forced_divergence_prompt.txt` / `skills/{dr-design, dr-log, dr-judgment}/`) のみ
  - Observable: `tree scripts/dual_reviewer_prototype/extensions/ scripts/dual_reviewer_prototype/tests/integration/design_review/` で extensions/ + tests/integration/design_review/ presence、`python3 -c "import yaml, jsonschema, pytest"` 全 import 成功、foundation 7 sub-dir presence (foundation task 1 完走確認の延長)
  - _Requirements: 4.6, 5.2, 7.5_

- [ ] 2. Static configuration data 配置
- [ ] 2.1 (P) `extensions/design_extension.yaml` 全 7 top-level section 生成
  - design.md State Definition (line 596-694) を完全準拠で生成
  - top-level: `version` (initial "1.0") / `metadata` (name + description + `layer1_dependency: "1.0"` + `attach_identifier: design_extension`) / `rounds` (10 entry、Round 1-10) / `phase1_metapatterns` (3 entry) / `bias_suppression_quota_design_specific` (4 entry: formal_challenge / detection_miss / phase1_isomorphism_search / rigorous_verification_5) / `escalate_required_conditions` (5 entry) / `chappy_p0_invocation` (3 facility = fatal_patterns_match / impact_score / forced_divergence_prompt、`./` install root 基点 path、A5 fix 整合) / `v4_features_invocation` (5 facility = judgment_subagent_dispatch / necessity_5_fields_evaluation / five_condition_rule / three_label_classification / fix_negation_prompt_role_separation、**全 path `./` install root 基点で生成 = `./skills/dr-judgment` / `./schemas/necessity_judgment.schema.json` 等、design.md A5 fix の `chappy_p0_invocation` 限定範囲を `v4_features_invocation` にも extension 適用、A1 apply**) / `layer3_attach_acceptance` (override_hierarchy: layer_3_over_layer_2)
  - `rounds` 各 entry に `round_index` + `name` (規範範囲確認 / 一貫性 / 実装可能性 + アルゴリズム + 性能 統合 / 責務境界 / 失敗モード + 観測 統合 / concurrency / timing / security / cross-spec 整合 / test 戦略 / 運用) + `description` + `related_seed_patterns: []` (**placeholder 空 list、具体 mapping は本 spec implementation phase で foundation seed_patterns.yaml 23 件 entry 実体化と同 timing 確定**、design.md L638 整合) + 確定 timing 注記 comment (例: `# resolution timing: implementation phase, when foundation seed_patterns.yaml 23 entries are materialized`)
  - `attach_identifier: design_extension` (Req 4.1 整合、foundation Layer 1 attach contract identifier 形式)
  - bilingual section heading 適用 (yaml comments)
  - Observable: yaml parse 成功 + 7 top-level section presence + `rounds` array 10 entry (round_index 1-10 各 `related_seed_patterns: []` placeholder + 確定 timing comment presence) + `phase1_metapatterns` 3 entry + `bias_suppression_quota_design_specific` 4 entry + `escalate_required_conditions` 5 entry + `chappy_p0_invocation` 3 facility + `v4_features_invocation` 5 facility + `attach_identifier == "design_extension"` + **全 path 文字列 (`chappy_p0_invocation` + `v4_features_invocation` 内) が `./` 基点 (`../` 不在)** assert (A1 apply)
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 7.2_
  - _Boundary: extensions/design_extension.yaml_

- [ ] 2.2 (P) `prompts/forced_divergence_prompt.txt` 配置 (3 段落構成、英語固定)
  - design.md Final Prompt Text (line 727-735) を byte-level copy
  - 3 段落構成 (空行 separated):
    1. **Instruction 段落**: independent detection 後 separate forced divergence challenge 実施明示
    2. **Method 段落**: 暗黙前提 identify + alternative premise replace + 結論成立性試行
    3. **Role separation 段落**: judgment subagent 担当 fix-negation との区別明示 ("forced divergence questions the validity of the conclusion itself, not the necessity of the proposed fix")
  - 英語固定 single canonical form
  - Observable: text file 配置 + 3 段落 (= 空行 separated 3 paragraphs) presence + `forced_divergence_prompt.txt` content と design.md §forced_divergence Prompt Template Final Prompt Text (L727-735) を空白 / 改行 normalize 後の byte-level diff した結果が 0 byte + role separation 段落で `forced divergence` / `fix-negation` / `judgment` 各 keyword presence
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 7.4_
  - _Boundary: prompts/forced_divergence_prompt.txt_

- [ ] 3. dr-judgment Skill 実装
- [ ] 3.1 `skills/dr-judgment/SKILL.md` 起動規約 + dispatch instructions
  - skill name + description + 起動 args 3 種 (`--payload-json` arg [stdin 代替も許容] = primary findings + adversarial findings + counter_evidence + requirements + design / `--dual-reviewer-root` arg = foundation install location absolute path / `--config-yaml-path` arg = target project `.dual-reviewer/config.yaml` の絶対 path、`judgment_model` 取得用、design.md DrJudgmentService Interface L536 整合、A6 apply)
  - behavior 規約: foundation `./prompts/judgment_subagent_prompt.txt` 動的読込、dispatch payload assemble (primary findings + adversarial findings + adversarial_counter_evidence + requirements_text + design_text + semi-mechanical mapping defaults 7 種)、Claude Code Agent tool で judgment_reviewer subagent dispatch (`subagent_type: general-purpose` + `model: sonnet` via config.yaml `judgment_model`)、出力 yaml validate + escalate mapping (uncertainty=high → should_fix + user_decision)
  - 修正否定試行 prompt (V4 §5.2 既存組込、judgment 用、修正 proposal 必要性否定) を judgment subagent 内、forced_divergence prompt (Step B、本 spec `prompts/forced_divergence_prompt.txt`、結論成立性試行) を adversarial 内 = 役割分離維持 (判定 5-C 整合)
  - 出力 mechanism = stdout default (Decision 5)、代替 (一時 file path) も許容
  - Layer 3 project 固有 terminology entries は foundation Layer 1 contract (foundation Req 1.6) に従い attach、override 階層 (Layer 3 > Layer 2 > Layer 1) で Layer 3 entry が本 spec terminology を override 可能 (Req 5.7)
  - bilingual section heading 適用
  - frontmatter 規約: kiro-* + dr-init 同方式 (`name` / `description` field、design.md Decision 4 整合)
  - Observable: SKILL.md 配置 + Claude Code skill format spec 準拠 valid markdown + frontmatter `name` / `description` field presence + dispatch / 修正否定試行 / 役割分離 各 mention + **起動引数 3 種 (`--payload-json` / `--dual-reviewer-root` / `--config-yaml-path`) mention** (A6 apply)
  - _Requirements: 3.1, 3.3, 3.7, 3.8, 5.7, 7.1_
  - _Depends: 1_

- [ ] 3.2 `skills/dr-judgment/judgment_dispatcher.py` 実装
  - foundation `./prompts/judgment_subagent_prompt.txt` を起動時動的 read (hardcode 禁止、Req 5.5)
  - dispatch payload assemble: `primary_findings` + `adversarial_findings` + `adversarial_counter_evidence` (adversarial subagent 同一 yaml 出力の **別 section** = adversarial 1 dispatch で 2 役割分離 output) + `requirements_text` (当該 spec requirements.md 全文) + `design_text` (design phase only、design.md 全文) + `semi_mechanical_mapping_defaults` (foundation V4 §1.4.2 7 種 inline embed)
  - Claude Code Agent tool dispatch は **Claude assistant が SKILL.md instructions に従って実行** (`subagent_type: general-purpose` + `model: sonnet` via config.yaml `judgment_model`)。Python helper script (`judgment_dispatcher.py`) は dispatch logic を実装せず、payload assemble + output yaml validate helper のみ責務 (design.md L565-568 = "SKILL.md instructions = Claude assistant が ... judgment subagent dispatch + yaml validate を実行。judgment_dispatcher.py が prompt load + payload assemble + yaml output validate helpers を提供" 整合、P4 apply)
  - 出力 yaml を foundation `./schemas/necessity_judgment.schema.json` で validate (Python `jsonschema.Draft202012Validator`、本 task は単一 schema validate に責務限定、cross-file `$ref` resolver 設定は foundation Task 7.5 に集約)
  - 5 条件判定ルール (V4 §1.4.1 = critical impact / requirement_link+ignored_impact / scope_expansion / fix_cost vs ignored_impact / uncertainty) 順次評価指示を judgment subagent prompt 内で明示 (= prompt template 内既存)
  - escalate mapping: uncertainty=high → `should_fix` + `recommended_action: user_decision` (foundation `fix_decision.label` 3 値 enum 整合、Req 3.5)
  - semi-mechanical mapping default 7 種 (V4 §1.4.2) を judgment subagent prompt 内 inline 保持 + override 時 `override_reason` field 必須記録
  - 出力 yaml stdout 経由返却 (default、Decision 5)、代替 (一時 file path) 引数も許容
  - exit code: 0=success / 1=prompt read fail / 2=judgment subagent dispatch fail / 3=output yaml validate fail
  - 2 スペースインデント遵守 (`.kiro/steering/tech.md` 整合)
  - Observable: `python3 scripts/dual_reviewer_prototype/skills/dr-judgment/judgment_dispatcher.py` で sample payload (mock primary + mock adversarial + mock requirements/design) 投入 → yaml output が `necessity_judgment.schema.json` validate pass + escalate mapping (uncertainty=high → should_fix + user_decision) 動作確認
  - _Requirements: 3.1, 3.2, 3.4, 3.5, 3.6, 3.8, 5.1, 5.5, 7.3_
  - _Depends: 1_

- [ ] 4. dr-log Skill 実装
- [ ] 4.1 `skills/dr-log/SKILL.md` 起動規約 + log writing instructions
  - skill name + description + 起動 args (subordinate skill として dr-design から invoke、session lifecycle = open / append / flush の 3 method、A1 fix integration)
  - behavior 規約: foundation `./schemas/` 動的読込、target project `.dual-reviewer/config.yaml` `dev_log_path` field 動的読込、JSONL append-only 1 line = 1 review_case object、schema validate fail-fast (finding ID + 違反 field + 期待 enum + 実値 enumerate to stderr)
  - LLM 自己ラベリング prompt 組込: primary 自己ラベリング (`miss_type` / `trigger_state`) + adversarial 自己ラベリング (`difference_type`) を全 finding 生成時に必須付与
  - 3 系統対応 (Req 2.7):
    - single 系統: state=detected, source=primary_self_estimate, adversarial_counter_evidence omit
    - dual 系統: state=detected, source=primary_self_estimate, adversarial_counter_evidence required
    - dual+judgment 系統: state=judged, source=judgment_subagent, adversarial_counter_evidence required
  - session lifecycle 詳細 (A1 fix):
    - `open(session_id, treatment, round_index, design_md_commit_hash, target_spec_id, config_yaml_path)`: session 開始 + `timestamp_start` (ISO8601) 自動付与 + in-memory state 初期化
    - `append(session_id, finding)`: per finding を in-memory accumulator 追加 + 即時 schema validate fail-fast
    - `flush(session_id)`: 1 review_case object 組立 + JSONL append-only に 1 line + `timestamp_end` 自動付与 + accumulator 削除 (= **flush は 1 session_id ごとに exactly 1 JSONL line を produce**、A1 grain-correction guarantee)
  - Layer 3 project 固有 terminology attach 整合 (Req 5.7、override 階層 Layer 3 > Layer 2 > Layer 1)
  - bilingual section heading 適用
  - frontmatter 規約 同上
  - Observable: SKILL.md 配置 + valid markdown + frontmatter `name` / `description` field presence + open/append/flush / 3 系統 / 自己ラベリング 各 mention + flush 1 line/session 明記
  - _Requirements: 2.5, 2.7, 5.7, 7.1_
  - _Depends: 1_

- [ ] 4.2 `skills/dr-log/log_writer.py` 実装 (session-scoped accumulator + schema validate + 3 系統対応)
  - foundation `./schemas/` (review_case + finding + impact_score + failure_observation + necessity_judgment) を Python `jsonschema.Draft202012Validator` で起動時動的 read (hardcode 禁止、Req 5.6)
  - target project `.dual-reviewer/config.yaml` `dev_log_path` field を起動時動的 read (hardcode 禁止、Req 2.4)
  - cross-file `$ref` 解決: `jsonschema.RefResolver` (or v4.18+ `Registry`) で foundation `./schemas/` directory absolute path を `base_uri` に設定 (foundation Task 7.5 cross-file resolver 設定責務に依拠、本 task は foundation 設定済 resolver を import 利用)
  - Service Interface 3 method 実装 (A1 fix):
    - `open(session_id, treatment, round_index, design_md_commit_hash, target_spec_id, config_yaml_path)`: review session 開始、in-memory state 初期化、`timestamp_start` (ISO8601) 自動付与
    - `append(session_id, finding)`: per finding を in-memory accumulator 追加、即時 schema validate fail-fast (state=detected で necessity_judgment optional / state=judged で必須)
    - `flush(session_id)`: 1 review_case object 組立 (session metadata + 全 finding aggregate)、JSONL append-only に 1 line 書出、`timestamp_end` (ISO8601) 自動付与、accumulator 削除 (= **flush invocation 1 回で exactly 1 JSONL line per session_id**)
  - schema validate fail-fast: stderr に finding ID + 違反 field + 期待 enum 値 + 実値 enumerate (Req 2.6)、non-zero exit
  - **2 層 source field 明示分離** (A4 apply): `finding.source` (foundation `finding.schema.json` 内 enum = `primary | adversarial` = **検出元**、誰が finding を検出したか) と `necessity_judgment.source` (foundation `necessity_judgment.schema.json` 内 enum = `primary_self_estimate | judgment_subagent` = **判定元**、誰が修正必要性を判定したか) は別 schema 階層 + 別 enum 値 = 混同しない
  - 3 系統対応 helper (= `necessity_judgment.source` field 値の 3 系統別切替):
    - single: `state=detected`, `necessity_judgment.source=primary_self_estimate` (judgment subagent 未起動、primary 自己 estimate)、`adversarial_counter_evidence` omit
    - dual: `state=detected`, `necessity_judgment.source=primary_self_estimate` (同上)、`adversarial_counter_evidence` required (string)
    - dual+judgment: `state=judged`, `necessity_judgment.source=judgment_subagent` (judgment subagent 確定値)、`adversarial_counter_evidence` required (string)
  - 各 finding object 自体の `finding.source` field は **検出元** (primary or adversarial) を表現、3 系統 treatment と独立 (treatment 区別なし)
  - exit code: 0=success / 1=schema validate fail or schema read fail / 2=config read fail / 3=JSONL write fail
  - 2 スペースインデント遵守
  - Observable: log_writer.py 配置 + Python parse 成功 + sample (open → append 1 finding mock → flush) sequence で `dev_log.jsonl` に 1 line 追記成功 + JSON parse OK + 1 review_case object に `treatment` / `round_index` / `design_md_commit_hash` / `timestamp_start` / `timestamp_end` field presence + state=judged で necessity_judgment 必須 validate 動作確認
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.6, 2.7, 5.1, 5.6, 7.3_
  - _Depends: 1_

- [ ] 5. dr-design Skill 実装
- [ ] 5.1 `skills/dr-design/SKILL.md` orchestration instructions
  - skill name + description + 起動 args (target_design_md_path + dual_reviewer_root + config_yaml_path + `--treatment` flag = single | dual | dual+judgment)
  - 10 Round sequential orchestration: Round 1-10、各 Round で Step A → B → C → D 順次実施、**Round 開始時 dr-log `open(session_id, treatment, round_index, design_md_commit_hash, ...)` invoke + Round 終端時 `flush(session_id)` invoke** (A1 fix integration)
  - Step A (primary detection): invoking Claude assistant (= primary_reviewer = Opus、`config.yaml` `primary_model`) が直接実行、Step 1a 軽微検出 + Step 1b 構造的検出 5 重検査 (二重逆算 / Phase 1 patterns / dev-log patterns [seed_patterns + extracted_patterns 照合] / 自己診断 / 内部論理整合) + Step 1b-v 自動深掘り (5 観点 + 5 切り口 negative 視点 強制発動)
  - Step B (adversarial review): adversarial subagent (Sonnet、`config.yaml` `adversarial_model`) を Claude Code Agent tool で dispatch、3 task = independent Step 1b detection + forced_divergence prompt (本 spec `./prompts/forced_divergence_prompt.txt` 末尾追加) + V4 §1.5 fix-negation prompt (英語固定 3 行 inline embed、Decision 3)
  - **V4 §1.5 fix-negation prompt sync header 3 行** (Decision 3 整合、SKILL.md 内 inline 配置): (1) `# canonical-source: docs/過剰修正バイアス.md §3 (or .kiro/methodology/v4-validation/v4-protocol.md §1.5)`、(2) `# v4-protocol-version: 0.3`、(3) `# sync-policy: byte-level integrity, manual sync at v4-protocol revision`。本文 3 行 = `For each proposed fix, argue why it may not be necessary. / Classify it as must_fix, should_fix, or do_not_fix. / Prefer do_not_fix when the issue is speculative, expands scope, or lacks requirement linkage.` (V4 §5.1 byte-level copy)
  - Step C (judgment): dr-judgment skill を Claude Code skill invocation で起動、payload (primary findings + adversarial findings + adversarial_counter_evidence + requirements + design) 渡す
  - Step D (integration): primary + adversarial + judgment yaml merge、V4 §2.5 三ラベル提示 (must_fix bulk apply default / do_not_fix bulk skip default / should_fix individual review) を user 提示用に構造化、**自動 apply / skip 禁止** (V4 §2.5 user oversight 原則整合、user 判断必須)
  - bias 抑制 quota event-triggered 発動 (formal challenge / 検出漏れ / Phase 1 同型探索 / 厳しく検証 5 種) + Phase 1 escalate 3 メタパターン (規範範囲先取り / 構造的不均一 / 文書 vs 実装不整合) Step 1b 5 重検査内必ず照合 + Chappy P0 全機能 (foundation `fatal_patterns.yaml` 8 種強制照合 + `impact_score` 3 軸付与 + forced_divergence prompt) invoke + escalate 必須条件 5 種 (内部矛盾 / 実装不可能性 / 責務境界 / 規範範囲 / 複数選択肢 trade-off) Step 1b-v + Step 1c 両方適用
  - 3 系統 treatment 切替 (Decision 6 prep、v1.2 改修要件):
    - `--treatment single`: Step B/C 全 skip (primary のみ運用) + Step D で primary 検出のみ user 提示
    - `--treatment dual`: Step B 実行 + Step C skip (judgment 起動なし) + Step D で primary + adversarial 検出 user 提示
    - `--treatment dual+judgment`: Step B/C 全実行 (V4 完全) + Step D で primary + adversarial + judgment 結果 user 提示
  - target design.md commit hash 取得 (`git rev-parse HEAD -- <design.md>`) → dr-log invocation `open(...)` payload `design_md_commit_hash` 付与 (A2 fix、reproducibility、dogfeeding spec Req 3.7 整合)
  - adversarial 出力 yaml の counter_evidence section を issue_id 単位 decompose → 各 finding object の `adversarial_counter_evidence` field 付与 (A6 fix、dual / dual+judgment 系統)
  - Layer 3 terminology attach 整合 (Req 5.7、override 階層)
  - bilingual section heading 適用
  - frontmatter 規約 同上
  - Observable: SKILL.md 配置 + valid markdown + frontmatter + Round 1-10 sequential mention + Step A/B/C/D 構造 + treatment 3 系統 + V4 §2.5 三ラベル提示 + bias quota event-triggered + Chappy P0 invocation + escalate 必須条件 5 種 + V4 §1.5 sync header 3 行 inline embed + Round 開始時 dr-log open invoke + Round 終端 flush invoke 各 mention
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 5.7, 6.4, 7.1, 7.2, 7.5_
  - _Depends: 2.1, 2.2, 3, 4_

- [ ] 5.2 `skills/dr-design/orchestrator.py` 実装 (Layer 1/2 yaml load + 5 重検査 helper + path resolution + commit hash + counter_evidence decompose + treatment switch)
  - foundation `./framework/layer1_framework.yaml` + 本 spec `./extensions/design_extension.yaml` を起動時動的 read (hardcode 禁止、Req 5.1)
  - foundation `./patterns/seed_patterns.yaml` の `version` field 動的読込 + 内部 quota / pattern matching 反映 (Req 5.3)
  - foundation `./patterns/fatal_patterns.yaml` 8 種 enum 動的読込 (Req 5.4)
  - 本 spec `./prompts/forced_divergence_prompt.txt` 動的 read (Req 6.4)
  - **path resolution helper utility** (例: `resolve_foundation_path(base_root, relative)` function): `--dual-reviewer-root` CLI 引数 default + 環境変数 `DUAL_REVIEWER_ROOT` fallback で foundation install location absolute path を解決 (Task 1 で確定した mechanism、design.md L773 整合)
  - 5 重検査 helper logic (Step 1b、二重逆算 + Phase 1 patterns + dev-log patterns [seed_patterns + Layer 3 extracted_patterns 照合] + 自己診断 + 内部論理整合) の checklist generator
  - target design.md git commit hash 取得 helper: `subprocess.run(["git", "rev-parse", "HEAD", "--", target_design_md_path], cwd=target_project_root, capture_output=True, text=True)` → return non-empty string (= active design.md commit hash)
  - adversarial counter_evidence section 解析 + issue_id 単位 decompose helper (input = adversarial 出力 yaml、output = `adversarial_counter_evidence` field 別 dict by issue_id)
  - treatment 3 系統 切替 helper (Step B/C skip 制御): single → Step B/C skip / dual → Step B exec, Step C skip / dual+judgment → Step B/C exec
  - **V4 §1.5 fix-negation prompt 自体は SKILL.md (Task 5.1) に inline 配置、orchestrator.py は dispatch 自体に関与しない** = adversarial subagent dispatch は **Claude assistant が SKILL.md instructions に従って Agent tool 経由で実行**、orchestrator.py は payload assemble + Layer 1/2 yaml load + 5 重検査 helper + commit hash + counter_evidence decompose + treatment switch helpers のみ責務 (= prompt content の Python 側 file read / regex extract は不実装、design.md L420-424 + L460-466 SKILL.md instructions vs helper script 分担整合、P4 + A3 apply)
  - exit code: 0=success / 1=Layer 1/2 read fail / 2=adversarial dispatch fail / 3=dr-judgment invoke fail / 4=dr-log invoke fail (warning, not abort、A4 fix 整合)
  - 2 スペースインデント遵守
  - Observable: orchestrator.py 配置 + Python parse 成功 + sample target design.md mock で起動 (Round 1 のみ、treatment=dual+judgment) → SKILL.md instructions に従って Layer 1/2 yaml load + foundation patterns yaml load + forced_divergence prompt load + commit hash 取得 (= `git rev-parse` 実行結果が **non-empty `design_md_commit_hash`** として dr-log invocation payload に渡される) + 各 helper function 動作確認
  - _Requirements: 1.1, 1.2, 1.3, 1.6, 1.7, 1.8, 5.1, 5.2, 5.3, 5.4, 6.4_
  - _Depends: 2.1, 2.2, 3, 4_

- [ ] 6. Unit tests
- [ ] 6.1 (P) dr-design orchestrator.py: Layer 1/2 yaml load + Round 1-10 sequential 制御フロー test
  - foundation Layer 1 framework + 本 spec Layer 2 extension yaml mock load → Round 1-10 が指定順 (1, 2, 3, ..., 10) に呼ばれること assert
  - Observable: pytest run で test pass
  - _Requirements: 1.1, 1.9_
  - _Depends: 5.2_

- [ ] 6.2 (P) dr-design orchestrator.py: 5 重検査 logic test
  - Step 1b が 5 layer (二重逆算 / Phase 1 patterns / dev-log patterns / 自己診断 / 内部論理整合) を全 traverse することを確認
  - Observable: pytest run で test pass
  - _Requirements: 1.2_
  - _Depends: 5.2_

- [ ] 6.3 (P) dr-log log_writer.py: open/append/flush session lifecycle + JSONL append-only test
  - clean dev_log.jsonl で `tempfile.TemporaryDirectory` fixture → open → append (1 finding mock) → flush → **flush invocation 1 回で exactly 1 JSONL line per session_id** (A1 grain-correction guarantee) + entry id 返却 + `timestamp_start` / `timestamp_end` field presence + 次回 open → append (2 findings) → flush → 累計 2 JSONL lines (= 1 line per session) 確認
  - Observable: pytest run で test pass
  - _Requirements: 2.4_
  - _Depends: 4.2_

- [ ] 6.4 (P) dr-log log_writer.py: state field variant validate test
  - state=detected で necessity_judgment 省略 → validate pass、state=judged で省略 → validate fail (foundation Task 7.5 cross-file resolver 設定経由)
  - Observable: pytest run で test pass
  - _Requirements: 2.3_
  - _Depends: 4.2_

- [ ] 6.5 (P) dr-log log_writer.py: 3 系統対応 test
  - single/dual/dual+judgment 系統 input で **2 層 source field** + adversarial_counter_evidence field の正しい付与確認 (A4 apply): (1) `finding.source = primary | adversarial` (検出元) は 3 系統共通 / (2) `necessity_judgment.source` = 3 系統別 (single = `primary_self_estimate`, no counter_evidence / dual = `primary_self_estimate`, counter_evidence required / dual+judgment = `judgment_subagent`, counter_evidence required)
  - Observable: pytest run で test pass
  - _Requirements: 2.7_
  - _Depends: 4.2_

- [ ] 6.6 (P) dr-judgment judgment_dispatcher.py: prompt load + payload assemble + escalate mapping + output validate test
  - foundation prompts/judgment_subagent_prompt.txt 動的読込 + dispatch payload 構造 (primary + adversarial + counter_evidence + requirements + design + mapping defaults 7 種) + escalate (uncertainty=high → should_fix + user_decision) + V4 §1.6 yaml format validate
  - Observable: pytest run で test pass
  - _Requirements: 3.1, 3.2, 3.4, 3.5_
  - _Depends: 3.2_

- [ ] 7. Integration tests
- [ ] 7.1 (P) dr-design → adversarial subagent dispatch → dr-judgment invocation → dr-log per finding flow test
  - 1 finding のみで Step A/B/C/D 全 flow を mock subagent + mock skill 経由で実行、Round 1 完了で finding が JSONL append + judgment yaml が dr-design 返却
  - Observable: pytest run で test pass
  - _Requirements: 1.4, 3.8, 2.4_
  - _Depends: 5.2, 4.2, 3.2_
  - _Boundary: tests/integration/design_review/skill_flow/_

- [ ] 7.2 (P) Foundation install location relative path resolution test
  - 3 skill helper script が `./patterns/` + `./prompts/` + `./schemas/` + `./framework/` + `./extensions/design_extension.yaml` を全 locate 可能、hardcode なし確認 (path resolution helper utility 経由 = Task 1 で確定した `--dual-reviewer-root` CLI arg + `DUAL_REVIEWER_ROOT` env fallback)
  - Observable: pytest run で test pass
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_
  - _Depends: 5.2, 4.2, 3.2_
  - _Boundary: tests/integration/design_review/path_resolution/_

- [ ] 7.3 (P) forced_divergence + V4 §1.5 fix-negation prompt の adversarial dispatch payload inline embed test
  - SKILL.md file (Task 5.1) を pytest fixture で read + adversarial subagent dispatch payload (mock 化) string が (1) `prompts/forced_divergence_prompt.txt` の 3 段落全 substring + (2) V4 §1.5 fix-negation 3 行 substring を含むことを assertion (= **pytest 自動化 only**、manual SKILL.md instructions trace 排除、A3 apply)
  - Observable: pytest run で test pass (substring assertion 全 pass、自動化済)
  - _Requirements: 6.4_
  - _Depends: 5.1, 5.2, 2.2_
  - _Boundary: tests/integration/design_review/prompt_embed/_

- [ ] 7.4 (P) 修正否定試行 prompt vs forced_divergence prompt 役割分離 test
  - judgment subagent prompt 内容 = 修正否定試行 (= V4 §5.2 fix-negation、修正 proposal 必要性否定) を foundation `prompts/judgment_subagent_prompt.txt` から読込 / adversarial subagent dispatch payload = forced_divergence (= 結論成立性試行、暗黙前提別前提置換) を本 spec `prompts/forced_divergence_prompt.txt` + V4 §1.5 fix-negation (3 行、SKILL.md 内、judgment 用とは別 prompt) で構成
  - 2 prompt content が **別物** + 役割分離 keyword (judgment "fix-negation" + adversarial "forced divergence questions the validity of the conclusion itself") presence + dr-design SKILL.md (Task 5.1) で adversarial vs judgment dispatch wiring が役割分離通りになっていることを SKILL.md instructions trace で確認
  - Observable: pytest run で test pass
  - _Requirements: 3.7, 6.5_
  - _Depends: 3.2, 2.2, 5.1_
  - _Boundary: tests/integration/design_review/role_separation/_

- [ ] 7.5 (P) 3 系統 (single/dual/dual+judgment) で同一 dr-log skill 動作 test
  - 系統別 finding (state + source + counter_evidence 異なる) を順次 dr-log に投入、JSONL の各 entry が `treatment` field + correct state + correct source で記録されること確認 (single 系統 with primary_self_estimate / dual 系統 with primary_self_estimate + counter_evidence / dual+judgment 系統 with judgment_subagent + counter_evidence)
  - Observable: pytest run で test pass
  - _Requirements: 2.7_
  - _Depends: 4.2_
  - _Boundary: tests/integration/design_review/three_treatment/_

- [ ] 8. E2E test (sample 1 round 通過 = 動作確認終端条件、Req 7.4)
  - **Prerequisite** (P5 apply): Spec 6 (`rwiki-v2-perspective-generation`) design.md generation 完了 (= dogfeeding spec の Spec 6 design phase 着手後にのみ本 task 実行)。Spec 6 が休止中の場合、本 task は dogfeeding spec の Spec 6 design phase 完走を待ち、dogfeeding spec scope で execute される (= 本 spec implementation phase の sample 1 round 通過 test は dogfeeding spec dependency)
  - foundation `dr-init` で target project bootstrap → 本 spec 3 skills + Layer 2 extension + foundation 全 artifact 使用 → dr-design 起動 (target = Spec 6 design.md, treatment=dual+judgment, Round 1 のみ)
  - 3 条件全達成 pass criteria:
    - (a) Round 1 を Step A → B → C → D 全完了
    - (b) dr-log JSONL に最低 1 entry を foundation 提供 schema (失敗構造観測軸 3 要素 + 修正必要性判定軸 V4 §1.3) で validate 成功で記録
    - (c) dr-design Step 2 user 提示用 V4 §2.5 三ラベル提示 yaml (must_fix / should_fix / do_not_fix 分類済み出力) を stdout 出力
  - **注**: 全 10 ラウンド完走 + 3 系統対照実験 (single + dual + dual+judgment) は `dual-reviewer-dogfeeding` spec 責務、本 spec scope 外
  - Observable: 3 条件全達成 = sample 1 round 通過 pass criteria 満たす + (a) Step A/B/C/D 完了 log + (b) JSONL 1 entry validate 成功 + (c) V4 §2.5 yaml stdout output presence
  - _Requirements: 7.4_
  - _Depends: 5.2, 4.2, 3.2, 2.1, 2.2, 1_

## Change Log

- **v1.0** (2026-05-01 14th セッション、本 file 初版): A-1 tasks phase = `/kiro-spec-tasks dual-reviewer-design-review` Skill 経由生成、8 major task / 19 sub-task、Foundation prereqs → Static config data → 3 skills (dr-judgment / dr-log / dr-design) → Validation (unit / integration / E2E) phase 順序、`(P)` parallel marker 11 sub-task、`_Depends_` 注記 17 件 (cross-major dependency)。Step 3 Task plan review gate pass + Step 3.5 sanity review subagent verdict = `NEEDS_FIXES` (10 fix list)、1 repair pass で 9 fix integrate (#6 sequential ordering で sufficient のため skip)。
- **v1.1** (2026-05-01 14th セッション、V4 ad-hoc protocol Step 1a/1b/1b-v/1c/2/3 review gate 完走後): V4 review 15 件 (P1-P8 primary + A1-A7 adversarial) 検出、judgment subagent 必要性評価で must_fix 2 / should_fix 5 / do_not_fix 8、user 三ラベル提示で全 7 件 apply (must_fix bulk apply + should_fix bulk apply + do_not_fix bulk skip)。
  - **A1 apply** (must_fix): Task 2.1 description + Observable で `v4_features_invocation` 内 path も `./` 基点で生成する旨明示 (design.md A5 fix の `chappy_p0_invocation` 限定範囲を `v4_features_invocation` にも extension 適用、L676/L679 の `../` 基点を `./` install root 基点に統一、Observable で `../` 不在 assert 追加)
  - **A6 apply** (must_fix): Task 3.1 起動 args bullet を 3 種に更新 (`--payload-json` + `--dual-reviewer-root` + `--config-yaml-path`、`judgment_model` 取得用、design.md DrJudgmentService Interface L536 整合) + Observable に起動引数 3 種 mention 追記
  - **P4 apply** (should_fix): Task 3.2 description で "Claude Code Agent tool dispatch" を **Claude assistant が SKILL.md instructions に従って実行** に修正、Python helper script は dispatch logic 不実装 + payload assemble + output validate helper のみ責務明示 (design.md L565-568 整合)
  - **P5 apply** (should_fix): Task 8 (E2E) に Prerequisite bullet 追加: "Spec 6 design.md generation 完了 (= dogfeeding spec の Spec 6 design phase 着手後にのみ本 task 実行)。Spec 6 休止中の場合は dogfeeding spec scope で execute"
  - **P6 apply** (should_fix): Task 1 で `jsonschema>=4.18` (Draft 2020-12 + `Registry` API 対応) version pinned 明示、cross-spec 整合で foundation tasks task 1 にも同 version pin 推奨注記
  - **A3 apply** (should_fix): Task 5.2 description に "V4 §1.5 prompt は SKILL.md (Task 5.1) inline、orchestrator.py は dispatch 自体に関与しない" 明示 + Task 7.3 Observable を "SKILL.md file pytest fixture read + dispatch payload string substring assertion (pytest 自動化 only、manual trace 排除)" に修正
  - **A4 apply** (should_fix): Task 4.2 で 2 層 source field 明示分離 (`finding.source = primary | adversarial` 検出元 vs `necessity_judgment.source = primary_self_estimate | judgment_subagent` 判定元) + 3 系統対応 helper 表現を `necessity_judgment.source` 切替として明確化 + Task 6.5 Observable に 2 層 source field assert 追記
  - V4 metric: 採択率 13.3% (2/15) / 過剰修正比率 53.3% (8/15) / should_fix 比率 33.3% (5/15) / judgment override 5 件 / primary↔judgment disagreement 1 件 (P3) / adversarial↔judgment disagreement 2 件 (A6 should_fix → must_fix / A7 should_fix → do_not_fix) / V4 修正否定 prompt 機能 28.6% (foundation 75% より低下、design-review tasks では adversarial が修正必要性高めに評価)
  - do_not_fix 8 件 bulk skip (V4 §2.5 規範通り、内訳 = P1 [cosmetic 文言] / P2 [確認手段未記述 cosmetic] / P3 [open() payload Task 4.1/4.2 SSoT 整合] / P7 [treatment invalid log_writer exit 1 implicit guard] / P8 [granularity annotation noise] / A2 [v1.2-prep scope-appropriate] / A5 [target_project_root dynamic、P5 fix で間接対処] / A7 [A3 fix 統合で一括対処])
  - **tasks-phase ad-hoc V4 caveat 4 件** (`data-acquisition-plan.md` v0.3 §5 整合、paper limitations 明示用): (1) ad-hoc 観点 / (2) phase 横断 strict comparability 問題 / (3) forced_divergence prompt design phase optimization / (4) paper rigor 保証 = preliminary cross-phase verification 補助 evidence
  - **Cross-spec implication**: P6 (jsonschema>=4.18 version pin) は foundation tasks task 1 にも同期適用候補 (Task 5 dogfeeding 完走後 cross-spec review で集約処理、Group C 軽微 implication として統合)
