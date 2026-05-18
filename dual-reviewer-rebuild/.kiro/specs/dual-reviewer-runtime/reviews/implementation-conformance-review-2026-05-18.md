# implementation conformance review

_実施日: 2026-05-18_
_レビュー種別: implementation conformance review（独立適合レビュー）_
_対象 feature: dual-reviewer-runtime（実行系のみ）_
_正本: docs/coordination/implementation-conformance-review.md / docs/reviews/templates/implementation-conformance-review-template.md_

## 1. review scope

- review type: `implementation conformance review`
- reviewed branch: `claude/v2-acquisition-code-mod`
- reviewed commit: `a3b2d9ec3b11b45dadef634fdad219b50c8ebacb`
- reviewed features: `dual-reviewer-runtime`（基盤確定済み契約 `runtime/foundation/`・`runtime/schemas/`・`runtime/prompts/`・`runtime/validators/contracts/`・`runtime/config/` を前提とする）
- review focus:
  - 承認済み requirements.md（Requirement 1〜9、10 は削除済み）・design.md・tasks.md（tasks-approved）が要求する成果物が既存実装に実在し、現行承認仕様（基盤新契約を含む）へ構造適合するか
  - 基盤側で削除済みの旧資産（`runtime/patterns/`・旧命名 prompt・旧 metadata_contract キー等）への依存残存有無
  - 静的に動作確認できるか（ruby ロード・`initialize_run` 実行）

### 対象として列挙した承認要求成果物

- run manifest 開始時固定／実行中更新 2 群（design「Run Manifest Field Set」、Task 2）
- `review_case.json` 唯一横断正本（foundation schema 準拠、投影規約 runtime 所有。実行側 A-5、Task 6）
- step 実行印（`executed`/`skipped`/`reduced` marker、`step_id`/`step_name`/`execution_state`/`reason`/`treatment`。Task 3）
- treatment × step 実行マトリクス（`single`/`dual`/`dual+judgment`。design 表、Task 3）
- Step B forced-divergence（`adversarial_outcome` 必須設定。Task 3）
- Step D 機械統合（追加 LLM 呼び出しなし 6 手順、human_decision 未確定。Task 3）
- prompt resolution（foundation canonical path → runtime override → ambiguous fail、prompt identity 4 項目。Task 4）
- decision unit／human sign-off record（foundation enum `pending`/`approved`/`rejected`/`deferred`。Task 5）
- `failures/failure_observation.json`（foundation schema 準拠。Requirement 4 受入 7、Task 6）
- Run Close Boundary 順序（Step D → human sign-off → raw freeze → validator → close。Requirement 6 受入 9、Task 7）
- validator_status 正準 enum（`not_run`/`passed`/`failed`/`blocked`）の丸めなし伝播（Task 7）
- invalidation marker（raw 不変・別 artifact）と `derived/invalid_run_triage_note.json`（Task 8）
- portable evidence bundle export（Task 9）
- phase-aware review profiles（runtime-owned profile config。Task 10）
- testability seams 決定的検証ケース（Task 11）

## 2. validation rerun

- rerun commands:
  - `ruby -c runtime/controller/session_controller.rb` → `Syntax OK`
  - `ruby -e 'require "./runtime/controller/session_controller"'` → `LOAD_OK`（require 連鎖は通る）
  - 削除済み資産の実在確認（`runtime/prompts/shared/frontmatter_contract.yaml` 他 5 件）
  - 最小 smoke: `SessionController#initialize_run(...)` 実行
- result summary:
  - require 連鎖はロードできるが、`initialize_run` が `KeyError: key not found: "review_protocol"` で **run 開始時点で失敗**。run manifest を 1 件も生成できず、以降の全成果物（review_case／step／decision／validation／export）に到達不能。
  - 旧資産依存 5 件すべて `MISSING`（基盤再実装で削除済み）。
  - 専用テストスイートは未確認（`tests/` 配下に runtime executor の決定的検証ケース不在）。

## 3. findings

### Finding 1 `P1`

