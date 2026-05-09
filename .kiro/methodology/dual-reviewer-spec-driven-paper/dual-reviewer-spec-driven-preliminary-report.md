# Preliminary Paper Report — dual-reviewer spec-driven development support

_作成: 2026-05-09_  
_status: draft v0.2_  
_position: intent-origin 仕様駆動開発支援論文の preliminary preview_

---

## 1. Executive Summary

本報告は、`dual-reviewer` の次段論文化に向けた preliminary report である。

今回の論文では、単独の code review evaluation を主結果に置かず、
**intent 起点の仕様駆動開発支援** を主結果に置く。

現時点で言えることは次である。

1. `dual-reviewer v1` は構築済みであり、governance と conformance review を含む最低限の workflow が成立している
2. manual dogfooding evidence は system construction validity の証拠として利用できる
3. 次の主評価は `Intent Track`, `Spec Track`, `Implementation Track` の 3 分類で整理する
4. code review は主線ではなく implementation/review phase の一部として扱う

---

## 2. Research Framing

本研究の中心問題は、
LLM code review に複数 agent を入れること自体ではない。

中心問題は、

- `intent` しかない状態で論点漏れや premature closure が起きやすい
- `design/tasks` で detail が増えるほど人間の認知負荷が高まる
- implementation/review phase では disagreement や caveat が落ちやすい
- 手戻りが起きても、どこまで戻るべきかを管理できないと workflow が壊れる

という点である。

この問題に対し、`dual-reviewer` は

- adversarial review
- judgment
- handback / reopen
- governance
- evidence retention

を組み合わせた workflow system として設計されている。

---

## 3. Novelty and Intended Appeal

### 3.1 Core novelty

本研究の core novelty は次である。

- `intent` 起点の仕様駆動開発支援を review workflow system として扱う
- finding quality と process/evidence quality を同時に評価する
- implementation/review phase まで含めた end-to-end support を示す

### 3.2 adversarial review の位置づけ

`adversarial review` は novelty の中心ではない。

位置づけ:

- 高認知負荷レビューで見落とし候補を並列化する mechanism
- 単独 reviewer の premature closure を崩す mechanism

`judgment` は、
その結果として増えた候補を整理し、
過剰修正を抑制する mechanism である。

### 3.3 paper appeal

訴求点は次の 3 層で組み立てる。

1. human cognitive load support
2. governed spec-driven workflow
3. evidence-preserving downstream support

---

## 4. Current Evidence Status

### 4.1 Already available

- `dual-reviewer v1` completion
- implementation governance formalization
- manual implementation conformance review
- finding fix + rerun evidence
- phase metrics baseline
- intent review baseline

これらは main evaluation ではなく、
`system construction validity` と `evaluation readiness` を支える evidence として使う。

### 4.2 Not yet acquired

- Intent Track (`intent-only`) の追加 run
- Spec Track (`spec-present`) の cross-case comparison
- Implementation Track (`implementation/review`) の new Ruby-based review run
- downstream rework data across cases
- disagreement preservation metrics across tracks

---

## 5. Main Evaluation Tracks

### Intent Track

- `intent` から `requirements/design/tasks` を起こすケース
- 主観測:
  - requirement coverage
  - handback depth
  - alignment / reopen control

### Spec Track

- 既存 `requirements/design/tasks` を持つケース
- 主観測:
  - downstream refinement
  - recheck / reopen
  - process/evidence stability

### Implementation Track

- implementation artifact を持つケース
- 主観測:
  - conformance review
  - caveat retention
  - disagreement preservation
  - downstream rework traceability

---

## 6. Claims for the Next Paper

### Claim 1

`dual-reviewer` は、仕様駆動開発の下流工程における cognitive brittleness を減らす。

### Claim 2

`dual-reviewer` は、finding だけでなく disagreement, caveat, disposition, handback depth を traceable に残す。

### Claim 3

`dual-reviewer` は、`intent-only`, `spec-present`, `implementation-present` の複数開始条件でも workflow を維持できる。

### Claim 4

`dual-reviewer` は、review 後の evidence を self-improvement / reporting に再利用可能な形で残す。

---

## 7. Metrics Plan

### 7.1 phase-oriented

- blocking issue count
- nonblocking open point count
- minor adjustment count
- major correction count
- intent-attributed issue count

### 7.2 process-oriented

- handback class distribution
- reopen required count
- conformance finding count
- severity-weighted conformance score

### 7.3 evidence-oriented

- review artifact presence rate
- finding-to-signal link rate
- caveat retention rate
- evidence trace completeness
- disagreement preservation rate

### 7.4 downstream-oriented

- downstream rework event count
- review-to-fix traceability rate
- unresolved finding count

---

## 8. Threats to Validity

現時点で見えている主な threat は次である。

- Intent Track / Spec Track / Implementation Track の case 数がまだ少ない
- implementation-phase case が scientific / embedded 側に寄っている
- manual reference は補助比較に留まる
- ground truth を absolute oracle としない
- model drift の影響がある

---

## 9. Immediate Next Work

1. case manifest を正本化する
2. Intent Track / Spec Track / Implementation Track の acquisition protocol を分離する
3. Implementation Track pilot run を small batch で開始する
4. Intent Track / Spec Track 側の first-run も別途定義する

---

## 10. Readiness Summary

| area | status | note |
|------|--------|------|
| system construction validity | `ready` | v1 completion and governance evidence available |
| track framing | `ready` | intent-origin framing restored |
| implementation-phase setup | `partially ready` | phase-field first snapshot fixed, run data not yet acquired |
| main paper evidence | `not yet ready` | new Ruby-based multi-track batch pending |

現時点では、
「論文の主張構成は整ったが、main evaluation data はこれから取得する」
という状態である。
