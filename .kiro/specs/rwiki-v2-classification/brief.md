# Brief: rwiki-v2-classification

> 出典: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §5, §7.2 Spec 1

## Problem

L3 Curated Wiki は markdown ページの集合だが、frontmatter スキーマ・カテゴリ体系・タグ vocabulary が未定義のままでは、各 spec が独自に frontmatter フィールドを使い始め、lint や derived cache 同期が成立しない。Entity 固有のショートカット（authored/collaborated_with 等）の扱いも宙ぶらりんになる。

## Current State

- consolidated-spec §5 に共通必須・推奨・任意・wiki 固有・review 固有・skill ファイル固有等の frontmatter スキーマが整理済
- カテゴリ（articles / papers / notes / narratives / essays / code-snippets の **6 種**）と vocabulary（tags / relations / categories / entity_types）の方針も合意済（`llm_logs` は L3 から除外、L1 raw のみで扱う方針に 2026-04-26 セッションで変更、概念軸統一のため）
- v1 では tags 体系が部分実装、v2 では vocabulary を `.rwiki/vocabulary/` 配下に集約

## Desired Outcome

- L3 wiki ページの frontmatter スキーマが固定され、lint / approve / distill / extract-relations が同じスキーマを前提に動作する
- カテゴリは「強制ディレクトリ」ではなく「推奨パターン」として、ユーザー拡張可能
- タグ vocabulary の最小スキーマ（canonical + description + aliases）と未登録タグの扱い（INFO / WARN）が確定
- Entity 固有ショートカット field（authored/implements 等）の定義が固まる（内部正規化は Spec 5）

## Approach

frontmatter スキーマ・カテゴリ体系・tag vocabulary を Spec 1 の責務とする。`.rwiki/vocabulary/tags.yml` `categories.yml` `entity_types.yml` のスキーマを定義し、`rw tag *` コマンドで管理。L3 frontmatter `related:` は derived cache として位置付け（正本は Spec 5 の Graph Ledger）。

## Scope

- **In**:
  - カテゴリディレクトリ構造定義
  - 共通・L3 wiki 固有・review 固有の frontmatter スキーマ
  - `.rwiki/vocabulary/tags.yml` スキーマ
  - `.rwiki/vocabulary/categories.yml`（拡張）
  - Tag 操作コマンド（`rw tag *`）
  - lint の vocabulary 統合
  - L3 frontmatter `related:` を derived cache として位置付け
  - Entity 固有ショートカット field の定義（`authored:` `collaborated_with:` `implements:` 等）
  - 新規 review 層: `review/vocabulary_candidates/`
- **Out**:
  - Typed edges の正本管理（Spec 5）
  - Skill 内のタグ自動抽出（Spec 2）
  - Relation vocabulary 定義（Spec 5 の `relations.yml`）

## Boundary Candidates

- frontmatter スキーマ定義（本 spec）と スキーマを使う動作（他 spec の lint / approve / extract）
- vocabulary（tags / categories / entity_types）の管理（本 spec）と relations vocabulary（Spec 5）
- Entity 固有 field の宣言（本 spec）と Entity 固有 field の typed edge 展開（Spec 5）

## Out of Boundary

- L2 edges.jsonl の管理（Spec 5）
- Distill skill の dispatch（Spec 3）
- L3 page lifecycle（Spec 7）

## Upstream / Downstream

- **Upstream**: rwiki-v2-foundation（Spec 0）
- **Downstream**: rwiki-v2-cli-mode-unification（Spec 4 — lint で vocabulary 検証）/ rwiki-v2-knowledge-graph（Spec 5 — frontmatter 正規化）/ rwiki-v2-prompt-dispatch（Spec 3 — `type:` field を dispatch hint）/ rwiki-v2-lifecycle-management（Spec 7 — Page lifecycle field（`status` / `successor` / `merged_*` 等）のセマンティクス実装）

## Existing Spec Touchpoints

