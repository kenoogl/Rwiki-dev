# Requirements Document

## Introduction

`dual-reviewer-generic-execution-layer-v2` は、
case-specific heuristic pilot を置換する
generic execution layer v2 の主正本 feature である。

本 feature の中心は runtime 的再設計だが、
単一 module の局所改善ではない。
`Intent / Spec / Implementation` の 3 track を共通 execution contract で扱い、
`foundation / evaluation / self-improvement / paper-interface`
への波及を coordination 対象として明示的に管理する。

本 feature は
[execution-control-ledger.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/execution-control-ledger.md:1)
を redesign input ledger とし、
[generic-execution-layer-v2-spec.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/generic-execution-layer-v2-spec.md:1)
を上位仕様とする。

## Boundary Context

- **Primary ownership**:
  - runtime-centered cross-track redesign
- **In scope**:
  - generic execution contract
  - Case Manifest / Analysis / Decision / Writer の layer 分離
  - case-aware branch の除去
  - taxonomy-first finding 表現
  - cross-feature coordination rule
- **Out of scope**:
  - v2 実装の完全完了
  - main evidence claim の更新
  - downstream feature の詳細設計確定
- **Coordination targets**:
  - `dual-reviewer-foundation`
  - `dual-reviewer-runtime` 相当 runtime 実体
  - evaluation pipeline
  - self-improvement pipeline
  - paper-interface pipeline

## Requirements

### Requirement 1: New Feature Ownership and Coordination

**Objective:** As a maintainer of the v2 redesign effort, I want the generic execution layer to be managed as a new primary feature with explicit cross-feature coordination, so that runtime-centered redesign does not get fragmented across foundation, evaluation, self-improvement, and paper-interface artifacts.

#### Acceptance Criteria

1. The feature shall treat `dual-reviewer-generic-execution-layer-v2` as the primary authoritative feature for the v2 execution-layer redesign, rather than distributing the redesign contract across existing feature specs.
2. The feature shall declare `foundation`, `runtime`, `evaluation`, `self-improvement`, and `paper-interface` as coordination targets and shall not treat downstream impact on those areas as implicit.
3. The feature shall distinguish between `primary ownership` and `coordination ownership`, where primary ownership remains in this feature and downstream updates may be absorbed here or handed back as follow-on work.
4. The feature shall define handback criteria for when a change can be absorbed within this feature and when a downstream feature-specific reopen is required.
5. The feature shall preserve `ACTIVE_WORKLIST` as the execution-control artifact and shall treat this feature spec as the authoritative redesign spec input/output, not as the control board itself.

### Requirement 2: Generic Execution Contract

**Objective:** As a designer of the v2 system, I want all three tracks to run on a common execution contract, so that the system can compare and evolve behavior without case-specific branching in the core rule layer.

#### Acceptance Criteria

1. The feature shall define a common execution contract shared by `Intent Track`, `Spec Track`, and `Implementation Track`.
2. The common execution contract shall include at least the following common inputs: `track`, `target_id`, `target_artifact_hash`, `source_repository_id`, `source_revision`, `phase_profile`, `treatment`, `review_mode`, `source_refs`, `governance_refs`, and `case_manifest_ref`.
3. The common execution contract shall include at least the following common intermediate objects: `evidence_observation`, `review_issue_candidate`, `caveat_candidate`, `reopen_candidate`, and `signal_candidate`.
4. The common execution contract shall include at least the following common outputs: `review_artifact`, `metric_snapshot`, `trace_note`, `signal_linkage_note`, and `run_manifest`.
5. The feature shall allow track-specific input differences, but those differences shall be expressed as input contract specialization rather than case-specific rule branches.
6. The feature shall preserve `treatment` as a first-class execution input so that `single`, `dual`, and `dual+judgment` style treatment differences remain comparable in downstream evaluation, self-improvement intake, and paper-facing reporting.
7. The feature shall preserve `target_id` as a run-level identity field for traceability and downstream reuse, while prohibiting its use as a case-specific branching trigger in the core execution rule layer.
8. The feature shall preserve `target_artifact_hash`, `source_repository_id`, and `source_revision` as run-level provenance fields unless an explicit foundation handback updates the shared metadata contract.

