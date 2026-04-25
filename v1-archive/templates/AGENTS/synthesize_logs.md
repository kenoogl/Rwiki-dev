# AGENTS/synthesize_logs.md

## Purpose

コミット済みの `raw/llm_logs/` をreusableな知識候補に変換する。
LLMとのインタラクションログから高価値・汎用化可能な知識を抽出し、
構造化されたsynthesis候補として `review/synthesis_candidates/` に出力する。

---

## Execution Mode

**CLI (Hybrid)** — `rw synthesize-logs` コマンドで実行。
CLIが内部でClaude CLIを呼び出す（`claude -p <prompt>`）。
エージェントファイルの直接ロードは不要。実行宣言はコマンド呼び出し自体が代替する。

---

## Prerequisites

- `raw/llm_logs/` 配下にコミット済みのログファイルが存在すること
- 作業ツリーが `raw/llm_logs/` について clean であること（dirty な場合は警告）

---

## Input

- Source: `raw/llm_logs/**/*.md`
- コミット済みファイルのみ有効な入力
- 未コミットのログを使用してはならない

---

## Output

- 出力先: `review/synthesis_candidates/`
- ファイル種別: `synthesis_candidate`
- フォーマット: 構造化マークダウン（会話形式でないこと）

### 出力ファイル形式

```markdown
---
title: "<明確なトピック名>"
source: "<raw/llm_logs/...>"
type: "synthesis_candidate"
status: "pending"
reviewed_by: ""
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [tag1, tag2]
---

## Summary
<3〜5行の簡潔な要約>

## Decision
<最終的な決定>

## Reason
<なぜその決定か>

## Alternatives
<却下された選択肢>

## Reusable Pattern
<汎用化されたルール>
```

### CLIが使用するJSONスキーマ（Claude CLIへの出力形式）

Claude CLIには以下のJSON形式で出力させる:

```json
{
  "topics": [
    {
      "title": "string",
      "summary": "string",
      "decision": "string",
      "reason": "string",
      "alternatives": "string",
      "reusable_pattern": "string",
      "tags": ["string"]
    }
  ]
}
```

---

## Processing Rules

1. `raw/llm_logs/` 配下の全 `.md` ファイルを列挙する
2. 各ログファイルについて Claude CLI を呼び出し、再利用可能な知識を抽出する
3. Claude CLIのレスポンスをJSONとしてパースし、`topics` 配列を取得する
4. 各トピックについて、スラッグ（タイトルを正規化）から出力パスを決定する
5. 同スラッグのファイルが既に存在する場合はスキップする（上書き禁止）
6. 候補ノートを `review/synthesis_candidates/` に書き出す

### 知識抽出ルール

**除外する内容**:
- 試行錯誤のステップ
- 冗長な説明
- 文脈依存の記述
- 不正確な中間的内容（ただし却下理由として有用な場合を除く）

**含める内容のみ**:
- 明確な決定事項
- 設計パターン
- 汎用的な原則
- 再利用可能なワークフロー

### トピック分割ルール

- 再利用可能なトピックごとに分割する
- 一貫した1つの決定を細かく断片化しない
- 各ノートは意味のある自己完結した知識単位を表すこと
- ログが支持する範囲を超えて過度に汎用化しない

### 命名規則

- ファイル名はタイトルを lowercase + hyphen に正規化したスラッグ
- 例: `title: "Batch Insert Strategy"` → `batch-insert-strategy.md`

### コミットについて

CLI（`rw synthesize-logs`）は自動コミットを行わない。
生成された候補ファイルのコミットはユーザーが手動で実行する。
コミット時は `synthesize-logs: ...` メッセージを使用し、`review/synthesis_candidates/` のみを対象とする。

---

## Prohibited Actions

- `wiki/synthesis/` への直接書き込み（wiki への直行禁止）
- `raw/` への書き込み
- 未コミストのログの使用
- 既存候補ファイルの上書き
- 会話構造の保持（Q&A形式・対話形式での出力禁止）
- ログが支持しない内容の創作

---

## Failure Conditions

即座に中止する条件（単一ファイルの失敗は記録して次へ続行）:

- `raw/llm_logs/` にファイルが存在しない（全体終了）
- Claude CLI の呼び出しが失敗した（該当ログをスキップして次へ）
- Claude CLIのレスポンスが有効なJSONでない（該当ログをスキップして次へ）
- 内容が文脈依存すぎる / 明確な決定が存在しない（該当トピックを破棄）
- 既存の `review/synthesis_candidates/` または `wiki/synthesis/` と重複する（スキップ）
