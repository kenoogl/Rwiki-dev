# Implementation Plan

## 概要

`scripts/rw_light.py`（約 3,827 行）を 6 モジュール（`rw_config`, `rw_utils`, `rw_prompt_engine`, `rw_audit`, `rw_query`, `rw_light`）に分割する純粋リファクタリング。design.md の Migration Strategy に従い、Phase 1 → 2 → 3 → 4a → 4b → 5 の順で「コード抽出 + 対応テストパッチ更新 + pytest green」を 1 単位として実施する。

各 Phase 完了時に `pytest tests/` が green であることを必須ゲートとする。中間 FAIL 状態を main に merge しない（design.md「Commit 単位の推奨」参照）。

## Phase 構成（ハイレベル）

| Major Task | 抽出モジュール | 完了ゲート |
|------------|----------------|-----------|
| 1 (Phase 1) | `rw_config.py` | pytest green |
| 2 (Phase 2) | `rw_utils.py` | pytest green |
| 3 (Phase 3) | `rw_prompt_engine.py`（re-export なし — Req 1.3） | pytest green |
| 4 (Phase 4a) | `rw_audit.py` | pytest green + `wc -l rw_audit.py ≤ 1,500` |
| 5 (Phase 4b) | `rw_query.py` | pytest green |
| 6 (Phase 5) | `rw_light.py` 最終スリム化 + 全体検証 + symlink smoke | pytest 642 件以上 green + 手動 smoke |

並列マーカー `(P)` は付与しない: 各 Phase は rw_light の import 構造を変更するため次 Phase の前提となり、各 Phase 内のコードタスクは対応テストパッチタスクの前提となる。

## Re-Export 戦略: ゼロ（Req 1.3 — AC 1.3 再評価後の確定方針）

`rw_light.py` への後方互換 re-export は **一切追加しない**。`call_claude` 含む全移動済みシンボルは `rw_<module>.<symbol>` 形式での直接参照のみを提供する。テスト本体に存在する約 299 件の `rw_light.<symbol>` 直接アクセス（test_rw_light.py 208, test_utils.py 28, test_audit.py 23, test_lint_query.py 22, test_git_ops.py 7, conftest.py 5, test_init.py 2, test_lint.py 2, test_conftest_fixtures.py 2）のうち **コード行 ~296 件** を各 Phase X.2 で当該 Phase の移動シンボルに対応する箇所を `rw_<module>.<symbol>` 形式に機械置換する。**conftest.py の docstring / コメント言及 3 件は書き換え対象外**（pytest 動作に影響せず、Follow-up Obligation の docs 同期タスクで別途更新）。これにより patch 先と access 先が完全対称化され、モジュール境界がテストコードからも可視となる（網羅 re-export 案を fundamental review で却下、さらに `call_claude` のみ re-export も AC 1.3 再評価で外部運用スクリプト実在なしのため廃止した経緯は design.md 参照）。

**総書き換え件数の見積**: monkeypatch 先更新 ~520 件 + 直接アクセス書き換え ~296 件（コード行のみ、docstring 言及 3 件は除外） = 約 800 件強。大半は sed/正規表現で機械化可能だが、各 Phase X.2 のスコープが当初 Option A 案より約 2 倍に拡大することを織り込んでスケジュールする（Phase X.2 ごとに 2-3 時間 → 4-6 時間程度を想定）。

**Follow-up obligation**: 本スペック実装完了後、`docs/developer-guide.md` L188-190 の呼び出し経路表を `rw_prompt_engine.call_claude` / `rw_prompt_engine.call_claude_for_log_synthesis` 参照に更新する。加えて `tests/conftest.py` L231 docstring 内の `rw_light.call_claude` 例示（および他の docstring 言及 L18 VAULT_DIRS / L55 today など）も同時に更新する（いずれも Phase 5 完了後の docs 同期作業）。

### 各 Phase X.2 での直接アクセス書き換え手順

1. **対象列挙**: `grep -nE "rw_light\.(<this_phase_moved_symbols>)" tests/` で当該 Phase の直接アクセスを全件列挙。**docstring / コメント内の言及は置換対象外**（`tests/conftest.py` 等に docstring 内の API 例示がある）— grep 結果を目視レビューし、コード行のみ抽出
2. **機械置換**: sed/正規表現で `rw_light\.<symbol>` → `rw_<module>.<symbol>` に置換。**macOS BSD sed は `\b` 非対応のため**、GNU sed (`gsed`) または Python ワンライナー（`python -c "import re, sys; print(re.sub(r'rw_light\.<symbol>\b', 'rw_<module>.<symbol>', sys.stdin.read()))"`）を使用する
3. **`from rw_light import X` 形式の検出**: `grep -nE "from rw_light import\b" tests/` で残存を確認、必要なら `from rw_<module> import X` に手動修正
4. **import 文追加**: 書き換え対象シンボルを持つテストファイルに `import rw_<module>` を追加（既存の `import rw_light` は cmd_lint / cmd_ingest 等の残留シンボル参照が残るため保持）
5. **早期検出**: `pytest tests/ --collect-only` で import エラーがないことを確認
6. **ロジック不変性**: テストアサーション・テスト関数本体のロジックは変更せず、参照経路のみ更新する（CLAUDE.md「実装中はテストを変更せず」原則のリファクタ的解釈 — sed 置換は機械的な参照経路更新でロジック改変ではない）
7. **完全性確認**: 書き換え後に `grep -nE "rw_light\.(<this_phase_moved_symbols>)(\(|\b)" tests/` で残存ヒット 0 件（docstring 言及があれば許容、コメントで明示）

### Commit 分割戦略の推奨

