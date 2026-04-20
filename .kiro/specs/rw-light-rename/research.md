# Gap Analysis: rw-light-rename

_生成日時: 2026-04-21_
_対象スペック: `.kiro/specs/rw-light-rename/requirements.md`（requirements-approved）_

## 1. 現状スナップショット

### 1.1 リポジトリ全体の `rw_light` 参照分布

`rg -c rw_light` 結果: **647 occurrences / 60 files**

| カテゴリ | ファイル | 件数 | 変更区分 |
|---------|---------|------|---------|
| コード本体 | `scripts/rw_light.py` | 3 | **更新対象**（自ファイル内の自己言及） |
| 他モジュール docstring | `scripts/rw_config.py`, `rw_utils.py`, `rw_prompt_engine.py`, `rw_audit.py`, `rw_query.py` | 8 | **要判断**（R2） |
| テスト | `tests/*.py`（13 ファイル） | 141 | **更新対象** |
| ドキュメント（current） | `docs/CLAUDE.md`, `docs/developer-guide.md` | 21 | **更新対象** |
| ドキュメント（template） | `templates/CLAUDE.md` | 1 | **更新対象** |
| README / ルート | `README.md`, `CHANGELOG.md` | 26 | **要切り分け**（R4） |
| Steering | `.kiro/steering/structure.md`, `tech.md`, `roadmap.md` | 15 | **更新対象**（roadmap 要判断 R3） |
| 過去 spec 本文 | `.kiro/specs/*/{requirements,design,tasks,research}.md`, `brief.md` | ~400 | **変更対象外**（歴史性保持、Req 6.3） |
| 完了セッション TODO | `TODO_NEXT_SESSION.md` | 10 | **変更対象外**（生成物） |
| 設定 | `.claude/settings.local.json` | 6 | **要確認**（実体次第） |

### 1.2 `scripts/rw_light.py` 内の自己言及（3 箇所）

- L580: `rw_src = os.path.join(rw_config.DEV_ROOT, "scripts", "rw_light.py")` — symlink source path リテラル（Req 4.1 の主対象）
- L583: コメント `# rw_light.py に実行権限を付与`
- L589: warn メッセージ `[WARN] rw_light.py の実行権限付与失敗: {e}`

### 1.3 `cmd_init` の argparse 現状（L421-429）

```python
parser = _argparse.ArgumentParser(prog="rw init", add_help=False)
parser.add_argument("--force", action="store_true", default=False, ...)
parser.add_argument("target", nargs="?", default=None)
parsed, _unknown = parser.parse_known_args(args)
```

- `add_help=False`: `--help` 出力は `rw init --help` で現状は表示されない（argparse 自動生成の help を使わない実装）→ **Req 5.4 実装時に `add_help=True` 化または手動 usage 拡充が必要**
- `parse_known_args` 使用: 未知フラグを黙って無視する現行挙動。`--reinstall-symlink` 追加は `parser.add_argument` で対応可

### 1.4 既存 symlink 作成ロジック（L579-604）

- `rw_src` に `scripts/rw_light.py` 絶対パスを生成
- `os.chmod` で実行権限付与
- `os.path.islink(rw_link)` チェック → `os.remove` で **既存 symlink は削除して再作成するロジックを既に保有**
- ただし周囲には AGENTS/ コピー / ディレクトリ生成 / .gitignore コピー / git init など **通常初期化処理が並列して実行される**

→ 「symlink のみ張り替え」用途を実現するには、通常初期化処理を skip する制御フロー（early return）を `cmd_init` の冒頭に挿入する必要がある

### 1.5 他モジュール docstring 内の `rw_light` 言及詳細

