# Technology Stack

> 出典: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §1.5, §2, §3.4, §3.5

## Architecture

3 層 + 横断要素。詳細は `structure.md` 参照。

- **L1 Raw** (`raw/**/*.md`): 人間入力、append-only
- **L2 Graph Ledger** (`.rwiki/graph/`): LLM 抽出 + reject-only + Hygiene
- **L3 Curated Wiki** (`wiki/**/*.md`): 人間承認済 markdown

## Required

| ツール | 役割 |
|------|------|
| Git | バージョン管理、trust chain |
| Python 3.10+ | `rw` CLI ランタイム |
| LLM CLI | distill / query / audit semantic 等 |
| Markdown エディタ | 候補・wiki 編集（任意） |

LLM CLI 参照実装: Claude Code / OpenAI Codex / 他（MCP 経由含む）

## Python 依存

| パッケージ | 用途 | 備考 |
|-----------|-----|------|
| `sqlite3` | L2 derived cache | 標準 |
| `networkx` ≥ 3.0 | Graph 操作 | 追加（Spec 5） |

## Recommended / Optional

| ツール | 役割 |
|------|------|
| Obsidian（推奨） | Vault 閲覧・編集、Graph view、Dataview |
| Zotero（任意） | 論文管理連携（roadmap） |

## 実装独立性

- **LLM 非依存**: 特定 LLM に縛られない。抽象層は Spec 3（prompt-dispatch）
- **エディタ非依存**: 生成 markdown は任意のエディタで編集可能

## 実行モード

| モード | 起動 | 用途 |
|--------|------|------|
| Interactive | `rw chat` | 探索操作、L2 メンテ委任（推奨） |
| CLI 直接 | `rw <task> [args]` | 自動化、batch、熟練ユーザー |
| CLI Hybrid | `rw <task>`（内部 LLM 呼出） | distill / query / extract-relations |

いずれも同じ `cmd_*` エンジン関数を呼ぶ。

## 中核原則 13 項目の層別適用マトリクス

層が違えば人間と LLM の関与モデルが違う。**全原則が全層に一律適用されるわけではない**。

| 原則 | L1 Raw | L2 Ledger | L3 Wiki |
|------|:---:|:---:|:---:|
| §2.1 Paradigm C（対話+エディタ） | — | — | ✅ |
| §2.2 Review layer first | △ lint | ❌ | ✅ |
| §2.3 Status frontmatter | — | ❌ Edge | ✅ Page |
| §2.4 Dangerous ops 8 段階 | — | ❌ | ✅ |
| §2.5 Simple dangerous ops | — | ✅ edge | ✅ unapprove |
| §2.6 Git + 層別履歴媒体 | ✅ Git log | ✅ events.jsonl | ✅ frontmatter |
| §2.7 エディタ責務分離 | ✅ | △ JSONL | ✅ |
| §2.8 Skill library | — | ✅ extract | ✅ distill |
| §2.9 Graph as first-class | — | ✅ 正本 | △ cache |
| §2.10 Evidence chain | ✅ 起点 | ✅ 集約 | ✅ sources |
| §2.11 Discovery / Maint guide | ✅ | ✅ | ✅ |
| §2.12 Candidate Graph | — | ✅ 独占 | — |
| §2.13 Curation Provenance | △ | ✅ decision_log | ✅ approve |

凡例: ✅ 完全 / △ 限定 / ❌ 適用外 / — 該当なし

**最重要の帰結**:

- L2 では §2.12 が §2.2 / §2.4 より優先 — append-only JSONL + reject-only + Hygiene 自律進化
- L3 は従来型 — review/ 経由 + approve 必須 + dangerous op 8 段階対話
- L1 は人間領域 — lint のみ、自動変換しない
- §2.10 Evidence chain のみ全層を貫く（trust の基盤）

## Key Technical Decisions

### L2 ledger 形式: JSONL（vs Graph DB 正本）採用

理由 — (a) append-only で git diff 親和、行単位で履歴可読、(b) 人間可読、デバッグ可能、(c) Graph DB は diff 困難・trust chain の人間検証困難、(d) sqlite cache は rebuild 可能なので正本にしない。詳細は consolidated-spec §2.6。

### Reject-only filter（vs 全件 approve）

通常 GraphRAG の「全件レビュー必須」は入力コスト問題（§1.3.2）を再発させる。Rwiki は **reject-only + Hygiene 自己進化** に転換。詳細は consolidated-spec §2.12。

### Edge status 6 階段

`weak / candidate / stable / core / deprecated / rejected`。confidence と usage event の関数で遷移。reject は物理削除せず rejected_edges.jsonl に保持し unreject 可能（Karpathy「失敗から学ぶ」思想）。

### On-demand summary（vs 事前構築）

community summary 等は事前 index 化しない。理由 — (a) graph が evolving で陳腐化しやすい、(b) 必要時のみ LLM コスト発生、(c) Hygiene 後の最新状態を反映。

### Severity 4 水準（v1 から継承）

`CRITICAL / ERROR / WARN / INFO`。AGENTS と CLI で同名 align。`map_severity()` は identity 関数（v1 の 4→3 マッピングコスト解消済）。

### Exit code 0/1/2 分離（v1 から継承）

`exit 0 = PASS / exit 1 = runtime error / exit 2 = FAIL 検出`。全コマンド共通。`cmd_ingest` 等 status 自発判定しないコマンドは 0/1 のみ。

### LLM CLI subprocess timeout 必須

v1 で未設定だった `call_claude()` は v2 では timeout 必須（v1 audit で 30-120 秒の長時間呼出ハングリスクが顕在化）。デフォルト値は spec ごとに決定。

## 開発標準

### Test-Driven Development

期待入出力からテストを先に書く → 失敗確認 → コミット → 実装 → 通過まで反復。実装中はテストを変更しない。インデントは 2 スペース固定。

### Code Quality

- Python 3.10+ 型ヒントを全関数で使用
- Linter / Formatter 設定なし、Git pre-commit 規律に依存（v1 から踏襲）
- 汎用関数は `rw_utils` 系で共通化（v1 `v1-archive/scripts/rw_utils.py` 参考）

### Concurrency / Lock

- `.rwiki/.hygiene.lock`: Hygiene バッチ実行時の排他制御（Spec 4 ↔ Spec 5）
- L2 ledger は append-only JSONL なので reader/writer 衝突は局所化

## Common Commands

```bash
# 開発
pytest tests/                            # テスト全実行
pytest tests/test_<module>.py            # 個別実行
python -m pyflakes scripts/rw_*.py       # 静的解析

# CLI（v2 想定、Spec 4 / 5 / 6 完成後）
rw chat                                  # 対話モード（推奨入口）
rw perspective <topic>                   # Perspective 生成
rw hypothesize                           # Hypothesis 探索
rw approve <candidate>                   # L3 昇格
rw reject <edge-id>                      # L2 edge reject（理由必須）
rw graph rebuild                         # sqlite cache 再生成
rw hygiene                               # Decay/Reinforcement バッチ
```
