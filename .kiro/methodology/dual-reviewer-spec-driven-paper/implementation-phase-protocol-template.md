# implementation phase protocol template

_作成: 2026-05-12_  
_最終更新: 2026-05-13_  
_status: template v0.2_  
_purpose: 新しい implementation case の review acquisition protocol を、参照 case なしで起こすための最小 template_

---

## 1. 目的

この protocol は、`<target label>` を
`dual-reviewer` の implementation track review acquisition target として扱う際の
取得条件を固定する。

本 target の主な役割は、
**`<domain or code style>` review** に対して
`dual-reviewer` が `<観測したい維持項目（再取得時に固定）>` を
維持できるかを観測することである。

---

## 2. Target Definition

- target label: `<target-label>`
- language: `<language>`
- category: `<embedded | simulation | backend | ui | other>`
- expected difficulty: `<low | medium | high>`
- current split:
  - `<feature-a>`
  - `<feature-b>`

### Review Boundary

review 対象に含めるもの:

- `<implementation-local concern 1>`
- `<implementation-local concern 2>`
- `<owner boundary or handoff contract>`

原則として review 対象に含めないもの:

- `<cosmetic-only change>`
- `<deployment-external concern>`
- `<non-goal detail>`

---

## 3. Why This Target

本 target を implementation case に使う理由を書く。

最低限含める観点:

- なぜこの domain が review stress を与えるのか
- 既存 case とどう違う stress profile を持つのか
- 何を paper / evaluation で補完したいのか

---

## 4. Comparison Setting

最低限の比較軸:

1. `single review`
2. `dual-reviewer workflow`
3. `manual reference`

解釈ルール:

- manual reference は calibration 用
- count 単独比較ではなく、観測対象に応じた主軸を置く（具体項目は再取得段階で確定）
- downstream rework との接続を残す

---

## 5. Target-Specific Stress Points

この target で特に観測したい review stress を 3-5 件まで書く。

例:

1. `<timing / ordering / ownership / numerical caveat>`
2. `<failure contract>`
3. `<boundary preservation>`

期待する `dual-reviewer` の役割:

- `<what should be preserved or surfaced>`
- `<what should not be collapsed into generic style feedback>`
- `<what should remain a human-gated ambiguity>`

---

## 6. Required Artifacts

最低限残すもの:

- target descriptor
- review artifact
- decision units
- signal linkage
- caveat / exclusion artifact
- conformance review result
- downstream rework log

可能なら残すもの:

- `<domain caveat note>`
- `<boundary memo>`
- `<behavioral limitation note>`

---

## 7. Review Mode Rule

- `single review`
  - finding と disposition を記録
- `dual-reviewer workflow`
  - disagreement と判断記録を残す（具体項目は再取得段階で確定）
- `manual reference`
  - rationale summary を短く残す

---

## 8. Success Interpretation

この target で成功とみなす条件:

1. `<critical contract>` を silent に落とさない
2. finding に supporting artifact と caveat が紐づく
3. human gate が必要な曖昧点を強引に閉じない
4. downstream rework と review evidence がつながる

失敗とみなす条件:

1. `<domain-specific risk>` が generic issue に吸収される
2. caveat が lost する
3. disagreement が残らない
4. traceability が切れる

---

## 9. Minimal Customization Rule

この template を埋めるときの原則:

- 既存 completed case の stress point をそのままコピーしない
- case 固有に観測したい contract だけを書く
- この段階では heuristic rule まで増やしすぎない
- protocol 文書は target の読み方を固定し、解の押し付けには使わない
