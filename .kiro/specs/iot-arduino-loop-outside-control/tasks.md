# Implementation Plan

> `iot-arduino-loop-outside-control` は、灌水 loop の外側にある policy / orchestration owner である。ここでは、configuration、state boundary、time validity、eligibility、reporting、post-run commit、sleep planning を、実装着手順と shared file owner が分かる形に落とす。

## 1. Loop outside control pipeline を実装する

- [ ] 1.1 top-level entry と configuration skeleton を実装する
  - `src/irrigation_controller.ino`、`src/loop_outside_control/controller_config.h`、`controller_config.cpp`、`loop_outside_controller.h`、`loop_outside_controller.cpp` の skeleton を追加する。
  - `.ino` は `runCycle()` 呼び出しと deep sleep entry だけを持つ thin entrypoint に固定し、policy logic をここへ書かない。
  - 観測条件: top-level file owner が `loop-outside-control` に固定され、entrypoint の責務が薄いことがコード上でも読める。
  - _Requirements: 1, 5_
  - _Boundary: src/irrigation_controller.ino, src/loop_outside_control/controller_config.*, src/loop_outside_control/loop_outside_controller.*_

- [ ] 1.2 state boundary を実装する
  - `src/loop_outside_control/state_store.h/.cpp` を追加し、EEPROM の `lastWateringUnixTime`、RTC memory の `alreadyWateredToday`、`wateredDayOfYear`、`networkRetryCount` の load/save contract を実装する。
  - deep sleep restart と full power loss restart で読み手が同じ `PersistentState` を得る形にする。
  - 観測条件: state read/write owner が `StateStore` に固定され、他 file が EEPROM / RTC memory field を直接触らない。
  - _Requirements: 2_
  - _Boundary: src/loop_outside_control/state_store.*_
  - _Depends: 1.1_

- [ ] 1.3 time validity と loop entry decision を実装する
  - `src/loop_outside_control/time_sync_gateway.h/.cpp` と `eligibility_gate.h/.cpp` を追加する。
  - WiFi connect、NTP sync、`TimeContext` 構築、`LoopEntryDecision` の生成を実装する。
  - `current time unavailable => no-run` をこの path に固定する。
  - 観測条件: `network_unavailable / time_unavailable / outside_time_window / already_watered_today / interval_not_elapsed` が decision reason として返る。
  - _Requirements: 2, 3_
  - _Boundary: src/loop_outside_control/time_sync_gateway.*, src/loop_outside_control/eligibility_gate.*_
  - _Depends: 1.1, 1.2_

- [ ] 1.4 reporting policy を実装する
  - `src/loop_outside_control/status_reporter.h/.cpp` を追加する。
  - pre-run / final OLED render、telemetry publish、`TelemetryWarning` 生成を実装する。
  - telemetry failure は warning へ変換し、cycle failure にしない。
  - 観測条件: reporting owner が `StatusReporter` に固定され、warning payload shape が code 上で一意に読める。
  - _Requirements: 4_
  - _Boundary: src/loop_outside_control/status_reporter.*_
  - _Depends: 1.1_

- [ ] 1.5 post-run commit と sleep planning を実装する
  - `src/loop_outside_control/post_run_committer.h/.cpp` と `sleep_planner.h/.cpp` を追加する。
  - `wateringCompleted = true` の場合に timeout 停止でも state commit を行う rule と、`maxSleepSeconds` で capped した sleep plan を実装する。
  - 観測条件: post-run state write timing と sleep plan owner が code 上で固定される。
  - _Requirements: 5_
  - _Boundary: src/loop_outside_control/post_run_committer.*, src/loop_outside_control/sleep_planner.*_
  - _Depends: 1.2, 1.3_

- [ ] 1.6 `LoopOutsideController` の orchestration path を実装する
  - `runCycle()` で `config -> state -> time -> decision -> runLoop if allowed -> commit -> report -> sleep` の順を実装する。
  - `LoopEntryDecision` と config から `LoopInput` を組み立てて `watering-loop` を呼ぶ。
  - `LoopOutcome` を `FinalStatus` と `SleepPlan` に束ねて `CycleResult` を返す。
  - 観測条件: `loop entry -> loop outcome -> final status` の chain が 1 か所に閉じる。
  - _Requirements: 3, 4, 5_
  - _Boundary: src/loop_outside_control/loop_outside_controller.*_
  - _Depends: 1.2, 1.3, 1.4, 1.5, iot-arduino-watering-loop 1.5_

- [ ] 1.7 loop outside control smoke test を整備する
  - `no-run (time unavailable)`、`no-run (already watered)`、`timeout stop with commit`、`telemetry warning non-blocking` の最小 smoke を追加する。
  - `watering-loop` は real runner または narrow fake contract で差し替え可能にする。
  - 観測条件: controller-level branch routing と post-run commit rule が tasks gate 前に確認できる。
  - _Requirements: 2, 3, 4, 5_
  - _Boundary: loop outside control smoke tests_
  - _Depends: 1.3, 1.4, 1.5, 1.6, iot-arduino-watering-loop 1.6_
