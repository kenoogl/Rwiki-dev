# heat3d phase-field implementation comparison note

_作成: 2026-05-11_  
_status: post-acquisition observation note_  
_role: `F1-phase-field-cpp` と `F2-heat3d-julia` の implementation-track 差分を固定_

---

## 1. この文書の役割

この文書は、implementation track の 2 case

- `F1-phase-field-cpp`
- `F2-heat3d-julia`

を並べて、

- 何が共通 finding として再現したか
- `single -> dual` で増えた 1 件が何か
- `heat3d` の gate-approved rerun で何が確認できたか

を短く固定するための observation note である。

---

## 2. 対象 artifact

### 2.1 phase-field

- summary:
  [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F1-phase-field-cpp/comparison_summary.json:1)
- content read:
  - [single review artifact](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F1-phase-field-cpp/exports/bundle-run-20260510T215435Z-66f7b030/run/run-20260510T215435Z-66f7b030/v2/review_artifact.json:1)
  - [dual+judgment review artifact](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F1-phase-field-cpp/exports/bundle-run-20260510T215435Z-42f86b08/run/run-20260510T215435Z-42f86b08/v2/review_artifact.json:1)

### 2.2 heat3d

- summary:
  [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F2-heat3d-julia/comparison_summary.json:1)
- content read:
  - [single review artifact](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F2-heat3d-julia/runtime-runs/run-20260511T062535Z-d6c4618a/v2/review_artifact.json:1)
  - [dual review artifact](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F2-heat3d-julia/runtime-runs/run-20260511T062535Z-e945dac7/v2/review_artifact.json:1)
  - [dual+judgment review artifact](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F2-heat3d-julia/runtime-runs/run-20260511T062535Z-70acf852/v2/review_artifact.json:1)

---

## 3. 共通パターン

- 両 case とも件数は `2 / 3 / 3` だった
- `single` の 2 件は両方とも
  - `boundary-condition semantics`
  - `update ordering / state mutation`
  だった
- `single -> dual` で増えた 1 件は両方とも `parameter-caveat` 系だった

したがって、現時点の 2 case では

1. `adversarial` を入れると `+1 finding`
2. その追加分は `parameter interpretation / caveat surface`

という読みは崩れていない。

---

## 4. case 差分

### 4.1 phase-field

`phase-field` の 3 件目は、

- defaults
- CLI meaning
- reconstruction caveat

のズレ可能性として出ている。

根拠は snapshot と approved `requirements / design / tasks` に分散しており、
「upstream から implementation behavior への mapping を明示しないと drift しうる」
という一般形に寄っている。

### 4.2 heat3d

`heat3d` の 3 件目は、

- fixed MVP case
- solver defaults
- clean-room boundary
- snapshot rationale

の読み違いリスクとして出ている。

特に [heat3d-julia-implementation-phase-first-snapshot.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-julia-implementation-phase-first-snapshot.md:1)
が
`fixed MVP case` と `clean-room constraint` を review boundary に入れているため、
adversarial finding が snapshot rationale 依存で強化されている。

---

## 5. heat3d rerun の意味

今回の `heat3d` は、旧 pilot と違って

- umbrella input
- approved `requirements`
- approved `design`
- approved `tasks`

を upstream input に含めた gate-approved rerun だった。

それでも finding pattern が `2 / 3 / 3` のままだったことから、少なくとも次は言える。

1. `heat3d` の review acquisition gate package は runtime batch に接続できた
2. approved upstream bundle を追加しても、core finding shape は崩れなかった
3. 3 件目の `parameter-caveat` は `phase-field` 局所ではなく second case でも再現した

---

## 6. 現時点の読み

今の 2 case からの最小読みは次である。

1. `boundary` と `update-order` は simulation implementation track の共通 first-pass finding 候補である
2. `parameter-caveat` は adversarial pass で増えやすい third finding 候補である
3. ただし `parameter-caveat` の具体的根拠は case ごとの snapshot rationale と upstream packaging に依存する

つまり、一般化できるのは
`parameter interpretation / caveat surface が立つ`
ところまでであり、証拠の置き方までは case 固有である。

---

## 7. caveat

`phase-field` 側は、summary が指す `2026-05-11` run id の local runtime bundle を直接参照できなかったため、
内容比較には local export に残っている最新の

- `single`
- `dual+judgment`

bundle を使った。

ただし、

- summary 上の件数 `2 / 3 / 3`
- `parameter-caveat` が 3 件目であること

は一致しているため、この note では pattern comparison 用の補助 evidence として使っている。