- **Extends**: なし（新規）
- **Adjacent**: v1 `agents-system`（v1-archive、参考のみ、AGENTS と vocabulary の関係を参照）

## Constraints

- カテゴリは強制ではなく推奨パターン
- source は frontmatter 必須、自由文字列、カテゴリから自動推論しない
- 未登録タグは INFO、エイリアスは WARN、非推奨は WARN
- L3 `related:` は L2 edges.jsonl からの derived cache（`rw graph rebuild --sync-related` または Hygiene batch sync で整合、Spec 5 所管）
- Entity 固有ショートカットは Spec 5 の `normalize_frontmatter` API で typed edge に展開（confidence 0.9 固定）

## Coordination 必要事項

- **Spec 1 ↔ Spec 3**: frontmatter 推奨フィールドに `type:` 追加（distill dispatch hint）→ requirements.md R11.1 で確定。`categories.yml` の default_skill mapping 方式 → **inline `default_skill` field 方式に確定**（requirements.md R11.2、別ファイル方式は不採用）。
- **Spec 1 ↔ Spec 5**: Entity 固有 field のスキーマ宣言（本 spec）と展開ロジック（Spec 5）の境界 → requirements.md R12 で責務分離確定。

## Design phase 持ち越し（2026-04-26 requirements レビューセッションで段階的に追加、計約 42 件、第 1 〜第 6 ラウンド構成）

### 第 1 ラウンド指摘（4 件）

- **R3.6 `update_history.evidence` の型明確化**: 現状「任意、raw path」だが、`raw/` 配下の relative path（文字列）として型定義を design phase で明示する。
- **R5.6 と R9.1 の言い回し統一**: 「ショートカット field が未登録 entity type に属する」（R5.6）vs 「未登録 entity type のショートカット field 使用」（R9.1）の文言を design phase で統一する。
- **R4.5 必須/任意区別の明示**: `review/vocabulary_candidates/*` の field（`operation` / `target` 必須、`aliases` 任意、`affected_files` 必須、`status` デフォルト `draft`）の必須/任意区別を design phase で整理する。
- **R7.3 `categories.yml` 初期値の空欄許容明示**: `recommended_type` と `default_skill` が「空欄でも valid」であることを design phase で明示する。

### 第 2 ラウンド指摘（roadmap.md / brief.md 厳格照合で発見、8 件）

- **F: R5.3 entity-person/tool ショートカット → typed edge 名 mapping の初期値**: `entity-person.shortcuts.authored` → 展開後 typed edge 名（例: `authored` / `is_author_of`）など、初期 mapping 例を design phase で確定する。Spec 5 の `relations.yml` と整合する必要あり。
- **G: typed edge の directed/undirected 区別**: `mentored`（directed: mentor → mentee）と `collaborated_with`（undirected）等、各 typed edge の方向性宣言が `entity_types.yml` または `relations.yml`（Spec 5）に必要。design phase で所管と表現方法を確定する。
- **L: lint で許可値外 `merge_strategy:` の WARN 検出追加**: R3.4 で `merge_strategy:` 5 値を確定したが、R9.1 の lint 検査項目に許可値外 `merge_strategy:` 検出が含まれていない。design phase で R9.1 拡張を検討する。
- **M: type 表記の統一**: R3.4 「path」「path 配列」など型表記の表記揺れを design phase で「文字列（path）」「配列（path）」のような統一フォーマットに整える。
- **N: R4.7 `decision-views/` の `period_start` / `period_end` 必須/任意の妥当性**: Tier 2 timeline の本質は「期間内の decision を時系列表示」のため、period の必須化を design phase で再検討する。
- **O: Decision visualization Tier 1, 3, 4, 5 の出力先所管**: Foundation R7.4 で Tier 1-5 が定義されているが、Spec 1 R4.7 では Tier 2 のみを `decision-views/` の固定値として宣言。他 Tier の出力先所管（Spec 5 か Spec 1 か）を design phase で確認する。
- **S: `categories.yml.enforcement` セマンティクス**: 本-1 修正で `enforcement` を 2 値（`recommended` / `optional`）に縮約し、R1.2「いずれの推奨カテゴリ外でも valid」と整合化済。本項目は本-1 修正で **解消済**（design phase 持ち越し対象から除外）。
- **T: `merge_strategy: canonical-a` / `canonical-b` の a/b 順序規約**: R3.4 で値を確定したが、`canonical-a` がどちらのページを指すか（`merged_from` の順序など）の規約を design phase で明示する。

