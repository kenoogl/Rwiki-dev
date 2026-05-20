# implementation conformance review

_実施日: 2026-05-20_
_レビュー種別: implementation conformance review（独立適合レビュー。実装者とは別プロセス・別視点）_
_対象 feature: dual-reviewer-foundation（基盤のスクラッチ再実装、postrebuild 段階）_
_reviewed commit: HEAD=`cea191b8`（基盤再実装は単一コミット `c4928ff3` で完結。`c4928ff3..HEAD` の foundation 配下追加変更は git log 上ゼロ。実体は `c4928ff3` の artefact をそのままレビュー対象とする）_
_review focus: 基盤のスクラッチ再実装（コミット `c4928ff3`）が承認済み foundation 仕様（requirements.md Requirement 1〜7、Requirement 5 削除済み／design.md Shared Artifact Layout・Domain Model §1〜§10・§4 mandatory/deferred 符号化規約・Test Strategy・Completion Criteria／tasks.md Task 1〜9、Task 5 欠番）へ構造適合し、前回 finding 9 件（P1=5/P2=3/P3=1、A8/B1）が解消したかを独立確認する_

本証跡は生証跡として不変扱いとする。本レビューにおいて実装ファイル・spec・design・requirements・tasks・基盤資産は一切変更していない（点検と所見記録のみ）。前回証跡（`implementation-conformance-review-2026-05-18.md`）と設計差し戻し証跡（`design-reopen-review-2026-05-18.md`）は鵜呑みにせず独立判断した。

## 1. review scope

- review type: `implementation conformance review`
- reviewed branch: `claude/v2-acquisition-code-mod`
- reviewed commit: 現在 HEAD `cea191b8`。基盤再実装は単一コミット `c4928ff3`（メッセージ「基盤フィーチャー スクラッチ再実装：旧仕様ベース実装を承認済み仕様へ全面置換（適合 finding A 8件解消）」）で完結。`c4928ff3..HEAD` 間で `runtime/foundation/`・`runtime/schemas/`・`runtime/prompts/{primary_detection,adversarial_review,judgment}/`・`runtime/validators/contracts/`・`runtime/config/`・`scripts/validate_foundation_contracts.rb`・`tests/foundation/` への追加コミットなし（独立に `git log c4928ff3^..HEAD -- ...` で確認）
- reviewed features: `dual-reviewer-foundation`（基盤のみ。spec.json `phase: tasks-approved`、3 phase approved=true、alignment.requirements/design/tasks=completed）
- review focus:
  - 前回 9 finding（P1×5・P2×3・P3×1、A8/B1）が解消したか
  - Requirement 1〜7 受入と Task 1〜9 完了条件・§4 Downstream Handoff・§6 Completion Criteria を実装が満たすか
  - design §4 mandatory/deferred 符号化規約（2026-05-18 追記、design-reopen-review で確定）への schema 適合
  - 削除済み旧資産（`runtime/patterns/`／`review_mode_vocab.yaml`／旧 prompt ディレクトリ名）の物理不在
  - 静的検証（`scripts/validate_foundation_contracts.rb`／`tests/foundation/test_foundation_contracts.rb`）の完走
- 評価原則: コード・既存仕様の書き換えは行わず、評価と本証跡作成のみ。手戻り種別は WORKFLOW_OVERVIEW 第 4 節（A=task-local / B=design handback / C=requirements handback / D=intent handback、迷えば上流寄せ）に従う

### 点検対象とした実装の所在

- `runtime/foundation/layer1_framework.yaml`（commit `c4928ff3`、4342 bytes）
- `runtime/foundation/metadata_contract.yaml`（同）
- `runtime/schemas/{review_case,finding,impact_score,failure_observation,necessity_judgment}.schema.json`（5 file）
- `runtime/prompts/{primary_detection/primary_reviewer,adversarial_review/adversarial_reviewer,judgment/judgment_reviewer}.prompt.md`（3 file。`integration/`・`shared/` 非存在を独立確認）
- `runtime/config/{config,terminology}.yaml.template`
- `runtime/validators/contracts/{validator_result,invalidation_marker}.schema.json`
- `tests/fixtures/foundation/{review_case,finding,necessity_judgment,validator_result,invalidation_marker}.minimal.json`（5 fixture）
- `scripts/validate_foundation_contracts.rb`（125 行、外部依存なし）
- `tests/foundation/test_foundation_contracts.rb`（133 行、Minitest）

