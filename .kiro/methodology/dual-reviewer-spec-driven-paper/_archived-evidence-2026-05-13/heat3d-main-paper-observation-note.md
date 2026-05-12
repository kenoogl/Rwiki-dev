# heat3d main paper observation note

_作成: 2026-05-11_  
_status: draft observation v0.1_  
_role: main paper に入れる `C-3 heat3d` の読みを短く固定する_

---

## 1. case role

`heat3d` は、main paper における `C-3` の fixed core case である。

この case は `Spec-origin` / `Implementation-origin` の両方を持ち、`Claim 2 / 3 / 4` を支える simulation-oriented case として使う。

refs:

- [core-case-heat3d.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-heat3d.md:1)
- [heat3d-case-fixation-decision.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-case-fixation-decision.md:1)

---

## 2. confirmed points

`heat3d` で確認できた main-paper relevant point は次である。

1. gate-based workflow は restart / reopen / recheck を含めても破綻せず回った
2. approved upstream artifact から clean-room implementation まで進められた
3. implementation track では `single / dual / dual+judgment = 2 / 3 / 3` を再取得できた
4. actual implementation では coding-layer rework `3` 件を観測し、upstream phase reopen `0` 件だった

refs:

- [heat3d-c3-evidence-bundle.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-c3-evidence-bundle.md:1)
- [implementation-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/implementation-evidence-summary.md:1)

---

## 3. key reading

この case の重要点は、clean-room 実装が **動作し、reduced validation を通る** 一方で、reference behavior とは一致しなかったことである。

この観測から first-order に言うべきなのは、implementation defect 断定ではなく、**approved spec/design だけでは所望挙動を十分拘束できていなかった可能性**である。

したがって `heat3d` は、

- workflow validity evidence
- implementation-origin second-case evidence
- spec/design underconstraint exposure evidence

の 3 つを兼ねる。

---

## 4. preserved caveat

main paper では、次を明示的に留保する。

1. current implementation は reference log と behavioral match をまだ達成していない
2. canonical full-case acceptance `13.4` は main evidence の admission gate ではなく、behavioral adequacy の補助観測として扱う
3. behavior mismatch の責任所在は、v3 で `code ↔ tasks/design/requirements` conformance を見て切り分ける

paper placement rule:

- main paper 本文:
  - workflow validity
  - implementation-origin evidence
  - spec underconstraint exposure
- `v3` 側:
  - implementation deviation vs spec/design underconstraint の責任分解

refs:

- [heat3d-v3-evaluation-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-v3-evaluation-note.md:1)
- [heat3d-validation-boundary-decision.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-validation-boundary-decision.md:1)
- [log.txt](/Users/Daily/Development/Heat3ds/log.txt:1)

---

## 5. paper-facing sentence

短く書くなら、`heat3d` の読みは次になる。

`heat3d` では、intent-governed upstream artifact から clean-room implementation まで到達できた一方、reference behavior との差が残った。この差は implementation defect を直ちに意味するのではなく、approved spec/design が所望挙動を十分拘束していなかった可能性を示す。したがって本 case は、workflow validity と implementation-origin evidence に加えて、spec underconstraint exposure の evidence として扱う。
