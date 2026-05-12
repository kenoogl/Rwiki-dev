# iot-arduino review acquisition preparation

_作成: 2026-05-12_  
_status: review acquisition gate input v0.1_  
_purpose: `iot-arduino` の review acquisition gate 前に、implementation boundary と upstream approved input を固定する_

---

## 1. この文書の役割

この文書は、`iot-arduino` の `requirements / design / tasks` 承認後に、
review acquisition へ入る前の入力境界を固定する preparation memo である。

ここで固定するのは次の 4 点である。

1. implementation target statement
2. upstream approved spec set
3. implementation snapshot / review acquisition boundary
4. validation / conformance entrypoint

この文書は human `review acquisition gate` の判断材料であり、
coding phase の完成承認そのものではない。

## 2. Implementation Target Statement

- case id:
  - `C-4-iot-arduino`
- implementation target label:
  - `iot-arduino-c`
- current implementation role:
  - spec-origin `iot-arduino` first snapshot の review acquisition boundary 固定
- operational interpretation:
  - 今回の review acquisition gate は、Arduino source tree の完成承認ではない
  - approved `requirements / design / tasks` を upstream input とし、fresh source tree を review acquisition target に結び直すための gate である

この case で review acquisition に入る意味は、
`tasks` で固定した implementation order と owner boundary を
implementation review acquisition に接続できるかを検証することにある。

## 3. Fixed Upstream Approved Spec Set

review acquisition gate input に含める upstream approved spec は次で固定する。

### 3.1 Umbrella Inputs

- [intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/intent.md:1)
- `/Users/Daily/Development/DR-IoT/intent.md`
- `/Users/Daily/Development/DR-IoT/仕様.md`

### 3.2 Approved Requirements

- [loop-outside-control/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/requirements.md:1)
- [watering-loop/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-watering-loop/requirements.md:1)

### 3.3 Approved Design

- [loop-outside-control/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/design.md:1)
- [watering-loop/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-watering-loop/design.md:1)

### 3.4 Approved Tasks

- [loop-outside-control/tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/tasks.md:1)
- [watering-loop/tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-watering-loop/tasks.md:1)

## 4. Fixed Implementation Snapshot and Review Boundary

### 4.1 Snapshot Ref

- implementation snapshot ref:
  - [iot-arduino-implementation-phase-first-snapshot.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-first-snapshot.md:1)
- implementation protocol ref:
  - [iot-arduino-implementation-phase-protocol.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-protocol.md:1)
- run template ref:
  - [implementation-track-run-template.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/implementation-track-run-template.md:1)

### 4.2 Review Boundary

implementation review acquisition の主対象に含めるもの:

- thin entrypoint と policy / execution owner の分離
- `LoopEntryDecision -> LoopInput -> LoopOutcome -> FinalStatus` の handoff chain
- time sync, persistence, telemetry, sleep planning, loop runner の stub path
- implementation-local issue と upstream spec issue の切り分け
- embedded / event-driven control code としての timing, I/O, fail-safe, caveat retention

implementation review acquisition の主対象にしないもの:

- real WiFi credential / Blynk token 設定
- board-specific wiring 調整
- pulse calibration 定数の tuning
- remote configuration の将来拡張
- cosmetic-only concern

### 4.3 Clean-Room or Provenance Constraint

- canonical source:
  - `/Users/Daily/Development/DR-IoT/intent.md`
  - `/Users/Daily/Development/DR-IoT/仕様.md`
- provenance rule:
  - current implementation snapshot は approved upstream spec から新規に起こした spec-origin tree とする
  - prior external implementation を review evidence に混ぜない

## 5. Implementation Order and Shared Artifact Rule

approved `tasks` から implementation order を次で固定する。

1. `loop-outside-control` helper skeleton
2. `watering-loop` public contract と execution skeleton
3. `LoopOutsideController` integration
4. `irrigation_controller.ino` thin entrypoint

parallel / handoff rule:

- `loop-outside-control` helper files と `watering-loop` public contract は並行着手可能
- `LoopOutsideController` integration は helper / contract が見えた後に進む
- `.ino` wiring は最後に固定する

shared file owner:

- `src/irrigation_controller.ino`: `loop-outside-control`
- `src/loop_outside_control/*`: `loop-outside-control`
- `src/watering_loop/*`: `watering-loop`
- `LoopInput / LoopOutcome`: `watering-loop`
- `FinalStatus / SleepPlan / CycleResult`: `loop-outside-control`

shared allocator owner:

- none
- この case では shared memory allocator を別 owner に分けない

## 6. Validation and Conformance Entry Points

review acquisition で最初に使う validation entrypoint は次で固定する。

1. feature-local smoke targets
   - `loop-outside-control`: `time unavailable no-run`, `already watered no-run`, `telemetry warning non-blocking`
   - `watering-loop`: `threshold stop`, `timeout stop`, `relayOffConfirmed`
2. top-level smoke target
   - `irrigation_controller.ino` -> `LoopOutsideController::runCycle()` wiring path
3. review acquisition modes
   - `single review`
   - `dual review`
   - `dual+judgment`

conformance review で見ること:

- implementation issue と upstream spec issue を混同していないか
- operational caveat / disagreement が残っているか
- reopen が必要なら target reopen phase を切り分けられるか

## 7. Operational Caveat

この preparation で固定するのは review acquisition boundary であり、
まだ hardware integration や compile verification は完了していない。

したがって、今回の review acquisition gate は

- `source tree ready for review acquisition` の承認であり
- `device-ready implementation` の承認ではない

として読む。

## 8. Preparation Conclusion

この時点で fixed とみなすもの:

- upstream approved spec set
- implementation snapshot ref
- review inclusion / exclusion boundary
- implementation order
- shared file owner
- validation / conformance entrypoint

次の action:

- human `review acquisition gate` の decision を取る
- approve 後、implementation review acquisition artifact 取得へ進む

