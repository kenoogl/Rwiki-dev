# phase-field dual-treatment observation

_作成: 2026-05-11_  
_status: pilot evidence note_  
_role: `single / dual / dual+judgment` 比較で見えた treatment 差の固定_

---

## 1. この文書の役割

この文書は、`phase-field-cpp` implementation pilot において

- `single`
- `dual`
- `dual+judgment`

の 3 treatment を比較した結果、
**`dual` と `dual+judgment` は finding 件数は同じでも、後続判断の質が異なる**
という知見を固定するための短い evidence note である。

この文書は main claim の確定版ではない。
ただし、後の論文化で

- `adversarial` は何を増やしたか
- `judgment` は何を追加でやったか

を説明するための pilot observation として使う。

---

## 2. 対象 run

- batch:
  [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F1-phase-field-cpp/comparison_summary.json:1)
- `single` run:
  `run-20260511T005003Z-1f9fc703`
- `dual` run:
  `run-20260511T005003Z-91c5445a`
- `dual+judgment` run:
  `run-20260511T005003Z-4b7f9ca1`

---

## 3. 観測結果

### 3.1 件数

- `single`: `2 findings`
- `dual`: `3 findings`
- `dual+judgment`: `3 findings`

今回の pilot では、
`adversarial` を入れると `single -> dual` で `+1 finding` になった。
一方で `judgment` を入れても、
`dual -> dual+judgment` では finding 件数は増えなかった。

### 3.2 finding 内容

`dual` と `dual+judgment` の finding は、件数だけでなく
**本文・severity・source role も同じ** だった。

つまり今回の `judgment` は、
新しい finding を追加する役ではなかった。

### 3.3 質の変化

差が出たのは、finding 件数ではなく
**decision/disposition の情報量** である。

`dual`:

- `judgment_ref` なし
- `decision_units` の `proposed_action` は `manual_review_required`
- finding はあるが、どう扱うかは次工程へ持ち越し

`dual+judgment`:

- 各 finding に `judgment_ref` が付く
- `decision_units` に具体的な `proposed_action` が入る
- `necessary / optional` の区別が付く

今回の 3 finding に対する `judgment` 結果:

1. `boundary`: `necessary`
2. `update-order`: `optional`
3. `parameter-caveat`: `optional`

つまり今回の `judgment` は、
**候補を増やす処理ではなく、候補を disposition-ready にする処理**
として働いた。

---

## 4. 論文化上の意味

この pilot から少なくとも次が言える。

1. `adversarial` の寄与は finding 増分として観測できる
2. `judgment` の寄与は、必ずしも finding 増分としては出ない
3. ただし `judgment` は、finding を
   - `necessary`
   - `optional`
   - concrete proposed action
   へ整理することで、後続工程に渡す質を上げる

したがって、論文化では
`judgment` を
**recall 拡張手段**
としてではなく、
**candidate disposition / action shaping 手段**
として位置づける方が適切である。

---

## 5. 制約

この観測は `phase-field-cpp` の pilot 1 case に限られる。

まだ言えないこと:

- 他 case でも `dual` と `dual+judgment` が同件数になるか
- 他 case で `judgment` が finding 件数差として現れるか

したがって、今の位置づけは次である。

- **使ってよいこと**:
  `judgment` は件数以外の質差を生みうる、という pilot observation
- **まだ言ってはいけないこと**:
  `judgment` は常に finding 件数を変えない、という一般則

---

## 6. 次の確認点

この知見を強くするために、次は少なくとも 1 つ別 case で

- `single`
- `dual`
- `dual+judgment`

を取り、次のどちらかを確認したい。

1. `dual+judgment` で件数差が出る case がある
2. 件数差がなくても disposition quality 差が再現する

この役は、現時点では `heat3d-julia` が最有力候補である。
