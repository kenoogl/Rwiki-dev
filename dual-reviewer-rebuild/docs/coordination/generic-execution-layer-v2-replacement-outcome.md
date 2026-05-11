# generic execution layer v2 replacement outcome

## 1. この文書の役割

この文書は、`dual-reviewer-generic-execution-layer-v2` の implementation replacement 後に、

- `phase-field` pilot rerun がどこまで再取得できたか
- 何が既に v2 path へ移ったか
- 何がまだ reopen item として残っているか
- なぜまだ `main evidence` へ昇格しないか

を固定するための outcome note である。

この文書は feature 完了宣言ではない。
`first validation result` と `remaining reopen item register` を残し、
pilot reacquisition 完了までを閉じるための記録である。

## 2. Reacquired Outputs

### 2.1 Intent Track

- batch:
  [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild/comparison_summary.json:1)
- status:
  reacquired through runtime-mediated v2 path with legacy protocol artifacts preserved
- key observations:
  - `single_review` findings: `2`
  - `dual_reviewer_workflow` findings: `3`
  - dual run requires intent handback: `true`
  - `v2/` internal artifacts are emitted alongside legacy intent-track artifacts

### 2.2 Spec Track

- tasks batch:
  [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec/comparison_summary.json:1)
- requirements batch:
  [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-requirements-phase-field-reverse-spec/comparison_summary.json:1)
- design batch:
  [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-design-phase-field-reverse-spec/comparison_summary.json:1)
- status:
  reacquired through runtime-mediated v2 path with reviewed-phase protocol artifacts preserved
- key observations:
  - tasks case still records reopen requirement toward `design` / `tasks`
  - requirements case still records downstream approval gap and clean-room boundary pressure
  - design case still records boundary-density and validation-ownership concerns
  - `v2/` internal artifacts are emitted alongside reviewed-phase note / alignment artifact / metrics

### 2.3 Implementation Track

- batch:
  [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F1-phase-field-cpp/comparison_summary.json:1)
- status:
  reacquired through v2 runtime path
- key observations:
  - `single_review` findings: `2`
  - `dual_reviewer_workflow` findings: `3`
  - `dual_minus_single_findings`: `1`
  - adversarial role is preserved in dual run
  - `v2/review_artifact.json`, `v2/metric_snapshot.json`, `v2/trace_note.json`, `v2/signal_linkage_note.json` are emitted with compatibility projection

## 3. What Was Replaced

- case-specific input wiring was moved into case manifests for `intent`, `spec`, and `implementation`
- `runtime/execution_v2/` now owns:
  - common execution contract
  - track specialization
  - case manifest validation
  - rule-match analysis for profile-backed runtime findings
  - observation-first step payload emission for implementation runtime runs
  - v2 review artifact writing
  - compatibility projection
- reusable seed pattern vocabulary now exists so heuristic profiles can point at named review concerns instead of embedding every match term inline
- `implementation` runs now emit taxonomy-based:
  - evidence observations
  - review issue candidates
  - reopen candidates
  - signal candidates
- `implementation` runtime runs now also preserve explicit step-level observations in `steps/*.json` and `review_case.json`, so findings are no longer the earliest analysis object
- those observations now carry `evidence_types`, `review_focuses`, and matched pattern IDs, so the runtime artifact records what kind of implementation concern was detected instead of preserving only raw term hits
- implementation rules can now require specific `evidence_types` and `counter_evidence_types`, so observation creation is no longer just one-term-hit driven
- implementation rules can now also require source kinds such as `implementation_snapshot` and `upstream_spec`, so observation creation depends on both evidence type and document-role coverage
- implementation runtime runs now preserve explicit `evidence_records`, so observation and finding both point back to a concrete intermediate evidence object rather than collapsing directly to matched refs
- those `evidence_records` are now section-scoped and retain heading / line-range context, so the runtime artifact captures document structure in addition to raw term matches
- implementation rules can now also require `section_class` such as `snapshot_rationale` and `acceptance_criteria`, so observation creation depends on document-structure class as well as source kind and evidence type
- implementation rules can now emit structural-support evidence records from document-role + section-class conditions alone, so the evidence layer is no longer purely term-triggered
- the primary boundary / update-order path can now be satisfied from actual evidence records created by document-role + fragment-class structure, so part of the implementation track has moved from `pattern-first` to `structure-first`
- parameter-related implementation evidence is now filtered through fragment classes such as `parameter_review_rationale`, `parameter_caveat_note`, and `parameter_contract`, which narrows broad section matches into smaller line-role units
- fragment-class cue rules are now loaded from `runtime/patterns/seed_patterns.yaml` instead of being embedded in Ruby conditionals, so the remaining heuristic surface is more explicitly data-backed
- upstream-spec acceptance fragments can now also be classified by parent Requirement heading and numbered item marker, so part of fragment-class assignment no longer depends on local sentence terms
- snapshot rationale fragments can now also be treated as numbered list items with continuation lines, so `Why This Snapshot` evidence no longer depends on single-line term placement
- `implementation_snapshot_note` parameter-side cues can now be emitted from section heading + bullet/item position alone, and the note-side fragment classes have started to split into `clean_room_constraint_note`, `local_provenance_note`, `digest_fixity_note`, `operational_digest_check_note`, and `evidence_exclusion_note`
- note-side evidence records are now also compacted when pattern-derived and structure-derived entries refer to the same scoped evidence, which reduces duplicate support without changing the observed dual-over-single behavior
- `spec` and `intent` runs now emit `v2/` internal artifacts from runtime-mediated runs while preserving legacy human-facing artifacts

