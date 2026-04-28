# Project Structure

> 出典: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §3, §4, §9.2

## Organization Philosophy

**3 層アーキテクチャ**で物理格納位置・アクセスパターン・人間関与の度合いを分離。

```
L1 Raw (raw/)              人間入力、append-only、trust 起点
   ↓ LLM 自動抽出
L2 Graph Ledger            候補 edges、Hygiene で進化
(.rwiki/graph/)
   ↓ 人間承認
L3 Curated Wiki (wiki/)    人間承認済み markdown
```

各層の特徴：

| 層 | 物理格納 | 更新頻度 | 人間関与 |
|----|---------|---------|---------|
| L1 Raw | `raw/**/*.md` | append-only | 入力のみ |
| L2 Ledger | `.rwiki/graph/*.jsonl` | 頻繁 | reject only |
| L3 Wiki | `wiki/**/*.md` | 人間承認時 | approve 必須 |

Git 管理: 全層 ✓（L2 cache `*.sqlite` `*.pkl` のみ gitignore）

## Vault 構造（実行時、ユーザーの Vault 側）

```
<vault>/
├── raw/                              # L1
│   ├── incoming/                     # 未検証入力（gitignore）
│   ├── llm_logs/                     # 対話ログ 3 区別（Spec 2 Decision 2-7）
│   │   ├── chat-sessions/            # rw chat 起源
│   │   ├── interactive/<skill>/      # interactive: true skill 起源（skill 別 sub-subdirectory）
│   │   └── manual/                   # 手動 import 起源
│   └── （ingest 後カテゴリ展開: articles/papers/notes/code-snippets/...）
├── review/                           # L2 ↔ L3 buffer
│   ├── synthesis_candidates/  query/
│   ├── hypothesis_candidates/        # Spec 6
│   ├── perspectives/                 # Spec 6
│   ├── skill_candidates/             # Spec 2
│   ├── lint_proposals/               # Spec 2 Decision 2-9（frontmatter_completion 出力先、synthesis_candidates と意味分離）
│   ├── vocabulary_candidates/        # Spec 1
│   ├── audit_candidates/
│   ├── relation_candidates/          # Spec 5
│   └── decision-views/               # Tier 2 markdown timeline（§2.13）
├── wiki/                             # L3
│   ├── concepts/  methods/  projects/
│   ├── entities/{people,tools}/
│   ├── synthesis/                    # 最高ランク（8 段階）
│   └── .follow-ups/
├── AGENTS/
│   ├── lint.md  ingest.md  approve.md  audit.md
│   ├── skills/                       # Spec 2
│   └── guides/                       # dangerous op 対話
├── scripts/rw → <dev>/scripts/rw_cli.py    # symlink
├── logs/
├── CLAUDE.md
├── .rwiki/
│   ├── config.yml
│   ├── vocabulary/
│   │   └── tags.yml  relations.yml  categories.yml  entity_types.yml
│   ├── graph/                        # L2 git 管理
│   │   ├── entities.yaml             # normalized
│   │   ├── edges.jsonl               # source of truth
│   │   ├── edge_events.jsonl         # confidence 変遷
│   │   ├── evidence.jsonl            # 根拠引用集（§2.10 trust 縦軸）
│   │   ├── decision_log.jsonl        # curator decision rationale（§2.13 横軸）
│   │   ├── rejected_edges.jsonl
│   │   └── reject_queue/
│   └── cache/                        # gitignore
│       ├── graph.sqlite
│       └── networkx.pkl
└── .git/
```

## 開発リポジトリ構造（本リポジトリ）

```
Rwiki-dev/
├── CLAUDE.md                  # Kiro SDLC（v1/v2 共通）
├── README.md                  # v2 リライト中スタブ
├── .kiro/
│   ├── drafts/                # v2 設計議論
│   │   ├── rwiki-v2-consolidated-spec.md  # v0.7.12
│   │   ├── rwiki-v2-scenarios.md
│   │   └── ...
│   ├── settings/templates/    # kiro skill 共通テンプレート（不変）
│   ├── specs/                 # v2 spec 起票先
│   │   └── v1-archive/        # v1 spec 退避
│   └── steering/              # 本ファイル群
│       └── v1-archive/
├── docs/                      # 議論ログ・archive
├── sample/  tVault/           # サンプル / テスト Vault
└── v1-archive/                # v1 実装（参考資料）
    ├── scripts/  templates/  tests/
    ├── README.md  CHANGELOG.md  pytest.ini
    └── review/  wiki/         # 空（git では消える）
```

## データフロー

