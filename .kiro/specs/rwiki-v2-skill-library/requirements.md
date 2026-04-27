# Requirements Document

## Project Description (Input)

Rwiki v2 では L1 raw から L2 Graph Ledger / L3 Curated Wiki へのコンテンツ生成（distill / 抽出 / 統合）が多様な出力形式を要求する。タスクと出力形式を一体で実装すると、出力形式を増やすたびに各タスクのコードを書き換える必要が生じ、Spec 5（rwiki-v2-knowledge-graph）が必要とする entity / relation 抽出も独立した skill として用意されていなければ Graph Ledger への投入経路が成立しない。

本 spec（Spec 2）は §2.8 Skill library 原則の実体化として、`AGENTS/skills/` ディレクトリ構造、Skill ファイルの 8 section スキーマ、Skill frontmatter、初期 skill 群（知識生成 12 種 + Graph 抽出 2 種 + lint 支援 1 種）、Custom skill 作成フロー（`rw skill draft/test/install`）、`review/skill_candidates/` 層、Install 前の dry-run 必須化と install validation を所管する。

出典 SSoT: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §2.8 / §5.6 / §5.7 / §7.2 Spec 2 / §11.2。

## Introduction

本 requirements は、Rwiki v2 における Skill library の構造・初期 skill 群・Custom skill ライフサイクル（draft → test → install）・Install validation・Graph 抽出 skill の出力 schema 固定 を、user / operator から観測可能な振る舞いとして定義する。読者は Spec 2 の実装者および Spec 3（dispatch）/ Spec 4（CLI）/ Spec 5（L2 Ledger）/ Spec 6（perspective / hypothesis）/ Spec 7（lifecycle）の起票者である。

本 spec が SSoT として固定するのは「skill 内容（prompt と出力 schema）」と「skill ライフサイクルのうち作成・install・validation 部分」である。Skill 選択ロジック（distill タスクからの dispatch）は Spec 3、Skill lifecycle の deprecate / retract / archive イベントは Spec 7、Graph 抽出結果の格納・進化は Spec 5 の所管であり、本 spec はそれらに介入しない。

本 spec が想定する subject は次の 3 種類である。

- **Skill Library**: AGENTS/skills/ 配下の skill 集合とその構造を所管する論理コンポーネント
- **Skill Authoring Workflow**: `rw skill draft / test / install` を通る custom skill 作成・install フロー
- **Skill Validator**: Install 時の 8 section / YAML / 衝突 / 参照整合性検査を行う論理コンポーネント

## Boundary Context

- **In scope**:
  - `AGENTS/skills/` ディレクトリ構造と命名規約
  - Skill ファイルの 8 section スキーマ（Purpose / Execution Mode / Prerequisites / Input / Output / Processing Rules / Prohibited Actions / Failure Conditions）
  - Skill frontmatter（必須: `name` / `origin` / `version` / `status` / `interactive` / `update_mode` / `handles_deprecated`、optional: `applicable_categories` / `applicable_input_paths` / `dialogue_guide` / `auto_save_dialogue`）
  - 初期 skill 群（知識生成 12 種 / Graph 抽出 2 種 / lint 支援 1 種、計 15 種）の存在・用途・出力種別の固定
  - Graph 抽出 skill（`relation_extraction` / `entity_extraction`）の出力 schema 仕様（Spec 5 が validation する interface）
  - Custom skill 作成フロー（`rw skill draft / test / install` の振る舞い、対話 7 段階）
  - `review/skill_candidates/` 層への candidate 蓄積と frontmatter
  - Install 前の dry-run 最低 1 回必須化
  - Install validation（8 section 完備 / YAML 妥当 / 名前衝突なし / 参照整合性）
  - `update_mode: extend` 対応（差分マーカー HTML コメント形式）
  - `origin: standard | custom` の区別、`rw init` 配布対象の定義
- **Out of scope**:
  - Skill 選択ロジック（distill タスクからの dispatch、Spec 3 が所管）
  - Skill 起動 CLI の引数 parse / 結果整形 / exit code（Spec 4 が所管。本 spec は subcommand の振る舞い契約のみ規定）
  - Skill lifecycle イベントのうち deprecate / retract / archive（Spec 7 が所管）
  - L2 Graph Ledger への抽出結果の永続化、edge confidence 計算、reject queue 管理（Spec 5 が所管）
  - Frontmatter フィールドの汎用 vocabulary 定義（Spec 1 が所管。本 spec は skill 固有 frontmatter のみ所管）
  - Skill export / import（v2 MVP 外、将来拡張、Requirement 11.5 と整合）
  - **version up 操作**（v2 MVP 外、Requirement 1.5 / Requirement 3.1 と整合、改版時は新規 skill 名で install することを基本方針とする）
  - **Skill ファイルへの `update_history` field 適用**（v2 MVP 外、Requirement 3.6 と整合、Skill lifecycle 履歴は `decision_log.jsonl` の Skill 起源 4 種 = `skill_install` / `skill_deprecate` / `skill_retract` / `skill_archive` で網羅、Spec 5 Requirement 11.2 / Spec 7 Requirement 12.7 と整合）
