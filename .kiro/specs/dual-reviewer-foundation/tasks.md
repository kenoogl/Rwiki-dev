# Implementation Plan

## Overview

`dual-reviewer-foundation` の portable 7 artifact (Layer 1 framework + dr-init skill + 共通 JSON schema 5 file + 静的 data 3 種 + V4 §5.2 prompt template + 設定 template 2 種) を `scripts/dual_reviewer_prototype/` 配下に配置する実装計画。Phase A scope = Rwiki repo 内 prototype 段階を厳守、Phase B 独立 fork (npm package 化) は本 spec scope 外。

7 major task / 18 sub-task で構成、Foundation phase (Task 1) → Core phase (Task 2-4) → Integration phase (Task 5) → Validation phase (Task 6-7) の順序で進行。Core phase 内の 3 major task (静的 data / JSON schemas / framework + templates) は major task 間で parallel-capable、Validation phase の sub-task は同 phase 内で parallel-capable。Cross-major dependency は `_Depends:_` 注記で明示。

## Tasks

- [ ] 1. Foundation: install location skeleton + ランタイム前提確認 + tests scaffolding
  - `scripts/dual_reviewer_prototype/` 配下に 7 sub-directory (`framework/`, `schemas/`, `patterns/`, `prompts/`, `config/`, `terminology/`, `skills/`) を生成
  - install location 配下に `tests/` directory + `conftest.py` placeholder を配置 (Validation phase 用 test scaffolding)
  - `README.md` placeholder を配置: bilingual section heading 規約 (project 言語 + 英語ラベル) で foundation 利用ガイド skeleton + Phase A scope 注記 + 7 portable artifact 一覧を記述
  - Python 3.10+ / `pyyaml` / `jsonschema>=4.18` (Draft 2020-12 + `Registry` API 対応 version pinned、Task 7.5 cross-file `$ref` resolver 設定で `Registry` 必須、cross-spec C-1 fix) / `pytest` の install 状態を確認、不足は pip install で揃える (実行環境前提 = `.kiro/steering/tech.md` 整合)
  - Observable: `tree scripts/dual_reviewer_prototype/ -d -L 2` で 7 sub-directory + `tests/` 表示、`README.md` presence、`python3 -c "import yaml, jsonschema, pytest"` が全 import 成功
  - _Requirements: 7.2_

- [ ] 2. Static data + portable artifacts 配置
- [ ] 2.1 (P) `fatal_patterns.yaml` 致命級 8 種固定 enum 配置
  - 8 entry を snake_case key で記述: `sandbox_escape` / `data_loss` / `privilege_escalation` / `infinite_retry` / `deadlock` / `path_traversal` / `secret_leakage` / `destructive_migration`
  - 各 entry に project 言語 (日本語) の `description` を含め、reviewer が design 内容に対し当該 pattern を認識できる粒度で記述 (design.md Domain Model: fatal_patterns.yaml 例文準拠)
  - top-level `version: "1.0"` field を含む
  - bilingual section heading を yaml comments で適用 (例: `# 致命級パターン (Fatal Patterns)`)
  - data 提供のみ責務、matching logic は Layer 2 (`dual-reviewer-design-review` spec) と明記する coment
  - Observable: `python3 -c "import yaml; d = yaml.safe_load(open('scripts/dual_reviewer_prototype/patterns/fatal_patterns.yaml')); assert len(d['patterns']) == 8 and {p['key'] for p in d['patterns']} == {'sandbox_escape','data_loss','privilege_escalation','infinite_retry','deadlock','path_traversal','secret_leakage','destructive_migration'}"` 成功
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 7.2_
  - _Boundary: patterns/fatal_patterns.yaml_

