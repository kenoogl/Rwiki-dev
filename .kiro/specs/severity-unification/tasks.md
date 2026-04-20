# Implementation Plan

本 tasks は Core-only スコープ確定（Y 選択、2026-04-20）に基づき、design.md §Out of Scope (Y Cut) および §Phased Migration (Y Cut 後 3-phase 版) に従い **3 phase / 34 sub-tasks** で構成する。各 phase 完了時点で `tests/` 全件 green を不変条件として維持する。P1 は atomic 強制（部分 merge 禁止）、P2 / P3 は単一 PR 推奨（速度優先、分割は実装者裁量）。

**除外項目**（observability-infra spec で将来対応）: schema_version bump / MAX_DRIFT_EVENTS cap + sentinel / `_emit_drift_summary` invocation end summary / `--strict-severity` strict mode / `--validate-vault-only` dry-run / `write_log_atomic` / property-based cross-channel invariant / Turkish locale regression / coverage gate / flakiness detection / `.git-blame-ignore-revs`。

## 1. P1: AGENTS 語彙 rename + identity 化 + Vault validation + drift 最低限（atomic、1 PR 強制）

- [x] 1.1 `tests/conftest.py` + Vault/Claude mock fixture の DRY 化
  - `tests/conftest.py` を新規作成し、Phase 1-3 の 6-7 test file で共用する fixture を function/session scope で提供
  - fixture 一覧: `tmp_vault`（一時 Vault ディレクトリ + `AGENTS/audit.md` 新語彙 template copy）/ `deprecated_agents_vault`（旧語彙 HIGH/MEDIUM/LOW 残存 Vault、Pattern A/B/C カバー）/ `claude_mock_response`（Claude CLI subprocess を mock し任意 JSON 応答を注入）/ `env_normalized`（autouse=True, TZ=UTC, LC_ALL=C.UTF-8）
  - pytest markers を `pytest.ini` に登録: `slow` / `subprocess` / `locale`
  - 観察可能完了条件: `pytest tests/ -m "not slow"` が conftest.py 読み込み後に既存 test 全件 green（regression 0 件）、fixture が 4 種すべて import 可能
  - _Requirements: 7.1_
  - _Boundary: tests infrastructure_

- [x] 1.2 `_normalize_severity_token` helper の TDD 実装
  - 先に `tests/test_rw_light.py` に test_normalize_severity_token を red 状態で追加: (a) 新 4 水準 identity（CRITICAL/ERROR/WARN/INFO → 同一返却、drift_sink 空のまま）/ (b) 旧語彙（HIGH/MEDIUM/LOW）は Y Cut 後の P1 atomic merge 後は AGENTS template から消失するため **drift として扱い INFO 降格 + drift_sink append + stderr 記録**（transitional rename map は Y Cut で廃止、Claude 応答に旧語彙が混入する場合は 3 層防御の Layer 3 runtime gate で捕捉）/ (c) 未知 severity（`WARNING` / `CRITICAL_ERROR` 等）→ `INFO` 降格 + `drift_sink` append + stderr 記録 / (d) 空文字 / None / 非 str は drift 扱い（stderr + INFO 降格 + drift_sink append）/ (e) drift_sink 要素の shape 検証（下記 5 キー必須）
  - `scripts/rw_light.py` に `_normalize_severity_token(token: str, *, source_context: dict | None = None, drift_sink: list[dict] | None = None) -> str` helper を新設
  - **source_context 型は dict**（3 キー: `{"context": <cmd_context_str>, "source_field": <json_path_str>, "location": <file:line_str_or_"-">}`、欠落キーは空文字列補完）。str 型ではない（AC 1.9 の 3 要素 stderr フォーマット "source / related location / demoted to" を構造化出力するため）
  - 前処理: `.strip().upper()`（Python `str.upper()` は Unicode 仕様準拠で locale 非依存）
  - sanitization: 40 文字 truncate + printable ASCII only（`drift_events[].original_token` への格納値、secret leak 防御）
  - **drift_sink append 時の entry shape（5 キー必須、design.md §drift_events[] schema 準拠）**: `{"original_token": <raw_str>, "sanitized_token": <sanitized_display>, "demoted_to": "INFO", "source_field": <from_source_context>, "context": <from_source_context>}`。requirements.md AC 1.9 (ii) の 4 キー表記（`source_context` 単一）は本設計で `source_field + context` の 2 キーに展開され実装される（requirements は Design constraint として設計フェーズ決定を許容）
  - stderr フォーマット（AC 1.9 確定、4 行形式）: `[severity-drift] unknown token in <context>: <sanitized_T>\n  - source: <source_field>\n  - related location: <location>\n  - demoted to: INFO`
  - 観察可能完了条件: 全 5 fixture pass、`_VALID_SEVERITIES = {"CRITICAL", "ERROR", "WARN", "INFO"}` 定数が導入され drift 判定の single source of truth になる、drift_sink の全要素が 5 キー（original_token / sanitized_token / demoted_to / source_field / context）を持つ、`pytest tests/test_rw_light.py::test_normalize_severity_token` green
  - _Requirements: 1.1, 1.5, 1.9_
  - _Boundary: severity helpers_

- [x] 1.3 `_validate_agents_severity_vocabulary` helper の TDD 実装
  - 先に `tests/test_audit.py` に test_vault_vocabulary_validation を red で追加: (a) 新語彙のみ AGENTS（PASS）/ (b) Pattern A（table cell `| HIGH |` 等）検出 → 複数行 error message / (c) Pattern B（summary key `- high:` 等、行頭限定）検出 / (d) Pattern C（finding bracket `[HIGH]` 等）検出 / (e) Pattern A/B/C 混在時 → 全パターン列挙した error message / (f) Migration Notes ブロック（`<!-- severity-vocab: legacy-reference --> 〜 <!-- /severity-vocab -->`）内の旧語彙は除外 / (g) 1 MB 超えファイルは `SystemExit(1)` + error message / (h) symlink 先が vault-root 外の場合 `SystemExit(1)` + `[vault-validation] path escape detected` stderr
  - `scripts/rw_light.py` に `_validate_agents_severity_vocabulary(agents_file: Path) -> None` を実装（Pattern A/B/C の 3 regex + 1 MB file size 上限 + Migration Notes ブロック除外 + no-caching 不変量 + symlink path escape 防御）
  - error message 形式: `[agents-vocab-error] deprecated severity vocabulary detected in <path>:\n  line <N>: <pattern_id> → <snippet>\n  ... (detected <count> violation(s))\n  Run 'rw init --force <vault>' to redeploy.`（複数行、line / pattern_id / snippet を含む）
  - Sort stability: 同一行で複数 Pattern match する場合、(line, col, pattern_id) の 3 段 key で deterministic ordering
  - 観察可能完了条件: 8 fixture が正しい PASS/FAIL を返し、エラーメッセージに正確な line / pattern_id / violation count が含まれる、`pytest tests/test_audit.py::test_vault_vocabulary_validation` green
  - _Requirements: 7.9, 8.6_
  - _Boundary: severity helpers_