- **Adjacent expectations**:
  - **Spec 2 ↔ Spec 5**: 本 spec は Graph 抽出 skill（`relation_extraction` / `entity_extraction`）の出力 schema を確定する。Spec 5 は当該 schema を入力 contract として validation 実装と ledger への永続化を担う（Spec 5 Requirement 3.5 / 4.5 / 19.2 と整合）。本 spec が schema を変更する場合は Spec 5 を先行して再合意する。
  - **Spec 2 ↔ Spec 3**: 本 spec は skill カタログ（initial 15 種）と各 skill の `applicable_categories`（L3 wiki content category）および `applicable_input_paths`（L1 raw 入力 path glob、Requirement 3.2 と整合）を提供する。Spec 3 は当該カタログを入力として、content type / 入力 path に応じた skill 選択ロジック（`applicable_categories` による L3 category マッチ + `applicable_input_paths` による L1 raw path マッチの 2 系統）を構築する。
  - **Spec 2 ↔ Spec 4**: `rw skill draft / test / install / list / show` の CLI dispatch（引数 parse、対話 confirm、結果整形、exit code）は Spec 4 の所管とし、本 spec は各 subcommand の入出力契約と内部処理（candidate 生成、validation、install 移動）のみ所管する。**対話ログ markdown ファイルの frontmatter スキーマ規定**は本 spec が SSoT として所管し（Requirement 15）、Spec 4（Requirement 1.8）は当該スキーマに従う保存実装と保存先 path 規約を所管する責務分離とする。
  - **Spec 2 ↔ Spec 7**: Skill の deprecate / retract / archive 状態遷移は Spec 7 が所管する。本 spec は frontmatter の `status` フィールドが取り得る 4 値（`active / deprecated / retracted / archived`）の定義と install 時の初期値（`active`）のみ所管する。
  - **Spec 2 ↔ Spec 6**: Spec 6 は perspective / hypothesis 生成スキルを skill ファイルとして定義し、本 spec の 8 section スキーマと frontmatter 規約に従う。skill 自体の prompt 内容は Spec 6 所管、構造規約は本 spec 所管。

## Requirements

### Requirement 1: AGENTS/skills/ ディレクトリ構造と命名規約

**Objective:** As a Spec 3 / Spec 4 / Spec 6 起票者, I want skill ファイルが置かれるディレクトリと命名規約が固定されている, so that skill discovery / dispatch / 表示で path を一意に解決できる。

#### Acceptance Criteria

1. The Skill Library shall standard skill を `AGENTS/skills/<skill_name>.md` という単一ディレクトリ配置とし、サブディレクトリによる分類を導入しないことを規定する。
2. The Skill Library shall skill 名（`<skill_name>`）を snake_case の ASCII 文字列とし、frontmatter `name` フィールドとファイル名（拡張子除く）が完全一致することを規定する。
3. If skill ファイル名と frontmatter `name` が一致しない skill が AGENTS/skills/ 配下に存在する, then the Skill Validator shall ERROR severity で報告し、当該 skill を読み込み対象から除外することを規定する。
4. The Skill Library shall skill candidate を `review/skill_candidates/<skill_name>.md` に配置し、install を経て初めて `AGENTS/skills/` に移動されることを規定する。
5. While skill 名の衝突（既存 standard / custom skill と同名の draft / install）が検出される場合, the Skill Validator shall ERROR severity で操作を拒否し、改名または改版時の対処（同名 skill の上書き install は不可、改版時は新規 skill 名で install することを基本方針とする。version up 操作は v2 MVP 外として本 spec では扱わない）を求めることを規定する。

### Requirement 2: Skill ファイルの 8 section スキーマ

**Objective:** As a custom skill 作成者および skill 利用者, I want すべての skill ファイルが 8 section の固定構造を持つ, so that 任意 skill が同じ手順で読解・dry-run・lifecycle 管理できる。

#### Acceptance Criteria

1. The Skill Library shall すべての skill ファイル（standard / custom 共通）が以下 8 section を見出し（`##` レベル）として順に保持することを規定する：(1) Purpose / (2) Execution Mode / (3) Prerequisites / (4) Input / (5) Output / (6) Processing Rules / (7) Prohibited Actions / (8) Failure Conditions。
2. The Skill Library shall 各 section の役割を以下のとおり定義することを規定する。
   - **Purpose**: skill の目的を 1〜3 文で記述
   - **Execution Mode**: interactive / batch / hybrid のいずれかと、対話深度を記述
   - **Prerequisites**: skill 実行前に成立すべき入力ファイル / vocabulary / 他 skill の状態を列挙
   - **Input**: 受け取る入力の形式・必須フィールド・制約を記述
   - **Output**: 生成する出力の形式・必須フィールド・出力先（review/synthesis_candidates/ など）を記述
   - **Processing Rules**: 出力生成時に LLM が守るべき変換規則・抽出規則・要約原則を列挙
   - **Prohibited Actions**: skill が行ってはならない操作（無根拠生成・evidence 改変・他 skill の領分介入など）を列挙
   - **Failure Conditions**: 出力生成失敗時の判定基準と次のアクション（再試行 / ERROR で停止 / candidate 廃棄など）を記述
3. If skill ファイルに 8 section のうち 1 つでも欠落している, then the Skill Validator shall ERROR severity で報告し、当該 skill の install を拒否することを規定する。
4. While Failure Conditions section を記述する場合, the Skill Library shall 各 failure に対する「次のアクション」欄（再試行可否、人間判断要否、candidate 廃棄の有無）を必須項目として規定する（§7.3 で明文化された原則と整合）。
5. The Skill Library shall 8 section 以外の追加 section（例: Examples / Notes / Changelog）を任意で持つことを許容するが、validation 対象は 8 section のみであることを規定する。

### Requirement 3: Skill frontmatter スキーマ

**Objective:** As a Skill Validator および Spec 3 dispatcher, I want skill frontmatter のフィールドと値域が固定されている, so that 自動 validation と dispatch ロジックが skill メタデータを安全に参照できる。

