# 手動検証チェックリスト — rw-light-rename

## 目的

本ドキュメントは `rw-light-rename` スペックの実装完了後、自動テストでは網羅しにくい側面（git 履歴連続性・symlink 実態・既存 Vault マイグレーション動作）を人手で確認するためのチェックリストである。

## 実施条件

- 本リストは実装タスク（Tasks 1〜6）が全て完了し、CI がグリーンになった後に実施する。
- 検証は `Rwiki-dev` リポジトリのルートディレクトリで実施する。
- 各項目の「記録欄」に実施結果を記入し、本ファイルを更新してレビュー担当者に提出する。

---

## チェックリスト

### 項目 1: git 履歴連続性の確認（Req 1.2）

- [x] **完了**

#### 説明

`git log --follow` により、リネーム前（`rw_light.py` 時代）のコミットが `rw_cli.py` の履歴として辿れることを確認する。

#### 実行コマンド

```bash
git log --follow --oneline scripts/rw_cli.py
```

#### 期待結果

- 出力に、`rw_light.py` 時代（リネーム実施コミット以前）のコミットハッシュとメッセージが含まれていること。
- リネームコミット（例: `rename rw_light.py to rw_cli.py`）より古いコミットが少なくとも 1 件以上表示されること。
- コマンドが非ゼロ終了コードで終了しないこと（exit 0）。

#### 記録欄

| 項目 | 内容 |
|------|------|
| 実行日時 | 2026-04-21|
| 実行者 | keno |
| 結果 | pass|
| 備考 | % git log --follow --oneline scripts/rw_cli.py | grep rw_cli.py
69b34ea feat(rw-light-rename): バッチ A — rw_light.py → rw_cli.py rename + cmd_init --reinstall-symlink 拡張 + tests 全参照更新 (644 passed)|

---

### 項目 2: 引数なし起動時の usage 表示確認（Req 2.1, 5.4）

- [x] **完了**

#### 説明

`python scripts/rw_cli.py` を引数なしで実行したとき、リネーム前と同一の usage テキストが表示され、`--reinstall-symlink` フラグの説明が追記されていることを確認する。

#### 実行コマンド

```bash
python scripts/rw_cli.py
```

#### 期待結果

- usage テキストが標準出力または標準エラーに表示されること。
- 表示内容に `--reinstall-symlink` フラグの説明が含まれていること（Req 5.4 の `rw init --help` 相当の情報が usage に反映されている、または `rw init --help` で確認可能）。
- `rw_light` という文字列が usage テキスト内に出現しないこと（コマンド名・ファイル名ともに `rw_cli` に統一されていること）。
- 既存サブコマンド（`lint`, `ingest`, `synthesize-logs`, `approve`, `init`, `query` 系, `audit` 系）が一覧表示されること。

補足確認:

```bash
python scripts/rw_cli.py init --help
```

- `--reinstall-symlink` フラグとその説明文が出力に含まれること。

#### 記録欄

| 項目 | 内容 |
|------|------|
| 実行日時 | 2026-04-21 |
| 実行者 | keno |
| 結果 | pass |
| 備考 | |

---

### 項目 3: 新規 Vault 初期化時の symlink ターゲット確認（Req 4.1, 4.2）

- [x] **完了**

#### 説明

新規空ディレクトリに対して `rw init` を実行し、作成された `scripts/rw` シンボリックリンクが `rw_cli.py` を指向していることを確認する。

#### 実行コマンド

```bash
# 1. 新規空ディレクトリを作成して初期化
python scripts/rw_cli.py init ./tmp-vault

# 2. symlink の実態を確認
ls -l ./tmp-vault/scripts/rw

# 3. symlink 経由で CLI が起動できることを確認
python ./tmp-vault/scripts/rw
```

#### 期待結果

- `ls -l ./tmp-vault/scripts/rw` の出力で、symlink ターゲットが `rw_cli.py` を含むパス（例: `../../scripts/rw_cli.py` または絶対パス相当）を指していること。
- ターゲットパスに `rw_light` という文字列が含まれないこと。
- `python ./tmp-vault/scripts/rw` が usage テキストを表示して正常終了（exit 0）すること。

#### 後片付け（任意）

```bash
rm -rf ./tmp-vault
```

#### 記録欄