- [x] 1.4 Vault validation の `load_task_prompts` フック + `--skip-vault-validation` escape hatch + `build_audit_prompt` severity prefix 挿入 + Claude mock drift 可視性 e2e テスト（TDD、AC 7.10 対応）
  - 先に `tests/test_audit.py` に test_vault_validation_hook / test_skip_vault_validation_flag / test_build_audit_prompt_severity_prefix / **test_claude_mock_drift_visibility_e2e** の 4 test を red で追加
  - `load_task_prompts()` L846-886 に `task_name == "audit"` 分岐で `_validate_agents_severity_vocabulary` を呼び出すフックを追加、`skip_vault_validation: bool = False` kwarg 受け入れ、audit subcommand の argparse から kwarg を伝播
  - audit subcommand の argparse に `--skip-vault-validation` flag を追加（環境変数 `RW_SKIP_VAULT_VALIDATION=1` との OR 結合）。strict mode 系 flag（`--strict-severity`）および dry-run mode flag（`--validate-vault-only`）は Y Cut で除外
  - `--skip-vault-validation` 使用時は stderr に warning `[vault-validation] SKIPPED (--skip-vault-validation or RW_SKIP_VAULT_VALIDATION=1 set). Drift 3-layer defense weakened.` を出力しつつ処理継続
  - `build_audit_prompt()` 冒頭に Severity Vocabulary (STRICT) prefix ブロックを挿入（AC 8.5、drift 3 層防御 Layer 2）: task_prompts 本文差し込み直前に固定文字列 `"## Severity Vocabulary (STRICT)\n\nUse ONLY these severity tokens: CRITICAL, ERROR, WARN, INFO.\nDo NOT use deprecated tokens: HIGH, MEDIUM, LOW.\nAny deviation will be flagged as drift in post-processing.\n\n"` を埋め込み
  - **test_claude_mock_drift_visibility_e2e（AC 7.10 専用 integration test）**: `claude_mock_response` fixture で Claude CLI subprocess を mock し、findings 配列に 4 水準外 severity（例: `"HIGH"` / `"WARNING"` / `"CRITICAL_ERROR"`）を含む応答を注入。`rw audit weekly --skip-vault-validation` を subprocess 経由で実行し、(i) stderr に `[severity-drift]` 警告が少なくとも 1 行出現、(ii) `logs/audit-weekly-<timestamp>.md` に対応する `drift_events[]` section（または関連 finding の `INFO` 降格）が出現、(iii) exit code 0 or 2（drift 検出でも audit 継続）、(iv) drift 対応 finding が drop されず保持されていること、を検証。drift cap / sentinel / invocation end summary は Y Cut で未実装のため検証対象外
  - 観察可能完了条件: 4 test green、`rw audit <tier>` が deprecated Vault で `SystemExit(1)` + 複数行 stderr error、`rw audit <tier> --skip-vault-validation` で escape hatch warning を stderr に出力しつつ継続、`build_audit_prompt()` の戻り文字列の最初のブロックに新語彙明示 + 旧語彙禁止 instruction が含まれる、Claude mock drift test で Layer 3 runtime gate が drift を stderr + drift_events に可視化する e2e 動作確認済
  - _Requirements: 1.9, 6.5, 7.9, 7.10, 8.5, 8.6_
  - _Boundary: CLI command layer + audit prompt construction_
  - _Depends: 1.2, 1.3_

- [x] 1.5 (P) `templates/AGENTS/audit.md` の severity 語彙 rename
  - Pattern A（table cell `| HIGH |` → `| ERROR |` 等、3 行、L144-147）
  - Pattern B（summary key `- high:` → `- error:` 等、3 行、L48-50）
  - Pattern C（finding bracket marker `[HIGH]` → `[ERROR]` 等、3 箇所、L53-58）
  - `CRITICAL` はすべて維持
  - 観察可能完了条件: `grep -nE '\b(HIGH|MEDIUM|LOW)\b' templates/AGENTS/audit.md` が Migration Notes ブロック外で no match
  - _Requirements: 1.2, 1.7_
  - _Boundary: AGENTS templates_

- [x] 1.6 `Finding` NamedTuple から sub_severity 廃止（機械的一括削除）
  - NamedTuple L1267-1274 から `sub_severity: str` 行を削除
  - Finding コンストラクタ 25 箇所の `sub_severity=...` kwarg を全削除（L1328, L1346, L1370, L1402, L1414, L1427, L1439, L1467, L1528, L1607, L1629, L1646, L2374 等）
  - `_format_finding_line` L1988-1998 の `f.sub_severity` 参照削除、sev_tag を `[{severity}]` 単一化（2 段表記 `[ERROR] [CRITICAL 由来]` を廃止）
  - 既存 test の `sub_severity=` を期待する assertion を削除 / 更新
  - 観察可能完了条件: `grep -n "sub_severity" scripts/rw_light.py tests/` が no match、audit markdown 出力の finding prefix が `[CRITICAL]` / `[ERROR]` / `[WARN]` / `[INFO]` 単一表記
  - _Requirements: 1.5, 4.5_
  - _Boundary: Finding data structure + output formatting_
  - _Depends: 1.2_

- [x] 1.7 `map_severity()` 全廃と `_normalize_severity_token` 置換（機械的一括置換）
  - `map_severity()` L1696-1715 の関数定義を削除
  - `_run_llm_audit` L2360-2376 の `cli_severity, sub_severity = map_severity(f["severity"])` を `severity = _normalize_severity_token(f["severity"], source_context={"context": f"audit {tier}", "source_field": f"findings[{i}].severity", "location": f.get("location", "-")}, drift_sink=drift_events)` に置換（source_context は dict 必須、Task 1.2 signature 確定事項）
  - `parse_audit_response` 等の残存 `map_severity` 呼び出し箇所を全て `_normalize_severity_token` に置換
  - 既存 test の `map_severity` tuple 期待を identity assertion に更新
  - invocation scope の `drift_events: list[dict] = []` を `_run_llm_audit` / `cmd_lint` / `cmd_lint_query` の冒頭で初期化（cap / sentinel / invocation summary は実装しない、Y Cut）
  - 観察可能完了条件: `grep -n "map_severity" scripts/rw_light.py tests/` が no match、`rw audit` 出力に `CRITICAL` が identity で現れる、drift 発生時に stderr 記録 + `drift_events[]` append（cap なし、上限なし）
  - _Requirements: 1.5, 1.7, 1.9_
  - _Boundary: audit parsing layer_
  - _Depends: 1.2, 1.6_

