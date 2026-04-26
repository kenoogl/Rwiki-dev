# Requirements Document

## Project Description (Input)

Rwiki v2 の L3 Curated Wiki は人間承認済 markdown 集合だが、frontmatter スキーマ・カテゴリ体系・タグ vocabulary が固定されないと、各 spec が独自に frontmatter フィールドを使い始め、lint / approve / distill / extract-relations が同じスキーマを前提にできない。Entity 固有のショートカット（`authored:` / `collaborated_with:` / `implements:` 等）の扱いも宙ぶらりんになる。

本 spec（Spec 1、Phase 1）は、`rwiki-v2-foundation`（Spec 0）が固定したビジョン・原則・用語・3 層アーキテクチャ・frontmatter スキーマ骨格に準拠しつつ、L3 Curated Wiki の分類体系基盤を確立する。具体的には、(a) カテゴリディレクトリ構造（強制ではなく推奨パターン、ユーザー拡張可能）、(b) 共通・L3 wiki 固有・review 固有の frontmatter スキーマ、(c) `.rwiki/vocabulary/tags.yml` `categories.yml` `entity_types.yml` のスキーマ、(d) Tag 操作コマンド（`rw tag *`）、(e) lint の vocabulary 統合、(f) L3 frontmatter `related:` を Spec 5 Graph Ledger からの derived cache として位置付ける規約、(g) Entity 固有ショートカット field の宣言、(h) 新規 review 層 `review/vocabulary_candidates/` の責務を定義する。

L3 frontmatter `related:` の正本は Spec 5 の `.rwiki/graph/edges.jsonl`、本 spec は cache 利用と sync 規約のみを定義する。Entity 固有ショートカットは本 spec でスキーマ宣言、内部正規化（typed edge への展開）は Spec 5 の `normalize_frontmatter` API が担うという責務分離を取る。

出典 SSoT: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §5（frontmatter スキーマ全 9 サブセクション）/ §6.2 Tag Vocabulary コマンド / §7.2 Spec 1 / 周辺 §2.2 §2.3 §3.2 §4.5 §9.4。Upstream: `rwiki-v2-foundation` requirements.md（13 中核原則・用語集・Edge/Page status の区別）。

## Introduction

本 requirements は、Rwiki v2 の Spec 1 として L3 Curated Wiki の **分類体系基盤** を定義する。読者は Spec 1 の実装者と、本 spec が固定する frontmatter スキーマ・vocabulary を引用する Spec 3（prompt-dispatch）/ Spec 4（cli-mode-unification）/ Spec 5（knowledge-graph）/ Spec 7（lifecycle-management）の起票者である。

本 spec は **frontmatter スキーマ・vocabulary・Tag 操作 CLI を直接定義する spec** であり、規範文書（Foundation）と異なり実装される機能を含む。したがって本 requirements の各 acceptance criterion は、(a) スキーマ・vocabulary が満たすべき記述要件、(b) `rw tag *` コマンドが満たすべき動作要件、(c) lint が vocabulary を参照する際の動作要件、(d) 周辺 spec との境界・coordination 要件、として記述される。Subject は概ね `the Classification System` または個別コンポーネント（`the rw tag command` / `the lint task` / `the vocabulary store` 等）を用いる。

本 spec の成果物は次の 6 種類に分類される。

- カテゴリディレクトリ構造の推奨パターン定義（L3 wiki 配下の **6 カテゴリ**、`llm_logs` は L1 raw のみで扱う方針、強制せず、ユーザー拡張可能）
- frontmatter スキーマの確定（共通必須・推奨・任意フィールド + `entity_type:` 新設で content 種別と entity 種別を直交分離 / L3 wiki 固有 lifecycle field / review 固有 / Entity 固有ショートカット）
- `.rwiki/vocabulary/` 配下の最小スキーマ（tags / categories / entity_types）と未登録語・エイリアス・非推奨語の severity 規約（`successor` field を tags.yml に含む 6 項目スキーマ、`enforcement` 2 値）
- Tag 操作 CLI 群（`rw tag scan / stats / diff / merge / split / rename / deprecate / register / vocabulary / review`）と vocabulary 操作 approve 時の decision_log 自動記録 (Spec 5 `record_decision()` coordination)
- L3 frontmatter `related:` を Spec 5 からの derived cache として位置付ける sync 規約と、Entity 固有ショートカットのスキーマ宣言（展開ロジックは Spec 5 が所管、shortcut 由来 typed edge と `related:` cache の **完全分離方針**）
- Review レイヤー frontmatter の所管マップ（`vocabulary_candidates/` 新設・`decision-views/` 骨格宣言・`audit_candidates/` / `relation_candidates/` / `Follow-up` を所管 spec へ再委譲）と、`vocabulary_candidates/` の approve 処理を Spec 4 へ拡張要求

Spec 3-7 が本 spec を引用することで、frontmatter フィールド名・vocabulary 整合・Entity ショートカット表記が複数 spec で分岐することを防ぐ。

## Boundary Context

- **In scope**:
  - L3 wiki 配下のカテゴリディレクトリ推奨パターン（`articles` / `papers` / `notes` / `narratives` / `essays` / `code-snippets` の **6 カテゴリ** を初期セットとし、ユーザー拡張可能な仕組み。`llm_logs` は L3 カテゴリから除外し、L1 raw `raw/llm_logs/` のみで扱う — 概念軸統一・L1 同名衝突回避・長期拡張耐性のため）
  - 共通必須フィールド（`title` / `source` / `added`）、推奨フィールド（`type` / `tags`）、任意フィールド（`author` / `date` / `entity_type` 等）の確定（`type` はコンテンツ種別、`entity_type` は entity 種別を表し、別 field として直交させる）
  - L3 wiki ページ固有 frontmatter（`status` / `status_changed_at` / `status_reason` / `successor` / `merged_from` / `merged_into` / `merge_strategy` / `merge_conflicts_resolved` / `related` / `update_history`）の **スキーマ宣言**（lifecycle 操作セマンティクスは Spec 7、edge 正本は Spec 5）
  - Review レイヤー固有 frontmatter（`review/synthesis_candidates/` の `status` / `target` / `update_type` / `reviewed_by` / `approved_at` / `review/vocabulary_candidates/` の `operation` / `target` / `aliases` / `affected_files` / `status`）の宣言
  - Entity 固有ショートカット field（`authored:` / `collaborated_with:` / `mentored:` / `implements:` 等）の **スキーマ宣言** と、entity type 別の field 集合定義
  - `.rwiki/vocabulary/tags.yml` のスキーマ（canonical / description / aliases / deprecated 状態を最小単位として）
  - `.rwiki/vocabulary/categories.yml` のスキーマ拡張（カテゴリ名 + 説明 + 推奨 frontmatter `type:` 値 + Spec 3 が利用する default skill mapping のための field）
  - `.rwiki/vocabulary/entity_types.yml` の最小スキーマ（entity type → 許可されるショートカット field 集合 → typed edge 名のマッピング）
  - Tag 操作 CLI 群（`rw tag scan / stats / diff / merge / split / rename / deprecate / register / vocabulary {list, show, edit} / review`）
  - lint task の vocabulary 統合（未登録タグ / エイリアス使用 / 非推奨タグ の検出、severity は INFO / WARN / WARN）
  - 新規 review 層 `review/vocabulary_candidates/` の責務（vocabulary 変更計画の人間レビュー buffer）
  - L3 frontmatter `related:` を Spec 5 `edges.jsonl` からの derived cache とする規約（cache 利用側の sync 契約のみ、cache invalidation 実装は Spec 5）
