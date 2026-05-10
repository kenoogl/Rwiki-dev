# Core Case: phase-field

_作成: 2026-05-10_  
_status: fixed core case v0.1_  
_role: scientific / numerical representative case_

---

## 1. Case Identity

- case id: `C-2-phase-field`
- label: `phase-field`
- domain: scientific / numerical simulation
- primary language:
  - C++ (`implementation phase`)

---

## 2. Canonical Upstream Inputs

- intent:
  - [phase-field-reverse-spec/intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/phase-field-reverse-spec/intent.md:1)
- requirements:
  - [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/phase-field-reverse-spec/requirements.md:1)
- design:
  - [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/phase-field-reverse-spec/design.md:1)
- tasks:
  - [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/phase-field-reverse-spec/tasks.md:1)

canonical source constraint:

- `DR-pfm/spec_seed/DEVELOPMENT_SPEC.md`
- `wingxa.h`

---

## 3. Downstream Reference

- implementation-phase protocol:
  - [phase-field-implementation-phase-protocol.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/phase-field-implementation-phase-protocol.md:1)
- implementation snapshot:
  - [phase-field-implementation-phase-first-snapshot.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/phase-field-implementation-phase-first-snapshot.md:1)

---

## 4. Supported Tracks

- `Spec Track`
- `Implementation Track`

`Intent Track` の primary case ではない。

---

## 5. Paper Role

この case は次の claim を支える。

- `Claim 2`
  - traceability / caveat / handback depth を scientific case で観測する
- `Claim 3`
  - `Spec-origin` と `Implementation-origin` の両開始条件で workflow を維持できることを示す
- `Claim 4`
  - downstream implementation/review evidence の再利用可能性を示す

---

## 6. Stress Characteristics

主な stress point:

1. numerical model interpretation
2. boundary condition semantics
3. parameter interpretation drift
4. update ordering and state mutation
5. scientific caveat retention

---

## 7. Operational Note

この case は main paper の core case として固定する。
ただし main evidence に使うのは、Ruby 版 `dual-reviewer v1` で新たに取得する review artifact のみである。
