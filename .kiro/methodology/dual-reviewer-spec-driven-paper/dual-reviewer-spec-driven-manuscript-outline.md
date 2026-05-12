# dual-reviewer 論文アウトライン — manuscript drafting outline

_作成: 2026-05-12_  
_status: draft v0.1_  
_role: 本文起草のための章・節・段落アウトライン正本_

---

## 1. この文書の役割

この文書は、現在の evidence basis に合わせて
main paper を **章・節・段落レベル** で書き下ろすための直接的な下書き骨格である。

狙いは次の 3 つである。

1. 各章で何を主張し、何を主張しないかを固定する
2. 各段落でどの case / artifact を使うかを先に決める
3. `F1 upstream`、`F1-phase-field-cpp-r2`、`F2 heat3d`、`F3 iot-arduino` の役割を混線させない

---

## 2. Case Tier

本文での case tier は次で固定する。

- main upstream line:
  - `F1-intent-dual-reviewer-rebuild`
  - `F1-phase-field-reverse-spec`
- main implementation comparison line:
  - `F1-phase-field-cpp-r2`
- bridge implementation line:
  - `F2-heat3d-julia`
- supporting line:
  - `F3-iot-arduino`

refs:

- [claim-case-matrix.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/claim-case-matrix.md:1)
- [cross-track-narrative-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/cross-track-narrative-note.md:1)

---

## 3. Chapter Outline

### Chapter 1. Introduction

#### 1.1 Problem setting

- paragraph 1:
  - LLM review の関心は code review quality に寄りやすい
  - しかし実務上の壊れやすさは、`intent -> requirements/design/tasks -> implementation` の降下過程で強く出る
- paragraph 2:
  - detail が増えるほど human review は認知的に brittle になる
  - disagreement, caveat, reopen obligation が脱落すると downstream が壊れる
- paragraph 3:
  - 本研究は code review assistant ではなく、意図駆動開発 workflow support system を対象にする

#### 1.2 Paper claim

- paragraph 1:
  - `dual-reviewer` は governed workflow, evidence preservation, multiple-entry viability を支える
- paragraph 2:
  - cognitive load support は設計意図として述べる
  - strong efficacy claim にはしない

#### 1.3 Contributions

- paragraph 1:
  - `Intent Track / Spec Track / Implementation Track` の 3 track framing
- paragraph 2:
  - handback / reopen / caveat / disposition を artifact として保持する workflow
- paragraph 3:
  - reporting / self-improvement に再利用できる evidence pipeline

primary refs:

- [dual-reviewer-spec-driven-preliminary-report.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-preliminary-report.md:1)

---

### Chapter 2. Related Work And Positioning

#### 2.1 LLM-based code review

- paragraph 1:
  - 既存研究は code review quality に寄りやすい
- paragraph 2:
  - しかし `intent -> requirements/design/tasks -> implementation` の流れ全体は扱わないことが多い

#### 2.2 Multi-agent and debate-style review

- paragraph 1:
  - 複数 reviewer や debate は candidate expansion に有効
- paragraph 2:
  - ただし handback, reopen, gate, downstream trace まで扱わないことが多い

#### 2.3 Requirements/spec-driven development support

- paragraph 1:
  - 要件・設計支援の研究は upstream quality を扱う
- paragraph 2:
  - しかし implementation/review phase まで同一 contract でつなぐ例は限られる

#### 2.4 Traceability and governance support

- paragraph 1:
  - traceability や provenance の研究はある
- paragraph 2:
  - 本研究はそれを review workflow と一体化して扱う

#### 2.5 Position of this paper

- paragraph 1:
  - code review assistant 論文ではない
- paragraph 2:
  - 意図駆動開発 workflow support と evidence-preserving review system の論文として位置づける

### Chapter 3. System Framing And Design Goal

#### 2.1 What dual-reviewer is

- paragraph 1:
  - multi-agent prompt の寄せ集めではない
  - workflow, governance, evidence system である
- paragraph 2:
  - adversarial review, judgment, gate, reopen, signal retention の位置づけ

#### 2.2 What the system is meant to support

- paragraph 1:
  - `intent-only`
  - `spec-present`
  - `implementation-present`
  の 3 開始条件
- paragraph 2:
  - phase ごとの review を止めるのではなく、次の human gate まで進める設計

