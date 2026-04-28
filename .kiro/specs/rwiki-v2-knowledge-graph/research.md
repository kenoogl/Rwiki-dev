# Research & Design Decisions — rwiki-v2-knowledge-graph (Spec 5)

## Summary

- **Feature**: `rwiki-v2-knowledge-graph` (Spec 5、Phase 3 前半、最重要・最大規模 spec、内部 P0-P4 段階実装、MVP は P0+P1+P2)
- **Discovery Scope**: New Feature (v2 新規層、v1 に L2 Graph Ledger 相当概念なし)
- **Key Findings**:
  - **networkx version pin 戦略**: networkx 3.5+ は Python 3.11+ 強制、Python 3.10 互換維持には `>= 3.0, < 3.5` で pin が必要 (3.4.2 が Python 3.10 互換最終版)。Foundation / steering の「Python 3.10+」制約と矛盾しないように本 spec 単独で完結
  - **Louvain 採択 + Leiden は Phase 3 拡張余地**: networkx 内蔵 `community.louvain.louvain_communities()` が依存ゼロ追加で MVP 制約整合。Leiden は `leidenalg + python-igraph` 別パッケージ追加が必要、roadmap.md「Constraints: 追加依存は networkx ≥ 3.0 のみ」に違反
  - **fcntl.flock thread-safety 持ち越し Adjacent Sync 残 1 項目の確定**: MVP single-thread 前提で fcntl.flock 単独で確保。Phase 2 並列化時 (Spec 7 orchestrate_edge_ops の ThreadPoolExecutor 4 並行化) は process-level (fcntl.flock) + thread-level (threading.Lock) の二重 lock が必須

## Research Log

### Topic 1: 既存 4 design (Spec 0/1/4/7) の書きぶり pattern と Spec 5 が満たすべき contracts

- **Context**: Spec 5 が最重要・最大規模の spec、既 approve 済 4 design を pattern として参照 + 各 spec が Spec 5 に期待する contracts を抽出
- **Sources Consulted**:
  - `.kiro/specs/rwiki-v2-foundation/design.md` (Spec 0、966 行)
  - `.kiro/specs/rwiki-v2-classification/design.md` (Spec 1、1415 行)
  - `.kiro/specs/rwiki-v2-cli-mode-unification/design.md` (Spec 4、2056 行)
  - `.kiro/specs/rwiki-v2-lifecycle-management/design.md` (Spec 7、1754 行)
- **Findings**:
  - **Pattern**: 14 セクション標準 (Overview / Goals / Non-Goals / Boundary Commitments / Architecture / File Structure Plan / System Flows / Requirements Traceability / Components and Interfaces / Data Models / Error Handling / Security / Performance / Testing Strategy / Migration Strategy / 設計決定事項 / change log)
  - **Boundary Commitments 形式**: This Spec Owns / Out of Boundary / Allowed Dependencies / Revalidation Triggers の 4 サブセクション
  - **Component block 形式**: table (Intent / Requirements / Owner) + Responsibilities & Constraints + Dependencies + Contracts + Service Interface (Python docstring) + Implementation Notes
  - **設計決定 ADR 代替**: design.md 本文「設計決定事項」セクションに numbered subsection (Decision N-1 〜 N-N) + change log 二重記録
  - **Mermaid 利用**: Architecture Pattern & Boundary Map (graph TB) + Module DAG (graph LR) + System Flow (sequence + flowchart)。design-principles.md 制約: label 内 `/` `()` `*` `[]` `"` 禁止
  - **Spec 7 contracts (最重要)**:
    - edge API 3 種 signature: `edge_demote(edge_id, reason, timeout=5.0)` / `edge_reject(edge_id, reason_category, reason_text, timeout=10.0)` / `edge_reassign(edge_id, new_endpoint, timeout=30.0)`
    - `EDGE_API_TIMEOUT_DEFAULTS` dict (deprecate: 5.0 / retract: 10.0 / merge: 30.0 / reassign: 30.0)
    - `OrchestrationResult` dataclass (successful_edge_ops / failed_edge_ops / followup_ids / partial_failure)
    - `record_decision_for_lifecycle()` 11 種 decision_type (Page lifecycle 7 種 + Skill lifecycle 4 種)
    - `outcome` field 内 partial failure 4 field (`partial_failure` / `successful_edge_ops` / `failed_edge_ops` / `followup_ids`)
- **Implications**: design.md の 14 セクション順序と Spec 7 を pattern として踏襲、各 component block で Spec 7 contracts を Service Interface に明示

### Topic 2: SSoT drafts (§2.6 / §2.9 / §2.10 / §2.12 / §2.13 / §3.1-§3.3 / §4.3 / §5.10 / §7.2 Spec 5) からの設計詳細

