# 2026-05-12 iot-arduino design alignment gate

## 1. alignment scope

- aligned features:
  - [iot-arduino-loop-outside-control/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/design.md:1)
  - [iot-arduino-watering-loop/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-watering-loop/design.md:1)
- alignment focus:
  - owner boundary matrix
  - handoff object shape
  - dependency direction
  - tasks phase へ持ち越す detail-level open point

## 2. owner boundary confirmation

- `ControllerConfig` owner: `iot-arduino-loop-outside-control`
- `PersistentState` owner: `iot-arduino-loop-outside-control`
- `TimeContext` owner: `iot-arduino-loop-outside-control`
- `LoopEntryDecision` owner: `iot-arduino-loop-outside-control`
- `LoopInput` owner: `iot-arduino-watering-loop`
- `LoopOutcome` owner: `iot-arduino-watering-loop`
- `FinalStatus` owner: `iot-arduino-loop-outside-control`
- `SleepPlan` owner: `iot-arduino-loop-outside-control`
- `CycleResult` owner: `iot-arduino-loop-outside-control`

## 3. dependency confirmation

- `loop-outside-control -> watering-loop`
  - bridge from `LoopEntryDecision` and config values into `LoopInput`
  - consumption of `LoopOutcome` into post-run commit, final status, sleep planning
- `watering-loop` does not depend on WiFi, NTP, EEPROM, OLED, or Blynk
- `irrigation_controller.ino` depends only on `loop-outside-control` entry contract

上の dependency direction に逆流は見つからなかった。`watering-loop` は loop 外 policy を owner として再定義していない。

## 4. carried open points

- open point 1:
  - EEPROM byte layout と RTC memory field placement は tasks phase で固定する。design では owner と field set だけを確定した。
- open point 2:
  - ISR snapshot の atomic section と `millis()` wraparound-safe helper の具体実装は tasks phase で固定する。design では contract と責務だけを確定した。
- open point 3:
  - OLED page layout と Blynk virtual pin send cadence の exact wording は tasks phase で固定する。design では policy boundary だけを確定した。

## 5. metric snapshot

- `phase_blocking_issue_count`: `2`
- `phase_nonblocking_open_point_count`: `3`
- `phase_recheck_count`: `0`
- `phase_minor_adjustment_count`: `0`
- `phase_major_correction_count`: `2`
- `phase_intent_attributed_issue_count`: `0`
- `phase_reopen_required_count`: `0`

## 6. alignment conclusion

- alignment result:
  - blocking 級の owner conflict は残っていない
  - tasks phase に持ち越す open point は detail-level 3 件に限られる
- next action:
  - design evidence summary を作成し、human design gate input を提示する
