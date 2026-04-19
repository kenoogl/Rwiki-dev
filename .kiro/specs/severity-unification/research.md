# Gap Analysis: severity-unification

調査日: 2026-04-19
対象 requirements: `.kiro/specs/severity-unification/requirements.md`（2026-04-19T10:30:00Z 時点）

## 1. Current State Investigation

### 1.1 プロジェクト構造と技術スタック

- **言語・依存**: Python 3.10+、標準ライブラリのみ（zero-dependency）
- **CLI 実装**: 単一モノリシック `scripts/rw_light.py`（3,490 行）— ポータビリティ重視
- **テスト**: pytest、コマンド別に `tests/test_*.py` に分割済（test-suite スペックで整備完了）
- **プロンプト**: `templates/AGENTS/*.md`（dev master）→ `rw init` で Vault の `AGENTS/*.md` に deploy
- **ログ**: `logs/*_latest.json` 構造化出力

### 1.2 severity / status / exit code 関連の現行実装マップ

| 領域 | 関数 / 位置 | 現状 | 本スペック変更要否 |
|---|---|---|---|
| severity 変換 | `map_severity()` L1696-1715 | `(cli_severity, sub_severity)` タプル返却、4→3 mapping、L1713-1715 で INFO silent fallback | **必須**（identity 化 / 廃止 + fallback 置換） |
| severity validation | `parse_audit_response()` L1838-1920、`_VALID_SEVERITIES` L1866 | 現行は `{CRITICAL, HIGH, MEDIUM, LOW}`（AGENTS 旧語彙）、不正値は L1904-1907 で `[WARN]` を stdout に print しつつ L1908 `continue` で finding を drop（stderr ではなく stdout である点・drop 後に集計から消える点が AC 1.9 の「drift 可視化」要件で問題） | **必須**（値域 rename、stdout→stderr 化、drop → 設計確定の fallback policy 適用） |
| lint status 判定 | `cmd_lint()` L317-366 | PASS/WARN/FAIL 3 値、`summary: {pass, warn, fail}`、L366 で FAIL → `exit 1` | **必須**（PASS/FAIL 2 値 + exit 2） |
| lint JSON schema | L356-360 | `{files: [...], summary: {pass, warn, fail}}` | **必須**（summary キー設計要確定） |
| lint_query status 判定 | `cmd_lint_query()` L3034-3106 / `lint_single_query_dir()` L2901-3009 | PASS/PASS_WITH_WARNINGS/FAIL、L3099-3105 で status ベース exit 0/1/2（L3104 WARN → exit 1、L3103 FAIL → exit 2）、引数パース不正で exit 3（L3048/L3056/L3063）、target path 不在で exit 4（L3078） | **必須**（PASS_WITH_WARNINGS 廃止、exit 1（WARN）廃止、exit 3/4 を `cmd_lint_query()` 内で exit 1 に統合） |
| audit micro / weekly | `cmd_audit_micro()` L2112-2179、`cmd_audit_weekly()` L2185-2275 | Finding.severity = ERROR/WARN/INFO（3 水準）、ERROR 検出で `exit 1` | **必須**（CRITICAL 追加、exit 1 → exit 2） |
| audit monthly / quarterly | `_run_llm_audit()` L2281-2388 | Claude 応答を `map_severity()` で 3 水準に変換、ERROR 検出で `exit 1` | **必須**（identity 通過、exit 1 → exit 2） |
| ingest precondition | `cmd_ingest()` L404-409 | `lint_latest.json` の `summary["fail"] > 0` 参照 → abort + `exit 1` | **部分的**（summary キー設計に追随、exit 1 は維持） |
| query extract / fix | `cmd_query_extract()` L2694-2704、`cmd_query_fix()` L3213-3224 | `lint_single_query_dir()` 呼び出し後 status == "FAIL" で `return 2` | **必須**（上流 status 2 値化に追随、exit 2 semantics は維持） |
| Claude プロンプト | `build_audit_prompt()` L1718+ | severity 語彙の明示指示なし（AGENTS に依存） | **必須**（新 4 水準明示、旧語彙禁止指示） |
| AGENTS 読み込み | `load_task_prompts()` L846-886 | FileNotFoundError のみ handle、旧語彙残存 validation なし | **必須**（AC 8.6 Vault validation 新規追加） |

