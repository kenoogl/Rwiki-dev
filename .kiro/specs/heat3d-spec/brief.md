# Brief: heat3d-spec

> 出典: [intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1), [thermal_simulator_spec.md](/Users/Daily/Development/DR-heat3d/spec_seed/thermal_simulator_spec.md:1)

## Problem

`heat3d` を `cc-sdd` 的に進めるには、いきなり単一 feature の `requirements/design/tasks` に入るのではなく、どこで feature を分けるかを先に決める必要がある。単一 `heat3d-spec` のままでは、feature 間調整 gate や依存順を検証できず、`cc-sdd` workflow の代表試行にならない。

## Current State

- intent は固定済み
- system-level の [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/requirements.md:1) 初稿はある
- ただしこの draft は feature decomposition 前提が欠けており、gate 候補としては保留
- canonical source は 1 本だが、内容は少なくとも grid/material/boundary/solver/case/main の責務に分かれている

## Desired Outcome

- `heat3d` を複数 feature の依存構造として読める状態にする
- 各 feature ごとに requirements wave を起こせる境界を決める
- `cc-sdd` の alignment gate が意味を持つ粒度に落とす
- visualization は scope 内に入れるか、明示的に defer するかを boundary として固定する

## Approach

まず discovery artifact を起こし、`heat3d` を feature 候補へ分解する。現時点の第一案は次の 5 区分である。

1. `heat3d-foundation`
2. `heat3d-linear-solver`
3. `heat3d-case-model`
4. `heat3d-main`
5. `heat3d-visualization`

このうち `visualization` は user 提案で boundary candidate として明示するが、intent と canonical source の non-goal に従い current MVP では defer 候補として扱う。

## Scope

- **In**:
  - feature decomposition
  - feature dependency の固定
  - `requirements.md` を gate 候補から decomposition input へ格下げする判断
  - feature ごとの requirements wave を起こす前提整理
- **Out**:
  - `cc-sdd` ツール導入そのもの
  - 外部 `kiro-discovery` command 実行
  - feature ごとの design/tasks 起草
  - implementation 着手

## Boundary Candidates

- `foundation` と `linear-solver` の境界
- `foundation` と `case-model` の境界
- `case-model` と `main` の境界
- `main` と `visualization` の境界

## Out of Boundary

- GUI
- CSV 出力
- 複数ケース一括実行
- 並列化
- GPU

## Upstream / Downstream

- **Upstream**: canonical source, intent
- **Downstream**: feature-level requirements wave, design wave, tasks wave

## Existing Spec Touchpoints

- **Extends**: なし
- **Adjacent**: current [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/requirements.md:1) は decomposition input として参照する

## Constraints

- clean-room 制約により元 Julia 実装は参照しない
- current repo では `/kiro-discovery` command は直接使わず、文書運用で代替する
- feature decomposition は [phase-and-feature-dependency-map.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/phase-and-feature-dependency-map.md:1) の考え方に合わせる

## Coordination 必要事項

- `visualization` を active feature に含めるか、deferred boundary に置くかを明示する
- feature 名を `heat3d-*` で個別 spec 化するか、`heat3d-spec` 配下の sub-feature として運用するかを後続で決める
