# Requirements Document

## Introduction
Rwiki知識ベースシステムにおいて、CLAUDE.mdカーネルの肥大化を防ぎつつ、Claudeがタスク実行時に適切なルールをオンデマンドで読み込める仕組みを構築する。仕様案で定義された9タスク種別に対応するサブプロンプト（AGENTS/）を `docs/` の素案に基づきレビュー・精査し、`templates/AGENTS/` に正式配置する。カーネルにはエージェント選択ルールのみを記載し、詳細実行ルールはAGENTS/に委譲する。ポリシー系ファイル（page_policy, naming, git_ops）の配置先も決定する。ユーザーガイド初版およびCHANGELOG追記も含む。

## Boundary Context
- **In scope**: 9タスク別エージェントファイルの精査・正式配置、ポリシーファイルの配置先決定・配置、CLAUDE.mdカーネルへのエージェントロード指示の統合、AGENTS/README.md、docs/user-guide.md 初版、CHANGELOG.md追記
- **Out of scope**: CLIコマンドの実装変更（cli-query、cli-auditスペック）、テスト体系（test-suiteスペック）、Obsidian Vault設定
- **Adjacent expectations**: project-foundation が `templates/CLAUDE.md` カーネルと `rw init` コマンド（templates/AGENTS/ をVaultにコピーする機能）を提供済み。cli-audit は本スペックの audit エージェント定義に依存する。cli-query は query系エージェント定義を参照する（roadmap 上も agents-system への依存関係あり。AGENTS/ ファイルを直接読み込む方式を前提とする）。既存CLIコマンド（ingest, lint, synthesize-logs, approve）はPythonでルールを実装しており、対応するAGENTS/ファイルとルールの二重管理が生じる。将来的なCLI側の一元化（AGENTS/ファイルをCLIから参照する方式への移行）は本スペックのスコープ外だが、エージェントファイル設計時にCLIとの整合性を意識すること

## Requirements

### Requirement 1: タスク別エージェントファイルの配置
**Objective:** Rwiki運用者として、9タスク種別それぞれに対応するエージェントファイルが `templates/AGENTS/` に配置されていてほしい。Claudeがタスク実行時に必要なルールを選択的にロードできるようにするため。

#### Acceptance Criteria
1. The `templates/AGENTS/` shall エージェントファイルとして以下の9ファイルを含む: `ingest.md`, `lint.md`, `synthesize.md`, `synthesize_logs.md`, `query.md`, `query_answer.md`, `query_fix.md`, `audit.md`, `approve_synthesis.md`
2. The 各エージェントファイル shall `docs/` の対応する素案をベースとし、仕様案のタスクモデル・実行モデルとの整合性を確保した内容を持つ。整合性の確認観点: レイヤー境界（入力元・出力先が仕様案の知識フローに違反しないか）、タスク分類（仕様案の9種と1:1対応するか）、禁止パターン（仕様案のマルチステップルール違反がないか）
3. The 各エージェントファイル shall 当該タスクの実行に必要十分な情報を含み、他のタスクエージェントファイルへの依存なしにロード可能である（ただし、ポリシーファイルの参照または埋め込みは許容する。その方針はReq 4で定義する）
4. The エージェント体系 shall 将来のタスク種別追加に対して拡張可能な構造とする。新しいエージェントファイルの追加手順（ファイル作成、マッピング表への追記、README更新）が明確に定義されている
5. The agents-system shall ファイル名とタスク種別の対応関係を明確にする。現在の非対称な命名（タスク種別 `query_extract` に対しファイル名 `query.md`、タスク種別 `approve` に対しファイル名 `approve_synthesis.md`）について、設計時に命名方針を確定する
6. The `audit.md` shall 仕様案の監査モデルで定義された4階層の監査ティア（Micro-check、Structural、Semantic、Strategic）の定義と実行条件を含む

### Requirement 2: エージェントファイルの共通構造
**Objective:** Rwiki運用者として、すべてのエージェントファイルが統一された構造を持ち、予測可能な形式で記述されていてほしい。Claudeがエージェントを効率的に解釈し、ルールを適用できるようにするため。

#### Acceptance Criteria
1. The 各エージェントファイル shall 以下の要素を明示的に定義する: タスクの目的、実行モード（CLI経由またはプロンプトレベル）、前提条件（実行前に完了しているべき先行タスクやコミット状態）、入力元（読み取り対象のレイヤー/ディレクトリ）、出力先（書き込み対象のレイヤー/ディレクトリ）、処理ルール、禁止事項
2. The 各エージェントファイル shall レイヤー境界制約（どのレイヤーへの読み書きが許可/禁止されるか）を明記する
3. The 各エージェントファイル shall 出力形式またはコミットルールを定義する（該当する場合）
4. The 各エージェントファイル shall 失敗条件（処理を中断すべき状況）を定義する
5. If エージェントファイルの内容が肥大化する場合（docs/素案のレビュー時に判断）, the agents-system shall 当該エージェントをサブファイルに分割し、メインファイルからの参照構造を設計時に定義する

### Requirement 3: カーネルとエージェントの責務分離
**Objective:** Rwiki運用者として、CLAUDE.mdカーネルにはグローバルルールとエージェント選択ロジックのみが記載され、タスク固有の詳細ルールはAGENTS/に完全委譲されていてほしい。カーネルの肥大化を防ぎ、保守性を維持するため。