## 2. validation rerun

- rerun commands:
  - `ruby scripts/validate_foundation_contracts.rb`（design Test Strategy 5 項目に準拠した静的検証スクリプト）
  - `ruby tests/foundation/test_foundation_contracts.rb`（同検証の minitest 実装）
  - `find runtime/foundation runtime/schemas runtime/prompts runtime/validators/contracts -type f`（配置実地調査）
  - `grep -n "x-deferred\|x-staleness\|x-raw-evidence\|x-versioning" runtime/schemas/*.json runtime/validators/contracts/*.json`（design §4 符号化規約適合の独立確認）
  - 旧資産不在確認：`ls runtime/patterns runtime/validators/contracts/review_mode_vocab.yaml runtime/prompts/{primary,adversarial,integration,shared}`
  - `git log c4928ff3^..HEAD -- runtime/foundation/ runtime/schemas/ runtime/prompts/{primary_detection,adversarial_review,judgment}/ runtime/validators/contracts/ runtime/config/ scripts/validate_foundation_contracts.rb tests/foundation/`（再実装後の追加変更有無）

- result summary:
  - `scripts/validate_foundation_contracts.rb`: 完走（`foundation contract validation passed` を標準出力、`EXIT=0`）。前回 Finding 3 が再現せず（`ArgumentError: invalid byte sequence in US-ASCII` は発生しない。`path.read(encoding: "UTF-8")` で明示固定済み、scripts/validate_foundation_contracts.rb:32,51,61,92,108）
  - `tests/foundation/test_foundation_contracts.rb`: 8 runs / 107 assertions / 0 failures / 0 errors / 0 skips（`EXIT=0`）。test list は schema_files_are_valid_json_schema・deleted_legacy_assets_absent・layer1_framework_required_sections・metadata_contract_fields_and_enums・prompt_artifacts_frontmatter・step_d_has_no_prompt・templates_parse_as_yaml・fixtures_parse の 8 件
  - 配置調査：design Shared Artifact Layout 12 entry すべて実在。`runtime/foundation/layer1_framework.yaml` が存在（前回 Finding 1 解消）、prompt 3 件が `primary_detection/`・`adversarial_review/`・`judgment/` 配下（前回 Finding 2 解消）、`runtime/prompts/integration/`・`shared/` および旧 `primary/`・`adversarial/` ディレクトリは物理不在
  - 旧資産不在確認：`runtime/patterns` 不存在、`runtime/validators/contracts/review_mode_vocab.yaml` 不存在（前回 Finding 4 解消）
  - 符号化規約適合確認：6 schema に `x-deferred` または validator-facing 特例キー（`x-staleness-propagation`）が design §4 規約箇条 3・4 に従って配置。1 例外あり（finding.adversarial_outcome、後述 Finding 1）
  - 再実装後の追加変更：`c4928ff3..HEAD` 間で foundation 配下に追加コミットなし。再実装は単一コミットで完結

## 3. findings

### Finding 1 `P3`

