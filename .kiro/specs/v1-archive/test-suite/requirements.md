# Requirements Document

## Introduction
rw_light.py（3,490 行）の未テスト領域に対するテストを追加し、テストインフラを整備する。現在 tests/test_rw_light.py（6,326 行）に query 系コマンド（extract/answer/fix）、audit 系関数（check_*, run_micro_checks, run_weekly_checks, _run_llm_audit, map_severity, parse_audit_response 等）、Prompt Engine（parse_agent_mapping, load_task_prompts, call_claude, build_query_prompt 等）のテストが存在する。

未テスト領域は以下の 2 カテゴリに分かれる：
1. **ユーティリティ関数**: parse_frontmatter, build_frontmatter, slugify, list_md_files, first_h1, ensure_basic_frontmatter, read_text/write_text/append_text, read_json, git_commit, git_status_porcelain, git_path_is_dirty
2. **CLI コマンド**: cmd_lint, cmd_ingest, cmd_synthesize_logs, cmd_approve, cmd_lint_query, cmd_init

本スペックでは、これらの未テスト領域のテスト追加、共通フィクスチャの conftest.py への集約、docs/developer-guide.md の作成を行う。

既存テストで既にカバー済みの領域（query 系コマンド、audit 系関数・コマンド（cmd_audit_monthly / cmd_audit_quarterly の tier ルーティング・戻り値・エラー処理を含む）、Prompt Engine のエラー処理、wiki/ 不在時の検証、dirty tree 警告 等）は本スペックのスコープ外とする。

## Boundary Context
- **In scope**: 上記未テスト領域のテスト追加、tests/conftest.py の作成（新規テスト用共通フィクスチャ）、docs/developer-guide.md、CHANGELOG.md 追記
- **Out of scope**: CI/CD パイプライン設定、カバレッジ閾値の強制、Claude CLI の実呼び出しを伴う E2E テスト、パフォーマンステスト、既存テスト（test_rw_light.py）のリファクタリング・移動、既存テストでカバー済みのエラー処理（query 系 / audit 系の wiki 不在・Claude CLI 失敗・AGENTS 欠損等）
- **Adjacent expectations**: テストは隣接スペック（project-foundation, agents-system, cli-query, cli-audit）で定義された動作契約を検証する。テストの期待値は隣接スペックの要件と実装コードの両方に基づく。コマンドの仕様変更は行わない
- **Constraints**: TDD（テストファースト）で進める。2 スペースインデント。モック手法は既存テストに合わせ `monkeypatch.setattr` のみ使用する。`unittest.mock`（`Mock`, `patch`, `MagicMock` 等）は使用しない

## Requirements

### Requirement 1: テストインフラ整備
**Objective:** As a 開発者, I want 共通フィクスチャと pytest 設定が整備されている, so that 新規テストの追加が容易で、テスト間の環境汚染が防止される

#### Acceptance Criteria
1. When `pytest` をプロジェクトルートで実行した時, the テストスイート shall 既存テスト（test_rw_light.py）と新規テストの両方を検出・実行し、結果を報告する
2. The テストスイート shall tests/conftest.py に新規テスト用の共通フィクスチャを定義する。既存テスト（test_rw_light.py）のインラインフィクスチャは変更しない。conftest.py のフィクスチャは全て `autouse=False` とし、既存テストに副作用を与えない
3. The テストスイート shall Vault ディレクトリ構造を tmp_path 上に構築するフィクスチャを提供する。ディレクトリリストは `rw_light.VAULT_DIRS` 定数を参照し、ハードコードによる二重管理を避ける
4. The テストスイート shall 指定フィールド付きフロントマター Markdown ファイルを生成するヘルパーフィクスチャを提供する
5. The テストスイート shall 各テストを独立した tmp_path 上で実行し、テスト間の状態共有を防止する
6. The テストスイート shall rw_light モジュールのグローバル定数を monkeypatch で tmp_path に差し替えるフィクスチャを提供する。対象定数: ROOT, RAW, INCOMING, LLM_LOGS, REVIEW, SYNTH_CANDIDATES, QUERY_REVIEW, WIKI, WIKI_SYNTH, LOGDIR, LINT_LOG, QUERY_LINT_LOG, INDEX_MD, CHANGE_LOG_MD, CLAUDE_MD, AGENTS_DIR, DEV_ROOT（モジュールロード時に評価済みのため、派生定数も個別に差し替える）
7. The テストスイート shall `rw_light.today` を monkeypatch で固定日付に差し替えるフィクスチャを提供する（ensure_basic_frontmatter, render_candidate_note, promote_candidate 等が日付依存のためテストの決定性を保証する）
8. The テストスイート shall rw_light モジュールのインポートに必要な `sys.path` 操作を conftest.py に定義し、新規テストファイルでは個別の `sys.path.insert` を不要にする。既存テスト（test_rw_light.py）のモジュールレベル `sys.path.insert` はそのまま残す
9. The テストスイート shall lint_latest.json のフォーマット（`timestamp`, `files`, `summary` の 3 キー構造）に準拠した JSON ファイルを生成するヘルパーフィクスチャを提供する
10. The テストスイート shall query アーティファクト一式（question.md, answer.md, evidence.md, metadata.json）を指定ディレクトリに生成するヘルパーフィクスチャを提供する
11. The テストスイート shall cmd_init テスト用のモックテンプレートディレクトリ（CLAUDE.md, AGENTS/, .gitignore）を tmp_path 上に構築するヘルパーフィクスチャを提供する