#### 2.3 What the paper does not claim

- paragraph 1:
  - 全ドメイン一般化は主張しない
- paragraph 2:
  - correctness proof ではない
- paragraph 3:
  - human cognitive load reduction の有意差実証は本論文の中心ではない

primary refs:

- [dual-reviewer-v2-user-guide.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/guides/dual-reviewer-v2-user-guide.md:1)
- [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:1)

---

### Chapter 4. Workflow And Artifact Contract

#### 3.1 End-to-end workflow

- paragraph 1:
  - `intent -> requirements -> design -> tasks -> implementation -> review acquisition`
- paragraph 2:
  - feature-local review
  - phase review wave
  - alignment gate
  - human gate

#### 3.2 Governance and control artifacts

- paragraph 1:
  - `workflow-gate-status`
  - `ACTIVE_WORKLIST`
  - `ECL`
  の役割
- paragraph 2:
  - reopen / handback は意思決定そのものより traceability contract として重要

#### 3.3 Evidence-preserving outputs

- paragraph 1:
  - review artifact
  - decision units
  - caveat / invalidation / triage
- paragraph 2:
  - reporting, self-improvement, paper interface への接続

figures:

- workflow waterfall 図
- evidence flow 図

primary refs:

- [dual-reviewer-v2-user-guide.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/guides/dual-reviewer-v2-user-guide.md:1)
- [dual-reviewer-spec-driven-case-manifest.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-case-manifest.md:1)

---

### Chapter 5. Evaluation Design And Evidence Basis

#### 4.1 Claim set

- paragraph 1:
  - `Claim 1-4` を短く定義
- paragraph 2:
  - strong evidence line と supplementary wording を分ける

#### 4.2 Case classes

- paragraph 1:
  - `Intent-origin`
  - `Spec-origin`
  - `Implementation-origin`
- paragraph 2:
  - excluded case の条件

#### 4.3 Selection-driven analysis basis

- paragraph 1:
  - protocol-backed run set
  - selection manifest
  - coverage
- paragraph 2:
  - global analysis basis は selection manifest により切り替わる

#### 4.4 Tiering

- paragraph 1:
  - `F1 upstream` を main upstream line
- paragraph 2:
  - `F1-phase-field-cpp-r2` を main implementation comparison line
- paragraph 3:
  - `F2 heat3d` を bridge case
- paragraph 4:
  - `F3 iot-arduino` を supporting line

primary refs:

- [claim-case-matrix.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/claim-case-matrix.md:1)
- [analysis-run-set-selection-policy.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/analysis-run-set-selection-policy.md:1)

---

### Chapter 6. Main Longitudinal Case: F1

#### 5.1 Intent Track: F1-intent-dual-reviewer-rebuild

- paragraph 1:
  - intent-only 開始条件で bootstrap が回ること
- paragraph 2:
  - handback / propagation obligation が artifact に残ること

#### 5.2 Spec Track: F1-phase-field-reverse-spec

- paragraph 1:
  - requirements/design/tasks refinement が gate 付きで回ること
- paragraph 2:
  - reopen / alignment が残ること

#### 5.3 Implementation Track: F1-phase-field-cpp-r2

- paragraph 1:
  - original snapshot を fresh protocol root で reacquire したこと
- paragraph 2:
  - `single / dual / dual+judgment = 2 / 3 / 3`
- paragraph 3:
  - `dual` が `single` より `+1` finding
- paragraph 4:
  - `dual+judgment` は finding count を増やさず judgment-bearing trace を加える

#### 5.4 F1 as the main line

- paragraph 1:
  - `intent -> spec -> implementation` の 3 track が同系統 case で繋がること
- paragraph 2:
  - 論文の中心はここに置く

primary refs:

- [F1-selection-rollout-status-2026-05-12.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/F1-selection-rollout-status-2026-05-12.md:1)
- [F1-phase-field-cpp-r2-rollout-status-2026-05-12.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/F1-phase-field-cpp-r2-rollout-status-2026-05-12.md:1)
- [F1-phase-field-cpp-r2/comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F1-phase-field-cpp-r2/comparison_summary.json:1)

---

### Chapter 7. Bridge Case: F2 heat3d

#### 6.1 Why heat3d is not just another implementation case

- paragraph 1:
  - `Spec-origin / Implementation-origin` を同時に持つ