### 第 3 ラウンド指摘（本質的観点で発見、要 design phase 対応）

- **本-4: `source:` 重複検出・canonical 化の Spec 4 audit task 連携詳細**: requirements.md Boundary Adjacent expectations で Spec 4 audit task に再委譲済（同一 paper / DOI / URL / arXiv ID 等の表記揺れ検出）。Spec 4 起票時に audit カテゴリへの `source dedup` 追加と、本 spec から渡す検出パターン（URL 正規化 / DOI 抽出 / arXiv ID 抽出 等）の interface を design phase で詰める。
- **本-5: `related:` cache stale 時の UX 保護**: requirements.md Boundary Adjacent expectations で Spec 5 / Spec 6 に再委譲済（案C 採用、frontmatter schema 拡張なし、文書メタデータと cache 状態メタデータの分離原則を維持）。design phase で確定すべき項目: (a) Spec 5 sync 履歴メタデータの設計（格納場所 / 形式 / sync log エントリ schema、`.rwiki/graph/` 配下推奨）、(b) Spec 6 stale UX 閾値・警告表示・rebuild 提案 UX、(c) Spec 5 ↔ Spec 6 間の coordination（メタデータ参照 interface）、(d) 質的乖離（age では検出不可な edge 変動）の検出は Spec 5 sync 機構の rebuild ポリシーで対応。
- **本-14: L3 カテゴリ `llm_logs` 除外に伴う Spec 2 / drafts の整合**:
  - **Spec 2 ↔ Spec 1 coordination 要求**: Spec 2 起票時に skill `applicable_categories` の値域を「L3 `categories.yml.name` のみ」と限定し、L1 raw `raw/llm_logs/` を入力対象とする skill（例: consolidated-spec L2572 の `llm_log_extract`）は **applicable_categories ではなく別の input path 規約**（例: `applicable_input_paths` field 等）で表現するよう coordination する。Spec 2 起票時に本 spec から requirements 要求を出す。
  - **consolidated-spec.md drafts への Adjacent Sync**: L1502 の「カテゴリディレクトリ構造（articles / papers / notes / narratives / essays / code-snippets / llm_logs）」を 6 カテゴリに更新（drafts は本 spec を最新 SSoT として参照する位置付けに変更、別セッションで実施可）。L2563-2599 の `llm_log_extract` skill 説明は L1 raw 対象である旨を明示化（Spec 2 起票時の input として再評価）。
