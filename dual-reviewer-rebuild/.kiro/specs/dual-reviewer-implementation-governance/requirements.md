# Requirements Document

## Introduction

`dual-reviewer-implementation-governance` は、`dual-reviewer-rebuild` における
implementation 完了判定と review evidence の扱いを定義する cross-cutting spec である。

既存 feature spec は artifact placement、schema、runtime、evaluation、learning、
paper export を定義しているが、prototype 実装後に

- 実装が spec を守っているか
- fixture / heuristic 依存が残っていないか
- finding が証跡として残るか

を横断確認する workflow contract は独立して定義されていなかった。

本 spec はその不足を補い、implementation completion rule を明文化する。

## Boundary Context

- **In scope**
  - `intent review` の artifact contract
  - post-implementation `implementation conformance review` の定義
  - conformance finding の severity と disposition rule
  - review artifact placement rule
  - conformance metric definition
  - phase-review metric definition
  - finding と signal / coordination の接続 rule
  - governance artifact の最小 validation

- **Out of scope**
  - 各 feature の business logic 修正
  - runtime/evaluation/self-improvement/paper-interface の具体的挙動変更
  - PR 運用や external CI の詳細
  - human reviewer assignment policy

- **Adjacent expectations**
  - foundation/runtime/evaluation/self-improvement/paper-interface は本 spec の completion rule に従う
  - `docs/coordination/` と `docs/reviews/` は本 spec の artifact placement rule に従う

## Requirements

### Requirement 1: Post-Implementation Conformance Review

**Objective:** As a maintainer, I want a mandatory post-implementation review stage, so that implementation completion is not decided by smoke pass alone.

#### Acceptance Criteria

1. The governance feature shall define `implementation conformance review` as a required stage after implementation and relevant smoke validation.
2. The feature shall define the review focus to include at minimum specification conformance, boundary conditions, and evidence traceability.
3. The feature shall define when conformance review must be run, including at least prototype completion, pre-push or pre-PR checkpoints, and after changes to trust boundary, invalidation, provenance, or approval/adoption logic.
4. The feature shall define that an implementation checkpoint is not fully closed until conformance review has either no findings or recorded findings with explicit disposition.

### Requirement 2: Review Artifact and Finding Contract

**Objective:** As a reviewer, I want conformance findings to be preserved as structured review evidence, so that implementation issues can be tracked across fixes and rechecks.

#### Acceptance Criteria

1. The governance feature shall define a canonical location for conformance review artifacts under a repo-contained review directory.
2. The feature shall define a minimum review artifact content set including reviewed scope, reviewed commit or branch, validation rerun summary, findings, severity, recommended action, and disposition summary.
3. The feature shall define severity classes for findings and distinguish at least critical implementation nonconformance from lower-severity boundary or traceability risks.
4. The feature shall define that open findings must link to either the implementation signal register, the coordination log, or both.
5. The feature shall provide a reusable review template so that subsequent reviews do not drift in structure.

### Requirement 3: Conformance Metric Register

**Objective:** As a maintainer, I want measurable conformance review outputs, so that the review stage itself does not become a ceremonial step.

#### Acceptance Criteria

1. The governance feature shall define a canonical metric register for conformance review.
2. The feature shall define metrics for at minimum finding count, severity-weighted finding score, post-smoke nonconformance count, fixture-bound resolution count, heuristic linkage count, and review artifact presence rate.
3. The feature shall define the meaning, collection timing, and interpretation for each metric.
4. The feature shall allow manual snapshot collection when automatic extraction is not yet implemented.

### Requirement 4: Signal and Handback Integration

**Objective:** As an implementation coordinator, I want conformance findings to feed existing signal and handback mechanisms, so that workflow governance does not create an isolated review silo.

#### Acceptance Criteria

1. The governance feature shall define how conformance findings map into `implementation-signal-register`.
2. The feature shall define how findings relate to handback classes `A`, `B`, `C`, and intent-level handback.
3. The feature shall define that unresolved findings affecting trust boundary, invalidation, provenance, or approval/adoption logic are not silently ignored.
4. The feature shall preserve the distinction between implementation-only fixes and findings that require design, requirements, or intent reopen.

### Requirement 5: Governance Artifact Validation

**Objective:** As a maintainer, I want governance artifacts to be mechanically checkable, so that review workflow changes remain reproducible and repo-contained.

#### Acceptance Criteria

1. The governance feature shall provide a repo-contained validation entrypoint for conformance review artifacts and metric register artifacts.
2. The validation entrypoint shall check the presence of required governance documents and review template artifacts.
3. The validation entrypoint shall check that conformance review artifacts include the minimum required sections and metric keys.
4. The feature shall provide at least one concrete review artifact that passes the validation entrypoint.

### Requirement 6: Workflow Gate Status and Cross-Spec Alignment

**Objective:** As a maintainer, I want governance changes themselves to pass the declared workflow gates, so that workflow enforcement does not drift outside the workflow it governs.

#### Acceptance Criteria

1. The governance feature shall require a cross-spec alignment review when a governance rule changes completion criteria for multiple features.
2. The feature shall require a repo-contained artifact that records current workflow gate status for the repository.
3. The feature shall distinguish `completed` from `completed_with_open_findings` for implementation checkpoints.
4. The feature shall require governance spec metadata to reflect whether cross-spec alignment was required and completed.
5. The feature shall support intent-triggered reopen propagation, where an intent change can invalidate downstream requirements, design, and tasks checkpoints.

### Requirement 7: Intent Review and Phase-Review Metrics

**Objective:** As a maintainer, I want intent review and phase-level measurement to be part of the governance spec, so that upstream intent changes and downstream intent-attributed problems are recorded in the same workflow system.

#### Acceptance Criteria

1. The governance feature shall define `intent review` as a first-class review stage in the repository workflow.
2. The feature shall define a canonical template and at least one concrete artifact for `intent review`.
3. The feature shall define `intent_revision_count` and `intent_handback_count` as intent-phase metrics.
4. The feature shall define that issues observed in downstream phases may be recorded as `intent-attributed` without reclassifying them as intent-phase issues.
5. The feature shall define a canonical phase-review metric register that covers at minimum `intent`, `requirements`, `design`, `tasks`, and `implementation`.
6. The feature shall require the governance artifact validator to check the presence of the intent review template, a concrete intent review artifact, and the phase-review metric register.

### Requirement 8: Reference-Free Case Bootstrap and Minimal Heuristic Policy

**Objective:** As a maintainer starting a new case, I want a reference-free bootstrap path and minimal heuristic defaults, so that workflow entry does not depend on copying an older pilot case.

#### Acceptance Criteria

1. The governance feature shall define a reference-free bootstrap path as a first-class workflow entry for new cases.
2. The feature shall define repo-contained bootstrap artifacts or scripts that create the minimum case-control artifacts needed to begin from `intent`.
3. The feature shall define that reusable templates and gate structure may be reused, while case content must be derived from the provided source documents rather than copied from a pilot case.
4. The feature shall define a minimal heuristic policy in which `heuristic_profile_ref` may be omitted and the runtime uses track-specific repo-contained minimal templates by default.
5. The feature shall define canonical references for the bootstrap guide, bootstrap script, implementation protocol/snapshot templates, heuristic policy note, and track-level minimal heuristic templates.