- **Context**: requirements.md に書かれていない設計に直接効く詳細を SSoT から抽出
- **Sources Consulted**:
  - `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §2.6 (JSONL 採用理由 + edge_events.jsonl 設計意図) / §2.9 (Graph as first-class) / §2.10 (Evidence chain) / §2.12 (6 係数加重式 + 3 段階閾値 + 暴走防止 3 制約) / §2.13 (selective recording + reasoning hybrid + Tier 1/2/3 + privacy) / §3.1-§3.3 (3 層アーキテクチャ + データフロー) / §4.3 (Graph Ledger 用語 + relations.yml 4 field) / §5.10 (entities/edges/edge_events/evidence/rejected_edges schema example + field 順序) / §7.2 Spec 5 (中核の 6 設計判断)
  - `.kiro/drafts/rwiki-v2-scenarios.md` Scenario 13, 14, 34, 35, 36, 37, 38
- **Findings**:
  - **6 係数加重式の具体係数** (§2.12): `evidence` 0.35 / `explicitness` 0.20 / `source_reliability` 0.15 / `graph_consistency` 0.15 / `recurrence` 0.10 / `human_feedback` 0.05、合計 1.0
  - **4 extraction_mode の explicitness_score**: explicit=1.0 / paraphrase=0.75 / inferred=0.5 / co_occurrence=0.25
  - **3 段階閾値** (§2.12): auto_accept 0.75 / candidate_weak_boundary 0.45 / reject_queue_threshold 0.3 / evidence_required_ceiling 0.3
  - **Reinforcement 暴走防止 3 制約**: per-event 0.1 / per-day 0.2 / `independence_factor` 頭打ち
  - **Selective recording trigger 5 条件** (§2.13): confidence boundary (0.45 ±0.05) / contradiction 検出 / human action / status 遷移 / synthesis promotion
  - **記録しない 3 対象** (§2.13): hygiene_routine_decay / hygiene_routine_reinforce / extraction_with_confidence_above_0.85
  - **reasoning hybrid input 3 方式**: auto-generate from chat / manual `--reason` flag / default skip ("default" 印)
  - **selective privacy 2 方式**: `decision_log.gitignore` (vault 全体) + per-decision `private:` flag
  - **edges.jsonl schema example** (§5.10、12 field): `edge_id / source / type / target / confidence / status / evidence_ids / extraction_mode / created_at / updated_at / source_file / is_inverse`
  - **§7.2 Spec 5 の 6 確定決定**: normalize_frontmatter API (Spec 1 / Spec 5 境界) / Query API 15 種署名 / Community detection (Leiden / Louvain 選択可、本 spec で Louvain 採択) / Rebuild + sync (Hybrid stale-mark + Hygiene batch) / Concurrency lock 物理実装 (fcntl/flock + stale lock 検出 + PID 記録) / 外部依存 networkx ≥ 3.0
- **Implications**: requirements の各 AC は SSoT と完全整合、design.md ではこれら数値・schema・構造例を Service Interface + Data Models + Configuration セクションに具体記述

### Topic 3: networkx 3.x community detection (Louvain vs Leiden + version pin)

- **Context**: 本 spec の唯一の新規 external dependency
- **Sources Consulted**:
  - [louvain_communities — NetworkX 3.6.1](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.community.louvain.louvain_communities.html) (2026-04-28)
  - [leiden_communities — NetworkX 3.6.1](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.community.leiden.leiden_communities.html) (2026-04-28)
  - [networkx · PyPI](https://pypi.org/project/networkx/) (2026-04-28)
  - [leidenalg · PyPI](https://pypi.org/project/leidenalg/) (2026-04-28)
- **Findings**:
  - 最新安定版 networkx 3.6.1 (2025-12-08 release) は Python 3.11+ 強制 (`Requires-Python: !=3.14.1, >=3.11`)。Python 3.10 互換最終版は 3.4.2 系
  - `louvain_communities(G, weight='weight', resolution=1, threshold=1e-07, max_level=None, seed=None)`、戻り値は list[set]、resolution default 1
  - **non-deterministic by default** — ノード処理順を random shuffle、再現性確保には `seed=` 引数明示が必須
  - Leiden は networkx 3.6 で `leiden_communities` API が追加されたが native CPU 実装なし、`cugraph` (GPU) backend のみ。CPU で Leiden を使うには `leidenalg + python-igraph` 別パッケージスタックが必要
  - 100-500 nodes / 1000-5000 edges 規模での実行時間は理論計算量 O(m log n)、数 ms〜数十 ms オーダー
- **Implications**:
  - **採用**: `networkx >= 3.0, < 3.5` で pin (Python 3.10 維持)、Louvain MVP 採択
  - **seed 固定**: `.rwiki/config.yml` `graph.community.seed` (default 42) で determinism 確保、`get_communities(seed=...)` で override 可
  - **Louvain disconnected community 問題**: post-process で `networkx.connected_components()` を community subgraph に適用 + 再分割
  - **Leiden は Phase 3 拡張余地**: 別 spec で `leidenalg` 依存追加検討

### Topic 4: sqlite WAL mode + Python sqlite3 + cache migration

- **Context**: derived cache (`.rwiki/cache/graph.sqlite`) の高速 traverse + crash safety
- **Sources Consulted**:
  - [Write-Ahead Logging — SQLite](https://sqlite.org/wal.html) (2026-04-28)
  - [Pragma statements — SQLite](https://sqlite.org/pragma.html) (2026-04-28)
  - [SQLite User Forum: WAL journal and threading mode](https://sqlite.org/forum/info/461653af585fb599) (2026-04-28)
- **Findings**:
  - `PRAGMA journal_mode=WAL` は永続設定 (DB file header に格納)
  - WAL は multiple readers + single writer を許容、reader は writer 進行中も blocking なく読める
  - WAL と threading mode は直交、同一 connection を複数 thread で共有することは依然 unsafe → connection-per-thread 規律
  - `(src_id)` 単独 index と `(dst_id)` 単独 index の両方を貼ると bidirectional traversal が両方とも O(log n)
  - cache が gitignore な derived artifact なら schema migration 不要 → drop + rebuild from JSONL
- **Implications**:
  - **採用**: cache.db open 直後に `PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL;`
  - **schema migration 実装しない**: cache に `schema_version` table を持ち、起動時に期待 version 不一致なら drop + rebuild from JSONL
  - **connection-per-thread + threading.Lock で内部直列化**

### Topic 5: fcntl.flock cross-process semantics + thread-safety + 持ち越し Adjacent Sync 残 1 項目

- **Context**: `.rwiki/.hygiene.lock` 物理実装 + Spec 7 design Round 5 軽-5-3 由来 (orchestrate_edge_ops 並列化 Phase 2 拡張余地)
- **Sources Consulted**:
  - [fcntl — Python Standard Library](https://docs.python.org/3/library/fcntl.html) (2026-04-28)
  - [Everything you never wanted to know about file locking — apenwarr](https://apenwarr.ca/log/20101213) (2026-04-28)
  - [Flock and fcntl file locks and Linux NFS](https://utcc.utoronto.ca/~cks/space/blog/linux/FlockFcntlAndNFS) (2026-04-28)
- **Findings**:
  - `fcntl.flock()` は process + file struct ベース、thread identity を見ない → **同一 process 内の複数 thread は flock を bypass する**
  - 対策: process-level (fcntl.flock) + thread-level (threading.Lock) の二重 lock が標準 pattern。順序は outer = threading.Lock → inner = fcntl.flock
  - `LOCK_EX | LOCK_NB` は non-blocking で `BlockingIOError` を即座 raise → fail-fast UX
  - close(fd) または process exit で自動解放 → MVP single-thread CLI では PID file 不要
- **Implications**:
  - **MVP (P0-P2)**: `fcntl.flock(LOCK_EX | LOCK_NB)` + fail-fast、stale lock 検出は kernel 任せ、PID 記録は debug 用
  - **持ち越し Adjacent Sync 残 1 項目の確定**: Phase 2 multi-thread 化時は `threading.Lock` (outer) + `fcntl.flock` (inner) の二重 lock が必須 (Decision 5-20、Migration Strategy)

### Topic 6: JSONL append-only + atomic rename pattern

- **Context**: ledger 7 ファイル更新の crash safety
- **Sources Consulted**:
  - [Crash-safe JSON at scale: atomic writes + recovery without a DB](https://dev.to/constanta/crash-safe-json-at-scale-atomic-writes-recovery-without-a-db-3aic) (2026-04-28)
  - [PSA: Avoid Data Corruption by Syncing to the Disk](https://blog.elijahlopez.ca/posts/data-corruption-atomic-writing/) (2026-04-28)
  - [python-atomicwrites GitHub](https://github.com/untitaker/python-atomicwrites) (2026-04-28)
- **Findings**:
  - 正しい順序: `(1) write to tmp → (2) f.flush() → (3) os.fsync(f.fileno()) → (4) os.replace(tmp, target) → (5) os.fsync(parent_dir_fd)`
  - macOS 特有: `fsync()` は disk cache まで flush しない、`fcntl.fcntl(fd, F_FULLFSYNC)` が真の disk-flush
  - tmp file は **必ず target と同一 directory** (cross-device rename は atomic 保証なし)
  - POSIX append atomic 保証: `O_APPEND` で `n < PIPE_BUF` (Linux: 4096 / macOS: 512) のみ atomic
  - 末尾行 corruption は reader 側で `try: json.loads() except: log warn + skip` で許容
- **Implications**:
  - **採用**: 5 step pattern + macOS 条件分岐で F_FULLFSYNC 併用
  - **JSONL append**: `open(path, 'a')` + 1 line + 末尾 `\n` + flush + fsync + flock 排他、1 record は可能な限り 4096 bytes 以下
  - **Reader robustness**: 末尾 1 行 corrupt は warn + skip、それ以前 corrupt は CRITICAL error

### Topic 7: GraphRAG (Microsoft 2024) reference

- **Context**: Spec 5 の community detection / hierarchical summary / missing bridge を GraphRAG style と比較
- **Sources Consulted**:
  - [GraphRAG (Microsoft)](https://microsoft.github.io/graphrag/) (2026-04-28)
  - [From Local to Global: A GraphRAG Approach (arXiv 2404.16130)](https://arxiv.org/html/2404.16130v2) (2026-04-28)
  - [GraphRAG: Improving global search via dynamic community selection](https://www.microsoft.com/en-us/research/blog/graphrag-improving-global-search-via-dynamic-community-selection/) (2026-04-28)
- **Findings**:
  - **Community detection: Leiden 採用 (公式)** — disconnected community を作らない保証
  - **Hierarchical summary は pre-computed (bottom-up)** — indexing 時に各 community に対し LLM で summary 生成、上位 level は下位 summary を recursive 取込
  - **Global query vs Local query**: Global は corpus 全体 broad question / Local は entity から外向きに neighbor expand
  - **Missing bridge detection**: GraphRAG 公式 docs 言及なし、一般的には Adamic-Adar / Cosine similarity / Jaccard / Common Neighbors / Preferential Attachment
- **Implications**:
  - **本 spec MVP**: Louvain で代用 (Leiden が依存違反のため)、disconnected community 問題は post-process check で緩和
  - **Missing bridge**: networkx 内蔵 `nx.adamic_adar_index()` 採用 (依存ゼロで MVP 最適)
  - **hierarchical summary**: P2 (on-demand 採択)、cache 利用 + Hygiene batch 無効化

### Topic 8: Append-only event log (event sourcing) + decision log envelope

- **Context**: 本 spec の 7 ledger ファイル + decision log の forward-compatible schema 進化
- **Sources Consulted**:
  - [Simple patterns for events schema versioning](https://event-driven.io/en/simple_events_versioning_patterns/) (2026-04-28)
  - [Event Sourcing Pattern — Microsoft Learn](https://learn.microsoft.com/en-us/azure/architecture/patterns/event-sourcing) (2026-04-28)
  - [Event Sourcing — Martin Fowler](https://martinfowler.com/eaaDev/EventSourcing.html) (2026-04-28)
- **Findings**:
  - **Schema versioning**: 新 field は optional / nullable で追加 (forward-compatible、旧 reader は無視)、Breaking change 時のみ schema_version bump
  - **Compensating event での訂正**: 物理削除しない、誤った event の逆操作 event を append (会計帳簿 pattern)
  - **ID 生成**: UUID v4 (完全ランダム / sortable でない) / ULID / UUID v7 (Python 3.14+ 標準) / hash-based。Python 3.10 維持なら UUID v4 + ISO timestamp 併記が依存ゼロで sort 可能性確保
- **Implications**:
  - **採用**: envelope に `schema_version: 1` (整数) + `<id>: <uuid v4>` + `timestamp: <ISO 8601 UTC>` を必須 field
  - **field 追加は forward-compatible**、reader は未知 field 無視
  - **訂正は compensating event** (物理削除しない)
  - **ID は UUID v4 で開始**、Python 3.14+ 移行時に UUID v7 検討

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| **Layered architecture (採用)** | 9 layer DAG、各 layer は下位のみ依存、上向き / 同層 cyclic 禁止 | Spec 4 / Spec 7 同型 pattern、責務分離明確、test 容易、parallel 実装可 | layer 数増加で間接呼出増 (実害なし) | Spec 7 Decision 7-21 同型問題回避、Layer 4 を機能別 3 sub-module 分割 |
| Microservices | API gateway 経由で各 layer を別 process 化 | scalability | overengineering、subprocess overhead、single-user CLI に不適 | 却下 (MVP 範囲外) |
| Event sourcing only | event log のみで state 復元、cache なし | 完全 audit trail | sqlite cache の高速 traverse 性能を失う | 部分採用 (Layer 1 ledger は append-only event sourcing、Layer 7 query は sqlite cache derived) |
| CQRS (Command Query Responsibility Segregation) | command (write) と query (read) を分離 | read 性能 / scaling | overengineering、本 spec の規模では不要 | 部分採用 (Hygiene write は lock 必須、Query read は lock 不要) |

## Design Decisions

### Decision: Generalization (一般化機会)

- **Edge API 3 種 → 共通 timeout + partial_failure pattern**: edge_demote / edge_reject / edge_reassign は同一 pattern (timeout 必須 / partial failure 伝搬 / decision_log 記録) を共有、共通 wrapper として `rw_edge_api` 単一 module に集約
- **decision_log と event_log → 共通 envelope (schema_version + uuid + ts)**: 両者 append-only JSONL、forward-compatible schema 進化、共通 envelope schema を Layer 1 LedgerStore で集約
- **Query API 共通 filter (status_in / min_confidence / relation_types)**: 15 種 API すべてに統一 filter dataclass `CommonFilter` を引数として渡す、各 API 個別の filter validation を排除
- **Vocabulary parser (relations.yml / entity_types.yml) → 共通 loader**: 両者 YAML、同一 cache せず毎回最新 reload pattern、`rw_vocabulary` 単一 module に集約

### Decision: Build vs Adopt (build-vs-adopt)

| 機能 | 判定 | 採用先 / 理由 |
|------|------|--------------|
| Community detection | Adopt | networkx 内蔵 Louvain (依存ゼロ) |
| Missing bridge detection | Adopt | networkx 内蔵 `nx.adamic_adar_index()` |
| sqlite cache | Adopt | sqlite3 標準 (WAL + index) |
| File lock | Adopt | fcntl.flock 標準 (LOCK_EX + LOCK_NB) |
| Atomic rename | Adopt | os.replace 標準 (5 step pattern) |
| YAML parser | Adopt | PyYAML (既存依存) |
| 6 係数 confidence scorer | Build | §2.12 SSoT 独自数式、外部 library なし |
| Hygiene 5 ルール | Build | §2.12 / §2.13 独自規範、Reinforcement 暴走防止 3 制約は本 spec 独自 |
| Decision log selective recording | Build | §2.13 Curation Provenance 独自規範、selective trigger 5 条件 + reasoning hybrid 3 方式 |
| Reject workflow | Build | §2.12 Reject-only filter 独自規範、unreject 復元 5 step は本 spec 独自 |
| Edge API 3 種 (Spec 7 連携) | Build | Spec 7 R12 由来 coordination 確定 signature |

### Decision: Simplification (簡素化機会)

- **Schema migration 実装しない**: cache が gitignore な derived artifact、schema_version table で version 検出 → drop + rebuild from JSONL ledger で済む。複雑な incremental rebuild ロジック不要
- **Stale lock 検出を kernel 任せ**: MVP single-thread CLI では fcntl.flock の close(fd) 自動解放で十分、PID file は debug 用に minimal 記録のみ
- **Leiden は Phase 3 拡張余地**: MVP は Louvain のみ、`leidenalg` 別パッケージ依存追加は MVP 制約違反のため Phase 3 で再検討
- **Missing bridge は MVP で Adamic-Adar 単発**: embedding ベース (Node2vec / TransE) は別パッケージ依存追加 (gensim / sentence-transformers) で MVP 制約違反、Adamic-Adar が依存ゼロで MVP 最適
- **schema_version は整数で開始**: semver "1.2.0" にしない、Breaking change 発生時のみ bump (`1` → `2`)

### Decision: hygiene.lock thread-safety (Adjacent Sync 残 1 項目の確定、Decision 5-20)

- **Context**: Spec 7 design Round 5 軽-5-3 由来 (orchestrate_edge_ops 並列化 Phase 2 拡張余地)
- **Alternatives**:
  1. MVP single-thread + fcntl.flock 単独
  2. MVP から threading.Lock 二重 lock 実装
  3. RWLock (shared / exclusive) で並列 read 許容
- **Selected**: 案 1 (MVP)、Phase 2 で案 2 移行を Migration Strategy で明示
- **Rationale**:
  - MVP single-user serialized 前提では同一 process 内に複数 thread が edge API を並行呼出する想定なし
  - fcntl.flock は process + file struct ベース、thread identity を見ないため、同一 process 内複数 thread は flock を bypass する → multi-thread 化時には threading.Lock 二重 lock が必須
  - PID 記録 + stale lock 検出ロジックの「check-then-act」パターンが複数 thread 並行時に race condition を持つ可能性、Phase 2 移行時に thread_id 記録追加が必要
- **Trade-offs**: MVP では fcntl.flock 単独、Phase 2 移行時に LockManager 改修コスト発生
- **Follow-up** (Phase 2 移行時 implementation 手順):
  1. `LockManager.acquire_lock()` に `threading.Lock` を内部追加
  2. lock file format に `thread_id` field 追加 (debug 用)
  3. test に concurrent thread test (4 並行 acquire/release) 追加
  4. Spec 7 design に「Spec 5 LockManager は Phase 2 から thread-safe」を反映 (Adjacent Sync)

## Risks & Mitigations

- **Risk 1 (networkx version pin 衝突)**: Python 3.11+ 引き上げが Foundation / steering の改版を引き起こす可能性
  - **Mitigation**: MVP は `networkx >= 3.0, < 3.5` で Python 3.10 互換維持、Phase 3 で別 spec として Python 3.11+ 引き上げ + networkx 3.5+ への移行を検討
- **Risk 2 (Reinforcement per-day cap 接触問題、大規模 Vault)**: edges > 5,000 で一部 edge のみ強化、他は cap で skip
  - **Mitigation**: brief.md 第 4-E 持ち越しを Phase 3 で `--scope=community:<id>` / `--scope=since:7d` 部分 Hygiene として実装 (Requirement 21.6)
- **Risk 3 (edge_id hash 衝突)**: source+type+target hash 12 hex 文字、Vault 規模 (edges 5,000-10,000) で衝突確率実質ゼロだが理論的には発生しうる
  - **Mitigation**: brief.md 第 4-B 持ち越しを Decision 5-10 で「衝突検出時 ERROR severity で abort、衝突解決アルゴリズム未実装」として確定、衝突発生事例があれば再検討
- **Risk 4 (decision_log privacy mode 切替時の意味曖昧)**: `gitignore: true` 切替時に過去 history 含むか
  - **Mitigation**: brief.md 第 4-A 持ち越しを Decision 5-11 で「未来分のみ git 管理外、過去 history はそのまま残る」として確定、過去 sanitize 必要時は別 task で `git filter-branch` 等
- **Risk 5 (Phase 2 multi-thread 化時の hygiene.lock thread-safety)**: fcntl.flock 単独では thread-safety なし
  - **Mitigation**: Decision 5-20 で MVP single-thread 前提を確定、Phase 2 移行時の implementation 手順を Migration Strategy で明示
- **Risk 6 (LLM CLI subprocess hang)**: timeout 未設定で hang
  - **Mitigation**: Foundation R11 「LLM CLI subprocess timeout 必須」継承、本 spec の Layer 3 / Layer 9 全 subprocess 起動箇所で timeout 引数必須
- **Risk 7 (sqlite cache schema drift)**: gitignore な cache が古い schema で残留
  - **Mitigation**: Decision 5-2 で「`schema_version` table で version 検出 + drop + rebuild from JSONL」を採用、cache が drop されても JSONL から再生成可能

## References

- [NetworkX 3.6.1 community.louvain.louvain_communities](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.community.louvain.louvain_communities.html) — Louvain API 仕様 (採用)
- [NetworkX 3.6.1 leiden_communities](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.community.leiden.leiden_communities.html) — Leiden API 仕様 (Phase 3 拡張余地)
- [networkx · PyPI](https://pypi.org/project/networkx/) — version pin 戦略の根拠
- [leidenalg · PyPI](https://pypi.org/project/leidenalg/) — Phase 3 候補
- [SQLite WAL](https://sqlite.org/wal.html) — sqlite cache strategy 根拠
- [SQLite Pragma](https://sqlite.org/pragma.html) — `PRAGMA journal_mode=WAL` / `synchronous=NORMAL`
- [Python fcntl](https://docs.python.org/3/library/fcntl.html) — fcntl.flock 仕様
- [apenwarr — Everything you never wanted to know about file locking](https://apenwarr.ca/log/20101213) — fcntl.flock thread-safety 詳細
- [Crash-safe JSON at scale](https://dev.to/constanta/crash-safe-json-at-scale-atomic-writes-recovery-without-a-db-3aic) — atomic write 5 step pattern
- [GraphRAG (Microsoft)](https://microsoft.github.io/graphrag/) — community detection / hierarchical summary reference
- [GraphRAG arXiv 2404.16130](https://arxiv.org/html/2404.16130v2) — From Local to Global pattern
- [Event-Driven.io Schema versioning patterns](https://event-driven.io/en/simple_events_versioning_patterns/) — schema_version envelope pattern
- [Event Sourcing Pattern (Microsoft Learn)](https://learn.microsoft.com/en-us/azure/architecture/patterns/event-sourcing) — compensating event での訂正 pattern
- [Martin Fowler — Event Sourcing](https://martinfowler.com/eaaDev/EventSourcing.html) — event sourcing 古典 reference
- `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §2.6 / §2.9 / §2.10 / §2.12 / §2.13 / §3.1-§3.3 / §4.3 / §5.10 / §7.2 Spec 5 — SSoT
- `.kiro/drafts/rwiki-v2-scenarios.md` Scenario 13, 14, 34, 35, 36, 37, 38 — シナリオ
- `.kiro/specs/rwiki-v2-foundation/design.md` (Spec 0) — 規範 design pattern
- `.kiro/specs/rwiki-v2-classification/design.md` (Spec 1) — Entity 固有 shortcut field 宣言
- `.kiro/specs/rwiki-v2-cli-mode-unification/design.md` (Spec 4) — CLI handler 6 系統 + lock 取得契約
- `.kiro/specs/rwiki-v2-lifecycle-management/design.md` (Spec 7) — edge API 3 種 signature + EDGE_API_TIMEOUT_DEFAULTS + record_decision_for_lifecycle 11 種 + outcome partial failure 4 field

