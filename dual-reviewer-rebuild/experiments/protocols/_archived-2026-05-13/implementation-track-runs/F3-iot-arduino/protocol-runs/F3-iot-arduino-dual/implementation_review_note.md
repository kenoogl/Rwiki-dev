  # implementation review note

  ## 1. run scope

  - run label: `F3-iot-arduino-dual`
  - case id: `F3-iot-arduino`
  - track: `implementation`
  - review mode: `dual_reviewer_workflow`
  - runtime review mode: `runtime_mediated`
  - treatment: `dual+judgment`
  - operator: `iot-arduino-gate-approved`
  - implementation snapshot ref:
    - `.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-first-snapshot.md`
  - case manifest ref:
    - `experiments/protocols/case_manifests/F3-iot-arduino.yaml`
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
    - `experiments/protocols/implementation-track-runs/F3-iot-arduino/runtime-runs/run-20260512T013548Z-4f530012/review_case.json`
  - decision units:
    - `experiments/protocols/implementation-track-runs/F3-iot-arduino/runtime-runs/run-20260512T013548Z-4f530012/decisions/decision_units.json`

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
  - upstream refs:
    - `.kiro/specs/iot-arduino-loop-outside-control/requirements.md:51`
    - `.kiro/specs/iot-arduino-loop-outside-control/requirements.md:52`
  - implementation-local reading:
    - `TimeSyncGateway` が常に `time_unavailable` を返す stub のため、restart 後の positive path と post-run persistence boundary を second snapshot で明示する必要がある。
  - disposition:
    - `implementation-local refinement planned`

  ### 3.2 relay fail-safe

  - finding id:
    - `step-01-finding-stop-failsafe`
  - severity:
    - `high`
  - source role:
    - `primary_reviewer`
  - summary:
    - `Relay shutdown safety is review-critical because every threshold, timeout, or abnormal exit path must converge on a reliable relay-off contract.`
  - upstream refs:
    - `.kiro/specs/iot-arduino-watering-loop/requirements.md:34`
    - `.kiro/specs/iot-arduino-watering-loop/requirements.md:35`
    - `.kiro/specs/iot-arduino-watering-loop/requirements.md:36`
  - implementation-local reading:
    - current snapshot は stub loop の 1 経路で `turnOff()` しているだけで、abnormal exit を含む finalization contract がまだ code の中心構造になっていない。
  - disposition:
    - `implementation-local refinement planned`

  ### 3.3 telemetry caveat

  - finding id:
    - `step-02-finding-telemetry-caveat`
  - severity:
    - `medium`
  - source role:
    - `adversarial_reviewer`
  - summary:
    - `Telemetry policy remains adversarially review-worthy because the upstream rule is intentionally non-blocking while the first snapshot still relies on observability stubs and warning-only handling.`
  - upstream refs:
    - `.kiro/specs/iot-arduino-loop-outside-control/requirements.md`
    - `.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-first-snapshot.md`
  - implementation-local reading:
    - non-blocking policy 自体は維持するが、second snapshot では telemetry warning return path を明示し、watering status と telemetry caveat を分離して読める状態にする。
  - disposition:
    - `caveat-preserving refinement planned`

  ### 3.4 linked planning artifact

  - refinement plan:
    - `.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-refinement-plan.md`
  - downstream rework log:
    - `experiments/protocols/implementation-track-runs/F3-iot-arduino/protocol-runs/F3-iot-arduino-dual/downstream_rework_log.yaml`

  ## 4. reopen assessment

  - reopen required:
    - `false`
  - target reopen phases:
    - `none at current reading`
  - caveats:
    - `telemetry failure を blocking に変える場合は requirements reopen`
    - `time unavailable でも run する fallback を導入する場合は requirements reopen`
    - `stop reason taxonomy を upstream meaning ごと変える場合は design reopen`
