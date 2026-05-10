# Core Case: iot-arduino

_作成: 2026-05-10_  
_status: provisional core case v0.1_  
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
- requirements:
  - [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/requirements.md:1)
- canonical source:
  - `/Users/Daily/Development/DR-IoT/src/Irrigation.ino`

current note:

- intent と最小 requirements は fixed
- downstream design / tasks はこれから formalize する

---

## 3. Downstream Reference

- implementation source:
  - `/Users/Daily/Development/DR-IoT/src/Irrigation.ino`
- expected peripherals:
  - WiFi
  - NTP
  - EEPROM
  - OLED
  - Blynk
  - deep sleep

implementation-phase protocol は今後 fixed する。

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

この case は、現時点では provisional case である。

fixed core case に上げる条件:

1. `design / tasks` が固定される
2. `Spec Track` の concrete case が固定される
3. `Implementation Track` の protocol が固定される

main evidence に使うのは、Ruby 版 `dual-reviewer v1` で新たに取得する review artifact のみである。