- **Out of scope**:
  - Typed edges の正本管理・追加・update・status 遷移（Spec 5 Graph Ledger）
  - L3 frontmatter `related:` cache の実 sync 実装（Spec 5 `rw graph rebuild --sync-related` / Hygiene batch sync）
  - Entity 固有ショートカット field の typed edge への **展開ロジック実装**（Spec 5 の `normalize_frontmatter` API、双方向 edge 自動生成、confidence 0.9 固定等）
  - `.rwiki/vocabulary/relations.yml`（典型 relation 名の vocabulary、Spec 5 所管）
  - Skill 内のタグ自動抽出（Spec 2）
  - Skill 選択ロジック（Spec 3）。本 spec は `categories.yml` に default skill mapping field を **定義する** だけで、参照側の dispatch は Spec 3 が担う
  - Page lifecycle 操作（`rw deprecate` / `rw retract` / `rw archive` / `rw reactivate` 等）の動作。本 spec は `status` 等の field を **宣言する** だけで、操作セマンティクスは Spec 7 が担う
  - Skill ファイル / Skill candidate / Hypothesis candidate / Perspective 保存版の frontmatter（それぞれ Spec 2 / Spec 6 が所管。Foundation §5.6-§5.9.2 で骨格は固定済）
  - L1 raw subdirectory 規約（`raw/incoming/` / `raw/llm_logs/{interactive,chat-sessions,manual}/` / ingest 後カテゴリ展開先 等）の SSoT は steering `structure.md`。本 spec は L3 wiki カテゴリディレクトリ規約のみを所管し、L1 raw 構造の規定は行わない（Foundation Boundary Out of scope と整合）。
- **Adjacent expectations**:
  - 本 spec は Foundation（Spec 0、`rwiki-v2-foundation`）が固定する 13 中核原則 / 用語集 / 3 層アーキテクチャ / Edge status 6 種と Page status 5 種の区別 / Hypothesis status 7 種の独立性 を **唯一の引用元** として参照し、独自定義による再解釈・再命名を行わない。Foundation の用語と矛盾する記述が必要になった場合は先に Foundation を改版し、その後本 spec を更新する（roadmap.md の「Adjacent Spec Synchronization」運用ルールに従う）。
  - Spec 3 は本 spec の `categories.yml` の default skill mapping field と frontmatter `type:` を distill dispatch の手掛かりとして参照する。本 spec は dispatch ロジック自体は持たない。
  - Spec 5 は本 spec が宣言する Entity 固有ショートカット field（`authored:` 等）と `entity_types.yml` の mapping を読み、`normalize_frontmatter(page_path) → List[Edge]` API で typed edge へ展開する。本 spec は宣言と mapping table のみを所管する。
  - Spec 5 は L2 `edges.jsonl` を正本とし、L3 frontmatter `related:` cache を Hygiene batch / `rw graph rebuild --sync-related` で sync する。本 spec は cache が stale になる可能性を許容（eventual consistency）し、cache 鮮度を query / perspective 動作の必須条件にしない。さらに **`related:` cache の stale 検出・警告 UX・stale 期間上限規約は Spec 5（sync 履歴メタデータの管理側、場所・形式は Spec 5 設計）と Spec 6（perspective / hypothesize 利用側、stale age に基づく信頼度表示）が所管** する。本 spec は frontmatter に sync 状態メタデータ field を追加せず（文書メタデータと cache 状態メタデータを別レイヤーに分離する原則、Foundation §2.3 精神と整合）、cache 利用側は Spec 5 が独自管理する sync 履歴メタデータを参照することを規約とする。
  - Spec 5 sync 機構は `related:` cache 生成時に **Entity-specific shortcuts で表現される typed edge を除外するフィルタ** を実装する責務を負う（本 spec Requirement 5.5 / 10.1 と整合）。具体的には、L2 `edges.jsonl` の stable / core edge を `related:` cache に sync する際、source ページの frontmatter shortcut field に該当する edge を除外し、shortcut で表現されない typed edge のみを cache する。
  - Spec 6（perspective / hypothesize 利用側）は **全 typed edge を統合的に閲覧する用途では L2 `edges.jsonl` を Spec 5 Query API（`get_neighbors` / `get_shortest_path` 等）経由で直接参照する** ことを設計原則とする。`related:` cache はあくまで shortcut で表現されない typed edge の補助 cache であり、shortcut field（`authored:` 等）と統合して全 edge を取得する用途には用いない。
  - Spec 4 は本 spec の lint vocabulary 統合規約に従って `rw lint` を実装し、severity 体系（CRITICAL / ERROR / WARN / INFO）を本 spec の出力に揃える。さらに本 spec が自由文字列として規定する `source:` field（Requirement 2.1）の **重複検出・canonical 化支援（同一 paper / DOI / URL / arXiv ID 等の表記揺れ検出と統合提案）は Spec 4 audit task の所管** とし、本 spec は dedup ロジックを規定しない。加えて Spec 4 は **`rw approve` コマンドが本 spec で新設する `review/vocabulary_candidates/*` を扱うように拡張** する責務を負う（本 spec Requirement 4.9）。
  - Spec 7 は本 spec が宣言する `status` / `status_changed_at` / `status_reason` / `successor` / `merged_from` / `merged_into` / `merge_strategy` field のセマンティクス（active / deprecated / retracted / archived / merged の 5 状態間遷移）を実装する。本 spec は field の存在と型のみを規定する。

