# Rwiki-dev

Karpathy の LLM Wiki アプローチにインスパイアされた、AI 支援型の知識ベース構築システム。

## プロジェクト概要

Rwiki は、ローカルの Markdown ファイルを 3 層パイプライン（raw → review → wiki）で処理し、断片的な情報を体系的な知識ベースへと変換するシステムです。

- **raw 層**: 未処理の入力素材（記事、論文、会議メモ、コードスニペット、LLM ログ）
- **review 層**: 合成候補およびクエリ用の中間ステージ
- **wiki 層**: 人間が承認した最終的な知識（概念、手法、プロジェクト、エンティティ、合成記事）

すべての wiki への書き込みは人間の承認を必須とし、LLM が直接 raw 層を書き換えることを禁止することで、知識の正確性と信頼性を担保します。

## Vault セットアップ

`rw init` コマンドを使って任意のディレクトリを Rwiki Vault として初期化します。

### 前提条件

- Python 3.10 以上
- Git
- Claude CLI（`synthesize-logs`・`query`・`audit monthly/quarterly` コマンドで使用）

### 手順

```bash
# 1. このリポジトリをクローン
git clone <repo-url> ~/Rwiki-dev
cd ~/Rwiki-dev

# 2. 新しい Vault を作成する（パスを指定）
python scripts/rw_cli.py init ~/my-vault

# または、カレントディレクトリを Vault として初期化
mkdir ~/my-vault && cd ~/my-vault
python /path/to/Rwiki-dev/scripts/rw_cli.py init
```

`rw init` は以下を自動生成します。

| 項目 | 内容 |
|------|------|
| ディレクトリ構造 | `raw/`, `review/`, `wiki/`, `logs/`, `scripts/`, `AGENTS/` など 22 ディレクトリ |
| `CLAUDE.md` | Wiki 運用ルールカーネル（`templates/CLAUDE.md` からコピー） |
| `AGENTS/` | AI タスク別プロンプトテンプレート（`templates/AGENTS/` からコピー） |
| `.gitignore` | `raw/incoming/` および `.obsidian/workspace*` を除外 |
| `index.md` | インデックスファイルの初期版 |
| `log.md` | 操作ログファイルの初期版 |
| `scripts/rw` | `rw_cli.py` へのシンボリックリンク |
| Git リポジトリ | `git init` による Vault の初期化 |

セットアップ完了後、Vault ディレクトリ内で `./scripts/rw <command>` を使って各コマンドを実行できます。

## コマンドリファレンス

```
rw [lint|ingest|synthesize-logs|approve|init|query|audit]
```

### 基本運用サイクル

| コマンド | 内容 |
|---------|------|
| `rw lint` | `raw/incoming/` の素材の形式チェックとメタデータ検証・自動補完 |
| `rw ingest` | lint 済み素材を `raw/incoming/` から `raw/` の各カテゴリへ移動・登録 |
| `rw synthesize-logs` | LLM が `raw/llm_logs/` を解析し、合成候補を `review/synthesis_candidates/` に生成 |
| `rw approve` | 人間が合成候補をレビューし、`wiki/synthesis/` へ昇格を承認 |

### クエリ

| コマンド | 内容 |
|---------|------|
| `rw query extract "<question>"` | raw 素材から関連エビデンスを抽出し `review/query/` に保存 |
| `rw query answer "<question>"` | エビデンスをもとに LLM が回答を生成 |
| `rw query fix <query_id>` | 既存クエリの回答を修正・更新 |
| `rw lint query [--path <query_id>]` | クエリアーティファクトの構造検証（QL コード報告） |

### 監査

| コマンド | 内容 |
|---------|------|
| `rw audit micro` | 最近更新されたページを対象とした静的チェック |
| `rw audit weekly` | 全ページを対象とした構造チェック |
| `rw audit monthly` | Claude CLI を使用した意味的監査 |
| `rw audit quarterly` | Claude CLI を使用した戦略的監査 |

> **注意**: `wiki/` への書き込みは `approve` ステップでの人間承認後のみ実施されます。LLM は直接 `wiki/` を変更しません。

## 開発リポジトリのディレクトリ構成

```
Rwiki-dev/                     # 開発リポジトリルート
├── scripts/
│   └── rw_cli.py              # メイン CLI スクリプト（全コマンドの実体）
├── templates/
│   ├── CLAUDE.md              # Wiki 運用カーネル（init 時に Vault へコピー）
│   ├── .gitignore             # Vault 用 .gitignore テンプレート
│   └── AGENTS/                # AI タスク別プロンプトテンプレート（init 時にコピー）
├── tests/
│   ├── conftest.py            # 共通フィクスチャ（vault_path, patch_constants 等）
│   ├── test_rw_cli.py         # query/audit/Prompt Engine テスト（450+件）
│   ├── test_utils.py          # ユーティリティ関数テスト
│   ├── test_git_ops.py        # Git 操作関数テスト
│   ├── test_lint.py           # cmd_lint テスト
│   ├── test_ingest.py         # cmd_ingest テスト
│   ├── test_synthesize_logs.py# cmd_synthesize_logs テスト
│   ├── test_approve.py        # cmd_approve テスト
│   ├── test_lint_query.py     # cmd_lint_query テスト
│   └── test_init.py           # cmd_init テスト
├── docs/
│   ├── user-guide.md          # ユーザー操作ガイド
│   ├── developer-guide.md     # 開発者向けガイド（テスト実行・アーキテクチャ）
│   ├── audit.md               # 監査コマンド詳細仕様
│   └── Rwiki仕様案.md         # 詳細仕様ドキュメント
├── README.md                  # このファイル
└── CHANGELOG.md               # 変更履歴（Keep a Changelog 形式）
```

## テスト実行

```bash
# 全テスト実行
pytest tests/

# 新規テストのみ（既存の大規模テストを除く）
pytest tests/ --ignore=tests/test_rw_cli.py

# 個別ファイル
pytest tests/test_utils.py -v
```

詳細は `docs/developer-guide.md` を参照してください。

## Severity / Status / Exit Code

| 概念 | 値 |
|------|-----|
| **Severity** | `CRITICAL` / `ERROR` / `WARN` / `INFO`（4 水準） |
| **Status** | `PASS` / `FAIL`（2 値、WARN は FAIL に影響しない） |
| **Exit Code** | `0`=PASS / `1`=runtime error または precondition failure / `2`=FAIL 検出 |

詳細は [`docs/developer-guide.md §Severity Vocabulary`](docs/developer-guide.md) および [`§Migration Notes`](docs/developer-guide.md) を参照してください。