- [ ] 2.2 (P) `seed_patterns.yaml` 23 件 retrofit 配置
  - 23 entry を memory `feedback_review_judgment_patterns.md` 由来で配置、各 entry は `id` / `primary_group` / `secondary_groups` / `description` / `origin` / `detected_in` field を含む
  - 全 entry に `origin: "rwiki-v2-dev-log"` を付与 (initial knowledge 識別)
  - 二層 grouping schema 準拠 (`primary_group` 5-10 種程度 + `secondary_groups` 中程度 granularity)
  - 固有名詞 (Rwiki / Spec X 等) を保持 (Phase A scope、generalization は Phase B-1.0 release prep に defer)
  - top-level `version: "1.0.0"` field (initial commit 後の更新時 increment 必須)
  - bilingual section heading を yaml comments で適用
  - Observable: yaml parse 成功 + `len(patterns) == 23` + 全 entry に `origin == "rwiki-v2-dev-log"`
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 7.2_
  - _Boundary: patterns/seed_patterns.yaml_

- [ ] 2.3 (P) V4 §5.2 judgment subagent prompt template 配置
  - `prompts/judgment_subagent_prompt.txt` 先頭に sync header 3 行を追加: (1) `# canonical-source: .kiro/methodology/v4-validation/v4-protocol.md §5.2`、(2) `# v4-protocol-version: 0.3`、(3) `# sync-policy: byte-level integrity, manual sync at v4-protocol revision`
  - 4 行目以降の本文部分を `.kiro/methodology/v4-validation/v4-protocol.md` §5.2 から英語固定 prompt 全文 byte-level copy
  - 本文に必要性 5-field 評価指示 / semi-mechanical mapping default 7 種 / 5 条件判定ルール 順次評価指示 / 出力 yaml format 規約 を全て含む (V4 §5.2 仕様準拠)
  - 単一 relative path 規約 (`./prompts/judgment_subagent_prompt.txt`) 固定、複数 location candidate を expose しない
  - Observable: header 3 行が固定文字列に一致、4 行目以降本文を v4-protocol.md §5.2 抽出本文と空白 / 改行 normalize 後の byte-level diff した結果が 0 byte (P1 apply、Req 6.2 "byte-level に整合 (minor 差異 = 空白 / 改行 を除き)" 整合)
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 6.10, 7.4_
  - _Boundary: prompts/judgment_subagent_prompt.txt_

- [ ] 3. JSON Schema 5 file 統合生成
  - `schemas/review_case.schema.json` (`$schema` = JSON Schema Draft 2020-12 URL、`session_id` / `phase` enum [requirements, design, tasks, implementation] / `target_spec_id` / `timestamp_start` format date-time / `timestamp_end` / `trigger_state` $ref to `failure_observation.schema.json#/$defs/trigger_state` / `findings` array of finding $ref)
  - `schemas/finding.schema.json` (`issue_id` / `source` enum [primary, adversarial] / `finding_text` / `severity` enum [CRITICAL, ERROR, WARN, INFO] / `state` enum [detected, judged] / `impact_score` $ref / optional `failure_observation` $ref / optional `necessity_judgment` $ref + `state == judged` の時 `necessity_judgment` を required にする `allOf` + `if/then` block)
  - `schemas/impact_score.schema.json` (`severity` 4 値 / `fix_cost` 3 値 [low, medium, high] / `downstream_effect` 3 値 [isolated, local, cross-spec])
  - `schemas/failure_observation.schema.json` (`miss_type` 6 値 / `difference_type` 6 値 / `trigger_state` $ref `#/$defs/trigger_state` + `$defs.trigger_state` 定義 = `negative_check` / `escalate_check` / `alternative_considered` 各 string enum [applied, skipped])
  - `schemas/necessity_judgment.schema.json` (`source` enum [primary_self_estimate, judgment_subagent] / 必要性 5-field [requirement_link, ignored_impact, fix_cost, scope_expansion, uncertainty] / `fix_decision.label` 3 値 [must_fix, should_fix, do_not_fix] / `recommended_action` 3 値 [fix_now, leave_as_is, user_decision] / optional `override_reason` string)
  - 全 schema field 名は英語固定 (`description` 等の自由記述部分は project 言語可、Req 7.3)
  - B-1.0 minimum 拡張 field を `required` array に含める (失敗構造観測軸 3 要素 + 必要性 5-field + `fix_decision.label`)
  - B-1.x optional 拡張 (`decision_path` / `skipped_alternatives` / `bias_signal`) は schema 含めない (consumer 拡張 mechanism = `additionalProperties: true` で許容、Req 3.6)
  - Observable: `python3 -c "import json; [json.load(open(f'scripts/dual_reviewer_prototype/schemas/{n}.schema.json')) for n in ['review_case','finding','impact_score','failure_observation','necessity_judgment']]"` 全 file parse 成功 + 各 file の `$schema` value が `https://json-schema.org/draft/2020-12/schema` を指す
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10, 7.3_

