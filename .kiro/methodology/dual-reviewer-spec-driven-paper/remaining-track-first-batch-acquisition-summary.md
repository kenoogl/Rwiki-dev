# Remaining Track First-Batch Acquisition Summary

_作成: 2026-05-11_  
_status: completed summary v0.1_  
_role: `Intent Track / Spec Track` の fresh first batch を paper-facing provenance として束ねる_

---

## 1. scope

この文書は、cross-track narrative の前半を埋めるために再取得した

- `Intent Track`
- `Spec Track`

の fresh first batch を短く束ねる。

旧 pilot batch は provenance として保持し、この文書では main paper 向けに取り直した narrative-connected batch を扱う。

---

## 2. batch refs

### 2.1 Intent Track

- batch:
  - [F1-intent-dual-reviewer-rebuild-narrative comparison summary](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild-narrative/comparison_summary.json:1)
- run labels:
  - `F1-intent-dual-reviewer-rebuild-narrative-single`
  - `F1-intent-dual-reviewer-rebuild-narrative-dual`

### 2.2 Spec Track

- batch:
  - [F1-spec-phase-field-reverse-spec-narrative comparison summary](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec-narrative/comparison_summary.json:1)
- run labels:
  - `F1-spec-phase-field-reverse-spec-narrative-single`
  - `F1-spec-phase-field-reverse-spec-narrative-dual`

---

## 3. result snapshot

### 3.1 Intent Track

- `single review`:
  - findings `2`
  - handback `0`
- `dual-reviewer workflow`:
  - findings `3`
  - handback `1`
- preserved reading:
  - dual only で `intent handback` が残り、`requirements / design / tasks` への propagation obligation が artifact に残った

### 3.2 Spec Track

- `single review`:
  - blocking issue `1`
  - reopen required `true`
  - intent-attributed issue `1`
- `dual-reviewer workflow`:
  - blocking issue `1`
  - reopen required `true`
  - intent-attributed issue `1`
  - major correction `1`
- preserved reading:
  - dual only で `major correction` と `B-class handback` が残り、`tasks` entry から `design / requirements` carry-over inconsistency を保持した

---

## 4. interpretation

今回の fresh batch では、旧 pilot と同じ finding pattern が再現した。

これは、

1. 旧 pilot の差分が偶然ではなかった
2. current paper narrative に接続し直しても、`Intent Track` では handback depth、`Spec Track` では reopen/correction depth が保持される
3. `Implementation Track` に偏っていた本文の前半を、別 provenance の fresh batch で埋められる

ことを意味する。

---

## 5. paper-facing consequence

これにより、3-track story は少なくとも first-batch level では acquisition-backed と言える。

- `Intent Track`
  - 上流 bootstrap と downstream propagation
- `Spec Track`
  - 中流 refinement と reopen / alignment
- `Implementation Track`
  - 下流 review acquisition と implementation trace

ただし、これは track ごとの初回 batch による成立確認であり、large-N comparison や behavioral adequacy の主張にはまだ使わない。
