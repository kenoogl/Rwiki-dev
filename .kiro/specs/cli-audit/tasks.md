# Implementation Plan

- [ ] 1. Foundation — データ構造・基盤ユーティリティ
- [x] 1.1 Finding / WikiPage NamedTuple 定義 + call_claude() timeout 拡張 + audit セクションヘッダー配置
  - `from typing import Any, NamedTuple` に変更
  - Finding NamedTuple を定義（severity, category, page, message, sub_severity, marker の 6 フィールド、全て str）
  - WikiPage NamedTuple を定義（path, filename, raw_text, frontmatter, body, links, read_error の 7 フィールド）
  - call_claude() に `timeout: int | None = None` パラメータを追加し、subprocess.run に timeout を渡す
  - subprocess.TimeoutExpired を捕捉し RuntimeError に変換する（メッセージにタイムアウト秒数を含む）
  - rw_light.py に audit 用の空セクションヘッダーを先行配置する（並列タスクのマージコンフリクト防止）。read_wiki_content の後 / Output utilities の前に以下の順序で挿入:
    `# audit: data loading` → `# audit: static checks — micro` → `# audit: static checks — weekly` → `# audit: LLM engine` → `# audit: report engine` → `# audit: commands — dispatch+micro` → `# audit: commands — weekly` → `# audit: commands — monthly/quarterly`
    後続タスク（1.2-1.4, 2.x, 3.x, 4.x, 5.x）は各セクションヘッダーの下に関数を追加する
  - 既存の call_claude() テスト（TestCallClaude）が変更なしで引き続きパスすること
  - _Requirements: 7.2_
  - _Boundary: DataLoading, Prompt Engine_

- [x] 1.2 validate_wiki_dir + load_wiki_pages
  - validate_wiki_dir(): wiki/ ディレクトリ存在、.md ファイル存在チェック。不在時は [ERROR] メッセージ + False 返却。dirty tree は warn_if_dirty_paths(["wiki"], "audit ...") で警告
  - load_wiki_pages(wiki_dir, target_files=None): ファイル読み込み + parse_frontmatter + `\[\[([^\]|]+)(?:\|[^\]]+)?\]\]` regex で body から [[link]] 抽出
  - (OSError, UnicodeDecodeError) を捕捉し read_error に設定。正常時は read_error=""
  - all_pages_set の構築ヘルパー: list_md_files(WIKI) → relpath() → wiki/ プレフィックス除去
  - テスト用 wiki ディレクトリに正常・異常（エンコーディングエラー）ファイルを配置し、load_wiki_pages が WikiPage リストを返すこと
  - _Requirements: 7.1, 7.6, 7.8_
  - _Boundary: DataLoading, Validation_

- [x] 1.3 _git_list_files + get_recent_wiki_changes
  - _git_list_files(args): subprocess.run(["git"] + args) のラッパー。失敗時は空リスト。call_claude() と独立してモック可能
  - get_recent_wiki_changes(): 未コミット変更 + 直近コミット変更の和集合。HEAD~1 不在時は HEAD の全追加ファイルにフォールバック。削除ファイル除外 + .md フィルタ
  - git リポジトリで wiki/ に変更がある場合にファイルパスリストが返ること。変更なしの場合は空リスト
  - _Requirements: 1.2_
  - _Boundary: DataLoading_

- [x] 1.4 read_all_wiki_content
  - wiki/ 全 .md + ROOT/index.md + ROOT/log.md を `<!-- file: ... -->` ヘッダー付きで結合
  - 150 ページ超で標準出力に警告表示（処理は続行）
  - index.md / log.md が存在しない場合はスキップ（エラーにしない）
  - テスト用 wiki で全ページが結合されること。index.md / log.md が結合に含まれること
  - _Requirements: 3.1, 4.1_
  - _Boundary: DataLoading_

- [ ] 2. Core — 静的チェックエンジン
- [x] 2.1 (P) micro チェック関数群 + run_micro_checks
  - check_broken_links: WikiPage.links を all_pages_set と照合。リンク解決ルール（ファイル名部分マッチ、.md 付加）を実装。Severity: ERROR
  - check_index_registration: ROOT/index.md（INDEX_MD）から [[link]] を抽出し、ページの登録状況を検証。index.md 不在時はチェックスキップ + WARNING の Finding を返却。Severity: WARN
  - check_frontmatter: raw_text を直接検査（空ブロック→ERROR、不正行→ERROR、未閉じ→ERROR）。parse_frontmatter() 結果で title 欠落→WARN。frontmatter なし時は title 欠落のみ
  - run_micro_checks: 3 つの check 関数を呼び出し。read_error が非空の WikiPage は ERROR Finding として記録しチェック対象から除外
  - 実装制約: check 関数は WikiPage のフィールド（frontmatter, links 等）を変更しないこと（NamedTuple の dict/list は mutable だが read-only で使用する）
  - テスト用 wiki に broken link / 正常リンク / index.md 未登録 / frontmatter 異常のページを用意し、各 Finding が正しい severity で返ること
  - _Requirements: 1.1, 7.7, 7.8_
  - _Boundary: StaticCheckEngine — micro_