- [x] 1.8 `parse_audit_response` の 4 段構造検証（silent skip 廃止、TDD）
  - 先に test_parse_audit_response_structural_invariants を red で追加: (a) 非 dict 応答 → `RuntimeError` → exit 1 / (b) `findings` key 非 list / (c) `findings[i]` 非 dict → placeholder finding + drift_events 記録 / (d) 必須 key（severity / message / location）欠落 → 補完 + drift_events 記録 / (e) 正常応答の 5 fixture
  - 実装: (i) top-level type 検証（非 dict は `RuntimeError`）、(ii) findings key 型検証、(iii) 各 finding item の `isinstance(dict)` + placeholder + drift_events 記録、(iv) message / location 欠落は補完 + drift_events 記録
  - severity coerce 3 段（`raw_sev → str coerce → _normalize_severity_token` 呼出、drift_events に missing-severity 記録）。**呼出パターン**（Task 1.2 signature 準拠、source_context は dict）: `severity = _normalize_severity_token(coerced_sev, source_context={"context": cmd_context, "source_field": f"findings[{i}].severity" if raw_sev is not None else f"findings[{i}].<missing-severity>", "location": finding.get("location", "-")}, drift_sink=drift_events)`。missing-severity 時も source_field を `<missing-severity>` 付き JSON path で記録し、drift_events の可観測性を保持
  - silent skip（現行 L1904-1908）は廃止（AC 1.9 違反防止）、全 finding を配列長保持で必ず返す
  - 観察可能完了条件: 5 fixture すべて pass、`pytest tests/test_audit.py::test_parse_audit_response_structural_invariants` green、silent skip されずに placeholder finding が drift_events 経由で可視化される
  - _Requirements: 1.5, 1.9_
  - _Boundary: audit parsing layer_
  - _Depends: 1.7_

- [x] 1.9 `rw init --force` フラグ実装（symlink 防御 + timestamp collision fallback、TDD）
  - 先に `tests/test_rw_light.py` に test_rw_init_force_overwrites_agents を red で追加: (a) 既存 `AGENTS/audit.md` が存在する Vault で `rw init --force <vault>` が旧 AGENTS を新 template で上書きする / (b) `--force` 無しで既存 AGENTS がある場合は旧動作（skip or error）を維持 / (c) `--force` 指定時の stderr に上書き通知出力 / (d) `.backup/` が既存 symlink の場合 `SystemExit(1)` + `[rw-init] .backup/ must be a regular directory` stderr（symlink 先への意図しない書込防御）/ (e) `<timestamp>` directory が既に存在する場合（同一秒内の 2 回目 `--force`）、`<timestamp>-<pid>` フォールバック名で作成して成功
  - `cmd_init` に `--force` argparse flag を追加、既存 AGENTS ディレクトリのバックアップ（`.backup/<timestamp>` 配下に退避、`.backup/` が既存 symlink なら abort、`<timestamp>` 衝突時は `<timestamp>-<pid>` fallback）後に `templates/AGENTS/` 全ファイルを再コピーする経路を実装
  - `.gitignore` に `logs/` または `logs/*_latest.json` の exclusion 行が存在することを本タスクの PR で先行確認（`drift_events[].original_token` が raw Claude 応答を最大 40 bytes 保持するため secret leak 防御として重要）。未除外の場合、同一 PR で `.gitignore` に `logs/` を追加
  - 観察可能完了条件: 5 fixture pass、`rw init --force <vault>` 実行で `<vault>/AGENTS/audit.md` が新 template の内容で上書きされ、旧版は `<vault>/.backup/<timestamp>/AGENTS/audit.md`（または衝突時は `<timestamp>-<pid>/`）に退避され、`.backup/` が symlink の場合は abort、`grep -nE '^logs/' .gitignore` が 1 件以上 match
  - _Requirements: 6.5_
  - _Boundary: cmd_init_

- [x] 1.10 P1 atomic 完了ゲート: 統合 test 全件 green + pre-flight Vault 再デプロイ確認 + post-merge operator instruction 記載
  - P1 の 9 sub-tasks（1.1-1.9）を 1 PR で完結、部分 merge 禁止（identity 化と Vault validation を分離すると旧 Vault + 新 runtime の silent drift が発生するため atomic 強制）
  - `tests/test_audit.py` / `tests/test_rw_light.py` が全件 green、`rw audit <tier>` の出力 severity 語彙が identity 化で新 4 水準を返す、Vault validation が deprecated Vault で `SystemExit(1)` abort、`rw init --force` が symlink 防御 + timestamp collision fallback で 5 fixture pass
  - **pre-flight 必須**: P1 PR 作成前に `rw init --force <vault-path>` を実行し、Vault AGENTS が新 template と同期していることを `rw audit weekly --skip-vault-validation` で確認（escape hatch で validation を bypass しつつ Claude 応答が新語彙で返ることを手動確認）。未実行の場合、本 P1 PR を merge すると既存 Vault の旧語彙で audit が `SystemExit(1)` abort する
  - **post-merge operator instruction 必須**: P1 PR description の冒頭に inline 記載: `⚠️ After pulling this PR, all operators MUST run 'rw init --force <vault-path>' before next 'rw audit' invocation. Without redeployment, audit will abort with exit 1 due to Vault vocabulary validation.` — P3（SSoT Migration Notes / CHANGELOG）完了前の P1 先行 merge を想定し、migration 手順を PR description に self-contained 化
  - **CLI 出力観察**: `rw audit <tier>` stdout に `CRITICAL` が新規出現（それ以外の語彙は旧→新 rename）、audit markdown finding prefix が `[CRITICAL]` / `[ERROR]` / `[WARN]` / `[INFO]` 単一表記、`drift_events[]` 配列（可能なら空 list）が出力に含まれる
  - 観察可能完了条件: `pytest tests/test_audit.py tests/test_rw_light.py` 全件 green、P1 PR description に `[pre-flight: rw init --force executed + rw audit --skip-vault-validation passed]` マーカーおよび post-merge operator instruction ブロックが inline 記載されている
  - _Requirements: 1.5, 7.5, 7.9_
  - _Depends: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9_

## 2. P2: status 2 値化 + exit code 3 値分離 + 隣接コマンド更新（統合、1 PR 推奨）