## Requirements

### Requirement 1: カテゴリディレクトリ構造の推奨パターン

**Objective:** As a Rwiki v2 ユーザーおよび Spec 4 / Spec 7 起票者, I want カテゴリが「強制ディレクトリ」ではなく「推奨パターン」として定義され、ユーザー拡張可能な仕組みである, so that 個人の Vault 構成を柔軟に保ちつつ、Rwiki が想定する典型カテゴリでスキル選択や lint が動作する。

#### Acceptance Criteria

1. The Classification System shall L3 wiki 配下の初期推奨カテゴリとして `articles` / `papers` / `notes` / `narratives` / `essays` / `code-snippets` の **6 カテゴリ** を定義する。`llm_logs` は L3 カテゴリから除外し L1 raw `raw/llm_logs/` のみで扱うこととする（除外理由: (a) 残る 6 カテゴリが全て **content 種別** の概念軸で統一され、`llm_logs` のみ origin 種別となる軸混在を回避、(b) L1 raw `raw/llm_logs/` との同名ディレクトリ衝突による UX 混乱を解消、(c) 将来の origin 起源（音声録音 / AI 画像 / OCR 等）が登場してもカテゴリを増やさず frontmatter `source:` + `tags:` で対応できる長期拡張耐性、(d) LLM 由来 wiki が必要なら他カテゴリ + `tags: [llm-derived]` 等のタグ運用で代替可能）。
2. The Classification System shall カテゴリを「強制ディレクトリ」ではなく「推奨パターン」として位置付け、L3 wiki ページがいずれの推奨カテゴリディレクトリに属していなくても valid とみなす。
3. When ユーザーが `.rwiki/vocabulary/categories.yml` に新規カテゴリエントリを追加した, the Classification System shall そのカテゴリを Rwiki 内蔵カテゴリと同等に扱い、lint および dispatch hint の参照対象に含める。
4. The Classification System shall カテゴリ識別を frontmatter フィールドからの自動推論ではなく、`source:` を含む全フィールドから推論しないこととし、ユーザーがディレクトリ配置で表現する設計を取る。
5. If ある wiki ページが推奨カテゴリディレクトリ外に配置されている, then the lint task shall そのページを INFO severity 以下で扱い、エラーや警告にしない。
6. The Classification System shall カテゴリの強制力（推奨 / 任意）の区別を `categories.yml` のスキーマで宣言可能にし、初期セット **6 カテゴリ** の強制力は「推奨」として登録する。

### Requirement 2: 共通・任意 frontmatter フィールドの確定

**Objective:** As a Spec 2 / Spec 4 / Spec 5 / Spec 7 起票者, I want 全 markdown ファイルに共通の必須・推奨・任意フィールドの集合と意味が確定している, so that lint / approve / distill / extract-relations が同じ前提で frontmatter を解釈できる。

#### Acceptance Criteria

1. The Classification System shall 全 markdown ファイル共通の必須フィールドを `title`（文字列）/ `source`（自由文字列、URL / DOI / meeting ID / 書籍名等）/ `added`（YYYY-MM-DD）の 3 個として固定する。
2. The Classification System shall 推奨フィールドを `type`（**コンテンツ種別**の単一値、`categories.yml.recommended_type` 由来）と `tags`（文字列の配列）として固定し、それぞれの目的を「`type:` は Spec 3 dispatch hint（コンテンツ種別ベースの distill skill 選択）」「`tags:` は多次元分類・検索・audit 用」として明示する。なお entity 種別は本 spec で別途新設する `entity_type:`（Requirement 2.3 参照）で表現し、`type:` は entity 種別を含めない。
3. The Classification System shall 任意フィールドとして `author`（文字列または配列）/ `date`（YYYY-MM-DD、原典発行日）/ `entity_type`（**entity 種別**の単一値、`entity_types.yml.name` 由来、entity ページ（`wiki/entities/**` 配下を含む）では事実上推奨）と、ドメイン固有任意項目（`venue` / `journal` / `doi` / `arxiv_id` / `isbn` 等）が許可されることを宣言する。`entity_type:` を `type:` と別 field に分離する根拠は、コンテンツ種別と entity 種別が概念的に直交し、Spec 3 dispatch / Spec 5 ショートカット展開 / lint がそれぞれ独立に判定可能になるため（本 spec Requirement 11.3 と整合）。
4. The Classification System shall `source:` をカテゴリディレクトリから自動推論しないこととし、ユーザーが明示記入することを前提にする。
5. If ある markdown ファイルが必須フィールド `title` / `source` / `added` のいずれかを欠く, then the lint task shall そのファイルを ERROR として報告する。
6. If ある markdown ファイルが推奨フィールド `type` または `tags` を欠く, then the lint task shall そのファイルを INFO として報告し、ERROR にしない。
7. The Classification System shall `type:` の許可値判定を「`categories.yml.recommended_type` の値集合のみ」、`entity_type:` の許可値判定を「`entity_types.yml.name` の値集合のみ」として **2 系統に分離** し、許可値外の `type:` および許可値外の `entity_type:` をそれぞれ WARN として lint で検出可能にする。

### Requirement 3: L3 wiki ページ固有 frontmatter のスキーマ宣言

**Objective:** As a Spec 7 起票者および Spec 5 起票者, I want L3 wiki ページ固有の lifecycle・関係・履歴 field のスキーマ（field 名・型・許可値）が確定している, so that lifecycle 実装と graph derived cache 実装が同じ field 仕様に依拠できる。

#### Acceptance Criteria