### 1.3 テストコードの現状（test-suite 完了済）

- `tests/test_rw_light.py`: L4243-4269 で `map_severity()` 4 パターン検証（旧タプル返却）、L4418 で severity 4 値検証
- `tests/test_lint.py`: L23, 44, 65, 118-143 で exit 0/1 検証（FAIL → exit 1）
- `tests/test_lint_query.py`: L66-96 で exit 0/1/2 検証（L74 で WARN → exit 1、L92 で ERROR → exit 2、L98-107 で exit 3/4）
- `tests/test_ingest.py`: L68 で FAIL → exit 1 検証
- 旧 status `PASS_WITH_WARNINGS` 参照: `test_rw_light.py` L2193, L2233

### 1.4 templates/AGENTS/ の現状（実ファイル突合済）

**注**: `templates/AGENTS/audit.md` は日本語セクション見出しで構成されており、独立した英語節（`# PRIORITY LEVELS` 等）は含まない。英語テキストは `### 出力フォーマット` 節内のコードサンプル（`## Summary`、`- critical:` 等）にのみ現れる。これは `docs/audit.md` が独立した英語セクション（L85-92 `# PRIORITY LEVELS` 等、§1.5 参照）を持つ構造と対照的。

- `audit.md`:
  - **L40-74 出力フォーマット**（日本語セクション見出し + 英語サンプルコード）: コードブロック内で `## Summary` リストに `- critical:` / `- high:` / `- medium:` / `- low:`（L47-50）、Findings 例に `[CRITICAL]` / `[MEDIUM]` / `[HIGH]` マーカー（L53-58）— AC 1.2 の rename（旧語彙 `HIGH`/`MEDIUM`/`LOW` → `ERROR`/`WARN`/`INFO`）を適用
  - **L140-147 優先度レベル**（日本語 4 段階表）: `CRITICAL` / `HIGH` / `MEDIUM` / `LOW` の定義表（データ行 L144-147） — AC 1.2 で rename
  - 英語版の独立節（`# PRIORITY LEVELS` 等）は本ファイルには存在しない（それは `docs/audit.md` L85-92 側、§1.5 参照）
- `lint.md`:
  - **L32-34 終了コード**: `0` / `1` のみ記載（exit 2 なし）— AC 1.8 (b) で新 3 値体系に更新
  - **L44 status スキーマ**: `"PASS | WARN | FAIL"` — AC 1.8 (a) で `"PASS | FAIL"` に更新
  - **L50 summary 構造**: `{pass, warn, fail}` — Design constraint「`lint` JSON の `summary` キー構成」確定後に追随
  - 「判定レベル PASS / WARN / FAIL」節 — AC 1.8 (c) で status（PASS/FAIL）と severity（4 水準）の 2 次元構造に再構成
- `ingest.md` / `git_ops.md`: FAIL 件数参照（概念は新体系でも不変、文法 verify のみ）

### 1.5 docs/ の現状（実ファイル突合済、subagent 誤認を訂正）