- [ ] 4. Layer 1 framework + 設定 templates
- [ ] 4.1 `framework/layer1_framework.yaml` 全 top-level section 生成
  - design.md State Definition (L361-460) を完全準拠で 7 top-level section + metadata + version を生成: `version` (initial "1.0") / `metadata` (name + description + `v4_protocol_version: "0.3"`) / `step_pipeline` / `bias_suppression_quota` / `pattern_schema` / `attach_contract` / `chappy_p0` / `v4_features` / `terminology`
  - `step_pipeline` に Step A (primary_detection、role: primary_reviewer、sub_steps: [step_1a, step_1b, step_1b_v]) / Step B (adversarial_review、role: adversarial_reviewer、sub_steps: [independent_detection, forced_divergence, fix_negation_counter_evidence]) / Step C (judgment、role: judgment_reviewer、sub_steps: [necessity_evaluation, semi_mechanical_mapping, five_condition_rule, label_decision]) / Step D (integration、role: primary_reviewer、sub_steps: [merge, three_label_presentation, user_oversight]) を内包
  - `bias_suppression_quota.fundamental_events` に 3 events (`formal_challenge`, `detection_miss`, `phase1_pattern_match`) + `measurement_policy: post_run_only` (Goodhart 回避)
  - `pattern_schema.structure: two_layer_grouping` + `layers.primary_group: required` + `layers.secondary_groups: required`
  - `attach_contract.placeholder_resolution` 1 行注記 (V4 review P4 apply、`{layer2_install_root}` / `{target_project_root}` resolve mechanism 明示) + `layer_2` (entry_point_location / identifier_format / failure_signal) + `layer_3` (同形 interface) + `override_hierarchy.order: [layer_3, layer_2, layer_1]` + `semantics: single_direction_unidirectional`
  - `chappy_p0` に 3 facility expose: `fatal_patterns_match` (data_source = `./patterns/fatal_patterns.yaml`、matching_responsibility: layer_2) / `impact_score` (schema = `./schemas/impact_score.schema.json`、axes 3) / `forced_divergence_prompt` (canonical_form: english、placement: adversarial_subagent_prompt_tail、final_text_definition_responsibility: dual-reviewer-design-review)
  - `v4_features` に 5 facility expose: `judgment_subagent_dispatch` (prompt_source = `./prompts/judgment_subagent_prompt.txt`) / `necessity_5_fields` / `five_condition_rule` (5 rule + evaluation_order: sequential_strongest_wins) / `three_label_classification` / `role_separation` (Step B forced_divergence = adversarial_reviewer / Step C fix_negation = judgment_reviewer の分担明示)
  - `terminology.role_abstractions` に 3 抽象名 (`primary_reviewer`, `adversarial_reviewer`, `judgment_reviewer`) + `concrete_model_resolution: config_yaml_field`
  - bilingual section heading を yaml comments で適用 (例: `# Step Pipeline (Step A/B/C/D)`)
  - Observable: yaml 1.2 parse 成功 + 7 top-level section 全 presence + `terminology.role_abstractions` が `[primary_reviewer, adversarial_reviewer, judgment_reviewer]` に一致 + `override_hierarchy.order` が `[layer_3, layer_2, layer_1]` に一致
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 7.1, 7.2_

