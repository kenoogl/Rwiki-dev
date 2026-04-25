# Research & Design Decisions

## Summary
- **Feature**: `cli-query`
- **Discovery Scope**: Extension（既存CLIに3サブコマンドを追加）
- **Key Findings**:
  - `slugify()` が80文字上限・Unicode→ASCII変換を既に実装しており、query_id のスラッグ生成に利用可能
  - `QUERY_REVIEW` パス定数が定義済み（`review/query/`）。lint query のディレクトリ探索ロジックも再利用可能
  - AGENTS/ ファイルを Python から読む既存パターンが存在しない。一元管理（Req 9）のための新規設計が必要

## Research Log

### 既存コマンドディスパッチャの構造
- **Context**: 3サブコマンドの追加方法を決定するため
- **Sources Consulted**: `scripts/rw_light.py` L1228-1259
- **Findings**:
  - `main()` で `sys.argv[1]` を if 文で分岐する単純な構造
  - `rw lint query` は `sys.argv[2] == "query"` で2階層目を判定
  - `rw query extract/answer/fix` も同じパターンで追加可能
- **Implications**: ディスパッチャの拡張は低リスク。既存の `rw lint query` と衝突しない

### Claude CLI 呼び出しパターン
- **Context**: Req 9（一元管理）の実現方式を決定するため
- **Sources Consulted**: `call_claude_for_log_synthesis()` L434-481
- **Findings**:
  - `subprocess.run(["claude", "-p", prompt], capture_output=True, text=True, encoding="utf-8", check=False)`
  - プロンプトは f-string でハードコード（二重管理の原因）
  - 戻り値は `result.stdout.strip()`、returncode != 0 で RuntimeError
  - JSON パースは別関数 `parse_topics()` で実行
- **Implications**: subprocess.run パターンは再利用する。プロンプト構築をハードコードからAGENTS/ファイル読み込みに置き換える

### AGENTS/ ファイル読み込みの新規設計
- **Context**: Req 9 の実現にはAGENTS/ファイルをランタイムで読み込む必要がある
- **Sources Consulted**: `rw_light.py` の `read_text()` ユーティリティ、`cmd_init()` でのテンプレートコピー
- **Findings**:
  - `read_text(path)` はUTF-8ファイル読み込みユーティリティとして利用可能
  - 現状はAGENTS/ファイルをPythonから読むコードが存在しない
  - `ROOT = os.getcwd()` がVaultルート。`os.path.join(ROOT, "AGENTS", name)` でパス解決
- **Implications**: `read_agent_file(name)` 関数を新設し、AGENTS/ファイルをプロンプトに組み込む

### wiki コンテンツの収集方式
- **Context**: --scope なし時のwikiコンテンツ選択方式（Design decision）
- **Sources Consulted**: AGENTS/query_extract.md の抽出プロセス、CLAUDE.md の知識フロー
- **Findings**:
  - AGENTS/query_extract.md は「index.md を最初に読む」「関連ページを特定する」と定義
  - wiki/ 全体をプロンプトに含めるとコンテキスト制限に達する可能性
  - Claude CLI の `-p` フラグはプロンプト長に実質的な制限がない（Claude側のコンテキストウィンドウが制約）
- **Implications**: 2段階方式を採用: (1) index.md + 質問文をClaudeに渡して関連ページを特定、(2) 特定されたページのみを本プロンプトに含める。--scope 指定時はこの手順をスキップ

### slugify の既存実装
- **Context**: AC 4.6 のスラッグ生成ルール
- **Sources Consulted**: `slugify()` L139-147
- **Findings**:
  - `unicodedata.normalize("NFKD")` → ASCII変換 → 小文字 → 非英数除去 → スペース→ハイフン → 80文字上限
  - naming.md の要件（ASCII のみ・小文字・ハイフン区切り）とほぼ一致
  - 80文字上限が既に設定されている
- **Implications**: 既存の `slugify()` をそのまま使用。最大長は80文字（既存実装に従う）

### lint query の既存実装
- **Context**: AC 4.5/3.3/3.9 の自動lint検証
- **Sources Consulted**: `cmd_lint_query()` L957-1029, `lint_single_query_dir()` L824-932
- **Findings**:
  - `cmd_lint_query(args)` は args パースして `lint_single_query_dir()` を呼ぶ
  - 終了コード: 0=PASS, 1=PASS_WITH_WARNINGS, 2=FAIL, 4=path not found
  - プログラマティックに呼び出すには `lint_single_query_dir(path)` を直接使用するのが適切
  - `QUERY_LINT_LOG` にJSON結果を書き出す
