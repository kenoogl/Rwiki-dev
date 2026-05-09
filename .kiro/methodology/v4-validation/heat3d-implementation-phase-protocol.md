# heat3d-julia review acquisition protocol

_作成: 2026-05-09_  
_status: draft v0.1_  
_role: dual-reviewer code review evaluation の target-specific protocol_

---

## 1. 目的

この protocol は、3D heat conduction の Julia 実装を
`dual-reviewer` の code review evaluation target として扱う際の
取得条件を固定する。

本 target の主な役割は、
**PDE / discretization を含む scientific implementation review** に対して
`dual-reviewer` が caveat-preserving workflow を維持できるかを観測することである。

---

## 2. Target Definition

- target label: `heat3d-julia`
- language: `Julia`
- category: PDE / simulation implementation
- expected difficulty: `high`

### Review Boundary

review 対象に含めるもの:

- discretization-related code
- dimensional consistency に関わる logic
- update scheme
- state transition / array update
- performance caveat に関わる code and comments

原則として review 対象に含めないもの:

- plotting-only helper
- notebook formatting
- cosmetic refactor only

---

## 3. Why Julia

本 target では Julia を main に固定する。

理由:

- `phase-field-cpp` と言語を分け、heterogeneous target set を明確にする
- numerical code でありつつ C++ とは異なる abstraction level を持つ
- implementation detail よりも model/update/caveat の整理が中心になる

---

## 4. Comparison Setting

最低限の比較軸:

1. `single review`
2. `dual-reviewer workflow`
3. `manual reference`

解釈ルール:

- manual reference は calibration 用
- finding count 単独比較はしない
- caveat retention と traceability を主要比較軸に含める

---

## 5. Target-Specific Stress Points

この target で特に観測したい review stress は次である。

1. dimensional consistency
2. update scheme correctness
3. discretization assumption visibility
4. state transition ordering
5. performance caveat retention

期待する `dual-reviewer` の役割:

- 実装 detail と model assumption の混線を避ける
- findings を caveat と一緒に残す
- ambiguous finding を無理に must-fix 化しない

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

- discretization-caveat note
- performance-limitation note
- ambiguity classification memo

---

## 7. Review Mode Rule

- `single review`
  - finding と disposition を記録
- `dual-reviewer workflow`
  - disagreement, caveat retention, judgment effect を記録
- `manual reference`
  - qualitative reasoning を短く残す

---

## 8. Success Interpretation

この target で成功とみなすのは次である。

1. discretization / dimensional caveat を silent に落とさない
2. finding に supporting artifact と caveat が紐づく
3. reopen depth が必要なときに phase-local correction と上流 reopen を分けられる
4. downstream rework と review evidence が接続する

失敗とみなすのは次である。

1. model-level caveat が implementation finding に埋没する
2. performance caveat が mature claim のように扱われる
3. disagreement が記録されない
4. rework 後に traceability が切れる
