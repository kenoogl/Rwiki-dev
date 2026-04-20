# Requirements Document

## Introduction

Rwiki の既存 CLI コマンド群で混在している severity / status / exit code 体系を、AGENTS と CLI で完全 align された **4 水準 vocabulary（`CRITICAL` / `ERROR` / `WARN` / `INFO`）** に統一する。同時に終了コードを **runtime error と FAIL 検出に分離（exit 0 / 1 / 2）** する。これにより:

1. 永続的な AGENTS↔CLI 間マッピングコスト（`map_severity()` 関数、`(cli_severity, sub_severity)` タプル）を解消
2. roadmap Technical Debt L99-111（severity 体系統一）と L113-122（exit 1 セマンティクス分離）を 1 つのスペックで同時解消し、破壊的変更を 1 回で終わらせる
3. 将来の CI 統合・ダッシュボード・横断レポート機能の基盤を確立

### 現状の混在状況（調査結果）

| コマンド | 現在の severity / status | 終了コード |
|---|---|---|
| `rw lint` | status = `PASS` / `WARN` / `FAIL`（3 値）、severity は JSON の `errors` / `warnings` / `fixes` 配列分類で表現され status とは独立 | 0（成功）/ 1（FAIL あり、ランタイムエラーも） |
| `rw lint query` | status = `PASS` / `PASS_WITH_WARNINGS` / `FAIL`（3 値）、checks[].severity = `ERROR` / `WARN` / `INFO` | 0（PASS）/ 1（WARN）/ 2（FAIL） |
| `rw audit`（cli-audit 実装済み） | severity = `ERROR` / `WARN` / `INFO`（CRITICAL/HIGH/MEDIUM/LOW から 4→3 マッピング、`map_severity()` が sub_severity タプル返却）、status = `PASS` / `FAIL` | 0（PASS）/ 1（FAIL、ランタイムエラーも） |
| `rw query extract` / `rw query fix` | 内部で `lint_single_query_dir()` を呼び FAIL なら exit 2 | 0 / 1 / 2 |
| `AGENTS/audit.md`（Claude 内部分類） | `CRITICAL` / `HIGH` / `MEDIUM` / `LOW`（4 段階） | — |

### 統一後の体系

| 次元 | 統一値 | 備考 |
|---|---|---|
| severity（AGENTS と CLI で align、1:1 identity） | `CRITICAL` / `ERROR` / `WARN` / `INFO`（4 水準） | AGENTS の `HIGH/MEDIUM/LOW` を `ERROR/WARN/INFO` に rename。`CRITICAL` はそのまま保持 |
| status | `PASS` / `FAIL`（2 値） | `CRITICAL` または `ERROR` を 1 件以上検出すると `FAIL` |
| 終了コード | `0`（PASS）/ `1`（runtime error）/ `2`（FAIL 検出） | 全コマンド共通 |

AGENTS と CLI が同じ 4 水準を使うため、severity の変換処理は **identity（無変換）** に簡略化され、旧 `(cli_severity, sub_severity)` タプル構造は廃止される（具体的な関数シグネチャは設計フェーズで確定）。

### 用語定義（本スペック内で一貫して使用）

- **severity**: 問題単位に付与される重大度トークン。`CRITICAL` / `ERROR` / `WARN` / `INFO` の 4 水準
- **status**: コマンド全体の判定結果。`PASS` / `FAIL` の 2 値。構造化出力（JSON 等）では `status` フィールドとして現れる。本スペックでは run-level / file-level を問わず一貫して `status` を用いる（`verdict` 等の同義語は用いない）
- **exit code**: プロセス終了コード。`0` / `1` / `2` の 3 値

### 対象 CLI コマンド全列挙（本スペックの exit code 契約対象）

本スペックの exit code 契約（0/1/2）は以下の全 CLI コマンドに適用される:

1. `rw init` — Vault セットアップ（severity / status は発行しない。exit 0/1 のみ使用）
2. `rw lint` — 静的検査（severity 4 水準、status 2 値、exit 0/1/2 全て使用）
3. `rw lint query` — query ディレクトリ検査（severity 4 水準、status 2 値、exit 0/1/2 全て使用）
4. `rw ingest` — raw/incoming → raw 移動（status は上流参照。exit 0/1 のみ使用）
5. `rw synthesize-logs` — ログ合成（severity / status は発行しない。exit 0/1 のみ使用）
6. `rw approve` — review → wiki 昇格（severity / status は発行しない。exit 0/1 のみ使用）
7. `rw query extract` — query アーティファクト生成（内部 lint 結果に応じて exit 0/1/2 全て使用）
8. `rw query answer` — wiki 参照回答（severity / status は発行しない。exit 0/1 のみ使用）
9. `rw query fix` — query 修復（内部 lint 結果に応じて exit 0/1/2 全て使用）
10. `rw audit` — Claude ベース監査（severity 4 水準、status 2 値、exit 0/1/2 全て使用）

### 決定の根拠

本スペックの設計判断は、cli-audit 要件策定時に確定した 3 水準方針を再考した結果に基づく（記録: `memory/project_severity_system.md`、`memory/project_exit_code_ambiguity.md`、`.kiro/steering/roadmap.md` Technical Debt 節）:

1. **4 水準採用の理由**: cli-audit 時の 3 水準方針は永続的な AGENTS↔CLI マッピング維持コスト（`map_severity()` の 4→3 変換、`(cli_severity, sub_severity)` タプル）を生んでいた。4 水準で 1:1 align することでマッピングを identity 化し、長期保守コストを解消する。CRITICAL と ERROR（旧 HIGH）を独立水準にすることで、sub_severity タプルを使わずに両者を自然に区別できる
2. **`CRITICAL / ERROR / WARN / INFO` の名称選択理由**: 業界標準（syslog、Python logging）と整合。AGENTS の `CRITICAL` をそのまま保持、`HIGH/MEDIUM/LOW` のみ rename することで変更の最小化と業界標準の整合を両立
3. **`exit 0/1/2` 分離の理由**: roadmap L113-122「exit 1 セマンティクス分離」が将来課題として残っていたが、本スペックの語彙統一と一括実施することで破壊的変更を 2 回 → 1 回に削減。exit 1 = runtime error、exit 2 = FAIL 検出の分離により、CI スクリプトが「実行できなかった」と「実行して問題を見つけた」を明確に区別可能になる
4. **AGENTS 正規ソース化方針との関係**: cli-audit Req 10 は「AGENTS をプロンプトの正規ソースとする」。本スペックは AGENTS 自体の vocabulary を CLI と整合化することで、正規ソース原則をより強化する（CLI が AGENTS 出力をそのまま提示する形になり、二重語彙の divergence が消滅）
5. **`rw lint` / `rw lint query` の severity 割当**: Python 静的チェックも 4 水準を使用可能（例: YAML パース不能・pre-condition 違反は `CRITICAL`、通常の検査失敗は `ERROR` など）。具体的割り当ては設計フェーズで決定

## Boundary Context