- title: `finding.schema.json` の `adversarial_outcome` field が design §4 符号化規約箇条 3 第 2 文「`x-deferred` に拡張の委譲先を併記する」に対し、`x-deferred` トップレベル注記を欠く（`description` 内のみで委譲先を表現）
- file: `runtime/schemas/finding.schema.json:27-35`（`adversarial_outcome` property 定義）、`runtime/schemas/finding.schema.json:37`（schema トップレベルに `x-versioning-note` はあるが `x-deferred` なし）
- references: design.md §4「mandatory/deferred の JSON Schema 符号化規約」箇条 3 第 2 文「『初版語彙を固定し将来拡張のみ先送りする』項目は、当該 field の `enum` を schema に記載する（形状・初版語彙とも mandatory）。そのうえで語彙の将来拡張が deferred である旨を `description` に記し、`x-deferred` に拡張の委譲先を併記する」、design-reopen-review-2026-05-18.md 観点 3 D2（重要）「規約箇条 3 が『初版 enum 固定＋拡張のみ deferred』型を対象外としており、`finding.adversarial_outcome` が該当」
- description: 実装は `adversarial_outcome` に enum 3 値（`counter_evidence_raised`／`no_counter_evidence_after_challenge`／`not_assessed`）を schema 内に記載し、`description` に「語彙拡張は deferred（runtime/evaluation 委譲）」と明記。これは規約箇条 3 第 2 文（初版 enum 固定＋拡張 deferred 型）の主旨と一貫する。ただし規約は「`x-deferred` に拡張の委譲先を併記する」と明記しており、`description` 内記載と並行して schema トップレベルの `x-deferred` キーへの委譲先記載を要求する読み方ができる。実装は description のみで委譲先を示し、トップレベル `x-deferred` を持たない（`impact_score.schema.json:15`・`failure_observation.schema.json:20` は同 field に `x-deferred` を備えるのと対照的）
- impact: 規約箇条 3 第 2 文の文面と finding schema 表面の文面整合に軽微な空白。機械検証としては `tests/foundation/test_foundation_contracts.rb` が「`x-deferred` 必須」までは検査していないため pass しているが、design §4 規約の「機械可読な mandatory/deferred 区別」の正本表現としては不均一（`impact_score`・`failure_observation` はトップレベル `x-deferred` あり、`finding` のみ description 依存）。downstream が `x-deferred` キーを符号化規約の判定起点に使う場合、`finding.adversarial_outcome` の語彙拡張 deferred を機械抽出できない
- recommended action: `finding.schema.json` トップレベルに `"x-deferred": "adversarial_outcome の語彙拡張は runtime/evaluation 委譲（design §4 finding／規約箇条 3 第 2 文）"` を追加。または design §4 規約箇条 3 第 2 文を「description のみで委譲先記載でも可」と緩和（後者は design 側 reopen を要するため非推奨）
- impact severity: P3（機械検証は pass、downstream 実害は規約利用形態に依存。文面整合の不均一にとどまる）
- handback assessment: A（task-local。schema トップレベルへの 1 キー追加で吸収可能。設計境界は design-reopen-review で確定済み）
- status: open / disposition=`fix-in-current-branch`

### 非 finding の観察

- 規約箇条 4 の validator-facing 2 contract 特例（`x-deferred` 代替の専用注記キー）について、`invalidation_marker.schema.json:21` は `x-staleness-propagation` で deferred 相当の伝播義務を表現し、design §4 規約箇条 4 後段「validator-facing 2 contract で deferred を表現する際、専用注記キー（例：`x-staleness-propagation`）を `x-deferred` の代替として用いてよい」と完全一致。前回 Finding 9（陳腐化伝播義務の contract 明記欠落）は実装側で解消されている
- `review_case.schema.json:20-26,32-36` は §5 step-level replay identity 6 項目を `step_records.items.required` 配列に展開しており、design-reopen-review 観点 3 で指摘されていた「§5 identity の schema 機械確認不能」も解消されている（規約箇条 1 末尾「入れ子の object および配列 `items` についても、各階層の `required` で当該階層の mandatory を表現する」と整合）
- `validator_result.schema.json:11-15` の `validator_status` は `metadata_contract.yaml` 語彙（`not_run`/`passed`/`failed`/`blocked`）を schema enum で固定し、`description` に「metadata_contract.yaml の canonical 語彙と整合（再定義しない）」と明記。canonical_ownership 原則と整合
- `metadata_contract.yaml:102-104` で `canonical_ownership` セクションに `validator_status`／`evidence_class` を明示しており、design Completion Criteria 第 4 項「foundation が canonical source として所有」を artifact 上で読める

## 4. metric snapshot

