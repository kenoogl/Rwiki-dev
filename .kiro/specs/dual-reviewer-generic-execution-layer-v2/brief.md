# Brief

## Feature

`dual-reviewer-generic-execution-layer-v2`

## Why

現行 pilot acquisition は成立しているが、
execution layer が `phase-field` と `dual-reviewer-rebuild` に強く埋め込まれており、
generic execution rule として再利用できない。

この feature は、

- `ECL` で固定した case-specific hardcode の除去対象を吸収し
- `Intent / Spec / Implementation` をまたぐ generic execution contract を定義し
- case onboarding を code edit ではなく manifest 更新で扱える形にする

ための主 feature である。

## Scope

- Case Manifest / Analysis / Decision / Writer の layer boundary
- track 共通 contract
- finding taxonomy
- analyzer / writer 分離
- cross-feature coordination rule

## Non-Goals

- 全ドメイン自動一般化
- main evidence への即昇格
- finding quality の最終最適化
- 人間 gate の除去

## Primary Dependencies

- `.kiro/methodology/dual-reviewer-spec-driven-paper/execution-control-ledger.md`
- `.kiro/methodology/dual-reviewer-spec-driven-paper/generic-execution-layer-v2-spec.md`