1. The Classification System shall L3 wiki ページ固有 lifecycle field として `status` / `status_changed_at` / `status_reason` を宣言し、`status:` の許可値を `active` / `deprecated` / `retracted` / `archived` / `merged` の 5 値として固定する（Foundation Requirement 5 と整合）。
2. The Classification System shall `status:` のデフォルト値を `active` とし、`status:` 未記載のページを `active` として扱うことを規定する。
3. While `status: deprecated` を記述する場合, the Classification System shall `successor:` field を許可し、その値を 0 個以上の wiki ページ path の配列として宣言する。
4. While `status: merged` を記述する場合, the Classification System shall `merged_from:`（path 配列）/ `merged_into:`（path）/ `merge_strategy:`（文字列、**初期許可値** として `complementary` / `dedup` / `canonical-a` / `canonical-b` / `restructure` の 5 値を宣言。Spec 7 は本 spec を全面改版することなく `merge_strategy:` 値を追加可能とし、追加時は Spec 7 の requirements で新値を宣言した上で Adjacent Spec Synchronization 運用ルール（roadmap.md）に従い本 spec の許可値リストを同期更新する。許可値リストの正本は本 spec、拡張要請は Spec 7 が起点）/ `merge_conflicts_resolved:`（issue / resolution の二項オブジェクト配列）の field を宣言する。
5. The Classification System shall typed edges の derived cache field として `related:` を宣言し、その要素を `target`（wiki path、必須）/ `relation`（typed edge 名、必須）/ `edge_id`（任意、L2 ledger への逆参照）の 3 項目で構成されるオブジェクトとして固定する。
6. The Classification System shall page-level 意味的更新履歴 field として `update_history:` を宣言し、その要素を `date`（YYYY-MM-DD）/ `type`（`extension` / `refactor` / `deprecation` / `merge` 等）/ `summary`（文字列）/ `evidence`（任意、raw path）として宣言する。`update_history` の **生成責務（誰が・いつ追記するか）は各操作所管 spec が担う**: lifecycle 起源（`type: deprecation` / `merge` / `split` / `archive` 等）は Spec 7 が自動追記、synthesis 起源（`type: extension` / `refactor` 等）は Spec 6（perspective / hypothesize / extend 出力時）または Spec 4 distill が自動追記、ユーザー手動編集は許可。本 spec は schema（field 存在・型・要素構造）のみを規定し、各 type 値の正規許可値リストおよび追記トリガは所管 spec が確定する。
7. The Classification System shall L3 wiki ページ固有 field の **セマンティクス（状態遷移ルール / 操作可逆性 / dangerous op 階段）は Spec 7 の所管** であることを明示し、本 spec は field の存在・型・許可値のみを規定することを宣言する。

### Requirement 4: Review レイヤー固有 frontmatter のスキーマ宣言

**Objective:** As a Spec 2 / Spec 6 起票者, I want review レイヤー（`review/synthesis_candidates/` 等）と本 spec 新設の `review/vocabulary_candidates/` の frontmatter スキーマが固定されている, so that 各 review buffer の生成側と approve 側が同じ field 仕様で書き込み・読み取りできる。

#### Acceptance Criteria

1. The Classification System shall `review/synthesis_candidates/*` の frontmatter として `status`（`draft` / `approved`、デフォルト `draft`）/ `target`（昇格予定 wiki path または dir、任意）の 2 field を宣言する。
2. The Classification System shall `review/synthesis_candidates/*` の拡張差分（`rw extend` 出力）向けに `update_type` と `target`（更新対象 wiki page path）field を宣言する。
3. When 任意の review candidate が approve 済みになった, the Classification System shall その frontmatter に `reviewed_by`（文字列）と `approved_at`（YYYY-MM-DD）が追記されることを規定する。
4. The Classification System shall 新規 review 層 `review/vocabulary_candidates/*` の責務を「vocabulary 変更計画（merge / split / rename / deprecate / register）の人間レビュー buffer」として定義する。
5. The Classification System shall `review/vocabulary_candidates/*` の frontmatter として `operation`（`merge` / `split` / `rename` / `deprecate` / `register` の 5 値）/ `target`（canonical tag または vocabulary key、文字列）/ `aliases`（merge 操作時の文字列配列、任意）/ `affected_files`（path 配列）/ `status`（`draft` / `approved`、デフォルト `draft`）の field を宣言する。
6. The Classification System shall Skill ファイル / Skill candidate / Hypothesis candidate / Perspective 保存版の frontmatter は **Foundation Requirement 8 が骨格を委譲した先の各 spec（Spec 2 / Spec 6）が所管** であり、本 spec の対象外であることを明示する。
7. The Classification System shall `review/decision-views/*`（Decision log の Tier 2 markdown timeline 出力先、`_candidates` 命名規則の対象外）の frontmatter 骨格として `decision_id`（参照元 decision ID、必須）/ `tier`（固定値 `2`、Decision visualization Tier marker、必須）/ `period_start`（YYYY-MM-DD、timeline 期間の開始、任意）/ `period_end`（YYYY-MM-DD、timeline 期間の終了、任意）/ `entity`（対象 entity または subject ref、任意）/ `source_decisions`（元になった decision_id の配列、任意）/ `generated_at`（YYYY-MM-DD、生成日時、必須）の 7 field を宣言し、render 実装と出力トリガは Spec 5 の `rw decision render` 等が担うことを明示する（Foundation Requirement 8.4 の Spec 1 委譲を引き受ける）。
8. The Classification System shall Foundation Requirement 8.4 が委譲した review レイヤー所管のうち、本 spec が直接スキーマ宣言しない領域について次の再委譲を明示する: `review/audit_candidates/` の frontmatter は Spec 4（audit task 出力側）が所管 / `review/relation_candidates/` の frontmatter は Spec 5（typed edge 候補生成側）が所管 / Follow-up（`wiki/.follow-ups/`）の frontmatter は Spec 7（Page lifecycle 操作側）が所管。本 spec はそれぞれの所管が Foundation 骨格と本 spec の共通 frontmatter（Requirement 2）に整合する責務を負うことのみを規定する。
9. The Classification System shall 本 spec が新設する `review/vocabulary_candidates/*` の **approve 処理（`status: draft` → `status: approved` への遷移、approve 時の vocabulary 反映 / 既存 markdown 一括更新の起動）を Spec 4 の `rw approve` コマンドが本 review 層も扱うように拡張する責務を Spec 4 への coordination 要求として明示** する。本 spec は approve コマンドの実装ロジックは規定せず、approve 後の vocabulary 反映時に従うべき不変条件（重複登録禁止 / canonical unique 等は Requirement 6.2、severity 規約は Requirement 9）のみを規定する。`audit_candidates/` / `relation_candidates/` / `decision-views/` の approve 機構は本 Requirement 4.8 で再委譲した各所管 spec（Spec 4 / Spec 5）が独自設計する。

### Requirement 5: Entity 固有ショートカット field のスキーマ宣言

**Objective:** As a Spec 5 起票者, I want Entity 固有ショートカット field（`authored:` / `collaborated_with:` / `mentored:` / `implements:` 等）が entity type 別に定義され、`entity_types.yml` で field 集合と typed edge 名へのマッピングが宣言されている, so that Spec 5 の `normalize_frontmatter` API が typed edge へ展開する際に固定の参照表を持てる。

