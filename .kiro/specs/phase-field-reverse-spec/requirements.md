# Requirements Document

## Introduction

本仕様は、三相分解フェーズフィールドコード (= 3 成分濃度場 `c1`, `c2`, `c3` の連成 Cahn-Hilliard 型 PDE solver、`c2`, `c3` を独立変数として時間発展させ `c1 = 1 - c2 - c3` を従属変数とする) の C++ clean-room 再実装を対象とする。実装者は SSoT 仕様書 `DR-pfm/spec_seed/DEVELOPMENT_SPEC.md` (= 22 章 9007 byte) と描画 API ヘッダ `wingxa.h` のみを参照し、等価なプログラム群を構築する。

本 spec は req / design / tasks 三段階分割 + V4 review protocol Round 1-5 適用を経て、論文 Claim D (= forward vs reverse engineering asymmetry) の primary evidence 取得用 sample として機能する。

要求事項の各受入基準は EARS 形式で記述し、SSoT 章番号 (= `§N`) を参照することで `DEVELOPMENT_SPEC.md` を canonical source として保持する。

## Boundary Context

- **In scope**:
  - 3 機能 = (1) シミュレーション実行、(2) 保存済み濃度データの再描画、(3) 保存済み濃度データからの BMP 書き出し (= `§3`)
  - 数値モデル = 支配変数 (= `§4`) / 支配方程式 (= `§5`) / 化学ポテンシャル (= `§6`) / 空間離散 (= `§7`) / 既定定数 (= `§8`) / 時間発展手順 (= `§11`) / 平均組成保存補正 (= `§12`)
  - 入出力契約 = 実行パラメータ受付 (= `§13`) / 濃度データ形式 (= `§16`) / BMP 書き出し対象ステップ群 (= `§19`) / 異常終了 (= `§20`)
  - 可視化 = 可視化仕様 (= `§17`、色変換 + 描画要件 + 描画領域 + 周期境界連続性) / 描画 API 依存契約 (= `§18`)
  - 濃度制約 invariant = 初期化時 / ポテンシャル計算前 / 時間更新後 / 平均組成補正後 (= `§10` で 4 タイミング定義、初期化時の適用 trigger は `§9`)
- **Out of scope (= 実装裁量、`§21` から本 spec 用に絞り込み)**:
  - 反復制御の書き方、乱数生成器の具体実装、内部関数名、ファイル分割の仕方
  - 画面表示を実機で行うか、ヘッドレス描画バッファのみで扱うか
  - (注) `§21` で実装裁量とされた「配列を静的 / 動的に保持するか」は、本 spec では Req 2 で静的確保に固定する
- **Adjacent expectations**:
  - 描画 API ヘッダ `wingxa.h` (= 9 関数 prototype) は外部提供済の依存、本実装は API interface contract に従う
  - 描画 API の実体実装 (= ヘッダ宣言関数の実装) は本 spec の責任範囲外、外部 link 前提
  - **Reference materials limitation (= `§2`)**: 実装時の参照物は SSoT 仕様書 (= `DEVELOPMENT_SPEC.md`) と描画 API ヘッダ (= `wingxa.h`) のみに限定する (= clean-room 制約の根幹規定、論文 Claim D evidence 取得の前提条件)

## Requirements

### Requirement 1: シミュレーション実行機能 (= `§3` 機能 1, `§13`-`§15`)

**Objective:** 材料物性研究者として、三相分解の時間発展 simulation を入力パラメータで実行したい。平均組成の異なる条件群で組織発展を観察できるように。

#### Acceptance Criteria

