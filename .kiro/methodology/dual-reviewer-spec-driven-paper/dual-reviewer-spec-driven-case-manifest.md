# dual-reviewer case manifest

_作成: 2026-05-09_  
_status: draft v0.2_  
_purpose: 仕様駆動開発支援評価に使う case の固定_

---

## 1. この文書の役割

この文書は、`dual-reviewer` の次段論文化において
主評価対象として扱う case を固定するための manifest である。

ここでいう case は、単なる code target ではない。
`intent/spec/design/tasks/implementation/review` のどの段階から始まるかを含む。

---

## 2. Case 分類

### Intent Track

- 開始点:
  - `intent`
- 観測したいこと:
  - requirement 化
  - design/task 化
  - `D/C/B/A` handback

### Spec Track

- 開始点:
  - `requirements/design/tasks`
- 観測したいこと:
  - downstream refinement
  - alignment gate
  - reopen / recheck

### Implementation Track

- 開始点:
  - implementation artifact
- 観測したいこと:
  - implementation/review phase support
  - caveat retention
  - disagreement preservation
  - downstream rework traceability

---

## 3. Core Evaluation Set

### C-1: dual-reviewer-rebuild

- category:
  - intent-origin internal rebuild case
- track:
  - `Intent Track / Spec Track / Implementation Track`
- role in paper:
  - workflow construction validity
  - intent-only start case の代表
- fresh first batch:
  - [F1-intent-dual-reviewer-rebuild-narrative comparison summary](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild-narrative/comparison_summary.json:1)

### C-2: phase-field reverse-spec / phase-field-cpp

- core case note:
  - [core-case-phase-field.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-phase-field.md:1)
- category:
  - scientific / numerical case
- track:
  - `Spec Track / Implementation Track`
- intent ref:
  - [phase-field-reverse-spec/intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/phase-field-reverse-spec/intent.md:1)
- role in paper:
  - high-cognitive-load downstream case
  - spec-present refinement / reopen case の代表
- fresh spec-track batch:
  - [F1-spec-phase-field-reverse-spec-narrative comparison summary](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec-narrative/comparison_summary.json:1)

### C-3: heat3d

- core case note:
  - [core-case-heat3d.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-heat3d.md:1)
- status:
  - fixed core case
  - preserved v3 evaluation case
- category:
  - PDE / simulation case
- track:
  - `Spec Track / Implementation Track` を想定
- intent ref:
  - [heat3d-spec/intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1)
- role in paper:
  - simulation implementation case
- role in v3:
  - code-conformance vs spec-underconstraint evaluation case

### C-4: iot-arduino

- core case note:
  - [core-case-iot-arduino.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-iot-arduino.md:1)
- status:
  - provisional
- category:
  - embedded / event-driven case
- track:
  - `Implementation Track` を中心に、intent/spec 作成後は `Spec Track` も追加
- intent ref:
  - [iot-arduino-spec/intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/intent.md:1)
- role in paper:
  - operational / event-driven downstream case

---

## 4. Selection Rule

各 case は次のいずれかを満たす必要がある。

1. `intent` から開始できる
2. `requirements/design/tasks` が存在する
3. implementation artifact があり、対応する上流 spec を持つか再構成できる

上流を持たない孤立 code snapshot は、main case にしない。

---

## 5. Evidence Rule

main evaluation に含める evidence は、
**Ruby 版 `dual-reviewer v1` で新たに取得するものだけ** とする。

過去バージョンで得た観測値は、

- main evidence
- comparison metric
- performance claim

には使わない。

許される用途は次のみ。

- boundary explanation
- case provenance note
- historical memo

---

## 6. Track-to-Paper Mapping

| case | primary contribution |
|------|----------------------|
| `dual-reviewer-rebuild` | intent-origin workflow validity |
| `phase-field reverse-spec / cpp` | high-load downstream case |
| `heat3d` | simulation-oriented downstream case |
| `iot-arduino` | event-driven downstream case |

---

## 7. Success Condition

この manifest が機能したとみなす条件は次である。

1. Intent Track / Spec Track / Implementation Track を少なくとも 1 case ずつ持つ
2. phase ごとの evidence を main paper claim に対応づけられる
3. implementation case も upstream spec と切り離さず説明できる
4. prior evidence と main evidence の provenance を混同しない
