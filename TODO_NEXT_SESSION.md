# TODO_NEXT_SESSION.md

_更新: 2026-04-20 — module-split spec 承認完了、実装フェーズ待ち_

---

## 現在の状態サマリー

**プロジェクト**: Rwiki — AI 支援ナレッジベース構築システム
**ブランチ**: `main`（プッシュ済み、`origin/main` と同期、最新コミット `cb088bb`）
**全テスト**: 642+ passed（severity-unification 完了時点で確認済み）
**実施中スペック**: `module-split`（**3 承認完了、`implementation-ready`**）
**次のアクション**: `/kiro-impl module-split` で autonomous 実装フェーズ開始

---

## 進行中スペック: module-split

### 目的
`scripts/rw_light.py`（現 3,827 行）を 6 モジュールに分割する純粋リファクタリング。CLI 外部動作・テスト結果・公開 API は完全不変を維持。

### 分割構成（DAG）

```
rw_config (定数のみ、~100 行)
    ↓
rw_utils (汎用ユーティリティ、~400 行)
    ↓
rw_prompt_engine (Claude 呼び出し + プロンプト構築、~600 行)
    ↓
rw_audit (audit コマンド群、~1,470 行 ⚠️ 1,500 行制限ギリギリ)
rw_query (query コマンド群、~820 行)
    ↓
rw_light (残存コマンド + main()、~700 行)
```

### 成果物（すべて承認済み）

| ファイル | 状態 |
|---------|------|
| `.kiro/specs/module-split/requirements.md` | ✅ approved（6 要件、18 numeric AC、AC 1.3 は re-export 禁止） |
| `.kiro/specs/module-split/design.md` | ✅ approved（732 行、Option B + Option X 版） |
| `.kiro/specs/module-split/research.md` | ✅ 最新化済み（Option B 確定 decision block 記録） |
| `.kiro/specs/module-split/tasks.md` | ✅ approved（211 行、13 sub-tasks、6 Phase 構成） |
| `.kiro/specs/module-split/spec.json` | `phase: implementation-ready`、全 approvals: true |

### 重要な設計判断（確定版）

1. **モジュール修飾参照規約**: 全パッチ対象シンボルは `<module>.<symbol>` 形式で参照（`from X import Y` 禁止）。Req 3.2 / Req 4 の monkeypatch 即時反映を保証。
2. **`read_all_wiki_content` は `rw_prompt_engine` に配置**（Req 4.5 設計判断）。
3. **Option B — 後方互換 re-export ゼロ**（Req 1.3）。AC 1.3 再評価で外部運用スクリプト実在なしを確認、Fundamental review で Facade+Proxy 構造的負債を回避。テスト側は `rw_light.<symbol>` 直接アクセスのコード行を `rw_<module>.<symbol>` 形式に機械置換。
4. **Option X — docstring / コメント言及は書き換え対象外**。pytest 動作に影響しないため、Phase 5 完了後の docs 同期 Follow-up で `docs/developer-guide.md` + `tests/conftest.py` L231/L18/L55 等を一括更新。
5. **rw_audit は 1,500 行制限に余裕 ~30 行**: 超過時は本スペック内で吸収せず、フォローアップスペックで `rw_audit_checks.py` 分離を検討。Phase 4a 完了時に `wc -l scripts/rw_audit.py` で行数検証を必須化。

### Migration Strategy（Phase 構成）

| Phase | コード変更 | テスト変更 | 完了条件 |
|-------|------------|------------|----------|
| 1 | `rw_config.py` 作成、全定数移動 | `conftest.py` patch_constants 更新 + `rw_light.<UPPER>` 直接アクセス書き換え | pytest green |
| 2 | `rw_utils.py` 作成、ユーティリティ移動 | test_approve/test_ingest/test_synthesize_logs の utils patch 更新 + `rw_light.<utility>` 直接アクセス書き換え | pytest green |
| 3 | `rw_prompt_engine.py` 作成（**re-export 一切なし — Req 1.3**） | 該当 patch を `rw_prompt_engine` に更新 + `rw_light.call_claude` 含む直接アクセス **12 件**書き換え（docstring L231 除外） | pytest green |
| 4a | `rw_audit.py` 作成、Finding/WikiPage/severity 関数も移動 | audit 系 patch を `rw_audit` に更新 + 直接アクセス書き換え | pytest green + **`wc -l rw_audit.py` ≤ 1,500** |
| 4b | `rw_query.py` 作成、`_strip_code_block` 含む | query 系 patch を `rw_query` に更新 + 直接アクセス書き換え | pytest green |
| 5 | `rw_light.py` 最終スリム化 | 残存参照・re-export 不在の最終検証 | 642+ green + usage 表示 + symlink smoke |