- **In scope**:
  - `rw lint` / `rw lint query` の severity（4 水準）/ status（2 値）/ 終了コード（3 値）の統一体系への移行
  - `rw query extract` / `rw query fix` の exit code を新体系（exit 2 = FAIL 検出）に整合
  - `rw audit` の severity マッピングを 4→4 identity 化（severity 変換の簡略化、`sub_severity` タプル廃止）
  - `templates/AGENTS/audit.md` の severity vocabulary rename: `HIGH` → `ERROR`、`MEDIUM` → `WARN`、`LOW` → `INFO`（`CRITICAL` は維持）
  - `templates/AGENTS/lint.md` の更新: (a) `status` スキーマ `"PASS | WARN | FAIL"` を `"PASS | FAIL"` に変更、(b) 終了コード契約「`0` → FAIL 無、`1` → FAIL 有」を新 3 値体系（`0` = PASS、`1` = runtime error、`2` = FAIL 検出）に更新、(c) 「判定レベル PASS / WARN / FAIL」節を status（PASS / FAIL）と severity（CRITICAL / ERROR / WARN / INFO）の 2 次元構造に再構成
  - `templates/AGENTS/ingest.md`・`templates/AGENTS/git_ops.md` の lint 結果参照記述（「lint結果に FAIL が含まれないこと（FAIL == 0）」等）の整合確認: FAIL 概念自体は新体系でも維持されるため意味は不変だが、参照が AGENTS/lint.md の新体系記述と文法上整合することを verify
  - 構造化出力（`logs/lint_latest.json`、`logs/query_lint_latest.json`、`logs/audit-<tier>-<timestamp>.md` 等）に現れる severity / status 値域の更新
  - 標準出力の人間向けサマリー表示の更新
  - exit code 分離の実装: ランタイムエラーは exit 1、FAIL 検出は exit 2、PASS は exit 0
  - `docs/user-guide.md`・`docs/developer-guide.md`・`docs/lint.md`・`docs/ingest.md`・`docs/audit.md`・`docs/query.md`・`docs/query_fix.md`・`README.md`・`CHANGELOG.md` の用語統一および移行ノート記載
  - 既存テストのアサーション更新（旧値・旧 exit code を期待している箇所）および新規アサーション追加
  - `rw ingest` が `rw lint` の結果を参照して abort 判定する箇所の、上流 status 値域変更に伴う判定ロジック調整
  - `rw query extract` / `rw query fix` が内部で lint の status を参照する箇所の、上流 status 値域変更および新 exit code semantics に伴う判定ロジック調整
  - `rw audit` が Vault の `AGENTS/audit.md` を読み込む箇所に、旧語彙（`HIGH` / `MEDIUM` / `LOW`）残存検出と明示的エラーでの abort を追加（R8.6、旧 Vault + 新 CLI の組み合わせ時の Claude drift 防止）
  - 完了時の governance 更新: `roadmap.md` Technical Debt L99-111（severity 統一）および L113-122（exit 1 分離）両エントリに「→ severity-unification で実装済み」を追記
  - R6.5 の「既存 Vault の再デプロイ手順」実装の一部として `rw init` に軽微な修正（例: `--force` フラグ相当の追加、既存 `AGENTS/` バックアップ後の再コピー経路の有無）が必要となる場合、その修正も本スペックの in scope とする。具体的な機能追加の有無と設計は設計フェーズで決定する（AC 6.5 の設計フェーズ決定事項）
  - `roadmap.md` Technical Debt L128-136（`rw_light.py` モジュール分割）の行数見積もり refresh と優先度再評価（本スペック実装で純増する可能性があるため）
  - `roadmap.md` governance 節に「後続スペックによる完了済 requirements.md の整合更新は再 approval を要求しない」というルールを追記
  - 隣接スペック `requirements.md` の文言同期: cli-audit（Severity 体系節・Req 1-4 の AC）、cli-query R4.7、test-suite（Req 4 / Req 8 の status・exit code 記述）を新体系に合わせて更新
- **Out of scope**:
  - `AGENTS/audit.md` の検査項目本体・Tier 定義・priority 意味付けの変更（severity 名称の rename のみで、検査ロジックは変更しない）
  - `rw approve`・`rw synthesize-logs`・`rw query answer` の内部ロジック本体変更（severity / status を自前で発行しないため影響を受けない。R8.4 で対象外を明示）
  - 構造化出力の **フィールド名（キー名）や schema 形状の統一**（例: 全コマンドで `{status, findings[]}` 構造に揃える、など）。本スペックは値域（severity / status トークン）の統一のみを扱う
  - JSON ログの旧値との後方互換モード（legacy キー併記、出力バージョン切替フラグなど）の提供 — クリーンカット方式を採用
  - 旧値を用いた既存スクリプト向けの **実行時 deprecation 警告表示** — クリーンカット方針のため警告出力は行わない（CHANGELOG による周知のみ）
  - `rw_light.py` のモジュール分割
  - 既存の `logs/audit-<tier>-<timestamp>.md` 履歴ファイル（過去の audit 実行結果）の旧体系から新体系への一括変換 — 本スペックでは実施せず、履歴ファイルは旧体系のまま保持する。統一後の新規実行分から新体系で書き出される
  - `templates/AGENTS/*.md` へのバージョンマーカー導入（`# version: 2` 等のメタデータ埋め込みによる汎用的な差分検知機構）— deploy 版と dev 版の差分検知機構は agents-system スペックの管轄であり、本スペックでは扱わない。本スペックに限定した Vault 再デプロイ漏れ検出は、`rw audit` 実行時の `AGENTS/audit.md` 旧語彙残存 validation（R8.6）で代替する。再デプロイの必要性は R6.5 で CHANGELOG と user-guide に記載して運用者へ周知する
  - `rw --version` フラグの新設や semver バージョニング体系の導入 — CHANGELOG 形式と合わせて将来スペックで扱うため本スペック対象外
