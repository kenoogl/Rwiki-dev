# implementation conformance review

## 1. review scope

- review type: `implementation conformance review`
- reviewed branch: `claude/v2-acquisition-code-mod`
- reviewed commit: `129d1ffde9f0c6c66567fad0e173c4dd94e5928a`
- reviewed features: `dual-reviewer-foundation`（基盤のみ。承認状態 = tasks-approved、spec.json `phase: tasks-approved`、3 phase approved=true）
- review focus: 承認済み requirements.md（Requirement 1〜7、Requirement 5 削除済み）・design.md（Shared Artifact Layout / Domain Model §1〜§10 / Test Strategy）・tasks.md（Task 1〜9、Task 5 欠番）が要求する成果物（artifact 配置／metadata 契約／schema／prompt 資産／provenance／validator contract）が、`runtime/` 配下および `scripts/validate_foundation_contracts.rb` の既存実装で実在・構造適合・静的動作するかの照合
- 評価原則: コード・既存仕様の書き換えは行わず、評価と本証跡作成のみ。手戻り種別は WORKFLOW_OVERVIEW 第 4 節（A=task-local / B=design handback / C=requirements handback / D=intent handback、迷えば上流寄せ）に従う

## 2. validation rerun

- rerun commands:
  - `find runtime -type f | sort`（配置実地調査）
  - 期待 prompt 正本パス存在チェック（design §Placement Decisions 項目 3 の 3 パス）
  - `ruby scripts/validate_foundation_contracts.rb`（design Test Strategy 準拠と称する既存検証）
  - `python3` による各 schema の `required` / `properties` 抽出（finding / necessity_judgment / impact_score / failure_observation / review_case）
  - `runtime/foundation/metadata_contract.yaml` の field・enum 突合
- result summary:
  - `runtime/foundation/layer1_framework.yaml` が **存在しない**（`runtime/foundation/` には `metadata_contract.yaml` のみ）
  - Step A/B の prompt 正本配置が design と不一致（実在 = `runtime/prompts/primary/`・`runtime/prompts/adversarial/`、期待 = `primary_detection/`・`adversarial_review/`）
  - `scripts/validate_foundation_contracts.rb` は `prompt_frontmatter_smoke_test!` で `ArgumentError: invalid byte sequence in US-ASCII`（外部 encoding 依存）により **完走せず失敗**。検証は最後まで通らない
  - 既存 validator は削除済み資産（`review_mode_vocab.yaml`、`runtime/patterns/*`）を前提とした旧仕様準拠であり、承認設計の Test Strategy（`layer1_framework.yaml` 必須 section 検証等）を実装していない
  - `metadata_contract.yaml` に `config_version` / `config_hash` が **欠落**、`validator_status` enum に `blocked` が **欠落**
  - schema 群の field 命名が承認設計（design §4）と不一致（詳細は Finding 6〜8）

## 3. findings

### Finding 1 `P1`

- title: `layer1_framework.yaml`（Layer 1 review state machine contract の正本）が未実装
- file: `runtime/foundation/`（あるべき `layer1_framework.yaml` が不在）
- references: Requirement 1 受入 1〜9・Requirement 2 受入 1、design §Domain Model §1・§Shared Artifact Layout・§Test Strategy「framework 整合」、tasks Task 2
- description: foundation の中核 contract である `layer1_framework.yaml`（top-level section `version`/`roles`/`step_pipeline`/`step_intents`/`required_metadata_refs`/`asset_locations`/`override_extension_point`）が repo 上に存在しない。Step A/B/C/D の canonical 名称・role abstraction・Step D 統合契約・override 拡張点が artifact として固定されていない
- impact: Requirement 1 全体（state machine contract）が未充足。downstream 4 spec が import 前提とする最上位 artifact が欠落し、Test Strategy「framework 整合」が原理的に pass しない。基盤の存在意義に直結
- recommended action: 承認済み design §1 に従い `runtime/foundation/layer1_framework.yaml` を新規作成（本レビューでは作成しない＝実装タスクへ差し戻し）
- handback assessment: `A`（task-local。Task 2 の未実施＝設計・要件は十分。実装で吸収可能）
- status: open / disposition = `fix-before-next-feature`

### Finding 2 `P1`

