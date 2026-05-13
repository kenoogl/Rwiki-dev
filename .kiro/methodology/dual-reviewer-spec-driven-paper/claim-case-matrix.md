# Claim-Case Matrix

_作成: 2026-05-09_  
_最終更新: 2026-05-13_  
_status: draft v0.2_  
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

`dual-reviewer` は、意図駆動開発（intent-driven development = 意図や仕様を起点に開発を進める方法）の下流の工程で、レビューでどこに注目するかを段階ごとに整理することを目指した設計である。そうした整理が下流での見落としや手戻りを実際に減らすかどうかは、観測課題として残し、本書では断定しない。

### Claim 2

`dual-reviewer` は、発見（finding）だけでなく、レビューア間の意見の不一致、注意書き、判断結果、差し戻しの重さといった付随情報を、レビュー成果物の中で機械可読な形で扱えるように設計されている。それらが実際に追跡可能な形で保持されているかは、観測課題として残す。

### Claim 3

`dual-reviewer` は、意図のみが存在する状態（intent-only）、仕様まで存在する状態（spec-present）、実装まで存在する状態（implementation-present）という 3 つの開始条件のいずれからも作業を起こせるよう設計されている。各条件で作業の流れが実際に維持されるかは、観測課題として残す。

### Claim 4

`dual-reviewer` は、レビュー後の成果物を、自己改善（self-improvement = 過去の信号から学んで次のレビューに反映する仕組み）や報告生成に渡せる構造で保存する設計である。再利用がどこまで実用に耐えるかは、観測課題として残す。

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

| claim | required case class |
|---|---|
| `Claim 1` | `Intent-origin` |
| `Claim 2` | `Intent-origin` または `Spec-origin`、補助として `Implementation-origin` |
| `Claim 3` | `Intent-origin` + `Spec-origin` + `Implementation-origin` の組 |
| `Claim 4` | `Implementation-origin`、ただし upstream `intent/spec` が必須 |

各主張の主証拠ケースと補助証拠ケースの割り当ては、再取得結果が揃った段階で別途決定する。本書ではケース類別の適合性のみを固定する。

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

`Claim 4` は implementation artifact を持つ case が必要である。観測対象は、コードの品質そのものではなく、レビュー成果物が後続処理に渡せる構造で保存されているかどうかである。

観測候補項目（最終確定は再取得後）:

- review artifact
- decision units
- caveat
- signal inventory
- self-improvement linkage
- paper-facing traceability

### Rule 5

敵対役と判断役の寄与を分けて示したい主張では、少なくとも 1 つの代表ケースで次の 3 方式（取得方式）を取る方針とする。

1. `single`（単独）
2. `dual`（二重）
3. `dual+judgment`（二重+判断）

設計上の意図は、二重で広がる候補と、判断で整理される差を分解できるようにすることである。実際にそうした分解が観測できるかは、再取得後の検証対象とする。

代表ケースの確定は、再取得が完了した段階で行う。

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
- 方式上の役割:
  - upstream package:
    - `phase-field-reverse-spec`
  - implementation package:
    - `F1-phase-field-cpp-r2`
  - 代表ケースとしての位置づけと、3 方式（単独 / 二重 / 二重+判断）取得の最終構成は、再取得後に確定する。

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
  - 論文での位置づけは、再取得が完了した段階で別途決定する。
- 観測候補項目（最終確定は再取得後）:
  - 作業の流れが成り立つかどうか
  - 実装段階を起点とする観測が得られるかどうか
  - レビュー成果物が後続処理に渡せる構造で保存されるかどうか
  - 仕様や設計の拘束が不足している場合に、それがレビュー側で見える形で現れるかどうか

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
  - 論文での位置づけは、再取得が完了した段階で別途決定する。
- 観測候補項目（最終確定は再取得後）:
  - 一般化したケースの最初の実装段階として、作業の流れが成り立つかどうか
  - 安全関連の指摘や注意書きが、改修反復に対してどのように扱われるか

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

1. 4 つの候補ケース（`dual-reviewer-rebuild`、`phase-field-reverse-spec` / `phase-field-cpp`、`heat3d`、`iot-arduino`）のケース類別への適合性は、上記のとおり固定する。
2. 各ケースの主証拠と補助証拠の割り当て、主線と支持線の区別、3 方式取得の代表ケース選定は、再取得が完了した段階で別途決定する。
3. 過去の取得結果（archive 配下）は、新規取得が完了するまで根拠として参照しない。