- [ ] 4.2 (P) `config/config.yaml.template` 5 field placeholder 生成
  - 5 field を populate: `primary_model: <primary-model>` / `adversarial_model: <adversarial-model>` / `judgment_model: <judgment-model>` / `lang: ja` / `dev_log_path: .dual-reviewer/dev_log.jsonl`
  - 各 field の用途 + 確定 timing を bilingual comment で記述 (project bootstrap 後 user が placeholder を具体 model identifier に置換する旨)
  - Observable: yaml parse 成功 + 5 field 全 presence + 3 model field の値が placeholder 文字列 (`<...>` 形式) + `lang == "ja"` + `dev_log_path == ".dual-reviewer/dev_log.jsonl"`
  - _Requirements: 2.2, 7.1_
  - _Boundary: config/config.yaml.template_

- [ ] 4.3 (P) `terminology/terminology.yaml.template` 生成
  - top-level `version: "1.0"` + `entries: []` 空 list を含む
  - dr-init が target project の `.dual-reviewer/terminology.yaml` に copy する placeholder としての役割を bilingual comment で記述
  - 実体的蓄積は Phase A-2 dogfeeding 以降 (target 30-50 entries は Phase B-1.2 まで延伸) と注記
  - Observable: yaml parse 成功 + `version` field presence + `entries == []` 空 list 確認
  - _Requirements: 7.5_
  - _Boundary: terminology/terminology.yaml.template_

- [ ] 5. dr-init Skill 実装
- [ ] 5.1 `skills/dr-init/SKILL.md` 起動規約 + behavior + exit code 規約
  - skill name + description + 起動 args (`--lang ja` default、`--lang ja` 以外 reject + Phase B-1.3 reference message)
  - behavior 規約: clean target → `.dual-reviewer/` directory + 4 file (config.yaml + extracted_patterns.yaml + terminology.yaml + dev_log.jsonl) 生成 → stdout に absolute path 1 行 → exit 0
  - exit code 規約: `0` = success / `1` = conflict (既存 `.dual-reviewer/`) / `2` = filesystem error / `3` = unsupported lang / `4` = rollback failure
  - all-or-nothing rollback semantics 記述 + rollback failure 時 stderr に削除失敗 file の absolute path list を enumerate + 手動削除指示提示 (silent fail 禁止)
  - target project の `.dual-reviewer/` 配下以外の任意 file (`CLAUDE.md` / `.kiro/` / source code 等) を改変しない invariants 明示
  - bilingual section heading 適用
  - frontmatter 規約: kiro-* skill (例: `.claude/skills/kiro-spec-tasks/SKILL.md`) を sample として参照、required field (`name` / `description`) を同形式で記述 (design.md 設計決定 4 = "kiro-* skill と同方式" を Task に明示反映、P3 apply)
  - Observable: `skills/dr-init/SKILL.md` 配置 + Claude Code skill format spec (frontmatter + content) 準拠の valid markdown ファイルとして parse 可能 + frontmatter に `name` / `description` field presence
  - _Requirements: 2.1, 2.4, 2.5, 2.7_
  - _Depends: 4.2, 4.3_

