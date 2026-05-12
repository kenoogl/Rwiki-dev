# dual-reviewer spec-driven paper index

_作成: 2026-05-09_  
_status: active index v0.2_  
_scope: main paper 用 methodology 文書、および今回生成した `heat3d` / remaining-track artifact の入口_

---

## 1. この index の役割

この文書は、現在の main paper 作業で生成された文書と artifact の入口を
**漏れなく辿れるようにするための index** である。

この index では次を分けて扱う。

- methodology 正本
- `heat3d` case 固有の workflow / evidence 文書
- `heat3d` spec package
- fresh `Intent / Spec` batch と `heat3d` implementation batch の出力入口
- 外部 supporting template / workflow 文書

runtime 配下の deeply nested JSON をここで全部再列挙はしない。  
代わりに、**各 batch root の入口 file** と **その配下に何があるか**を注記する。

---

## 2. Start Here

最初に読む順は次でよい。

1. [dual-reviewer-spec-driven-preliminary-report.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-preliminary-report.md:1)  
   現時点の本文正本。`Claim 2 / 3 / 4` の canonical prose 。
2. [dual-reviewer-spec-driven-paper-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-paper-plan.md:1)  
   planning source / fallback source。
3. [dual-reviewer-spec-driven-case-manifest.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-case-manifest.md:1)  
   `Intent / Spec / Implementation` の case 配置。
4. [claim-case-matrix.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/claim-case-matrix.md:1)  
   `Claim` と case の対応表。
5. [ACTIVE_WORKLIST.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md:1)  
   current step と next step の制御板。
6. [heat3d-c3-evidence-bundle.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-c3-evidence-bundle.md:1)  
   `C-3 heat3d` の証拠束。
7. [remaining-track-first-batch-acquisition-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/remaining-track-first-batch-acquisition-summary.md:1)  
   fresh `Intent / Spec` batch の集約。

---

## 3. Methodology Core

### 3.1 Paper framing

- [dual-reviewer-spec-driven-preliminary-report.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-preliminary-report.md:1)  
  本文正本。claim prose、track framing、threats、解釈境界。
- [dual-reviewer-spec-driven-paper-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-paper-plan.md:1)  
  planning source。claim candidate と case allocation。
- [dual-reviewer-spec-driven-first-run-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-first-run-plan.md:1)  
  旧来の first-run planning 文書。現状は historical plan 参照用。
- [dual-reviewer-spec-driven-case-manifest.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-case-manifest.md:1)  
  paper で使う case manifest。
- [claim-case-matrix.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/claim-case-matrix.md:1)  
  claim と case の matrix。
- [claim-2-3-4-cross-case-synthesis.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/claim-2-3-4-cross-case-synthesis.md:1)  
  `dual-reviewer-rebuild / phase-field / heat3d` を束ねた claim 補助メモ。
- [cross-track-narrative-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/cross-track-narrative-note.md:1)  
  `Intent / Spec / Implementation` を 1 本の story に圧縮した補助メモ。
- [cross-track-metric-aggregation-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/cross-track-metric-aggregation-plan.md:1)  
  additional comparison / metric aggregation の planning 正本。
- [cross-track-metric-aggregation-first-package.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/cross-track-metric-aggregation-first-package.md:1)  
  track-level preservation と downstream rework の最小集計 package。

### 3.2 Control and redesign

- [ACTIVE_WORKLIST.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md:1)  
  current workflow step, blocker, exit condition。
- [execution-control-ledger.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/execution-control-ledger.md:1)  
  generic execution / control constraint ledger。
- [generic-execution-layer-v2-spec.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/generic-execution-layer-v2-spec.md:1)  
  redesign 上位仕様。
- [active-worklist-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/active-worklist-template.md:1)  
  case 初期化時に current control board を生成する最小 template。
- [case-workflow-overlay-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/case-workflow-overlay-template.md:1)  
  case 固有差分だけを書く workflow overlay template。
- [reference-free-case-bootstrap-guide.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/reference-free-case-bootstrap-guide.md:1)  
  既存 case を参照せずに新しい case を起こすための bootstrap guide。

---

## 4. Core Cases

