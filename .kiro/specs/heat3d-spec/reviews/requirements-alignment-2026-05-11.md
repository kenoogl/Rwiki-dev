# 2026-05-11 heat3d requirements alignment gate

## 1. purpose

active feature 4 本の requirements wave 後に、shared contract、owner boundary、handoff input を横断確認し、design フェーズへ進める requirements package を固定する。

## 2. reviewed feature set

- [heat3d-foundation/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/requirements.md:1)
- [heat3d-linear-solver/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/requirements.md:1)
- [heat3d-case-model/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/requirements.md:1)
- [heat3d-main/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/requirements.md:1)

## 3. alignment result

### 3.1 Shared contract owner

- `heat3d-foundation` が `grid / Z / ΔZ / material table / primitive contract / boundary-condition contract / shared output class` の owner である
- 他 feature はこれらを消費し、再定義しない

### 3.2 Numerical kernel owner

- `heat3d-linear-solver` が `RHS / coefficient interpretation / GS / PBiCGSTAB / convergence` の owner である
- solver entry contract は `qvol` と `Δt` を含み、main からの handoff に必要な入力が閉じた

### 3.3 Canonical case owner

- `heat3d-case-model` が canonical `SimulationConfig` と fixed MVP geometry / heating / boundary set / active `z_range` の owner である
- `heat3d-main` は canonical config を再定義せず、consumer として扱う

### 3.4 Top-level integration owner

- `heat3d-main` が one-step execution, logging, result return, regression-baseline observation, MVP acceptance execution の owner である
- `foundation` の shared output class と `case-model` の canonical config を消費することで責務分離が維持される

## 4. open points

blocking 級の open point は残していない。

design フェーズで再確認すべき論点:

- `foundation` 内の `grid/materials/geometry/boundary` 再分割要否
- `SimulationConfig` と assembled case bundle の具体型
- residual history を `main` がどう受け取るかの interface detail

## 5. conclusion

requirements wave で修正した 2 件を反映した結果、active feature 4 本の owner boundary と handoff input は design へ進める水準で整合した。したがって `heat3d` は human `requirements gate` へ進める。
