# TODO_NEXT_SESSION.md

_更新: 2026-04-20 — module-split spec Option B（re-export ゼロ）確定、承認取消＆再承認待ち_

---

## 現在の状態サマリー

**プロジェクト**: Rwiki — AI 支援ナレッジベース構築システム
**ブランチ**: `main`（プッシュ済み、`origin/main` と同期）
**全テスト**: 642+ passed（severity-unification 完了時点で確認済み）
**実施中スペック**: `module-split`（requirements / design / tasks 生成済み、**3 承認すべて取消中**、Option B 方針で再承認待ち）

---

## 進行中スペック: module-split

### 目的
`scripts/rw_light.py`（現 3,827 行）を 6 モジュールに分割する純粋リファクタリング。CLI 外部動作・テスト結果・公開 API は完全不変を維持。

### 分割構成（DAG）

```
rw_config (定数のみ、~100 行)
    ↓
rw_utils (汎用ユーティリティ、~300 行)
    ↓
rw_prompt_engine (Claude 呼び出し + プロンプト構築、~600 行)
    ↓
rw_audit (audit コマンド群、~1,470 行 ⚠️ 1,500 行制限ギリギリ)
rw_query (query コマンド群、~820 行)
    ↓
rw_light (残存コマンド + main()、~720 行)
```

### 成果物（すべて生成済み、3 承認いずれも取消中）

| ファイル | 状態 |
|---------|------|
| `.kiro/specs/module-split/requirements.md` | 🔄 生成済み・再承認待ち（6 要件、18 numeric AC、AC 1.3 は re-export 禁止に改訂済み） |
| `.kiro/specs/module-split/design.md` | 🔄 生成済み・再承認待ち（732 行、Option B 純粋版に全面改訂済み） |
| `.kiro/specs/module-split/research.md` | ✅ 最新化済み（Option B 確定 decision section に更新） |
| `.kiro/specs/module-split/spec.json` | `phase: tasks-generated`、全 approvals: false |
| `.kiro/specs/module-split/tasks.md` | 🔄 生成済み・再承認待ち（211 行、13 sub-tasks、Option B 直接アクセス書き換え手順含む） |

### 重要な設計判断（Option B 確定後）

1. **モジュール修飾参照規約**: 全パッチ対象シンボルは `<module>.<symbol>` 形式で参照（`from X import Y` 禁止）。Req 3.2 / Req 4 の monkeypatch 即時反映を保証。
2. **`read_all_wiki_content` は `rw_prompt_engine` に配置**（Req 4.5 設計判断）。
3. **後方互換 re-export は一切提供しない**（Req 1.3、Option B 純粋版）。AC 1.3 再評価で外部運用スクリプト実在なしを確認、Fundamental review で Facade+Proxy 構造的負債を回避。テスト側は `rw_light.<symbol>` 直接アクセス ~299 件を各 Phase X.2 で `rw_<module>.<symbol>` 形式に機械置換する（patch 先更新 ~520 件と合わせ総書き換え 800 件超）。
4. **rw_audit は 1,500 行制限に余裕 ~30 行**: 超過時は本スペック内で吸収せず、フォローアップスペックで `rw_audit_checks.py` 分離を検討。Phase 4a 完了時に `wc -l scripts/rw_audit.py` で行数検証を必須化。

### Migration Strategy（Phase 構成 — Option B 版）

| Phase | コード変更 | テスト変更 | 完了条件 |
|-------|------------|------------|----------|
| 1 | `rw_config.py` 作成、全定数移動 | `conftest.py` patch_constants 更新 + `rw_light.<UPPER>` 直接アクセス書き換え | pytest green |
| 2 | `rw_utils.py` 作成、ユーティリティ移動 | test_approve/test_ingest/test_synthesize_logs の utils patch 更新 + `rw_light.<utility>` 直接アクセス書き換え | pytest green |
| 3 | `rw_prompt_engine.py` 作成（**re-export 一切なし — Req 1.3**） | 該当 patch を `rw_prompt_engine` に更新 + `rw_light.call_claude` 含む直接アクセス全 13 件書き換え | pytest green |
| 4a | `rw_audit.py` 作成、Finding/WikiPage/severity 関数も移動 | audit 系 patch を `rw_audit` に更新 + 直接アクセス書き換え | pytest green + **`wc -l rw_audit.py` ≤ 1,500** |
| 4b | `rw_query.py` 作成、`_strip_code_block` 含む | query 系 patch を `rw_query` に更新 + 直接アクセス書き換え | pytest green |
| 5 | `rw_light.py` 最終スリム化 | 残存参照・re-export 不在の最終検証 | 642+ green + usage 表示 + symlink smoke |

### テスト書き換え対象

- **monkeypatch 先更新**: ~520 件（conftest.py 17 / test_rw_light.py ~425 / test_audit.py ~57 / test_approve.py ~15 / test_synthesize_logs.py ~20 / test_ingest.py 15）
- **直接アクセス書き換え**: ~299 件（test_rw_light.py 208 / test_utils.py 28 / test_audit.py 23 / test_lint_query.py 22 / test_git_ops.py 7 / conftest.py 2 / test_init.py 2 / test_lint.py 2 / test_conftest_fixtures.py 2）
- **合計**: 約 800 件強（各 Phase X.2 で当該 Phase の移動シンボルに対応する箇所のみを段階的に書き換え）

---

## セッション再開手順

```bash
cd /Users/Daily/Development/Rwiki-dev

# 状態確認
git log --oneline -5
cat .kiro/specs/module-split/spec.json  # 全 approvals: false であることを確認
```

### 再承認手順

1. `.kiro/specs/module-split/requirements.md` を確認 → 承認（spec.json の `approvals.requirements.approved` を true に）
2. `.kiro/specs/module-split/design.md` を確認 → 承認（同上）
3. `.kiro/specs/module-split/tasks.md` を確認 → 承認（同上、`phase` を `implementation-ready` に進める）
4. `/kiro-impl module-split` で実装フェーズ開始（Phase 1 から autonomous mode）

---

## 未コミット変更

- `.claude/settings.local.json` — `Read(//tmp/**)` 権限追加（ローカル設定ノイズ、無関係）
  → 必要に応じて `git add .claude/settings.local.json && git commit -m "chore: allow /tmp read permission"`

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
| module-split | 🔄 requirements / design / tasks 生成済み、Option B（re-export ゼロ）で再承認待ち |

---

## 参考情報

### 実測関数サイズ（大型関数トップ 10）
- `cmd_query_extract`: 167 行（rw_query）
- `parse_audit_response`: 158 行（rw_audit）
- `build_audit_prompt`: 129 行（rw_audit）
- `_run_llm_audit`: 125 行（rw_audit）
- `cmd_query_fix`: 121 行（rw_query）
- `_validate_agents_severity_vocabulary`: 120 行（rw_prompt_engine）
- `generate_audit_report`: 118 行（rw_audit）
- `parse_agent_mapping`: 109 行（rw_prompt_engine）
- `build_query_prompt`: 108 行（rw_prompt_engine）
- `cmd_query_answer`: 99 行（rw_query）

### Follow-up Obligations（本スペック実装完了後）
- `/kiro-steering` を実行して `.kiro/steering/structure.md` の「モノリシック CLI」記述を更新（6 モジュール構成へ）

---

_このファイルはセッション開始時に削除またはアーカイブして構いません_