- **Adjacent expectations**:
  - **cli-audit spec との整合**: `rw audit` の検査ロジック・Tier 定義・プロンプト構造は変更しない。severity vocabulary のみ AGENTS 発行値を identity（無変換）で通過させる形で更新する（現行 `map_severity()` 関数の具体的な置換方式は Design constraints 参照）。cli-audit `requirements.md` 本体は旧 3 水準・FAIL=exit 1 前提で記述されているため、本スペック完了時に以下の文言同期が必要: (a) L18-L27 Severity 体系節（3 水準マッピング表・終了コード 0/1 記述）を 4 水準 identity・exit 0/1/2 体系に更新、(b) Req 1.3/1.5/1.6（micro）、Req 2.3/2.4/2.5（weekly）、Req 3.3/3.4/3.6/3.7（monthly、3.3 の `[ERROR] [CONFLICT]` マーカー例示も `[CRITICAL]` 系を含む形に拡張）、Req 4.3/4.4/4.5（quarterly）の severity 語彙を `CRITICAL`/`ERROR`/`WARN`/`INFO` 4 水準に拡張、(c) 上記 AC の「ERROR 1 件以上 → 終了コード 1」を「`CRITICAL` または `ERROR` 1 件以上 → 終了コード 2」に更新、(d) Req 7.1/7.2/7.3/7.5/7.8 のランタイムエラー系「終了コード 1」は新体系でも整合のため維持
  - `AGENTS/audit.md`（agents-system スペック管轄）の severity 名称を rename。検査ルール・priority 意味付けは変更しない。cli-audit Req 10「AGENTS/ ファイルをプロンプトの正規ソースとして使用する」は維持し、CLI が AGENTS の語彙をそのまま提示する形に整合化することでむしろ強化される
  - `logs/*.json` / `logs/*.md` を解釈する運用者のスクリプトや将来の統合ツールは、本スペックの値域変更（特に新 4 水準と exit code semantics）に応じて更新が必要
  - **cli-query spec との整合**: cli-query requirements `rw query fix` AC 3.8（終了コードを「自動lint検証結果に基づく」と規定）は抽象的であり、本スペックで `exit 2` を「FAIL 検出」専用に再定義しても満たされ続ける。一方 `rw query extract` AC 4.7 は「ERROR レベルの FAIL」という具体的 severity 名を含むため、4 水準化後は `CRITICAL` も FAIL 発火条件になることを反映して文言同期（「`CRITICAL` または `ERROR` レベル」等）が必要。cli-query design / tasks の `exit 2` 記述は意味的に整合（FAIL → exit 2）。実装時に「exit 2 = FAIL 検出」semantics の明文化、および R4.7 文言同期が必要
  - **agents-system spec との整合**: 本スペックは `AGENTS/audit.md` の severity 名称のみ rename する。agents-system Req 1.6 が規定する 4 階層の監査ティア（Micro-check / Structural / Semantic / Strategic）は severity とは独立した概念であり、本スペックでは変更しない。したがって Req 1.6 の要件充足には影響しない
  - **test-suite spec との整合**: test-suite `requirements.md` 本体に旧体系前提の AC が残存しているため、本スペック完了時に以下の文言同期が必要: (a) Req 4（cmd_lint）AC 3 の「WARN と判定」を 2 値 status（PASS / FAIL）および 4 水準 severity 前提に更新、(b) Req 4 AC 6 の「FAIL → 終了コード 1」を「FAIL → 終了コード 2」に更新、(c) Req 4 AC 7 の「PASS または WARN のみで終了コード 0」を新 status 体系に更新、(d) Req 8（cmd_lint_query）AC 4 の「ERROR レベルの問題がない時 → 終了コード 0」を「`CRITICAL` または `ERROR` レベルの問題がない時 → 終了コード 0」に文言拡張（意味論的には新体系の superset だが 4 水準化の明示のため）、(e) Req 8 AC 5 の「WARN レベルのみで終了コード 1」を廃止（PASS → exit 0 に統合）、(f) Req 8 AC 6 の「ERROR レベル → 終了コード 2」は維持しつつ `CRITICAL` を含める形に拡張、(g) Req 8 AC 7（終了コード 4）・AC 8（終了コード 3）を新 exit 0/1/2 3 値体系に統合（パス不在・引数パースエラーはいずれも runtime error = exit 1）。テストコード本体の書き換えは Req 7.1 が既にカバー
  - **roadmap.md との整合**: 本スペックは roadmap Technical Debt L99-111（Severity 体系の既存コマンド統一）および **L113-122（exit 1 セマンティクス分離）** の両エントリを解消する。**完了済の governance 更新**: Specs (dependency order) L144 への severity-unification エントリ追加。**完了時に必要な governance 更新**: L99-111 および L113-122 両エントリに「→ severity-unification で実装済み」追記
  - **完了済スペックの requirements.md 修正の governance 方針**: cli-audit・test-suite は roadmap で `[x]` 完了マーク済だが、本スペックによる語彙/exit code 変更の波及として `requirements.md` 本体の文言同期が必要になる。この修正は「後続スペックによる整合更新」として扱い、対象スペックの再 approval を要求しない（spec.json の `updated_at` 更新と CHANGELOG への記載のみで足りる）。本方針が steering に無いため、本スペック完了時に `roadmap.md` の governance 節に「後続スペックによる完了済 requirements.md の整合更新は再 approval 不要」を追記する
  - **`rw init` との関係**: `rw init` は Vault セットアップ時に `templates/AGENTS/*.md` を Vault にコピーする。本スペック完了後に `rw init` を実行した Vault は自動的に新 vocabulary で初期化される。`rw init` 自体は severity / status を発行せず、exit code 契約（0 / 1）のみが適用される。既存 Vault の再デプロイ手順は R6.5 で扱う
  - **`rw_light.py` サイズへの影響**: 現行 `rw_light.py` は 3,490 行（保守限界 3,000 行を超過、roadmap Technical Debt L128-136）。本スペックは `map_severity()` 本体の削減と引き換えに、4 水準分岐・exit code 分離・旧値残存検査の追加コードを伴うため、純増する可能性が高い。本スペック完了時に roadmap L128-136 の行数見積もりを refresh し、モジュール分割の優先度を再評価する必要がある（分割自体は本スペック対象外）
