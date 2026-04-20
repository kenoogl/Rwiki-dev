# TODO_NEXT_SESSION.md

_更新: 2026-04-20 — rw-light-rename スペック requirements-generated 状態、承認 + design 着手待ち_

---

## 現在の状態サマリー

**プロジェクト**: Rwiki — AI 支援ナレッジベース構築システム
**ブランチ**: `main`（プッシュ済み、`origin/main` と同期、最新コミット `23bad66`）
**全テスト**: 641 passed + 1 skipped = 642 collected（module-split 完了時点から維持）
**実施中スペック**: `rw-light-rename`（**requirements-generated、承認 + design 着手待ち**）
**次のアクション**: requirements.md をレビュー → 承認 → `/kiro-spec-design rw-light-rename` で design フェーズへ

---

## 進行中スペック: rw-light-rename

### 目的
module-split 完了後に意味を失った `scripts/rw_light.py` の名前を責務に合う `scripts/rw_cli.py` へ rename する純粋な命名整合リファクタリング。`light` 接頭辞は pre-split 時代の「軽量単一ファイル CLI」を示すが、現在の実態は CLI エントリポイント + argparse dispatcher + 残留コマンド (`cmd_lint` / `cmd_ingest` / `cmd_synthesize_logs` / `cmd_approve` / `cmd_init`) のホスト。他 5 モジュール (`rw_config` / `rw_utils` / `rw_prompt_engine` / `rw_audit` / `rw_query`) と同じ `rw_<責務>.py` 命名パターンに合わせる。

### スコープ（Req 1 で確定）
1. `git mv scripts/rw_light.py scripts/rw_cli.py`（history 連続性保持）
2. `cmd_init` の symlink 作成ターゲット更新（新規 Vault に `rw → rw_cli.py`）
3. テスト側 ~500 件の `import rw_light` / `monkeypatch.setattr(rw_light, ...)` / `rw_light.<residual>` 直接アクセスを `rw_cli` 参照に機械置換
4. `docs/user-guide.md` / `docs/developer-guide.md` / `CLAUDE.md` / `templates/` 配下テンプレート / `.kiro/steering/structure.md` + `tech.md` の参照更新
5. 既存 Vault マイグレーションヘルパ: `rw init --reinstall-symlink` サブフラグ追加（既存 symlink 検出 → 削除 → 再作成、通常初期化処理はスキップ）
6. `rw_light.py` は bridge / proxy として残さず完全削除（Req 1.3 re-export ゼロ方針を継承）

### 成果物（requirements-generated 状態）

| ファイル | 状態 |
|---------|------|
| `.kiro/specs/rw-light-rename/spec.json` | `phase: requirements-generated`, `approvals.requirements.generated: true`, `approved: false` |
| `.kiro/specs/rw-light-rename/requirements.md` | 6 要件 / 21 AC ドラフト、A/B/E レビュー対処済み |

### 要件サマリ（6 要件）

| Req | タイトル | AC 数 |
|-----|----------|-------|
| 1 | ファイル名と参照先の整合（rw_cli.py 存在、rw_light.py 不在、git 履歴連続性、bridge ファイル不在） | 3 |
| 2 | CLI 外部動作の不変性（usage 不変、サブコマンド挙動不変、main() エクスポート不変） | 3 |
| 3 | テスト整合性と継続グリーン（641 + 1 skipped 維持、import 0、patch 対象 rw_cli、直接アクセス書き換え、rw_light.shutil.move 置換、mock_templates ダミーファイル更新） | 6 |
| 4 | 新規 Vault 初期化時の symlink ターゲット整合（`rw → rw_cli.py` 作成、symlink 経由起動で usage 表示） | 2 |
| 5 | 既存 Vault マイグレーションヘルパ（`rw init --reinstall-symlink` による symlink 検出・再作成、通常初期化スキップ、非 Vault エラー exit 1、--help 記載） | 4 |
| 6 | ドキュメント・steering 参照整合（docs/templates/CLAUDE.md/steering の rw_cli 更新、歴史性保持、module-split Req 6.1 言及の扱いは design 判断） | 3 |

### レビュー対処（完了）

- **A (Req 5.2 語順)**: 日本語語順破綻「shall skip X を行い」→ "shall skip X and execute Y" に英語 EARS で明確化
- **B (Req 5.3 exit code)**: severity-unification 契約との矛盾 exit 2 → exit 1 (runtime error) に修正
- **E (`templates/` 参照整合)**: In scope に `templates/` 配下と `mock_templates` fixture ダミーファイルを追加、Req 3.6 を新規追加、Req 6.1 に `templates/` を追加

