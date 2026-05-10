# generic execution layer v2 replacement outcome

## 1. この文書の役割

この文書は、`dual-reviewer-generic-execution-layer-v2` の implementation replacement 後に、

- `phase-field` pilot rerun がどこまで再取得できたか
- 何が既に v2 path へ移ったか
- 何がまだ reopen item として残っているか
- なぜまだ `main evidence` へ昇格しないか

を固定するための outcome note である。

この文書は feature 完了宣言ではない。
`first validation result` と `remaining reopen item register` を残し、
pilot reacquisition 完了までを閉じるための記録である。

## 2. Reacquired Outputs

### 2.1 Intent Track

- batch:
  [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild/comparison_summary.json:1)
- status:
  reacquired through runtime-mediated v2 path with legacy protocol artifacts preserved
- key observations:
  - `single_review` findings: `2`
  - `dual_reviewer_workflow` findings: `3`
  - dual run requires intent handback: `true`
  - `v2/` internal artifacts are emitted alongside legacy intent-track artifacts

### 2.2 Spec Track

- tasks batch:
  [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec/comparison_summary.json:1)
- requirements batch:
  [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-requirements-phase-field-reverse-spec/comparison_summary.json:1)
- design batch:
  [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-design-phase-field-reverse-spec/comparison_summary.json:1)
- status:
  reacquired through runtime-mediated v2 path with reviewed-phase protocol artifacts preserved
- key observations:
  - tasks case still records reopen requirement toward `design` / `tasks`
  - requirements case still records downstream approval gap and clean-room boundary pressure
  - design case still records boundary-density and validation-ownership concerns
  - `v2/` internal artifacts are emitted alongside reviewed-phase note / alignment artifact / metrics

### 2.3 Implementation Track

- batch:
  [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F1-phase-field-cpp/comparison_summary.json:1)
- status:
  reacquired through v2 runtime path
- key observations:
  - `single_review` findings: `2`
  - `dual_reviewer_workflow` findings: `3`
  - `dual_minus_single_findings`: `1`
  - adversarial role is preserved in dual run
  - `v2/review_artifact.json`, `v2/metric_snapshot.json`, `v2/trace_note.json`, `v2/signal_linkage_note.json` are emitted with compatibility projection

## 3. What Was Replaced

- case-specific input wiring was moved into case manifests for `intent`, `spec`, and `implementation`
- `runtime/execution_v2/` now owns:
  - common execution contract
  - track specialization
  - case manifest validation
  - rule-match analysis for profile-backed runtime findings
  - v2 review artifact writing
  - compatibility projection
- reusable seed pattern vocabulary now exists so heuristic profiles can point at named review concerns instead of embedding every match term inline
- `implementation` runs now emit taxonomy-based:
  - evidence observations
  - review issue candidates
  - reopen candidates
  - signal candidates
- `spec` and `intent` runs now emit `v2/` internal artifacts from runtime-mediated runs while preserving legacy human-facing artifacts

## 4. ECL Mandatory Removal Check

### 4.1 Completed or materially advanced

- `ECL-B1` / `ECL-B2`:
  batch wiring is now manifest-backed rather than script-local only
- `ECL-B3`:
  protocol defaults are demoted closer to sample/default behavior because protocol entrypoints can now take manifest refs explicitly
- `ECL-S2` / `ECL-I2`:
  case identity is no longer the only place where track inputs are sourced; manifest-backed input resolution is now available

### 4.2 Still open

- `ECL-R2` / `ECL-R3`:
  implementation heuristics are now profile-backed, use a shared rule-match analyzer, and increasingly reference named seed-pattern vocabulary instead of inline term lists, but they are still source-pattern heuristics rather than fully semantics-aware generic review logic

要するに、**binding と protocol-side case payload は外へ出て、`spec` / `intent` は runtime-mediated path へ移った。残る未解決は `implementation` 側の heuristic がまだ source-pattern ベースな点である**。

## 5. Remaining Reopen Item Register

1. `implementation` analyzer is still seeded by source-pattern runtime executor findings, even though target-specific predicate gating and executor-local heuristic payloads have been removed.
2. comparison summaries are reacquired, but the result is still pilot evidence rather than reusable main-evidence-grade acquisition.

## 6. Main-Evidence Status

`main evidence` へはまだ昇格しない。

理由:

- implementation 側はまだ source-pattern heuristic に依存している
- `spec` と `intent` は runtime-mediated path へ移ったが、human-facing protocol artifact はなお pilot projection であり、main-evidence-grade acquisition ではない
- `phase-field` rerun は成功したが、generic execution layer replacement の最終安定化までは未完了である

したがって現時点の位置づけは、

- `pilot reacquisition completed`
- `first validation result recorded`
- `main evidence promotion not allowed yet`

である。