- **Design constraints（設計フェーズで決定すべき事項）**:
  - **`rw lint` の per-file 表示形式**: 現行は `[PASS]` / `[WARN]` / `[FAIL]` を per-file プレフィックスで混在使用している。統一後は file-level status が `PASS` / `FAIL` の 2 値になるため、per-file 表示形式（候補: (A) `[PASS] path (warn: 2)` のような status + 注釈、(B) 最重 severity を per-file トークンに表示、(C) status のみ表示し severity 内訳は別集計行へ）は設計フェーズで決定する
  - **`lint` JSON の `fixes` 配列の扱い**: 現行 `logs/lint_latest.json` は `errors` / `warnings` / `fixes` の 3 配列を持つ。`fixes` は severity ではなく remediation suggestion を表す別概念であり、本スペックは severity 値域の統一のみを扱うため `fixes` 配列の存廃は設計フェーズで判断する
  - **`lint` JSON の `summary` キー構成**: 現行は `summary: {pass: N, warn: N, fail: N}`（file 数の status 別集計）。統一後は file-level status が PASS/FAIL のみとなるため、選択肢: (A) `summary.warn` を常に 0 として残す、(B) キーを削除（`{pass: N, fail: N}`）、(C) finding 集計と統合し 4 水準の件数を加える。設計フェーズで決定
  - **`rw lint` / `rw lint query` の各検査項目への 4 水準割り当て**: 個別検査項目（frontmatter 検証、link 検証等）に対して `CRITICAL` / `ERROR` / `WARN` / `INFO` のいずれを割り当てるかは設計フェーズで確定する
  - **exit code 分離の実装方法**: ランタイムエラーをどこで catch し exit 1 を返すか、FAIL 検出は status 計算後に exit 2 を返す統一規約の実装方式は設計フェーズで確定する
  - **R7.7 の静的スキャン実装方式**: 旧値リテラル残存検証の具体的方法（AST ベース、regex ベース、custom lint rule 等）は設計フェーズで確定する
  - **`audit` 構造化出力の `sub_severity` フィールド存廃**: identity mapping 化により `sub_severity` はデータとして廃止されるが、構造化出力（Markdown / JSON）からフィールド自体を削除するか、残置して常に空値（null / 未記載）とするかは設計フェーズで決定する（Boundary Out of scope の「フィールド名・schema 形状統一」には該当せず、既存フィールドの存廃のみ扱う）
  - **`map_severity()` 相当の関数シグネチャ**: 現行 `map_severity()` を identity 関数として置き換えるか、関数自体を削除して呼び出し側を直接 AGENTS 出力値に置き換えるかは設計フェーズで確定する
  - **`cmd_ingest` の lint 結果参照契約**: 現行 `cmd_ingest` は `lint_latest.json` の `summary["fail"]` を参照して abort 判定する（`scripts/rw_light.py` L406-409）。上記「`lint` JSON の `summary` キー構成」設計で (B) キー削除 / (C) 4 水準件数統合 を選択する場合、`cmd_ingest` の参照ロジックも同時に更新する必要がある。AC 8.1 は overall status ベースでの判定を規定するが、実装戦略（file-level fail カウント継続 vs overall status 参照切替）は設計フェーズで確定する
  - **`audit` Markdown レポートの finding プレフィックス形式**: 現行は `map_severity()` タプルに基づき `[ERROR] [CRITICAL 由来] ...` 等の 2 段表記になっている可能性がある。identity mapping 化により sub_severity 情報が消えるため、finding 行のプレフィックス形式（候補: (A) `[CRITICAL] ...` / `[ERROR] ...` / `[WARN] ...` / `[INFO] ...` の単一 severity 表記、(B) 旧 2 段構造を維持して 1 段目を空にする）は設計フェーズで決定する
  - **移行実装順序（3 フェーズ、atomic + green-gated）**: 運用者から見れば破壊的変更は 1 回だが、実装側は以下 3 フェーズで段階化し、**各フェーズ完了時点でテスト全件 green** を不変条件とする。従来の 5 phase 案（P1 transitional / P2 identity 化 を分離）は Core-only スコープ確定（Y 選択）により、「P1 transitional → P2 identity 化」の 2 段階を 1 atomic PR に統合して速度を優先する。TDD は phase 単位で red → green を反復する。

    **P1: AGENTS 語彙 rename + identity 化 + Vault validation + drift 最低限（1 PR、atomic）**
    - `templates/AGENTS/audit.md` rename（`HIGH`→`ERROR`、`MEDIUM`→`WARN`、`LOW`→`INFO`、`CRITICAL` 維持）
    - `_normalize_severity_token` helper を最初から identity 関数として実装（旧語彙受信時は stderr + INFO 降格 + `drift_events[]` 追記）
    - `map_severity()` 廃止、`sub_severity` NamedTuple フィールド削除、呼び出し側 25 箇所を identity に置換
    - Vault vocabulary validation helper（`_validate_agents_severity_vocabulary`）+ `load_task_prompts` フック + `--skip-vault-validation` escape hatch
    - `build_audit_prompt` に Severity Vocabulary (STRICT) prefix 挿入（Claude drift 抑止）
    - `parse_audit_response` の 4 段構造検証（silent skip 廃止、AC 1.9 違反防止）
    - `rw init --force` 実装（symlink 防御 + timestamp collision → `<timestamp>-<pid>` fallback）
    - `rw audit` 出力に `CRITICAL` が新たに現れる、それ以外の語彙変更は旧→新の 1:1 rename
    - P1 PR description に post-merge operator instruction inline 記載（`rw init --force` 実行必須）
    - Rollback 容易性: 単純 revert（1 PR 単位）

    **P2: status 2 値化 + exit code 3 値分離 + 隣接コマンド（1 PR、統合）**
    - `_compute_run_status(findings)` helper TDD（CRITICAL or ERROR 1 件以上 → FAIL）
    - `_compute_exit_code(status, had_runtime_error)` helper TDD（0/1/2 返却）
    - `cmd_lint` status 2 値化 + `logs/lint_latest.json` の `summary.warn` 削除 + `severity_counts` 追加 + top-level `status` 追加
    - `cmd_lint_query` status 2 値化 + `PASS_WITH_WARNINGS` 廃止 + `checks[]` 単一配列化
    - `cmd_audit_*` status 計算 + Summary に CRITICAL 行追加 + stdout `CRITICAL X, ERROR Y, WARN Z, INFO W — status` format
    - stdout 4 水準併記形式 + per-file 表示形式更新
    - `cmd_lint` / `cmd_audit_*` の FAIL → `exit 2` 移行
    - `cmd_lint_query` の旧 `exit 3`（引数エラー）/ `exit 4`（path 不在）→ `exit 1` に統合、FAIL → `exit 2`
    - `cmd_ingest` の precondition failure → `exit 1` 維持（上流 FAIL は自身の finding 由来ではないため、AC 8.1）、status 位置の WARN 解釈除去
    - `cmd_query_extract` / `cmd_query_fix` の内部 lint FAIL → `exit 2` 整合（artifact 保持）
    - `templates/AGENTS/lint.md` の status / 終了コード / summary 記述更新
    - Rollback 容易性: P1 状態へ revert 可能

    **P3: ドキュメント + 隣接 spec + 静的スキャン + Acceptance Smoke Test（1 PR、縮約）**
    - `docs/developer-guide.md` SSoT 6 節（Severity Vocabulary / Exit Code Semantics / Migration Notes / Vault Redeployment / Glossary / Debugging FAIL）
    - Reference docs 更新（`docs/user-guide.md` / `docs/audit.md` / `docs/lint.md` / `docs/ingest.md` / `docs/query.md` / `docs/query_fix.md`）
    - `README.md` / `CHANGELOG.md` 更新（破壊的変更 5 項目列挙 + Migration Guide リンク）
    - 隣接 spec `requirements.md` 同期（cli-audit / cli-query / test-suite、`_change log` 追記、governance ルールにより再 approval 不要）
    - `roadmap.md` governance 更新（L99-111 / L113-122 完了マーク、L128-136 行数見積もり refresh、新 Technical Debt 5 項目、Adjacent Spec Synchronization 節新設、`observability-infra` debt エントリ追加）
    - Reverse Dependency Inventory scan 実行 + `developer-guide.md` §Reverse Dependency Inventory 節に MD table 記録
    - 静的スキャンテスト（`tests/test_agents_vocabulary.py` + `tests/test_source_vocabulary.py`）による旧値残存検証（AC 7.6 / 7.7）
    - 非対象コマンド regression test（AC 7.8）
    - Acceptance Smoke Test: `rw audit weekly --skip-vault-validation` 系を手動確認
    - Rollback 容易性: コード挙動は P2 時点で確定、P3 は周辺更新のみ

    **フェーズ間の不変条件**:
    - 各 phase 完了時点で `tests/` 全件 green
    - 各 phase は独立した commit / PR として review 可能（P1 は atomic 強制、P2 / P3 も単一 PR 推奨）
    - 複数 phase を 1 つの PR にまとめることは可（速度優先）、分割は P1 atomic 不変条件を除き実装者裁量
    - P1 は `_normalize_severity_token` と `map_severity()` 廃止を同時に行うため、部分 merge 不可（atomic 強制）
  - **日本語ドキュメント内の severity 表記方針**: `docs/*.md`（日本語）で severity トークン（`CRITICAL`・`ERROR`・`WARN`・`INFO`）を英字のまま用いるか、和訳（例: 「重大」「エラー」「警告」「情報」）を併記するかは設計フェーズで決定する。既存ドキュメントの前例（`docs/audit.md` の既存記法）と整合する方針を優先する
  - **未知 severity の fallback policy**: Claude が 4 水準外の severity 値を返した場合の扱いは AC 1.9 で確定済み（stderr 記録 + INFO 降格 + audit 継続 + `drift_events[]` 追記）。本スペックでは strict mode / ERROR 昇格 / cap + sentinel / 3 段 collapse / invocation end summary を含めない（drift 実例が観察された時点で `observability-infra` spec で扱う、`roadmap.md` Technical Debt 記録）。設計フェーズで確定する細目は: (i) drift stderr メッセージフォーマット — **確定**: 4 行形式 `[severity-drift] unknown token in <context>: <sanitized_T>\n  - source: <source_field>\n  - related location: <location>\n  - demoted to: INFO`、(ii) `drift_events[]` エントリ形状 — **確定**: 5 キー必須 (`original_token / sanitized_token / demoted_to / source_field / context`、本 AC 冒頭の 4 キー表記中 `source_context` を `source_field + context` の 2 キーに展開実装、tasks.md 1.2 signature と整合)、(iii) 現行実装（`scripts/rw_light.py` L1713-1715）の silent fallback を新挙動に置き換える実装箇所のみ。
  - **`rw lint` の per-file 論理モデル**: 現行は per-file status（`PASS` / `WARN` / `FAIL` 3 値）と run-level summary の 2 層構造。新体系で per-file status が取りうる値域（候補: (A) `PASS` / `FAIL` 2 値、severity は別次元で付与、(B) file-level 概念を廃止し finding レベルの severity のみで管理、(C) per-file status として `PASS` / `FAIL` 2 値を採用しつつ最重 severity を per-file メタ情報として保持）は設計フェーズで決定する。Req 2.2-2.3 は run-level status のみを規定し、per-file レベルの論理モデルは本項目で確定する
  - **CHANGELOG の記述形式**: R6.2 で列挙義務を課す破壊的変更の CHANGELOG 記述フォーマット（候補: Keep a Changelog スタイル、semver バージョン番号付与の要否、エントリの timestamp 粒度）は設計フェーズで決定する。Rwiki が外部パッケージとして配布されるか internal tool として運用されるかによって要件が変わるため、product.md / roadmap.md の方針と整合させる
  - **Requirement ↔ Design / Tasks トレーサビリティ**: 本 requirements の各 AC が design フェーズのどの設計項目・tasks フェーズのどの実装タスクに対応するかのマッピングは、design.md 作成時にトレーサビリティマトリクスとして構築する（requirements 単独ではカバレッジ検証が困難なため）
  - **AC 8.6 Vault validation の検出方式**: `AGENTS/audit.md` の旧語彙残存検出について、(i) 検出アルゴリズム（単純 substring 検索、word boundary regex、AST / Markdown セクション解析等）、(ii) 検出スコープ（ファイル全体 / severity 定義セクションに限定 / Migration Notes ブロックを除外）、(iii) 検証のタイミング（各 `rw audit` 実行の都度 / 初回読み込み時のキャッシュ / 専用サブコマンド `rw lint agents` 等）、(iv) false positive 回避策（コメント内の歴史的言及や例示を誤検出しない方法）は設計フェーズで確定する。本 AC の目的は旧 Vault + 新 CLI による Claude drift の防止であり、運用者が意図的に旧語彙を保持する legitimate なユースケースは想定しない

