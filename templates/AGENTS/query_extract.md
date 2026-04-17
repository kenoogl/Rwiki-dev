# AGENTS/query_extract.md

## Purpose

キュレーション済みwiki知識から再利用可能なクエリアーティファクトを生成する。
単純な検索や一問一答ではなく、構造化された知識抽出プロセスである。

---

## Execution Mode

**CLI (Hybrid)** — `rw query extract "<question>"` コマンドで実行。
CLIがエージェントルールに従い、wiki知識の読み込み・Claude呼び出し・アーティファクト書き出しを自動で行う。

実行宣言（CLIが自動で行う）:
- Task Type: query_extract
- Loaded Agents: query_extract.md, naming.md, page_policy.md
- Execution Plan: [クエリ内容・スコープ・query_id]

---

## Prerequisites

- `wiki/` にコンテンツが存在すること
- query_id が決定されていること（例: `20260417-nonuniform-z`）

---

## Input

- Primary source: `wiki/` のみ
- `index.md` が利用可能な場合は最初に読む
- `raw/`・外部知識・未明示の仮定は使用しない
- 情報が不足している場合は明示的にその旨を述べる

---

## Output

### 4ファイル出力契約（必須）

出力先: `review/query/<query_id>/`

| ファイル | 内容 |
|---|---|
| `question.md` | クエリ・クエリタイプ・スコープ・日付 |
| `answer.md` | 構造化された回答（エビデンス基盤） |
| `evidence.md` | 支持するwikiの抜粋（source: 付き） |
| `metadata.json` | メタデータ（必須フィールド含む） |

全4ファイルを必ず生成すること。wikiが不十分な場合でも4ファイルを生成し、限界を明示する。

#### question.md 必須フィールド
- `query`: クエリテキスト
- `query_type`: `fact` / `structure` / `comparison` / `why` / `hypothesis` の1つ
- `scope`: 対象スコープ
- `date`: YYYY-MM-DD

#### answer.md 要件
- 空でないこと
- 構造化されていること（見出しまたは箇条書き）
- 簡潔かつ意味のある内容
- 全ての重要な主張はエビデンスで裏付けるか `[INFERENCE]` で明示する

#### evidence.md 要件
- 空でないこと
- 各ブロックに `source:` を含むこと
- 最小限の十分な抜粋（バルクダンプ禁止）

#### metadata.json 必須フィールド
- `query_id`
- `query_type`
- `scope`
- `sources`
- `created_at`

---

## Processing Rules

### ルール1: ファクト–エビデンス分離

- `answer.md` = 構造化された説明
- `evidence.md` = 支持する抜粋

混在させない。

### ルール2: ハルシネーション禁止

`answer.md` の全ての重要な主張は `evidence.md` に根拠が必要。

解釈・抽象化・クロスページ推論・拡張を行う場合は必ず:

```
[INFERENCE]
```

と明示する。

### ルール3: Reusability First

チャット文脈なしに使用可能な結果であること。

避けるべき表現:
- 前述 / 上記
- これ / あれ / 今回
- as mentioned above

### ルール4: クエリタイプの選択

以下から1つを選択すること:
- `fact` — 事実の確認
- `structure` — 構造・関係の把握
- `comparison` — 比較・対比
- `why` — 理由・根拠
- `hypothesis` — 仮説・検証

### ルール5: 粒度コントロール

**atomic but meaningful**: 粒度が細かすぎる（単純な1事実）も粗すぎる（過度に広いサマリー）も避ける。

良い例:
- "Why is nonuniform Z grid used?"
- "Difference between Quasi-3D and full 3D solver"

### ルール6: 構造化推論

回答はフラットな抽出であってはならない。コンセプト間の関係を明示し、"what" だけでなく "how" と "why" を説明する。

### 抽出プロセス

1. **スコープ特定**: 関連するwikiページを特定し、query_typeを定義する
2. **エビデンス収集**: 候補箇所を抽出（最小十分量・重複なし）
3. **エビデンス選定**: 直接的な支持エビデンスのみ採用（無関係な文脈を除外）
4. **回答構築**: エビデンスから構造化された回答を構築し、推論を明示する
5. **検証**: 全ての主張にエビデンスまたは `[INFERENCE]` があることを確認する

### Synthesis Candidate ルール

結果が以下を満たす場合:
- クロスページ統合
- reusable
- 汎用化可能

→ `synthesis_candidate = true` を設定してよい

ただし `wiki/synthesis/` には直接書き込まない（候補の提案のみ）。

---

## Prohibited Actions

- `wiki/synthesis/` への直接書き込み
- `raw/` の使用（明示的に指示された場合を除く）
- 4ファイルのうちいずれかを省略する
- 他のエージェントファイルへの直接リンク（`.md` ファイル参照）
- エビデンスなしの主張
- Missing evidenceの創作

---

## Failure Conditions

即座に中止する条件:

- wikiが不十分で回答できない → 限界を明示して4ファイルを生成（ファクトが空の場合は空でもよいが説明を含む）
- query_id が確定していない → STOP してユーザーに確認
- 必須フィールドを含まない metadata.json を生成しようとしている
