# Research & Design Decisions

## Summary

- **Feature**: `heat3d-spec`
- **Discovery Scope**: Complex Integration (= single canonical source から multi-feature decomposition を再構成し、cc-sdd の gate/alignment が意味を持つ粒度へ落とす)
- **Key Findings**:
  1. `heat3d` を単一 feature として進めると、feature 間調整 gate を検証できず、cc-sdd workflow trial として弱い
  2. canonical source は 1 本でも、責務は少なくとも `foundation / linear-solver / case-model / main` に分離できる
  3. `visualization` は user が boundary candidate として明示したが、intent と canonical source の non-goal により current MVP では defer 候補である

## Research Log

### Topic: なぜ single-feature 開始が不適切か

- **Context**: `heat3d` trial を single `heat3d-spec` として requirements gate に進めようとしたが、user から feature decomposition の不足を指摘された
- **Sources Consulted**:
  - [intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1)
  - [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/requirements.md:1)
  - [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:211)
  - [phase-and-feature-dependency-map.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/phase-and-feature-dependency-map.md:1)
- **Findings**:
  - current `requirements.md` は system-level contract としては読めるが、feature 間依存や alignment gate の entry point を持たない
  - cc-sdd 正本では multi-feature alignment gate が標準手順であり、単一 feature のままだとそこを実運用で検証できない
  - したがって current requirements draft は gate 候補ではなく decomposition input として扱うのが妥当
- **Implications**:
  - `requirements gate` は保留
  - discovery artifact を先に作る
  - feature decomposition 後に requirements wave をやり直す

### Topic: canonical source から読める責務分離

- **Context**: `thermal_simulator_spec.md` が 1 本でも、どこで feature を切るべきかを判断する必要がある
- **Sources Consulted**:
  - [thermal_simulator_spec.md](/Users/Daily/Development/DR-heat3d/spec_seed/thermal_simulator_spec.md:1)
- **Findings**:
  - `types/grid/materials/geometry/boundary` は shared contract として複数下流に供給される
  - `solver.jl` は独立した numerical kernel であり、`grid`, `mask`, `boundary-derived coefficients`, `rhs` などの明示入力 contract を持つ
  - `case_model.jl` は fixed MVP case を構築し、grid/material/geometry/heating/boundary を束ねる orchestration feature と読める
  - `main.jl` は case construction、solve 実行、logging を担う entrypoint feature と読める
  - canonical source は visualization を non-target とするため、current MVP の active feature ではなく deferred boundary と読むのが自然
- **Implications**:
  - active feature 第一案 = `foundation`, `linear-solver`, `case-model`, `main`
  - `visualization` は deferred candidate として明示し、active wave には入れない

### Topic: phase-and-feature-dependency-map への写像

