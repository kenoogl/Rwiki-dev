# Research & Design Decisions: rwiki-v2-skill-library

## Summary

- **Feature**: `rwiki-v2-skill-library` (Spec 2)
- **Discovery Scope**: Complex Integration (Spec 5 / 4 / 7 / 1 / 3 / 6 と多重 coordination、Skill 内容と CLI dispatch / Lifecycle 操作 / dispatch logic / vocabulary / extraction schema の責務分離)
- **Key Findings**:
  - v1 task-based AGENTS (9 種) の 8 section スキーマを v2 が正本承継、output skill 概念分離 (15 種 = 知識生成 12 + Graph 抽出 2 + lint 支援 1) は v2 新規
  - Skill Library / Skill Authoring Workflow / Skill Validator の 3 subject は責務性質が異なる (静的 catalog / 動的 lifecycle / 純粋 check) ため module 分割が自然 (Spec 5 Decision 5-17 / Spec 7 Decision 7-21 同型問題回避)
  - 周辺 spec との boundary は requirements.md で明確化済 (Spec 5 = 出力 schema 委譲先 / Spec 7 = lifecycle handler 所管 / Spec 4 = CLI dispatch 所管 / Spec 1 = vocabulary 所管 / Spec 3 = dispatch logic 所管 / Spec 6 = skill prompt 内容所管)、design ではこれらの interface contract を具体化する
  - design phase 持ち越し 5 項目 (対話ログ markdown フォーマット / Skill frontmatter 任意 field 値域 / HTML 差分マーカー attribute / frontmatter_completion 出力先 / R15.4 判定基準) を本 design で解消する必要

## Research Log

### Topic 1: v1 → v2 概念進化と 8 section スキーマの起源

- **Context**: Skill ファイルの 8 section スキーマがどこから来たか、v1 知識をどこまで活用できるか
- **Sources Consulted**:
  - `v1-archive/templates/AGENTS/README.md` (9 task type 一覧 + 8 section スキーマ要件)
  - `v1-archive/templates/AGENTS/synthesize.md` (8 section の具体例)
  - `v1-archive/templates/CLAUDE.md` (Failure Conditions Judgment Criteria、8 section 不備時 stop)
- **Findings**:
  - v1 ではタスク種別ごとに `AGENTS/<task>.md` を 1:1 配置、`synthesize` のように出力固定タスクが知識生成の柔軟性を阻害していた
  - 8 section 構造 (Purpose / Execution Mode / Prerequisites / Input / Output / Processing Rules / Prohibited Actions / Failure Conditions) は v1 から確立済、Failure Condition Judgment Criteria が「不備時 stop」を明文化していた
  - v1 には `page_policy.md` / `naming.md` / `git_ops.md` の 3 ポリシーファイルが共存、v2 では skill 単独動作 + 共通規範は steering / Foundation に集約される構造に変化
- **Implications**:
  - 8 section の必須化と「Failure Conditions の次のアクション」必須化 (R2.4) は v1 経験を踏襲した正当化済の設計選択
  - v2 で 9 task → 15 skill に拡張しても、各 skill が独立 .md ファイルなので追加コストは小さい (skill ファイル独立性の維持)

### Topic 2: 3 subject の境界と Module 分割

- **Context**: 15 skill の管理機能を 1 module に集約すると Spec 5 Decision 5-17 と同型の容量超過リスクが生じる、TODO_NEXT_SESSION.md L125-126 でも警告
- **Sources Consulted**:
  - `.kiro/specs/rwiki-v2-knowledge-graph/design.md` Decision 5-17 (Hygiene 機能別 3 sub-module 分割)
  - `.kiro/specs/rwiki-v2-lifecycle-management/design.md` Decision 7-21 (Layer 4 を 3 sub-module 化、handler 17 種 ~2000 行 estimate で制約超過回避)
  - `.kiro/steering/structure.md` Code Organization Principles「モジュール責務分割」
  - Spec 4 決定 4-3 (≤ 1500 行制約)
- **Findings**:
  - Spec 5 / Spec 7 とも「機能別 sub-module 分割」を採用しており、Spec 2 でも同パターンが妥当
  - Skill Library 機能の性質を分類すると静的 catalog (read-only) / 動的 lifecycle (state machine) / 純粋 validation (stateless) の 3 系統に分離可能
  - 各 module 行数 estimate: rw_skill_library.py ≤ 300 行 (catalog load / list / show) + rw_skill_validator.py ≤ 500 行 (4 validation 種) + rw_skill_authoring.py ≤ 700 行 (7 段階 workflow + dry-run)
- **Implications**:
  - 3 sub-module 分割を Decision 2-1 として採用、各 module ≤ 1500 行制約を遵守
  - Module DAG = `rw_skill_library` ← `rw_skill_validator` ← `rw_skill_authoring` の 1 方向 import (sibling import 禁止、cyclic 禁止)
  - Layer 4 (Spec 7 cmd_skill_install) からは rw_skill_authoring を呼出、Layer 4a Page handler との sibling import は発生しない (Skill 内容と Page lifecycle は独立)

