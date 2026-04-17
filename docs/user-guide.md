# Rwiki ユーザーガイド

## はじめに

Rwikiは制御された知識パイプラインです。LLMが知識を直接編集するのではなく、raw → review → (human approval) → wiki というフローで知識を構築します。

---

## 基本的な運用サイクル

```
[1] lint        raw/incoming/ のバリデーション
[2] ingest      raw/incoming/ を raw/ へ移動・コミット
[3] synthesize  raw/ から review/ への知識候補生成（Prompt）
[4] approve     review/ の承認済み候補を wiki/ へ昇格（CLI）
[5] audit       wiki/ の整合性・一貫性を検証（Prompt）
```

### ステップ詳細

**ステップ1: lint**

```bash
rw lint
```

`raw/incoming/` 配下のファイルを検証し `logs/lint_latest.json` を生成する。
FAIL が存在する場合は ingest を実行しない。

**ステップ2: ingest**

```bash
rw ingest
```

lint が FAIL == 0 の場合のみ実行可能。
`raw/incoming/` のファイルを `raw/` へ移動し、`ingest: batch import` でコミットする。

**ステップ3: synthesize（Prompt）**

Claude CLIで synthesize エージェントをロードして実行する:

```bash
claude
```

実行時の宣言:
```
Task Type: synthesize
Loaded Agents: synthesize.md, page_policy.md, naming.md
Execution Plan: raw/papers/sindy-tutorial.md を review/synthesis_candidates/ に変換する
```

出力先は `review/synthesis_candidates/` のみ。`wiki/` には直接書かない。

**ステップ4: approve**

`review/synthesis_candidates/` の候補ファイルを人間がレビューし、frontmatterを更新する:

```yaml
status: approved
reviewed_by: alice
approved: 2026-04-17
```

承認後に実行:

```bash
rw approve
```

`wiki/synthesis/` に昇格される。完了後、コミットを手動で実行:

```bash
git add review/synthesis_candidates/
git commit -m "approve: update promoted flag"

git add wiki/synthesis/ wiki/index.md wiki/log.md
git commit -m "approve: promote synthesis"
```

**ステップ5: audit（Prompt）**

Claude CLIで audit エージェントをロードして実行する。

実行宣言:
```
Task Type: audit
Loaded Agents: audit.md, page_policy.md, naming.md, git_ops.md
Execution Plan: Tier 1 Structural Audit を wiki/ 全体に対して実行する
```

audit はレポートのみ。ファイルを変更しない。

---

## CLIコマンドリファレンス

### `rw init`

新しいVaultを初期化する。`templates/` の構成を新しいVaultディレクトリにコピーする。

```bash
rw init <vault-path>
```

**引数**: `vault-path` — 初期化先のディレクトリパス

**出力**: ディレクトリ構造・CLAUDE.md・AGENTS/ディレクトリが配置される

---

### `rw lint`

`raw/incoming/` のファイルを検証する。

```bash
rw lint
```

**引数**: なし

**出力**:
- `logs/lint_latest.json`（全ファイルの検証結果）
- 標準出力に各ファイルの判定（PASS / WARN / FAIL）
- 終了コード: 0（FAIL なし）/ 1（FAIL あり）

**例**:
```
[PASS] raw/incoming/articles/sindy-intro.md
[WARN] raw/incoming/papers/local/draft.md too short
[FAIL] raw/incoming/code-snippets/empty.md empty file

Summary: {'pass': 1, 'warn': 1, 'fail': 1}
Log: logs/lint_latest.json
```

---

### `rw lint query`

`review/query/` 配下のクエリアーティファクトを検証する。

```bash
rw lint query [query_id]
```

**引数**: `query_id`（省略時は全クエリを対象）

**出力**: 各クエリの検証結果（QLコードと詳細）

---

### `rw ingest`

lint済みファイルを `raw/incoming/` から `raw/` へ移動する。

```bash
rw ingest
```

**前提条件**: `rw lint` が実行済みで FAIL == 0 であること