```
L1 raw/incoming/  ──lint──►  raw/  (ingest commit)
                              │ LLM extract-relations (Spec 5)
                              ▼
L2 .rwiki/graph/edges.jsonl  status: candidate
                              │
                              ├─► Hygiene 進化
                              │     → stable → core (reinforcement)
                              │     → weak → deprecated (decay)
                              │     人間 reject → rejected_edges.jsonl
                              │
                              │ Query 時 (perspective/hypothesize)
                              │   L2 traverse → usage_signal 加算
                              │
                              │ 明示的に wiki 化したい時
                              ▼
review/*_candidates/         L2 → L3 承認 buffer
                              │ rw approve（人間判断）
                              ▼
L3 wiki/                     markdown ページ
                              related: ← L2 stable/core から sync
                              wiki/synthesis/ は最高ランク（8 段階）
```

## コマンド 4 Level 階層

| Level | 対象 | コマンド例 |
|-------|------|---------|
| L1 発見 | 日常入口 | `rw chat`, `rw perspective` |
| L2 判断 | L3 昇格・検証 | `rw approve`, `rw verify` |
| L3 メンテ（LLM ガイド） | L2 ledger 運用、wiki 保守 | `rw chat` 経由で自然言語 |
| L4 Power user / CI | 全コマンド直接 | `rw graph *`, `rw edge *` |

## 主要用語（最低限、詳細は consolidated-spec §4）

| 用語 | 定義 |
|------|------|
| **Vault** | ユーザー Wiki 物理ルート |
| **L1/L2/L3** | 3 層（Raw / Graph Ledger / Curated Wiki） |
| **Edge** | L2 の typed relation |
| **Edge status** | weak/candidate/stable/core/deprecated/rejected |
| **Page status** | active/deprecated/retracted/archived/merged |
| **Evidence** | edge / wiki の根拠引用 |
| **Hygiene** | Decay / Reinforcement / Competition / Merging 総称 |
| **Reject queue** | 低 confidence 候補の確認待ち行列 |
| **Distill** | raw → wiki 要約タスク（旧 synthesize） |
| **Perspective** | 既存 wiki の再解釈出力（Spec 6） |
| **Hypothesis** | 未検証の新命題（Spec 6） |

## Code Organization Principles

- **3 層分離**: L1/L2/L3 を import で混在させない（L2 → L3 cache 同期は明示的 interface）
- **フロントマター駆動メタデータ**: 全 markdown に YAML frontmatter（title, status, sources, related, type, tags）
- **JSONL append-only**: L2 ledger は edges/edge_events/evidence/rejected_edges 全て JSONL、追記のみで履歴保全
- **Derived cache は gitignore**: `.rwiki/cache/*.sqlite|*.pkl` は再生成可能なので非追跡
- **構造化ログ**: lint / query / audit 結果は JSON 出力（`logs/*_latest.json` 命名）、人間用サマリは標準出力
- **モジュール責務分割**: v2 でも責務別モジュール分割（v1 の DAG 依存方針を継承予定、Spec 4 起票時に確定）

## Naming Conventions

| 対象 | 規約 | 例 |
|------|------|------|
| Python ファイル | snake_case | `rw_cli.py`, `rw_graph.py` |
| ディレクトリ | lowercase + underscore | `synthesis_candidates/`, `reject_queue/` |
| CLI コマンド | 動詞ベース、kebab | `rw chat`, `rw graph rebuild` |
| 関数 | snake_case | `parse_frontmatter`, `git_commit` |
| Frontmatter 日付 | ISO 8601 | `2026-04-26` |
| Edge ID | `e_<6 桁>` | `e_042` |
| Evidence ID | `ev_<6 桁>` | `ev_017` |
| ログファイル | `<command>_latest.json` | `lint_latest.json` |

## Import Organization

```python
# 標準ライブラリ
import json, os, re, shutil, subprocess, sys, sqlite3
from pathlib import Path
from datetime import datetime
from typing import Optional

# 追加依存（Spec 5 以降）
import networkx as nx

# プロジェクト内（モジュール修飾参照を徹底、from import は避ける）
import rw_utils      # 例: rw_utils.parse_frontmatter(...)
import rw_graph      # 例: rw_graph.add_edge(...)
```

`from rw_<module> import <symbol>` は **禁止**（v1 経験から踏襲）。理由 — テストの `monkeypatch.setattr` が全呼出経路で作用するように、モジュール修飾参照で統一する。

## v1 との対応

- v1 → v2 命名対応表は consolidated-spec §11.3
- v1 実装の参照: `v1-archive/scripts/`, `v1-archive/templates/AGENTS/`, `v1-archive/tests/`
- v1 spec の参照: `.kiro/specs/v1-archive/`
- v2 開発は **v1 を知らない前提で新名称のみで自己完結**（§9.1）