### テスト書き換え対象

- **monkeypatch 先更新**: ~520 件（conftest.py 17 / test_rw_light.py ~425 / test_audit.py ~57 / test_approve.py ~15 / test_synthesize_logs.py ~20 / test_ingest.py 15）
- **直接アクセス書き換え（コード行のみ）**: ~296 件（test_rw_light.py 208 / test_utils.py 28 / test_audit.py 23 / test_lint_query.py 22 / test_git_ops.py 7 / conftest.py 2 / test_init.py 2 / test_lint.py 2 / test_conftest_fixtures.py 2）
- **docstring 言及**: 3 件（conftest.py L18/L55/L231 等）は書き換え対象外、Phase 5 完了後の docs 同期 Follow-up で処理
- **合計書き換え**: 約 800 件強（各 Phase X.2 で当該 Phase の移動シンボルに対応する箇所のみを段階的に書き換え）

---

## セッション再開手順

```bash
cd /Users/Daily/Development/Rwiki-dev

# 状態確認
git log --oneline -5
cat .kiro/specs/module-split/spec.json  # phase: implementation-ready を確認
```

### 実装開始

```bash
# autonomous mode（推奨）— 全 Phase を subagent 経由で自動実装 + 独立レビュー + 最終 validation
/kiro-impl module-split

# 特定タスクのみ実装する場合
/kiro-impl module-split 1.1,1.2
```

### 実装中のゲート

- 各 Phase X.2 完了時に `pytest tests/` で 642 件以上 green を必須化
- Phase 4a 完了時は追加で `wc -l scripts/rw_audit.py ≤ 1,500` を検証
- 中間 FAIL 状態を main に merge しない（Phase ごとに green 復帰してから次 Phase）

### 実装完了後の Follow-up Obligations

1. `docs/developer-guide.md` L188-190 の呼び出し経路表を更新
   - `rw_light.call_claude` → `rw_prompt_engine.call_claude`
   - `rw_light.call_claude_for_log_synthesis` → `rw_prompt_engine.call_claude_for_log_synthesis`
2. `tests/conftest.py` 内の docstring 例示を更新
   - L18 `rw_light.VAULT_DIRS` → `rw_config.VAULT_DIRS`
   - L55 `rw_light.today` → `rw_utils.today`
   - L231 `rw_light.call_claude("prompt")` → `rw_prompt_engine.call_claude("prompt")`
   - L78/L96/L120/L126 等の説明的 docstring も必要に応じて同期
3. `/kiro-steering` を実行して `.kiro/steering/structure.md` の「モノリシック CLI」「単一ファイル集約」記述を 6 モジュール構成に更新

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
| module-split | ✅ 3 承認完了、実装待ち |

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

### 直近セッションの経緯（参考）

1. **Option B 確定** — AC 1.3 再評価で外部運用スクリプト実在なしを grep 確認 → Facade+Proxy 構造的負債を回避するため網羅 re-export（Option A）を却下
2. **Option X 確定** — docstring 書き換え方針の内部矛盾（tasks.md 原則 vs 具体アクション）を検出し、「docstring は書き換え対象外、Follow-up で docs 同期時に一括更新」に一本化
3. **requirements.md L9 修正** — 「テストファイル 13 件」を実測値 12 件に訂正
4. **再承認完了** — 3 approvals を true に更新、phase を `implementation-ready` に進行
5. **コミット `cb088bb`** — Option X 確定 + 再承認をリモートへ push

---

_このファイルはセッション開始時に削除またはアーカイブして構いません_
