# Requirements Document

## Introduction

仕様案で定義されている audit タスクの CLI コマンドを実装する。Wiki の整合性・構造・完全性を定期的に検証する4段階の監査サイクルをサブコマンドとして提供する。micro と weekly は Python コードで完結する静的チェック、monthly と quarterly は Claude CLI を呼び出す LLM 支援監査である。すべての audit は読み取り専用であり、wiki/・raw/・review/ への書き込みは行わない。監査結果は `logs/` にのみ Markdown レポートとして出力し、修正はユーザの明示指示に委ねる。

### ティア対応表

| CLI サブコマンド | AGENTS/audit.md ティア | 実装方式 |
|---|---|---|
| `rw audit micro` | Tier 0: Micro-check | Python 静的チェック |
| `rw audit weekly` | Tier 1: Structural Audit | Python 静的チェック |
| `rw audit monthly` | Tier 2: Semantic Audit | Claude CLI (LLM 支援) |
| `rw audit quarterly` | Tier 3: Strategic Audit | Claude CLI (LLM 支援) |

### Severity 体系

CLI はプロジェクト全体で統一された3水準の severity を使用する。AGENTS/audit.md が定義する4段階（CRITICAL / HIGH / MEDIUM / LOW）は Claude の内部分類であり、CLI は出力時に以下のマッピングでプロジェクト標準に変換する。

| AGENTS/audit.md (Claude 内部) | CLI 出力 | status への影響 | 意味 |
|---|---|---|---|
| CRITICAL | ERROR | → FAIL | 対処必須 |
| HIGH | ERROR | → FAIL | 対処必須 |
| MEDIUM | WARN | — | 注意喚起 |
| LOW | INFO | — | 改善提案 |

この3水準は既存コマンド（`rw lint`: PASS/WARN/FAIL、`rw lint query`: ERROR/WARN/INFO）と意味的に同一であり、終了コードも統一する（exit 0: PASS、exit 1: FAIL）。ERROR 内での優先度表示（CRITICAL 由来 / HIGH 由来の区別保持）は設計フェーズで決定する。

## Boundary Context

- **In scope**: `rw audit micro`・`rw audit weekly`・`rw audit monthly`・`rw audit quarterly` の4サブコマンド実装、`logs/` への監査レポート出力、標準出力へのサマリー表示、usage 表示更新、`docs/user-guide.md` への audit リファレンス追記、CHANGELOG.md 追記、実行モード更新（templates/CLAUDE.md・AGENTS/audit.md・AGENTS/README.md の Execution Mode を Prompt → CLI (Hybrid) に変更）、AGENTS/ファイルをプロンプトの正規ソースとする一元管理方式の適用
- **Out of scope**: 監査結果に基づく自動修正（読み取り専用の原則）、`[CONFLICT]`/`[TENSION]`/`[AMBIGUOUS]` タグの wiki ページへの書き込み（ユーザの明示指示が必要）、AGENTS/audit.md のルール定義・処理内容の変更（agents-system スペック管轄。ただし Execution Mode 表記の更新は本スペックで実施する）、テスト（test-suite スペック管轄）、`logs/` 内の古いレポートのローテーション・自動削除（蓄積量が小さいため現時点で不要。運用者が手動削除で対応）
- **Adjacent expectations**:
  - `templates/AGENTS/audit.md` がプロンプトルールの正規ソースである。CLI はこれをプロンプト構築に使用するが、ルール定義内容の変更は行わない
  - `wiki/` のコンテンツが存在し、コミット済みであることを前提とする
  - `templates/AGENTS/naming.md`・`page_policy.md`・`git_ops.md` が audit 用ポリシーとして CLAUDE.md マッピング表で定義されている
  - cli-query で実装済みの Prompt Engine（`parse_agent_mapping()`・`load_task_prompts()`・`call_claude()`・`read_wiki_content()`）を monthly/quarterly で再利用する
- **Design constraint: micro/weekly と monthly/quarterly の実装方式の違い**:
  - micro/weekly は Python コード内で静的チェックを実行し、Claude CLI を呼び出さない
  - monthly/quarterly は AGENTS/audit.md をプロンプトソースとして Claude CLI を呼び出す LLM 支援監査である
  - この方式の違いにより、micro/weekly は Prompt Engine を使用せず、monthly/quarterly のみが使用する。具体的な設計は設計フェーズで決定する
