# Implementation Plan

## Implementation Notes

<!-- タスク実装中に判明したクロスカッティングな知見をここに記録する -->
- タスク 5（実行モード更新）はコード実装ではなくテンプレート変更だが、AGENTS/ファイルはランタイムで parse_agent_mapping() によって読み込まれるため、設定タスクとして含む
- 全関数は同一ファイル rw_light.py に追加する。同一ファイルへの並列書き込みを避けるため、Foundation フェーズのタスクは (P) マーカーを付与しない

---

- [ ] 1. Prompt Engine 基盤
- [x] 1.1 CLAUDE.md マッピングパーサーとエージェント+ポリシーローダーを実装する
  - CLAUDE.md のマッピング表をパースし、タスク名→エージェント+ポリシーの辞書を返す parse_agent_mapping() を実装する
  - ヘッダー列名（Task, Agent, Policy, Execution Mode）で位置特定し、列順変更に耐性を持たせる
  - 必須列・各行のフィールド妥当性・パス先ファイルの実在を検証するバリデーションを含める。不正時は ValueError を raise する
  - load_task_prompts() を実装し、parse_agent_mapping() の結果に基づきエージェント+ポリシーを読み込み結合する。task_name がマッピング表に存在しない場合は ValueError、ファイル不在時は FileNotFoundError を raise する
  - 現在の templates/CLAUDE.md に対してパーサーが正しく動作するユニットテストを作成する。テストは Execution Mode の具体値ではなく「パース可能であること」「9行存在すること」「各行に Agent/Policy パスが含まれること」を検証する（Task 5 で Execution Mode が Prompt → CLI (Hybrid) に変更されても壊れないようにする）
  - parse_agent_mapping() が全9タスクのマッピングを正しく返し、load_task_prompts() がファイル内容を結合して返すこと
  - _Requirements: 9.1, 9.2, 6.5_
  - _Boundary: Prompt Engine_

- [x] 1.2 Claude CLI 呼び出し汎用関数を実装する
  - subprocess.run(["claude", "-p", prompt]) ラッパーの call_claude() を実装する
  - returncode != 0 で RuntimeError を raise し、stderr を含めるエラーメッセージにする
  - 呼び出し失敗時に生レスポンス先頭500文字を stderr に出力するデバッグ支援を含める
  - call_claude() が成功時に stdout を返し、失敗時に RuntimeError を raise することをユニットテストで確認する
  - _Requirements: 6.1_
  - _Boundary: Prompt Engine_

- [x] 1.3 Wiki コンテンツ収集関数を実装する
  - read_wiki_content(scope) を実装する。scope 指定時は指定ページのみ読み込む
  - scope=None かつ wiki/ のファイル数が 20 以下の場合は全ファイルを読み込む
  - scope=None かつ wiki/ のファイル数が 20 超の場合は、cmd_* がオーケストレーションする2段階方式のために index.md のみを返す（2段階方式のフロー制御は cmd_* 側の責務）。cmd_* が2段階方式の要否を判別できるよう、戻り値をタプル `(content: str, is_complete: bool)` とするか、cmd_* 側でファイル数を事前チェックする方式とするかを実装時に決定する
  - wiki/ 不在時は FileNotFoundError、.md ファイルゼロ時は ValueError、scope 指定ページ不在時は FileNotFoundError を raise する
  - read_wiki_content() の正常系・エラー系をユニットテストで確認する
  - _Requirements: 5.3, 5.4, 6.4_
  - _Boundary: Prompt Engine_

- [x] 1.4 プロンプト構築関数を実装する
  - build_query_prompt(task_prompts, question, wiki_content, output_format, ...) を実装する
  - プロンプト構造: エージェント+ポリシー内容 → wiki コンテンツ → 質問文 → 出力形式指定
  - output_format="json"（extract/fix）で JSON スキーマ指示を、"plaintext"（answer）で参照ページリスト指示を含める
  - query_type=None の場合はプロンプトにクエリタイプ指定を含めず、Claude に質問文から自動判定させる
  - fix 用: lint_results + existing_artifacts をプロンプトに含める
  - build_query_prompt() が output_format に応じた異なるプロンプトを生成することをユニットテストで確認する
  - _Requirements: 1.3, 1.4, 1.5, 1.8, 2.4_
  - _Depends: 1.1_
  - _Boundary: Prompt Engine_

