# AGENTS/query_fix.md

## Purpose

lint結果を使って既存のクエリアーティファクトを修復する。
既存コンテンツを最大限保持し、lintが報告した問題のみを最小限の編集で修正する。

---

## Execution Mode

**CLI (Hybrid)** — `rw query fix <query_id>` コマンドで実行。
CLIがエージェントルールに従い、lint実行・Claude呼び出し・アーティファクト修復を自動で行う。

実行宣言（CLIが自動で行う）:
- Task Type: query_fix
- Loaded Agents: query_fix.md, naming.md
- Execution Plan: [修復対象 query_id・lint結果]

---

## Prerequisites

- 修復対象の `review/query/<query_id>/` が存在すること
- `rw lint query` の結果（lintコード・エラー詳細）が提供されていること

---

## Input

- 修復対象: `review/query/<query_id>/` 配下の4ファイル
- lint結果: `rw lint query` の出力（QLコードと詳細）

---

## Output

- 修正後のファイル内容（`question.md`・`answer.md`・`evidence.md`・`metadata.json`）
- 変更が必要なファイルのみを修正する。問題のないファイルは変更しない

---

## Processing Rules

### ルール1: 既存コンテンツの尊重

- 有効なコンテンツは保持する
- lintが報告した問題のみ修正する
- 新たなサポートされていない主張を導入しない
- 全面書き直しは必要な場合のみ

### ルール2: ファクト–エビデンス分離の維持

- `answer.md` = 説明
- `evidence.md` = source情報付きの抜粋

混在させない。

### ルール3: Missing Evidenceを創作しない

lintがevidenceの不足を報告した場合:
- wikiで実際に見つかったevidenceのみを追加する
- 見つからない場合は回答を弱める
- 解釈は `[INFERENCE]` でマークする

fabricateしない。

### Lintコード別の修正方法

| コード | 修正内容 |
|---|---|
| QL002 | `question.md` に明示的なクエリテキストを追加 |
| QL003 | 有効な `query_type` を修正または追加 |
| QL004 | `question.md` および `metadata.json` にスコープを追加 |
| QL005 | `created_at` を追加 |
| QL006 | `answer.md` を空でない有意義な内容に拡充 |
| QL007 | answer の構造を改善（見出し・箇条書き）|
| QL008 | `evidence.md` に実際のevidence抜粋を追加 |
| QL009 | 各evidenceブロックに `source:` 行を追加 |
| QL010 | 必要に応じてevidence coverage を増加 |
| QL011 | 解釈が存在する箇所に `[INFERENCE]` マーカーを追加 |
| QL017 | `metadata.json` に必須キーを追加 |

### 最終確認

修正完了前に確認:
- 全4ファイルが存在すること
- いずれのファイルも空でないこと
- evidence に source 情報が含まれること
- 必須メタデータが存在すること
- サポートされていない解釈が `[INFERENCE]` でマークされていること

---

## Prohibited Actions

- lintが報告していない箇所の変更
- Evidenceの創作・fabrication
- `answer.md` と `evidence.md` の混在
- 4ファイルのうちいずれかの削除
- `wiki/` への書き込み
- 他のエージェントファイルへの直接参照（`.md` リンク）

---

## Failure Conditions

即座に中止する条件:

- 修復対象の `review/query/<query_id>/` が存在しない → STOP してユーザーに確認
- lint結果が提供されていない → STOP してlint実行を要求
- evidenceがwikiに存在しない → 回答を弱めるかlimitationを明示し、fabricateしない