- **Design constraint: naming.md ルールの実装方式**:
  - naming.md の命名規則（小文字・ハイフン区切り・ASCII のみ）は機械的に単純であるため、weekly の命名チェックは Python コードに直接実装する（naming.md を実行時にパースしない）。naming.md の内容変更時は Python コードも同期する必要がある
- **Design constraint: micro/weekly の severity 割り当て**:
  - micro/weekly は Python 静的チェックのため、各チェック項目の severity（ERROR / WARN / INFO）を Python コード内で決定する必要がある。AGENTS/audit.md の Priority レベル定義（CRITICAL〜LOW）が参考になるが、リンク切れ・index.md 未登録・命名規則違反など明示的に割り当てられていない項目がある。severity は終了コード（exit 1 if ERROR）に直結するため、設計フェーズで全チェック項目の severity を確定する
- **Design constraint: frontmatter パーサーの制約**:
  - 既存の `parse_frontmatter()` は regex ベース（`key: value` の行分割）であり、厳密な YAML パーサーではない。ネスト構造やマルチライン値は非対応。Req 1.1 の「YAML パースエラー」検出精度はこのパーサーの能力に依存する。YAML ライブラリ（PyYAML 等）の導入要否は設計フェーズで判断する
- **Design constraint: micro のスコープ特定方法**:
  - AGENTS/audit.md Tier 0 は「現在のingestまたは更新に影響されたページのみ」をスコープとし、全ページスキャンを禁止している。CLI で「最近更新されたページ」をどう特定するか（git diff、引数指定、その他）は設計フェーズで決定する
- **Design constraint: Claude CLI 呼び出しのタイムアウト（monthly/quarterly）**:
  - 既存の `call_claude()` にはタイムアウトが設定されていない（cli-query と共通の課題）。audit は wiki 全体の分析で応答時間が長くなるため（50ページで30-60秒、100ページで40-120秒）、リスクが顕在化しやすい。タイムアウト値の設定要否は設計フェーズで判断する
- **Design constraint: monthly/quarterly のレスポンス形式**:
  - monthly/quarterly で Claude に要求する出力形式（構造化 JSON、Markdown、その他）は設計フェーズで決定する。cli-query では `output_format="json"` で JSON を要求しパース確実性を確保した。audit でも同様に構造化出力を要求するか、AGENTS/audit.md の Markdown フォーマットをそのまま使うかはトレードオフ（パース確実性 vs エージェント定義との整合性）がある
- **Design constraint: 大規模 wiki のハンドリング（monthly/quarterly）**:
  - monthly/quarterly は wiki 全体の整合性・矛盾を検出するため、原則として全ページが対象となる。wiki ファイル数が多い場合（目安: 150ページ超で Claude のコンテキストウィンドウ 200K トークンに近づく）、分割戦略が必要となる
  - cli-query の2段階方式（質問で関連ページを絞り込む）は audit には直接適用できない。audit は質問ベースではなく全体の整合性検査であるため、ページ選択の基準が異なる。audit 固有の分割方式（バッチ分割、カテゴリ別分割、要約→詳細の2段階等）を設計フェーズで決定する

## Requirements

### Requirement 1: audit micro サブコマンド

**Objective:** 運用者として、wiki 更新後にマイクロチェックを実行し、直近の更新で生じたリンク切れ・index 更新漏れ・frontmatter 崩れを素早く検知したい。

#### Acceptance Criteria

1.1. When 運用者が `rw audit micro` を実行した場合, the CLI shall 最近更新されたページを対象として以下の静的チェックを実行する: リンク切れ（wiki 内 `[[link]]` の参照先ページ不在）、`index.md` への未登録ページ、frontmatter の YAML パースエラー（パース不能な YAML）

1.2. The CLI shall audit micro のスコープを全ページではなく最近更新されたページに限定する（AGENTS/audit.md Tier 0 の定義に準拠）。スコープ特定方法は設計フェーズで決定する

