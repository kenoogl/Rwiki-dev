---
name: review log template (Round 提示 + 完了報告)
description: review 中の user 向け message を統一 template で出力。Round 提示と完了報告の 2 種類
type: feedback
originSessionId: 5550c82b-3239-48a1-aad5-ca9566a9ec80
---
## Round 提示 template

```
# Round N (観点名) 検出 件数

## 概要
1-2 文 = 何の review か + user に求める判断 + 判断しないと何が止まるか

## 検出 1 = P-1 + 短い見出し
### 概要 / 問題点 / 選択肢 (案 a/b) / 推奨

(検出 2, 3, ... 同 structure)

## 推奨まとめ
- 検出 1: 案 (a)
- 検出 2: 案 (b)
```

## Round 完了報告 template

```
# Round N 完走

検出 (一次 N + 反対側 M) = K 件採用 + L 件 skip

修正内容:
- 検出 1 (案 X): 1 文で何を変えたか

commit:
- hash1 = 設計書修正
- hash2 = 履歴

次: Round N+1 (観点名) 着手?
```

## 入れない要素

- forced_divergence の詳細 (log artifact のみ)
- 反対側 reviewer の各 option ラベル詳細 (log のみ)
- seed_pattern hits / Phase 1 metapattern コード (jargon)
- 修正規模の細かい数字 (= +X -Y +Z net 等)
- branch 詳細名 (= 「今回の作業ブランチ」で十分)
- enforcement / methodology meta (`feedback_response_quality_rules.md` 規律 3)

## 補強

- `feedback_explanation_with_context.md` (= 7 軸 self-check + paraphrase + 文脈 + 3 要素) は本 template の content quality を担当
- 本 memory は structure / 入れる要素 / 入れない要素を担当
