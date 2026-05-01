# dual-reviewer-dogfeeding (Operational Protocol + Research Script Hybrid)

## 概要 (Overview)

dual-reviewer prototype を Spec 6 (`rwiki-v2-perspective-generation`) design phase に dogfeeding 適用するための Operational Protocol + 3 Research Script (Python)。Phase A scope = `scripts/dual_reviewer_prototype/` 配下を consumer-only 利用、新規 skill / framework / schema 実装一切なし (Decision 1)。

## §1 Scope (本 spec scope)

- Spec 6 design.md に対する 3 系統 (single / dual / dual+judgment) × 10 Round = 30 review session 適用 (Operational Protocol)
- 3 Python script で metric / figure / Phase B fork 判定の自動化 (Research Script)
- Phase A 終端 trigger 成立確認 (Spec 6 design approve = Rwiki v2 全 8 spec design approve = Phase A 終端)

### Out of Scope

- B-1.x 拡張 schema (multi-vendor LLM 対応 / case study qualitative figure 4-5、Req 7.5)
- 論文 draft 執筆 (Phase 3 = 7-8 月別 effort、Req 7.6)
- case study 記述 (figure 4-5 qualitative narrative、Req 7.6)
- Phase B-1.0 release prep 自体 (固有名詞除去 / npm package 化、Req 7.7)

### Phase A scope constraints

- foundation install location = `scripts/dual_reviewer_prototype/` 配下のみ対象 (固定)
- 3 script は consumer-only (foundation + design-review artifact 改変禁止)
- Spec 6 design approve = Phase A 終端 trigger (Phase B-1.0 release prep 移行は本 spec scope 外、別 effort)

## §2 Treatment Flag Contract (Decision 3 + 6 整合)

design-review v1.2 cycle で確定済の `dr-design --treatment` flag behavior (= 3 系統対照実験):

| treatment | Step A (primary) | Step B (adversarial) | Step C (judgment) | Step D (integration) | user 提示 |
|-----------|-----------------|---------------------|-------------------|----------------------|----------|
| single | exec | skip | skip | exec | primary 検出のみ |
| dual | exec | exec | skip | exec | primary + adversarial 検出 |
| dual+judgment | exec | exec | exec | exec | primary + adversarial + judgment (V4 完全) |

Round 開始時に dr-log `open(session_id, treatment, round_index, design_md_commit_hash, target_spec_id, config_yaml_path)` invoke + Round 終端 `flush(session_id)` invoke で **1 line/session JSONL append-only** を担保 (A1 fix integration、design-review L463-492 整合)。

## §3 Consumer 拡張 4 field (foundation Req 3.6 整合)

review_case JSONL log の 4 field 必須付与:

| field | type | constraint | source skill |
|-------|------|------------|--------------|
| `treatment` | string enum | single / dual / dual+judgment | dr-log open() payload |
| `round_index` | int | 1-10 | dr-log open() payload |
| `design_md_commit_hash` | string | non-empty | dr-design `git rev-parse HEAD -- <design.md>` 取得 |
| `adversarial_counter_evidence` | string | dual / dual+judgment 系統で必須、single 系統で省略可、finding object 単位 | dr-design counter_evidence decompose helper |

foundation `review_case.schema.json` + `finding.schema.json` は `additionalProperties: true` (default) のため上記 4 field を validate pass。consumer 側で `assertIn` による key existence assertion 必須 (Task 6.2 integration test で mechanically verify、A6 apply)。

## §4 3 Script 連携手順

3 script の起動順序 (前段 output → 後段 input):

```
[Spec 6 design.md]
    │
    ├──[dr-init bootstrap]──→ [.dual-reviewer/config.yaml + dev_log.jsonl]
    │
    ├──[dr-design × 30 sessions (3 treatment × 10 Round)]──→ [dev_log.jsonl 30 lines]
    │
    └──[3 Python script 順次実行]
        │
        ├──[1] python3 metric_extractor.py
        │      --input dev_log.jsonl
        │      --output dogfeeding_metrics.json
        │      --dual-reviewer-root scripts/dual_reviewer_prototype/
        │
        ├──[2] python3 figure_data_generator.py
        │      --metrics dogfeeding_metrics.json
        │      --output-dir .kiro/methodology/v4-validation/
        │      --design-review-spec .kiro/specs/dual-reviewer-design-review/spec.json
        │      --dual-reviewer-root scripts/dual_reviewer_prototype/
        │      → 4 file (figure_1/2/3/ablation_data.json)
        │
        └──[3] python3 phase_b_judgment.py
               --metrics dogfeeding_metrics.json
               --figure-dir .kiro/methodology/v4-validation/
               --report .kiro/methodology/v4-validation/comparison-report.md
               --jsonl dev_log.jsonl
               --dual-reviewer-root scripts/dual_reviewer_prototype/
               → comparison-report.md §12 append (idempotent) + judgment record stdout
```

