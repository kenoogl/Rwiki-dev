# Intent Document

## Current State

この文書は `iot-arduino` case の upstream anchor である。
repo 内の downstream artifact は一度ゼロクリアしたうえで、active feature set と requirements wave まで再構成した。

current source of truth:

- `/Users/Daily/Development/DR-IoT/intent.md`
- `/Users/Daily/Development/DR-IoT/仕様.md`

## プロダクト概要

家庭菜園・ベランダ菜園で育てる植物に対し、人の手を介さずに、決まった時刻に決まった水量で自動的に水やりを行う装置を作る。
電池や少電力配線でも長期間動作するよう、普段は省電力モードで待機し、水やりの時刻だけ目を覚ます設計を目指す。

この case は、意図駆動開発で event-driven IoT control code を構築する代表例として使う。

## 解決したい困りごと

- 毎朝の水やりは欠かせないが、旅行や外出があると止まってしまう
- 蛇口に付ける機械式タイマーでは、実際にどれだけ水が出たか分からない

## 目指す姿

- 時刻で起きて、水量で止まる装置
- 量が見える水やり
- 置きっぱなしで動く省電力装置
- 二度やりしない装置

## Users

- 灌水装置を運用する利用者
  - 指定時刻に自動灌水したい
  - 当日の二重灌水を避けたい
  - 灌水量と流量を確認したい
- IoT 制御コードの構築者
  - センサー、ネットワーク、永続化、deep sleep を含む制御コードを意図駆動で構築したい

## Goals

1. 指定時刻・指定間隔で灌水を実行できること
2. 流量センサーから流量と積算灌水量を計測できること
3. OLED 表示とネットワーク通知で状態を確認できること
4. EEPROM / RTC メモリ / deep sleep を使って自律運転できること
5. 意図駆動開発の case として downstream artifact に接続できること

## Non-Goals

1. 土壌水分や天候を使った自動判断
2. 複数バルブ・複数ゾーン対応
3. 手元からの即時手動起動
4. 高機能なクラウド履歴分析や remote configuration

## Constraints

1. current canonical source docs は `/Users/Daily/Development/DR-IoT/intent.md` と `/Users/Daily/Development/DR-IoT/仕様.md`
2. 対象プラットフォームは ESP32
3. WiFi, NTP, Blynk, OLED, EEPROM, deep sleep を含む制御コードであること
4. current implementation source tree は fresh `Spec-origin` skeleton として `/Users/Daily/Development/DR-IoT/src` に作成済みである

## Current Progress Note

- repo 内 umbrella state は [spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/spec.json:1) の `tasks-approved`
- active feature set は [iot-arduino-case-workflow-overlay.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-case-workflow-overlay.md:1) の 2 feature 版に固定した
- requirements gate package は [requirements-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/requirements-evidence-summary.md:1) で承認済み
- design gate package は [design-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/design-evidence-summary.md:1) で承認済み
- tasks gate package は [tasks-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/tasks-evidence-summary.md:1) で承認済み
- review acquisition gate package は [review-acquisition-gate-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/review-acquisition-gate-summary.md:1) で作成済みである
- review acquisition summary は [review-acquisition-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/review-acquisition-summary.md:1) で固定済みである
- first acquisition では `single / dual / dual+judgment = 2 / 3 / 3` を得た
- 次の作業は first acquisition の finding を implementation refinement と paper evidence に接続すること
