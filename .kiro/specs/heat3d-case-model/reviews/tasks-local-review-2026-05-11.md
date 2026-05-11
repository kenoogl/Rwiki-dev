# 2026-05-11 heat3d-case-model tasks local review

## 1. review scope

- review type: `tasks local review`
- reviewed feature: `heat3d-case-model`
- reviewed artifact:
  - [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/tasks.md:1)
- review focus:
  - canonical constant owner と assembly owner が tasks に落ちているか
  - `FieldBuffers` の allocation site が明示されているか
  - assembled case の shape drift を smoke test で検出できるか

## 2. findings

### Finding 1

- title: `FieldBuffers` scratch policy did not identify the allocator owner
- references:
  - [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/tasks.md:15)
  - [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/tasks.md:18)
- description:
  - 初稿では `FieldBuffers` を case assembly scratch とだけ書いており、shared container の shape を誰が allocate するかが task 単位で閉じていなかった。
- impact:
  - case-model が独自 shape で scratch buffer を確保し、foundation contract とずれる恐れがあった。
- recommended action:
  - `FieldBuffers` は `foundation.allocate_field_buffers(shape)` で確保すると明記する。
- status: `fixed`

## 3. metric snapshot

- `phase_blocking_issue_count`: `1`
- `phase_major_correction_count`: `1`
- `phase_intent_attributed_issue_count`: `0`

## 4. disposition summary

- immediate disposition:
  - task 1.2 に `FieldBuffers` allocator owner を追記し、case assembly scratch の boundary を閉じた。
- downstream implication:
  - phase wave では `FieldBuffers` を canonical runtime path に持ち込まないことの確認に集中できる。
- next action:
  - remaining active feature の local tasks review を揃えた後、horizontal tasks review wave へ進む。
