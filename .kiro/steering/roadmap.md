# Roadmap

## Overview
Rwikiは、Karpathy式LLM Wikiを参考にした知識ベース構築システムである。知識ソースの取捨選択は人間が行い、要約・概念化・分析・監査はLLMが担当する。Markdownファイルの集合をWikiとし、raw → review → wiki の3層パイプラインを通じて、トレーサビリティと品質を保証する統制された知識管理を実現する。

既存実装として `scripts/rw_light.py` にlint, ingest, synthesize-logs, approve, lint queryの5コマンドが存在する。本ロードマップでは、残りのインフラ・コマンド・プロンプト体系・テストを設計・実装し、システムを完成させる。また、必要に応じて機能追加や再設計も考慮する。

**注**: 仕様案のタスク分類9種のうち、`synthesize` はCLIコマンドではなくプロンプトレベルで実行する（Claude CLIがAGENTS/synthesize.mdをロードして直接操作）。CLIで実装するのは `synthesize-logs` のみ。

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
│       ├── query.md                      │   │   └── code-snippets/
│       ├── query_answer.md               │   ├── llm_logs/
│       ├── query_fix.md                  │   ├── articles/
│       ├── audit.md                      │   ├── papers/{zotero,local}/
│       ├── approve_synthesis.md          │   ├── meeting-notes/
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

## Specs (dependency order)
- [x] project-foundation -- `rw init`コマンド（Vaultセットアップ・Git初期化）・Wiki用CLAUDE.mdカーネル・templates/配置. Dependencies: none
- [ ] agents-system -- AGENTS/サブプロンプト体系（9タスク用エージェント定義 + ポリシー系配置）. Dependencies: project-foundation
- [ ] cli-query -- query_answer, query_extract, query_fixコマンドの実装. Dependencies: project-foundation, agents-system
- [ ] cli-audit -- auditコマンド（micro/weekly/monthly/quarterly監査）の実装. Dependencies: project-foundation, agents-system
- [ ] test-suite -- rw_light.py全コマンドのテスト体系構築. Dependencies: project-foundation, cli-query, cli-audit
