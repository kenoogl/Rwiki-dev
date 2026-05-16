# Requirements Document

## Introduction

`dual-reviewer-evaluation` は runtime が出力した evidence を valid / invalid に切り分け、比較可能な metrics と analysis artifact に変換する feature である。本 spec の目的は、review session の質を測るための protocol-aware evaluation contract を定義することにある。

本 spec は runtime を動かす責務を持たず、runtime が出した evidence を受け取って扱う。paper-facing output は `dual-reviewer-paper-interface` が担う。

## Boundary Context

- **In scope**
  - treatment definition for comparison
  - valid / invalid run separation
  - metrics extraction
  - derived evaluation artifacts
  - exclusion reporting
  - central-side evidence ingestion and admission for portable bundles

- **Out of scope**
  - runtime orchestration
  - prompt design
  - improvement proposal adoption
  - paper draft generation

- **Adjacent expectations**
  - `dual-reviewer-runtime` から structured run evidence を受け取る
  - `dual-reviewer-foundation` の schema と metadata contract に依存する
  - `dual-reviewer-self-improvement` に reusable analysis inputs を渡す
  - `dual-reviewer-paper-interface` に paper-facing source data を渡す

## Requirements

### Requirement 1: Valid / Invalid Run Separation

**Objective:** As an evaluator, I want valid and invalid runs to be mechanically separable, so that metrics and comparisons do not silently mix incomparable data.

#### Acceptance Criteria

1. The evaluation feature shall classify runs into valid, invalid, or explicitly exploratory categories based on metadata and invalidation markers.
2. The evaluation feature shall exclude invalid runs from standard comparative metrics by default.
3. The evaluation feature shall preserve counts and reasons for excluded runs.
4. The evaluation feature shall distinguish “missing data” from “invalid data.”
5. The evaluation feature shall not require free-form human memory to determine run validity.
6. The evaluation feature shall treat run-validity classification (valid / invalid / exploratory) and review-mode classification (manual dogfooding / runtime-mediated) as orthogonal independent axes, so that a content-valid run executed under manual dogfooding is not misclassified as invalid.

### Requirement 2: Treatment Comparison Contract

**Objective:** As a researcher, I want treatment-level comparison contracts, so that differences between `single`, `dual`, and `dual+judgment` can be interpreted consistently.

#### Acceptance Criteria

1. The evaluation feature shall define treatment-aware aggregation rules.
2. The evaluation feature shall support at minimum comparison across `single`, `dual`, and `dual+judgment`.
3. The evaluation feature shall distinguish treatment-driven step omission from runtime failure.
4. The evaluation feature shall make treatment identity visible in all comparison-relevant derived outputs.
5. The evaluation feature shall detect and report comparison sets that are invalid because of mismatched treatment conditions or target conditions.
6. The evaluation feature shall require protocol-version and prompt-version uniformity within a single comparison set as a comparability condition, and shall detect and report comparison sets that mix differing protocol or prompt versions even when all per-run metadata is present and well-formed.

### Requirement 3: Metric Extraction

**Objective:** As an evaluator, I want reproducible metric extraction from structured evidence, so that comparative claims are based on traceable calculations.

#### Acceptance Criteria

1. The evaluation feature shall define the minimum metric set for run comparison.
2. The evaluation feature shall compute metrics from structured evidence rather than from narrative summaries alone.
3. The evaluation feature shall preserve the derivation path from raw evidence to derived metric.
4. The evaluation feature shall allow re-computation when schema-compatible raw evidence is unchanged.
5. The evaluation feature shall separate run-level, finding-level, and treatment-level metrics.

### Requirement 4: Exclusion and Caveat Reporting

**Objective:** As a maintainer and future author, I want exclusion and caveat reporting to be explicit, so that later paper-facing artifacts do not hide data-quality issues.

#### Acceptance Criteria

1. The evaluation feature shall emit exclusion reports describing which runs were excluded and why.
2. The evaluation feature shall preserve caveat-relevant information needed by paper-interface and self-improvement features.
3. The evaluation feature shall distinguish data-quality caveats from runtime-quality caveats.
4. The evaluation feature shall make it possible to report exclusion counts without re-reading raw run logs manually.
5. The evaluation feature shall not silently collapse invalid and valid populations into one aggregate.

### Requirement 5: Derived Artifact Production

**Objective:** As a downstream consumer, I want evaluation outputs in machine-usable form, so that self-improvement and paper-facing features can reuse them without reparsing raw logs.

#### Acceptance Criteria