---

_change log_

- 2026-04-28: 初版生成 (Spec 5 design Discovery + Synthesis 完了、外部技術 research 8 topic + 4 既存 design pattern 抽出 + SSoT drafts 整合確認)。Decision 5-1 〜 5-20 を design.md 本文「設計決定事項」と二重記録。持ち越し Adjacent Sync 残 1 項目 (hygiene.lock thread-safety) を Decision 5-20 で確定 (MVP single-thread + Phase 2 multi-thread 二重 lock 移行戦略)。Build vs Adopt 4 件 / Generalization 4 件 / Simplification 5 件を Synthesis 章で明示。
- 2026-04-28 (Round 1 レビュー結果記録): requirements 全 23 R / 180 AC 網羅検査 (TODO 記載 197 AC は概数、実カウントは 180)。本質的観点 5 種強制発動、Step 1b 4 重検査 + Step 1b-v 5 切り口 (5 番目 negative 強制発動) 適用。
  - **検出 [escalate 推奨] 2 件**: 重-1-1 (Service Interface section 7 module 欠落、構造的不均一、Spec 0 R2 重-厳-3 同型) + 重-1-2 (`EDGE_API_TIMEOUT_DEFAULTS` dict key annotation 欠落、文書記述 vs 実装不整合、Spec 1 R5 escalate 同型)
  - **検出 [自動採択候補] 1 件**: 軽-1-5 (v1 継承 list の不整合、R23.7 と design L1874 list が `Python 3.10+` / `git 必須` 2 項目を欠落)
  - **検出 [取り下げ] 1 件**: 軽-1-4 (Configuration full schema example 不足) → Spec 7 / Spec 4 design に config.yml 完全 schema example block なし、Phase 1/2 慣行整合のため取り下げ
  - **検出 [既正当化] 1 件**: 軽-1-3 (Decision 5-10 / 5-11 brief 持ち越し handling) → brief.md 第 4-A / 4-B 持ち越し handling として既に正当化済、design 内吸収範囲のため修正不要
  - 5 観点深掘り検証 (実装難易度 / 設計理念整合 / 運用整合性 / boundary 違反リスク / Phase 1 整合) で全 escalate 案件の推奨案を確証、user 2 択判断後に Edit 適用。
  - 適用結果: design.md change log 2026-04-28 (Round 1 レビュー反映) に記録、本 spec design phase = approve 待ち継続 (`spec.json.approvals.design.approved=false` 維持)。