1.3. When audit micro の検査が完了した場合, the CLI shall 検出された問題を severity（ERROR / WARN / INFO）付きで標準出力にサマリー表示する

1.4. When audit micro の検査が完了した場合, the CLI shall `logs/` にレポートファイルを出力する

1.5. When audit micro で ERROR severity の問題が検出されなかった場合, the CLI shall 終了コード 0 で終了する（WARN / INFO のみの場合も終了コード 0）

1.6. When audit micro で ERROR severity の問題が1件以上検出された場合, the CLI shall 終了コード 1 で終了する

1.7. When audit micro の対象ページが0件の場合（最近の wiki 更新なし）, the CLI shall 「チェック対象なし」を表示し、レポートには pages scanned: 0 を記載して終了コード 0 で終了する

1.8. The CLI shall audit micro の実行に Claude CLI を使用しない（Python コードで完結する静的チェック）

### Requirement 2: audit weekly サブコマンド

**Objective:** 運用者として、週次の構造監査を実行し、孤立ページ・双方向リンクの欠落・命名規則違反を検知したい。

#### Acceptance Criteria

2.1. When 運用者が `rw audit weekly` を実行した場合, the CLI shall wiki/ 内の全ページに対して以下の構造チェックを実行する: 孤立ページ（他ページからリンクされていない、index.md からのリンクを除く）、双方向リンクの欠落、命名規則違反（naming.md に定義された命名規則 — 小文字・ハイフン区切り・ASCII のみ — に準拠するかを検査する）、`source:` フィールドの空・欠落。page_policy.md にページ種別ごとの必須セクション定義が存在する場合は、その定義に基づく必須セクション欠落もチェックする

2.2. When audit weekly の検査が完了した場合, the CLI shall micro チェックの全項目（リンク切れ・index.md 未登録・frontmatter パースエラー）も全ページに対して実行する（weekly は micro のスーパーセットであり、スコープは全ページに拡張される）

2.3. When audit weekly の検査が完了した場合, the CLI shall 検出された問題を severity（ERROR / WARN / INFO）付きで標準出力にサマリー表示し、`logs/` にレポートファイルを出力する

2.4. When audit weekly で ERROR severity の問題が検出されなかった場合, the CLI shall 終了コード 0 で終了する（WARN / INFO のみの場合も終了コード 0）

2.5. When audit weekly で ERROR severity の問題が1件以上検出された場合, the CLI shall 終了コード 1 で終了する

2.6. The CLI shall audit weekly の実行に Claude CLI を使用しない（Python コードで完結する静的チェック）

### Requirement 3: audit monthly サブコマンド

**Objective:** 運用者として、月次の意味監査を実行し、wiki 内のページ間の矛盾・曖昧さを検知したい。

#### Acceptance Criteria

3.1. When 運用者が `rw audit monthly` を実行した場合, the CLI shall Claude CLI 呼び出し前に処理中メッセージを標準出力に表示し、Claude CLI を呼び出して AGENTS/audit.md Tier 2 の定義に基づいて wiki 内の意味的な問題を検出する

3.2. The CLI shall monthly 実行時のプロンプトに Tier 2（Semantic Audit）を実行する旨の指示を含め、Claude に実行すべきティアを明示する

3.3. When audit monthly の検査が完了した場合, the CLI shall Claude が付与した `[CONFLICT]`・`[TENSION]`・`[AMBIGUOUS]` のマーカーを severity と併記してレポートに記載する（例: `[ERROR] [CONFLICT] ...`、`[WARN] [TENSION] ...`）

3.4. When audit monthly の検査が完了した場合, the CLI shall 検出された問題を severity（ERROR / WARN / INFO）付きで標準出力にサマリー表示し、`logs/` にレポートファイルを出力する

3.5. The CLI shall audit monthly のレポートに `[CONFLICT]`・`[TENSION]`・`[AMBIGUOUS]` マーカーを記載するが、wiki ページへのタグ書き込みは行わない

3.6. When audit monthly で ERROR severity の問題が検出されなかった場合, the CLI shall 終了コード 0 で終了する（WARN / INFO のみの場合も終了コード 0）

