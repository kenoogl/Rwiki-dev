# AGENTS/git_ops.md

## Purpose

安定した再現可能なワークフロー状態を維持するためのGitオペレーションポリシー。

---

## Rules

### 原則

- `raw/`・`review/`・`wiki/` の更新は**別々に**コミットする（3層分離）
- コミットは安定した再現可能な状態を定義する
- コミット済みの `raw/` のみを下流LLM処理の入力として使用できる

### 禁止事項

- `raw/incoming/` をコミットしない
- ソース層コミットと知識層コミットを混在させない
- `raw/` のingest更新を `review/` や `wiki/` の更新と混在させない
- コミット境界が不明な場合 → **STOP** してユーザーに確認する

### 許可される例外

- `index.md` と `log.md` は知識層コミットに含めてよい

### コミット種別

**ingest commit**
- 対象: `raw/`
- 条件: lint成功後のみ（FAIL == 0）
- メッセージ: `ingest: ...`

**synthesis commit**
- 対象: `review/`（synthesize タスクの出力先は review/ のみ）
- メッセージ: `synthesis: ...`

**synthesize-logs commit**
- 対象: `review/synthesis_candidates/`
- メッセージ: `synthesize-logs: ...`

**query commit**
- 対象: `review/query/`
- メッセージ: `query: ...`

**approve commit**
- 対象(1): `review/`（promoted フラグ更新）
- 対象(2): `wiki/`（昇格ノート作成）
- `review/` と `wiki/` の変更は別々にコミットする
- `index.md`・`log.md` は `wiki/` コミットに含めてよい
- メッセージ: `approve: ...`

**audit**
- コミットなし（読み取り専用タスク）

### コミット済み状態ルール

下流タスクはコミット済みファイルのみを使用しなければならない。

- 未コミットの変更を安定した入力として扱ってはならない
- 作業ツリーがdirtyな場合 → 厳格度に応じて警告またはSTOP

### タイミング

- LLM処理前にrawをコミットする
- 未コミットのraw入力からwikiを更新しない
