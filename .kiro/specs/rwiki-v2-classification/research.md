# Research & Design Decisions: rwiki-v2-classification

## Summary

- **Feature**: `rwiki-v2-classification`
- **Discovery Scope**: Extension (Foundation = Spec 0 を上位規範とし、L3 Curated Wiki の分類体系基盤を確立する。新規 implementation = vocabulary 3 種 + `rw tag *` 13 サブコマンド + lint vocabulary 統合 + frontmatter 8 種固有スキーマ。フルスクラッチ方針)
- **Key Findings**:
  - Spec 1 brief.md には design phase 持ち越し項目が **約 42 件** 集積されており、第 1-6 ラウンドの requirements review 経緯から各 escalate 案件が明示されている
  - 新規 library 依存不要 — すべて Python 標準ライブラリ (`pyyaml` / `unicodedata` / `pathlib` / `difflib`) で実装可能
  - L3 frontmatter `related:` は Spec 5 derived cache、Entity ショートカットは Spec 5 で typed edge へ展開 — 本 spec は schema 宣言と vocabulary mapping table のみ所管
  - Coordination が極めて多い: Spec 3 (frontmatter `type:` / `categories.yml.default_skill`) / Spec 4 (lint / `rw approve` / `.hygiene.lock`) / Spec 5 (`normalize_frontmatter` / `relations.yml` / `record_decision()`) / Spec 7 (page lifecycle field セマンティクス) / Foundation (R12.4 vocabulary 操作の解釈拡張)

## Research Log

### consolidated-spec §5 / §6.2 確認

- **Context**: Spec 1 の SSoT 出典を baseline として確認、frontmatter スキーマ詳細と `rw tag *` コマンド一覧の現状を把握
- **Sources Consulted**: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §5 (frontmatter スキーマ全 9 サブセクション) / §6.2 Tag Vocabulary table / §7.2 Spec 1 / Spec 0 design.md `foundation §5 frontmatter 骨格`
- **Findings**:
  - §5.1-§5.3 共通必須 / 推奨 / 任意 field は yaml 形式で集約済、本 spec が引き受ける詳細スキーマと整合
  - §5.4 Wiki ページ固有 (lifecycle / typed edges derived cache / Entity ショートカット / update_history) も spec ベース
  - §5.5-§5.9.2 Review レイヤー / Skill / Vocabulary candidate / Follow-up / Hypothesis / Perspective 各 frontmatter は本 spec or Spec 2 / Spec 6 / Spec 7 で所管確定
  - §6.2 Tag Vocabulary command 一覧 = R8 の 13 サブコマンドと完全整合 (drafts → requirements への忠実な移植確認済)
- **Implications**:
  - design.md §「Components G2 Frontmatter スキーマ」「Components G4 Tag CLI」は consolidated-spec §5 / §6.2 を baseline とし、各設計決定で具体化を加える形式
  - foundation.md §5 (frontmatter 骨格) → Spec 1 詳細スキーマの委譲チェーンが完成

### v1-archive vocabulary patterns 確認

- **Context**: v2 はフルスクラッチ方針だが、v1 で tags 体系が部分実装されていた可能性を確認
- **Sources Consulted**: `v1-archive/scripts/` / `v1-archive/tests/test_*vocabulary*.py`
- **Findings**:
  - v1-archive に `rw_tag.py` / `rw_lint.py` 等の専用 module は存在しない
  - `tests/test_agents_vocabulary.py` / `test_source_vocabulary.py` の 2 テスト存在、AGENTS と source の vocabulary に関連
  - v1 vocabulary patterns は AGENTS.md 規範文書中心で、CLI tooling は v2 で新規導入
- **Implications**:
  - フルスクラッチ前提と整合、v1 patterns 流用なし
  - design.md は v1 reference を持たず、Spec 0 design + consolidated-spec を SSoT として完結

### B-9 Unicode normalization 規約

- **Context**: tag canonical の重複登録禁止 (R6.2) が文字 byte 比較なら NFC/NFD / 大文字小文字 / 全角半角の表記揺れで dedup 困難
- **Sources Consulted**: brief.md B-9 / Python `unicodedata` 標準ライブラリ
- **Findings**:
  - Python 標準で `unicodedata.normalize('NFC', s)` / `s.casefold()` / 全角半角は `unicodedata.normalize('NFKC', s)` で fold 可能
  - 対象 token (tag canonical / category name / entity type name) は人間入力中心、自動正規化が UX 適切
