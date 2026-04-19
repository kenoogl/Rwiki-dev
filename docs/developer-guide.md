# 開発者ガイド

Rwiki テストスイートの実行方法、ファイル構成、拡張手順、モック戦略、アーキテクチャ概要をまとめたリファレンスです。

---

## 1. テスト実行方法

### 基本コマンド

```bash
# 全テスト実行（既存 + 新規）
pytest tests/

# 新規テストのみ実行（既存 test_rw_light.py を除外）
pytest tests/ --ignore=tests/test_rw_light.py

# 個別ファイルを詳細表示で実行
pytest tests/test_utils.py -v
```

### よく使うフラグ

| フラグ | 説明 | 使用例 |
|--------|------|--------|
| `-x` | 最初の失敗で即時停止 | `pytest tests/ -x` |
| `-k` | テスト名でフィルタ | `pytest tests/ -k "test_slugify"` |
| `-v` | 詳細出力（テスト名を 1 行ずつ表示） | `pytest tests/test_utils.py -v` |
| `--tb=short` | トレースバックを短縮表示 | `pytest tests/ --tb=short` |

使用例:

```bash
# slugify 関連テストだけを実行
pytest tests/ -k "slugify" -v

# git_ops の最初の失敗で停止
pytest tests/test_git_ops.py -x
```

---

## 2. テストファイル構成

### ファイル一覧と責務分担

| ファイル | 区分 | 主な責務 |
|----------|------|----------|
| `tests/test_rw_light.py` | 既存 | query・audit コマンド全般、Prompt Engine |
| `tests/conftest.py` | 新規（共通） | 全新規テスト共通フィクスチャ（autouse=False） |
| `tests/test_utils.py` | 新規 | ユーティリティ関数（parse_frontmatter、slugify、ensure_basic_frontmatter 等 11 関数） |
| `tests/test_git_ops.py` | 新規 | Git 操作（git_commit、git_status_porcelain、git_path_is_dirty） |
| `tests/test_lint.py` | 新規 | `rw lint` コマンド |
| `tests/test_ingest.py` | 新規 | `rw ingest` コマンド |
| `tests/test_synthesize_logs.py` | 新規 | `rw synthesize-logs` コマンド |
| `tests/test_approve.py` | 新規 | `rw approve` コマンド |
| `tests/test_lint_query.py` | 新規 | `rw lint-query` コマンド |
| `tests/test_init.py` | 新規 | `rw init` コマンド |

### conftest.py の位置づけ

`tests/conftest.py` は**新規テスト専用**の共通フィクスチャを提供します。

- すべてのフィクスチャは `autouse=False`（明示的に引数に指定した場合のみ適用）
- `sys.path` への `scripts/` 追加を担うため、新規テストファイルでは個別の `sys.path.insert` は不要
- 既存の `test_rw_light.py` は独自の setup を持つため、conftest.py の影響を受けない

---

## 3. テスト追加手順

新規テストを追加するときの標準手順です。

### 1. テストファイルの配置

新規テストファイルは `tests/test_<対象>.py` に配置します:

```
tests/
  test_my_feature.py   # 新規ファイル
```

### 2. インポート

`conftest.py` が `sys.path` を設定済みのため、次の 1 行だけで rw_light を利用できます:

```python
import rw_light
```

`unittest.mock` は使用せず、pytest の `monkeypatch` で統一します（詳細は「4. モック戦略」参照）。

### 3. クラスとメソッドの命名規約

| 対象 | 規約 | 例 |
|------|------|----|
| ユーティリティ関数 | `Test<関数名>` | `TestSlugify` |
| CLI コマンドハンドラ | `TestCmd<コマンド名>` | `TestCmdLint` |
| テストメソッド | `test_<シナリオ>` | `test_empty_string_returns_untitled` |

### 4. フィクスチャの使用

フィクスチャはテストメソッドの引数に指定するだけで利用できます:

```python
class TestCmdLint:
  def test_no_files(self, patch_constants, monkeypatch):
    # patch_constants: 17 定数を tmp_path ベースに差し替え済み
    result = rw_light.cmd_lint([])
    assert result == 0
```

主なフィクスチャ:

| フィクスチャ | 説明 |
|-------------|------|
| `vault_path` | VAULT_DIRS を tmp_path 上に生成した Path を返す |
| `patch_constants` | rw_light の 17 グローバル定数を vault_path ベースに差し替える |
| `fixed_today` | `rw_light.today` を `'2025-01-15'` に固定する |
| `make_md_file` | フロントマター付き MD ファイルを生成するファクトリ |
| `lint_json` | `lint_latest.json` を生成するファクトリ |
| `query_artifacts` | クエリアーティファクトセット（4 ファイル）を生成するファクトリ |
| `mock_templates` | `templates/` モックと `DEV_ROOT` パッチを提供（`test_init.py` 専用） |

### 5. インデント規則

**2 スペースインデント必須**（プロジェクト全体の規約に準拠）:

```python
class TestSlugify:
  def test_basic(self):
    assert rw_light.slugify("Hello World") == "hello-world"

  def test_unicode_stripped(self):
    assert rw_light.slugify("日本語") == "untitled"
```

---

## 4. モック戦略

### 基本方針

**`monkeypatch.setattr` のみ使用、`unittest.mock` は不使用。**

