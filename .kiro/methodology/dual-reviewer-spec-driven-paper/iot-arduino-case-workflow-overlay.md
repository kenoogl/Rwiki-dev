# iot-arduino case workflow overlay

_作成: 2026-05-12_  
_status: review acquisition completed v1.0_  
_purpose: `iot-arduino` を generic workflow に載せるための case 固有差分だけを固定する_

---

## 1. Role

この文書は `iot-arduino` 専用の全文 workflow ではない。  
generic procedure の正本は [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:1) とし、この overlay では case 固有差分だけを持つ。

## 2. Case Identity

- case id:
  - `C-4-iot-arduino`
- core note:
  - [core-case-iot-arduino.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-iot-arduino.md:1)
- canonical source:
  - `/Users/Daily/Development/DR-IoT/intent.md`
  - `/Users/Daily/Development/DR-IoT/仕様.md`
- umbrella state:
  - [spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/spec.json:1)

## 3. Active Feature Set

- active features:
  - `iot-arduino-loop-outside-control`
  - `iot-arduino-watering-loop`

## 4. Dependency Order

- order:
  1. `iot-arduino-loop-outside-control`
  2. `iot-arduino-watering-loop`

## 5. Approval Model

- human gates:
  - `intent`
  - `requirements`
  - `design`
  - `tasks`
  - `review acquisition`
- fixed input:
  - `intent`
  - `external source docs`

## 6. Special Stop Conditions

- stop when:
  - telemetry failure を irrigation blocker とみなすか non-blocking degradation とみなすかが未確定
  - 完全電源断後の same-day duplicate prevention をどこまで保証するかが未確定
  - compile-time setting と persisted setting の境界が曖昧
  - implementation source tree 不在のまま implementation-ready を仮定しようとしている

## 7. Optional Extensions

- uses review acquisition:
  - `yes`
- uses behavioral appendix boundary:
  - `no`

## 8. Primary Working Artifacts

- workflow trace:
  - [iot-arduino-workflow-path.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-workflow-path.md:1)
- current control board:
  - [iot-arduino-active-worklist.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-active-worklist.md:1)
- first gate input:
  - [2026-05-12-iot-arduino-intent-review.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/2026-05-12-iot-arduino-intent-review.md:1)
- current gate package:
  - [iot-arduino-c4-evidence-bundle.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-c4-evidence-bundle.md:1)
  - [review acquisition summary](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/review-acquisition-summary.md:1)
  - [review acquisition gate summary](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/review-acquisition-gate-summary.md:1)
  - [iot-arduino-review-acquisition-preparation.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-review-acquisition-preparation.md:1)
  - [iot-arduino-implementation-phase-first-snapshot.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-first-snapshot.md:1)