1. When the user starts the simulation, the Simulation Module shall accept the following input parameters per `§13`: 平均組成 `c2a`, 平均組成 `c3a`, 時間刻み `delt`, 最大ステップ数, 濃度データ保存間隔, BMP 保存間隔, 出力ディレクトリ. 各 parameter の値域 / 型は `0 < c2a < 1`, `0 < c3a < 1`, `c2a + c3a < 1`, `delt > 0` の double、最大ステップ数 / 濃度データ保存間隔 / BMP 保存間隔は正整数 (`> 0`)、出力ディレクトリは文字列。`delt` は必須引数 (= 省略不可、未指定時は AC10 / Req 6 AC1 に従い非 0 終了)。Note: `c2a`, `c3a` は SSoT `§13` 文言「平均組成 `c2`」「平均組成 `c3`」の Kiro req 内正規名 (= `§9`/`§12` 系命名と統一)。
2. When the maximum step count is not specified, the Simulation Module shall use the default value `100000` per `§13`.
3. When the concentration data save interval is not specified, the Simulation Module shall use the default value `2000` per `§13`.
4. When the BMP save interval is not specified, the Simulation Module shall use the default value `2000` per `§13`.
5. When the output directory is not specified, the Simulation Module shall use the default value `"output"` per `§13`.
6. When the simulation starts, the Simulation Module shall execute the startup sequence specified in `§14`: (a) パラメータを解釈する, (b) 出力ディレクトリの存在を確認する, (c) 必要なら出力ディレクトリを作成する, (d) 初期濃度場を構築する, (e) 描画バッファを初期化する, (f) 初期スナップショットを濃度データと BMP に保存する.
7. While the simulation is running, the Simulation Module shall execute time steps until one of the stop conditions defined in `§15` is met.
8. When the step count reaches the maximum, the Simulation Module shall terminate normally per `§15`.
9. When `keypress()` returns non-zero, the Simulation Module shall terminate normally per `§15`.
10. If an I/O error occurs during simulation execution, the Simulation Module shall terminate with a non-zero exit code per `§15` and `§20`.

### Requirement 2: 数値モデル (= 支配方程式 + 離散化 + 時間発展、`§4`-`§8`, `§11`)

**Objective:** 材料物性研究者として、`§5`-`§12` で規定された numerical scheme と等価な解を得たい。reverse engineering 評価で original 実装と数値的に再現可能であるように。

#### Acceptance Criteria

1. The Numerical Engine shall solve the 2-component coupled Cahn-Hilliard equation per `§5`: `∂c2/∂t = M22 ∇²μ2 + M23 ∇²μ3` and `∂c3/∂t = M32 ∇²μ2 + M33 ∇²μ3`, where `c1 = 1 - c2 - c3` is the dependent component (= `§4`).
2. The Numerical Engine shall compute chemical potentials `μ2`, `μ3` per `§6` using the following explicit formulas: chemical free-energy partial derivatives `∂f_chem/∂c2 = om_12 (c1 - c2) - om_13 c3 + om_23 c3 + log(c2) - log(c1)` and `∂f_chem/∂c3 = om_13 (c1 - c3) - om_12 c2 + om_23 c2 + log(c3) - log(c1)`; full chemical potentials `μ2 = ∂f_chem/∂c2 - 2 κ2 ∇²c2 - κ3 ∇²c3` and `μ3 = ∂f_chem/∂c3 - 2 κ3 ∇²c3 - κ2 ∇²c2` (= ここで `κ2 ≡ kapa_c2`, `κ3 ≡ kapa_c3`、SSoT `§8` で既定値定義の同係数の数式記号表記、AC6 / AC8 step(1) と同一変数).
3. The Numerical Engine shall discretize space on a 2D square lattice with default grid count `ND = 100` and grid indices `0` to `ND-1` per `§7`.
4. The Numerical Engine shall apply periodic boundary conditions in both x and y directions per `§7`.
5. The Numerical Engine shall approximate the Laplacian using the 5-point finite difference stencil defined in `§7`: `lap(a) = a(i+1,j) + a(i-1,j) + a(i,j+1) + a(i,j-1) - 4 a(i,j)` (= dimensionless stencil = `dx = 1` 相当、物理格子間隔 `b1` は `§8` の `kapa_c2`, `kapa_c3` 定義に `b1^2` として吸収済、stencil に `b1^2` を追加除算しない).
6. The Numerical Engine shall use the default constants defined in `§8` listed independently per SSoT format: `rr = 8.3145`, `temp = 900.0`, `al = 100.0e-9`, `b1 = al / ND`, `om_12 = 25000 / (rr * temp)`, `om_23 = 25000 / (rr * temp)`, `om_13 = 25000 / (rr * temp)`, `cmob22 = 1.0`, `cmob33 = 1.0`, `cmob23 = -0.5`, `cmob32 = -0.5`, `kapa_c2 = 5.0e-15 / (b1 * b1 * rr * temp)`, `kapa_c3 = 5.0e-15 / (b1 * b1 * rr * temp)`.
7. The Numerical Engine shall integrate time explicitly per `§11`.
8. While computing one time step, the Numerical Engine shall execute the following 7 steps in the fixed order defined in `§11` using the explicit formulas (= step boundary は SSoT `§11` 文言と一致):
   - step (0) (= ポテンシャル計算前 clamp、`§10` 4 タイミング invariant の 1 つ、Req 3 AC3 と整合): apply concentration clamps to `c2`, `c3` per `§10` before potential computation;
   - step (1): compute the chemical free-energy partial derivatives `mu2_chem = om_12*(c1 - c2) - om_13*c3 + om_23*c3 + log(c2) - log(c1)` and `mu3_chem = om_13*(c1 - c3) - om_12*c2 + om_23*c2 + log(c3) - log(c1)`, then compute the full chemical potentials `mu2 = mu2_chem - 2*kapa_c2*lap(c2) - kapa_c3*lap(c3)` and `mu3 = mu3_chem - 2*kapa_c3*lap(c3) - kapa_c2*lap(c2)` at all grid points;
   - step (2): compute `lap(mu2)` and `lap(mu3)` at all grid points;
   - step (3): compute concentration time derivatives `dc2_dt = cmob22*lap(mu2) + cmob23*lap(mu3)` and `dc3_dt = cmob32*lap(mu2) + cmob33*lap(mu3)`;
   - step (4): update to a temporary array `c2_new = c2_old + dc2_dt * delt` and `c3_new = c3_old + dc3_dt * delt`;
   - step (5): apply concentration clamps to the temporary array (= `§10`);
   - step (6): invoke the Mean Composition Corrector to apply mean composition correction (= `§12`、Mean Composition Corrector に委譲、内部で Concentration Clamp 呼出);
   - step (7): re-apply concentration clamps after correction (= `§10`).
