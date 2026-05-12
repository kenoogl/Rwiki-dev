# heat3d C-3 evidence bundle

_作成: 2026-05-11_  
_status: bundle v0.1_  
_role: `C-3 heat3d` の workflow / spec / review acquisition / implementation evidence を 1 本に束ねる_

---

## 1. scope

- case id:
  - `C-3-heat3d`
- class:
  - `Spec-origin`
  - `Implementation-origin`
- language:
  - Julia
- canonical source:
  - [thermal_simulator_spec.md](/Users/Daily/Development/DR-heat3d/spec_seed/thermal_simulator_spec.md:1)
- intent:
  - [intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1)

この bundle は、`heat3d` で次の 2 点がどこまで確認できたかを束ねる。

1. gate-based workflow が実運用で回るか
2. implementation-origin second case として `single / dual / dual+judgment` が取れるか

---

## 2. upstream spec package

### 2.1 umbrella

- [brief.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/brief.md:1)
- [research.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/research.md:1)
- [spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/spec.json:1)

### 2.2 active feature set

- [heat3d-foundation](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/spec.json:1)
- [heat3d-linear-solver](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/spec.json:1)
- [heat3d-case-model](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/spec.json:1)
- [heat3d-main](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/spec.json:1)

dependency order は
`foundation -> linear-solver / case-model -> main`
で固定した。

---

## 3. phase evidence

### 3.1 requirements

- gate package:
  - [requirements-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/requirements-evidence-summary.md:1)
- totals:
  - `6 findings`
  - `6 blocking`
  - `6 fixed`
  - `1 recheck`

この phase では、single-feature 開始が不適切と判明し、
discovery checkpoint へ戻した手戻りが 1 回あった。
その後、multi-feature decomposition に戻して gate を通した。

### 3.2 design

- gate package:
  - [design-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/design-evidence-summary.md:1)
- totals:
  - `7 findings`
  - `7 blocking`
  - `7 fixed`

主に owner boundary と handoff object shape の固定を行った。

### 3.3 tasks

- gate package:
  - [tasks-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/tasks-evidence-summary.md:1)
- totals:
  - `6 findings`
  - `6 blocking`
  - `6 fixed`

主に shared file owner、allocator lifecycle、integration blocker を固定した。

---

## 4. workflow evidence

- trial protocol:
  - [heat3d-gate-only-trial.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-gate-only-trial.md:1)
- workflow trace:
  - [heat3d-workflow-path.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-workflow-path.md:1)

この case で実際に観測された workflow 上の特徴は次である。

1. 最初の `requirements` draft 後に、single-feature 前提が不適切と判明して discovery へ戻した
2. `review-before-gate` を破った gate request を 1 回 reopen した
3. readability 指摘を受けて `requirements` を平易な日本語へ rewrite した
4. その後は `requirements -> design -> tasks -> review acquisition` の順で gate を通した

つまり、`heat3d` は

- restart
- reopen
- recheck
- gate approval

の 4 種の control event を含んだ second-case trace になっている。

---

## 5. review acquisition evidence

### 5.1 boundary

- preparation:
  - [heat3d-review-acquisition-preparation.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-review-acquisition-preparation.md:1)
- gate summary:
  - [review-acquisition-gate-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/review-acquisition-gate-summary.md:1)
- summary:
  - [review-acquisition-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/review-acquisition-summary.md:1)

ここで固定したのは coding 完了ではなく、
clean-room `heat3d-julia` snapshot に対する review acquisition boundary である。

### 5.2 treatments

- batch summary:
  - [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F2-heat3d-julia/comparison_summary.json:1)
- run ids:
  - `single = run-20260511T062535Z-d6c4618a`
  - `dual = run-20260511T062535Z-e945dac7`
  - `dual+judgment = run-20260511T062535Z-70acf852`
- counts:
  - `2 / 3 / 3`
- validation:
  - all `passed`

今回の rerun は、旧 pilot と違って approved `requirements / design / tasks` を upstream input に含めた gate-approved acquisition である。

---

## 6. cross-case observation