- 2026-04-28 (Round 2 レビュー結果記録): アーキテクチャ整合性検査 = 9 Layer DAG (上向き禁止) / Module 分割 / Boundary 4 サブセクション整合 / Spec 7 Decision 7-21 同型問題回避。
  - **検出 [escalate 推奨] 1 件**: 重-2-1 (Layer 4 → Layer 5 number 上向き依存と「上向き禁止」規範解釈の曖昧化、Spec 1 R7 escalate Eventual Consistency 同型)
  - **検出 [取り下げ] 1 件**: 軽-2-2 (Architecture Pattern Map mermaid に L4Hygiene→L5Decision arrow 欠落と疑った検出 → L177 に既存 arrow 確認、検出誤り)
  - **確認結果 (検出なし)**: Module 分割 (23 module すべて ≤ 1500 行、最大 67%) / 後方互換 re-export 禁止 (L274 明示) / Spec 7 Decision 7-21 同型問題回避 (Layer 4/7/8 sub-module 分割で防止) / Boundary 4 サブセクション (This Spec Owns 19 / Out of Boundary 10 / Allowed Dependencies 内外両方 / Revalidation Triggers 10) / 9 Layer 依存方向 8/9 が number 下向き
  - 推奨案 X1 (現状維持 + 規範解釈明示文追加) を 5 観点深掘り検証で確証 (case X2 番号 reorder / X3 共通基盤 layer 化は cost / Phase 1 違反で dominated)、user 2 択判断後に Edit 適用。
  - 適用結果: design.md L194 付近に「Layer 番号と依存方向の解釈」明示文追加、change log に 2026-04-28 (Round 2 レビュー反映) を記録。
