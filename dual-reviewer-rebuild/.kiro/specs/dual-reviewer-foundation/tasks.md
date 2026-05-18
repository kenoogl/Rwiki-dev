# Tasks

## 1. この文書の役割

この文書は `dual-reviewer-foundation` を implementation 可能な作業単位へ落とした task plan である。承認済み requirements.md（Requirement 1〜7、Requirement 5 は削除済み）と design.md から全面再導出した。

`foundation` は実行コードを持たず、downstream feature 全体が依存する shared contract を artifact と配置規約として固定する spec である。したがって本 task は次の順で artifact を作る。

- shared asset directory skeleton
- Layer 1 review contract（`layer1_framework.yaml`）
- run metadata contract（`metadata_contract.yaml`）
- shared schema set 5 file
- Step A/B/C prompt artifacts
- config / terminology template
- validator-facing contract 2 file
- fixture と機械検証

## 2. 実装順序

1. foundation 所有 directory skeleton を確定する
2. `layer1_framework.yaml` を作る
3. `metadata_contract.yaml` を作る
4. shared schema 5 file を作る
5. Step A/B/C prompt artifacts を作る
6. config / terminology template を作る
7. validator-facing contract 2 file を作る
8. fixture を置く
9. 機械検証（design Test Strategy 準拠）を用意する

理由（design「Impact on Downstream Specs」「Architecture」より）:

- runtime は metadata contract と schema set がないと artifact を emit できない
- evaluation は validator-facing metadata・evidence_class・invalidation contract がないと intake 条件を固定できない
- self-improvement は step-level replay identity と `failure_observation` schema に依存する
- paper-interface は foundation が所有する evidence_class 語彙を参照する

## 3. Tasks

### Task 1: foundation 所有 directory skeleton を確定する

根拠: design「Shared Artifact Layout」「Placement Decisions」。

作業:

- 次のディレクトリ／配置先を repo 上に skeleton として用意する。
  - `runtime/foundation/`
  - `runtime/schemas/`
  - `runtime/prompts/primary_detection/`
  - `runtime/prompts/adversarial_review/`
  - `runtime/prompts/judgment/`
  - `runtime/config/`
  - `runtime/validators/contracts/`
- `runtime/patterns/` および `runtime/prompts/shared/` は作らない（Requirement 5 削除済み、design §7・§Shared Artifact Layout に存在しないため）。

完了条件:

- design「Shared Artifact Layout」の配置先が repo 上に一意に解決できる（design Completion Criteria 第 2 項）
- downstream feature が参照すべき foundation 所有 directory が存在する

### Task 2: `layer1_framework.yaml` を作る

根拠: Requirement 1（受入 1〜9）、Requirement 2 受入 1、design「Domain Model §1 Layer 1 Review Contract」「§2 Role Abstraction」。

作業:

- `runtime/foundation/layer1_framework.yaml` に次の top-level section を定義する。
  - `version`
  - `roles`（`primary_reviewer` / `adversarial_reviewer` / `judgment_reviewer` の abstract 名のみ。vendor / model 名を入れない＝Requirement 2 受入 1・2）
  - `step_pipeline`（Step A=`primary_detection` / Step B=`adversarial_review` / Step C=`judgment` / Step D=`integration` の canonical 名称のみ）
  - `step_intents`（Step B forced-divergence と Step C necessity judgment を別 role・別 output intent として区別＝Requirement 1 受入 4。Step D は A/B/C 出力を追加 LLM 呼び出しなしに統合し run close で消費される統合 review record＝Requirement 1 受入 7）
  - `required_metadata_refs`（Requirement 1 受入 5 の最小 binding set への参照）
  - `asset_locations`
  - `override_extension_point`（拡張点の所在のみ。選択順序・優先規則・適用条件は定義しない＝design §1 / Boundary Clarification）
- phase/profile 値語彙と treatment 値語彙を **列挙しない**（Requirement 1 受入 8・9。所有は runtime）。
- retry / subagent dispatch / human interaction timing を定義しない（runtime 責務）。

完了条件:

- 必須 top-level section（`version` / `roles` / `step_pipeline` / `step_intents` / `required_metadata_refs` / `asset_locations`）が宣言されている（design Test Strategy「framework 整合」）
- Step A/B/C/D の canonical 名称と Step D の統合契約が contract として読める
- phase/profile・treatment の値列挙が含まれていない

### Task 3: `metadata_contract.yaml` を作る

根拠: Requirement 1 受入 5、Requirement 6（受入 1〜10）、Requirement 7 受入 3、Requirement 2 受入 4、design「Domain Model §3 Run Metadata Contract」「§9 Exploratory Handling」。

