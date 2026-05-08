# Requirements Document

## Introduction

`dual-reviewer-foundation` は `dual-reviewer-rebuild` における最下層 contract を定義する spec である。本 spec は review runtime そのものではなく、runtime が依存する共通定義を提供する。再構築の主眼は、旧 repo の prototype 資産を流用しつつも、repo 外依存や運用依存を排除し、clone 直後から再現可能な foundation を作ることにある。

本 spec は以下を担う。

- review state machine の共通定義
- role と config の抽象 contract
- finding / judgment / review_case の schema
- prompt template の配置と versioning 規約
- pattern data source と terminology template の共通配置規約
- validator が前提とする metadata contract

本 spec は `intent/` と `operations/` の上位文書を入力とし、後続 spec (`dual-reviewer-runtime` / `dual-reviewer-evaluation` / `dual-reviewer-self-improvement` / `dual-reviewer-paper-interface`) の土台を提供する。

## Boundary Context

- **In scope**
  - Layer 1 review state machine definition
  - role abstraction (`primary_reviewer` / `adversarial_reviewer` / `judgment_reviewer`)
  - 共通 schema 5 file とその versioning 規約
  - judgment prompt template の canonical placement rule
  - pattern files (`seed_patterns.yaml` / `fatal_patterns.yaml`) の配置規約
  - config / terminology template の最小 contract
  - validator 用 metadata の required field 定義

- **Out of scope**
  - 実際の review orchestration
  - `dr-design` / `dr-log` / `dr-judgment` 相当の runtime 実装
  - treatment ごとの step 実行有無の決定
  - phase/profile ごとの review emphasis の具体挙動
  - prompt override の選択順序
  - step file naming や run directory layout の concrete storage
  - metrics extraction と figure generation
  - self-improvement proposal 生成そのもの
  - paper draft 生成
  - 外部 contributor data intake

- **Adjacent expectations**
  - `dual-reviewer-runtime` は本 spec の schema、prompt placement、config contract、state machine を import する
  - `dual-reviewer-evaluation` は本 spec の review metadata contract と schema に依存する
  - `dual-reviewer-self-improvement` は本 spec の finding / judgment / review_case schema に依存する
  - `dual-reviewer-paper-interface` は本 spec で定義される evidence fields を参照する

## Requirements

### Requirement 1: Review State Machine Contract

**Objective:** As a runtime implementer, I want a phase-independent review state machine contract, so that all downstream runtimes use the same conceptual pipeline and log structure.

#### Acceptance Criteria

1. The foundation shall define a canonical 4-step review pipeline consisting of Step A (`primary detection`), Step B (`adversarial review`), Step C (`judgment`), and Step D (`integration`).
2. The foundation shall define these steps as a logical contract only; execution order, retries, and user interaction timing are runtime responsibilities.
3. The foundation shall define required state transition names so that logs can refer to the same conceptual stages across implementations.
4. The foundation shall distinguish Step B forced-divergence behavior from Step C necessity judgment behavior as separate roles and separate output intents.
5. The foundation shall define the minimum run metadata required to bind each review event to a protocol version, prompt version, runtime version, target artifact hash, phase/profile, treatment, and operator sign-off status.
6. The foundation shall define step identity and transition labels as shared contract only, while leaving concrete step storage layout and execution control to runtime.

### Requirement 2: Role and Config Abstraction

**Objective:** As a maintainer, I want reviewer roles and model configuration to be abstract, so that model substitutions do not force spec rewrites.

#### Acceptance Criteria

1. The foundation shall refer to reviewer roles only by abstract names: `primary_reviewer`, `adversarial_reviewer`, and `judgment_reviewer`.
2. The foundation shall not embed vendor-specific model names in the framework definition or schema field names.
3. The foundation shall define a minimum config contract containing at least model identifiers per role, project language, protocol version, and evidence output location fields.
4. The foundation shall define config as runtime input, not as hidden operator memory.
5. The foundation shall define terminology and config templates as repo-contained files.

### Requirement 3: Shared Schema Set

**Objective:** As a runtime and evaluation implementer, I want a shared schema set for review evidence, so that review output, validation, and analysis operate on the same contracts.