3.7. When audit monthly で ERROR severity の問題が1件以上検出された場合, the CLI shall 終了コード 1 で終了する

3.8. The CLI shall audit monthly の実行に AGENTS/audit.md をプロンプトの正規ソースとして使用する

### Requirement 4: audit quarterly サブコマンド

**Objective:** 運用者として、四半期の戦略的監査を実行し、wiki のグラフ構造の俯瞰・カバレッジギャップ・スキーマ改訂提案を得たい。

#### Acceptance Criteria

4.1. When 運用者が `rw audit quarterly` を実行した場合, the CLI shall Claude CLI 呼び出し前に処理中メッセージを標準出力に表示し、Claude CLI を呼び出して AGENTS/audit.md Tier 3 の定義に基づいて wiki の戦略的な問題を検出する

4.2. The CLI shall quarterly 実行時のプロンプトに Tier 3（Strategic Audit）を実行する旨の指示を含め、Claude に実行すべきティアを明示する

4.3. When audit quarterly の検査が完了した場合, the CLI shall 検出された問題と提案を severity（ERROR / WARN / INFO）付きで標準出力にサマリー表示し、`logs/` にレポートファイルを出力する

4.4. When audit quarterly で ERROR severity の問題が検出されなかった場合, the CLI shall 終了コード 0 で終了する（WARN / INFO のみの場合も終了コード 0）

4.5. When audit quarterly で ERROR severity の問題が1件以上検出された場合, the CLI shall 終了コード 1 で終了する

4.6. The CLI shall audit quarterly の実行に AGENTS/audit.md をプロンプトの正規ソースとして使用する

### Requirement 5: レポート出力共通仕様

**Objective:** 運用者として、すべての監査レベルで統一されたレポート形式を得ることで、監査結果の比較・追跡を容易にしたい。

#### Acceptance Criteria

5.1. The CLI shall すべての audit サブコマンドのレポートを `logs/audit-<tier>-<YYYYMMDD-HHMMSS>.md` 形式のファイル名で出力する。`<tier>` は micro / weekly / monthly / quarterly のいずれか

5.2. The CLI shall レポートに以下のセクションを含める: Summary（severity 別問題数の集計）、Findings（severity 付き問題一覧。micro/weekly は Structural Findings、monthly は Semantic Findings、quarterly は Strategic Findings として分類）、Metrics、Recommended Actions

5.3. The CLI shall 各問題にプロジェクト標準の severity（ERROR / WARN / INFO）を付与する。micro / weekly では Python コードが直接 severity を割り当てる。monthly / quarterly では Claude が返す AGENTS/audit.md の4段階（CRITICAL / HIGH / MEDIUM / LOW）を Introduction の Severity 体系に従って3水準にマッピングする。ERROR 内での優先度表示（CRITICAL 由来 / HIGH 由来の区別保持）は設計フェーズで決定する。なお、severity（問題の影響度）と `[CONFLICT]`/`[TENSION]`/`[AMBIGUOUS]` マーカー（問題の種類）は直交する次元であり、Claude が両者を独立に割り当てる。CLI はマーカーと severity の固定マッピングを行わない

5.4. The CLI shall レポートの Metrics セクションにティアに応じた該当メトリクスを含める。利用可能なメトリクスカテゴリ: Structural（スキャンページ数、orphan ページ数、broken link 数、index 欠落数、frontmatter 問題数）、Connectivity（双方向リンク準拠率）、Reliability（source 保有ページ率）。monthly ではさらに `[CONFLICT]`・`[TENSION]`・`[AMBIGUOUS]` の件数を含める。各ティアで必須とするメトリクスの選定は設計フェーズで決定する（micro はスコープが限定されるため全ページ統計のメトリクスは対象外）

5.5. When 運用者が `rw audit` をサブコマンドなしで実行した場合, the CLI shall 利用可能なサブコマンド（micro / weekly / monthly / quarterly）の一覧と使用方法を表示する

5.6. The CLI shall audit の出力先を `logs/` ディレクトリに限定する。`wiki/`・`raw/`・`review/` にはファイルを出力しない

5.7. When レポートファイルの出力が完了した場合, the CLI shall レポートファイルのパスを標準出力に表示する

