# 2026-05-12 iot-arduino requirements alignment gate

## 1. purpose

active feature 2 本の requirements wave 後に、shared contract、owner boundary、handoff input を横断確認し、design フェーズへ進める requirements package を固定する。

## 2. reviewed feature set

- [iot-arduino-loop-outside-control/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/requirements.md:1)
- [iot-arduino-watering-loop/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-watering-loop/requirements.md:1)

## 3. alignment result

### 3.1 Loop outside control owner

- `iot-arduino-loop-outside-control` が compile-time configuration、runtime state names、EEPROM / RTC memory boundary、WiFi / NTP、eligibility decision、telemetry policy、post-run persistence commit、sleep planning、top-level orchestration の owner である
- `iot-arduino-watering-loop` はこれらを消費し、独自の保存境界や policy owner を再定義しない

### 3.2 Loop inside execution owner

- `iot-arduino-watering-loop` が relay on / off、pulse counting、instantaneous flow、cumulative irrigation、threshold / timeout stop、loop outcome の owner である
- loop entry は `should_water` と decision reason を入力にし、loop outcome は `watering_completed` と stop reason を返す
- timeout 停止も loop 外制御が post-run persistence commit へ載せられる outcome を返す

## 4. open points

blocking 級の open point は残していない。

design フェーズで再確認すべき論点:

- loop 外制御の中で state / time / telemetry helper をどう内部再分割するか
- full power loss restart 後の `same local day` 比較 helper をどこに置くか
- loop outcome と final status をどう struct 化するか

## 5. conclusion

requirements reopen 後に 2 feature split へ再構成した結果、loop 外制御と loop 内実行の owner boundary と handoff input は design へ進める水準で整合した。したがって `iot-arduino` は human `requirements gate` へ進める。
