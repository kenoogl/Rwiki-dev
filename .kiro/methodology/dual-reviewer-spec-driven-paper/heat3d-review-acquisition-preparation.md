# heat3d review acquisition preparation

_作成: 2026-05-11_  
_status: review acquisition gate input v0.1_  
_purpose: `heat3d` trial の review acquisition gate 前に、review acquisition boundary と upstream input を固定する_

---

## 1. この文書の役割

この文書は、`heat3d` の `requirements / design / tasks` 承認後に、
review acquisition へ入る前の入力境界を固定するための preparation memo である。

ここで固定するのは次の 4 点である。

1. implementation target statement
2. upstream approved spec set
3. implementation snapshot / review acquisition boundary
4. validation / conformance entrypoint

この文書は human `review acquisition gate` の判断材料であり、
coding phase の正本そのものではない。

この文書は
[review-acquisition-preparation-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/review-acquisition-preparation-template.md:1)
の `heat3d` 適用例として書く。

正本順位は次に従う。

1. [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:1)
2. [heat3d-gate-only-trial.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-gate-only-trial.md:1)
3. [heat3d-spec/spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/spec.json:1)
4. この preparation memo

## 2. Implementation Target Statement

- case id:
  - `C-3-heat3d`
- implementation target label:
  - `heat3d-julia`
- current implementation role:
  - `intent-governed heat3d trial` の review acquisition boundary 固定
- operational interpretation:
  - 今回の review acquisition gate は、新しい Julia source tree の完成承認ではない
  - approved `requirements / design / tasks` を upstream input とし、既取得 `heat3d-julia` snapshot を review acquisition target として結び直すための gate である

この trial で review acquisition に入る意味は、
`tasks` で fixed した implementation order と owner boundary を
implementation review acquisition に接続できるかを検証することにある。

## 3. Fixed Upstream Approved Spec Set

review acquisition gate input に含める upstream approved spec は次で固定する。

### 3.1 Umbrella Inputs

- [intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1)
- [brief.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/brief.md:1)
- [research.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/research.md:1)

### 3.2 Approved Requirements

- [heat3d-foundation/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/requirements.md:1)
- [heat3d-linear-solver/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/requirements.md:1)
- [heat3d-case-model/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/requirements.md:1)
- [heat3d-main/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/requirements.md:1)

### 3.3 Approved Design

- [heat3d-foundation/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/design.md:1)
- [heat3d-linear-solver/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/design.md:1)
- [heat3d-case-model/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/design.md:1)
- [heat3d-main/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/design.md:1)

### 3.4 Approved Tasks

- [heat3d-foundation/tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/tasks.md:1)
- [heat3d-linear-solver/tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/tasks.md:1)
- [heat3d-case-model/tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/tasks.md:1)
- [heat3d-main/tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/tasks.md:1)

## 4. Fixed Implementation Snapshot and Review Boundary

### 4.1 Snapshot Ref

- implementation snapshot ref:
  - [heat3d-julia-implementation-phase-first-snapshot.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-julia-implementation-phase-first-snapshot.md:1)
- implementation protocol ref:
  - [heat3d-implementation-phase-protocol.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-implementation-phase-protocol.md:1)
- run template ref:
  - [implementation-track-run-template.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/implementation-track-run-template.md:1)

### 4.2 Review Boundary

implementation review acquisition の主対象に含めるもの:

- `heat3d-julia` first snapshot に含まれる canonical seed
- discretization / boundary / solver / software structure の rules
- approved `requirements / design / tasks` から導かれる owner boundary
- implementation-local issue と upstream spec inconsistency の切り分け

implementation review acquisition の主対象にしないもの:

- `Heat3ds_rework` 配下の既存 Julia code
- plotting-only helper
- deferred feature である `visualization`
- batch / CLI 拡張の将来構想

### 4.3 Clean-Room Constraint

- canonical source は `/Users/Daily/Development/DR-heat3d/spec_seed/thermal_simulator_spec.md`
- original Julia implementation は review evidence に入れない
- implementation target は clean-room boundary を保持した `heat3d-julia` snapshot に固定する

## 5. Implementation Order and Shared Artifact Rule

approved `tasks` から implementation order を次で固定する。

1. `heat3d-foundation`
2. `heat3d-linear-solver`
3. `heat3d-case-model`
4. `heat3d-main`

parallel / handoff rule:

- `linear-solver` と `case-model` は `foundation` 完了後に並行可能
- `main` は `linear-solver` と `case-model` の smoke test 完了後に進む

shared file / artifact owner:

- `src/foundation/*`: `heat3d-foundation`
- `src/linear_solver/*`: `heat3d-linear-solver`
- `src/case_model/*`: `heat3d-case-model`
- `src/main/*`, `src/bin/heat3d_main.jl`, final `src/Heat3D.jl`: `heat3d-main`

allocator owner:

- `allocate_field_buffers(shape)`: `foundation`
- `allocate_boundary_contributions(shape)`: `foundation`
- `allocate_coefficient_workspace(shape)`: `linear-solver`
- `allocate_solver_state(shape)`: `linear-solver`

## 6. Validation and Conformance Entry Points

review acquisition で最初に使う validation entrypoint は次で固定する。

1. feature-local smoke tests
   - `foundation` contract smoke test
   - `linear-solver` one-step smoke test
   - `case-model` assembled bundle smoke test
2. top-level end-to-end smoke test
   - `main` canonical MVP 1 step path
3. implementation review acquisition
   - `single review`
   - `dual review`
   - `dual+judgment`

conformance review で見ること:

- implementation issue と upstream spec issue を混同していないか
- caveat / disagreement が残っているか
- reopen が必要なら target reopen phase を切り分けられるか

## 7. Operational Caveat

この preparation で固定するのは review acquisition boundary であり、
まだ新しい Julia source tree 自体を生成したわけではない。

したがって、今回の review acquisition gate は

- `source tree ready` の承認ではなく
- `review acquisition boundary ready` の承認

として読む。

この caveat は workflow validation の current objective と整合している。

## 8. Preparation Conclusion

この時点で fixed とみなすもの:

- upstream approved spec set
- implementation snapshot ref
- review inclusion / exclusion boundary
- implementation order
- shared file owner
- validation / conformance entrypoint

次の action:

- `review acquisition gate` の human decision を取る
- approve 後、implementation review acquisition artifact 取得へ進む