| ファイル | 行番号 | 現状 | 備考 |
|---|---|---|---|
| `docs/user-guide.md` | L408-415 | **`[verified]` severity マッピング表「Claude 内部 4 段階 → CLI 3 水準」(CRITICAL/HIGH→[ERROR]、MEDIUM→[WARN]、LOW→[INFO])** | **cli-audit の 3 水準マッピング表が残存**。subagent B の「対応済」報告は誤認。新 4 水準 identity 表への差し替え必須 |
| `docs/user-guide.md` | L126, 310 | lint / audit の「exit 0/1」記述 | AC 6.4 で exit 2 導入、移行ノートを付加 |
| `docs/user-guide.md` | L245, 296 | query extract / fix exit 0/1/2 | 意味論的には新体系と整合、文言 sync のみ |
| `docs/audit.md` | **L89-92** | **`[verified]` PRIORITY LEVELS 表**（`CRITICAL` / `HIGH` / `MEDIUM` / `LOW`、独立した英語版としてAGENTS/audit.md の日本語「優先度レベル」と同じ 4 段階を定義） | AC 1.2 の rename に追随必要。templates/AGENTS/audit.md の Japanese 側 rename と同時に docs/audit.md の English 側も rename する必要あり（ソース同期の整合方針は Design constraint で確定） |
| `docs/audit.md` | **L152-157** | **`[verified]` 出力例のマーカー** `[CRITICAL]` / `[HIGH]` / `[MEDIUM]` | rename 必須 |
| `docs/lint.md` | L32-34 相当 | exit 0/1 記述のみ | AC 6.4 で exit 2 追加 |
| `docs/ingest.md` / `docs/query.md` / `docs/query_fix.md` | — | status/exit 参照 | lint 結果参照の文言 sync 対象 |
| `CHANGELOG.md` | — | cli-audit スペック時の 3 水準記述 | R6.2 で本スペック完了時に破壊的変更追記 |

`[verified]` は 2026-04-19 時点で実ファイル L 番号 + 内容を確認済みの項目。他項目は subagent 報告のままであり、design フェーズで再確認推奨。

## 2. Requirements Feasibility Analysis

### 2.1 Requirement-to-Asset Map

| Req | 要件 | 現行 asset | gap | gap 種別 |
|---|---|---|---|---|
| 1.1-1.4 | 全 CLI で severity 4 水準 | lint / lint query は 3 水準相当（severity 配列分類）、audit は `map_severity()` 出力の 3 水準 | CRITICAL の新設、個別検査項目の severity 再割当 | **Missing** |
| 1.5 | `rw audit` identity mapping、sub_severity 廃止 | `map_severity()` L1696-1715 が (cli, sub) タプル返却 | identity 化、呼び出し側の tuple unpacking 除去 | **Missing** |
| 1.6 | lint / lint query に 4 水準直接割当 | 現行は `errors`/`warnings`/`fixes` 配列分類（値域は 3 水準相当） | 各検査項目への CRITICAL/ERROR/WARN/INFO 直接付与 | **Unknown**（割当は設計で確定） |
| 1.7 | AGENTS↔CLI 1:1 align | `map_severity()` が変換している時点で不一致 | `_VALID_SEVERITIES` を新 4 水準に rename + identity 化 | **Missing** |
| 1.8 | AGENTS/lint.md 更新 | 現行 `"PASS \| WARN \| FAIL"`、exit 0/1 | 新 2 値 + 3 値 exit に書き換え | **Missing** |
| 1.9 | drift 可視化（silent fallback 禁止） | L1713-1715 INFO silent fallback（AC 1.9 違反、§1.2 参照）、L1904-1907 で `[WARN]` を stdout に print + L1908 `continue` で finding drop（stderr ではなく stdout、かつ drop で集計から消える点が AC 1.9 違反） | stderr 記録 + drop 廃止 + 設計確定の fallback 挙動（(C) INFO 降格 / (D) ERROR 昇格 / (B) strict exit） | **Missing** |
| 2.1-2.9 | status 2 値統一 | lint 3 値、lint query 3 値、audit 2 値 | PASS_WITH_WARNINGS 廃止、lint の WARN 廃止、audit は OK | **Missing** |
| 3.1-3.7 | exit 0/1/2 分離 | lint・audit は 0/1、lint query・query extract/fix は 0/1/2、`rw lint query` のみ引数エラー系で exit 3/4 も使用 | rw lint / rw audit の exit 1（FAIL）→ exit 2 移行、`rw lint query` の exit 3/4（引数パース不正・target 不在）を exit 1 に統合 | **Missing** |
| 4.1-4.6 | 構造化出力の値域統一 | `lint_latest.json` summary に warn キー、`query_lint_latest.json` に PASS_WITH_WARNINGS | schema 更新 | **Missing** |
| 5.1-5.5 | 標準出力統一 | 既存サマリーフォーマットは 3 水準ベース | 4 水準サマリー + status 併記 | **Missing** |
| 6.1-6.5 | ドキュメント統一・CHANGELOG・Vault 再デプロイ | docs は cli-audit 前提、CHANGELOG 未更新 | 全更新 | **Missing** |
| 7.1-7.10 | テスト | 旧値期待が残存（~20 箇所）、Vault validation / drift テストなし | 書き換え + 新規追加 | **Missing** |
| 8.1 | ingest precondition abort | `summary["fail"] > 0` で abort + exit 1 | 新 status 体系（summary キー設計次第） | **Constraint** |
| 8.2 | ingest の status WARN 解釈除去 | grep で status 位置 WARN 解釈なし（subagent 確認） | コード不要だが一貫性のため verify | **None**（既に満たす） |
| 8.3 | query extract/fix の status 2 値判定 | 現行は FAIL 単独判定（PASS_WITH_WARNINGS が通る） | 廃止に伴う判定ロジック整理 | **Missing** |
| 8.4 | 非 status コマンドに発行義務なし | 現行満たす | — | **None** |
| 8.5 | プロンプトに新語彙明示 + 旧語彙禁止 | `build_audit_prompt()` に明示指示なし | プロンプトテキスト更新 | **Missing** |
| 8.6 | Vault validation | `load_task_prompts()` は validation なし | 新規実装 | **Missing** |