- [ ] 2. クエリ出力ユーティリティ
- [x] 2.1 query_id 生成とアーティファクト書き出しを実装する
  - generate_query_id(question) を実装する（YYYYMMDD-slugify(question) 形式、既存 slugify 使用、80文字上限）
  - 空の質問文に対するバリデーション（slugify("") → "untitled" のケースを防ぐ）
  - write_query_artifacts(query_id, data) を実装する。review/query/<query_id>/ に question.md, answer.md, evidence.md, metadata.json を書き出す
  - CLI 生成の query_id で metadata.json の query_id フィールドを上書きする
  - question.md はキーバリュー形式（query:, query_type:, scope:, date:）で書き出す
  - generate_query_id() のスラッグ生成・80文字上限・非ASCII処理、write_query_artifacts() の4ファイル書き出しをユニットテストで確認する
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.6_
  - _Boundary: Output_

- [x] 2.2 Claude CLI レスポンスパーサーを実装する
  - parse_extract_response(response) を実装する。JSON をパースし query/answer/evidence/metadata の各セクションを抽出する
  - parse_fix_response(response) を実装する。fixes/files/skipped の各セクションを抽出する
  - 不正 JSON や必須フィールド欠落時に ValueError を raise する
  - パースエラー時に生レスポンス先頭500文字を stderr に出力するデバッグ支援を含める
  - 正常JSON・不正JSON・フィールド欠落のユニットテストを作成する
  - _Requirements: 6.2_
  - _Boundary: Output_

- [ ] 3. サブコマンド実装
- [x] 3.1 cmd_query_extract を実装する
  - 引数パース（question, --scope, --type）。質問文が空の場合はエラー終了（exit 1）
  - 前提条件チェック（wiki/ 存在、CLAUDE.md/AGENTS/ 存在、warn_if_dirty_paths(["wiki"], "query extract")）
  - generate_query_id() で query_id 生成。同一 query_id ディレクトリ存在時はエラーメッセージ（手動削除で再生成可能である旨を案内）を表示して exit 1
  - load_task_prompts("query_extract") → read_wiki_content(scope) → build_query_prompt(output_format="json") → call_claude() → parse_extract_response() → write_query_artifacts()
  - scope なし かつ 大規模 wiki 時: 2段階方式をオーケストレーション（1回目で関連ページ特定、2回目で本プロンプト）
  - lint_single_query_dir() で自動 lint 検証。status=="FAIL" なら警告+QLコード表示して exit 2、それ以外は生成ファイルパス表示して exit 0
  - rw query extract "test question" が review/query/ に4ファイルを生成し、lint 検証結果を表示して正しい終了コードで終了すること
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 4.5, 4.7, 5.1, 5.2, 5.5, 5.6_

- [x] 3.2 cmd_query_answer を実装する
  - 引数パース（question, --scope）。質問文が空の場合はエラー終了（exit 1）
  - 前提条件チェック（wiki/ 存在、CLAUDE.md/AGENTS/ 存在、warn_if_dirty_paths(["wiki"], "query answer")）
  - load_task_prompts("query_answer") → read_wiki_content(scope) → build_query_prompt(output_format="plaintext") → call_claude()
  - 回答テキストと参照ページを stdout に表示。Claude のレスポンス末尾から `---\nReferenced:` 行を分離して参照ページリストとして表示する。ファイルは生成しない
  - wiki が不十分な場合は Claude が回答の限界を明示する（AGENTS/query_answer.md のルールに従う）。この振る舞いをテストで確認する
  - 終了コード 0
  - rw query answer "test question" が stdout に回答と参照ページを表示し、review/query/ にファイルを生成しないこと
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 5.2, 5.3, 5.4, 5.5_

