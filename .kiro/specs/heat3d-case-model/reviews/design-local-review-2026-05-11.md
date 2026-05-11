# 2026-05-11 heat3d-case-model design local review

## 1. review scope

- review type: `design local review`
- reviewed feature: `heat3d-case-model`
- reviewed artifact:
  - [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/design.md:1)
- review focus:
  - canonical MVP defaults と assembled case bundle の owner が閉じているか
  - geometry / material / heat / boundary の assembly sequence が明確か
  - run-time field を bundle に混ぜていないか

## 2. findings

### Finding 1

- title: run-time fields were not explicitly excluded from `AssembledCase`
- references:
  - [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/design.md:133)
  - [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/design.md:147)
- description:
  - 初稿では `AssembledCase` に何を含めないかが明示されておらず、`theta` や `mask` まで case bundle に入れる設計に drift する余地があった。
- impact:
  - `case-model` と `main` の runtime field ownership が重複し、solver input 準備責務が曖昧になった。
- recommended action:
  - `theta` と `mask` は `main` が初期化する runtime field であり、`AssembledCase` に含めないと明記する。
- status: `fixed`

## 3. metric snapshot

- `phase_blocking_issue_count`: `1`
- `phase_major_correction_count`: `1`
- `phase_intent_attributed_issue_count`: `0`

## 4. disposition summary

- immediate disposition:
  - `AssembledCase` 定義直後に runtime field exclusion を追記し、bundle boundary を閉じた。
- downstream implication:
  - `main` は `AssembledCase` を read-only input として受け、`theta` / `mask` は run-time field として別初期化する。
- next action:
  - remaining active feature の local design review を揃えた後、horizontal design review wave へ進む。
