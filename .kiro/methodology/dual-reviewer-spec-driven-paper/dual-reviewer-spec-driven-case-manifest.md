# dual-reviewer case manifest

_作成: 2026-05-09_  
_最終更新: 2026-05-13_  
_status: draft v0.3_  
_purpose: 仕様駆動開発支援評価に使う case の固定_

---

## 1. この文書の役割

この文書は、`dual-reviewer` の次段論文化において
主評価対象として扱う case を固定するための manifest である。

ここでいう case は、単なる code target ではない。
`intent/spec/design/tasks/implementation/review` のどの段階から始まるかを含む。

---

## 2. Case 分類

### Intent Track

- 開始点:
  - `intent`
- 観測したいこと:
  - requirement 化
  - design/task 化
  - `D/C/B/A` handback

### Spec Track

- 開始点:
  - `requirements/design/tasks`
- 観測したいこと:
  - downstream refinement
  - alignment gate
  - reopen / recheck

### Implementation Track

- 開始点:
  - implementation artifact
- 観測候補項目（最終確定は再取得後）:
  - 実装段階のレビューが作業の流れの中で成立するかどうか
  - 注意書きやレビューア間の意見の不一致が成果物として保持されるかどうか
  - 下流で生じる手戻りを追跡できるかどうか

---

## 3. Core Evaluation Set

### C-1: dual-reviewer-rebuild

- category:
  - intent-origin internal rebuild case
- track:
  - `Intent Track / Spec Track / Implementation Track`
- role in paper:
  - 作業の流れが成立するかを観測する候補ケース（最終確定は再取得後）。
  - intent-only 開始の代表候補。

### C-2: phase-field reverse-spec / phase-field-cpp

- core case note:
  - [core-case-phase-field.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-phase-field.md:1)
- category:
  - scientific / numerical case
- track:
  - `Spec Track / Implementation Track`
- intent ref:
  - [phase-field-reverse-spec/intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/phase-field-reverse-spec/intent.md:1)
- role in paper:
  - 下流の認知的負荷が大きい候補ケース（最終確定は再取得後）。
  - spec-present 開始の代表候補。

### C-3: heat3d

- core case note:
  - [core-case-heat3d.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-heat3d.md:1)
- status:
  - 候補ケース。最終的な役割は再取得後に確定する。
- category:
  - PDE / simulation case
- track:
  - `Spec Track / Implementation Track` を想定
- intent ref:
  - [heat3d-spec/intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1)
- role in paper:
  - シミュレーション系の実装段階の候補ケース（最終確定は再取得後）。

### C-4: iot-arduino

- core case note:
  - [core-case-iot-arduino.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-iot-arduino.md:1)
- status:
  - 候補ケース。最終的な役割は再取得後に確定する。
- category:
  - embedded / event-driven case
- track:
  - `Implementation Track` を中心に、intent/spec 作成後は `Spec Track` も追加
- intent ref:
  - [iot-arduino-spec/intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/intent.md:1)
- role in paper:
  - 組み込み・イベント駆動系の候補ケース（最終確定は再取得後）。

---

## 4. Selection Rule

各 case は次のいずれかを満たす必要がある。

1. `intent` から開始できる
2. `requirements/design/tasks` が存在する
3. implementation artifact があり、対応する上流 spec を持つか再構成できる

上流を持たない孤立 code snapshot は、main case にしない。

---

## 5. Evidence Rule

main evaluation に含める evidence は、
**`dual-reviewer v2` で新たに取得するものだけ** とする。

過去バージョンで得た観測値は、

- main evidence
- comparison metric
- performance claim

には使わない。

許される用途は次のみ。

- boundary explanation
- case provenance note
- historical memo

---

## 6. Track-to-Paper Mapping

| case | 役割の類別（確定は再取得後） |
|------|----------------------|
| `dual-reviewer-rebuild` | intent-origin 候補ケース |
| `phase-field reverse-spec / cpp` | spec-origin と implementation-origin の候補ケース |
| `heat3d` | implementation-origin の候補ケース |
| `iot-arduino` | implementation-origin の候補ケース |

各ケースの最終的な貢献（主証拠と補助証拠の区別など）は、再取得が完了した段階で確定する。

---

## 7. Success Condition

この manifest が機能したとみなす条件は次である。

1. Intent Track / Spec Track / Implementation Track を少なくとも 1 case ずつ持つ
2. phase ごとの evidence を main paper claim に対応づけられる
3. implementation case も upstream spec と切り離さず説明できる
4. prior evidence と main evidence の provenance を混同しない
