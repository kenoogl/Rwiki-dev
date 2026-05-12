# 2026-05-12 iot-arduino-loop-outside-control design local review

## 1. review scope

- review type: `design local review`
- reviewed feature: `iot-arduino-loop-outside-control`
- reviewed artifact:
  - [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/design.md:1)
- review focus:
  - loop 外制御の内部 service seam が tasks に十分な concrete contract を持つか
  - persistence / telemetry / sleep planning の owner が設計上も割れていないか
  - `watering-loop` との handoff object が一意に読めるか

## 2. findings

### Finding 1

- title: top-level cycle return contract was underspecified
- references:
  - [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/design.md:112)
  - [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/design.md:202)
- description:
  - 初稿では `runCycle()` が final status と sleep plan を返すとだけ書かれており、tasks phase でどの bundle を top-level entry が受け取るかが弱かった。
- impact:
  - `irrigation_controller.ino` 側の受け取り contract を場当たりで決める余地があった。
- recommended action:
  - `CycleResult` を concrete struct として設計書に追加する。
- status: `fixed`

### Finding 2

- title: telemetry warning payload shape needed to be explicit
- references:
  - [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/design.md:181)
- description:
  - telemetry failure を non-blocking とする方針はあったが、warning payload の具体形が design 上で閉じていなかった。
- impact:
  - tasks phase で bool だけ返す実装と structured warning を返す実装が割れる余地があった。
- recommended action:
  - `TelemetryWarning` を concrete struct として明記する。
- status: `fixed`

## 3. metric snapshot

- `phase_blocking_issue_count`: `2`
- `phase_major_correction_count`: `1`
- `phase_intent_attributed_issue_count`: `0`

## 4. disposition summary

- immediate disposition:
  - top-level cycle result と telemetry warning payload を具体化し、feature-local blocking issue を解消した。
- downstream implication:
  - `watering-loop` review では loop outcome handoff と bundle composition の境界確認に集中できる。
- next action:
  - `iot-arduino-watering-loop` の design local review と phase-level design review wave を進める。
