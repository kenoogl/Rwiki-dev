# Brief: rwiki-v2-prompt-dispatch

> 出典: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §7.2 Spec 3

## Problem

distill タスクで複数 skill が候補になる場合（例: paper_summary vs multi_source_integration）、選択ロジックが固定されていないと、毎回ユーザーが `--skill` を明示する負担が発生する。一方で、固定ロジックだけでは精度が落ちる（コンテンツによって最適 skill が異なる）。

## Current State

- consolidated-spec §7.2 Spec 3 に skill 選択の優先順位（明示 → frontmatter `type:` → カテゴリ default → LLM 判断）が整理済
- preparatory 議論で「LLM 毎回判定」「`generic_summary` fallback」が決定（v0.7.10 の 6 決定の一部）
- Spec 1 の categories.yml に default_skill mapping を持たせる方針が合意

## Desired Outcome

- distill 起動時の skill 選択が自動化され、明示指定なしでも妥当な skill が選ばれる
- 明示 `--skill` は常に最優先（ユーザー意図を尊重）
- frontmatter `type:` が distill のヒントとして機能
- LLM 判断と明示指定が食い違う場合、ユーザーに確認

## Approach

優先順位: 明示 `--skill` → frontmatter `type:` → categories.yml の default → LLM 毎回判定（コンテンツを読んで推論）。LLM 判断は精度優先、結果と明示指定の食い違いは user に confirm。skill 欠如時は `generic_summary` fallback。

## Scope

- **In**:
  - スキル選択の優先順位（明示 → `type:` → カテゴリ default → LLM 判断）
  - LLM 毎回判定方式
  - スキル欠如時の `generic_summary` fallback
  - `.rwiki/vocabulary/categories.yml` のカテゴリ → default skill マッピング
- **Out**:
  - Skill 内容自体（Spec 2）
  - Perspective / Hypothesis の skill 選択（Spec 6 は固定 skill 呼出、dispatch 対象外）

## Boundary Candidates

- skill 選択ロジック（本 spec）と skill 定義（Spec 2）
- distill の skill dispatch（本 spec）と perspective/hypothesis の固定 skill 呼出（Spec 6）

## Out of Boundary

- Skill 内容と Skill ファイル（Spec 2）
- Perspective/Hypothesis dispatch（Spec 6 では dispatch 不要、固定 skill）
- frontmatter `type:` field 自体の定義（Spec 1）

## Upstream / Downstream

- **Upstream**: rwiki-v2-classification（Spec 1 — categories.yml、frontmatter `type:`）/ rwiki-v2-skill-library（Spec 2 — skill 一覧）
- **Downstream**: rwiki-v2-cli-mode-unification（Spec 4 — `rw distill` 起動時に dispatch 呼出）

## Existing Spec Touchpoints

- **Extends**: なし（新規）
- **Adjacent**: v1 `agents-system`（v1-archive、prompt selection ロジックの参考）

## Constraints

- 明示 `--skill` は常に最優先
- `type:` frontmatter があれば LLM 判断とのコンセンサス確認
- LLM は毎回コンテンツを読んで最適 skill を推論（精度優先）
- 推論結果と明示指定が食い違う場合、ユーザーに確認
- Perspective / Hypothesis は dispatch 対象外（固定 skill 呼出）

## Coordination 必要事項

- **Spec 1 ↔ Spec 3**: frontmatter `type:` field を Spec 1 で追加
- **Spec 1 ↔ Spec 3**: `categories.yml` の default_skill mapping 方式（inline / 別ファイル）