### Requirement 2: ユーティリティ関数の単体テスト
**Objective:** As a 開発者, I want 中核ユーティリティ関数の正常系・異常系が検証されている, so that パイプライン全体の基盤となるデータ処理の正確性が保証される

#### Acceptance Criteria
1. When 有効な YAML フロントマター付き Markdown を入力した時, the テストスイート shall parse_frontmatter がメタデータ辞書と本文を正しく分離することを検証する
2. When フロントマターが存在しない Markdown を入力した時, the テストスイート shall parse_frontmatter が空辞書と全文を返すことを検証する
3. If フロントマターの開始 `---` はあるが閉じ `---` がない不完全な Markdown を入力した時, the テストスイート shall parse_frontmatter が空辞書と全文を返すことを検証する
4. When メタデータ辞書を入力した時, the テストスイート shall build_frontmatter が有効な YAML フロントマターブロック（`---` で囲まれた `key: value` 形式）を生成することを検証する
5. When 日本語・記号・スペースを含む文字列を入力した時, the テストスイート shall slugify が ASCII スラッグ（小文字・ハイフン区切り・80 文字上限）を生成し、空文字列入力時に `"untitled"` を返すことを検証する
6. When ディレクトリに .md ファイルと非 .md ファイルが混在する時, the テストスイート shall list_md_files が .md ファイルのみを再帰的に収集することを検証する
7. If list_md_files に存在しないディレクトリパスを渡した時, the テストスイート shall 空リストを返すことを検証する
8. When Markdown ファイルに H1 見出しが存在する時, the テストスイート shall first_h1 が最初の H1 見出しテキストを抽出することを検証する
9. If Markdown ファイルに H1 見出しが存在しない時, the テストスイート shall first_h1 が `None` を返すことを検証する
10. When フロントマターに title・source・added のいずれかが欠落している Markdown を入力した時, the テストスイート shall ensure_basic_frontmatter が不足フィールドを自動補完して書き戻し、戻り値（変更有無の bool、修正内容の list、補完後テキストの str）を返すことを検証する
11. When フロントマターに title・source・added がすべて存在する Markdown を入力した時, the テストスイート shall ensure_basic_frontmatter が変更なし（`False`, 空リスト, 元テキスト）を返しファイルを書き換えないことを検証する
12. The テストスイート shall read_text / write_text / append_text がファイルの読み書き・追記を UTF-8 エンコーディングで正しく行うことを検証する
13. The テストスイート shall read_json が有効な JSON ファイルを辞書として読み込むことを検証する
14. If read_json に不正な JSON ファイルを渡した時, the テストスイート shall 例外の発生を検証する

### Requirement 3: Git 操作関数のテスト
**Objective:** As a 開発者, I want Git 関連ユーティリティの動作が検証されている, so that コミット・ステータス確認の正確性が保証される

#### Acceptance Criteria
1. When ファイル変更が存在する時, the テストスイート shall git_commit が subprocess.run を通じて git add と git commit を実行することを検証する（subprocess.run はモック）
2. When git_commit に渡したパスにステージ済み変更がない時, the テストスイート shall git_commit がコミットをスキップすることを検証する
3. If git add または git commit が失敗した時, the テストスイート shall git_commit が CalledProcessError を送出することを検証する
4. When git_status_porcelain を呼び出した時, the テストスイート shall subprocess.run の stdout を返すことを検証する（subprocess.run はモック）
5. When git_path_is_dirty にパスプレフィックスを渡した時, the テストスイート shall git_status_porcelain の出力を解析し、指定パス配下の変更有無を正しく判定することを検証する