### Topic 3: 対話ログ markdown フォーマットの設計選択

- **Context**: design phase 持ち越し 1 項目 (R15.2)、drafts §2.11 で命名規則の表記揺れ (`chat-sessions/` / `interactive-<skill>/` / `manual/`) と Turn 内部 schema 未確定
- **Sources Consulted**:
  - `.kiro/drafts/rwiki-v2-consolidated-spec.md` §2.11 (`raw/llm_logs/{interactive,chat-sessions,manual}/` 構造記述)
  - Scenario 15 (interactive_synthesis 出力)、Scenario 25 (llm_log_extract 入力)
  - `.kiro/specs/rwiki-v2-cli-mode-unification/design.md` 決定 4-13 (session_id 形式 = `<timestamp>-<8 hex>`)
  - Spec 0 §2.7 エディタ責務分離原則 (人間可読 + 機械可読の両立)
- **Findings**:
  - drafts §2.11 では subdirectory 形式 (`interactive/`) と ファイル名形式 (`interactive-<skill>-<timestamp>.md`) が混在、design phase で一意化が必要
  - Turn 内部 schema の選択肢は (A) Markdown 見出し構造 (`## Turn N - ISO 8601` + `**User:** / **Assistant:**`) / (B) 自由形式 + frontmatter のみ機械可読 / (C) frontmatter 内 `turns:` 配列 + 本文補助記述 の 3 案
  - Spec 4 G1 ChatEntry 実装は `init_session_log()` + `ended_at` 追記 (decision 4-13) で保存実装を所管、本 spec はスキーマ規約のみ
- **Implications**:
  - **Decision 2-6** で案 A (Markdown 見出し構造 + frontmatter 件数記録) 採用 → 人間可読維持 + Turn append-save 単位明確化 + 機械側は Turn 件数のみ参照
  - **Decision 2-7** でディレクトリ命名規則を 3 区別に統一 (`chat-sessions/` = rw chat / `interactive/<skill_name>/` = interactive skill 起源 / `manual/` = 手動 import) → drafts §2.11 表記揺れ解消、Adjacent Sync 経由で drafts §2.11 / Spec 4 R1.8 へ反映

### Topic 4: HTML 差分マーカー attribute (Spec 4 決定 4-8 委譲)

- **Context**: design phase 持ち越し 3 項目 (Important I-3、R10.4)、Spec 4 決定 4-8 / Spec 7 lifecycle merge 仕様と整合させる必要
- **Sources Consulted**:
  - `.kiro/specs/rwiki-v2-cli-mode-unification/design.md` 決定 4-8 (HTML 差分マーカー attribute = Phase 2/3 Spec 2 / Spec 7 design 委譲)
  - Spec 7 design (lifecycle merge 仕様 = `merge_strategy` field、Spec 6 cmd_promote_to_synthesis 経由)
  - R10.2 / R10.4 (`<!-- rw:extend:start ... -->` / `<!-- rw:extend:end -->` 開始/終了マーカー対)
- **Findings**:
  - Spec 7 lifecycle merge 仕様には wiki ページ単位の `merge_strategy` 概念が存在するが、これは別 wiki ページ間の merge 操作 (deprecate → successor)、本 spec の Skill 出力差分マーカーとは目的が異なる
  - 差分マーカーの最小必須 attribute = (a) `target` (拡張対象 wiki page path、機械的に lifecycle merge handler が認識) + (b) `reason` (拡張理由 1 行、人間レビュー支援)
  - Phase 2 拡張候補: `merge_strategy` (Spec 7 merge 仕様連携) / `confidence` (LLM 確信度) / `evidence_id` (L2 evidence.jsonl 参照) — MVP では除外
- **Implications**:
  - **Decision 2-8** で MVP attribute = `target` + `reason` の 2 種必須、validator が両者欠落時 ERROR severity 報告
  - Phase 2 以降で Spec 7 lifecycle merge 仕様との整合拡張を Adjacent Sync 経由で実施

### Topic 5: frontmatter_completion 出力先 review path

- **Context**: design phase 持ち越し 4 項目 (R6.2)、drafts §11.2 「review via `rw lint --fix`」記述
- **Sources Consulted**:
  - drafts §11.2 (lint 支援 skills、`frontmatter_completion` の用途 = 不足 frontmatter 補完提案)
  - Scenario 26 (lint-fail recovery)、Spec 5 R11 (decision_log)
  - 既存 review/ 層 (`synthesis_candidates/` / `relation_candidates/` / `vocabulary_candidates/` / `skill_candidates/` / `audit_candidates/` / `hypothesis_candidates/`) の意味的分類
