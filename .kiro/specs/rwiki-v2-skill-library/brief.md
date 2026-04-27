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
  - Skill frontmatter（必須: origin / interactive / update_mode / handles_deprecated、optional: applicable_categories / applicable_input_paths / dialogue_guide / auto_save_dialogue）
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
- **version up 操作は v2 MVP 外**（改版時は新規 skill 名で install することを基本方針、Requirement 1.5 / Requirement 3.1 と整合）
- **Skill ファイルへの `update_history` field 適用は v2 MVP 外**（Skill lifecycle 履歴は `decision_log.jsonl` の Skill 起源 4 種で網羅、Requirement 3.6 / Spec 5 Requirement 11.2 / Spec 7 Requirement 12.7 と整合）
- Graph 抽出 skill の出力先は `review/relation_candidates/`、その後 reject filter を経て `edges.jsonl`

## Coordination 必要事項

- **Spec 2 ↔ Spec 5**: extraction skill（`relation_extraction` / `entity_extraction`）の出力 validation interface
- **Spec 2 ↔ Spec 4**: 対話ログ markdown ファイルの frontmatter スキーマ（必須 5 field: `type / session_id / started_at / ended_at / turns`）は本 spec が SSoT として所管し、Spec 4 Requirement 1.8 が当該スキーマに従う保存実装を提供する責務分離（Requirement 15 で明文化）

## Design phase 持ち越し項目

- **対話ログ markdown フォーマット詳細**（Turn 表現の内部構造、auto-save の append 単位、speaker / content / timestamp 等の Turn 内部 schema、命名規則の `chat-sessions/` / `interactive-<skill>/` / `manual/` ディレクトリ区別、frontmatter 任意フィールドの拡張規約）— Requirement 15 AC 2 で参照点のみ残置、design phase で drafts §2.11 / Scenario 15 / Scenario 25 を参照して確定
- **Skill frontmatter 任意フィールドの値域**（`dialogue_guide` / `auto_save_dialogue` の値域・運用詳細）— Requirement 15 AC 3 で許容のみ規定、運用詳細は design phase
- **HTML 差分マーカー attribute 詳細**（`update_mode: extend` 出力の `<!-- rw:extend:start ... -->` 内部 attribute = `target` / `reason` 等の詳細仕様）— Requirement 10.4 で言及、Spec 7 lifecycle merge 仕様と整合させて design phase で確定（Important I-3）
- **`frontmatter_completion` skill の出力先 review path**（補完提案 candidate の格納先、例: `review/lint_proposals/` 等）— Requirement 6.2 では Output 内容（補完提案 frontmatter YAML 文字列 + 確信度）のみ規定、出力先 path は drafts §11.2 「review via `rw lint --fix`」記述とも整合する形で design phase で確定（Scenario 26 / Spec 5 Requirement 11 と整合、永続化先 `decision_log.jsonl` は Spec 5 所管とは別軸）
- **R15.4 「対話ログを生成または依拠する skill (...等)」の判定基準**（軽-C 由来）— 「等」の解釈を `frontmatter `interactive: true` または `auto_save_dialogue: true` を真とする等」の具体ルールとして design phase で確定。本 requirements は明示列挙 3 種（`interactive_synthesis` / `frontmatter_completion` / `llm_log_extract`）への必須記載のみを SSoT として確定

## 要件記述の精度懸念事項（design phase で軽微整理予定）

- **軽-A: Skill frontmatter 任意 field の所在分散**（Requirement 3 と Requirement 15.3 でクロス参照）— Requirement 3.2 で `applicable_categories` / `applicable_input_paths`、Requirement 15.3 で `dialogue_guide` / `auto_save_dialogue` を任意 field として規定。Skill frontmatter 全体像（任意 field 4 種）は Boundary Context In scope（requirements.md L28）と本 brief.md Scope.In に集約済（第 5 ラウンド再点検 発見 1 / 2 で修正済）。design phase で 4 種を Requirement 3 に集約する整理を検討
- **軽-D: Requirement 5.5 と 5.6 の表現重複**（軽微）— R5.5 = 責務分離の明示、R5.6 = 変更時 Adjacent Sync 手順、と意味的には別だが「skill ファイルおよび本 requirements に参照点を残す」の表現が重複。design phase で R5.5 + R5.6 を 1 AC に統合 / 簡素化を検討
