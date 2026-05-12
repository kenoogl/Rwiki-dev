# iot-arduino implementation refinement plan

_作成: 2026-05-12_  
_status: first-batch follow-up planned v0.1_  
_role: first implementation batch の finding を implementation-local work と second snapshot entry に変換する_

---

## 1. Source Boundary

この plan は、次の fixed artifact を入力として使う。

- acquisition summary:
  - [review-acquisition-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/review-acquisition-summary.md:1)
- paper evidence bundle:
  - [iot-arduino-c4-evidence-bundle.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-c4-evidence-bundle.md:1)
- canonical comparison summary:
  - [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F3-iot-arduino/comparison_summary.json:1)
- canonical implementation review note:
  - [implementation_review_note.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F3-iot-arduino/protocol-runs/F3-iot-arduino-dual/implementation_review_note.md:1)
- canonical downstream rework log:
  - [downstream_rework_log.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F3-iot-arduino/protocol-runs/F3-iot-arduino-dual/downstream_rework_log.yaml:1)

この時点では、`requirements / design / tasks` の meaning は変えない。  
まずは implementation-local refinement として閉じられるかを試す。

---

## 2. Refinement Queue

| id | origin finding | class | target | reopen default | second snapshot entry |
|---|---|---|---|---|---|
| `R1` | `restart boundary` | implementation hardening | `loop-outside-control` | `no` | required |
| `R2` | `relay fail-safe` | implementation hardening | `watering-loop` | `no` | required |
| `R3` | `telemetry caveat` | caveat-preserving clarification | `loop-outside-control` | `no` | required |

---

## 3. Refinement Tasks

### R1. restart-boundary hardening

- source finding:
  - `review_case.json#step-01-finding-restart-boundary`
- current reading:
  - upstream contract は `EEPROM state + time re-sync + no-run fallback` を要求している
  - first snapshot では [time_sync_gateway.cpp](/Users/Daily/Development/DR-IoT/src/loop_outside_control/time_sync_gateway.cpp:1) が常に `time_unavailable` を返すため、restart 後の positive path が未実装である
- target files:
  - [time_sync_gateway.cpp](/Users/Daily/Development/DR-IoT/src/loop_outside_control/time_sync_gateway.cpp:1)
  - [eligibility_gate.cpp](/Users/Daily/Development/DR-IoT/src/loop_outside_control/eligibility_gate.cpp:1)
  - [post_run_committer.cpp](/Users/Daily/Development/DR-IoT/src/loop_outside_control/post_run_committer.cpp:1)
  - [loop_outside_controller.cpp](/Users/Daily/Development/DR-IoT/src/loop_outside_control/loop_outside_controller.cpp:1)
- done when:
  - time sync success path と failure path の両方が code 上で読める
  - `full power loss + no valid time` は明示的に `no-run` に倒れる
  - post-run commit は valid time context の下でのみ same-day duplicate prevention 情報を前進させる
- reopen trigger:
  - `time unavailable` でも run したい、または別 fallback policy を導入したい場合は `requirements` reopen

### R2. relay fail-safe hardening

- source finding:
  - `review_case.json#step-01-finding-stop-failsafe`
- current reading:
  - upstream contract は `threshold / timeout / abnormal exit` の全経路で relay OFF を要求している
  - first snapshot では [watering_loop.cpp](/Users/Daily/Development/DR-IoT/src/watering_loop/watering_loop.cpp:1) が stub 1 経路で `turnOff()` しているだけで、loop finalization が contract 化されていない
- target files:
  - [watering_loop.cpp](/Users/Daily/Development/DR-IoT/src/watering_loop/watering_loop.cpp:1)
  - [watering_loop.h](/Users/Daily/Development/DR-IoT/src/watering_loop/watering_loop.h:1)
  - [relay_driver.cpp](/Users/Daily/Development/DR-IoT/src/watering_loop/relay_driver.cpp:1)
  - [stop_condition_judge.h](/Users/Daily/Development/DR-IoT/src/watering_loop/stop_condition_judge.h:1)
- done when:
  - relay OFF が single finalization path として読める
  - abnormal exit でも `wateringCompleted = false` と `relayOffConfirmed = true` が両立する
  - `shouldRun = false` 側から loop runner を呼ばない境界が崩れていない
- reopen trigger:
  - stop reason taxonomy や watering completion semantics を upstream で変更したい場合は `design` reopen

### R3. telemetry caveat clarification

- source finding:
  - `review_case.json#step-02-finding-telemetry-caveat`
- current reading:
  - upstream policy は telemetry non-blocking を許す
  - first snapshot では [status_reporter.cpp](/Users/Daily/Development/DR-IoT/src/loop_outside_control/status_reporter.cpp:1) が warning-only stub で、non-blocking の表現が最小限に留まっている
- target files:
  - [status_reporter.cpp](/Users/Daily/Development/DR-IoT/src/loop_outside_control/status_reporter.cpp:1)
  - [status_reporter.h](/Users/Daily/Development/DR-IoT/src/loop_outside_control/status_reporter.h:1)
  - [loop_outside_controller.cpp](/Users/Daily/Development/DR-IoT/src/loop_outside_control/loop_outside_controller.cpp:1)
  - [loop_outside_controller.h](/Users/Daily/Development/DR-IoT/src/loop_outside_control/loop_outside_controller.h:1)
- done when:
  - telemetry publish failure が `TelemetryWarning` として明示的に返る
  - watering completion / stop reason の primary status が telemetry failure によって覆らない
  - real cloud/OLED 実装がまだ stub でも、non-blocking caveat が second snapshot note に残る
- reopen trigger:
  - telemetry failure を blocking に変えたい場合は `requirements` reopen

---

## 4. Second Snapshot Entry Rule

second snapshot を切ってよい条件は次である。

1. `R1` と `R2` が code 上で完了している  
2. `R3` は fully implemented でなくてもよいが、warning-return boundary が明示されている  
3. upstream reopen が open になっていない  
4. [iot-arduino-implementation-phase-first-snapshot.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-first-snapshot.md:1) の後継 snapshot ref を新たに固定できる  
5. second acquisition では first batch `2 / 3 / 3` を baseline として比較できる

---

## 5. Out of Scope

この refinement plan では、まだ次を扱わない。

- persisted setting の導入
- real credential provisioning
- hardware calibration tuning
- OLED / Blynk の UX polish
- phase-level reopen を先に前提とする policy 変更

---

## 6. Operational Reading

今回の 3 finding は、現時点ではすべて implementation-local work として扱う。  
ただし `telemetry blocking 化` や `time unavailable でも run 継続` のような policy change が必要になれば、その時点で `requirements / design` reopen に切り替える。
