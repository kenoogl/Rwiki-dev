# Requirements Document

## Introduction
Rwiki知識ベースシステムの実行基盤を構築する。`rw init` コマンドにより、任意のディレクトリにRwiki Vault（運用環境）をセットアップできるようにする。テンプレート（CLAUDE.mdカーネル）は開発リポジトリで管理し、デプロイ時にVaultへコピーする。プロジェクトのREADME.mdおよびCHANGELOG.md初版も作成する。

## Boundary Context
- **In scope**: `rw init` コマンドの実装、`templates/CLAUDE.md` の作成、Vaultディレクトリ構造の生成、Vault用Git初期化と.gitignore、index.md/log.md初期ファイル、rwシンボリックリンク、README.md、CHANGELOG.md初版
- **Out of scope**: AGENTS/サブプロンプトの中身（agents-systemスペック）、query/auditコマンド（cli-query/cli-auditスペック）、テスト体系（test-suiteスペック）、Obsidian Vault設定、開発用CLAUDE.mdの変更
- **Adjacent expectations**: agents-systemスペックが後続で `templates/AGENTS/` を追加する。`rw init` はAGENTS/ディレクトリを作成するが中身は空（またはREADMEのみ）。既存の `scripts/rw_light.py` にinitサブコマンドを追加する形で実装される想定

## Requirements

### Requirement 1: Vaultディレクトリ構造の生成
**Objective:** Rwiki運用者として、`rw init` を実行してVaultの全ディレクトリ構造を一括生成したい。手動でディレクトリを作成する手間をなくすため。

#### Acceptance Criteria
1. When ユーザが `rw init <path>` を実行した場合, the `rw init` shall 指定パスに以下のディレクトリを作成する: `raw/incoming/{articles, papers/zotero, papers/local, meeting-notes, code-snippets}`, `raw/{articles, papers/zotero, papers/local, meeting-notes, code-snippets, llm_logs}`, `review/{synthesis_candidates, query}`, `wiki/{concepts, methods, projects, entities/people, entities/tools, synthesis}`, `logs/`, `scripts/`, `AGENTS/`
2. When ユーザが `rw init` をパス引数なしで実行した場合, the `rw init` shall カレントディレクトリをVaultルートとしてセットアップする
3. If 指定パスが存在しない場合, the `rw init` shall ディレクトリを作成してからセットアップを続行する
4. If 指定パスに既にVault構造が存在する場合（CLAUDE.mdまたはindex.mdが存在）, the `rw init` shall 警告メッセージを表示し、上書きするかどうかユーザに確認を求める

### Requirement 2: テンプレートの管理と配置
**Objective:** Rwiki開発者として、Wiki運用用のCLAUDE.mdカーネルを開発リポジトリの `templates/` で一元管理し、`rw init` 実行時にVaultへ自動配置したい。テンプレートの変更管理を開発リポジトリに集約するため。

#### Acceptance Criteria
1. The `rw init` shall 開発リポジトリの `templates/CLAUDE.md` をVaultルートの `CLAUDE.md` としてコピーする
2. The `templates/CLAUDE.md` shall docs/Rwiki仕様案.md の「グローバルルール」セクションに定義された全ルール（rawの完全性、reviewの強制、承認要件、書き込み権限、インデックスとログ整合性、コミット分離）を含む
3. The `templates/CLAUDE.md` shall タスク分類（9種）とTask→AGENTSマッピングを含む
4. The `templates/CLAUDE.md` shall 実行モデル（実行宣言、マルチステップルール）と失敗条件を含む
5. Where `templates/AGENTS/` が開発リポジトリに存在する場合, the `rw init` shall その内容をVaultの `AGENTS/` にコピーする
6. If `templates/CLAUDE.md` が開発リポジトリに存在しない場合, the `rw init` shall エラーメッセージを表示して処理を中断する

