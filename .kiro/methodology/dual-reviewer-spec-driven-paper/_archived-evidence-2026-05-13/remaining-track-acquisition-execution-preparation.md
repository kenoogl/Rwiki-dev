# Remaining Track Acquisition Execution Preparation

_作成: 2026-05-11_  
_status: execution-ready prep v0.2_  
_role: `Intent Track / Spec Track` の残り acquisition を実行準備レベルに落とす_

---

## 1. purpose

この文書は、既に narrative role が固定された

- `Intent Track`
- `Spec Track`

について、次に何を実行すべきかを concrete に落とす。

ここでは first batch 実行直前までの固定を行い、

- 実行順
- case scope
- review mode
- required artifact
- human judgment が必要になる停止点

を固定する。

---

## 2. execution order

推奨順序は次である。

1. `Intent Track` first-run
2. `Spec Track` first-run

理由:

1. cross-track story の欠けている前半は `Intent -> Spec` の順で埋まる
2. `Intent Track` の propagation evidence が、その後の `Spec Track` の interpretation rule を支える
3. `Implementation Track` はすでに `phase-field` と `heat3d` で本文接続済みであり、次の narrative gap は upstream 側にある

---

## 3. Intent Track execution prep

### 3.1 fixed target

- case id:
  - `F1-intent-dual-reviewer-rebuild`
- target:
  - [intent-track-first-case-dual-reviewer-rebuild.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/intent-track-first-case-dual-reviewer-rebuild.md:1)
- run plan:
  - [intent-track-first-run-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/intent-track-first-run-plan.md:1)
- run template:
  - [intent-track-run-template.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/intent-track-run-template.md:1)

### 3.2 recommended execution shape

- review modes:
  - `single review`
  - `dual-reviewer workflow`
- minimum output:
  - intent review artifact
  - intent-to-requirements trace note
  - phase metric snapshot
  - signal linkage
  - propagation issue memo

### 3.3 narrative target

この run で本文に接続したい最小読みは次である。

- `intent` を最上位入力にした bootstrap loop が成立した
- `D` handback と propagation obligation が artifact に残った
- upstream uncertainty を premature closure しなかった

---

## 4. Spec Track execution prep

### 4.1 fixed target

- case id:
  - `F1-spec-phase-field-reverse-spec`
- target:
  - [spec-track-first-case-phase-field-reverse-spec.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/spec-track-first-case-phase-field-reverse-spec.md:1)
- run plan:
  - [spec-track-first-run-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/spec-track-first-run-plan.md:1)
- run template:
  - [spec-track-run-template.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/spec-track-run-template.md:1)

### 4.2 recommended execution shape

- review modes:
  - `single review`
  - `dual-reviewer workflow`
- reviewed phase scope:
  - recommended start: `tasks` as entry phase
  - required carry-over:
    - `design` inconsistency
    - `requirements` inconsistency
    - `intent-attributed issue`
- minimum output:
  - reviewed phase note
  - alignment artifact or memo
  - phase metric snapshot
  - signal linkage
  - phase propagation note

### 4.3 narrative target

この run で本文に接続したい最小読みは次である。

- spec-present case で review / alignment / reopen loop が成立した
- downstream refinement と cross-phase inconsistency が artifact に残った
- reopen / recheck depth を phase 単位で保持できた

---

## 5. resolved execution decisions

実行前に止まるべき点として挙げていた 3 点は、今回は次のように固定した。

1. `Intent Track` の exact input intent ref
   - fixed:
     - [dual-reviewer-spec-driven-paper-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-paper-plan.md:1)
2. `Spec Track` の reviewed phase scope
   - fixed:
     - `tasks` を entry phase とする
     - `design inconsistency`, `requirements inconsistency`, `intent-attributed issue` を carry-over mandatory とする
3. artifact placement
   - fixed:
     - intent narrative batch:
       - `dual-reviewer-rebuild/experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild-narrative`
     - spec narrative batch:
       - `dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec-narrative`

旧 pilot batch は provenance 用に残し、今回の fresh batch とは分けて扱う。

---

## 6. immediate next action

この execution prep の次にやるべきことは次である。

1. fresh `Intent Track` narrative batch を実行する
2. fresh `Spec Track` narrative batch を実行する
3. comparison summary と paper-facing acquisition summary を作成する