- title: `initialize_run` が存在しない config キー `review_protocol` を要求し run 開始が即失敗する
- file: `runtime/controller/session_controller.rb:515-520`（`config_protocol_version`）
- references: `runtime/config/config.yaml.template`（`protocol_version` はトップレベル、`review_protocol` ネストは無い）／Requirement 1 受入 1・受入 6／design「Session Inputs」「Run Manifest Field Set」
- description: `config.fetch("review_protocol").fetch("protocol_version")` を呼ぶが、基盤確定 config template は `protocol_version: "1.0.0"` をトップレベルに持つのみ。
- impact: review session を 1 件も開始できない。runtime の全要求成果物が到達不能。致命。
- recommended action: `config.fetch("protocol_version")` に修正し基盤 config 構造へ適合させる。
- handback assessment: A（task-local。基盤 config 契約は正、実装側の参照キー誤り）
- status: open / disposition=`fix-before-next-feature`

### Finding 2 `P1`

- title: `FoundationAssetLoader` が基盤で削除済みの旧資産 3 件に依存する
- file: `runtime/support/foundation_asset_loader.rb:22-35`
- references: 削除確認 `runtime/prompts/shared/frontmatter_contract.yaml`／`runtime/validators/contracts/review_mode_vocab.yaml`／`runtime/patterns/seed_patterns.yaml`（いずれも MISSING）／CLAUDE.md「foundation 確定 shared contract を前提」
- description: `prompt_frontmatter_contract`／`review_mode_vocabulary`／`seed_pattern_catalog` が旧パスを `load_yaml` する。基盤再実装（commit c4928ff3）で旧命名・旧 patterns 体系は撤廃済み。
- impact: validation_bridge（`asset_loader.review_mode_vocabulary`）・controller（`prompt_frontmatter_contract`）が呼ばれた時点で `Errno::ENOENT`。Run Close Boundary・prompt identity 記録が全滅。致命。
- recommended action: 基盤の現行 prompt frontmatter 規約（各 prompt の YAML frontmatter `prompt_id`/`version`/`role`/`step`）と現行 metadata_contract / review_mode enum 参照へ全面付け替え。
- handback assessment: B（基盤新契約に対する asset 解決層の構造的付け替えが必要。単純な参照修正に留まらず resolution policy 再設計を含む）
- status: open / disposition=`reopen-design`（runtime design「Prompt Resolution Model」と実装の整合を取り直す）

### Finding 3 `P1`

- title: step executor のインタフェースが controller 呼び出しと不一致（実行不能）
- file: `runtime/executors/step_{a,b,c,d}_*.rb:14`（`def execute(context)`）／`runtime/controller/session_controller.rb:138-145`
- references: Requirement 1 受入 1〜4／Requirement 2 受入 1〜5／design「Step Execution Model」「Treatment × Step Execution Matrix」
- description: controller は `executor.execute(step_id:, target_id:, phase_profile:, treatment:, analysis_inputs:, prior_step_payloads:)` とキーワード引数で呼ぶが、各 executor は位置引数 1 個 `execute(context)` を取り `context.fetch(:treatment)` 等を参照。`ArgumentError`（wrong number of arguments）で全 step が実行不能。
- impact: Step A/B/C/D が一切実行できず、step 実行印・treatment×step マトリクス・Step B forced-divergence・Step D 機械統合の全要求が成立しない。致命。
- recommended action: controller・executor 間で引数契約を統一（Task 3 で固定されたキーワード契約に executor 側を合わせる）。
- handback assessment: A（task-local。設計境界は不変、実装内インタフェース不整合）
- status: open / disposition=`fix-before-next-feature`

### Finding 4 `P1`

