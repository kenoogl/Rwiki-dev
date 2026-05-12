# cross-track metric aggregation first package

_作成: 2026-05-11_  
_status: derived package v0.1_  
_role: main paper に足す最小比較 package を 1 枚に束ねる_

---

## 1. role

この文書は [cross-track-metric-aggregation-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/cross-track-metric-aggregation-plan.md:1) の first package を、実データから埋めた派生 artifact である。

ここでの目的は、

1. `Intent / Spec / Implementation` をまたぐ preservation pattern を 1 枚で読む
2. `heat3d` の implementation-local rework を implementation track の比較文脈に載せる
3. 本文に入れる compressed reading を固定する

ことである。

---

## 2. source set

- [remaining-track-first-batch-acquisition-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/remaining-track-first-batch-acquisition-summary.md:1)
- [phase-field dual-treatment observation](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/phase-field-dual-treatment-observation.md:1)
- [heat3d-phase-field-implementation-comparison-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-phase-field-implementation-comparison-note.md:1)
- [implementation-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/implementation-evidence-summary.md:1)
- [heat3d-supplementary-behavioral-evidence-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-supplementary-behavioral-evidence-note.md:1)

---

## 3. Track-Level Preservation Table

| track | handback | reopen | major correction | caveat / disposition | evidence summary |
|---|---|---|---|---|---|
| `Intent` | `present (dual only)` | `not observed in fresh first batch` | `not observed` | `propagation obligation preserved` | `present` |
| `Spec` | `present (B-class, dual only)` | `present` | `present (dual only)` | `carry-over inconsistency preserved` | `present` |
| `Implementation` | `not primary unit; review acquisition / coding trace used instead` | `upstream reopen not observed in heat3d coding` | `judgment and local correction both preserved` | `parameter-caveat`, `necessary/optional`, local rework disposition preserved | `present` |

short reading:

- `Intent` では dual only で handback depth が残った
- `Spec` では dual only で major correction が残り、reopen は single/dual 共通で維持された
- `Implementation` では finding 数差だけでなく `judgment` と coding-layer rework trace が保存された

---

## 4. Implementation Downstream Rework Table

| case | single findings | dual findings | dual+judgment findings | implementation-local blocking issues | upstream reopen |
|---|---|---|---|---|---|
| `phase-field` | `2` | `3` | `3` | `not collected in current package` | `not collected in current package` |
| `heat3d` | `2` | `3` | `3` | `3` | `0` |

short reading:

- implementation-track の finding shape は `phase-field` と `heat3d` で `2 / 3 / 3` に一致した
- ただし `heat3d` では review acquisition に加えて actual coding を行い、blocking issue `3` 件が implementation local に閉じた
- current package 上、`phase-field` は review acquisition baseline、`heat3d` は review acquisition + coding trace bridge case と読むのが正確である

---

## 5. Interpretation Boundary Table

| track | first-batch only | behavioral adequacy outside main claim | v3 delegation needed |
|---|---|---|---|
| `Intent` | `yes` | `n/a` | `no` |
| `Spec` | `yes` | `n/a` | `no` |
| `Implementation` | `no` | `yes (heat3d)` | `yes (heat3d responsibility split)` |

short reading:

- upstream 2 track は acquisition-backed support だが、まだ first-batch level に留まる
- `Implementation` は case depth が深いが、`heat3d` behavioral adequacy は本文主張の外に置く
- `v3` が必要なのは implementation-present case の責任分解であり、track 全体の workflow 成立可否ではない

---

## 6. compressed paper-facing reading

`dual-reviewer` の差分は finding 数の増分だけではない。fresh `Intent Track` では dual only で handback depth が残り、fresh `Spec Track` では reopen を維持したまま dual only で major correction が残った。implementation-present case では `phase-field` と `heat3d` の両方で `2 / 3 / 3` の finding shape が再現し、さらに `heat3d` では actual coding 中の blocking issue `3` 件が upstream reopen `0` のまま implementation local に閉じた。したがって本研究は、finding recall だけでなく handback, reopen, caveat, disposition, downstream rework trace の保持を workflow/evidence の主成果として評価できる。ただし `Intent / Spec` の支持は first-batch level に留まり、`heat3d` の behavioral adequacy 責任分解は `v3` に委ねる。

---

## 7. use rule

この package は次の順で使う。

1. main paper 本文では `Section 6 Claims` の短い補助段落へ圧縮する
2. supporting note では本表をそのまま残す
3. large-N comparison を後で追加する場合も、この package を baseline table として扱う
