# heat3d case fixation decision

_作成: 2026-05-11_  
_status: fixed decision v0.1_  
_role: `C-3 heat3d` を main paper の fixed core case として扱う判断を明文化する_

---

## 1. decision

`heat3d` は、**main paper の fixed core case として固定する**。

同時に、`heat3d` は **v3 の code-conformance evaluation case としても保存する**。

この 2 つは矛盾しない。  
main paper では `workflow / spec / review acquisition / implementation trace` の主要ケースとして使い、`v3` では `code ↔ upstream artifact` の整合性評価ケースとして使う。

---

## 2. why fixed now

`heat3d` は、main paper の core case として要求していた条件を満たしている。

1. 明示的な `intent` がある
2. `requirements / design / tasks` が formalized され、承認済みである
3. `review acquisition` が upstream spec と結びついた形で取得済みである
4. actual implementation も存在する
5. workflow 上の restart / reopen / recheck / gate approval が trace として残っている

したがって、`heat3d` は `Claim 2 / 3 / 4` を支える `C-3` の main paper case として固定してよい。

---

## 3. what is fixed

fixed にするのは次である。

- `heat3d` を `C-3` の main paper core case として使うこと
- `Spec-origin / Implementation-origin` の両方を担うこと
- approved upstream artifact と clean-room implementation trace を、この case の正本 evidence として使うこと

---

## 4. what is not claimed

fixed core case にしたからといって、次まで確定したわけではない。

1. canonical full-case acceptance `13.4` が十分に確立した
2. current implementation が reference behavior を再現した
3. behavioral mismatch が implementation bug だと確定した
4. `13.4` full-scale runtime acceptance が implementation correctness oracle だと確定した

つまり、fixed なのは **case identity と paper role** であって、behavioral adequacy の結論ではない。

補足:

- `13.4` を main paper の admission gate にしない判断は
  [heat3d-validation-boundary-decision.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-validation-boundary-decision.md:1)
  に固定した

---

## 5. reading rule

`heat3d` を main paper で使うときは、次のように読む。

### 5.1 main paper side

- workflow が回った
- approved spec bundle が作れた
- review acquisition が取れた
- clean-room implementation まで進めた
- implementation-local rework と upstream underconstraint の切り分け材料が得られた

### 5.2 v3 side

- reference behavior mismatch を起点に
- code と approved `tasks/design/requirements` の conformance を検査し
- implementation deviation か spec underconstraint かを切り分ける

---

## 6. preserved caveat

`heat3d` で最も重要な caveat は次である。

approved upstream artifact から clean-room implementation を作ると、コードは動作し reduced validation も通るが、reference log と同じ behavior を必ずしも再現しない。

この観測は `heat3d` の価値を下げるものではない。  
むしろ、`dual-reviewer` を

- implementation correctness detector
ではなく
- spec/design underconstraint exposure tool

として評価する材料になる。

---

## 7. linked artifacts

- [core-case-heat3d.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-heat3d.md:1)
- [heat3d-c3-evidence-bundle.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-c3-evidence-bundle.md:1)
- [heat3d-v3-evaluation-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-v3-evaluation-note.md:1)
