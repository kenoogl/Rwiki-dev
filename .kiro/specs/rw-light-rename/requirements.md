# Requirements Document

## Introduction
`scripts/rw_light.py` は module-split 完了により実態として CLI エントリポイント + argparse dispatcher + 残留コマンド (`cmd_lint` / `cmd_ingest` / `cmd_synthesize_logs` / `cmd_approve` / `cmd_init`) のホストとなったが、ファイル名の `light` 接頭辞は pre-split 時代の「軽量単一ファイル CLI」を示すものであり現在の責務と意味的に乖離している。本スペックは開発者・メンテナーが対象の命名整合リファクタリングであり、`scripts/rw_light.py` を `scripts/rw_cli.py` にリネームして責務別 6 モジュール構成の他 5 モジュール (`rw_config` / `rw_utils` / `rw_prompt_engine` / `rw_audit` / `rw_query`) と命名一貫性を確立する。CLI の外部動作・テスト結果・公開 API はすべて現状と同一に保つ。

## Boundary Context
- **In scope**: `scripts/rw_light.py` → `scripts/rw_cli.py` のファイルリネーム、`cmd_init` の symlink 作成ターゲット更新、テスト側 ~500 件の `rw_light` 参照を `rw_cli` 参照に一括置換、`docs/` および `.kiro/steering/` の参照更新、`templates/` 配下のテンプレートファイル（`templates/CLAUDE.md` 等）と `tests/conftest.py::mock_templates` fixture の `scripts/rw_light.py` ダミーファイル生成 (cmd_init の os.stat 検査対応) が `rw_light.py` に言及する場合の参照更新、既存 Vault 向けマイグレーションヘルパとしての `rw init --reinstall-symlink` サブフラグ追加。
- **Out of scope**: コマンド動作変更、新機能追加、テストロジックの変更（patch 対象および直接アクセス参照の文字列更新のみ許可）、他 5 モジュール (`rw_config`, `rw_utils`, `rw_prompt_engine`, `rw_audit`, `rw_query`) の内容変更、`rw_light.py` を bridge/proxy ファイルとして残す案（Req 1.3 に抵触するため不採用）。
- **Adjacent expectations**: module-split スペックの Req 6.1（「`scripts/rw_light.py` が存在し続ける」）は本スペックで失効し、`scripts/rw_cli.py` に読み替える契約に更新される。既存 Vault（`rw` symlink が旧 `rw_light.py` を指す状態）は現時点で実体なしと確認済みだが、将来ユーザ向けの再構成手順は `rw init --reinstall-symlink` で提供する。

## Requirements

### Requirement 1: ファイル名と参照先の整合
**Objective:** As a 開発者, I want `scripts/rw_light.py` をモジュール命名規約に従う `scripts/rw_cli.py` にリネームしたい, so that 6 モジュール全てが同一の `rw_<責務>.py` 命名パターンで一貫し、新規コントリビュータの認知負荷が下がる。

#### Acceptance Criteria
1. The CLI codebase shall expose `scripts/rw_cli.py` as the sole entry point file; `scripts/rw_light.py` は存在しないこと。
2. The rename shall preserve git 履歴連続性: `git log --follow scripts/rw_cli.py` でリネーム前の `rw_light.py` 時代のコミットを辿れること。
3. The CLI codebase shall not contain `scripts/rw_light.py` as a bridge / proxy / shim ファイル（module-split Req 1.3 の re-export ゼロ方針を継承）。

### Requirement 2: CLI 外部動作の不変性
**Objective:** As a オペレーター, I want リネーム後も既存の CLI 使用方法がそのまま動作する, so that 運用スクリプトや手順書が壊れない。

#### Acceptance Criteria
1. When a user invokes `python scripts/rw_cli.py` without arguments, the CLI shall display リネーム前の `rw_light.py` と同一の usage テキスト。
2. When a user invokes any subcommand（`lint`, `ingest`, `synthesize-logs`, `approve`, `init`, `query` 系, `audit` 系, `lint query`）via `python scripts/rw_cli.py <subcommand>`, the CLI shall produce リネーム前と同一の引数受付・出力・exit code。
3. The CLI entry point shall expose `main()` function at scripts/rw_cli.py の top level と同様の位置（既存の外部呼び出し契約を維持）。

### Requirement 3: テスト整合性と継続グリーン
**Objective:** As a テスト作成者, I want リネーム後も全テストがグリーンを維持し、参照経路が新モジュール名で一貫する, so that 今後のメンテナンスが命名揺れに悩まされない。