- **Implications**: 自動lint検証は `lint_single_query_dir()` を内部呼び出し。CLIの終了コード体系（0/1/2/4）を考慮した設計が必要

## Design Decisions

### Decision: プロンプト構築方式（Req 9 一元管理）
- **Context**: AGENTS/ファイルをCLIプロンプトの正規ソースとし、ハードコードを避ける
- **Alternatives Considered**:
  1. AGENTS/ファイルを丸ごとプロンプトに埋め込む — 最もシンプル、ファイル更新が即反映
  2. AGENTS/ファイルから特定セクションを抽出してプロンプトに組み込む — コンテキスト節約だがパーサーが必要
  3. AGENTS/ファイルパスをClaude CLIの `--allowedTools` で Read 可能にする — Claude自身に読ませる
- **Selected Approach**: 方式1（丸ごと埋め込み）
- **Rationale**: パーサー不要で最もシンプル。AGENTS/ファイルは最大195行（audit.md）で、プロンプトコンテキストへの影響は軽微。ファイル更新が次回実行で即反映され、9.2を自然に満たす
- **Trade-offs**: プロンプトが長くなるが、Claude のコンテキストウィンドウ（200k+）に対して十分小さい

### Decision: scope なし時の wiki コンテンツ選択方式
- **Context**: --scope 省略時に wiki 全体を渡すとコンテキスト制限に達する可能性
- **Alternatives Considered**:
  1. wiki/ 全ファイルを結合してプロンプトに含める — 小規模wiki向け、大規模で破綻
  2. 2段階方式（関連ページ特定→本処理）— Claude CLI を2回呼ぶがスケーラブル
  3. --scope を必須にする — シンプルだが運用者の利便性が低下
- **Selected Approach**: 方式2（2段階方式）をデフォルトとし、wiki が小規模（ファイル数 ≤ 閾値）の場合は方式1にフォールバック
- **Rationale**: AGENTS/query_extract.md が「index.md を最初に読む → 関連ページを特定する」プロセスを定義しており、2段階方式はエージェントルールと自然に整合する
- **Trade-offs**: Claude CLI を2回呼ぶためレイテンシが増加する。閾値の具体値は実装時に調整

### Decision: Claude CLI 出力形式
- **Context**: extract/answer/fix それぞれの出力パース方式
- **Selected Approach**:
  - extract: JSON形式（4ファイルの内容を構造化して返す）— synthesize-logs パターンの踏襲
  - answer: プレーンテキスト（そのまま stdout に表示）
  - fix: JSON形式（修正後のファイル内容を構造化して返す）
- **Rationale**: extract/fix はファイル書き込みが必要なためJSONでパース。answer はstdout直接表示なのでプレーンテキストで十分

### Decision: 終了コード体系
- **Context**: lint query の終了コード（0/1/2/4）との整合
- **Selected Approach**: query サブコマンド独自の終了コード体系
  - 0: 成功（extract: 生成+lint通過、answer: 回答生成、fix: 修復+lint通過）
  - 1: エラー（Claude CLI失敗、パースエラー、ディレクトリ不在等）
  - 2: 生成/修復は完了したがlint FAIL（extract の 4.7、fix の 3.8+3.9）
- **Rationale**: lint query の 0/1/2/4 と方向性は同じ（0=成功、2=FAIL）。4（path not found）は query では 1（一般エラー）に統合

## Synthesis Outcomes

### 一般化
- `call_claude()` を汎用化: プロンプト文字列を受け取り Claude CLI を呼び出す共通関数。synthesize-logs の `call_claude_for_log_synthesis()` と同じパターンだがプロンプトをパラメータ化
- `read_agent_file()` は query 以外の将来のCLI Hybrid コマンド（audit等）でも再利用可能

### 構築 vs 採用
- 全て既存ユーティリティ（`read_text`, `write_text`, `slugify`, `build_frontmatter`）の上に構築
- 外部ライブラリ追加なし

### 簡素化
- プロンプト構築は AGENTS/ファイル丸ごと埋め込みで最もシンプルな方式を選択
- extract/fix の出力パースは単一JSON形式に統一
- answer は別フロー（stdout直接）として分離し、4ファイル出力ロジックを共有しない

## Risks & Mitigations
- Claude CLI のレスポンス品質が非決定論的 → 自動lint検証（4.5/3.9）で品質ゲートを設け、FAIL時は非ゼロ終了で運用者に通知
- 2段階方式のレイテンシ増加 → 小規模wiki時はフォールバックで1回呼び出しに最適化
- AGENTS/ファイルがVaultに存在しない → AC 6.5 でエラー処理。`rw init` 再実行を案内