## Requirements

### Requirement 1: 統一 severity 語彙（4 水準、AGENTS と CLI で align、1:1 identity）

**Objective:** 運用者として、AGENTS と CLI で同じ severity 語彙を使うことで、Claude の出力と CLI の表示を mental mapping なしに対応付けたい。

#### Acceptance Criteria

1.1. The CLI shall Rwiki CLI 全体で severity を `CRITICAL` / `ERROR` / `WARN` / `INFO` の 4 水準のみで表記する（具体的な出力種別ごとの要件は構造化出力を Req 4、標準出力を Req 5 で定義する）。

1.2. The CLI shall `templates/AGENTS/audit.md` 内の severity 名称を `CRITICAL` / `ERROR` / `WARN` / `INFO` に統一する（`HIGH` → `ERROR`、`MEDIUM` → `WARN`、`LOW` → `INFO` の rename）。`CRITICAL` はそのまま保持する。

1.3. When `rw lint` が 1 件以上の問題を検出した場合, the CLI shall 各問題に `CRITICAL` / `ERROR` / `WARN` / `INFO` のいずれかを付与する。

1.4. When `rw lint query` が 1 件以上の問題を検出した場合, the CLI shall 各問題に `CRITICAL` / `ERROR` / `WARN` / `INFO` のいずれかを付与する。

1.5. When `rw audit` が Claude から severity を受け取った場合, the CLI shall AGENTS で定義された 4 水準（`CRITICAL` / `ERROR` / `WARN` / `INFO`）を無変換（identity）で構造化出力および標準出力に通過させる。severity に付随する旧 `(cli_severity, sub_severity)` タプル構造はデータとして廃止する（タプル構造に対応する出力フィールドの存廃は設計フェーズで確定）。

1.6. The CLI shall `rw lint` / `rw lint query` の各検査項目に対して、Claude の 4 段階分類を介さず、`CRITICAL` / `ERROR` / `WARN` / `INFO` のいずれか 1 つを直接割り当てる（これらは Python 静的チェックであり LLM 出力を扱わないため）。各検査項目への具体的な severity 割り当ては設計フェーズで決定する。なお、`rw lint` / `rw lint query` が実際に発行する severity は「4 水準のいずれか」であり、全 4 水準を必ず使用する義務は課さない（利用されない水準が生じても本 AC に違反しない）。

1.7. The CLI shall AGENTS と CLI の vocabulary を 1:1 で一致させ、両者の間に語彙差分（divergence）を持たない。

1.8. The implementation shall `templates/AGENTS/lint.md` の status 記述を新体系（status = `PASS` / `FAIL` 2 値、severity = `CRITICAL` / `ERROR` / `WARN` / `INFO` 4 水準、終了コード `0` / `1` / `2`）に更新する。`templates/AGENTS/ingest.md`・`templates/AGENTS/git_ops.md` の lint 結果参照箇所（FAIL 件数の参照等）は FAIL 概念が新体系でも維持されることから意味不変だが、更新後の `templates/AGENTS/lint.md` 記述と矛盾しないことを verify する。

