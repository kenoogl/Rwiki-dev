# Research & Design Decisions — module-split

---
**Purpose**: `scripts/rw_light.py`（3,827 行）を 6 モジュールへ分割する設計の根拠・調査結果・意思決定を記録する。
---

## Summary

- **Feature**: `module-split`
- **Discovery Scope**: Extension（既存 CLI のリファクタリング、外部動作・API は不変）
- **Key Findings**:
  - 現行 `rw_light.py` は 3,827 行、関数 83+ / 定数 20+ を含むモノリス。6 モジュールに分割しても各モジュールは 1,500 行制限内に収まる見込み（最大 `rw_audit` で ~950 行）。
  - Python の symlink 実行時 `sys.path[0]` 自動解決により、Vault デプロイ環境でもサブモジュール（`rw_config.py` 等）は追加 PYTHONPATH 設定なしに import 可能。`scripts/__init__.py` も不要。
  - 既存テストの `monkeypatch.setattr(rw_light, "XXX", ...)` 箇所は 約 461 件。うち最多は パス定数（~252 件）と `call_claude`/`load_task_prompts`（~106 件）。`tests/conftest.py` の `patch_constants` フィクスチャ経由で多くは一括更新可能。

## Research Log

### 現行 `rw_light.py` の関数/定数インベントリ

- **Context**: 6 モジュールへ振り分けるための起点として、各関数の責務・行番号・呼び出し関係を網羅。
- **Sources Consulted**:
  - `scripts/rw_light.py` 全体（L1–L3827）
  - Req 4 の関数帰属指定（AC1–AC6）
- **Findings**:
  - グローバル定数は 3 カテゴリに整理できる:
    - **パス定数**（L13–33, L83）: `ROOT`, `RAW`, `INCOMING`, `LLM_LOGS`, `REVIEW`, `SYNTH_CANDIDATES`, `QUERY_REVIEW`, `WIKI`, `WIKI_SYNTH`, `LOGDIR`, `LINT_LOG`, `QUERY_LINT_LOG`, `INDEX_MD`, `CHANGE_LOG_MD`, `CLAUDE_MD`, `AGENTS_DIR`, `DEV_ROOT`
    - **ドメイン定数**（L35–81, L1104, L1721–1722）: `ALLOWED_QUERY_TYPES`, `INFERENCE_PATTERNS`, `EVIDENCE_SOURCE_PATTERNS`, `VAULT_DIRS`, `LARGE_WIKI_THRESHOLD`, `_VALID_SEVERITIES`, `_FAIL_SEVERITIES`
    - これらすべてを `rw_config.py` に集約することで Req 3 AC1 を満たす。
  - 関数の帰属先は Req 4 のホスト指定を正として以下に分類:
    - `rw_utils`: `today`, `git_path_is_dirty`, `_git_list_files`, `git_commit`, `warn_if_dirty_paths`, frontmatter 関数群, ファイル I/O 群, `_compute_run_status`, `_compute_exit_code` など
    - `rw_prompt_engine`: `call_claude`, `load_task_prompts`, `parse_agent_mapping`, `build_query_prompt`, `read_wiki_content`, `read_all_wiki_content`, `call_claude_for_log_synthesis`
    - `rw_audit`: `cmd_audit_micro/weekly/monthly/quarterly`, `check_*`, `run_*_checks`, `build_audit_prompt`, `parse_audit_response`, `generate_audit_report`, `_run_llm_audit`
    - `rw_query`: `cmd_query_extract/answer/fix`, `cmd_lint_query`, `lint_single_query_dir`, `generate_query_id`, `write_query_artifacts`, `parse_extract_response`, `parse_fix_response`, query 検査関数群
    - `rw_light`（残置）: `cmd_lint`, `cmd_ingest`, `cmd_synthesize_logs`, `cmd_approve`, `cmd_init`, `plan_ingest_moves`, `execute_ingest_moves`, `promote_candidate`, `merge_synthesis` など + `main()` + `print_usage()`
- **Implications**:
  - 6 モジュールで合計 2,300–2,700 行程度。各モジュール 1,500 行以内を厳守可能（Req 1 AC2）。
  - `call_claude_for_log_synthesis`（L452）は `cmd_synthesize_logs` 内部ヘルパーだが、Claude 呼び出しラッパーという性質上 `rw_prompt_engine` に帰属させるのが自然。Req 4 には明示ないが、`rw_light` から利用可能にするため再 import する必要はある。