各 Phase X.2 は作業量が大きいため、以下の 2-3 commit 分割を推奨（design.md「Commit 単位の推奨」を強化）:
- commit X.2-a: `monkeypatch.setattr` 先更新（patch 先のみ、test ロジック不変）
- commit X.2-b: `rw_light.<symbol>` 直接アクセス書き換え + `import rw_<module>` 追加
- commit X.2-c: pytest green 復帰確認 + 軽微な fix-up（必要な場合）

これにより 1 commit あたりの diff が 100-200 行程度に収まり、レビュー容易性を確保。

### Cross-Phase ファイル touch マトリクス（境界明確化）

複数の Phase が同じテストファイルを touch する。Phase は sequential 実行のため merge conflict は発生しないが、各 Phase が「どのシンボル set のみ」を担当するかを明確化:

| File | Phase 1 (rw_config) | Phase 2 (rw_utils) | Phase 3 (rw_prompt_engine) | Phase 4a (rw_audit) | Phase 4b (rw_query) |
|------|--------|--------|------------------|----------|----------|
| `tests/conftest.py` | patch_constants 17 + import + 直接アクセス 1 (L20 VAULT_DIRS) | 直接アクセス 1 (L69 build_frontmatter) + `fixed_today` fixture L58 の `today` patch + import | — (L231 docstring の `rw_light.call_claude` 例示は書き換え対象外 — docs 同期 Follow-up で処理) | — | — |
| `tests/test_rw_light.py` | 定数 patch + 定数直接アクセス + import | utility patch + utility 直接アクセス + import | prompt engine patch + 直接アクセス + import | audit patch + 直接アクセス + import | query patch + 直接アクセス + import |
| `tests/test_audit.py` | 定数 patch | — | severity 関連 6 件 patch + 直接アクセス | audit 系 17 件 + 残り patch + 直接アクセス + import | — |
| `tests/test_approve.py` | — | git_path_is_dirty / warn_if_dirty_paths patch + import | — | — | — |
| `tests/test_ingest.py` | — | git_commit 15 件 patch + import | — | — | — |
| `tests/test_synthesize_logs.py` | — | git_path_is_dirty patch + import | call_claude_for_log_synthesis patch + import | — | — |
| `tests/test_utils.py` | — | 28 件直接アクセス + import | — | — | — |
| `tests/test_git_ops.py` | — | 7 件直接アクセス + import | — | — | — |
| `tests/test_lint.py` | — | 2 件直接アクセス + import | — | — | — |
| `tests/test_init.py` | 2 件直接アクセス + import | — | — | — | — |
| `tests/test_lint_query.py` | — | — | — | — | 22 件直接アクセス + import |
| `tests/test_conftest_fixtures.py` | — | — | L107/L119 の `rw_light.call_claude` 2 件を `rw_prompt_engine.call_claude` に更新 + `import rw_prompt_engine` 追加 | — | — |

**最終的な test ファイルの import 状態**:
- 既存 `import rw_light` は全テストファイルで保持（rw_light に残留する cmd_lint / cmd_ingest / cmd_synthesize_logs / cmd_approve / cmd_init 等の参照のため）。ただし `rw_light` へのアクセスはこれら残留コマンドに限定され、移動済みシンボル（call_claude 含む）へのアクセスは Req 1.3 により許可されない
- 新規 import は累積で追加（例: test_rw_light.py は最終的に `import rw_light, rw_config, rw_utils, rw_prompt_engine, rw_audit, rw_query` の 6 import）
- `rw_light` を一切使わないテストファイルが発生した場合（例: test_lint_query.py が cmd_lint_query 以外の rw_light シンボルを使わないケース）、`import rw_light` を削除する選択肢も可だが、本スペックでは削除を必須化しない（Phase 5 の手動確認で削除可能性を観察）

---

## Tasks

- [ ] 1. Phase 1: `rw_config` 抽出と定数 patch 移行

