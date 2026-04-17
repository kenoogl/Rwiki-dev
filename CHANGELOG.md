# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added — agents-system スペック

- `templates/AGENTS/` ディレクトリ: タスク種別ごとのサブプロンプト体系を新設
- **9タスクエージェントファイル**:
  - `templates/AGENTS/ingest.md`: raw/incoming/ から raw/ へのファイル移動ルール（CLI）
  - `templates/AGENTS/lint.md`: raw/incoming/ のバリデーション・正規化ルール（CLI）
  - `templates/AGENTS/synthesize.md`: raw/ から review/ への知識候補生成ルール（Prompt）
  - `templates/AGENTS/synthesize_logs.md`: llm_logsからsynthesis候補抽出ルール（CLI Hybrid）
  - `templates/AGENTS/approve.md`: synthesis候補の wiki/synthesis/ 昇格ルール（CLI）
  - `templates/AGENTS/query_answer.md`: wiki知識を使った直接回答ルール（Prompt）
  - `templates/AGENTS/query_extract.md`: 構造化クエリアーティファクト生成ルール（Prompt）
  - `templates/AGENTS/query_fix.md`: クエリアーティファクトのlint修復ルール（Prompt）
  - `templates/AGENTS/audit.md`: wiki整合性・一貫性・構造監査ルール（Prompt、4ティア）
- **3ポリシー**:
  - `templates/AGENTS/page_policy.md`: Wikiページ種別定義と選択ルール
  - `templates/AGENTS/naming.md`: ファイル名・スラッグ・frontmatterの命名規則
  - `templates/AGENTS/git_ops.md`: Gitオペレーション・コミット分離ルール
- `templates/AGENTS/README.md`: エージェント体系の概要・一覧・依存マトリクス・追加手順
- `templates/CLAUDE.md` 更新: マッピング表をポリシー列・実行モード列付きテーブルに拡張、Execution Flow・Agent Loading Procedure・失敗条件判定基準・Extension Guideを追記
- `docs/user-guide.md`: 運用サイクル・CLIリファレンス・プロンプト実行手順・Vault更新手順の初版

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
