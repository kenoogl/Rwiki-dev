# iot-arduino implementation phase second snapshot

_作成: 2026-05-12_  
_status: snapshot fixed v0.2_  
_purpose: first batch の refinement 後に切った second implementation snapshot を固定する_

---

## 1. Role

この文書は、`iot-arduino` の second acquisition に入れる implementation snapshot を固定する。

ここで固定するのは次である。

1. second snapshot root
2. first batch 後に変えた owner-visible boundary
3. まだ caveat として残す未完了部分
4. second acquisition が first batch baseline と何を比較するか

---

## 2. Snapshot Root

- implementation workspace:
  - `/Users/Daily/Development/DR-IoT`
- snapshot root:
  - `/Users/Daily/Development/DR-IoT/src`
- source provenance:
  - approved `requirements / design / tasks`
  - first acquisition findings
  - [iot-arduino-implementation-refinement-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-refinement-plan.md:1)

---

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

---

## 4. Fixed Snapshot Reading

この snapshot で読ませたいことは次である。

- `TimeSyncGateway` が success path と `network_unavailable / time_unavailable` path を両方持つこと
- `StateStore` が no-op ではなく、stub でも persistence boundary を持つこと
- `LoopOutsideController` が retryable no-run と post-run commit の境界を明示していること
- `WateringLoopRunner` が relay finalization を 1 つの path に寄せていること
- telemetry failure が watering completion を覆さず、`TelemetryWarning` に残ること

---

## 5. Known Incompleteness

この snapshot でも、次はまだ本実装ではない。

- real WiFi / NTP sync
- real EEPROM / RTC memory integration
- real OLED / Blynk publish
- real ISR-driven pulse input
- board-specific deep sleep entry

ただし first snapshot と違い、second snapshot では
`restart boundary / relay fail-safe / telemetry warning boundary`
の code seam は explicit になっている。

---

## 6. Comparison Intent

second acquisition では、first batch の `2 / 3 / 3` を baseline として次を見る。

1. `restart boundary` が implementation-local hardening としてどう読まれるか
2. `relay fail-safe` が still high-risk か、それとも boundary clarified と読まれるか
3. `telemetry caveat` が warning-preserving caveat に収まるか

---

## 7. Exclusions

second acquisition の主対象にしないもの:

- WiFi credential provisioning
- board-specific pin retuning
- hardware calibration
- deployment enclosure / wiring details