- **本-17: Foundation R12.4 への vocabulary 操作追加（Adjacent Sync）**: requirements.md R8.13 で vocabulary 操作（`merge` / `split` / `rename` / `deprecate` / `register`）の approve 時に Spec 5 `record_decision()` API 経由で decision_log 自動記録を Spec 5 への coordination 要求として明示済。これは Foundation R12.4 が列挙する「人間 approve・reject・merge・split」の解釈拡張として vocabulary 操作も含む宣言。Foundation 側の文言整合化は Adjacent Spec Synchronization 運用ルール（roadmap.md L162-168）に従い別セッションで Spec 0 (foundation) requirements.md R12.4 を「人間 approve・reject・(page) merge・split・(vocabulary) merge・split・rename・deprecate・register / ...」のように拡張する微修正を実施する。decision_type 値（`vocabulary_merge` / `vocabulary_split` / `vocabulary_rename` / `vocabulary_deprecate` / `vocabulary_register`）の正規化と Spec 5 record_decision() interface の確定は Spec 5 design phase で行う。
- **本-20: Entity shortcuts と `related:` cache の完全分離（案A 採用、Spec 5 / Spec 6 への design 要求）**:
  - **Spec 5 への要求**: requirements.md Boundary Adjacent expectations で「Spec 5 sync 機構は `related:` cache 生成時に Entity-specific shortcuts で表現される typed edge を除外するフィルタを実装する責務」を明示済。Spec 5 design phase で「shortcut 除外フィルタ」の実装詳細（source ページの frontmatter 読み込み → shortcut field の値集合取得 → `related:` cache 候補から該当 edge を除外）を確定する。
  - **Spec 6 への要求**: requirements.md Boundary Adjacent expectations で「全 typed edge を統合的に閲覧する用途では L2 `edges.jsonl` を Spec 5 Query API 経由で直接参照する設計原則」を明示済。Spec 6 design phase で perspective / hypothesize / verify の各処理が「shortcut field を含む全 edge を見たい」場面で L2 直接参照（`get_neighbors` 等）を採用することを明示し、`related:` cache を統合する方式は採用しないことを implementation guideline として固定する。
  - **完全分離方針の根拠**: 案A 採用（案C「重複許容、役割分離」の 4 つの実用上破綻 — 同期タイミングずれの UX 露出 / 編集権限の二重化 / frontmatter サイズ肥大化 / shortcut の簡潔性メリット減 — を回避）。長期的に concept 純度・実装シンプルさが優位。

### 第 3 ラウンド指摘（中重要度、design phase で確定）

- **本-9: Vocabulary 並行編集時の競合解決規約**: 複数ユーザーが同時に `tags.yml` / `categories.yml` / `entity_types.yml` を編集した場合の Git conflict 解決規約が requirements.md に明示なし。R6.2 で重複登録 ERROR は規定済だが、merge conflict の resolution 手順（手動マージ / 優先ルール / lock 機構等）は未定義。design phase で「`.rwiki/.hygiene.lock` 拡張で vocabulary 編集 lock を扱うか、Git の通常 merge に委ねるか」を Spec 4 ↔ Spec 1 coordination として確定する。
- **本-10: `tags.yml` 大規模時の lint 性能**: R9.3「vocabulary 検査が `tags.yml` / `categories.yml` / `entity_types.yml` を起動時に読み込み、cache せずに毎回最新を反映」は 1 万タグ超で性能問題化のリスク。design phase で「タグ数規模の上限想定（v2 MVP では 1,000 タグ程度を想定）」と「規模を超えた場合の cache 戦略（mtime ベース invalidation 等）」を確定する。
- **本-11: 既存 markdown への migration 手順**: 本 spec が確定するスキーマを既存 wiki ページに適用する手順（migration script / 既存ページが必須 field を欠く場合の扱い / 既存 tags が canonical 化前の表記等）が requirements.md に明示なし。v2 はフルスクラッチのため初期は migration 不要だが、将来 v2 → v2.1 でスキーマ拡張する時の migration 規約を design phase で検討する。Spec 7 lifecycle-management との coordination も視野。
- **本-13: `narratives` / `essays` カテゴリ重複の使い分け**: R1.1 で初期 6 カテゴリに `narratives` と `essays` を含むが、両者の使い分け（物語的 vs 主観的記述）が曖昧。design phase で `categories.yml` の `description` field に「narratives = 時系列・出来事中心、essays = 主観・論述中心」のような区別を明示するか、両者を統合するかを判断する。
- **本-15: `type:` / `entity_type:` 不在ページの扱い**: 【本-2】修正で `type:` と `entity_type:` を別 field に分離、【本-3】系問題は R5.5 / R5.6 修正で発火条件を `entity_type:` ベースに固定済 → **本項目は本-2/本-3 修正で実質解決**。design phase では「`entity_type:` 未指定 entity ページ（`wiki/entities/**` 配下）の扱い」を確定（INFO 通知で `entity_type:` 推奨を促す等）。
- **本-16: CLI 起動しないユーザーの cache stale 蓄積**: R10.2 eventual consistency 許容は妥当だが、「ユーザーが永久に CLI を起動しない期間」では Spec 5 sync が走らず cache が永遠に stale。Spec 5 design phase で「CLI 起動時 stale detection」の実装と、「CLI を起動させる UX 設計（rw chat 起動時に sync ステータス表示等）」を Spec 5 / Spec 4 / Spec 6 coordination として確定する。
- **本-18: vocabulary entry の evidence chain 適用範囲**: R13.1 で §2.10 Evidence chain を本 spec の設計前提として参照。ただし `tags.yml` / `categories.yml` / `entity_types.yml` の各エントリに evidence chain（L1 起点 → L2 evidence.jsonl → L3 sources）が必要かは未明示。vocabulary entry は L2 ledger でなく L3 wiki と同レベルの curated content であり、evidence は frontmatter `description` または `decision_log` で代替されるべき。design phase で「vocabulary entry は §2.10 Evidence chain の直接適用対象外、curation provenance（§2.13）で代替」を明示する。
- **本-21: `entity_types.yml.description` field の具体用途**: R5.2 で `description` を任意 field として宣言したが、lint / `rw tag` コマンド・Spec 5 normalize_frontmatter API での具体的な利用方法が未明示（単なる人間用説明か、機械判定にも使うか）。design phase で「description は人間向け説明用途のみ、機械判定には使わない」または「`rw tag vocabulary show` で表示する」等の用途を確定する。

