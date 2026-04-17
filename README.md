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

### 手順

```bash
# 1. このリポジトリをクローン
git clone <repo-url> ~/Rwiki-dev
cd ~/Rwiki-dev

# 2. 新しい Vault を作成する（パスを指定）
python scripts/rw_light.py init ~/my-vault

# または、カレントディレクトリを Vault として初期化
mkdir ~/my-vault && cd ~/my-vault
python /path/to/Rwiki-dev/scripts/rw_light.py init
```

`rw init` は以下を自動生成します。

| 項目 | 内容 |
|------|------|
| ディレクトリ構造 | `raw/`, `review/`, `wiki/`, `logs/`, `scripts/`, `AGENTS/` など |
| `CLAUDE.md` | Wiki 運用ルールカーネル（`templates/CLAUDE.md` からコピー） |
| `.gitignore` | `raw/incoming/` および `.obsidian/workspace*` を除外 |
| `index.md` | インデックスファイルの初期版 |
| `log.md` | 操作ログファイルの初期版 |
| `scripts/rw` | `rw_light.py` へのシンボリックリンク |
| Git リポジトリ | `git init` による Vault の初期化 |

セットアップ完了後、Vault ディレクトリ内で `./scripts/rw <command>` を使って各コマンドを実行できます。

## 基本的な運用サイクル

Rwiki の日常的な運用は以下の 5 ステップで構成されます。

```
ingest → lint → synthesize → approve → audit
```

| ステップ | コマンド | 内容 |
|---------|---------|------|
| **ingest** | `./scripts/rw ingest` | `raw/incoming/` に置かれた素材を `raw/` の各カテゴリへ移動・登録 |
| **lint** | `./scripts/rw lint` | raw 素材の形式チェックとメタデータ検証 |
| **synthesize** | `./scripts/rw synthesize` | LLM が raw/review 素材をもとに wiki 合成候補を `review/synthesis_candidates/` に生成 |
| **approve** | `./scripts/rw approve` | 人間が合成候補をレビューし、`wiki/` へ昇格を承認 |
| **audit** | `./scripts/rw audit` | wiki の整合性確認（index.md/log.md との整合、承認記録の検証） |

> **注意**: `wiki/` への書き込みは `approve` ステップでの人間承認後のみ実施されます。LLM は直接 `wiki/` を変更しません。

## 開発リポジトリのディレクトリ構成

```
Rwiki-dev/                     # 開発リポジトリルート
├── scripts/
│   └── rw_light.py            # メイン CLI スクリプト（rw コマンドの実体）
├── templates/
│   ├── CLAUDE.md              # Wiki 運用カーネル（init 時に Vault へコピー）
│   └── .gitignore             # Vault 用 .gitignore テンプレート
├── docs/
│   ├── CLAUDE.md              # CLAUDE.md ドラフト・仕様案
│   └── Rwiki仕様案.md         # 詳細仕様ドキュメント
├── README.md                  # このファイル
└── CHANGELOG.md               # 変更履歴（Keep a Changelog 形式）
```

### 各ディレクトリの役割

- **`scripts/`**: Rwiki CLI の実装。`rw_light.py` に全サブコマンド（init, ingest, lint, synthesize, approve, audit）が含まれます。
- **`templates/`**: Vault 初期化時に配置されるテンプレートファイル群。`CLAUDE.md` は Wiki 運用ルールのカーネルとして Vault 直下に配置されます。
- **`docs/`**: 設計ドキュメント、仕様案、および CLAUDE.md の開発版ドラフトを管理します。
