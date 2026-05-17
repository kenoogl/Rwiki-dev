# Requirements Document

## Introduction

`dual-reviewer-runtime` は `dual-reviewer-foundation` が定義する共通 contract の上で、実際の review session を実行する feature である。本 spec の役割は、review orchestration、prompt loading、log emission、validator integration、human decision points を runtime として定義することにある。

本 spec は「review をどう動かすか」を扱うが、「その結果をどう測るか」は `dual-reviewer-evaluation`、「どう改善するか」は `dual-reviewer-self-improvement` に分離する。

## Boundary Context

- **In scope**
  - review session orchestration
  - Step A/B/C/D の実行順序と state transition
  - phase-aware review profile selection
  - treatment ごとの実行 shape 決定
  - prompt resolution
  - structured log emission
  - run close validation integration
  - human approval / reject / defer integration

- **Out of scope**
  - metrics 集計
  - figure / table 生成
  - improvement proposal 生成
  - paper-facing report 生成
  - central-side external contribution intake

- **Adjacent expectations**
  - `dual-reviewer-foundation` から schema、metadata contract、prompt placement rule を import する
  - `dual-reviewer-evaluation` から valid / invalid 判定に必要な evidence を要求される
  - `dual-reviewer-self-improvement` から replay 可能な run evidence を要求される
  - `dual-reviewer-paper-interface` には原則として evaluation 経由で artifact を渡し、runtime が paper-facing 要件に直接従属しない

## Requirements

### Requirement 1: Review Session Orchestration

**Objective:** As an operator, I want the runtime to execute a review session using a consistent 4-step pipeline, so that review output is reproducible and comparable across runs.

#### Acceptance Criteria

1. The runtime shall execute review sessions according to the canonical Step A (`primary detection`) -> Step B (`adversarial review`) -> Step C (`judgment`) -> Step D (`integration`) model defined by foundation.
2. The runtime shall represent step transitions explicitly in run records.
3. The runtime shall allow treatment-based execution differences while preserving the same conceptual state machine.
4. The runtime shall distinguish omitted steps from failed steps in its run records.
5. The runtime shall expose a run close boundary after which evidence is frozen and validation is invoked.
6. The runtime shall own concrete run directory layout, step file naming, and evidence writing order while remaining conformant to foundation contracts.

### Requirement 2: Treatment-Aware Execution

**Objective:** As an evaluator, I want treatments to be runtime-visible and mechanically traceable, so that single / dual / dual+judgment comparisons remain valid.

#### Acceptance Criteria

1. The runtime shall record treatment as a first-class run attribute.
2. The runtime shall support at minimum `single`, `dual`, and `dual+judgment` treatments.
3. The runtime shall define which steps are executed, skipped, or reduced for each treatment.
4. The runtime shall emit explicit skip markers when a step is intentionally not run because of treatment selection.
5. The runtime shall prevent ambiguous treatment execution where run records cannot distinguish whether a step was skipped by design or omitted accidentally.

### Requirement 3: Prompt Resolution and Version Traceability

**Objective:** As a maintainer, I want runtime prompt loading to be explicit and versioned, so that review behavior is attributable to concrete in-repo prompt artifacts.

#### Acceptance Criteria

1. The runtime shall resolve prompts from repo-contained locations only.
2. The runtime shall record prompt version or prompt artifact identity in run metadata.
3. The runtime shall distinguish role-specific prompt usage by role and step.
4. The runtime shall fail or mark invalid a run that cannot resolve required prompts unambiguously.
5. The runtime shall not rely on repo-external memory as a hidden prompt source for steady-state behavior.

### Requirement 4: Structured Evidence Emission

**Objective:** As an evaluator and self-improvement implementer, I want runtime output to be structured and schema-conformant, so that downstream analysis does not depend on free-form interpretation alone.

#### Acceptance Criteria

1. The runtime shall emit run-level evidence conforming to foundation schemas.
2. The runtime shall emit finding-level records with source attribution and judgment linkage.
3. The runtime shall emit counter-evidence and override-related fields when applicable.
4. The runtime shall separate raw evidence from derived summaries.
5. The runtime shall preserve enough information for downstream replay and proposal analysis.
6. The runtime shall emit review-mode provenance in a form conformant to the foundation metadata contract.
7. The runtime shall emit a `failure_observation` record conforming to the foundation schema whenever a review run encounters a failure mode, so that the failure classification data is captured rather than left as an unused schema.