### 2.2 Research Needed（設計フェーズで確定）

- AGENTS/audit.md 旧語彙残存の検出アルゴリズム（substring / regex / AST）、検出スコープ（全文 / severity 定義節 / Migration Notes 除外）、検証タイミング（毎回 / キャッシュ / 専用 subcommand）、false positive 回避
- 4 水準外 severity 受信時の fallback 動作（(C) 警告 + INFO 降格 / (D) 警告 + ERROR 昇格 / (B) strict mode）とフラグ名
- `lint_latest.json` `summary` キー構成（(A) warn=0 残置 / (B) キー削除 / (C) 4 水準件数統合）と `cmd_ingest` 参照ロジック追随
- `rw lint` per-file 論理モデル（PASS/FAIL 2 値 / finding レベル管理 / 最重 severity per-file メタ）
- `rw lint` per-file 表示形式、日本語 docs の severity 表記（英字 vs 和訳）
- `audit` Markdown レポートの finding プレフィックス形式（`[CRITICAL]` 単一 / 2 段構造維持）
- `sub_severity` フィールドの schema 存廃（JSON / Markdown）
- `map_severity()` の関数シグネチャ（identity 化 / 削除）
- R7.7 旧値残存の静的スキャン実装（AST / regex / custom lint rule）
- Vault 再デプロイコマンド（`rw init --force` 相当の有無）
- CHANGELOG の記述形式（Keep a Changelog / semver の要否）

### 2.3 Complexity Signals

- **Algorithmic**: 比較的単純（値域 rename + 2 値化 + exit code 分岐）
- **Workflow**: P1-P5 段階移行で各 phase 完了時に green 保証する TDD サイクル
- **External integration**: Claude CLI プロンプト変更 + 応答パース（既存 `_run_llm_audit()` を活かす）
- **File-level impact**: `rw_light.py` の 15 箇所前後、`tests/` の 20 箇所前後、`templates/AGENTS/` 2 ファイル、`docs/` 7 ファイル、隣接スペック 3 件、roadmap 3 箇所、CHANGELOG 新 section

## 3. Implementation Approach Options

### Option A: 既存関数の in-place 拡張（extend）

**アプローチ**: `map_severity()` / `cmd_lint()` / `cmd_lint_query()` / `cmd_audit_*()` をすべて既存シグネチャのまま内部実装を差し替える。

- `map_severity(sev)` を `str` 返しの identity（旧タプル返却は廃止）
- `cmd_lint()` の `summary` 辞書のキー構成だけ変更
- `_VALID_SEVERITIES = {"CRITICAL", "ERROR", "WARN", "INFO"}` に rename
- Vault validation を `load_task_prompts()` 内に追加（audit task 限定）
- drift 可視化を `map_severity()` 内で stderr 記録 + 設計確定の fallback 動作