#### Acceptance Criteria

1. The Classification System shall Entity 固有ショートカット field を「特定 entity type のページが frontmatter で typed edge を簡潔に表現するための糖衣構文」として位置付け、本 spec はその **宣言とマッピング表** を所管する。
2. The Classification System shall `.rwiki/vocabulary/entity_types.yml` のスキーマとして、各 entity type に対し `name`（canonical、文字列）/ `description`（任意）/ `shortcuts`（ショートカット field 名 → 展開後の typed edge 名のマッピング）の 3 項目を宣言可能にする。
3. The Classification System shall 初期 entity type として最低 `entity-person` と `entity-tool` の 2 種を定義し、`entity-person` は `authored` / `collaborated_with` / `mentored` を、`entity-tool` は `implements` をショートカットとして含める。
4. The Classification System shall ショートカット field の値を「対象 wiki path の配列」として固定し、空配列または field 自体の省略を許可する。
5. The Classification System shall ショートカット field の **typed edge への展開（双方向 edge 自動生成 / confidence 0.9 固定 / extraction_mode=explicit / 冪等性保証 / alias 衝突時 canonical 優先）は Spec 5 の `normalize_frontmatter` API が担う** ことを明示し、本 spec は呼び出し側（Spec 4 の `rw ingest` / `rw approve`、および Spec 5 の `rw graph rebuild` 等）の存在と展開トリガを前提として記述するに留める。展開対象の判定は **`entity_type:` field の値**（Requirement 2.3 で新設）を `entity_types.yml.name` と照合して行うものとし、`entity_type:` 未指定ページではショートカット field を展開しないことを規約として固定する。展開後の typed edge は L2 `edges.jsonl` に記録されるが、**L3 frontmatter `related:` cache への重複展開は行わない**（完全分離方針、Requirement 10.1 と整合、shortcut 由来 edge は shortcut field 自身が表現を担うことで frontmatter サイズ肥大化回避と shortcut の簡潔性メリット保持を実現）。
6. If あるページの `entity_type:` 値が登録 entity type のいずれにも属さない、または `entity_type:` 未指定でショートカット field（`authored:` / `collaborated_with:` / `mentored:` / `implements:` 等）が記述されている, then the lint task shall その状況を WARN として報告する。
7. The Classification System shall ユーザーが `entity_types.yml` に新規 entity type および新規ショートカット field を追加した場合、その mapping を Spec 5 の `normalize_frontmatter` API が参照することを規約として宣言する。

### Requirement 6: `.rwiki/vocabulary/tags.yml` の最小スキーマ

**Objective:** As a Spec 4 起票者および lint 利用者, I want tag vocabulary が最小スキーマ（canonical + description + aliases + 非推奨フラグ）で固定され、未登録タグ / エイリアス使用 / 非推奨タグの severity が一意である, so that lint と `rw tag *` コマンドが同じ vocabulary を解釈できる。

#### Acceptance Criteria

1. The Classification System shall `.rwiki/vocabulary/tags.yml` の最小スキーマとして、各タグエントリに `canonical`（文字列、unique、必須）/ `description`（文字列、任意）/ `aliases`（文字列配列、任意）/ `deprecated`（真偽、デフォルト false）/ `deprecated_reason`（文字列、`deprecated: true` 時に推奨）/ `successor`（後継 canonical タグ名、文字列または文字列配列、`deprecated: true` 時に推奨、後継なしの純粋廃止では省略可）の 6 項目を宣言可能にする。
2. The Classification System shall 同一文字列が複数の `canonical` または `aliases` に重複登録されることを禁止し、重複時に `rw tag *` コマンドおよび lint が ERROR として報告することを規定する。
3. If 任意の wiki / raw / review markdown ページの `tags:` に **未登録タグ**（`tags.yml` に canonical / aliases いずれにも一致しない）が出現した, then the lint task shall その出現を INFO severity で報告する。
4. If 任意のページの `tags:` に **エイリアス**（`tags.yml` のいずれかの `aliases` に該当）が出現した, then the lint task shall canonical への置換を提案する WARN を報告する。
5. If 任意のページの `tags:` に **非推奨タグ**（`tags.yml` で `deprecated: true` のタグ）が出現した, then the lint task shall その出現を WARN severity で報告し、可能なら successor または deprecated_reason をメッセージに含める。
6. The Classification System shall `tags.yml` を `.rwiki/vocabulary/` 配下に配置し、git 管理対象であることを規定する。

### Requirement 7: `.rwiki/vocabulary/categories.yml` のスキーマと default skill mapping

**Objective:** As a Spec 3 起票者, I want カテゴリ vocabulary が `categories.yml` に集約され、各カテゴリに対し distill dispatch のための default skill mapping field が宣言されている, so that Spec 3 が dispatch 時に inline で参照する単一の表を持てる。

#### Acceptance Criteria

1. The Classification System shall `.rwiki/vocabulary/categories.yml` の最小スキーマとして、各カテゴリエントリに `name`（文字列、unique、必須）/ `description`（文字列、任意）/ `enforcement`（`recommended` / `optional` の 2 値、デフォルト `recommended`、Requirement 1.2「強制ではなく推奨」原則と整合させるため `required` 値は採用しない）/ `recommended_type`（推奨 frontmatter `type:` 値の配列、任意）/ `default_skill`（distill dispatch の default skill 名、文字列、任意）の 5 項目を宣言可能にする。
2. The Classification System shall Spec 1 ↔ Spec 3 coordination の決定として、default skill mapping は `categories.yml` の **inline `default_skill` field** として記述する方式を採用し、別ファイルへの分離は行わないこととする。
3. The Classification System shall 初期カテゴリ **6 種**（`articles` / `papers` / `notes` / `narratives` / `essays` / `code-snippets`）について、それぞれの `recommended_type` と `default_skill` の初期値が将来 Spec 3 起票時に確定可能な形で空欄を許可する。
4. When ユーザーが `.rwiki/vocabulary/categories.yml` を編集して新規カテゴリを追加した, the Classification System shall 追加直後から lint / dispatch hint がそのカテゴリを参照対象に含める。
5. If `categories.yml` の同一 `name` が重複登録されている, then the Classification System shall `rw tag *` コマンドおよび lint が ERROR として報告する。
6. The Classification System shall `categories.yml` の `default_skill` の **参照側 dispatch ロジックは Spec 3 の所管** であることを明示し、本 spec は field の存在と意味のみを規定することを宣言する。

