# Brief: project-foundation

## Problem
Rwikiの実行基盤が未整備。Vaultをセットアップする仕組み（`rw init`）が存在せず、ディレクトリ構造作成・Wiki用CLAUDE.mdカーネル配置・Vault用Git初期化・CLIシンボリックリンク設定を手動で行う必要がある。

## Current State
- `scripts/rw_light.py` が存在し、コード内でraw/, review/, wiki/等のパスを参照しているが、ディレクトリは未作成
- Gitリポジトリ初期化済み、リモート origin = kenoogl/Rwiki-dev.git に登録済み
- Wiki運用時のCLAUDE.md（カーネル）が未作成（ただし `docs/CLAUDE.md` に素案あり）
- `rw` シンボリックリンク未設定
- `docs/` に事前検討済みのCLAUDE.mdカーネル素案およびサブプロンプト素案が配置済み

## Desired Outcome
- `rw init` で以下のVaultディレクトリ構造が一括生成される：
  - `raw/incoming/{articles, papers/zotero, papers/local, meeting-notes, code-snippets}/`
  - `raw/{articles, papers/zotero, papers/local, meeting-notes, code-snippets, llm_logs}/`
  - `review/{synthesis_candidates, query}/`
  - `wiki/{concepts, methods, projects, entities/people, entities/tools, synthesis}/`
  - `logs/`, `scripts/`, `AGENTS/`
- Vault用Gitリポジトリが初期化され、.gitignoreが適切に設定されている
- Wiki用CLAUDE.mdカーネルが仕様案のグローバルルールに基づいて作成されている（`templates/CLAUDE.md`からコピー）
- `rw` コマンドでrw_light.pyが実行可能

## Approach
開発リポジトリとデプロイ先Vaultは別ディレクトリとする。Wiki運用用のCLAUDE.mdカーネルは `templates/CLAUDE.md` として開発リポジトリで管理する。`rw init` コマンドを新設し、任意のディレクトリにVaultをセットアップ（ディレクトリ構造作成・テンプレートコピー・Git初期化・rwシンボリックリンク）する。

## Scope
- **In**: `rw init` コマンドの実装、`templates/CLAUDE.md`（Wiki運用用カーネル）の作成、Vault用ディレクトリ構造定義、.gitignoreテンプレート、index.md/log.md初期ファイル生成、README.md（プロジェクト概要・セットアップ手順）、CHANGELOG.md初版
- **Out**: AGENTS/サブプロンプトの中身（agents-systemスペックで対応）、新CLIコマンド追加（query/audit）、Obsidian設定

## Boundary Candidates
- `rw init` コマンド（Vaultセットアップ自動化）
- `templates/CLAUDE.md`（Wiki運用用カーネルの内容設計）
- ディレクトリ構造とGit設定テンプレート

## Out of Boundary
- AGENTS/ディレクトリの中身（agents-systemスペック）
- 新しいCLIコマンドの実装（query/audit）
- テスト体系
- 開発用CLAUDE.md（既存、変更しない）

## Upstream / Downstream
- **Upstream**: docs/Rwiki仕様案.md（設計の源泉）
- **Downstream**: agents-system（templates/AGENTS/を追加）, cli-query, cli-audit, test-suite（すべてこの基盤に依存）

## Existing Spec Touchpoints
- **Extends**: なし
- **Adjacent**: なし（最初のスペック）

## Constraints
- CLAUDE.mdカーネルは仕様案の「グローバルルール」セクションに準拠すること
- raw/incoming/ は .gitignore でコミット対象外とする（仕様: 未検証でありコミットしてはならない）
- ディレクトリ構造は仕様案の「層管理」に完全準拠
- 開発用CLAUDE.md（Kiro/Spec設定）とWiki運用用CLAUDE.md（Rwikiグローバルルール）は別ファイル
- テンプレートのマスターは開発リポジトリの `templates/` で管理