### 4.1 Phase-field

- [core-case-phase-field.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-phase-field.md:1)  
  `phase-field` core case note。
- [phase-field-dual-treatment-observation.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/phase-field-dual-treatment-observation.md:1)  
  implementation track の既存観測メモ。
- [phase-field-implementation-phase-protocol.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/phase-field-implementation-phase-protocol.md:1)  
  `phase-field` implementation protocol。
- [phase-field-implementation-phase-first-snapshot.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/phase-field-implementation-phase-first-snapshot.md:1)  
  `phase-field-cpp` snapshot 固定。

### 4.2 heat3d

- [core-case-heat3d.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-heat3d.md:1)  
  `heat3d` fixed core case note。
- [heat3d-case-fixation-decision.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-case-fixation-decision.md:1)  
  fixed core case judgment。
- [heat3d-c3-evidence-bundle.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-c3-evidence-bundle.md:1)  
  `C-3 heat3d` の bundle。
- [heat3d-main-paper-observation-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-main-paper-observation-note.md:1)  
  `heat3d` の paper-facing short note。
- [heat3d-v3-evaluation-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-v3-evaluation-note.md:1)  
  `v3` code-conformance case としての保存判断。
- [heat3d-validation-boundary-decision.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-validation-boundary-decision.md:1)  
  `13.4` を supplementary behavioral evidence とする判断。
- [heat3d-phase-field-implementation-comparison-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-phase-field-implementation-comparison-note.md:1)  
  `phase-field` との implementation 比較。
- [heat3d-implementation-execution-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-implementation-execution-note.md:1)  
  actual coding phase の実行メモ。
- [heat3d-supplementary-behavioral-evidence-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-supplementary-behavioral-evidence-note.md:1)  
  canonical-scale 実行結果と behavior mismatch を supplementary evidence として固定。
- [heat3d-case-workflow-overlay.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-case-workflow-overlay.md:1)  
  `heat3d` を generic workflow に載せるための case 固有差分。

### 4.3 iot-arduino

- [core-case-iot-arduino.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-iot-arduino.md:1)  
  provisional case note。
- [iot-arduino-implementation-phase-protocol.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-protocol.md:1)  
  implementation protocol draft。
- [iot-arduino-c4-evidence-bundle.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-c4-evidence-bundle.md:1)  
  two-snapshot implementation evidence を束ねた paper evidence bundle。
- [iot-arduino-case-decision.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-case-decision.md:1)  
  supporting case として閉じる判断。
- [iot-arduino-implementation-phase-second-snapshot.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-second-snapshot.md:1)  
  second snapshot boundary note。
- [implementation-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/implementation-evidence-summary.md:1)  
  first/second acquisition comparison と implementation-local refinement 読み。

---

## 5. Track Documents

### 5.1 Intent Track

- [intent-track-first-case-dual-reviewer-rebuild.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/intent-track-first-case-dual-reviewer-rebuild.md:1)  
  `F1-intent-dual-reviewer-rebuild` case 定義。
- [intent-track-first-run-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/intent-track-first-run-plan.md:1)  
  first-run planning。
- [intent-track-run-template.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/intent-track-run-template.md:1)  
  run template。

### 5.2 Spec Track

- [spec-track-first-case-phase-field-reverse-spec.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/spec-track-first-case-phase-field-reverse-spec.md:1)  
  `F1-spec-phase-field-reverse-spec` case 定義。
- [spec-track-first-run-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/spec-track-first-run-plan.md:1)  
  first-run planning。
- [spec-track-run-template.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/spec-track-run-template.md:1)  
  run template。

### 5.3 Implementation Track

- [implementation-track-run-template.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/implementation-track-run-template.md:1)  
  implementation track template。
- [implementation-phase-protocol-template.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/implementation-phase-protocol-template.md:1)  
  target 固有 implementation protocol を起こす最小 template。
- [implementation-phase-snapshot-template.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/implementation-phase-snapshot-template.md:1)  
  implementation snapshot boundary を固定する最小 template。
- [heat3d-implementation-phase-protocol.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-implementation-phase-protocol.md:1)  
  `heat3d` implementation track protocol。
