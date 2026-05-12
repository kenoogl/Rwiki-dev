# implementation evidence summary

> derived artifact only. source of truth remains the implementation files under `/Users/Daily/Development/DR-IoT`, implementation snapshot notes, runtime batch outputs, and workflow trace.

_作成: 2026-05-12_  
_status: second acquisition completed v0.1_

## 1. scope

- implementation workspace:
  - `/Users/Daily/Development/DR-IoT`
- first snapshot:
  - [iot-arduino-implementation-phase-first-snapshot.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-first-snapshot.md:1)
- second snapshot:
  - [iot-arduino-implementation-phase-second-snapshot.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-second-snapshot.md:1)
- refinement plan:
  - [iot-arduino-implementation-refinement-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-refinement-plan.md:1)

## 2. implementation-local rework

| seq | class | target | issue | disposition |
|---|---|---|---|---|
| 1 | `restart boundary` | `loop-outside-control` | `StateStore` が no-op で、`TimeSyncGateway` に success path がなかった | fixed in second snapshot |
| 2 | `relay fail-safe` | `watering-loop` | relay OFF が stub 1 経路にしか現れず、single finalization contract になっていなかった | fixed in second snapshot |
| 3 | `telemetry boundary` | `loop-outside-control` | telemetry non-blocking policy が warning-return contract として明示されていなかった | clarified in second snapshot |

## 3. acquisition comparison

| batch | scope | single | dual | dual+judgment | validation |
|---|---|---:|---:|---:|---|
| `F3-iot-arduino` | first snapshot | `2` | `3` | `3` | all passed |
| `F3-iot-arduino-r2` | second snapshot | `2` | `3` | `3` | all passed |

refs:

- first batch:
  - [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F3-iot-arduino/comparison_summary.json:1)
- second batch:
  - [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F3-iot-arduino-r2/comparison_summary.json:1)

## 4. operational reading

- second snapshot でも `2 / 3 / 3` は維持された
- これは refinement が無効だったというより、`restart boundary` と `relay fail-safe` が upstream safety contract に強く結びついており、review signal として残り続けることを示している
- `telemetry caveat` も消えていないが、second snapshot では `warning-return boundary` を明示した上で preserved caveat として残っている
- したがって、この case では implementation-local refinement 後も finding count は単純には減らず、むしろ caveat retention と safety-sensitive contract persistence が安定している

## 5. counted observations

- `implementation_refinement_item_count: 3`
- `implementation_reopen_required_count: 0`
- `first_batch_total_findings: 3`
- `second_batch_total_findings: 3`
- `finding_count_delta_after_refinement: 0`
- `telemetry_caveat_retained_after_refinement: true`

## 6. residual gap

- real WiFi / NTP
- real EEPROM / RTC memory integration
- real OLED / Blynk publish
- real ISR-driven pulse input
- hardware-specific deep sleep entry

## 7. operational conclusion

今回の implementation-local refinement では、`requirements / design / tasks` への reopen は発生しなかった。  
second snapshot の取得により、`iot-arduino` は `first snapshot baseline -> implementation-local hardening -> second acquisition` の loop を一度回したが、finding count は `2 / 3 / 3` のまま維持された。  
この case で主に残った signal は、欠落 bug というより safety-sensitive upstream contract と preserved caveat である。
