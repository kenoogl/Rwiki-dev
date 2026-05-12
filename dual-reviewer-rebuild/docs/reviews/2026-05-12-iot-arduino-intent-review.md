# 2026-05-12 iot-arduino intent review

> historical note: この文書で提示した 6 feature split は 2026-05-12 requirements gate で `too fine-grained` と判断され、current active feature set は 2 feature 版へ再構成された。current gate input は [requirements-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/requirements-evidence-summary.md:1) を参照。

## 1. review scope

- review type: `intent review`
- reviewed intent documents:
  - `/Users/Daily/Development/DR-IoT/intent.md`
  - `/Users/Daily/Development/DR-IoT/仕様.md`
  - [intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/intent.md:1)
- reviewed traceability documents:
  - none at this stage
- review focus:
  - `intent` と `仕様` から active feature set を自然に引けるか
  - requirements wave に入る前に scope ambiguity がどこにあるか
  - embedded / event-driven case として human gate の単位をどこで切るか

## 2. current understanding

- この case の最優先価値は `時刻で起きて、水量で止まる装置` を安全に成立させることである
- safety と correctness の中心は `same-day duplicate prevention`, `interval check`, `flow accumulation`, `timeout stop` にある
- `OLED` と `Blynk` は重要だが、灌水の成立条件よりは下位の observability 責務として切り出せる
- current implementation source tree は未作成なので、今は `intent -> feature decomposition -> requirements wave` を正規順序で始めるのが適切である

## 3. proposed active feature set

### Feature 1: `iot-arduino-settings-and-state`

- 設定値の所在
- EEPROM / RTC memory の保持項目
- runtime state struct
- hardware pin / peripheral dependency boundary

### Feature 2: `iot-arduino-network-time`

- WiFi 接続
- NTP 同期
- retry / backoff / sleep fallback
- time normalization

### Feature 3: `iot-arduino-irrigation-eligibility`

- target time window 判定
- interval day 判定
- same-day duplicate prevention
- run/no-run decision contract

### Feature 4: `iot-arduino-watering-loop`

- relay on/off
- pulse counting
- instantaneous flow calculation
- cumulative irrigation calculation
- timeout stop and forced stop

### Feature 5: `iot-arduino-observability-and-sleep`

- OLED rendering
- Blynk telemetry
- final status update
- next sleep seconds calculation
- deep sleep entry

### Feature 6: `iot-arduino-main-orchestrator`

- boot sequence
- feature call order
- branch routing
- post-run handoff

## 4. dependency order

1. `iot-arduino-settings-and-state`
2. `iot-arduino-network-time`
3. `iot-arduino-irrigation-eligibility`
4. `iot-arduino-watering-loop`
5. `iot-arduino-observability-and-sleep`
6. `iot-arduino-main-orchestrator`

理由:

- 設定値と保持状態が固まらないと、後続 feature の boundary が曖昧なままになる
- eligibility は network/time と state を前提にする
- watering loop は eligibility の run contract がないと stop/start の意味が定まらない
- observability と sleep は loop の outcome を受ける downstream として切ると見通しがよい
- orchestrator は最後に全 feature を接続する

## 5. findings and open questions

### Finding 1

- title:
  - cloud telemetry failure の扱いが未確定
- references:
  - `/Users/Daily/Development/DR-IoT/仕様.md`
- description:
  - 仕様は Blynk 送信を含むが、送信失敗時に灌水そのものを止めるのか、non-blocking degradation とみなすのかが明示されていない
- impact:
  - `network-time` と `observability-and-sleep` の責務境界に影響する
- recommended action:
  - requirements wave では `telemetry failure is non-blocking unless user explicitly overrides` を仮置きし、人間が gate で採否を決める
- handback assessment: `D`
- status:
  - `open`

### Finding 2

- title:
  - 完全電源断後の duplicate prevention guarantee が曖昧
- references:
  - `/Users/Daily/Development/DR-IoT/仕様.md`
- description:
  - RTC memory は完全電源断で消える一方、「二度やりしない」をどこまで保証するかが境界としてまだ粗い
- impact:
  - `settings-and-state` と `irrigation-eligibility` の acceptance line に影響する
- recommended action:
  - requirements wave で `deep sleep restart` と `full power loss restart` を別条件として書き分ける
- handback assessment: `D`
- status:
  - `open`

### Finding 3

- title:
  - setting の保存境界が未確定
- references:
  - `/Users/Daily/Development/DR-IoT/intent.md`
  - `/Users/Daily/Development/DR-IoT/仕様.md`
- description:
  - 時刻、水量、間隔、固定IP、CF などの設定項目が compile-time constant なのか、不揮発領域に置くのかが未確定
- impact:
  - `settings-and-state` の scope に直接影響する
- recommended action:
  - 初回 requirements wave では compile-time configuration を default とし、persisted configuration は scope 外に置く
- handback assessment: `D`
- status:
  - `open`

### Finding 4

- title:
  - implementation source tree 不在
- references:
  - [core-case-iot-arduino.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-iot-arduino.md:1)
- description:
  - 現在の canonical source は prose docs であり、implementation artifact はまだ存在しない
- impact:
  - review acquisition と implementation track は tasks gate の後まで開始できない
- recommended action:
  - 現段階では `Spec-origin` を先行し、implementation entry は tasks gate 後にのみ議論する
- handback assessment: `D`
- status:
  - `accepted as current boundary`

## 6. metric snapshot

- `intent_revision_count`: `0`
- `intent_handback_count`: `0`
- `intent_review_findings_count`: `4`
- `review_artifact_presence_rate`: `1.0`

## 7. disposition summary

- immediate disposition:
  - active feature set と dependency order を human gate input として提示する
- downstream implication:
  - approve されたら requirements wave は 6 feature の horizontal wave として開始する
- next action:
  - user が active feature set を approve / adjust した後、requirements wave に進む