#### Acceptance Criteria

1. The Skill Library shall skill frontmatter の必須フィールドを以下のとおり規定する。
   - `name`: snake_case 文字列、ファイル名と一致
   - `origin`: `standard` または `custom` のいずれか
   - `version`: 整数（default 1、v2 MVP では install 時 `1` 固定。version up 操作は v2 MVP 外、Requirement 1.5 と整合）
   - `status`: `active` / `deprecated` / `retracted` / `archived` のいずれか（install 直後は `active`）
   - `interactive`: 真偽値（対話型 skill か）
   - `update_mode`: `create` / `extend` / `both` のいずれか
   - `handles_deprecated`: 真偽値（deprecated ページを evidence として使うか）
2. The Skill Library shall optional フィールドとして以下 2 種を許容することを規定する。各 skill は `applicable_categories` / `applicable_input_paths` の片方または両方を指定可能とする。
   - `applicable_categories`（文字列配列、L3 wiki content category 一覧）— 各値は `.rwiki/vocabulary/categories.yml` の `name` field に登録されたカテゴリ名と一致するものとし、許可値外の値は Skill Validator が WARN severity で報告する（Spec 1 Requirement 7.1 / Requirement 10.3 と整合、Spec 1 categories.yml 拡張に追従可能）
   - `applicable_input_paths`（文字列配列、L1 raw 入力 path glob 一覧、例: `raw/llm_logs/**` / `raw/incoming/**`）— L3 category に該当しない L1 raw 入力対象 skill（例: `llm_log_extract` が `raw/llm_logs/` を入力対象とするケース）の dispatch hint を表現する独立 field（Spec 1 brief.md L103 由来 coordination 要求）。glob は **extended glob 互換**（POSIX glob `*` / `?` / `[...]` に加えて `**` recursive match を許容）とし、Skill Validator は path 形式の構文妥当性のみを検査する（実 path の存在検証は dispatch 時の Spec 3 所管）
3. If frontmatter が YAML として parse できない, then the Skill Validator shall ERROR severity で報告し、当該 skill を install / load の対象から除外することを規定する。
4. If `origin` が `standard` / `custom` 以外、または `update_mode` が `create` / `extend` / `both` 以外、または `status` が定義 4 値以外である, then the Skill Validator shall ERROR severity で値域違反を報告することを規定する。
5. The Skill Library shall skill ファイルの初期 install 時の `status` を必ず `active` とし、`deprecated` / `retracted` / `archived` への遷移は Spec 7 lifecycle 操作のみが行えることを規定する（本 spec では遷移を実装しない）。
6. The Skill Library shall Skill ファイルには `update_history` field を v2 MVP では適用しないことを規定する。Skill の lifecycle 履歴は `decision_log.jsonl` の Skill 起源 4 種（`skill_install` / `skill_deprecate` / `skill_retract` / `skill_archive`、Spec 5 Requirement 11.2 / Spec 7 Requirement 12.7 と整合）で網羅し、wiki page frontmatter `update_history` field（Spec 1 Requirement 3.6 が規定、Spec 7 Requirement 3.8 が page lifecycle 起源で運用）を Skill ファイルに適用しない。本規定により Skill 履歴管理を `decision_log.jsonl` に single source of truth として集約する。Skill `update_history` の必要性が将来発生した場合は v2 MVP 後の Adjacent Spec Synchronization で本 spec を改版する手順を採る。

### Requirement 4: 初期 skill 群（知識生成 12 種）

**Objective:** As a Spec 3 / Spec 4 / Spec 6 起票者, I want distill タスク向けの知識生成 skill が初期セットとして 12 種揃っている, so that ユーザーが追加 custom skill なしで主要な content type を distill できる。

#### Acceptance Criteria

1. The Skill Library shall 知識生成 skill として以下 12 種を `origin: standard` で初期配布することを規定する。
   - `paper_summary` — 論文要約（Abstract / Method / Findings / Critique）
   - `multi_source_integration` — 複数論文統合（統合概念ページ）
   - `cross_page_synthesis` — wiki 横断 synthesis（wiki/synthesis/ 候補）
   - `personal_reflection` — 個人ノート・内省（Observation / Interpretation / Action）
   - `llm_log_extract` — LLM 対話ログ抽出（Summary / Decision / Reason / Alternatives / Reusable Pattern）
   - `narrative_extract` — 物語・事例から教訓（初期状態 / 選択 / 制約 / 試練 / 結果 / 本質 / 一般化）
   - `concept_map` — 概念説明（Core Idea / Related Concepts / Examples / Applications）
   - `historical_analysis` — 歴史的文書（Context / Events / Causes / Consequences / Significance）
   - `code_explanation` — コード（Purpose / Pattern / Caveats / Reusability）
   - `entity_profile` — 人物・ツール紹介（Who / What / Context / Relationships）
   - `interactive_synthesis` — 対話型 synthesis（user 視点反映の wiki ページ候補）
   - `generic_summary` — 汎用 fallback（自由形式 + WARN）
2. The Skill Library shall 12 種の知識生成 skill それぞれが Requirement 2 の 8 section スキーマと Requirement 3 の frontmatter スキーマを完全に満たすことを規定する。
3. The Skill Library shall 知識生成 skill の出力先を `review/synthesis_candidates/` 配下とし、各 candidate の `target` および `update_type` フィールドの取り扱いは Spec 1（frontmatter スキーマ）所管である旨を skill ファイル内で参照することを規定する。
4. Where ある content の type が既存 11 種の専門 skill のいずれにも該当しない場合に, the Skill Library shall `generic_summary` を fallback として提供し、生成出力に WARN マーカーを付与して人間レビューを促すことを規定する。

