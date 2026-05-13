# Spec Track first-run plan

_作成: 2026-05-09_  
_最終更新: 2026-05-13_  
_status: draft v0.2_  
_purpose: spec-present case の最初の取得条件固定_

---

## 1. この文書の役割

この文書は、`dual-reviewer` の次段評価における
`Spec Track` の最初の取得バッチを固定するための plan である。

ここでの first-run は、
既に `requirements / design / tasks` が存在する case に対して、
downstream refinement と alignment gate を `dual-reviewer` がどう支えるかを見る pilot である。

---

## 2. first-run の目的

Spec Track first-run の目的は、大規模比較ではない。

目的は次の 4 つである。

1. spec-present case で review / alignment / reopen の loop が成立することを確認する
2. `requirements / design / tasks` 間の伝播修正が artifact に残ることを確認する
3. phase-review metrics を case 単位で取得できることを確認する
4. main batch 前に alignment memo や reopen 記録の欠落を潰す

narrative role:

- cross-track story の「中流 refinement と reopen / alignment」を acquisition-backed にする
- implementation-centered に見えやすい current paper prose の中流層を埋める

---

## 3. First-Run Case Shape

first-run では、少なくとも次の条件を満たす case を使う。

1. `requirements / design / tasks` が repo-contained で存在する
2. phase 間依存が明示されている
3. review round または alignment evidence を残せる

推奨 first case:

- [spec-track-first-case-phase-field-reverse-spec.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/spec-track-first-case-phase-field-reverse-spec.md:1)

---

## 4. Minimum Batch

- batch label: `F1-spec-track`
- minimum batch:
  - `1 spec-present case x 2 review modes`

比較軸:

1. `single review`
   - phase-local に spec を点検
2. `dual-reviewer workflow`
   - adversarial / judgment / governance を含む標準系

`manual reference` は optional とする。

---

## 5. System/Protocol Success Condition

Spec Track first-run で system/protocol success とみなす条件:

1. `requirements / design / tasks` の phase-review metric を取得できる
2. alignment memo または equivalent artifact が残る
3. reopen / recheck obligation が phase ごとに追跡できる
4. `intent-attributed issue` を downstream phase 側で区別できる
5. workflow gate status に phase 状態を接続できる

---

## 6. Review-Output Success Condition

Spec Track first-run で review-output success とみなす条件:

1. phase 間の不整合、抜け漏れ、順序依存のいずれかが meaningful finding として出る
2. `single review` よりも disagreement / caveat / reopen depth が残る
3. issue が `requirements/design/tasks` のどこに属するかを無理に混同しない

---

## 7. Required Artifacts

最低限必要な出力:

- case descriptor
- reviewed phase note
- alignment artifact or memo
- phase-review metric snapshot
- signal linkage
- workflow gate status reference

first-run 特有で残すもの:

- spec acquisition memo
- phase propagation note
- protocol mismatch note

---

## 8. Interpretation Rule

Spec Track first-run の結果は、
「dual-reviewer が正しい spec を自動生成したか」の単純評価には使わない。

見るのは次である。

- spec-present case で review/governance loop が成立したか
- phase 間伝播を適切に扱えたか
- reopen depth を evidence として残せたか

つまり、この track の value は
`正しい spec を自動生成できたこと`
ではなく、
`spec-present refinement evidence を main narrative に供給できること`
にある。

---

## 9. Immediate Next Step

この plan の直後に必要なのは次である。

1. `phase-field-reverse-spec` を Spec Track first case として固定する
   - status:
     - fixed as `F1-spec-phase-field-reverse-spec`
2. `single review` と `dual-reviewer workflow` の spec-run template を作る
   - status:
     - [spec-track-run-template.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/spec-track-run-template.md:1)
3. phase-review metric snapshot の採取手順を run template に落とす
   - status:
     - reflected in [spec-track-run-template.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/spec-track-run-template.md:1)
4. current cross-track story における narrative role は、再取得段階で確定する。