| ファイル:行 | 内容 | 性質 |
|-----------|------|------|
| `rw_config.py:3` | `他のサブモジュール（rw_utils, rw_prompt_engine, rw_audit, rw_query, rw_light）から` | **現役**依存関係説明 |
| `rw_utils.py:3` | 同上 | **現役** |
| `rw_prompt_engine.py:3` | `` `rw_audit`, `rw_query`, `rw_light` から `` | **現役** |
| `rw_prompt_engine.py:9` | `他のサブモジュール（rw_audit, rw_query, rw_light）は import しない` | **現役** |
| `rw_audit.py:3` | `` `rw_light` から `import rw_audit` + `rw_audit.<name>` 形式で参照する `` | **現役** |
| `rw_audit.py:8` | `他のサブモジュール（rw_query, rw_light）は import しない` | **現役** |
| `rw_query.py:4` | `Phase 4b (module-split spec) で rw_light.py から物理移動。` | **historical** |
| `rw_query.py:7` | `rw_audit / rw_light は import しない` | **現役** |

→ 「現役 docstring」は本スペックで更新すべき（モジュール構成説明の正確性維持）。「historical」は要判断。

### 1.6 テスト側詳細分布（141 occurrences / 13 files）

| ファイル | 件数 | 主な参照形態 |
|---------|------|-------------|
| `tests/test_init.py` | 37 | 最多 |
| `tests/test_rw_light.py` | 24 | **ファイル名自体が `rw_light`**（R1） |
| `tests/test_lint.py` | 24 | import + monkeypatch + 直接アクセス |
| `tests/test_ingest.py` | 18 | `rw_light.shutil.move` 含む |
| `tests/test_approve.py` | 13 | |
| `tests/test_synthesize_logs.py` | 11 | |
| `tests/test_source_vocabulary.py` | 4 | |
| `tests/conftest.py` | 3 | mock_templates fixture、shutil patch |
| `tests/test_conftest_fixtures.py` | 2 | |
| `tests/test_git_ops.py` | 2 | |
| `tests/test_utils.py` | 1 | |
| `tests/test_audit.py` | 1 | |
| `tests/test_lint_query.py` | 1 | |

### 1.7 ドキュメント類の現役 vs historical 切り分け

- `docs/developer-guide.md`: 20 箇所。`test_rw_light.py` のファイル名言及 (L49, L66) + 導入例コード (L85, L88, L109) など **現役ドキュメントとして使われている**。全更新対象
- `docs/CLAUDE.md:131`: 「`scripts/rw` シンボリックリンク: `scripts/rw_light.py` への実行可能シンボリックリンク」— **現役**、更新対象
- `templates/CLAUDE.md:109`: Vault 向けテンプレート内の CLI 参照 — 更新対象
- `README.md`: 6 箇所（L33 手順例、L37 絶対パス起動例、L50 symlink 説明、L95 ディレクトリ構造図、L102 テスト構成、L127 pytest 除外コマンド）— **全て現役**
- `CHANGELOG.md`: 1 箇所（L1 付近、要 Read で詳細確認） — historical 可能性高
- `.kiro/steering/roadmap.md`: 10 箇所。module-split 前の旧計画記述が多い（例 L6「既存実装として `scripts/rw_light.py` に…」、L128-130「rw_light.py のモジュール分割」セクション）。**本スペック適用時点で矛盾発生するため補注 or 更新が必要** → R3

---

## 2. Requirement-to-Asset Map（ギャップ分類）

| Req | 必要変更 | Gap 分類 | 備考 |
|-----|---------|---------|------|
| 1.1 | `scripts/rw_light.py` → `scripts/rw_cli.py` | **Missing** | `git mv` |
| 1.2 | 履歴連続性 | Constraint | `git mv` 使用で自動保証 |
| 1.3 | bridge/proxy 不在 | Constraint | 追加しない方針維持 |
| 2.1 / 2.2 | CLI 外部動作不変 | 既存挙動継承 | rename のみで変化しない |
| 2.3 | `main()` top-level 位置 | 既存構造継承 | 現在 L626 付近に `main()` 存在（要確認） |
| 3.1 | 642 collected 同件数 | Constraint | テスト追加・削除なし |
| 3.2 | import 0 化 | **Missing** | 141 箇所中 import 行を一括置換 |
| 3.3 | monkeypatch 0 化 | **Missing** | object 形 + 文字列形両対応 |
| 3.4 | `rw_light.<sym>` 直接アクセス 0 | **Missing** | |
| 3.5 | `rw_light.shutil.move` 置換 | **Missing** | `conftest.py`, `test_ingest.py` |
| 3.6 | mock_templates ダミーファイル名更新 | **Missing** | fixture 修正 |
| 4.1 | symlink ターゲット更新 | **Missing** | L580 リテラル修正 |
| 4.2 | symlink 起動時 usage 表示 | 既存挙動継承 | |
| 5.1 | `--reinstall-symlink` フラグ追加 | **Missing** | argparse + dispatch 分岐 |
| 5.2 | 通常初期化処理 skip | **Missing** | 制御フロー追加 |
| 5.3 | 非 Vault エラー exit 1 | **Missing** | validation 追加 |
| 5.4 | `--help` に記載 | **Missing** | `add_help=True` 化 or usage 手動拡充 |
| 6.1 | docs/templates/CLAUDE.md/README 更新 | **Missing** | |
| 6.2 | steering 更新 | **Missing** | structure + tech、roadmap は R3 |
| 6.3 | historical 保持 | Constraint | spec 過去本文は不変 |

