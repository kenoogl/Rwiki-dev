# F1 Phase-Field Cpp R2 Rollout Status

2026-05-12 時点の `F1-phase-field-cpp-r2` reacquisition 状態をまとめる。

## Scope

- implementation:
  - `F1-phase-field-cpp-r2`

`F1-phase-field-cpp-r2` は、original first snapshot を同条件で再取得し、欠落していた `dual` runtime-backed evidence chain を復元するための reacquisition batch である。

## Ready Manifests

- [F1-phase-field-cpp-r2-selection.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/manifests/F1-phase-field-cpp-r2-selection.yaml:1)

## Acquisition Results

- batch root:
  - [F1-phase-field-cpp-r2](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F1-phase-field-cpp-r2:1)
- comparison summary:
  - [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F1-phase-field-cpp-r2/comparison_summary.json:1)
- selected run count:
  - `3`
- included treatments:
  - `single`
  - `dual`
  - `dual+judgment`

## Observed Reading

- `single`
  - total findings: `2`
- `dual`
  - total findings: `3`
- `dual+judgment`
  - total findings: `3`
- `dual_minus_single_findings`
  - `+1`
- `dual_plus_judgment_minus_dual_only_findings`
  - `0`

## Operational Reading

`F1-phase-field-cpp-r2` は、original `F1-phase-field-cpp` の implementation-first evidence gap を埋める 3-treatment reacquisition basis として使える。

このため、論文化では次の 2 通りの使い方が可能になる。

1. `F2-heat3d-julia` を main implementation case に据え、`F1-phase-field-cpp-r2` を supporting 3-treatment implementation case に置く
2. `F1-phase-field-cpp-r2` 自体を `single / dual / dual+judgment` の clean implementation comparison case として再評価する

## Not Yet Run

- `refresh_analysis_and_paper_from_selection.rb` has not yet been run for `F1-phase-field-cpp-r2`
- current global `experiments/analysis` is not `F1-phase-field-cpp-r2`-based unless explicitly refreshed