### exit code mapping

| script | 0 | 1 | 2 | 3 | 4 |
|--------|---|---|---|---|---|
| metric_extractor | success | input read fail | JSON parse fail | (validate fail w/ flag) | output write fail |
| figure_data_generator | success | metrics read fail | output write fail | - | - |
| phase_b_judgment | success or idempotent skip | input read fail | report append fail | - | - |

## §5 Round 開始時 commit hash 取得手順 (P10 fix 整合、Operational Protocol 4 step)

各 Round 開始時に **同一 Round 内 3 系統で commit hash 共通化** を担保:

1. **Round 開始時 hash 取得**: `git rev-parse HEAD -- <target_design_md_path>` を Round 開始時 (= 3 系統各 Round の最初の treatment) で 1 回実行
2. **同一 Round 内 3 系統で同一 hash 使用**: 同 Round の single / dual / dual+judgment 全 session で同一 hash を `dr-log open()` payload に渡す
3. **Round 完了後 次 Round で再取得**: 次 Round 開始時に再度 `git rev-parse` 実行 (= Round 跨ぎで Spec 6 design.md が改版された場合の hash 反映)
4. **30 session 中 hash variance 検出**: `metric_extractor.py` が `commit_hash_variance` field で hash 集合を集計、複数あれば warning として `comparison-report.md` 併記用 input に記録 (Round 跨ぎ design 改版を fair comparison から除外する判断材料)

## §6 dogfeeding session 全体フロー

A-2 期間 (= 本 spec implementation 完走後) 全体フロー:

1. **Spec 6 (`rwiki-v2-perspective-generation`) design phase 着手** (Spec 6 spec 責務、本 spec 並走、本 spec は design 内容に介入しない)
2. **`dr-init` bootstrap** (Spec 6 working directory に `.dual-reviewer/` 配置)
3. **30 review session 完走** (3 treatment × 10 Round、各 Round 開始時 commit hash 取得手順 = §5 4 step)
4. **`metric_extractor.py` 実行** → `dogfeeding_metrics.json` (Req 4.1-4.7、12 軸 metric)
5. **`figure_data_generator.py` 実行** → 4 figure data file (Req 5.1-5.6、figure 2 sequencing 制約 = design-review approve 後)
6. **`phase_b_judgment.py` 実行** → comparison-report.md §12 append (5 条件評価 + go/hold + V4 仮説検証 + evidence_references、Req 6.1-6.5)
7. **Spec 6 design approve 確認** = Rwiki v2 全 8 spec design approve 完了 = **Phase A 終端 = Phase B-1.0 release prep 移行 trigger 成立** (Req 7.4)

## 構成 (Structure)

```
scripts/dual_reviewer_dogfeeding/
├── README.md                  (本 file、Operational Protocol 中心)
├── helpers.py                 (3 script 共通 helper module、DRY)
├── metric_extractor.py        (JSONL log → 12 軸 metric 算出)
├── figure_data_generator.py   (metric → 4 figure data file 生成)
├── phase_b_judgment.py        (metric + figure → 5 条件評価 + go/hold)
└── tests/                     (3 script unit + integration tests)
    ├── test_metric_extractor.py
    ├── test_figure_data_generator.py
    ├── test_phase_b_judgment.py
    ├── test_integration_flow.py        (Task 6.1 = 3 script sequential)
    └── test_consumer_extension_fields.py (Task 6.2 = 4 field 全件 presence)
```

## 関連 reference (References)

- `scripts/dual_reviewer_prototype/` (foundation + design-review portable artifact)
- `.kiro/specs/dual-reviewer-dogfeeding/` (本 spec requirements + design + tasks)
- `.kiro/methodology/v4-validation/comparison-report.md` (phase_b_judgment.py append target)
