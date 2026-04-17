# Requirements Document

## Introduction
Rwiki知識ベースシステムにおいて、CLAUDE.mdカーネルの肥大化を防ぎつつ、Claudeがタスク実行時に適切なルールをオンデマンドで読み込める仕組みを構築する。仕様案で定義された9タスク種別に対応するサブプロンプト（AGENTS/）を `docs/` の素案に基づきレビュー・精査し、`templates/AGENTS/` に正式配置する。カーネルにはエージェント選択ルールのみを記載し、詳細実行ルールはAGENTS/に委譲する。ポリシー系ファイル（page_policy, naming, git_ops）の配置先も決定する。ユーザーガイド初版およびCHANGELOG追記も含む。

## Boundary Context
- **In scope**: 9タスク別エージェントファイルの精査・正式配置、ポリシーファイルの配置先決定・配置、CLAUDE.mdカーネルへのエージェントロード指示の統合、AGENTS/README.md、docs/user-guide.md 初版、CHANGELOG.md追記
- **Out of scope**: CLIコマンドの実装変更（cli-query、cli-auditスペック）、テスト体系（test-suiteスペック）、Obsidian Vault設定
- **Adjacent expectations**: project-foundation が `templates/CLAUDE.md` カーネルと `rw init` コマンド（templates/AGENTS/ をVaultにコピーする機能）を提供済み。cli-audit は本スペックの audit エージェント定義に依存する。cli-query は query系エージェント定義を参照する

## Requirements

### Requirement 1: タスク別エージェントファイルの配置
**Objective:** Rwiki運用者として、9タスク種別それぞれに対応するエージェントファイルが `templates/AGENTS/` に配置されていてほしい。Claudeがタスク実行時に必要なルールを選択的にロードできるようにするため。

#### Acceptance Criteria
1. The `templates/AGENTS/` shall エージェントファイルとして以下の9ファイルを含む: `ingest.md`, `lint.md`, `synthesize.md`, `synthesize_logs.md`, `query.md`, `query_answer.md`, `query_fix.md`, `audit.md`, `approve_synthesis.md`
2. The 各エージェントファイル shall `docs/` の対応する素案をベースとし、仕様案のタスクモデル・実行モデルとの整合性を確保した内容を持つ
3. The 各エージェントファイル shall 当該タスクの実行に必要十分な情報を自己完結的に含み、他のエージェントファイルへの依存なしに単独でロード可能である

### Requirement 2: エージェントファイルの共通構造
**Objective:** Rwiki運用者として、すべてのエージェントファイルが統一された構造を持ち、予測可能な形式で記述されていてほしい。Claudeがエージェントを効率的に解釈し、ルールを適用できるようにするため。

#### Acceptance Criteria
1. The 各エージェントファイル shall 以下の要素を明示的に定義する: タスクの目的、入力元（読み取り対象のレイヤー/ディレクトリ）、出力先（書き込み対象のレイヤー/ディレクトリ）、処理ルール、禁止事項
2. The 各エージェントファイル shall レイヤー境界制約（どのレイヤーへの読み書きが許可/禁止されるか）を明記する
3. The 各エージェントファイル shall 出力形式またはコミットルールを定義する（該当する場合）
4. The 各エージェントファイル shall 失敗条件（処理を中断すべき状況）を定義する

### Requirement 3: カーネルとエージェントの責務分離
**Objective:** Rwiki運用者として、CLAUDE.mdカーネルにはグローバルルールとエージェント選択ロジックのみが記載され、タスク固有の詳細ルールはAGENTS/に完全委譲されていてほしい。カーネルの肥大化を防ぎ、保守性を維持するため。

#### Acceptance Criteria
1. The `templates/CLAUDE.md` shall エージェントロードルール（必要なエージェントのみをロードし、すべてを読み込まないこと）を明記する
2. The `templates/CLAUDE.md` shall 9タスク種別からAGENTS/ファイルへの完全なマッピング表を含む
3. The `templates/CLAUDE.md` shall タスク固有の処理ルール（例: ingestの移動手順、lintの検証項目詳細）をAGENTS/に委譲し、カーネル内に重複記載しない
4. When Claudeがタスクを開始する場合, the `templates/CLAUDE.md` shall タスク種別の分類 → 該当エージェントの特定 → エージェントファイルのロード、という手順を指示する

### Requirement 4: ポリシーファイルの配置
**Objective:** Rwiki運用者として、タスク横断的なポリシー（ページ種別、命名規則、Git操作ルール）が適切に配置され、必要なタスクから参照可能であってほしい。複数タスクで共通のルールを一貫して適用できるようにするため。

#### Acceptance Criteria
1. The agents-system shall `page_policy.md`（ページ種別と選択ルール）、`naming.md`（命名規則）、`git_ops.md`（コミット規律）の3ポリシーファイルを配置する
2. The 各ポリシーファイル shall `docs/` の対応する素案をベースとした内容を持つ
3. The ポリシーファイル shall 必要とするエージェントから参照可能な場所に配置される
4. If ポリシーファイルがCLAUDE.mdカーネルに統合される場合, the 統合内容 shall 元の素案の主要ルールを網羅する

### Requirement 5: AGENTS/ドキュメント
**Objective:** Rwiki運用者として、AGENTS/ディレクトリの構成と各ファイルの役割を把握できるドキュメントがほしい。エージェント体系の全体像を素早く理解できるようにするため。

#### Acceptance Criteria
1. The `templates/AGENTS/README.md` shall エージェント体系の概要（目的、カーネルとの関係、ロードルール）を説明する
2. The `templates/AGENTS/README.md` shall 全エージェントファイルの一覧と各ファイルの役割を記載する
3. Where ポリシーファイルが `templates/AGENTS/` に配置される場合, the `README.md` shall ポリシーファイルの位置づけ（タスクエージェントとの違い）を説明する

### Requirement 6: ユーザーガイド初版
**Objective:** Rwiki運用者として、運用サイクルの詳細手順と各コマンドのリファレンスを参照できるドキュメントがほしい。日常的なWiki運用を円滑に進められるようにするため。

#### Acceptance Criteria
1. The `docs/user-guide.md` shall Rwikiの基本的な運用サイクル（ingest → lint → synthesize → approve → audit）の詳細手順を記載する
2. The `docs/user-guide.md` shall 既存CLIコマンド（init, ingest, lint, synthesize-logs, approve）のリファレンス（使用方法、引数、出力）を記載する
3. The `docs/user-guide.md` shall プロンプトレベルで実行するタスク（synthesize, query系, audit）の実行方法（Claude CLIでのAGENTSロード手順）を記載する

### Requirement 7: CHANGELOG追記
**Objective:** プロジェクト関係者として、agents-systemスペックの成果物を変更履歴に記録したい。何がいつ変更されたかを追跡するため。

#### Acceptance Criteria
1. The `CHANGELOG.md` shall agents-systemスペックの成果物（AGENTS/エージェントファイル9種、ポリシーファイル、CLAUDE.mdカーネル更新、AGENTS/README.md、docs/user-guide.md）を記録する