- [x] 1.1 `rw_config.py` 作成と全グローバル定数の移動 + 残留関数本体の bare 参照書き換え
  - `scripts/rw_config.py` を新規作成し、design.md「File Structure Plan」の rw_config セクションで列挙された全パス定数（ROOT, RAW, INCOMING, LLM_LOGS, REVIEW, SYNTH_CANDIDATES, QUERY_REVIEW, WIKI, WIKI_SYNTH, LOGDIR, LINT_LOG, QUERY_LINT_LOG, INDEX_MD, CHANGE_LOG_MD, CLAUDE_MD, AGENTS_DIR, DEV_ROOT）と全ドメイン定数（ALLOWED_QUERY_TYPES, INFERENCE_PATTERNS, EVIDENCE_SOURCE_PATTERNS, VAULT_DIRS, LARGE_WIKI_THRESHOLD, _VALID_SEVERITIES, _FAIL_SEVERITIES）を `rw_light.py` から物理移動する
  - `rw_light.py` は `import rw_config` を追加し、**Phase 1 時点で rw_light.py 内に存在する全ての関数本体**の定数参照をすべて `rw_config.X` 形式の修飾参照に書き換える（修飾参照規約 — Req 3.2 保証のため）。対象関数群は最終残留分（cmd_lint / cmd_ingest / cmd_synthesize_logs / cmd_approve / cmd_init / `_backup_timestamp`）に加え、**Phase 4a で rw_audit に移動予定の関数群**（cmd_audit_* / check_* / build_audit_prompt / parse_audit_response / _run_llm_audit / generate_audit_report / print_audit_summary / `_normalize_severity_token` / `_record_drift` / `_resolve_link` / validate_wiki_dir / load_wiki_pages / get_recent_wiki_changes / run_micro_checks / run_weekly_checks / `Finding` / `WikiPage` クラス本体）と、**Phase 4b で rw_query に移動予定の関数群**（cmd_query_* / cmd_lint_query / generate_query_id / write_query_artifacts / parse_extract_response / parse_fix_response / `_strip_code_block` / count_evidence_blocks / contains_markdown_structure / has_query_text / extract_query_type / extract_scope / has_evidence_source / contains_inference_language / lint_single_query_dir / print_query_lint_text）を**含む**（Phase 1 時点ではこれら全 44 関数 + 2 クラスがまだ rw_light 内に物理存在し bare 定数参照を持つため）。**特に注意**: cmd_init は `DEV_ROOT`（複数箇所）、`VAULT_DIRS` を bare 参照しており、これらが移動後も bare のままだと NameError 発生
  - `DEV_ROOT` は `Path(__file__).resolve().parent.parent` で `rw_config.py` の物理位置から既存と同じ値が得られることを確認する
  - **残留関数本体の bare 参照ゼロ検証**: `grep -nE "(^|[^a-zA-Z0-9_.])(ROOT|RAW|INCOMING|LLM_LOGS|REVIEW|SYNTH_CANDIDATES|QUERY_REVIEW|WIKI|WIKI_SYNTH|LOGDIR|LINT_LOG|QUERY_LINT_LOG|INDEX_MD|CHANGE_LOG_MD|CLAUDE_MD|AGENTS_DIR|DEV_ROOT|ALLOWED_QUERY_TYPES|INFERENCE_PATTERNS|EVIDENCE_SOURCE_PATTERNS|VAULT_DIRS|LARGE_WIKI_THRESHOLD|_VALID_SEVERITIES|_FAIL_SEVERITIES)\b" scripts/rw_light.py` を実行し、ヒットがすべて `rw_config.X` 形式（先頭が `rw_config.` または `import rw_config` 文）であることを目視確認する。bare 参照が残っている場合は修正
  - 完了状態: `scripts/rw_config.py` が存在し、`scripts/rw_light.py` 内に `UPPER_CASE` グローバル定数の独自定義が残っていない（`grep -nE "^[A-Z_]+ *=" scripts/rw_light.py` でヒット 0 件）、かつ残留関数本体内の bare 定数参照が 0 件。**rw_light 単独で `python scripts/rw_light.py` を起動して NameError なく usage 表示**することを smoke 確認。`pytest tests/` がまだ green でなくてもよい（テスト patch 更新と直接アクセス書き換えは 1.2 で実施）
  - _Requirements: 1.1, 2.1, 2.2, 3.1_

- [x] 1.2 定数 patch 先を `rw_config` に置換 + 直接アクセス書き換え + pytest green 復帰
  - `tests/conftest.py` の `patch_constants` fixture（17 箇所）の `monkeypatch.setattr(rw_light, "ROOT", ...)` 等を `monkeypatch.setattr(rw_config, "ROOT", ...)` 等に更新する。fixture 構造（引数・yield 順序）は変更しない
  - `tests/test_rw_light.py` / `tests/test_audit.py` 内の直接定数パッチ参照（`monkeypatch.setattr(rw_light, "<UPPER_CASE>", ...)` 形式）を `rw_config` 参照に sed/正規表現で一括置換する
  - **直接アクセス書き換え**: `grep -nE "rw_light\.[A-Z_]+\b" tests/` で全件列挙し（**docstring / コメント内の言及は除外**、コード行のみ抽出）、検出された `rw_light.<UPPER_CASE>` を `rw_config.<UPPER_CASE>` に sed で置換する（test_init.py 2, test_conftest_fixtures.py 2, conftest.py fixture body 内 1〔L20 `VAULT_DIRS`〕, test_rw_light.py / test_audit.py 該当分）
  - **import 文追加**: 上記書き換え対象シンボルを持つテストファイルに `import rw_config` を追加（既存の `import rw_light` は残留シンボル参照のため保持）
  - **`from rw_light import <UPPER>` 形式の確認**: `grep -nE "from rw_light import\b" tests/` で残存 import を確認、定数を import している箇所があれば `from rw_config import <UPPER>` に修正
  - `pytest tests/ --collect-only` で import エラー不在を早期確認、その後 `pytest tests/` を実行して 642 件以上 green になることを確認する（Phase 1 完了ゲート）
  - 完了状態: `pytest tests/` が green、`tests/` 配下で `grep -nE "monkeypatch\.setattr\(rw_light,\s*\"[A-Z_]+\"" tests/` ヒット 0 件、かつ `grep -nE "rw_light\.[A-Z_]+\b" tests/` ヒット 0 件
  - _Requirements: 3.2, 5.1, 5.2_

- [ ] 2. Phase 2: `rw_utils` 抽出と utility patch 移行