### Requirement 4: cmd_lint コマンドのテスト
**Objective:** As a 開発者, I want lint コマンドの検証ロジックとレポート出力が正しく動作することを確認したい, so that incoming ファイルのバリデーションが信頼できる

#### Acceptance Criteria
1. When raw/incoming/ に十分な内容を持つ Markdown ファイルが存在する時, the テストスイート shall cmd_lint が当該ファイルを PASS と判定し、標準出力に PASS を表示することを検証する
2. When ファイルの内容が空の時, the テストスイート shall cmd_lint が当該ファイルを FAIL と判定することを検証する
3. When フロントマター補完後のテキスト全体が 80 文字未満の時, the テストスイート shall cmd_lint が当該ファイルを WARN と判定することを検証する
4. When raw/incoming/ にファイルが存在しない時, the テストスイート shall cmd_lint が終了コード 0 で正常終了することを検証する
5. When cmd_lint が完了した時, the テストスイート shall lint 結果の JSON ログ（`timestamp`, `files`, `summary` の 3 キー構造）が lint_latest.json に出力されることを検証する
6. When FAIL 判定のファイルが 1 件以上ある時, the テストスイート shall cmd_lint が終了コード 1 を返すことを検証する
7. When FAIL 判定のファイルがない時（PASS または WARN のみ）, the テストスイート shall cmd_lint が終了コード 0 を返すことを検証する
8. When フロントマターが不足しているファイルを lint した時, the テストスイート shall cmd_lint が raw/incoming/ のファイルに不足フロントマターを書き戻した後の内容が正しいことを検証する

### Requirement 5: cmd_ingest コマンドのテスト
**Objective:** As a 開発者, I want ingest コマンドのファイル移動と Git 連携が正しく動作することを確認したい, so that raw/incoming/ から raw/ への取り込みが信頼できる

#### Acceptance Criteria
1. While lint_latest.json に FAIL が含まれていない時, when raw/incoming/ にファイルが存在する場合, the テストスイート shall cmd_ingest がファイルを raw/incoming/ 以下の相対パスを保持して raw/ 直下へ移動することを検証する
2. When raw/incoming/ にファイルが存在しない時, the テストスイート shall cmd_ingest が終了コード 0 で正常終了することを検証する
3. When ファイル移動が成功した時, the テストスイート shall cmd_ingest が git_commit を呼び出すことを検証する（git_commit はモック）
4. When lint_latest.json の summary に FAIL が 1 件以上含まれている時, the テストスイート shall cmd_ingest がファイル移動を行わず終了コード 1 を返すことを検証する
5. If git_commit が CalledProcessError を送出した時, the テストスイート shall cmd_ingest が終了コード 1 を返すことを検証する
6. If lint_latest.json が存在しない時（lint 未実行）, the テストスイート shall cmd_ingest が FileNotFoundError を送出することを検証する
7. If 移動先に同名ファイルが既に存在する時, the テストスイート shall cmd_ingest が RuntimeError を送出することを検証する
8. If 複数ファイルの移動中にエラーが発生した時, the テストスイート shall 完了済みの移動がロールバックされ元の位置に復元されることを検証する

### Requirement 6: cmd_synthesize_logs コマンドのテスト
**Objective:** As a 開発者, I want synthesize-logs コマンドの LLM 呼び出しと候補生成が正しく動作することを確認したい, so that LLM ログからの合成候補生成が信頼できる

**Note:** synthesize-logs は Prompt Engine（parse_agent_mapping / load_task_prompts / call_claude）を使用せず、独自の `call_claude_for_log_synthesis()` でハードコードプロンプトを送信する（roadmap.md Architecture Decision: CLI-AGENTS プロンプト統合方針）。モック境界は query/audit 系とは異なり、`call_claude_for_log_synthesis` または `subprocess.run` を対象とする

