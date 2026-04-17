# AGENTS/synthesize.md

## Purpose

コミット済みの `raw/` ソースをreview層の構造化された知識候補に変換する。
最終的なwikiコンテンツは生成しない。レビュー待ちの知識アーティファクトを生成する。

---

## Execution Mode

**Prompt** — Claude CLIまたは対話型プロンプトで実行。
このエージェントをロードしてから実行すること。

実行宣言（必須）:
- Task Type: synthesize
- Loaded Agents: synthesize.md, page_policy.md, naming.md
- Execution Plan: [処理対象とアウトプット先]

---

## Prerequisites

- 対象の `raw/` ファイルがコミット済みであること
- `raw/incoming/` は使用しない

---

## Input

- Source: `raw/` 配下のコミット済みファイル（`raw/incoming/` を除く）
- `raw/` は読み取り専用

---

## Output

- 出力先: `review/` 層のみ
- 主な出力先: `review/synthesis_candidates/`
- `wiki/` への書き込みは一切禁止

---

## Processing Rules

### 知識フロー位置づけ

このエージェントが実装するフロー: `raw → review`

**絶対に行ってはならないフロー**: `review → wiki`

wikiへの昇格は approve タスクのみが行う。

### 抽出戦略

**対象**:
- コンセプト・メソッド
- 設計上の決定事項・パターン
- 構造化された関係性

**除外**:
- 生のサマリー
- 文脈依存の説明
- 会話的なアーティファクト

### 粒度ルール

- 断片化しない: 1つの出力 = 1つの意味のある知識ブロック
- 無関係なコンセプトをマージしない
- 各出力は独立してreusableであること

### 統合優先

- 既存の知識構造との整合を試みる
- 孤立したノートを避ける
- 将来のwiki統合を念頭に置く

---

## Prohibited Actions

- `wiki/` への書き込み（`wiki/synthesis/` を含む全て）
- `index.md` または `log.md` の更新（synthesize タスクでは不可）
- `raw/` ファイルの変更
- reviewをバイパスした最終知識としてのマーク付け
- 承認のシミュレーション
- `raw/incoming/` の使用

---

## Failure Conditions

即座に中止する条件:

- `wiki/` への書き込みを試みている
- reviewをバイパスしようとしている
- raw データが不十分（→ STOP してユーザーに確認）
- 出力がreusableでない（純粋なサマリーのみ）
- 出力がwikiコンテンツを参照せず raw のみを参照する構造になっている