### レビュー保留事項（2 件、design / tasks フェーズで再評価可能）

- **C (Req 2.3)**: `main()` 位置指定が過剰仕様の可能性。外部 API 契約として削除可能だが残しても害なし
- **D (Req 3.3)**: residual symbol 列挙に `print_usage` / `main` が漏れているが、monkeypatch される可能性は低く影響軽微

---

## セッション再開手順

```bash
cd /Users/Daily/Development/Rwiki-dev

# 状態確認
git log --oneline -5
cat .kiro/specs/rw-light-rename/spec.json  # phase: requirements-generated
cat .kiro/specs/rw-light-rename/requirements.md  # 要件レビュー
```

### 次のアクション（優先順）

**Step 1: Requirements 承認**

ユーザが requirements.md を確認し、追加修正なければ承認。`spec.json` の `approvals.requirements.approved` を手動で `true` にするか、次の `-y` オプションで自動承認。

**Step 2: Design フェーズへ**

Brownfield (既存コードベース) のため、optional でギャップ分析を先行:

```bash
/kiro-validate-gap rw-light-rename  # 既存 cmd_init との統合ポイント分析
```

その後 design:

```bash
/kiro-spec-design rw-light-rename     # 承認確認あり
# または
/kiro-spec-design rw-light-rename -y  # requirements 承認も自動化
```

### Design フェーズで判断するポイント

1. **Req 6.3**: `.kiro/specs/module-split/requirements.md` Req 6.1 の `scripts/rw_light.py` 言及の扱い（原文編集 / 補注追加 / 不変）
2. **保留 C**: Req 2.3 `main()` 位置指定 AC を削除するか
3. **保留 D**: Req 3.3 の residual symbol 列挙に `print_usage` / `main` を明示追加するか、包括表現化するか
4. **`--reinstall-symlink` の実装アプローチ**: argparse のサブフラグ実装詳細、既存 `rw init <path>` 引数との共存方法
5. **Phase 分割戦略**: module-split 同様に「コード rename → テスト patch 更新 → docs/steering 更新」の Phase 分割にするか、単一 Phase で完結させるか（module-split より変更規模が小さいので後者も現実的）

### 実装フェーズ（Design / Tasks 承認後）

```bash
/kiro-spec-tasks rw-light-rename      # tasks 生成
/kiro-impl rw-light-rename            # 自動実装（autonomous mode）
/kiro-validate-impl rw-light-rename   # 最終検証
```

---

## 完了済みスペック

| スペック | 状態 |
|---------|------|
| project-foundation | ✅ |
| agents-system | ✅ |
| cli-query | ✅ |
| cli-audit | ✅ |
| test-suite | ✅ |
| severity-unification | ✅ 全 P1/P2/P3 完了 |
| module-split | ✅ 全 13 タスク実装完了、Follow-up 3 件 (docs/conftest docstring/steering) 完了 |

---

## 参考: 前セッションからの経緯

### module-split Follow-up 完了

本セッションで module-split スペックの Follow-up Obligations を全て完了:
- **Item 1**: `docs/developer-guide.md` L188-190 の LLM モック対象を `rw_prompt_engine.*` に更新（commit `259b6b2`）
- **Item 2**: `tests/conftest.py` 7 箇所 + `tests/test_rw_light.py` 2 箇所の docstring/コメント言及を新モジュール参照に同期（commit `5a5df6c`）
- **Item 3**: `.kiro/steering/structure.md` + `tech.md` を 6 モジュール構成に同期（commit `23bad66`）

### rw-light-rename の起票背景

Item 3 完了直後、ユーザが `rw_light.py` のファイル名と実体の意味的乖離を指摘。検討の結果、Option B (破壊的変更 + `rw init --reinstall-symlink` サブフラグ) で別スペックを起票する方針で合意。既存 Vault 実体がないため破壊的変更を許容。feature name = `rw-light-rename`、new file name = `rw_cli.py` で確定。

### 決定事項

1. **Feature name**: `rw-light-rename`（後世に「`rw_light.py` の名前を変えた変更」と辿れる）
2. **新ファイル名**: `rw_cli.py`（他 5 モジュールとの `rw_` 接頭辞一貫性、責務明示）
3. **既存 Vault 互換性**: Option B（`rw init --reinstall-symlink` 提供、破壊的変更を許容）
4. **Re-export policy**: Req 1.3 (re-export ゼロ) 維持 — bridge ファイルは残さない
5. **pytest ゲート**: 641 passed + 1 skipped = 642 collected を維持（module-split 完了時と同値）

---

_このファイルはセッション開始時に削除またはアーカイブして構いません_
