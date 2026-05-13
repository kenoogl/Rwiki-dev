# iot-arduino implementation review acquisition protocol

_作成: 2026-05-09_  
_最終更新: 2026-05-13_  
_status: draft v0.3_  
_role: `iot-arduino` implementation track の target-specific review acquisition protocol_

---

## 1. 目的

この protocol は、Arduino / IoT 系 C コードを
`iot-arduino` implementation track の review acquisition target として扱う際の
取得条件を固定する。

本 target の主な役割は、
**event-driven / operational code review** に対して
`dual-reviewer` が workflow portability を維持できるかを観測することである。

---

## 2. Target Definition

- target label: `iot-arduino-c`
- language: `C`
- category: embedded / event-driven code
- expected difficulty: `medium-high`
- current split:
  - `loop-outside-control`
  - `watering-loop`

### Review Boundary

review 対象に含めるもの:

- event loop
- timing-sensitive logic
- I/O handling
- sensor / actuator interaction
- failure handling
- deployment-relevant comments or configuration
- owner boundary と handoff contract

原則として review 対象に含めないもの:

- trivial constant rename
- purely cosmetic serial print cleanup
- hardware-external documentation only
- credential provisioning detail

---

## 3. Why Arduino C

本 target は scientific code と異なる stress profile を与える。

狙い:

- timing / ordering / I/O safety
- operational failure mode
- deployment caveat

を含むため、
`dual-reviewer` が scientific domain 専用に崩れていないことを示しやすい。

---

## 4. Comparison Setting

最低限の比較軸:

1. `single review`
2. `dual-reviewer workflow`
3. `manual reference`

解釈ルール:

- manual reference は qualitative calibration 用
- 観測項目は再取得段階で確定する
- accepted finding と downstream fix を結び付ける

---

## 5. Target-Specific Stress Points

この target で特に観測したい review stress は次である。

1. timing / event ordering
2. I/O safety
3. operational failure mode
4. concurrency-like hazards

期待する `dual-reviewer` の役割:

- harmless-looking code path の operational risk を拾う
- domain caveat を evidence に残す
- human gate が必要な operational ambiguity を分離する

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

- timing hazard note
- operational limitation note
- deployment caveat note

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

この target で成功とみなすのは次である。

1. operational hazard を harmless cosmetic issue に矮小化しない
2. timing / I/O caveat が structured artifact に残る
3. human judgment が必要な曖昧点を強引に閉じない
4. downstream fix / rollback に接続できる evidence が残る

失敗とみなすのは次である。

1. event-driven risk が generic style issue に吸収される
2. operational caveat が lost する
3. disagreement が残らない
4. downstream rework と finding が結べない