- [x] 2.2 (P) weekly チェック関数群 + run_weekly_checks
  - check_orphan_pages: 被リンク集合を構築し、どのページからもリンクされず index_links にも含まれないページを検出。ファイル名 "index.md" は除外。Severity: WARN
  - check_bidirectional_links: 全リンクペアの双方向チェック。index.md からのリンクは対象外。(findings, {"total_pairs": N, "bidirectional_pairs": M}) のタプルを返却
  - check_naming_convention: `^[a-z0-9]+(-[a-z0-9]+)*\.md$` にマッチしないファイル名を検出。Severity: WARN
  - check_source_field: frontmatter の source フィールドの空・欠落を検出。Severity: INFO
  - check_required_sections: 現行 page_policy.md では no-op（Finding なし）。将来の拡張構造のみ用意
  - run_weekly_checks: 5 つの check 関数を呼び出し。戻り値は `tuple[list[Finding], dict]`。check_bidirectional_links の stats（total_pairs, bidirectional_pairs）を dict として findings と共に返す
  - orphan / 双方向 / 命名違反の各ケースで正しい Finding が返ること
  - _Requirements: 2.1, 2.2_
  - _Boundary: StaticCheckEngine — weekly_

- [ ] 3. Core — LLM 監査エンジン
- [x] 3.1 (P) build_audit_prompt + map_severity
  - build_audit_prompt(tier, task_prompts, wiki_content): ティア指示テンプレート（排他的限定 + Markdown→JSON オーバーライド + Execution Declaration 抑制）+ wiki コンテンツ + JSON スキーマサンプル（末尾配置）
  - map_severity(claude_severity): CRITICAL→("ERROR","CRITICAL"), HIGH→("ERROR","HIGH"), MEDIUM→("WARN",""), LOW→("INFO","")
  - monthly と quarterly でティア指示と JSON サンプルが正しく切り替わること。map_severity の 4 パターンが正しくマッピングされること
  - _Requirements: 3.2, 4.2, 5.3, 10.1, 10.2_
  - _Boundary: LLMAuditEngine_

- [x] 3.2 parse_audit_response（スキーマ検証付き）
  - _strip_code_block() でコードブロック除去 + json.loads() でパース
  - スキーマ検証 5 ステップ: トップレベル必須キー（findings/metrics/recommended_actions の型チェック）、finding 必須キー（severity/page/message）、severity 値検証（CRITICAL/HIGH/MEDIUM/LOW）、message 改行→空白置換、null→"" 変換
  - severity 不正値の finding はスキップし [WARN] 表示。トップレベル不備は ValueError
  - 正常 JSON / 不正スキーマ / 不正 severity / 改行含み message の各ケースで期待通りのパース・検証結果
  - _Requirements: 7.3_
  - _Boundary: LLMAuditEngine_

- [ ] 4. Core — レポートエンジン
- [x] 4.1 (P) generate_audit_report + print_audit_summary
  - generate_audit_report(tier, findings, metrics, recommended_actions=None, timestamp=None): Markdown レポートを logs/ に write_text() で出力。ファイル名 `audit-{tier}-{timestamp}.md`。セクション: Summary / Findings（Structural/Semantic/Strategic）/ Metrics / Recommended Actions。recommended_actions=None の場合（micro/weekly）は findings の ERROR/WARN 項目から推奨アクションを自動生成する（関数内部で処理。呼び出し元は None を渡すだけ）。自動生成ルール: category ごとに findings を集約し、「{category} が {N} 件検出されました。対象ページを確認してください」形式で生成する。monthly/quarterly は Claude が返す recommended_actions をそのまま渡す
  - print_audit_summary(tier, findings, report_path): `[{severity}] {page}: {message}` 形式で各 Finding を表示。page="" 時はページ省略。サマリー行 `audit {tier}: ERROR N, WARN N, INFO N — PASS/FAIL`。最終行にレポートパス
  - micro 用 findings でレポートファイルが生成され、サマリーが標準出力に表示されること
  - _Requirements: 5.1, 5.2, 5.4, 5.6, 5.7, 7.4_
  - _Boundary: ReportEngine_

- [ ] 5. Integration — コマンドハンドラ統合
- [x] 5.1 cmd_audit ディスパッチャ + cmd_audit_micro + main/print_usage 更新
  - cmd_audit(args): サブコマンド分岐（micro/weekly/monthly/quarterly）。サブコマンドなし or 不明→ audit 専用 usage + exit 1
  - cmd_audit_micro(): validate_wiki_dir → get_recent_wiki_changes → 対象 0 件チェック（レポート出力 + exit 0）→ load_wiki_pages(target_files) → all_pages_set 構築 → index_content 読み込み（read_text(INDEX_MD)、不在時は None）→ run_micro_checks → findings から metrics dict 算出（pages_scanned, broken_links, index_missing, frontmatter_errors, total_findings）→ generate_audit_report → print_audit_summary → exit 0 or 1。ensure_dirs() は使用しない（wiki/ / review/ にディレクトリを作成し Req 6.1, 6.3 に違反するため）
  - main() に `if cmd == "audit": sys.exit(cmd_audit(sys.argv[2:]))` を追加
  - print_usage() に audit コマンドのヘルプ行を追加
  - `rw audit micro` が wiki/ のあるテスト Vault で正常に実行され、レポートが logs/ に生成されること。wiki/ 不在時は [ERROR] + exit 1
  - _Requirements: 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 5.5_
  - _Depends: 2.1, 4.1_