---

## 3. 実装アプローチ Options

### Option A: 最小変更（cmd_init をインラインで extend）

- `cmd_init` の argparse に `--reinstall-symlink` を追加
- 既存 symlink 作成ロジック（L579-604）はそのまま
- フラグ判定は `cmd_init` 冒頭で行い、true なら symlink 処理のみ実行して early return

**Trade-offs**:
- ✅ 変更行数最小（+20 行程度）
- ✅ 既存挙動に対する影響限定
- ❌ symlink 作成ロジックが `cmd_init` に埋め込まれたまま → テスト単位が粗い
- ❌ 通常 init パスと `--reinstall-symlink` パスでロジック重複（symlink 作成が二箇所に出現）

### Option B: Hybrid（symlink helper 抽出 + cmd_init extend）【推奨】

- 既存 symlink 作成ロジック（L579-604）を `_install_rw_symlink(target_path: str, dev_root: str) -> dict` に抽出
- `cmd_init` 通常パスと `--reinstall-symlink` 早期 return パスの両方から同じ helper を呼ぶ
- Vault 検出 helper（`rw_utils.is_existing_vault`）を再利用して Req 5.3 の validation を実装

**Trade-offs**:
- ✅ テスト可能性: helper 単体で Req 4.1 / 5.1 を網羅
- ✅ 重複排除: 挙動不整合リスク低減
- ✅ Scope 適切: 1 関数抽出で済む
- ❌ 変更行数 やや増（+40 行程度）
- ❌ 既存挙動保全のため抽出時の動作等価性確認が必要

### Option C: 新規サブコマンド分離（`rw reinstall-symlink`）

- `rw init --reinstall-symlink` ではなく独立サブコマンド化

**Trade-offs**:
- ❌ **Req 5.1 の明示記述**（`rw_cli.py init <existing-vault> --reinstall-symlink`）**に抵触** → 却下

---

## 4. Effort / Risk

| 項目 | 評価 | 根拠 |
|------|------|------|
| **Effort** | **S (1-3 days)** | Rename は機械置換、`cmd_init` 拡張 +40 行、テスト修正は文字列置換主体で論理変更なし |
| **Risk** | **Low** | 642 test の回帰検出網が既存、純粋 rename + argparse 拡張は既知パターン、循環依存なし |

---

## 5. Research Needed（design フェーズに持ち越し）