| 項目 | 内容 |
|------|------|
| 実行日時 | 2026-04-21 |
| 実行者 | keno |
| 結果 | pass|
| 備考（ls -l 出力の symlink ターゲット値 ./tmp-vault/scripts/rw@ -> /Users/Daily/Development/Rwiki-dev/scripts/rw_cli.py） | |

---

### 項目 4: `--reinstall-symlink` による symlink 再作成確認（Req 5.1, 5.2）

- [x] **完了**

#### 説明

既存 Vault に対して `--reinstall-symlink` を実行したとき、symlink のみが再作成され、他のファイル・ディレクトリの更新日時（mtime）が変化しないことを確認する。

#### 実行コマンド

```bash
# 1. 項目 3 で作成した tmp-vault を再利用（または再作成）
python scripts/rw_cli.py init ./tmp-vault

# 2. 現在のファイル・ディレクトリの mtime を記録
stat ./tmp-vault/scripts/rw
find ./tmp-vault -not -path "*/scripts/rw" -exec stat -f "%m %N" {} \; | sort

# 3. --reinstall-symlink を実行
python scripts/rw_cli.py init ./tmp-vault --reinstall-symlink

# 4. 実行後の mtime を再確認
stat ./tmp-vault/scripts/rw
find ./tmp-vault -not -path "*/scripts/rw" -exec stat -f "%m %N" {} \; | sort

# 5. symlink ターゲットが rw_cli.py を指していることを再確認
ls -l ./tmp-vault/scripts/rw
```

#### 期待結果

- `--reinstall-symlink` 実行後、`./tmp-vault/scripts/rw` の symlink ターゲットが `rw_cli.py` を指していること。
- `./tmp-vault/scripts/rw` 以外のファイル・ディレクトリの mtime が実行前後で変化しないこと（通常初期化処理がスキップされること）。
- コマンドが exit 0 で正常終了すること。

#### 後片付け（任意）

```bash
rm -rf ./tmp-vault
```

#### 記録欄

| 項目 | 内容 |
|------|------|
| 実行日時 | 2026-04-21 |
| 実行者 | keno |
| 結果 | pass |
| 備考（mtime 変化なしの確認方法・結果を記載推奨） | |

---

### 項目 5: 非 Vault ディレクトリへの `--reinstall-symlink` エラー確認（Req 5.3）

- [x] **完了**

#### 説明

`scripts/` サブディレクトリが存在しない新規空ディレクトリに対して `--reinstall-symlink` を実行したとき、明示的なエラーメッセージが stderr に出力され exit code 1 で終了することを確認する。

#### 実行コマンド

```bash
# 1. 新規空ディレクトリを作成（Vault 初期化は行わない）
mkdir ./non-vault

# 2. --reinstall-symlink を実行してエラーを確認
python scripts/rw_cli.py init ./non-vault --reinstall-symlink
echo "exit code: $?"

# 3. stderr にエラーメッセージが出力されることを確認
python scripts/rw_cli.py init ./non-vault --reinstall-symlink 2>&1 | cat
```

#### 期待結果

- コマンドが exit code 1 で終了すること（`echo "exit code: $?"` の出力が `exit code: 1`）。
- stderr に、対象ディレクトリが既存 Vault ではない旨を示す明示的なエラーメッセージが出力されること（例: `Error:`, `not a vault`, または類似のエラー文言）。
- stdout に通常初期化の進捗メッセージが出力されないこと（処理が中断されること）。

#### 後片付け（任意）

```bash
rm -rf ./non-vault
```

#### 記録欄

| 項目 | 内容 |
|------|------|
| 実行日時 | 2026-04-21|
| 実行者 | keno |
| 結果 | pass |
| 備考（exit code: 1・[ERROR] './non-vault' は既存の Vault ではありません（CLAUDE.md または index.md が不在）。--reinstall-symlink は既存 Vault にのみ適用可能です。） | |

---

## 検証完了サマリ

| 項目 | 対応 Req | 結果 |
|------|----------|------|
| 1. git 履歴連続性 | 1.2 | pass |
| 2. 引数なし usage 表示 | 2.1, 5.4 | pass |
| 3. 新規 Vault symlink ターゲット | 4.1, 4.2 | pass |
| 4. `--reinstall-symlink` symlink 再作成 | 5.1, 5.2 | pass |
| 5. 非 Vault エラー確認 | 5.3 | pass |

**最終承認者:**
keno
**承認日時:**
2026-04-21