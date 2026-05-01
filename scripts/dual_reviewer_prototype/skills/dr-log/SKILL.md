---
name: dr-log
description: review session-scoped JSONL log writing skill。foundation `./schemas/` 動的読込 + target project `.dual-reviewer/config.yaml` の `dev_log_path` 動的読込 + open/append/flush 3 method (A1 fix session lifecycle) で **flush invocation 1 回で exactly 1 JSONL line per session_id** を guarantee。3 系統 (single / dual / dual+judgment) 対応 + 2 層 source field 明示分離 (finding.source = primary | adversarial 検出元 vs necessity_judgment.source = primary_self_estimate | judgment_subagent 判定元) + state=detected で necessity_judgment optional / state=judged で必須 (foundation finding.schema.json allOf if/then 整合)。
---

# dr-log Skill (review session JSONL log writer)

## 概要 (Overview)

`dr-log` skill は dr-design からの per-finding invoke を accumulate し、Round 終端で 1 review_case object を JSONL append-only に書出する。session-scoped accumulator mechanism (A1 fix) により per-finding invoke の頻度と per-review_case 1 line/session の粒度不整合を解消。Req 1.1-1.9 + 2.1-2.7 + 5.1 + 5.6 + 5.7 + 7.1 + 7.3 に対応。

## 起動規約 (Invocation)

dr-log は subordinate skill として dr-design から per-finding invoke される。3 method (open / append / flush) を提供:

```python
from log_writer import LogWriter

w = LogWriter(schemas_dir=Path("./schemas"))
w.open(session_id, treatment, round_index, design_md_commit_hash, target_spec_id, config_yaml_path)
w.append(session_id, finding)  # per-finding invoke
w.flush(session_id)             # Round 終端で 1 JSONL line
```

CLI 起動 (smoke test):

```
python3 scripts/dual_reviewer_prototype/skills/dr-log/log_writer.py \
  --schemas-dir <foundation_schemas_absolute_path>
```

## 動作 (Behavior)

### Session lifecycle (A1 fix)

1. **`open(session_id, treatment, round_index, design_md_commit_hash, target_spec_id, config_yaml_path)`**: review session 開始 + `timestamp_start` (ISO8601 + UTC) 自動付与 + in-memory state 初期化 + `config_yaml_path` 読込で `dev_log_path` resolve
2. **`append(session_id, finding)`**: per finding を in-memory accumulator に追加 + 即時 schema validate fail-fast (foundation finding.schema.json + allOf if/then = state=detected で necessity_judgment optional / state=judged で必須)
3. **`flush(session_id)`**: 1 review_case object 組立 + JSONL append-only に 1 line + `timestamp_end` (ISO8601 + UTC) 自動付与 + accumulator 削除 (= **flush invocation 1 回で exactly 1 JSONL line per session_id**、A1 grain-correction guarantee)

### 3 系統対応 (Req 2.7)

| treatment | finding.state | necessity_judgment.source | adversarial_counter_evidence |
|-----------|---------------|---------------------------|------------------------------|
| single | detected | primary_self_estimate (judgment 未起動) | omit |
| dual | detected | primary_self_estimate | required (string) |
| dual+judgment | judged | judgment_subagent | required (string) |

### 2 層 source field 明示分離 (A4 apply)

- `finding.source` (foundation `finding.schema.json` 内 enum = `primary | adversarial`) = **検出元** (誰が finding を検出したか)、3 系統共通 (treatment 区別なし)
- `necessity_judgment.source` (foundation `necessity_judgment.schema.json` 内 enum = `primary_self_estimate | judgment_subagent`) = **判定元** (誰が修正必要性を判定したか)、3 系統別

### LLM 自己ラベリング prompt 組込 (Req 2.5)

primary 自己ラベリング (`miss_type` / `trigger_state`) + adversarial 自己ラベリング (`difference_type`) を全 finding 生成時に必須付与 (dr-design 経由で finding object に含めて渡される、本 skill は schema validate 担当)。

### Schema validate fail-fast (Req 2.6)

invalid finding append 時:
- stderr に finding ID + 違反 field + 期待 enum 値 + 実値 enumerate
- `jsonschema.ValidationError` raise + non-zero exit (Service 利用時は exception 透過、CLI 利用時は exit 1)

### cross-file $ref 解決

`referencing.Registry` + `Resource.from_contents()` + `DRAFT202012` で foundation `./schemas/` directory 配下 5 schema (review_case + finding + impact_score + failure_observation + necessity_judgment) を URI = `<name>.schema.json` で registry 登録 (foundation Task 7.5 cross-file resolver pattern 整合)。

### Layer 3 terminology attach 整合 (Req 5.7)

foundation `terminology.yaml` placeholder = Layer 3 project 固有 terminology entries は foundation Layer 1 contract に従い attach、override 階層 (Layer 3 > Layer 2 > Layer 1) で Layer 3 entry が本 spec terminology を override 可能。

## 出力 (Output)

### Success path

JSONL append-only に 1 line per session_id (review_case object):

```json
{"session_id": "s-1", "phase": "design", "target_spec_id": "foundation", "timestamp_start": "...", "timestamp_end": "...", "treatment": "dual+judgment", "round_index": 1, "design_md_commit_hash": "...", "findings": [...]}
```

### Failure path

| exit code | failure | stderr |
|-----------|---------|--------|
| 1 | schema validate fail or schema read fail | `finding <id> field <X> expected <Y> got <Z>` |
| 2 | config read fail | `config.yaml not found or unparseable: <path>` |
| 3 | JSONL write fail | `dev_log.jsonl write fail: <error>` |

## 関連 reference (References)

- foundation `schemas/review_case.schema.json` (出力 line 構造定義)
- foundation `schemas/finding.schema.json` (per finding validate target、allOf if/then)
- design.md §dr-log Skill (Service Interface 定義 + A1 fix session lifecycle)
