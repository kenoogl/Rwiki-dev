# Spec Track first case: phase-field-reverse-spec

_作成: 2026-05-10_  
_最終更新: 2026-05-13_  
_status: draft v0.2_  
_role: `F1-spec-track` の concrete case 固定_

---

## 1. この文書の役割

この文書は、`Spec Track` の最初の取得バッチで使う
concrete case を固定する。

ここでの目的は、
既に `requirements / design / tasks` を持つ scientific case に対して、
`dual-reviewer` が downstream refinement, alignment, reopen / recheck を
どう支えるかを見ることである。

---

## 2. Fixed Case ID

- case id: `F1-spec-phase-field-reverse-spec`
- batch label: `F1-spec-track`
- track: `Spec Track`
- target label: `phase-field-reverse-spec`
- role in paper:
  - spec-origin で下流の認知的負荷が大きい候補ケース（最終確定は再取得後）。
  - 科学計算系の代表候補。

---

## 3. Case Definition

この case は、`phase-field-reverse-spec` の
`requirements / design / tasks` 一式を対象にする。

固定する対象は次の 3 層である。

1. intent-side anchor
2. spec-side anchor
3. downstream implementation reference

### 3.1 Intent-Side Anchor

- intent ref:
  - [phase-field-reverse-spec/intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/phase-field-reverse-spec/intent.md:1)

この intent は、三相フェーズフィールド code を
scientific simulation の仕様駆動開発 case として扱うための最上位入力である。

### 3.2 Spec-Side Anchor

- spec root:
  - [phase-field-reverse-spec](/Users/Daily/Development/Rwiki-dev/.kiro/specs/phase-field-reverse-spec)
- requirements:
  - [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/phase-field-reverse-spec/requirements.md:1)
- design:
  - [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/phase-field-reverse-spec/design.md:1)
- tasks:
  - [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/phase-field-reverse-spec/tasks.md:1)
- metadata:
  - [spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/phase-field-reverse-spec/spec.json:1)

phase status:

- requirements:
  - generated / approved
- design:
  - generated / not approved
- tasks:
  - generated / not approved
- current phase:
  - `tasks-generated`

Spec Track first-run では、この phase 状態自体も観測対象に含める。

### 3.3 Downstream Implementation Reference

downstream implementation との接続は、再取得後に固定する。再取得段階で、spec-side issue が downstream implementation へどう波及するかを説明する補助 anchor を選定する。

---

## 4. Why This Case

この case を `Spec Track` first-run に選ぶ理由は次である。

1. `requirements / design / tasks` が repo-contained で揃っている  
   first-run で phase 間整合と reopen depth を見やすい。

2. scientific case として認知負荷が高い  
   数値モデル、境界条件、可視化、入出力、clean-room 制約が同時に存在する。

3. downstream implementation reference がある  
   `Spec Track` の結果を `Implementation Track` に接続しやすい。

4. `intent` を持つ  
   `intent-attributed issue` を spec 側で追跡できる。

---

## 5. Review Boundary for First Run

first-run で主対象に含めるもの:

- `requirements / design / tasks`
- phase 間の依存関係
- missing requirement / design drift / task ordering issue
- reopen / recheck obligation
- `intent-attributed issue`

first-run で主対象にしないもの:

- implementation code quality の詳細比較
- numerical output の正しさ検証そのもの
- paper-facing reporting artifact の品質

つまりこの case で見るのは、
「spec-present case に対して review/governance loop が成立するか」である。

---

## 6. Required First-Run Outputs Bound to This Case

`F1-spec-phase-field-reverse-spec` で最低限残す出力:

- `run_manifest.yaml`
- `reviewed_phase_note.md`
- `alignment_artifact.yaml`
- `phase_metric_snapshot.json`
- `signal_linkage_note.yaml`
- protocol mismatch note（必要時）

加えて、run memo では少なくとも次を持つ。

- phase-local finding
- cross-phase inconsistency
- reopen required
- recheck target
- `intent-attributed issue`
- caveat

---

## 7. Comparison Modes Bound to This Case

`F1-spec-phase-field-reverse-spec` に対して固定する比較軸:

1. `single review`
2. `dual-reviewer workflow`

`manual reference` は optional とする。

---

## 8. Caveats

この case の caveat は次である。

1. current phase は `tasks-generated` で、design/tasks は未承認である
2. したがって first-run は「完成 spec の比較」ではなく
   「spec-origin review loop の成立確認」に重心を置く
3. downstream implementation reference はあるが、Spec Track first-run の main evidence ではない

この caveat は preliminary report では limitation として保持する。

---

## 9. Immediate Operational Rule

`Spec Track` first-run を開始する前に、少なくとも次を行う。

1. reviewed phase scope を明示する
   - `requirements`
   - `design`
   - `tasks`
2. `single review` と `dual-reviewer workflow` の両方で
   同じ spec root を使う
3. phase metric snapshot に phase 状態と reopen obligation を入れる
4. `intent-attributed issue` を downstream phase 側で区別する

これを満たした時点で、
`F1-spec-phase-field-reverse-spec` を fixed case とみなす。