9. The Numerical Engine shall allocate concentration field arrays statically using the grid count parameter `ND` defined in `§7` (= サイズは compile time に固定、runtime での動的再確保は行わない、`ND` は compile-time constant で `§7` 既定値 `100` に固定、runtime での `ND` 変更は本 spec scope 外). この AC は `§21` で実装裁量とされた「配列を静的 / 動的に保持するか」を本 spec で静的確保に固定するための上書き条項である。

### Requirement 3: 濃度制約 invariant + 初期化 + 平均組成保存 (= `§9`, `§10`, `§12`)

**Objective:** 材料物性研究者として、計算中に物理的に意味のある濃度範囲を維持したい。`log(c1), log(c2), log(c3)` の定義域逸脱や数値発散を防げるように。

#### Acceptance Criteria

1. When the simulation is initialized, the Initial Field Builder shall set the initial concentration at each grid point to the mean compositions `c2a`, `c3a` plus random fluctuation of default amplitude `±0.01` per `§9` (= `§9` 既定値、本 spec で明示固定値として要求するわけではない).
2. When initialization completes, the Initial Field Builder shall apply the concentration clamping defined in `§10` such that `0 < c2 < 1`, `0 < c3 < 1`, `c2 + c3 < 1`, and `c1 = 1 - c2 - c3 > 0` hold at every grid point. Note: `c2a` または `c3a` が境界近傍 (= 例 `c2a < 0.01` or `c2a + c3a > 0.99`) で initial clamping が field を変更する場合、initial field の実際平均が `c2a`, `c3a` から bounded deviation で乖離する可能性あり、AC9 の Mean Composition Corrector が time step 1 で補正する。
3. While the simulation is running, the Numerical Engine shall maintain `0 < c2 < 1`, `0 < c3 < 1`, `c2 + c3 < 1`, and `c1 > 0` at every grid point at the four points specified in `§10` (= 初期化時、ポテンシャル計算前、時間更新後、平均組成補正後).
4. If `c2 ≤ 0` at any grid point, the Concentration Clamp shall set `c2 = eps` where the default `eps = 1.0e-6` per `§10`.
5. If `c2 ≥ 1` at any grid point, the Concentration Clamp shall set `c2 = 1 - eps` per `§10`.
6. If `c3 ≤ 0` at any grid point, the Concentration Clamp shall set `c3 = eps` per `§10`.
7. If `c3 ≥ 1` at any grid point, the Concentration Clamp shall set `c3 = 1 - eps` per `§10`.
8. If `c2 + c3 ≥ 1` at any grid point, the Concentration Clamp shall scale `c2` and `c3` proportionally so that the sum is at most `1 - 2*eps` per `§10`. After the proportional scaling, if any of AC4-AC7 conditions become violated (= 縮小後 `c2 < eps` or `c3 < eps` 等)、the Concentration Clamp shall re-apply AC4-AC7 to restore individual lower-bound invariants (= 統合適用 = AC4-AC8 を全条件満足まで適用)。
9. After each time step, the Mean Composition Corrector shall maintain the input mean compositions `c2a`, `c3a` per `§12` by computing `delta_c2 = avg_c2 - c2a` and `delta_c3 = avg_c3 - c3a`, uniformly subtracting them from all grid points, and re-applying concentration clamps via the Concentration Clamp service (= 階層委譲: Mean Composition Corrector が Concentration Clamp を下請け呼出、Numerical Engine が Mean Composition Corrector を呼出). Priority note: re-clamping 後の residual deviation (= `|avg_c2 - c2a|`, `|avg_c3 - c3a|`) は clamping epsilon の bounded 範囲内で許容、本 AC は再 iterate しない (= `§10` 濃度制約 invariant を `§12` 平均組成厳密保存より優先、final invariant は `§10`)。

