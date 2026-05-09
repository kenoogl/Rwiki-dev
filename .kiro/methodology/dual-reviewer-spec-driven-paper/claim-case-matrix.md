# Claim-Case Matrix

_作成: 2026-05-09_  
_status: draft v0.1_  
_purpose: claim と評価 case の対応を固定する_

---

## 1. この文書の役割

この文書は、`Claim 1-4` と評価 case の対応を
直交表として固定するための文書である。

目的は次の 3 つである。

1. claim ごとに何が必須 evidence かを明確にする
2. case の役割を主評価 / 補助評価 / 不採用で分ける
3. `intent` がない case を main paper から外す rule を固定する

---

## 2. Claim Definitions

### Claim 1

`dual-reviewer` は、仕様駆動開発の下流工程における cognitive brittleness を減らす。

### Claim 2

`dual-reviewer` は、finding だけでなく disagreement, caveat, disposition, handback depth を traceable に残す。

### Claim 3

`dual-reviewer` は、`intent-only`, `spec-present`, `implementation-present` の異なる開始条件でも workflow を維持できる。

### Claim 4

`dual-reviewer` は、review 後の evidence を self-improvement / reporting に再利用可能な形で残す。

---

## 3. Case Classes

### Intent-origin case

- 明示的な `intent` を持つ
- `requirements / design / tasks` への伝播を観測できる

### Spec-origin case

- `intent` を持つ
- 開始点は `requirements / design / tasks`

### Implementation-origin case

- `intent` と upstream spec を持つ
- 開始点は implementation artifact

### Excluded case

- `intent` がない
- 上流 spec がない、または review 用に固定されていない
- code-only snapshot で workflow 主張を支えられない

---

## 4. Orthogonal Matrix

| claim | required case class | primary case | secondary case | not acceptable as main evidence |
|---|---|---|---|---|
| `Claim 1` | `Intent-origin` | `dual-reviewer-rebuild` | intent を新設した `phase-field` / `heat3d` / `iot-arduino` | `intent` がない case |
| `Claim 2` | `Intent-origin` または `Spec-origin`、補助として `Implementation-origin` | `dual-reviewer-rebuild`, intent 付き `phase-field-reverse-spec` | intent 付き `heat3d`, intent 付き `iot-arduino` | intent なし code-only case |
| `Claim 3` | `Intent-origin` + `Spec-origin` + `Implementation-origin` の組 | `dual-reviewer-rebuild` + intent 付き `phase-field-reverse-spec` + intent 付き `phase-field-cpp` | intent 付き `heat3d`, intent 付き `iot-arduino` | `intent-absent reconstruction` を主 case にすること |
| `Claim 4` | `Implementation-origin`、ただし upstream `intent/spec` が必須 | intent 付き `phase-field-cpp` | intent 付き `heat3d-julia`, intent 付き `iot-arduino-c` | upstream を持たない implementation-only case |

---

## 5. Interpretation Rules

### Rule 1

`Claim 1` の主証拠は `Intent-origin case` に限る。

理由:
- 認知負荷軽減の主張は、`intent` から下流へ降りる局面で最も強く観測されるため。

### Rule 2

`Claim 2` は複数開始条件で観測可能だが、
少なくとも 1 つは upstream `intent` を持つ case を含める。

理由:
- traceability の主張が code-only case だけだと、`intent-attributed issue` を評価できないため。

### Rule 3

`Claim 3` は 3 開始条件すべてを 1 回ずつ成立させる必要がある。

必要な最低構成:

1. `Intent-origin`
2. `Spec-origin`
3. `Implementation-origin`

### Rule 4

`Claim 4` は implementation artifact を持つ case が必要だが、
main evidence は code quality ではなく evidence reusability である。

見るもの:

- review artifact
- decision units
- caveat
- signal inventory
- self-improvement linkage
- paper-facing traceability

---

## 6. Current Candidate Mapping

### C-1 `dual-reviewer-rebuild`

- current class:
  - `Intent-origin`
- primary language:
  - Ruby
- supports:
  - `Claim 1`
  - `Claim 2`
  - `Claim 3`
- notes:
  - current main bootstrap case

### C-2 `phase-field`

- current class:
  - `Spec-origin` / `Implementation-origin`
- primary language:
  - C++ (implementation phase)
- prerequisite:
  - explicit `intent` must be authored first
- supports after intent creation:
  - `Claim 2`
  - `Claim 3`
  - `Claim 4`

### C-3 `heat3d`

- current class:
  - `Spec-origin` / `Implementation-origin`
- primary language:
  - Julia
- prerequisite:
  - explicit `intent` must be authored first
- supports after intent creation:
  - `Claim 2`
  - `Claim 3`
  - `Claim 4`

### C-4 `iot-arduino`

- current class:
  - `Spec-origin` / `Implementation-origin`
- primary language:
  - C
- prerequisite:
  - explicit `intent` must be authored first
- supports after intent creation:
  - `Claim 2`
  - `Claim 3`
  - `Claim 4`

---

## 7. Selection Rule

main paper で使う case は、次の条件を満たすものに限定する。

1. 明示的な `intent` がある
2. 対応する `requirements/design/tasks` がある、または固定できる
3. implementation を使う場合も upstream spec と結びついている

次は main paper の case にしない。

1. `intent` がない case
2. review 時点で `intent` を後付け再構成していない case
3. code-only snapshot

---

## 8. Immediate Consequence

この matrix から導かれる次の作業は次である。

1. `phase-field` の intent を作る
2. `heat3d` の intent を作る
3. `iot-arduino` の intent を作る
4. その後に `Spec Track` / `Implementation Track` case を正式固定する

つまり、今後の case 追加は
**intent 作成が先、track 固定が後**
で進める。