- title: prompt path が基盤現行配置と不一致、Step D は存在しない prompt を要求
- file: `runtime/executors/step_b_adversarial_review.rb:8`（`runtime/prompts/adversarial/...`）／`runtime/executors/step_d_integration.rb:8`（`runtime/prompts/integration/integration_reviewer.prompt.md`）
- references: 実在は `runtime/prompts/adversarial_review/adversarial_reviewer.prompt.md`／design「Role and Step Mapping」（Step D は role なし＝LLM 非依存の機械統合）
- description: Step B は `adversarial/`（実在は `adversarial_review/`）を指す。Step D は `integration/integration_reviewer.prompt.md` を要求するが、design では Step D は reviewer role を持たず prompt 不要。該当 prompt も MISSING。さらに `base_step_executor.rb` は frontmatter から `prompt_version` を fetch するが、基盤 prompt の frontmatter キーは `version`。
- impact: Step B/D の prompt 解決が `Errno::ENOENT`／`KeyError`。design Role and Step Mapping（Step D role なし）に構造非適合。致命。
- recommended action: Step B path を `adversarial_review/` に修正、Step D の prompt 依存を撤廃（機械統合に整合）、frontmatter キー参照を `version` に統一。
- handback assessment: A（path/キー修正は task-local。ただし Step D の prompt 依存撤廃は Task 4 の role-step mapping 実装範囲）
- status: open / disposition=`fix-before-next-feature`

### Finding 5 `P1`

- title: v2 取得方針で撤廃済みの規則ファイル参照・種パターン照合に runtime が依存
- file: `runtime/executors/base_step_executor.rb:2-3,82-150`（`HeuristicProfileLoader`／`RuleMatchAnalyzer`／`heuristic_profile_ref`／`seed_pattern_catalog`）
- references: requirements.md Requirement 10「削除済み」／design「Case Manifest and Heuristic Resolution Model」備考（`heuristic_profile_ref` 撤廃）／design「Generic Fragment Cue Rule（削除済み）」
- description: 全 step executor の基底が `heuristic_profile_ref` 解決と `RuleMatchAnalyzer`（種パターン照合）に依存。承認済み spec は v2 で実 LLM 呼び出しへ置換し規則ファイル参照・パターン照合を撤廃する方針を明記（Requirement 10 削除、design 該当節削除）。実装は旧 v1 方針のまま。
- impact: 承認仕様の中核方針（パターン照合撤廃）に構造非適合。Step 実行系が旧 contract（`runtime/patterns/seed_patterns.yaml`）前提で組まれており、致命的な仕様逸脱。
- recommended action: step executor の解析戦略を実 LLM 呼び出し（testability seam 経由の差し替え可能境界）へ再設計。v2 取得 spec（`dual-reviewer-v2-acquisition`）との境界整合を要確認。
- handback assessment: B（設計境界の見直しが必要。runtime design Step Execution Model と v2-acquisition の責務境界の再確定を含む）
- status: open / disposition=`reopen-design`

### Finding 6 `P1`

- title: `validation_bridge` が削除済み旧 metadata_contract キー・旧 vocab に依存し Run Close Boundary が成立しない
- file: `runtime/validation/validation_bridge.rb:18-22,73,83`
- references: 基盤 `runtime/foundation/metadata_contract.yaml`（`contract_id`/`required_fields` キー不在、`canonical_ownership.validator_status` を所有）／Requirement 6 受入 1・2・9
- description: `asset_loader.metadata_contract.fetch("contract_id")`／`.fetch("required_fields")`／`asset_loader.review_mode_vocabulary` を参照。基盤現行 metadata_contract には `contract_id`／`required_fields` キーが無く（`fields:` マップ構造）、`review_mode_vocab.yaml` は削除済み。`session_controller.rb:489` の `validate_required_metadata!` も同じく不在キー `required_fields` に依存。
- impact: Run Close Boundary（validator 呼び出し）が `KeyError`/`ENOENT` で破綻。validator_status 正準 enum 伝播（Requirement 6 受入 2）も成立しない。致命。
- recommended action: 基盤 metadata_contract の `fields:` 構造（`required: true` 抽出）・`canonical_ownership.validator_status`・`review_mode` enum を参照する形へ付け替え。
- handback assessment: B（基盤新契約構造への validation 層の構造的付け替え。参照修正に加え required 抽出ロジック設計を含む）
- status: open / disposition=`reopen-design`

### Finding 7 `P2`