### Requirement 4: 濃度データ入出力 + BMP 書き出し (= `§3` 機能 2-3, `§16`, `§19`)

**Objective:** 材料物性研究者として、計算結果を再現可能な形式で永続化し、特定ステップを後から可視化できるように。

#### Acceptance Criteria

1. When the Snapshot Writer saves a concentration snapshot, the Snapshot Writer shall record one real value `time1` followed by `ND * ND` real pairs `(c2, c3)` in text format per `§16`. `time1` の値は当該 snapshot 保存時点の物理時刻 (= 累積 step 数 × `delt`、初期 snapshot は `time1 = 0.0`)。
2. The Snapshot Writer shall separate numeric values with whitespace or newlines such that the output is parsable as whitespace-separated text.
3. When saving the initial snapshot, the Snapshot Writer shall create a new file or overwrite an existing one per `§16`.
4. When saving a subsequent snapshot, the Snapshot Writer shall append to the existing file per `§16`.
5. The BMP Writer shall be able to generate a BMP image for any saved concentration snapshot. Under the default BMP save interval parameter (= `§13` 既定 `2000`) and default maximum step count (= `§13` 既定 `100000`), this shall include at least the steps `0, 2000, 4000, 6000, 8000, 10000, 12000, 14000, 16000, 18000, 20000, 30000, 40000, 50000, 60000, 70000, 80000` per `§19` (= デフォルト param での normative 保存 step 列挙)。param 変更時 (= BMP 保存間隔 `K` で実行時) は step 群 = `{0, K, 2K, ...} ∩ {≤ 最大ステップ数}` を生成 (= 動的規則、default 下では本 AC 列挙の `§19` 17 step を必ず含む)。
6. The Re-render Function shall be able to load a saved concentration snapshot file and re-display its contents via the Renderer per `§3` 機能 2.
7. If the concentration data file fails to open, the Snapshot Reader shall terminate with a non-zero exit code per `§20` (= canonical error termination policy は Requirement 6 で規定、本 AC は局所的完結性のための per-component 適用記述).
8. If concentration data parsing fails, the Snapshot Reader shall terminate with a non-zero exit code per `§20` (= 同 Req 6 への canonical pointer).
9. If a BMP save fails, the BMP Writer shall terminate with a non-zero exit code per `§20` (= 同 Req 6 への canonical pointer).

