# tasks review wave template

> 複数 feature spec の `tasks.md` を横断的にレビューする wave のテンプレート。

## 1. review scope

- review type: `tasks-review-wave`
- reviewed feature set:
  - `<feature A>`
  - `<feature B>`
  - `<feature C>`
- reviewed documents:
  - `<feature A>/tasks.md`
  - `<feature B>/tasks.md`
  - `<feature C>/tasks.md`
- review focus:
  - cross-feature の implementation 順序
  - shared artifact の migration timing
  - blocking dependency の cross-feature への波及
  - test sequencing の整合
  - 各 feature の tasks が cross-spec の design に整合していること

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
