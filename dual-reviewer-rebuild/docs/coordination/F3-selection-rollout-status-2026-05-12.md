# F3 Selection Rollout Status

2026-05-12 時点の `F3` selection-driven analysis rollout の状態をまとめる。

## Scope

- implementation:
  - `F3-iot-arduino`
  - `F3-iot-arduino-r2`

`F3` は implementation-only case であり、`intent/spec` track の protocol run は持たない。

## Ready Manifests

- [F3-iot-arduino-selection.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/manifests/F3-iot-arduino-selection.yaml:1)
- [F3-iot-arduino-r2-selection.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/manifests/F3-iot-arduino-r2-selection.yaml:1)

## Selection Results

- `F3-iot-arduino`
  - selected run count: `3`
  - included treatments:
    - `single`
    - `dual`
    - `dual+judgment`
- `F3-iot-arduino-r2`
  - selected run count: `3`
  - included treatments:
    - `single`
    - `dual`
    - `dual+judgment`

## Operational Reading

- `F3-iot-arduino`
  - first snapshot / first acquisition basis
- `F3-iot-arduino-r2`
  - second snapshot / post-refinement basis

このため `F3` は、selection-driven analysis の対象としては単一 case ではなく、`before` と `after` の implementation pair として扱うのが自然である。

## Repair Status

- protocol-facing summaries are already present
- runtime triage notes are already present
- stale runtime ref repair was not required

## Not Yet Run

- `refresh_analysis_and_paper_from_selection.rb` has not yet been run on either `F3` manifest
- current global `experiments/analysis` is not `F3`-based unless explicitly refreshed

## Next Operational Choice

1. refresh onto `F3-iot-arduino` to read the first snapshot as the active analysis basis
2. refresh onto `F3-iot-arduino-r2` to read the refined snapshot as the active analysis basis
3. keep `F3` as selection-ready only, and continue rollout to another case