### Requirement 5: 可視化機能 + 描画 API 契約 (= `§17`, `§18`)

**Objective:** 材料物性研究者として、計算中および保存済みデータから組織を視覚的に把握したい。色 mapping は物理量と直接対応するように。

#### Acceptance Criteria

1. When rendering a grid point, the Renderer shall compute color components per `§17`: `R = 1 - c2 - c3`, `G = c2`, `B = c3`.
2. The Renderer shall clamp each color component to `[0, 1]` and convert it to a `0..255` integer color before drawing per `§17`.
3. The Renderer shall draw each grid point as a filled rectangle per `§17`.
4. The Renderer shall use a default drawing area of `400 x 400` pixels per `§17`.
5. The Renderer shall handle grid edges so that the periodic boundaries appear continuous in the displayed image per `§17`. Operational 判定基準: 描画は格子インデックス `0` から `ND-1` の全格子点を網羅し、wraparound 列 (= `ND` 番目相当) の追加描画は実装裁量 (= `§21`)。本 AC pass 条件は「格子全点描画 + 隣接格子間に visible gap がない」。
6. The Renderer shall depend only on the 9 functions declared in `wingxa.h` per `§18`: `gwinsize`, `ginit`, `gsetorg`, `keypress`, `gcolor`, `grect`, `swapbuffers`, `save_screen`, `itoa`.

### Requirement 6: エラー処理 + 異常終了 (= `§20`)

**Objective:** 運用者として、異常系で確実に非 0 終了コードを得たい。CI / バッチ実行時に失敗を検出できるように。

#### Acceptance Criteria

1. If invalid input arguments are detected at startup (= Req 1 AC1 値域違反 = `c2a ≤ 0` or `c2a ≥ 1` or `c3a ≤ 0` or `c3a ≥ 1` or `c2a + c3a ≥ 1` or `delt ≤ 0` or 最大ステップ数 / 保存間隔 が非正整数 / 必須 `delt` 引数欠落), the Simulation Module shall terminate with a non-zero exit code per `§20`.
2. If numeric conversion of input parameters fails, the Simulation Module shall terminate with a non-zero exit code per `§20`.
3. If output directory creation fails, the Simulation Module shall terminate with a non-zero exit code per `§20`.
4. If the concentration data file fails to open during read or write, the affected component (= Simulation Module / Snapshot Writer / Snapshot Reader / BMP Writer / Re-render Function) shall terminate with a non-zero exit code per `§20`.
5. If concentration data parsing fails, the affected component shall terminate with a non-zero exit code per `§20`.
6. If a BMP save fails, the affected component shall terminate with a non-zero exit code per `§20`.

### Requirement 7: 受け入れ基準 (= `§22`)

**Objective:** 運用者 / 検証担当として、本 spec の最終受け入れ基準を AC として明示し、tasks / validation phase での verification target が canonical に参照可能であるように。

#### Acceptance Criteria

1. The Build System shall succeed in building all required executables (= ビルドが成功する) per `§22`.
2. When the Simulation Module is started, it shall produce both an initial concentration snapshot and an initial BMP file (= シミュレーション実行機能が起動し、初期濃度データと初期 BMP を出力する) per `§22`.
3. The Re-render Function shall be able to load a previously saved concentration data file (= 再描画機能が保存済み濃度データを読み込める) per `§22`.
4. The BMP Writer shall be able to generate BMP files for the prescribed step group defined in `§19` under the default `§13` parameters (= BMP 書き出し機能が所定ステップ群を出力できる、param 変更時は対応する step 群を生成、Req 4 AC5 と整合) per `§22`.
5. While the simulation is running, the Numerical Engine shall keep `c1`, `c2`, `c3` strictly within the domain of `log()` (= 実行中に `log(c1), log(c2), log(c3)` の定義域を外れない) per `§22`.
6. After mean composition correction at every time step, the Numerical Engine shall ensure all 4 concentration constraints defined in `§10` remain satisfied (= 平均組成補正後も濃度制約を満たす、内部で Concentration Clamp に委譲、Req 3 AC3 と subject 整合) per `§22`.
