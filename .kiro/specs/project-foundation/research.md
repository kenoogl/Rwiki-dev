# Research & Design Decisions

## Summary
- **Feature**: `project-foundation`
- **Discovery Scope**: Extension（既存 `scripts/rw_light.py` に `init` サブコマンドを追加）
- **Key Findings**:
  - rw_light.py は `ROOT = os.getcwd()` パターンで動作し、手動argv解析を使用。新コマンドも同パターンに従う
  - `docs/CLAUDE.md` にWiki運用カーネルの素案が既に存在し、これを `templates/CLAUDE.md` のベースにできる
  - 開発リポジトリのパスは `Path(__file__).resolve().parent.parent` で導出可能（scripts/rw_light.py の2階層上）

## Research Log

### 既存CLIアーキテクチャの分析
- **Context**: `cmd_init()` を既存コードに統合する方法の調査
- **Sources Consulted**: `scripts/rw_light.py`（1041行）
- **Findings**:
  - コマンドは `cmd_<name>()` 関数パターンで実装（cmd_lint, cmd_ingest, cmd_synthesize_logs, cmd_approve, cmd_lint_query）
  - `main()` で `sys.argv[1]` を分岐、戻り値を `sys.exit()` に渡す
  - 外部ライブラリ不使用（stdlib only: os, shutil, subprocess, json, re, sys, pathlib, datetime, unicodedata, typing）
  - `ensure_dirs()` で必要ディレクトリを作成するパターンが存在
  - `write_text()` は親ディレクトリを自動作成する
  - `read_text()`, `write_text()`, `relpath()`, `slugify()` など汎用ユーティリティが充実
- **Implications**: `cmd_init()` も同パターンで実装し、stdlibのみ使用する

### 開発リポジトリパスの導出方法
- **Context**: `cmd_init()` がtemplates/を見つける方法
- **Findings**:
  - rw_light.pyは `scripts/` に配置。`Path(__file__).resolve().parent.parent` で開発リポジトリルートを取得可能
  - シンボリックリンク経由の呼び出しでも `resolve()` が実パスを返すため、常に開発リポジトリを指す
  - これにより `templates/CLAUDE.md` や `templates/AGENTS/` のパスを確実に構築できる
- **Implications**: ハードコードやenv変数不要。`__file__` ベースで安全に導出

### Vault検出と上書き防止
- **Context**: 既存Vaultへの再実行時の振る舞い
- **Findings**:
  - 要件では「CLAUDE.mdまたはindex.mdが存在する場合」を検出条件としている
  - 上書き確認はユーザインタラクション（`input()`）が必要
  - 既存の `index.md`, `log.md` は保護（上書きしない）
  - 既存の `.git/` はGit初期化をスキップ
- **Implications**: 検出→確認→スキップのフローを段階的に実装

### テンプレートカーネル内容の検証
- **Context**: `docs/CLAUDE.md` の内容が仕様案のグローバルルールを網羅しているか
- **Sources Consulted**: `docs/CLAUDE.md`（207行）、`docs/Rwiki仕様案.md`
- **Findings**:
  - docs/CLAUDE.md は仕様案のグローバルルール6項目（rawの完全性、reviewの強制、承認要件、書き込み権限、インデックスとログ整合性、コミット分離）をすべて含む
  - タスク分類9種、Task→AGENTSマッピング、実行モデル（実行宣言、マルチステップルール）、失敗条件も含まれている
  - 内容は要件2の受入基準2.2〜2.4を満たしている
- **Implications**: docs/CLAUDE.md をそのまま templates/CLAUDE.md のベースとして使用可能