#### Acceptance Criteria
1. When raw/llm_logs/ に Markdown ファイルが存在する時, the テストスイート shall cmd_synthesize_logs が call_claude_for_log_synthesis を呼び出し、レスポンスを解析して review/synthesis_candidates/ に候補ファイルを生成することを検証する（call_claude_for_log_synthesis はモック。モック戻り値は `{"topics": [...]}` 形式の JSON 文字列。parse_topics が解析する）
2. When raw/llm_logs/ にファイルが存在しない時, the テストスイート shall cmd_synthesize_logs が終了コード 0 で正常終了し、候補ファイルを生成しないことを検証する
3. When 候補ファイルが生成された時, the テストスイート shall log.md にエントリが追記されることを検証する
4. The テストスイート shall 生成された候補ファイルが有効なフロントマター（少なくとも title, source, type, status を含む）を持つことを検証する
5. If call_claude_for_log_synthesis が例外を送出した時, the テストスイート shall 当該ファイルを FAIL として報告し、残りのファイルの処理を継続することを検証する
6. The テストスイート shall cmd_synthesize_logs が常に終了コード 0 を返すことを検証する（全ファイル FAIL 時を含む）
7. If review/synthesis_candidates/ に同名の候補ファイルが既に存在する時, the テストスイート shall cmd_synthesize_logs が当該トピックをスキップし既存ファイルを上書きしないことを検証する
8. When cmd_synthesize_logs が実行開始した時, the テストスイート shall raw/llm_logs の dirty 状態に対する警告表示を検証する

### Requirement 7: cmd_approve コマンドのテスト
**Objective:** As a 開発者, I want approve コマンドの候補フィルタリングと昇格ロジックが正しく動作することを確認したい, so that review/ から wiki/synthesis/ への昇格が信頼できる

#### Acceptance Criteria
1. When review/synthesis_candidates/ に承認済み候補（status: approved, reviewed_by 非空, approved が有効な ISO 日付, promoted: false）が存在する時, the テストスイート shall cmd_approve がファイルを wiki/synthesis/ に新規作成し、フロントマターの type が `"synthesis"` に変更されることを検証する
2. If 候補ファイルのフロントマターが承認条件を満たさない時, the テストスイート shall cmd_approve が当該ファイルをスキップすることを検証する（4 条件それぞれの個別拒否: status が approved 以外、reviewed_by が空、approved が無効な日付、promoted が true）
3. When 昇格が完了した時, the テストスイート shall 元の候補ファイルのフロントマターに promoted: true, promoted_at, promoted_to が設定されることを検証する
4. When 昇格先の wiki/synthesis/ に同名ファイルが既に存在する時, the テストスイート shall cmd_approve が既存ファイルに新しい本文をセパレータ付きで追記し、フロントマターの updated・candidate_source を更新することを検証する
5. When 昇格が完了した時, the テストスイート shall index.md の synthesis セクションが再生成されることを検証する
6. When 昇格が完了した時, the テストスイート shall log.md に昇格エントリが追記されることを検証する
7. The テストスイート shall cmd_approve が常に終了コード 0 を返すことを検証する（承認済みファイルの有無に関わらず）
8. When cmd_approve が実行開始した時, the テストスイート shall review/synthesis_candidates の dirty 状態に対する警告表示を検証する

### Requirement 8: cmd_lint_query コマンドのテスト
**Objective:** As a 開発者, I want lint-query コマンドの構造検証と QL コード判定が正しく動作することを確認したい, so that query アーティファクトのバリデーションが信頼できる

#### Acceptance Criteria
1. When review/query/<query_id>/ に 4 ファイル（question.md, answer.md, evidence.md, metadata.json）が揃っている時, the テストスイート shall cmd_lint_query が全ファイルの構造検証を実行し、結果を標準出力に表示することを検証する
2. If 必須ファイル（question.md, answer.md, evidence.md, metadata.json のいずれか）が欠落している時, the テストスイート shall cmd_lint_query が QL001（ERROR）を報告することを検証する
3. When cmd_lint_query が完了した時, the テストスイート shall ログファイルに結果 JSON（timestamp, results, summary）が出力されることを検証する
4. When ERROR レベルの問題がない時, the テストスイート shall cmd_lint_query が終了コード 0 を返すことを検証する
5. When WARN レベルのみの問題がある時（例: metadata.json に created_at がない QL005、query_type が未指定の QL003）, the テストスイート shall cmd_lint_query が終了コード 1 を返すことを検証する
6. When ERROR レベルの問題がある時, the テストスイート shall cmd_lint_query が終了コード 2 を返すことを検証する
7. If 指定されたパスが存在しない時, the テストスイート shall cmd_lint_query が終了コード 4 を返すことを検証する
8. If 引数パースエラー（`--path` や `--format` の値なし、不明オプション）が発生した時, the テストスイート shall cmd_lint_query が終了コード 3 を返すことを検証する

