# Claim 2-3-4 Cross-Case Synthesis

_作成: 2026-05-11_  
_status: draft synthesis v0.2_  
_role: `dual-reviewer-rebuild`, `phase-field`, `heat3d` を使って `Claim 2 / 3 / 4` の本文候補を短く固定する_

---

## 1. scope

この文書は、現時点で main paper の claim prose に直結する

- `dual-reviewer-rebuild`
- `phase-field`
- `heat3d`

を並べて、main paper の `Claim 2 / 3 / 4` に使う cross-track reading を短く固定する。

refs:

- [remaining-track-first-batch-acquisition-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/remaining-track-first-batch-acquisition-summary.md:1)
- [core-case-phase-field.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-phase-field.md:1)
- [core-case-heat3d.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-heat3d.md:1)
- [phase-field-dual-treatment-observation.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/phase-field-dual-treatment-observation.md:1)
- [heat3d-phase-field-implementation-comparison-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-phase-field-implementation-comparison-note.md:1)
- [heat3d-main-paper-observation-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-main-paper-observation-note.md:1)

---

## 2. claim 2 reading

`Claim 2` に対して今 safely 言える最小読みは次である。

- `phase-field` では scientific case で traceability, caveat retention, handback depth を観測できた
- fresh `dual-reviewer-rebuild` / `phase-field-reverse-spec` batch では、`intent handback`, `propagation obligation`, `reopen required`, `intent-attributed issue`, `major correction` を implementation 以前の層で artifact に残せた
- `heat3d` では requirements/design/tasks の summary、review acquisition、implementation evidence を同じ case id で縦に接続できた
- したがって `dual-reviewer` は、少なくとも first-batch / fixed-core-case level では、finding 件数だけでなく caveat, disposition, reopen depth, evidence summary を track 横断で traceable に残せる

paper sentence candidate:

`phase-field` と `heat3d` の 2 case では、review artifact は finding の列挙に留まらず、caveat, disposition, reopen depth, phase evidence summary を同じ case lineage 上に保持した。したがって `dual-reviewer` は、指摘品質だけでなく traceability 自体を成果物として残す workflow system として読める。

short caveat:

- upstream support は fresh first-batch level に留まる

---

## 3. claim 3 reading

`Claim 3` に対して今 safely 言える最小読みは次である。

- fresh `dual-reviewer-rebuild` は `intent-only` の representative first batch である
- fresh `phase-field-reverse-spec` は `spec-present` の representative first batch である
- `heat3d` は restart, reopen, readability recheck, review acquisition, actual implementation を含む second case である
- `heat3d` では multi-feature decomposition への差し戻し後も workflow が崩壊しなかった
- したがって `dual-reviewer` は、少なくとも first-batch / bridge-case level では `intent-only`, `spec-present`, `implementation-present` の開始条件と手戻り差を吸収しつつ workflow を維持できた

paper sentence candidate:

`phase-field` と `heat3d` は、ともに `Spec-origin / Implementation-origin` を含むが、`heat3d` では restart, reopen, readability recheck, review acquisition, actual implementation まで含む長い経路を破綻なく通した。これは `dual-reviewer` が、開始条件や途中手戻りの差を吸収しながら workflow を維持できることの cross-case evidence である。

short caveat:

- `intent-only / spec-present` support は first-batch level として読む

---

## 4. claim 4 reading

`Claim 4` に対して今 safely 言える最小読みは次である。

- `phase-field` と `heat3d` はどちらも implementation track で `2 / 3 / 3` を示した
- 共通の 2 件は `boundary` と `update-order`
- `single -> dual` で増えた 1 件は両 case とも `parameter-caveat`
- ただし `heat3d` では reduced validation pass と reference behavior mismatch が共存し、その差は first-order では implementation defect ではなく `spec/design underconstraint exposure` として再利用された

paper sentence candidate:

implementation track では、`phase-field` と `heat3d` の両方で `boundary`, `update-order`, `parameter-caveat` という finding pattern が再現した。一方 `heat3d` は、reduced validation pass と reference behavior mismatch の併存を通じて、review evidence を downstream reporting と future code-conformance evaluation の両方へ再利用できることを示した。

supporting note:

`Intent / Spec` の fresh first batch も provenance 分離された形で取得済みであり、Implementation Track に偏っていた report 前半は acquisition-backed に補強された。したがって `Claim 4` は、implementation evidence の再利用だけでなく、track 横断 provenance の再利用という読みも取れる。ただし behavior mismatch の責任分解は `v3` 側に委譲し、本文では workflow/evidence claim に留める。

---

## 5. preserved caution

この synthesis でまだ強く言わないことは次である。

1. `parameter-caveat` が常に third finding になる
2. canonical full-case acceptance `13.4` が main evidence の必須条件として既に確立した
3. behavior mismatch の責任が implementation 側にないと確定した
4. simulation case 以外にもこの pattern がそのまま一般化する

したがって本文では、

- `implementation defect`
  より先に
- `spec conformance` と `behavioral adequacy` を分ける必要

を明示しておく。
