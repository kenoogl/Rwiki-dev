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

---

## 6. Design Synthesis（2026-04-19 追記）

`design.md` 策定前に、Design Synthesis の 3 レンズ（Generalization / Build-vs-Adopt / Simplification）を discovery 成果に適用した結果を記録する。

### 6.1 Generalization

- **Req 1-5 の共通核**: 全 CLI で同一 vocabulary（severity 4 / status 2 / exit 3）を揃える。コマンドごとに分散した判定ロジックを、`_compute_run_status()` / `_compute_exit_code()` の 2 つの共通ヘルパーに一般化する（コマンドは findings を渡すだけ）
- **Req 8.5 / 8.6 / 1.9 の共通核**: severity drift 防御の 3 touchpoint（プロンプト / ファイル / ランタイム）。名前付き戦略 `SeverityDriftDefense` として design.md で命名統一し、3 層それぞれの責務境界を明示する

### 6.2 Build vs Adopt

- **Python `logging` levels との関係**: `CRITICAL / ERROR / WARNING / INFO / DEBUG` は Python 標準 logging と近似だが、本スペックでは severity を **ドメイントークン**（JSON / Markdown / stdout に書き出す文字列リテラル）として扱うため、logging モジュールは **adopt しない**。`WARN`（`WARNING` ではない）を採用する理由: 既存 `rw lint query` の `checks[].severity = "WARN"` との後方互換（値文字列のみ）および文字数短縮（表示整列）
- **severity 判定の外部ライブラリ**: 採用しない（zero-dependency 原則、tech.md Key Libraries）
- **JSON schema 検証ライブラリ**: adopt しない。本スペックは既存 `json.dump` を維持し、schema は docstring と tests で固定

### 6.3 Simplification

- **`map_severity()` の最終形態**: identity 関数として残すより、**関数自体を削除**し、呼び出し側で AGENTS 出力文字列をそのまま使う方がシンプル。P1 では transitional（旧新両語彙を新語彙に正規化するアダプタ）として一時保持、P2 で削除
- **`sub_severity` タプル**: データ構造から完全廃止（フィールド残置しない）。identity mapping 化により情報落ちなし
- **exit 3 / 4（`rw lint query`）**: exit 1（runtime error 系）に統合。引数パース不正・path 不在は「実行できなかった」カテゴリに該当するため、専用 exit code は不要
- **summary キー構成**: `{pass, fail, severity_counts}` の 1 構造に統合（選択肢 C）。`cmd_ingest` は `summary["fail"] > 0` を参照し続けられるため、下流参照ロジックの破壊的変更を回避
- **drift fallback**: strict mode は **optional flag** として提供（デフォルト = C 案「警告 + INFO 降格」）。常時 strict（B）にはしない。可用性優先（requirements Design constraint の選択基準順位に従う）

### 6.4 設計確定事項（design.md で明示）

上記 synthesis の結論として、requirements.md の Design constraints 12 項目を以下のように設計フェーズで確定する:

| Design constraint | 確定内容 |
|---|---|
| `rw lint` per-file 表示形式 | `[PASS] path (warn: 2, info: 1)` 形式（status + severity 内訳の注釈） |
| `lint` JSON の `fixes` 配列 | 既存フィールドは維持（remediation suggestion として severity とは別概念）。本スペックで存廃判断せず |
| `lint` JSON `summary` キー構成 | `{pass: N, fail: N, severity_counts: {critical, error, warn, info}}` |
| `rw lint` / `rw lint query` の severity 割当 | `lint`: YAML parse 失敗 → CRITICAL、frontmatter 必須項目欠落 → ERROR、link 壊れ → ERROR、命名規則違反 → WARN、推奨タグ欠如 → INFO。`lint query`: 既存 severity 分類を 4 水準化（詳細は design.md §6） |
| exit code 分離実装 | 共通ヘルパー `_compute_exit_code()` が `(status, had_runtime_error)` から exit code を返す |
| R7.7 静的スキャン | regex ベース（AST は過剰）、対象: `scripts/rw_light.py` / `tests/` / `templates/AGENTS/*.md`、対象外: `CHANGELOG.md` / `docs/*.md` Migration Notes 節 |
| `sub_severity` フィールド | JSON / Markdown 両方から完全削除 |
| `map_severity()` シグネチャ | P1 で transitional（旧→新正規化）、P2 で関数削除（呼び出し側は AGENTS 出力を直接使用） |
| `cmd_ingest` lint 参照契約 | `summary["fail"] > 0` を維持（新 summary キー構成で fail カウントが継続） |
| audit Markdown finding プレフィックス | `[CRITICAL]` / `[ERROR]` / `[WARN]` / `[INFO]` の単一 severity 表記（2 段構造廃止） |
| 移行実装順序 | P1-P5 を tasks.md のフェーズ境界として採用、各 phase 完了時に green 保証 |
| 日本語 docs の severity 表記 | 英字まま（`CRITICAL`・`ERROR`・`WARN`・`INFO`）、既存 `docs/audit.md` 前例踏襲 |
| 未知 severity fallback policy | デフォルト (C) 警告 + `INFO` 降格、optional strict mode（`--strict-severity` フラグ）で exit 1 |
| `rw lint` per-file 論理モデル | (C) per-file status = `PASS` / `FAIL` 2 値 + per-file `severity_counts` を保持 |
| CHANGELOG 記述形式 | Keep a Changelog スタイル（既存形式と整合）、semver バージョン番号は付与しない（internal tool） |
| AC 8.6 Vault validation 検出方式 | word boundary regex（`\b(HIGH\|MEDIUM\|LOW)\b`）、scope: severity 定義節と output format 節のみ、timing: 各 `rw audit` 実行時、false positive 回避: Migration Notes ブロック（`<!-- severity-vocab: legacy-reference -->` マーカーで囲まれた範囲）を除外 |
| `docs/audit.md` ↔ `templates/AGENTS/audit.md` 同期ルール | 独立 maintain（docs は英語独立版、templates は dev master）。P1 で両ファイルを同一 commit で更新し、以降は test_agents_vocabulary.py で「両ファイルに旧語彙が残存しないこと」のみを共通保証 |
| Claude プロンプトの新語彙明示形式 | `build_audit_prompt()` の冒頭（AGENTS 本文より前）に明示 instruction ブロックを挿入（AGENTS 本文を信頼するが drift 防御として二重化） |

---

## §7 Essential Design Review Record（本質観点レビュー記録、2026-04-20）

A-M の形式的観点（13）および N-Q の補完観点（4）を適用した後、**design.md の前提・方針そのもの**を問う本質観点レビューを実施した。以下の 4 観点は design を巻き戻さず approval に前進する判断（Option 2）の下で、**将来の再設計トリガー**および**現設計の思想限界の記録**として残す。後続の spec（severity 関連改訂、exit code 再分類、documentation governance 等）の出発点として参照可能。

### §7.1 観点 X: スペック存在の正当性（Existence Justification）

- **X-1 観察された実害の不在**: 現状の severity 混在（PASS/WARN/FAIL × ERROR/WARN/INFO）による incident が brief.md / research.md / memory に記録されていない。本スペックの動機は「cli-audit で発覚した技術負債の解消」「見た目の整合性」であり、実害駆動ではない。将来、観測可能な incident が発生した場合は本スペックの投資対効果が事後検証可能となる。
- **X-2 投資規模と期待リターンの定量化不在**: 2,312 行の設計 × 5 phase × 130+ tests × 74 callsite の投資に対し、期待される CI 誤判定削減数・ドキュメント保守工数削減・運用混乱件数減少 等の定量目標が未定義。**Review Trigger**: 本スペック完了後 6 ヶ月時点で Post-Merge Monitoring の incident 数 0 ならば「美的動機投資」だったと事後認定、今後の類似スペックの着手判断基準を厳格化する。
- **X-3 今 vs 将来の cost-benefit 比較の不在**: cli-audit spec 策定時に「後回し」とした判断と「今実施する」判断の比較が research.md 内で不十分。結果として「今やる」が選ばれているが、機会損失（同期間で他の debt が解消できた可能性）は未評価。

### §7.2 観点 Y: 問題 framing の正確さ（Problem Framing）

- **Y-1 3 変更の束ね化の必然性不在**: 本スペックは「(a) severity 語彙統一」「(b) CRITICAL を CLI に露出」「(c) exit code 3 値化」という**独立した 3 つの変更**を束ねている。技術的には (a) 単独、(b) 単独、(c) 単独で spec 化可能。束ねる合理性（同時実施の方が migration cost が下がる等）が spec 内で証明されていない。
- **Y-2 CRITICAL 可視化の独立議論の不在**: requirements.md で CRITICAL 可視化の是非が単独議論された形跡が薄い。「mapping 削除の副次効果として黙認」された扱いで、運用者が CLI で CRITICAL を区別する必要性の検証が弱い。audit markdown のみで十分な可能性。
- **Y-3 Alternative の不十分な比較**: 以下 3 案の比較が research.md §3 で不十分:
  - **案 A**: 4 水準 CRITICAL/ERROR/WARN/INFO で AGENTS / CLI 両層統一（現設計）
  - **案 B**: 3 水準 ERROR/WARN/INFO + CRITICAL は ERROR のサブカテゴリ扱い（運用者認知負荷最小）
  - **案 C**: AGENTS 内部 4 水準維持 + CLI 出力は mapping で 3 水準（現状維持 + CRITICAL のみ露出）
  - **Review Trigger**: 将来 severity 関連の再設計が必要になった時、本観点を出発点に 3 案の定量比較（運用者アンケート / CI 誤判定データ）を実施

