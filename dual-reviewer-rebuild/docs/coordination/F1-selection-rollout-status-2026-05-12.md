# F1 Selection Rollout Status

2026-05-12 時点の `F1` selection-driven analysis rollout の状態をまとめる。

## Scope

- implementation:
  - `F1-phase-field-cpp`
- intent:
  - `F1-intent-dual-reviewer-rebuild`
- spec:
  - `F1-requirements-phase-field-reverse-spec`
  - `F1-design-phase-field-reverse-spec`
  - `F1-spec-phase-field-reverse-spec`

## Ready Manifests

- [F1-phase-field-cpp-selection.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/manifests/F1-phase-field-cpp-selection.yaml:1)
- [F1-intent-dual-reviewer-rebuild-selection.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/manifests/F1-intent-dual-reviewer-rebuild-selection.yaml:1)
- [F1-requirements-phase-field-reverse-spec-selection.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/manifests/F1-requirements-phase-field-reverse-spec-selection.yaml:1)
- [F1-design-phase-field-reverse-spec-selection.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/manifests/F1-design-phase-field-reverse-spec-selection.yaml:1)
- [F1-spec-phase-field-reverse-spec-selection.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/manifests/F1-spec-phase-field-reverse-spec-selection.yaml:1)

## Selection Results

- `F1-phase-field-cpp`
  - selected run count: `2`
  - included treatments:
    - `single`
    - `dual+judgment`
  - excluded from default population:
    - `dual_review` / `dual`
  - reason:
    - protocol run existed, but matching closed runtime run was not present
- `F1-intent-dual-reviewer-rebuild`
  - selected run count: `2`
  - included treatments:
    - `single`
    - `dual+judgment`
- `F1-requirements-phase-field-reverse-spec`
  - selected run count: `2`
  - included treatments:
    - `single`
    - `dual+judgment`
- `F1-design-phase-field-reverse-spec`
  - selected run count: `2`
  - included treatments:
    - `single`
    - `dual+judgment`
- `F1-spec-phase-field-reverse-spec`
  - selected run count: `2`
  - included treatments:
    - `single`
    - `dual+judgment`

## Repair Actions Applied

- old intent/spec protocol runs:
  - backfilled `runtime_validation_summary.yaml`
  - synthesized `derived/invalid_run_triage_note.json` where absent
- `F1-phase-field-cpp` implementation protocol runs:
  - repaired stale runtime refs in `single` and `dual+judgment`
  - rewrote `conformance_review_result.yaml` to the shared runtime validation summary contract
  - synthesized `derived/invalid_run_triage_note.json` for selected runtime runs

## Not Yet Run

- `refresh_analysis_and_paper_from_selection.rb` has not been run for the `F1` manifests
- current global `experiments/analysis` has not been replaced with an `F1` population
- current global paper artifact set has not been switched to an `F1` basis

## Operational Read

`F1` is now selection-ready across implementation / intent / spec.

The next operational choice is one of:

1. refresh analysis and paper on a chosen `F1` manifest
2. continue the same rollout pattern to the next case without changing the current global analysis basis
