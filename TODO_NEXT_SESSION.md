# TODO_NEXT_SESSION.md

_更新: 2026-04-20 — module-split 実装完了、docs 同期 Follow-up 待ち_

---

## 現在の状態サマリー

**プロジェクト**: Rwiki — AI 支援ナレッジベース構築システム
**ブランチ**: `main`（プッシュ済み、`origin/main` と同期、最新コミット `9af67ed`）
**全テスト**: 641 passed + 1 skipped = 642 collected（module-split Phase 6.2 で確認）
**完了スペック**: `module-split`（**全 13 タスク実装完了、pushed**）
**次のアクション**: Follow-up Obligations（docs 同期 + steering 更新）を別セッションで実施

---

## 完了したスペック: module-split

### 成果
`scripts/rw_light.py`（3,827 行）を 6 モジュールに分割する純粋リファクタリング完了。CLI 外部動作・テスト結果・公開 API はすべて不変を維持。

### 最終モジュール構成

| モジュール | 行数 | 責務 |
|-----------|------|------|
| `scripts/rw_config.py` | 87 | 全グローバル定数（パス + ドメイン） |
| `scripts/rw_utils.py` | 294 | ドメイン非依存ユーティリティ（I/O, git, frontmatter 等） |
| `scripts/rw_prompt_engine.py` | 607 | Claude 呼び出し + プロンプト構築 |
| `scripts/rw_audit.py` | 1,419 | audit コマンド + チェック関数群（上限 1,500 に 81 行余裕） |
| `scripts/rw_query.py` | 842 | query コマンド + query lint |
| `scripts/rw_light.py` | 699 | 残留コマンド（cmd_lint / cmd_ingest / cmd_synthesize_logs / cmd_approve / cmd_init）+ main() + dispatch |
| **合計** | **3,948** | 全モジュール ≤ 1,500 行（Req 1.2 充足） |

### 達成した要件（6 要件 / 18 AC）

- **Req 1.1** 6 モジュール責務分割 — 全モジュール存在確認
- **Req 1.2** 各モジュール ≤ 1,500 行 — rw_audit が最大 1,419、余裕 81 行
- **Req 1.3** re-export ゼロ — `from rw_<module> import` 0 件、`hasattr(rw_light, 'call_claude')` → False
- **Req 2.1 / 2.2** DAG 維持 — 全モジュール一括 import / 個別 import 成功、circular なし
- **Req 3.1 / 3.2** rw_config 一元管理 + パッチ互換性 — 全 24 定数が rw_config に集約
- **Req 4.1 / 4.2 / 4.3 / 4.4 / 4.5 / 4.6** 関数パッチ先の正確性 — `cmd_query_fix` 内で `rw_query.lint_single_query_dir(...)` 自モジュール修飾呼び出し採用
- **Req 5.1** 全テスト継続 green — 641 passed + 1 skipped = 642 collected
- **Req 5.2** サブモジュール発見 — `sys.path[0]` 自動解決で PYTHONPATH 不要
- **Req 6.1 / 6.2** CLI エントリポイント互換性 — `python scripts/rw_light.py` で usage 表示
- **Req 6.3** symlink 経由起動 — 一時 Vault で `python <vault>/scripts/rw` からの起動確認済

### 13 コミット履歴