- title: Step A/B prompt 正本配置が承認設計のディレクトリ規約と不一致
- file: `runtime/prompts/primary/primary_reviewer.prompt.md`、`runtime/prompts/adversarial/adversarial_reviewer.prompt.md`（期待 = `runtime/prompts/primary_detection/`、`runtime/prompts/adversarial_review/`）
- references: Requirement 4 受入 1・4、design §Placement Decisions 項目 3「Step A=`primary_detection/primary_reviewer.prompt.md`、Step B=`adversarial_review/adversarial_reviewer.prompt.md`」、tasks Task 1・Task 6
- description: prompt は step 目的ディレクトリ配下に置く規約だが、実装は `primary/`・`adversarial/` という旧名ディレクトリに置かれている。Step C のみ `judgment/` で一致。さらに design §Shared Artifact Layout に存在しない `runtime/prompts/integration/integration_reviewer.prompt.md`・`runtime/prompts/shared/` が存在（Step D は prompt artifact を持たない規約に反する）
- impact: runtime が repo 相対パスのみで canonical 解決する前提（Requirement 4 受入 4）が崩れる。downstream の path 解決が承認設計どおりに動かない
- recommended action: prompt を `primary_detection/`・`adversarial_review/` へ再配置し、`integration/`・`shared/` の扱いを design に整合（実装タスクへ差し戻し）
- handback assessment: `A`（task-local。配置規約は design で確定済み、移動で吸収可能）
- status: open / disposition = `fix-before-next-feature`

### Finding 3 `P1`

- title: foundation 検証スクリプトが完走せず失敗（design Test Strategy 不成立）
- file: `scripts/validate_foundation_contracts.rb:29`
- references: design §Test Strategy・§Completion Criteria 第 1 項、tasks Task 9
- description: `parse_frontmatter` の正規表現 match が US-ASCII 外部 encoding 下で `ArgumentError: invalid byte sequence in US-ASCII` を送出し、`prompt_frontmatter_smoke_test!` で異常終了。`puts "foundation contract validation passed"` に到達しない。さらにこの script は `layer1_framework.yaml` 必須 section 検証・metadata enum 全数検証など design Test Strategy 5 項目を実装しておらず、旧仕様（`review_mode_vocab.yaml` 必須）に準拠
- impact: 「機械検証で完了判定する」という design Completion Criteria が満たせない。foundation の完了主張に対する fresh evidence が存在しない
- recommended action: encoding 固定（`File.read(path, encoding: "UTF-8")` 等）と、design Test Strategy 5 項目（schema / framework / metadata / prompt / template 整合）への全面書き換え（実装タスクへ差し戻し）
- handback assessment: `A`（task-local。検証実装の不足。設計の Test Strategy は明確）
- status: open / disposition = `fix-before-next-feature`

### Finding 4 `P1`

- title: 削除済み Requirement 5 資産（`runtime/patterns/*`）と `review_mode_vocab.yaml` が残存し、検証もそれを前提化
- file: `runtime/patterns/seed_patterns.yaml`、`runtime/patterns/fatal_patterns.yaml`、`runtime/validators/contracts/review_mode_vocab.yaml`、`scripts/validate_foundation_contracts.rb`（`review_mode_consistency_smoke_test!`）
- references: requirements Requirement 5「削除済み」、design §7「削除済み」、tasks Task 1（`runtime/patterns/` を作らない）・Task 8（`review_mode_vocab.yaml` は作らない、review-mode 語彙は `metadata_contract.yaml` 所有）・§4 Downstream Handoff「`runtime/patterns/*` および `review_mode_vocab.yaml` は提供しない」
- description: 承認仕様で明示的に責務外・非提供とされた pattern 資産と `review_mode_vocab.yaml` が実在し、かつ既存 validator がそれらを必須前提として検証している。実装が旧仕様ベースである直接証拠
- impact: downstream が削除済み資産に依存しうる。承認仕様の trust boundary（repo-contained / v2 は実 LLM 呼び出し）と矛盾し、契約面が旧構造のまま固定されている
- recommended action: 削除済み資産の除去と validator の `metadata_contract.yaml` 所有語彙への一本化（実装タスクへ差し戻し）
- handback assessment: `A`（task-local。仕様は削除確定済み、実装の追従漏れ）
- status: open / disposition = `fix-before-next-feature`

### Finding 5 `P1`

- title: `metadata_contract.yaml` に必須 field `config_version` / `config_hash` が欠落、`validator_status` enum に `blocked` が欠落
- file: `runtime/foundation/metadata_contract.yaml`
- references: Requirement 6 受入 2・10、Requirement 7 受入 3、Requirement 2 受入 4、design §Domain Model §3（field 一覧に `config_version`/`config_hash`、`validator_status` enum = `not_run`/`passed`/`failed`/`blocked`）、tasks Task 3
- description: design §3 必須 field 一覧と承認 enum に対し、実装の `required_fields` は `config_version`・`config_hash` を持たず、`validator_status` enum は `not_run`/`passed`/`failed` のみで `blocked` を欠く。`blocked`（前提未充足で実行不能）は requirements 再開（spec.json alignment.requirements note: 2026-05-17 要件 6 受入 10 追加）で確定した canonical 語彙
- impact: config↔run の機械追跡（Requirement 7 受入 3）・config が hidden state でない担保（Requirement 2 受入 4）が成立しない。foundation が canonical source として所有すべき validator-status 語彙が不完全で、downstream runtime/evaluation が誤った語彙を参照する
- recommended action: design §3 どおり 2 field 追加と `blocked` enum 追加（実装タスクへ差し戻し）
- handback assessment: `A`（task-local。design・requirements は確定済み、実装が再開後の最新仕様に未追従）
- status: open / disposition = `fix-before-next-feature`