- [heat3d-julia-implementation-phase-first-snapshot.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-julia-implementation-phase-first-snapshot.md:1)  
  `heat3d-julia` snapshot。
- [heat3d-review-acquisition-preparation.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-review-acquisition-preparation.md:1)  
  review acquisition gate 前メモ。
- [iot-arduino-implementation-phase-protocol.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-protocol.md:1)  
  `iot-arduino` implementation track protocol。
- [iot-arduino-implementation-phase-first-snapshot.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-first-snapshot.md:1)  
  `iot-arduino` first snapshot。
- [iot-arduino-implementation-phase-second-snapshot.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-second-snapshot.md:1)  
  `iot-arduino` second snapshot。
- [implementation-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/implementation-evidence-summary.md:1)  
  `iot-arduino` implementation-local refinement と acquisition comparison。
- [heuristic_profiles/README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/heuristic_profiles/README.md:1)  
  `heuristic_profile` を minimal template から起こす方針。

---

## 6. heat3d Workflow and Remaining-Track Support

- [heat3d-case-workflow-overlay.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-case-workflow-overlay.md:1)  
  `heat3d` の current case overlay。
- [heat3d-gate-only-trial.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-gate-only-trial.md:1)  
  `heat3d` 試行時の historical trial record。
- [heat3d-workflow-path.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-workflow-path.md:1)  
  `heat3d` path trace。
- [remaining-track-acquisition-bridge-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/remaining-track-acquisition-bridge-note.md:1)  
  `Intent / Spec` acquisition の narrative bridge。
- [remaining-track-acquisition-execution-preparation.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/remaining-track-acquisition-execution-preparation.md:1)  
  fresh batch 実行準備。
- [remaining-track-first-batch-acquisition-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/remaining-track-first-batch-acquisition-summary.md:1)  
  fresh `Intent / Spec` batch 集約。

---

## 7. heat3d Spec Package

### 7.1 Umbrella spec

- [intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1)  
  canonical source 参照つき intent。
- [brief.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/brief.md:1)  
  discovery 後の brief。
- [research.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/research.md:1)  
  feature decomposition と dependency note。
- [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/requirements.md:1)  
  旧 single-feature draft。active gate artifact ではなく historical input として残す。
- [spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/spec.json:1)  
  umbrella state。

### 7.2 Phase review / gate artifacts

- [requirements-review-wave-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/requirements-review-wave-2026-05-11.md:1)  
  requirements wave。
- [requirements-alignment-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/requirements-alignment-2026-05-11.md:1)  
  requirements alignment。
- [requirements-readability-recheck-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/requirements-readability-recheck-2026-05-11.md:1)  
  readability recheck。
- [requirements-alignment-recheck-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/requirements-alignment-recheck-2026-05-11.md:1)  
  readability 後の alignment recheck。
- [requirements-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/requirements-evidence-summary.md:1)  
  requirements gate package summary。
- [design-review-wave-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/design-review-wave-2026-05-11.md:1)  
  design wave。
- [design-alignment-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/design-alignment-2026-05-11.md:1)  
  design alignment。
- [design-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/design-evidence-summary.md:1)  
  design gate package summary。
- [tasks-review-wave-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/tasks-review-wave-2026-05-11.md:1)  
  tasks wave。
- [tasks-alignment-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/tasks-alignment-2026-05-11.md:1)  
  tasks alignment。
- [tasks-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/tasks-evidence-summary.md:1)  
  tasks gate package summary。
- [review-acquisition-gate-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/review-acquisition-gate-summary.md:1)  
  review acquisition gate package。
- [review-acquisition-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/review-acquisition-summary.md:1)  
  review acquisition 結果 summary。
- [implementation-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/implementation-evidence-summary.md:1)  
  actual coding phase の evidence summary。

### 7.3 Active feature specs

#### `heat3d-foundation`

- [brief.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/brief.md:1)  
- [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/requirements.md:1)  
- [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/design.md:1)  
- [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/tasks.md:1)  
- [spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/spec.json:1)  
- [requirements-local-review-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/reviews/requirements-local-review-2026-05-11.md:1)  
- [design-local-review-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/reviews/design-local-review-2026-05-11.md:1)  
- [tasks-local-review-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/reviews/tasks-local-review-2026-05-11.md:1)  