### 既存ディレクトリパス定数の分析
- **Context**: rw_light.py 内で定義されているディレクトリパス定数との整合性確認
- **Findings**:
  - 既存定数: RAW, INCOMING, LLM_LOGS, REVIEW, SYNTH_CANDIDATES, QUERY_REVIEW, WIKI, WIKI_SYNTH, LOGDIR
  - 仕様案のディレクトリ構成に対して、rawのサブディレクトリ（articles, papers/*, meeting-notes, code-snippets）の定数は未定義
  - wikiのサブディレクトリ（concepts, methods, projects, entities/*）の定数も未定義
  - initコマンドではこれらすべてを作成する必要がある
- **Implications**: VAULT_DIRS 定数としてinit用のディレクトリリストを別途定義する

## Design Decisions

### Decision: コマンド引数の解析方式
- **Context**: `rw init [path]` の引数解析
- **Alternatives Considered**:
  1. argparseサブパーサー導入 — 型安全だが既存コードと不整合
  2. 既存の手動argv解析パターン踏襲 — 一貫性が高い
- **Selected Approach**: 手動argv解析を踏襲
- **Rationale**: 既存5コマンドすべてが手動解析。argparse導入はスコープ外のリファクタリングになる
- **Trade-offs**: 将来的にはargparse移行が望ましいが、本スペックでは一貫性を優先

### Decision: templates/CLAUDE.md のソース
- **Context**: Wiki運用カーネルの正式版をどこから作るか
- **Alternatives Considered**:
  1. docs/CLAUDE.md をそのままコピー — 素案がそのまま使える
  2. ゼロから書き直し — 仕様との完全整合が保証される
- **Selected Approach**: docs/CLAUDE.md をベースに templates/CLAUDE.md として配置
- **Rationale**: docs/CLAUDE.md は既に仕様案との整合性が確認済み
- **Trade-offs**: agents-systemスペックで後続の微調整が入る可能性あり

### Decision: シンボリックリンクのパス形式
- **Context**: Vault内の `scripts/rw` → 開発リポの `scripts/rw_light.py`
- **Alternatives Considered**:
  1. 絶対パス — 確実だがポータビリティに劣る
  2. 相対パス — ポータブルだが計算が複雑
- **Selected Approach**: 絶対パス（resolve済み）
- **Rationale**: 開発リポとVaultは異なるディレクトリツリーにあるため、相対パスの利点がない。絶対パスが最もシンプルで確実
- **Trade-offs**: マシン間の移植性は低いが、個人開発環境では問題なし

### Decision: VAULT_DIRSの定義方式
- **Context**: initで作成するディレクトリ一覧をどう管理するか
- **Alternatives Considered**:
  1. cmd_init内にリストをハードコード — シンプルだが保守性低い
  2. モジュールレベル定数として定義 — 既存パターンと一貫
  3. 外部設定ファイルで管理 — 柔軟だが過剰
- **Selected Approach**: モジュールレベルのリスト定数 `VAULT_DIRS` として定義
- **Rationale**: 既存のRAW, REVIEW等の定数パターンと一貫。ただしinitは任意パス対象のため、ROOT相対ではなく相対パスのリストとして定義し、init実行時にターゲットパスと結合する
- **Trade-offs**: ディレクトリ構成変更時はコード修正が必要だが、頻度は低い

## Synthesis Outcomes

### 一般化
- ディレクトリ作成は `ensure_dirs()` の既存パターンを拡張するのではなく、init専用の `VAULT_DIRS` リストを定義する。ensure_dirsは既存コマンド用で、initの全ディレクトリリストとは責務が異なる
- テンプレートコピーは `shutil.copytree`（AGENTS/）と `shutil.copy2`（CLAUDE.md）の使い分けで対応

### 構築 vs 採用
- 全て stdlib で実装。新規外部ライブラリは不要
- Git操作は既存の `subprocess.run(["git", ...])` パターンを踏襲

### 簡素化
- Vault検出は `CLAUDE.md` または `index.md` の存在チェックのみで十分（設定ファイルベースの検出は過剰）
- セットアップレポートは print 文による簡潔な出力で十分（構造化ログは不要）

## Risks & Mitigations
- `__file__` が凍結バイナリで動作しない — 現状Python直接実行のため問題なし
- シンボリックリンクがWindows未対応 — 制約として明記（macOS/Linux前提）
- templates/AGENTS/ が初回init時は空 — agents-systemスペック完了後に再度 `rw init` で更新可能な設計にする
- `input()` によるユーザ確認がCI環境で問題になる可能性 — `--force` フラグの追加は将来の拡張とし、本スペックでは対話的確認のみ
