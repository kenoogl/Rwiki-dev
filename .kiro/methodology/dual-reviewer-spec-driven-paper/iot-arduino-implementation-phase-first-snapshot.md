# iot-arduino implementation phase first snapshot

_作成: 2026-05-12_  
_status: snapshot fixed v0.1_  
_purpose: `iot-arduino` の first implementation snapshot を review acquisition boundary 用に固定する_

---

## 1. Role

この文書は、`iot-arduino` の implementation source tree のうち、
review acquisition に入れる first snapshot を固定するための snapshot note である。

ここで固定するのは、

1. snapshot root
2. included file set
3. owner boundary が見える最小 source tree
4. snapshot の未完了部分

である。

この文書は source of truth ではなく、
source tree の current cut を参照可能にするための boundary note である。

## 2. Snapshot Root

- implementation workspace:
  - `/Users/Daily/Development/DR-IoT`
- snapshot root:
  - `/Users/Daily/Development/DR-IoT/src`
- source provenance:
  - approved `requirements / design / tasks` から起こした fresh spec-origin source tree

## 3. Included File Set

### 3.1 Top-Level Entrypoint

- [irrigation_controller.ino](/Users/Daily/Development/DR-IoT/src/irrigation_controller.ino:1)

### 3.2 loop-outside-control owner files

- [controller_config.h](/Users/Daily/Development/DR-IoT/src/loop_outside_control/controller_config.h:1)
- [controller_config.cpp](/Users/Daily/Development/DR-IoT/src/loop_outside_control/controller_config.cpp:1)
- [state_store.h](/Users/Daily/Development/DR-IoT/src/loop_outside_control/state_store.h:1)
- [state_store.cpp](/Users/Daily/Development/DR-IoT/src/loop_outside_control/state_store.cpp:1)
- [time_sync_gateway.h](/Users/Daily/Development/DR-IoT/src/loop_outside_control/time_sync_gateway.h:1)
- [time_sync_gateway.cpp](/Users/Daily/Development/DR-IoT/src/loop_outside_control/time_sync_gateway.cpp:1)
- [eligibility_gate.h](/Users/Daily/Development/DR-IoT/src/loop_outside_control/eligibility_gate.h:1)
- [eligibility_gate.cpp](/Users/Daily/Development/DR-IoT/src/loop_outside_control/eligibility_gate.cpp:1)
- [status_reporter.h](/Users/Daily/Development/DR-IoT/src/loop_outside_control/status_reporter.h:1)
- [status_reporter.cpp](/Users/Daily/Development/DR-IoT/src/loop_outside_control/status_reporter.cpp:1)
- [post_run_committer.h](/Users/Daily/Development/DR-IoT/src/loop_outside_control/post_run_committer.h:1)
- [post_run_committer.cpp](/Users/Daily/Development/DR-IoT/src/loop_outside_control/post_run_committer.cpp:1)
- [sleep_planner.h](/Users/Daily/Development/DR-IoT/src/loop_outside_control/sleep_planner.h:1)
- [sleep_planner.cpp](/Users/Daily/Development/DR-IoT/src/loop_outside_control/sleep_planner.cpp:1)
- [loop_outside_controller.h](/Users/Daily/Development/DR-IoT/src/loop_outside_control/loop_outside_controller.h:1)
- [loop_outside_controller.cpp](/Users/Daily/Development/DR-IoT/src/loop_outside_control/loop_outside_controller.cpp:1)

### 3.3 watering-loop owner files

- [watering_loop.h](/Users/Daily/Development/DR-IoT/src/watering_loop/watering_loop.h:1)
- [watering_loop.cpp](/Users/Daily/Development/DR-IoT/src/watering_loop/watering_loop.cpp:1)
- [relay_driver.h](/Users/Daily/Development/DR-IoT/src/watering_loop/relay_driver.h:1)
- [relay_driver.cpp](/Users/Daily/Development/DR-IoT/src/watering_loop/relay_driver.cpp:1)
- [pulse_counter.h](/Users/Daily/Development/DR-IoT/src/watering_loop/pulse_counter.h:1)
- [pulse_counter.cpp](/Users/Daily/Development/DR-IoT/src/watering_loop/pulse_counter.cpp:1)
- [flow_accumulator.h](/Users/Daily/Development/DR-IoT/src/watering_loop/flow_accumulator.h:1)
- [flow_accumulator.cpp](/Users/Daily/Development/DR-IoT/src/watering_loop/flow_accumulator.cpp:1)
- [stop_condition_judge.h](/Users/Daily/Development/DR-IoT/src/watering_loop/stop_condition_judge.h:1)
- [stop_condition_judge.cpp](/Users/Daily/Development/DR-IoT/src/watering_loop/stop_condition_judge.cpp:1)

## 4. Fixed Snapshot Reading

この snapshot で読ませたいことは次である。

- `.ino` が thin entrypoint であること
- `loop-outside-control` が policy / orchestration owner であること
- `watering-loop` が execution owner であること
- `LoopEntryDecision -> LoopInput -> LoopOutcome -> FinalStatus / SleepPlan` の handoff chain
- EEPROM / time sync / telemetry / loop runner が stub であっても owner boundary が崩れていないこと

## 5. Known Incompleteness

この snapshot では、次はまだ未実装である。

- real WiFi / NTP sync
- EEPROM / RTC memory persistence
- real OLED / Blynk integration
- sampled period loop と ISR wiring
- hardware-specific deep sleep entry

したがって、この snapshot は
`hardware-ready implementation` ではなく
`reviewable first boundary snapshot`
として扱う。

## 6. Exclusions

review acquisition の主対象にしないもの:

- WiFi credential や Blynk token などの secret provisioning
- board-specific pin retuning
- calibration value tuning
- deployment enclosure や wiring 外形

