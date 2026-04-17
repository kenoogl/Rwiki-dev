# Brief: cli-audit

## Problem
仕様案で定義されているauditタスクがCLIに未実装。Wikiの整合性・構造・完全性を定期的に検証する仕組みがなく、知識ベースの品質劣化を検知できない。

## Current State
- auditコマンドは未実装
- 仕様案に4段階の監査サイクルが定義されている（micro/weekly/monthly/quarterly）
- lint queryで一部の検証ロジックは存在するが、wiki全体の整合性チェックは未対応

## Desired Outcome
- `rw audit micro` でingest後のマイクロチェック（リンク切れ・index更新漏れ・frontmatter崩れ）
- `rw audit weekly` で構造監査（孤立ページ・双方向リンク・命名違反）
- `rw audit monthly` で意味監査（矛盾候補抽出、[CONFLICT]/[TENSION]/[AMBIGUOUS]マーカー）
- `rw audit quarterly` でグラフ構造俯瞰・スキーマ改訂提案
- すべてのauditは読み取り専用（ファイル変更禁止）
- 結果はlogs/に出力し、修正にはユーザの明示指示が必要

## Approach
4段階のauditをサブコマンドとして実装。micro/weeklyはrw_light.py内で完結する静的チェック、monthly/quarterlyはClaude CLIを呼び出すLLM支援監査とする。AGENTS/audit.mdのプロンプト定義と連携する。

## Scope
- **In**: audit micro, audit weekly, audit monthly, audit quarterlyの4サブコマンド、logs/への結果出力、レポート表示、docs/user-guide.md へのauditコマンドリファレンス追記、CHANGELOG.md追記
- **Out**: 監査結果に基づく自動修正（読み取り専用の原則）、テスト

## Boundary Candidates
- micro/weekly: 静的チェック（Pythonコードで完結）
- monthly/quarterly: LLM支援監査（Claude CLI連携）

## Out of Boundary
- 監査結果に基づく自動修正
- AGENTS/audit.mdの内容定義（agents-systemスペック）
- テスト（test-suiteスペック）

## Upstream / Downstream
- **Upstream**: project-foundation（ディレクトリ構造・index.md）、agents-system（AGENTS/audit.md）、docs/audit.md（監査プロンプト素案）
- **Downstream**: test-suite（テスト対象）

## Existing Spec Touchpoints
- **Extends**: なし
- **Adjacent**: agents-system（audit実行時のプロンプトはAGENTS/audit.mdを参照）

## Constraints
- auditは読み取り専用タスク（仕様: ファイル変更は禁止）
- 問題を報告してから修正（仕様: 修正にはユーザの明示指示が必要）
- 結果レポートに severity（ERROR/WARN/INFO）を含める
- monthly監査の矛盾マーカーは[CONFLICT]/[TENSION]/[AMBIGUOUS]の3段階
