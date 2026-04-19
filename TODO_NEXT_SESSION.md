# TODO_NEXT_SESSION.md

_作成: 2026-04-19 — セッション継続用ハンドオフ_

---

## 現在の状態サマリー

**プロジェクト**: Rwiki — AI 支援ナレッジベース構築システム  
**ブランチ**: `main`（リモートと同期済み）  
**全テスト**: 538 passed ✅

### 完了済みスペック（全件）

| スペック | 内容 | 状態 |
|---------|------|------|
| project-foundation | `rw init` コマンド・Vault 初期化・CLAUDE.md カーネル | ✅ 完了 |
| agents-system | AGENTS/ サブプロンプト体系（9 タスク） | ✅ 完了 |
| cli-query | query_answer / query_extract / query_fix コマンド | ✅ 完了 |
| cli-audit | audit（micro/weekly/monthly/quarterly）コマンド | ✅ 完了 |
| test-suite | 全コマンドのテスト体系（538 テスト） | ✅ 完了 |

### 主要成果物

- `scripts/rw_light.py` — 3,490 行のモノリシック CLI（全コマンド実装済み）
- `tests/` — 10 ファイル（conftest.py + 9 テストファイル）
- `templates/AGENTS/` — 9 タスク用プロンプト + README
- `docs/` — user-guide.md, developer-guide.md, audit.md 等
- `README.md` — 全コマンドリファレンス更新済み
- `CHANGELOG.md` — Keep a Changelog フォーマット

---

## 次のセッションで検討すべき事項

### Technical Debt（roadmap.md に記録済み）

1. **Severity 体系の既存コマンド統一**  
   - cli-audit は ERROR/WARN/INFO 3 水準、既存 `rw lint` は PASS/WARN/FAIL  
   - 統一は将来の別スペックで対応予定

2. **exit 1 セマンティクス分離**  
   - 現状: exit 1 = ランタイムエラー & FAIL 検出の両方  
   - CI 統合が必要になったタイミングで exit 1（エラー）/ exit 2（FAIL）に分離

3. **rw_light.py のモジュール分割**  
   - 3,490 行（保守限界目安 3,000 行を超過）  
   - 新規スペック追加時に検討。自然な分割境界:  
     - `rw_utils.py` / `rw_prompt_engine.py` / `rw_audit.py` / `rw_query.py`

4. **call_claude() タイムアウト**  
   - cli-audit で `timeout` パラメータ追加済み（audit=300秒）  
   - 他コマンドへの適用は任意

### 次期スペック候補（Roadmap 外・未着手）

- CI/CD 統合（GitHub Actions 等）
- マルチユーザー対応
- Obsidian Vault 設定との統合
- qmd / Zotero 連携

---

## セッション再開手順

```bash
# 1. プロジェクトに移動
cd /Users/Daily/Development/Rwiki-dev

# 2. 現在の状態確認
git log --oneline -5
python -m pytest tests/ -q

# 3. ステアリング確認（AI コンテキスト用）
# /kiro-steering  ← Sync モードで最新状態を確認

# 4. スペック状況確認
# /kiro-spec-status <feature-name>
```

---

## このセッションで実施した作業

- `/kiro-steering` — Sync モード実行
  - `structure.md`: テスト構成（単一→マルチファイル）+ `developer-guide.md` 追記
  - `tech.md`: テストファイル記述を `test_*.py` マルチファイル構成に更新

---
_このファイルはセッション開始時に削除またはアーカイブして構いません_