#### Acceptance Criteria
1. The `templates/CLAUDE.md` shall エージェントロードルール（必要なエージェントのみをロードし、すべてを読み込まないこと）を明記する
2. The `templates/CLAUDE.md` shall 9タスク種別からAGENTS/ファイルへの完全なマッピング表を含む
3. The `templates/CLAUDE.md` shall タスク固有の処理ルール（例: ingestの移動手順、lintの検証項目詳細）をAGENTS/に委譲し、カーネル内に重複記載しない。カーネルに残すルールは「複数タスクに共通で常時適用されるグローバルルール」に限定し、その判断基準を設計時に定義する
4. The `templates/CLAUDE.md` shall project-foundationで確立した既存グローバルルール（rawの完全性、reviewの強制、承認要件、書き込み権限、インデックスとログ整合性、コミット分離）および実行モデルのグローバルルール（タスク選択ルール、曖昧性ルール、実行宣言、マルチステップルール）を保全し、カーネル更新時にこれらを破壊しない
5. When Claudeがプロンプトレベルでタスクを開始する場合, the `templates/CLAUDE.md` shall タスク分類 → エージェント特定 → エージェントロード → 実行宣言 → 実行、という順序を明確に指示する
6. The `templates/CLAUDE.md` shall CLI実行（rw コマンド経由）とプロンプトレベル実行（Claude CLIでの対話的実行）を区別し、それぞれにおけるエージェントロードの要否と手順を明記する
7. The `templates/CLAUDE.md` shall プロンプトレベル実行時のエージェントロードの具体的手順（Claudeがどのようにファイルを読み込むか）を記載する
8. The `templates/CLAUDE.md` shall 失敗条件「required AGENTS are not identified」の判定基準（マッピング表に該当がない場合、ファイルが存在しない場合など）を明記する
9. The `templates/CLAUDE.md` shall タスク→エージェントマッピング表が将来のエージェント追加に対応できるよう、マッピング表の拡張ルール（新タスク種別とエージェントの追加方法）を記載する
10. The `templates/CLAUDE.md` shall カーネルのグローバルルールがエージェントファイルの指示に常に優先するというルール階層原則を明記する。If エージェントファイルの記述がカーネルのグローバルルールと矛盾する場合, the Claude shall カーネルのルールに従う

### Requirement 4: ポリシーファイルの配置とロード方針
**Objective:** Rwiki運用者として、タスク横断的なポリシー（ページ種別、命名規則、Git操作ルール）が適切に配置され、必要なタスクから参照可能であってほしい。複数タスクで共通のルールを一貫して適用できるようにするため。

#### Acceptance Criteria
1. The agents-system shall `page_policy.md`（ページ種別と選択ルール）、`naming.md`（命名規則）、`git_ops.md`（コミット規律）の3ポリシーの内容を配置する（独立ファイル、CLAUDE.mdカーネルへの統合、エージェントファイルへの埋め込みのいずれかの形式で。配置形式は設計時に決定する）
2. The 各ポリシー shall `docs/` の対応する素案をベースとした内容を持つ
3. The ポリシー shall 必要とするエージェントから参照可能な形式で配置される
4. If ポリシーがCLAUDE.mdカーネルに統合される場合, the 統合内容 shall 元の素案の主要ルールを網羅する
5. The agents-system shall 各タスクがどのポリシーを必要とするか（例: synthesizeはpage_policy + naming、approveはgit_ops）を定義し、タスク→エージェント+ポリシーの複合的なロード対象をカーネルまたはエージェントファイル内で明示する
6. If ポリシーがエージェントファイルに埋め込まれる場合, the 埋め込み内容 shall `docs/` の対応する素案の主要ルールとの整合性を維持する

### Requirement 5: AGENTS/ドキュメント
**Objective:** Rwiki運用者として、AGENTS/ディレクトリの構成と各ファイルの役割を把握できるドキュメントがほしい。エージェント体系の全体像を素早く理解できるようにするため。

#### Acceptance Criteria
1. The `templates/AGENTS/README.md` shall エージェント体系の概要（目的、カーネルとの関係、ロードルール）を説明する
2. The `templates/AGENTS/README.md` shall 全エージェントファイルの一覧と各ファイルの役割を記載する
3. Where ポリシーファイルが `templates/AGENTS/` に配置される場合, the `README.md` shall ポリシーファイルの位置づけ（タスクエージェントとの違い）を説明する
4. The `templates/AGENTS/README.md` shall 新しいエージェントの追加手順（ファイル作成規約、マッピング表への追記、README自体の更新方法）を記載する

### Requirement 6: ユーザーガイド初版
**Objective:** Rwiki運用者として、運用サイクルの詳細手順と各コマンドのリファレンスを参照できるドキュメントがほしい。日常的なWiki運用を円滑に進められるようにするため。

#### Acceptance Criteria
1. The `docs/user-guide.md` shall Rwikiの基本的な運用サイクル（lint → ingest → synthesize → approve → audit）の詳細手順を記載する
2. The `docs/user-guide.md` shall 既存CLIコマンド（init, ingest, lint, lint query, synthesize-logs, approve）のリファレンス（使用方法、引数、出力）を記載する
3. The `docs/user-guide.md` shall プロンプトレベルで実行するタスク（synthesize, query系, audit）の実行方法（Claude CLIでのAGENTSロード手順）を記載する
4. The `docs/user-guide.md` shall 既存Vaultのエージェント更新手順（`rw init` の re-init による templates/AGENTS/ の再配置方法）を記載する

### Requirement 7: CHANGELOG追記
**Objective:** プロジェクト関係者として、agents-systemスペックの成果物を変更履歴に記録したい。何がいつ変更されたかを追跡するため。

#### Acceptance Criteria
1. The `CHANGELOG.md` shall agents-systemスペックの成果物（AGENTS/エージェントファイル9種、ポリシー、CLAUDE.mdカーネル更新、AGENTS/README.md、docs/user-guide.md）を記録する