- [ ] 5.2 `skills/dr-init/bootstrap.py` 実装 (all-or-nothing rollback)
  - 引数 parse: `--target` (target project root path) / `--lang` (default `ja`)
  - 4 重 mechanical pre-check: (a) target が directory か / (b) `.dual-reviewer/` 既存か / (c) `--lang` ≠ `ja` か / (d) target 書込権限あるか — いずれか fail で early exit (各 exit code)
  - 4 file 生成: (a) `config.yaml` (config.yaml.template から copy + 5 field populate) / (b) `extracted_patterns.yaml` (Layer 3 placeholder、空 patterns list + version "1.0" を inline 書出 + bilingual heading) / (c) `terminology.yaml` (terminology.yaml.template から copy) / (d) `dev_log.jsonl` (空 file、append target)
  - all-or-nothing rollback: 生成途中で write error / permission denied / partial write 検出時、生成済 file を全削除 (pre-bootstrap state 復元)、partial state を残さない
  - rollback failure handling: rollback 中の write error 時、削除失敗 file の absolute path を **1 line per path** 形式で stderr に enumerate (= design.md Service Interface `residual_files: string[]` の 1 entry per line 表現) + 手動削除指示 message + exit 4 (silent fail 禁止、P6 apply)
  - success 時 stdout に `.dual-reviewer/` の absolute path を 1 行で報告 + exit 0
  - target project の `.dual-reviewer/` 配下以外を一切改変しない invariant
  - 2 スペースインデント遵守 (`.kiro/steering/tech.md` 整合)
  - Observable: `python3 scripts/dual_reviewer_prototype/skills/dr-init/bootstrap.py --target /tmp/dr_init_test --lang ja` で `/tmp/dr_init_test/.dual-reviewer/` 配下に 4 file 生成 + stdout が absolute path 1 行 + exit 0
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_
  - _Depends: 4.2, 4.3_

- [ ] 6. Unit tests
- [ ] 6.1 dr-init bootstrap success path test
  - `tempfile.TemporaryDirectory` で clean target project root を fixture 生成
  - bootstrap.py 起動 (`--lang ja`) → exit 0 + stdout absolute path 1 行 assert
  - 生成 file 4 個 (config.yaml + extracted_patterns.yaml + terminology.yaml + dev_log.jsonl) の presence assert
  - config.yaml が 5 field (primary_model / adversarial_model / judgment_model / lang=ja / dev_log_path) populated 確認
  - extracted_patterns.yaml content 確認: `version` field presence + `patterns: []` 空 list (Layer 3 placeholder としての initial state、A6 apply)
  - target project の `.dual-reviewer/` 配下以外 (例: target に予め置いた dummy file) が改変なし confirmation
  - Observable: pytest run で test pass (= success path 全 assertion pass)
  - _Requirements: 2.1, 2.2, 2.4_
  - _Depends: 5.2_

- [ ] 6.2 dr-init failure path test (conflict + rollback + rollback failure + unsupported lang + 改変禁止)
  - conflict test: 既存 `.dual-reviewer/` を持つ target → exit 1 + 既存 file 上書きなし + stderr conflict message presence
  - unsupported lang test: `--lang en` → exit 3 + stderr に Phase B-1.3 reference message presence
  - rollback test: filesystem error injection (test mock で permission denied or chmod readonly) → 生成済 file 全削除 + exit 2 + stderr error report
  - rollback failure test: rollback 中の write error injection (= 削除も失敗) → exit 4 + stderr に残存 file list (削除失敗 absolute path) enumerate + 手動削除指示 message
  - 改変禁止 test: target の `.kiro/`, `CLAUDE.md`, source files 等 dummy file が修正なし confirmation
  - Observable: pytest run で 5 failure path 全 test pass
  - _Requirements: 2.3, 2.5, 2.6, 2.7_
  - _Depends: 5.2_

- [ ] 6.3 (P) JSON Schema unit validation: 5 schema 各 valid + invalid sample
  - 5 schema 各々に valid sample (schema 適合) を作成、`jsonschema.Draft202012Validator` で validate → pass (本タスクは **単一 schema 完結 validate に責務限定**、cross-file `$ref` 解決は Task 7.5 に集約、A4 apply)
  - 5 schema 各々に invalid samples 作成 (各 enum 値違反 / required field 欠落 / 型違反) → fail expected
  - finding state variant: `state: detected` で `necessity_judgment` 省略 → validate pass、`state: judged` で `necessity_judgment` 省略 → validate fail
  - B-1.0 required mark 確認: 必要性 5-field / `fix_decision.label` / 失敗構造観測軸 3 要素を schema の `required` array に含む
  - Observable: pytest run で 5 schema × (valid + invalid samples + state variant) test 全 pass
  - _Requirements: 3.7, 3.8, 3.9_
  - _Depends: 3_
  - _Boundary: tests/schemas/_