- **Findings**:
  - 既存 review/ 層は「LLM 生成候補 → human approve」の workflow に統一されており、frontmatter_completion の出力 (補完提案 = 自動修復候補) は意味的に異なる (人間 review というより lint --fix の修復候補)
  - `synthesis_candidates/` 流用は不適切 (synthesis = 知識生成、補完提案とは別概念)
  - 新設候補: `review/lint_proposals/<filename>-completion.md` (1 ファイル 1 提案、決定後採用 / 棄却 / 部分採用は decision_log に記録 = R6.3)
- **Implications**:
  - **Decision 2-9** で `review/lint_proposals/` 新設、`<original_filename>-completion.md` 命名規約
  - Adjacent Sync 経路: drafts §11.2 / steering structure.md の review/ 層構造表 / Spec 1 (lint --fix の動作箇所)

### Topic 6: R15.4 判定基準と Skill frontmatter 任意 4 field 集約 (軽-A / 軽-D)

- **Context**: design phase 持ち越し 5 項目 (R15.4) + 軽微整理 2 件 (軽-A / 軽-D)
- **Sources Consulted**:
  - R3.2 (`applicable_categories` / `applicable_input_paths` 任意 field)
  - R15.3 (`dialogue_guide` / `auto_save_dialogue` 任意 field)、R15.4 (「対話ログを生成または依拠する skill (...等)」)
  - R5.5 (Spec 2 = SSoT、Spec 5 = validation 実装)、R5.6 (変更時 Adjacent Sync 手順)
- **Findings**:
  - 「対話ログを生成または依拠する skill (...等)」の「等」は要件曖昧化、明示判定基準の不在で R15.4 必須記載対象が判定不能
  - frontmatter 任意 4 field は R3 (`applicable_categories` / `applicable_input_paths`) と R15.3 (`dialogue_guide` / `auto_save_dialogue`) に分散、design では 1 表に統合表示が読解性高
  - R5.5 と R5.6 は意味的に独立 (R5.5 = interface ownership 静的、R5.6 = 変更時手順 動的) なので統合せず分離維持が妥当
- **Implications**:
  - **Decision 2-10** で R15.4 判定基準 = 「frontmatter `interactive: true` または `auto_save_dialogue: true` のいずれかが真」+ 明示列挙 3 種 (`interactive_synthesis` / `frontmatter_completion` / `llm_log_extract`) を併記、validator が必須記載 check
  - **Decision 2-11** で Skill frontmatter 全 11 field (必須 7 + 任意 4) を Components & Interfaces section に 1 表で統合表示、軽-A 解消
  - 軽-D は requirements.md の R5.5 / R5.6 を維持、design では役割明確化のため両者の意味的差分を明示説明

### Topic 7: Lock + Atomic 機構 (Spec 5 / Foundation 同パターン)

- **Context**: R9.6 atomic install + R13.8 hygiene.lock 取得 (write 系 3 操作)
- **Sources Consulted**:
  - Spec 5 design Decision 5-3 (fcntl.flock + fail-fast LOCK_NB + POSIX 限定)
  - Spec 5 design Decision 5-4 (Atomic rename 5 step + macOS F_FULLFSYNC)
  - Foundation R11.5 (`.rwiki/.hygiene.lock` 必須、ディレクトリ排他)
  - Spec 4 design G5 LockHelper (`acquire_lock(kind)` API、kind = `'graph'` / `'tag'` / `'skill'`)
- **Findings**:
  - Spec 4 G5 LockHelper が既に skill 用 lock 取得 API を提供 (Adjacent Sync 反映済)、本 spec は `from rw_lock import acquire_lock` で `acquire_lock('skill')` 呼出
  - Atomic install operation は Spec 5 R7.11 と同パターン: (1) candidate を tmp ディレクトリに copy、(2) 4 validation 全件実行、(3) atomic rename で `AGENTS/skills/<name>.md` に配置、(4) 成功時 candidate ファイル削除、(5) 失敗時 tmp 削除 + candidate 残置
  - macOS の `F_FULLFSYNC` は Spec 5 で採用、本 spec でも同等の fsync 必須
- **Implications**:
  - **Decision 2-4** で Atomic install operation 5 step 採用、Spec 5 Decision 5-4 同パターン
  - **Decision 2-5** で `acquire_lock('skill')` 経由の lock 取得 + write 系 3 操作 (`draft` / `test` / `install`) のみ対象 (read-only `list` / `show` は対象外)
  - Spec 4 G5 LockHelper は既存実装、本 spec は consumer のみで build しない

### Topic 8: Skill validator の 4 種独立関数化 + 全件 report

- **Context**: R9.1 (4 種 validation = 8 section / YAML / 衝突 / 参照整合性)、R9.2 (失敗時 ERROR severity)
- **Findings**:
  - 4 種 validation はそれぞれ独立した check (依存関係なし、順序自由)、共通の Validator interface で抽象化可能
  - UX 改善観点: 1 件目失敗で short-circuit すると修正サイクルが長期化、全件実行 → 全件 report が望ましい
  - 各 validation の実装は標準 Python 機能で完結 (PyYAML / re / pathlib / glob)、新規 dependency 不要
