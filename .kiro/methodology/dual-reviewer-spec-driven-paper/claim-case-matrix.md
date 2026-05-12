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

`dual-reviewer` は、意図駆動開発の下流工程で review attention を構造化し、cognitive brittleness を緩和するよう設計されている。

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
| `Claim 1` | `Intent-origin` | `dual-reviewer-rebuild` | intent 付き `phase-field-reverse-spec`, intent 付き `heat3d`, intent 付き `iot-arduino` | `intent` がない case |
| `Claim 2` | `Intent-origin` または `Spec-origin`、補助として `Implementation-origin` | `dual-reviewer-rebuild`, intent 付き `phase-field-reverse-spec` | `F1-phase-field-cpp-r2`, intent 付き `heat3d`, intent 付き `iot-arduino` | intent なし code-only case |
| `Claim 3` | `Intent-origin` + `Spec-origin` + `Implementation-origin` の組 | `dual-reviewer-rebuild` + intent 付き `phase-field-reverse-spec` + `F1-phase-field-cpp-r2` | `heat3d`, `iot-arduino` | `intent-absent reconstruction` を主 case にすること |
| `Claim 4` | `Implementation-origin`、ただし upstream `intent/spec` が必須 | `F1-phase-field-cpp-r2`, `heat3d-julia` | `iot-arduino` | upstream を持たない implementation-only case |

---

## 5. Interpretation Rules

### Rule 1

`Claim 1` の主証拠は `Intent-origin case` に限る。

理由:
- cognitive burden support の主張は、`intent` から下流へ降りる局面で最も強く観測されるため。

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

### Rule 5

`adversarial` と `judgment` の寄与を分けて示したい claim では、
少なくとも 1 つの代表 case で

1. `single`
2. `dual`
3. `dual+judgment`

の 3 treatment を取る。

理由:
- `dual` だけで増える候補
- `judgment` を入れると整理される差
を分解して示すため。

現時点の代表 case は `F1-phase-field-cpp-r2` とする。

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
- intent ref:
  - [phase-field-reverse-spec/intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/phase-field-reverse-spec/intent.md:1)
- supports after intent creation:
  - `Claim 2`
  - `Claim 3`
  - `Claim 4`
- treatment role:
  - upstream package:
    - `phase-field-reverse-spec`
  - implementation package:
    - `F1-phase-field-cpp-r2`
  - `F1-phase-field-cpp-r2` を representative 3-treatment implementation case として使う
  - `single / dual / dual+judgment` を取得して `adversarial` と `judgment` の寄与を分ける

### C-3 `heat3d`

- current class:
  - `Spec-origin` / `Implementation-origin`
- primary language:
  - Julia
- intent ref:
  - [heat3d-spec/intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1)
- supports after intent creation:
  - `Claim 2`
  - `Claim 3`
  - `Claim 4`
- paper role:
  - bridge implementation case
- reading:
  - workflow validity
  - implementation-origin evidence
  - evidence reusability
  - spec/design underconstraint exposure

### C-4 `iot-arduino`

- current class:
  - `Spec-origin` / `Implementation-origin`
- primary language:
  - C
- intent ref:
  - [iot-arduino-spec/intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/intent.md:1)
- supports after intent creation:
  - `Claim 2`
  - `Claim 3`
  - `Claim 4`
- paper role:
  - snapshot-based supporting case
- reading:
  - generalized first implementation case
  - stable safety finding / preserved caveat evidence

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

1. `dual-reviewer-rebuild` を `Intent-origin` の主証拠に固定する
2. `phase-field-reverse-spec` を `Spec-origin` の主証拠に固定する
3. `F1-phase-field-cpp-r2` を clean 3-treatment implementation comparison case として扱う
4. `heat3d-julia` を bridge implementation case として扱う
5. `iot-arduino` を generalized supporting case として扱う
6. 追加 case は、この tiering を崩さない範囲で supporting evidence として足す

つまり、現時点の main line は
**`F1 upstream` + `F1-phase-field-cpp-r2` + `F2 heat3d`**
であり、`iot-arduino` は supporting line として読む。
