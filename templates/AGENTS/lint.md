# AGENTS/lint.md

## Purpose

`raw/incoming/` 配下のファイルを検証・正規化し、ingestの前提条件を確立する。

---

## Execution Mode

**CLI** — `rw lint` コマンドで実行。
エージェントファイルの直接ロードは不要。実行宣言はコマンド呼び出し自体が代替する。

---

## Prerequisites

- `raw/incoming/` ディレクトリが存在すること

---

## Input

- Source: `raw/incoming/**/*.md`
- スコープ: `raw/incoming/` 配下のみ

---

## Output

- `logs/lint_latest.json`（全ファイルの検証結果を含む）
- 終了コード:
  - `0` → FAIL が存在しない
  - `1` → FAIL が1件以上存在する

### lint_latest.json スキーマ

```json
{
  "timestamp": "ISO 8601",
  "files": [
    {
      "path": "raw/incoming/...",
      "status": "PASS | WARN | FAIL",
      "warnings": [],
      "errors": [],
      "fixes": []
    }
  ],
  "summary": { "pass": 0, "warn": 0, "fail": 0 }
}
```

---

## Processing Rules

### 判定レベル

**PASS**
- 有効な構造を持つ（マークダウン + パース可能なYAML frontmatter + 必須フィールド確認済み）
- 内容が80文字以上（正規化後）

**WARN**
- 内容が80文字未満（too short）
- 任意メタデータの欠如など軽微な問題

**FAIL**
- ファイルが空
- 必須フィールドが判定不能（値が推測できない場合）
- 安全に正規化できない構造

### 必須フィールド（frontmatter）

- `title`
- `source`
- `added`

### Auto Fix（自動修正）

FAIL にしない範囲で自動修正を適用する:

- frontmatterが存在しない場合は追加する
- 欠落フィールドが推測可能な場合は補完する
- フォーマットを正規化する

**制約**:
- セマンティックな内容を変更しない
- 不明なメタデータを創作しない
- 値が確定できない場合は空欄のままにするか FAIL にする

### 決定論性

lintは決定論的かつスクリプト駆動でなければならない。
同一入力に対して異なる結果を返してはならない。

---

## Prohibited Actions

- `raw/incoming/` 外のファイルへの書き込み
- `raw/incoming/` のコミット
- セマンティックな内容の変更
- 不明なメタデータの創作
- `wiki/` や `review/` への書き込み

---

## Failure Conditions

即座に中止する条件:

- `raw/incoming/` ディレクトリが存在しない
- ファイルが空（該当ファイルを FAIL として記録し処理継続）

### ingest側への契約

- ingest は `summary.fail > 0` の場合に実行を中止しなければならない
- lint は ingest の前提条件であり、lint なしのingest実行は禁止される
