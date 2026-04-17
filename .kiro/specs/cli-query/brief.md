# Brief: cli-query

## Problem
仕様案で定義されているquery系タスク（query_answer, query_extract, query_fix）がCLIに未実装。Wikiに対する質問応答・情報抽出・修正提案のワークフローが自動化されていない。

## Current State
- `rw lint query` でクエリディレクトリの検証は可能
- query用のディレクトリ構造（review/query/）とメタデータスキーマ（question.md, answer.md, evidence.md, metadata.json）はlint queryで定義済み
- しかし、クエリの実行・回答生成・抽出・修正を行うコマンドが存在しない

## Desired Outcome
- `rw query answer` でWikiに対する質問を実行し、回答をreview/query/に生成
- `rw query extract` でwikiから構造化知識アーティファクト（question.md, answer.md, evidence.md, metadata.json）を抽出しreview/query/に配置
- `rw query fix` でlint/audit結果に基づく修正提案を生成
- すべてのquery結果はreview/を経由し、直接wikiに書き込まない

> **Note (requirements phase で変更)**: `rw query answer` は ephemeral な直接回答（stdout のみ）に変更。`review/query/` へのファイル生成は `rw query extract` のみが担当する。また、synthesize-logs の実装パターン踏襲は撤回し、AGENTS/ファイルをプロンプトの正規ソースとする一元管理方式を採用する（Req 9）。log.md追記は query 操作が wiki/ を変更しないため除外。query fix の入力は lint 結果のみ（audit 結果は含まない）。

## Approach
既存のlint query実装のデータ構造（question.md, answer.md, evidence.md, metadata.json）を活用し、Claude CLIを呼び出して回答生成を行う。

## Scope
- **In**: query answer, query extract, query fixの3サブコマンド実装、review/query/への出力、log.md追記、usage表示更新、docs/user-guide.md へのqueryコマンドリファレンス追記、CHANGELOG.md追記
- **Out**: query結果のwikiへの昇格（approveコマンドの拡張として別途検討）、クエリのUI

## Boundary Candidates
- query answer: 質問→回答生成（Wikiソース参照）
- query extract: wikiからの構造化知識アーティファクト抽出
- query fix: 問題修正提案の生成

## Out of Boundary
- query結果の承認・昇格プロセス
- AGENTS/query_extract.mdの内容（agents-systemスペック）
- テスト（test-suiteスペック）

## Upstream / Downstream
- **Upstream**: project-foundation（ディレクトリ構造）、既存のlint query実装（データ構造定義）、docs/の素案（query.md, query_answer.md, query_fix.md — プロンプト設計の参考）
- **Downstream**: test-suite（テスト対象）

## Existing Spec Touchpoints
- **Extends**: なし
- **Adjacent**: agents-system（query実行時のプロンプトはAGENTS/query_extract.mdを参照する可能性）

## Constraints
- query結果はreview/query/に配置（wikiへ直行禁止）
- 推論を含む回答には[INFERENCE]マーカー必須
- metadata.jsonにquery_id, sources, query_type, created_atを含める
- scopeの明示が必要（lint queryのQL004チェック）