- paragraph 2:
  - long trace を 1 case に束ねている

#### 6.2 Workflow validity and implementation arrival

- paragraph 1:
  - restart / reopen / readability recheck を含むこと
- paragraph 2:
  - approved upstream artifact から clean-room implementation に到達したこと

#### 6.3 Underconstraint exposure

- paragraph 1:
  - reduced validation pass と reference mismatch の併存
- paragraph 2:
  - behavioral adequacy と spec/design underconstraint を分けて読む必要

#### 6.4 Reusability role

- paragraph 1:
  - reporting
  - self-improvement
  - future code-conformance line
 への接続

primary refs:

- [core-case-heat3d.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-heat3d.md:1)
- [heat3d-c3-evidence-bundle.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-c3-evidence-bundle.md:1)
- [heat3d-supplementary-behavioral-evidence-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-supplementary-behavioral-evidence-note.md:1)

---

### Chapter 8. Supporting Case: F3 iot-arduino

#### 7.1 Why it is included

- paragraph 1:
  - external `intent.md` / `仕様.md` から generalized case を起動したこと
- paragraph 2:
  - event-driven domain transfer を補うこと

#### 7.2 What happened in the case

- paragraph 1:
  - first feature split proposal was effectively rejected and recomposed
- paragraph 2:
  - review acquisition, first snapshot, second snapshot acquisition を通した

#### 7.3 What the case supports

- paragraph 1:
  - stable safety finding
- paragraph 2:
  - preserved caveat
- paragraph 3:
  - hardware-ready adequacy ではなく supporting evidence として読む

primary refs:

- [iot-arduino-case-decision.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-case-decision.md:1)
- [iot-arduino-c4-evidence-bundle.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-c4-evidence-bundle.md:1)

---

### Chapter 9. Cross-Track Discussion

#### 8.1 Claim 2: traceability

- paragraph 1:
  - finding 以外の evidence が残る
- paragraph 2:
  - handback / reopen / caveat / disposition の preservation

#### 8.2 Claim 3: multiple-entry viability

- paragraph 1:
  - `intent-only`
  - `spec-present`
  - `implementation-present`
  の 3 開始条件
- paragraph 2:
  - strong generalization ではなく existence proof として読む

#### 8.3 Claim 4: evidence reuse

- paragraph 1:
  - reporting / self-improvement への再利用
- paragraph 2:
  - implementation-local rework trace の再利用

#### 8.4 Claim 1: weak wording only

- paragraph 1:
  - review attention の構造化
  - support
  - mitigation
 という言い方に留める
- paragraph 2:
  - significant reduction, general quality improvement は言わない

primary refs:

- [cross-track-narrative-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/cross-track-narrative-note.md:1)
- [dual-reviewer-spec-driven-preliminary-report.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-preliminary-report.md:1)

---

### Chapter 10. Limitations And Future Work

#### 9.1 Current evidence boundary

- paragraph 1:
  - large-N ではない
- paragraph 2:
  - `Intent / Spec` は first-batch level

#### 9.2 Domain and adequacy boundary

- paragraph 1:
  - `iot-arduino` は hardware-ready ではない
- paragraph 2:
  - `heat3d` は behavioral adequacy と spec conformance を分けて読む

#### 9.3 Future work

- paragraph 1:
  - cross-track aggregation
- paragraph 2:
  - broader case coverage
- paragraph 3:
  - `v3` code-conformance line

---

### Chapter 11. Conclusion

#### 10.1 What was shown

- paragraph 1:
  - intent-driven workflow support
- paragraph 2:
  - evidence-preserving review
- paragraph 3:
  - multiple-entry viability

#### 10.2 What remains outside the claim boundary

- paragraph 1:
  - strong efficacy
  - universal quality improvement
  - correctness proof

---

## 4. Writing Order

本文起草の順番は次を推奨する。

1. Chapter 5
2. Chapter 6
3. Chapter 7
4. Chapter 8
5. Chapter 9
6. Chapter 1
7. Chapter 2
8. Chapter 3
9. Chapter 4
10. Chapter 10
11. Chapter 11

理由:

- 先に evidence basis と case tier を固定した方が prose drift を防ぎやすい
- Chapter 6-9 が本文の中核であり、ここを書けば introduction と conclusion は自然に決まる