- 2026-04-28 (Round 3 レビュー結果記録): データモデル検査 = 7 ledger schema (12 / 5 / 4 / 10 / 8 field) + sqlite WAL schema + vocabulary YAML + envelope schema (Decision 5-16)。
  - **検出 [escalate 推奨] 1 件**: 重-3-1 (entities.yaml + relations.yml example で `entity_type: method` / `domain: method` / `range: method` が Spec 1 R2.7 直交分離 / R5.3 初期 entity_type / R7.2 `entity_types.yml.name` のみ参照に違反、Spec 1 R5 escalate Levenshtein 同型)
  - **検出 [自動採択] 1 件**: 軽-3-2 (decision_log の `private:` field の必須/任意 status が design Data Models 内で未明示、R11.1 10 field 必須に含まれず R11.7 任意 field)
  - **検出 [取り下げ] 1 件**: 軽-3-3 (sqlite と JSONL の役割分担明示) → L1265-1266 + Decision 5-2 + L1666 で既に必要十分
  - **確認結果 (検出なし)**: edges.jsonl 12 field / evidence.jsonl 5 field / edge_events.jsonl 4 field 最低 + 固有 field / decision_log.jsonl 10 field + outcome partial failure 4 field / rejected_edges.jsonl 8 field / entities.yaml 3 項目最低 / sqlite WAL schema (schema_version + nodes + edges + community_memberships + decisions tables + index 4) / vocabulary YAML 4 field (inverse / symmetric / domain / range) / envelope schema (schema_version 1 + UUID v4 + ISO 8601) は全 example で整合確認
  - 推奨案 X1 (entity-tool で example 統一、最小修正) を 5 観点深掘り検証で確証 (案 X2 entity-method 新規例 / X3 完全書き換えは Spec 1 改版または影響範囲大で dominated)、user 2 択判断後に Edit 適用。
  - 適用結果: design.md entities.yaml / relations.yml / decision_log.jsonl example に Spec 1 直交分離整合の Note 追加、change log に 2026-04-28 (Round 3 レビュー反映) を記録。
