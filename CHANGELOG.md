# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added — cli-audit スペック

- `rw audit micro` — 直近の更新ページを対象とした高速静的チェック（Tier 0: Micro-check）。リンク切れ・index.md 未登録・frontmatter パースエラーを検出。Claude CLI 不使用
- `rw audit weekly` — 全ページを対象とした構造チェック（Tier 1: Structural Audit）。micro のスーパーセット。孤立ページ・双方向リンク欠落・命名規則違反・source フィールド欠落を追加検出。Claude CLI 不使用
- `rw audit monthly` — LLM 支援による意味的監査（Tier 2: Semantic Audit）。wiki ページ間の矛盾（`[CONFLICT]`）・緊張関係（`[TENSION]`）・曖昧さ（`[AMBIGUOUS]`）を Claude CLI で検出
- `rw audit quarterly` — LLM 支援による戦略的監査（Tier 3: Strategic Audit）。wiki グラフ構造の俯瞰・カバレッジギャップ・スキーマ改訂提案を Claude CLI で生成
- 統一レポート出力: `logs/audit-<tier>-<YYYYMMDD-HHMMSS>.md` 形式。Summary・Findings・Metrics・Recommended Actions セクションを含む
- プロジェクト標準3水準 severity（ERROR / WARN / INFO）と統一終了コード（exit 0: PASS / exit 1: FAIL）
- Claude 内部4段階（CRITICAL / HIGH / MEDIUM / LOW）→ CLI 3水準へのマッピング（CRITICAL/HIGH → ERROR、MEDIUM → WARN、LOW → INFO）
- `docs/user-guide.md`: `rw audit micro`・`rw audit weekly`・`rw audit monthly`・`rw audit quarterly` のリファレンスを追記

### Changed — cli-audit スペック

- `templates/CLAUDE.md`: audit の Execution Mode を `Prompt` → `CLI (Hybrid)` に更新
- `templates/AGENTS/audit.md`: Execution Mode セクションを CLI (Hybrid) の実態に合わせて更新
- `templates/AGENTS/README.md`: エージェント一覧テーブルの audit 行を `CLI (Hybrid)` に更新
- `docs/user-guide.md`: 基本的な運用サイクルの audit ステップ説明を `Prompt` → `CLI Hybrid` に更新

### Added — cli-query スペック

- `rw query extract` — wiki 知識から構造化クエリアーティファクトを生成するサブコマンド
- `rw query answer` — wiki 知識に基づく直接回答を stdout に表示するサブコマンド
- `rw query fix` — lint 結果に基づくクエリアーティファクト修復サブコマンド
- Prompt Engine: CLAUDE.md マッピングに基づく AGENTS/ ファイルの動的読み込み（プロンプト一元管理）
- query_id 自動生成（YYYYMMDD-slug 形式）
- 自動 lint 検証（extract/fix コマンド実行後）

### Changed — cli-query スペック

- query_extract・query_answer・query_fix の Execution Mode を `Prompt` → `CLI (Hybrid)` に更新

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