### Requirement 5: 初期 skill 群（Graph 抽出 2 種）と Spec 5 連携

**Objective:** As a Spec 5 起票者, I want Graph 抽出 skill 2 種（`entity_extraction` / `relation_extraction`）が固定の出力 schema を持つ, so that Spec 5 が schema validation と ledger 永続化を独立に実装できる。

#### Acceptance Criteria

1. The Skill Library shall Graph 抽出 skill として以下 2 種を `origin: standard` で初期配布することを規定する。
   - `entity_extraction` — 文書から entity（人物・概念・手法）を抽出
   - `relation_extraction` — entity ペアから typed relation を抽出（GraphRAG-inspired 2-stage）
2. The Skill Library shall `entity_extraction` skill の出力 schema を以下フィールドの JSON 配列として規定する：`name` / `canonical_path` / `entity_type`（`entity_types.yml` の値）/ `aliases` / `evidence_ids`（Spec 5 Requirement 3.5 / Spec 1 Requirement 2.3 と整合）。
3. The Skill Library shall `relation_extraction` skill の出力 schema を以下フィールドの JSON 配列として規定する：`source` / `type` / `target` / `extraction_mode`（`explicit` / `paraphrase` / `inferred` / `co_occurrence` のいずれか）/ `evidence`（`quote` + `span` + `source_file`）（Spec 5 Requirement 4.5 と整合）。
4. The Skill Library shall Graph 抽出 skill の出力先を `review/relation_candidates/` 配下とし、当該 candidate を Spec 5 が `edges.jsonl` / `entities.yaml` に永続化する前段の human reject filter を経由することを skill ファイル内で参照することを規定する（§7.2 Spec 2 と整合）。
5. The Skill Library shall Graph 抽出 skill の出力 schema 自体（フィールド名・値域・必須性）を本 spec が SSoT として確定し、Spec 5 が当該 schema を入力 contract として validation 実装する責務分離を skill ファイルおよび本 requirements に明記することを規定する（Spec 5 Requirement 19.2 と整合）。
6. If 本 spec が Graph 抽出 skill の出力 schema を変更する必要が生じた, then the Skill Library shall 変更を Spec 5 と先行合意した上でしか反映できない手順（roadmap.md「Adjacent Spec Synchronization」運用ルール）を skill ファイルおよび本 requirements に参照点として残すことを規定する。
7. The Skill Library shall Graph 抽出 skill の Failure Conditions section に「schema validation 不通過時は当該 entity / edge を candidate に採用せず ERROR で報告する」旨を必須記載することを規定する。

### Requirement 6: 初期 skill 群（lint 支援 1 種）

**Objective:** As a Scenario 26 ユーザー, I want lint FAIL 時に frontmatter 不足を補完提案する skill が存在する, so that `rw lint --fix` が滞留 incoming を効率的に修復できる。

#### Acceptance Criteria

1. The Skill Library shall lint 支援 skill として `frontmatter_completion` を `origin: standard` で初期配布することを規定する。
2. The Skill Library shall `frontmatter_completion` skill の Input section に「lint FAIL となった markdown ファイルパスと FAIL 理由」を必須入力として規定し、Output section に「補完提案 frontmatter（YAML 文字列）と確信度」を出力フォーマットとして規定する。
3. While `frontmatter_completion` の出力を採用する場合, the Skill Library shall 採用判断（提案採用 / 棄却 / 部分採用）が `decision_log.jsonl` に記録される対象であることを skill ファイルで参照することを規定する（Scenario 26 / Spec 5 Requirement 11 と整合、永続化は Spec 5 所管）。
4. The Skill Library shall `frontmatter_completion` を `interactive: true` として配布し、ユーザー対話による採否判断を前提とすることを規定する。

### Requirement 7: Custom skill 作成フロー（draft / test / install）

**Objective:** As a custom skill 作成者, I want `rw skill draft / test / install` の 7 段階対話フローが既存スキルでカバーできない出力パターンの skill 化を可能にする, so that ユーザーが固有の content type に応じた skill を自前で追加できる。

#### Acceptance Criteria

1. The Skill Authoring Workflow shall custom skill 作成を以下 7 段階の対話フローとして規定する（Scenario 20 と整合）。
   - (1) 意図確認（既存ベース利用 `--base` か、ゼロから作成か）
   - (2) 情報収集（8 section の各項目を埋めるための質問）
   - (3) 草案生成（`review/skill_candidates/<skill_name>.md` に書き出し）
   - (4) Validation（YAML / 8 section / 衝突 / 参照整合性）
   - (5) Dry-run（テストサンプル入力で出力生成を試行）
   - (6) 修正ループ（不備があれば 4-5 を繰り返し）
   - (7) Install（`AGENTS/skills/<skill_name>.md` に配置）
