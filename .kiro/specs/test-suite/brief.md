# Brief: test-suite

## Problem
rw_light.py（3,490 行）の一部コマンドとユーティリティ関数にテストが存在しない。cli-query・cli-audit スペック実装時に query 系・audit 系のテストは作成されたが、lint・ingest・synthesize-logs・approve・init 等の初期コマンドと、parse_frontmatter・slugify 等の中核ユーティリティは未検証のままであり、リグレッションリスクが高い。

## Current State
- tests/test_rw_light.py（6,326 行、49 クラス、450+ テストメソッド）が存在
- テスト済み: query 系（extract/answer/fix）、audit 系（check_*, run_micro/weekly_checks, _run_llm_audit, map_severity, parse_audit_response 等）、Prompt Engine（parse_agent_mapping, load_task_prompts, call_claude, build_query_prompt 等）
- 未テスト: cmd_lint, cmd_ingest, cmd_synthesize_logs, cmd_approve, cmd_lint_query, cmd_init、および parse_frontmatter, build_frontmatter, slugify, list_md_files, first_h1, ensure_basic_frontmatter, git_commit, git_status_porcelain, git_path_is_dirty 等のユーティリティ関数
- conftest.py は未作成。フィクスチャはテストファイル内にインライン定義

## Desired Outcome
- 未テスト領域のテストが追加されている
- ユーティリティ関数（frontmatter解析、slugify等）の単体テスト
- 未テストCLIコマンド（init, lint, ingest, synthesize-logs, approve, lint query）の統合テスト
- conftest.py に共通フィクスチャが集約されている
- docs/developer-guide.md（コントリビューション手順・テスト実行方法・アーキテクチャ概要）が作成されている
- `pytest` 一発で既存テスト・新規テストの両方が実行可能

## Approach
TDD原則に基づき、既存コードに対してまずテストを作成し失敗を確認、その後必要に応じてコードを修正する。テストはtests/ディレクトリに機能別ファイルとして配置し、pytestで実行する。tmp_pathフィクスチャでファイルシステムを隔離し、monkeypatchでモジュール定数を差し替える。

## Scope
- **In**: conftest.py（共通フィクスチャ）、ユーティリティ関数テスト、init/lint/ingest/synthesize-logs/approve/lint queryテスト、audit-monthly/quarterlyエントリポイントテスト、エラー処理テスト、docs/developer-guide.md、CHANGELOG.md追記
- **Out**: CI/CD設定、カバレッジ目標設定、E2Eテスト（Claude CLI呼び出しを含むもの）、既存テスト（test_rw_light.py）のリファクタリング・移動

## Boundary Candidates
- ユーティリティ関数の単体テスト
- CLIコマンドの統合テスト（ファイルシステム操作）
- LLM呼び出し部分のモック戦略（synthesize-logs は call_claude_for_log_synthesis、query/audit は call_claude — モック境界が異なる）

## Out of Boundary
- CI/CDパイプライン
- パフォーマンステスト
- Claude CLI呼び出しの実E2Eテスト
- 既存テストのリファクタリング

## Upstream / Downstream
- **Upstream**: project-foundation, cli-query, cli-audit（テスト対象のコード）
- **Downstream**: なし（最終スペック）

## Existing Spec Touchpoints
- **Extends**: なし
- **Adjacent**: cli-query, cli-audit（テスト済みコマンドのコード。既存テストを変更しない）

## Constraints
- TDD（テストファースト）で進める
- 2スペースインデント
- Claude CLI呼び出し部分はモックする（synthesize-logs: call_claude_for_log_synthesis、monthly/quarterly audit: call_claude）
- pytestを使用
- テストはtmp_pathフィクスチャでファイルシステムを隔離
- monkeypatch.setattrでモジュール定数を差し替え（unittest.mockは不使用）