- title: validator_status の正準 enum が実装で別トークンに丸められる
- file: `runtime/controller/session_controller.rb:349`／`runtime/validation/validation_bridge.rb:51`
- references: 基盤 metadata_contract `validator_status` enum `[not_run, passed, failed, blocked]`／Requirement 6 受入 2（再定義・丸め禁止）／tasks.md Task 7
- description: validation_bridge は `overall_status` を `passed`/`failed` の 2 値のみ生成し、controller は `== "passed" ? "passed" : "failed"` で `blocked` を握り潰す。基盤所有の `blocked`（required artifact 不足）が final metadata まで伝播しない。
- impact: 現状（Finding 1〜6 で実行到達前）では顕在化しないが、上流修正後に `blocked` ケースが silent に `failed` へ丸められ Requirement 6 受入 2 違反。重要。
- recommended action: validator 結果に `blocked` を導入し、`validator_status` を丸めず正準 enum のまま伝播。insufficiency detail を併記。
- handback assessment: A（task-local。Task 7 実装範囲内で吸収可能）
- status: open / disposition=`fix-in-current-branch`

### Finding 8 `P2`

- title: human_signoff record が design 規定の正本フィールド集合と不一致
- file: `runtime/controller/session_controller.rb:279-285`（`emit_decision_artifacts`）
- references: design「Human Sign-off Record」（`run_id`/`human_signoff_status`/`signed_off_by`/`signed_off_at`/`covered_decision_unit_ids`/`signoff_note`）／Requirement 5 受入 3・4／Requirement 6 受入 9
- description: 実装は `run_id`/`human_signoff_status`/`operator_id`/`signoff_timestamp`/`note` を書く。design 正本の `signed_off_by`/`signed_off_at`/`covered_decision_unit_ids` を欠き、フィールド名も不一致。foundation finding schema が参照する linkage（covered_decision_unit_ids）が欠落。
- impact: human decision absence と明示 defer/reject の区別、close judgment が対象とした decision unit 追跡が不能。重要。
- recommended action: design「Human Sign-off Record」の 6 フィールドへ整合。
- handback assessment: A（task-local。Task 5 実装範囲）
- status: open / disposition=`fix-in-current-branch`

### Finding 9 `P2`

- title: Run Close Boundary の順序（Step D → human sign-off → freeze → validator → close）が実装上担保されない
- file: `runtime/controller/session_controller.rb:259-387`（`emit_decision_artifacts`／`close_run`）
- references: Requirement 6 受入 9（human sign-off → validator → run close の順序厳守、validator が human decision に先行しない）／design「Run Close Boundary」／tasks.md Task 7
- description: `emit_decision_artifacts` で human_decision を引数として受け取り decision unit へ即時転記する設計で、Step D 出力（human_decision 未確定）→ 人間 sign-off → validator の時間順序を強制する機構（raw evidence freeze ポイント・順序ガード）が存在しない。`close_run` は human_signoff を引数で受けるのみで先行関係を検証しない。
- impact: validator 結果が human decision に先行する／sign-off 前 close を実装が防げない。Requirement 6 受入 9・design Decision 3 に構造非適合。重要。
- recommended action: raw evidence freeze 後にのみ validator を起動する単一起動点と、sign-off artifact 書込済みを前提条件とする順序ガードを実装。
- handback assessment: B（順序保証は controller のライフサイクル設計に関わる。Task 7 の境界実装方針の明確化を要する）
- status: open / disposition=`reopen-design`

### Finding 10 `P3`

- title: Step B forced-divergence の `adversarial_outcome` 必須設定が未実装
- file: `runtime/executors/step_b_adversarial_review.rb:14-46`
- references: design「Step B: Adversarial Review」（各 finding に `adversarial_outcome` ∈ `counter_evidence_raised`/`no_counter_evidence_after_challenge`/`not_assessed` を必ず設定。foundation 要件 1 受入 4）／tasks.md Task 3
- description: Step B 出力は `counter_evidence` を集約するのみで、各 finding に `adversarial_outcome` を設定しない。「反証を試みていない」と「試みた結果なし」を曖昧にしない要求が未充足。
- impact: 実行到達前のため即座には壊れないが、Step B の中核要求（forced-divergence の証跡性）が欠落し traceability を弱める。軽微。
- recommended action: 各 finding に `adversarial_outcome` を必須設定する実装を追加。
- handback assessment: A（task-local。Task 3 実装範囲）
- status: open / disposition=`record-and-watch`