### Requirement 3: Vault用Git初期化
**Objective:** Rwiki運用者として、VaultをGitリポジトリとして初期化し、適切な.gitignoreを自動設定したい。バージョン管理の初期設定を自動化するため。

#### Acceptance Criteria
1. When `rw init` がVaultセットアップを完了した場合, the `rw init` shall Vaultディレクトリで `git init` を実行する
2. The `rw init` shall `.gitignore` を生成し、`raw/incoming/` をGit管理対象外とする
3. The `.gitignore` shall `.obsidian/workspace.json` および `.obsidian/workspace-mobile.json` をGit管理対象外とする（プラグイン設定等の共有可能な設定はGit管理下に置く）
4. If 指定パスに既にGitリポジトリが存在する場合（.git/が存在）, the `rw init` shall 既存のGitリポジトリを維持し、`git init` をスキップする

### Requirement 4: 初期ファイルの生成
**Objective:** Rwiki運用者として、Vaultセットアップ時にindex.mdとlog.mdの初期ファイルが自動生成されてほしい。運用開始に必要なファイルを手動作成する必要をなくすため。

#### Acceptance Criteria
1. When `rw init` がVaultセットアップを完了した場合, the `rw init` shall `index.md` を「# Index」見出しとともに生成する
2. When `rw init` がVaultセットアップを完了した場合, the `rw init` shall `log.md` を「# Log」見出しとともに生成する
3. If `index.md` が既に存在する場合, the `rw init` shall 既存の `index.md` を上書きしない
4. If `log.md` が既に存在する場合, the `rw init` shall 既存の `log.md` を上書きしない

### Requirement 5: CLIエントリポイント
**Objective:** Rwiki運用者として、Vaultで `rw` コマンドを実行してrw_light.pyの全機能にアクセスしたい。CLIの利用を簡便にするため。

#### Acceptance Criteria
1. When `rw init` がVaultセットアップを完了した場合, the `rw init` shall 開発リポジトリの `scripts/rw_light.py` へのシンボリックリンクをVaultの `scripts/rw` として作成する
2. The シンボリックリンク shall 実行権限を持ち、`./scripts/rw <command>` でrw_light.pyの全サブコマンドを実行できる
3. If シンボリックリンクの作成に失敗した場合（パーミッション不足、開発リポジトリパスが無効等）, the `rw init` shall エラーメッセージを表示し、手動リンク手順を案内する

### Requirement 6: セットアップ完了レポート
**Objective:** Rwiki運用者として、`rw init` の完了時に何が作成されたかを把握したい。セットアップ結果を確認するため。

#### Acceptance Criteria
1. When `rw init` が正常に完了した場合, the `rw init` shall 作成されたディレクトリ数、コピーされたテンプレート、初期化されたGitリポジトリ、作成されたシンボリックリンクのサマリーを標準出力に表示する
2. If 一部のステップでスキップや警告が発生した場合, the `rw init` shall スキップされた項目と理由をサマリーに含める

### Requirement 7: README.md
**Objective:** プロジェクト関係者として、プロジェクトの概要とセットアップ手順を一箇所で参照したい。初めてRwikiに触れる人がすぐに使い始められるようにするため。

#### Acceptance Criteria
1. The README.md shall プロジェクトの目的と概要（知識ベース構築システムとしてのRwiki）を説明する
2. The README.md shall `rw init` によるVaultセットアップ手順を記載する
3. The README.md shall 基本的な運用サイクル（ingest → lint → synthesize → approve → audit）の概要を記載する
4. The README.md shall 開発リポジトリのディレクトリ構成の説明を含む

### Requirement 8: CHANGELOG.md
**Objective:** プロジェクト関係者として、変更履歴を追跡したい。何がいつ変更されたかを把握するため。

#### Acceptance Criteria
1. The CHANGELOG.md shall Keep a Changelog形式（## [バージョン] - 日付）に準拠する
2. The CHANGELOG.md shall 初版として project-foundation スペックの成果物を記録する