#### `heat3d-linear-solver`

- [brief.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/brief.md:1)  
- [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/requirements.md:1)  
- [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/design.md:1)  
- [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/tasks.md:1)  
- [spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/spec.json:1)  
- [requirements-local-review-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/reviews/requirements-local-review-2026-05-11.md:1)  
- [design-local-review-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/reviews/design-local-review-2026-05-11.md:1)  
- [tasks-local-review-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/reviews/tasks-local-review-2026-05-11.md:1)  

#### `heat3d-case-model`

- [brief.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/brief.md:1)  
- [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/requirements.md:1)  
- [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/design.md:1)  
- [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/tasks.md:1)  
- [spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/spec.json:1)  
- [requirements-local-review-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/reviews/requirements-local-review-2026-05-11.md:1)  
- [design-local-review-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/reviews/design-local-review-2026-05-11.md:1)  
- [tasks-local-review-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/reviews/tasks-local-review-2026-05-11.md:1)  

#### `heat3d-main`

- [brief.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/brief.md:1)  
- [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/requirements.md:1)  
- [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/design.md:1)  
- [tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/tasks.md:1)  
- [spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/spec.json:1)  
- [requirements-local-review-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/reviews/requirements-local-review-2026-05-11.md:1)  
- [design-local-review-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/reviews/design-local-review-2026-05-11.md:1)  
- [tasks-local-review-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/reviews/tasks-local-review-2026-05-11.md:1)  

---

## 8. Batch Outputs

### 8.1 Intent Track fresh narrative batch

- [batch_manifest.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild-narrative/batch_manifest.yaml:1)  
  batch 構成。
- [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild-narrative/comparison_summary.json:1)  
  fresh `Intent Track` 集約。

注記:

- 配下に `protocol-runs/` があり、single / dual 各 run の `intent_review.md`, `intent_trace_note.yaml`, `phase_metric_snapshot.json`, `signal_linkage_note.yaml`, `run_manifest.yaml` を持つ。
- 配下に `runtime-runs/` があり、v2 artifact と validator result を持つ。

### 8.2 Spec Track fresh narrative batch

- [batch_manifest.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec-narrative/batch_manifest.yaml:1)  
  batch 構成。
- [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec-narrative/comparison_summary.json:1)  
  fresh `Spec Track` 集約。

注記:

- 配下に `protocol-runs/` があり、single / dual 各 run の `reviewed_phase_note.md`, `alignment_artifact.yaml`, `phase_metric_snapshot.json`, `signal_linkage_note.yaml`, `run_manifest.yaml` を持つ。
- 配下に `runtime-runs/` があり、v2 artifact と validator result を持つ。

### 8.3 heat3d implementation batch

- [batch_manifest.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F2-heat3d-julia/batch_manifest.yaml:1)  
  `F2-heat3d-julia` batch 構成。
- [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F2-heat3d-julia/comparison_summary.json:1)  
  `single / dual / dual+judgment` 集約。

注記:

- 配下に `exports/` があり、bundle 単位の frozen export を持つ。
- 配下に `protocol-runs/` と `runtime-runs/` があり、run 単位の review artifact と validation artifact を持つ。

---

## 9. Supporting External Files

### 9.1 Workflow and control

- [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:1)  
  procedure 正本。
- [phase-review-metric-register.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/phase-review-metric-register.md:1)  
  phase metric register。

### 9.2 Review templates

- [intent-review-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/intent-review-template.md:1)  
  intent review template。
- [implementation-conformance-review-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/implementation-conformance-review-template.md:1)  
  implementation conformance template。
- [phase-evidence-summary-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/phase-evidence-summary-template.md:1)  
  phase evidence summary template。
- [active-worklist-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/active-worklist-template.md:1)  
  current control board 生成用 template。
- [case-workflow-overlay-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/case-workflow-overlay-template.md:1)  
  case workflow overlay template。
- [review-acquisition-preparation-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/review-acquisition-preparation-template.md:1)  
  review acquisition preparation template。
