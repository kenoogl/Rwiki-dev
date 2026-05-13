# design review wave template

> 複数 feature spec の `design.md` を横断的にレビューする wave のテンプレート。

## 1. review scope

- review type: `design-review-wave`
- reviewed feature set:
  - `<feature A>`
  - `<feature B>`
  - `<feature C>`
- reviewed documents:
  - `<feature A>/design.md`
  - `<feature B>/design.md`
  - `<feature C>/design.md`
- review focus:
  - cross-feature の interface 互換性
  - file / directory 衝突の有無
  - version 戦略の整合
  - validator 統合点の合意
  - 後段（implementation、review acquisition、self-improvement、paper-interface）への引き渡しの整合

## 2. findings

### Finding N

- title:
- affected features:
- references:
- description:
- impact:
- recommended action:
- handback assessment: `<A | B | C | D>`
- status:

## 3. metric snapshot

- `phase_blocking_issue_count`:
- `phase_nonblocking_open_point_count`:
- `phase_recheck_count`:
- `phase_minor_adjustment_count`:
- `phase_major_correction_count`:
- `phase_intent_attributed_issue_count`:
- `phase_reopen_required_count`:

## 4. disposition summary

- immediate disposition:
- downstream implication:
- next action:
