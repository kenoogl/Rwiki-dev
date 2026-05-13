# design local review template

> 単一 feature spec の `design.md` を内部レビューするためのテンプレート。複数 feature を横断する場合は `design-review-wave-template.md` を使う。

## 1. review scope

- review type: `design-local-review`
- reviewed feature: `<feature spec name>`
- reviewed document: `<feature spec path>/design.md`
- requirements ref: `<feature spec path>/requirements.md`
- review focus:
  - interface の明示性
  - file / directory 配置の妥当性
  - versioning 戦略の整合
  - validator 統合点の明示
  - downstream への引き渡し方の明示

## 2. findings

### Finding N

- title:
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