**出力**:
- 各ファイルの移動状況
- 完了後に自動コミット（`ingest: batch import`）

---

### `rw synthesize-logs`

`raw/llm_logs/` のLLMインタラクションログからsynthesis候補を生成する。

```bash
rw synthesize-logs
```

**前提条件**: `raw/llm_logs/` にコミット済みのログファイルが存在すること

**出力**: `review/synthesis_candidates/` にsynthesis候補ファイルを生成

**注**: CLIは自動コミットしない。完了後に手動でコミットすること:
```bash
git add review/synthesis_candidates/
git commit -m "synthesize-logs: generate candidates"
```

---

### `rw approve`

承認済みの synthesis 候補を `wiki/synthesis/` へ昇格させる。

```bash
rw approve
```

**前提条件**: `review/synthesis_candidates/` に以下の全フィールドを持つファイルが存在すること:
- `status: approved`
- `reviewed_by: <非空の文字列>`
- `approved: YYYY-MM-DD`
- `promoted` が `"true"` でない

**出力**:
- `wiki/synthesis/` への昇格（新規作成またはマージ）
- 候補ファイルの `promoted: true` フラグ更新

**注**: CLIは自動コミットしない。完了後に以下の順序でコミットすること:
```bash
git add review/synthesis_candidates/
git commit -m "approve: update promoted flag"

git add wiki/synthesis/ wiki/index.md wiki/log.md
git commit -m "approve: promote synthesis"
```

---

## プロンプトレベルタスクの実行

### Claude CLIでのエージェントロード手順

1. Claude CLIを起動する
2. 実行宣言を行う（Task Type / Loaded Agents / Execution Plan）
3. 必要なエージェントファイルをReadツールでロードする
4. エージェントルールに従って実行する

### synthesize タスク

```
Task Type: synthesize
Loaded Agents: synthesize.md, page_policy.md, naming.md
Execution Plan: [対象ファイル] を review/synthesis_candidates/ に変換する
```

ロード:
```
Read("AGENTS/synthesize.md")
Read("AGENTS/page_policy.md")
Read("AGENTS/naming.md")
```

### query_extract タスク

```
Task Type: query_extract
Loaded Agents: query_extract.md, naming.md, page_policy.md
Execution Plan: query_id: 20260417-sindy-dimensionality でクエリアーティファクトを生成する
```

出力先: `review/query/<query_id>/` 配下の4ファイル（query.md / answer.md / evidence.md / metadata.json）

### query_answer タスク

```
Task Type: query_answer
Loaded Agents: query_answer.md, page_policy.md
Execution Plan: [質問内容]
```

wiki知識に基づいた直接回答を返す。アーティファクトは生成しない。

### query_fix タスク

```
Task Type: query_fix
Loaded Agents: query_fix.md, naming.md
Execution Plan: query_id: 20260417-sindy-dimensionality の lint エラーを修復する
```

lint結果（QLコード）を提供した上で実行する。

### audit タスク

```
Task Type: audit
Loaded Agents: audit.md, page_policy.md, naming.md, git_ops.md
Execution Plan: Tier 1 Structural Audit / Tier 0 Micro-check（直近のingest後）
```

---

## 既存VaultのAGENTS更新手順

新しいバージョンの `templates/AGENTS/` をVaultに適用する場合:

```bash
rw init <vault-path>
```

`rw init` は `templates/AGENTS/` の内容をVaultの `AGENTS/` ディレクトリに再配置する。

> **注意**: 既存のVault固有のカスタマイズがある場合は、`rw init` の前にバックアップを取ること。

---

## 知識フロー図

```
raw/incoming/          (未検証入力)
    ↓ rw lint
    ↓ rw ingest
raw/                   (検証済みソース・READ ONLY)
    ↓ synthesize (Prompt)
    ↓ synthesize-logs (CLI)
review/                (レビュー・ステージング層)
    ↓ [human review & approval]
    ↓ rw approve (CLI)
wiki/                  (キュレーション済み知識層)
```
