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
cli-audit 要件策定時に、プロジェクト内で 3 つの severity 体系が混在していることが判明し、3 水準（ERROR/WARN/INFO）での統一方針を一時決定した。severity-unification 要件策定時に「3 水準方針は永続的な AGENTS↔CLI マッピングコスト（`map_severity()` 関数、`(cli_severity, sub_severity)` タプル）を生む」と再認識し、**4 水準 align 方針に転換**。

統一対象と方針:
- AGENTS と CLI で同名 4 水準: `CRITICAL` / `ERROR` / `WARN` / `INFO`
- `AGENTS/audit.md` の severity 名称を rename: `HIGH`→`ERROR`、`MEDIUM`→`WARN`、`LOW`→`INFO`（`CRITICAL` は維持）
- `rw lint`: status PASS/WARN/FAIL → PASS/FAIL + severity は 4 水準直接割当
- `rw lint query`: status PASS/PASS_WITH_WARNINGS/FAIL → PASS/FAIL（PASS_WITH_WARNINGS 廃止）、severity は 4 水準
- `rw query extract` / `rw query fix`: 内部 `lint_single_query_dir()` の FAIL 判定に基づく exit 2 は新 semantics（FAIL 検出）として維持
- `rw audit`: `map_severity()` を 4→3 マッピングから 4→4 identity 関数に簡略化、`sub_severity` タプル方式を廃止

判断根拠（4 水準選択、AGENTS rename の理由、業界標準整合、cli-audit Req 10 強化）は `memory/project_severity_system.md` に記録。
→ **完了**（severity-unification spec により、2026-04-20）。

### exit 1 のセマンティクス分離
全 `rw` コマンドで exit 1 が「ランタイムエラー」と「FAIL 検出」の両方を意味する問題。当初は別スペックで対応予定だったが、severity-unification 要件策定時に「語彙統一と同時に実施することで破壊的変更を 2 回 → 1 回に削減できる」と判断し、**severity-unification に統合**。

統一後の exit code:
- `exit 0` = PASS（問題なし）
- `exit 1` = ランタイムエラー専用
- `exit 2` = FAIL 検出専用（CRITICAL または ERROR を 1 件以上検出）

全コマンド共通。判断根拠は `memory/project_exit_code_ambiguity.md` に記録。
→ **完了**（severity-unification spec により、2026-04-20）。

### call_claude() のタイムアウト未設定
`call_claude()` に `subprocess.run()` のタイムアウトが設定されていない。Claude CLI がハングした場合、プロセスが無限に待機する。cli-query では応答が速いため顕在化していないが、cli-audit の monthly/quarterly では wiki 全体の分析で30-120秒かかり、リスクが高まる。cli-audit 設計フェーズでタイムアウト値を決定し、`call_claude()` 共通関数に適用する（cli-query にも波及）。
→ **cli-audit で実装済み**: `call_claude()` に `timeout` パラメータを追加（デフォルト None、audit は 300 秒）。

### rw_light.py のモジュール分割
cli-audit 実装後の rw_light.py は 3,490 行に達し、保守限界の目安（3,000 行）を超過した。現時点の roadmap（test-suite が最後のスペック）では rw_light.py への大規模追加は予定されていないため即座の分割は不要だが、新規スペック（CI 統合、マルチユーザー等）が追加される場合はモジュール分割を検討する。自然な分割境界:
- `rw_light.py` → コマンドディスパッチ + main
- `rw_utils.py` → ユーティリティ関数群
- `rw_prompt_engine.py` → Prompt Engine
- `rw_audit.py` → audit コマンド + check 関数群
- `rw_query.py` → query コマンド + query lint

分割時は `rw` シンボリックリンクの仕組み（単一ファイル前提）の変更も必要。

### observability-infra（severity-unification Y Cut 残件）
severity-unification スペック策定時（2026-04-20）の本質観点レビューで Core-only スコープ（Y 選択）を確定したことに伴い、以下の投機的 observability / 品質 infra 項目を別スペックに分離:
- JSON schema versioning（`schema_version: "1.0"` → `"2.0"` bump policy、forward-compat window）
- drift 可視化の拡張（`MAX_DRIFT_EVENTS=100` cap、cap-reached sentinel、3 段 stderr collapse、`_emit_drift_summary` invocation end summary）
- strict mode（`--strict-severity` / `RW_STRICT_SEVERITY`）および dry-run mode（`--validate-vault-only`）
- `write_log_atomic` helper（`logs/` 配下の tempfile + os.replace 方式、crash recovery + cross-filesystem 失敗検出）
- property-based cross-channel invariant test（stdout / markdown / JSON / stderr の 4 チャネル整合性、500 random cases）
- Turkish locale regression（`LC_ALL=tr_TR.UTF-8` での severity token upper() / lower() 壊れ regression）
- coverage gate（`.coveragerc` + pytest-cov 統合、line ≥ 90% / branch ≥ 85% / function ≥ 100% target）
- flakiness detection（pytest-repeat で subprocess test を 10 回繰り返し、flaky 検出 + mitigation）
- `.git-blame-ignore-revs` 運用（mechanical commit の blame 保全）