- 2026-04-28 (Round 4 レビュー結果記録): API interface 検査 = Query API 15 種 + edge API 3 種 (timeout default) + record_decision + normalize_frontmatter + check_decision_log_integrity の signature 整合。
  - **検出 [escalate 推奨] 1 件**: 重-4-1 (R14.2「全 API 共通で提供」規定に対し design で 8 Edge-domain API に CommonFilter 引数欠落、Spec 1 R5 escalate API signature 文書 vs 実装乖離 同型)
  - **検出 [自動採択] 1 件**: 軽-4-3 (Error Categories の Business Logic Errors 表に `RecordDecisionError` 例外列挙漏れ、Layer 5 DecisionLogStore L1094 docstring と整合修正)
  - **確認結果 (検出なし)**: Query API 15 種 P0/P1/P2 名前 (R14.1 と design L1242-1267) / edge API 3 種 timeout default 5s/10s/30s (R18.7 / Spec 7 EDGE_API_TIMEOUT_DEFAULTS) / record_decision signature (R11.8 / 10 field 個別引数 + private 任意 + decision_id/ts 自動生成) / normalize_frontmatter signature (R13.1) / check_decision_log_integrity signature (R11.15 / 4 診断項目) / EDGE_API_TIMEOUT_DEFAULTS dict (Round 1 重-1-2 で annotation 追加済) はすべて整合確認
  - 推奨案 X1 (Edge-domain 8 API に filter 引数追加 + 2 軸 filter 分離 Note) を 5 観点深掘り検証で確証 (案 X2 全 15 API に CommonFilter / X3 union 型は API 過剰複雑化で dominated)、user 2 択判断後に Edit 適用。
  - 適用結果: design.md QueryEngine Service Interface 8 API signature 修正 + Note 追加、Error Categories 表に RecordDecisionError 追加、change log に 2026-04-28 (Round 4 レビュー反映) を記録。