### Requirement 3: Layer Separation

**Objective:** As a maintainer of the execution layer, I want manifest handling, analysis, decision, and artifact writing to be separated into distinct layers, so that case registration, review logic, and artifact serialization do not collapse into the same code path.

#### Acceptance Criteria

1. The feature shall define a `Case Manifest Layer` responsible for case identity, refs, batch grouping, and pilot scope.
2. The feature shall define an `Analysis Layer` responsible for reading input artifacts, extracting evidence, and mapping observations into generic taxonomy candidates.
3. The feature shall define a `Decision Layer` responsible for severity, necessity, reopen depth, and handback classification decisions.
4. The feature shall define a `Writer Layer` responsible for serializing already-determined review results into runtime and protocol artifacts.
5. The Writer Layer shall not generate case-specific review findings by itself.
6. The Analysis Layer may be track-aware but shall not be case-aware.
7. The Case Manifest Layer may contain case-specific refs and scope metadata but shall not contain review rules.

### Requirement 4: Elimination of Case-Specific Core Branching

**Objective:** As a maintainer replacing the heuristic pilot, I want case identity to stop controlling core review behavior, so that onboarding a new case does not require modifying execution logic.

#### Acceptance Criteria

1. The feature shall prohibit analyzer selection by `case_id` string matching.
2. The feature shall prohibit runtime review activation or finding generation by `target_id` string matching.
3. The feature shall prohibit writer-generated fixed issue summaries that are specific to a single case.
4. The feature shall prohibit core reopen, signal, or handback rules that depend on a single hardcoded spec path.
5. The feature shall treat the `remove` entries in the `ECL` as mandatory redesign targets.
6. The feature shall treat the `migrate to case manifest` entries in the `ECL` as manifest-layer migration targets rather than leaving them in runtime logic.

### Requirement 5: Taxonomy-First Finding Representation

**Objective:** As a designer of cross-case review outputs, I want findings to be represented first by taxonomy and only second by case-specific wording, so that comparison and downstream reuse remain stable across cases.

#### Acceptance Criteria

1. The feature shall define generic first-class categories for at least `gap type`, `inconsistency type`, `caveat type`, and `propagation type`.
2. The feature shall allow case-specific wording in rendered findings, but the underlying representation shall be taxonomy-based.
3. Case-specific details shall be preserved in input refs, extracted evidence excerpts, and final rendered text, but not in the execution rule itself.
4. The feature shall support at least the taxonomy families identified in the v2 upper spec, including phase contract gaps, cross-phase inconsistencies, scope-boundary caveats, and propagation/handback classes.
5. Downstream consumers shall be able to read the same taxonomy objects without depending on case names embedded in summary text.

### Requirement 6: Track-Specific Contracts

**Objective:** As a maintainer of three entry conditions, I want each track to have an explicit minimal input contract, so that track differences stay in declared inputs rather than ad hoc implementation branches.

#### Acceptance Criteria

1. The feature shall define an `Intent Track` minimal input contract including `intent_ref`, `supporting_refs`, and `traceability_refs`.
2. The feature shall define a `Spec Track` minimal input contract including `reviewed_phase`, `reviewed_phase_ref`, `adjacent_phase_refs`, and `alignment_refs`.
3. The feature shall define an `Implementation Track` minimal input contract including `implementation_snapshot_ref`, `upstream_spec_refs`, `governance_refs`, and `target_artifact_hash`.
4. The feature shall define for each track the primary observation classes it is expected to emit.
5. Track-specific input contracts shall remain compatible with the common execution contract in Requirement 2.

### Requirement 7: Downstream Compatibility and Handback Rules

