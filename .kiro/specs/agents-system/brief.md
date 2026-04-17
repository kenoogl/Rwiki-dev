# Brief: agents-system

## Problem
仕様案ではCLAUDE.mdの肥大化を防ぐためAGENTS/サブプロンプト体系が必要とされているが、未作成。Claudeがタスク実行時に適切なルールをオンデマンドで読み込む仕組みがない。

## Current State
- AGENTS/ディレクトリが存在しない（templates/配下にもまだ未配置）
- scripts/rw_light.pyのsynthesize-logsコマンドがClaude CLIを直接呼び出すプロンプトをハードコードしている
- `docs/` に事前検討済みのサブプロンプト素案が存在する：
  - **カーネル**: CLAUDE.md（Wiki運用用の絶対原則）
  - **AGENTS系**: ingest.md, lint.md, synthesize.md, synthesize_logs.md, query_extract.md, query_answer.md, query_fix.md, audit.md
  - **ポリシー系**: page_policy.md, naming.md, git_ops.md
- これらの素案をレビュー・精査し、`templates/` に正式配置する必要がある

## Desired Outcome
- AGENTS/ディレクトリにタスク種別ごとのサブプロンプトが配置されている
- 各エージェントファイルが、そのタスクの実行ルール・制約・出力形式を明確に定義している
- CLAUDE.mdカーネルからAGENTSへの参照・ロード指示が記載されている
- Claudeが作業時に必要なエージェントのみを選択的にロードできる

## Approach
`docs/` の素案をベースに、仕様案の「タスクモデル」「実行モデル」「監査モデル」との整合性をレビューし、`templates/` に正式版を配置する。CLAUDE.mdカーネルにはエージェント選択ルールのみを記載し、詳細はAGENTS/に委譲する。ポリシー系（page_policy, naming, git_ops）はAGENTS/とは別にCLAUDE.mdに統合するか独立配置するかを設計時に判断する。

## Scope
- **In**: `docs/` の素案をレビュー・精査し `templates/AGENTS/` に正式配置（ingest.md, lint.md, synthesize.md, synthesize_logs.md, query_extract.md, query_answer.md, query_fix.md, audit.md, approve.md, README.md）、ポリシー系（page_policy.md, naming.md, git_ops.md）の配置先決定、`templates/CLAUDE.md` へのエージェントロード指示追記、docs/user-guide.md 初版作成（運用サイクル概要・既存コマンドリファレンス）、CHANGELOG.md追記
- **Out**: CLIコマンドの実装変更、テスト

## Boundary Candidates
- ingest/synthesize系エージェント（データフロー制御）
- query系エージェント（質問応答・抽出・修正）
- audit系エージェント（整合性検証）

## Out of Boundary
- CLIコマンドの新規追加・変更（cli-query, cli-auditスペック）
- テスト体系（test-suiteスペック）

## Upstream / Downstream
- **Upstream**: project-foundation（`templates/CLAUDE.md` カーネルとディレクトリ構造）、docs/Rwiki仕様案.md
- **Downstream**: cli-audit（auditエージェントの定義に依存）、cli-query（queryエージェントの参照）。`rw init` がtemplates/AGENTS/をVaultにコピーする

## Existing Spec Touchpoints
- **Extends**: なし
- **Adjacent**: project-foundation（CLAUDE.mdカーネルとの責務分離）

## Constraints
- エージェントロードは必要時のみ（仕様: すべてのAGENTSを読み込んではならない）
- 実行前に必ずタスク種別・読み込んだエージェント・実行計画を宣言（仕様: 実行宣言）
- マルチステップ処理は分解すること（仕様: ingest→wikiを1ステップで行わない）
