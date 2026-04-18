# Gap Analysis: test-suite

## 現状調査

### テストカバレッジ状況

| 要件 | 対象 | 既存テスト | ギャップ |
|------|------|-----------|---------|
| Req 1: テストインフラ | conftest.py, フィクスチャ, pytest 設定 | なし | **Missing** — conftest.py 未作成、フィクスチャはインライン定義 |
| Req 2: ユーティリティ単体 | parse_frontmatter, slugify 等 11 関数 | なし | **Missing** — 中核ユーティリティのテストが一切ない |
| Req 3: Git 操作 | git_commit, git_status_porcelain, git_path_is_dirty | なし | **Missing** |
| Req 4: lint | cmd_lint (L317) | なし | **Missing** |
| Req 5: ingest | cmd_ingest (L404) | なし | **Missing** |
| Req 6: synthesize-logs | cmd_synthesize_logs (L536) | なし | **Missing** |
| Req 7: approve | cmd_approve (L709) | なし | **Missing** |
| Req 8: lint-query | cmd_lint_query (L3034) | なし | **Missing** |
| Req 9: init | cmd_init (L3231) | なし | **Missing** |
| ~~Req 10: audit-monthly/quarterly~~ | ~~cmd_audit_monthly / cmd_audit_quarterly~~ | **既存テストでカバー済み** | 削除 — TestRunLlmAudit (18テスト) + E2E で tier ルーティング・戻り値・エラー処理すべて検証済み |
| Req 10: 開発者ドキュメント | docs/developer-guide.md, CHANGELOG | なし | **Missing** |

### 既存テストの規約・パターン

- **テストファイル**: tests/test_rw_light.py（6,326 行、49 クラス、450+ テストメソッド）
- **構成**: クラスベース、関数名は `test_<動作>` パターン
- **フィクスチャ**: pytest `tmp_path` + `monkeypatch`、`_setup_*` ヘルパー関数をインライン定義
- **モック戦略**: `monkeypatch.setattr()` のみ使用（`unittest.mock` 不使用）
  - `subprocess.run` を直接モックし `CompletedProcess` を返す
  - モジュール定数（`ROOT`, `WIKI`, `INDEX_MD` 等）を `monkeypatch.setattr` で差し替え
- **アサーション**: bare `assert` + `pytest.raises()` + `capsys.readouterr()`
- **インポート**: `sys.path.insert()` で scripts/ を追加し `import rw_light`

### モジュール定数の monkeypatch 対象

既存テストで確認された主要な monkeypatch 対象：
- `rw_light.ROOT` — Vault ルートパス
- `rw_light.WIKI` — wiki/ ディレクトリ
- `rw_light.INDEX_MD` — index.md パス
- `rw_light.LOG_MD` — log.md パス
- `rw_light.REVIEW` — review/ ディレクトリ
- `rw_light.RAW` — raw/ ディレクトリ
- `rw_light.LOGS` — logs/ ディレクトリ
- `rw_light.AGENTS_DIR` — AGENTS/ ディレクトリ
- `rw_light.today` — 日付関数

### call_claude 呼び出し箇所（モック境界）

| コマンド | 関数 | 行 | モック方法 |
|---------|------|------|----------|
| synthesize-logs | cmd_synthesize_logs | L536 内 | subprocess.run モック |
| query-extract | cmd_query_extract | L2631, L2674 | subprocess.run モック（2 段階呼び出し） |
| query-answer | cmd_query_answer | L2779 | subprocess.run モック |
| query-fix | cmd_query_fix | L3181 | subprocess.run モック |
| audit-monthly | _run_llm_audit | L2340 | subprocess.run モック |
| audit-quarterly | _run_llm_audit | L2342 | subprocess.run モック |

### 未テストコマンドの依存分析

| コマンド | ファイル I/O | Git 操作 | Claude CLI | 主な検証ポイント |
|---------|------------|---------|-----------|----------------|
| lint | incoming/ 読み込み → サブディレクトリ移動 | なし | なし | フロントマター検証、ファイル移動ロジック |
| ingest | pending → raw/ 移動 | git_commit | なし | ディレクトリ判定、コミット呼び出し |
| synthesize-logs | llm_logs/ 読み込み → review/ 書き出し | なし | call_claude | プロンプト構築、レスポンスパース |
| approve | review/synthesis_candidates/ → wiki/ 移動 | git_commit | なし | index.md 更新、ディレクトリ振り分け |
| lint-query | review/query/ 読み込み | なし | なし | 品質スコア計算、logs/ JSON 出力 |
| init | ディレクトリ作成、テンプレートコピー | git init | なし | 構造検証、テンプレート整合性 |
| audit-monthly | wiki/ 読み込み | なし | call_claude | プロンプト構築、レスポンスパース |
| audit-quarterly | wiki/ 読み込み | なし | call_claude | プロンプト構築、レスポンスパース |

