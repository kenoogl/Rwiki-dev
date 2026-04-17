# AGENTS/approve.md

## Purpose

レビュー済みのsynthesis候補を `review/synthesis_candidates/` から `wiki/synthesis/` へ昇格させる。
人間が承認した知識のみを処理する。

---

## Execution Mode

**CLI** — `rw approve` コマンドで実行。
エージェントファイルの直接ロードは不要。実行宣言はコマンド呼び出し自体が代替する。

---

## Prerequisites

- `review/synthesis_candidates/` 配下にコミット済みの候補ファイルが存在すること
- 作業ツリーが `review/synthesis_candidates/` について clean であること（dirty な場合は警告）

---

## Input

- Source: `review/synthesis_candidates/**/*.md`
- コミット済みファイルのみ使用する

---

## Output

- 昇格先: `wiki/synthesis/`
- 更新: `review/synthesis_candidates/` 内の候補ファイル（promotedフラグ更新）
- 更新: `index.md`（新規ノート作成時）
- 追記: `log.md`

### 承認メタデータ（4フィールド契約）

処理対象ファイルのfrontmatterに以下の全フィールドが存在しなければならない:

| フィールド | 条件 |
|---|---|
| `status` | `"approved"` と完全一致すること |
| `reviewed_by` | 空でない文字列であること |
| `approved` | `YYYY-MM-DD` 形式の有効な日付であること |
| `promoted` | `"true"` でないこと（既昇格候補の除外） |

いずれかのフィールドが欠落または不正な場合、そのファイルは処理しない。
承認メタデータを創作・補完してはならない。

### 昇格後のwikiページ形式

```markdown
---
title: "<タイトル>"
source: "<元のraw/ソース>"
candidate_source: "<review/synthesis_candidates/...>"
type: "synthesis"
reviewed_by: "<name>"
approved: YYYY-MM-DD
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [tag1, tag2]
---

## Summary
...

## Decision
...

## Reason
...

## Alternatives
...

## Reusable Pattern
...
```

---

## Processing Rules

各候補ファイルについて:

1. frontmatterを読み込み、4フィールド契約を検証する
2. `promoted: true` の場合はスキップする（再昇格禁止）
3. `wiki/synthesis/` 内に類似ノートが存在するか確認する
4. 類似ノートが存在する場合: 既存ファイルへマージ（上書き禁止、差分追記）
5. 類似ノートが存在しない場合: `wiki/synthesis/` に新規ノートを作成する
6. 候補ファイルのメタデータを更新する:
   - `promoted: true`
   - `promoted_at: YYYY-MM-DD`
   - `promoted_to: wiki/synthesis/<slug>.md`
7. 新規ノート作成時は `index.md` を更新する
8. `log.md` に追記する

### 再利用可能性の確認

以下を満たさない候補は昇格しない:

- 元の会話なしに理解できる
- 安定した決定・原則・再利用可能なパターンを表現している
- 簡潔で構造化されている

### 重複確認

`wiki/synthesis/` に類似内容が既に存在する場合はマージする。
異なる側面・補足のみの場合は統合する。

### provenanceの保持

昇格ノートには候補ファイルへの追跡可能性（`candidate_source`）を必ず含める。

### コミットについて

CLI（`rw approve`）は自動コミットを行わない。
昇格操作後のコミットはユーザーが手動で実行する。
git_ops.mdの定義に従い、コミットは以下の順序で別々に行う:
1. `review/` の promoted フラグ更新: `approve: update promoted flag`
2. `wiki/` のノート作成 + `index.md` + `log.md`: `approve: promote synthesis`

---

## Prohibited Actions

- 承認メタデータの創作・補完
- `promoted: true` のファイルの再昇格
- 自動承認（人間の承認なしに昇格）
- `wiki/synthesis/` 以外への昇格
- 既存wikiノートの上書き（マージのみ許可）
- `raw/` への書き込み
- `log.md` への上書き（追記のみ）

---

## Failure Conditions

即座に中止する条件:

- 4フィールド契約を満たす候補ファイルが存在しない（終了コード0で正常終了）

個別スキップ条件（当該ファイルをスキップして次へ）:

- `promoted: true` が設定済み（再昇格防止）
- `status` が `"approved"` でない
- `reviewed_by` が空
- `approved` が有効なISO日付形式でない