- [x] 2.1 `rw_utils.py` 作成と汎用ユーティリティ関数の移動
  - `scripts/rw_utils.py` を新規作成し、design.md「File Structure Plan」の rw_utils セクションで列挙された全関数を `rw_light.py` から物理移動する（`today`, `is_valid_iso_date`, `relpath`, `ensure_dirs`, `is_existing_vault`, `read_text`, `write_text`, `append_text`, `read_json`, `safe_read_json`, frontmatter 関数群（`has_frontmatter`, `parse_frontmatter`, `build_frontmatter`, `ensure_basic_frontmatter`, `first_h1`, `infer_source_from_path`, `slugify`）, `list_md_files`, `list_query_dirs`, git 関数群（`git_status_porcelain`, `git_path_is_dirty`, `warn_if_dirty_paths`, `git_commit`, `_git_list_files`）, `_compute_run_status`, `_compute_exit_code`）
  - `rw_utils.py` は `import rw_config` のみを行い、定数参照を `rw_config.X` 形式に統一する（他サブモジュールを import しない — DAG 維持）
  - **Phase 2 時点で rw_light.py 内に存在する全ての関数本体**（最終残留分: cmd_lint / cmd_ingest / cmd_synthesize_logs / cmd_approve / cmd_init / `_backup_timestamp` + Phase 4a 移動予定の cmd_audit_* / check_* / その他 audit 関数群 + Phase 4b 移動予定の cmd_query_* / cmd_lint_query / その他 query 関数群を含む全 44 関数）の上記関数呼び出しをすべて `rw_utils.X(...)` 形式の修飾参照に書き換える（修飾参照規約）。**特に注意**: cmd_init は `is_existing_vault` を bare 呼び出し、cmd_audit_* は `_compute_run_status` / `_compute_exit_code` / `git_path_is_dirty` を bare 呼び出ししている可能性があり、これらが移動後 bare のままだと NameError 発生
  - 既存関数のシグネチャ（引数名・型ヒント・default 値）は厳守する。新規 default 引数を追加する場合は `def f(root=None): root = root or rw_config.WIKI` パターンを用い import 時固定化を回避する
  - **残留関数本体の bare 参照ゼロ検証**: `grep -nE "(^|[^a-zA-Z0-9_.])(today|is_valid_iso_date|relpath|ensure_dirs|is_existing_vault|read_text|write_text|append_text|read_json|safe_read_json|has_frontmatter|parse_frontmatter|build_frontmatter|ensure_basic_frontmatter|first_h1|infer_source_from_path|slugify|list_md_files|list_query_dirs|git_status_porcelain|git_path_is_dirty|warn_if_dirty_paths|git_commit|_git_list_files|_compute_run_status|_compute_exit_code)\(" scripts/rw_light.py` を実行し、ヒットがすべて `rw_utils.X(...)` 形式または関数定義行であることを目視確認する。bare 呼び出しが残っている場合は修正
  - 完了状態: `scripts/rw_utils.py` が存在し、Phase 2 で移動した utility 関数のうち bare 形式（`today(...)` 等）の呼び出しが `rw_light.py` 残留関数本体内に残っていない。**rw_light 単独で `python scripts/rw_light.py` を起動して NameError なく usage 表示**することを smoke 確認。テスト patch 更新と直接アクセス書き換えは 2.2 で実施
  - _Requirements: 1.1, 2.1, 2.2_

- [x] 2.2 utility patch 先を `rw_utils` に置換 + 直接アクセス書き換え + pytest green 復帰
  - `tests/test_approve.py` の `git_path_is_dirty` / `warn_if_dirty_paths` パッチ（~15 箇所）を `rw_utils` 参照に更新
  - `tests/test_ingest.py` の `git_commit` パッチ（15 箇所）を `rw_utils` 参照に更新（`rw_light.shutil.move` パッチは `cmd_ingest` が rw_light 残留のため**更新不要**）
  - `tests/test_synthesize_logs.py` の `git_path_is_dirty` パッチを `rw_utils` 参照に更新（~20 箇所中該当分）
  - `tests/test_rw_light.py` の `today` / `_git_list_files` / `git_commit` / `git_path_is_dirty` / `warn_if_dirty_paths` / `_compute_run_status` / `_compute_exit_code` 等のパッチ参照を `rw_utils` に更新
  - **直接アクセス書き換え**: `grep -nE "rw_light\.(today|is_valid_iso_date|relpath|ensure_dirs|is_existing_vault|read_text|write_text|append_text|read_json|safe_read_json|has_frontmatter|parse_frontmatter|build_frontmatter|ensure_basic_frontmatter|first_h1|infer_source_from_path|slugify|list_md_files|list_query_dirs|git_status_porcelain|git_path_is_dirty|warn_if_dirty_paths|git_commit|_git_list_files|_compute_run_status|_compute_exit_code)\b" tests/` で全件列挙し（**docstring / コメント内の言及は除外**）、`rw_utils.<func>` に sed で置換する（test_utils.py 28, test_git_ops.py 7, test_lint.py 2, test_rw_light.py 該当分, conftest.py fixture body 内 1〔L69 `build_frontmatter`〕）
  - **import 文追加**: 上記書き換え対象を持つテストファイル（test_utils.py / test_git_ops.py / test_lint.py / test_rw_light.py / conftest.py 等）に `import rw_utils` を追加
  - **`from rw_light import` 形式の確認**: `grep -nE "from rw_light import\b" tests/` で utility 関数を直接 import している箇所があれば `from rw_utils import ...` に修正
  - `pytest tests/ --collect-only` で import エラー不在を早期確認、その後 `pytest tests/` を実行して 642 件以上 green になることを確認する（Phase 2 完了ゲート）
  - 完了状態: `pytest tests/` が green、`tests/` 配下で utility 関数が `rw_light` 経由で patch されている grep ヒット 0 件、かつ rw_utils 移動済みシンボルへの `rw_light.<func>` 直接アクセス grep ヒット 0 件
  - _Requirements: 4.4, 4.6, 5.1_

- [ ] 3. Phase 3: `rw_prompt_engine` 抽出（re-export なし — Req 1.3）