- [x] 2.1 `_compute_run_status(findings)` helper の TDD 実装
  - 先に `tests/test_rw_light.py` に test_compute_run_status を red で追加: (a) 空 findings → `"PASS"` / (b) INFO のみ → `"PASS"` / (c) WARN のみ → `"PASS"` / (d) ERROR 1 件 → `"FAIL"` / (e) CRITICAL 1 件 → `"FAIL"` / (f) CRITICAL + ERROR 混在 → `"FAIL"` の 6 fixture
  - 実装: CRITICAL または ERROR が 1 件以上 → `"FAIL"`、それ以外 → `"PASS"`
  - 観察可能完了条件: 6 fixture が期待通りの status を返す、`pytest tests/test_rw_light.py::test_compute_run_status` green
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.8, 2.9_
  - _Boundary: severity helpers_

- [x] 2.2 `_compute_exit_code(status, had_runtime_error)` helper の TDD 実装
  - 先に test_compute_exit_code を red で追加: (a) status="PASS" + had_runtime_error=False → 0 / (b) had_runtime_error=True（status 不問）→ 1 / (c) status="FAIL" + had_runtime_error=False → 2 の 6 fixture（status ∈ {"PASS", "FAIL", None} × runtime ∈ {True, False}）
  - 実装: `had_runtime_error` が True なら 1 を返す（status 引数に優先、Composition invariant H-2）、FAIL なら 2、PASS なら 0
  - 観察可能完了条件: 6 fixture が期待通りの exit code を返す、helper 単体 test green
  - _Requirements: 3.1, 3.2, 3.3, 3.4_
  - _Boundary: severity helpers_

- [ ] 2.3 (P) `templates/AGENTS/lint.md` の status / exit code / severity 記述更新
  - L32-34 終了コード（0/1 → 0/1/2）更新、L44 status スキーマ（`"PASS | WARN | FAIL"` → `"PASS | FAIL"`）、L50 summary 構造（`{pass, warn, fail}` → `{pass, fail, severity_counts: {critical, error, warn, info}}`）、判定レベル節を status / severity の 2 次元構造に再構成
  - `templates/AGENTS/ingest.md` L43 の schema reference を top-level status 参照に更新（`summary.fail > 0` は deprecated alias として維持、意味不変）
  - `templates/AGENTS/git_ops.md` の FAIL 件数参照箇所が新体系で意味保持されることを verify
  - 観察可能完了条件: lint.md / ingest.md / git_ops.md の記述が新体系と矛盾しない、Pattern A/B/C/D の 4 regex で旧語彙残存 0 件（status 位置 WARN 含む）
  - _Requirements: 1.8_
  - _Boundary: AGENTS templates_

- [ ] 2.4 `cmd_lint` の status 計算差替え + `lint_latest.json` schema 更新（機械 JSON 変更、TDD）
  - 先に test_lint_json_new_schema を red で追加: top-level `status ∈ {"PASS","FAIL"}` / `files[].status ∈ {"PASS","FAIL"}` / `summary.severity_counts` の 4 キー（critical/error/warn/info）存在 / `summary.warn` 非存在 / `drift_events` フィールド存在（空 list 可）を検証（`schema_version` フィールドは **追加しない**、Y Cut）
  - 実装: per-file status を 2 値（PASS / FAIL）に、`summary.warn` を削除、`summary.severity_counts` 追加、top-level `status` を追加、`files[].status` から WARN を削除、`drift_events[]` フィールド追加
  - `_compute_run_status` を使用（2.1 に依存）
  - 検査項目ごとの severity 割当（frontmatter 欠落 → ERROR / 短すぎる本文 → WARN 等）を design §検査項目ごとの severity 割当（AC 1.6 確定）table に従って適用
  - 観察可能完了条件: test_lint_json_new_schema green、`rw lint` で生成した lint_latest.json が新 schema に適合（schema_version なし）
  - _Requirements: 1.3, 1.6, 2.2, 2.3, 2.6, 2.7, 4.1, 4.2, 4.3, 4.6_
  - _Boundary: cmd_lint (JSON output)_
  - _Depends: 2.1_

- [ ] 2.5 `cmd_lint` の stdout / per-file 表示更新（human-visible 変更、TDD）
  - 先に test_lint_stdout_4_tier を red で追加: per-file 行 `[PASS] path (warn: 2, info: 1)` 形式（0 件水準省略）/ stdout summary 行に 4 水準件数と status を併記 / WARN が status 位置に出現しないこと / **対象 0 件時（lint 対象ファイル 0 件）も status（PASS）は表示される**（AC 5.5 境界）/ **問題 0 件時（全 PASS）も status は表示される**（AC 5.5 境界、severity 別件数行のみ省略可）を検証
  - 実装: per-file display format 変更、stdout summary 行拡張（`lint: CRITICAL X, ERROR Y, WARN Z, INFO W — status` 形式）、0 件ケースの status 行常時表示
  - 観察可能完了条件: test_lint_stdout_4_tier green、`rw lint` 実行時の stdout が 4 水準併記形式 + 最終 status を表示、対象 0 件および問題 0 件の 2 境界で status 行が省略されないこと
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_
  - _Boundary: cmd_lint (stdout)_
  - _Depends: 2.1_

- [ ] 2.6 `cmd_lint_query` の status 計算差替え + checks[] 単一化 + `query_lint_latest.json` schema 更新（機械 JSON 変更、TDD）
  - 先に test_lint_query_json_new_schema を red で追加: `PASS_WITH_WARNINGS` 非出力 / `checks[]` 単一配列（errors/warnings/infos 3 配列なし）/ `severity_counts` 4 キー / `drift_events` フィールド存在を検証（`schema_version` 追加なし）
  - `lint_single_query_dir` の add 関数を 4 severity 対応に拡張、`checks[]` 1 配列に集約（errors[] / warnings[] / infos[] 廃止）
  - `PASS_WITH_WARNINGS` を廃止、PASS / FAIL の 2 値に統合、top-level status から `PASS_WITH_WARNINGS` を削除
  - 検査項目ごとの severity 割当を design §検査項目ごとの severity 割当 table に従って適用
  - 観察可能完了条件: test_lint_query_json_new_schema green、新 JSON schema に適合
  - _Requirements: 1.4, 1.6, 2.4, 2.5, 2.6, 4.2, 4.4, 4.6_
  - _Boundary: cmd_lint_query (JSON output)_
  - _Depends: 2.1_

