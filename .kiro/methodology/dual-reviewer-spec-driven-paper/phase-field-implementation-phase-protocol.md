# phase-field-cpp implementation-phase acquisition protocol

_作成: 2026-05-09_  
_status: draft v0.2_  
_role: `phase-field` case の implementation/review phase protocol_

---

## 1. 目的

この protocol は、`phase-field` case における implementation/review phase の取得条件を固定する。

本 case の役割は、単独の code review target ではない。
`phase-field-reverse-spec` から続く
**仕様駆動開発の downstream implementation artifact**
として `phase-field-cpp` を扱い、
その implementation/review phase を `dual-reviewer` がどう支えるかを観測する。

---

## 2. Case Definition

- case label: `phase-field`
- implementation-phase label: `phase-field-cpp`
- language: `C++`
- category: scientific / numerical implementation
- expected difficulty: `high`
- track:
  - `B/C`

### Upstream prerequisites

本 protocol の前提:

- `intent` は少なくとも再構成済みである
- `requirements / design / tasks` が存在する
- implementation code は downstream artifact として扱う

---

## 3. Review Boundary

implementation/review phase で対象に含めるもの:

- phase-field update logic
- boundary condition handling
- parameter semantics
- data structure / state update
- numerical caveat に関わる code と comments

原則として対象に含めないもの:

- build system convenience only の変更
- formatting-only noise
- benchmark harness only の変更

---

## 4. Provenance Rule

この case に関する prior observed metrics は、
main evaluation evidence として使わない。

つまり次は main comparison に入れない。

- 過去バージョンの reviewer で得た finding / rework / acceptance 統計
- Python 系 implementation process の観測値

main evaluation に使うのは、
Ruby 版 `dual-reviewer v1` で新たに取得する evidence のみである。

---

## 5. Comparison Setting

implementation/review phase で最低限の比較軸:

1. `single review`
   - implementation phase に対する単独 reviewer 相当
2. `dual only`
   - primary + adversarial
   - judgment なし
3. `dual-reviewer workflow`
   - adversarial / judgment / governance を含む標準系
4. `manual reference`
   - optional

解釈ルール:

- `manual reference` は absolute ground truth としない
- `dual-reviewer` の評価は finding count 単独で行わない
- process / evidence metrics を必ず併記する
- `phase-field-cpp` は representative implementation case として `single / dual / dual+judgment` を取得する
- ここでの `dual-reviewer workflow` は treatment 名としては `dual+judgment` を指す

---

## 6. Target-Specific Stress Points

この implementation phase で特に観測したい stress は次である。

1. algorithmic correctness
2. boundary condition semantics
3. parameter interpretation drift
4. update ordering and state mutation
5. numerical caveat retention
6. implementation-level brittleness

期待する `dual-reviewer` の役割:

- plausible-but-wrong explanation で premature closure しない
- disagreement を evidence として残す
- caveat を消さずに finding を扱う
- 必要なら reopen depth を明示する

---

## 7. Required Artifacts

最低限残すもの:

- case descriptor
- upstream spec refs
- implementation-phase review scope note
- review artifact
- decision units
- signal linkage
- conformance review result
- caveat / exclusion artifact
- downstream rework log

可能なら残すもの:

- target-specific finding taxonomy
- numerical caveat summary
- accepted / rejected finding rationale

---

## 8. Success Interpretation

この implementation phase で成功とみなすのは次である。

1. scientific code 特有の caveat を脱落させず review できる
2. disagreement evidence が残る
3. handback / reopen が必要なら depth が明示される
4. upstream spec と implementation review が切れずにつながる

失敗とみなすのは次である。

1. plausible explanation に流されて caveat が消える
2. adversarial/judgment の寄与が evidence に残らない
3. review artifact はあるが reopening logic が不明
4. upstream spec との traceability が切れる