**Trade-offs**:
- ✅ ファイル数不変、`rw_light.py` のポータビリティ単一ファイル原則を維持
- ✅ 呼び出し側の修正は「unpacking 除去」等の軽微変更で済む
- ❌ `rw_light.py` の行数純増（現在 3,490 行、roadmap L128-136 懸念）
- ❌ `map_severity()` のシグネチャ変更で 20+ 呼び出し箇所の一括更新が必要
- ❌ 段階移行（P1 transitional）には追加 boilerplate が必要

### Option B: 新規ヘルパーモジュール化（create new）

**アプローチ**: severity / status / exit code の共通ロジックを新規関数として切り出す。例:
- `_compute_status(findings) -> Literal["PASS", "FAIL"]`
- `_compute_exit_code(status, runtime_error) -> int`
- `_validate_agents_severity_vocabulary(path) -> None`（AC 8.6）
- `_record_severity_drift(unknown_token) -> str`（AC 1.9）

全コマンドから共通呼び出し。

**Trade-offs**:
- ✅ 単一責任原則に沿い、テスト容易性向上
- ✅ 4 水準ロジックの重複回避、将来の追加コマンドでも再利用可能
- ❌ 単一ファイル集約原則に反するという見方もある（ただし `rw_light.py` 内の内部関数として配置すれば維持可能）
- ❌ 関数群が追加され行数純増リスクは Option A より大きい

### Option C: Hybrid（推奨）

**アプローチ**:
- **コア値域ロジック**は新規ヘルパー関数として切り出す（Option B 的な切り出し、`rw_light.py` 内部関数として）: `_compute_status`、`_compute_exit_code`、`_validate_agents_vocabulary`、`_record_severity_drift`
- **既存コマンド**は in-place 修正（Option A 的）: `cmd_lint` / `cmd_lint_query` / `cmd_audit_*` / `cmd_query_extract` / `cmd_query_fix` / `cmd_ingest` はシグネチャ不変、内部だけ新ヘルパー呼び出しに差し替え
- **`map_severity()`** は identity 化（`str → str`）または関数削除（呼び出し側で AGENTS 出力をそのまま使用） — 設計フェーズで確定
- P1-P5 段階移行を維持: P1 で transitional 実装（新旧両語彙受理）、P2 で identity 化

**Trade-offs**:
- ✅ 値域判定ロジックの重複を排しつつ、コマンドの呼び出し境界は既存維持
- ✅ P1 transitional 段階の保守コスト最小化（ヘルパー内で新旧両対応）
- ✅ Vault validation / drift 可視化は独立関数化してテスト容易性を確保
- ✅ `rw_light.py` の行数純増を抑制（共通化により 20+ 重複箇所を統一）
- ❌ 切り出しと in-place 修正の境界判断が必要（設計フェーズで明示）

## 4. Effort & Risk

### 4.1 Effort: **L（1-2 週間）**

**内訳**:
- P1 AGENTS rename + transitional `map_severity()`: 1 日
- P2 identity 化 + sub_severity タプル廃止 + audit テスト更新: 1.5 日
- P3 lint / lint query status 2 値化 + テスト更新: 2 日
- P4 exit code 分離 + 関連テスト更新: 1.5 日
- P5 docs / CHANGELOG / 隣接スペック sync / Vault validation / drift 可視化 / roadmap: 3 日
- **計 9 日**（バッファ込みで L）

### 4.2 Risk: **Medium**

**根拠**:
- 破壊的変更であるが、**P1-P5 の各 phase で green 境界を保つ TDD 戦略**が requirements Design constraint で確立済み（big-bang migration 回避）
- 既存パターン（既存コマンド、既存テストフィクスチャ、既存 JSON schema）を踏襲する延長線上の作業
- 唯一の新規実装は Vault validation（AC 8.6）と drift 可視化（AC 1.9）だが、いずれも境界の限定された独立ロジック
- 懸念: Claude CLI の応答が AGENTS rename 後も旧語彙に drift するリスク（AC 8.5 + 8.6 + 1.9 の 3 層防御でカバー）
- `rw_light.py` 行数純増（roadmap L128-136 のモジュール分割懸念）は本スペック対象外だが測定・報告が必要