- [x] 3.1 `rw_prompt_engine.py` 作成と Claude 関連関数の移動（re-export なし — Req 1.3）
  - `scripts/rw_prompt_engine.py` を新規作成し、design.md「File Structure Plan」の rw_prompt_engine セクションで列挙された全関数を `rw_light.py` から物理移動する（`call_claude`, `call_claude_for_log_synthesis`, `parse_agent_mapping`, `load_task_prompts`, `_validate_agents_severity_vocabulary`, `build_query_prompt`, `read_wiki_content`, `read_all_wiki_content`）
  - `rw_prompt_engine.py` は `import rw_config` および `import rw_utils` のみを行い、定数・ユーティリティ参照を修飾形式に統一する（`rw_audit`, `rw_query`, `rw_light` を import しない — DAG 維持）
  - **Phase 3 時点で rw_light.py 内に存在する全ての関数本体**（最終残留分: cmd_lint / cmd_ingest / cmd_synthesize_logs / cmd_approve / cmd_init / `_backup_timestamp` + **Phase 4a で移動予定の cmd_audit_* / check_* / build_audit_prompt / parse_audit_response / _run_llm_audit / generate_audit_report / print_audit_summary / `_validate_agents_severity_vocabulary` の caller** + **Phase 4b で移動予定の cmd_query_extract / cmd_query_answer / cmd_query_fix / cmd_lint_query**）の上記関数呼び出しをすべて `rw_prompt_engine.X(...)` 形式の修飾参照に書き換える。**特に注意**: (1) rw_light に残留する `cmd_synthesize_logs` は `call_claude_for_log_synthesis` を bare 呼び出し、(2) Phase 4a まで rw_light に残る `cmd_audit_*` は `call_claude` / `load_task_prompts` / `read_all_wiki_content` / `read_wiki_content` / `build_audit_prompt`（後者は同モジュール内なので bare のまま OK、Phase 4a で rw_audit に同居）を bare 呼び出し、(3) Phase 4b まで rw_light に残る `cmd_query_extract/answer/fix` は `build_query_prompt` および `call_claude` を bare 呼び出し。Phase 3 のスコープでは `rw_prompt_engine` 移動シンボルへの bare 参照のみ対象（同モジュール内 bare 呼び出しは Phase 4a/4b の物理移動時に同居解決）
  - **Re-export は一切追加しない**（Req 1.3）。`rw_light.py` 内で `from rw_prompt_engine import ...` 形式の行は追加禁止。rw_light.py には `import rw_prompt_engine` のみを追加し、必要な呼び出しは `rw_prompt_engine.X(...)` 形式で行う
  - timeout 値は呼び出し側コマンドで指定する既存パターン（audit=300s, query=120s）を維持する
  - **残留関数本体の bare 参照ゼロ検証**: `grep -nE "(^|[^a-zA-Z0-9_.])(call_claude|call_claude_for_log_synthesis|parse_agent_mapping|load_task_prompts|_validate_agents_severity_vocabulary|build_query_prompt|read_wiki_content|read_all_wiki_content)\(" scripts/rw_light.py` を実行し、ヒットがすべて `rw_prompt_engine.X(...)` 形式または関数定義行であることを目視確認する
  - 完了状態: `scripts/rw_prompt_engine.py` が存在し、`rw_light.py` には `from rw_prompt_engine import` 文が**一切存在しない**ことを `grep -nE "from rw_prompt_engine import" scripts/rw_light.py` ヒット 0 件で確認。`python -c "import sys; sys.path.insert(0, 'scripts'); import rw_light; hasattr(rw_light, 'call_claude')"` で `False`（`rw_light.call_claude` アクセス不可）を確認。**rw_light 単独で `python scripts/rw_light.py` を起動して NameError なく usage 表示**することを smoke 確認。テスト書き換えは 3.2 で実施
  - _Requirements: 1.1, 1.3, 2.1, 2.2_

- [x] 3.2 prompt engine patch 先を `rw_prompt_engine` に置換 + 直接アクセス全件書き換え + pytest green 復帰
  - `tests/test_rw_light.py` の `call_claude` / `load_task_prompts` / `read_wiki_content` / `read_all_wiki_content` / `build_query_prompt` / `parse_agent_mapping` / `_validate_agents_severity_vocabulary` パッチ参照を `rw_prompt_engine` に更新（`call_claude` 関連シンボル使用回数 ~54 件含む）
  - `tests/test_audit.py` の `read_all_wiki_content` / `read_wiki_content` / `load_task_prompts` / `_validate_agents_severity_vocabulary` パッチ参照を `rw_prompt_engine` に更新
  - `tests/test_synthesize_logs.py` の `call_claude_for_log_synthesis` パッチ参照を `rw_prompt_engine` に更新
  - **直接アクセス書き換え（`call_claude` 含む全 8 シンボル対象、コード行のみ）**: `grep -nE "rw_light\.(call_claude|call_claude_for_log_synthesis|parse_agent_mapping|load_task_prompts|_validate_agents_severity_vocabulary|build_query_prompt|read_wiki_content|read_all_wiki_content)\b" tests/` で全件列挙し、**docstring / コメント言及を除外したコード行のみ**を `rw_prompt_engine.<func>` に sed で置換する（test_audit.py の severity 関連 + load_task_prompts / read_wiki_content / read_all_wiki_content 等、test_rw_light.py 該当分 + `test_rw_light.py` L280/297/314/336/2582/2598/2615/2633/2648/2662 の `rw_light.call_claude` 10 件、`test_conftest_fixtures.py` L107/L119 の `rw_light.call_claude` 2 件の**計 12 件**が call_claude 書き換え対象 — Req 1.3 により再 export ゼロ）。**`conftest.py` L231 は docstring 内例示のため書き換え対象外**（pytest 動作に影響せず、Follow-up Obligation の docs 同期で `docs/developer-guide.md` と合わせて更新）
  - **import 文追加**: 上記書き換え対象を持つテストファイル（test_audit.py / test_rw_light.py / test_synthesize_logs.py / test_conftest_fixtures.py）に `import rw_prompt_engine` を追加（conftest.py はコード行の書き換えが発生しないため追加不要）
  - **`from rw_light import` 形式の確認**: `grep -nE "from rw_light import\b" tests/` で prompt engine 関数を import している箇所があれば `from rw_prompt_engine import ...` に修正
  - `pytest tests/ --collect-only` で import エラー不在を早期確認、その後 `pytest tests/` を実行して 642 件以上 green になることを確認する（Phase 3 完了ゲート）
  - 完了状態: `pytest tests/` が green、`tests/` 配下で `grep -nE "monkeypatch\.setattr\(rw_light,\s*\"(call_claude|load_task_prompts|read_wiki_content|read_all_wiki_content|build_query_prompt|_validate_agents_severity_vocabulary|call_claude_for_log_synthesis|parse_agent_mapping)\"" tests/` ヒット 0 件、かつ `grep -nE "rw_light\.(call_claude|call_claude_for_log_synthesis|parse_agent_mapping|load_task_prompts|_validate_agents_severity_vocabulary|build_query_prompt|read_wiki_content|read_all_wiki_content)\b" tests/` ヒット 0 件（Req 1.3 により `call_claude` も除外なし）
  - _Requirements: 1.3, 4.1, 4.2, 4.5, 5.1_

