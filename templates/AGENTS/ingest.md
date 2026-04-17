# AGENTS/ingest.md

## Purpose

`raw/incoming/` から `raw/` へのファイル移動プロセスを定義する。
lint済みの未検証ファイルを検証済み状態に遷移させる。

---

## Execution Mode

**CLI** — `rw ingest` コマンドで実行。
エージェントファイルの直接ロードは不要。実行宣言はコマンド呼び出し自体が代替する。

---

## Prerequisites

- `rw lint` が実行済みであること（`logs/lint_latest.json` が存在する）
- lint結果に FAIL が含まれないこと（FAIL == 0）
- `raw/incoming/` 配下に処理対象ファイルが存在すること

---

## Input

- Source: `raw/incoming/**/*.md`
- 対象: lintによって検証されたファイル
- コミット済みでなくてもよい（incoming は未コミット前提）

---

## Output

- 移動先: `raw/` 配下（incoming以下のディレクトリ構造を保持）
- Gitコミット: 全ファイル移動後に `ingest: batch import` メッセージでコミット
- コミット対象: `raw/` 層のみ

---

## Processing Rules

1. `logs/lint_latest.json` を読み込み、`summary.fail > 0` の場合は即座に中止する
2. `raw/incoming/` 配下の全 `.md` ファイルを列挙する
3. 各ファイルの移動先パスを計算する（`raw/incoming/` → `raw/` プレフィックス置換、ディレクトリ構造保持）
4. 移動先に既存ファイルがある場合は **STOP**（上書き禁止）
5. 全ファイルを `raw/` へ移動する（アトミック: 失敗した場合はロールバック）
6. 全移動完了後に `git commit`（`raw/` 層のみ）

### レイヤー境界

- 入力層: `raw/incoming/` のみ
- 出力層: `raw/` 配下（`raw/incoming/` を除く各カテゴリ）
- `review/`・`wiki/` には一切触れない

---

## Prohibited Actions

- `wiki/` への書き込み
- `raw/incoming/` のコミット
- lint FAIL が存在する状態でのingest実行
- 既存ファイルの上書き
- 部分ingest（一部のファイルだけ移動してコミット）
- コンテンツの内容変更
- synthesize または wiki 更新のトリガー

---

## Failure Conditions

即座に中止する条件:

- `logs/lint_latest.json` が存在しない（lint未実行）
- lint結果に FAIL が1件以上存在する
- 移動先パスにファイルが既に存在する（コンフリクト）
- git commit が失敗した（→ 移動をロールバックする）
- `raw/incoming/` に処理対象ファイルが存在しない
