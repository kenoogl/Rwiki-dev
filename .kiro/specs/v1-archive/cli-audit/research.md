# Research & Design Decisions

## Summary
- **Feature**: `cli-audit`
- **Discovery Scope**: Extension（既存 CLI システムへの audit サブコマンド追加）
- **Key Findings**:
  - 既存 Prompt Engine（parse_agent_mapping / load_task_prompts / call_claude）が monthly/quarterly で再利用可能。ただし read_wiki_content() は >20 ファイルで index.md のみ返すため audit には不適合 → read_all_wiki_content() を新設
  - rw_light.py のモノリシック CLI パターン（コマンドディスパッチ → ハンドラ関数 → exit code 返却、グローバル定数使用）に従う
  - parse_frontmatter() は不正行を黙ってスキップするため、frontmatter エラー検出には raw テキスト直接検査が必要
  - INDEX_MD は Vault ルート直下（ROOT/index.md）であり、wiki/index.md ではない

## Research Log

### CLI コマンドディスパッチパターン
- **Context**: audit サブコマンドの追加方法を決定するため
- **Findings**:
  - main() が argv[1] でトップレベルコマンドを分岐
  - query のように argv[2] でサブコマンドを分岐するパターンが確立済み
  - 全ハンドラは int（exit code）を返却
- **Implications**: `cmd_audit(args)` → `cmd_audit_micro()` 等のディスパッチパターンを採用

### Prompt Engine の再利用可能性
- **Context**: monthly/quarterly で Claude CLI を呼び出すインフラの確認
- **Findings**:
  - `parse_agent_mapping()`: CLAUDE.md マッピング表をパースし、タスク名→エージェント+ポリシー辞書を返却
  - `load_task_prompts()`: エージェント+ポリシーファイルを結合してプロンプト文字列を返却
  - `call_claude()`: subprocess で `claude -p <prompt>` を実行。タイムアウト未設定
  - `read_wiki_content()`: wiki 全文を返却。20 ファイル超の場合は index.md のみ返却（2段階戦略）
  - cli-query で `output_format="json"` による構造化出力パターンが確立済み
- **Implications**: monthly/quarterly は既存パターンを踏襲。ただし audit 用に read_wiki_content の全ページ取得が必要な場合がある

### parse_frontmatter() の能力
- **Context**: micro/weekly のフロントマターチェックで使用する既存パーサーの制約確認
- **Findings**:
  - Regex ベース（`key: value` 行分割）。ネスト構造・マルチライン値は非対応
  - `---` で囲まれたブロックを抽出し、行ごとにキー・バリューをパース
  - 戻り値: `(dict, body_text)`
  - YAML パースエラー = `---` ブロック内で `key: value` にマッチしない行の存在
- **Implications**: PyYAML 導入不要。パーサーの制約は要件で承認済み

### naming.md ルールの実装方式
- **Context**: weekly の命名チェックを Python 直接実装にする判断
- **Findings**:
  - naming.md のルール: 小文字、ハイフン区切り、ASCII のみ
  - 既存の slugify 関数が類似ロジックを持つ
  - regex `^[a-z0-9]+(-[a-z0-9]+)*\.md$` で検証可能
- **Implications**: naming.md をランタイムパースせず、Python コード内に直接実装（要件の Design constraint で決定済み）

### micro のスコープ特定方法
- **Context**: 「最近更新されたページ」の特定方法を決定するため
- **Findings**:
  - git diff でコミット済み変更を検出可能
  - `git diff --name-only HEAD~1 -- wiki/` で直近コミットの変更ファイル
  - `--diff-filter=d` で削除ファイルを除外
  - 未コミットの変更は `git diff --name-only -- wiki/` + `git ls-files --others wiki/` で検出
  - コミット範囲を引数で指定可能にすると柔軟性が高い
- **Implications**: デフォルトは直近コミット + 未コミット変更。オプションで範囲指定可能