### Requirement 5: Human Decision Integration

**Objective:** As an operator, I want runtime output to align with human decision units, so that approve / reject / defer actions are explicit and reviewable.

#### Acceptance Criteria

1. The runtime shall present review output in decision units that can be approved, rejected, or deferred by a human.
2. The runtime shall record the human decision outcome for each decision unit.
3. The runtime shall distinguish human decision absence from explicit defer or reject.
4. The runtime shall require explicit sign-off before a run is treated as closed and ready for downstream evaluation.
5. The runtime shall not silently auto-adopt LLM findings into accepted review output.

### Requirement 6: Validator Integration and Run Close

**Objective:** As a maintainer, I want run closure to invoke mechanical checks, so that invalid sessions are separated before evaluation and self-improvement consume them.

#### Acceptance Criteria

1. The runtime shall invoke validator checks at run close.
2. The runtime shall propagate validator status into run metadata using the foundation canonical validator-status vocabulary (at minimum pass / fail / blocked) rather than redefining or collapsing it.
3. The runtime shall support invalidation markers without mutating raw evidence.
4. The runtime shall distinguish validator failure from orchestration failure.
5. The runtime shall prevent downstream “valid run” handling when required validation fails.
6. The runtime shall mark runtime-produced evidence with the canonical runtime-mediated review mode rather than relying on downstream inference.
7. The runtime shall emit a machine-readable invalid-run triage artifact when validation or invalidation indicates workflow failure.
8. The runtime shall preserve linkage between failed validator checks, invalidation markers, and operator-facing remediation hints.
9. The runtime shall enforce the ordering human sign-off -> validator invocation -> run close, so that a run is never closed before sign-off and validation are both complete, and validator results never precede the human decision.

### Requirement 7: Replay-Friendly Runtime Records

**Objective:** As a self-improvement implementer, I want runtime evidence to support replay and backtest, so that recurring failures can be analyzed without depending on informal recollection.

#### Acceptance Criteria

1. The runtime shall preserve sufficient run metadata to identify the exact runtime condition of a past session.
2. The runtime shall preserve step-level evidence boundaries.
3. The runtime shall preserve prompt and treatment identity needed for replay classification.
4. The runtime shall make it possible to distinguish quality problems from workflow or validation problems.
5. The runtime shall not compress evidence so aggressively that replay feasibility is lost.

### Requirement 8: Phase-Aware Review Profiles

**Objective:** As an operator and maintainer, I want the runtime to support phase-aware review profiles, so that review emphasis can shift as complexity grows from intent and requirements to design and tasks.

#### Acceptance Criteria

1. The runtime shall support explicit phase/profile selection for at minimum `intent`, `requirements`, `design`, and `tasks`.
2. The runtime shall allow profile-specific review emphasis without changing the canonical Step A/B/C/D state machine.
3. The runtime shall preserve which phase/profile was used in run metadata.
4. The runtime shall support stronger structural and dependency-oriented review behavior for `design` and `tasks` than for upstream profiles.
5. The runtime shall distinguish treatment selection from phase/profile selection.
6. The runtime shall own prompt override resolution policy when multiple in-repo prompt candidates exist, provided foundation placement and identity rules are preserved.

### Requirement 9: Portable Evidence Bundle Export

**Objective:** As a maintainer operating across multiple local environments, I want runtime-produced evidence to be exportable as a portable bundle, so that central analysis can ingest cross-project runs without relying on hidden local state.

#### Acceptance Criteria

1. The runtime shall support exporting a run as a portable evidence bundle without rewriting the underlying raw evidence semantics.
2. The runtime shall preserve required provenance for exported bundles, including source repository identity and source revision.
3. The runtime shall preserve review-mode identity for exported bundles.
4. The runtime shall distinguish bundle export from central-side ingestion or admission decisions.
5. The runtime shall not require repo-external hidden memory to reconstruct the meaning of an exported bundle.

### Requirement 10: 削除済み

旧 v1 の取得処理は規則ファイル参照（`heuristic_profile_ref`）と種パターン照合に依存していたが、v2 では実 LLM 呼び出しに置き換える方針のため、本要件は削除した。ケース取得設定のトラック検証は v2 取得 spec（`dual-reviewer-rebuild/.kiro/specs/dual-reviewer-v2-acquisition/`）で再設計する。
