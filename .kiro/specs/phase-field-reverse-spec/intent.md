# Intent Document

## Intent

三相フェーズフィールドコードを C++ で実装し、
描画 API ヘッダ `wingxa.h` を用いて相分離の状況を可視化できるようにする。

この case は、仕様駆動開発で scientific simulation code を構築する
代表例として使う。

## Users

- 材料物性研究者
  - 相分離組織の発展を観察したい
  - 保存済み結果を再描画・出力して解析したい
- シミュレータ構築者
  - scientific simulation code を仕様駆動で構築したい

## Goals

1. 三相フェーズフィールド計算を実行できること
2. 計算結果を可視化できること
3. 保存済み結果を再利用できること
4. 仕様駆動開発の case として downstream artifact に接続できること

## Non-Goals

1. original 実装との binary-level 一致
2. GPU / 並列化 / 高速化最適化
3. 汎用 solver framework 化

## Constraints

1. canonical source は `DR-pfm/spec_seed/DEVELOPMENT_SPEC.md` と `wingxa.h`
2. clean-room 再実装であること
