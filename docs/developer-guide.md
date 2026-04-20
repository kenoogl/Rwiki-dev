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

---

## 6. Severity Vocabulary

Rwiki の CLI コマンドは **4 水準** の severity を使用します。

| Severity | 定義 | 使用例 |
|----------|------|--------|
| `CRITICAL` | Vault の整合性を即座に損なう重大欠陥 | `metadata.json` が invalid JSON（QL017） |
| `ERROR` | 修正必須の欠落・違反 | 必須ファイル欠落（QL001）、フロントマター欠落（lint） |
| `WARN` | 推奨違反・品質低下（修正推奨、FAIL 判定には寄与しない） | 本文が短すぎる（lint）、`created_at` 欠落（QL005） |
| `INFO` | 参考情報（自動補完や情報提供） | フロントマター自動補完通知 |

### 2 値 status

| Status | 条件 |
|--------|------|
| `PASS` | CRITICAL・ERROR が 0 件（WARN / INFO は許容） |
| `FAIL` | CRITICAL または ERROR が 1 件以上 |

`PASS_WITH_WARNINGS` は廃止済みです。WARN は `summary.severity_counts.warn` に件数が記録されますが、status に影響しません。

---

## 7. Exit Code Semantics

| Exit Code | 意味 | 典型事例 |
|-----------|------|---------|
| `0` | PASS（正常完了） | lint 全件 PASS、audit 問題なし |
| `1` | Runtime error / Precondition failure | 引数エラー、ファイル未存在、上流 lint FAIL による ingest 中断 |
| `2` | FAIL 検出（コンテンツ品質問題） | lint ERROR 検出、audit CRITICAL/ERROR 検出、query lint FAIL |

### 3 値契約が適用されるコマンド

`rw lint` / `rw audit <tier>` / `rw lint query` — exit 0/1/2 の 3 値

### 2 値契約のコマンド（exit 0/1 のみ）

`rw init` / `rw ingest` / `rw synthesize-logs` / `rw approve` / `rw query answer`

> `rw ingest` は**上流 lint の FAIL を検知して exit 1** を返します（exit 2 ではありません）。
> これは ingest 自体は FAIL 検出コマンドではなく、上流 FAIL を precondition failure として扱うためです。

---

## 8. Migration Notes

### Before / After 対応表

<!-- severity-vocab: legacy-reference -->
| 変更点 | 旧値 | 新値 |
|--------|------|------|
| AGENTS severity（table cell） | `HIGH` / `MEDIUM` / `LOW` | `ERROR` / `WARN` / `INFO` |
| status vocabulary | `PASS_WITH_WARNINGS` / `WARN`（status 位置） | `PASS` / `FAIL` のみ |
| exit code: rw lint FAIL | `exit 1` | `exit 2` |
| exit code: rw audit FAIL | `exit 1` | `exit 2` |
| exit code: rw lint query 引数エラー | `exit 3` | `exit 1` |
| exit code: rw lint query path 未存在 | `exit 4` | `exit 1` |
| `logs/*_latest.json` per-file severity 配列 | `errors[]` / `warnings[]` / `infos[]` | `checks[]` 単一配列 |
| `logs/lint_latest.json` summary | `summary.warn` キー | `summary.severity_counts.warn` |
<!-- /severity-vocab -->

### Shell script migration recipe

```bash
# 旧スクリプト（FAIL を exit 1 として扱う）
<!-- severity-vocab: legacy-reference -->
rw lint
if [ $? -eq 1 ]; then echo "lint failed"; fi
<!-- /severity-vocab -->

# 新スクリプト（exit 0/1/2 の 3 値分岐）
rw lint
case $? in
  0) echo "PASS" ;;
  1) echo "runtime error / precondition failure" ;;
  2) echo "FAIL: content quality issues" ;;
esac
```

### JSON consumer migration

