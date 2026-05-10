# Core Case: heat3d

_作成: 2026-05-10_  
_status: provisional core case v0.1_  
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
- canonical source:
  - [thermal_simulator_spec.md](/Users/Daily/Development/Heat3ds_rework/docs/thermal_simulator_spec.md:1)

current note:

- 現時点では intent は fixed
- downstream `requirements / design / tasks` はこれから formalize する

---

## 3. Downstream Reference

- implementation-phase protocol:
  - [heat3d-implementation-phase-protocol.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-implementation-phase-protocol.md:1)

implementation snapshot は今後 fixed する。

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

この case は、現時点では provisional case である。

fixed core case に上げる条件:

1. `requirements / design / tasks` が固定される
2. `Spec Track` の concrete case が固定される
3. `Implementation Track` の protocol / snapshot が固定される

main evidence に使うのは、Ruby 版 `dual-reviewer v1` で新たに取得する review artifact のみである。