### Requirement 9: cmd_init コマンドのテスト
**Objective:** As a 開発者, I want init コマンドの Vault セットアップが project-foundation スペックの定義通りに動作することを確認したい, so that 新規 Vault の初期化が信頼できる

#### Acceptance Criteria
1. When 中身が空の既存ディレクトリパスを指定した時, the テストスイート shall cmd_init が project-foundation Req 1.1 で定義された全ディレクトリ構造（raw/incoming/{articles, papers/...}, review/{synthesis_candidates, query}, wiki/{concepts, methods, ...} 等）を作成することを検証する
2. If 指定パスが存在しない時, the テストスイート shall cmd_init がディレクトリを自動作成してからセットアップを続行することを検証する
3. When init を実行した時, the テストスイート shall templates/CLAUDE.md が Vault ルートの CLAUDE.md としてコピーされることを検証する
4. Where templates/AGENTS/ が存在する場合, the テストスイート shall AGENTS/ ディレクトリがコンテンツごと Vault にコピーされることを検証する
5. When init を実行した時, the テストスイート shall index.md（「# Index」見出し付き）と log.md（「# Log」見出し付き）が生成されることを検証する
6. If index.md または log.md が既に存在する場合, the テストスイート shall cmd_init が既存ファイルを上書きしないことを検証する
7. When init を実行した時, the テストスイート shall git init が実行されることを検証する（subprocess.run はモック）
8. If .git/ ディレクトリが既に存在する場合, the テストスイート shall cmd_init が git init をスキップすることを検証する
9. When init を実行した時, the テストスイート shall templates/.gitignore が Vault の .gitignore としてコピーされることを検証する
10. If .gitignore が既に存在する場合, the テストスイート shall cmd_init が既存の .gitignore を上書きしないことを検証する
11. When init を実行した時, the テストスイート shall scripts/rw シンボリックリンクが作成されることを検証する
12. When init を実行した時, the テストスイート shall セットアップ完了レポートが標準出力に表示されることを検証する
13. If 既に初期化済みのディレクトリ（CLAUDE.md または index.md が存在）を指定した時, the テストスイート shall cmd_init が警告メッセージを表示し上書き確認を求めることを検証する（stdin はモック）
14. When 再初期化で上書きが承認された時, the テストスイート shall 既存の CLAUDE.md が CLAUDE.md.bak にリネームされ、既存の AGENTS/ が AGENTS.bak/ にリネームされた後に新しいテンプレートがコピーされることを検証する
15. When 再初期化で上書きが拒否された時, the テストスイート shall cmd_init が終了コード 0 で中断し、既存ファイルを変更しないことを検証する（stdin はモック）
16. If templates/CLAUDE.md が存在しない場合, the テストスイート shall cmd_init が終了コード 1 でエラー終了することを検証する
17. If templates/.gitignore が存在しない場合, the テストスイート shall cmd_init が終了コード 1 でエラー終了することを検証する

### Requirement 10: 開発者ドキュメント
**Objective:** As a コントリビューター, I want テスト実行方法とアーキテクチャ概要が文書化されている, so that プロジェクトへの参加障壁が低い

#### Acceptance Criteria
1. The テストスイート shall docs/developer-guide.md にテスト実行コマンド（pytest）、テストファイル構成（既存 test_rw_light.py と新規テストファイルの関係）、テスト追加手順を記載する
2. The テストスイート shall docs/developer-guide.md にモック戦略（monkeypatch による subprocess.run / モジュール定数の差し替え、conftest.py のフィクスチャ利用方法）を記載する
3. The テストスイート shall docs/developer-guide.md に rw_light.py のアーキテクチャ概要（3 層パイプライン、コマンドハンドラ構造、Prompt Engine）を記載する
4. When テストスイート構築が完了した時, the テストスイート shall CHANGELOG.md にテスト体系追加のエントリを追記する

_change log_
- 2026-04-20: severity-unification spec により Req 4 / Req 8 の status 記述(PASS/FAIL 2 値)・exit code 記述(0/1/2 3 値)を新体系に整合。PASS_WITH_WARNINGS および status 位置 WARN を廃止。