- [x] 5.2 (P) cmd_audit_weekly
  - cmd_audit_weekly(): validate_wiki_dir → load_wiki_pages(全ページ) → all_pages_set + index_content + index_links 構築 → page_policy は None を渡す（現行 page_policy.md に必須セクション定義がないため no-op）→ run_micro_checks（list[Finding]）+ run_weekly_checks（tuple[list[Finding], dict]）→ findings 統合 → run_weekly_checks の返却 stats から bidirectional_compliance を算出し metrics dict を構築（pages_scanned, broken_links, index_missing, frontmatter_errors, orphan_pages, bidirectional_compliance, source_coverage, naming_violations, total_findings）→ generate_audit_report → print_audit_summary → exit 0 or 1
  - `rw audit weekly` が全ページをスキャンし、micro + weekly チェックの結果を統合したレポートを生成すること
  - _Requirements: 2.3, 2.4, 2.5, 2.6_
  - _Depends: 2.1, 2.2, 4.1_
  - _Boundary: audit commands — weekly_

- [x] 5.3 (P) _run_llm_audit + cmd_audit_monthly/quarterly
  - _run_llm_audit(tier, args): args から --timeout パース（デフォルト 300）→ validate_wiki_dir → CLAUDE.md/AGENTS/ 明示チェック → load_task_prompts("audit") → read_all_wiki_content → build_audit_prompt → [INFO] 表示 → call_claude(timeout=N) → 生レスポンス保存（logs/audit-{tier}-{ts}-raw.txt）→ parse_audit_response → map_severity で Finding 変換 → generate_audit_report → print_audit_summary
  - cmd_audit_monthly/quarterly: _run_llm_audit に委譲する 1 行関数
  - 内部エラーハンドリング: 各ステップの例外を [ERROR] メッセージ付きで捕捉。パース失敗時は raw ファイルパスを [INFO] 表示
  - Claude CLI モック環境で `rw audit monthly` が JSON レスポンスをパースし、severity マッピング済みレポートを生成すること。`--timeout 600` オプションが適用されること
  - _Requirements: 3.1, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 4.1, 4.3, 4.4, 4.5, 4.6, 7.2, 7.3, 7.5, 10.1, 10.2_
  - _Depends: 3.1, 3.2, 4.1_
  - _Boundary: audit commands — monthly/quarterly_

- [ ] 6. ファイル更新
- [ ] 6.1 (P) Execution Mode 更新
  - templates/CLAUDE.md: マッピング表の audit 行の Execution Mode を `Prompt` → `CLI (Hybrid)` に変更
  - templates/AGENTS/audit.md: Execution Mode セクションを CLI (Hybrid) に更新
  - templates/AGENTS/README.md: エージェント一覧テーブルの audit 行を CLI (Hybrid) に更新
  - 3 ファイルの audit 行が全て `CLI (Hybrid)` に更新されていること
  - _Requirements: 9.1, 9.2, 9.3_
  - _Boundary: templates_

- [ ] 6.2 (P) docs/user-guide.md + CHANGELOG.md
  - docs/user-guide.md に audit コマンドのリファレンスセクションを追加（micro/weekly/monthly/quarterly の使用方法・引数・出力例）
  - CHANGELOG.md の [Unreleased] セクションに cli-audit の変更内容を追記
  - user-guide.md に 4 サブコマンドのリファレンスが記載されていること
  - _Requirements: 8.1, 8.2_
  - _Boundary: docs_

- [ ] 7. E2E 統合検証
- [ ] 7.1 全 4 ティアの動作確認 + 読み取り専用保証
  - テスト用 Vault（wiki/ に複数ページ、index.md、log.md を配置）で rw audit micro / weekly / monthly / quarterly を順次実行
  - 各ティアのレポートが logs/ に正しいファイル名・セクション構成で生成されること
  - monthly/quarterly の raw レスポンスファイルが logs/ に保存されること
  - 全ティア実行後に wiki/ / raw/ / review/ のファイルが一切変更されていないこと（読み取り専用保証）
  - エラーケース: wiki/ 不在 → exit 1、AGENTS/ 不在（monthly）→ exit 1、micro 対象 0 件 → exit 0
  - _Requirements: 6.1, 6.2, 6.3, 6.4_
  - _Depends: 5.1, 5.2, 5.3, 6.1, 6.2_

## Implementation Notes
- task 2.2: `check_orphan_pages` に未使用の `LINK_RE` 変数と未参照の `all_pages_set` パラメータあり（dead code）。5.2 実装時に整理すること
- task 2.2: `run_weekly_checks` では `read_error` ページの除外をしていない。5.2 の `cmd_audit_weekly` で両者連携時に対処すること