### Requirement 8: Tag 操作 CLI 群（`rw tag *`）

**Objective:** As a Rwiki v2 ユーザーおよび Spec 4 起票者, I want tag vocabulary を維持・整理するためのコマンド群 `rw tag *` が定義されている, so that ユーザーが対話・スクリプトから vocabulary を操作でき、`rw chat` から LLM がガイド可能になる。

#### Acceptance Criteria

1. The rw tag command shall 以下のサブコマンドを提供する: `scan` / `stats [<tag>]` / `diff <a> <b>` / `merge <canonical> <aliases>...` / `split <tag> <new-tags>...` / `rename <old> <new>` / `deprecate <tag>` / `register <tag> [--desc]` / `vocabulary {list, show, edit}` / `review`。
2. When `rw tag scan` が実行された, the rw tag command shall 全 markdown ページの `tags:` を走査して、未登録タグ・エイリアス使用・非推奨タグ・重複候補を Requirement 6 の severity 規約に従って一覧出力する。本コマンドは Requirement 9 の `rw lint` の vocabulary 検査と severity 体系を共有しつつ、tag 統計・重複候補・エイリアス置換提案等の vocabulary 整理に特化した詳細情報を追加出力する点で `rw lint` と機能境界を区別する。
3. When `rw tag stats` または `rw tag stats <tag>` が実行された, the rw tag command shall 全タグまたは指定タグの出現件数・最終使用日・使用ページ数を集計して出力する。
4. When `rw tag diff <a> <b>` が実行された, the rw tag command shall 2 タグの使用ページ集合の重複率と類似度（共起関係を含む）を算出して出力する。
5. When `rw tag merge <canonical> <aliases>...` または `rw tag split <tag> <new-tags>...` が実行された, the rw tag command shall **対話ガイド必須**（Foundation §2.4 / Requirement 3 の dangerous operations 8 段階対話に準じる）として `review/vocabulary_candidates/` への変更計画 candidate 生成を経由し、`rw approve`（Spec 4 所管、本 spec Requirement 4.9 で `vocabulary_candidates/` 対応を Spec 4 への coordination 要求として明示）で初めて vocabulary と既存 markdown が更新される手順を取る。
6. When `rw tag rename <old> <new>` が実行された, the rw tag command shall 単純改名として vocabulary と既存 markdown を一括更新するが、対話 confirm を求めることを規定する（Simple dangerous operation 相当）。
7. When `rw tag deprecate <tag>` が実行された, the rw tag command shall 該当タグに `deprecated: true` を付与し、deprecated_reason の入力を求める。
8. When `rw tag register <tag> [--desc <description>]` が実行された, the rw tag command shall 未登録タグを `tags.yml` に追加し、description が指定されていればそれを記録する。
9. When `rw tag vocabulary list` / `rw tag vocabulary show <tag>` / `rw tag vocabulary edit` が実行された, the rw tag command shall それぞれ全タグ一覧 / 個別タグ詳細 / `tags.yml` の対話編集起動を行う。
10. When `rw tag review` が実行された, the rw tag command shall 対話的 vocabulary 整理セッションを起動し、`scan` / `merge` / `split` / `deprecate` を順序立てて案内する。
11. The rw tag command shall 全サブコマンドが exit code 0/1/2 分離規約（PASS / runtime error / FAIL 検出）に従うことを規定する（roadmap.md「v1 から継承する技術決定」と整合）。
12. The rw tag command shall LLM CLI を呼び出すサブコマンドが存在する場合、subprocess timeout を必須設定とすることを規定する（roadmap.md「v1 から継承する技術決定」と整合）。
13. The rw tag command shall vocabulary を変動させる操作（`merge` / `split` / `rename` / `deprecate` / `register`）の approve 完了時に、Spec 5 の `record_decision()` API（Foundation Requirement 12 / §2.13 Curation Provenance、`decision_log.jsonl` への append-only 記録）を呼び出して decision を自動記録する責務を Spec 5 への coordination 要求として明示する。`decision_type` は `vocabulary_merge` / `vocabulary_split` / `vocabulary_rename` / `vocabulary_deprecate` / `vocabulary_register` を初期値として宣言し、`subject_refs` には対象 canonical / aliases / affected_files 等を、`reasoning` には `review/vocabulary_candidates/*` の `deprecated_reason` または approve 時のユーザー入力を、`outcome` には実施操作内容を記録する。本 acceptance criterion は Foundation Requirement 12.4 が列挙する「人間 approve・reject・merge・split」の **解釈拡張** として vocabulary 操作も自動記録対象に含めることを宣言し、Foundation 側の文言整合化は Adjacent Spec Synchronization で別途実施する（brief.md Design phase 持ち越しに記録）。
14. The rw tag command shall vocabulary を変動させる操作（`merge` / `split` / `rename` / `deprecate` / `register`）の実行時に **Foundation Requirement 11.5 が規定する `.rwiki/.hygiene.lock` を取得** することを Spec 4 への coordination 要求として明示する。これにより Hygiene batch との競合・複数 `rw tag *` 同時実行・複数端末同時編集を排他制御し、vocabulary YAML（`tags.yml` / `categories.yml` / `entity_types.yml`）と影響を受ける markdown ファイル群の整合性を保証する。具体的な lock 取得 / 解放 / timeout / deadlock 検出ロジックは Spec 4 / Spec 5 の design phase で確定する。

### Requirement 9: lint task の vocabulary 統合

**Objective:** As a Spec 4 起票者, I want lint task が tag vocabulary・category vocabulary・entity_types vocabulary を統合参照し、severity を 4 水準（CRITICAL / ERROR / WARN / INFO）で報告する, so that ユーザーが ingest / approve 前に vocabulary 違反を一意の基準で検出できる。

#### Acceptance Criteria