### 既存テストの `monkeypatch` 使用パターン

- **Context**: Req 4（パッチ先正確性）を満たすには、どのテスト・どの件数を更新するかを把握する必要がある。
- **Sources Consulted**:
  - `tests/conftest.py`, `tests/test_rw_light.py`（6,827 行）、`tests/test_audit.py`, `tests/test_approve.py`, `tests/test_synthesize_logs.py`, `tests/test_ingest.py` 他
- **Findings**:
  - 総テスト関数 642 件。すべて `import rw_light` を使用し、`from rw_light import X` 形式は未使用。
  - `monkeypatch.setattr(rw_light, ...)` は合計 461 件前後:
    - パス定数（`ROOT`, `WIKI`, `LOGDIR`, `INDEX_MD`, `CHANGE_LOG_MD`, `CLAUDE_MD`, `AGENTS_DIR`, `QUERY_REVIEW`, `QUERY_LINT_LOG`, `DEV_ROOT`, `RAW`, `REVIEW`）: 約 252 件 → `rw_config`
    - LLM 関連（`call_claude`, `load_task_prompts`, `call_claude_for_log_synthesis`）: 約 112 件 → `rw_prompt_engine`
    - ユーティリティ（`today`, `git_path_is_dirty`, `_git_list_files`, `git_commit`, `warn_if_dirty_paths`）: 約 80 件 → `rw_utils`
    - クエリ関連（`lint_single_query_dir`, `cmd_query_extract/answer/fix`）: 約 17 件 → `rw_query`
    - `read_all_wiki_content`: 24 件、`read_wiki_content`: 3 件 → `rw_prompt_engine`（後述の設計判断）
  - `tests/conftest.py` の `patch_constants` フィクスチャは 17 のパス定数を一括モックしており、このフィクスチャ単体を修正するだけで広範囲のテストが追随する。
- **Implications**:
  - 機械的な文字列置換で大半を更新可能（`rw_light.ROOT` → `rw_config.ROOT` 等）。
  - `conftest.py` を最初に更新することで、多くのテストが自動追随する。

### Symlink デプロイと Python import 解決

- **Context**: Req 6 AC3（Vault symlink 経由実行時にサブモジュール発見可能）を満たす仕組みの検証。
- **Sources Consulted**:
  - `scripts/rw_light.py` の `cmd_init`（L3542–3754）
  - Python 公式ドキュメント（`sys.path` 初期化）
  - `tests/conftest.py` の sys.path 操作
- **Findings**:
  - `cmd_init` は `{vault}/scripts/rw` → `{DEV_ROOT}/scripts/rw_light.py` の絶対パス symlink を作成する。
  - Python は symlink 経由で実行されたスクリプトについて、`__file__` を **symlink の実ターゲット** に解決し、`sys.path[0]` を **実ターゲットの親ディレクトリ** に設定する（Python 3.10+）。
  - したがって `python /vault/scripts/rw <command>` と実行すると `sys.path[0] == /Users/.../Rwiki-dev/scripts`、`import rw_config` は `/Users/.../Rwiki-dev/scripts/rw_config.py` を自動発見する。
  - `scripts/__init__.py` を追加する必要はなく、既存の「直接実行スクリプト + 兄弟モジュール」構成で十分。
- **Implications**:
  - Req 6 AC3 は Python 標準動作で自動的に満たされる。`rw_light.py` 側で `sys.path` 操作を追加する必要はない。
  - テスト環境（Req 5 AC2）は `tests/conftest.py` の既存 `sys.path.insert(0, "scripts")` 行で同様に解決される。

### Python バインディングの罠（constants と patched functions）

- **Context**: Req 3 AC2 と Req 4 の全 AC は「パッチが実装呼び出し経路に作用すること」を要求する。Python の import バインディング規則により、`from X import Y` を使うと monkeypatch が期待通りに動作しない場合がある。
- **Sources Consulted**:
  - Python Language Reference §7.11 (The import statement)
  - pytest monkeypatch ドキュメント