理由: 既存の `test_rw_light.py` が `monkeypatch` を全面採用しており、新規テストも同一スタイルに統一することでコードベースの一貫性を保ちます。

### モジュール定数のパッチ

rw_light のグローバル定数はモジュールインポート時に `os.getcwd()` を基準に評価されます。テスト時は `patch_constants` フィクスチャで 17 定数を一括差し替えます:

```python
def test_example(self, patch_constants, monkeypatch):
  # patch_constants 適用後、rw_light.ROOT は tmp_path を指す
  # コマンドハンドラ内で定数を参照するコードが tmp_path 上で動作する
  assert rw_light.cmd_lint([]) == 0
```

差し替え対象の 17 定数:
`ROOT`, `RAW`, `INCOMING`, `LLM_LOGS`, `REVIEW`, `SYNTH_CANDIDATES`,
`QUERY_REVIEW`, `WIKI`, `WIKI_SYNTH`, `LOGDIR`, `LINT_LOG`,
`QUERY_LINT_LOG`, `INDEX_MD`, `CHANGE_LOG_MD`, `CLAUDE_MD`,
`AGENTS_DIR`, `DEV_ROOT`

### subprocess.run のモック

subprocess 呼び出しを記録するリストパターンを使います:

```python
def test_git_commit(self, patch_constants, monkeypatch):
  calls = []

  def fake_run(cmd, **kwargs):
    calls.append(cmd)
    import subprocess
    return subprocess.CompletedProcess(cmd, 0, stdout="", stderr="")

  monkeypatch.setattr(rw_light.subprocess, "run", fake_run)

  rw_light.git_commit("/path/to/vault", "test commit")
  assert any("git" in str(c) for c in calls)
```

### LLM 呼び出しのモック

| コマンド | モック対象関数 |
|----------|---------------|
| `rw query` | `rw_light.call_claude` |
| `rw audit monthly/quarterly` | `rw_light.call_claude` |
| `rw synthesize-logs` | `rw_light.call_claude_for_log_synthesis` |

モック例:

```python
def test_synthesize_logs_calls_llm(self, patch_constants, monkeypatch):
  calls = []

  def fake_llm(prompt, model=None):
    calls.append(prompt)
    return "# Synthesis\nTest output."

  monkeypatch.setattr(rw_light, "call_claude_for_log_synthesis", fake_llm)
  rw_light.cmd_synthesize_logs([])
  assert len(calls) == 1
```

---

## 5. アーキテクチャ概要

### 3 層パイプライン

Rwiki は raw → review → wiki の 3 層パイプラインで知識を管理します:

```
raw/incoming/   ──ingest──▶  raw/           ──synthesize──▶  review/synthesis_candidates/
                                                                        │
                                                                     approve
                                                                        ▼
                                                                  wiki/synthesis/
```

| 層 | ディレクトリ | 役割 |
|----|-------------|------|
| raw | `raw/incoming/`, `raw/`, `raw/llm_logs/` | 生データ・LLM ログの受け取りと保管 |
| review | `review/synthesis_candidates/`, `review/query/` | 人間レビュー待ちの候補を一時保管 |
| wiki | `wiki/concepts/`, `wiki/synthesis/` 等 | 承認済み知識の永続保管 |

### コマンドハンドラ構造

```
argparse エントリポイント (main)
  └── cmd_<command>(args)         # コマンドハンドラ
        ├── ensure_dirs()          # 必要ディレクトリを保証
        ├── ユーティリティ関数      # parse_frontmatter, slugify 等
        └── (必要に応じて) call_claude / subprocess.run
```

各コマンドハンドラは独立した関数として実装されており、テストから直接呼び出せます。
エントリポイント（`main()`）は `argparse` でサブコマンドを振り分けるだけのシンルーターです。

### Prompt Engine の呼び出しチェーン

```
parse_agent_mapping(CLAUDE.md)
  └── load_task_prompts(task_type, AGENTS/)
        └── call_claude(prompt, model)
```

1. `parse_agent_mapping`: `CLAUDE.md` から `タスク → AGENTS/ ファイル名` のマッピングを読み込む
2. `load_task_prompts`: AGENTS/ ディレクトリからプロンプトファイルを連結して読み込む
3. `call_claude`: 組み立てたプロンプトを Claude CLI (`claude` コマンド) 経由で実行する

### テスト観点からの注意点

**モジュール定数のインポート時評価**
`ROOT = os.getcwd()` 等の定数はモジュールインポート時に評価されます。
テスト内で直接 `rw_light.ROOT = "..."` と書いても、ハンドラ内の参照には反映されないケースがあるため、必ず `monkeypatch.setattr(rw_light, "ROOT", ...)` を使用します（`patch_constants` フィクスチャが一括で処理）。

**ensure_dirs の動作**
多くのコマンドハンドラは冒頭で `ensure_dirs()` を呼び出します。
`patch_constants` 適用後は `LOGDIR` 等が tmp_path を指すため、実ファイルシステムへの書き込みは発生しません。

**mock_templates と patch_constants の排他制約**
`mock_templates` と `patch_constants` は同一テストで併用しないでください。
両フィクスチャが `rw_light.DEV_ROOT` をパッチするため、後から適用された方が勝ち、挙動が不定になります。
`test_init.py` は `mock_templates` のみ、それ以外は `patch_constants` のみを使用する設計です。