2. When `rw skill draft <name>` が呼び出された, the Skill Authoring Workflow shall `review/skill_candidates/<name>.md` を新規生成し、`status: draft` / `dry_run_passed: false` を frontmatter 初期値として設定することを規定する。
3. When `rw skill draft <name> --base <existing_skill>` が呼び出された, the Skill Authoring Workflow shall 既存 skill の 8 section を template として candidate に複製し、`base: <existing_skill>` を frontmatter に記録することを規定する。
4. When `rw skill test <candidate-or-name> [--sample <file>]` が呼び出された, the Skill Authoring Workflow shall 当該 candidate に対して入力サンプルで dry-run を実行し、成功時に candidate の frontmatter `dry_run_passed` を `true` に更新することを規定する。LLM CLI 呼び出しの timeout（Foundation Requirement 11 で必須化）/ crash / 出力 schema 違反 / その他 dry-run 内部例外で dry-run が失敗した場合, the Skill Authoring Workflow shall `dry_run_passed` を `false` のまま維持し、ERROR severity で失敗種別（`timeout` / `crash` / `output_error` 等）と原因を report することを規定する。
5. When `rw skill install <candidate>` が呼び出された, the Skill Authoring Workflow shall Requirement 9 の install validation を全件通過した場合に限り candidate を `AGENTS/skills/<name>.md` に移動し、frontmatter `origin` を `custom`、`status` を `active`、`version` を `1` に確定することを規定する。
6. If `rw skill install <candidate>` 実行時に candidate の `dry_run_passed` が `false` である, then the Skill Authoring Workflow shall ERROR severity で install を拒否し、Requirement 8 の dry-run 必須化を理由として提示することを規定する。
7. The Skill Authoring Workflow shall custom skill のサブカテゴリ（Scenario 35 由来の reject 学習 skill 等）も同じ 7 段階フローで作成可能とすることを規定する（Scenario 20 v0.7 軽微更新と整合）。

### Requirement 8: Install 前 dry-run 必須化

**Objective:** As a Skill Validator, I want すべての custom skill install が直前に最低 1 回の dry-run 成功を要求する, so that 動作未確認の skill が AGENTS/skills/ に紛れ込まない。

#### Acceptance Criteria

1. The Skill Authoring Workflow shall `rw skill install <candidate>` 実行前に、当該 candidate に対する `rw skill test` の成功実績（candidate frontmatter `dry_run_passed: true`）が最低 1 回存在することを必須要件として規定する。
2. If candidate の最終修正以降に dry-run が再実行されていない（修正後 `dry_run_passed` が `false` にリセットされている）, then the Skill Authoring Workflow shall install を拒否し、再 dry-run を要求することを規定する。
3. While candidate ファイルが Validation 段階で修正される場合, the Skill Authoring Workflow shall 修正と同時に frontmatter `dry_run_passed` を `false` にリセットすることを規定する（修正後の再 dry-run 強制のため）。
4. The Skill Authoring Workflow shall standard skill（`origin: standard`）の `rw init` 配布時には dry-run 必須化を適用しないことを規定する（Rwiki 配布側で品質保証済を前提とするため）。

### Requirement 9: Install validation（8 section / YAML / 衝突 / 参照整合性）

**Objective:** As a Skill Validator, I want install 時に 4 種の validation が全て通過した場合のみ skill を AGENTS/skills/ に配置する, so that 不正な skill が dispatch / 実行で連鎖障害を起こさない。

#### Acceptance Criteria

1. The Skill Validator shall install 時に以下 4 種 validation を全て実行することを規定する。
   - **(a) 8 section 完備**: Requirement 2.1 の 8 section が全て存在すること
   - **(b) YAML 妥当**: frontmatter が YAML として parse 可能で、Requirement 3.1 の必須フィールドが全て揃い、値域が Requirement 3.4 を満たすこと
   - **(c) 名前衝突なし**: `AGENTS/skills/<name>.md` が既存しないこと（同名 standard / custom skill が既に install 済でないこと）
   - **(d) 参照整合性**: skill 内で参照される vocabulary（`entity_types.yml` 等）/ 出力先（`review/<dir>/`）/ 他 skill 名が実在または将来配置先として明記された path であること
2. If 4 種 validation のいずれか 1 つでも失敗した, then the Skill Validator shall ERROR severity で install を拒否し、失敗した validation 種別と該当箇所を report することを規定する。
3. The Skill Validator shall validation 失敗時に candidate ファイルを `review/skill_candidates/` に残置し、ユーザーが修正後に再 install を試行できる状態を保つことを規定する。
4. The Skill Validator shall `rw skill install` を `dangerous_op category: 中`（推奨対話）として位置付け、validation 通過後も install 直前に 1-stage confirm を経ることを規定する（§8.4 / §2.5 Simple dangerous op に整合、対話深度の正確な仕様は Spec 4 所管）。
5. The Skill Validator shall standard skill 配布（`rw init`）時にも同等の 4 種 validation を実行することを規定する（Rwiki 自体の配布パッケージ整合性検査として）。
6. The Skill Validator shall install operation（candidate → `AGENTS/skills/<name>.md` 移動 + candidate ファイル削除、Requirement 7.5 / Requirement 12.4 と整合）を atomic に実行することを規定し、process kill / disk full / OOM 等で操作中断された場合は元の状態（candidate 残置 / `AGENTS/skills/` 未配置）に復帰することを保証する。具体的な atomic 機構（atomic rename / tmp file / 2-phase commit 等）は design phase で確定する（Foundation Requirement 11.5 / Spec 5 Requirement 7.11 が規定する atomic 操作と整合パターン）。

### Requirement 10: `update_mode: extend` と差分マーカー

**Objective:** As a custom skill 作成者および Spec 7 起票者, I want 既存 wiki ページを拡張する skill が差分マーカー HTML コメント形式で出力する, so that `rw approve` が新規生成と既存拡張を一貫した手順で扱える。

#### Acceptance Criteria