## 5. Recommendations for Design Phase

### 5.1 推奨アプローチ

**Option C（Hybrid）を採用**:
- ヘルパー関数 `_compute_status` / `_compute_exit_code` / `_validate_agents_vocabulary` / `_record_severity_drift` を `rw_light.py` 内部に切り出し
- 既存コマンドのシグネチャ不変、内部のみ差し替え
- `map_severity()` の扱い（identity 化 or 削除）は設計フェーズで確定

### 5.2 設計で確定すべき主要決定（優先順）

1. **`map_severity()` の最終形態**: identity 関数として保持するか削除するか。呼び出し側の 2+ 箇所への影響を設計ドキュメントで明示
2. **`_VALID_SEVERITIES` の新語彙**: `{"CRITICAL", "ERROR", "WARN", "INFO"}` への rename（旧 `HIGH/MEDIUM/LOW` 検出時の動作を AC 1.9 fallback policy と整合させる）
3. **`summary` キー構成**: `lint_latest.json` の `{pass, warn, fail}` → (A) `{pass, fail}` / (B) `{pass, fail, counts: {critical, error, warn, info}}` / (C) 4 水準 finding 件数のみ。`cmd_ingest` の参照ロジック追随とセットで確定
4. **`rw lint` per-file 論理モデル**: run-level `PASS/FAIL` + per-file severity 集計 vs per-file status（PASS/FAIL） + finding
5. **Vault validation 検出方式**: substring / word boundary regex / セクション指定。Migration Notes ブロックの除外方針
6. **drift fallback 挙動**: (C) 警告 + INFO 降格（デフォルト推奨） / (D) 警告 + ERROR 昇格 / (B) strict mode フラグ名
7. **`exit 3/4` の `rw lint query` からの除却**: 引数パースエラー・パス不在を exit 1 に統合する実装方式（argparse 層での統一 vs 各 cmd 内の return 1）
8. **Claude プロンプトの新語彙明示形式**: `_run_llm_audit()` 内のプロンプト組み立て関数での反映位置（AGENTS 本文を信頼 vs プロンプト冒頭で instruction 挿入）
9. **docs/user-guide.md L408-415 の severity 表の再書換**（検証済）: cli-audit の 3 水準マッピング表が実在することを 2026-04-19 に確認済み。4 水準 identity 表（`CRITICAL` / `ERROR` / `WARN` / `INFO` を Claude 内部・標準出力・レポートで同一値）に置換
10. **docs/audit.md L89-92 / L152-157 の更新**（検証済）: templates/AGENTS/audit.md（Japanese「優先度レベル」表・L140-147、および `### 出力フォーマット` 内の英語サンプルコード・L40-74）と docs/audit.md（独立した英語 `# PRIORITY LEVELS` 表・L85-92 および出力例マーカー・L152-157）はそれぞれ独立して rename する必要がある。docs は AGENTS 本文の逐語転記ではなく独立した英語版として記述されているため、設計フェーズで同期ルール（docs 側を AGENTS 側の英訳とみなすか、独立 maintain とするか）を確定する

### 5.3 Research Items Carry-Forward（設計で未解決の場合 design.md で再提起）

- `rw lint` の per-file 表示形式（Design constraint 済）
- `audit` 構造化出力の `sub_severity` フィールド存廃（Design constraint 済）
- CHANGELOG 記述形式（Design constraint 済）
- Requirement↔Design↔Tasks トレーサビリティマトリクス（Design 作成時に構築）

### 5.4 実装戦略の再確認

Requirements Design constraint「移行実装順序」の P1-P5 を `tasks.md` のフェーズ区切りとして採用することを推奨。各 phase で:
- Phase 冒頭: 対象 AC のテストを新体系に書き換え → red 確認
- Phase 中: 実装更新
- Phase 末尾: テスト全件 green 確認 + commit

この TDD cycle と Option C のヘルパー関数切り出しを組み合わせることで、revert 可能性と保守性を両立できる。
