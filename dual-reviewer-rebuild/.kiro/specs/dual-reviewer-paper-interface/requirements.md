# Requirements Document

## Introduction

`dual-reviewer-paper-interface` は runtime と evaluation の出力を、paper-facing artifact に変換する interface feature である。本 spec は論文そのものの執筆を扱うのではなく、研究報告や論文化に必要な structured inputs をどのように受け取り、どう整理するかを定義する。

本 spec の重要な制約は、paper convenience が runtime rule を逆流的に変えてはならないことである。

## Boundary Context

- **In scope**
  - claim mapping
  - required paper inputs
  - figure / table input contracts
  - caveat and limitation tracking
  - paper-facing derived report fragments

- **Out of scope**
  - runtime rule definition
  - evaluation metric definition
  - full manuscript drafting workflow
  - external submission packaging

- **Adjacent expectations**
  - `dual-reviewer-evaluation` から comparison-ready data を受け取る
  - `dual-reviewer-foundation` の evidence field naming に依存する
  - `dual-reviewer-self-improvement` とは改善 proposal と paper narrative を混同しない

## Requirements

### Requirement 1: Claim-to-Evidence Mapping

**Objective:** As an author, I want explicit mapping from claims to evidence sources, so that paper-facing assertions remain traceable to runtime and evaluation artifacts.

#### Acceptance Criteria

1. The paper-interface feature shall define how claims map to concrete evidence sources.
2. The paper-interface feature shall preserve run and analysis provenance for each claim-supporting artifact.
3. The paper-interface feature shall distinguish direct evidence from caveated or preliminary evidence.
4. The paper-interface feature shall consume evaluation outputs and shall not directly re-interpret raw logs; when evaluation outputs do not exist, it shall require the evaluation process to be run rather than accessing raw logs directly.
5. The paper-interface feature shall not allow claim-supporting artifacts that cannot be traced to versioned evidence.
6. The paper-interface feature shall define a claim as a paper-facing assertion that serves as the unit of claim-to-evidence mapping, requiring at minimum that each claim carries an identifier and an explicit evidence-source linkage, so that Requirements 1 through 3 remain testable.

### Requirement 2: Paper-Facing Data Contract

**Objective:** As a downstream reporting consumer, I want stable input contracts for paper-facing tables, figures, and summaries, so that reporting can be regenerated without changing runtime semantics.

#### Acceptance Criteria

1. The paper-interface feature shall define required fields for figure and table source artifacts.
2. The paper-interface feature shall require provenance linkage back to evaluation outputs.
3. The paper-interface feature shall keep paper-facing artifacts separate from raw evidence and core evaluation outputs.
4. The paper-interface feature shall support regeneration when upstream evaluation outputs are unchanged.
5. The paper-interface feature shall not force runtime or foundation schema changes solely for formatting convenience.
6. The paper-interface feature shall require regeneration of paper-facing artifacts when their upstream evaluation outputs are marked stale due to run invalidation, not only when those outputs change.

### Requirement 3: Caveat and Limitation Tracking

**Objective:** As an author, I want caveats and limitations to remain attached to reporting artifacts, so that narrative simplification does not erase methodological constraints.

#### Acceptance Criteria

1. The paper-interface feature shall preserve caveat metadata associated with evidence sources.
2. The paper-interface feature shall distinguish invalid-data exclusions, partial evidence, and methodological limitations.
3. The paper-interface feature shall allow paper-facing summaries to reference caveats without re-reading raw archives manually.
4. The paper-interface feature shall support preliminary labeling where evidence is intentionally incomplete.
5. The paper-interface feature shall not upgrade caveated evidence to strong evidence silently.

### Requirement 4: Separation from Runtime and Evaluation Logic

**Objective:** As a maintainer, I want the paper-facing layer to consume but not govern lower layers, so that reporting needs do not distort runtime or evaluation behavior.

#### Acceptance Criteria

1. The paper-interface feature shall consume outputs from evaluation rather than directly modifying evaluation rules.
2. The paper-interface feature shall not define runtime-critical metadata requirements independently of foundation.
3. The paper-interface feature shall not override invalidation policy.
4. The paper-interface feature shall treat paper convenience as subordinate to reproducibility and validity.
5. The paper-interface feature shall make downstream narrative transformations explicit and versionable.

### Requirement 5: Preliminary vs Mature Evidence Distinction

**Objective:** As a researcher, I want paper-facing artifacts to distinguish mature evidence from exploratory or preliminary evidence, so that reporting accuracy is preserved.

#### Acceptance Criteria

1. The paper-interface feature shall support explicit labeling of preliminary evidence.
2. The paper-interface feature shall preserve whether evidence comes from a stable comparison set or from exploratory analysis.
3. The paper-interface feature shall allow mixed-maturity reporting only when the distinction remains visible.
4. The paper-interface feature shall not collapse mature and preliminary evidence into the same undifferentiated artifact.
5. The paper-interface feature shall preserve traceability needed for later refinement or replacement.
6. The paper-interface feature shall use a single unified evidence-classification vocabulary across Requirements 1, 3, and 5, bound to the foundation canonical evidence-class field, rather than maintaining independent per-requirement classification terms.

### Requirement 6: Review-Mode Provenance in Reporting

**Objective:** As an author, I want paper-facing artifacts to preserve whether supporting evidence came from manual dogfooding review or runtime-mediated review, so that early method-validation records are not overstated as runtime evidence.

#### Acceptance Criteria

1. The paper-interface feature shall preserve review-mode provenance for paper-facing artifacts.
2. The feature shall allow manual dogfooding evidence to be reported separately from runtime-mediated evidence.
3. The feature shall not present manual review records as runtime-produced evidence without explicit labeling.
4. The feature shall support caveat attachment when mixed review modes appear in the same report set.
5. The feature shall preserve traceability needed to replace early manual evidence with later runtime-mediated evidence.
