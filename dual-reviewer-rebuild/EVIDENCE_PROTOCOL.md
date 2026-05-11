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

## Pruning Trace Retention Rule

- pruning, ablation, treatment decomposition, or rollback の途中 run は、未追跡であっても即時 discard 候補とみなしてはならない
- これらの raw artifact は、rule 変更の因果や一般化過程を後から説明する evidence 候補になりうる
- 削除や物理整理の前に、少なくとも次の 3 区分で一覧化する
  - `must keep`
  - `hold for decision`
  - `safe to discard`
- `must keep` の最低条件:
  - comparison summary に採用された run
  - rollback 判断の根拠になった run
  - pruning branch point を示す run
- operator は、物理削除前にこの分類結果を明示し、承認を得なければならない

## Destructive-Action Rule

- raw evidence, portable bundles, runtime run directories, protocol rerun outputs に対する物理削除は destructive action とみなす
- destructive action は、対象一覧の提示と明示承認の後にのみ実施できる
- `git status` 上で未追跡であることだけを理由に削除してはならない
