# Intent Document

## Intent

ESP32 ベースの灌水制御コードを実装し、
指定時刻に灌水を実行し、流量センサーから灌水量を計測し、
表示・記録・スリープ制御を含めて自律運転できるようにする。

この case は、仕様駆動開発で event-driven IoT control code を構築する
代表例として使う。

## Users

- 灌水装置を運用する利用者
  - 指定時刻に自動灌水したい
  - 当日の二重灌水を避けたい
  - 灌水量と流量を確認したい
- IoT 制御コードの構築者
  - センサー、ネットワーク、永続化、deep sleep を含む制御コードを
    仕様駆動で構築したい

## Goals

1. 指定時刻・指定間隔で灌水を実行できること
2. 流量センサーから流量と積算灌水量を計測できること
3. OLED 表示とネットワーク通知で状態を確認できること
4. EEPROM / RTC メモリ / deep sleep を使って自律運転できること
5. 仕様駆動開発の case として downstream artifact に接続できること

## Non-Goals

1. 汎用ホームオートメーション framework 化
2. 複数バルブ・複数ゾーン対応
3. ローカル GUI
4. オフライン時の高機能履歴分析

## Constraints

1. canonical source は `/Users/Daily/Development/DR-IoT/src/Irrigation.ino`
2. 対象プラットフォームは ESP32
3. WiFi, NTP, Blynk, OLED, EEPROM, deep sleep を含む制御コードであること
