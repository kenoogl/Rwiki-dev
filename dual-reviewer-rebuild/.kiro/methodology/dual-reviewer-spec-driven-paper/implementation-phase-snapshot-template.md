# implementation-phase-snapshot-template

_purpose: reference-free case の implementation phase の metric snapshot を手作業で記録するためのひな型_
_正本参照: `.kiro/specs/dual-reviewer-implementation-governance` design「Owned Artifacts」「Metric Model」、requirements Requirement 8 受入 5、tasks Task 1／Task 6_

---

## 1. このひな型の役割

この文書は governance 所有の methodology artifact であり、reference-free case の implementation phase における conformance metric snapshot の記入様式を固定する。自動抽出未実装時は manual snapshot を許容する（design Metric Model）。

## 2. ヘッダ欄

- `case_slug` — 対象 case の slug
- `phase` — `implementation`
- `snapshot_at` — ISO 8601
- `reviewed_commit_or_branch` — 対象 commit / branch

## 3. conformance metric snapshot

design「Metric Model」の baseline metric を記録する。

- `conformance_findings_count`
- `severity_weighted_finding_score`
- `post_smoke_nonconformance_count`
- `fixture_bound_resolution_count`
- `heuristic_linkage_count`
- `placeholder_or_deferred_count`
- `review_artifact_presence_rate`
- `finding_to_signal_link_rate`

## 4. phase-review metric snapshot（implementation 段）

- phase-local issue count
- recheck count
- handback count
- `intent-attributed issue` count

## 5. 記入規律

- snapshot 値は対応する review artifact（`docs/reviews/*.md`）と conformance metric register（`docs/coordination/implementation-conformance-metric-register.md`）に整合させる。
- phase-review 段階語彙（`implementation` を含む）は governance 所有であり、runtime 所有の phase/profile 審査語彙とは別物として扱う。