- **Implications**:
  - **Decision 2-13** で 4 種 validation を独立関数化 + 一括実行 + 全件 report (UX 改善)
  - 各 validation は `(skill_path: Path, severity_collector: SeverityCollector) -> None` signature 統一

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| 1 module 集約 | Library / Validator / Authoring を 1 module に集約 | import 経路最小、ファイル数少 | Spec 5 Decision 5-17 / Spec 7 Decision 7-21 同型容量超過リスク (~1500 行 estimate)、責務分離不明確 | 採択せず |
| **3 sub-module 分割** | Library / Validator / Authoring を別 module 化 | 各 module ≤ 1500 行制約遵守、責務明快、test 単位明快 | import 経路 3 段階、ファイル数増 | **採択** (Decision 2-1) |
| 機能別 5 module 分割 | 4 validation 種をそれぞれ別 module 化 | 各 validator 独立性最大化 | over-fragmentation、各 module < 200 行で 5 module は冗長 | 採択せず |
| Custom skill generator = Spec 4 流用 | 8 段階対話 generator base + StageEvent dataclass を sibling import | コード再利用 | 目的不一致 (危険操作確認 vs skill 生成)、共通化メリット小 | 採択せず |
| **Custom skill generator = 独自実装** | 7 段階対話 generator を本 spec で新設 | 目的特化、import 依存最小 | コード重複 (StageEvent 類似) 但し小規模 | **採択** (Decision 2-3) |

## Design Decisions

### Decision 2-1: Module 数 = 3 sub-module 分割

- **Context**: 15 skill 管理機能を 1 module 集約すると Spec 5 Decision 5-17 / Spec 7 Decision 7-21 同型問題 (容量超過 + 責務分離不明確) が発生、TODO_NEXT_SESSION.md L125-126 でも警告
- **Alternatives Considered**:
  1. 1 module 集約 — import 経路最小だが容量超過リスク
  2. 3 sub-module 分割 (Library / Validator / Authoring)
  3. 機能別 5 module 分割 (4 validation 種を更に分離) — over-fragmentation
- **Selected Approach**: 3 sub-module 分割。`rw_skill_library.py` (catalog, ≤ 300 行) / `rw_skill_validator.py` (4 validation, ≤ 500 行) / `rw_skill_authoring.py` (7 段階 workflow + dry-run, ≤ 700 行)
- **Rationale**: Spec 4 決定 4-3 ≤ 1500 行制約遵守 + 機能別 boundary 明快 (静的 catalog / 純粋 validation / 動的 lifecycle) + Spec 5 / Spec 7 同パターン
- **Trade-offs**: import 経路 3 段階に増加 (read 1 方向)、ファイル数 +2 — 容量と責務分離の利益が上回る
- **Follow-up**: 各 module 行数を実装時に測定、≤ 1500 行制約超過時は更に分割検討

### Decision 2-2: Skill ファイル parser = 標準 `re` モジュール

- **Context**: 8 section 検出と差分マーカー parse の実装手段
- **Alternatives Considered**:
  1. 専用 parser (markdown-it 等) — 過剰機能、新規 dependency
  2. `re` モジュール (`^## ` 見出し抽出 + `<!-- rw:extend:* -->` regex) — Python 標準
  3. mistune ライブラリ — 8 section 構造のみで AST 不要
- **Selected Approach**: `re` モジュール標準利用。8 section = `^## (Purpose|Execution Mode|...)$` regex match、差分マーカー = `<!--\s*rw:extend:(start|end)([^>]*)-->` regex
- **Rationale**: 構造単純で正規表現で十分、新規 dependency 不要、テスト容易
- **Trade-offs**: 複雑な markdown 構造には弱い — 本 spec の用途では問題なし
- **Follow-up**: skill ファイル本文の自由 section (Examples / Notes / Changelog) も regex で抽出可能性確認

### Decision 2-3: Custom skill 7 段階対話 generator = 独自実装

- **Context**: R7.1 の 7 段階対話フロー (意図確認 / 情報収集 / 草案生成 / Validation / Dry-run / 修正ループ / Install) の実装手段
- **Alternatives Considered**:
  1. Spec 4 8 段階対話 generator base + StageEvent dataclass を sibling import 流用 — 目的不一致
  2. 本 spec で独自 7 段階対話 generator 新設
- **Selected Approach**: 独自実装。Skill Authoring Workflow 内に `draft_skill_generator(...)` / `test_skill_generator(...)` / `install_skill_generator(...)` の 3 つの generator function を定義、yield で各段階の対話 event を返す
- **Rationale**: 8 段階対話 (危険操作確認、Page lifecycle) と 7 段階対話 (skill 生成) は目的が異なり、StageEvent dataclass の `--auto` flag 等の概念が直接適用できない。Spec 7 Decision 7-21 でも Page と Skill は別 generator function と決定済、同パターン
- **Trade-offs**: コード重複 (event yield pattern が小規模重複) — 目的特化のメリットが上回る
- **Follow-up**: 7 段階の各 yield event を共通 dataclass `SkillStageEvent` に統一、Spec 4 G3 が caller として受領