- 2026-04-28 (Round 5 レビュー結果記録): アルゴリズム + 性能検査 (12→10 統合済 = アルゴリズム + 性能を 1 ラウンドに集約) = 6 係数加重式 / Hygiene 進化則 / Louvain + Adamic-Adar / 性能目標。
  - **検出 [escalate 推奨] 1 件**: 軽-5-1 (Big O 表で `get_shortest_path` を "Dijkstra unweighted" と表記、unweighted は BFS が正、複数選択肢 trade-off で escalate 寄せ。Spec 1 R5 escalate Levenshtein 同型)
  - **確認結果 (検出なし)**: 6 係数加重式 (R5.1) / evidence-less ceiling 0.3 (R5.4) / explicitness_score 4 値 (R4.3) / Hygiene 進化則 (R5.6) / Hygiene 5 ルール固定実行順序 (R7.2) / Reinforcement 暴走防止 3 制約 (R7.7) / Usage signal 4 種別計算式 (R8.1, R8.2) / 3 段階閾値 (R6.3, R5.4) / Louvain MVP / Leiden Phase 3 (R15.1, Decision 5-5) / Adamic-Adar (R14.1) / 性能目標 R21 全項目 / Big O 計算量 (get_shortest_path 以外) / Reinforcement per-day cap 接触問題対処 (Decision 5-9, brief 第 4-E) / Autonomous 発火 trigger 4 条件 (R21.7) / Production deploy 性能達成可能性は Big O 計算で確認可能
  - 推奨案 X1 (BFS MVP 採択 + Big O 表訂正 + Phase 2/3 weighted Dijkstra 拡張余地) を 5 観点深掘り検証で確証 (案 X2 Dijkstra weighted MVP は overkill / X3 両方提供 API 拡張は signature 過剰で dominated)、user 2 択判断後に Edit 適用。
  - 適用結果: design.md Big O 表で `get_shortest_path` を BFS に訂正 + 意味論明示、Migration Strategy に "Phase 2/3 拡張余地: get_shortest_path weighted variant" 新節追加、change log に 2026-04-28 (Round 5 レビュー反映) を記録。
- 2026-04-28 (Round 6 レビュー結果記録): 失敗 handler + 観測性検査 (12→10 統合済 = 失敗 handler + 観測性を 1 ラウンドに集約) = 4 階層 exception / Rollback Strategy / partial failure / decision_id トレース / tmp 残留 cleanup。
  - **検出 [escalate 推奨] 1 件**: 重-6-1 (Error Strategy「4 階層 exception」表に Layer 5 = Decision Log 行が欠落、Round 4 で追加した RecordDecisionError が Business Logic Errors にだけ記載され構造的不均一、Spec 0 R2 重-厳-3 同型)
  - **検出 [取り下げ] 2 件**: 軽-6-2 (decision_id トレース連鎖の具体例明示) → R11.16 outcome.followup_ids + DiagnosticsCalculator で必要十分 / 軽-6-3 (exit code → exception 対応の集約表) → exit code 制御は Spec 4 CLI dispatch の責務、本 spec は同期 API
  - **確認結果 (検出なし)**: partial failure 伝搬 (R4.10 + R18.8 = extract batch per-page continue-on-error / Edge API timeout Spec 7 orchestration 伝搬) / decision_id トレース (R11.16 followup_ids) / Severity 4 水準 + exit code 0/1/2 分離 (Foundation R11 継承) / tmp 残留 cleanup 3 step (R7.11) / Hygiene Rollback (R7.3, R7.10) / Edge API timeout 内部状態整合 (R18.8) / Monitoring メトリクス 8 種 (R16.8、L2 4 種 + Decision Log 健全性 4 種) / 3 区分 (User / System / Business Logic Errors) はすべて整合確認
  - 推奨案 X1 (表に L5 行追加 + 4→5 階層訂正) を 5 観点深掘り検証で確証 (案 X2 4 階層維持で Layer 別表が不完全のまま残る dominated)、user 2 択判断後に Edit 適用。
  - 適用結果: design.md Error Strategy 表に L5 (Decision Log) 行 (RecordDecisionError) 追加、本文「4 階層」→「5 階層」訂正、change log に 2026-04-28 (Round 6 レビュー反映) を記録。
- 2026-04-28 (Round 7 レビュー結果記録): セキュリティ検査 = subprocess shell injection (LLM CLI) / Path traversal (page_path / edge_id / new_endpoint) / decision_log selective privacy 切替時の意味確定。
  - **検出 [escalate 推奨] 1 件**: 重-7-1 (sanitize_subprocess_args() の Layer 4c 配置 = Layer 3 / Layer 9 からの上向き依存 = DAG 違反、+ Spec 7 参照誤り = Decision 7-19 は cyclic import 禁止 + 6 module DAG であり、sanitization helper 集約パターンは Spec 7 Round 7 重-7-1。Spec 1 R5 escalate Levenshtein 同型)
  - **検出 [取り下げ] 2 件**: 軽-7-2 (gitignore mode 意味確定) → Decision 5-11 + brief 第 4-A 持ち越し handling として既正当化済 / 軽-7-3 (per-decision private redact 動作具体仕様) → R11.7 で要求は明示、redact 実装機構 (git filter / pre-commit hook) は Phase 5b 確定範囲
  - **確認結果 (検出なし)**: subprocess shell injection 防止 (shell=False + 引数 list 形式 + LLM CLI path config 注入) / subprocess timeout 必須 (Foundation R11) / Path traversal 防止 (page_path resolve + relative_to + edge_id hex 12 文字 regex) / `.rwiki/.hygiene.lock` 配置固定 / decision_log selective privacy (Decision 5-11) / `.archived/` git 管理対象 はすべて整合確認
  - 推奨案 X1 (sanitize 機能を Layer 1 `rw_atomic_io` 拡張に集約 + Spec 7 参照訂正) を 5 観点深掘り検証で確証 (案 X2 Layer 3/9 個別配置 = handler inconsistency / X3 上向き例外拡張 = 規範弱体化で dominated)、user 2 択判断後に Edit 適用。
  - 適用結果: design.md Security Considerations の sanitize 集約位置を Layer 1 (`rw_atomic_io`) に変更、`rw_atomic_io` Service Interface に sanitize helper 3 種 (sanitize_subprocess_args / sanitize_page_path / sanitize_edge_id) を追加、Module DAG / File Structure Plan で `rw_atomic_io` line budget を 250 → 350 行に拡張、Spec 7 参照を Round 7 重-7-1 (Layer 構造別の sanitization helper 集約パターン) に訂正、change log に 2026-04-28 (Round 7 レビュー反映) を記録。
