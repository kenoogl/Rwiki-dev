# Manual Review Metrics Summary

## Scope

この summary は、現時点で記録済みの manual review session 5件を対象にした集計である。

- `manual-intent-review-20260508-001`
- `manual-requirements-review-20260508-001`
- `manual-requirements-review-20260508-002`
- `manual-design-review-20260508-001`
- `manual-tasks-review-20260509-001`

全 session の `review_mode` は `manual-dual-reviewer-inspired` で統一されている。

## Session Metrics

- total sessions: `5`
- approved sessions: `5`
- pending sessions: `0`
- sessions with findings: `3`
- sessions with zero findings: `2`
- sessions with unresolved concerns: `2`
- sessions requiring downstream recheck: `1`

## Finding Metrics

- total findings: `8`
- accepted findings: `8`
- rejected findings: `0`
- deferred findings: `0`
- open findings: `0`

severity distribution:

- `medium`: `5`
- `high`: `3`

category distribution:

- `missing_design_detail`: `4`
- `ambiguity`: `2`
- `workflow_gap`: `1`
- `missing_requirement`: `1`

## Phase Slice

- `intent`: 1 session, 2 findings, 2 accepted
- `requirements`: 2 sessions, 2 findings, 2 accepted
- `design`: 1 session, 4 findings, 4 accepted
- `tasks`: 1 session, 0 findings, 0 accepted

この manual wave では、findings は `design` に最も集中している。

## Workflow Signals

- `reopen_required_sessions`: `0`
- downstream recheck は `design` 向けに `1` 回発生

この結果は、「review wave は閉じたが、phase 間 handback が発生しうる」という workflow 特性を示している。

## Effort Note

- total recorded minutes: `75`
- sessions with zero recorded minutes: `3`

この effort 値は参考値に留まる。3 session が `duration_minutes: 0` で記録されており、実作業時間を過小評価している。

## Interpretation

現時点の manual review 記録からは、少なくとも次が言える。

- manual review record format から session / finding / category / severity / downstream recheck は抽出できる
- 初期 dogfooding では `design` phase に問題が集中しやすい
- accepted rate は高いが、これは現時点では review と handback を同一作業者が行っているため、将来の runtime-mediated review の精度指標とは区別して扱う必要がある

## Limitations

- runtime-mediated review の evidence はまだ含まれない
- recall や missed issue は測れない
- reviewer 間一致率は測れない
- cost / token / latency の指標はまだない

machine-readable version:

- [manual_review_metrics_summary.json](manual_review_metrics_summary.json)
