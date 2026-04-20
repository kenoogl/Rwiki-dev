# Implementation Plan

本スペックは Migration Strategy 5 step を task graph に落とし込む。Task 1 は pre-check、Task 2 は「バッチ A: 原子的 1 コミット推奨」として中間 pytest green を期待しない前提で分解。Task 3-5 は Task 2 完了後に並行実行可能。Task 6 は最終検証で、6.3 は手動検証チェックリスト文書化（autonomous 可）、6.4 は人間による実施（`/kiro-impl` 完了後 hand-off）。

- [x] 1. Pre-check: `.claude/settings.local.json` の `rw_light` 参照判断
  - `rg -n "rw_light" .claude/settings.local.json` で 6 箇所の実体を確認
  - permission 文字列 / JSON 値内に `scripts/rw_light.py` 等の symlink target 参照があれば更新対象として記録（Task 5 に取り込み）
  - それ以外（permission rule の例示・historical コメント等）は Out of Boundary 確定として記録
  - 判断結果を `.kiro/specs/rw-light-rename/research.md` §8 に追記（実装時判断の記録）
  - バッチ A 着手前に実施することで、Task 6.2 の残存参照判定を単純化（条件分岐を排除）
  - 完了条件: 6 箇所全ての実体確認済み、更新 / 保持の振り分けが `research.md` に記録され、更新対象があれば Task 5 の対象ファイルリストに追加済み
  - _Requirements: 6.1, 6.2_

- [ ] 2. バッチ A: rename と cmd_init 拡張（原子的 1 コミット推奨、中間 pytest green 非要求）

- [x] 2.1 ファイル rename（git mv で履歴連続性保持）
  - `git mv scripts/rw_light.py scripts/rw_cli.py` を実行
  - `git mv tests/test_rw_light.py tests/test_rw_cli.py` を実行
  - `git log --follow scripts/rw_cli.py` で rename 前コミット履歴が辿れることを確認
  - この時点では `rw_cli.py` 内部の自己言及や他ファイルの import は未更新、pytest は赤でよい
  - 完了条件: `scripts/rw_cli.py` と `tests/test_rw_cli.py` が git 追跡下で存在、`scripts/rw_light.py` と `tests/test_rw_light.py` が不在
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 2.2 rw_cli.py 内部コード更新と cmd_init 拡張
  - `rw_cli.py` 内自己言及 3 箇所を更新（symlink source path リテラル / コメント / warn メッセージ）
  - 既存 symlink 作成ロジックを `_install_rw_symlink(target_path, dev_root) -> dict[str, str]` private helper として抽出、chmod + 既存 symlink 削除 + `os.symlink` + report dict 返却を同関数に集約
  - `cmd_init` の argparse に `--reinstall-symlink` フラグを追加（既存 `--force` と同列、`add_help=False` 維持）
  - `cmd_init` 冒頭に早期 return 分岐を実装: `--reinstall-symlink` 指定時は `rw_utils.is_existing_vault()` で Vault 判定 → 非 Vault なら stderr エラー + return 1、Vault なら `_install_rw_symlink` のみ呼び出して return 0
  - `--reinstall-symlink` + `--force` 併用時は stderr 警告出力後 `--reinstall-symlink` を優先
  - `cmd_init` 通常パスも `_install_rw_symlink` 呼び出しに差し替え（重複排除）
  - `print_usage` の `rw init` 記載行に `--reinstall-symlink` 説明を追加
  - `--reinstall-symlink` パスの report dict は `{target, dirs_created=0, templates_copied=[], skipped=[], git_init="skipped (--reinstall-symlink)", gitignore="skipped (--reinstall-symlink)", symlink=<result>}` 形式
  - 完了条件: `rg "rw_light" scripts/rw_cli.py` が 0 件、`_install_rw_symlink` 関数定義が `rg "def _install_rw_symlink" scripts/rw_cli.py` で検出される、`rg "reinstall-symlink" scripts/rw_cli.py` で argparse add_argument と print_usage 内の記載が検出される
  - _Requirements: 1.1, 2.1, 2.2, 2.3, 4.1, 5.1, 5.2, 5.3, 5.4_

