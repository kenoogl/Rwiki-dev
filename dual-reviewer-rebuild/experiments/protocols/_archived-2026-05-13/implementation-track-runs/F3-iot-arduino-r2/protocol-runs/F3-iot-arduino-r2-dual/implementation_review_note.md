  # implementation review note

  ## 1. run scope

  - run label: `F3-iot-arduino-r2-dual`
  - case id: `F3-iot-arduino-r2`
  - track: `implementation`
  - review mode: `dual_reviewer_workflow`
  - runtime review mode: `runtime_mediated`
  - treatment: `dual+judgment`
  - operator: `iot-arduino-refinement-r2`
  - implementation snapshot ref:
    - `.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-second-snapshot.md`
  - case manifest ref:
    - `experiments/protocols/case_manifests/F3-iot-arduino-r2.yaml`
  - upstream spec refs:
  - `.kiro/specs/iot-arduino-spec/intent.md`
  - `.kiro/specs/iot-arduino-loop-outside-control/requirements.md`
  - `.kiro/specs/iot-arduino-watering-loop/requirements.md`
  - `.kiro/specs/iot-arduino-loop-outside-control/design.md`
  - `.kiro/specs/iot-arduino-watering-loop/design.md`
  - `.kiro/specs/iot-arduino-loop-outside-control/tasks.md`
  - `.kiro/specs/iot-arduino-watering-loop/tasks.md`
  - `/Users/Daily/Development/DR-IoT/intent.md`
  - `/Users/Daily/Development/DR-IoT/仕様.md`

  ## 2. runtime artifact refs

  - review artifact:
    - `experiments/protocols/implementation-track-runs/F3-iot-arduino-r2/runtime-runs/run-20260512T084649Z-7c843863/review_case.json`
  - decision units:
    - `experiments/protocols/implementation-track-runs/F3-iot-arduino-r2/runtime-runs/run-20260512T084649Z-7c843863/decisions/decision_units.json`

  ## 3. findings

  ### 3.1 restart boundary

  - finding id:
    - `step-01-finding-restart-boundary`
  - severity:
    - `high`
  - source role:
    - `primary_reviewer`
  - summary:
    - `Restart and duplicate-prevention behavior are review-critical because the upstream contract explicitly ties power-loss recovery to EEPROM state, time re-sync, and a no-run fallback when time is unavailable.`
  - implementation-local reading:
    - second snapshot では `TimeSyncGateway` の success/failure seam と `StateStore` の stub persistence boundary を加えたが、review signal 自体は safety-critical contract として維持された。
  - disposition:
    - `carry as stable safety finding`

  ### 3.2 relay fail-safe

  - finding id:
    - `step-01-finding-stop-failsafe`
  - severity:
    - `high`
  - source role:
    - `primary_reviewer`
  - summary:
    - `Relay shutdown safety is review-critical because every threshold, timeout, or abnormal exit path must converge on a reliable relay-off contract.`
  - implementation-local reading:
    - second snapshot では single finalization path を入れたが、high-severity review signal としては残った。つまり fail-safe は clarified されても still review-critical である。
  - disposition:
    - `carry as stable safety finding`

  ### 3.3 telemetry caveat

  - finding id:
    - `step-02-finding-telemetry-caveat`
  - severity:
    - `medium`
  - source role:
    - `adversarial_reviewer`
  - summary:
    - `Telemetry policy remains adversarially review-worthy because the upstream rule is intentionally non-blocking while the second snapshot still preserves observability caveats.`
  - implementation-local reading:
    - second snapshot では `TelemetryWarning` return path を明示したが、real publish integration が未完のため caveat は意図どおり残っている。
  - disposition:
    - `preserved caveat`

  ### 3.4 comparison reading

  - first batch:
    - `2 / 3 / 3`
  - second batch:
    - `2 / 3 / 3`
  - interpretation:
    - finding count は減らなかったが、second snapshot では implementation seam が明示され、signal が `missing boundary` から `stable safety / caveat reading` に寄った。

  ## 4. reopen assessment

  - reopen required:
    - `false`
  - target reopen phases:
    - `none at current reading`
  - caveats:
    - `telemetry failure を blocking policy に変える場合は requirements reopen`
    - `restart fallback policy を no-run 以外へ変える場合は requirements reopen`
    - `watering completion semantics を timeout から切り離す場合は design reopen`