- **Findings**:
  - `from rw_config import ROOT` は import 時に `ROOT` を importing モジュールの名前空間にコピーする。後の `monkeypatch.setattr(rw_config, "ROOT", new_val)` は `rw_config.ROOT` を差し替えるが、importing モジュール側のローカル `ROOT` には反映されない。
  - `import rw_config` + `rw_config.ROOT` パターンはアクセス時に毎回 attribute lookup するため、patch が即時反映される。
- **Implications**:
  - **パッチ対象シンボル（Req 4 指定の関数 + 全 `rw_config` 定数）はすべて `<module>.<symbol>` 形式で参照する**こと。ショートカット `from rw_X import foo` は禁止。
  - これは Req 3 AC2 と Req 4 AC1–AC6 を実装レベルで保証するための必須制約。

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| 単一ファイル継続 | 現状維持 | 変更コスト 0 | Req 違反、保守性低下の継続 | 対象外 |
| **機能別 6 モジュール分割**（採用） | Req 1 指定の 6 モジュール構成 | 責務明確、1,500 行以内、DAG 維持可能 | テストの patch 先更新コスト（~461 件）、機械的更新可能 | Req 準拠 |
| パッケージ化（`scripts/rw/__init__.py`） | サブパッケージとして構成 | import 名空間が明確 | symlink デプロイの import 解決ロジック変更必要、Req スコープ外 | 過剰設計 |

**採用理由**: Req 1 で 6 モジュール構成が指定されており、Python の直接実行スクリプト + 兄弟モジュール構成でフラットに分割することで、symlink デプロイも追加設定なしで動作する。パッケージ化はスコープ外の変更を伴うため不採用。

## Design Decisions

### Decision: `read_all_wiki_content` / `read_wiki_content` / `call_claude_for_log_synthesis` の帰属先

- **Context**: Req 4 AC5 は `read_all_wiki_content` の帰属先を設計フェーズで確定する旨を指定。類似の `read_wiki_content`（スコープ指定版）および `call_claude_for_log_synthesis` も同様の判断が必要。
- **Alternatives Considered**:
  1. `rw_utils`（ファイル I/O ユーティリティとして）
  2. `rw_audit`（主に audit コマンドから使われているため）
  3. **`rw_prompt_engine`**（LLM プロンプト入力データ準備として）
- **Selected Approach**: **`rw_prompt_engine` に配置する**
- **Rationale**:
  - `read_all_wiki_content` と `read_wiki_content` は Wiki 全文/スコープ分を結合して LLM 入力用のコンテキスト文字列を生成する専用関数。汎用 I/O ではなく LLM プロンプト構築の一部。
  - `build_audit_prompt`・`build_query_prompt` と同じ「プロンプト入力準備」レイヤに位置する。
  - `call_claude_for_log_synthesis` は `synthesize-logs` コマンド専用の Claude 呼び出しラッパー。Claude 呼び出しロジックは `rw_prompt_engine` に一元化する方が責務が明確。
  - audit/query 以外に再利用の可能性があり、`rw_audit` 固有にすると `rw_query` から参照しにくい。
- **Trade-offs**:
  - `rw_prompt_engine` が LLM 呼び出し + プロンプトビルダ + 入力データリーダを兼ねることになる（責務がやや広め）。ただし全て「Claude に送る材料を準備する」という一貫性がある。
  - `rw_utils` 側はドメイン非依存の汎用 I/O に留まり、境界がきれいに保たれる。
- **Follow-up**: 実装時、`rw_prompt_engine` の行数を監視し、1,500 行に近づく場合は分割再検討。現状見積 300–400 行で十分余裕あり。

### Decision: グローバル定数・パッチ対象関数のアクセス規約

- **Context**: Req 3 AC2 と Req 4 全 AC は patch 即時反映を要求。Python の import バインディング規則で挙動が変わる。
- **Alternatives Considered**:
  1. `from rw_config import ROOT` で個別 import（短い記述）
  2. **`import rw_config` + `rw_config.ROOT` で module-qualified 参照**
- **Selected Approach**: **モジュール修飾参照を全面採用**
- **Rationale**:
  - `<module>.<symbol>` は毎回 attribute lookup を行い、`monkeypatch.setattr(module, symbol, new)` の効果を即時反映する。
  - `from X import Y` は importing モジュールにローカルバインディングを作り、後続の patch を拾わない → Req 3 AC2 / Req 4 違反のリスク。
  - テスト側も現在すでに `rw_light.ROOT` / `rw_light.call_claude` 形式でアクセスしている。分割後 `rw_config.ROOT` / `rw_prompt_engine.call_claude` への置換が機械的に可能。
