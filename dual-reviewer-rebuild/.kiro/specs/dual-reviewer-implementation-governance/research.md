# Research

## 観測起点

prototype 一巡後の shelf review で、smoke pass 後にも次の nonconformance が見つかった。

- approval / adoption gate の混線
- fixture-name-bound な replay resolution
- heuristic な caveat linkage

これは tasks 完了と smoke validator pass だけでは、

- 仕様準拠性
- 境界条件
- 証跡性

を十分に担保できないことを示している。

## 導出

必要なのは追加の feature logic ではなく、
implementation 後に横断確認する governance layer である。

この governance layer は少なくとも次を formalize する必要がある。

- post-implementation review の必須化
- review artifact の正本化
- finding と signal / coordination の接続
- review 自体を測る metric 定義

## Boundary

この spec は runtime/evaluation/self-improvement/paper-interface の設計を置き換えない。
それらの implementation をどう閉じるかという workflow contract を追加する。
