# Brief: rwiki-v2-skill-library

> 出典: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §7.2 Spec 2

## Problem

L1 raw から L2/L3 へのコンテンツ生成（distill / 抽出 / 統合）は多様な出力形式を必要とするが、タスクと出力形式を一体で管理すると、出力形式を増やすたびに各タスクのコードを書き換える必要が出る。Spec 5 が必要とする entity/relation 抽出も、独立した skill として用意されていなければ Graph Ledger への投入経路が成立しない。

## Current State

- consolidated-spec §7.2 Spec 2 に skill ライブラリの 8 section スキーマと初期スキル群（知識生成 12 種 + Graph 抽出 2 種 + lint 支援 1 種）が整理済
- v1 の `templates/AGENTS/*.md` は v1-archive にあり、distill 系の prompt 設計の参考資料
- 初期スキル設計は AGENTS/skills/ 配下のディレクトリ構造として固定方針

## Desired Outcome

- タスクと出力形式の分離が実現され、新しい出力形式の追加が新 skill ファイルの追加で完結する
- Graph 抽出 skill（`relation_extraction` / `entity_extraction`）が Spec 5 の Ledger と連携可能
- Custom skill 作成フローが提供され、ユーザーが独自 skill を draft → test → install できる
- Skill install 前に dry-run 必須化、validation（8 section / YAML / 衝突）が動作

## Approach

`AGENTS/skills/` ディレクトリと 8 section スキーマで skill を定義。`origin: standard | custom` を区別し、`rw init` は standard のみ配布。Custom skill は `review/skill_candidates/` を経由して install。Graph 抽出 skill の出力先は `review/relation_candidates/` で、human reject filter を経て Spec 5 の `edges.jsonl` に投入される。

## Scope

- **In**:
  - `AGENTS/skills/` ディレクトリ構造
  - Skill ファイルの 8 section スキーマ（Purpose / Execution Mode / Prerequisites / Input / Output / Processing Rules / Prohibited Actions / Failure Conditions）
  - Skill frontmatter（origin / interactive / update_mode / handles_deprecated / applicable_categories）
  - 初期スキル群（知識生成 12 種、Graph 抽出 2 種、lint 支援 1 種）
  - Custom skill 作成フロー（`rw skill draft/test/install`）
  - `review/skill_candidates/` 層
  - Dry-run 必須化、install validation
- **Out**:
  - Skill 選択ロジック（Spec 3）
  - Skill lifecycle 管理（Spec 7）
  - Graph 抽出結果の格納・進化（Spec 5）

## Boundary Candidates

- Skill 内容（本 spec）と skill 選択（Spec 3）
- Skill 定義（本 spec）と skill ライフサイクル（Spec 7）
- 抽出 skill の出力フォーマット（本 spec）と出力の永続化（Spec 5）

## Out of Boundary

- Skill 選択ロジック（Spec 3）
- Skill lifecycle イベント（deprecate / retract / archive、Spec 7）
- L2 Graph Ledger の data model（Spec 5）

## Upstream / Downstream

- **Upstream**: rwiki-v2-foundation（Spec 0）/ rwiki-v2-knowledge-graph（Spec 5 — Ledger API、抽出 skill output validation interface）
- **Downstream**: rwiki-v2-prompt-dispatch（Spec 3 — skill 一覧）/ rwiki-v2-cli-mode-unification（Spec 4 — skill 起動）/ rwiki-v2-perspective-generation（Spec 6 — perspective_gen / hypothesis_gen を skill として定義）

## Existing Spec Touchpoints

- **Extends**: なし（新規）
- **Adjacent**: v1 `agents-system`（v1-archive、AGENTS prompt の構造を参考）

## Constraints

- 必須 8 section: Purpose / Execution Mode / Prerequisites / Input / Output / Processing Rules / Prohibited Actions / Failure Conditions
- `update_mode: extend` 対応（差分マーカー形式、HTML コメント）
- Install 時の validation（8 section / YAML / 衝突 / 参照整合性）
- Install 前に dry-run 最低 1 回必須
- `origin: standard | custom` の区別
- Skill export/import は v2 MVP 外
- Graph 抽出 skill の出力先は `review/relation_candidates/`、その後 reject filter を経て `edges.jsonl`

## Coordination 必要事項

- **Spec 2 ↔ Spec 5**: extraction skill（`relation_extraction` / `entity_extraction`）の出力 validation interface