- [ ] 7. Integration tests
- [ ] 7.1 (P) Foundation install location relative path locate test
  - foundation install location (`scripts/dual_reviewer_prototype/`) からの相対 path で 8 file (`schemas/review_case.schema.json` / `schemas/finding.schema.json` / `schemas/impact_score.schema.json` / `schemas/failure_observation.schema.json` / `schemas/necessity_judgment.schema.json` / `patterns/seed_patterns.yaml` / `patterns/fatal_patterns.yaml` / `prompts/judgment_subagent_prompt.txt`) 全 locate
  - JSON Schema parser で 5 schema parse 成功
  - yaml parse で 2 patterns 成功
  - text 読込で 1 prompt 成功 (header 3 行 + 本文 presence)
  - Observable: pytest run で 8 file locate + parse 全 pass
  - _Requirements: 3.10, 4.6, 5.4, 6.1, 6.9_
  - _Depends: 2.1, 2.2, 2.3, 3_
  - _Boundary: tests/integration/relative_path/_

- [ ] 7.2 (P) dr-init → consumer mock config 読込 test
  - dr-init bootstrap で tempfile target project に `.dual-reviewer/config.yaml` 生成
  - consumer mock (本 spec scope では Python script で実装) が `.dual-reviewer/config.yaml` を yaml parse → 5 field 全 populate 確認
  - placeholder 文字列 (`<primary-model>` / `<adversarial-model>` / `<judgment-model>`) が default 値として presence 確認
  - `lang == "ja"` + `dev_log_path == ".dual-reviewer/dev_log.jsonl"` 確認
  - Observable: pytest run で test pass + 5 field 全 populated
  - _Requirements: 2.2_
  - _Depends: 5.2_
  - _Boundary: tests/integration/dr_init_consumer/_

- [ ] 7.3 (P) V4 §5.2 prompt sync byte-level diff test
  - `prompts/judgment_subagent_prompt.txt` 先頭 3 行が固定 header (canonical-source path / v4-protocol-version / sync-policy) 文字列に一致を assert
  - 4 行目以降の本文部分を `.kiro/methodology/v4-validation/v4-protocol.md` §5.2 抽出本文と byte-level diff (空白 / 改行 normalize 後 0 byte 差分)
  - 本 spec 単独改変禁止 enforcement (= V4 protocol 改訂以外の本文変更が test fail で検出される)
  - Observable: pytest run で header 3 行 presence + 本文 0 byte diff test pass
  - _Requirements: 6.2, 6.8, 6.10_
  - _Depends: 2.3_
  - _Boundary: tests/integration/v4_sync/_

- [ ] 7.4 (P) layer1_framework.yaml structure + content semantic presence test
  - yaml 1.2 parse 成功
  - 全 7 top-level section (`step_pipeline` / `bias_suppression_quota` / `pattern_schema` / `attach_contract` / `chappy_p0` / `v4_features` / `terminology`) presence
  - `step_pipeline` に Step A/B/C/D 4 step + 各 sub_steps presence
  - `bias_suppression_quota.fundamental_events` が `['formal_challenge', 'detection_miss', 'phase1_pattern_match']` に一致 + `measurement_policy == 'post_run_only'`
  - `pattern_schema.structure == 'two_layer_grouping'` + primary_group/secondary_groups required
  - `attach_contract.layer_2` 3 要素 + `attach_contract.layer_3` 3 要素 = 合計 6 field (各 layer に entry_point_location + identifier_format + failure_signal) presence + `attach_contract.override_hierarchy.order == ['layer_3', 'layer_2', 'layer_1']` 完全一致 (P2 apply)
  - `chappy_p0` 配下 3 facility (fatal_patterns_match / impact_score / forced_divergence_prompt) presence
  - `v4_features` 配下 5 facility (judgment_subagent_dispatch / necessity_5_fields / five_condition_rule / three_label_classification / role_separation) presence + `role_separation.step_b_forced_divergence.assigned_to == 'adversarial_reviewer'` + `role_separation.step_c_fix_negation.assigned_to == 'judgment_reviewer'`
  - `terminology.role_abstractions` が `['primary_reviewer', 'adversarial_reviewer', 'judgment_reviewer']` 完全一致
  - Observable: pytest run で structure + content semantic assertion 全 pass
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9_
  - _Depends: 4.1_
  - _Boundary: tests/integration/framework_structure/_