- comparison note:
  - [heat3d-phase-field-implementation-comparison-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-phase-field-implementation-comparison-note.md:1)

現時点の implementation-track cross-case 読みは次である。

1. `phase-field` と `heat3d` はどちらも `2 / 3 / 3`
2. 共通の 2 件は `boundary` と `update-order`
3. 3 件目は両方とも `parameter-caveat`
4. ただし 3 件目の具体的根拠は case ごとの snapshot rationale と upstream packaging に依存する

---

## 7. implementation evidence

- execution note:
  - [heat3d-implementation-execution-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-implementation-execution-note.md:1)
- evidence summary:
  - [implementation-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/implementation-evidence-summary.md:1)
- code root:
  - [/Users/Daily/Development/DR-heat3d/src/Heat3D.jl](/Users/Daily/Development/DR-heat3d/src/Heat3D.jl:1)
- validation:
  - `julia --project=. test/runtests.jl` passed

implementation-phase reading:

1. coding layer での blocking issue は `3` 件だった
2. それらは `Project.toml`, module boundary, guard-cell material contract に閉じていた
3. requirements/design/tasks への reopen は発生しなかった
4. したがって、今回の実装手戻りは upstream spec 不備ではなく implementation-local correction として観測された

---

## 8. current claim support

この bundle から、今の時点で比較的安全に言えることは次である。

### 8.1 Claim 2 / workflow operation

- `heat3d` では gate-only human approval model が実運用で回った
- restart / reopen / recheck を trace artifact に残せた
- multi-feature decomposition を途中で差し戻しても workflow が崩壊しなかった
- requirements/design/tasks の phase evidence と implementation evidence を同じ case id で縦に接続できた

paper-facing reading:

`heat3d` は、simulation-oriented case でも finding だけでなく reopen depth, caveat, evidence summary を traceable に残せることを示す。

### 8.2 Claim 3 / second implementation case

- `heat3d-julia` を `phase-field-cpp` に続く second implementation case として起こせた
- clean-room boundary を維持したまま `single / dual / dual+judgment` を再取得できた
- approved upstream bundle から actual implementation まで同じ workflow contract で接続できた

paper-facing reading:

`heat3d` は、`Spec-origin / Implementation-origin` の別ドメイン case でも workflow maintenance が可能であることを示す fixed core case として読める。

### 8.3 Claim 4 / domain transfer

- simulation-oriented second case でも
  - `boundary`
  - `update-order`
  - `parameter-caveat`
  の 3 系統が立った
- したがって `phase-field` だけの局所観測ではない可能性がある
- behavior mismatch を `implementation defect` 断定ではなく `spec/design underconstraint exposure` として report-facing note と `v3` 記録へ再利用できた

paper-facing reading:

`heat3d` は、review 後の evidence を downstream reporting と future conformance evaluation の両方に再利用できることを示す。

---

## 9. current limits

この bundle だけでは、まだ次は言えない。

1. canonical full-case acceptance `13.4` が確立した
2. `review acquisition` と `implementation` が常に同じ case で揃う
3. `parameter-caveat` が一般則として常に 3 件目になる
4. main-evidence-grade な generic runtime replacement が完了した

加えて、`phase-field` 側は summary が指す最新 run id の local runtime bundle を直接参照できず、
content comparison には local export に残っている最新 bundle を使っている。

---

## 10. next action

この bundle の次にやるべきことは 2 つである。

1. `heat3d` の fixed-case reading を `Claim 2 / 3 / 4` の本文または supporting note に統合する
2. `13.4` を supplementary behavioral evidence として扱う判断を残り文書へ反映する

補足:

- `heat3d` は [heat3d-v3-evaluation-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-v3-evaluation-note.md:1) に基づき、`v3` の code-conformance evaluation case として保存する
- `heat3d` の core-case fixation judgment は [heat3d-case-fixation-decision.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-case-fixation-decision.md:1) に記録した
- preliminary report と paper plan への一次統合は完了している
- validation boundary judgment は [heat3d-validation-boundary-decision.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-validation-boundary-decision.md:1) に記録した