- [ ] 2.7 `cmd_lint_query` の stdout / summary 表示更新（human-visible 変更、TDD）
  - 先に test_lint_query_stdout_4_tier を red で追加: stdout summary 行が `query lint: CRITICAL X, ERROR Y, WARN Z, INFO W — status` 形式 / **対象 query 0 件時も status（PASS）は表示される**（AC 5.5 境界）/ **問題 0 件時も status は表示される**（AC 5.5 境界、severity 別件数行のみ省略可）を検証
  - `print_query_lint_text` L3012-3031 の「X error(s), Y warning(s)」表示を 4 水準併記に拡張、0 件ケースの status 行常時表示
  - 観察可能完了条件: test_lint_query_stdout_4_tier green、`rw lint query` 実行時の stdout が 4 水準併記形式 + 最終 status を表示、対象 0 件および問題 0 件の 2 境界で status 行が省略されないこと
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_
  - _Boundary: cmd_lint_query (stdout)_
  - _Depends: 2.1_

- [ ] 2.8 `cmd_audit_*` の status 計算差替え + CRITICAL 可視化（TDD）
  - 先に test_audit_summary_critical_visibility を red で追加: Summary 節に `- CRITICAL: N` 行 / stdout format `audit <tier>: CRITICAL X, ERROR Y, WARN Z, INFO W — status` / 件数 0 水準も常時表示 を検証
  - `generate_audit_report` / `print_audit_summary` で `_compute_run_status(findings)` 使用
  - Summary 節に `- CRITICAL: {critical_count}` 行を追加（4 水準件数を全て常時表示）
  - stdout format を `f"audit {tier}: CRITICAL {c}, ERROR {e}, WARN {w}, INFO {i} — {status}"` に拡張
  - **AC 5.5 境界検証**: Vault 内 audit 対象 0 件時（例: empty vault）も stdout に `audit <tier>: CRITICAL 0, ERROR 0, WARN 0, INFO 0 — PASS` 形式の status 行が表示される、問題 0 件（全 PASS）時も status 行が省略されない
  - 観察可能完了条件: test_audit_summary_critical_visibility green、audit markdown Summary 節に CRITICAL 行が存在、対象 0 件および問題 0 件の 2 境界で stdout status 行が省略されないこと
  - _Requirements: 2.8, 2.9, 4.5, 5.4, 5.5_
  - _Boundary: cmd_audit_
  - _Depends: 2.1_

- [ ] 2.9 `cmd_lint` / `cmd_audit_*` の FAIL → exit 2 移行（TDD）
  - 先に test_lint_exit_2_on_fail / test_audit_exit_2_on_fail を red で追加: FAIL → exit 2、runtime error → exit 1、PASS → exit 0
  - 旧 `return 1`（FAIL 由来）を `_compute_exit_code(status, had_runtime_error)` 経由に置換（exit 2）
  - runtime error 系は `_compute_exit_code(status=None, had_runtime_error=True)` で exit 1
  - 観察可能完了条件: test が green、3 値 exit 契約が cmd_lint / cmd_audit で統一
  - _Requirements: 3.3, 3.7, 7.4_
  - _Boundary: cmd_lint + cmd_audit_
  - _Depends: 2.2_

- [ ] 2.10 `cmd_lint_query` の旧 exit 3 / 4 を exit 1 に統合（TDD）
  - 先に test_lint_query_exit_code_consolidation を red で追加: 引数エラー / path 不在 → exit 1、FAIL → exit 2、PASS → exit 0
  - 手動パーサー L3041-3064 の旧 `return 3`（引数エラー）/ `return 4`（path 不在）を `_compute_exit_code(status=None, had_runtime_error=True)` 経由で exit 1 に統合
  - FAIL 検出は exit 2 に統一（AC 3.3）
  - 観察可能完了条件: test green、旧 exit 3/4 が exit 1 に統合、FAIL は exit 2 に分離
  - _Requirements: 3.2, 3.4, 7.4_
  - _Boundary: cmd_lint_query_
  - _Depends: 2.2_

- [ ] 2.11 `cmd_ingest` の precondition failure を exit 1 として維持 + WARN 解釈除去（AC 8.1 + 8.2、TDD）
  - 先に test_ingest_precondition_exit_1 を red で追加: 上流 FAIL → exit 1（exit 2 にしない）、PASS → 続行 exit 0、status 位置 WARN → FAIL と同等扱い（旧コードパス除去の regression 防止）
  - 上流 lint の FAIL 検知（`summary.fail > 0` または top-level `status == "FAIL"`）で stderr precondition msg + exit 1
  - status 位置の WARN を解釈するコードパスを除去（AC 8.2）
  - 観察可能完了条件: test green、`cmd_ingest` の上流 FAIL 参照時 exit 1 を維持（AC 8.1 と整合）、status 位置 WARN 解釈コード 0 件
  - _Requirements: 3.2, 3.4, 7.4, 7.8, 8.1, 8.2_
  - _Boundary: cmd_ingest_
  - _Depends: 2.2_

- [ ] 2.12 `cmd_query_extract` / `cmd_query_fix` の exit code 整合（TDD）
  - 先に test_query_extract_exit_2_on_fail / test_query_fix_exit_2_on_fail を red で追加: 内部 lint FAIL → exit 2（artifact 保持）、runtime error → exit 1、PASS → exit 0
  - 内部 `lint_single_query_dir()` 結果が FAIL → exit 2（artifact 保持）
  - runtime error → exit 1
  - 観察可能完了条件: test green、生成 artifact 存在確認 + 3 値 exit 契約
  - _Requirements: 3.5, 3.6, 7.4, 8.3_
  - _Boundary: cmd_query_extract + cmd_query_fix_
  - _Depends: 2.2_

- [ ] 2.13 P2 完了ゲート: status 2 値 + exit code 3 値の統合 test 全件 green + Reverse Dependency Inventory scan 実施
  - `pytest tests/test_lint.py tests/test_lint_query.py tests/test_audit.py tests/test_ingest.py tests/test_rw_light.py` 全件 green、4 水準 stdout format が 3 コマンド横断で一貫、exit code の意味が 10 CLI コマンド全てで設計書と一致（`rw init` / `rw synthesize-logs` / `rw approve` / `rw query answer` は exit 0/1 のみ、他 6 コマンドは exit 0/1/2 の 3 値）
  - **Reverse Dependency Inventory scan 実施**（Task 3.5 連携、exit 2 破壊的影響の pre-commit 検出）: design.md §Reverse Dependency Inventory の 7 grep コマンドを P2 PR commit 前に local 実行し、結果（hits 件数）を P2 PR description に `[reverse-dep scan: clean]` または `[reverse-dep scan: N hits, addressed in <commit-SHA>]` マーカー形式で記載。hits > 0 の場合は該当箇所（shell / CI / hooks / skills 等）の exit code 分岐 migration を同一 PR 内の先行 commit または別 PR 先行マージで対応。scan の snapshot 記録は P3 Task 3.5 で developer-guide.md に反映
  - 観察可能完了条件: 5 test file 全件 green、exit code 3 値契約が 10 コマンド横断で統一、`PASS_WITH_WARNINGS` および status 位置 WARN が構造化出力 / stdout から消失、**P2 PR description に `[reverse-dep scan: clean|N hits]` マーカーが inline 記載済**
  - _Requirements: 7.2, 7.3, 7.4, 7.5_
  - _Depends: 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 2.10, 2.11, 2.12_