- [ ] 4. Phase 4a: `rw_audit` 抽出と audit dispatch 切り替え

- [x] 4.1 `rw_audit.py` 作成と audit コマンド / チェック関数群の移動
  - `scripts/rw_audit.py` を新規作成し、design.md「File Structure Plan」の rw_audit セクションで列挙された全シンボルを `rw_light.py` から物理移動する（`Finding` / `WikiPage` NamedTuple、`check_broken_links`, `check_index_registration`, `check_frontmatter`, `check_orphan_pages`, `check_bidirectional_links`, `check_naming_convention`, `check_source_field`, `check_required_sections`, `_resolve_link`, `validate_wiki_dir`, `load_wiki_pages`, `get_recent_wiki_changes`, `_normalize_severity_token`, `_record_drift`, `run_micro_checks`, `run_weekly_checks`, `build_audit_prompt`, `parse_audit_response`, `generate_audit_report`, `print_audit_summary`, `_run_llm_audit`, `cmd_audit`, `cmd_audit_micro`, `cmd_audit_weekly`, `cmd_audit_monthly`, `cmd_audit_quarterly`）
  - `rw_audit.py` は `import rw_config`, `import rw_utils`, `import rw_prompt_engine` のみを行い、すべての参照を修飾形式に統一する（`rw_query`, `rw_light` を import しない — DAG 維持）
  - `rw_light.main()` ディスパッチ層の audit 系呼び出しを `rw_audit.cmd_audit(sys.argv[2:])` 等の修飾参照に書き換える
  - **行数事前試算（リスク緩和）**: 抽出前に予測値を計算する — 既存 audit セクション ~1,470 行 + 必要な import 文（`import rw_config`, `import rw_utils`, `import rw_prompt_engine` で 3 行）+ 修飾参照書き換えで blank 行整理（差し引きほぼ 0）= 約 1,475-1,485 行見積。30 行余裕は楽観的なため、抽出後 `wc -l scripts/rw_audit.py` で実測し、1,500 行を超過した場合は本タスクを中断
  - **完了直後に `wc -l scripts/rw_audit.py` を実行し、行数が 1,500 行以内であることを確認する。1,500 行を超過した場合は本タスクを中断し、フォローアップスペック（`rw_audit_checks.py` 分離）を起票して要件再評価を行う**（Req 1.2、design.md「Rollback Triggers」参照）
  - 完了状態: `scripts/rw_audit.py` が存在し、`wc -l scripts/rw_audit.py` の出力が 1,500 行以内、かつ `python scripts/rw_light.py audit micro` 等の CLI 起動が import エラーなく動作する。テスト patch 更新と直接アクセス書き換えは 4.2 で実施
  - _Requirements: 1.1, 1.2, 2.1, 2.2_

- [x] 4.2 audit 系 patch 先を `rw_audit` に置換 + 直接アクセス書き換え + pytest green 復帰
  - `tests/test_audit.py` の audit コマンド / チェック関数 / severity 関連関数パッチ参照（~57 箇所、severity 関連 17 件含む）を `rw_audit` に更新する。`_normalize_severity_token` / `_record_drift` は `rw_audit` へ、`_validate_agents_severity_vocabulary` は `rw_prompt_engine`（Phase 3 で更新済み）を区別する
  - `tests/test_rw_light.py` の audit 系パッチ参照（`cmd_audit_*`, `check_*`, `_run_llm_audit`, `parse_audit_response`, `build_audit_prompt`, `generate_audit_report`, `_normalize_severity_token`, `_record_drift`, `run_micro_checks`, `run_weekly_checks`, `load_wiki_pages`, `get_recent_wiki_changes`, `validate_wiki_dir`, `_resolve_link` 等）を `rw_audit` に更新する
  - severity 関連内部関数（`_normalize_severity_token`, `_record_drift`）の patch 先が `rw_audit`、`_validate_agents_severity_vocabulary` の patch 先が `rw_prompt_engine`（Phase 3 で更新済み）に区別されていることを最終確認する。これは Req 1.1 が指定する audit 責務帰属に基づくシンボル配置の整合性検証
  - **直接アクセス書き換え**: `grep -nE "rw_light\.(check_broken_links|check_index_registration|check_frontmatter|check_orphan_pages|check_bidirectional_links|check_naming_convention|check_source_field|check_required_sections|_resolve_link|validate_wiki_dir|load_wiki_pages|get_recent_wiki_changes|_normalize_severity_token|_record_drift|run_micro_checks|run_weekly_checks|build_audit_prompt|parse_audit_response|generate_audit_report|print_audit_summary|_run_llm_audit|cmd_audit|cmd_audit_micro|cmd_audit_weekly|cmd_audit_monthly|cmd_audit_quarterly|Finding|WikiPage)\b" tests/` で全件列挙し、`rw_audit.<symbol>` に sed で置換する（test_audit.py の audit 関数 + severity 関連 17 件、test_rw_light.py 該当 ~50-100 件）
  - **import 文追加**: 上記書き換え対象を持つテストファイル（test_audit.py / test_rw_light.py）に `import rw_audit` を追加
  - **`from rw_light import` 形式の確認**: `grep -nE "from rw_light import\b" tests/` で audit 関数を import している箇所があれば `from rw_audit import ...` に修正
  - `pytest tests/ --collect-only` で import エラー不在を早期確認、その後 `pytest tests/` を実行して 642 件以上 green になることを確認する（Phase 4a 完了ゲート）
  - 完了状態: `pytest tests/` が green、`tests/` 配下で audit 系シンボルが `rw_light` 経由で patch されている grep ヒット 0 件、かつ rw_audit 移動済みシンボルへの `rw_light.<symbol>` 直接アクセス grep ヒット 0 件
  - _Requirements: 1.1, 5.1_