```python
# 旧: errors[] / warnings[] を直接参照
<!-- severity-vocab: legacy-reference -->
errors = lint_result["errors"]  # 廃止
warnings = lint_result["warnings"]  # 廃止
<!-- /severity-vocab -->

# 新: checks[] + severity でフィルタ
checks = lint_result["checks"]
errors = [c for c in checks if c["severity"] in {"CRITICAL", "ERROR"}]
warnings = [c for c in checks if c["severity"] == "WARN"]

# top-level status で PASS/FAIL を判定
if lint_result["status"] == "FAIL":
    ...

# summary.severity_counts で件数取得
sc = lint_result["summary"]["severity_counts"]
print(f"ERROR: {sc['error']}, WARN: {sc['warn']}")
```

> **注意**: `schema_version` フィールドは追加されません。`drift_events[]` / `summary.severity_counts` / top-level `status` の existence-based 検出で新 schema を識別してください。

---

## 9. Vault Redeployment Procedure

<!-- severity-vocab: legacy-reference -->
既存 Vault の `AGENTS/audit.md` が旧語彙（`HIGH` / `MEDIUM` / `LOW`）を含む場合、`rw audit` は `SystemExit(1)` で中断します。
<!-- /severity-vocab -->

### 手順

```bash
# 1. Vault AGENTS を新 template で上書き（旧版は .backup/<timestamp>/ に退避）
rw init --force <vault-path>

# 2. 更新後に audit が通ることを確認
rw audit weekly --skip-vault-validation

# 3. 問題なければ通常実行
rw audit weekly
```

### `--skip-vault-validation` escape hatch

正規表現の false positive などで誤検出が発生した場合の緊急回避です。
**通常運用では使用しないでください。**

```bash
rw audit weekly --skip-vault-validation
# stderr: [vault-validation] SKIPPED (--skip-vault-validation or RW_SKIP_VAULT_VALIDATION=1 set)
```

環境変数でも設定可能: `RW_SKIP_VAULT_VALIDATION=1 rw audit weekly`

### rollback 時の注意

- `.backup/` が symlink の場合、`rw init --force` は `SystemExit(1)` で中断します（symlink 先への意図しない書き込み防止）
- 同一秒内に 2 回 `--force` を実行した場合、`<timestamp>-<pid>` フォールバック名でバックアップを作成します

---

## 10. Glossary

| 用語 | 定義 |
|------|------|
| **severity** | 問題の重大度。`CRITICAL` / `ERROR` / `WARN` / `INFO` の 4 水準 |
| **status** | コマンド実行の合否。`PASS` / `FAIL` の 2 値（WARN は影響しない） |
| **exit code** | プロセス終了コード。0=PASS / 1=runtime error または precondition failure / 2=FAIL 検出 |
| **drift** | AGENTS template が新語彙に対応しているが、Claude が<!-- severity-vocab: legacy-reference -->旧語彙（HIGH 等）<!-- /severity-vocab -->を応答した場合の乖離 |
| **drift_events** | drift 発生を記録するリスト。各 JSON ログの `drift_events[]` フィールドに格納される |
| **vault** | Rwiki が管理するディレクトリ一式（raw/ / review/ / wiki/ / AGENTS/ 等を含む） |
| **Vault validation** | `rw audit` 実行前に AGENTS ファイルの語彙が新体系に準拠しているかを確認する工程 |
| **precondition failure** | コマンド実行の前提条件が満たされない状態（上流 lint FAIL など）。exit 1 を返す |
| **identity mapping** | severity token が正規 4 水準に完全一致し、変換不要であること（例: `ERROR` → `ERROR`） |
| **escape hatch** | `--skip-vault-validation` のように、通常検証をバイパスする緊急回避機能 |

---

## 11. Debugging FAIL (exit 2)

`rw lint` / `rw audit` / `rw lint query` が exit 2 を返した場合の診断手順:

### 手順 1: `summary.severity_counts` を確認

```bash
cat logs/lint_latest.json | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['summary']['severity_counts'])"
# {'critical': 0, 'error': 2, 'warn': 1, 'info': 0}
```

### 手順 2: `files[]` または `results[]` で対象ファイルを特定

```bash
cat logs/lint_latest.json | python3 -c "
import sys,json
d=json.load(sys.stdin)
for f in d['files']:
    if f['status'] == 'FAIL':
        print(f['path'], f['status'])
"
```