### Requirement 6: 読み取り専用の保証

**Objective:** 運用者として、audit コマンドが wiki/・raw/・review/ のファイルを変更しないことを保証したい。誤操作によるデータ破損を防ぐためである。

#### Acceptance Criteria

6.1. The CLI shall audit の実行中に `wiki/` 配下のファイルを作成・変更・削除しない

6.2. The CLI shall audit の実行中に `raw/` 配下のファイルを作成・変更・削除しない

6.3. The CLI shall audit の実行中に `review/` 配下のファイルを作成・変更・削除しない

6.4. The CLI shall audit 実行後に自動コミットを行わない。レポートファイルのコミットは運用者が手動で行う

### Requirement 7: エラー処理

**Objective:** 運用者として、audit コマンド実行時のエラーが明確に報告され、データが破損しないことを保証したい。

#### Acceptance Criteria

7.1. If `wiki/` ディレクトリが存在しない、または `.md` ファイルが1つも存在しない場合, then the CLI shall エラーメッセージを表示し、終了コード 1 で終了する

7.2. If Claude CLI の呼び出しが失敗した場合（monthly / quarterly）, then the CLI shall エラーメッセージを表示し、終了コード 1 で終了する

7.3. If Claude CLI のレスポンスが有効なフォーマットでない場合（monthly / quarterly）, then the CLI shall パースエラーを表示し、終了コード 1 で終了する

7.4. If `logs/` ディレクトリが存在しない場合, then the CLI shall 自動的に作成する

7.5. If プロンプト構築に必要な AGENTS/ファイルが存在しない、または CLAUDE.md のマッピング表がパースできない場合（monthly / quarterly）, then the CLI shall エラーメッセージを表示し、終了コード 1 で終了する

7.6. If `wiki/` の作業ツリーが dirty な場合, the CLI shall 警告メッセージを表示する

7.7. If `index.md` が存在しない場合（micro / weekly の index.md 未登録チェック）, then the CLI shall 当該チェックをスキップし、WARNING を表示する

7.8. If wiki/ 内の個別ファイルが読み込み不能な場合（エンコーディングエラー、パーミッション等）, then the CLI shall 当該ファイルを ERROR として報告しスキップし、残りのページの検査を継続する

### Requirement 8: ドキュメント更新

**Objective:** 運用者として、audit コマンドの使い方が `docs/user-guide.md` と CHANGELOG に記載されていることで、コマンドの正しい利用法を把握したい。

#### Acceptance Criteria

8.1. 本スペックの成果物として、`docs/user-guide.md` に `rw audit micro`・`rw audit weekly`・`rw audit monthly`・`rw audit quarterly` の使用方法・引数・出力例が追記されていること

8.2. 本スペックの成果物として、CHANGELOG.md の `[Unreleased]` セクションに cli-audit スペックの変更内容が追記されていること

### Requirement 9: 実行モード更新

**Objective:** 運用者として、audit タスクの実行モードが CLI 実装を反映した正確な情報であることで、正しい実行手順を把握したい。

#### Acceptance Criteria

9.1. 本スペックの成果物として、`templates/CLAUDE.md` のマッピング表で audit の Execution Mode が「CLI (Hybrid)」に更新されていること

9.2. 本スペックの成果物として、`templates/AGENTS/audit.md` の Execution Mode セクションの実行モード表記および関連する説明文が CLI (Hybrid) の実態に合わせて更新されていること

9.3. 本スペックの成果物として、`templates/AGENTS/README.md` のエージェント一覧テーブルで audit の実行モードが「CLI (Hybrid)」に更新されていること

### Requirement 10: プロンプトの一元管理

**Objective:** 運用者として、AGENTS/ファイルのルール変更が CLI の動作に自動的に反映されることで、ルール定義の二重管理による乖離を防ぎたい。

#### Acceptance Criteria

10.1. The CLI shall monthly / quarterly の実行時に AGENTS/ファイルをプロンプトの正規ソースとして使用し、プロンプトルールを Python コード内にハードコードしない

10.2. When AGENTS/ファイルのルール定義が更新された場合, the CLI shall 次回実行時に更新後の内容を使用する（CLI コードの変更なしに反映される）
