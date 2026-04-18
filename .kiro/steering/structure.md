# Project Structure

## Organization Philosophy

**パイプライン・ファースト設計** — ディレクトリ構造は 3 層データパイプライン（Raw → Review → Wiki）を反映する。コードはユーティリティ中心の単一 CLI ツールに集約。

## Directory Patterns

### データ層（Vault 内）
**Location**: `raw/`, `review/`, `wiki/`
**Purpose**: パイプラインの各段階に対応するナレッジストア
**Rules**: LLM は raw/wiki に直接書き込み不可。review/ は LLM 生成の候補を格納

### CLI ツール
**Location**: `scripts/rw_light.py`
**Purpose**: 全コマンドを集約したモノリシック CLI
**Implemented**: `lint`, `ingest`, `synthesize-logs`, `approve`, `query-extract`, `query-answer`, `lint-query`, `query-fix`, `init`
**Planned**: `audit`（cli-audit スペック実装待ち）
**Pattern**: ユーティリティ関数群 → コマンドハンドラ → argparse エントリポイント

### プロンプトテンプレート
**Location**: `templates/AGENTS/`
**Purpose**: AI タスク別のプロンプト定義（audit, synthesize, query_answer 等）
**Pattern**: 1 タスク = 1 Markdown ファイル

### ドキュメント
**Location**: `docs/`
**Purpose**: ユーザーガイド、運用仕様、CHANGELOG
**Pattern**: 機能別に分割（user-guide.md, git_ops.md, audit.md）

### テスト
**Location**: `tests/`
**Purpose**: CLI のユニットテスト・E2E テスト
**Pattern**: `test_rw_light.py` に集約

### ログ出力
**Location**: `logs/`
**Purpose**: lint/query 結果の JSON ログ
**Pattern**: `{command}_latest.json` 命名規則

## Naming Conventions

- **Files**: snake_case（`rw_light.py`, `query_answer.md`）
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

- **ユーティリティ・ファースト**: ファイル I/O、Git 操作、フォーマットパーサーを純関数として定義
- **単一ファイル集約**: ポータビリティのため全機能を `rw_light.py` に集約
- **フロントマター駆動メタデータ**: 全 Markdown ファイルに YAML フロントマターを付与
- **構造化ログ**: 検証・lint 結果は JSON で出力、人間用サマリーは標準出力

---
_created_at: 2026-04-18_