1.9. When `rw audit` が Claude から 4 水準（`CRITICAL` / `ERROR` / `WARN` / `INFO`）外の severity トークン（例: 旧語彙 `HIGH` / `MEDIUM` / `LOW`、`WARNING`、`CRITICAL_ERROR` 等）を受け取った場合, the CLI shall 当該 drift を stderr に記録した上で audit 実行を継続し、該当 finding を `INFO` に降格して構造化出力（`logs/<cmd>_latest.json` の `drift_events[]` フィールド）へ追記する。silent な fallback（通知なしでの既定値への自動置換）は許容しない（AC 8.5 / 8.6 の防御をすり抜けた drift が累積すると既存テストを無効化し、severity 体系の信頼性を毀損するため）。drift 発生数の上限（cap）、重複抑制、invocation end summary、strict mode オプションは本スペックの対象外とし、drift 実例が観察された時点で別スペック `observability-infra`（`roadmap.md` Technical Debt に記録）で扱う。

### Requirement 2: 統一 status 語彙

**Objective:** 運用者として、コマンド全体の status を `PASS` / `FAIL` の 2 値だけで判断したい。中間値や独自語彙を暗記する必要をなくしたい。

#### Acceptance Criteria

2.1. The CLI shall 任意の rw コマンドの status を `PASS` または `FAIL` のいずれか 1 つで表記する。

2.2. When `rw lint` の検査で `CRITICAL` または `ERROR` severity の問題が 1 件も検出されなかった場合, the CLI shall status を `PASS` として出力する（`WARN` / `INFO` のみの場合も `PASS`）。

2.3. If `rw lint` の検査で `CRITICAL` または `ERROR` severity の問題が 1 件以上検出された場合, the CLI shall status を `FAIL` として出力する。

2.4. When `rw lint query` の検査で `CRITICAL` または `ERROR` severity の問題が 1 件も検出されなかった場合, the CLI shall status を `PASS` として出力する。

2.5. If `rw lint query` の検査で `CRITICAL` または `ERROR` severity の問題が 1 件以上検出された場合, the CLI shall status を `FAIL` として出力する。

2.6. The CLI shall `PASS_WITH_WARNINGS` などの中間 status 値を JSON ログおよび標準出力のいずれにも出力しない。

2.7. The CLI shall `WARN` を status として使用しない（`WARN` は severity 語彙であり、status 語彙ではない）。

2.8. When `rw audit` の検査で `CRITICAL` または `ERROR` severity の問題が 1 件も検出されなかった場合, the CLI shall status を `PASS` として出力する（`WARN` / `INFO` のみの場合も `PASS`）。

2.9. If `rw audit` の検査で `CRITICAL` または `ERROR` severity の問題が 1 件以上検出された場合, the CLI shall status を `FAIL` として出力する。

### Requirement 3: 統一 exit code 契約（runtime error / FAIL 分離）

**Objective:** スクリプトや CI から rw コマンドを呼び出す運用者として、終了コードで「実行成功」「実行失敗（ランタイムエラー）」「検査 FAIL 検出」の 3 状態を明確に区別したい。

#### Acceptance Criteria

3.1. When 任意の rw コマンドが status `PASS` で完了した場合、または status を発行しないコマンド（`rw init`・`rw ingest`・`rw synthesize-logs`・`rw approve`・`rw query answer`）が runtime error・precondition 不成立を伴わず正常終了した場合, the CLI shall 終了コード `0` で終了する。

3.2. If 任意の rw コマンドがランタイムエラー（引数不正、ファイル未検出、Claude CLI 呼び出し失敗、パースエラー等の例外）または precondition 不成立（上流コマンドの結果が `FAIL` のため下流コマンドが abort する場合等、自身の finding 由来ではない失敗）で終了する場合, the CLI shall 終了コード `1` で終了する。

3.3. If 以下の rw コマンドが status `FAIL` と判定された場合（`CRITICAL` または `ERROR` を 1 件以上検出）, the CLI shall 終了コード `2` で終了する: (a) 自身の検査結果で status を判定するコマンド（`rw lint`・`rw lint query`・`rw audit`）、(b) 自身が実行する内部 lint の結果を自身の status として扱うコマンド（`rw query extract`・`rw query fix`）。status を発行しない・または上流結果を参照するのみの非対象コマンド（`rw init`・`rw ingest`・`rw synthesize-logs`・`rw approve`・`rw query answer`）は本 AC の対象外であり、上流 FAIL を参照して abort する場合でも終了コード `2` を使用しない（AC 7.8 および AC 8.1 を参照）。

3.4. The CLI shall 終了コード `1` を「自身の finding 由来ではない失敗（ランタイムエラーおよび precondition 不成立）」専用、終了コード `2` を「自身の status が `FAIL` と判定された場合（自身の finding 由来の FAIL 検出）」専用として使用し、両者を混同しない。

3.5. When `rw query extract` が内部の自動 lint 検証で status `FAIL` を検出した場合, the CLI shall 生成したアーティファクトを保持したまま終了コード `2` で終了する（cli-query requirements R4.7 の「非ゼロの終了コードで終了する」を満たす）。

3.6. When `rw query fix` が修復後の再 lint で残存 `FAIL` を検出した場合, the CLI shall 終了コード `2` で終了する（cli-query requirements R3.8 の「自動lint検証の結果に基づいて決定する」を満たす）。

3.7. The CLI shall `rw lint`・`rw audit` などの既存コマンドで現状 status `FAIL` に対して `exit 1` を返している箇所を `exit 2` に移行する（破壊的変更、CHANGELOG で周知）。

### Requirement 4: 構造化出力の値域統一

**Objective:** `logs/` 配下の構造化出力（JSON ログ・Markdown レポート）を解析する運用者・ツール作者として、どのコマンドの出力も同じ severity / status 値域で解釈できるようにしたい。

**Scope note:** 本要件は各構造化出力内に現れる severity / status **値（トークン）の値域統一** のみを扱う。各コマンドで異なるフィールド名や schema 形状（`lint` の `errors`/`warnings`/`fixes` 配列、`lint query` の `checks[].severity` フィールド、`audit` の Markdown 内 severity マーカーなど）の統一は Boundary Context に従いスコープ外とする。

#### Acceptance Criteria

4.1. The CLI shall 構造化出力に現れる問題レベルトークン（各コマンドが severity を表現するために使用している値）を `CRITICAL` / `ERROR` / `WARN` / `INFO` のいずれかのみで書き込む。

4.2. The CLI shall 構造化出力に現れる status トークン（各コマンドが全体 status を表現するために使用している値）を `PASS` / `FAIL` のいずれかのみで書き込む（`PASS_WITH_WARNINGS` などの中間値を含めない）。

