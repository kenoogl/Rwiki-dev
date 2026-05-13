# Core Case: iot-arduino

_作成: 2026-05-10_  
_status: snapshot-based supporting case / closed v0.1_  
_role: event-driven IoT control representative case_

---

## 1. Case Identity

- case id: `C-4-iot-arduino`
- label: `iot-arduino`
- domain: embedded / event-driven IoT control
- primary language:
  - C / Arduino

---

## 2. Canonical Upstream Inputs

- intent:
  - [iot-arduino-spec/intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/intent.md:1)
- external source docs:
  - `/Users/Daily/Development/DR-IoT/intent.md`
  - `/Users/Daily/Development/DR-IoT/仕様.md`

current note:

- repo 内 case artifact は再試行後の requirements wave まで再構成済み
- 現在の repo 内 upstream anchor は `intent.md` と active feature requirements 群である
- current state は [spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/spec.json:1) の `tasks-approved`
- first gate input は [2026-05-12-iot-arduino-intent-review.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/2026-05-12-iot-arduino-intent-review.md:1)
- current active feature set は `loop-outside-control` と `watering-loop` の 2 本である
- requirements gate package は [requirements evidence summary](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/requirements-evidence-summary.md:1) で承認済み
- design gate package は [design evidence summary](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/design-evidence-summary.md:1) で承認済み
- tasks gate package は [tasks evidence summary](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/tasks-evidence-summary.md:1) で承認済み
- implementation source tree は `/Users/Daily/Development/DR-IoT/src` に作成済みである
- current review acquisition package は [review acquisition gate summary](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/review-acquisition-gate-summary.md:1) と [iot-arduino-review-acquisition-preparation.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-review-acquisition-preparation.md:1) である
- first implementation acquisition summary は [review acquisition summary](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/review-acquisition-summary.md:1) である
- paper evidence bundle は [iot-arduino-c4-evidence-bundle.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-c4-evidence-bundle.md:1) である
- first-batch refinement plan は [iot-arduino-implementation-refinement-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-refinement-plan.md:1) である
- implementation comparison summary は [implementation-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/implementation-evidence-summary.md:1) である
- case decision は [iot-arduino-case-decision.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-case-decision.md:1) に固定した

---

## 3. Downstream Reference

- implementation workspace:
  - `/Users/Daily/Development/DR-IoT`
- implementation source:
  - [iot-arduino first snapshot](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-first-snapshot.md:1)
- expected peripherals:
  - WiFi
  - NTP
  - EEPROM
  - OLED
  - Blynk
  - deep sleep

implementation-phase protocol は [iot-arduino-implementation-phase-protocol.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-protocol.md:1) を current target-specific protocol ref とする。

---

## 4. Supported Tracks

- `Spec Track`
- `Implementation Track`

`Intent Track` の primary case ではない。

---

## 5. Paper Role

この case は次の claim を支える。

- `Claim 2`
  - event-driven control case で traceability / caveat retention を観測する
- `Claim 3`
  - `Spec-origin` と `Implementation-origin` の別ドメイン検証に使う
- `Claim 4`
  - control / telemetry / persistence artifact の再利用可能性を示す補助 case とする

---

## 6. Stress Characteristics

主な stress point:

1. schedule and interval logic
2. sensor interrupt handling
3. persistence across restart / deep sleep
4. network and time synchronization dependency
5. actuator stop conditions and fail-safe behavior

---

## 7. Operational Note

この case は、現時点では **snapshot-based supporting case として閉じた**。

決定内容:

1. `iot-arduino` は fixed core case に上げない
2. generalized first implementation case として保持する
3. `stable safety finding / preserved caveat` を示す supporting evidence に使う
4. hardware-ready adequacy claim には使わない

main evidence に使うのは、`dual-reviewer v2` で新たに取得した review artifact だけである。  
この case の role と非主張境界は [iot-arduino-case-decision.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-case-decision.md:1) を正本とする。
