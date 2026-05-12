# Requirements Document

## Introduction

この文書は `iot-arduino-watering-loop` の requirements である。  
ここでは、灌水 loop の内側で実行する relay 制御、パルス計数、瞬時流量、積算水量、停止条件、loop outcome を固定する。

## Boundary Context

- この feature で決めること:
  - relay on / off
  - pulse counting
  - instantaneous flow calculation
  - cumulative irrigation calculation
  - threshold stop と timeout stop
  - loop outcome contract
- この feature で決めないこと:
  - 灌水可否の判定
  - EEPROM / RTC memory への commit
  - OLED / cloud への表示と送信方針
  - sleep seconds の計算
- 依存する上流 feature:
  - `iot-arduino-loop-outside-control`

## Requirements

### Requirement 1: 灌水 loop は relay を確実に閉じる

**目的:** 異常系でも電磁弁が開いたまま残らないようにする。

#### Acceptance Criteria

1. `should_water = true` のときだけ relay を ON にすること。
2. loop の終了理由が `threshold_reached` でも `timeout` でも、終了前に relay を OFF にすること。
3. loop 途中で異常が起きても、最終的な exit path に relay OFF が含まれること。
4. `should_water = false` の場合は relay を ON にしないこと。

### Requirement 2: パルス計数と瞬時流量計算の式を固定する

**目的:** 表示、cloud telemetry、積算水量が別々の計算式を持たないようにする。

#### Acceptance Criteria

1. flow sensor pulse は下りエッジごとに 1 回計数すること。
2. instantaneous flow `Q [L/min]` は `elapsed` と `pulseCount` と `flow_coefficient_cf` を用いて canonical formula どおりに算出すること。
3. `elapsed` を使って正規化し、積算周期の遅延による誤差を抑えること。
4. calculation inputs と outputs は `loop-outside-control` がそのまま表示・送信・最終 status 集約に使えること。

### Requirement 3: 積算水量と停止条件を固定する

**目的:** 「どの時点で止めるか」を requirements 上で閉じる。

#### Acceptance Criteria

1. cumulative irrigation `Irr [L]` は canonical formula どおりに更新すること。
2. `Irr` が `target_irrigation_liters` 以上になった時点で `threshold_reached` として停止すること。
3. 経過時間が `watering_timeout_minutes` を超えた時点で `timeout` として強制停止すること。
4. 流量が出ない場合でも timeout で必ず停止できること。

### Requirement 4: loop outcome は persistence commit と表示更新に使える

**目的:** loop 外 feature が測定値と停止理由をそのまま受け取れるようにする。

#### Acceptance Criteria

1. loop outcome は少なくとも `stop_reason`、`elapsed_seconds`、`final_flow_lpm`、`final_irrigation_liters`、`watering_completed` を返せること。
2. `stop_reason` は少なくとも `threshold_reached` と `timeout` を区別できること。
3. timeout 停止でも `watering_completed = true` として、loop 外 feature の post-run persistence commit 対象にできること。
4. 本 feature は loop outcome を返すが、EEPROM / RTC memory 更新の owner にはならないこと。