- [review-acquisition-gate-summary-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/review-acquisition-gate-summary-template.md:1)  
  review acquisition gate summary template。

### 9.3 Protocol manifests / scripts

- [F1-intent-dual-reviewer-rebuild.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/case_manifests/F1-intent-dual-reviewer-rebuild.yaml:1)  
  `Intent Track` manifest。
- [F2-heat3d-julia.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/case_manifests/F2-heat3d-julia.yaml:1)  
  `heat3d` implementation manifest。
- [F2-heat3d-julia heuristic profile](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/heuristic_profiles/implementation/F2-heat3d-julia.yaml:1)  
  implementation heuristic profile。
- [run_dual_reviewer_rebuild_intent_narrative_batch.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/run_dual_reviewer_rebuild_intent_narrative_batch.rb:1)  
  fresh `Intent Track` batch runner。
- [run_phase_field_spec_narrative_batch.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/run_phase_field_spec_narrative_batch.rb:1)  
  fresh `Spec Track` batch runner。
- [run_heat3d_implementation_first_batch.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/run_heat3d_implementation_first_batch.rb:1)  
  `F2-heat3d-julia` implementation batch runner。

### 9.4 Rebuild logs

- [DR-rebuild-log-4.md](/Users/Daily/Development/Rwiki-dev/docs/DR-rebuild-log-4.md:1)  
  中途の rebuild / governance / workflow 調整ログ。
- [DR-rebuild-log-5.md](/Users/Daily/Development/Rwiki-dev/docs/DR-rebuild-log-5.md:1)  
  `heat3d` trial, remaining-track batch, report 同期を含む後続ログ。

---

## 10. Reading Order By Purpose

### main paper の現在本文を追う

1. [dual-reviewer-spec-driven-preliminary-report.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-preliminary-report.md:1)
2. [dual-reviewer-spec-driven-paper-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-paper-plan.md:1)
3. [claim-2-3-4-cross-case-synthesis.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/claim-2-3-4-cross-case-synthesis.md:1)

### `heat3d` の workflow と判断を追う

1. [heat3d-case-workflow-overlay.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-case-workflow-overlay.md:1)
2. [heat3d-workflow-path.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-workflow-path.md:1)
3. [heat3d-c3-evidence-bundle.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-c3-evidence-bundle.md:1)
4. [heat3d-main-paper-observation-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-main-paper-observation-note.md:1)
5. [heat3d-v3-evaluation-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-v3-evaluation-note.md:1)
6. [heat3d-supplementary-behavioral-evidence-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-supplementary-behavioral-evidence-note.md:1)
7. [heat3d-gate-only-trial.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-gate-only-trial.md:1)

### fresh `Intent / Spec` batch を追う

1. [remaining-track-acquisition-execution-preparation.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/remaining-track-acquisition-execution-preparation.md:1)
2. [remaining-track-first-batch-acquisition-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/remaining-track-first-batch-acquisition-summary.md:1)
3. [Intent Track comparison](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild-narrative/comparison_summary.json:1)
4. [Spec Track comparison](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec-narrative/comparison_summary.json:1)
5. [cross-track-metric-aggregation-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/cross-track-metric-aggregation-plan.md:1)
6. [cross-track-metric-aggregation-first-package.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/cross-track-metric-aggregation-first-package.md:1)

---

## 11. Current Status

2026-05-11 時点の状態は次である。

- `heat3d` は fixed core case
- `heat3d` は同時に `v3` code-conformance evaluation case
- `Intent Track / Spec Track` fresh first batch は取得済み
- `Claim 2 / 3 / 4` の canonical prose は [dual-reviewer-spec-driven-preliminary-report.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-preliminary-report.md:1)
- current control は [ACTIVE_WORKLIST.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md:1)
- 次段は first aggregation package の compressed reading を本文へ再利用

未完了なのは主に次である。

- additional case comparison
- disagreement preservation の track 横断集計
- first-batch boundary を越える比較設計

index omission rule:

- batch root 配下の deeply nested runtime JSON / export file は、入口 file と配下注記で代表させる
- methodology 主線と無関係な一般作業ファイルは、この index には入れない