1. The lint task shall vocabulary 検査項目として「未登録タグ（INFO）」「エイリアス使用（WARN）」「非推奨タグ（WARN）」「未登録カテゴリディレクトリ配置（INFO）」「許可値外の `type:`（`categories.yml.recommended_type` 未該当、WARN）」「許可値外の `entity_type:`（`entity_types.yml.name` 未登録、WARN、本項目は Requirement 5.6 の「`entity_type:` 値が登録 entity type のいずれにも属さない」と同義）」「`entity_type:` 未指定でショートカット field 記述（WARN、Requirement 5.6 と整合）」「`tags.yml` / `categories.yml` / `entity_types.yml` 内重複登録（ERROR）」「必須 frontmatter field 欠落（ERROR）」を含む。
2. The lint task shall severity 体系として CRITICAL / ERROR / WARN / INFO の 4 水準を採用し、roadmap.md「v1 から継承する技術決定」を経由して継承された severity 4 水準と `map_severity()` identity マッピング規約に準拠する（v1-archive の severity-unification spec を直接参照しない）。
3. The lint task shall vocabulary 検査が `tags.yml` / `categories.yml` / `entity_types.yml` を起動時に読み込み、cache せずに毎回最新を反映する（vocabulary 変更が即座に lint 結果に反映される）。
4. If `tags.yml` / `categories.yml` / `entity_types.yml` がいずれも存在しない, then the lint task shall vocabulary 検査をスキップして INFO で「vocabulary 未初期化」を通知し、それ以外の lint 検査は継続する。
5. The lint task shall 検出結果を JSON / human-readable 両形式で出力可能とし、CI から下流 consumer が parse できる構造を提供する。
6. The lint task shall exit code 0/1/2 分離（PASS / runtime error / FAIL 検出 = ERROR 以上 1 件以上）に従う。
7. If 個別 vocabulary ファイル（`tags.yml` / `categories.yml` / `entity_types.yml` のいずれか）が YAML として parse 不可、または部分破損で読み込み失敗した場合, then the lint task shall 当該 vocabulary 関連検査のみ ERROR severity で fail（vocabulary file 読み込みエラーとして報告、原因 file path と parse error message を含める）し、他の vocabulary 検査と非 vocabulary 検査は継続する。これにより 1 ファイルの破損が全 lint を停止させない fail-soft 動作を保証する。
8. If 個別 vocabulary ファイルに整合性 ERROR（重複登録等、Requirement 6.2 / 7.5 等）が検出された, then the lint task shall その vocabulary を入力とする他の検査（未登録タグ / 許可値外 `type:` / 許可値外 `entity_type:` / `entity_type:` 未指定でショートカット記述 等）を **skip** して WARN で「vocabulary 整合性 ERROR のため関連検査を skip」と通知することにより、誤検出（重複した canonical のどちらを正規とみなすかの不確定性に起因する偽陽性）を避ける。

### Requirement 10: L3 frontmatter `related:` を Spec 5 derived cache とする規約

**Objective:** As a Spec 5 起票者および Spec 6 / Spec 7 起票者, I want L3 frontmatter `related:` の正本が Spec 5 の `.rwiki/graph/edges.jsonl` であり、本 spec は cache 利用と sync 規約のみを定義することが明確である, so that 各 spec が cache の鮮度を必須条件にせず、Spec 5 の sync 機構と整合した動作をとれる。

#### Acceptance Criteria

1. The Classification System shall L3 frontmatter `related:` を「Spec 5 `edges.jsonl` の **stable / core** edge のうち **Entity-specific shortcuts（`authored:` / `collaborated_with:` / `mentored:` / `implements:` 等）で表現されない typed edge のみ** を絞り込んだ derived cache」として位置付け、正本ではないことを明示する。shortcut 由来 typed edge は frontmatter shortcut field 自身が表現を担い、`related:` への重複展開は行わない（完全分離方針、Requirement 5.5 と整合）。全 typed edge を統合的に閲覧する用途では cache 統合ではなく L2 `edges.jsonl` を Spec 5 Query API 経由で直接参照することが推奨される。
2. The Classification System shall `related:` cache の鮮度を eventual consistency とし、cache が stale の状態でも L3 wiki ページが invalid にならないことを規定する。
3. The Classification System shall cache invalidation と sync 機構（stale mark 追記 / Hygiene batch 一括 sync / CLI 起動時 stale detection / 手動 `rw graph rebuild --sync-related`）の **実装は Spec 5 が所管** であることを明示する。
4. The Classification System shall `related:` の各要素 schema を Requirement 3.5 で確定した定義（`target` / `relation` / 任意の `edge_id`）に従うものとし、本 Requirement では cache 規約のみを扱う。relation 名の vocabulary（`relations.yml`）は Spec 5 が所管することを明示する。
5. If lint task が `related:` の要素中に `target` または `relation` が欠落した, then the lint task shall ERROR として報告する。
6. If lint task が `related:` の `relation` 値が Spec 5 `relations.yml` に未登録である, then the lint task shall WARN として報告する。ただし `relations.yml` が未配置の場合は INFO に降格する。
7. The Classification System shall ユーザーが `related:` を手動編集することを禁じない（緊急時の override 経路として残す）が、次回 Spec 5 sync 実行時に edges.jsonl 由来の値で上書きされる可能性を規約として明示する。

### Requirement 11: Spec 1 ↔ Spec 3 coordination の確定

**Objective:** As a Spec 3 起票者, I want Spec 1 ↔ Spec 3 の coordination 決定（frontmatter `type:` 追加と categories.yml の default skill mapping 方式）が本 spec で固定されている, so that Spec 3 起票時に Spec 1 を再変更する coordination リスクが消える。

#### Acceptance Criteria

1. The Classification System shall frontmatter 推奨フィールドに `type:` を含めることを Spec 1 の決定として固定し、`type:` を Spec 3 distill dispatch の hint として参照可能にする（Requirement 2 と整合）。
2. The Classification System shall `categories.yml` の default skill mapping 方式として **inline `default_skill` field** を採用することを Spec 1 の決定として固定し、別ファイル（例: `category_skill_map.yml`）への分離は採用しないことを明示する（Requirement 7 と整合）。
3. The Classification System shall `type:` 値の許可集合が `categories.yml` の `recommended_type` と Spec 2 の skill 群の applicable_categories と整合することを規約として宣言し、`entity_type:` 値の許可集合は `entity_types.yml.name` のみを参照すると規定する。両 field の整合チェックはそれぞれ独立に lint task が WARN として実装することを規定する（Requirement 2.7 / Requirement 9 と整合）。
4. While Spec 3 が dispatch 実装を行う段階において, the Classification System shall 自身が field の意味と vocabulary 表のみを所管し、dispatch 優先順位（明示 → `type:` → category default → LLM 判断）の **判断ロジック自体は Spec 3 が所管** することを明示する。
5. If 将来 Spec 3 起票時に default_skill mapping 方式の変更が必要になった, then the Classification System shall 本 spec を先に改版する手順（roadmap.md「Adjacent Spec Synchronization」運用ルール）を参照点として残す。