## 3. P3: docs + 隣接 spec + 静的スキャン + Acceptance Smoke Test（縮約、1 PR 推奨）

- [ ] 3.1 `docs/developer-guide.md` SSoT **7 節** の新規執筆（Y Cut 後の authoritative 節構成、Task 3.5 が §Reverse Dependency Inventory を 8 節目として後続追加）
  - **Y Cut 整合注記**: design.md L368-414 の developer-guide.md 節構成は original 5-phase plan の参照用。Y Cut 後は本 Task の 7 節のみ実装し、design.md が記述する §Emergency Procedures の `--skip-vault-validation` 以外の項目 / §Environment Variables and CLI Flags の `--strict-severity` / `--validate-vault-only` 関連 / Glossary の `MAX_DRIFT_EVENTS` / `Drift_events sentinel` / `Schema version` / `Transitional normalize` エントリは **記載しない**（`observability-infra` spec に繰延、本 docs では Y Cut 整合の SSoT のみ記述）
  - **§Reverse Dependency Inventory は本 Task の範囲外**: developer-guide.md の 8 節目として Task 3.5 が後続追加する（`_Depends: 3.1_` 関係により本 Task 完了後に 3.5 が節を挿入）。本 Task では placeholder を残さず、節見出しのみ将来位置として comment で予約しておくことを推奨（例: `<!-- §Reverse Dependency Inventory は Task 3.5 で追加 -->`）
  - §Severity Vocabulary: 4 水準 × 定義 × 使用例 table（3 列 10 行以上、`CRITICAL` / `ERROR` / `WARN` / `INFO` を順序保持で列挙）
  - §Exit Code Semantics: 3 値 × 意味 × 典型事例 table（exit 0 = PASS、exit 1 = runtime error + precondition 不成立、exit 2 = FAIL 検出）
  - §Migration Notes: Before/After 例、Shell script migration recipe（`case $?` の 3 値分岐例）、JSON consumer migration 対応表（旧 schema → 新 schema のフィールド変換、`schema_version` フィールド非使用のため `summary.severity_counts` / top-level `status` / `drift_events[]` の existence-based 検出方式を明示）
  - §Vault Redeployment Procedure: `rw init --force` の使用タイミング・手順・rollback 時の注意、symlink 防御と timestamp collision（`<timestamp>-<pid>` fallback）の挙動説明、`--skip-vault-validation` escape hatch の用途（regex false positive 時の緊急時のみ）
  - §Glossary: severity / status / exit code / drift / vault / Vault validation / precondition failure / identity mapping / escape hatch / drift_events の **10 用語以上** × 定義（`MAX_DRIFT_EVENTS` / sentinel / schema_version / strict mode は Y Cut 除外のため記載なし）
  - §Debugging FAIL (exit 2): 診断 5 手順（`summary.severity_counts` → `files[]`・`checks[]` → `drift_events[]` → 該当ファイル行 navigate → 再実行 exit 0 確認）、stderr drift warning の読み方（4 行形式）、Vault validation error の修正手順（Pattern A/B/C 種別の意味）
  - **§Acceptance Smoke Test (Y Cut 後 7 ケース)**（新設、tasks.md 3.11 実行内容の runbook 化、Fix #8）: Task 3.11 で実行する 7 ケース手動 smoke test を developer-guide.md に runbook として転記。各ケース（1 `rw audit weekly` PASS Vault / 2 FAIL Vault / 3 deprecated Vault abort / 4 `--skip-vault-validation` escape / 5 `rw lint` 3 exit / 6 `rw ingest` 上流 FAIL exit 1 / 7 `rw query extract` FAIL exit 2 + artifact 保持）に期待 exit code + 期待 stdout 抜粋を掲載。design.md L485-512 の 5-minute QA（`--validate-vault-only` / `schema_version` 使用）は Y Cut 除外項目に依存するため採用せず、本 7 ケースに置換
  - **Legacy example wrapping 規約（Fix #C 対応）**: §Migration Notes 内の Before/After 例で旧 vocabulary（status 位置の `WARN`、`PASS_WITH_WARNINGS`、旧 `HIGH` / `MEDIUM` / `LOW`、旧 exit code semantics の例示）を含む code block は必ず `<!-- severity-vocab: legacy-reference -->` と `<!-- /severity-vocab -->` で wrap する（Task 3.8 Pattern A-D の false positive 誤検出回避）。新 vocabulary のみの例は wrap 不要
  - 観察可能完了条件: 7 節すべてが存在（§Reverse Dependency Inventory は Task 3.5 で 8 節目として追加、本 Task の範囲外）、各節に code block + 具体例が含まれる、§Severity Vocabulary と §Exit Code Semantics が table 3 行以上、§Glossary に 10 用語以上（Y Cut 除外用語は含まない）、§Acceptance Smoke Test に 7 ケース all coverage、developer-guide.md 内の grep で `MAX_DRIFT_EVENTS` / `--strict-severity` / `--validate-vault-only` / `write_log_atomic` が 0 件（`schema_version` は §Migration Notes の "non-use 説明" で 1〜2 箇所の legitimate 言及を許容、legacy-reference marker wrap 内に限定）、legacy vocabulary を含む Before 例が全て `<!-- severity-vocab: legacy-reference -->` wrap 内に配置されている
  - _Requirements: 6.1, 6.3, 6.4_
  - _Boundary: documentation (SSoT)_

- [ ] 3.2 Reference docs の一括更新（cross-reference + 要約、重複禁止）
  - `docs/user-guide.md` / `docs/audit.md` / `docs/lint.md` / `docs/ingest.md` / `docs/query.md` / `docs/query_fix.md` の 6 file を cross-reference + 要約のみに更新（詳細定義は `docs/developer-guide.md` SSoT に委譲、重複禁止）
  - 各 file の §Severity Level 節に「詳細は developer-guide.md §Severity Vocabulary 参照」のリンクを最低 1 箇所含める
  - 観察可能完了条件: 全 6 reference docs に §Severity Level 節 + SSoT への cross-reference が 1 箇所以上存在、旧 severity / status 語彙（HIGH/MEDIUM/LOW、PASS_WITH_WARNINGS、status 位置 WARN）残存 0 件
  - _Requirements: 6.1, 6.3, 6.4_
  - _Boundary: documentation (reference)_
  - _Depends: 3.1_

