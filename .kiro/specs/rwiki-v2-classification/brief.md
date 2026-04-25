# Brief: rwiki-v2-classification

> 出典: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §5, §7.2 Spec 1

## Problem

L3 Curated Wiki は markdown ページの集合だが、frontmatter スキーマ・カテゴリ体系・タグ vocabulary が未定義のままでは、各 spec が独自に frontmatter フィールドを使い始め、lint や derived cache 同期が成立しない。Entity 固有のショートカット（authored/collaborated_with 等）の扱いも宙ぶらりんになる。

## Current State

- consolidated-spec §5 に共通必須・推奨・任意・wiki 固有・review 固有・skill ファイル固有等の frontmatter スキーマが整理済
- カテゴリ（articles / papers / notes / narratives / essays / code-snippets / llm_logs）と vocabulary（tags / relations / categories / entity_types）の方針も合意済
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
- **Downstream**: rwiki-v2-cli-mode-unification（Spec 4 — lint で vocabulary 検証）/ rwiki-v2-knowledge-graph（Spec 5 — frontmatter 正規化）/ rwiki-v2-prompt-dispatch（Spec 3 — `type:` field を dispatch hint）

## Existing Spec Touchpoints

- **Extends**: なし（新規）
- **Adjacent**: v1 `agents-system`（v1-archive、参考のみ、AGENTS と vocabulary の関係を参照）

## Constraints

- カテゴリは強制ではなく推奨パターン
- source は frontmatter 必須、自由文字列、カテゴリから自動推論しない
- 未登録タグは INFO、エイリアスは WARN、非推奨は WARN
- L3 `related:` は L2 edges.jsonl からの derived cache（`rw graph sync` で整合）
- Entity 固有ショートカットは Spec 5 の `normalize_frontmatter` API で typed edge に展開（confidence 0.9 固定）

## Coordination 必要事項

- **Spec 1 ↔ Spec 3**: frontmatter 推奨フィールドに `type:` 追加（distill dispatch hint）、`categories.yml` の default_skill mapping 方式（inline / 別ファイル）
- **Spec 1 ↔ Spec 5**: Entity 固有 field のスキーマ宣言（本 spec）と展開ロジック（Spec 5）の境界
