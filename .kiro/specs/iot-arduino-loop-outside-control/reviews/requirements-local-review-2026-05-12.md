# 2026-05-12 iot-arduino-loop-outside-control requirements local review

## 1. review scope

- review type: `requirements local review`
- reviewed feature: `iot-arduino-loop-outside-control`
- reviewed artifact:
  - [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/requirements.md:1)
- review focus:
  - ループ外の責務を 1 feature にまとめても意味が崩れていないか
  - duplicate prevention と restart 境界が読み取れるか
  - telemetry policy と post-run persistence owner が requirements 上で閉じているか

## 2. findings

### Finding 1

- title: full power loss 後の duplicate prevention line was not explicit enough
- references:
  - [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/requirements.md:40)
- description:
  - 初稿では restart 境界をまとめたが、full power loss 後は successful time sync を前提に再判定し、時刻が無ければ `no-run` に倒すことが読み取りにくかった。
- impact:
  - duplicate prevention の安全側方針が弱く見えた。
- recommended action:
  - `current time が利用できない場合は no-run` を明記する。
- status: `fixed`

### Finding 2

- title: telemetry policy and persistence commit owner needed stronger wording
- references:
  - [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/requirements.md:58)
  - [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/requirements.md:67)
- description:
  - 初稿では telemetry failure の non-blocking 性と、timeout 停止後も post-run persistence commit を行うことがやや埋もれていた。
- impact:
  - human gate で `telemetry blocks irrigation?` `timeout run counts as watering?` の疑義が残る余地があった。
- recommended action:
  - telemetry warning は watering safety を block しないこと、timeout 停止でも commit 対象であることを requirements に強く書く。
- status: `fixed`

## 3. metric snapshot

- `phase_blocking_issue_count`: `2`
- `phase_major_correction_count`: `1`
- `phase_intent_attributed_issue_count`: `2`

## 4. disposition summary

- immediate disposition:
  - restart 境界、telemetry policy、post-run commit owner を補強し、feature-local blocking issue を解消した。
- downstream implication:
  - `watering-loop` は loop 内処理に専念でき、loop 外の policy は本 feature を正本にできる。
- next action:
  - `iot-arduino-watering-loop` の requirements local review と phase-level review wave を進める。