### Decision 2-4: Install operation atomic 機構

- **Context**: R9.6 atomic install (process kill / disk full / OOM 時の状態復帰)
- **Alternatives Considered**:
  1. naive `os.rename` 単独 — validation 通過前の partial 状態が `AGENTS/skills/` に出現するリスク
  2. tmp ディレクトリ + 全 validation → atomic rename (Spec 5 R7.11 同パターン)
  3. 2-phase commit (database 風) — 過剰、Skill ファイルは単一 .md のみ
- **Selected Approach**: 5 step atomic install: (1) candidate → `AGENTS/skills/.tmp_<name>.md` に copy / (2) tmp ファイルに対し 4 validation 全件実行 / (3) 全件通過時 `os.rename(.tmp_<name>.md, <name>.md)` で atomic 配置 / (4) macOS の場合 `F_FULLFSYNC` で fsync 強制 / (5) 成功時 candidate ファイル削除、失敗時 tmp 削除 + candidate 残置
- **Rationale**: Spec 5 Decision 5-4 と同パターン、process kill 時の partial state 防止、POSIX `rename(2)` の atomicity 保証活用
- **Trade-offs**: tmp ファイル一時生成のオーバーヘッド (< 1KB skill ファイル、無視可能)
- **Follow-up**: Windows 非対応 (Spec 5 Decision 5-3 同パターン、Phase 2/3 拡張余地)

### Decision 2-5: Lock 取得 = `.rwiki/.hygiene.lock` 経由 (Spec 4 G5 LockHelper)

- **Context**: R13.8 write 系 3 操作 (`rw skill draft / test / install`) の lock 取得
- **Alternatives Considered**:
  1. 本 spec 独自の skill 専用 lock ファイル — Spec 5 / Spec 1 / Spec 4 と分離、deadlock 検出複雑化
  2. `.rwiki/.hygiene.lock` 共通利用 (Spec 4 G5 `acquire_lock('skill')` 経由)
- **Selected Approach**: Spec 4 G5 `acquire_lock('skill')` 経由で `.rwiki/.hygiene.lock` 取得。read-only (`list` / `show`) は lock 不要、write 系 3 操作のみ対象
- **Rationale**: Foundation R11.5 / Spec 5 R17 / Spec 1 R8.14 と同パターン、Hygiene batch / vocabulary 操作 / 他 skill install との並行衝突を排他制御、deadlock 検出統一
- **Trade-offs**: Hygiene batch 実行中は skill 操作 blocking、ただし MVP single-thread 前提で問題なし
- **Follow-up**: `applicable_categories` 値域参照整合性 (Spec 1 categories.yml) との整合は read-only check のため lock 不要だが、categories.yml 編集中の skill install は WARN 提示

### Decision 2-6: 対話ログ markdown フォーマット = `## Turn N - ISO 8601` 見出し形式

- **Context**: design phase 持ち越し 1 項目 (R15.2)、Turn 内部 schema + append-save 単位の確定
- **Alternatives Considered**:
  1. Markdown 見出し構造 (`## Turn N - ISO 8601` + `**User:** / **Assistant:**`) — 人間可読 + 機械可読 (Spec 0 §2.7)
  2. 自由形式 markdown + frontmatter のみ機械可読 — Turn 単位 append-save 困難
  3. frontmatter 内 `turns:` 配列 + 本文補助記述 — 大規模 session で frontmatter 肥大化