作業:

- `runtime/foundation/metadata_contract.yaml` に次の必須 field を定義する（design §3 の field 一覧）。
  - `run_id` / `target_id` / `target_artifact_hash` / `source_repository_id` / `source_revision` / `phase_profile` / `treatment` / `review_mode` / `protocol_version` / `runtime_version` / `schema_set_version` / `prompt_set_version` / `config_version` / `config_hash` / `run_status` / `validator_status` / `human_signoff_status` / `evidence_class` / `started_at` / `closed_at`
- 各 field の purpose、required / optional、enum を明文化する。
- `run_status` と `evidence_class` の責務を分離する（design Decision 2／§3）。`run_status` / `validator_status` / `human_signoff_status` / `evidence_class` の 4 状態を混同しない宣言を含める。
- enum を次の通り固定する。
  - `run_status`: `created` / `in_progress` / `closed` / `orchestration_failed`
  - `validator_status`: `not_run` / `passed` / `failed` / `blocked`（foundation が所有する canonical validator-status 語彙＝Requirement 6 受入 10。「実行し pass」「実行し fail」「前提未充足で実行不能＝blocked」を最低限区別）
  - `human_signoff_status`: `pending` / `approved` / `rejected` / `deferred`
  - `evidence_class`: `candidate` / `valid` / `invalid` / `exploratory`（foundation が所有する canonical evidence-class 語彙＝Requirement 6 受入 8。downstream evaluation / paper-interface は再定義せず参照）
- `review_mode` の canonical 語彙が、最低限 `manual_dogfooding`（手動 dogfooding review）と `runtime_mediated`（runtime 媒介 review）を区別できることを明記する（Requirement 6 受入 6）。
- provenance field の役割分担（`source_repository_id` / `source_revision` / `target_id` / `target_artifact_hash`）を記述する（Requirement 6 受入 7、design §3）。
- 必須 metadata 欠落が validator failure を引き起こすこと（Requirement 6 受入 4）、metadata だけで invalid run を除外できること（Requirement 6 受入 5）を宣言する。
- phase/profile・treatment は field として持つが、値語彙は列挙しない（runtime 所有＝Requirement 1 受入 8・9。field 説明にその旨を記す）。

完了条件:

- design Test Strategy「metadata 整合」: §3 の必須 field 一覧と各 enum が宣言されている
- `validator_status`（`not_run`/`passed`/`failed`/`blocked`）と `evidence_class`（`candidate`/`valid`/`invalid`/`exploratory`）を foundation が canonical source として所有している
- `run_status=closed` かつ `validator_status=passed` でも `evidence_class=exploratory` が成立しうることが読める（design §9）

### Task 4: shared schema 5 file を作る

根拠: Requirement 3（受入 1〜10）、Requirement 1 受入 4、design「Domain Model §4 Shared Schema Relationships」「§5 Step-Level Replay Model」。

作業:

- `runtime/schemas/` 配下に次の 5 file を作る。
  - `review_case.schema.json`
  - `finding.schema.json`
  - `impact_score.schema.json`
  - `failure_observation.schema.json`
  - `necessity_judgment.schema.json`
- schema field label は英語で定義する（Requirement 3 受入 10）。
- 各 schema は項目ごとに mandatory-B1.0 か deferred かを明示する（Requirement 3 受入 9、design §4 冒頭）。
- `review_case`: run-level metadata、step record 境界、finding 群、validation / invalidation artifact への参照を表現する。derived metrics を持たない（design §4 review_case）。§5 の step-level replay identity（`step_id` / `step_name` / `step_status` / `step_prompt_artifact_id` / `step_started_at` / `step_closed_at`）を参照可能にする（Requirement 3 受入 4、design §5）。
- `finding`: mandatory-B1.0 field（`finding_id` / `step_id` / `source_role` / `severity` / `summary` / `source_refs` / `counter_evidence_refs` / `judgment_ref` / `decision_unit_id` / `human_decision_ref` / `adversarial_outcome`）を定義し、source attribution / severity / counter-evidence linkage / judgment linkage / human decision linkage を満たす（Requirement 3 受入 5）。`adversarial_outcome` の最小語彙を `counter_evidence_raised` / `no_counter_evidence_after_challenge` / `not_assessed` とし、反証の意図的不在を記録できるようにする（Requirement 1 受入 4、design §4 finding）。語彙拡張は deferred。
- `necessity_judgment`: 5-field structure（`requirement_link` / `ignored_impact` / `fix_cost` / `scope_expansion` / `uncertainty`）、final label、recommended action、optional override reason を固定する（Requirement 3 受入 6）。
- `impact_score`: `finding_ref` / `severity_axis` / `fix_cost_axis` / `downstream_scope_axis` を mandatory-B1.0 として固定する。値語彙・採点尺度・重み付けは deferred（evaluation 委譲、Requirement 3 受入 7、design §4 impact_score）。
- `failure_observation`: `observation_id` / `run_ref` / `related_finding_ref` / `failure_type` / `missed_by_role` / `detected_at_step` を mandatory-B1.0 として固定する。詳細分類体系・メトリクス導出は deferred（self-improvement / evaluation 委譲、Requirement 3 受入 8、design §4 failure_observation）。
- versioned artifact とし、silent な非互換編集を禁ずる旨を schema directory の規約として記す（Requirement 3 受入 3）。

