# Requirements Document

## Introduction

この文書は `heat3d-linear-solver` の requirements である。
ここでは、疎行列連立一次方程式を解くための numerical kernel だけを決める。

具体的には、次をここで固定する。

- RHS の作り方
- 各方向の係数の意味
- `A*x` の扱い
- GS 前処理
- PBiCGSTAB
- 収束判定

geometry の具体配置や最上位のログ出力は、この feature の責務に含めない。

## Boundary Context

- この feature で決めること:
  - backward Euler 1 ステップの線形系
  - RHS 構築
  - X/Y/Z 面係数
  - 境界由来の係数と RHS 寄与
  - `A*x`
  - GS 前処理
  - PBiCGSTAB
  - 残差と収束判定
- この feature で決めないこと:
  - 共通型や格子の定義
  - 材料表や geometry primitive
  - MVP 固定ケースの組み立て
  - 最上位のログと baseline 固定
- 上流 feature:
  - `heat3d-foundation`
- 下流 feature:
  - `heat3d-main`

## Requirements

### Requirement 1: 1 ステップの線形系

**目的:** backward Euler 1 ステップで何を解くのかを 1 か所で固定する。

#### Acceptance Criteria

1. 各更新セルの RHS は `rhs = - ( T_old / Δt + (qvol + q_boundary) / (ρ Cp) )` で作ること。
2. X と Y の面係数は、調和平均した面拡散率をそれぞれ `dx^2`、`dy^2` で割って求めること。
3. Z の面係数は、`alpha_face / (ΔZ[k] * distance_to_neighbor)` で求めること。
4. 熱流束境界の寄与は `q_boundary` として RHS に入れること。
5. 熱伝達境界に接するセルでは、対角項へ熱伝達寄与を加え、周囲温度の寄与を RHS に入れること。

### Requirement 2: `A*x` と更新対象セル

**目的:** solver がどのセルを未知数として扱うかを明確にする。

#### Acceptance Criteria

1. backward Euler 系に対応する `A*x` を計算できること。
2. `A*x` は、共通の `mask` と active `z_range` で選ばれたセルだけを更新対象として扱うこと。
3. `mask = 0.0` のセルは、固定セルまたは未知数集合の外として扱うこと。
4. `A*x` の計算は、少なくとも `theta`、`rhs`、`alpha`、`rho`、`cp`、`dx`、`dy`、`Z`、`ΔZ` を入力として使うこと。
5. 内部セルの拡散係数と、境界由来の係数を同じ規約でまとめて扱うこと。

### Requirement 3: GS 前処理

**目的:** MVP 必須の前処理を main から切り離して固定する。

#### Acceptance Criteria

1. MVP では GS smoother を前処理として実装すること。
2. GS 前処理は、本体の `A*x` と同じ係数解釈を使うこと。
3. GS 前処理も `mask` と active `z_range` を守ること。
4. 固定セルを勝手に未知数へ戻さないこと。

### Requirement 4: PBiCGSTAB と収束判定

**目的:** solver の入出力と収束判定を固定し、後段で意味が変わらないようにする。

#### Acceptance Criteria

1. MVP では PBiCGSTAB を必須 solver とすること。
2. solver の入力は、少なくとも `theta`、`rhs`、`qvol`、`alpha`、`rho`、`cp`、`mask`、`dx`、`dy`、`Δt`、`Z`、`ΔZ`、`z_range`、境界由来係数、`tolerance`、`max_iterations` を含むこと。
3. solver の出力は、少なくとも更新後 `theta`、`iterations`、`final_residual`、`converged` を含むこと。
4. canonical MVP の既定値として、`max_iterations = 8000`、`tolerance = 1.0e-4` を使うこと。
5. 相対残差は `residual_rms / initial_residual_rms` と定義すること。
6. `relative_residual < tolerance` のときだけ収束とみなすこと。
7. 最大反復数に達しても収束しなければ `converged = false` を返すこと。

### Requirement 5: solver 単体で見る最低限の確認項目

**目的:** integration 前に、solver 自体が壊れていないかを判定できるようにする。

#### Acceptance Criteria

1. 一様材料、一様初期温度 `300 K`、発熱 `0`、全境界等温 `300 K` の 1 ステップ計算では、すべての更新セルが `300 K ± 1e-10` に収まること。
2. 1 セルだけ発熱させた加熱応答試験では、そのセルの温度が初期値より上がること。
3. 上の加熱応答試験で、`NaN` や負温度を出さないこと。