- [ ] 7.5 (P) JSON Schema 複合条件 validation test ($ref + allOf + if/then mixed)
  - finding schema の `state == judged` 時 `necessity_judgment` 必須 condition を `jsonschema.Draft202012Validator` で実装
  - valid sample 1: `state: detected` without `necessity_judgment` → pass
  - valid sample 2: `state: judged` with `necessity_judgment` (必要性 5-field + fix_decision.label) → pass
  - invalid sample: `state: judged` without `necessity_judgment` → fail (期待通り)
  - $ref 解決 chain (review_case → finding → impact_score / failure_observation / necessity_judgment) も検証 (review_case sample が finding array 経由で全 nested $ref を解決): `jsonschema.RefResolver` (or v4.18+ の `jsonschema.Registry`) で `base_uri` を `schemas/` directory absolute path に設定、cross-file `$ref` を解決。**本タスクが cross-file `$ref` resolver 設定の責務を持つ** (Task 6.3 は単一 schema 完結 validate に責務限定、A4 apply)
  - Observable: pytest run で 4 sample (valid 2 + invalid 1 + $ref chain 1) 全期待通り pass/fail
  - _Requirements: 3.7, 3.8_
  - _Depends: 3_
  - _Boundary: tests/integration/schema_complex/_

## Change Log