### 第 3 ラウンド指摘（軽微、design phase で確定）

- **本-12: `entity-person` (単数) と `wiki/entities/people/` (複数) の命名不統一**: R5.3 で entity type 名は単数形（`entity-person` / `entity-tool`）だが、structure.md L48-49 のディレクトリ規約は複数形（`wiki/entities/people/` / `wiki/entities/tools/`）。design phase で「entity type 名（単数）とディレクトリ名（複数）のマッピング規約」を `entity_types.yml` のスキーマに `directory_name` field として追加するか、命名統一するかを確定する。
- **本-22: `rw tag *` コマンドの help text / man page 所管**: R8 で `rw tag *` のサブコマンド群を定義したが、各サブコマンドの `--help` メッセージ・man page・error message スキーマが未明示。Spec 4 の CLI 統一規約に従う想定。design phase で Spec 4 ↔ Spec 1 coordination として「help text の所管 spec」と「メッセージのテンプレート規約」を確定する。

### 第 4 ラウンド指摘（B 観点：Failure mode / 並行 / セキュリティ / 国際化 / 観測可能性 / 可逆性 / 規模 / 暗黙前提崩壊）

#### 中重要度 6 件

- **B-9: tag canonical の Unicode normalization / 大文字小文字 / 全角半角規約**: R6.2 の重複登録禁止が文字 byte 比較なら、「カフェ」(NFC) vs 「カフェ」(NFD) / `python` vs `Python` / `python` vs `ｐｙｔｈｏｎ` が別タグとして通る → 表記揺れ dedup 困難。design phase で「canonical の正規化規約（NFC normalization 必須 / case-sensitive vs insensitive / 全角半角 fold）」を確定する。
- **B-11: lint 結果の root cause 追跡支援**: R9.5 で JSON / human-readable 出力を規定したが、「なぜ未登録タグなのか」（タイポ / 新概念 / vocabulary 古い）の判別を支援する情報（distance metric / 類似 canonical の suggestion / Levenshtein 距離等）が未明示。design phase で lint 出力の suggestion 拡張を確定する。
- **B-13: tag merge / rename 後の rollback 手順**: `rw tag merge X Y` で 50 ページの tags が変わった後、「やはり戻したい」場合の手順未明示。git revert で全ファイル戻すか、`rw tag split Y X` で逆操作するか、専用 `rw tag undo` を用意するかを design phase で確定。
- **B-14: 誤 approve からの復旧 + decision_log 補正記録**: `review/vocabulary_candidates/` を誤 approve すると vocabulary と markdown が変わってしまう。git revert は使えるが decision_log には「approve」が残る → rollback 手順 + decision_log への補正記録（`decision_type: vocabulary_rollback` 等）を design phase で確定。
- **B-15: 大規模 vault（10,000+ pages）での scan 性能**: R8.2 `rw tag scan` が全 markdown ページを走査、R9.3 で「cache せず毎回最新」 → 10,000 ページ + 1,000 タグで分単位の遅延リスク。本-10 と統合して design phase で「規模上限想定 + cache 戦略（mtime ベース invalidation 等）」を確定。
- **B-16: ユーザーがカテゴリディレクトリ削除時の `categories.yml` 残存 lint 動作**: ユーザーが `wiki/articles/` を削除（全ページ別カテゴリへ移動）した時、`categories.yml.articles` が残ったまま。lint で「未使用カテゴリ INFO」として通知するか、無視するかを design phase で確定。

