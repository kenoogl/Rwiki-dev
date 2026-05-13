# tasks local review template

> 単一 feature spec の `tasks.md` を内部レビューするためのテンプレート。複数 feature を横断する場合は `tasks-review-wave-template.md` を使う。

## 1. review scope

- review type: `tasks-local-review`
- reviewed feature: `<feature spec name>`
- reviewed document: `<feature spec path>/tasks.md`
- design ref: `<feature spec path>/design.md`
- review focus:
  - implementation 順序の妥当性
  - test sequencing の明示
  - blocking dependency の特定
  - shared artifact owner の明示
  - 各 task が requirements / design に対応していること

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