### 大規模 wiki のハンドリング
- **Context**: monthly/quarterly で wiki 全体を Claude に渡す際のトークン制限対策
- **Findings**:
  - 現行の read_wiki_content() は 20 ファイル超で index.md のみに切り替え
  - audit は全ページの整合性検査のため、この戦略は直接適用不可
  - 150 ページ超で 200K トークンに近づく見積もり
  - 分割戦略: wiki/ のサブディレクトリ（カテゴリ）単位でバッチ分割し、各バッチの findings を集約
- **Implications**: 初期実装は全ページ一括送信。ページ数閾値超過時に警告を表示。将来的にバッチ分割を追加

## Design Decisions

### Decision: micro スコープに git diff を使用
- **Context**: AGENTS/audit.md Tier 0 は「最近更新されたページのみ」をスコープとする
- **Alternatives Considered**:
  1. git diff（直近コミット + 未コミット変更）
  2. ファイルの mtime で判定
  3. CLI 引数で対象ファイルを明示指定
- **Selected Approach**: git diff ベース。デフォルトは直近コミット + 未コミット変更（HEAD との差分 + HEAD~1..HEAD）。cmd_audit_micro() は引数なし（グローバル定数使用）で、範囲指定オプションは初期実装では提供しない
- **Rationale**: Git 統合が既に確立されたプロジェクト。mtime はコピー・チェックアウトで不正確になる。git diff は信頼性が高い
- **Trade-offs**: Git リポジトリが必須（プロジェクトの前提条件として許容）

### Decision: monthly/quarterly のレスポンス形式に JSON を採用
- **Context**: Claude からの応答をパースする形式の選択
- **Alternatives Considered**:
  1. 構造化 JSON（cli-query パターン踏襲）
  2. AGENTS/audit.md の Markdown フォーマットをそのまま使用
- **Selected Approach**: JSON（`output_format="json"` で構造化出力を要求）
- **Rationale**: cli-query で確立済みのパターン。パース確実性が高い。severity マッピングやメトリクス集計が容易
- **Trade-offs**: AGENTS/audit.md の Markdown 出力定義との乖離。プロンプトで JSON スキーマを明示する必要あり

### Decision: ERROR 内の優先度表示
- **Context**: CRITICAL/HIGH → ERROR マッピング後に元の優先度を保持するか
- **Alternatives Considered**:
  1. `[ERROR:CRITICAL]` / `[ERROR:HIGH]` のように元の優先度をサブラベルで表示
  2. 元の優先度を保持せず、すべて `[ERROR]` に統一
- **Selected Approach**: サブラベル方式。レポート内で `[ERROR:CRITICAL]` / `[ERROR:HIGH]` として区別を保持
- **Rationale**: 運用者がトリアージする際に優先度情報が有用。表示上のコストが低い
- **Trade-offs**: micro/weekly の ERROR にはサブラベルなし（Python コードが直接 ERROR を割り当てるため）

### Decision: call_claude() のタイムアウト設定
- **Context**: 既存の call_claude() にタイムアウトが未設定。audit は wiki 全体分析で応答が長くなる
- **Alternatives Considered**:
  1. call_claude() にグローバルタイムアウトを追加
  2. audit 専用のタイムアウト付き呼び出しラッパー
  3. タイムアウトなし（現状維持）
- **Selected Approach**: call_claude() にオプショナルな timeout パラメータを追加（デフォルト: None = タイムアウトなし）。audit ハンドラが `call_claude(prompt, timeout=300)` で呼び出す
- **Rationale**: デフォルト None により既存の cli-query 呼び出しの動作は変わらない。audit 固有のタイムアウトは呼び出し側で指定
- **Trade-offs**: 大規模 wiki で 300 秒を超える可能性。--timeout CLI オプションでオーバーライド可能にする

