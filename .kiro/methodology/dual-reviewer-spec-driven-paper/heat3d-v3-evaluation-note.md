# heat3d v3 evaluation note

_作成: 2026-05-11_  
_status: recorded v0.1_  
_role: `heat3d` を v3 code-conformance evaluation case として保存するための判断メモ_

---

## 1. judgment

`heat3d` は、**v3 の code-conformance evaluation case として保存する**。

この判断は、`heat3d` を現時点で main paper の fixed core case に即昇格させる、という意味ではない。  
ここで固定するのは次である。

1. `heat3d` は workflow / review acquisition / implementation まで実際に回った
2. clean-room 実装は成立した
3. しかし reference log と behavioral match は取れていない
4. したがって、この case は `implementation bug` 断定より先に `spec/design underconstraint` を観測したケースとして読むべきである

---

## 2. observed split

今回の `heat3d` では、次の split が明確に観測された。

### 2.1 spec conformance side

- `intent -> requirements -> design -> tasks` の gate-based workflow は回った
- approved upstream bundle を根拠に clean-room implementation を作れた
- code は実際に動き、unit/smoke validation を通過した

### 2.2 behavioral adequacy side

- [log.txt](/Users/Daily/Development/Heat3ds/log.txt:1) の reference behavior とは大きく違う結果になった
- current implementation は形式条件を満たしても、reference log の `theta_max` や収束挙動を再現しなかった
- よって、「approved spec/design だけで所望挙動を十分拘束できていた」とは言えない

---

## 3. why this matters for v3

v3 で見たいのは、まず **code と upstream artifact の整合性** である。

`heat3d` はその評価に向く。理由は次である。

1. upstream artifact が揃っている
   - intent
   - requirements
   - design
   - tasks
2. actual implementation が存在する
3. behavioral mismatch が出た
4. したがって、`code ↔ tasks/design/requirements` の一致不一致を調べる意義が明確である

この case で v3 が判定したい問いは次になる。

- code と approved tasks/design/requirements が一致しているか
- もし一致していれば、behavior mismatch は spec/design insufficiency と読めるか
- もし一致していなければ、implementation error または LLM interpretation drift と読めるか

---

## 4. evaluation reading rule

`heat3d` を v3 で使うときは、次の順序で読む。

1. `code ↔ tasks/design/requirements` の conformance を判定する
2. conformance が高ければ、behavior mismatch は first-order で spec/design insufficiency とみなす
3. conformance が低ければ、implementation deviation とみなす
4. そのうえで初めて、reference behavior との差を spec 側へ返す

つまり、この case の primary value は
`正解コードを当てること`
ではなく、
`behavior mismatch の責任所在を upstream artifact と implementation のどちらへ返すべきか切り分けること`
にある。

---

## 5. preserved artifact set

v3 evaluation case として最低限参照する artifact は次である。

- upstream:
  - [heat3d-spec/intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1)
  - [heat3d-foundation/spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/spec.json:1)
  - [heat3d-linear-solver/spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/spec.json:1)
  - [heat3d-case-model/spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/spec.json:1)
  - [heat3d-main/spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/spec.json:1)
- workflow/evidence:
  - [heat3d-c3-evidence-bundle.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-c3-evidence-bundle.md:1)
  - [implementation-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/implementation-evidence-summary.md:1)
  - [heat3d-implementation-execution-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-implementation-execution-note.md:1)
- code/reference:
  - [/Users/Daily/Development/DR-heat3d/src/Heat3D.jl](/Users/Daily/Development/DR-heat3d/src/Heat3D.jl:1)
  - [/Users/Daily/Development/Heat3ds/log.txt](/Users/Daily/Development/Heat3ds/log.txt:1)

---

## 6. conclusion

`heat3d` は、`dual-reviewer v3` において

- code review from approved upstream artifact
- implementation deviation vs spec underconstraint の切り分け
- behavioral mismatch の責任分解

を評価するケースとして保存する。
