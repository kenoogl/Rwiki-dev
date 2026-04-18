# Roadmap

## Overview
Rwikiは、Karpathy式LLM Wikiを参考にした知識ベース構築システムである。知識ソースの取捨選択は人間が行い、要約・概念化・分析・監査はLLMが担当する。Markdownファイルの集合をWikiとし、raw → review → wiki の3層パイプラインを通じて、トレーサビリティと品質を保証する統制された知識管理を実現する。

既存実装として `scripts/rw_light.py` にlint, ingest, synthesize-logs, approve, lint queryの5コマンドが存在する。本ロードマップでは、残りのインフラ・コマンド・プロンプト体系・テストを設計・実装し、システムを完成させる。また、必要に応じて機能追加や再設計も考慮する。

**注**: 仕様案のタスク分類9種のうち、CLIコマンドを持たないPrompt-onlyタスクは `synthesize` のみ（Claude CLIがAGENTS/synthesize.mdをロードして直接操作）。他の8タスクは既存CLI（ingest, lint, synthesize-logs, approve, lint query）または新規CLI（query extract, query answer, query fix — cli-queryスペック、audit — cli-auditスペック）として実装予定である。query系・auditのCLIは内部でClaude CLIを呼び出すHybridモードを採用予定。実装完了時に各成果物（templates/CLAUDE.md, AGENTS/*.md, README.md）の実行モード表記を Prompt → CLI (Hybrid) に更新する。

## Approach Decision
- **Chosen**: レイヤー順構築 — インフラ → AGENTS → CLI → テストの順に上流から構築
- **Why**: データフローの自然な依存順に沿うため、各フェーズが前段の成果物を前提にできる。全スペックを先に設計し、実装は依存順に進める
- **Rejected alternatives**:
  - 横断設計・一括実装: 設計フェーズが長くフィードバックが遅い
  - MVP優先: 後から設計変更が必要になるリスク

## Scope
- **In**: `rw init`コマンド（Vault用ディレクトリ構造・Git初期化）、Wiki用CLAUDE.mdカーネル、AGENTS/サブプロンプト体系、query系3コマンド、auditコマンド、全コマンドのテスト、ドキュメント（README.md、ユーザガイド、開発者ガイド、CHANGELOG）
- **Out**: Obsidian Vault設定、qmd統合、Zotero連携、CI/CD

## Documentation Strategy

ドキュメントは各スペックの実装と同時に作成し、実装と乖離しない状態を保つ。

| ドキュメント | 担当スペック | 内容 |
|-------------|-------------|------|
| README.md | project-foundation | プロジェクト概要、セットアップ手順（rw init）、基本的な使い方 |
| docs/user-guide.md | cli-query, cli-audit で段階的に拡充 | 運用サイクルの詳細手順、各コマンドのリファレンス、ワークフロー例 |
| docs/developer-guide.md | test-suite | コントリビューション手順、テスト実行方法、アーキテクチャ概要 |
| CHANGELOG.md | 全スペック（各実装完了時に追記） | リリースノート・変更履歴 |

## Architecture Decision: 開発リポジトリとVaultの分離

```
Rwiki-dev/（開発リポジトリ）              ~/SomeVault/（デプロイ先Vault）
├── scripts/rw_light.py                    ├── CLAUDE.md  （テンプレートからコピー）
├── templates/                            ├── index.md
│   ├── CLAUDE.md        ──deploy──►      ├── log.md
│   └── AGENTS/          ──deploy──►      ├── raw/
│       ├── ingest.md                     │   ├── incoming/
│       ├── lint.md                       │   │   ├── articles/
│       ├── synthesize.md                 │   │   ├── papers/{zotero,local}/
│       ├── synthesize_logs.md            │   │   ├── meeting-notes/
│       ├── query_extract.md              │   │   └── code-snippets/
│       ├── query_answer.md               │   ├── llm_logs/
│       ├── query_fix.md                  │   ├── articles/
│       ├── audit.md                      │   ├── papers/{zotero,local}/
│       ├── approve.md                   │   ├── meeting-notes/
│       ├── page_policy.md               │   └── code-snippets/
│       ├── naming.md                    ├── review/
│       ├── git_ops.md                   │   ├── synthesis_candidates/
├── tests/                                │   └── query/
├── docs/                                 ├── wiki/
│   ├── Rwiki仕様案.md                    │   ├── concepts/
│   ├── CLAUDE.md（カーネル素案）           │   ├── methods/
│   └── ...（サブプロンプト素案）            │   ├── projects/
├── .kiro/                                │   ├── entities/{people,tools}/
├── .git/（初期化済み）                     │   └── synthesis/
└── CLAUDE.md（開発用）                    ├── AGENTS/    （テンプレートからコピー）
                                          ├── logs/
                                          ├── scripts/rw.py → rw_light.py
                                          ├── .obsidian/
                                          └── .git/（rw initで初期化）
```

- **`docs/`** = 開発ドキュメント保存先。仕様案・設計メモ・ADR等を配置（`Rwiki仕様案.md` をここに移動）
- **`Rwiki-dev/`** = 開発リポジトリ。CLI・AGENTS・テスト等のソースコードを管理
- **デプロイ先Vault** = Obsidian Vaultとして運用。`rw init` コマンドでディレクトリ構造・テンプレートコピー・Git初期化・シンボリックリンクを一括セットアップ
- **`templates/`** = Wiki運用用のCLAUDE.mdカーネルとAGENTS/サブプロンプトのマスターコピー。開発リポジトリで管理し、デプロイ時にVaultへコピーする
- 開発用CLAUDE.md（Kiro/Spec設定）とWiki運用用CLAUDE.md（Rwikiグローバルルール）は**目的が異なる別ファイル**

## Constraints
- Python（rw_light.pyの既存実装に合わせる）
- CLIはrw_light.pyへのシンボリックリンク `rw` で実行
- Claude CLIをLLMインターフェースとして使用（synthesize-logsで実績あり）
- rawへのLLM書き込みは一切禁止
- wikiへの昇格は必ずreviewを経由
- 開発リポジトリとデプロイ先Vaultは別ディレクトリ

## Boundary Strategy
- **Why this split**: 各スペックが明確な責務境界を持ち、独立してレビュー・テスト可能。project-foundationが全体の基盤、agents-systemがLLM実行ルール、cli-query/cli-auditが機能追加、test-suiteが品質保証と役割が分離されている
- **Shared seams to watch**:
  - AGENTS/のプロンプトとCLIコマンドの整合性（特にauditとquery）
  - CLAUDE.mdカーネルとAGENTS/の責務分離
  - rw_light.pyへの新コマンド追加時の既存コード影響

## Architecture Decision: CLI-AGENTS プロンプト統合方針

現在 `cmd_synthesize_logs()` は Claude CLI 呼び出し用プロンプトを Python コード内にハードコードしている。agents-system で `AGENTS/synthesize_logs.md` が作成されると、同じルールが2箇所に存在する二重管理状態になる。

**方針**:
- **既存コマンド（synthesize-logs）**: agents-system スコープでは二重管理を容認し、Implementation Notes で初期整合性を確保する。将来的に CLI が AGENTS/ ファイルをプロンプトソースとして読み込む方式に移行する（別スペックまたは技術負債として対応）
- **新規コマンド（cli-query, cli-audit）**: 設計時に AGENTS/ ファイルを直接読み込む方式を前提とし、ハードコードプロンプトを避ける。CLI が `AGENTS/{task}.md` を読み込み、プロンプトの基礎として使用する

これにより、新規コマンドでは単一ソース（AGENTS/ ファイル）を維持し、既存コマンドは段階的に移行する。

## Technical Debt (将来の修正事項)

### Severity 体系の既存コマンド統一
cli-audit 要件策定時に、プロジェクト内で3つの severity 体系が混在していることが判明。cli-audit では ERROR/WARN/INFO の3水準に統一して実装する。既存コマンド（`rw lint`: PASS/WARN/FAIL）の severity 移行は将来対応とする。

### exit 1 のセマンティクス分離
全 `rw` コマンドで exit 1 が「ランタイムエラー」と「FAIL 検出」の両方を意味する。自動化やCI統合の要件が出た段階で、exit 1（エラー）/ exit 2（FAIL 検出）の分離を全コマンドに一括適用する別スペックとして検討する。

### call_claude() のタイムアウト未設定
`call_claude()` に `subprocess.run()` のタイムアウトが設定されていない。Claude CLI がハングした場合、プロセスが無限に待機する。cli-query では応答が速いため顕在化していないが、cli-audit の monthly/quarterly では wiki 全体の分析で30-120秒かかり、リスクが高まる。cli-audit 設計フェーズでタイムアウト値を決定し、`call_claude()` 共通関数に適用する（cli-query にも波及）。
→ **cli-audit 設計で対応済み**: `call_claude()` に `timeout` パラメータを追加（デフォルト None、audit は 300 秒）。

### rw_light.py のモジュール分割
cli-audit 実装後の rw_light.py は約 2,800 行・94 関数に達する。単一ファイルとしての保守限界（目安: 3,000 行）に接近している。現時点の roadmap（test-suite が最後のスペック）では rw_light.py への大規模追加は予定されていないため即座の分割は不要だが、新規スペック（CI 統合、マルチユーザー等）が追加される場合はモジュール分割を検討する。自然な分割境界:
- `rw_light.py` → コマンドディスパッチ + main
- `rw_utils.py` → ユーティリティ関数群
- `rw_prompt_engine.py` → Prompt Engine
- `rw_audit.py` → audit コマンド + check 関数群
- `rw_query.py` → query コマンド + query lint

分割時は `rw` シンボリックリンクの仕組み（単一ファイル前提）の変更も必要。

## Specs (dependency order)
- [x] project-foundation -- `rw init`コマンド（Vaultセットアップ・Git初期化）・Wiki用CLAUDE.mdカーネル・templates/配置. Dependencies: none
- [x] agents-system -- AGENTS/サブプロンプト体系（9タスク用エージェント定義 + ポリシー系配置）. Dependencies: project-foundation
- [x] cli-query -- query_answer, query_extract, query_fixコマンドの実装. Dependencies: project-foundation, agents-system
- [ ] cli-audit -- auditコマンド（micro/weekly/monthly/quarterly監査）の実装. Dependencies: project-foundation, agents-system
- [ ] test-suite -- rw_light.py全コマンドのテスト体系構築. Dependencies: project-foundation, cli-query, cli-audit