### 手順 3: `checks[]` で具体的な問題を確認

```bash
cat logs/lint_latest.json | python3 -c "
import sys,json
d=json.load(sys.stdin)
for f in d['files']:
    for c in f.get('checks', []):
        if c['severity'] in ('CRITICAL', 'ERROR'):
            print(c['id'], c['message'])
"
```

### 手順 4: `drift_events[]` で severity drift を確認

```bash
cat logs/lint_latest.json | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('drift_events', []))"
```

drift が発生している場合は stderr に `[severity-drift]` 警告が出力されています。

### 手順 5: 修正後に exit 0 を確認

```bash
rw lint && echo "exit 0: PASS"
```

---

## 12. Acceptance Smoke Test

以下の 7 ケースで severity-unification の動作を手動確認してください。

| # | コマンド | 前提 | 期待 exit code | 期待 stdout 抜粋 |
|---|---------|------|----------------|-----------------|
| 1 | `rw audit weekly` | PASS Vault（新語彙） | 0 | `audit weekly: CRITICAL 0, ERROR 0, ... — PASS` |
| 2 | `rw audit weekly` | FAIL Vault（ERROR finding あり） | 2 | `audit weekly: ... ERROR N ... — FAIL`、audit markdown に `- CRITICAL: N` 行 |
| 3 | `rw audit weekly` | <!-- severity-vocab: legacy-reference -->deprecated Vault（HIGH/MEDIUM/LOW 含む）<!-- /severity-vocab --> | 1 | stderr に `[agents-vocab-error] deprecated severity vocabulary detected` |
| 4 | `rw audit weekly --skip-vault-validation` | deprecated Vault | 0 or 2 | stderr に `[vault-validation] SKIPPED`、drift 検出時 `[severity-drift]` |
| 5 | `rw lint`（PASS）/ `rw lint`（FAIL）/ `rw lint`（引数エラー） | 正常 / 空ファイル / 引数なし | 0 / 2 / 1 | `lint: CRITICAL N, ERROR N, WARN N, INFO N — PASS/FAIL` |
| 6 | `rw ingest`（上流 lint に FAIL あり） | lint_latest.json status=FAIL | **1**（exit 2 でないこと） | stderr に `FAIL exists in lint_latest.json. abort ingest.` |
| 7 | `rw query extract "question"`（artifact 生成後 lint FAIL） | FAIL Vault | 2 | `[WARN] lint 検証失敗`、artifact ディレクトリが存在する |

---

## 13. Reverse Dependency Inventory

`rw lint` / `rw audit` / `rw lint query` の exit code が `exit 1`（FAIL）から `exit 2`（FAIL）に変更されたため、以下の逆依存スキャンを P2 commit 前に実施しました。

### スキャン実行日

2026-04-20

### スキャン結果

| スキャン対象 | コマンド | Hits | 対応 |
|-------------|---------|------|------|
| `.git/hooks/` | `grep -rn "exit\s*1\|return 1" .git/hooks/` | 0 | — |
| `.pre-commit-config.yaml` | `ls .pre-commit-config.yaml` | 存在しない | — |
| `Makefile` | `ls Makefile` | 存在しない | — |
| `.github/workflows/` | `ls .github/` | 存在しない | — |
| `scripts/*.sh` | `find scripts/ -name "*.sh"` | 0 | — |
| `.claude/skills/` | `grep -rn "exit code\|returncode" .claude/skills/` | 0（exit code 依存なし） | — |
| `templates/AGENTS/` | AGENTS template 内に exit code 依存なし | 0 | — |

**結果: clean（hits 0）**

### 将来の consumer 追加時の checklist

新たに `rw lint` / `rw audit` / `rw lint query` の exit code を参照するスクリプトや CI を追加する際は、以下の 3 値契約に準拠してください:

```bash
rw lint
case $? in
  0) echo "PASS" ;;
  1) echo "runtime error / precondition failure" ;;
  2) echo "FAIL: content quality issues" ;;
esac
```
