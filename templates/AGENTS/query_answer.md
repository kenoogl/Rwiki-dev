# AGENTS/query_answer.md

## Purpose

キュレーション済みwiki知識を使ってユーザーの質問に直接回答する。
このモードは**ユーザーへの直接説明**が目的であり、アーティファクト生成モードではない。

再利用可能なアーティファクトが必要な場合は、query_extract タスクを使用すること。

---

## Execution Mode

**Prompt** — Claude CLIまたは対話型プロンプトで実行。
このエージェントをロードしてから実行すること。

実行宣言（必須）:
- Task Type: query_answer
- Loaded Agents: query_answer.md, page_policy.md
- Execution Plan: [質問内容]

---

## Prerequisites

- `wiki/` にコンテンツが存在すること

---

## Input

- Primary source: `wiki/`
- 有用な場合は最初に `index.md` を確認する
- `raw/`・`raw/incoming/`・`raw/llm_logs/`・外部の仮定は使用しない（明示的指示がある場合を除く）

---

## Output

- チャットスタイルの回答（`review/query/<query_id>/` アーティファクトは生成しない）
- ただし明示的に抽出モードへの切り替えを指示された場合を除く

---

## Processing Rules

### ルール1: Wiki-first 回答

常に現在のwiki知識から回答する。wikiがサポートしていない事実を発明しない。

wikiが不完全な場合は明示的に述べる:
- "insufficient knowledge in current wiki"
- "the current wiki does not contain enough information to answer this fully"

### ルール2: 直接説明（アーティファクト生成なし）

- チャットスタイルの明確な回答を生成する
- 4ファイルアーティファクト契約を強制しない
- 抽出モードへの明示的な切り替え指示がない限り `question.md`・`answer.md`・`evidence.md`・`metadata.json` を生成しない

### ルール3: 構造化されているが軽量な回答

適切な場合に使用:
- 短いセクション
- 簡潔な箇条書き
- 関連コンセプトへの `[[wiki links]]`

シンプルな質問を形式的なレポートに変換しない。

### ルール4: 用語の一貫性

既存のwikiと一致する用語を使用する。wikiに複数の用語が存在する場合は、主要な用語を使用し、エイリアスは明確さが必要な場合のみ言及する。

### ルール5: 事実と解釈の区別

解釈・抽象化・クロスページ推論を行う場合は、信頼度を明示する:
- "based on the current wiki, ..."
- "the wiki suggests that ..."
- "[INFERENCE] ..." （強い明示が必要な場合）

### 回答プロセス

1. **質問タイプを特定**: 定義・説明・比較・理由・関係などに分類する（出力には過度に露出しない）
2. **関連wiki知識を特定**: `index.md` を確認し、最も関連性の高いwikiページを特定する
3. **回答を構築**: 直接回答から始め、必要に応じて構造を追加する
4. **不十分な場合は明示**: wikiで回答できない部分を明示し、fabricateしない
5. **必要に応じてエスカレーション提案**: 再利用可能なアーティファクトが有用な場合のみ提案する

### エスカレーションルール

以下のような場合は query_extract タスクへの切り替えを提案する:
- 「整理して保存したい」
- 「再利用可能な形にしたい」
- 「evidence付きで残したい」

自動的に保存・生成はしない（指示があった場合を除く）。

---

## Prohibited Actions

- `review/query/<query_id>/...` の自動生成
- `wiki/synthesis/` への直接書き込み
- `raw/` をキュレーション済み知識として扱う
- サポートされていない主張のfabrication
- クロスページ解釈を確立した事実として提示する

---

## Failure Conditions

wikiが不十分な場合:

1. 現在のwikiがサポートしている内容を述べる
2. サポートしていない内容を述べる
3. その境界内でのみ回答する

情報が完全に欠落している場合:
- 限界を明示する
- 欠落しているものを説明する
- 次のステップを提案する（query_extract タスクの実行、raw素材のingest、knowledge synthesisの実行など）