完了条件:

- design Test Strategy「スキーマ整合」: 5 schema が有効な JSON Schema として meta-schema 検証を通る
- 各 field に mandatory-B1.0 / deferred の区分が付いている（Requirement 3 受入 9）
- field naming が design と一致し、downstream が schema import 前提を持てる

### Task 5: 削除済み（旧 Pattern and Terminology Assets）

旧 v1 はパターン定義ファイル（種パターン・重大パターン）を data source として配置していたが、v2 では実 LLM 呼び出しに置き換える方針のため Requirement 5 ごと削除された。terminology template の配置は Task 6 に統合する（design §7、§Shared Artifact Layout）。本 task 番号は欠番として維持する。

### Task 6: Step A/B/C prompt artifacts を作る

根拠: Requirement 4（受入 1〜5）、design「Domain Model §6 Prompt Artifact Model」「Placement Decisions 項目 3」「Interface Decision 1」。

作業:

- frontmatter 付き Markdown artifact として次の正本を作る。
  - Step A: `runtime/prompts/primary_detection/primary_reviewer.prompt.md`
  - Step B: `runtime/prompts/adversarial_review/adversarial_reviewer.prompt.md`
  - Step C: `runtime/prompts/judgment/judgment_reviewer.prompt.md`
- 各 frontmatter は少なくとも `prompt_id` / `version` / `role` / `step` / `language` / `source_ref` を持つ（design §6）。
- 本文は prompt body とし、runtime が frontmatter を parse して本文を LLM に渡せる形にする。
- Step D（integration）は追加 LLM 呼び出しを持たないため prompt artifact を置かない（Requirement 1 受入 7、design Placement Decisions 項目 3）。
- prompt 正本は repo 内 artifact とし、skill body には埋め込まない（Interface Decision 1）。runtime が repo 相対パスのみで解決できる配置にする（Requirement 4 受入 4）。

完了条件:

- design Test Strategy「prompt 整合」: Step A/B/C の正本配置にファイルが存在し、各 frontmatter が解析可能で必須 field を持つ
- prompt version traceability（run record → prompt artifact）が成立する前提が用意される（Requirement 4 受入 2・3・5）

### Task 7: config / terminology template を作る

根拠: Requirement 2（受入 3〜5）、Requirement 7（受入 1〜4）、design「Domain Model §10 Config and Template Model」。

作業:

- `runtime/config/config.yaml.template` に最小項目を表現する。
  - role ごとの model identifier
  - project language
  - protocol version
  - evidence output location
  - default phase/profile
- `runtime/config/terminology.yaml.template` を作る（空でも成立するが `version` と `entries` を持つ）。
- config を runtime input contract として定義し、hidden operator memory に依存しない旨を記す（Requirement 2 受入 4、Requirement 7 受入 2）。
- template を repo-contained file として置く（Requirement 2 受入 5、Requirement 7 受入 1・4）。

完了条件:

- design Test Strategy「template 整合」: `config.yaml.template` / `terminology.yaml.template` が YAML として解析できる
- config が runtime input であり repo 内 artifact が正本であることが読める

### Task 8: validator-facing contract 2 file を作る

根拠: Requirement 6（受入 3・9）、design「Domain Model §8 Validation and Invalidation Model」「Interface Decision 4」。

作業:

- `runtime/validators/contracts/validator_result.schema.json` を作る。少なくとも `run_id` / `validator_status` / `checked_contract` / `error_list` / `validated_by` / `validated_at` を持つ。`validator_status` は `metadata_contract.yaml` の語彙（`not_run` / `passed` / `failed` / `blocked`）と整合させる（design §8）。
- `runtime/validators/contracts/invalidation_marker.schema.json` を作る。少なくとも `run_id` / `reason_code` / `reason_detail` / `scope` / `issued_by` / `issued_at` を持つ。`scope` 初版語彙は `run` / `step` / `finding`（design §8）。
- raw evidence を書き換えず別 artifact として重ねる原則を schema 説明に記す（Requirement 6 受入 3、Interface Decision 4）。
- 無効化標識の付与が、その run を参照した下流派生成果物への陳腐化伝播義務を伴うことを contract として明記する。具体的な陳腐化フラグ付け／再導出手段は evaluation / paper-interface に委ねる旨も記す（Requirement 6 受入 9、design §8 末尾）。
- `review_mode_vocab.yaml` は作らない（review-mode 語彙は `metadata_contract.yaml` 所有。design §Shared Artifact Layout に存在しない）。

完了条件:

- 2 schema が有効な JSON Schema として meta-schema 検証を通る（design Test Strategy「スキーマ整合」に含む）
- validation と invalidation が raw evidence を汚さない artifact 分離として定義されている（design Completion Criteria 第 4 項）
- 陳腐化伝播義務の存在が contract として読める

### Task 9: foundation fixtures と機械検証を用意する

根拠: design「Test Strategy」「Completion Criteria」。foundation は実行コードを持たないため、検証は成果物の機械検証に限定する。

作業:

- 最小 fixture を `tests/fixtures/foundation/` などに置く。
  - minimal `review_case` example
  - minimal `finding` example
  - minimal `necessity_judgment` example
  - minimal `validator_result` example
  - minimal `invalidation_marker` example
- design Test Strategy の全項目を repo 内・外部依存なしで実行できる静的検証として用意する。
  - スキーマ整合: `runtime/schemas/*.schema.json` および `runtime/validators/contracts/*.schema.json` が JSON Schema meta-schema 検証を通る
  - framework 整合: `layer1_framework.yaml` が YAML 解析でき、必須 top-level section（`version` / `roles` / `step_pipeline` / `step_intents` / `required_metadata_refs` / `asset_locations`）が存在する
  - metadata 整合: `metadata_contract.yaml` が YAML 解析でき、§3 必須 field と各 enum が宣言されている
  - prompt 整合: Step A/B/C 正本配置にファイルが存在し、各 frontmatter が解析可能で必須 field を持つ
  - template 整合: `config.yaml.template` / `terminology.yaml.template` が YAML 解析できる

完了条件:

- design Test Strategy の全項目が pass する（design Completion Criteria 第 1 項）
- CI でも手動チェックでも同一基準で判定できる

## 4. Downstream Handoff

foundation tasks 完了後に、downstream feature が依存してよい artifact は次である（design「Impact on Downstream Specs」）。

- `runtime/foundation/layer1_framework.yaml`
- `runtime/foundation/metadata_contract.yaml`
- `runtime/schemas/*.schema.json`（5 file）
- `runtime/prompts/{primary_detection,adversarial_review,judgment}/*.prompt.md`
- `runtime/config/config.yaml.template`、`runtime/config/terminology.yaml.template`
- `runtime/validators/contracts/{validator_result,invalidation_marker}.schema.json`

`runtime/patterns/*` および `review_mode_vocab.yaml` は提供しない（Requirement 5 削除済み、design §7・§Shared Artifact Layout）。

## 5. Blocking Dependencies

`foundation` の tasks が終わるまで、次の downstream task は blocked とみなす（design「Impact on Downstream Specs」、phase-and-feature-dependency-map §5.3）。

- runtime の run manifest / `review_case` concrete storage task と portable bundle task
- evaluation の intake / admission artifact task
- self-improvement の proposal provenance / step-level replay task
- paper-interface の provenance-preserving bundle task

## 6. Completion Criteria

design「Completion Criteria」に従い、少なくとも次を満たすとき本 task plan は有効とみなす。判定は Task 9 の機械検証で行い、説明は補助とする。

- design Test Strategy の全項目が pass する
- foundation asset の配置先が design「Shared Artifact Layout」で一意に解決できる
- metadata field の責務分離（`run_status` / `validator_status` / `human_signoff_status` / `evidence_class`）が `metadata_contract.yaml` で宣言されている
- `validator_status`（`not_run`/`passed`/`failed`/`blocked`）と `evidence_class`（`candidate`/`valid`/`invalid`/`exploratory`）を foundation が canonical source として所有している
- invalidation と validation が raw evidence を汚さない artifact 分離として定義され、無効化標識の陳腐化伝播義務が contract 化されている
- downstream 4 spec が import する artifact が §4 Downstream Handoff で追跡できる