- **Context**: `/kiro-discovery` command を使わず、この repo の文書運用へ写像する必要がある
- **Sources Consulted**:
  - [phase-and-feature-dependency-map.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/phase-and-feature-dependency-map.md:1)
  - [cc-sdd README](https://github.com/gotalab/cc-sdd)
  - [Codex AGENTS template](https://raw.githubusercontent.com/gotalab/cc-sdd/main/tools/cc-sdd/templates/agents/codex/docs/AGENTS.md)
- **Findings**:
  - current repo では `/kiro-discovery` 相当の役割を dependency map と spec-local research artifact が担っている
  - 本家 cc-sdd は discovery を entry point とし、必要なら multiple specs への decomposition を行う
  - したがって今回必要なのは command 実行ではなく、same intent を local artifact に落とすこと
- **Implications**:
  - `brief.md` + `research.md` を discovery output として扱う
  - 後続で feature-level spec へ split するなら、この research を上流判断根拠にする

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Single feature `heat3d-spec` | 全責務を 1 spec に保持 | 文書数が少ない | cc-sdd alignment gate が意味を失う | 却下 |
| 4 active features + 1 deferred boundary | `foundation / linear-solver / case-model / main` を active、`visualization` を deferred | 責務分離と MVP scope が両立 | feature 数増で wave 運用が必要 | 採用候補 |
| Full micro-feature split | `grid/materials/geometry/boundary/solver/main/...` を全て独立 spec 化 | granularity が高い | 初回 trial としては過剰分割 | 現時点では採用しない |

## Design Decisions

### Decision: current requirements draft は decomposition input として扱う

- **Context**: [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/requirements.md:1) は feature decomposition 前に起草されている
- **Alternatives Considered**:
  1. そのまま `requirements gate` に進める
  2. decomposition input として保留し、feature 分解後に requirements wave をやり直す
- **Selected Approach**: 2
- **Rationale**: `cc-sdd` の feature-aware workflow を検証するには、feature 分解が先行条件
- **Trade-offs**: 初稿の一部を書き直すコストが発生する
- **Follow-up**: feature 名確定後に requirements を再配分する

### Decision: active feature 第一案 = foundation / linear-solver / case-model / main

- **Context**: canonical source の責務を active feature に落とす必要がある
- **Alternatives Considered**:
  1. single feature のまま進める
  2. 4 active features に分ける
  3. さらに `grid/materials/geometry/boundary` まで micro-feature 化する
- **Selected Approach**: 2
- **Rationale**:
  - `foundation` は shared contract owner
  - `linear-solver` は numerical kernel として独立 contract を持つ
  - `case-model` は fixed MVP case の構築責務を持つ
  - `main` は solve orchestration と logging を担う
- **Trade-offs**:
  - `foundation` がやや太い feature になる
  - ただし初回 discovery としては妥当な粗さ
- **Follow-up**: `foundation` 内に `grid/materials/geometry/boundary` を保持するか、後続で再分割するかは design wave で再検討

### Decision: visualization は deferred boundary candidate として保持する

- **Context**: user は `visualization` を最低 feature 候補として挙げた一方、intent と canonical source は visualization を non-goal / non-target に置いている
- **Alternatives Considered**:
  1. current MVP active feature に含める
  2. deferred boundary candidate として明示し、active wave には入れない
- **Selected Approach**: 2
- **Rationale**: current scope を壊さずに boundary を見える化できる
- **Trade-offs**: user が後で visualization を有効化する場合、別途 spec 化が必要
- **Follow-up**: `heat3d-visualization` を後続 optional spec として扱うなら、その activation 条件を別途定義する

## Proposed Feature Set

### `heat3d-foundation`

- shared types
- grid generation
- Z-grid and `ΔZ` rules
- material table
- geometry inclusion and material assignment primitives
- boundary-condition data structures and application helpers
- shared result/log contracts

### `heat3d-linear-solver`

- RHS construction
- interior coefficient construction
- boundary-derived coefficient incorporation
- matrix-vector application
- GS preconditioning
- PBiCGSTAB
- residual and convergence evaluation

### `heat3d-case-model`

- fixed MVP case assembly
- canonical geometry placement
- heating distribution
- boundary-condition set construction
- `z_range` derivation for the chosen boundary set

### `heat3d-main`

- case orchestration
- one-step execution
- solver invocation
- logging
- regression-baseline observation points

### `heat3d-visualization` (deferred candidate)

- current intent and canonical source では active scope 外
- 将来 scope 拡張時の boundary candidate としてのみ保持

## Proposed Dependency Order

1. `heat3d-foundation`
2. `heat3d-linear-solver`
3. `heat3d-case-model`
4. `heat3d-main`
5. `heat3d-visualization` (deferred)

dependency sketch:

- `foundation -> linear-solver`
- `foundation -> case-model`
- `linear-solver -> main`
- `case-model -> main`
- `main -> visualization` when visualization is activated later

## Risks & Mitigations

- Risk 1: `foundation` が太すぎて後で再分割が必要になる
  - Mitigation: design wave で `grid/materials/geometry/boundary` の再分割可否を再検討する
- Risk 2: current `requirements.md` を放置すると誤って gate 候補と読まれる
  - Mitigation: workflow trace と current action で decomposition input と明記する
- Risk 3: `visualization` を feature 候補に入れたことで scope 混乱が起きる
  - Mitigation: deferred candidate と明記し、active wave から除外する

## References

- [intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1)
- [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/requirements.md:1)
- [thermal_simulator_spec.md](/Users/Daily/Development/DR-heat3d/spec_seed/thermal_simulator_spec.md:1)
- [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:1)
- [phase-and-feature-dependency-map.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/phase-and-feature-dependency-map.md:1)
- [cc-sdd README](https://github.com/gotalab/cc-sdd)
