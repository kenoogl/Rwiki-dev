# Remaining Track Acquisition Bridge Note

_作成: 2026-05-11_  
_status: bridge fulfilled v0.2_  
_role: `Intent Track / Spec Track` acquisition を current cross-track story にどう接続したかを固定する_

---

## 1. scope

この文書は、既に本文側へ接続済みの cross-track story に対して、
acquisition が薄かった部分をどう埋め、どこまで埋まったかを短く固定する。

対象は次の 2 つである。

- `Intent Track`
- `Spec Track`

`Implementation Track` は `phase-field` と `heat3d` で本文接続済みなので、この文書では補完対象から外す。

---

## 2. current split

現時点の story は次の状態にある。

1. `Implementation Track`
   - `phase-field` と `heat3d` により、review acquisition, implementation trace, evidence reuse, spec underconstraint exposure まで接続済み
2. `Spec Track`
   - `phase-field-reverse-spec` の fresh first batch を取得し、paper-facing refinement / reopen evidence を補った
3. `Intent Track`
   - `dual-reviewer-rebuild` の fresh first batch を取得し、bootstrap / propagation artifact を本文接続可能にした

つまり、現時点の本文は implementation 側だけでなく、intent/spec 側にも acquisition-backed な first-batch evidence を持つ。

---

## 3. what each remaining acquisition should add

### 3.1 Intent Track

`Intent Track` acquisition が埋めるべき narrative gap は次である。

- `intent` が最上位入力であることを artifact 上で示す
- `D` handback と propagation obligation が phase artifact に残ることを示す
- upstream uncertainty を premature closure せず保持できることを示す

したがって `Intent Track` は、
cross-track story の「上流 bootstrap と downstream propagation」を実測で支える役割を持つ。

### 3.2 Spec Track

`Spec Track` acquisition が埋めるべき narrative gap は次である。

- `requirements / design / tasks` 間の refinement と alignment が artifact に残ることを示す
- reopen / recheck depth を phase 単位で保持できることを示す
- `intent-attributed issue` を downstream で区別できることを示す

したがって `Spec Track` は、
cross-track story の「中流 refinement と reopen / alignment」を実測で支える役割を持つ。

---

## 4. paper-facing reading

本文に接続するときの最小 reading は次である。

`Implementation Track` だけでは、workflow story の後半しか直接支えられない。残る `Intent Track` と `Spec Track` の acquisition は、それぞれ上流 bootstrap と中流 refinement/alignment を実測で支えるために必要である。したがって今後の acquisition は、単なる case 追加ではなく、3-track story の欠けている前半を埋める作業として位置づける。

---

## 5. immediate consequence

この bridge note の直後に必要なのは次である。

1. [remaining-track-first-batch-acquisition-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/remaining-track-first-batch-acquisition-summary.md:1) を first-batch provenance summary として参照する
2. `Intent Track` の result を bootstrap / propagation evidence として本文へ反映する
3. `Spec Track` の result を refinement / alignment evidence として本文へ反映する