- [ ] 3.3 cmd_query_fix を実装する
  - 引数パース（query_id）
  - 前提条件チェック（query_id ディレクトリ存在、CLAUDE.md/AGENTS/ 存在、warn_if_dirty_paths(["wiki"], "query fix")）
  - lint_single_query_dir(query_dir) で事前 lint。FAIL==0 なら「修復不要」exit 0
  - load_task_prompts("query_fix") → read_wiki_content(scope=None) → 既存アーティファクト読み込み → build_query_prompt(output_format="json", lint_results=..., existing_artifacts=...) → call_claude() → parse_fix_response()
  - 変更が必要なファイルのみ既存 write_text() で書き出す（write_query_artifacts() は新規作成用であり fix では使用しない）。修復不可能な項目はスキップ理由とともに報告
  - lint_single_query_dir() で修復後 lint 再検証。結果に基づき終了コード決定（0: PASS, 2: FAIL残存）
  - rw query fix <query_id> が修復項目と修復後 lint 結果を表示して正しい終了コードで終了すること
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 5.1, 5.2, 5.5, 5.6, 6.3_
  - _Depends: 3.1_

- [ ] 4. CLI 統合
- [ ] 4.1 ディスパッチャ・usage・例外ハンドラを更新する
  - main() に if cmd == "query" ブロックを追加し、sys.argv[2] で extract/answer/fix にルーティングする
  - rw query（サブコマンドなし）で query 用 usage を表示する
  - print_usage() に query サブコマンドの使用方法を追加する
  - main() の例外ハンドラに ValueError を追加する（parse_agent_mapping の ValueError 対応）
  - rw query extract/answer/fix が正しくルーティングされ、rw query が usage を表示し、ValueError が適切にキャッチされること
  - _Requirements: 1.9, 6.5_

- [ ] 5. 実行モード更新
- [ ] 5.1 templates/CLAUDE.md のマッピング表で query_extract・query_answer・query_fix の Execution Mode を CLI (Hybrid) に更新する
  - 更新後のマッピング表に3行が CLI (Hybrid) と記載されていること
  - _Requirements: 8.1_
  - _Boundary: Execution Mode 更新_

- [ ] 5.2 (P) templates/AGENTS/query_extract.md・query_answer.md・query_fix.md の Execution Mode セクションと関連説明文を CLI (Hybrid) に更新する
  - 各ファイルの Execution Mode が CLI (Hybrid) に変更され、実行手順・実行宣言の説明が CLI 実態に合わせて更新されていること
  - _Requirements: 8.2_
  - _Boundary: Execution Mode 更新_

- [ ] 5.3 (P) templates/AGENTS/README.md のエージェント一覧テーブルで query_extract・query_answer・query_fix の実行モードを CLI (Hybrid) に更新する
  - README.md のテーブルで3行が CLI (Hybrid) と記載されていること
  - _Requirements: 8.3_
  - _Boundary: Execution Mode 更新_

- [ ] 6. ドキュメント・CHANGELOG 更新
- [ ] 6.1 docs/user-guide.md に rw query extract・rw query answer・rw query fix の使用方法・引数・出力例を追記する
  - user-guide.md に3サブコマンドのリファレンスが追記されていること
  - _Requirements: 7.1_

- [ ] 6.2 (P) CHANGELOG.md の [Unreleased] に cli-query スペック成果物を追記する
  - CHANGELOG.md に cli-query の変更内容が記載されていること
  - _Requirements: 7.2_

- [ ] 7. 統合検証
- [ ] 7.1 extract → lint → fix ワークフローの E2E 検証を実施する
  - extract で4ファイル生成 → lint で FAIL を意図的に含むケースを作成 → fix で修復 → lint 再検証で PASS を確認する
  - AGENTS/ファイル更新反映: AGENTS/ファイル変更後に extract を実行し、変更がプロンプトに反映されることを確認する（Req 9.2）
  - --scope オプション: 特定ページのみをソースとした extract/answer の実行を確認する
  - 全コマンドのエラーケース（wiki不在、AGENTS不在、CLAUDE.mdパース失敗、空質問文、scope不在ページ）を確認する
  - 全テストがパスすること
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.3, 3.1, 3.9, 4.5, 6.1, 6.2, 6.4, 6.5, 9.2_
  - _Depends: 4.1_