### Finding 6 `P2`

- title: `finding` schema が承認設計の field 集合と不一致（`adversarial_outcome` 欠落、設計外 field 混在）
- file: `runtime/schemas/finding.schema.json`
- references: Requirement 3 受入 5、Requirement 1 受入 4、design §Domain Model §4 finding（mandatory-B1.0 = `finding_id`/`step_id`/`source_role`/`severity`/`summary`/`source_refs`/`counter_evidence_refs`/`judgment_ref`/`decision_unit_id`/`human_decision_ref`/`adversarial_outcome`）、tasks Task 4
- description: 実装 required は design 列挙に対し `adversarial_outcome` を持たず、代わりに `schema_version`/`run_id`/`validation_refs` を required 化、`impact_score_ref`/`failure_observation_refs` を追加。Requirement 1 受入 4 が要求する「反証の意図的不在の記録」を担う `adversarial_outcome`（語彙 `counter_evidence_raised`/`no_counter_evidence_after_challenge`/`not_assessed`）が欠落
- impact: Step B forced-divergence の意図的結果記録（要件 1 受入 4）が schema 上で表現できない。空 `counter_evidence_refs` と「意図的不在」が区別不能。downstream self-improvement/evaluation の前提が崩れる
- recommended action: design §4 finding に合わせ `adversarial_outcome` を mandatory-B1.0 として追加、設計外 field の mandatory/deferred 区分を design に整合（実装タスクへ差し戻し）
- handback assessment: `A`（task-local。design に field 確定済み）
- status: open / disposition = `fix-before-next-feature`

### Finding 7 `P2`

- title: `impact_score` / `failure_observation` schema が承認設計の mandatory-B1.0 field 命名と不一致
- file: `runtime/schemas/impact_score.schema.json`、`runtime/schemas/failure_observation.schema.json`
- references: Requirement 3 受入 7・8、design §Domain Model §4 impact_score（`finding_ref`/`severity_axis`/`fix_cost_axis`/`downstream_scope_axis`）・failure_observation（`observation_id`/`run_ref`/`related_finding_ref`/`failure_type`/`missed_by_role`/`detected_at_step`）、tasks Task 4
- description: `impact_score` 実装は `impact_score_id`/`finding_id`/`scale`/`overall_score`/`dimensions`/`rationale` で、design が固定する 3 軸命名（`severity_axis`/`fix_cost_axis`/`downstream_scope_axis`）を持たない。`failure_observation` 実装は `failure_observation_id`/`related_finding_id`/`failure_mode`/`detected_by`/`recorded_at` で、design 命名（`observation_id`/`run_ref`/`related_finding_ref`/`failure_type`/`missed_by_role`/`detected_at_step`）と不一致。`missed_by_role`（見落とした role）相当が欠落
- impact: downstream evaluation/self-improvement が design 命名で import する前提と齟齬。cross-run research metrics（要件 3 受入 8）に必要な最小分類項目が承認形状でない
- recommended action: design §4 の mandatory-B1.0 命名へ整合、各 field に mandatory-B1.0/deferred 区分を付与（実装タスクへ差し戻し）
- handback assessment: `A`（task-local。design 命名確定済み）
- status: open / disposition = `fix-before-next-feature`

### Finding 8 `P2`

- title: `review_case` schema に step-level replay identity / `adversarial_outcome` 連動が設計どおり表現されているか追跡不能、mandatory/deferred 区分の欠如
- file: `runtime/schemas/review_case.schema.json`、`runtime/schemas/necessity_judgment.schema.json` 他 schema 群
- references: Requirement 3 受入 4・9、design §Domain Model §4・§5（step-level replay identity = `step_id`/`step_name`/`step_status`/`step_prompt_artifact_id`/`step_started_at`/`step_closed_at`）、tasks Task 4
- description: `review_case` の required は `schema_version`/`review_case_id`/`metadata`/`step_records`/`findings`/`validation_artifacts` で top-level 形状は近いが、§5 の step-level replay identity 6 項目が `step_records` 内で参照可能かを schema 定義から機械確認できない（properties 未展開）。全 schema が Requirement 3 受入 9 の「項目ごとの mandatory-B1.0 / deferred 明示」を JSON Schema 上で表現していない（design §4 冒頭が要求）
- impact: self-improvement の step-level replay（design §5）契約が schema 面で保証されない。B-1.0 必須／先送り境界が機械検証できず、silent 非互換編集の検出（Requirement 3 受入 3）が弱い
- recommended action: §5 identity の schema 内明示と mandatory/deferred 区分の構造化（実装タスクへ差し戻し）
- handback assessment: `B`（design handback 候補。mandatory/deferred を JSON Schema 上でどう表現するかの境界が design に具体化されていない。保守的に上流寄せ）
- status: open / disposition = `reopen-design`（要否は設計レビューで判断）