- [ ] 5. Phase 4b: `rw_query` 抽出と query dispatch 切り替え

- [x] 5.1 `rw_query.py` 作成と query コマンド / query lint 関数群の移動
  - `scripts/rw_query.py` を新規作成し、design.md「File Structure Plan」の rw_query セクションで列挙された全関数を `rw_light.py` から物理移動する（`generate_query_id`, `write_query_artifacts`, `parse_extract_response`, `parse_fix_response`, `_strip_code_block`, `count_evidence_blocks`, `contains_markdown_structure`, `has_query_text`, `extract_query_type`, `extract_scope`, `has_evidence_source`, `contains_inference_language`, `lint_single_query_dir`, `print_query_lint_text`, `cmd_query_extract`, `cmd_query_answer`, `cmd_query_fix`, `cmd_lint_query`）
  - `rw_query.py` は `import rw_config`, `import rw_utils`, `import rw_prompt_engine` のみを行い、すべての参照を修飾形式に統一する（`rw_audit`, `rw_light` を import しない — DAG 維持）
  - `cmd_query_fix` 内では `rw_query.lint_single_query_dir(...)` と自モジュール内でも修飾参照する（Req 4.3 の monkeypatch を有効化するため）
  - `rw_light.main()` ディスパッチ層の query / lint-query 系呼び出しを `rw_query.cmd_query_*(...)`, `rw_query.cmd_lint_query(...)` の修飾参照に書き換える
  - 完了状態: `scripts/rw_query.py` が存在し、`python scripts/rw_light.py query extract <dummy_args>` 相当の CLI 起動が import エラーなく動作する（実行は引数不足で異常終了してよい — import 解決のみが検証対象）。テスト patch 更新と直接アクセス書き換えは 5.2 で実施
  - _Requirements: 1.1, 2.1, 2.2_

- [x] 5.2 query 系 patch 先を `rw_query` に置換 + 直接アクセス書き換え + pytest green 復帰
  - `tests/test_rw_light.py` の `lint_single_query_dir` および `cmd_query_extract` / `cmd_query_answer` / `cmd_query_fix` の patch 参照を `rw_query` に更新する。さらに query lint 検査関数（`count_evidence_blocks`, `has_evidence_source`, `extract_query_type` 等）の patch 参照があれば `rw_query` に更新する
  - `tests/test_lint_query.py` で `rw_light` 経由の patch 参照があれば `rw_query` に更新する（`conftest.py` 経由のみで関与する場合は更新不要）
  - **直接アクセス書き換え**: `grep -nE "rw_light\.(generate_query_id|write_query_artifacts|parse_extract_response|parse_fix_response|_strip_code_block|count_evidence_blocks|contains_markdown_structure|has_query_text|extract_query_type|extract_scope|has_evidence_source|contains_inference_language|lint_single_query_dir|print_query_lint_text|cmd_query_extract|cmd_query_answer|cmd_query_fix|cmd_lint_query)\b" tests/` で全件列挙し、`rw_query.<symbol>` に sed で置換する（test_lint_query.py 22 件、test_rw_light.py 該当分）
  - **import 文追加**: 上記書き換え対象を持つテストファイル（test_lint_query.py / test_rw_light.py）に `import rw_query` を追加
  - **`from rw_light import` 形式の確認**: `grep -nE "from rw_light import\b" tests/` で query 関数を import している箇所があれば `from rw_query import ...` に修正
  - `pytest tests/ --collect-only` で import エラー不在を早期確認、その後 `pytest tests/` を実行して 642 件以上 green になることを確認する（Phase 4b 完了ゲート）
  - 完了状態: `pytest tests/` が green、`tests/` 配下で query 系シンボルが `rw_light` 経由で patch されている grep ヒット 0 件、かつ rw_query 移動済みシンボルへの `rw_light.<symbol>` 直接アクセス grep ヒット 0 件
  - _Requirements: 4.3, 5.1_

- [ ] 6. Phase 5: `rw_light` 最終スリム化と全体検証