| ID | 項目 | 判断軸 |
|----|------|-------|
| R1 | `tests/test_rw_light.py` ファイル名をリネームするか（`test_rw_cli.py`） | Req 3 の AC には未明記。内部 import 先だけ `rw_cli` に変えて名前は残す案 / git mv で整合させる案 / どちらでも可 |
| R2 | 他モジュール docstring 内の `rw_light` 言及の扱い（`rw_config.py`, `rw_utils.py`, `rw_prompt_engine.py`, `rw_audit.py`, `rw_query.py`） | Req 6 の対象に `scripts/*.py` docstring が含まれていない。現役依存関係説明は更新、historical 記述は保持の切り分けが必要 |
| R3 | `.kiro/steering/roadmap.md` の扱い | module-split 以前の旧計画記述が残存。本スペック完了時点で矛盾発生 → Req 6.2 への追加 / 補注追加 / 不変のいずれか |
| R4 | `README.md` / `CHANGELOG.md` の current/historical 切り分け | README は全て現役 → 更新。CHANGELOG は historical エントリ → 保持、の整理 |
| R5 | `docs/CLAUDE.md` の Req 6.1 対象への明示化 | 現 Req 6.1 は「`CLAUDE.md`」とのみ記載。`docs/CLAUDE.md` と ルート `CLAUDE.md` を明確化 |
| R6 | `--reinstall-symlink` と `--force` / `target` / `--help` の相互作用 | 排他制御の要否、`--reinstall-symlink` 指定時に `--force` 無視か error か |
| R7 | `add_help=False` → `add_help=True` 化の影響 | 既存の usage 出力が変化しないか確認（Req 2.1 との整合性） |
| R8 | `.claude/settings.local.json` の 6 箇所 | 実体内容次第（permission 許可リスト等なら更新不要の可能性） |
| R9 | module-split `requirements.md` Req 6.1 の `rw_light.py` 言及 | 本スペック適用で失効する記述への対処（Adjacent expectations 記載事項） |
| R10 | 保留 C（Req 2.3 `main()` 位置 AC） / 保留 D（Req 3.3 residual symbol 列挙の `print_usage` / `main`） | 前回 requirements レビュー時点の持ち越し事項 |

---

## 6. 推奨（design 着手時点）

### 6.1 Preferred Approach

**Option B (Hybrid)** を推奨。

理由:
- `cmd_init` は既に 200 行超で単一責務を保ちにくい規模、symlink ロジック抽出は構造改善にも寄与
- 純粋重複排除で挙動等価性を担保しやすい
- `_install_rw_symlink` 単体テストで Req 4.1 / 5.1 の挙動確認を独立実施可能

### 6.2 Key Decisions for Design Phase

1. **Phase 構成**: 単一 Phase（rename + argparse 拡張 + 置換を一括）vs 多段（module-split に倣い rename 先行 → test patch → docs 更新）の選択
2. **Symlink helper インタフェース**: 戻り値 dict / 例外設計 / chmod タイミングを helper 内に含めるか
3. **`--reinstall-symlink` 引数の位置**: `cmd_init` argparse のフラグとして実装、排他制約の明示
4. **`--help` 化**: `add_help=True` 化の可否、既存 usage 出力との整合性確認
5. **R1-R10 の判断**: 特に R1（test_rw_light.py ファイル名）、R2（他モジュール docstring）、R3（roadmap.md）は実装範囲を左右

### 6.3 Research Items to Carry Forward

- **R1-R5**: 範囲決定（スコープ拡大の可能性）
- **R6-R7**: argparse 拡張の挙動確認
- **R8**: 実体確認
- **R9**: Adjacent expectations 最終化
- **R10**: requirements 保留事項の最終判断

---

_次のアクション_: `/kiro-spec-design rw-light-rename` で design フェーズへ（R1-R10 を design 内で解決）

---

## 7. Design Synthesis Outcomes（design フェーズで確定）

### 7.1 Generalization

- 本スペックは **単一 rename 変換 + 1 argparse フラグ追加** の局所変更。generalize 対象となる複数要件の変種パターンは存在しない
- symlink 作成処理は既に `cmd_init` 内部でインライン実装済み。helper 抽出 (`_install_rw_symlink`) は Req 4.1 と 5.1 の両方で再利用可能な唯一の汎化点

### 7.2 Build vs. Adopt

- **Adopt**: `git mv` で履歴連続性を得る（GitHub / git 標準機能）
- **Adopt**: `argparse` `add_argument` による `--reinstall-symlink` フラグ（既存 `--force` パターン踏襲）
- **Adopt**: `rw_utils.is_existing_vault()` を再利用して非 Vault 検出（Req 5.3）
- **Build**: `_install_rw_symlink(target_path, dev_root) -> dict` helper 抽出（新規、cmd_init インラインからの純粋切り出し、挙動等価）