#### Acceptance Criteria

1. The foundation shall provide at minimum the following schema files: `review_case`, `finding`, `impact_score`, `failure_observation`, and `necessity_judgment`.
2. The foundation shall define a placement rule that keeps these schema files under a single repo-contained schema directory.
3. The foundation shall require versioned schema artifacts and forbid silent incompatible edits.
4. The `review_case` contract shall support run-level metadata needed for reproducibility and invalidation checks.
5. The `finding` contract shall support source attribution, severity, counter-evidence linkage, judgment linkage, and human decision linkage.
6. The `necessity_judgment` contract shall support the 5-field necessity structure, final label, recommended action, and optional override reason.
7. The foundation shall specify which fields are mandatory for B-1.0-equivalent operation and which future extension points are intentionally deferred.
8. The foundation shall define the schema field labels in English even when descriptive free-text content is written in Japanese.

### Requirement 4: Canonical Prompt Placement

**Objective:** As a runtime implementer, I want canonical prompt placement and version rules, so that prompt behavior is reproducible and drift is detectable.

#### Acceptance Criteria

1. The foundation shall define a canonical in-repo location for the judgment prompt template.
2. The foundation shall require prompt version traceability from each run record to the prompt artifact used.
3. The foundation shall treat prompt templates as versioned artifacts, not implicit operator knowledge.
4. The foundation shall define prompt placement rules that downstream runtime code can locate using relative repo paths only.
5. The foundation shall require that prompt content updates be detectable through ordinary repository diff history.

### Requirement 5: Pattern and Terminology Assets

**Objective:** As a runtime and self-improvement implementer, I want stable pattern and terminology asset contracts, so that reusable knowledge can be attached without changing runtime code.

#### Acceptance Criteria

1. The foundation shall define canonical placement rules for `seed_patterns.yaml` and `fatal_patterns.yaml`.
2. The foundation shall preserve the distinction between reusable seed patterns and project-accumulated patterns.
3. The foundation shall define a terminology template artifact with explicit versioning and an empty initial entries structure.
4. The foundation shall define pattern assets as data sources, not embedded constants in runtime code.
5. The foundation shall leave matching logic and quota logic out of scope for this spec.

### Requirement 6: Validator-Oriented Metadata Contract

**Objective:** As a validation implementer, I want required metadata fields that support reproducibility and invalidation, so that valid and invalid runs can be separated mechanically.

#### Acceptance Criteria

1. The foundation shall define required run metadata fields needed by validators.
2. The foundation shall include fields for protocol version, prompt version, runtime version, target artifact hash, phase/profile, treatment, review mode, run status, validator status, human sign-off status, and evidence class.
3. The foundation shall define how invalidation markers are attached to run records without mutating raw evidence.
4. The foundation shall define that missing required metadata causes validator failure.
5. The foundation shall support downstream evaluation and self-improvement specs in excluding invalid runs by metadata alone.
6. The foundation shall define a canonical review-mode vocabulary sufficient to distinguish at minimum manual dogfooding review records from runtime-mediated review records.
7. The foundation shall define canonical provenance field names sufficient to identify at minimum source repository identity and source revision for cross-project evidence intake.

### Requirement 7: Repo-Contained Asset Rule

**Objective:** As a rebuild maintainer, I want all foundation-critical assets to live inside the repository, so that runtime behavior is not dependent on external memory or hidden environment state.

#### Acceptance Criteria

1. The foundation shall require all prompts, schemas, templates, and pattern assets needed for runtime behavior to be stored inside the repository.
2. The foundation shall forbid steady-state dependence on repo-external memory files for runtime-critical behavior.
3. The foundation shall allow environment-level configuration only when explicitly modeled in config and recorded in run metadata.
4. The foundation shall define repo-contained artifacts as the normative source for downstream runtime behavior.

## Change Intent

この spec は旧 repo の foundation spec を簡略化して捨てたのではなく、再構築の初期段階で必要な contract に絞り込み、運用依存だった部分を repo-contained / validator-aware / traceable に引き直すことを目的とする。
