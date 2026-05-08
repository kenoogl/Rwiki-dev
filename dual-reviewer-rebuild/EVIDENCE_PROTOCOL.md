# EVIDENCE_PROTOCOL

## Required Evidence Classes

- review_case log
- finding-level decisions
- judgment overrides
- counter-evidence
- run metadata
- invalidation markers

## Storage Rule

- raw run output goes under `experiments/runs/`
- derived analysis goes under `experiments/analysis/`
- learning proposals go under `learning/proposals/`
- manual review records go under `reviews/manual/sessions/`

## Manual Review Baseline Rule

- manual review records stored under `reviews/manual/sessions/` shall be treated as `manual single-review dogfooding baseline`
- these records are valid evidence for method validation, workflow tracing, and early baseline extraction
- these records shall not enter the standard runtime-mediated comparison population by default
- any analysis that includes both manual review records and runtime-mediated evidence shall preserve the distinction explicitly

## Portable Bundle Principle

- evidence collected outside the central rebuild repository shall be moved as a portable bundle, not as undocumented ad-hoc copies
- a portable bundle shall preserve run metadata, provenance, validation artifacts, and review-mode identity together
- central-side ingestion shall reject or downgrade bundles that cannot preserve required provenance

## Minimum Cross-Project Provenance

- `source_repository_id`
- `source_revision`
- `target_id`
- `target_artifact_hash`
- `protocol_version`
- `runtime_version`
- `prompt_set_version`
- `schema_set_version`
- `review_mode`
- `operator_identity_label`

## Admission Principle

- runtime-produced external bundles may enter central comparative analysis only after ingestion validation
- exploratory or provenance-insufficient bundles shall remain separable from the standard comparison population
- manual dogfooding review records and runtime-mediated bundles shall not be silently mixed