1. The Skill Library shall `update_mode: create` の skill が新規 wiki / synthesis ページを `review/synthesis_candidates/` に生成することのみを許容し、既存ページの差分出力を行わないことを規定する。
2. The Skill Library shall `update_mode: extend` の skill が既存 wiki ページに対する差分（追記 / 修正）を HTML コメント形式の差分マーカーで囲んで出力することを規定する。
3. The Skill Library shall `update_mode: both` の skill が新規生成と既存拡張の両方を出力可能とし、各候補ファイルの frontmatter `update_type` で create / extension / refactor / deprecation-reference 等を識別することを規定する（Spec 1 frontmatter 所管と整合）。
4. While `update_mode: extend` の skill が出力する差分マーカーを記述する場合, the Skill Library shall 開始マーカー（`<!-- rw:extend:start ... -->`）と終了マーカー（`<!-- rw:extend:end -->`）を必ず対で出力することを規定する。マーカー内部の attribute（`target` / `reason` 等）の詳細仕様は Spec 7 lifecycle merge 仕様と整合させる。
5. If `update_mode: extend` の skill 出力に開始マーカーまたは終了マーカーが欠落している, then the Skill Validator shall dry-run 段階で ERROR severity で報告し、`dry_run_passed` を `false` のまま維持することを規定する。

### Requirement 11: `origin: standard | custom` の区別と `rw init` 配布

**Objective:** As a Rwiki 利用者および Spec 4 起票者, I want `rw init` で配布される skill が standard 15 種に限定され、custom skill はユーザー作成 install のみで AGENTS/skills/ に追加される, so that 配布パッケージの整合性とユーザー拡張の境界が明確になる。

#### Acceptance Criteria

1. The Skill Library shall `origin: standard` の skill を Rwiki 配布パッケージに同梱し、`rw init` 実行時に `AGENTS/skills/` に展開することを規定する。
2. The Skill Library shall `origin: custom` の skill を `rw init` の配布対象から除外し、ユーザーが `rw skill draft / test / install` を経由してのみ追加できることを規定する。
3. The Skill Library shall standard skill の初期配布数を Requirement 4 / 5 / 6 の合計 15 種（知識生成 12 + Graph 抽出 2 + lint 支援 1）として固定することを規定する。
4. If standard skill が install 後にユーザーによってファイル編集された, then the Skill Library shall 当該 skill の `origin` を `custom` に変更することなく `standard` のまま保持し、ユーザー編集は次回 `rw init --reinstall` 等の挙動仕様（Spec 4 所管）で扱うことを規定する。
5. The Skill Library shall skill export / import を v2 MVP 外として位置付け、本 requirements で当該機能の振る舞いを規定しないことを明示する。
6. The Skill Library shall `rw init` 配布完了後に standard skill 15 種（Requirement 4 / 5 / 6 の合計）が `AGENTS/skills/` に揃っていることを配布完整性 check として検証し、`generic_summary` を含む不在 skill があれば ERROR を発行することを規定する（Spec 3 の `generic_summary` fallback の前提を確保するため）。

### Requirement 12: `review/skill_candidates/` 層の frontmatter

**Objective:** As a Skill Authoring Workflow および Spec 1 起票者, I want skill candidate の frontmatter フィールドが固定されている, so that draft → test → install の進行状態を frontmatter で一意に追跡できる。

#### Acceptance Criteria

1. The Skill Library shall `review/skill_candidates/<name>.md` の frontmatter 必須フィールドを以下のとおり規定する。
   - `name`: skill 名（snake_case、install 後の `AGENTS/skills/<name>.md` ファイル名と一致）
   - `base`: 既存 skill 名または `null`（`--base` 未指定時は `null`）
   - `status`: `draft` / `validated` のいずれかの 2 値（drafts §5.7 が記述する `approved` 値は本 spec では採用しない。理由: dry-run 通過記録は `dry_run_passed` フラグが独立軸で担うため、`status` 軸で同じ概念を重複させる必要がない。drafts §5.7 を `draft / validated` の 2 値に絞る Adjacent Sync を本 spec から要請する）
   - `dry_run_passed`: 真偽値（最終修正以降に dry-run が成功しているか、Requirement 7.4 / Requirement 8 と整合）
2. When candidate が新規生成される, the Skill Library shall `status: draft` / `dry_run_passed: false` を初期値として設定することを規定する。
3. When validation（Requirement 9 の (a)〜(d)）が全件通過した, the Skill Library shall candidate frontmatter `status` を `validated` に更新することを規定する。
4. When candidate が install 完了によって `AGENTS/skills/` に移動された, the Skill Library shall 当該 candidate ファイルを `review/skill_candidates/` から削除することを規定する（履歴は `decision_log.jsonl` の `decision_type: skill_install` で保全。`skill_install` は Spec 7 が `record_decision()` 経由で記録する Skill 起源 decision_type の一種として宣言、`decision_log.jsonl` schema 自体は Spec 5 所管、Spec 5 Requirement 11.2 / Spec 7 Requirement 12.7 と整合）。
5. If candidate frontmatter の必須 4 フィールドのいずれかが欠落・型違反している, then the Skill Validator shall ERROR severity で当該 candidate を install 候補から除外することを規定する。

### Requirement 13: `rw skill` subcommand 振る舞い契約

**Objective:** As a Spec 4 起票者, I want `rw skill` subcommand 群の振る舞い契約（入出力・状態遷移）が本 spec で固定されている, so that Spec 4 が引数 parse / 結果整形 / exit code 制御を独立に設計できる。

#### Acceptance Criteria