#### 軽微 4 件

- **B-5: vocabulary YAML の YAML injection リスク**: `rw tag register` 等で自動追記される canonical 名に特殊文字（`:` / `[` / `&aliases` 等の YAML 制御文字）が含まれた場合の YAML parser 破壊リスク。design phase で「canonical 文字種 whitelist / YAML 安全 escape」規約を確定。
- **B-6: `rw tag register` 等の引数 path traversal**: 引数（特に `register <tag>`）に `../../` や絶対 path を含む場合の処理未明示。design phase で「引数 sanitization 規約」を確定。
- **B-10: `entity_types.yml.name` の日本語命名許容性**: R5.3 で `entity-person` / `entity-tool`（kebab case 英語）を初期定義。日本語 entity type（例: `エンティティ-人物`）の許容性は未明示。design phase で「entity type 名の文字種 / case 規約」を確定。
- **B-17: `entity_types.yml` 空時の WARN 大量発生抑制**: `entity_types.yml` が空の場合、全ショートカット field が R5.6 で WARN → 大量警告。R5.6 の WARN 発生条件を「`entity_types.yml` が空でない場合のみ」に限定するか、`entity_types.yml` 未初期化時は INFO 降格するかを design phase で確定。

#### 確認済（修正不要、参考記録）

- **B-7**: スキーマ拡張時の既存ページ扱い → 本-11 と重複（本-11 で対応済）
- **B-8**: v1 → v2 vocabulary 引き継ぎ → roadmap.md フルスクラッチ方針で影響なし
- **B-12**: 手動編集の audit → git log で追える前提で OK
- **B-18**: 規定 vs 実装境界 → R3.4 修正（merge_strategy 5 値の Spec 7 拡張可規定）で妥当な妥協済

### 第 5 ラウンド指摘（C 観点：他 spec への波及影響、各 spec 起票時 / Adjacent Sync で coordination）

- **C-1: Spec 5 / Spec 2 の `type` 表記が entity type を指す箇所の調整**:
  - Spec 5 R1.2 (entities.yaml): `type`（entity type、`entity_types.yml` の値）
  - Spec 5 R5.5 (relation_extraction skill 出力 schema): `type`（`entity_types.yml` の値）
  - Spec 2 R7.2 (entity_extraction skill 出力 schema): `type`（`entity_types.yml` の値）
  - **問題**: 本 spec 修正（本-2）で `type:` を content 種別、`entity_type:` を entity 種別に **2 系統分離** したが、Spec 5 / Spec 2 の出力 schema および `entities.yaml` 内の field では entity type を依然 `type` と表記している。本 spec frontmatter の `type:` (content) と Spec 5 / Spec 2 の `type` (entity) が同名で意味が異なる二重命名状態。
  - **対応方針**: Spec 5 / Spec 2 起票時または Adjacent Sync で、それぞれの schema field 名を `entity_type` に統一するよう coordination 要求を出す。本 spec の `entity_type:` (frontmatter) と一貫させることで命名混乱を排除。
