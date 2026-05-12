# iot-arduino active worklist

_status: case decision fixed / closed_  
_purpose: `iot-arduino` case の current control board_

---

## 1. Role

この文書は workflow 正本ではない。  
この文書の役割は、**今この case で何を実行中か**を固定することに限る。

## 2. Authoritative Refs

- workflow:
  - [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:1)
- case manifest:
  - [dual-reviewer-spec-driven-case-manifest.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-case-manifest.md:1)
- core case:
  - [core-case-iot-arduino.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-iot-arduino.md:1)
- state:
  - [spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/spec.json:1)

## 3. Current Workflow Step

- current phase:
  - `case closure`
- current artifact type:
  - `supporting-case decision`
- current target set:
  - `paper role and non-claim boundary`

## 4. Current Blocker

- blocker:
  - `none`

## 5. Current Action

- action:
  - `iot-arduino` を snapshot-based supporting case として閉じる判断を正本化する

## 6. Exit Condition

- exit:
  - case の role, claim support, non-claim boundary が decision note に固定されていること

## 7. Working Artifacts

- primary:
  - [review acquisition summary](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/review-acquisition-summary.md:1)
  - [iot-arduino-c4-evidence-bundle.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-c4-evidence-bundle.md:1)
  - [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F3-iot-arduino/comparison_summary.json:1)
  - [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F3-iot-arduino-r2/comparison_summary.json:1)
  - [iot-arduino-implementation-refinement-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-refinement-plan.md:1)
  - [implementation review note](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F3-iot-arduino/protocol-runs/F3-iot-arduino-dual/implementation_review_note.md:1)
  - [downstream rework log](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F3-iot-arduino/protocol-runs/F3-iot-arduino-dual/downstream_rework_log.yaml:1)
  - [implementation evidence summary](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/implementation-evidence-summary.md:1)
  - [iot-arduino-case-decision.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-case-decision.md:1)
  - [review acquisition gate summary](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/review-acquisition-gate-summary.md:1)
  - [iot-arduino-case-workflow-overlay.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-case-workflow-overlay.md:1)
- supporting:
  - [iot-arduino-review-acquisition-preparation.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-review-acquisition-preparation.md:1)
  - [iot-arduino-implementation-phase-first-snapshot.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-first-snapshot.md:1)
  - [tasks evidence summary](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/tasks-evidence-summary.md:1)
  - [tasks review wave](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/tasks-review-wave-2026-05-12.md:1)
  - [tasks alignment gate](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/tasks-alignment-2026-05-12.md:1)
  - [loop-outside-control tasks](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/tasks.md:1)
  - [watering-loop tasks](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-watering-loop/tasks.md:1)
  - [loop-outside-control design](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/design.md:1)
  - [watering-loop design](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-watering-loop/design.md:1)
  - [loop-outside-control requirements](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/requirements.md:1)
  - [watering-loop requirements](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-watering-loop/requirements.md:1)
  - `/Users/Daily/Development/DR-IoT/intent.md`
  - `/Users/Daily/Development/DR-IoT/仕様.md`

## 8. Stop Rules

- stop if:
  - canonical source interpretation forks
  - active feature split changes the case scope
  - gate closure basis is missing
  - reopen responsibility belongs to human
  - snapshot include / exclude boundary が割れる
  - implementation source tree が gate 中に変わり、snapshot ref を維持できない

## 9. Instance Notes

- special case caveat:
  - cloud telemetry と display は value が高いが、watering safety より優先しない
- requirements wave default:
  - persisted setting は今回の scope 外とし、compile-time configuration を前提に requirements を固定した
- requirements gate focal points:
  - telemetry failure の non-blocking 扱い
  - full power loss 後の duplicate prevention 境界
  - persistence commit owner を `loop-outside-control` に置く分割
- gate result:
  - `requirements approved`
- design gate focal points:
  - `loop entry -> loop outcome -> final status` の handoff chain
  - thin entrypoint と policy owner の分離
  - file / module placement が tasks に渡せるか
- gate result:
  - `design approved`
- tasks gate focal points:
  - implementation order が自然か
  - shared file owner / contract owner が自然か
  - feature-local smoke と controller smoke の順序が自然か
- gate result:
  - `tasks approved`
- implementation entry result:
  - `implementation source tree created`
- current gate focal points:
  - `restart boundary` を implementation-local hardening で閉じられるか
  - `relay fail-safe` を loop finalization contract として code に落とせるか
  - `telemetry caveat` を policy 不変更のまま warning boundary として明示できるか
- closure result:
  - `snapshot-based supporting case`
  - `stable safety finding / preserved caveat reading fixed`
  - `no further rerun planned under current boundary`
- dependency order:
  - `loop outside control -> watering loop`
- active feature set:
  - `loop-outside-control`
  - `watering-loop`
