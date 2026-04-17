# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [0.1.0] - 2026-04-17

### Added
- `rw init` コマンド: Vault一括セットアップ（ディレクトリ構造生成、テンプレート配置、Git初期化、シンボリックリンク作成）
- `templates/CLAUDE.md`: Wiki運用カーネル（グローバルルール、タスク分類、実行モデル定義）
- `templates/.gitignore`: Vault用.gitignoreテンプレート（raw/incoming/ および .obsidian/workspace*.json を除外）
- Vault ディレクトリ構造: `rw init` による22ディレクトリの自動生成（raw/, review/, wiki/, logs/, scripts/, AGENTS/ 配下）
- Git初期化: `rw init` 実行時の `git init` および `.gitignore` 自動配置
- `scripts/rw` シンボリックリンク: `scripts/rw_light.py` への実行可能シンボリックリンク
- `README.md`: プロジェクト概要、セットアップ手順、運用サイクル、ディレクトリ構成の説明
- `CHANGELOG.md`: 本ファイル（変更履歴の記録開始）