- [ ] 3.3 `README.md` 更新
  - severity / status / exit code 記述を新体系に更新
  - developer-guide.md §Migration Notes / §Acceptance Smoke Test へのリンク追加
  - 観察可能完了条件: README.md に新 4 水準 / 2 値 status / 3 値 exit code の簡潔な記述 + SSoT リンクが存在
  - _Requirements: 6.1_
  - _Boundary: documentation (entry point)_
  - _Depends: 3.1_

- [ ] 3.4 `CHANGELOG.md` 追記（Keep a Changelog 形式）
  - ⚠️ BREAKING CHANGES 5 項目を列挙（Requirements AC 6.2 (a)-(e) 全カバー必須、本 Task の (a)-(e) 再編版は同じ範囲を組み替え表記）:
    - (a) **severity vocabulary 4 水準化**（AGENTS/audit.md の HIGH/MEDIUM/LOW → ERROR/WARN/INFO rename、CRITICAL 維持）— **Requirements 6.2 (b) 充足**
    - (b) **status vocabulary 2 値化**（PASS / FAIL のみ、`PASS_WITH_WARNINGS` / `rw lint` の status から `WARN` を全廃）— **Requirements 6.2 (a) + (c) 充足**
    - (c) **exit code 3 値分離**（0/1/2、旧 `rw lint` / `rw audit` FAIL=exit 1 → exit 2、旧 `rw lint query` exit 3/4 → exit 1）— **Requirements 6.2 (e) 充足**
    - (d) **Finding 構造簡素化**（`sub_severity` NamedTuple フィールド廃止、finding prefix 単一表記 `[CRITICAL]` / `[ERROR]` / `[WARN]` / `[INFO]`）— Requirements 6.2 には明示列挙なし、本スペック内部データ構造変更の追加告知
    - (e) **`logs/*_latest.json` の schema 値域変更**（`severity_counts` / top-level `status` / `drift_events[]` 追加、`summary.warn` / `errors[]` / `warnings[]` / `infos[]` 廃止、`schema_version` フィールドは Y Cut により非追加）— **Requirements 6.2 (d) 充足**
  - **Requirements 6.2 網羅検証**: 本 Task 列挙の (a)-(e) 全体で Requirements 6.2 の (a) `PASS_WITH_WARNINGS` 廃止 / (b) AGENTS rename / (c) `rw lint` status WARN 廃止 / (d) JSON 値域 / (e) exit code semantics の **5 項目全てが 1 対 1 以上でマッピング** されていること（CHANGELOG 執筆時の自己検証 checklist）
  - Migration Guide リンク（developer-guide.md 7 節へ、Task 3.1 更新後の節構成参照）
  - 既存 Vault 運用者向け警告: `rw init --force <vault-path>` 実行必須（AC 6.5）
  - 観察可能完了条件: CHANGELOG.md 末尾に severity-unification entry が既存 format と整合、既存エントリの破壊なし、(a)-(e) 5 項目すべて列挙、Requirements 6.2 (a)-(e) との対応が inline 注記または Migration Guide で辿れる
  - _Requirements: 6.2, 6.5_
  - _Boundary: documentation_

- [ ] 3.5 Reverse Dependency Inventory scan + `developer-guide.md` §Reverse Dependency Inventory 節への記録
  - **Scan 実施タイミング（Y Cut 3-phase 整合）**: design.md §Reverse Dependency Inventory は exit 2 新設の破壊的影響検出のため「P1 commit 前」と規定していたが、Y Cut 3-phase では exit 2 導入は **P2** のため、scan は **P2 commit 前（tasks.md 2.9 直前）に local 実施** し、発見結果の記録・docs 反映は本 Task（P3）で実施する。P2 で hits が発見された場合は P2 PR description に `[reverse-dep scan: N hits]` マーカー付与 + migration 対応 commit を P2 PR に同梱（または先行 PR 独立化）
  - design.md §Reverse Dependency Inventory に列挙された 7 grep コマンドを P2 前に実行し、`.git/hooks` / `.pre-commit-config.yaml` / `Makefile` / `.github/workflows` / `scripts/` / `.claude/skills/` / `templates/AGENTS/` に対する逆依存を洗い出し
  - P3 の本 Task で: scan 結果の snapshot（コマンド + hits 件数 + 対応 commit SHA）を `docs/developer-guide.md` §Reverse Dependency Inventory 節（新規）に MD table として記録、将来の consumer 追加時の checklist として再利用可能にする
  - 観察可能完了条件: scan が P2 commit 前に実施済（commit history から検証可能）、inventory scan の実行結果 snapshot が developer-guide.md に MD table 形式で存在、hits > 0 の場合は P2 PR description に `[reverse-dep scan: N hits, addressed in <PR/commit>]` マーカー、hits 0 の場合は `[reverse-dep scan: clean]` マーカー
  - _Requirements: 3.3, 6.4, 8.1_
  - _Boundary: documentation + reverse dependency updates_
  - _Depends: 3.1_

- [ ] 3.6 `roadmap.md` governance 更新（Adjacent Spec Synchronization 節の事前敷設）
  - Technical Debt L99-111 / L113-122 に完了マーク追記（`**完了**（severity-unification spec により、2026-MM-DD）`）
  - 新規 Technical Debt 1 項目を追加: `observability-infra`（severity-unification Y Cut で除外した schema_version bump / MAX_DRIFT_EVENTS cap + sentinel / `_emit_drift_summary` / strict mode / `--validate-vault-only` / atomic write helper / property-based cross-channel test / Turkish locale regression / coverage gate / flakiness detection / `.git-blame-ignore-revs` を drift 実例観察後に統合対応、着手タイミング: drift 実例観察 or 下流 JSON consumer 特定時）
  - Governance: Adjacent Spec Synchronization 節を新設（後続スペックによる完了済 requirements.md の整合更新は再 approval 不要、`_change log` への記載のみで足りる）
  - L128-136 行数見積もり refresh（`scripts/rw_light.py` 純増行数を反映、本 spec による増減を明記）
  - 観察可能完了条件: roadmap.md に 4 項目の追記（完了マーク 2 件 / `observability-infra` debt 1 件 / Governance 節 / L128-136 行数更新）が全て存在、この gate が 3.7 の再 approval 免除ルールの前提となる
  - _Requirements: 6.3_
  - _Boundary: steering_