## 実装アプローチ評価

### Option A: 既存ファイル拡張（test_rw_light.py に追記）

- **対象**: 全新規テストを既存の test_rw_light.py に追加
- **Trade-offs**:
  - ✅ 既存パターンとの一貫性を維持
  - ✅ インポート・ヘルパー関数を共有可能
  - ❌ 6,326 行 → 推定 10,000+ 行に膨張（保守限界超過）
  - ❌ テスト実行時間の増加（並列化困難）

### Option B: 新規テストファイル分割 + conftest.py

- **対象**: 機能別にテストファイルを分割、共通フィクスチャを conftest.py に集約
- **分割案**（要件再生成後の番号に更新済み）:
  - `tests/conftest.py` — 共通フィクスチャ（Vault 構築、フロントマター生成）（Req 1）
  - `tests/test_utils.py` — ユーティリティ関数単体テスト（Req 2）
  - `tests/test_git_ops.py` — Git 操作関数（Req 3）
  - `tests/test_lint.py` — lint コマンド（Req 4）
  - `tests/test_ingest.py` — ingest コマンド（Req 5）
  - `tests/test_synthesize_logs.py` — synthesize-logs コマンド（Req 6）
  - `tests/test_approve.py` — approve コマンド（Req 7）
  - `tests/test_lint_query.py` — lint-query コマンド（Req 8）
  - `tests/test_init.py` — init コマンド（Req 9）
  - ~~`tests/test_audit_llm.py`~~ — 削除（既存テストでカバー済み）
- **Trade-offs**:
  - ✅ 各ファイルが小さく保守しやすい
  - ✅ pytest が自動でファイル並列実行可能
  - ✅ conftest.py でフィクスチャ再利用
  - ❌ 既存テストファイルとの規約の二重管理
  - ❌ 既存テストの移動・リファクタリングはスコープ外

### Option C: ハイブリッド（推奨）

- **対象**: 新規テストは分割ファイルで作成、既存テストはそのまま維持
- **戦略**:
  - conftest.py を作成し、新規テストで使用するフィクスチャを定義
  - 既存 test_rw_light.py のインラインフィクスチャはそのまま（リファクタリングはスコープ外）
  - 新規テストファイルは Option B の分割案に従う
  - 既存テストと新規テストの命名規約・アサーションスタイルを統一
- **Trade-offs**:
  - ✅ 既存テストを壊さない
  - ✅ 新規テストは整理された構造
  - ✅ 段階的にフィクスチャを conftest.py へ移行可能
  - ❌ 過渡期にフィクスチャが 2 箇所（conftest.py + test_rw_light.py インライン）に存在

## 技術的制約と注意事項

### Constraint: Git 操作テストの隔離
- `git_commit`, `git_status_porcelain`, `git_path_is_dirty` は `subprocess.run` で git コマンドを実行
- テストでは実際の Git リポジトリを tmp_path 上に `git init` で作成するか、subprocess.run をモックする
- 実 Git リポジトリ方式はテストの信頼性が高いが、テスト速度に影響

### Constraint: init コマンドのテンプレート依存
- `cmd_init` は templates/CLAUDE.md と templates/AGENTS/ を実際にコピーする
- テストでは実テンプレートファイルへのパス（`TEMPLATES_DIR`）をそのまま使用するか、モックテンプレートを使用するか選択が必要
- 既存テストでは `TEMPLATES_CLAUDE_MD` 定数で実テンプレートを参照するパターンあり

### Research Needed
- lint コマンドの内部ロジック詳細（フロントマター検証ルールの網羅的把握）— 設計フェーズで調査
- approve コマンドの index.md 更新ロジック詳細 — 設計フェーズで調査

## 工数・リスク評価

- **Effort**: M（3-7 日）— 既存パターンが確立されており、主にテストケース作成の繰り返し。ただし 8 コマンド + ユーティリティ + ドキュメントで量が多い
- **Risk**: Low — 既存テストパターンが明確、新規コードへの影響なし、既存機能の動作変更なし

## 設計フェーズへの推奨事項

- **推奨アプローチ**: Option C（ハイブリッド）
- **Key Decisions**:
  - conftest.py のフィクスチャ設計（Vault 構築ヘルパーの粒度）
  - Git 操作テストの実 Git vs モック方針
  - init テストのテンプレート参照方針
- **Research Items**:
  - cmd_lint の内部フロントマター検証ルールの詳細把握
  - cmd_approve の index.md 更新・ディレクトリ振り分けロジックの詳細把握
