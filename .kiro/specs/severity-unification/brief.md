# Brief: severity-unification

## Problem
Rwiki CLI 群で severity / status / exit code 体系が混在しており、運用者が複数コマンドの出力を横断的に解釈できない。さらに、cli-audit で導入された 3 水準統一方針は AGENTS（`CRITICAL/HIGH/MEDIUM/LOW`）と CLI（`ERROR/WARN/INFO`）の間に永続的な vocabulary マッピングコスト（`map_severity()` 関数、`(cli_severity, sub_severity)` タプル）を残していた。加えて、全コマンドで `exit 1` が「ランタイムエラー」と「FAIL 検出」の両方を意味する曖昧性も未解消（roadmap L113-122 Technical Debt）。本スペックはこれらを一括で解消する。

## Current State
- `rw lint`: status PASS/WARN/FAIL（3 値）、severity は JSON の `errors` / `warnings` / `fixes` 配列分類で表現され status とは独立、exit 0/1（runtime error も FAIL も 1）
- `rw lint query`: status PASS/PASS_WITH_WARNINGS/FAIL（3 値）、checks[].severity ERROR/WARN/INFO、exit 0/1/**2**
- `rw query extract` / `rw query fix`: 内部で `lint_single_query_dir()` を呼び FAIL なら exit 2
- `rw audit`（cli-audit 実装済み）: severity ERROR/WARN/INFO（CRITICAL/HIGH/MEDIUM/LOW から 4→3 マッピング + `sub_severity` タプル）、status PASS/FAIL、exit 0/1（runtime error も FAIL も 1）
- `AGENTS/audit.md`（Claude 内部分類）: CRITICAL/HIGH/MEDIUM/LOW（4 段階）

判断根拠（4 水準選択、業界標準整合、exit 0/1/2 分離のタイミング）は `memory/project_severity_system.md` および `memory/project_exit_code_ambiguity.md` に記録済。

## Desired Outcome
- AGENTS と CLI が **同名 4 水準**（`CRITICAL` / `ERROR` / `WARN` / `INFO`）を使用（`map_severity()` は identity 関数に簡略化、sub_severity タプル廃止）
- 全コマンドで status が `PASS` / `FAIL` の 2 値に統一（`PASS_WITH_WARNINGS` 廃止、`rw audit` 含む全 status 発行コマンドで `CRITICAL` または `ERROR` を 1 件以上検出すると `FAIL`）
- 全コマンドで exit code が **`0`（PASS）/ `1`（runtime error / precondition 不成立）/ `2`（自身の finding 由来の FAIL 検出）** に統一
- AGENTS/audit.md 内の severity 名称が `HIGH`→`ERROR`、`MEDIUM`→`WARN`、`LOW`→`INFO` に rename（`CRITICAL` は維持）
- JSON ログ・Markdown レポート・標準出力・ドキュメント・テストが統一語彙のみ使用
- severity drift 対策として 3 層防御を確立: (a) Claude プロンプトへの新語彙明示指示（事前防御）、(b) `rw audit` 起動時の旧語彙残存 Vault validation（事前防御、旧 Vault + 新 CLI の drift 阻止）、(c) 4 水準外 severity 受信時の drift 可視化（検知、silent fallback を禁止）
- roadmap Technical Debt L99-111（severity 統一）と L113-122（exit 1 分離）の両エントリが本スペック 1 つで解消される
- 既存スクリプトの後方互換性は提供しない（クリーンカット）

## Approach
**AGENTS と CLI の vocabulary を完全 align する**。`CRITICAL` は AGENTS のまま保持、`HIGH/MEDIUM/LOW` を CLI と同じ `ERROR/WARN/INFO` に rename。これにより `map_severity()` は identity mapping となり、`sub_severity` タプル方式は不要になる。cli-audit Req 10「AGENTS 正規ソース化」はむしろ強化される（CLI が AGENTS 出力をそのまま提示）。

**exit code を 3 値に分離する**: `exit 0` = PASS、`exit 1` = runtime error 専用、`exit 2` = FAIL 検出専用。roadmap L113-122 の「将来別スペックで exit 1/2 分離」を本スペックに取り込み、破壊的変更を 1 回で終わらせる。

`rw lint` / `rw lint query` は Python 静的チェックなので、個別検査項目に 4 水準を直接割り当てる（CRITICAL 例: YAML パース不能、pre-condition 違反）。テストは旧値（`PASS_WITH_WARNINGS`、status 位置の `WARN`、AGENTS の `HIGH/MEDIUM/LOW`、旧 exit code で FAIL を `exit 1` とする箇所）を新体系に書き換え、旧値リテラルが残存しないことを静的スキャンで検証する。

**完了済の governance 更新**: `roadmap.md` の Specs (dependency order) リストへの severity-unification エントリ追加（要件策定時に実施済）。

**実装時に追加で必要な同期更新**:
- cli-audit `requirements.md` L18-L27 Severity 体系節および Req 1-4 の各 AC（ERROR → FAIL → 終了コード 1）を 4 水準・exit 0/1/2 体系に更新
- cli-query `requirements.md` R4.7 の「ERROR レベルの FAIL」文言を「CRITICAL または ERROR レベル」に同期
- cli-query `design.md` / `tasks.md` における `exit 2` の意味明文化（FAIL 検出）
- test-suite `requirements.md` Req 4（WARN status・FAIL=exit 1）および Req 8（exit 1/2/3/4）の AC 文言を新体系に更新
- `roadmap.md` Technical Debt L99-111 と L113-122 両エントリの「→ severity-unification で実装済み」flip

## Scope
- **In**: `rw lint` / `rw lint query` の severity・status・exit code 移行、`rw query extract` / `rw query fix` の exit code を新 semantics（FAIL → exit 2）に整合、`rw audit` の severity 変換 identity 化・sub_severity タプル廃止・status 判定ルール明文化（CRITICAL/ERROR → FAIL）、`templates/AGENTS/audit.md` の severity rename（HIGH→ERROR、MEDIUM→WARN、LOW→INFO）、`templates/AGENTS/lint.md` の status・exit code 記述の新体系化（PASS/FAIL 2 値、0/1/2 3 値）、`templates/AGENTS/ingest.md` / `templates/AGENTS/git_ops.md` の FAIL 参照箇所の整合 verify、`rw ingest` の lint 結果参照箇所の判定ロジック調整（status FAIL → exit 1 で precondition 不成立 abort）、`rw lint` / `rw audit` の既存 FAIL→exit 1 を exit 2 に移行、`rw audit` 起動時の Vault validation 追加（`AGENTS/audit.md` の旧語彙 `HIGH`/`MEDIUM`/`LOW` 残存検出 → abort）、drift 可視化実装（4 水準外 severity 受信時の silent fallback 禁止・stderr 記録）、JSON ログ・Markdown レポートの値域更新、標準出力フォーマット統一、ドキュメント更新（user-guide / developer-guide / lint / ingest / audit / query / query_fix / README / CHANGELOG）、CHANGELOG と user-guide への Vault 再デプロイ手順明記（必要に応じて `rw init` の軽微修正も含む）、既存テストアサーション書き換え、新規テスト追加（旧値残存検証、identity mapping、exit code semantics、Vault validation、drift 可視化、非対象コマンドの regression 監視を含む）、roadmap.md 更新（L99-111・L113-122 の完了マーク、L128-136 の行数見積もり refresh、governance 節に「後続スペックによる完了済 requirements.md の整合更新は再 approval 不要」追記）、cli-audit `requirements.md` 本体の 4 水準・exit 0/1/2 体系同期、cli-query requirements R4.7 文言同期 / cli-query design / tasks の同期更新、test-suite `requirements.md` Req 4 / Req 8 の文言同期
- **Implementation strategy**: 運用者視点では破壊的変更は 1 回だが、実装は 5 フェーズ（P1: AGENTS rename + map_severity transitional、P2: identity 化 + sub_severity 廃止、P3: rw lint / rw lint query の status 2 値化、P4: exit code 分離、P5: ドキュメント / 隣接スペック sync / Vault validation / drift 可視化 / roadmap 更新）で段階化し、各 phase 完了時点でテスト全件 green を不変条件とする。big-bang migration のロールバック不能リスクを低減。詳細は requirements.md Design constraints 節
- **Out**: `templates/AGENTS/audit.md` の検査項目本体・Tier 定義・priority 意味付けの変更（severity 名称 rename のみ）、`rw audit` の検査ロジック再実装（既に統一体系）、`rw approve` / `rw synthesize-logs` / `rw query answer` の内部ロジック変更（severity / status を発行しないため）、構造化出力のフィールド名・schema 形状の統一（値域のみ統一）、JSON ログの後方互換モード提供、旧値向け実行時 deprecation 警告、`rw_light.py` のモジュール分割、既存 `logs/audit-*.md` 履歴ファイルの旧体系から新体系への一括変換（履歴は旧体系のまま保持）

## Boundary Candidates
- 4 水準 severity 統一（`CRITICAL` / `ERROR` / `WARN` / `INFO`、AGENTS と CLI で align、1:1 identity）
- status 値域統一（`PASS` / `FAIL` 2 値、`rw audit` 含む全 status 発行コマンドで同一判定ルール）
- exit code 3 値分離（`0` / `1` / `2`、`rw ingest` の precondition 不成立 abort は exit 1）
- `map_severity()` の identity 化と sub_severity タプル廃止
- `AGENTS/audit.md` の severity 名称 rename
- 構造化出力（JSON / Markdown）の値域更新
- 標準出力（人間向けサマリー）の語彙更新
- severity drift 対策 3 層（プロンプト明示指示 + Vault validation + runtime 可視化）
- ドキュメント更新と CHANGELOG への破壊的変更明記、Vault 再デプロイ手順明記
- テストアサーション更新、旧値残存検証、Vault validation テスト、drift 可視化テスト
- 隣接スペック（cli-audit / cli-query / test-suite）と steering（roadmap）の同期更新

## Out of Boundary
- AGENTS の検査項目本体・Tier 定義・priority 意味付けの変更 — severity 名称 rename のみで、検査ロジックは変更しない
- `rw audit` の検査ロジック・Claude プロンプト構造の再実装 — 既に統一体系で実装済み、本スペックは severity vocabulary のみ更新
- `rw approve` / `rw synthesize-logs` / `rw query answer` の内部ロジック変更 — severity / status を自前で発行しないため影響を受けない（ただし exit code 契約 0/1 は適用）
- 構造化出力のフィールド名（キー名）・schema 形状の統一 — 本スペックは値域（severity / status トークン）の統一のみ
- JSON ログの旧値との後方互換モード（legacy キー併記、出力バージョン切替フラグ等）— クリーンカット方式を採用
- 旧値を用いた既存スクリプト向けの実行時 deprecation 警告表示 — クリーンカット方針のため警告出力は行わない（CHANGELOG による周知のみ）
- `rw_light.py` モジュール分割 — roadmap L128-136 で別タイミング判断

## Upstream / Downstream
- **Upstream**: cli-audit（本スペックで `map_severity()` を identity 化する対象、既に 3 水準体系で実装済）
- **Downstream**: 将来の CI/CD 統合スペック、ダッシュボード機能（本スペック完了により統一された severity / exit code semantics を前提に構築可能）

## Existing Spec Touchpoints
- **Modifies**:
  - cli-audit（severity 変換を 4→3 マッピング + sub_severity タプルから 4→4 identity に簡略化、exit code の FAIL=1 を FAIL=2 に移行、`requirements.md` 本体 L18-L27 Severity 体系節および Req 1-4 各 AC の文言同期）
  - agents-system（`templates/AGENTS/audit.md` の severity 名称 rename、`templates/AGENTS/lint.md` の status・exit code 記述の新体系化、`templates/AGENTS/ingest.md` / `templates/AGENTS/git_ops.md` の FAIL 参照整合 verify）
  - test-suite（`requirements.md` Req 4 / Req 8 の status・exit code 記述を新体系に更新、および既存テストコードのアサーション書き換え）

**Governance note**: cli-audit・test-suite は roadmap で `[x]` 完了マーク済だが、本スペックによる波及で `requirements.md` 本体の文言同期が必要になる。この修正は「後続スペックによる整合更新」として扱い、対象スペックの再 approval は要求しない（`spec.json` の `updated_at` 更新と CHANGELOG 記載のみ）。本 spec 完了時に `roadmap.md` の governance 節にこのルールを追記する。
- **Adjacent**:
  - cli-query（`rw lint query` / `rw query extract` / `rw query fix` の振る舞いを変更。`rw query fix` R3.8 は抽象的で本スペック変更後も満たされ続けるが、`rw query extract` R4.7 は「ERROR レベルの FAIL」という具体的 severity 名を含むため 4 水準化後の文言同期が必要。加えて design / tasks の `exit 2` 明示記述の意味明文化が必要）

## Constraints
- TDD（テストファースト）: 既存テストの旧値アサーションを新体系に書き換えてから実装移行
- 2 スペースインデント
- クリーンカット方針（後方互換モード・実行時 deprecation 警告は提供しない）
- AGENTS と CLI の vocabulary は完全 align（1:1 identity mapping）、永続的なマッピングコストを持たない
- 4 水準名称は業界標準準拠（`CRITICAL` / `ERROR` / `WARN` / `INFO`）
- exit code は 3 値分離（`0` = PASS、`1` = runtime error、`2` = FAIL 検出）
- `map_severity()` は identity 関数として実装、`sub_severity` タプル方式は廃止
- roadmap Technical Debt L99-111 および L113-122 の両エントリを本スペックで解消

## References
- `memory/project_severity_system.md` — 統一方針と判断根拠（3 水準から 4 水準への転換経緯を含む）
- `memory/project_exit_code_ambiguity.md` — exit 1 曖昧性の解消方針（本スペックで exit 0/1/2 分離を実施）
- `.kiro/steering/roadmap.md` Technical Debt L99-122 — 解消対象（L99-111: Severity 体系の既存コマンド統一、L113-122: exit 1 セマンティクス分離）を両方本スペックで処理
- `.kiro/specs/cli-audit/requirements.md` L20-27 — 旧 3 水準方針の記述（本スペックで 4 水準に拡張）
- `.kiro/specs/cli-audit/brief.md` L46 — 「結果レポートに severity（ERROR/WARN/INFO）を含める」
- `.kiro/specs/cli-query/requirements.md` R3.8（L86）, R4.7（L108）— 終了コードを「非ゼロ」「自動lint検証結果に基づく」と抽象的に規定、本スペック変更後も満たされ続ける
- `.kiro/specs/cli-query/design.md` L208, L270, L654 — 意味明文化が必要な exit 2 記述（FAIL 検出として再定義）
- `.kiro/specs/cli-query/tasks.md` L77, L97 — 意味明文化が必要な exit 2 記述
- `.kiro/specs/agents-system/requirements.md` — `AGENTS/audit.md` の severity 名称 rename 対象