- 2026-04-28 (Round 8 レビュー結果記録): 依存選定検査 = networkx ≥3.0,<3.5 + sqlite WAL + fcntl.flock + PyYAML + LLM CLI subprocess timeout 必須。
  - **検出 [自動採択、dominated 除外で唯一案] 1 件**: 軽-8-1 (Windows 互換性 = fcntl POSIX のみの規範前提が design 内で曖昧、Spec 1 R7 escalate 規範前提曖昧化 同型)
  - **確認結果 (検出なし)**: networkx version pin (R15.6 / R23.7 / Decision 5-1 = `>= 3.0, < 3.5`) / networkx 3.x 機能 (Louvain / Adamic-Adar / shortest_path / simple_cycles / connected_components / pagerank すべて 3.0-3.4 範囲で利用可能) / sqlite3 (Python 標準、WAL mode 対応) / PyYAML (既存依存継承) / LLM CLI subprocess timeout 必須 (Foundation R11、L3 EntityExtractor 60s default / L3 RelationExtractor 120s default) / Allowed Dependencies completeness (external 1 + Python 標準 13 + subprocess 経由 + PyYAML) / roadmap.md「Constraints: 追加依存は networkx ≥ 3.0 のみ」整合 / v1 から継承する技術決定 9 項目 (Round 1 軽-1-5 で訂正済) はすべて整合確認
  - dominated 判定 (案 X2 Foundation 改版 = 大規模変更で本 spec 内吸収可能 / 案 X3 portalocker 追加 = roadmap.md「Constraints」違反)、唯一案 X1 (本 spec 内吸収で OS サポート規範前提明示) を自動採択。
  - 適用結果: design.md Allowed Dependencies に「OS サポート = macOS / Linux のみ (POSIX、fcntl 利用)、Windows 非対応」追加、Decision 5-3 のタイトル + Context + Alternatives 4 種 + Rationale + Trade-offs + Follow-up すべてに POSIX 限定 + Windows Phase 2/3 拡張余地を明示、Migration Strategy に新節「Phase 2/3 拡張余地: Windows サポート」追加 (案 A portalocker / 案 B 自前 OS 分岐 / 案 C Phase 4 持ち越し)、change log に 2026-04-28 (Round 8 レビュー反映) を記録。
- 2026-04-28 (Round 9 レビュー結果記録): テスト戦略検査 = TDD / Unit / Integration / E2E (P0/P1/P2) / Performance (1k/10k edges)。
  - **検出 [escalate 推奨] 1 件**: 重-9-1 (Testing Strategy Unit Tests entry で 3 module = rw_vocabulary / rw_atomic_io / rw_query_advanced の test 言及欠落、File Structure Plan の 23 test 1:1 列挙と不整合、Spec 0 R2 重-厳-3 + Round 1 重-1-1 同型 = 構造的不均一の連鎖再発)
  - **検出 [取り下げ] 1 件**: 軽-9-2 (cross-spec integration test の所管) → memory ハイブリッド方式ガイダンスは厳密規律ではなく provider/consumer 双方で test 持つことも妥当、escalate 必須条件 5 種非該当
  - **確認結果 (検出なし)**: Integration Tests 4 種 (Hygiene transaction + crash recovery R7.11 / extract-relations batch partial failure R4.10 / Page→Edge orchestration partial failure R18.8 / L3 related: cache sync R16.6) / E2E Tests 3 種 (P0 / P1 / P2 シナリオ) / Performance Tests 2 種 (get_neighbors / hygiene) / TDD 規律明示 (CLAUDE.md 継承 + Migration Strategy v1 継承) はすべて整合確認
  - 推奨案 X1 (Layer 1 / 7 entry に 3 module test 言及追加) を 5 観点深掘り検証で確証 (案 X2 File Structure Plan 縮小 = test coverage 低下で dominated)、user 2 択判断後に Edit 適用。
  - 適用結果: design.md Testing Strategy Layer 1 entry に rw_vocabulary + rw_atomic_io、Layer 7 entry に rw_query_advanced を追加、23 module ↔ 23 test 1:1 整合確保、change log に 2026-04-28 (Round 9 レビュー反映) を記録。
- 2026-04-28 (本質的厳しいレビュー結果記録): user 指示「Spec 5 の設計について本質的に厳しくレビュー」に応じた追加検査で、Round 1-10 では検出されなかった深層観点を点検。
  - **本質的整合性 9 大観点で検出ゼロ**: Curated GraphRAG 3 軸 (人間中心 + Hygiene 自己進化 + Reject-only) / §2.12 Evidence-backed (Evidence chain 逆追跡 + ceiling 0.3 + 6 係数) / §2.13 Curation Provenance (selective recording + reasoning hybrid + selective privacy) / L1↔L2↔L3 相互作用 (extract-relations + normalize_frontmatter + L3 sync + dangling 4 段階 degrade) / Page lifecycle 7 種 ↔ edge action 3 種 mapping (Spec 7 cmd_archive R2.4 履歴扱い / cmd_split user 個別判断 + edge_reassign 整合) / Spec 4/6/7 contracts (Round 1-9 修正後完全整合) / brief 持ち越し 3 件 (4-A / 4-B / 4-E、Decision 5-9 / 5-10 / 5-11 で全件解消済) / Concurrency single-user serialized + Phase 2 thread-safety 移行手順 / Migration P0-P4 段階 はすべて整合確認
  - **検出 [自動採択候補] 5 件 (補強)**: 軽-11-1 (Decision 5-10 Birthday paradox numerical 規模感 + Phase 3 拡張閾値 16 hex 不明示) / 軽-11-2 (Decision 5-6 6 係数値根拠 = evidence 0.35 最重視 〜 human 0.05 最小の各係数の理由 不明示) / 軽-11-3 (Decision 5-8 Hygiene 5 ルール固定順序の論理的根拠 = 5 step 依存連鎖 不明示) / 軽-11-4 (Decision 5-9 進化則の数値安定性議論 = bounded space + 線形上限 + sqrt 緩和 + independence + time_weight の 5 制約 不明示) / 軽-11-5 (Decision 5-2 External 更新 = git pull 後の cache invalidation 戦略 不明示)
  - dominated 判定: 全 5 件で escalate 必須条件 5 種非該当 (複数選択肢 / 規範範囲 / 設計決定間矛盾 / API 不整合 / failure mode いずれも該当せず)、設計内吸収範囲の文書補強。
  - 適用結果: Decision 5-2 / 5-6 / 5-8 / 5-9 / 5-10 すべてに補強文追加 (numerical 根拠 / 安定性議論 / 順序根拠 / 係数根拠 / cache invalidation 戦略)、本質的設計変更なし、approve 状態への進行に影響なし。change log に 2026-04-28 (本質的厳しいレビュー反映) を記録。