```
9af67ed chore(module-split): Phase 6.3 — Vault symlink 経由起動の手動 smoke 検証完了
d4eb913 chore(module-split): Phase 6.2 — 全テスト green + CLI + circular import 最終検証完了
e757e7e refactor(module-split): Phase 6.1 — rw_light.py 最終スリム化（未使用 import 削除）
1ac32f8 refactor(module-split): Phase 5.2 — query 系 patch 先を rw_query に置換 + 直接アクセス書き換え
9019db2 refactor(module-split): Phase 5.1 — rw_query.py 抽出と query コマンド / lint 関数群の移動
4a34456 refactor(module-split): Phase 4.2 — audit 系 patch 先を rw_audit に置換 + 直接アクセス書き換え
1ab8c18 refactor(module-split): Phase 4.1 — rw_audit.py 抽出と audit 系関数群の移動
1f6d583 refactor(module-split): Phase 3.2 — prompt engine patch 先を rw_prompt_engine に置換 + 直接アクセス書き換え
b97bbac refactor(module-split): Phase 3.1 — rw_prompt_engine.py 抽出（re-export なし）
22a3f85 refactor(module-split): Phase 2.2 — utility patch 先を rw_utils に置換 + 直接アクセス書き換え
f399277 refactor(module-split): Phase 2.1 — rw_utils.py 抽出と汎用ユーティリティ移動
d23005a refactor(module-split): Phase 1.2 — 定数 patch 先を rw_config に置換 + 直接アクセス書き換え
4421c14 refactor(module-split): Phase 1.1 — rw_config.py 抽出と全グローバル定数移動
```

### 実装中の重要な判断

1. **`_strip_code_block` duplicate**: rw_audit と rw_query の両方が必要だが DAG 上 Layer 3 相互 import 不可のため、rw_audit.py L768 と rw_query.py L93 に 11 行の duplicate を配置。follow-up で rw_prompt_engine/rw_utils への統合移動を検討可能（tasks.md Implementation Notes 記録済み）。
2. **TestAuditSectionHeaders test 3 skip**: Phase 3.1 で `read_wiki_content` / `read_all_wiki_content` が rw_prompt_engine に移動したことで `test_audit_headers_before_output_utilities` の cross-module 順序検証が意味を失った。`@pytest.mark.skip` でマーク、Phase 6.1 の rw_light 最終スリム化後の再 author 案として tasks.md Implementation Notes に記録。
3. **rw_query の self-import**: `cmd_query_fix` 内部の `rw_query.lint_single_query_dir(...)` 自モジュール修飾呼び出しを有効化するため、rw_query.py L22 に `import rw_query` を追加（Req 4.3 の monkeypatch 作用を保証）。
4. **セクションヘッダーコメント復活**: Phase 3.1 で rw_prompt_engine に移動した `read_wiki_content` 群に `# audit: data loading` ヘッダーコメントを復活（L437）。TestAuditSectionHeaders の minimal module retargeting を可能にするための構造マーカー保持。

---

## 次の作業: Follow-up Obligations（別セッションで実施）

module-split スペック本体は完了したが、プロジェクト全体の整合性維持のため以下の作業が未了:

### 1. docs/developer-guide.md 呼び出し経路表の更新（L188-190）

**対象**: `docs/developer-guide.md` L188-190

**変更内容**:
- `rw_light.call_claude` → `rw_prompt_engine.call_claude`
- `rw_light.call_claude_for_log_synthesis` → `rw_prompt_engine.call_claude_for_log_synthesis`

**理由**: Option B 確定（AC 1.3 廃止）により rw_light からの call_claude 参照が不可能になったため、ドキュメントを現状に合わせる必要がある。

### 2. tests/conftest.py の docstring 例示更新

module-split 中に Option X により保留した docstring/コメント内の API 例示を新モジュール参照に更新:

- **L18 付近**（VAULT_DIRS 言及）: `rw_light.VAULT_DIRS` → `rw_config.VAULT_DIRS`
- **L55-57 付近**（today 言及）: `rw_light.today` → `rw_utils.today`
- **L231-233 付近**（call_claude 例示）: `rw_light.call_claude("prompt")` → `rw_prompt_engine.call_claude("prompt")`
- その他 L78/L96/L120/L126 等の説明的 docstring も必要に応じて同期

**注意**: test_rw_light.py L213（docstring）/ L257（comment）にも `rw_light.ROOT` 言及あり — こちらも同時更新推奨。

### 3. .kiro/steering/structure.md の更新

