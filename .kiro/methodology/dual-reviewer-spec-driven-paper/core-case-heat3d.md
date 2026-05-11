# Core Case: heat3d

_作成: 2026-05-10_  
_status: fixed core case / preserved v3 evaluation case v0.3_  
_role: thermal simulation representative case_

---

## 1. Case Identity

- case id: `C-3-heat3d`
- label: `heat3d`
- domain: PDE / thermal simulation
- primary language:
  - Julia

---

## 2. Canonical Upstream Inputs

- intent:
  - [heat3d-spec/intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1)
- requirements:
  - [heat3d-foundation/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/requirements.md:1)
  - [heat3d-linear-solver/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/requirements.md:1)
  - [heat3d-case-model/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/requirements.md:1)
  - [heat3d-main/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/requirements.md:1)
- design:
  - [heat3d-foundation/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/design.md:1)
  - [heat3d-linear-solver/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/design.md:1)
  - [heat3d-case-model/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/design.md:1)
  - [heat3d-main/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/design.md:1)
- tasks:
  - [heat3d-foundation/tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/tasks.md:1)
  - [heat3d-linear-solver/tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/tasks.md:1)
  - [heat3d-case-model/tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/tasks.md:1)
  - [heat3d-main/tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/tasks.md:1)
- canonical source:
  - [thermal_simulator_spec.md](/Users/Daily/Development/DR-heat3d/spec_seed/thermal_simulator_spec.md:1)

current note:

- intent は fixed
- downstream `requirements / design / tasks` は formalized 済み
- actual implementation と reduced validation まで取得済み

---

## 3. Downstream Reference

- implementation-phase protocol:
  - [heat3d-implementation-phase-protocol.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-implementation-phase-protocol.md:1)
- implementation snapshot:
  - [heat3d-julia-implementation-phase-first-snapshot.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-julia-implementation-phase-first-snapshot.md:1)

---

## 4. Supported Tracks

- `Spec Track`
- `Implementation Track`

`Intent Track` の primary case ではない。

---

## 5. Paper Role

この case は次の claim を支える。

- `Claim 2`
  - simulation-oriented case で traceability / caveat retention を観測する
- `Claim 3`
  - `Spec-origin` と `Implementation-origin` の別ドメイン検証に使う
- `Claim 4`
  - thermal simulation artifact の再利用可能性を示す補助 case とする

paper-facing reading:

- `Claim 2`
  - requirements/design/tasks の summary、review acquisition、implementation evidence を縦に接続できるため、finding だけでなく caveat, disposition, reopen depth を traceable に残せることを示す
- `Claim 3`
  - restart, reopen, readability recheck, review acquisition, actual implementation を含む end-to-end path が成立しており、`Spec-origin / Implementation-origin` の workflow maintenance case として読める
- `Claim 4`
  - reduced validation pass と reference behavior mismatch を併記したまま、`spec/design underconstraint exposure` を report-facing note と `v3` 保存記録へ再利用できる

---

## 6. Stress Characteristics

主な stress point:

1. material assignment and property interpretation
2. boundary condition handling
3. non-uniform Z grid interpretation
4. implicit time integration and linear solver assumptions
5. simulation configuration drift

---

## 7. Operational Note

この case は main paper の fixed core case として固定する。

ただし、main evidence に使うのは Ruby 版 `dual-reviewer v1` で新たに取得した review artifact と、それに結びつく upstream artifact に限る。

---

## 8. Current Assessment

`heat3d` では、approved upstream artifact を根拠に clean-room implementation を作成し、実際に実行できることを確認した。

ただし、reference behavior との一致までは確認できていない。現時点で first-order に読むべき観測は、

- implementation が動いたこと
- workflow / review acquisition / implementation まで trace できたこと
- behavioral mismatch が出たこと

である。

この mismatch は、現時点では implementation defect と即断せず、spec/design insufficiency を露出したケースとして扱う。

main paper では、この点を

- implementation failure proof
  ではなく
- approved upstream artifact だけでは所望挙動を十分拘束できなかった可能性

として書く。

---

## 9. v3 Role

この case は、main paper の fixed core case 判定とは別に、**v3 の code-conformance evaluation case** として保存する。

参照:

- [heat3d-v3-evaluation-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-v3-evaluation-note.md:1)
- [heat3d-case-fixation-decision.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-case-fixation-decision.md:1)

v3 で見たいこと:

1. code と approved `tasks/design/requirements` が一致しているか
2. 一致しているのに behavior mismatch が残るなら spec/design insufficiency と言えるか
3. 一致していなければ implementation deviation と言えるか