- **Implications**:
  - 設計決定 1-3 で「NFC normalization 必須 + case-sensitive (英数字は区別、日本語は維持) + 全角半角は警告のみ」を採択
  - implementation 時は `normalize_token(s) -> str` ユーティリティを `rw_tag` 共通 module に配置

### D-3 tags.yml.successor vs wiki frontmatter.successor 命名衝突

- **Context**: `tags.yml.successor` (canonical タグ名) と `wiki frontmatter.successor` (wiki ページ path 配列) が同名 field で型・意味異なる
- **Sources Consulted**: brief.md D-3 / requirements R6.1 (tags.yml) / R3.3 (wiki frontmatter)
- **Findings**:
  - 案 A: tags.yml field 名 `successor` → `successor_tag` rename (命名衝突回避、明示的)
  - 案 B: 同名 field で文脈依存 (parser 側で識別、ドキュメントで明示)
- **Implications**:
  - 設計決定 1-4 で 案 A `successor_tag` を採択 (parser 識別の暗黙性回避、長期可読性優先)
  - requirements.md R6.1 を本 design phase で改版 (実質変更経路、Adjacent Sync では扱わない)
  - 該当する change は Spec 0 design 「決定 0-2 / 改版二重 gate」に従い、Spec 1 requirements.md R6.1 の改版 + spec.json approvals.requirements 再 approve が必要

### B-15 / 本-10 大規模 vault 性能対策

- **Context**: `tags.yml` が 1 万タグ超 / vault が 10K+ ページの場合、`rw tag scan` / `rw lint` が分単位の遅延リスク
- **Sources Consulted**: brief.md B-15 + 本-10 / R9.3 「cache せず毎回最新」
- **Findings**:
  - v2 MVP 想定規模 = 1,000 タグ + 1,000 ページ程度 → 性能問題なし
  - 大規模時 (10K+ ページ): mtime ベース cache invalidation で frontmatter parse をスキップ可能
- **Implications**:
  - 設計決定 1-8 で「v2 MVP は cache なし、規模 (10K+ ページ) で問題化したら mtime ベース cache を Phase 2 に追加」を採択
  - Performance & Scalability セクションで規模別の戦略を明記

### F: Entity-person / entity-tool ショートカット → typed edge 名 mapping 初期値