- [x] 2.3 tests 配下の参照一括置換と conftest 更新
  - `tests/` 配下全 13 ファイルの `rw_light` 参照 141 箇所のうち **code-line 参照**（import 文 / monkeypatch object 形 / monkeypatch 文字列形 / `rw_light.<symbol>` 直接アクセス / `rw_light.shutil.move` 等）を `rw_cli` に機械置換
  - `tests/conftest.py::mock_templates` fixture が生成する dummy ファイル名を `scripts/rw_light.py` から `scripts/rw_cli.py` に変更
  - `tests/test_ingest.py` と `tests/conftest.py` の `rw_light.shutil.move` を `rw_cli.shutil.move` に更新
  - docstring / コメント内の `rw_light` 言及は Req 3.4 により許容、機械置換対象外（historical 言及を保持する場合も含め個別判断せず原則残存可）
  - 既存テストの論理変更（monkeypatch パターンの変更・アサーション論理変更）は行わない、文字列置換のみ
  - 完了条件: `tests/` 配下の code-line 参照（import 文・`monkeypatch.setattr` 呼び出し・`rw_light.` 属性アクセス・`shutil.move` 系）で `rw_light` が 0 件（`grep -rE "^\s*(import rw_light|from rw_light|from scripts\.rw_light)" tests/` が 0 件、`grep -rE "monkeypatch\.setattr\s*\(\s*(rw_light|\"rw_light\.)" tests/` が 0 件、`grep -rE "rw_light\.[a-zA-Z_]" tests/ --include="*.py"` が docstring/コメント外で 0 件）
  - _Requirements: 3.2, 3.3, 3.4, 3.5, 3.6_

- [x] 2.4 `--reinstall-symlink` 専用テスト 3 件を追加
  - `tests/test_init.py` に以下 3 テストを新規追加（既存 fixture `mock_templates`, `patch_constants` 等を流用、既存テストの論理変更なし）:
    - `test_cmd_init_reinstall_symlink_on_existing_vault`: 既存 Vault（`CLAUDE.md` が存在する状態）に対して `cmd_init(["<target>", "--reinstall-symlink"])` 実行、戻り値 0、`report["dirs_created"] == 0`、`report["templates_copied"] == []`、`report["git_init"]` と `report["gitignore"]` が `"skipped (--reinstall-symlink)"` を含む、`report["symlink"]` が `created:` で始まり `rw_cli.py` を指向、実 FS 上の symlink が `rw_cli.py` を指す
    - `test_cmd_init_reinstall_symlink_rejects_non_vault`: `CLAUDE.md` も `index.md` も存在しないディレクトリで `cmd_init(["<target>", "--reinstall-symlink"])` 実行、戻り値 1、capsys で stderr 出力に「既存の Vault ではありません」相当のメッセージが含まれることを確認
    - `test_cmd_init_reinstall_symlink_with_force_warns`: `cmd_init(["<target>", "--reinstall-symlink", "--force"])` 実行、capsys で stderr 警告メッセージ（`--reinstall-symlink と --force が併用`）を含むことを確認、その後は `--reinstall-symlink` 挙動（通常初期化 skip）で進行、戻り値 0
  - 完了条件: `pytest tests/test_init.py::test_cmd_init_reinstall_symlink_on_existing_vault tests/test_init.py::test_cmd_init_reinstall_symlink_rejects_non_vault tests/test_init.py::test_cmd_init_reinstall_symlink_with_force_warns -v` の 3 テストが pass
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 2.5 バッチ A 最終検証（pytest green 確認）
  - `pytest tests/ -q` を実行し 644 passed + 1 skipped 以上を確認（既存 641 passed + 新規 3 passed + 1 skipped）
  - 件数不足 / 失敗検出時は 2.1-2.4 のいずれかに根本原因があるため、原因を特定して当該 task に戻る（バッチ A 全体を rollback する場合は `git reset --hard <before-2.1>`）
  - 完了条件: `pytest tests/ -q` の出力末尾が `644 passed, 1 skipped` 以上、かつ exit code 0
  - _Requirements: 3.1_