### Decision: Severity 割り当て（micro/weekly）
- **Context**: Python 静的チェックの各項目に severity を割り当てる必要がある
- **Selected Approach**:
  | チェック項目 | Severity | 根拠 |
  |---|---|---|
  | リンク切れ（wiki 内 `[[link]]` 参照先不在） | ERROR | データ整合性の直接的な問題 |
  | frontmatter 構造的パースエラー（空ブロック・不正行・未閉じ） | ERROR | メタデータの構造的破損（Req 1.1） |
  | ファイル読み込み不能 | ERROR | 検査不能 |
  | title フィールド欠落 | WARN | AGENTS/audit.md 定義。Req 1.1「パースエラー」の範囲外のため ERROR ではなく WARN |
  | index.md 未登録ページ | WARN | 発見可能性の低下 |
  | 孤立ページ | WARN | ナビゲーション構造の問題 |
  | 双方向リンク欠落 | WARN | リンク構造の不完全性 |
  | 命名規則違反 | WARN | 規約違反 |
  | source フィールド空・欠落 | INFO | 完全性の改善提案 |
  | 必須セクション欠落 | INFO | ページ品質の改善提案 |

### Decision: read_wiki_content() は audit に不適合 → read_all_wiki_content() 新設
- **Context**: 設計レビューで発覚。read_wiki_content(scope=None) は >20 ファイルで index.md のみ返す
- **Alternatives Considered**:
  1. read_wiki_content() にフラグを追加して全ページ返却モードを追加
  2. audit 専用の read_all_wiki_content() を新設
- **Selected Approach**: 新関数 read_all_wiki_content() を新設
- **Rationale**: read_wiki_content() の既存動作を変更するとcli-query に影響する。audit は「全ページ必須」という明確に異なるユースケース
- **Trade-offs**: コードの重複（ファイル結合ロジック）が若干発生するが、責任分離を優先

### Decision: CLAUDE.md マッピング表は単一 audit エントリを維持
- **Context**: 設計レビュー指摘。monthly/quarterly を別タスクに分割するか、単一 audit エントリを共用するか
- **Selected Approach**: 単一 `audit` エントリを維持。ティア差異は build_audit_prompt() で制御
- **Rationale**: monthly と quarterly は同じ Agent + 同じ Policy を使用。マッピング表の肥大化を回避

### Decision: frontmatter エラー検出は raw テキスト直接検査
- **Context**: 設計レビューで発覚。parse_frontmatter() は不正行を黙ってスキップし、エラーを検出できない
- **Selected Approach**: check_frontmatter() は parse_frontmatter() に依存せず、raw テキストから `---` ブロック内の構造問題を直接検出
- **Rationale**: parse_frontmatter() の改修は他コマンドに影響。audit 専用の検出ロジックが適切

### Decision: index.md パスは ROOT 直下（INDEX_MD グローバル定数）
- **Context**: 設計レビューで発覚。設計が暗黙に wiki/index.md を前提としていたが、実際は ROOT/index.md
- **Selected Approach**: グローバル定数 INDEX_MD を使用（既存パターン通り）

### Decision: source フィールドチェックは「空・欠落」のみ（要件 2.1 準拠）
- **Context**: AGENTS/audit.md Tier 1 は「sources: の参照先 raw ファイル存在確認」も定義しているが、要件 2.1 は「source: の空・欠落」のみ
- **Selected Approach**: 要件に従い「空・欠落」のみチェック。raw ファイル参照確認は対象外
- **Rationale**: 要件が権威的ソース。AGENTS 定義との差異は認識した上で、スコープを限定

### Decision: ensure_dirs() は audit では使用しない
- **Context**: 第2回設計レビューで発覚。ensure_dirs() は WIKI_SYNTH（wiki/synthesis/）と SYNTH_CANDIDATES（review/）も作成する
- **Selected Approach**: logs/ の作成は `write_text()` がファイル書き出し時に親ディレクトリを自動作成する既存動作で充足する（明示的な `os.makedirs()` 不要）
- **Rationale**: ensure_dirs() を使うと Req 6.1（wiki/ 書き込み禁止）・Req 6.3（review/ 書き込み禁止）に違反。write_text() の既存動作で Req 7.4 を満たす