### Finding 9 `P3`

- title: invalidation_marker schema に陳腐化伝播義務の contract 明記が無い
- file: `runtime/validators/contracts/invalidation_marker.schema.json`
- references: Requirement 6 受入 9、design §Domain Model §8 末尾（無効化標識付与は下流派生成果物への陳腐化伝播義務を伴う）、tasks Task 8
- description: invalidation_marker schema 内に staleness / propagation / downstream を示す記述・field・description が見当たらない。Requirement 6 受入 9 が求める「伝播義務の存在を contract として固定」が artifact 上で読めない
- impact: 無効化時の下流陳腐化義務が契約として追跡できず、evaluation/paper-interface が義務の存在を参照できない。traceability の弱化
- recommended action: schema description に伝播義務の存在を明記（具体手段は evaluation/paper-interface 委譲のまま）（実装タスクへ差し戻し）
- handback assessment: `A`（task-local。design §8 末尾に文言確定済み）
- status: open / disposition = `fix-in-current-branch`

## 4. metric snapshot

- `conformance_findings_count`: 9
- `severity_weighted_finding_score`: 22（重み P1=3 / P2=2 / P3=1、内訳 P1×5 + P2×3 + P3×1 = 15+6+1）
  - 注: 重み付け尺度は foundation で未確定（design §4 で deferred）のため暫定重みを明示
- `post_smoke_nonconformance_count`: 9（既存 smoke=`validate_foundation_contracts.rb` は完走自体せず[Finding 3]。完走しても旧仕様準拠のため非適合は検出されない。実質 smoke 通過後も残る非適合は全 9 件）
- `fixture_bound_resolution_count`: 1（既存 validator は `tests/fixtures/foundation/*.minimal.json` への required 突合に依存し、承認 schema 形状ではなく fixture 同梱 field に整合する構造）
- `heuristic_linkage_count`: 0（basename match 等の heuristic linkage は foundation 範囲では未検出）
- `review_artifact_presence_rate`: 1.0（本証跡 1 件を新規作成、`.kiro/specs/dual-reviewer-foundation/reviews/` 配下に保存）
- `finding_to_signal_link_rate`: 0.0（本レビューは評価専任のため signal register への起票・既存ファイル書き換えを行わず。連携は実装側対応時に別途必要）

## 5. disposition summary

- immediate disposition:
  - `fix-before-next-feature`: Finding 1〜7（P1×5、P2×2）。foundation は downstream 4 spec の blocking dependency（tasks §5）であり、これらが残ると runtime 以降の実装着手は contract 不整合の上に積み上がる
  - `reopen-design`: Finding 8（mandatory/deferred の JSON Schema 表現境界が design 未具体。設計レビューで要否判定）
  - `fix-in-current-branch`: Finding 9（contract 文言追記のみ）
- 総括（既存コードの現行仕様適合度）: **低い**。承認済み tasks-approved 仕様に対し、(1) 最上位 artifact `layer1_framework.yaml` が皆無、(2) prompt 配置が旧ディレクトリ名、(3) 削除済み Requirement 5 資産（`runtime/patterns/*`・`review_mode_vocab.yaml`）が残存し検証もそれを前提化、(4) metadata 必須 field 2 件と enum `blocked` が欠落、(5) schema 群の field 命名が design §4 と広範に不一致。既存実装は要件再開（2026-05-17 要件 6 受入 10、config 関連 field 追加）より前の旧仕様ベースであり、現行承認仕様には構造適合していない。さらに既存検証スクリプト自体が外部 encoding 依存で完走せず、completion を支える fresh evidence が存在しない
- evidence linkage: reviewed commit `129d1ffde9f0c6c66567fad0e173c4dd94e5928a` / branch `claude/v2-acquisition-code-mod`。spec.json `phase: tasks-approved`、alignment requirements note（2026-05-17 要件 6 受入 10 追加・要件人間再承認未実施）と実装の不整合が Finding 5 の根拠
- next action: 本証跡を foundation の implementation conformance 入力とし、Finding 1〜7・9 を実装タスク（Task 2/6/3/4/8/9）の再実施で解消、Finding 8 は設計レビューに付議。handback はすべて `A`（Finding 8 のみ保守的に `B`）であり要件・intent の再開は不要。実装着手・既存ファイル修正・signal register 起票は本レビュー範囲外（評価専任のため）
