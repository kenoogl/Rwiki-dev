---
name: dual-reviewer 自己改善 = Phase A は monitor only
description: paper rigor (= fixed methodology で N 件適用 → 統計分析) 維持のため Phase A は monitor (= metrics 集計 + alert) のみ、改善は Phase B-1.x 移行後
type: feedback
---

## user 判断 (= 41st 末)

「paper rigor の点からモニタだけで改善はしない」

## monitor (= Phase A 内 OK)

- metrics 集計 script (= dev_log + rework_log 読込んで各 round 検出 / 採用 / skip / 過剰修正比率 / treatment 別累計 / Phase 1 metapattern hits / fatal_pattern hits 計算)
- alert trigger (= 3 round 連続過剰修正比率 > 50% / 5 round 連続 adversarial 致命級発見 0 件 / Phase 1 同型 3 種全該当 5 度以上 / fatal_pattern hits ≥ 1)
- summary report 自動生成 (= round / treatment / phase 完走時印字)

## 改善 (= Phase B-1.x defer)

- Layer 3 `extracted_patterns.yaml` 自動拡張 (= 案 Y) → methodology 変動で paper baseline 崩れる
- meta-analysis subagent dispatch (= 案 Z) → 同上 + Phase A 内 token cost 増
- prompt 自動調整 / seed_patterns 自動昇格 → methodology 変動 = paper invalid risk

## paper rigor 整合性

Phase A baseline = 「fixed methodology で 30 review session 適用 → 統計分析」。monitor = 観察のみ methodology 不変 = baseline 維持。改善 = methodology 変動 = paper invalid。

ただし monitor で得た alert は Phase B-1.x design input として活用可 (= Phase A 終端後に集約 → Phase B-1.x の改善 priority 決定根拠)。

## Phase B-1.x 移行 trigger

以下完了後に検討:
1. A-2.1 完走 (= treatment=dual 残 round + 統合分析)
2. A-3 + §3.7.6 batch 完走 (= triangulation evidence 取得)
3. 論文 draft 着手 + 第 1 稿完成
4. Phase B fork 判断 (= 5 条件評価)