- `conformance_findings_count`: 1（P1=0 / P2=0 / P3=1）
- `severity_weighted_finding_score`: 1（重み P1=3・P2=2・P3=1 で P1×0 + P2×0 + P3×1 = 1）
- `post_smoke_nonconformance_count`: 0（`scripts/validate_foundation_contracts.rb`・`tests/foundation/test_foundation_contracts.rb` 両者 pass。Finding 1 は smoke 通過後も残るが、機械検証の判定基準（design Test Strategy 5 項目）には含まれず、規約箇条 3 第 2 文の文面整合の軽微空白で機能非適合ではない）
- `fixture_bound_resolution_count`: 0（新検証は `tests/fixtures/foundation/*.minimal.json` の存在・JSON parse 可能性のみを確認し、required 突合に依存しない構造。前回 Finding 6/7/8 の fixture 同梱 field への整合は解消）
- `heuristic_linkage_count`: 0（foundation は実行コードを持たず、basename match 等の heuristic linkage は構造上発生しない）
- `review_artifact_presence_rate`: 1.0（本証跡ファイルを新規作成、`.kiro/specs/dual-reviewer-foundation/reviews/` 配下に保存）
- `finding_to_signal_link_rate`: 0.0（本レビュー時点で signal register への起票は未実施。disposition で追跡）

## 5. disposition summary

- immediate disposition:
  - `fix-in-current-branch`: Finding 1（`finding.schema.json` トップレベル `x-deferred` 追加）
  - `fix-before-next-feature`: 該当なし
  - `record-and-watch`: 該当なし
  - `reopen-design` / `reopen-requirements` / `reopen-intent`: 該当なし（新規 B/C/D handback なし。design §4 規約は design-reopen-review-2026-05-18 で確定済みで、本レビューはその確定規約への準拠を点検）
- evidence linkage: 本証跡＝`.kiro/specs/dual-reviewer-foundation/reviews/implementation-conformance-review-2026-05-20-postrebuild.md`。新規 finding 1 件は handback class A（task-local）で reopen 連携は不要
- 手戻り種別の総括: A=1件（task-local cleanup）/ B=0 / C=0 / D=0。要件・設計境界・上位 intent 側の不足は検出されなかった
- 結論: 基盤のスクラッチ再実装（コミット `c4928ff3`）は **現行承認仕様（design §4 符号化規約を含む）へ構造適合**。前回 9 finding（P1×5/P2×3/P3×1、A8/B1）は **全 9 件解消** を独立確認。新規 finding は 1 件、P3・handback class A（規約箇条 3 第 2 文の文面整合空白）であり、実行・downstream 適合には非到達
- 推奨: **GO 可**。残 1 finding（P3/A）は本ブランチ内 cleanup（`finding.schema.json` トップレベルへの `x-deferred` キー 1 行追加）で吸収（reopen 不要）。downstream 4 spec（runtime／evaluation／self-improvement／paper-interface）への handoff artifact は §4 Downstream Handoff どおり整備済みで前進可。なお Finding 1 を機械検証に含めるため、`tests/foundation/test_foundation_contracts.rb` に「初版 enum 固定型 field のトップレベル `x-deferred` 存在検査」を加えると再発防止が機械化される（推奨）
- 最終判定行: **基盤再実装は承認仕様に構造適合（GO 可）。残 1 finding は task-local cleanup で吸収（reopen 不要）**

## 6. 前回 finding 9 件（手戻り A8/B1）の解消状況

前回証跡（`implementation-conformance-review-2026-05-18.md`）の 9 finding に対する本レビューの独立判定。前回 disposition と独立に、再実装後の実 artifact を Read して判定した。

### Finding 1（P1・A）`layer1_framework.yaml` 未実装：**解消**

- 根拠: `runtime/foundation/layer1_framework.yaml` が実在し、design §1 が要求する 7 つの top-level section（`version`／`roles`／`step_pipeline`／`step_intents`／`required_metadata_refs`／`asset_locations`／`override_extension_point`）をすべて宣言（layer1_framework.yaml:9,11,20,30,41,45,54）。Step A/B/C/D の canonical 名称（`primary_detection`／`adversarial_review`／`judgment`／`integration`）が `step_pipeline` で固定（layer1_framework.yaml:20-28）、Step B forced-divergence と Step C necessity judgment の別 role・別 intent 分離が `step_intents` で明示（layer1_framework.yaml:30-39）、Step D は `role: "(no additional LLM call)"` と明記（layer1_framework.yaml:37）。phase/profile・treatment 値語彙は列挙されていない（`tests/foundation/test_foundation_contracts.rb:59-62` で機械検証）。`override_extension_point` は所在のみ固定し選択順序・優先規則・適用条件を一切定義していない（layer1_framework.yaml:54-56）