着手タイミング: drift 実例観察（`drift_events[]` が複数運用サイクルで出現） or 下流 JSON consumer 特定（外部ダッシュボード / CI metrics 集計ツールから `logs/*_latest.json` を parse する利用者が現れる） or test suite flakiness の実報告、のいずれかが顕在化した時点で起草。severity-unification 本体完了後でも独立着手可能。

### vault-migration-framework（既存 Vault マイグレーション共通基盤）

スキーマ・フォーマットの破壊的変更（frontmatter フィールド変更、JSON ログ schema バージョンアップ、severity 体系変更、命名規約変更等）に対する、**既存 Vault の自動マイグレーション共通基盤**は未整備。これまでは個別スペックで対応してきた:

- `severity-unification`（2026-04-20 完了）: AGENTS 語彙 rename、CLI の exit code 契約統一。既存 JSON ログ互換性を個別に配慮した設計。
- `rw-light-rename`（2026-04-21 完了）: エントリポイントのファイル名変更に対応する `--reinstall-symlink` を個別に実装。

将来的に必要になりうる共通基盤:
- `rw migrate <from-version> <to-version>` 専用コマンド
- Vault 側の state version（`.rw-version` ファイル等）による自動マイグレーション検出
- 破壊的変更を伴うスペックでの「マイグレーションガイド」標準フォーマット
- `CHANGELOG.md` 記載の移行手順と実装の乖離検出（documentation drift prevention）

着手タイミング: 3 つ目以降の破壊的変更スペックが起草される、もしくは外部ユーザーの実運用 Vault で手動マイグレーションの負担が顕在化した時点。それまでは**個別スペックごとに `CHANGELOG.md` と `requirements.md` に移行手順を明記する**運用を維持する（user-guide.md §システム更新時の運用 ④ の方針と整合）。

## Governance

### Adjacent Spec Synchronization

後続スペックによる**完了済みスペックの `requirements.md` / `design.md` の整合更新**は、再 approval を要求しない。対象スペックの `spec.json.updated_at` を更新し、各 `requirements.md` の末尾 `_change log` に 1 行追記するだけで足りる。

**適用条件**: 更新内容が「先行スペックの変更による波及的な文言同期」であり、要件・設計の実質変更ではないこと。

**根拠**: severity-unification spec が cli-audit / cli-query / test-suite の `requirements.md` を整合更新した際に確立した運用ルール（2026-04-20）。

### rw_light.py 行数（2026-04-20 時点）

severity-unification 実装後: 約 3,650 行（保守限界 3,000 行を超過継続）。モジュール分割の優先度は据え置き（新規スペック追加または flakiness 顕在化まで）。

## Specs (dependency order)
- [x] project-foundation -- `rw init`コマンド（Vaultセットアップ・Git初期化）・Wiki用CLAUDE.mdカーネル・templates/配置. Dependencies: none
- [x] agents-system -- AGENTS/サブプロンプト体系（9タスク用エージェント定義 + ポリシー系配置）. Dependencies: project-foundation
- [x] cli-query -- query_answer, query_extract, query_fixコマンドの実装. Dependencies: project-foundation, agents-system
- [x] cli-audit -- auditコマンド（micro/weekly/monthly/quarterly監査）の実装. Dependencies: project-foundation, agents-system
- [x] test-suite -- rw_light.py全コマンドのテスト体系構築. Dependencies: project-foundation, cli-query, cli-audit
- [x] severity-unification -- AGENTS と CLI を 4 水準（CRITICAL/ERROR/WARN/INFO）で align、`AGENTS/audit.md` の HIGH/MEDIUM/LOW を ERROR/WARN/INFO に rename、`rw lint` / `rw lint query` / `rw query extract` / `rw query fix` の severity・status・exit code を統一（PASS/FAIL、exit 0/1/2）。`map_severity()` を identity 化、sub_severity タプル廃止、exit 1/2 分離（exit 1=runtime error、exit 2=FAIL 検出）。Dependencies: cli-audit（変更対象）, agents-system（AGENTS rename 対象）, cli-query, test-suite
- [x] module-split -- `scripts/rw_light.py`（3,490 行）を責務別 6 モジュールに分割（`rw_config` / `rw_utils` / `rw_prompt_engine` / `rw_audit` / `rw_query` / `rw_light` エントリポイント）。re-export ゼロ方針（bridge ファイル禁止）、DAG 依存方向の厳守。Dependencies: severity-unification
- [x] rw-light-rename -- `scripts/rw_light.py` → `scripts/rw_cli.py` への命名整合リファクタリング。module-split 完了後に `light` 接頭辞が実態と乖離したため、6 モジュール共通の `rw_<責務>.py` 命名パターンに統一。`cmd_init --reinstall-symlink` による既存 Vault マイグレーションヘルパを同時追加。Dependencies: module-split
