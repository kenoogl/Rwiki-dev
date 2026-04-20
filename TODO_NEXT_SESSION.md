# TODO_NEXT_SESSION.md

_更新: 2026-04-21 — module-split spec 設計承認後のハンドオフ_

---

## 現在の状態サマリー

**プロジェクト**: Rwiki — AI 支援ナレッジベース構築システム
**ブランチ**: `main`（プッシュ済み、`origin/main` と同期）
**全テスト**: 642+ passed（severity-unification 完了時点で確認済み）
**実施中スペック**: `module-split`（Phase 1: 設計承認完了、Phase 2: タスク生成待ち）

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

### 承認済み成果物

| ファイル | 状態 |
|---------|------|
| `.kiro/specs/module-split/requirements.md` | ✅ 承認済み（6 要件、18 numeric AC） |
| `.kiro/specs/module-split/design.md` | ✅ 承認済み（698 行、5 レビュー round 経過） |
| `.kiro/specs/module-split/research.md` | ✅ 調査ログ + 4 設計判断を記録 |
| `.kiro/specs/module-split/spec.json` | `phase: design-approved` |
| `.kiro/specs/module-split/tasks.md` | ❌ 未生成（次セッションで生成） |

### 重要な設計判断

1. **モジュール修飾参照規約**: 全パッチ対象シンボルは `<module>.<symbol>` 形式で参照（`from X import Y` 禁止）。Req 3.2 / Req 4 の monkeypatch 即時反映を保証。
2. **`read_all_wiki_content` は `rw_prompt_engine` に配置**（Req 4.5 設計判断）。
3. **後方互換 re-export は Phase 3 で追加**（Phase 5 まで遅延すると Req 1.3 中間状態違反）。
4. **rw_audit は 1,500 行制限に余裕 ~30 行**: 超過時は本スペック内で吸収せず、フォローアップスペックで `rw_audit_checks.py` 分離を検討。Phase 4a 完了時に `wc -l scripts/rw_audit.py` で行数検証を必須化。

### Migration Strategy（Phase 構成）

| Phase | コード変更 | テスト変更 | 完了条件 |
|-------|------------|------------|----------|
| 1 | `rw_config.py` 作成、全定数移動 | `conftest.py` patch_constants 更新 | pytest green |
| 2 | `rw_utils.py` 作成、ユーティリティ移動 | test_approve/test_ingest/test_synthesize_logs の utils patch 更新 | pytest green |
| 3 | `rw_prompt_engine.py` 作成 + **rw_light に re-export 追加** | 該当 patch を `rw_prompt_engine` に更新 | pytest green |
| 4a | `rw_audit.py` 作成、Finding/WikiPage/severity 関数も移動 | audit 系 patch を `rw_audit` に更新 | pytest green + **`wc -l rw_audit.py` ≤ 1,500** |
| 4b | `rw_query.py` 作成、`_strip_code_block` 含む | query 系 patch を `rw_query` に更新 | pytest green |
| 5 | `rw_light.py` 最終スリム化 | 残存参照の整合性確認 | 642+ green + usage 表示確認 |

### テスト patch 更新対象（約 549 件）

- `tests/conftest.py`: 17 件（`patch_constants` fixture）
- `tests/test_rw_light.py`: ~425 件（最多、全 4 モジュールを跨ぐ、severity 関連 7 件含む）
- `tests/test_audit.py`: ~57 件（severity 関連 17 件含む）
- `tests/test_approve.py`: ~15 件
- `tests/test_synthesize_logs.py`: ~20 件
- `tests/test_ingest.py`: 15 件（`shutil.move` パッチは更新不要）

---

## セッション再開手順

```bash
cd /Users/Daily/Development/Rwiki-dev

# 状態確認
git log --oneline -5
cat .kiro/specs/module-split/spec.json

# タスク生成フェーズ実行
# /kiro-spec-tasks module-split
# または auto-approve 版: /kiro-spec-tasks module-split -y
```

### タスク生成後の流れ

1. `tasks.md` が生成される（上記 Phase 構成をベースにタスク分解）
2. 内容レビュー → 承認
3. `/kiro-impl module-split` で実装フェーズ開始（Phase 1 から autonomous mode）

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
| module-split | 🔄 設計承認済み、タスク生成待ち |

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