### Requirement 12: Spec 1 ↔ Spec 5 coordination の責務分離

**Objective:** As a Spec 5 起票者, I want Entity 固有 field のスキーマ宣言（本 spec）と展開ロジック（Spec 5）の境界が明文で固定されている, so that Spec 5 の `normalize_frontmatter` API 設計時に本 spec の field を再定義せずに参照できる。

#### Acceptance Criteria

1. The Classification System shall Entity 固有ショートカット field の **スキーマ宣言と `entity_types.yml` の mapping table 定義** を Spec 1 の所管として固定する（Requirement 5 と整合）。
2. The Classification System shall ショートカット field から typed edge への **展開ロジック（mapping 参照 → source/target 決定 → extraction_mode=explicit → 双方向 edge 自動生成 → frontmatter evidence 登録 → confidence 0.9 固定 → alias 衝突時の canonical 優先と警告 → 冪等性保証）の実装** を Spec 5 の `normalize_frontmatter(page_path) → List[Edge]` API の所管として明示する。
3. The Classification System shall L3 frontmatter `related:` の cache 規約定義（本 spec、Requirement 10）と cache invalidation / sync 実装（Spec 5）の境界を明示する。
4. The Classification System shall `relations.yml`（typed edge 名の vocabulary）を Spec 5 の所管として明示し、本 spec は `related:` の `relation` field が `relations.yml` を参照することを規約として記述するに留める（Requirement 10 と整合）。
5. While Spec 5 が `normalize_frontmatter` API を実装する段階において, the Classification System shall 自身の `entity_types.yml` mapping を Spec 5 が読み込む input として固定し、Spec 5 が独自に entity type 集合を再定義することを禁ずる。
6. If Spec 5 起票時に Entity 固有 field のスキーマ追加・変更が必要になった, then the Classification System shall 本 spec を先に改版する手順（roadmap.md「Adjacent Spec Synchronization」運用ルール）を参照点として残す。

### Requirement 13: Foundation 規範への準拠

**Objective:** As a 本 spec の品質保証および将来の更新者, I want 本 spec が Foundation（Spec 0、`rwiki-v2-foundation`）の 13 中核原則・用語集・3 層アーキテクチャ・Edge / Page status の区別 を SSoT として参照し、独自定義による再解釈・再命名を行わない, so that 用語と原則の解釈が複数 spec で分岐することを防ぐ。

#### Acceptance Criteria

1. The Classification System shall Foundation の 13 中核原則のうち §2.2 Review layer first（L3 限定）/ §2.3 Status frontmatter over directory / §2.5 Simple dangerous operations / §2.6 Git + 層別履歴媒体 / §2.10 Evidence chain / §2.13 Curation Provenance を本 spec の設計前提として参照することを明示する。
2. The Classification System shall Foundation Requirement 5 の Page status 5 種（`active` / `deprecated` / `retracted` / `archived` / `merged`）を `status:` の許可値として継承し、独自に状態を追加しない（Requirement 3 と整合）。
3. The Classification System shall Foundation Requirement 5 の Edge status 6 種（`weak` / `candidate` / `stable` / `core` / `deprecated` / `rejected`）を Page status と独立した別次元として扱い、本 spec は Edge status を frontmatter で扱わないことを明示する。
4. The Classification System shall Foundation Requirement 8 が委譲した frontmatter 詳細スキーマの所管を本 spec が引き受けることを明示し、次の領域は所管 spec へ再委譲することを規定する（Requirement 4 と整合）: (a) Skill ファイル / Skill candidate / Hypothesis candidate / Perspective 保存版 → Spec 2 / Spec 6 (Requirement 4.6)、(b) `review/decision-views/` の Tier 2 timeline → Spec 1 が骨格宣言、render は Spec 5 (Requirement 4.7)、(c) `review/audit_candidates/` → Spec 4、`review/relation_candidates/` → Spec 5、Follow-up (`wiki/.follow-ups/`) → Spec 7 (Requirement 4.8)、(d) `review/vocabulary_candidates/` の approve 処理 → Spec 4 への coordination 要求 (Requirement 4.9)。
5. If Foundation の用語・原則・マトリクスと矛盾する記述が本 spec に必要となった, then the Classification System shall 先に Foundation を改版する手順（roadmap.md「Adjacent Spec Synchronization」運用ルール）を参照点として残し、本 spec を独自に逸脱させない。
6. The Classification System shall 本 spec 自身が `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §5 / §6.2 Tag Vocabulary / §7.2 Spec 1 を SSoT 出典とすることを明示する。

### Requirement 14: 文書品質と運用前提

**Objective:** As a 本 spec の品質保証および将来の更新者, I want 本 spec の出力が CLAUDE.md の出力ルール（日本語・表は最小限・長文は表外箇条書き）に準拠し、運用前提（Python 3.10+ / git 必須 / LLM CLI subprocess timeout 必須）を Foundation の規範経由で継承する, so that 本 spec の可読性と運用整合性が保たれる。

#### Acceptance Criteria

1. The Classification System shall 本 spec の requirements / design / tasks 文書を日本語で記述し、`spec.json.language=ja` および CLAUDE.md「All Markdown content written to project files MUST be written in the target language」要件に準拠する。
2. While 本 spec 文書中で表形式を用いる場合, the Classification System shall 表は最小限に留め、長文・解説は表外の箇条書きまたは段落で記述する。
3. The Classification System shall 運用前提（Python 3.10+ / git 必須 / LLM CLI subprocess timeout 必須 / Severity 4 水準 / exit code 0/1/2 分離）を Foundation Requirement 11 / roadmap.md「v1 から継承する技術決定」 経由で継承し、独自に再定義しない。
4. The Classification System shall `.rwiki/vocabulary/` 配下の全ファイル（`tags.yml` / `categories.yml` / `entity_types.yml`）が git 管理対象であり、derived cache（lint cache 等）は gitignore とすることを規定する（Foundation §2.6 と整合）。
5. The Classification System shall 本 requirements が定める 14 個の Requirement の各々について、design 段階で「Boundary Commitments」として境界が再確認されることを前提とし、本 requirements の境界（in scope / out of scope / adjacent expectations）を design phase に渡せる形で固定する。