- **Selected Approach**: 案 A 採用。Turn 内部 schema = `## Turn <N> - <ISO 8601 timestamp>` 見出し + `**User:**\n<content>\n\n**Assistant:**\n<content>` 形式 + frontmatter `turns: <integer>` で件数記録
- **Rationale**: 人間可読 (markdown 見出しでナビゲーション) + 機械可読 (regex で Turn 抽出可能) + append-save 単位明快 (Turn 1 件 = 1 見出しブロック追記) + frontmatter 軽量 (件数のみ)
- **Trade-offs**: Turn 内部の attachment / metadata 表現は本文埋め込み (例: ` ```code ``` ブロック)、構造化が必要な場合は Phase 2 拡張
- **Follow-up**: Spec 4 G1 ChatEntry 実装が本決定に従う、Adjacent Sync 経由で Spec 4 R1.8 + drafts §2.11 反映

### Decision 2-7: 対話ログディレクトリ命名規則 = 3 区別

- **Context**: design phase 持ち越し 1 項目 (R15.2)、drafts §2.11 表記揺れ (`chat-sessions/` / `interactive-<skill>/` / `manual/`) の一意化
- **Alternatives Considered**:
  1. ファイル名 prefix 区別 (`chat-<id>.md` / `interactive-<skill>-<id>.md` / `manual-<id>.md`) — 検索性低
  2. subdirectory 区別 (`raw/llm_logs/{chat-sessions, interactive, manual}/`)
  3. 単一ディレクトリ + frontmatter `mode` field 区別 — 物理分離なし
- **Selected Approach**: subdirectory 3 区別。`raw/llm_logs/chat-sessions/<timestamp>-<session-id>.md` (rw chat 起源) / `raw/llm_logs/interactive/<skill_name>/<timestamp>-<session-id>.md` (interactive skill 起源、skill 別 sub-subdirectory) / `raw/llm_logs/manual/<timestamp>-<session-id>.md` (手動 import 起源)
- **Rationale**: drafts §2.11 表記揺れ解消、interactive skill 起源は skill 名で更に分類 (skill 別の log 集約が容易)、Spec 4 G1 ChatEntry 実装で path 解決が単純化
- **Trade-offs**: ディレクトリ階層 +1、glob match 表現がやや複雑化 (`raw/llm_logs/**/*.md`) — 検索性 / 管理性のメリットが上回る
- **Follow-up**: Adjacent Sync 経路 = drafts §2.11 改版 + Spec 4 R1.8 改版 (本 spec design 由来 coordination)

### Decision 2-8: HTML 差分マーカー attribute = `target` + `reason` MVP

- **Context**: design phase 持ち越し 3 項目 (R10.4)、Spec 4 決定 4-8 / Spec 7 lifecycle merge 仕様と整合
- **Alternatives Considered**:
  1. attribute なし (空マーカー `<!-- rw:extend:start -->`) — 拡張対象不明、機械処理不能
  2. `target` + `reason` 2 種必須 (MVP)
  3. `target` + `reason` + `merge_strategy` + `confidence` + `evidence_id` 5 種 (Phase 2 fully)
- **Selected Approach**: MVP attribute = `target="<wiki/page/path>"` (拡張対象 wiki ページ path、必須) + `reason="<拡張理由 1 行>"` (人間レビュー支援、必須)。両者欠落時 ERROR severity 報告
- **Rationale**: 機械処理 (target) + 人間レビュー (reason) の最小集合、Spec 7 lifecycle merge 仕様 (`merge_strategy` 等) は Phase 2 拡張余地として保留
- **Trade-offs**: Phase 2 で attribute 追加時の既存 skill 出力との後方互換性 — 追加 attribute は optional default で互換維持
- **Follow-up**: Spec 7 lifecycle merge 仕様確定後、`merge_strategy` 連携を Adjacent Sync 経由で追加検討

### Decision 2-9: frontmatter_completion 出力先 = `review/lint_proposals/`

- **Context**: design phase 持ち越し 4 項目 (R6.2)、drafts §11.2 「review via `rw lint --fix`」記述
- **Alternatives Considered**:
  1. `review/synthesis_candidates/` 流用 — 意味不一致 (synthesis vs 補完提案)
  2. `review/lint_proposals/` 新設
  3. `review/audit_candidates/` 流用 — audit と lint は対象 layer 異なる
- **Selected Approach**: `review/lint_proposals/<original_filename>-completion.md` 新設。1 ファイル 1 提案、frontmatter `proposal_for: <original_path>` + `confidence: low | medium | high` + 補完 frontmatter 本文記述
- **Rationale**: 既存 review/ 層と意味分離、lint --fix workflow 専用、採用 / 棄却 / 部分採用判断は decision_log (Spec 5 所管) に記録 (R6.3)
- **Trade-offs**: review/ 層が 1 サブディレクトリ増 — 意味的明確化のメリットが上回る
- **Follow-up**: Adjacent Sync 経路 = drafts §11.2 改版 + steering structure.md review/ 層構造表改版 + Spec 1 lint --fix 動作箇所への参照点設置

### Decision 2-10: R15.4 判定基準 = `interactive: true` または `auto_save_dialogue: true` + 明示列挙 3 種

- **Context**: design phase 持ち越し 5 項目 (R15.4)、「対話ログを生成または依拠する skill (...等)」の「等」解釈
- **Alternatives Considered**:
  1. 明示列挙 3 種のみ — 拡張時の追加 skill が判定対象外、規範後退
  2. `interactive: true` のみ — `auto_save_dialogue: true` (interactive=false でログ保存) を見落とし
  3. 両 frontmatter field の OR 条件 + 明示列挙併記
- **Selected Approach**: 「frontmatter `interactive: true` または `auto_save_dialogue: true` のいずれかが真」+ 明示列挙 3 種 (`interactive_synthesis` / `frontmatter_completion` / `llm_log_extract`) を併記。validator は 8 section 検査時に当該 skill の Output / Input section に対話ログ frontmatter スキーマ参照点 (R15.1) があるか check、欠落時 ERROR
- **Rationale**: 機械的判定基準 (frontmatter field) + 明示列挙 (現存 skill) の併記で、現存と将来拡張の両方をカバー
- **Trade-offs**: validator が frontmatter field を check する実装複雑化 (1 行追加) — 拡張性のメリットが上回る
- **Follow-up**: 将来 skill 追加時に `interactive` / `auto_save_dialogue` のいずれかが真なら自動的に R15.4 必須記載対象、追加 spec 改版不要

### Decision 2-11: Skill frontmatter 11 field の R3 集約表示 (軽-A 解消)

- **Context**: requirements 記述精度懸念 軽-A、R3 と R15.3 で frontmatter 任意 field が分散
- **Alternatives Considered**:
  1. requirements.md を改版して R3 に 4 任意 field 集約 — requirements.md 再 approve 必要、コスト高
  2. design.md Components & Interfaces section に 1 表で全 11 field 統合表示 (必須 7 + 任意 4)
- **Selected Approach**: 案 2。design Components SkillCatalog の表に必須 7 field (`name` / `origin` / `version` / `status` / `interactive` / `update_mode` / `handles_deprecated`) + 任意 4 field (`applicable_categories` / `applicable_input_paths` / `dialogue_guide` / `auto_save_dialogue`) を 1 表で統合表示
- **Rationale**: requirements.md の責務 (規範定義) と design.md の責務 (実装可能性) を分離、design 側で読解性向上
- **Trade-offs**: requirements.md と design.md の表現重複 — design.md は design 視点で再整理 (実装に必要な順序)、重複でなく相補
- **Follow-up**: design.md 改版時に table 整合性を維持

### Decision 2-12: dry-run failure handling 4 種統一 ERROR

- **Context**: R7.4 dry-run 失敗種別 (`timeout` / `crash` / `output_error` / その他)、severity 統一の必要
- **Alternatives Considered**:
  1. 失敗種別ごとに severity 区別 (`timeout` = WARN / `crash` = ERROR 等) — 判断基準が複雑
  2. 全失敗種別 ERROR 統一 + 失敗種別を report に明示
- **Selected Approach**: 全失敗種別 ERROR 統一。`dry_run_passed: false` を維持し、report に `failure_kind: timeout | crash | output_error | dry_run_internal_error` + `failure_detail: <string>` を記載
- **Rationale**: dry-run 失敗 = install 拒否 (R8.1) の同一帰結、severity 区別は無意味、UX 観点で「dry-run 失敗 = ERROR」一貫性が分かりやすい
- **Trade-offs**: timeout は LLM CLI subprocess の一時的問題で再試行可能性あり — report に再試行推奨を併記してユーザー対処
- **Follow-up**: Phase 2 で dry-run 自動再試行 (timeout 専用) の検討余地

### Decision 2-13: Skill validator 4 種独立関数化 + 全件 report

- **Context**: R9.1 4 種 validation の実装手段、UX 改善
- **Alternatives Considered**:
  1. 4 種を 1 関数に集約、1 件目失敗で short-circuit — 修正サイクル長期化
  2. 4 種独立関数 + 順次実行で 1 件目失敗 short-circuit — 失敗箇所のみ report
  3. 4 種独立関数 + 一括実行 + 全件 report
- **Selected Approach**: 案 3。各 validation を `(skill_path: Path, severity_collector: SeverityCollector) -> None` signature 統一、4 関数を順次実行 (依存なし、順序自由) + SeverityCollector が全件報告を集約 + 1 件以上 ERROR で install 拒否
- **Rationale**: UX 改善 (1 度の dry-run で全エラー把握) + 各 validation 独立 (test 単位明快)
- **Trade-offs**: validation 4 種すべてを実行するため、1 件目で停止する場合より所要時間 +α (skill ファイル read は 1 回、parse 4 回 = 数 ms オーダー、無視可能)
- **Follow-up**: SeverityCollector は Foundation R11 の severity infra 共通利用

### Decision 2-14: Standard skill 15 種 path table の固定 (`rw init` 配布 manifest)

- **Context**: R11.3 standard skill 初期配布数 = 15 種、R11.6 配布完整性 check
- **Alternatives Considered**:
  1. ハードコード list (Python source 内 `STANDARD_SKILLS = [...]`) — Spec 4 から見えにくい
  2. `.rwiki/config.yml` 内 `standard_skills:` field — config 改ざんで rw init 失敗リスク
  3. 本 spec design Migration Strategy section + `rw_skill_library.STANDARD_SKILLS` 定数で固定
- **Selected Approach**: 案 3。`rw_skill_library.py` に `STANDARD_SKILLS: tuple[str, ...] = (paper_summary, ..., frontmatter_completion)` 15 件 frozen tuple 定数として固定、design Migration Strategy section にも path table を記載
- **Rationale**: hardcode による改ざん耐性 (config 経由でない) + design ドキュメントへの可視化、配布完整性 check は同 tuple を参照
- **Trade-offs**: 標準 skill 追加時に rw_skill_library.py の改版必要 — 配布側仕様変更なので Adjacent Sync で問題なし
- **Follow-up**: `rw init` 実行時に各 skill ファイルの存在確認 + frontmatter `origin: standard` 確認、不在 / 不一致は ERROR

### Decision 2-15: Skill frontmatter 任意 field 値域

- **Context**: design phase 持ち越し 2 項目 (R15.3)、`dialogue_guide` / `auto_save_dialogue` の値域
- **Alternatives Considered**:
  1. 厳格 schema (各 field の constraint 詳細) — over-specification
  2. 最小規定 (string / bool のみ)
- **Selected Approach**: 案 2 最小規定。`dialogue_guide` 値域 = string (free text、対話ガイド prompt) / `auto_save_dialogue` 値域 = bool (true / false)。Skill Validator が型 check のみ実行
- **Rationale**: MVP では運用詳細を skill 作者の自由に委ね、過剰 specification を避ける。Phase 2 で運用パターン蓄積後に schema 厳格化検討
- **Trade-offs**: free text による表記揺れ — Phase 2 で実例蓄積後に標準化
- **Follow-up**: Phase 2 で `dialogue_guide` の正規化パターン (例: 質問テンプレート構造) を Adjacent Sync で追加検討

## Risks & Mitigations

- **Risk 1**: Skill 1 module 集約への将来回帰 (Phase 2 で機能追加時に 3 sub-module → 1 module に巻き戻すリスク) — Mitigation: design に「3 sub-module 分割の理由」を明示記録、各 module の責務性質 (静的 / 純粋 / 動的) を boundary 説明
- **Risk 2**: Custom skill 7 段階対話 generator の StageEvent 類似実装が Spec 4 8 段階対話と微妙に乖離 (event field の意味的差) — Mitigation: 本 spec で `SkillStageEvent` を独自定義、Spec 4 `StageEvent` と意図的に分離 (流用しないことを明示)
- **Risk 3**: 対話ログ markdown フォーマット (Decision 2-6 / 2-7) の Adjacent Sync 失敗 (drafts §2.11 / Spec 4 R1.8 の連鎖更新漏れ) — Mitigation: design Migration Strategy section に Adjacent Sync 経路を明示記録、approve 時に Spec 4 / drafts への反映を同時実施
- **Risk 4**: Atomic install operation の OS 依存 (POSIX 限定、Windows 非対応) — Mitigation: Spec 5 Decision 5-3 と同パターン、Windows サポートは Phase 2/3 拡張余地として明示記録 (Foundation / roadmap.md 改版が必要)
- **Risk 5**: `applicable_categories` 値域 (Spec 1 categories.yml 参照) の categories.yml 編集中 race condition — Mitigation: skill install 時の参照整合性 check は read-only (lock 不要)、categories.yml の編集中に skill install 実行で WARN severity 報告 + 参照失敗時の retry 推奨

## References

- `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §2.8 / §5.6 / §5.7 / §7.2 Spec 2 / §11.2 — 出典 SSoT
- `.kiro/specs/rwiki-v2-skill-library/requirements.md` — 15 Requirement / AC 数 83 (approved 2026-04-27)
- `.kiro/specs/rwiki-v2-knowledge-graph/design.md` Decision 5-3 (fcntl.flock + POSIX) / Decision 5-4 (atomic rename + F_FULLFSYNC) / Decision 5-17 (Hygiene 機能別 3 sub-module) — 同パターン採用先
- `.kiro/specs/rwiki-v2-lifecycle-management/design.md` Decision 7-21 (Layer 4 sub-module 分割) / Decision 7-15 (Skill lifecycle 対話階段) / Decision 7-16 (Page と Skill 別 handler 関数) — Skill lifecycle 委譲先
- `.kiro/specs/rwiki-v2-cli-mode-unification/design.md` 決定 4-3 (≤ 1500 行制約) / 決定 4-8 (HTML 差分マーカー attribute 委譲) / 決定 4-10 (AGENTS hash 検知 MVP 外) / 決定 4-13 (session_id 形式) / G5 LockHelper — CLI dispatch 委譲元
- `.kiro/specs/rwiki-v2-classification/design.md` G3 categories.yml 5 項目 / R11.2 categories.yml.default_skill — Spec 1 connection
- `.kiro/specs/rwiki-v2-foundation/design.md` R11.5 hygiene.lock — Foundation 規範
- `v1-archive/templates/AGENTS/README.md` + `synthesize.md` + `CLAUDE.md` — v1 8 section スキーマ起源
- `.kiro/steering/structure.md` review/ 層構造表 + Code Organization Principles — Adjacent Sync 影響先

---

_change log_

- 2026-04-28: 初版生成 (Discovery 完了 + Synthesis 適用 + Decision 2-1 〜 2-15 の 15 件設計判断記録、design.md と並行生成)