- **Trade-offs**: 記述量がわずかに増える。可読性には影響軽微。
- **Follow-up**: 実装時、各サブモジュールの import セクションを lint 的に検証（`from rw_config import` / `from rw_utils import` / `from rw_prompt_engine import` / `from rw_query import` / `from rw_audit import` が存在しないことを確認）。

### Decision: `rw_light.call_claude` 等の後方互換アクセス

- **Context**: Req 1 AC3 は「外部運用スクリプトが `rw_light.call_claude(prompt)` を直接呼ぶ場合、継続アクセスできること」を要求。
- **Alternatives Considered**:
  1. `rw_light.py` 内で `from rw_prompt_engine import call_claude` として再 export
  2. `rw_light` に deprecation warning 付きのプロキシ関数を作る
- **Selected Approach**: **選択肢 1（再 export）**
- **Rationale**:
  - 最小変更で後方互換を維持。外部スクリプトは `rw_light.call_claude(prompt)` で引き続きアクセス可能。
  - テストは Req 4 AC1 に従い `rw_prompt_engine.call_claude` を patch する（`rw_light.call_claude` の patch は不要）。
  - プロキシ関数や deprecation warning はスコープ外（Req で要求されていない）。
- **Trade-offs**: `rw_light` に import 文が追加される。循環依存リスクなし（`rw_prompt_engine` は `rw_light` を import しない）。
- **Follow-up**: 他の外部公開シンボル（`today`, `git_path_is_dirty` 等）の扱いは、運用スクリプトからの利用実績が不明なため、デフォルトでは再 export せず、必要が発覚した時点で追加する方針。

### Decision: 依存方向性（DAG）

- **Context**: Req 2 は DAG と `rw_light` を import しないサブモジュールを要求。
- **Selected Approach**: 以下の階層を enforce する:
  ```
  rw_config  (最下層、他の submodule を import しない)
     ↓
  rw_utils   (rw_config のみに依存)
     ↓
  rw_prompt_engine  (rw_config, rw_utils に依存)
     ↓
  rw_audit, rw_query  (rw_config, rw_utils, rw_prompt_engine に依存)
     ↓
  rw_light   (上記 5 モジュールすべてに依存、全体のディスパッチャ)
  ```
- **Rationale**:
  - 単調に下から上へ依存が流れる。循環なし。
  - `rw_audit` と `rw_query` は相互依存なし（並列）。
  - `rw_light` のみが全体を集約し、CLI エントリポイントとして機能する。
- **Trade-offs**: なし。要件準拠の最小構成。

## Risks & Mitigations

- **Risk 1**: Python バインディング規則の誤解による patch 失敗
  - **Mitigation**: `from X import Y` 禁止を実装レビュー時にチェック。該当行があれば reject。
- **Risk 2**: テスト更新漏れで 642 件中の一部が fail
  - **Mitigation**: `tests/conftest.py` の `patch_constants` から着手し、他のテストは grep ベースで `rw_light.XXX` → `<new_module>.XXX` を機械的に置換。全テスト実行で検証。
- **Risk 3**: symlink デプロイ時の `PYTHONPATH` 問題
  - **Mitigation**: Python 標準の `sys.path` 自動解決に依存。Req 6 AC3 の手動検証（`rw init` 後に `python rw <command>` が起動すること）を実装完了後に実施。
- **Risk 4**: `cmd_init` が `rw_light.py` 本体の絶対パスに依存（`DEV_ROOT`）しており、分割後も同じロジックで動くか不明確
  - **Mitigation**: `cmd_init` は `rw_light.py` 内に残す（Req 1 指定）。`DEV_ROOT` は `rw_config` に配置され、`rw_light.py` の `__file__` から導出する既存ロジックを保持。

## References

- [Python Language Reference — The import system](https://docs.python.org/3/reference/import.html) — submodule 発見ルールの根拠
- [pytest monkeypatch documentation](https://docs.pytest.org/en/stable/how-to/monkeypatch.html) — setattr のスコープ仕様
- `.kiro/steering/tech.md` — 外部依存なし、pytest、型ヒント必須等の制約根拠
- `.kiro/steering/structure.md` — CLI ツールの責務分離パターン
