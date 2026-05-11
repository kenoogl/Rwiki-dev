# Requirements Document

## Introduction

この文書は `heat3d-case-model` の requirements である。
ここでは、canonical source に書かれた固定 MVP ケースをどう組み立てるかを決める。

具体的には、次をここで固定する。

- canonical `SimulationConfig`
- geometry の配置
- 材料割当の流れ
- 発熱分布
- 境界条件セット
- active `z_range`
- 下流へ渡す assembled case bundle

solver の中身や最上位のログ出力は、この feature の責務に含めない。

## Boundary Context

- この feature で決めること:
  - canonical MVP の実行設定
  - geometry 配置
  - 材料割当の組み立て
  - 発熱分布
  - 境界条件セット
  - active `z_range`
  - 下流へ渡す assembled case bundle
- この feature で決めないこと:
  - primitive 自体の定義
  - solver の反復法
  - 最上位のログと baseline 固定
- 上流 feature:
  - `heat3d-foundation`
- 下流 feature:
  - `heat3d-main`

## Requirements

### Requirement 1: canonical MVP の実行設定

**目的:** 固定 MVP の数値設定を 1 か所で持ち、main や solver に散らさないようにする。

#### Acceptance Criteria

1. canonical MVP の `SimulationConfig` をコード内で組み立てること。外部設定ファイルは使わないこと。
2. canonical MVP の格子数は `NX = 240`、`NY = 240`、`NZ = 31` とすること。
3. canonical MVP の時間刻みは `Δt = 1000.0 s`、実行ステップ数は `1` とすること。
4. canonical MVP の solver 既定値は `tolerance = 1.0e-4`、`max_iterations = 8000` とすること。
5. canonical MVP の初期温度は `300.0 K` とすること。
6. canonical MVP の solver 名は `PBiCGSTAB` とすること。

### Requirement 2: geometry と材料割当

**目的:** fixed case の geometry を canonical source どおりに再現できるようにする。

#### Acceptance Criteria

1. 次の plate layer をそのまま組み立てること。
   `substrate (0.0, 0.0, 0.000e-3, 1.2e-3, 1.2e-3, 0.05e-3, id=4)`、
   `silicon_1 (0.1e-3, 0.1e-3, 0.100e-3, 1.0e-3, 1.0e-3, 0.10e-3, id=2)`、
   `silicon_2 (0.1e-3, 0.1e-3, 0.250e-3, 1.0e-3, 1.0e-3, 0.10e-3, id=2)`、
   `silicon_3 (0.1e-3, 0.1e-3, 0.400e-3, 1.0e-3, 1.0e-3, 0.10e-3, id=2)`、
   `heatsink (0.0, 0.0, 0.550e-3, 1.2e-3, 1.2e-3, 0.05e-3, id=5)`。
2. power grid は、サイズ `0.2e-3 × 0.2e-3 × 0.005e-3`、材料 `id = 7` とし、`x ∈ {0.3e-3, 0.7e-3}`、`y ∈ {0.3e-3, 0.7e-3}`、`z ∈ {0.195e-3, 0.345e-3, 0.495e-3}` に置くこと。
3. TSV は、半径 `0.02e-3`、高さ `0.10e-3`、材料 `id = 1` とし、`x ∈ {0.3e-3, 0.5e-3, 0.7e-3, 0.9e-3}`、`y ∈ {0.3e-3, 0.5e-3, 0.7e-3, 0.9e-3}`、`z_base ∈ {0.100e-3, 0.250e-3, 0.400e-3}` に置くこと。
4. solder bump は、球半径 `0.03e-3`、材料 `id = 3` とし、`x ∈ {0.3e-3, 0.5e-3, 0.7e-3, 0.9e-3}`、`y ∈ {0.3e-3, 0.5e-3, 0.7e-3, 0.9e-3}`、`z ∈ {0.075e-3, 0.225e-3, 0.375e-3, 0.525e-3}` に置くこと。
5. 材料割当順序は `power grid -> TSV -> plate layers -> solder bumps -> resin` とすること。
6. 組み立て後、すべての物理セルで `id != 0` を満たすこと。

### Requirement 3: 発熱と境界条件セット

**目的:** solver が fixed case の外形を推測しなくてよいように、発熱と境界条件を case-model 側でまとめる。

#### Acceptance Criteria

1. `Q_src = 1.6e11 W/m^3` を使うこと。
2. `id == 7` のセルだけに `qvol = Q_src` を入れること。
3. それ以外のセルには `qvol = 0` を入れること。
4. 境界条件セットは、`x_minus = CONVECTION(h=5.0, T_amb=300.0)`、`x_plus = CONVECTION(h=5.0, T_amb=300.0)`、`y_minus = CONVECTION(h=5.0, T_amb=300.0)`、`y_plus = CONVECTION(h=5.0, T_amb=300.0)`、`z_minus = ISOTHERMAL(T=300.0)`、`z_plus = HEAT_FLUX(q=100000.0)` とすること。
5. active `z_range` は独自ルールで決めず、`heat3d-foundation` の共通規約から導くこと。

### Requirement 4: assembled case bundle

**目的:** `heat3d-main` が geometry や境界条件を作り直さずに solver を呼べるようにする。

#### Acceptance Criteria

1. assembled case bundle は、少なくとも `SimulationConfig`、格子、物性配列、材料 ID、`qvol`、境界条件セット、active `z_range` を含むこと。
2. MVP では `heat3d-foundation` の固定 Z 格子をそのまま使うこと。
3. `heat3d-main` は、この bundle を受け取れば geometry や境界条件を再構成せずに `heat3d-linear-solver` を呼べること。
