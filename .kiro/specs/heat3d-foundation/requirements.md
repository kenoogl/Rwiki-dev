# Requirements Document

## Introduction

この文書は `heat3d-foundation` の requirements である。
ここでは、他の feature が共通に使う土台だけを決める。

具体的には、次をここで固定する。

- 配列サイズと添字の約束
- X/Y/Z 格子の約束
- 材料表
- 図形の基本判定ルール
- 境界条件データの形
- 結果とログの共通データ項目

`heat3d-linear-solver`、`heat3d-case-model`、`heat3d-main` は、
この文書で決めた約束を使う側であり、ここで決めた内容を別の形で再定義してはならない。

## Boundary Context

- この feature で決めること:
  - 共通の型
  - 配列サイズと添字規約
  - X/Y 格子
  - 固定 Z 格子と `ΔZ`
  - 材料表と物性値の対応
  - 直方体、円柱、球の基本判定ルール
  - 材料割当順序の約束
  - 境界条件データの形
  - 結果とログの共通項目
- この feature で決めないこと:
  - RHS の計算方法
  - GS / PBiCGSTAB の中身
  - MVP 固定ケースの具体的な組み立て
  - 最上位の実行手順
- 下流 feature:
  - `heat3d-linear-solver`
  - `heat3d-case-model`
  - `heat3d-main`

## Requirements

### Requirement 1: 共通の型

**目的:** 下流 feature が同じ名前と同じ責務でデータを受け渡せるようにする。

#### Acceptance Criteria

1. `heat3d-foundation` は、少なくとも `Material`、`BoundaryCondition`、`BoundaryConditionSet`、`SimulationConfig`、`SimulationResult`、`WorkBuffers` に相当する共通型を定義すること。
2. 材料を表す共通型は、少なくとも `alpha`、`rho`、`cp` を持つこと。
3. 境界条件を表す共通型は、`ISOTHERMAL`、`HEAT_FLUX`、`CONVECTION` のいずれか 1 つを表せること。
4. 計算結果を表す共通型は、少なくとも `theta`、`iterations`、`final_residual`、`converged`、`elapsed_seconds` を持つこと。

### Requirement 2: 配列サイズと添字規約

**目的:** solver と case-model が同じ配列の見方を共有できるようにする。

#### Acceptance Criteria

1. 物理セル数は `NX × NY × NZ` とすること。
2. 配列サイズは `MX × MY × MZ = (NX+2) × (NY+2) × (NZ+2)` とすること。
3. 各軸で、`1` を下側ガードセル、`2..N+1` を物理セル、`N+2` を上側ガードセルとすること。
4. 少なくとも `theta`、`rhs`、`mask`、`rho`、`cp`、`alpha`、`id`、`qvol` を `[MX,MY,MZ]` 形で共通に持つこと。
5. `mask = 1.0` は線形方程式の未知数、`mask = 0.0` は固定セルまたは解く対象から外すセルを意味すること。

### Requirement 3: 格子

**目的:** 格子の定義を 1 か所で固定し、geometry、boundary、solver が別々の解釈を持たないようにする。

#### Acceptance Criteria

1. 解析領域の X/Y サイズは `Lx = 1.2e-3 m`、`Ly = 1.2e-3 m` とすること。
2. X/Y の格子幅は `dx = Lx / NX`、`dy = Ly / NY` とすること。
3. Z 方向の格子は、セル境界座標 `Z[1..MZ]` で表すこと。
4. 代表セル幅 `ΔZ[k]` は、`k = 2..MZ-1` について `0.5 * (Z[k+1] - Z[k-1])` で求め、さらに `ΔZ[2]` と `ΔZ[MZ-1]` は 1 回ずつ半分にすること。
5. MVP では、canonical source に書かれた固定 Z 格子をそのまま使い、`NZ = 31`、`MZ = 33` とすること。
6. 更新に使う Z 範囲は境界条件から決めること。下側が `ISOTHERMAL` なら `z_start = 3`、下側が `HEAT_FLUX` または `CONVECTION` なら `z_start = 2`、上側が `ISOTHERMAL` なら `z_end = NZ`、上側が `HEAT_FLUX` または `CONVECTION` なら `z_end = NZ+1` とすること。

### Requirement 4: 材料表

**目的:** 材料 ID と物性値の対応を共通化し、feature ごとに別の材料表を持ち込まないようにする。

#### Acceptance Criteria

1. canonical source にある `1..7` の材料 ID をそのまま使うこと。
2. `copper`、`silicon`、`solder`、`FR4`、`A1060`、`resin`、`pwrsrc` の `alpha`、`rho`、`cp` を canonical source どおりに持つこと。
3. 材料 ID から各セルの物性値を引ける共通の対応表を持つこと。
4. `id == 7` は power source 材料として扱い、下流 feature が発熱判定に使えること。

### Requirement 5: 図形の基本判定と材料割当順序

**目的:** case-model が geometry を組み立てるときの基本ルールを共通化する。

#### Acceptance Criteria

1. 直方体、円柱、球の 3 種類の基本判定を共通に提供すること。
2. 直方体は、セル体積の 50% 以上が図形に入っていれば含まれるとみなすこと。
3. 円柱は、サンプリング近似で 50% 以上が入っていれば含まれるとみなすこと。
4. 球は、サンプリング近似で 50% 以上が入っていれば含まれるとみなすこと。
5. MVP では、円柱と球のサンプリング数を各軸 `50` に固定すること。
6. 材料割当順序は `power grid -> TSV -> plate layers -> solder bumps -> resin` とすること。
7. 上の順序で図形を適用したあと、未割当の物理セルはすべて `resin` で埋めること。

### Requirement 6: 境界条件データ

**目的:** case-model、boundary 処理、solver が同じ形の境界条件データを使えるようにする。

#### Acceptance Criteria

1. 境界条件の種類は `ISOTHERMAL`、`HEAT_FLUX`、`CONVECTION` の 3 つに限定すること。
2. 各面の境界条件データは、少なくとも `type`、`temperature`、`heat_flux`、`heat_transfer_coefficient`、`ambient_temperature` を持つこと。
3. 使わない属性は `0` で保持してよいこと。
4. 等温境界を `mask` と `theta` に反映する共通ヘルパの責務を定義すること。
5. 熱流束境界の寄与を RHS に入れる共通ヘルパの責務を定義すること。
6. 熱伝達境界の寄与を対角項と RHS に入れる共通ヘルパの責務を定義すること。
7. 符号規約は canonical source に従うこと。`x_minus`、`y_minus`、`z_minus` は内向きを正寄与、`x_plus`、`y_plus`、`z_plus` は外向き流出を正として負寄与で扱うこと。

### Requirement 7: 結果とログの共通項目

**目的:** main と validation が同じ出力項目を見られるようにする。

#### Acceptance Criteria

1. 実行ログの共通項目として、少なくとも grid size、`dx`、`dy`、`Δt`、solver 名、tolerance、各反復の residual、最終 `theta min`、最終 `theta max`、最終 `L2 norm`、実行時間を定義すること。
2. 各反復の residual 行は `<iteration> <residual_in_scientific_notation>` の 2 列形式とすること。
3. 回帰確認に使う代表点の種類として、少なくとも中央点、TSV 近傍点、上面中央近傍点を定義すること。
