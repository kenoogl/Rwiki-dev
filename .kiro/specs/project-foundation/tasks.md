# Implementation Plan

- [ ] 1. Foundation: テンプレートファイル作成
- [x] 1.1 (P) Wiki運用カーネル（templates/CLAUDE.md）の作成
  - docs/CLAUDE.md を templates/CLAUDE.md としてコピーする
  - グローバルルール6項目（rawの完全性、reviewの強制、承認要件、書き込み権限、インデックスとログ整合性、コミット分離）が含まれることを確認する
  - タスク分類9種、Task→AGENTSマッピング、実行モデル（実行宣言・マルチステップルール）、失敗条件が含まれることを確認する
  - `templates/CLAUDE.md` が存在し、docs/CLAUDE.md と同一内容を持つ
  - _Requirements: 2.2, 2.3, 2.4_
  - _Boundary: templates/CLAUDE.md_

- [x] 1.2 (P) Vault用.gitignoreテンプレート（templates/.gitignore）の作成
  - `raw/incoming/`、`.obsidian/workspace.json`、`.obsidian/workspace-mobile.json`、`.DS_Store` を除外エントリとして記述する
  - `templates/.gitignore` が存在し、指定された4エントリを含む
  - _Requirements: 3.2, 3.3_
  - _Boundary: templates/.gitignore_

- [ ] 2. Core: rw_light.py への cmd_init() 実装
- [x] 2.1 (P) モジュールレベル定数とユーティリティ関数の追加
  - `VAULT_DIRS` リスト定数（全22ディレクトリの相対パス）をモジュールレベルに追加する
  - `DEV_ROOT` 定数を `str(Path(__file__).resolve().parent.parent)` で定義する
  - `is_existing_vault(path: str) -> bool` 関数を追加する（CLAUDE.md または index.md の存在で判定）
  - Pythonインポートで `VAULT_DIRS`（22要素）、`DEV_ROOT`（文字列）、`is_existing_vault`（関数）にエラーなくアクセスできる
  - _Requirements: 1.1, 1.4_
  - _Boundary: scripts/rw_light.py (モジュールレベル定数 VAULT_DIRS, DEV_ROOT + is_existing_vault 関数)_

- [x] 2.2 cmd_init() 新規Vault作成フローの実装
  - エラーハンドリング方針: 各ステップをtry-exceptで個別にエラー処理し、致命的エラー（テンプレート不在、パス作成失敗）は即座に終了コード1で中断、非致命的エラー（Git、symlink）は警告付きで続行する
  - 引数解析: `args` からターゲットパスを取得し、省略時は `os.getcwd()` を使用する
  - テンプレート存在チェック: `templates/CLAUDE.md` と `templates/.gitignore` が不在の場合、エラーメッセージを表示して終了コード1で中断する
  - 存在しないターゲットパスを `os.makedirs()` で自動作成する。作成失敗時（権限不足等）は OSError をキャッチし、エラーメッセージを表示して終了コード1で中断する
  - Vault検出: `is_existing_vault()` で既存Vaultを検出した場合、`input()` でユーザに上書き確認を求め、拒否時は終了コード0で中断する
  - `VAULT_DIRS` に基づき全22ディレクトリを `os.makedirs(exist_ok=True)` で一括生成する
  - `templates/CLAUDE.md` を Vaultルートに `shutil.copy2()` でコピーする
  - `templates/AGENTS/` が存在する場合、`shutil.copytree(dirs_exist_ok=True)` で Vault の `AGENTS/` にコピーする（不在時はスキップ）。`dirs_exist_ok=True` は VAULT_DIRS の makedirs で AGENTS/ が既に作成済みのため必須
  - `index.md`（`# Index\n`）と `log.md`（`# Log\n`）を生成する（既存ファイルがある場合はスキップ）
  - `report` dict を初期化し、各ステップの結果（作成ディレクトリ数、テンプレートコピー状態、スキップ項目と理由）を蓄積する（タスク2.3 がこの dict に追記して出力する）
  - 空ディレクトリに対して `cmd_init()` を実行し、全22ディレクトリ、CLAUDE.md、index.md、log.md が正しく生成される
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.5, 2.6, 4.1, 4.2, 4.3, 4.4_
  - _Depends: 1.1, 1.2, 2.1_
  - _Boundary: scripts/rw_light.py (cmd_init 関数: 引数解析〜テンプレートチェック〜ターゲットパス作成〜Vault検出〜ディレクトリ生成〜テンプレートコピー〜初期ファイル生成 + report dict 初期化)_