### Finding 2（P1・A）Step A/B prompt 正本配置の不一致：**解消**

- 根拠: prompt 3 件が design §Placement Decisions 項目 3 のパスに実在（`runtime/prompts/primary_detection/primary_reviewer.prompt.md`／`runtime/prompts/adversarial_review/adversarial_reviewer.prompt.md`／`runtime/prompts/judgment/judgment_reviewer.prompt.md`）。旧名ディレクトリ `runtime/prompts/primary`／`runtime/prompts/adversarial`／`runtime/prompts/integration`／`runtime/prompts/shared` はいずれも物理不在（`ls` で確認、`scripts/validate_foundation_contracts.rb:43-46`・`tests/foundation/test_foundation_contracts.rb:42-47` で機械検証）。Step D 用 prompt artifact は存在しない（design §3 placement 規約遵守、`tests/foundation/test_foundation_contracts.rb:110` で機械検証）

### Finding 3（P1・A）foundation 検証スクリプト完走失敗：**解消**

- 根拠: `scripts/validate_foundation_contracts.rb` を実行して `foundation contract validation passed` を出力し `EXIT=0`。前回原因の `ArgumentError: invalid byte sequence in US-ASCII` は `path.read(encoding: "UTF-8")` への明示固定（scripts/validate_foundation_contracts.rb:32,51,61,92,108）で完全に解消。検証内容も design Test Strategy 5 項目（schema 整合／framework 整合／metadata 整合／prompt 整合／template 整合）＋旧資産不在＋mandatory enum 全数突合に全面書き換え済み（旧 `review_mode_consistency_smoke_test!` は削除）。`tests/foundation/test_foundation_contracts.rb` も 8 runs / 107 assertions / 0 failures で同一基準を minitest として独立提供

### Finding 4（P1・A）削除済み Requirement 5 資産と `review_mode_vocab.yaml` 残存：**解消**

- 根拠: `runtime/patterns/`・`runtime/validators/contracts/review_mode_vocab.yaml` は物理不在（`ls` で確認、`scripts/validate_foundation_contracts.rb:42-46`・`tests/foundation/test_foundation_contracts.rb:42-47` で機械検証）。validator は `metadata_contract.yaml` 所有の review-mode 語彙のみを参照する構造（metadata_contract.yaml:56-59 で `review_mode` enum を `[manual_dogfooding, runtime_mediated]` として `metadata_contract.yaml` 内に固定）。Downstream Handoff（tasks §4「`runtime/patterns/*` および `review_mode_vocab.yaml` は提供しない」）と repo 実態が完全一致

### Finding 5（P1・A）`metadata_contract.yaml` の `config_version`／`config_hash` 欠落と `validator_status` enum `blocked` 欠落：**解消**

- 根拠: `metadata_contract.yaml:72-77` で `config_version`／`config_hash` の 2 field を `required: true` で定義（Requirement 7 受入 3／Requirement 2 受入 4 を実装）。`metadata_contract.yaml:82-85` で `validator_status` enum を `[not_run, passed, failed, blocked]` の 4 値で固定（Requirement 6 受入 10 を実装）。さらに `canonical_ownership` セクション（metadata_contract.yaml:102-104）で foundation が所有する canonical source として明示宣言。`tests/foundation/test_foundation_contracts.rb:70-87` が必須 field 全 20 件と 4 enum を機械検証して pass

### Finding 6（P2・A）`finding` schema の `adversarial_outcome` 欠落と設計外 field 混在：**解消**

