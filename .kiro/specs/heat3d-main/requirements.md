# Requirements Document

## Introduction

この文書は `heat3d-main` の requirements である。
ここでは、fixed case を実際に 1 回走らせ、結果を記録して返す最上位の流れを決める。

具体的には、次をここで固定する。

- case-model の呼び出し
- 初期温度の設定
- solver の呼び出し
- ログ出力
- `SimulationResult` の返却
- 回帰 baseline に使う代表値の取り方

geometry の細部や solver の内部アルゴリズムは、この feature の責務に含めない。

## Boundary Context

- この feature で決めること:
  - case construction の呼び出し順
  - 1 ステップ実行
  - canonical text log
  - `SimulationResult` の返却
  - baseline に使う代表値
- この feature で決めないこと:
  - 共通型や primitive の定義
  - fixed case の内部組み立て
  - solver の反復アルゴリズム
- 上流 feature:
  - `heat3d-case-model`
  - `heat3d-linear-solver`
- 下流 feature:
  - なし

## Requirements

### Requirement 1: 最上位の実行入口

**目的:** canonical MVP を self-contained に起動できる入口を決める。

#### Acceptance Criteria

1. canonical `SimulationConfig` はコード内で得ること。外部設定ファイルは使わないこと。
2. MVP では CLI 引数を要求しないこと。
3. canonical case は `heat3d-case-model` から受け取ること。
4. `heat3d-linear-solver` を使って、canonical MVP の backward Euler 1 ステップを 1 回だけ実行すること。
5. canonical MVP の実行は異常終了しないこと。

### Requirement 2: 初期化と solver 呼び出し

**目的:** 実行前に何を準備し、何を solver へ渡すかを明確にする。

#### Acceptance Criteria

1. 計算開始前に、全セルの初期温度を canonical `SimulationConfig` が持つ `initial_temperature` で初期化すること。MVP では `300.0 K` とすること。
2. 時間刻み `Δt` とステップ数は canonical `SimulationConfig` から読むこと。MVP では `Δt = 1000.0 s`、`step_count = 1` とすること。
3. `tolerance` と `max_iterations` も canonical `SimulationConfig` から読むこと。MVP では `1.0e-4` と `8000` とすること。
4. solver には、case-model から受け取った格子、物性配列、`qvol`、境界条件、active `z_range`、`Δt` を、その意味を変えずにそのまま渡すこと。

### Requirement 3: ログと返却値

**目的:** 実行結果を人と後続検証の両方が読める形で残す。

#### Acceptance Criteria

1. 実行ログは標準出力または `log.txt` に出すこと。
2. ログには、少なくとも grid size、`dx`、`dy`、`Δt`、solver 名、tolerance、各反復の residual、最終 `theta min`、最終 `theta max`、最終 `L2 norm`、実行時間を含めること。
3. 各反復の residual 行は `<iteration> <residual_in_scientific_notation>` の 2 列形式とすること。
4. 返り値の `SimulationResult` は、少なくとも `theta`、`iterations`、`final_residual`、`converged`、`elapsed_seconds` を含むこと。

### Requirement 4: 回帰 baseline 用の代表値

**目的:** 最初の成功 run を、後続比較の基準として固定できるようにする。

#### Acceptance Criteria

1. 最初に合格した MVP run では、`theta_min`、`theta_max`、最終 residual、反復回数を baseline として固定すること。
2. baseline には、中央点、TSV 近傍点、上面中央近傍点の 3 点温度も含めること。
3. これらの代表値は、解いた後の温度場から main が取り出せること。

### Requirement 5: MVP 全体としての合格条件

**目的:** feature 群を束ねた結果として canonical MVP が成立したかを判定できるようにする。

#### Acceptance Criteria

1. canonical MVP case `NX = 240`、`NY = 240`、`NZ = 31` で異常終了しないこと。
2. canonical MVP case で、反復回数が `8000` 以下であること。
3. canonical MVP case で、`final_residual < 1.0e-4` を満たすこと。
4. canonical MVP case で、`theta_min >= 250.0`、`theta_max <= 2000.0`、`theta_max > theta_min` を満たすこと。
