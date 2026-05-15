# F1 Narrative Selection Rollout Status

2026-05-12 時点の `F1` narrative variant selection rollout の状態をまとめる。

## Scope

- intent narrative:
  - `F1-intent-dual-reviewer-rebuild-narrative`
- spec narrative:
  - `F1-spec-phase-field-reverse-spec-narrative`

両方とも `case_id` は base case と同じなので、selection では `protocol_root` を固定して base population と分離する。

## Ready Manifests

- [F1-intent-dual-reviewer-rebuild-narrative-selection.yaml](../../experiments/analysis/manifests/F1-intent-dual-reviewer-rebuild-narrative-selection.yaml:1)
- [F1-spec-phase-field-reverse-spec-narrative-selection.yaml](../../experiments/analysis/manifests/F1-spec-phase-field-reverse-spec-narrative-selection.yaml:1)

## Selection Results

- `F1-intent-dual-reviewer-rebuild-narrative`
  - selected run count: `2`
  - included treatments:
    - `single`
    - `dual+judgment`
- `F1-spec-phase-field-reverse-spec-narrative`
  - selected run count: `2`
  - included treatments:
    - `single`
    - `dual+judgment`

## Operational Reading

- base `F1` manifests:
  - ordinary protocol-backed population
- narrative `F1` manifests:
  - cross-track narrative acquisition population

このため、narrative variant は base `F1` analysis population と混ぜず、必要なときだけ明示的に refresh する。