1. The evaluation feature shall produce structured derived outputs for metrics and comparison summaries.
2. The evaluation feature shall preserve linkage from derived outputs back to run identifiers and target identifiers.
3. The evaluation feature shall separate analysis artifacts from raw run evidence storage.
4. The evaluation feature shall support downstream consumption by both self-improvement and paper-interface features.
5. The evaluation feature shall make artifact versioning visible when evaluation logic changes.
6. The evaluation feature shall flag as stale or re-derive any derived artifact whose referenced runs are later invalidated, rather than leaving derived outputs based on invalidated runs unchanged.

### Requirement 6: Evaluation-Ready Metadata Completeness

**Objective:** As a maintainer, I want evaluation to fail fast when runtime evidence is insufficient, so that ambiguous evidence does not enter comparative analysis.

#### Acceptance Criteria

1. The evaluation feature shall check for required metadata before performing standard aggregation.
2. The evaluation feature shall refuse standard aggregation when required identifiers or versions are missing.
3. The evaluation feature shall emit explicit insufficiency diagnostics when aggregation is blocked.
4. The evaluation feature shall distinguish hard failure from exploratory partial analysis.
5. The evaluation feature shall not invent missing metadata from narrative context.

### Requirement 7: Phase-Aware Evaluation

**Objective:** As a researcher, I want evaluation outputs to preserve phase context, so that the system’s value in high-complexity phases such as design and tasks can be measured explicitly.

#### Acceptance Criteria

1. The evaluation feature shall preserve the reviewed phase/profile identity in derived artifacts.
2. The evaluation feature shall support phase-aware slicing of metrics and exclusions.
3. The evaluation feature shall make it possible to compare system behavior across at least `intent`, `requirements`, `design`, and `tasks` when such runs exist.
4. The evaluation feature shall preserve enough information to test the hypothesis that `design` and `tasks` are the highest-value phases for dual-reviewer support.
5. The evaluation feature shall not collapse phase-distinct runs into one undifferentiated aggregate by default.

### Requirement 8: Phase-Specific Effectiveness Metrics

**Objective:** As a researcher, I want the evaluation feature to support phase-specific effectiveness metrics, so that usefulness is not judged only by a design-centered metric set when reviewing intent, requirements, tasks, or implementation-oriented artifacts.

#### Acceptance Criteria

1. The evaluation feature shall allow different primary effectiveness metrics for different reviewed phases.
2. The evaluation feature shall preserve a shared core metric layer while allowing phase-specific overlays.
3. The evaluation feature shall not assume that the same metric interpretation is equally valid across `intent`, `requirements`, `design`, and `tasks`.
4. The evaluation feature shall make phase-specific metric selection explicit in derived artifacts.
5. The evaluation feature shall remain compatible with future expansion to implementation-oriented review without requiring redesign of the entire evaluation contract.

### Requirement 9: Review-Mode Distinction

**Objective:** As a researcher, I want manual dogfooding evidence and runtime-mediated evidence to remain distinguishable, so that early method-validation records are not silently mixed with later runtime-produced evidence.

#### Acceptance Criteria

1. The evaluation feature shall preserve `review_mode` or equivalent provenance needed to distinguish manual dogfooding review sessions from runtime-mediated review sessions.
2. The evaluation feature shall support excluding or separately slicing manual review evidence from standard runtime comparison sets.
3. The evaluation feature shall not treat ordinary editing activity as valid review evidence unless it is recorded through the manual review record contract.
4. The evaluation feature shall preserve when a comparison or metric output contains mixed review modes.
5. The evaluation feature shall make the handoff boundary between manual dogfooding and runtime-mediated evidence explicit in derived artifacts when both exist.
6. The evaluation feature shall own the standard comparison-population rule that manual dogfooding evidence is Phase 1 evidence and is excluded from standard runtime-mediated comparison sets unless explicitly included as a separate slice.

### Requirement 10: External Bundle Ingestion and Admission

**Objective:** As a central evaluator, I want portable evidence bundles collected in other local environments to be ingestible under explicit admission rules, so that cross-project analysis can grow without silently degrading provenance or comparability.

#### Acceptance Criteria

1. The evaluation feature shall define a central-side ingestion contract for portable evidence bundles.
2. The evaluation feature shall validate required provenance before admitting an imported bundle into standard analysis.
3. The evaluation feature shall distinguish imported runtime-mediated bundles from manually recorded dogfooding review sessions.
4. The evaluation feature shall support rejecting, downgrading to exploratory, or admitting imported bundles based on explicit admission rules.
5. The evaluation feature shall preserve which derived artifacts contain imported evidence and under what admission status.
