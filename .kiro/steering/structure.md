# Project Structure

## Organization Philosophy

**パイプライン・ファースト設計** — ディレクトリ構造は 3 層データパイプライン（Raw → Review → Wiki）を反映する。CLI ツールは責務別 6 モジュール構成（`scripts/rw_*.py`）で DAG 依存を維持する。

## Directory Patterns

### データ層（Vault 内）
**Location**: `raw/`, `review/`, `wiki/`
**Purpose**: パイプラインの各段階に対応するナレッジストア
**Rules**: LLM は raw/wiki に直接書き込み不可。review/ は LLM 生成の候補を格納

### CLI ツール
**Location**: `scripts/rw_*.py`（責務別 6 モジュール）
**Purpose**: 全コマンドを責務単位に分割したレイヤード CLI
**Module Structure**（DAG、各モジュール ≤ 1,500 行）:
- `rw_config.py`（Layer 0）: 全グローバル定数（パス + ドメイン）の単一ソース
- `rw_utils.py`（Layer 1）: 汎用ユーティリティ（ファイル I/O, git, frontmatter, 日付, severity/status 計算）
- `rw_prompt_engine.py`（Layer 2）: Claude CLI 呼び出し + プロンプト/Wiki コンテンツ構築
- `rw_audit.py`（Layer 3）: audit コマンド + チェック関数群 + LLM audit フロー
- `rw_query.py`（Layer 3）: query コマンド + query lint 検査関数群
- `rw_cli.py`（Layer 4）: エントリポイント + `main()`/argparse dispatch + 残留コマンド（`cmd_lint` / `cmd_ingest` / `cmd_synthesize_logs` / `cmd_approve` / `cmd_init`）
**Implemented**: `lint`, `ingest`, `synthesize-logs`, `approve`, `query-extract`, `query-answer`, `lint-query`, `query-fix`, `init`, `audit`（micro/weekly/monthly/quarterly の 4 サブコマンド）
**Pattern**: 下位レイヤのみ import する DAG 構造、モジュール修飾参照（`rw_<module>.<symbol>`）を徹底してテスト monkeypatch の作用経路を保証。`rw_cli` への後方互換 re-export は一切提供しない

### プロンプトテンプレート
**Location**: `templates/AGENTS/`
**Purpose**: AI タスク別のプロンプト定義（audit, synthesize, query_answer 等）
**Pattern**: 1 タスク = 1 Markdown ファイル

### ドキュメント
**Location**: `docs/`
**Purpose**: ユーザーガイド、開発者ガイド、運用仕様、CHANGELOG
**Pattern**: 機能別に分割（user-guide.md, developer-guide.md, git_ops.md, audit.md）

### テスト
**Location**: `tests/`
**Purpose**: CLI のユニットテスト・E2E テスト
**Pattern**: コマンド・機能領域ごとにファイル分割（`test_utils.py`, `test_git_ops.py`, `test_lint.py`, `test_ingest.py` 等）、共有フィクスチャは `conftest.py` に集約

### ログ出力
**Location**: `logs/`
**Purpose**: lint/query 結果の JSON ログ
**Pattern**: `{command}_latest.json` 命名規則

## Naming Conventions

- **Files**: snake_case（`rw_cli.py`, `rw_config.py`, `rw_audit.py`, `query_answer.md`）
- **Directories**: lowercase + underscore（`synthesis_candidates`, `query_review`）
- **CLI Commands**: 動詞ベース（`lint`, `ingest`, `query`, `audit`, `approve`）
- **Functions**: snake_case、用途を明示（`parse_frontmatter`, `list_md_files`, `git_commit`）
- **Frontmatter**: ISO 日付（YYYY-MM-DD）、スラッグ化タイトル

## Import Organization

```python
# 標準ライブラリのみ — 外部依存なし
import json, os, re, shutil, subprocess, sys
from pathlib import Path
from datetime import datetime
from typing import Optional, List, Dict, Tuple
```

## Code Organization Principles

- **ユーティリティ・ファースト**: ファイル I/O、Git 操作、フォーマットパーサーを純関数として定義（`rw_utils.py`）
- **責務別モジュール分割**: CLI ツールを責務単位の 6 モジュールに分割（Layer 0–4 の DAG）。`rw_cli.py` はエントリポイント + 残留コマンド + dispatch のみ。新規コマンド追加時はその責務に対応するレイヤに配置する
- **モジュール修飾参照規約**: サブモジュール内の関数呼び出しは `rw_<module>.<symbol>(...)` 形式で行い、`from rw_<module> import <symbol>` を禁止。これによりテストの `monkeypatch.setattr(rw_<module>, "<symbol>", mock)` が全呼び出し経路で作用する
- **後方互換 re-export の排除**: 移動済みシンボルへの `rw_cli.<symbol>` 形式のアクセスは提供しない。テスト・ドキュメント・外部コードは `rw_<module>.<symbol>` 形式で直接参照する
- **フロントマター駆動メタデータ**: 全 Markdown ファイルに YAML フロントマターを付与
- **構造化ログ**: 検証・lint 結果は JSON で出力、人間用サマリーは標準出力

---
_created_at: 2026-04-18_
_updated_at: 2026-04-20_
_change: module-split 完了による CLI 6 モジュール構成（Layer 0–4 の DAG）、モジュール修飾参照規約、re-export 排除方針を反映_
