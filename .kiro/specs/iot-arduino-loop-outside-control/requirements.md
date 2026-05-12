# Requirements Document

## Introduction

この文書は `iot-arduino-loop-outside-control` の requirements である。  
ここでは、灌水 loop の外側で行う設定、状態保持、時刻取得、灌水可否判定、表示と telemetry の方針、post-run 記録、sleep planning、全体 orchestration をまとめて固定する。

この feature は、`今回 loop に入るか` と `loop が終わったあと何を記録して次にどう待つか` の owner である。

## Boundary Context

- この feature で決めること:
  - compile-time configuration
  - runtime state と persistence boundary
  - WiFi / NTP と current time validity
  - 灌水可否判定
  - OLED / telemetry の運用方針
  - post-run persistence commit
  - sleep planning と top-level orchestration
- この feature で決めないこと:
  - relay の on / off 実行
  - pulse counting
  - instantaneous flow calculation
  - cumulative irrigation calculation
  - threshold / timeout stop の loop 内判定
- 下流 feature:
  - `iot-arduino-watering-loop`

## Requirements

### Requirement 1: 初回 loop では compile-time configuration を正本にする

**目的:** requirements 段で persisted setting の複雑さを持ち込まず、装置の基本挙動を先に固定する。

#### Acceptance Criteria

1. 本 feature は、少なくとも `target time`、`watering interval days`、`target irrigation liters`、`watering timeout minutes`、`target time tolerance minutes`、`max sleep seconds`、`period ms`、`flow coefficient CF` を持つ configuration を定義すること。
2. 本 feature は、少なくとも `wifi credentials`、`static IP related fields`、`ntp server`、`timezone`、`cloud token`、`serial baudrate` を持つ configuration を定義すること。
3. 初回 requirements wave では、上記 configuration を compile-time constant として扱うこと。
4. 装置単体での設定変更、遠隔設定変更、persisted setting editor は scope 外とすること。

### Requirement 2: 状態保持と restart 境界を 1 か所に固定する

**目的:** duplicate prevention と restart 後の再判定を同じ保存境界で扱う。

#### Acceptance Criteria

1. EEPROM には `last_watering_unix_time` を 1 件保持すること。
2. RTC memory には `already_watered_today`、`watered_day_of_year`、`network_retry_count` を保持すること。
3. deep sleep restart では EEPROM と RTC memory の両方を再利用すること。
4. full power loss restart では RTC memory が失われてもよく、EEPROM の `last_watering_unix_time` と成功した時刻同期結果から duplicate prevention を再判定すること。
5. current time が利用できない場合、full power loss restart 後は `no-run` に倒せること。

### Requirement 3: loop に入る前の判定を 1 feature で閉じる

**目的:** loop 実行の前提条件を別 feature に分散させない。

#### Acceptance Criteria

1. 本 feature は、少なくとも `WiFi connect -> NTP sync -> current time normalization -> eligibility decision` の順で loop entry 判定に必要な情報を揃えること。
2. eligibility 判定は、`current time is within tolerance window`、`not already watered today`、`interval days have elapsed since last watering or no prior record` の 3 条件を持つこと。
3. 上の 3 条件をすべて満たす場合のみ `should_water = true` を返すこと。
4. `no-run` の理由は少なくとも `outside_time_window`、`already_watered_today`、`interval_not_elapsed`、`network_unavailable`、`time_unavailable` を区別できること。

### Requirement 4: telemetry failure は non-blocking とする

**目的:** 可観測性の失敗で watering safety を壊さない。

#### Acceptance Criteria

1. OLED は起動直後、灌水中、sleep 直前で表示内容を切り替えられること。
2. cloud telemetry は瞬時流量、積算水量、稼働状態フラグを送れること。
3. telemetry failure は warning として扱い、灌水判定、loop stop、sleep planning を block しないこと。
4. `no-run`、`threshold stop`、`timeout stop` のいずれでも、final status に telemetry warning の有無を含められること。

### Requirement 5: loop 後の commit と sleep planning の owner を引き受ける

**目的:** `いつ記録し、いつ眠るか` を 1 feature に閉じる。

#### Acceptance Criteria

1. `watering-loop` が `watering_completed = true` を返した場合、EEPROM の `last_watering_unix_time` と RTC memory の `already_watered_today`、`watered_day_of_year` を更新すること。
2. timeout 停止でも post-run persistence commit を行うこと。
3. `no-run` の場合は `last_watering_unix_time` を更新しないこと。
4. 次回目標時刻までの残り時間を計算し、`max_sleep_seconds` を超えない sleep seconds を返せること。
5. top-level orchestration は `initialize -> connect/time sync -> eligibility -> loop if allowed -> post-run update -> sleep` の順で実行できること。
