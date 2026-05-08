# Tasks

## 1. この文書の役割

この文書は `dual-reviewer-foundation` を implementation 可能な作業単位へ落とした task plan である。

`foundation` は downstream feature 全体の shared contract を提供するため、ここでの task は

- directory skeleton
- metadata contract
- schema files
- prompt / pattern / terminology assets
- validator-facing contracts

の順で進める。

## 2. 実装順序

1. shared asset directory を確定する
2. metadata contract を作る
3. shared schema set を作る
4. prompt / pattern / terminology assets を置く
5. validator-facing contract を作る
6. fixture と最小 validation を用意する

理由:

- runtime は metadata と schema がないと artifact を emit できない
- evaluation は validator-facing metadata と invalidation contract がないと intake 条件を固定できない
- self-improvement と paper-interface は schema / field naming に依存する

## 3. Tasks

### Task 1: Create shared asset directory skeleton

目的:

- foundation owner の asset placement を repo 上に固定する

作業:

- `runtime/foundation/`
- `runtime/foundation/metadata_contract.yaml`
- `runtime/schemas/`
- `runtime/prompts/shared/`
- `runtime/prompts/judgment/`
- `runtime/patterns/`
- `runtime/config/`
- `runtime/validators/contracts/`

を skeleton として揃える。

完了条件:

- downstream feature が参照すべき foundation-owned directory が repo 上に存在する
- placement が design と矛盾しない

### Task 2: Implement `metadata_contract.yaml`

目的:

- shared run-level metadata field naming を concrete artifact にする

作業:

- `run_id`
- `target_id`
- `target_artifact_hash`
- `source_repository_id`
- `source_revision`
- `phase_profile`
- `treatment`
- `review_mode`
- `protocol_version`
- `runtime_version`
- `schema_set_version`
- `prompt_set_version`
- `run_status`
- `validator_status`
- `human_signoff_status`
- `evidence_class`
- `started_at`
- `closed_at`

の field 定義、enum、required / optional を明文化する。

完了条件:

- runtime / evaluation / self-improvement が同じ metadata 正本を参照できる
- cross-project provenance field naming が artifact として確定する

### Task 3: Create shared schema files

目的:

- foundation が owner である shared schema set を実ファイル化する

作業:

- `review_case.schema.json`
- `finding.schema.json`
- `impact_score.schema.json`
- `failure_observation.schema.json`
- `necessity_judgment.schema.json`

を `runtime/schemas/` 配下に作る。

特に `review_case` と `finding` では、

- metadata ref
- step refs
- decision unit linkage
- human decision linkage
- validation / invalidation refs

を表現する。

完了条件:

- 5 schema file が存在する
- field naming が design と一致する
- downstream feature が schema import 前提を持てる

### Task 4: Create shared prompt artifacts

目的:

- runtime が repo-contained artifact として prompt を解決できる土台を作る

作業:

- judgment prompt canonical artifact を作る
- shared prompt frontmatter contract を定める
- prompt identity field
  - `prompt_id`
  - `prompt_version`
  - `role`
  - `phase_scope`

を artifact 内に持たせる

完了条件:

- runtime が relative path で judgment prompt を解決できる
- prompt identity recording に必要な field が concrete になる

### Task 5: Create pattern and terminology assets

目的:

- pattern asset と terminology template を repo-contained data source にする

作業:

- `runtime/patterns/seed_patterns.yaml`
- `runtime/patterns/fatal_patterns.yaml`
- `runtime/config/terminology_template.yaml`

を作成する。

初版では empty / starter content でよいが、

- reusable seed pattern
- project-accumulated pattern
- terminology entries structure

の distinction は明示する。

完了条件:

- self-improvement と runtime が pattern assets の canonical placement を参照できる
- terminology template が empty でも schema-complete である

### Task 6: Create validator-facing contract artifacts

目的:

- validator と evaluation が同じ invalidation / metadata rule を読めるようにする

作業:

- `runtime/validators/contracts/invalidation_marker.schema.json`
- `runtime/validators/contracts/validator_result.schema.json`
- `runtime/validators/contracts/review_mode_vocab.yaml`

を作る。

含めるべきこと:

- invalidation marker shape
- validator result shape
- canonical review-mode vocabulary

完了条件:

- runtime close 後の validator integration に必要な contract が存在する
- evaluation が manual / runtime / imported evidence distinction を downstream 推定に頼らず読める

### Task 7: Add foundation fixtures and examples

目的:

- downstream feature が contract を試せる最小 fixture を持つ

作業:

- minimal `review_case` example
- minimal `finding` example
- minimal `validator_result` example
- minimal `invalidation_marker` example

を `tests/fixtures/foundation/` などに配置する。

完了条件:

- schema validation や downstream fixture reuse の起点ができる

### Task 8: Add foundation validation checks

目的:

- foundation assets 自体の整合を mechanical に確認できるようにする

作業:

- schema file が parse 可能であることを確認する test
- metadata contract required field の smoke test
- prompt artifact frontmatter の smoke test
- review-mode vocabulary と metadata contract の整合確認

を追加する。

完了条件:

- foundation task 完了時点で shared contract の最低限の mechanical validation が回る

## 4. Downstream Handoff

foundation tasks 完了後に、次の feature が依存してよい artifact は少なくとも次である。

- `runtime/foundation/metadata_contract.yaml`
- `runtime/schemas/*.schema.json`
- `runtime/prompts/judgment/*`
- `runtime/patterns/*`
- `runtime/config/terminology_template.yaml`
- `runtime/validators/contracts/*`

## 5. Blocking Dependencies

`foundation` の tasks が終わるまで、次の downstream task は blocked とみなす。

- runtime の `run_manifest.yaml` / `review_case.json` concrete task
- runtime の portable bundle manifest task
- evaluation の intake / admission artifact task
- self-improvement の proposal provenance task
- paper-interface の provenance-preserving bundle task

## 6. Completion Criteria

- foundation-owned directories が repo 上に存在する
- metadata contract が concrete artifact になっている
- shared schema set が作成されている
- prompt / pattern / terminology asset が repo-contained artifact として存在する
- validator-facing contract が存在する
- downstream feature が foundation artifact を参照する前提を持てる
