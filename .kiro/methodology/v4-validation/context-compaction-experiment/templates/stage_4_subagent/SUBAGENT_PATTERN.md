# SUBAGENT_PATTERN.md (= stage 4 = 周辺 work subagent dispatch 化)

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

## dispatch 例

```
Agent({
  description: "TODO update for Round N completion",
  prompt: "Round N 完走後の TODO_NEXT_SESSION.md update を以下要領で実施: (1) ... (2) ... 出力 = updated TODO content"
})
```

主 context では subagent return value (= updated TODO content) を Write tool で反映するのみ、context 量は subagent context 内で消費される。

## paper rigor 整合性

subagent dispatch 自体は methodology 変更ではなく context management の最適化、paper baseline 不変 = OK。