## 4. ECL Mandatory Removal Check

### 4.1 Completed or materially advanced

- `ECL-B1` / `ECL-B2`:
  batch wiring is now manifest-backed rather than script-local only
- `ECL-B3`:
  protocol defaults are demoted closer to sample/default behavior because protocol entrypoints can now take manifest refs explicitly
- `ECL-S2` / `ECL-I2`:
  case identity is no longer the only place where track inputs are sourced; manifest-backed input resolution is now available

### 4.2 Still open

- `ECL-R2` / `ECL-R3`:
  implementation heuristics are now profile-backed, use a shared rule-match analyzer, increasingly reference named seed-pattern vocabulary instead of inline term lists, emit `evidence_records -> observations -> findings`, and partially support structure-first evidence generation. Fragment-class cue rules are also externalized into shared pattern assets, some upstream-spec cues now use parent heading + item marker structure, snapshot rationale can be consumed as numbered fragments, and `implementation_snapshot_note` parameter-side cues can be derived from section + bullet position while starting to split into `clean-room`, `local provenance`, `digest fixedness`, `operational check`, and `evidence exclusion` roles. Duplicate note-side evidence is also compacted. However, note-side cue scope is still not yet semantics-aware generic review logic

要するに、**binding と protocol-side case payload は外へ出て、`spec` / `intent` は runtime-mediated path へ移った。残る未解決は `implementation` 側の heuristic がまだ source-pattern ベースな点である**。

## 5. Remaining Reopen Item Register

1. `implementation` analyzer now emits `evidence_records -> observations -> findings`, those records are section-scoped and observations carry evidence-type / review-focus / source-kind / section-class / fragment-class metadata. Part of the primary path is now structure-first, fragment-class cues are now data-backed, some upstream-spec fragment classes can be assigned from parent heading + item marker, snapshot rationale can be read as numbered fragments, and `implementation_snapshot_note` cues can be assigned from section + bullet/item position while splitting into `clean-room`, `local provenance`, `digest fixedness`, `operational check`, and `evidence exclusion` roles. Duplicate note-side evidence is also compacted, and both `local provenance` and `operational digest check` can already be removed from the parameter adversarial rule without losing the current dual-over-single pilot result. The remaining strongest heuristic concentration is the semantic stability of those note roles, which is not yet semantics-aware generic review logic.
2. comparison summaries are reacquired, but the result is still pilot evidence rather than reusable main-evidence-grade acquisition.

## 6. Main-Evidence Status

`main evidence` へはまだ昇格しない。

理由:

- implementation 側はまだ `implementation_snapshot_note` 系 cue の note role 境界が十分に安定しておらず、generic logic と言えるほど意味論的に固定されていない
- `spec` と `intent` は runtime-mediated path へ移ったが、human-facing protocol artifact はなお pilot projection であり、main-evidence-grade acquisition ではない
- `phase-field` rerun は成功したが、generic execution layer replacement の最終安定化までは未完了である

したがって現時点の位置づけは、

- `pilot reacquisition completed`
- `first validation result recorded`
- `main evidence promotion not allowed yet`

である。
