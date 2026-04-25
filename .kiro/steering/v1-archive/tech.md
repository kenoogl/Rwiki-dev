# Technology Stack

## Architecture

3 層データパイプライン（Raw → Review → Wiki）を中心とした CLI ツール。人間承認ゲートにより知識品質を制御する。

## Core Technologies

- **Language**: Python 3.10+（型ヒント完全対応）
- **Dependencies**: 標準ライブラリのみ（json, os, re, shutil, subprocess, pathlib, datetime, typing）
- **CLI**: カスタム argparse ベース（エントリポイント: `scripts/rw_cli.py`、責務別 6 モジュール構成）
- **Data Format**: Markdown + YAML フロントマター
- **Version Control**: Git 統合（変更追跡・コミット自動化）
- **LLM Integration**: Claude API（subprocess 経由の `claude` CLI 呼び出し）

## Key Libraries

外部依存なし。ポータビリティとシンプルさを最優先する設計判断。

## Development Standards

### Type Safety
- Python 3.10+ 型ヒント構文を全関数で使用
- `typing` モジュール活用（Optional, List, Dict, Tuple）

### Code Quality
- Linter/Formatter の設定ファイルなし — Git pre-commit 規律に依存
- 2 スペースインデント

### Testing
- **Framework**: pytest
- テストファイル: コマンド・機能領域ごとに分割（`tests/test_*.py`）、共有フィクスチャは `tests/conftest.py`
- TDD アプローチ（テスト先行 → 実装）

## Development Environment

### Required Tools
- Python 3.10+
- Git
- Claude CLI（synthesize/query/audit コマンド用）

### Common Commands
```bash
# Test: pytest tests/
# CLI:  python scripts/rw_cli.py <command> [options]
# Init: python scripts/rw_cli.py init <vault-path>
```

## Key Technical Decisions

- **責務別モジュール分割 CLI**: CLI ツールを 6 モジュール（`rw_config` / `rw_utils` / `rw_prompt_engine` / `rw_audit` / `rw_query` / `rw_cli`）に分割し Layer 0–4 の DAG を維持 — 各モジュール ≤ 1,500 行、モジュール修飾参照規約（`rw_<module>.<symbol>`）を徹底、後方互換 re-export は一切提供しない。`scripts/` 直下に全モジュールを配置し `sys.path[0]` 自動解決で Vault symlink 経由起動を保証（PYTHONPATH 不要）
- **フロントマター駆動**: メタデータ（date, source, tags, type, status）を Markdown フロントマターで管理
- **JSON ログ**: lint/query 結果を構造化 JSON で出力（`logs/` ディレクトリ）
- **AGENTS/ プロンプトシステム**: AI タスク別にモジュール化されたプロンプトテンプレート
- **Prompt Engine（単一ソース原則）**: Claude CLI を呼ぶ新規コマンドは `AGENTS/{task}.md` + 関連ポリシーを動的ロードしてプロンプトを構築する（`rw_cli.py` の `Prompt Engine` セクション）。CLI 側にプロンプトをハードコードせず、AGENTS/ を唯一のソースとする。既存 `synthesize-logs` の二重管理は段階的に解消予定
- **Severity/Status/Exit Code 統一契約**: 全 CLI コマンドで統一された 3 層契約を維持する:
  - **Severity**: `CRITICAL` / `ERROR` / `WARN` / `INFO`（AGENTS も同名 4 水準）
  - **Status**: `PASS` / `FAIL` の 2 値（`CRITICAL` または `ERROR` が 1 件以上 → `FAIL`）
  - **Exit Code**: `0`=PASS / `1`=runtime error / `2`=自身の FAIL 検出
  - 実装パターン: `_compute_run_status(findings)` と `_compute_exit_code(status, had_runtime_error)` を全コマンドで共用
  - `cmd_ingest` など status を自発的に判定しないコマンドは exit 0/1 の 2 値のみ（exit 2 を発行しない）

---
_created_at: 2026-04-18_
_updated_at: 2026-04-21_
_change: rw-light-rename 完了により CLI エントリポイントを `rw_light.py` → `rw_cli.py` に更新（命名規約との整合）_