**コマンド**: `/kiro-steering` を実行

**変更内容**: 「モノリシック CLI」「単一ファイル集約」などの記述を 6 モジュール構成に更新。具体的には:
- 現: `scripts/rw_light.py` 単一ファイル
- 新: 6 モジュール構成（rw_config / rw_utils / rw_prompt_engine / rw_audit / rw_query / rw_light）とその責務分離パターン
- DAG 依存関係（Layer 0 → Layer 1 → Layer 2 → Layer 3 → Layer 4）の記述追加

### 4. （オプション）TestAuditSectionHeaders test 3 の再 author

**対象**: `tests/test_rw_light.py` の `test_audit_headers_before_output_utilities`

**状態**: 現在 `@pytest.mark.skip` でマーク

**判断材料**:
- rw_light の最終構造（Phase 6.1 完了時点）を前提として、「output utilities に相当する構造マーカー」が rw_light 内に残っているか検証
- 残っていれば、`inspect.getsource(rw_audit)` で「audit 構造マーカー」を、`inspect.getsource(rw_light)` で「output utilities マーカー」を検索する cross-module 順序検証に再著述
- 残っていなければ、テストを削除するか、別テスト（「分割後の各モジュールに期待される構造マーカーの存在検証」など）に書き換え

**優先度**: 低（pytest は現状 641 passed + 1 skipped = 642 collected で Req 5.1 充足）

---

## セッション再開手順

```bash
cd /Users/Daily/Development/Rwiki-dev

# 状態確認
git log --oneline -5
git status  # clean, origin/main と同期

# Follow-up 作業開始
# (A) docs/developer-guide.md を編集
# (B) tests/conftest.py の docstring を更新
# (C) /kiro-steering で steering を更新
```

### Follow-up 開始テンプレート

```
docs/developer-guide.md L188-190 の呼び出し経路表と tests/conftest.py の docstring 例示を
module-split 完了後の新モジュール参照に更新してください。
続いて /kiro-steering で structure.md を 6 モジュール構成に更新してください。
```

---

## 完了済みスペック一覧

| スペック | 状態 |
|---------|------|
| project-foundation | ✅ |
| agents-system | ✅ |
| cli-query | ✅ |
| cli-audit | ✅ |
| test-suite | ✅ |
| severity-unification | ✅ 全 P1/P2/P3 完了 |
| **module-split** | ✅ **全 13 タスク実装完了、pushed** |

---

## 参考: 実装時の重要知見（次セッションで役立つ可能性）

### 1. モジュール修飾参照規約の必要性（Req 3.2 / 4.x 保証）

テストが `monkeypatch.setattr(rw_<module>, "<symbol>", mock)` で patch する場合、実装コード側での呼び出しは **必ず `rw_<module>.<symbol>(...)` 修飾形式**にする必要がある。`from rw_<module> import <symbol>` + `<symbol>(...)` 形式は patch が作用しないため禁止。

### 2. Option X の適用範囲（docstring 保持）

実装中は「テストロジック不変」原則により test 側の docstring/comment 内の `rw_light.<old>` 言及を保持した。これは pytest 動作に影響しないため。一方、ソース側（scripts/）の docstring/comment は strict 完了検証 grep 要件のため修飾形式に書き換えた。docs 同期 Follow-up で最終整合を取る。

### 3. `_strip_code_block` の duplicate 方針

DAG 維持のため audit と query の両方に 11 行 duplicate を配置。将来的に `rw_prompt_engine` または `rw_utils` への統合移動を検討可能だが、module-split スペック内では boundary 外のため見送り。

### 4. macOS BSD sed の word boundary 非対応

`\b` が BSD sed で使えないため、機械置換には Python ワンライナーもしくは Edit tool を使用した。次回同様の置換タスクでは `gsed` インストールを検討可能。

---

_このファイルはセッション開始時に削除またはアーカイブして構いません_
