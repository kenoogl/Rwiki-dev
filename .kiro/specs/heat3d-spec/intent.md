# Intent Document

## Intent

3 次元熱伝導シミュレータを実装し、
材料配置、内部発熱、境界条件を与えて温度分布の時間発展を計算できるようにする。

この case は、仕様駆動開発で thermal simulation code を構築する
代表例として使う。

## Users

- 熱設計・熱解析を行う研究者 / 開発者
  - 3 次元熱伝導の温度分布を計算したい
  - 材料配置や境界条件を変えて挙動を比較したい
- シミュレータ構築者
  - thermal simulation code を仕様駆動で構築したい

## Goals

1. 3 次元非定常熱伝導計算を実行できること
2. 材料配置、内部発熱、境界条件を扱えること
3. 仕様駆動開発の case として downstream artifact に接続できること

## Non-Goals

1. GUI
2. 可視化
3. CSV 出力
4. 複数ケース一括実行
5. 並列化
6. GPU

## Constraints

1. canonical source は [thermal_simulator_spec.md](/Users/Daily/Development/DR-heat3d/spec_seed/thermal_simulator_spec.md:1)
2. 仕様書案を起点に self-contained に構築できること
