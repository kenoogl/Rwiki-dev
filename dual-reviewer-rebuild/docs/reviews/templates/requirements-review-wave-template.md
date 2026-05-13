# requirements review wave template

> 複数 feature spec の `requirements.md` を横断的にレビューする wave のテンプレート。1 feature だけを深く見るのではなく、wave に属する feature 群を一通り見る。

## 1. review scope

- review type: `requirements-review-wave`
- reviewed feature set:
  - `<feature A>`
  - `<feature B>`
  - `<feature C>`
- reviewed documents:
  - `<feature A>/requirements.md`
  - `<feature B>/requirements.md`
  - `<feature C>/requirements.md`
- review focus:
  - 複数 feature を通した contract の一貫性
  - cross-feature で shared な schema / metadata の合意
  - responsibility boundary の食い違い
  - 重複する要件と欠落する要件の特定

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