- 根拠: `finding.schema.json:8-12` の `required` 配列が design §4 finding の mandatory-B1.0 11 field をすべて列挙（`finding_id`／`step_id`／`source_role`／`severity`／`summary`／`source_refs`／`counter_evidence_refs`／`judgment_ref`／`decision_unit_id`／`human_decision_ref`／`adversarial_outcome`）。前回指摘の設計外 required（`schema_version`／`run_id`／`validation_refs`／`impact_score_ref`／`failure_observation_refs`）は required 配列に存在しない。`adversarial_outcome` の enum は最小語彙 3 値（`counter_evidence_raised`／`no_counter_evidence_after_challenge`／`not_assessed`）で固定（finding.schema.json:30-34、Requirement 1 受入 4 を実装）。空 `counter_evidence_refs` と「意図的不在」の区別が schema 上で表現可能

### Finding 7（P2・A）`impact_score`／`failure_observation` schema の命名不一致：**解消**

- 根拠: `impact_score.schema.json:8` の `required` が design §4 impact_score の mandatory-B1.0 4 field（`finding_ref`／`severity_axis`／`fix_cost_axis`／`downstream_scope_axis`）と完全一致。値語彙・採点尺度・重み付けは `x-deferred`（impact_score.schema.json:15）で evaluation 委譲を明示。`failure_observation.schema.json:8-11` の `required` が design §4 failure_observation の mandatory-B1.0 6 field（`observation_id`／`run_ref`／`related_finding_ref`／`failure_type`／`missed_by_role`／`detected_at_step`）と完全一致。`missed_by_role`（見落とした role）も含まれる。詳細分類体系・メトリクス導出は `x-deferred`（failure_observation.schema.json:20）で self-improvement／evaluation 委譲を明示

### Finding 8（P2・B）`review_case` step-level replay identity と mandatory/deferred 区分の JSON Schema 表現：**解消**

- 根拠: `review_case.schema.json:28-46` で `step_records.items.required` 配列に design §5 step-level replay identity 6 項目（`step_id`／`step_name`／`step_status`／`step_prompt_artifact_id`／`step_started_at`／`step_closed_at`）を機械可読に展開済み。各 property 定義も同階層に列挙（review_case.schema.json:37-44）。design §4 で mandatory/deferred の JSON Schema 符号化規約を 4 箇条（mandatory=`required` 列挙／deferred=非列挙＋`description`＋`x-deferred`／初版 enum 固定型は `enum`＋`description`＋`x-deferred`／7 schema 一律適用＋validator-facing 2 contract 特例）として確定し（design-reopen-review-2026-05-18.md の D1〜D5 must-fix 5 件を反映）、本 finding は前回 B handback の唯一例として design.md §4 への規約追記で構造的に解消された。スキーマ実装側でも `review_case`・`impact_score`・`failure_observation` が規約箇条 1〜3 に整合（後述 Finding 1 で 1 例外）

### Finding 9（P3・A）`invalidation_marker` schema の陳腐化伝播義務 contract 明記なし：**解消**

- 根拠: `invalidation_marker.schema.json:21` に `x-staleness-propagation` キーで「この標識の付与は、当該 run を参照した下流派生成果物への陳腐化伝播義務を伴う（Requirement 6 受入 9）。具体的な陳腐化フラグ付け／再導出手段は evaluation／paper-interface に委ねる」を明記。design §4 規約箇条 4 後段の validator-facing 2 contract 特例（`x-deferred` 代替の専用注記キー）と一貫し、伝播義務の存在が contract として読める。`description`（invalidation_marker.schema.json:5）でも同義の文章を併記

### 総括

前回 9 finding（致命5／重要3／軽微1、A8/B1）は **全 9 件解消** を独立に確認した。B 群 1 件（Finding 8）は design-reopen-review-2026-05-18 で確定した §4 符号化規約に従い構造的に解消、A 群 8 件は task-local に解消。新規 finding は 1 件（P3／handback A／`finding.schema.json` トップレベル `x-deferred` 注記の追加漏れ）で、実行・downstream 適合には非到達。要件 1〜7・Task 1〜9 完了条件・§6 Completion Criteria・§4 Downstream Handoff・design §4 符号化規約は実 artifact の Read と機械検証（`scripts/validate_foundation_contracts.rb` 完走＋`tests/foundation/test_foundation_contracts.rb` 8 runs 全 pass）で満たすことを確認した。

**判定: 現行承認仕様に構造適合（GO 可）。残 1 finding は本ブランチ内 task-local cleanup（reopen 不要）。**
