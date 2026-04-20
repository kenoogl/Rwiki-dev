# TODO_NEXT_SESSION.md

_更新: 2026-04-20 — severity-unification P1 完了後のハンドオフ_

---

## 現在の状態サマリー

**プロジェクト**: Rwiki — AI 支援ナレッジベース構築システム  
**ブランチ**: `main`（未プッシュの P1 コミット 10 件あり）  
**全テスト**: 579 passed ✅  
**実施中スペック**: `severity-unification`

---

## 進行中スペック: severity-unification

### P1 完了（全 10 タスク ✓）

| タスク | 内容 | コミット |
|-------|------|---------|
| 1.1 | conftest fixtures + pytest markers | `87c58d9` |
| 1.2 | `_normalize_severity_token` helper TDD | `c94235d` |
| 1.3 | `_validate_agents_severity_vocabulary` TDD | `eee4bb4` |
| 1.4 | Vault validation hook + escape hatch + prompt prefix | `3004fd9` |
| 1.5 | `AGENTS/audit.md` severity rename (HIGH→ERROR 等) | `eed77b4` |
| 1.6 | Finding sub_severity フィールド廃止 | `7c89fce` |
| 1.7 | `map_severity()` 全廃 + `_normalize_severity_token` 置換 | `102da99` |
| 1.8 | `parse_audit_response` 4 段構造検証 + silent skip 廃止 | `fd02555` |
| 1.9 | `rw init --force` 実装（backup + symlink防御 + collision fallback） | `a412ad3` |
| 1.10 | P1 atomic 完了ゲート確認 | `723bf5b` |

### P2 開始待ち（status 2 値化 + exit code 3 値分離）

次のセッションでは **P2 から `/kiro-impl severity-unification` を再実行**。

P2 の全タスク（未着手）:
- `[ ] 2.1` `_compute_run_status(findings)` helper TDD（依存: なし）
- `[ ] 2.2` `_compute_exit_code(status, had_runtime_error)` helper TDD（依存: なし）
- `[ ] 2.3 (P)` `templates/AGENTS/lint.md` status/exit code 記述更新（依存: なし）
- `[ ] 2.4` `cmd_lint` JSON schema 更新（依存: 2.1）
- `[ ] 2.5` `cmd_lint` stdout 表示更新（依存: 2.1）
- `[ ] 2.6` `cmd_lint_query` JSON schema 更新（依存: 2.1）
- `[ ] 2.7` `cmd_lint_query` stdout 更新（依存: 2.1）
- `[ ] 2.8` `cmd_audit_*` status 計算 + CRITICAL 可視化（依存: 2.1）
- `[ ] 2.9` `cmd_lint` / `cmd_audit_*` の FAIL → exit 2 移行（依存: 2.2）
- `[ ] 2.10` `cmd_lint_query` 旧 exit 3/4 → exit 1 統合（依存: 2.2）
- `[ ] 2.11` `cmd_ingest` precondition failure exit 1 維持 + WARN 除去（依存: 2.2）
- `[ ] 2.12` `cmd_query_extract` / `cmd_query_fix` exit code 整合（依存: 2.2）
- `[ ] 2.13` P2 完了ゲート（依存: 2.4〜2.12）

### P3 残タスク（P2 後）
11 タスク（3.1〜3.11）— ドキュメント・隣接 spec 同期・静的スキャン・smoke test

---

## セッション再開手順

```bash
cd /Users/Daily/Development/Rwiki-dev

# 状態確認
git log --oneline -5
python -m pytest tests/ -m "not slow" -q

# P2 実装開始（autonomous mode）
# /kiro-impl severity-unification
```

> **注意**: `/kiro-impl` は tasks.md の未完了タスクを自動検出して P2 から開始する。

---

## 未コミット変更

- `.kiro/steering/tech.md` — Prompt Engine 方針の記述追加（steering sync 由来、実装と無関係）
  → 次セッション冒頭で `git add .kiro/steering/tech.md && git commit -m "chore(steering): Prompt Engine 単一ソース原則を tech.md に追記"` で処理

---

## P1 で新設・変更した主要関数（P2 実装者向け参照）

| 関数 | 場所 | 目的 |
|-----|------|-----|
| `_VALID_SEVERITIES` | rw_light.py:1718 | `{"CRITICAL","ERROR","WARN","INFO"}` 定数 |
| `_normalize_severity_token()` | rw_light.py:1721 | severity token 正規化 + drift 記録 |
| `_validate_agents_severity_vocabulary()` | rw_light.py:1798 | Vault AGENTS/audit.md の旧語彙検出 |
| `parse_audit_response()` | rw_light.py:2034 | 4 段構造検証 + severity coerce |
| `build_audit_prompt()` | (updated) | Severity Vocabulary (STRICT) prefix 付き |
| `load_task_prompts()` | (updated) | `skip_vault_validation` kwarg 追加 |
| `cmd_init --force` | (updated) | AGENTS/ 再デプロイ + .backup/ 退避 |

P2 で追加予定:
- `_compute_run_status(findings) -> str`
- `_compute_exit_code(status, had_runtime_error) -> int`

---

## 既存スペック（完了済み）

| スペック | 状態 |
|---------|------|
| project-foundation | ✅ |
| agents-system | ✅ |
| cli-query | ✅ |
| cli-audit | ✅ |
| test-suite | ✅ |
| severity-unification | 🔄 P1 完了、P2 待ち |

---

_このファイルはセッション開始時に削除またはアーカイブして構いません_
