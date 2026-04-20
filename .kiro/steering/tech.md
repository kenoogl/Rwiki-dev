# Technology Stack

## Architecture

3 層データパイプライン（Raw → Review → Wiki）を中心とした CLI ツール。人間承認ゲートにより知識品質を制御する。

## Core Technologies

- **Language**: Python 3.10+（型ヒント完全対応）
- **Dependencies**: 標準ライブラリのみ（json, os, re, shutil, subprocess, pathlib, datetime, typing）
- **CLI**: カスタム argparse ベース（`scripts/rw_light.py`）
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
# CLI:  python scripts/rw_light.py <command> [options]
# Init: python scripts/rw_light.py init <vault-path>
```

## Key Technical Decisions

- **モノリシック CLI**: 全コマンドを単一ファイル（`rw_light.py`）に集約 — ポータビリティ重視
- **フロントマター駆動**: メタデータ（date, source, tags, type, status）を Markdown フロントマターで管理
- **JSON ログ**: lint/query 結果を構造化 JSON で出力（`logs/` ディレクトリ）
- **AGENTS/ プロンプトシステム**: AI タスク別にモジュール化されたプロンプトテンプレート
- **Prompt Engine（単一ソース原則）**: Claude CLI を呼ぶ新規コマンドは `AGENTS/{task}.md` + 関連ポリシーを動的ロードしてプロンプトを構築する（`rw_light.py` の `Prompt Engine` セクション）。CLI 側にプロンプトをハードコードせず、AGENTS/ を唯一のソースとする。既存 `synthesize-logs` の二重管理は段階的に解消予定

---
_created_at: 2026-04-18_
_updated_at: 2026-04-20_
_change: Prompt Engine（AGENTS/ 動的ロードによる単一ソース原則）を Key Technical Decisions に追加_
