---
name: 説明文体規律 = 全 user 応答で説明文体 + 1 検出 1 turn (44th 末確定 + 45th 末 5 度連続失敗)
description: 全 user 応答で説明文体 default、1 文 1 fact + 説明動詞 + 接続詞 + 具体例先行 + 等号畳み込み禁止、Round 提示は 1 検出 1 turn 分割
type: feedback
---

## 規律

全 user 応答で説明文体を default 使用する。Round 提示時は 1 検出 = 1 turn に分割し、複数検出を 1 message に flat 並列で詰めない。

## 説明文体の原則 (= dense academic 文体との対比)

- 1 文に 1 つの事実だけ書く
- 「~です」「~あります」「~します」のような説明動詞を使う
- 「だから」「つまり」「例えば」「なぜなら」「ただし」のような接続詞で論を積み上げる
- 具体例から入り抽象に進む
- 暗黙前提を文ごとに展開する
- 等号 (=) で fact を畳み込む書き方を避ける (= 「A は B = C により D」のような畳み込み禁止)

## structural 補助 (= 1 検出 1 turn 分割)

review log Round 提示で N 件 batch を flat 並列で 1 message に詰めない。1 検出 = 1 turn = output unit を小さくして dense 文体への引力を弱める。Round 完走報告は 1 turn で OK (= 量小)。

## why

44th 末 user 確定。「常に説明文体」は保証できない (= training data default は dense academic 文体、説明文体は意識的切替必要)。user 指摘 → 私書き直し前提で運用、structural 補助で引力弱化。

## 違反 example (= 最新、45th Round 8、5 度連続失敗)

Round 8 概要提示で 8 件 batch flat 並列 + 等号連結 (「dangling pointer。... R14 欠番、R13.7 は実在しません」) = user「正しく日本語で表現されていません」明示指摘 → 5 度連続失敗で機構分析依頼。
