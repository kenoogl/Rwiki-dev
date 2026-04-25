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
  - `0` → PASS（ERROR / CRITICAL なし）
  - `1` → ランタイムエラー / 前提条件不成立
  - `2` → FAIL（ERROR または CRITICAL が 1 件以上）

### lint_latest.json スキーマ

```json
{
  "timestamp": "ISO 8601",
  "status": "PASS | FAIL",
  "files": [
    {
      "path": "raw/incoming/...",
      "status": "PASS | FAIL",
      "checks": [
        { "severity": "CRITICAL | ERROR | WARN | INFO", "message": "説明" }
      ]
    }
  ],
  "summary": {
    "pass": 0,
    "fail": 0,
    "severity_counts": { "critical": 0, "error": 0, "warn": 0, "info": 0 }
  },
  "drift_events": []
}
```

---

## Processing Rules

### 判定レベル

#### status（2 値）

**PASS**: ERROR も CRITICAL も検出されなかった。
**FAIL**: ERROR または CRITICAL が 1 件以上検出された。

#### severity（各チェック項目の重要度、4 水準）

**ERROR**（FAIL を引き起こす）
- ファイルが空
- 必須フィールドが判定不能（値が推測できない場合）
- 安全に正規化できない構造

**WARN**（FAIL を引き起こさない）
- 内容が80文字未満（too short）
- 任意メタデータの欠如など軽微な問題

**INFO**
- 情報のみ（自動修正が適用された通知など）

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
