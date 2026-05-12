# Cross-Track Narrative Note

_作成: 2026-05-11_  
_status: acquisition-backed narrative v0.2_  
_role: `Intent Track / Spec Track / Implementation Track` を 1 本の paper-facing story に圧縮する_

---

## 1. scope

この文書は、現時点で main paper に接続済みの 3 track

- `Intent Track`
- `Spec Track`
- `Implementation Track`

を、claim 単位ではなく workflow story として短く固定する。

refs:

- [intent-track-first-case-dual-reviewer-rebuild.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/intent-track-first-case-dual-reviewer-rebuild.md:1)
- [spec-track-first-case-phase-field-reverse-spec.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/spec-track-first-case-phase-field-reverse-spec.md:1)
- [core-case-phase-field.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-phase-field.md:1)
- [core-case-heat3d.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-heat3d.md:1)
- [dual-reviewer-spec-driven-case-manifest.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-case-manifest.md:1)

---

## 2. three-track story

今の最小 story は次である。

1. `Intent Track` では、`dual-reviewer-rebuild` を使って、`intent` を最上位入力にした bootstrap と downstream propagation の loop が artifact に残るかを見る
2. `Spec Track` では、`phase-field-reverse-spec` を使って、既存 `requirements / design / tasks` に対する refinement, reopen, alignment の loop が artifact に残るかを見る
3. `Implementation Track` では、`F1-phase-field-cpp-r2`, `heat3d-julia`, `iot-arduino` を使って、approved upstream artifact に結びついた implementation/review acquisition と downstream implementation trace が成立するかを見る

したがって paper 全体では、

- 上流 bootstrap
- 中流 refinement
- 下流 conformance / implementation trace

の 3 層を、別々の benchmark ではなく連続した workflow support story として読ませることができる。

---

## 3. role of heat3d in this story

`F1-phase-field-cpp-r2` は clean 3-treatment implementation comparison case であり、`heat3d` はこの 3-track story の後半を強くする bridge case である。一方 `iot-arduino` は、event-driven domain でも implementation-local refinement 後の signal stability を観測できる implementation-first case である。

理由は次である。

1. `F1-phase-field-cpp-r2` は `single / dual / dual+judgment` を runtime-backed に揃え、implementation comparison の clean basis を提供した
2. `heat3d` は `Spec-origin / Implementation-origin` の両方を 1 case で持つ
3. `heat3d` は restart, reopen, readability recheck, review acquisition, actual implementation まで含む長い trace を残した
4. `heat3d` では implementation-local rework と upstream underconstraint exposure を分けて記述できた
5. `heat3d` では `13.4` を admission gate にせず、behavioral adequacy probe として読む判断まで記録できた

そのため implementation track では、

- `F1-phase-field-cpp-r2`
  - clean 3-treatment comparison case
- `heat3d`
  - bridge case

という 2 層構成を取れる。そのうえで `heat3d` は、単なる second implementation case ではなく、

- workflow validity
- implementation-origin evidence
- evidence reusability
- spec/design underconstraint exposure

を同時に持つ bridge case として使える。

---

## 4. paper-facing narrative

paper-facing に短く書くなら、cross-track story は次になる。

`dual-reviewer` の主対象は code review 単体ではなく、intent から implementation まで下る意図駆動開発 workflow である。`Intent Track` では上流 bootstrap と propagation、`Spec Track` では downstream refinement と reopen/alignment、`Implementation Track` では approved upstream artifact に結びついた review acquisition と implementation trace を観測する。implementation 側では `F1-phase-field-cpp-r2` が clean 3-treatment comparison を担い、`heat3d` はこの後半を代表する bridge case として workflow validity、implementation-origin evidence、evidence reusability、spec/design underconstraint exposure を同時に示す。`iot-arduino` は event-driven implementation-first case として stable safety finding と preserved caveat を補う。

---

## 5. preserved caveat

この cross-track story でも、まだ強く言わないことは次である。

1. track ごとの case 数が十分に多い
2. `heat3d` の behavior mismatch の責任所在が確定した
3. simulation 以外の domain でも同じ finding pattern が一般に出る
4. canonical full-case acceptance `13.4` が correctness oracle として使える

`iot-arduino` は event-driven domain への transfer を補うが、現時点では hardware-ready adequacy ではなく snapshot-based signal stability と caveat retention を示すに留まる。

したがって本文では、

- workflow / evidence claim
  と
- behavioral adequacy claim

を分けて書く必要がある。

---

## 6. acquisition status

`Intent Track` と `Spec Track` については、fresh narrative-connected first batch を取得済みである。

refs:

- [remaining-track-first-batch-acquisition-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/remaining-track-first-batch-acquisition-summary.md:1)
- [F1-intent-dual-reviewer-rebuild-narrative comparison summary](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild-narrative/comparison_summary.json:1)
- [F1-spec-phase-field-reverse-spec-narrative comparison summary](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec-narrative/comparison_summary.json:1)

この取得により 3-track story は acquisition-backed になったが、`Intent / Spec` 側の支えはまだ first-batch level である。したがって本文では、workflow support claim と benchmark-style generalization claim を分けて書く。
