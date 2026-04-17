# Brief: test-suite

## Problem
rw_light.pyに対するテストが一切存在しない。複雑なlintロジック、ファイル移動、frontmatter解析、メタデータ検証などが無検証で、リグレッションリスクが高い。

## Current State
- テストディレクトリ・テストファイルが存在しない
- rw_light.pyには約1040行のコードがあり、ユーティリティ関数・lint・ingest・synthesize-logs・approve・lint queryの機能を含む
- 今後cli-query, cli-auditの追加でさらにコード量が増加する予定

## Desired Outcome
- pytest を使用したテスト体系が構築されている
- ユーティリティ関数（frontmatter解析、slugify等）の単体テスト
- 各CLIコマンド（init, lint, ingest, synthesize-logs, approve, lint query, query, audit）の統合テスト
- テストフィクスチャ（サンプルMarkdownファイル、ディレクトリ構造）が整備されている
- `pytest` 一発で全テスト実行可能

## Approach
TDD原則に基づき、既存コードに対してまずテストを作成し失敗を確認、その後必要に応じてコードを修正する。テストはtests/ディレクトリに配置し、pytestで実行する。tmpディレクトリを使ったファイルシステムテストでrw_light.pyのROOTを差し替える。

## Scope
- **In**: tests/ディレクトリ構成、pytest設定、ユーティリティ関数テスト、init/lint/ingest/approve/lint queryテスト、query系コマンドテスト、audit系コマンドテスト、テストフィクスチャ、docs/developer-guide.md（コントリビューション手順・テスト実行方法・アーキテクチャ概要）、CHANGELOG.md追記
- **Out**: CI/CD設定、カバレッジ目標設定、E2Eテスト（Claude CLI呼び出しを含むもの）

## Boundary Candidates
- ユーティリティ関数の単体テスト
- CLIコマンドの統合テスト（ファイルシステム操作）
- LLM呼び出し部分のモック戦略

## Out of Boundary
- CI/CDパイプライン
- パフォーマンステスト
- Claude CLI呼び出しの実E2Eテスト

## Upstream / Downstream
- **Upstream**: project-foundation, cli-query, cli-audit（テスト対象のコード）
- **Downstream**: なし（最終スペック）

## Existing Spec Touchpoints
- **Extends**: なし
- **Adjacent**: cli-query, cli-audit（追加コマンドのテストを含む）

## Constraints
- TDD（テストファースト）で進める
- 2スペースインデント
- Claude CLI呼び出し部分はモックする（synthesize-logs, monthly/quarterly audit）
- pytestを使用
- テストはtmp_pathフィクスチャでファイルシステムを隔離