- [x] 6.1 `rw_light.py` の最終スリム化と残留参照・re-export 不在検査
  - `rw_light.py` の残存内容を確認し、design.md「Modified Files」セクションが指定する保持関数のみが残っていることを確認する（`cmd_lint`, `cmd_ingest` + `plan_ingest_moves` + `execute_ingest_moves` + `load_lint_summary`, `cmd_synthesize_logs` + `parse_topics` + `render_candidate_note` + `candidate_note_path`, `cmd_approve` + `candidate_files` + `approved_candidate_files` + `synthesis_target_path` + `merge_synthesis` + `promote_candidate` + `mark_candidate_promoted` + `update_index_synthesis` + `append_approval_log`, `cmd_init` + `_backup_timestamp`, `print_usage`, `main`, `if __name__ == "__main__"` ブロック）
  - サブモジュール import 文（`import rw_config`, `import rw_utils`, `import rw_prompt_engine`, `import rw_audit`, `import rw_query`）のみが存在し、**`from rw_<module> import ...` 形式の re-export 文が一切存在しない**ことを `grep -nE "^from rw_(config|utils|prompt_engine|audit|query) import" scripts/rw_light.py` ヒット 0 件で最終確認する（Req 1.3）
  - **残留関数本体（cmd_lint / cmd_ingest / cmd_synthesize_logs / cmd_approve / cmd_init / `_backup_timestamp`）内の参照を grep で検査し、移動済みシンボル（`UPPER_CASE` 定数、utility 関数、prompt engine 関数、audit 関数、query 関数）が bare 形式で残っていないことを確認する**（残っていれば `rw_<module>.X` 修飾参照に修正）
  - **テスト直接アクセス完全性検証**: `grep -nE "rw_light\.[a-z_][a-zA-Z0-9_]*" tests/` で全テストの lower-case 直接アクセスを列挙し、移動済みシンボルへの直接アクセスが一切残っていないことを確認する（`call_claude` 除外なし — Req 1.3 により全シンボルが書き換え対象）。`grep -nE "rw_light\.[A-Z_]+\b" tests/` で UPPER_CASE 定数への直接アクセスも残っていないことを確認する（残存ヒットは Phase X.2 の漏れを示す。docstring / コメント言及のみ許容）
  - `main()` 内の argparse dispatch テーブルが Phase 4a/4b で書き換えられた修飾参照（`rw_audit.cmd_audit`, `rw_query.cmd_query_*`, `rw_query.cmd_lint_query` 等）を正しく呼び出すことを確認する
  - `wc -l scripts/rw_light.py scripts/rw_config.py scripts/rw_utils.py scripts/rw_prompt_engine.py scripts/rw_audit.py scripts/rw_query.py` を実行し、すべて 1,500 行以内であることを確認する（Req 1.2）。`rw_light.py` は ~700 行見積（re-export ゼロ方針）
  - 完了状態: `scripts/rw_light.py` の行数が ~700 行程度に縮小、かつ全 6 モジュールが 1,500 行以内、残留関数本体に bare 移動済みシンボル参照が残っていない、テストにコード行として `rw_light.<移動済みシンボル>` の直接アクセス grep ヒット 0 件、rw_light.py 内に re-export 文ゼロ
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 6.1_

- [ ] 6.2 全テスト green、CLI usage 表示、circular import 不在の最終検証
  - `pytest tests/` を実行し、642 件以上が pass、failure 0、skip / xfail が分割前と同等以下であることを確認する（Req 5.1）
  - `python scripts/rw_light.py` を引数なしで実行し、分割前と同一の usage テキストが表示されることを確認する（Req 6.2）
  - `python scripts/rw_light.py audit micro --help` 等の代表的なサブコマンド起動でも import エラーが発生しないことを確認する
  - **全モジュール一括 import 検証**（circular import / 部分初期化検出）: `cd scripts && python -c "import rw_config, rw_utils, rw_prompt_engine, rw_audit, rw_query, rw_light; print('ALL OK')"` が成功することを確認する（design.md「Rollback Triggers」の Phase 5 後 circular import 検出 trigger に対応）
  - 各サブモジュールが個別に import できることを確認する（`cd scripts && python -c "import rw_config" && python -c "import rw_utils" && python -c "import rw_prompt_engine" && python -c "import rw_audit" && python -c "import rw_query"` がすべて成功）（Req 5.2）
  - 完了状態: `pytest tests/ -v | tail -5` で 642 件以上 pass、`python scripts/rw_light.py` で usage 表示、6 モジュール一括 import / 個別 import がすべて成功（circular import なし）
  - _Requirements: 5.1, 5.2, 6.1, 6.2_

- [ ] 6.3 Vault symlink 経由起動の手動 smoke 検証
  - 一時ディレクトリ（例: `/tmp/rwiki-smoke-vault-<timestamp>`）を新規作成し、`python scripts/rw_light.py init /tmp/rwiki-smoke-vault-<timestamp>` で Vault 初期化を行う（既存の `cmd_init` ロジックで `rw` symlink が配置される）
  - 配置された symlink から `python /tmp/rwiki-smoke-vault-<timestamp>/rw` を引数なしで起動し、usage テキストが表示されること（= `import rw_config` 等のサブモジュール import が `sys.path` 自動解決で成功）を確認する（Req 6.3）
  - 検証結果（実行コマンド + 出力 + 成功/失敗判定）を本タスクの完了報告に記録する
  - 完了状態: 一時 Vault からの symlink 起動で usage 表示が確認され、コマンド出力が完了報告に記録されている
  - _Requirements: 6.3_

## Implementation Notes

- Phase 3.1 で rw_prompt_engine に移動した read_wiki_content / read_all_wiki_content の "# audit: data loading" 位置検証テスト `test_audit_headers_before_output_utilities` は output utilities が rw_light に残るため cross-module 順序検証として意味を失う。Phase 6.1 の rw_light 最終スリム化完了後に re-author を検討する。
- Phase 4.1 時点で `_strip_code_block` を rw_audit と rw_query の両方が必要とするが DAG 上 Layer 3 相互 import 不可のため、rw_audit.py に 11 行のローカル duplicate を置く実装判断をした。Phase 5.1 (rw_query 抽出) では同関数を rw_query に再配置し、duplicate 状態を容認する（Req 2.2 DAG 維持のための pragmatic trade-off）。将来的な重複解消は rw_prompt_engine または rw_utils への移動として follow-up スペックで検討可能。
- Phase 4.2 での必須修正: `tests/test_rw_light.py:5116` の型アノテーション `def _finding(self, sev: str) -> rw_light.Finding:` は Python 3.10 で関数定義時に評価されるため、Phase 4.1 直後は `pytest tests/ --collect-only` で AttributeError 発生。Phase 4.2 で `rw_audit.Finding` に更新することで解消。
