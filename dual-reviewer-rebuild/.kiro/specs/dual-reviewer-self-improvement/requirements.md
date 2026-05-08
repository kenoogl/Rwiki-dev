# Requirements Document

## Introduction

`dual-reviewer-self-improvement` は review 記録と内部動作 evidence を用いて、runtime を継続的に改善する feature である。本 spec は improvement proposal の生成と採否の流れを formalize し、ad-hoc な memory 追加ではなく evidence-driven な system improvement を可能にする。

本 spec は変更実装そのものではなく、改善の入力、proposal 単位、backtest / replay、approval / rollback を扱う。

## Boundary Context

- **In scope**
  - improvement input definition
  - proposal artifact contract
  - replay and backtest requirements
  - approval and rollback flow
  - accepted / rejected improvement history

- **Out of scope**
  - runtime execution itself
  - evaluation metric definition itself
  - paper-facing narrative generation
  - external contributor learning network

- **Adjacent expectations**
  - `dual-reviewer-runtime` から replay-friendly run evidence を受け取る
  - `dual-reviewer-evaluation` から quality and exclusion signals を受け取る
  - `dual-reviewer-foundation` の schema and metadata contract に依存する
  - `dual-reviewer-paper-interface` と proposal rationale を混同しない

## Requirements

### Requirement 1: Improvement Input Definition

**Objective:** As a maintainer, I want improvement inputs to be explicitly defined, so that runtime changes are grounded in evidence rather than intuition.

#### Acceptance Criteria

1. The self-improvement feature shall define valid improvement input classes.
2. The feature shall distinguish review-quality evidence from workflow-failure evidence.
3. The feature shall support inputs from valid runs and invalid runs while preserving that distinction.
4. The feature shall not treat unrecorded operator intuition as sufficient input.
5. The feature shall preserve provenance from input evidence to proposal.

### Requirement 2: Proposal Artifact Contract

**Objective:** As a maintainer, I want each proposed improvement to exist as a structured artifact, so that adoption decisions are reviewable and traceable.

#### Acceptance Criteria

1. The self-improvement feature shall define a structured proposal unit.
2. Each proposal shall identify the targeted layer at minimum among prompt, policy, schema, runtime, or workflow.
3. Each proposal shall identify the motivating evidence.
4. Each proposal shall record expected benefit and possible risk.
5. The feature shall preserve both accepted and rejected proposals as first-class records.

### Requirement 3: Replay and Backtest Requirements

**Objective:** As a maintainer, I want improvement candidates to be testable against recorded evidence, so that changes can be evaluated before adoption.

#### Acceptance Criteria

1. The self-improvement feature shall define when replay is required and when lighter backtest is sufficient.
2. The feature shall require replay or backtest inputs to reference concrete run evidence.
3. The feature shall preserve replay/backtest results as separate artifacts from raw run evidence.
4. The feature shall distinguish “proposal unsupported” from “proposal untested.”
5. The feature shall avoid treating anecdotal plausibility as equivalent to backtest evidence.

### Requirement 4: Approval and Adoption Flow

**Objective:** As a human maintainer, I want a formal approval flow for improvement adoption, so that system behavior does not drift through silent prompt growth or hidden policy change.

#### Acceptance Criteria

1. The self-improvement feature shall define explicit states for proposal review, approval, rejection, and adoption.
2. The feature shall require human approval before runtime-affecting changes are adopted.
3. The feature shall preserve the link between an adopted change and the proposal that justified it.
4. The feature shall require version updates for adopted runtime-affecting changes.
5. The feature shall make rejection a preserved outcome, not an invisible discard.

### Requirement 5: Rollback and Failure Handling

**Objective:** As a maintainer, I want rollback conditions for adopted improvements, so that harmful changes can be reversed without ambiguity.

#### Acceptance Criteria

1. The self-improvement feature shall define rollback-triggering conditions.
2. The feature shall preserve which accepted proposal introduced the reverted behavior.
3. The feature shall preserve rollback reason as evidence.
4. The feature shall distinguish rollback from ordinary supersession.
5. The feature shall support learning from failed improvements rather than deleting their history.

### Requirement 6: Separation from Paper Narrative

**Objective:** As a maintainer, I want the improvement loop to remain independent from paper-writing needs, so that runtime changes are not justified primarily by reporting convenience.

#### Acceptance Criteria

1. The self-improvement feature shall not accept paper convenience alone as sufficient reason for runtime-affecting change.
2. The feature shall distinguish report-layer caveat handling from runtime-layer improvement.
3. The feature shall preserve whether an improvement is motivated by runtime quality, workflow quality, or evidence quality.
4. The feature shall not allow undocumented narrative-driven change to enter steady-state behavior.
5. The feature shall remain compatible with future external evidence intake without requiring it in the initial rebuild.

### Requirement 7: Manual-vs-Runtime Evidence Provenance

**Objective:** As a maintainer, I want self-improvement inputs to preserve whether they come from manual dogfooding review or runtime-mediated review, so that early method-validation observations are not over-generalized as runtime behavior.

#### Acceptance Criteria

1. The self-improvement feature shall preserve review-mode provenance for improvement inputs.
2. The feature shall distinguish manual dogfooding findings from runtime-mediated findings when generating proposals.
3. The feature shall not treat ordinary unstructured editing history as valid self-improvement input.
4. The feature shall allow manual dogfooding evidence to motivate workflow or requirement improvements without implying runtime-quality equivalence.
5. The feature shall preserve the handoff boundary when later runtime-mediated evidence supersedes earlier manual evidence.

### Requirement 8: Imported Evidence Provenance Preservation

**Objective:** As a maintainer, I want self-improvement proposals derived from imported external bundles to preserve source provenance, so that adopted changes remain traceable to their originating project and admission context.

#### Acceptance Criteria

1. The self-improvement feature shall preserve whether an input came from local central runs or imported external bundles.
2. The feature shall preserve source repository identity and source revision when imported evidence motivates a proposal.
3. The feature shall preserve evaluation-side admission status for imported evidence referenced by proposals.
4. The feature shall allow imported evidence to motivate proposals without erasing review-mode provenance.
5. The feature shall not treat provenance-insufficient imported evidence as equivalent to admitted standard comparison evidence.
