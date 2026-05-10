# Requirements Document

## Introduction

本仕様は、ESP32 上で動作する灌水制御コードを対象とする。
コードは WiFi 接続、NTP による時刻同期、EEPROM による前回灌水時刻保持、
RTC メモリによる当日灌水済みフラグ保持、流量センサー計測、OLED 表示、
Blynk 通知、deep sleep を組み合わせて自律運転する。

canonical source は `/Users/Daily/Development/DR-IoT/src/Irrigation.ino` とする。

## Boundary Context

- In scope
  - 指定時刻の灌水実行判定
  - 灌水間隔判定
  - 当日二重灌水防止
  - WiFi 接続と NTP 同期
  - リレー制御による灌水開始・停止
  - 流量センサーのパルス計測
  - 積算灌水量計算
  - OLED 表示
  - Blynk への状態送信
  - EEPROM / RTC メモリへの状態保存
  - 次回時刻までの deep sleep
- Out of scope
  - 複数灌水ライン制御
  - GUI
  - 詳細なクラウド履歴管理
  - センサー校正 UI

## Requirements

### Requirement 1: スケジュール灌水

**Objective:** 利用者として、指定時刻になったときだけ灌水を自動実行したい。

#### Acceptance Criteria

1. システムは目標時刻を時分秒で保持できること。
2. システムは現在時刻が目標時刻の許容ウィンドウ内にあるか判定できること。
3. システムは前回灌水時刻から設定日数以上経過した場合のみ灌水可能と判定すること。
4. システムは当日灌水済みフラグが立っている場合、同日の再灌水を行わないこと。
5. 灌水条件を満たさない場合、システムは灌水を開始しないこと。

### Requirement 2: 灌水実行と停止

**Objective:** 利用者として、灌水開始後は所定量まで給水し、過剰灌水を防ぎたい。

#### Acceptance Criteria

1. 灌水開始時にシステムはリレー出力を有効化すること。
2. システムは流量センサーのパルスを割り込みで計測できること。
3. システムは一定周期ごとに流量と積算灌水量を計算できること。
4. 積算灌水量がしきい値を超えた場合、システムは灌水を停止すること。
5. 灌水継続時間がタイムアウトを超えた場合、システムは灌水を停止すること。
6. 灌水終了時にシステムはリレー出力を無効化すること。

### Requirement 3: 状態表示と通知

**Objective:** 利用者として、現在時刻、流量、灌水量、動作状態を確認したい。

#### Acceptance Criteria

1. システムは OLED に時刻または灌水状態を表示できること。
2. 灌水中、システムは流量と積算灌水量を表示できること。
3. システムは Blynk に流量、積算灌水量、稼働状態を送信できること。
4. 灌水終了時、システムは稼働状態を停止へ更新できること。

### Requirement 4: 永続化と再起動耐性

**Objective:** 利用者として、再起動や deep sleep 後も灌水状態が破綻しないでほしい。

#### Acceptance Criteria

1. システムは EEPROM から前回灌水時刻を読み出せること。
2. 灌水実行時、システムは EEPROM に今回の灌水時刻を書き込めること。
3. システムは RTC メモリに当日灌水済みフラグを保持できること。
4. システムは RTC メモリに WiFi リトライ回数を保持できること。
5. 同日内の deep sleep / restart 後も二重灌水防止判定が維持されること。

### Requirement 5: ネットワーク接続と時刻同期

**Objective:** 利用者として、ネットワーク接続と正しい現在時刻に基づいて運転してほしい。

#### Acceptance Criteria

1. システムは固定 IP 設定で WiFi 接続を試行できること。
2. WiFi 接続失敗時、システムは一定回数まで再試行できること。
3. 再試行上限に達した場合、システムは即時灌水を行わず sleep 側へ退避できること。
4. システムは NTP により現在時刻を取得できること。
5. 時刻同期に失敗した場合、システムは灌水処理へ進まず sleep 側へ退避できること。

### Requirement 6: スリープ制御

**Objective:** 利用者として、待機時に消費電力を抑えつつ次回時刻に備えてほしい。

#### Acceptance Criteria

1. システムは現在時刻から次の目標時刻までの秒差を計算できること。
2. システムは最大 sleep 時間を上限として deep sleep 時間を決定できること。
3. 灌水実行の有無にかかわらず、処理終了後は deep sleep へ遷移できること。
4. システムは sleep 前に現在時刻と sleep 秒数を表示できること。

### Requirement 7: プラットフォーム境界

**Objective:** 開発者として、対象コードの依存境界を明確にし、仕様駆動で扱いやすくしたい。

#### Acceptance Criteria

1. 対象プラットフォームは ESP32 であること。
2. システムは WiFi, Wire(I2C), OLED, EEPROM, Blynk, deep sleep API を利用すること。
3. システムは event-driven IoT control code の representative case として downstream artifact に接続できること。
