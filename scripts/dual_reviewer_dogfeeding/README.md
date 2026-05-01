# dual-reviewer-dogfeeding (Operational Protocol + Research Script Hybrid)

## 概要 (Overview)

dual-reviewer prototype を Spec 6 (`rwiki-v2-perspective-generation`) design phase に dogfeeding 適用するための Operational Protocol + 3 Research Script (Python)。Phase A scope = `scripts/dual_reviewer_prototype/` 配下を consumer-only 利用、新規 skill / framework / schema 実装一切なし (Decision 1)。

## Scope (本 spec scope)

- Spec 6 design.md に対する 3 系統 (single / dual / dual+judgment) × 10 Round = 30 review session 適用 (Operational Protocol)
- 3 Python script で metric / figure / Phase B fork 判定の自動化 (Research Script)
- Phase A 終端 trigger 成立確認 (Spec 6 design approve = Rwiki v2 全 8 spec design approve = Phase A 終端)

## Out of Scope (本 spec で扱わない)

- B-1.x 拡張 schema (multi-vendor LLM 対応 / case study qualitative figure 4-5、Req 7.5)
- 論文 draft 執筆 (Phase 3 = 7-8 月別 effort、Req 7.6)
- case study 記述 (figure 4-5 qualitative narrative、Req 7.6)
- Phase B-1.0 release prep 自体 (固有名詞除去 / npm package 化、Req 7.7)

## Phase A scope constraints

- foundation install location = `scripts/dual_reviewer_prototype/` 配下のみ対象 (固定)
- 3 script は consumer-only (foundation + design-review artifact 改変禁止)
- Spec 6 design approve = Phase A 終端 trigger (Phase B-1.0 release prep 移行は本 spec scope 外、別 effort)

## 構成 (Structure)

```
scripts/dual_reviewer_dogfeeding/
├── README.md                  (本 file、Operational Protocol 中心)
├── helpers.py                 (3 script 共通 helper module、DRY)
├── metric_extractor.py        (JSONL log → 12 軸 metric 算出)
├── figure_data_generator.py   (metric → 4 figure data file 生成)
├── phase_b_judgment.py        (metric + figure → 5 条件評価 + go/hold)
└── tests/                     (3 script unit + integration tests)
```

## 詳細 protocol + 起動順序

詳細 (Treatment Flag Contract / Consumer 拡張 4 field / 3 script 連携 / Round 開始時 commit hash / dogfeeding session 全体フロー) は **Task 5 完了時に full 記述**。本 file は scope skeleton (Task 1 配置済) のみ。

## 関連 reference (References)

- `scripts/dual_reviewer_prototype/` (foundation + design-review portable artifact)
- `.kiro/specs/dual-reviewer-dogfeeding/` (本 spec requirements + design + tasks)
- `.kiro/methodology/v4-validation/comparison-report.md` (phase_b_judgment.py append target)
