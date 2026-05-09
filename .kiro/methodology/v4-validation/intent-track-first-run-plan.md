# Intent Track first-run plan

_作成: 2026-05-09_  
_status: draft v0.1_  
_purpose: intent-only start case の最初の取得条件固定_

---

## 1. この文書の役割

この文書は、`dual-reviewer` の次段評価における
`Intent Track` の最初の取得バッチを固定するための plan である。

ここでの first-run は、
`intent` しかない状態から `requirements / design / tasks` に下る際に、
`dual-reviewer` が review/governance system として成立するかを見る pilot である。

---

## 2. first-run の目的

Intent Track first-run の目的は、大規模比較ではない。

目的は次の 4 つである。

1. `intent` から requirement 化に進む最初の review loop が成立することを確認する
2. `D` handback を含む upstream 由来の修正が artifact に残ることを確認する
3. `requirements / design / tasks` への伝播境界が追跡可能であることを確認する
4. main batch 前に intent-review artifact や traceability 欠落を潰す

---

## 3. First-Run Case Shape

first-run では、少なくとも次の条件を満たす case を使う。

1. 入力は `intent` 文書だけ、または `intent` が最上位入力として明確である
2. `requirements / design / tasks` は未確定、または生成・再整理対象である
3. phase ごとの reopen / recheck が観測できる

推奨 first case:

- `dual-reviewer-rebuild` の初期 intent bootstrap 区間

---

## 4. Minimum Batch

- batch label: `F1-intent-track`
- minimum batch:
  - `1 intent case x 2 review modes`

比較軸:

1. `single review`
   - 単独 reviewer 相当で intent から下流 spec を点検
2. `dual-reviewer workflow`
   - adversarial / judgment / governance を含む標準系

`manual reference` は optional とする。

---

## 5. System/Protocol Success Condition

Intent Track first-run で system/protocol success とみなす条件:

1. `intent review` artifact が残る
2. `intent_revision_count` と `intent_handback_count` を記録できる
3. downstream phase に伝播した issue が `intent-attributed` として区別される
4. `requirements / design / tasks` への reopen obligation が明示される
5. conformance 以前の upstream workflow evidence が欠落しない

---

## 6. Review-Output Success Condition

Intent Track first-run で review-output success とみなす条件:

1. intent から requirement 化への major gap または scope drift 候補が明示される
2. premature closure を避ける counter-hypothesis が残る
3. `single review` よりも disagreement / caveat が落ちにくい

---

## 7. Required Artifacts

最低限必要な出力:

- case descriptor
- intent review artifact
- intent-to-requirements trace note
- phase-review metric snapshot
- signal linkage
- workflow gate status reference

first-run 特有で残すもの:

- intent acquisition memo
- propagation issue memo
- protocol mismatch note

---

## 8. Interpretation Rule

Intent Track first-run の結果は、
「dual-reviewer が requirements を正しく自動生成したか」の単純評価には使わない。

見るのは次である。

- intent 起点の review/governance loop が成立したか
- upstream の不確実性を無理に閉じなかったか
- downstream phase に伝播すべき issue を記録できたか

---

## 9. Immediate Next Step

この plan の直後に必要なのは次である。

1. `dual-reviewer-rebuild` を Intent Track first case として固定する
2. `single review` と `dual-reviewer workflow` の intent-run template を作る
3. intent review artifact の最小 field を run template に落とす