1. The Skill Library shall `rw skill list` を「現存する全 skill（`AGENTS/skills/` 配下、`status: active` 以外も含む）の `name` / `origin` / `status` / `version` を返す」操作として規定する。
2. The Skill Library shall `rw skill show <name>` を「指定 skill の frontmatter 全フィールドと 8 section の本文を返す」操作として規定する。
3. The Skill Library shall `rw skill draft <name> [--base <skill>]` を Requirement 7.2 / 7.3 の振る舞いとして規定する。
4. The Skill Library shall `rw skill test <candidate-or-name> [--sample <file>]` を Requirement 7.4 / Requirement 8 の dry-run 振る舞いとして規定する。
5. The Skill Library shall `rw skill install <candidate>` を Requirement 7.5 / Requirement 9 の validation + 配置振る舞いとして規定する。
6. The Skill Library shall `rw skill deprecate <name>` / `rw skill retract <name>` を Spec 7 lifecycle 所管とし、本 spec では当該 subcommand 名の存在のみを認知し振る舞いを規定しないことを明示する。
7. While `rw skill` 各 subcommand の引数 parse / 出力整形 / exit code を規定する場合, the Skill Library shall 当該責務を Spec 4 所管とし、本 spec は内部の振る舞い契約のみを所管することを規定する。
8. The Skill Library shall write 系の `rw skill` 操作（`rw skill draft` / `rw skill test` / `rw skill install`）の実行時に **Foundation Requirement 11.5 が規定する `.rwiki/.hygiene.lock` を取得** することを Spec 4 への coordination 要求として明示する（Spec 1 Requirement 8.14 / Spec 5 Requirement 17 と同パターン）。これにより Hygiene batch / vocabulary 操作 / 他 skill install との並行衝突を排他制御し、`AGENTS/skills/` ディレクトリの整合性および applicable_categories 値域の参照整合性（Requirement 3.2 / Spec 1 Requirement 7.1 と整合）を保証する。`rw skill list` / `rw skill show` は read-only 操作のため lock 取得対象外とする。具体的な lock 取得 / 解放 / timeout / deadlock 検出ロジックは Spec 4 / Spec 5 の design phase で確定する（Spec 1 Requirement 8.14 と同パターン）。

### Requirement 14: Foundation 規範への準拠と SSoT 整合

**Objective:** As a Spec 0 規範遵守者および将来の更新者, I want 本 requirements が Foundation の用語・原則・SSoT 出典に準拠する, so that spec 横断の整合性が損なわれない。

#### Acceptance Criteria

