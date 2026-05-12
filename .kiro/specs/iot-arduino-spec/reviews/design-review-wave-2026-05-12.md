# 2026-05-12 iot-arduino design review wave

## 1. review scope

- review type: `design review wave`
- reviewed features:
  - [iot-arduino-loop-outside-control/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/design.md:1)
  - [iot-arduino-watering-loop/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-watering-loop/design.md:1)
- review focus:
  - loop 外制御と loop 内実行の handoff object が一意に決まっているか
  - file / module placement が 2 feature split を保ったまま tasks に渡せるか
  - tasks phase で必要な concrete return contract が閉じているか

## 2. findings

### Finding 1

- title: `loop entry` and `loop outcome` contracts needed to be linked explicitly across the two designs
- references:
  - [iot-arduino-loop-outside-control/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/design.md:150)
  - [iot-arduino-watering-loop/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-watering-loop/design.md:141)
- description:
  - 両 feature とも individual contract は持っていたが、`LoopEntryDecision -> LoopInput -> LoopOutcome -> FinalStatus` の連鎖が review 観点で少し飛んで見えた。
- impact:
  - tasks phase で adapter 層の束ね方を場当たりで決める余地があった。
- recommended action:
  - `loop-outside-control` には `watering-loop` への input bridge を、`watering-loop` には loop outcome の downstream target を明示する。
- status: `fixed`

### Finding 2

- title: entrypoint ownership between `irrigation_controller.ino` and `LoopOutsideController` needed to be made explicit
- references:
  - [iot-arduino-loop-outside-control/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/design.md:79)
- description:
  - file structure は示されていたが、`irrigation_controller.ino` が thin entrypoint であり、policy owner は `LoopOutsideController` にあることをより明確にした方がよかった。
- impact:
  - tasks phase で `ino` に policy logic が漏れ出す余地があった。
- recommended action:
  - top-level entrypoint は `runCycle()` の呼び出しと sleep entry に限定することを design に明記する。
- status: `fixed`

## 3. metric snapshot

- `phase_blocking_issue_count`: `2`
- `phase_recheck_count`: `0`
- `phase_major_correction_count`: `2`
- `phase_intent_attributed_issue_count`: `0`

## 4. disposition summary

- immediate disposition:
  - handoff chain と thin entrypoint rule を design wording に反映し、wave-level blocking issue を解消した。
- downstream implication:
  - design alignment gate では owner boundary と tasks-level carry-over point の確認に集中できる。
- next action:
  - design alignment gate を実施し、human design gate input を固定する。
