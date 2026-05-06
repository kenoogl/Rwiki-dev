---
name: 周辺 work は subagent dispatch で実施 (= 主 context 保持、46th 末確定)
description: 主 context を work-specific に保つため、TODO 更新 / memory 整理 / status report 等の周辺 work は subagent dispatch で isolated context 内で実施。46th 末 context compaction experiment で stage_4 採用根拠
type: feedback
originSessionId: 55ccc662-db53-44da-8131-b951110f1239
---
## 規律

主 context (= Round review 着手 + design.md 修正判断) を work-specific に保つため、周辺 work は subagent dispatch で isolated context 内で実施する。

## subagent dispatch 対象 (= 周辺 work)

- TODO_NEXT_SESSION.md update (= session 末の進捗反映 + 次 session 着手指示生成)
- memory 整理 (= MEMORY.md index update / archive 移行 / 重複 memory 統合)
- status report 集計 (= dev_log + rework_log 読込 → 累計 metric 計算 → markdown report 生成)
- log file 集計 (= wc -l + jq query 結果まとめ)
- methodology 4 文書 SSoT update (= preliminary-paper-report 各 round 完走時の §4.7 反映)

## subagent dispatch しない (= 主 context 内で実施)

- Round review の primary / adversarial dispatch 結果統合 (= V4 protocol 中核)
- design.md 修正判断 (= user 判断要請 + 採用案決定)
- spec.json approve / commit / push (= user 明示承認領域)
- 規律違反対応 (= user 指摘 → 書き直し)

## why

46th セッション context compaction experiment 5 trial で stage_4 (= 主 context 縮約 + subagent dispatch pattern 意識化) が baseline (= stage_0) から規律違反 raw 件数 100% 削減 (= 8 → 0) で最 effective と判定。driver = context 量だけでなく構造 (= active 必読 vs 参照層分離 + subagent pattern 意識化)、4 機構分析の機構 3 (= 規律意識の分散) が最大と推定。

## paper rigor 整合性

subagent dispatch 自体は methodology 変更ではなく context management の最適化、paper baseline 不変 = OK。

## 関連

- experiment 計画 = `.kiro/methodology/v4-validation/context-compaction-experiment/plan.md`
- experiment 結果 = `~/Development/context-compaction-trial/results.md`