1. The Skill Library shall 本 requirements の用語使用を Spec 0 Foundation の用語集 5 分類（特に「Skill」「Custom skill」「Skill candidate」「Review layer」「Dry-run」）と整合させ、独自の再定義・再命名を行わないことを規定する。
2. The Skill Library shall 本 requirements を日本語で記述し、`spec.json.language=ja` および CLAUDE.md「All Markdown content written to project files MUST be written in the target language」要件に準拠することを規定する。
3. While 本文中で表形式を用いる場合, the Skill Library shall 表は最小限に留め、長文・解説は表外の箇条書きまたは段落で記述することを規定する。
4. The Skill Library shall 本 requirements の各記述項目について SSoT 出典（`.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §2.8 / §5.6 / §5.7 / §7.2 Spec 2 / §11.2）を辿れるよう参照点を残すことを規定する。
5. If SSoT が改版された場合に本 requirements の更新が必要となる, then the Skill Library shall 自身の更新が roadmap.md「Adjacent Spec Synchronization」運用ルールに従い、`spec.json.updated_at` 更新と markdown 末尾 `_change log` への追記で足りる旨を参照点として残すことを規定する。
6. The Skill Library shall 本 requirements が定める 15 個の Requirement の各々について、design 段階で「Boundary Commitments」として境界が再確認されることを前提とし、本 requirements の境界（in scope / out of scope / adjacent expectations）を design phase に渡せる形で固定することを規定する。

### Requirement 15: 対話ログ frontmatter スキーマと Interactive skill 連携

**Objective:** As a Spec 4 起票者および Interactive skill (`interactive_synthesis` / `frontmatter_completion` / `llm_log_extract` 等) 利用者, I want 対話ログ markdown ファイルの frontmatter スキーマと skill 連携が本 spec で SSoT として確定されている, so that Spec 4（rw chat 保存実装）と Spec 6（perspective / hypothesis 対話 trigger）が独立に実装できる。

#### Acceptance Criteria

1. The Skill Library shall 対話ログ markdown ファイル（例: `raw/llm_logs/chat-sessions/<timestamp>-<session-id>.md` および `raw/llm_logs/interactive-<skill>-<timestamp>.md`）の frontmatter 必須フィールドを以下 5 種として固定することを規定する: `type`（固定値 `dialogue_log`）/ `session_id` / `started_at`（ISO 8601）/ `ended_at`（ISO 8601、進行中は省略可）/ `turns`（対話ターン数の整数）。Spec 4 Requirement 1.8 と整合。
2. The Skill Library shall 対話ログ markdown フォーマットの詳細仕様（Turn 表現の内部構造、auto-save の append 単位、speaker / content / timestamp 等の Turn 内部 schema、対話ログ保存先の命名規則とディレクトリ構造の確定（drafts §2.11 内に subdirectory 形式 `chat-sessions/` / `interactive/` / `manual/` 区別と、ファイル名形式 `interactive-<skill>-<timestamp>.md` の表記揺れが混在しており design phase で一意化が必要）、frontmatter 任意フィールドの拡張規約）を design phase 持ち越し項目として位置付け、本 requirements は SSoT 出典（drafts §2.11 / Scenario 15 / Scenario 25）への参照点のみを残すことを規定する。
3. The Skill Library shall Skill frontmatter（Requirement 3）の任意フィールドとして `dialogue_guide` および `auto_save_dialogue` の 2 種を許容することを規定し、`interactive: true` の skill が動的質問生成および対話ログ自動保存を制御するためのメタデータであることを明示する（drafts §2.11 / L341 と整合）。各フィールドの値域・運用詳細は design phase で確定する。
4. While 対話ログを生成または依拠する skill（`interactive_synthesis` / `frontmatter_completion` / `llm_log_extract` 等）を扱う場合, the Skill Library shall 当該 skill ファイルの Output section または Input section に対話ログ frontmatter スキーマ（AC 1）への参照点を必須記載することを規定する。
5. The Skill Library shall 対話ログ frontmatter スキーマ（AC 1）を本 spec が SSoT として確定し、Spec 4（Requirement 1.8 が定める保存実装と保存先 path 規約）/ Spec 6（保存タイミングと append 単位の trigger 起票時に確認）が当該スキーマに従う責務分離を明示することを規定する。本スキーマを変更する必要が生じた場合は roadmap.md「Adjacent Spec Synchronization」運用ルールに従い Spec 4 / Spec 6 への波及同期を行う。

---

_change log_

- 2026-04-26: 初版生成（v0.7.12 SSoT を基に Spec 2 全 14 Requirement を P0-P4 マーカー付きで定義、AC 数 75）
- 2026-04-27: 5 ラウンドレビュー反映 + 厳しく再精査 + approve（致命級 4 件 + 重要級 8 件 + 軽微 5 件、深掘り検討 + 自動採択方針で適用、AC 数 75 → 83、Requirement 数 14 → 15）。
  - **致-1 (第 1 R)**: R5.2 entity_extraction schema field `type` → `entity_type` 統一（Spec 1 R2.3 / Spec 5 R3.5 整合）
  - **致-2 (第 1 R)**: 新 R15「対話ログ frontmatter スキーマと Interactive skill 連携」追加（AC 5 件、Spec 4 R1.8 由来 coordination 要求の SSoT 確定）+ R14.6「14 → 15 個」+ Boundary Context Spec 2 ↔ Spec 4 拡張 + brief.md「Design phase 持ち越し項目」新設
  - **重-1 (第 1 R)**: R3.2 applicable_categories 値域に Spec 1 categories.yml SSoT 参照追加、許可値外は WARN
  - **重-2 (第 1 R)**: R12.4 `decision_type: skill_install` 所管を Spec 7 R12.7 / Spec 5 R11.2 経由で宣言と明示。Spec 5 R11.2 を 21 → 22 種化、Spec 7 R12.7 を Skill 起源 4 種化（Adjacent Sync 実施）
  - **重-3 (第 1 R)**: R1.5 / R3.1 で version up を v2 MVP 外と明示
  - **第 1 R 精査**: R15.2 命名規則記述の整理（drafts §2.11 表記揺れ明示）
  - **致-1 (第 3 R)**: R12.1 skill candidate `status` 値域を 3 → 2 値（`draft` / `validated`）に絞り、drafts §5.7 への Adjacent Sync を要請
  - **重-1 (第 4 R)**: R9.6 新設で install operation の atomic 性原則を追加（Foundation R11.5 / Spec 5 R7.11 と整合パターン）
  - **重-2 (第 4 R)**: R13.8 新設で write 系 `rw skill` 操作の `.rwiki/.hygiene.lock` 取得を Spec 4 への coordination 要求として明示（Spec 4 R10.1 を Adjacent Sync で対応）
  - **重-3 (第 4 R)**: R7.4 拡張で dry-run failure handling（timeout / crash / output_error）を明示
  - **重-1 (第 5 R)**: R3.2 拡張で `applicable_input_paths` 任意 field 新設（L1 raw 入力 skill 用 dispatch hint、Spec 1 brief.md L103 由来 coordination 解決）+ Boundary Context Spec 2 ↔ Spec 3 の dispatch logic 2 系統化
  - **第 5 R 再精査連鎖更新**: Boundary Context In scope / brief.md Scope.In に optional 4 種列挙の連鎖更新漏れ修正
  - **重-1 (厳しく再精査)**: R3.2 「POSIX glob 互換」と例示 `**` の矛盾を解消、「extended glob 互換」に修正
  - **軽-B (厳しく再精査、案 ii)**: R3.6 新設で Skill ファイルへの `update_history` field 適用を v2 MVP 外と明示。Skill lifecycle 履歴は `decision_log.jsonl` の Skill 起源 4 種に single source of truth として集約。Spec 7 R3.8 を Adjacent Sync で修正、命名不一致 `skill_deprecation` → 削除も同時解消
  - **MVP スコープ整合性**: Boundary Context Out of scope と brief.md Constraints に MVP 外 3 項目（export-import / version up / update_history）を集約列挙
  - **Adjacent Sync**: Spec 1 brief.md（C-1 status 更新）/ Spec 4 R10.1 + Boundary Context（skill 操作 lock 取得追加）/ Spec 5 R11.2 / R11.15 / Phase 表（22 種化）/ Spec 7 R3.8 + R12.7 + Boundary Context（Skill 起源 4 種、cmd_skill_install 追加、update_history MVP 外）の 4 spec へ実施、各 spec.json.updated_at 更新、再 approval 不要
  - approvals.requirements.approved = true、phase = requirements-approved（2026-04-27 ユーザー承認後）