### 7.3 Simplification

- `cmd_init` の argparse は既に `add_help=False` でカスタム `print_usage` を使用 → `add_help=True` 化は既存挙動変更リスク → **現状維持**（`add_argument("--reinstall-symlink", ..., help=...)` の help 文字列と `print_usage` への 1 行追記で Req 5.4 を満たす）
- `--reinstall-symlink` 分岐は `cmd_init` 冒頭の早期 return で実装。追加サブコマンド・追加モジュールは不要
- helper 戻り値は既存 report dict 拡張パターンを踏襲（`{"symlink": str}` のみ返却、例外は raise）

### 7.4 R1-R10 の design 判断

| ID | 判断 | 根拠 |
|----|------|------|
| R1 | **`tests/test_rw_light.py` → `tests/test_rw_cli.py` rename**（git mv で履歴保持） | 内部 import を `rw_cli` に変える以上、ファイル名整合も必要。Boundary 内として扱う |
| R2 | **scripts/*.py docstring 内 rw_light 言及 8 箇所全て rename**（historical 記述には「現 rw_cli.py」補注追加） | 現役の依存関係説明の正確性維持。historical 記述 1 箇所（`rw_query.py:4`）も補注形で整合化 |
| R3 | **`.kiro/steering/roadmap.md` は本スペック Scope 外**（別 spec で steering 全体見直し時に対処） | roadmap.md は module-split 以前の旧計画記述を多数含む historical document。本スペック適用で矛盾するが、部分更新は整合性悪化を招くため、別 spec で一括更新が適切 |
| R4 | **`README.md` 更新対象、`CHANGELOG.md` historical 保持** | README は全て現役手順/構造図。CHANGELOG は変更履歴エントリ (L131) で historical 性質 |
| R5 | **`docs/CLAUDE.md` を Req 6.1 対象に明示化**、ルート `CLAUDE.md` は current 対象として更新 | 両方とも現役ドキュメント |
| R6 | **`--reinstall-symlink` + `--force` 併用時は警告出力のうえ `--reinstall-symlink` を優先**（エラーにしない） | backward compatibility 配慮、symlink のみ張り替え用途が優先される明確なセマンティクス |
| R7 | **`add_help=False` のまま維持** | 既存カスタム `print_usage` 挙動保全 (Req 2.1)、argparse 自動 help を有効化すると既存 usage 出力が変化するリスク |
| R8 | **`.claude/settings.local.json` の 6 箇所は実装時に grep 再確認、permission 文字列内の参照なら機械置換、それ以外は個別判断** | 設定ファイル性質上、design で断定せず実装時判断 |
| R9 | **module-split `requirements.md` Req 6.1 原文は不変**（historical 保持原則、Req 6.3 継承） | requirements 完了済み spec 本文への補注追加は spec 本文汚染。本 research.md で参照継承を記録 |
| R10 | **保留 C (Req 2.3 `main()` 位置 AC) / 保留 D (Req 3.3 residual symbol 列挙) ともに現状維持** | C: 外部呼び出し契約として残しても害なし。D: `print_usage`/`main` は monkeypatch 対象になりにくく、AC 3.4 の包括表現で網羅 |

### 7.5 最終スコープ境界

- **In scope (確定)**: `scripts/rw_light.py` → `scripts/rw_cli.py` rename、`rw_light.py` 内自己言及 3 箇所、`_install_rw_symlink` helper 抽出、`cmd_init` の `--reinstall-symlink` フラグ追加 + 早期 return 分岐、`print_usage` 更新、scripts/*.py docstring 8 箇所、tests/ 141 箇所（`test_rw_light.py` ファイル名リネーム含む）、conftest.py mock_templates fixture、docs/user-guide.md / docs/developer-guide.md / docs/CLAUDE.md / CLAUDE.md / templates/CLAUDE.md、README.md、.kiro/steering/structure.md / tech.md、**`test_init.py` への `--reinstall-symlink` 新規テスト 3 件**
- **Out of scope (確定)**: `.kiro/steering/roadmap.md`, `CHANGELOG.md`, 過去 spec 本文（module-split Req 6.1 含む）, TODO_NEXT_SESSION.md, git commit メッセージ
- **要実装時判断**: `.claude/settings.local.json` (R8)

---

## 8. Design Review 対応履歴（2026-04-21）

`/kiro-validate-design rw-light-rename` による review で検出された 3 件の Critical Issue に対する対応記録:

### 8.1 Issue 1: `--reinstall-symlink` 自動テストカバレッジ欠如 → 推奨案 (A) 採択

**問題**: design 初版では「手動検証 + 後続 spec で補強」戦略を採用したが、これは新機能の CI 保護欠如と後続 spec 塩漬けリスクを抱える。root cause は Req 3.1「642 厳密同数」制約が新機能テスト追加を禁じていた点。

**対応**: **推奨案 (A) Req 3.1 緩和 + 本スペック内でテスト 3 件追加** を採択:
- `requirements.md` Req 3.1 を「現行件数以上」に緩和、`--reinstall-symlink` 関連の新規テスト追加を許容
- `requirements.md` Boundary Context の Out of scope から「テストロジックの変更」を「既存テストの論理変更」に限定、Req 5 関連の新規テスト追加を In scope に追加
- `design.md` Testing Strategy に新規テスト 3 件を明記 (`test_cmd_init_reinstall_symlink_on_existing_vault`, `test_cmd_init_reinstall_symlink_rejects_non_vault`, `test_cmd_init_reinstall_symlink_with_force_warns`)
- 期待件数を **642 → 645 collected（644 passed + 1 skipped）** に更新

**理由**: Req 3.1 の本来目的（既存テストの論理変更防止）は保てる。新規追加テストは既存テストを変更しないため backward-compatible。手動検証+後続 spec の運用オーバーヘッドを排除できる。

### 8.2 Issue 2: rename と内部自己言及更新の原子性が Migration Strategy で不明瞭

**問題**: Migration Strategy 初版 step 1 (git mv) と step 2 (内部自己言及更新) を分離すると、中間状態で `cmd_init` が壊れる（L580 の `"scripts/rw_light.py"` リテラルが FileNotFoundError を引き起こす）。

**対応**: Migration Strategy を再編し、初版 step 1-2 + step 4 (tests 一括置換) + conftest 更新 + 新規テスト追加を **「バッチ A: rename + コード同期更新」として原子的に実施する 1 step** に統合。"Why step 1 is a batch" セクションで依存理由を明示。

### 8.3 Issue 3: `conftest.py mock_templates` 更新と `cmd_init` symlink source path 更新の同期

**問題**: 初版で step 2（`cmd_init` の `rw_src = rw_cli.py`）と step 4（conftest.py ダミー名変更）が別 step だったため、step 2 完了時点で test_init.py が赤になる。

**対応**: Issue 2 と同じくバッチ A に統合して解決。conftest.py mock_templates fixture の更新は step 1 内で rw_cli.py 内部更新と同時実施。

### 8.4 review 後の Migration Strategy 新構成

```
Step 1: バッチ A（原子的・1 コミット推奨）
  ├ git mv scripts/rw_light.py → rw_cli.py
  ├ git mv tests/test_rw_light.py → test_rw_cli.py
  ├ rw_cli.py 内部自己言及 3 箇所更新
  ├ _install_rw_symlink 抽出 / cmd_init 分岐 / print_usage 更新
  ├ test_init.py に新規テスト 3 件追加
  ├ tests/ 内 141 箇所の rw_light → rw_cli 一括置換
  └ conftest.py::mock_templates ダミー名更新
  → pytest 期待値: 644 passed + 1 skipped
Step 2: scripts/ 他モジュール docstring 8 箇所更新
Step 3: docs / templates / README 更新
Step 4: .kiro/steering/structure.md + tech.md 更新
Step 5: 最終検証（pytest + grep + 手動検証）
```

### 8.5 Design Review 後の最終 GO 判定

Issue 1 推奨案採択 + Issue 2/3 design repair で全 Critical Issue が解消。Final Assessment は **無条件 GO**。