- [x] 2.3 Git初期化、.gitignore配置、シンボリックリンク作成、完了レポートの実装
  - `.git/` が存在しない場合、`subprocess.run(["git", "init"], cwd=target)` でGitリポジトリを初期化する（既存時はスキップ）。git init 失敗時は警告を表示し、処理を続行する
  - `.gitignore` が存在しない場合、`templates/.gitignore` を `shutil.copy2()` でコピーする（既存時はスキップ）
  - `DEV_ROOT/scripts/rw_light.py` への絶対パスシンボリックリンクを `target/scripts/rw` として `os.symlink()` で作成する
  - rw_light.py に実行権限があることを確認し、不足の場合は `os.chmod()` で付与する（要件5.2）
  - シンボリックリンク作成失敗時は警告メッセージと手動リンク手順（`ln -s ...`）を表示し、処理を続行する
  - タスク2.2 で初期化された `report` dict にGit初期化状態・.gitignoreコピー状態・シンボリックリンク状態を追記し、全ステップの結果（作成ディレクトリ数、コピーされたテンプレート、Git初期化状態、シンボリックリンク状態、スキップされた項目と理由）のサマリーを標準出力に表示する
  - 新規Vault作成後、`.git/` が存在し、`.gitignore` に `raw/incoming/` が含まれ、`scripts/rw` が `rw_light.py` を指す実行可能なシンボリックリンクであり、完了レポートが出力される
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 5.1, 5.2, 5.3, 6.1, 6.2_
  - _Depends: 1.2, 2.1, 2.2_
  - _Boundary: scripts/rw_light.py (cmd_init 関数: Git初期化〜.gitignoreコピー〜シンボリックリンク作成〜report dict 追記・出力)_

- [x] 2.4 re-initフロー（バックアップポリシー）の実装
  - タスク2.2のテンプレートコピー処理およびタスク2.3のシンボリックリンク作成処理を修正し、re-init時のバックアップロジックを各ステップの直前に挿入する（cross-cutting修正）
  - 既存Vault上書き確認後の各アセットバックアップポリシー:
    - CLAUDE.md: 既存を `CLAUDE.md.bak` に `os.rename()` でリネーム後、新テンプレートをコピー（タスク2.2のコピー処理を修正）
    - AGENTS/: `templates/AGENTS/` が存在する場合のみ — 既存 `AGENTS.bak/` を `shutil.rmtree()` で削除（存在時）、既存を `AGENTS.bak/` にリネーム後、`shutil.copytree(dirs_exist_ok=True)` でテンプレートからコピー（`templates/AGENTS/` 不在時はバックアップ・コピーともにスキップ）（タスク2.2のコピー処理を修正）
    - .gitignore: 既存保護（スキップ — タスク2.3の既存スキップロジックがそのまま適用）
    - index.md / log.md: 既存保護（スキップ — タスク2.2の既存スキップロジックがそのまま適用）
    - scripts/rw: `os.remove()` で既存リンクを削除後に再作成（タスク2.3のsymlink作成処理を修正）
  - 既存Vaultに対してre-initを実行し、`CLAUDE.md.bak` が作成され、新しいCLAUDE.mdがコピーされ、既存の index.md / log.md / .gitignore が変更されていない
  - _Requirements: 1.4_
  - _Depends: 2.2, 2.3_
  - _Boundary: scripts/rw_light.py (cmd_init 関数: re-init分岐のバックアップガード — タスク2.2/2.3のコード内に挿入)_

- [x] 2.5 main() ディスパッチと print_usage() の更新
  - `main()` に `"init"` コマンドの分岐を追加し、`cmd_init(sys.argv[2:])` を呼び出す
  - `print_usage()` に `rw init [path]` の使用方法を追加する
  - `python scripts/rw_light.py init` をコマンドラインから実行し、カレントディレクトリに対してVaultセットアップが開始される
  - _Requirements: 1.1, 1.2_
  - _Depends: 2.2, 2.3_
  - _Boundary: scripts/rw_light.py (main 関数の init 分岐 + print_usage 関数)_

- [ ] 3. ドキュメント作成
- [ ] 3.1 (P) README.md の作成
  - プロジェクトの目的と概要（Karpathy式LLM Wikiを参考にした知識ベース構築システム）を記述する
  - `rw init` によるVaultセットアップ手順を記載する
  - 基本的な運用サイクル（ingest → lint → synthesize → approve → audit）の概要を記載する
  - 開発リポジトリのディレクトリ構成（scripts/, templates/, docs/）を説明する
  - README.md が上記4セクションを含み、初めてのユーザがセットアップ手順を追える内容になっている
  - _Requirements: 7.1, 7.2, 7.3, 7.4_
  - _Boundary: README.md_

- [ ] 3.2 (P) CHANGELOG.md の作成
  - Keep a Changelog形式（`## [バージョン] - 日付`）で作成する
  - 初版として project-foundation スペックの成果物（rw init コマンド、templates/CLAUDE.md、Vaultディレクトリ構造、Git初期化、シンボリックリンク、README.md）を記録する
  - CHANGELOG.md が存在し、Keep a Changelog形式の見出しと初版エントリを含む
  - _Requirements: 8.1, 8.2_
  - _Boundary: CHANGELOG.md_