### Decision: Finding / WikiPage は NamedTuple で定義
- **Context**: 既存コードは dataclasses を import していない。lint results は dict ベース
- **Selected Approach**: NamedTuple を使用（typing モジュールは既に import 済み）
- **Rationale**: 既存パターンとの一貫性。immutable な値型として適切

### Decision: all_pages_set は wiki/ からの相対パスの集合
- **Context**: wiki/ はサブディレクトリ（concepts/, methods/ 等）を持つ。リンク解決に影響
- **Selected Approach**: wiki/ からの相対パス（例: "concepts/my-page.md"）の集合。[[link]] はファイル名部分で検索
- **Rationale**: サブディレクトリをまたいだリンク解決が可能

### Decision: check_bidirectional_links の双方向の定義
- **Context**: 「双方向リンク欠落」の具体的定義が未決定だった
- **Selected Approach**: A→B リンクに対して B→A リンクが存在するかを全ペアでチェック。index.md からのリンクは除外
- **Rationale**: AGENTS/audit.md の「双方向リンク準拠率」メトリクスと整合

### Decision: title 欠落チェックは WARN（ERROR ではない）
- **Context**: Req 1.1 は「YAML パースエラー」を定義。title 欠落はパースエラーではなくフィールド欠落
- **Selected Approach**: 構造的パースエラー（空ブロック、不正行、未閉じ）は ERROR。title 欠落は WARN
- **Rationale**: 要件の「パースエラー」の範囲を超える検出は severity を下げて分離

### Decision: weekly の tags/updated フィールドチェックはスコープ外
- **Context**: AGENTS/audit.md Tier 1 は tags・updated 欠落を定義。要件 2.1 は weekly 固有チェック項目を列挙しているが、frontmatter フィールドの追加チェックは含まれていない
- **Selected Approach**: スコープ外とする。将来の拡張候補として記録
- **Rationale**: 要件が権威的ソース。AGENTS 定義のフルカバレッジは agents-system スペックの管轄

### Decision: --timeout CLI オプションの追加
- **Context**: 大規模 wiki で 300 秒を超える可能性がある
- **Selected Approach**: cmd_audit_monthly/quarterly に --timeout オプションを追加。デフォルト 300 秒
- **Rationale**: 運用者が環境に応じてオーバーライド可能にする

### Decision: read_all_wiki_content に ROOT/index.md と ROOT/log.md を含める
- **Context**: AGENTS/audit.md の Input 定義が「index.md・log.md を含む」と明記。INDEX_MD と CHANGE_LOG_MD は wiki/ 外（ROOT 直下）にある
- **Selected Approach**: read_all_wiki_content() が wiki/ 全ファイルに加え ROOT/index.md と ROOT/log.md を結合する
- **Rationale**: monthly/quarterly で Claude が index.md の構造整合性やグラフ構造を分析するために必要

### Decision: parse_audit_response の例外型は ValueError（既存パターン統一）
- **Context**: 既存の parse_extract_response / parse_fix_response は ValueError を使用
- **Selected Approach**: ValueError に統一。当初 RuntimeError を検討したが一貫性を優先
- **Rationale**: 同種の parse 関数群で例外型を揃えることで保守性を向上

### Decision: 陳腐化エントリ検出はスコープ外
- **Context**: AGENTS/audit.md Tier 1 は index.md の「陳腐化エントリ」検出を定義。要件は「未登録ページ」のみ
- **Selected Approach**: スコープ外。check_index_registration の docstring に明記
- **Rationale**: 要件が権威的ソース。技術的に容易なため将来の拡張候補

### Decision: Allowed Dependencies のパス表記を実行時パスに修正
- **Context**: 設計が templates/AGENTS/ と記載していたが、実行時は ROOT/AGENTS/（デプロイ済み）を参照
- **Selected Approach**: ROOT/AGENTS/ と ROOT/CLAUDE.md を参照する旨に修正。templates/ はマスターコピー
- **Rationale**: load_task_prompts() が os.path.join(ROOT, entry["agent"]) でパス解決するため