- [ ] 3. (P) scripts 他モジュールの docstring 同期
  - `scripts/rw_config.py` L3、`scripts/rw_utils.py` L3、`scripts/rw_prompt_engine.py` L3 および L9、`scripts/rw_audit.py` L3 および L8、`scripts/rw_query.py` L7 の計 7 箇所の「現役依存関係説明」を `rw_light` → `rw_cli` に更新
  - `scripts/rw_query.py` L4 の historical 記述は「Phase 4b (module-split spec) で rw_light.py (現 rw_cli.py) から物理移動。」のように補注形で整合化
  - 完了条件: `rg "rw_light" scripts/rw_config.py scripts/rw_utils.py scripts/rw_prompt_engine.py scripts/rw_audit.py scripts/rw_query.py` が 0 件
  - _Requirements: 6.2_
  - _Boundary: rw_config, rw_utils, rw_prompt_engine, rw_audit, rw_query (docstring only)_
  - _Depends: 2.5_

- [ ] 4. ドキュメント参照更新

- [ ] 4.1 (P) `docs/` 配下の現役ドキュメント更新
  - `docs/user-guide.md` / `docs/developer-guide.md` / `docs/CLAUDE.md` の `rw_light` 参照を `rw_cli` に更新
  - 手順コマンド例（`python scripts/rw_light.py ...`）、ディレクトリ構造図、symlink 説明、テスト除外コマンド、import 例示などの現役ドキュメント記述を対象
  - `test_rw_light.py` ファイル名言及がある場合は `test_rw_cli.py` に更新
  - 完了条件: `rg "rw_light" docs/` が 0 件
  - _Requirements: 6.1_
  - _Boundary: docs/_
  - _Depends: 2.5_

- [ ] 4.2 (P) ルート `CLAUDE.md` / `README.md` / `templates/CLAUDE.md` の更新
  - `README.md` の L33/L37/L50/L95/L102/L127 を中心に `rw_light` 参照を `rw_cli` に更新
  - `templates/CLAUDE.md` L109 の `scripts/rw_light.py` 言及を `scripts/rw_cli.py` に更新
  - ルート `CLAUDE.md` 内の `rw_light` 参照を grep で確定し、検出された現役記述を更新（project 命令なので存在しない可能性高、ない場合は変更なしで完了）
  - 完了条件: `rg "rw_light" README.md templates/ CLAUDE.md` が 0 件（ルート `CLAUDE.md` は参照存在しなければスキップ）
  - _Requirements: 6.1_
  - _Boundary: README.md, templates/, root CLAUDE.md_
  - _Depends: 2.5_

- [ ] 5. (P) steering 記述の同期
  - `.kiro/steering/structure.md` と `.kiro/steering/tech.md` の CLI 構成記述を `rw_cli.py` に同期
  - CLI ツール module 構成セクション（Layer 4 の責務記述）、Common Commands セクション（`python scripts/rw_light.py ...` 形式の例示）、Key Technical Decisions セクション（責務別モジュール分割 CLI の記述）等を対象
  - `roadmap.md` は Out of Boundary のため変更しない
  - Task 1 の判断で `.claude/settings.local.json` が更新対象に含まれた場合、ここで同時に更新する
  - 完了条件: `rg "rw_light" .kiro/steering/structure.md .kiro/steering/tech.md` が 0 件、`.claude/settings.local.json` の判断結果が反映済み
  - _Requirements: 6.2_
  - _Boundary: .kiro/steering/, .claude/settings.local.json (判断次第)_
  - _Depends: 1, 2.5_

- [ ] 6. 最終検証