### §7.3 観点 Z: 解決策の本質的妥当性（Solution Soundness）

- **Z-1 CRITICAL vs ERROR 区別の実用性**: syslog（8 水準）/ Python logging（5 水準）の歴史的事実として、運用現場では ERROR と WARN のみが使われ、細分化された水準は dead code になる傾向。本スペックの 4 水準化は「理論上の精度」を上げるが実運用で使われない可能性。**Review Trigger**: Post-Merge Monitoring で 6 ヶ月間 CRITICAL と ERROR の切り分けが運用者の判断に影響した事例が 0 件なら、水準統合の後続 spec を検討。
- **Z-2 Defense-in-Depth の observational evidence 不在**: 3 層防御 + drift_events + 100 cap + sentinel + strict mode + schema_version + Public API Stability Policy + deprecation window は**理論的脅威**への対応であり、observational evidence ゼロ。個人開発 + 社内利用 repo で「外部 consumer 前提の governance」は over-engineering の疑い。**Review Trigger**: 6 ヶ月後 drift_events 記録が `original_token` の種類 < 3 ならば、Vault validation のみ維持 + 他の防御層は簡素化する後続 spec を検討。
- **Z-3 Exit code semantics の非対称性**: `exit 1 = runtime error + precondition failure` と `exit 2 = own FAIL` の混在は反直感。「上流 FAIL を検知して exit 1」vs「自分の FAIL で exit 2」は consumer から見て同じ「FAIL 派生」なのに code が異なる。**Review Trigger**: CI / pre-commit hook で混乱 incident が発生した場合、`exit 3 = precondition failure` 分離または `exit 2 に全 FAIL 統合` への再設計 spec を検討。

### §7.4 観点 W: Phase 分割の必要性（Migration Strategy Soundness）

- **W-1 Phase 分割の over-engineering の疑い**: 個人開発 repo で外部 consumer がいない前提なら、1 big-bang PR + CI green で十分な可能性。5 phase 分割は「各 phase で green-test invariant を維持するコスト」を増やす。**Review Trigger**: P2 atomic removal（F-2 で 6→8 ステップに拡大）が実装段階で 1 PR として review 不能の規模になった場合、big-bang 化の再検討を行う。
- **W-2 Rollback Procedure の観念的保険性**: Rollback Procedure / Validation Checkpoints / Downstream Impact Per Phase（§Migration Strategy の 200+ 行）は「rollback が発動しない前提」の観念的保険。実運用で発動しない場合は dead weight。**Review Trigger**: P5 完了時点で rollback が 1 度も発動しなかった場合、後続 spec で migration section を簡素化するテンプレート改訂を検討。
- **W-3 目的関数の曖昧さ**: 本スペックの最終目的（ユーザ観察性向上 / CI 自動化 / ドキュメント保守性のどれが主目的か）が design.md 冒頭で明示されず、結果として A-Q レビューで機能追加が止まらない（2,131 → 2,312 行）。**Review Trigger**: 将来のスペックテンプレート改訂で「冒頭に目的関数セクション」を必須化する提案の起点として本観点を引用可能。

### §7.5 本レビュー結果の扱い

- **approval 判断**: 本質観点は認識したうえで、既に A-Q の 17 観点で reviewed 済みの **現設計（案 A）で approval へ前進** する（Option 2 選択）。
- **本観点の活用先**:
  1. Post-Merge Monitoring（§Migration Strategy）で観察する兆候の参照元
  2. 将来の severity / exit code / migration 関連 spec の出発点（Y-3 の案 B / C 再評価など）
  3. `.kiro/steering/roadmap.md` の「Review Trigger 集約」節（本スペック完了時に追加を推奨）
- **X-2 の事後検証**: 本スペック完了から 6 ヶ月時点（想定: 2026-10-20 前後）で incident 数 0 ならば、今後の類似スペックでは「実害駆動か美的動機か」の判定を明示的に行うルール（steering レベル governance）を追加する。