### Finding 11 `P3`

- title: testability seams の決定的検証ケースが不在
- file: `tests/`（runtime executor / validation bridge / Step D 機械統合の決定的検証ケース不在）
- references: tasks.md Task 11 完了条件（4 seam それぞれに固定入力→期待出力の決定的検証ケースが 1 つ以上存在し pass）／プロジェクト TDD 方針
- description: runtime の 4 testability seam（言語モデル差し替え／検証ブリッジ起動点／ステップ入出力分離／Step D 機械統合）に対応する決定的検証ケースが確認できない。
- impact: 適合性を機械的に保証する回帰基盤が無く、Finding 1〜10 のような破綻が静的検出されないまま tasks-approved に至った。軽微（ただし再発防止上は重要度高）。
- recommended action: TDD 方針に従い 4 seam の決定的検証ケースを先行整備。
- handback assessment: A（task-local。Task 11 実装範囲）
- status: open / disposition=`fix-in-current-branch`

## 4. metric snapshot

- `conformance_findings_count`: 11（P1=6 / P2=3 / P3=2）
- `severity_weighted_finding_score`: 26（重み P1=3・P2=2・P3=1 で P1 6件×3 + P2 3件×2 + P3 2件×1 = 18+6+2 = 26）
- `post_smoke_nonconformance_count`: 11（smoke 自体が `initialize_run` で fail。smoke pass 後ではなく smoke 段階で全件露見）
- `fixture_bound_resolution_count`: 3（旧資産 path hard-code 依存：frontmatter_contract.yaml／review_mode_vocab.yaml／seed_patterns.yaml）
- `heuristic_linkage_count`: 1（`heuristic_profile_ref`＋`RuleMatchAnalyzer` の規則ファイル/種パターン照合依存。撤廃方針違反）
- `review_artifact_presence_rate`: 1.0（本証跡ファイルを新規作成）
- `finding_to_signal_link_rate`: 0.0（本レビュー時点で signal register への起票は未実施。disposition で追跡）

注: `severity_weighted_finding_score` は P1=3／P2=2／P3=1 重みで P1×6 + P2×3 + P3×2 = 18+6+2 = **26**。

## 5. disposition summary

- immediate disposition:
  - `fix-before-next-feature`: Finding 1・3・4（実行を物理的に阻む致命破綻。最優先）
  - `reopen-design`: Finding 2・5・6・9（基盤新契約への構造的付け替え／撤廃方針整合／close 順序保証＝設計境界 B 相当）
  - `fix-in-current-branch`: Finding 7・8・11
  - `record-and-watch`: Finding 10
- evidence linkage: 本証跡＝`.kiro/specs/dual-reviewer-runtime/reviews/implementation-conformance-review-2026-05-18.md`。reopen 必要分（B 群 4 件）は reopen 10 ステップに従い coordination log／spec.json `custom.reopened`／該当 alignment gate 連携が別途必要。
- next action:
  - 結論: 既存 runtime 実装は **現行承認仕様に未適合**。`initialize_run` 段階で実行不能であり、基盤再実装（commit c4928ff3 以降）で確定した shared contract（prompt frontmatter 規約・metadata_contract 構造・review_mode enum・patterns 撤廃・Requirement 10 削除）に旧 v1 ベース実装が全面的に追随していない。基盤と同様にスクラッチ再実装相当の是正が必要。
  - 手戻り種別の総括: A=5件（Finding 1・3・4・7・8・10・11 のうち task-local 吸収可）/ B=4件（Finding 2・5・6・9 設計境界）/ C=0 / D=0。基盤確定済み契約は正であり、要件・上位 intent 側の不足は検出されなかった（乖離は全て実装側の旧仕様残存）。
  - 推奨: B 群 4 件について reopen 10 ステップを起動し、runtime tasks 再開（スクラッチ再実装方針）を人間承認に諮る。