- [ ] 6.1 pytest による自動テスト検証
  - `pytest tests/ -q` を実行し 644 passed + 1 skipped 以上を確認
  - 完了条件: `pytest tests/ -q` の出力末尾が `644 passed, 1 skipped` 以上、exit code 0
  - _Requirements: 3.1_
  - _Depends: 3, 4.1, 4.2, 5_

- [ ] 6.2 残存参照 grep 検証
  - `rg -l rw_light` の結果が以下の Out of Boundary 対象ファイルのみに限定されることを確認: `.kiro/steering/roadmap.md` / `CHANGELOG.md` / `.kiro/specs/**/*.md`（ただし `.kiro/specs/rw-light-rename/` 配下の本スペック spec 本文は除外対象ではなく、更新された状態で参照が残らない前提） / `TODO_NEXT_SESSION.md` / tests 配下 docstring/コメント言及（Req 3.4 許容） / Task 1 で Out of Boundary 確定した `.claude/settings.local.json`（該当時）
  - 上記以外に `rw_light` 残存がある場合は原因を特定し、該当 task (2-5) に戻る
  - 完了条件: `rg -l rw_light` の出力が Out of Boundary リストのみ、それ以外への漏れが 0
  - _Requirements: 6.1, 6.2, 6.3_
  - _Depends: 3, 4.1, 4.2, 5_

- [ ] 6.3 手動検証チェックリスト文書化
  - `.kiro/specs/rw-light-rename/manual-verification.md` を作成し、以下 5 項目をチェックボックス付きで文書化:
    - (1) `git log --follow scripts/rw_cli.py` で rename 前コミットが辿れることを確認（Req 1.2）
    - (2) `python scripts/rw_cli.py` 単独実行で既存 usage が表示（`--reinstall-symlink` 追記のみの差分）（Req 2.1, 5.4）
    - (3) 新規空ディレクトリで `python scripts/rw_cli.py init ./tmp-vault` 実行、`ls -l ./tmp-vault/scripts/rw` が `rw_cli.py` を指向するシンボリックリンクであること（Req 4.1, 4.2）
    - (4) 上記 Vault で `python scripts/rw_cli.py init ./tmp-vault --reinstall-symlink` 実行、`./tmp-vault/scripts/rw` 以外のファイル・ディレクトリ mtime が不変で symlink のみ再作成されることを確認（Req 5.1, 5.2）
    - (5) 非 Vault ディレクトリ（新規空ディレクトリ）で `python scripts/rw_cli.py init ./non-vault --reinstall-symlink` 実行、exit 1 + stderr エラーメッセージを確認（Req 5.3）
  - 各項目に実行コマンド・期待結果・記入欄（実行日時・実行者・結果 pass/fail）を記載
  - 本 task は autonomous 実装範囲内で完了可能（文書作成のみ）
  - 完了条件: `.kiro/specs/rw-light-rename/manual-verification.md` が存在し、5 項目全てに実行コマンドと期待結果が明記されている
  - _Requirements: 1.2, 2.1, 4.1, 4.2, 5.1, 5.2, 5.3, 5.4_
  - _Depends: 6.1_

- [ ] 6.4 人間による手動検証実施（autonomous 外、`/kiro-impl` 完了後 hand-off）
  - **本 task は autonomous 実装範囲外**。`/kiro-impl rw-light-rename` 完了後、人間が `.kiro/specs/rw-light-rename/manual-verification.md` に従って 5 項目を実施する
  - 各項目の実行結果（pass/fail）を manual-verification.md に記録、全項目 pass で本 task を完了マーク
  - いずれかの項目が fail した場合、原因を特定し対応する実装 task に差し戻す
  - 完了条件: `.kiro/specs/rw-light-rename/manual-verification.md` の 5 項目全てが `[x]` 完了マーク付きで pass 記録されている
  - _Requirements: 1.2, 2.1, 4.1, 4.2, 5.1, 5.2, 5.3, 5.4_
  - _Depends: 6.3_