- **v1.0** (2026-05-01 14th セッション、本 file 初版): A-1 tasks phase = `/kiro-spec-tasks dual-reviewer-foundation` Skill 経由生成、7 major task / 18 sub-task、Foundation→Core→Integration→Validation phase 順序、`(P)` parallel marker 11 sub-task、`_Depends_` 注記 5 件。Task plan review gate pass + Step 3.5 sanity review subagent verdict = `PASS`。
- **v1.1** (2026-05-01 14th セッション、V4 ad-hoc protocol Step 1a/1b/1b-v/1c/2/3 review gate 完走後): V4 review 18 件 (P1-P10 primary + A1-A8 adversarial) 検出、judgment subagent 必要性評価で must_fix 1 / should_fix 5 / do_not_fix 12、user 三ラベル提示で全 6 件 apply (must_fix bulk apply + should_fix bulk apply + do_not_fix bulk skip)。
  - **A4 apply** (must_fix): Task 7.5 に `jsonschema` cross-file `$ref` 解決のための `RefResolver` / `Registry` `base_uri` 設定責務を明示 + Task 6.3 を単一 schema 完結 validate に責務限定明示 (judgment override = adversarial self-classify do_not_fix → must_fix、function-blocking + 1 行追記で済む)
  - **P1 apply** (should_fix): Task 2.3 Observable bullet "byte-level diff 0 byte (空白 / 改行 normalize 後)" → "空白 / 改行 normalize 後の byte-level diff 0 byte" に文言訂正 (Req 6.2 整合)
  - **P2 apply** (should_fix): Task 7.4 Observable bullet "3 要素 presence" → "layer_2 / layer_3 各々 3 要素 = 合計 6 field presence" に明確化 (Req 1.5/1.6 整合)
  - **P3 apply** (should_fix): Task 5.1 frontmatter 規約 detail bullet 追加 (kiro-* skill sample 参照 + `name`/`description` field presence assert、design.md 設計決定 4 整合)
  - **P6 apply** (should_fix): Task 5.2 rollback failure detail bullet "1 line per absolute path 形式 stderr enumerate" 明示 (design.md `residual_files: string[]` 整合)
  - **A6 apply** (should_fix): Task 6.1 Observable bullet "extracted_patterns.yaml content 検証 (`version` field + `patterns: []` 空 list)" 追加 (boundary 違反 + verification gap 解消)
  - V4 metric: 採択率 5.6% (1/18) / 過剰修正比率 66.7% (12/18) / should_fix 比率 27.8% (5/18) / judgment override 7 件 / primary↔judgment disagreement 3 件 (P3, P4, P5) / adversarial↔judgment disagreement 1 件 (A4) / V4 修正否定 prompt 機能 75% (adversarial 自己分類 do_not_fix 6/8)
  - do_not_fix 12 件 bulk skip (V4 §2.5 規範通り、内訳 = P4 [A4 で集約] / P5 [over-specification] / P7 [overdeclaration cosmetic] / P8 [環境前提] / P9 [環境前提] / P10 [実装者裁量] / A1 [(P) cosmetic] / A2 [over-specification] / A3 [Allowed Dependencies 明示済] / A5 [yaml 内 path 文字列リテラル] / A7 [annotation noise] / A8 [design.md L532 確定済])
  - **tasks-phase ad-hoc V4 caveat 4 件** (`data-acquisition-plan.md` v0.3 §5 整合、paper limitations 明示用): (1) ad-hoc 観点 = Layer 2 tasks extension 未実装で primary が boundary 違反 / dependency cycle / granularity / AC 網羅 / executability / verifiability の 6 観点 ad-hoc 列挙 / (2) phase 横断 strict comparability 問題 = design phase 10 ラウンド観点 vs tasks phase ad-hoc 観点で coverage 異なり phase 間 absolute 比較は spurious / (3) forced_divergence prompt design phase optimization = adversarial subagent dispatch で tasks phase 用 ad-hoc 微調整 (= primary's task structure 暗黙前提置換) / (4) paper rigor 保証 = tasks phase ad-hoc V4 evidence は preliminary cross-phase verification 補助 evidence、systematic tasks phase evidence は Phase B-1.1 (dr-tasks skill 実装後) で paper revision に活用
- **v1.2** (2026-05-01 14th セッション、3 spec tasks-phase 累計 cross-spec review C-1 fix): foundation tasks v1.1 + design-review tasks v1.1 + dogfeeding tasks v1.1 を 20 観点 integrity check (Group A 17 + Group B 2 + Group C 1) 実施、不整合 0 件、Group C-1 軽微 implication 1 件を本 v1.2 で apply。
  - **C-1 apply**: Task 1 description で `jsonschema` install version pin を `jsonschema>=4.18` (Draft 2020-12 + `Registry` API 対応) に明示 (= design-review tasks v1.1 P6 apply の cross-spec implication、Task 7.5 cross-file `$ref` resolver 設定で `Registry` 必須のため version pin 必要、3 spec 累計整合)
  - **3 spec tasks-phase 累計 V4 metric trend** (foundation → design-review → dogfeeding): 採択率 5.6% → 13.3% → 35.7% (+30.1pt 累計改善) / 過剰修正比率 66.7% → 53.3% → 42.9% (-23.8pt 累計改善) / should_fix 27.8% → 33.3% → 21.4% = V4 protocol 構造的有効性 3 spec 連続再現実証 (= design phase trend 81.25% → 58.8% → 40.0% と方向一致 = 6 spec instance 累計再現)
  - **Group C-2 implication** (tasks.md scope 外、別 commit 推奨): `data-acquisition-plan.md` §3.1 + §3.2 の "未収集 tasks phase ad-hoc V4 適用" checkbox 3 件 [x] 化 + 3 spec V4 metric 累計追記は **methodology document update** として本 spec scope 外
