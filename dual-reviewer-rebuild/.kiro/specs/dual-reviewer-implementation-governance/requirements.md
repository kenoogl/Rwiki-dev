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
7. The governance feature shall make explicit that the phase-review metric register vocabulary (which includes `implementation`) is governance-owned and distinct from the runtime-owned phase/profile review vocabulary, so that downstream evaluation and paper-interface specs do not expect `implementation` in the runtime phase/profile slice.

### Requirement 8: Reference-Free Case Bootstrap and Minimal Heuristic Policy

**Objective:** As a maintainer starting a new case, I want a reference-free bootstrap path and minimal heuristic defaults, so that workflow entry does not depend on copying an older pilot case.

#### Acceptance Criteria

1. The governance feature shall define a reference-free bootstrap path as a first-class workflow entry for new cases.
2. The feature shall define repo-contained bootstrap artifacts or scripts that create the minimum case-control artifacts needed to begin from `intent`.
3. The feature shall define that reusable templates and gate structure may be reused, while case content must be derived from the provided source documents rather than copied from a pilot case.
4. The feature shall define a minimal heuristic policy in which `heuristic_profile_ref` may be omitted and the runtime uses track-specific repo-contained minimal templates by default.
5. The feature shall define canonical references for the bootstrap guide, bootstrap script, implementation protocol/snapshot templates, heuristic policy note, and track-level minimal heuristic templates.
6. The governance feature shall treat the v2-acquisition spec as the canonical owner of the heuristic-default behavior and minimal-template vocabulary; the references in AC 4 and AC 5 are subordinate to that ownership, and governance validation entries shall not mandatorily check these heuristic template artifacts until the v2-acquisition spec fixes the vocabulary.

### Requirement 9: Workflow Execution Ledger and Compliance Enforcement

**Objective:** As a maintainer, I want every prescribed workflow process to require a single-source-of-truth-derived execution ledger and a mechanical enforcement that blocks irreversible workflow progress until the ledger's prescribed stages are evidenced, so that prescribed stages cannot be silently compressed under momentum anywhere in the workflow.

In this requirement, a *prescribed workflow process* denotes any workflow process defined in `operations/WORKFLOW_OVERVIEW.md` — at minimum phase execution, review wave, alignment gate, reopen procedure, and cross-spec alignment — and is terminologically distinct from the spec-phase vocabulary fixed in `CONVENTIONS.md` section 3.

#### Acceptance Criteria

1. The governance feature shall require, at entry of any prescribed workflow process (including but not limited to phase execution, review wave, alignment gate, reopen procedure, and cross-spec alignment), a repo-contained execution ledger derived freshly from the canonical workflow documents before any drafting or substantive work in that process begins.
2. The ledger shall enumerate every prescribed stage of that process with at minimum stage name, source-of-truth citation (document and section), an evidence-based completion predicate, and an independence requirement identifying which separate process produces the stage evidence so the drafting author does not self-review.
3. The governance feature shall define each stage completion predicate as the existence and structural conformance of a repo-contained evidence artifact rather than an assertion, so that stage completion cannot be satisfied by appearance alone.
4. The governance feature shall require any cross-feature or cross-stage alignment stage to be produced by a process independent of the artifact author and shall record the independent-production marker in the ledger.
5. The governance feature shall provide a repo-contained validation entrypoint that, independently of the agent-authored ledger, re-derives the required stage set for the workflow process from the canonical workflow documents, compares it against the ledger, and treats any missing prescribed stage as a validation failure. This entrypoint extends the Requirement 5 governance-artifact validation entrypoint as a superset that adds workflow-process stage-set re-derivation, rather than constituting a separate, independently-maintained entrypoint. The re-derivation shall not share the ledger-generation logic or its parsed output and shall interpret the canonical source documents as an independent primary parse that does not depend on the ledger generator's output.
6. The governance feature shall define an enforcement point at irreversible workflow actions — at minimum spec.json approval or phase-transition writes, any irreversible workflow state change, and the generation or presentation of any human approval request (including a phase evidence summary or gate package) — that blocks the action unless the execution ledger exists and every ledger stage predicate and the independent re-derivation check pass.
7. The governance feature shall apply this ledger-and-enforcement contract uniformly to the workflow as a whole and to every prescribed workflow process, with no process exempt and without specialization to any particular workflow process or spec phase.
8. The governance feature shall require the human approval request for any workflow process to embed the ledger reconciliation mapping each stage to its evidence artifact path, so the non-spec.json approval path is not an unguarded bypass.
9. The governance feature shall preserve the existing reopen-propagation and cross-spec-alignment obligations when this contract changes completion criteria for multiple features, and shall require that the existing procedure documents governing those obligations — including the reopen procedure in `workflow-repair-procedure.md` — be synchronized so that the reopen path itself is subject to the execution ledger, independent re-derivation, and enforcement of this requirement rather than remaining an unguarded path.
10. The governance feature shall require that, for each prescribed workflow process, the authoritative source document that fixes its stage set is singular and explicitly designated, so that ledger derivation (AC 1) and the independent re-derivation (AC 5) read the same authority; which document is authoritative for each process is a design decision, but the single-authority property itself is a requirement-level invariant.
11. The governance feature shall treat any state in which the validation entrypoint, the independent re-derivation, or the execution ledger cannot produce a conclusive pass result — including absence, execution failure, or a canonical source too ambiguous to derive the stage set uniquely — as fail-closed, blocking the irreversible action rather than treating it as a pass.