4.3. When `rw lint` が `logs/lint_latest.json` を書き出す場合, the CLI shall 各問題に付与される severity トークンを `CRITICAL` / `ERROR` / `WARN` / `INFO` のいずれかで、overall status を `PASS` / `FAIL` のいずれかで記録する。

4.4. When `rw lint query` が `logs/query_lint_latest.json` を書き出す場合, the CLI shall 各 check の severity トークンを `CRITICAL` / `ERROR` / `WARN` / `INFO` のいずれかで、overall status を `PASS` / `FAIL` のいずれかで記録する（AC 4.2 により `PASS_WITH_WARNINGS` は含まれない）。

4.5. When `rw audit` が `logs/audit-<tier>-<timestamp>.md` を書き出す場合, the CLI shall 各 finding に付与される severity トークンを `CRITICAL` / `ERROR` / `WARN` / `INFO` のいずれか（AGENTS 由来を identity mapping で通過）で、overall status を `PASS` / `FAIL` のいずれかで記録する。

4.6. The CLI shall 構造化出力に旧体系の severity / status 値（`PASS_WITH_WARNINGS`、AGENTS 旧 vocabulary `HIGH`/`MEDIUM`/`LOW`、status 位置に現れる `WARN` トークンなど）を併記しない。

### Requirement 5: 標準出力フォーマットの統一

**Objective:** 端末でコマンド出力を読む運用者として、severity と status の語彙が行内で混在しない状態にしたい。

#### Acceptance Criteria

5.1. When rw コマンドが問題単位の severity を伴うサマリー行を標準出力に表示する場合, the CLI shall `CRITICAL` / `ERROR` / `WARN` / `INFO` のいずれかのトークンのみを使用する。

5.2. When rw コマンドが status を伴う集計行を標準出力に表示する場合, the CLI shall `PASS` または `FAIL` のいずれかのトークンのみを使用する。

5.3. The CLI shall severity 語彙と status 語彙を 1 つのトークンに混在させない（例: status の位置に `[WARN]` を表示しない、finding の位置に `[PASS]` を表示しない）。

5.4. When rw コマンドが 1 件以上の問題を含む集計サマリーを出力する場合, the CLI shall severity 別件数（`CRITICAL` / `ERROR` / `WARN` / `INFO` の各件数）と最終 status（`PASS` / `FAIL`）を併記する。件数 0 の水準の表示形式（全 4 水準常時表示 / 0 件水準の省略）は設計フェーズで決定する。

5.5. When rw コマンドが対象 0 件または問題 0 件の状況で完了した場合, the CLI shall severity 別件数行を省略してもよいが、最終 status（`PASS` / `FAIL`）は表示する（cli-audit R1.7「対象ページ 0 件の場合 `pages scanned: 0` を表示」のような既存挙動と整合）。

### Requirement 6: ドキュメントとマイグレーション

**Objective:** 既存の運用ドキュメントを参照する運用者・外部ツール作者として、統一後の語彙・exit code semantics・移行手順を 1 箇所で把握したい。

#### Acceptance Criteria

6.1. The CLI shall 対応するドキュメント更新（`docs/user-guide.md`・`docs/developer-guide.md`・`docs/lint.md`・`docs/ingest.md`・`docs/audit.md`・`docs/query.md`・`docs/query_fix.md`・`README.md`）で severity を `CRITICAL / ERROR / WARN / INFO`、status を `PASS / FAIL`、終了コードを `0 / 1 / 2` と記載する。`docs/ingest.md` は `rw lint` 結果に基づく abort ロジック説明を、`docs/query.md` は `rw lint query` の severity・status・exit 2 semantics を、`docs/query_fix.md` は `rw query fix` の再 lint 後の exit 2 semantics を、それぞれ更新対象に含む。

6.2. The CLI shall `CHANGELOG.md` に本統一の破壊的変更点を列挙する: (a) `PASS_WITH_WARNINGS` 廃止、(b) `AGENTS/audit.md` の `HIGH / MEDIUM / LOW` を `ERROR / WARN / INFO` に rename、(c) `rw lint` の status から `WARN` 廃止、(d) JSON ログのフィールド値域変更、(e) exit code semantics 変更（`exit 1` → ランタイムエラー専用、`exit 2` → FAIL 検出専用、`rw lint` / `rw audit` などの旧 `exit 1` (FAIL) → `exit 2` への migration）。

6.3. The CLI shall ドキュメント内で AGENTS と CLI が同名 4 水準（`CRITICAL / ERROR / WARN / INFO`）を使用することを明記し、旧 AGENTS vocabulary（`HIGH / MEDIUM / LOW`）からの移行ノートを含める。

6.4. The CLI shall ドキュメント内で exit code semantics（`0` = PASS、`1` = runtime error、`2` = FAIL 検出）を明記し、旧 exit code 体系（特に `rw lint` / `rw audit` で旧 `exit 1` = FAIL を使っていた箇所）からの移行ノートを含める。

6.5. The CLI shall CHANGELOG および `docs/user-guide.md` に「既存の Vault は `templates/AGENTS/` を再デプロイする必要がある」旨の移行手順を明記する（`templates/AGENTS/audit.md`・`templates/AGENTS/lint.md` 等が rename / 更新されるため、旧版 `AGENTS/*.md` を持つ Vault では新版 `rw_light.py` と組み合わせたときに Claude 出力の語彙 drift が発生するため）。具体的な再デプロイコマンド（`rw init --force` 相当の有無など）は設計フェーズで決定する。なお運用者が再デプロイを失念した場合でも AC 8.6 の Vault validation で `rw audit` 実行時に検出・abort される（本 AC と AC 8.6 は「事前周知 + 実行時安全ネット」の 2 層防御）。

### Requirement 7: テストによる振る舞い固定

**Objective:** メンテナとして、4 水準体系・identity mapping・exit code 分離を自動テストでロックし、将来のリグレッションを検知できるようにしたい。

#### Acceptance Criteria

7.1. The CLI shall 既存テスト群の中で旧値（status としての `WARN`、`PASS_WITH_WARNINGS`、AGENTS 旧 vocabulary の `HIGH`/`MEDIUM`/`LOW`、旧 exit code semantics で `rw lint`/`rw audit` の FAIL を `exit 1` で期待していた箇所）を新体系に書き換える。

7.2. The test suite shall `rw lint` の JSON ログと標準出力が 4 水準 severity および 2 値 status のみを出力することを検証するテストを含む。

7.3. The test suite shall `rw lint query` の JSON ログと標準出力が 4 水準 severity および 2 値 status のみを出力し、`PASS_WITH_WARNINGS` を出力しないことを検証するテストを含む。

7.4. The test suite shall 各 rw コマンドの exit code が新 semantics に従うことを検証するテストを含む: PASS → `exit 0`、自身の finding 由来ではない失敗（ランタイムエラーおよび precondition 不成立、AC 3.2 / 3.4 の広義定義）→ `exit 1`、自身の status `FAIL`（自身の finding 由来の FAIL 検出、AC 3.3 対象コマンドのみ）→ `exit 2`。`rw ingest` が上流 lint の FAIL を参照して abort する場合も本 AC の `exit 1` 検証対象に含める（AC 8.1 参照）。

