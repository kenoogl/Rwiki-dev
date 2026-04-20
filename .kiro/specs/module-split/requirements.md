# Requirements Document

## Introduction
`scripts/rw_light.py`（約 3,830 行）は単一ファイルに全コマンドと補助関数が集約されており、ファイルサイズが保守限界（3,000 行目安）を超過している。本スペックは開発者・メンテナーが対象のリファクタリングであり、ファイルを責務別モジュールに分割して長期保守性を向上させる。CLI の外部動作・テスト結果・公開 API はすべて現状と同一に保つ。

## Boundary Context
- **In scope**: `scripts/` 配下のコード分割、テストの monkeypatch パッチ先更新、モジュール間インポート整理
- **Out of scope**: コマンドの動作変更、新機能追加、テストロジックの変更（パッチ対象の更新のみ許可）、`rw_light` の外部 API シグネチャ変更
- **Adjacent expectations**: テストファイル（12 件 — `import rw_light` を使用する全ファイル: conftest.py / test_rw_light.py / test_audit.py / test_approve.py / test_ingest.py / test_synthesize_logs.py / test_utils.py / test_git_ops.py / test_lint.py / test_lint_query.py / test_init.py / test_conftest_fixtures.py）は `import rw_light` を継続使用できる。CLI エントリポイント（`rw_light.py` の `main()`）は分割後も同一パスに存在すること

## Requirements

### Requirement 1: モジュール責務分割
**Objective:** As a 開発者, I want `rw_light.py` を責務単位のモジュールに分割したい, so that 各モジュールが単一責務を持ち、変更範囲が限定される。

#### Acceptance Criteria
1. The module split shall produce 以下 6 モジュール: `rw_config.py`（パス定数・全グローバル定数）、`rw_utils.py`（ユーティリティ関数: `today`・`git_path_is_dirty`・`_git_list_files`・frontmatter 操作・ファイル I/O・git 操作 等）、`rw_prompt_engine.py`（プロンプトエンジン + Claude 呼び出し）、`rw_audit.py`（監査コマンド + チェック関数）、`rw_query.py`（クエリコマンド + クエリ lint）、`rw_light.py`（`cmd_lint`・`cmd_ingest`・`cmd_synthesize_logs`・`cmd_approve`・`cmd_init` の実装 + `main()` + ディスパッチ）。Req 4 で明示された関数のホスト先を正とし、設計フェーズでの独自解釈による配置変更を禁止する。
2. The module split shall ensure 分割後の各モジュールが 1,500 行以内であること（`rw_light.py` 含む）。
3. The module split shall not provide 移動したシンボルへの `rw_light.<symbol>` 形式の後方互換 re-export を提供してはならない。テスト・ドキュメント・（将来の）外部コードは `rw_<module>.<symbol>` 形式で直接参照することを要求する（fundamental review + AC 1.3 再評価で外部運用スクリプトの実在が確認できなかったため、re-export は構造的負債として排除）。

### Requirement 2: 循環インポート禁止
**Objective:** As a 開発者, I want モジュール間の依存グラフが非循環である, so that インポートエラーや初期化順序の問題が発生しない。

#### Acceptance Criteria
1. The module dependency graph shall be acyclic（DAG）。
2. When any submodule (`rw_config`, `rw_utils`, `rw_prompt_engine`, `rw_audit`, `rw_query`) is imported in isolation, the submodule shall not import `rw_light` as a dependency。

### Requirement 3: グローバル定数の一元管理とパッチ互換性
**Objective:** As a テスト作成者, I want パス定数・ドメイン定数を単一モジュールでパッチできる, so that テストの fixture セットアップが一貫して動作する。

#### Acceptance Criteria
1. The rw_config.py shall パス定数（`ROOT`, `WIKI`, `LOGDIR`, `LINT_LOG`, `QUERY_LINT_LOG`, `INDEX_MD`, `AGENTS_DIR` 等）およびドメイン定数（`ALLOWED_QUERY_TYPES`, `INFERENCE_PATTERNS`, `VAULT_DIRS` 等）を含む全グローバル定数を一元管理すること。
2. When a path constant is patched on `rw_config`（`monkeypatch.setattr(rw_config, "ROOT", ...)`）, the refactored codebase shall ensure 全サブモジュール内のコマンド実装がパッチ後の値を参照すること。

### Requirement 4: 関数パッチ先の正確性
**Objective:** As a テスト作成者, I want モック対象関数を定義モジュールでパッチできる, so that モックが実際の呼び出し経路に確実に作用する。

#### Acceptance Criteria
1. When `call_claude` is patched on `rw_prompt_engine`, the refactored codebase shall ensure `cmd_query_extract`・`cmd_query_answer`・`cmd_query_fix`・`cmd_audit_*` の全呼び出しがモック実装を使用すること。
2. When `load_task_prompts` is patched on `rw_prompt_engine`, the refactored codebase shall ensure `load_task_prompts` を内部的に呼び出す全コマンドがモック実装を使用すること。
3. When `lint_single_query_dir` is patched on `rw_query`, the refactored codebase shall ensure `cmd_query_fix` の呼び出しがモック実装を使用すること。
4. When `today` is patched on `rw_utils`, the refactored codebase shall ensure `today` を内部的に呼び出す全コマンドがモック実装を使用すること。
5. When `read_all_wiki_content` is patched on the module that defines it, the refactored codebase shall ensure `cmd_audit_*` の呼び出しがモック実装を使用すること。この関数の帰属モジュールは設計フェーズで確定する。
6. When `git_path_is_dirty` or `_git_list_files` is patched on `rw_utils`, the refactored codebase shall ensure 各呼び出し元コマンドがモック実装を使用すること。

### Requirement 5: 全テスト継続グリーン
**Objective:** As a 開発者, I want リファクタリング後も全テストがグリーンである, so that 動作が変わっていないことを確認できる。

#### Acceptance Criteria
1. When the full test suite is run after the split (`pytest tests/`), the refactored codebase shall pass 分割前と同件数以上のテスト（642 件以上）。
2. The module split shall ensure テスト実行環境において `import rw_config`・`import rw_prompt_engine`・`import rw_query` 等のサブモジュールが `PYTHONPATH` の追加設定なしにインポートできること。

### Requirement 6: CLI エントリポイント互換性
**Objective:** As a オペレーター, I want `python scripts/rw_light.py <command>` および `rw` シンボリックリンク経由の実行が分割後も同一動作をする, so that 運用スクリプトや Vault セットアップが壊れない。

#### Acceptance Criteria
1. The rw_light.py shall 実行可能ファイルとして `scripts/rw_light.py` が存在し続けること。
2. If `rw_light.py` is invoked without arguments, the rw_light.py shall 分割前と同一の usage テキストを表示すること。
3. When `rw_light.py` is executed via a symbolic link placed in a directory other than `scripts/`（Vault デプロイ環境）, the rw_light.py shall サブモジュール（`rw_config`, `rw_utils` 等）を発見・インポートできること（`PYTHONPATH` の手動設定を不要とする）。この AC は自動テスト対象外であり、`rw init` 後に symlink を作成して `python rw <command>` が正常起動することで手動検証する。