- **Context**: `entity_types.yml` の初期 mapping (entity-person.shortcuts.authored → typed edge 名) を design phase で確定
- **Sources Consulted**: brief.md F / R5.3 / consolidated-spec §5.4 yaml example
- **Findings**:
  - `entity-person.shortcuts.authored` → typed edge 名 = `authored` (動詞ベース、source = person → target = wiki/methods/* etc.)
  - `entity-person.shortcuts.collaborated_with` → typed edge 名 = `collaborated_with` (undirected)
  - `entity-person.shortcuts.mentored` → typed edge 名 = `mentored` (directed: mentor → mentee)
  - `entity-tool.shortcuts.implements` → typed edge 名 = `implements` (directed: tool → method)
- **Implications**:
  - 設計決定 1-12 で初期 mapping を確定、Spec 5 `relations.yml` への coordination として明示
  - directed/undirected 区別 (G) は `entity_types.yml.shortcuts.<name>.directed` field で各 mapping ごとに宣言

### N: decision-views/ period_start / period_end 必須/任意

- **Context**: Tier 2 timeline の本質は「期間内 decision を時系列表示」、period 必須化を design phase 再検討
- **Sources Consulted**: brief.md N / R4.7
- **Findings**:
  - period_start / period_end が任意だと「期間指定なし → 全 decision 出力」と「期間指定あり → 期間内のみ」が同 schema で混在、render 側 (Spec 5 `rw decision render`) の logic 複雑化
  - 必須化すれば schema として timeline = 期間付き決定集約と明確化
- **Implications**:
  - 設計決定 1-13 で「period_start / period_end を必須化」採択、R4.7 改版経路 (実質変更、Adjacent Sync 不可)
  - ただしこれは Spec 1 R4.7 改版 → 再 approve 経路、本 design phase 内で対応する場合は requirements.md 改版 + 再 approve を伴う。Phase 1 内整理では 1-13 を **設計決定として記録** し、requirements.md は本 design phase 内で改版しない (escalate でユーザー判断)

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Module-per-Domain | G1-G6 を別 module (`rw_categories.py` / `rw_frontmatter.py` / `rw_vocabulary.py` / `rw_tag.py` / `rw_lint_vocabulary.py` / `rw_classification_coord.py`) で構成 | 責務明示、test 単位明確 | module 数が多くなり整合維持必要 | 採択、structure.md「モジュール責務分割」と整合 |
| Flat Module | `rw_classification.py` 1 ファイルに全機能集約 | import シンプル、関連 logic を 1 箇所に集約 | 1 ファイル 1500+ 行になりメンテ困難 | 却下 |
| Plugin Architecture | vocabulary 検査 / lint check / CLI subcommand を plugin として動的 register | 拡張性最大 | v2 MVP には過剰、複雑化 | 却下 (v2 MVP 範囲外) |

## Design Decisions

### Decision 1-1: Foundation 文書本体への引用形式 = `.kiro/specs/rwiki-v2-foundation/foundation.md#anchor`

- **Context**: Spec 1 が Foundation 規範を引用する path 形式を Spec 0 design 決定 0-1 から継承
- **Decision**: Spec 0 決定 0-1 を本 spec で踏襲、Spec 1 design.md / requirements.md / 将来 implementation 内の引用は `.kiro/specs/rwiki-v2-foundation/foundation.md#<github-auto-id>` 形式に統一
- **Impact**: 検証 3 (用語集引用 link 切れチェック) の検査対象範囲に Spec 1 が組み込まれる

### Decision 1-2: 検証 4 種の規範と実装責務分離 = Spec 0 規範 / Spec 4 実装

- **Context**: Spec 0 design 決定 0-2 を本 spec で踏襲、本 spec の lint / `rw tag *` も `rw doctor` 系統合の検査対象
- **Decision**: lint vocabulary 統合 (R9) は本 spec 所管、`rw doctor` 系統合 (Foundation 規範整合性チェック) は Spec 4 (Phase 2) 所管
- **Impact**: Phase 2 Spec 4 design 着手時に `rw doctor classification` サブコマンド (vocabulary YAML schema 妥当性 / mapping 整合性等) の coordination が必要

### Decision 1-3: Tag canonical の Unicode normalization 規約

- **Context**: B-9、tag canonical の表記揺れ (NFC/NFD / 大文字小文字 / 全角半角) で重複登録禁止 (R6.2) が機能しないリスク
- **Alternatives Considered**:
  1. NFC normalization 必須 + case-sensitive (英数字区別、日本語維持) + 全角半角は WARN 通知
  2. NFKC normalization 必須 (全角半角 fold)、case-insensitive (`python` ↔ `Python` 統合)
  3. byte 比較のみ (規約なし、ユーザー責任)
- **Decision**: 案 1 を採択。NFC normalization 必須、case-sensitive (英数字は区別、Python ≠ python)、全角半角は WARN で通知 (自動 fold せず、ユーザーに canonical 化を促す)
- **Rationale**: NFC は UTF-8 正規化の de facto standard、case-sensitive は技術用語の意味区別を保つ (例: `MAC` 媒体アクセス制御 vs `Mac` Macintosh)、全角半角の自動 fold は意図しない統合リスクあり
- **Trade-offs**: ユーザーが手動で canonical 統一を行う必要、ただし lint WARN が表記揺れを surface
- **Follow-up**: implementation 時に `normalize_token(s) -> str` ユーティリティを `rw_utils` に配置

### Decision 1-4: tags.yml `successor` field を `successor_tag` に rename

- **Context**: D-3、`tags.yml.successor` (canonical タグ名) と `wiki frontmatter.successor` (wiki ページ path 配列) の同名 field 命名衝突
- **Alternatives Considered**:
  1. tags.yml field 名 `successor` → `successor_tag` rename (案 A)
  2. 同名 field、文脈依存 (案 B)
- **Decision**: 案 A `successor_tag` を採択
- **Rationale**: parser 識別の暗黙性回避、grep / 検索時の文脈混乱解消、長期可読性優先
- **Trade-offs**: requirements.md R6.1 を改版する必要 (実質変更経路、再 approve 必要)。本 design phase では設計決定として記録し、Spec 1 requirements.md R6.1 改版は別 commit で扱う (escalate)
- **Follow-up**: requirements.md 改版時、change log に「2026-04-27: D-3 D 観点波及精査由来、tags.yml field `successor` → `successor_tag` rename」を追記

### Decision 1-5: review/vocabulary_candidates/ field 必須/任意区別の確定

- **Context**: R4.5、`operation` / `target` / `aliases` / `affected_files` / `status` の必須/任意区別が requirements で曖昧
- **Decision**:
  - 必須: `operation` / `target` / `affected_files` / `status` (デフォルト `draft`)
  - 任意: `aliases` (operation = `merge` 時のみ意味を持つ条件付き必須)
- **Rationale**: vocabulary 変更計画として最低限必要な field を必須化、aliases は merge 操作専用なので条件付き
- **Trade-offs**: parser 実装で operation 値ごとに必須 field を分岐する必要 (やや複雑だが意味的に正しい)

### Decision 1-6: lint suggestion = Levenshtein 距離による類似 canonical 提案

- **Context**: B-11、未登録タグの root cause (タイポ / 新概念 / vocabulary 古い) 判別支援
- **Decision**: lint output に「未登録タグ → 距離 ≤ 2 の canonical 候補リスト (上位 3 件)」を suggestion として併記。`difflib.SequenceMatcher` で Levenshtein 風の類似度算出
- **Rationale**: タイポ検出が大半 (距離 1-2)、新概念は距離 ≥ 3 で suggestion なし → ユーザーが `rw tag register` を判断可能
- **Trade-offs**: 大規模 vocabulary (1000+ タグ) で suggestion 計算コスト増、ただし lint 全体の bottleneck にはならない
- **Follow-up**: implementation 時 suggestion 上限 (3 件) を `categories.yml` 等で tunable に

### Decision 1-7: tag merge/rename rollback = git revert + decision_log 補正記録

- **Context**: B-13 + B-14、`rw tag merge` / `rename` の rollback と誤 approve からの復旧手順
- **Decision**:
  - rollback 手順: git revert で全ファイル戻す (markdown + tags.yml)
  - decision_log への補正記録: Spec 5 `record_decision(decision_type='vocabulary_rollback', ...)` を rollback 操作で呼び出す
  - 専用 `rw tag undo` は v2 MVP では実装せず (git revert で十分)、Phase 2 で必要時導入
- **Rationale**: git revert は標準操作、独自 undo は実装コスト + バグリスク。decision_log 補正は curation provenance 整合性保持
- **Trade-offs**: rollback 手順がユーザーに git 知識を要求、ただし `rw chat` 経由の LLM ガイドで吸収可能
- **Follow-up**: Spec 5 design 着手時に `decision_type='vocabulary_rollback'` 値を decision_type enum に追加 coordination

### Decision 1-8: 大規模 vault 性能対策 = mtime ベース cache invalidation (Phase 2)

- **Context**: B-15 + 本-10、`tags.yml` 1 万タグ + vault 10K+ ページで `rw tag scan` / `rw lint` の分単位遅延リスク
- **Decision**:
  - v2 MVP: cache なし、毎回 frontmatter / vocabulary を読み込む (R9.3 を維持)
  - Phase 2: mtime ベース cache を `rw_lint_vocabulary` 内に追加 (`.rwiki/cache/lint_vocabulary_cache.sqlite` 等)
- **Rationale**: v2 MVP 想定規模 (1,000 タグ + 1,000 ページ) では cache 不要、Phase 2 で実規模に応じて導入
- **Trade-offs**: 大規模 vault ユーザーは Phase 2 まで遅延を許容
- **Follow-up**: Performance & Scalability セクションで規模別の戦略を明記

### Decision 1-9: entity-person 単数 vs people/ 複数 = `entity_types.yml.directory_name` field 追加

- **Context**: 本-12、entity type 名 (`entity-person` / `entity-tool` 単数) と structure.md ディレクトリ規約 (`wiki/entities/people/` / `tools/` 複数) の命名不統一
- **Decision**: `entity_types.yml` の各 entity type に `directory_name` 任意 field を追加 (例: `entity-person.directory_name = "people"`)。指定時は wiki/entities/<directory_name>/ がカテゴリパスとして lint dispatch hint に使われる
- **Rationale**: 単数 entity type 名は概念明確化、複数 directory 名は英語慣習、両者を `entity_types.yml` で連結することで命名統一なしに整合可能
- **Trade-offs**: `entity_types.yml` schema が 1 field 増える、ただし任意 field のため後方互換
- **Follow-up**: implementation 時 directory_name の YAML schema 例を foundation.md §5 骨格にも反映 (Adjacent Sync)

### Decision 1-10: merge_strategy `canonical-a` / `canonical-b` 順序規約 = `merged_from` 配列 index 順

- **Context**: T、R3.4 で `canonical-a` / `canonical-b` 値を確定したが、a/b がどちらのページを指すか曖昧
- **Decision**: `merged_from: [path-a, path-b]` の配列 index 0 = a、index 1 = b と規定。`merge_strategy: canonical-a` は index 0 のページを正典とする選択
- **Rationale**: 配列 index 順は機械的、ユーザーが明示的に順序を指定可能、merge 操作 UX (Spec 7) で「どちらが canonical?」のプロンプトと整合
- **Trade-offs**: `merged_from` の順序が意味を持つため、Spec 7 merge 操作実装時にユーザー入力順を保持する必要
- **Follow-up**: Spec 7 design 着手時に merge UX (canonical 選択 prompt → `merged_from` 配列順序確定) を coordination

### Decision 1-11: Decision visualization Tier 1, 3, 4, 5 出力先所管 = Tier 1 → `.rwiki/cache/decision_summaries/` (Spec 5) / Tier 3-5 → Spec 5 design phase で確定

- **Context**: O、Foundation R7.4 で Tier 1-5 が定義、Spec 1 R4.7 では Tier 2 のみ `decision-views/` に固定。他 Tier の所管を確定
- **Decision**:
  - Tier 1 (Decision summary): `.rwiki/cache/decision_summaries/` (gitignore 対象、Spec 5 所管)
  - Tier 2 (Markdown timeline): `review/decision-views/` (Spec 1 骨格宣言、Spec 5 render 実装) ← R4.7
  - Tier 3-5: Spec 5 design phase で確定 (visualization の媒体は Spec 5 が決定)
- **Rationale**: Tier 1 は cache (再生成可能) なので gitignore、Tier 2 は人間向け timeline で git 管理、Tier 3-5 は Spec 5 visualization 設計の自由度を尊重
- **Trade-offs**: Tier 3-5 の所管が Spec 5 design 段階で確定、本 spec では未決でも問題なし
- **Follow-up**: Spec 5 design 着手時に Tier 3-5 出力先を確定し、Foundation R7.4 への Adjacent Sync を実施

### Decision 1-12: Entity-person / entity-tool ショートカット → typed edge 名 mapping 初期値

- **Context**: F + G、`entity_types.yml` の初期 mapping と directed/undirected 区別を design phase で確定
- **Decision**:
  - `entity-person.shortcuts`:
    - `authored` → typed edge `authored` (directed: person → wiki/methods/_concepts/_etc, source = person)
    - `collaborated_with` → typed edge `collaborated_with` (undirected, source/target 区別なし)
    - `mentored` → typed edge `mentored` (directed: mentor → mentee)
  - `entity-tool.shortcuts`:
    - `implements` → typed edge `implements` (directed: tool → method)
  - `entity_types.yml.shortcuts.<name>.directed` 任意 field で directed/undirected を宣言 (デフォルト: directed)
- **Rationale**: 動詞ベース命名は relations.yml と整合、directed/undirected の宣言は Spec 5 `normalize_frontmatter` API が typed edge 自動生成時に参照
- **Trade-offs**: Spec 5 `relations.yml` (typed edge vocabulary) への coordination 必要
- **Follow-up**: Spec 5 design 着手時に `relations.yml` 初期 typed edge 集合 (`authored` / `collaborated_with` / `mentored` / `implements` を含む) を確定

### Decision 1-13: review/decision-views/ period_start / period_end を必須化 (要件改版経路、本 design では設計決定として記録のみ)

- **Context**: N、Tier 2 timeline の本質 = 期間内 decision を時系列表示、period の任意化は render 複雑化
- **Decision**: `period_start` / `period_end` を必須化する設計判断を確定。ただし requirements.md R4.7 改版を伴うため、本 design phase 内では設計決定として記録し、要件改版は別 commit で扱う (escalate 対象)
- **Rationale**: schema として timeline = 期間付き決定集約と明確化、render 側 logic 簡素化
- **Trade-offs**: requirements.md 改版 + 再 approve 必要、本 design phase 内で完結しない
- **Follow-up**: 本 design 確定後、Spec 1 requirements.md R4.7 改版 PR を別 commit で起票 → 再 approve

### Decision 1-14: 並行編集競合解決 = `.rwiki/.hygiene.lock` 拡張で vocabulary 編集 lock を扱う

- **Context**: 本-9、複数ユーザーが同時に `tags.yml` / `categories.yml` / `entity_types.yml` を編集した場合の競合
- **Decision**: Foundation R11.5 / Spec 4 R10.1 が規定する `.rwiki/.hygiene.lock` を vocabulary 編集 (write 系 `rw tag *` 操作) でも取得する。R8.14 として既に requirements で coordination 確定済
- **Rationale**: 既存 lock 機構を共有することで実装コスト最小、Hygiene batch との競合も同時防止
- **Trade-offs**: lock 取得失敗時のリトライ logic は Spec 4 design で確定 (本 spec は coordination 要求のみ)
- **Follow-up**: Spec 4 design 着手時に vocabulary lock 取得 / 解放 / timeout の具体仕様を確定

### Decision 1-15: vocabulary entry の evidence chain 適用範囲 = §2.10 直接適用対象外、§2.13 curation provenance で代替

- **Context**: 本-18、`tags.yml` / `categories.yml` / `entity_types.yml` の各エントリに evidence chain (L1 起点 → L2 evidence.jsonl → L3 sources) が必要かどうか
- **Decision**: vocabulary entry は §2.10 Evidence chain の直接適用対象外、`description` field と `decision_log.jsonl` (vocabulary 操作履歴) で curation provenance (§2.13) を保全する
- **Rationale**: vocabulary は L3 wiki と同レベルの curated content、L1 raw 由来の evidence は不要 (vocabulary は人間 curation で生成)、curation の why は decision_log で十分
- **Trade-offs**: vocabulary entry の出典追跡は decision_log を参照する必要、L1 evidence ID では辿れない
- **Follow-up**: Foundation §2.10 に「vocabulary entry は適用対象外」の注記追加 (Adjacent Sync)

## Risks & Mitigations

- **Risk 1**: D-3 命名衝突 (`successor` field) を本 design 内で `successor_tag` rename と決定したが、requirements.md R6.1 の改版が伴う。改版を別 commit で扱う合意が崩れると本 design とのドリフト発生 → **Mitigation**: 本 design.md 設計決定 1-4 に明示記録、Phase 1 内で R6.1 改版 commit を確実に発行
- **Risk 2**: Coordination 多数 (Spec 3 / 4 / 5 / 7 / Foundation) のうち、Spec 5 / Spec 4 design (Phase 2-3) 着手時に本 spec 由来の coordination 要求が不整合になるリスク → **Mitigation**: 各 Spec design 着手時の coordination チェックリストを brief.md に集約済、本 design.md change log にも明示
- **Risk 3**: design phase 持ち越し 42 件を全件反映するため design.md が 1500 行超、メンテ性低下 → **Mitigation**: 設計決定 1-1〜1-15 を §「設計決定事項」に集約、その他は該当 Components / Data Models / Error Handling 等にセクション割り当て
- **Risk 4**: B-15 + 本-10 大規模 vault 性能対策が v2 MVP では cache なし、想定規模超過時の遅延が顕在化するリスク → **Mitigation**: 設計決定 1-8 で Phase 2 cache 導入を明示、Performance & Scalability で規模別戦略を記録

## References

- [consolidated-spec v0.7.12](.kiro/drafts/rwiki-v2-consolidated-spec.md) — §5 frontmatter / §6.2 Tag Vocabulary / §7.2 Spec 1 / §11.2 設計決定事項
- [Spec 0 design.md](/.kiro/specs/rwiki-v2-foundation/design.md) — Foundation 規範引用先、決定 0-1〜0-5 の継承
- [roadmap.md L132-](/.kiro/steering/roadmap.md) — v1 から継承される実装レベル決定の SSoT
- [memory feedback_design_decisions_record.md](~/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/feedback_design_decisions_record.md) — 二重記録方式の根拠
- [memory feedback_design_review.md](~/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/feedback_design_review.md) — 12 ラウンドレビュー方法論