### Decision: parse_audit_response にスキーマ検証を追加
- **Context**: セキュリティレビューで指摘。wiki コンテンツ経由のプロンプトインジェクションにより Claude が不正な JSON 構造を返すリスク
- **Selected Approach**: トップレベル必須キー検証 + findings 要素の必須フィールド検証 + severity 値検証 + message 改行除去
- **Rationale**: 既存 parse_extract_response() の必須キー検証パターンを踏襲しつつ、severity 値と message の安全性を追加。不正 severity の finding はスキップ（全体エラーにしない）

### Decision: build_audit_prompt の出力形式指示をプロンプト末尾に配置
- **Context**: プロンプトインジェクション軽減。wiki コンテンツに偽の出力指示が含まれるリスク
- **Selected Approach**: 既存 build_query_prompt() と同一パターンで出力形式指示を末尾に配置
- **Rationale**: Claude は最後の指示を優先する傾向がある。完全防御ではないが、スキーマ検証と組み合わせて影響を最小化

### Decision: AGENTS/audit.md の Markdown 出力定義と JSON 出力指示の競合解消
- **Context**: AGENTS/audit.md は Markdown レポート形式の出力を定義。CLI は JSON を要求。Claude が矛盾する指示を受け取る
- **Selected Approach**: build_audit_prompt() のティア指示に「Markdown は対話型用、CLI モードでは JSON」と明示的にオーバーライド
- **Rationale**: AGENTS/audit.md の変更は agents-system スペック管轄。プロンプト内の指示で出力フォーマットを制御する

### Decision: ティア排他指示の追加
- **Context**: AGENTS/audit.md は4ティア全定義を含む。monthly で Tier 0/1 のチェックが混入するリスク
- **Selected Approach**: ティア指示に「他ティアのチェック項目は実行しないでください」と排他的限定を明記
- **Rationale**: micro/weekly の静的チェックと monthly/quarterly の LLM チェックの重複を防止

### Decision: Execution Declaration 抑制
- **Context**: AGENTS/audit.md の実行宣言が JSON 出力前に付加され、json.loads() が失敗するリスク
- **Selected Approach**: ティア指示に「実行宣言不要、JSON のみ出力」を追加
- **Rationale**: CLI モードでは宣言は不要。JSON パースの確実性を確保

### Decision: JSON スキーマを具体的サンプルで提示
- **Context**: 設計の Python 型注釈風スキーマは Claude 向けではない
- **Selected Approach**: Claude に渡す具体的な JSON サンプル（値入り）を設計に記載。実装時に json.dumps() で埋め込む
- **Rationale**: 既存 build_query_prompt() パターン（スキーマを ```json ブロックで提示）に準拠

## Risks & Mitigations
- **call_claude() タイムアウト超過**: audit ハンドラが timeout=300 で呼び出し。TimeoutExpired は call_claude() 内で RuntimeError に変換、main() の既存例外ハンドラで処理
- **大規模 wiki でのトークン制限**: read_all_wiki_content() が 150 ページ超で警告表示。処理は続行。将来バッチ分割対応
- **parse_frontmatter() の silent skip**: check_frontmatter() が raw テキストを直接検査して構造問題を検出。parse_frontmatter() には依存しない
- **Claude JSON 応答の不正フォーマット**: parse_audit_response() がスキーマ検証（必須キー・severity 値・findings 構造）を実施。検証失敗時は ValueError を raise → exit 1。不正 severity の個別 finding はスキップ + WARNING 表示
- **subprocess.TimeoutExpired 未捕捉**: call_claude() 内で捕捉し RuntimeError に変換（main() の例外ハンドラとの整合性）
- **プロンプトインジェクション（wiki コンテンツ経由）**: 出力形式指示のプロンプト末尾配置 + parse_audit_response のスキーマ検証で軽減。完全防御は不可能だが、不正構造の検出と安全な処理を保証。既存 cli-query と同一リスクレベル
- **レポートへのコンテンツインジェクション**: Finding.message の改行を空白に置換し、Markdown 構造の破壊を防止