#### Acceptance Criteria
1. When the full test suite is run after the rename (`pytest tests/`), the refactored codebase shall pass 641 passed + 1 skipped = 642 collected 以上（module-split 完了時と同件数以上、リグレッションなし）。
2. The test files shall contain zero `import rw_light` statements（全て `import rw_cli` に機械置換済み）。
3. The test files shall contain zero `monkeypatch.setattr(rw_light, ...)` statements on residual commands (`cmd_lint` / `cmd_ingest` / `cmd_synthesize_logs` / `cmd_approve` / `cmd_init` / `_backup_timestamp` / `plan_ingest_moves` / `execute_ingest_moves` / `load_lint_summary` / `parse_topics` / `render_candidate_note` / `candidate_note_path` / `candidate_files` / `approved_candidate_files` / `synthesis_target_path` / `merge_synthesis` / `promote_candidate` / `mark_candidate_promoted` / `update_index_synthesis` / `append_approval_log`)（全て `rw_cli` 参照に機械置換済み）。
4. The test files shall contain zero code-line `rw_light.<residual_symbol>` 直接アクセス（全て `rw_cli.<residual_symbol>` に書き換え済み、docstring / コメント言及のみ許容）。
5. `tests/conftest.py` と `tests/test_ingest.py` の `rw_light.shutil.move` 参照は `rw_cli.shutil.move` に更新される（`shutil` は stdlib モジュールだが `rw_light` 名前空間経由でアクセスしているため）。
6. `tests/conftest.py::mock_templates` fixture が生成する dummy `<tmp>/scripts/rw_light.py` ファイルは `<tmp>/scripts/rw_cli.py` に更新される（リネーム後 cmd_init の os.stat 検査が `scripts/rw_cli.py` を対象とするため、ダミーファイル名もそれに合わせる必要がある）。

### Requirement 4: 新規 Vault 初期化時の symlink ターゲット整合
**Objective:** As a 新規ユーザ, I want `rw init <vault>` で Vault を初期化すると配置される `rw` symlink が新ファイル名を指す, so that 初期化直後から symlink 経由で正しく CLI が起動する。

#### Acceptance Criteria
1. When a user runs `python scripts/rw_cli.py init <vault-path>` against a fresh directory, the cmd_init shall create symlink `<vault-path>/scripts/rw` whose resolved target is `scripts/rw_cli.py` in the development root（path style は module-split 完了時の既存解決方式を継承）。
2. When the created symlink is invoked（例: `python <vault-path>/scripts/rw`）, the CLI shall display usage テキストを PYTHONPATH 追加設定なしで表示する（サブモジュール発見が `sys.path` 自動解決で成功）。

### Requirement 5: 既存 Vault マイグレーションヘルパ
**Objective:** As a 将来の既存ユーザ, I want 旧 `rw_light.py` を指す symlink を新ファイル名向けに張り替える手段, so that 本スペック適用後にユーザが Vault を再構築せずに CLI を継続利用できる。

#### Acceptance Criteria
1. When a user runs `python scripts/rw_cli.py init <existing-vault> --reinstall-symlink`, the cmd_init shall detect 既存 `<existing-vault>/scripts/rw` symlink, 削除し、新規に `scripts/rw_cli.py` を指す symlink を再作成する。
2. When `--reinstall-symlink` is specified against an existing Vault, the cmd_init shall skip 通常初期化処理（ディレクトリ生成・テンプレートコピー・Git 初期化・.gitignore 配置等）and execute symlink 張り替えのみ。
3. If `--reinstall-symlink` is specified against a directory that is not an existing Vault（`<vault>/scripts/` 不在など）, the cmd_init shall print 明示的なエラーメッセージを stderr に出力し exit code 1 (runtime error, severity-unification 契約準拠) で終了する。
4. The `rw init --help` output shall document the `--reinstall-symlink` フラグの目的・使用条件を含む。

### Requirement 6: ドキュメント・steering 参照整合
**Objective:** As a 新規コントリビュータ, I want ドキュメントと steering 記述が新ファイル名で一貫している, so that 古い `rw_light.py` 参照に惑わされずプロジェクト構造を理解できる。

#### Acceptance Criteria
1. The `docs/user-guide.md`, `docs/developer-guide.md`, `README` (存在する場合), `CLAUDE.md`, および `templates/` 配下のテンプレートファイル（`templates/CLAUDE.md` 等）shall contain zero コード例示 / 手順記述としての `scripts/rw_light.py` または `rw_light.<symbol>` 参照（全て `rw_cli` 参照に更新）。
2. The `.kiro/steering/structure.md` and `.kiro/steering/tech.md` shall reference `rw_cli.py` (and not `rw_light.py`) in all CLI 関連記述（module-split 完了時の記述を本スペック完了時点の実態に同期）。
3. Historical 参照（git commit メッセージ, 過去セッション記録, 完了済 spec 本文の `rw_light.py` 言及等）は変更対象外（歴史性を保持する）。本スペック完了後 `.kiro/specs/module-split/requirements.md` Req 6.1 の `scripts/rw_light.py` 言及の扱いは design フェーズで判断する（原文編集 / 補注追加 / 不変のいずれか）。
