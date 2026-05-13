# requirements local review template

> 単一 feature spec の `requirements.md` を内部レビューするためのテンプレート。複数 feature を横断する場合は `requirements-review-wave-template.md` を使う。

## 1. review scope

- review type: `requirements-local-review`
- reviewed feature: `<feature spec name>`
- reviewed document: `<feature spec path>/requirements.md`
- intent ref: `<feature spec の intent / brief / project-level intent への参照>`
- review focus:
  - 機能要件と非機能要件の完全性
  - 受入条件（acceptance criteria）の明示性
  - 上位 intent / brief との対応関係
  - scope drift がないか
  - 内部一貫性（要件間の矛盾なし）

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