- [ ] 3.7 (P) 隣接 spec requirements.md 同期（cli-audit / cli-query / test-suite）
  - 前提: 3.6 で roadmap Adjacent Spec Synchronization 節が敷設済（再 approval 免除ルール適用）
  - cli-audit requirements.md: Severity 体系節・Req 1-4 / Req 7 の AC を新体系に更新、`_change log` 追記（`- 2026-MM-DD: severity-unification spec により severity 4 水準 / status 2 値 / exit code 3 値分離に整合`）
  - cli-query requirements.md: R4.7 を `CRITICAL` 含む表記に更新、`_change log` 追記
  - test-suite requirements.md: Req 4 / Req 8 の status / exit code 記述を新体系に更新、`_change log` 追記
  - 3 spec の spec.json.updated_at を更新（再 approval は不要、3.6 で敷設した governance ルール適用）
  - 観察可能完了条件: 3 spec の requirements.md が新体系と整合、各 spec の `_change log` に entry が 1 件追加
  - _Requirements: 6.3_
  - _Boundary: adjacent specs_
  - _Depends: 3.6_

- [ ] 3.8 (P) `tests/test_agents_vocabulary.py` 新規（静的スキャン AC 7.6）
  - `templates/AGENTS/audit.md` / `templates/AGENTS/lint.md` / `templates/AGENTS/ingest.md` / `templates/AGENTS/git_ops.md` / `docs/audit.md` / `docs/user-guide.md` 等の AGENTS + docs 全 file 内に旧語彙（HIGH / MEDIUM / LOW / status 位置の WARN）が残存しないことを 4 パターン OR 結合 regex で検証:
    - Pattern A（旧 severity、table cell / prose、大文字）: `\b(HIGH|MEDIUM|LOW)\b`
    - Pattern B（旧 severity、Summary field key、小文字、行頭限定）: `^\s*-\s+(high|medium|low)\s*:`
    - Pattern C（旧 severity、Finding bracket marker、大文字・角括弧付き）: `\[(HIGH|MEDIUM|LOW)\]`
    - Pattern D（status 位置の `WARN`）: `"(?:PASS\s*\|\s*)?WARN(?:\s*\|\s*(?:PASS|FAIL))+"` — status schema 文字列内の `WARN` を検出（severity 文脈の合法使用と区別）
  - Migration Notes ブロック（`<!-- severity-vocab: legacy-reference --> 〜 <!-- /severity-vocab -->`）内は除外
  - 観察可能完了条件: test_agents_vocabulary の全 fixture pass（旧語彙 + status 位置 WARN 0 件検出、合法 severity 文脈は non-match）
  - _Requirements: 7.6_
  - _Boundary: tests_

- [ ] 3.9 (P) `tests/test_source_vocabulary.py` 新規（静的スキャン AC 7.7）
  - `scripts/rw_light.py` / `tests/` 内に `PASS_WITH_WARNINGS` / status 位置の `WARN` / `HIGH` / `MEDIUM` / `LOW` / 旧 exit code semantics（`rw lint` / `rw audit` の FAIL を `exit 1` として扱う文字列リテラル）の残存がないことを regex で検証
  - `CHANGELOG.md` / `docs/*.md` の Migration Notes 節は対象外（旧値言及が必須）
  - 観察可能完了条件: test_source_vocabulary が pass、対象外エリアのみ旧値残存許容
  - _Requirements: 7.7_
  - _Boundary: tests_

- [ ] 3.10 regression test: severity / status を発行しない非対象コマンドの exit code 契約 + 無発行義務（AC 7.8 + 8.4）
  - `rw init` / `rw ingest` / `rw synthesize-logs` / `rw approve` / `rw query answer` の exit 0 / 1 の 2 値契約が regression していないことを検証
  - 特に `cmd_ingest` の上流 FAIL → exit 1 の扱いを test_ingest で明示（exit 2 ではないこと）
  - **AC 8.4 検証**: 非対象コマンド 5 件が stdout / 構造化出力に `[CRITICAL]` / `[ERROR]` / `[WARN]` / `[INFO]` severity tag および `PASS` / `FAIL` status トークンを **自前で発行しない**（ingest は上流 lint の status を参照するのみ、本規約により発行義務なし）ことを grep ベース assertion で検証
  - 観察可能完了条件: `test_init` / `test_ingest` / `test_synthesize_logs` / `test_approve` / `test_query_answer` で exit code 契約が新体系に regression なしで pass、非対象コマンドの出力に severity / status トークンが自発的に出現しないことを確認
  - _Requirements: 7.8, 8.4_
  - _Boundary: tests_

- [ ] 3.11 P3 完了ゲート + Acceptance Smoke Test（最終ゲート）
  - Acceptance Smoke Test 7 ケースを手動実行（Task 3.1 §Acceptance Smoke Test に runbook 転記済、本 Task の実行結果は PR description にも `[smoke test: N/7 pass]` マーカー付与）:
    - (1) `rw audit weekly` 通常実行（PASS Vault）→ exit 0、stdout に 4 水準併記 + PASS 表示
    - (2) `rw audit weekly` FAIL Vault → exit 2、audit markdown に CRITICAL 行
    - (3) `rw audit weekly` deprecated Vault → exit 1 + 複数行 stderr error
    - (4) `rw audit weekly --skip-vault-validation` deprecated Vault → escape hatch warning + 継続（Claude drift 可視化確認）
    - (5) `rw lint` PASS → exit 0、`rw lint` FAIL → exit 2、`rw lint` 引数エラー → exit 1
    - (6) `rw ingest` 上流 FAIL → exit 1（exit 2 にならないこと確認）
    - (7) `rw query extract` artifact 生成 + 内部 lint FAIL → exit 2（artifact 保持確認）
  - `pytest tests/` 全件 green（120 秒以内）、`pytest -m "not slow"` fast subset も green
  - 観察可能完了条件: Acceptance Smoke Test 7 ケースすべてが期待 exit code で完走、`pytest tests/` 全件 green、developer-guide.md §Acceptance Smoke Test に 7 ケース全てが runbook 形式で記載済（Task 3.1 で反映）、`spec.json` の `phase: "implementation-complete"` への移行準備完了
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 7.10_
  - _Depends: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10_

## Implementation Notes
- **Task 1.4 先行実装**: `parse_audit_response()` の severity 正規化（`_normalize_severity_token` 呼出、旧語彙→INFO 降格、finding 保持、`drift_events[]` 追記）を task 1.4 で先行実装済み。task 1.8 は「4 段構造検証（非 dict 応答 → RuntimeError、findings 非 list、finding 非 dict → placeholder + drift_events）」および「missing key 補完」に集中すること。silent skip 廃止・severity coerce は既に完了。