7.5. The test suite shall `rw audit` の AGENTS 発行 severity が CLI 構造化出力および標準出力に同一文字列（`CRITICAL`→`CRITICAL`、`ERROR`→`ERROR`、`WARN`→`WARN`、`INFO`→`INFO`）でそのまま現れることを検証するテストを含む。旧 sub_severity タプル経由の検証は identity 検証に置き換える。

7.6. The test suite shall `templates/AGENTS/audit.md` および `templates/AGENTS/lint.md` 内に旧 vocabulary（`HIGH`、`MEDIUM`、`LOW`、status 位置の `WARN`）が残存しないことを検証するテストを含む（ファイル内容の静的検査）。

7.7. The test suite shall 本統一完了後のコードベースおよびテストアサーションに、旧値の文字列リテラル（`PASS_WITH_WARNINGS`、status 位置の `WARN`、AGENTS 旧 `HIGH/MEDIUM/LOW`、旧 exit code semantics で FAIL を `exit 1` とする箇所）が残存しないことを検証する（ソースおよびテストコードに対する静的スキャンまたは同等の検査。具体的な検査方法は設計フェーズで確定する）。検査対象: `scripts/rw_light.py`・`tests/`・`templates/AGENTS/*.md`。対象外: `CHANGELOG.md`（破壊的変更の移行記録として旧値言及が必須）および `docs/*.md` 内の「Migration Notes」/「移行ノート」節（旧値から新値への対応関係を説明するために旧値言及が必須）。

7.8. The test suite shall severity / status を自前で発行しない非対象コマンド（`rw init`・`rw ingest`・`rw synthesize-logs`・`rw approve`・`rw query answer`）について、新 exit code 契約（成功時 `0`、自身の finding 由来ではない失敗時 `1`（AC 3.2 / 3.4 の広義定義に従い、ランタイムエラーおよび precondition 不成立の両方を含む。特に `rw ingest` は上流 lint FAIL による abort も `exit 1` で扱う — AC 8.1 参照）、`2` は発行しない）を既に満たしていることを検証するテストを含む（既存挙動の regression 監視）。

7.9. The test suite shall AC 8.6 の Vault validation 挙動を検証するテストを含む: (a) `AGENTS/audit.md` に旧語彙（`HIGH` / `MEDIUM` / `LOW`）が severity トークンとして含まれる場合、`rw audit` が Claude にプロンプトを送らずに `exit 1` で abort し、stderr に再デプロイを促すメッセージを出力すること、(b) 新語彙（`CRITICAL` / `ERROR` / `WARN` / `INFO`）のみを含む正常な `AGENTS/audit.md` では validation が pass し audit 実行が継続すること、(c) false positive 回避の代表ケース（コメント内の歴史的言及や Migration Notes ブロックが設計で除外対象とされる場合）がある場合はそのケースで validation が pass すること。

7.10. The test suite shall AC 1.9 の drift 可視性挙動を検証するテストを含む: Claude CLI の出力をモックして 4 水準外の severity トークン（例: `HIGH`、`WARNING` 等）を返す状況を再現し、(a) silent fallback が発生しないこと（stderr に drift が記録され、`logs/<cmd>_latest.json` の `drift_events[]` に 1 件以上追記されること）、(b) 該当 finding が `INFO` に降格され audit 実行が継続すること、を検証する。drift cap / sentinel / strict mode / invocation end summary は本スペックの対象外。

### Requirement 8: 既存コマンド連携への波及制御

**Objective:** `rw ingest` や `rw query *` など lint/audit の結果を参照する既存コマンドのメンテナとして、上流の語彙変更および exit code semantics 変更に伴う下流の判定ロジック変更を明示的に扱いたい。

#### Acceptance Criteria

8.1. When `rw ingest` が `rw lint` の結果を参照して abort 判定する際, the CLI shall status `FAIL` のときに abort して終了コード `1` で終了し（上流 FAIL は `rw ingest` 自身の検査結果ではなく precondition 不成立として扱うため、`exit 2` ではなく `exit 1` を使用する。AC 7.8 と整合）、`PASS`（`WARN` / `INFO` のみの問題を含む場合も含む）のときに続行する。

8.2. The CLI shall `rw ingest` の判定ロジックから、status 位置で `WARN` を解釈するコードパスを除去する（上流 `rw lint` が status `WARN` を出さなくなるため、下流側でも受理しない）。

8.3. When `rw query extract` / `rw query fix` が内部で `lint_single_query_dir()` の status を参照して分岐する際, the CLI shall 上流の新 status 体系（`PASS` / `FAIL`）で判定し、FAIL 検出時は新 exit code semantics（`exit 2`）に従う。`rw query answer` は lint を参照しないため本要件の対象外とする。

8.4. The CLI shall `rw approve`・`rw synthesize-logs`・`rw query answer` のように severity / status を自前で発行しないコマンドに対して、新たな severity / status 発行義務を課さない（これらのコマンドは本スペックの直接対象外。ただしランタイムエラー時の `exit 1`、成功時の `exit 0` という exit code 契約は全コマンドに適用される）。

8.5. The CLI shall AGENTS/audit.md を読み込んで Claude にプロンプトを送る箇所（cli-audit `_run_llm_audit()` 等）について、新 vocabulary（`CRITICAL` / `ERROR` / `WARN` / `INFO`）を Claude の出力契約として渡し、プロンプト本文に「旧語彙 `HIGH` / `MEDIUM` / `LOW` は使用しないこと」の明示指示を含める（Claude の訓練バイアスによる旧語彙 drift を防ぐため）。旧 `HIGH` / `MEDIUM` / `LOW` を期待するパースロジックは除去する。

8.6. When `rw audit` が Vault の `AGENTS/audit.md` を読み込んだ時点で、ファイル内容に旧 severity 語彙（`HIGH` / `MEDIUM` / `LOW` のいずれか）が severity トークンとして残存していることを検出した場合, the CLI shall Claude にプロンプトを送る前に abort し、再デプロイを促す明示的なエラーメッセージ（例: 「`AGENTS/audit.md` に deprecated severity vocabulary (`HIGH` / `MEDIUM` / `LOW`) が含まれています。`templates/AGENTS/` を再デプロイしてください。詳細は CHANGELOG を参照。」）を stderr に出力し、終了コード `1`（自身の finding 由来ではない失敗として AC 3.2 / 3.4 の exit 1 に該当）で終了する。これは旧 Vault に新 `rw_light.py` を組み合わせた場合の Claude drift を検出前に防ぐ安全ネット（AC 6.5 Vault 再デプロイ手順を運用者が失念した場合の fallback）。検出対象は severity 語彙としての使用に限定し、他の文脈（例: コメント内での歴史的言及や Migration Notes ブロック）と区別する判定方式は設計フェーズで確定する。