- **C-3: Spec 4 で `rw approve` の各 review 層対応 AC が未記述**:
  - Spec 4 requirements には `rw approve` がサブコマンド・タスクリストに登場するのみで、対応する review 層（`synthesis_candidates/` / `vocabulary_candidates/` / `audit_candidates/` / `decision-views/` / `relation_candidates/` / `Follow-up` 等）の dispatch 詳細 AC はなし。
  - 本 spec R4.9 で「`vocabulary_candidates/` approve は Spec 4 拡張責務」を coordination 要求として明示済（本-6 対応）。
  - **対応方針**: Spec 4 起票時または Adjacent Sync で `rw approve` の対応 review 層リストを Spec 4 requirements に新 AC として明示。各 review 層は本 spec R4 の対応所管表（R4.6 / R4.7 / R4.8 / R4.9）と整合させる。
- **C-6: Foundation R8.4 の Spec 1 委譲リストと R4.6 / R4.7 / R4.8 / R4.9 の対応マップ整合**:
  - Foundation R8.4 委譲リスト: 「Skill ファイル / Skill candidate / Vocabulary candidate / Follow-up / Hypothesis candidate / Perspective 保存版」+ 「`review/decision-views/`」
  - 本 spec 修正後の対応マップ: R4.6 (Skill / Hypothesis / Perspective → Spec 2 / Spec 6) / R4.7 (decision-views → Spec 1 骨格、render → Spec 5) / R4.8 (audit_candidates → Spec 4, relation_candidates → Spec 5, Follow-up → Spec 7) / R4.9 (vocabulary_candidates approve → Spec 4) / R6 / R7 (Vocabulary 自体は Spec 1 所管)
  - **整合状況**: 暗黙整合は取れているが、対応マップが Foundation R8.4 と Spec 1 R4 の両方を参照しないと完全には見渡せない。
  - **対応方針**: Adjacent Spec Synchronization 運用ルールに従い、Foundation R8.4 末尾に「具体的な所管マップは Spec 1 Requirement 4.6 / 4.7 / 4.8 / 4.9 を参照」の参照リンクを追加する微改訂を別セッションで実施する。本 spec を最新の所管 SSoT として位置付ける。

### 第 6 ラウンド指摘（D 観点：drafts (consolidated-spec.md / scenarios.md) との整合）

- **D-3: tags.yml.successor と wiki frontmatter.successor の同名 field 意味的衝突**:
  - **R6.1 (修正済、本-19 対応)**: tags.yml の `successor`（後継 canonical タグ名、文字列または文字列配列、`deprecated: true` 時に推奨）
  - **R3.3 (既存)**: wiki page frontmatter の `successor:`（`status: deprecated` 時の後継 wiki ページ path の配列）
  - **問題**: 同名 field が wiki page 文脈（path 配列）と tag 文脈（canonical タグ名の文字列または配列）で意味と型が異なる → 命名衝突。lint / parser / 人間読者の混乱リスク。
  - **対応方針 候補**:
    - 案A: tags.yml field 名を `successor_tag` または `successor_canonical` 等に rename（命名衝突回避、最も明示的）
    - 案B: 同名 field で文脈依存と明示（spec ドキュメントで「tag context = canonical タグ名、page context = wiki path」を明示、parser は文脈識別）
  - design phase で確定する。Spec 1 内で完結する判断（他 spec との coordination 不要）。

#### 確認済（修正不要、参考記録）

- **D-1**: consolidated-spec.md L1502 の 7 カテゴリ列挙 → 本-14「consolidated-spec.md drafts への Adjacent Sync」で別セッション対応として記載済（重複）
- **D-2**: consolidated-spec.md L2572 の `applicable_categories: [llm_logs]` (`llm_log_extract` skill) → 本-14「Spec 2 起票時の coordination」で持ち越し記載済（重複）