**Objective:** As a maintainer of surrounding systems, I want v2 output changes to be governed by explicit compatibility and handback rules, so that downstream artifacts can evolve without accidental schema drift or silent breakage.

#### Acceptance Criteria

1. The feature shall identify whether each v2 contract change is absorbed locally or requires handback to `foundation`, `evaluation`, `self-improvement`, or `paper-interface`.
2. The feature shall require handback when taxonomy or metadata changes affect shared schema or vocabulary contracts.
3. The feature shall require handback when output artifact shape changes affect evaluation intake, signal intake, or paper-facing reporting builders.
4. The feature shall allow local absorption when a change is internal to manifest wiring or runtime layer separation and does not alter shared external contracts.
5. The feature shall preserve enough compatibility that the `phase-field` pilot can be re-acquired and compared after v2 replacement.

### Requirement 8: Requirements-Phase Coordination Gate

**Objective:** As a maintainer running this feature through the workflow, I want the requirements-phase cross-feature coordination gate to have explicit pass criteria, so that `requirements review`, `feature 間調整`, and `approval gate` do not rely on tacit judgment.

#### Acceptance Criteria

1. The feature shall define a requirements-phase coordination check that is executed before this feature is treated as requirements-approved.
2. The requirements-phase coordination check shall explicitly inspect at least the following categories named by the workflow: shared metadata contract, invalidation rule, prompt/schema/artifact dependencies, and responsibility boundary.
3. The feature shall identify for each coordination target whether the v2 change is:
   - absorbed inside this feature,
   - handed back to an existing feature spec, or
   - deferred as follow-on work after approval.
4. The feature shall require that unresolved coordination items be recorded as blockers rather than allowing the feature to advance implicitly to design.
5. The feature shall produce an explicit coordination outcome artifact or checklist that can be used at the requirements approval gate.
6. The requirements-phase coordination check shall explicitly identify whether v2 changes alter the conditions under which runs, findings, or bundled evidence are treated as valid, invalid, or comparison-ineligible.

### Requirement 9: Foundation Handback Rule

**Objective:** As a maintainer coordinating v2 with shared contracts, I want the conditions for reopening or updating foundation-owned contracts to be explicit, so that shared metadata, schema, and vocabulary changes do not get silently absorbed in runtime-only design.

#### Acceptance Criteria

1. The feature shall treat changes to shared metadata fields, shared schema shape, or shared controlled vocabulary as foundation-impacting changes.
2. When a v2 change affects shared metadata fields, shared schema shape, or shared controlled vocabulary, the feature shall require explicit foundation handback or equivalent foundation-owned contract update before design approval.
3. The feature shall distinguish foundation-impacting changes from runtime-local refactors, and shall not require foundation handback for runtime-only internal separations that leave shared contracts unchanged.
4. The feature shall identify the authoritative shared-contract update targets when foundation handback is required, including metadata contract, schema contract, and vocabulary/terminology contract as applicable.
5. The feature shall not allow taxonomy-first redesign to introduce new shared contract expectations without also identifying whether foundation must be reopened.

### Requirement 10: Replacement Path and Success Criteria

**Objective:** As a maintainer driving the redesign forward, I want a fixed replacement path from upper spec to implementation rerun, so that v2 work proceeds by spec-driven development rather than by direct opportunistic patching.

#### Acceptance Criteria

1. The feature shall treat the current requirements document as the first spec phase for v2 and shall require subsequent `design` and `tasks` artifacts before implementation replacement proceeds.
2. The feature shall define replacement planning in the order `requirements -> design -> tasks -> implementation -> pilot rerun`.
3. The feature shall treat `phase-field` pilot reacquisition as the first post-replacement validation target.
4. The feature shall not allow `main evidence` promotion before generic execution layer replacement and pilot reacquisition are completed.
5. The feature shall define completion for this feature as the point where `ECL` mandatory removals are absorbed into the v2 architecture and the v2 design can drive implementation work without introducing case-specific rule branches again.
