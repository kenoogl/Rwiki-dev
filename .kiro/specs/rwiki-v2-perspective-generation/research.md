---
**Purpose**: Capture discovery findings, architectural investigations, and rationale that inform the technical design.
---

## Summary

- **Feature**: `rwiki-v2-perspective-generation` (Spec 6、Phase 5、Rwiki v2 MVP の最後の spec、本丸)
- **Discovery Scope**: Complex Integration (7 upstream specs に依存、独自に上流 schema 定義しない consumer 型 spec)
- **Key Findings**:
  - Spec 5 Query API 15 種が L2 Graph Ledger への **唯一の contract** (本 spec は ledger を直接 read/write しない)
  - Hypothesis 7-status は Page status (Spec 7 所管) と Edge status (Spec 5 所管) と **独立した第 3 軸** (Foundation R5)
  - L2 への全 feedback は `reinforced` event + context attribute (Spec 5 R10.1 11 種列挙の基本セット 8 種の 1 種、独自 event 名禁止)
  - Maintenance autonomous trigger 6 種は Spec 5 (a/b/c/d) + Spec 7 (e/f) が計算、本 spec は **surface のみ** (自動実行しない)
  - 5 段階処理フローは Perspective / Hypothesis 共通、差分は scoring 戦略 + 出力先 + filter 閾値のみ

## Research Log

### Spec 5 Query API contract (15 種)

- **Context**: 本 spec の Step 1-5 全 step が L2 ledger 情報を必要とするが、ledger 直接読込が禁止 (R11.1)。Spec 5 が SSoT として 15 API signature を固定済 (Spec 5 R14.1)。
- **Sources Consulted**: `.kiro/specs/rwiki-v2-knowledge-graph/design.md` v0.1 / `.kiro/specs/rwiki-v2-knowledge-graph/requirements.md` R14
- **Findings**:
  - P0 = 5 API (`get_edge_history` / `normalize_frontmatter` / `resolve_entity` / `record_decision` / `get_decisions_for`)
  - P1 = 6 API (`get_neighbors` / `get_shortest_path` / `get_orphans` / `get_hubs` / `find_missing_bridges` / `search_decisions`)
  - P2 = 4 API (`get_communities` / `get_global_summary` / `get_hierarchical_summary` / `find_contradictory_decisions`)
  - 共通 `CommonFilter` dataclass: `status_in: list[str]` / `min_confidence: float` / `relation_types: Optional[list[str]]`
  - 性能 SLA: `get_neighbors(depth=2)` で 100-500 edges を 100ms 以下、10K edges を 300ms 以下 (Spec 5 R21.3 / R21.4)
- **Implications**:
  - 本 spec の Pipeline.Step 2 は `get_neighbors` / `get_shortest_path` を使い分ける必要 (depth + filter で過剰 traverse 回避)
  - Step 4 evidence 参照は `get_edge_history` で edge_events から取得
  - 本 spec の scoring 計算で必要な情報 (confidence / recency / novelty / bridge_potential) は **すべて API 経由** (R5.7)

### Skill dispatch 規約 (固定 skill 直接呼出、Spec 3 対象外)

- **Context**: v0.7.10 決定 6-1 で Perspective / Hypothesis は Spec 3 dispatch 対象外、固定 skill 直接呼出が確定 (R3 / Spec 3 R10)
- **Sources Consulted**: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.13 §11.2 v0.7.10 決定 6-1 / `.kiro/specs/rwiki-v2-prompt-dispatch/design.md` v0.1
- **Findings**:
  - `rw perspective` 実行時に `AGENTS/skills/perspective_gen.md` を **固定 skill 名で直接 load** (R3.1)
  - `rw hypothesize` 実行時に `AGENTS/skills/hypothesis_gen.md` を **固定 skill 名で直接 load** (R3.2)
  - `--skill <name>` flag は **要求しない** (distill 専用機能、R3.3)
  - skill 不在 / status != active なら **ERROR で拒否、generic_summary fallback には降格しない** (R3.5)
  - 両 skill は Spec 2 skill lifecycle (install / deprecate / retract) に参加
- **Implications**:
  - SkillInvoker component は dispatch ロジックを持たず、固定名 load + status check + ERROR 返却のみ
  - distill とは独立したシンプルな loader として実装可能

### Hypothesis 7-state lifecycle (Foundation R5 継承)

- **Context**: Hypothesis status 7 種が Page status / Edge status と独立した第 3 軸として確定 (Foundation R5、§5.9.1 整合性表)
- **Sources Consulted**: `.kiro/specs/rwiki-v2-foundation/requirements.md` R5 / `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.13 §5.9.1
- **Findings**:
  - 7 status: `draft / verified / confirmed / refuted / promoted / evolved / archived`
  - ALLOWED_TRANSITIONS (R7.3 で固定):
    - `draft → {verified}`
    - `verified → {confirmed, refuted, evolved, verified}` (再 verify 可)
    - `confirmed → {promoted, archived, evolved}`
    - `refuted → {archived, evolved}`
    - `evolved → {archived}`
    - `promoted → {}` (不可逆)
    - `archived → {}` (不可逆)
  - 物理削除しない (R7.7)、ディレクトリ移動を伴わない (R7.8)
  - status 遷移は frontmatter 編集のみで表現
- **Implications**:
  - HypothesisState は ALLOWED_TRANSITIONS 定数 + atomic frontmatter editor で十分、専用 state machine framework 不要
  - 7 状態の意味は frontmatter SSoT (Foundation §5.9.1) を参照、本 spec は遷移ルールのみ所管

### Verify workflow 半自動 4 段階

- **Context**: Karpathy 哲学 §1.3.5 「人間は判断、LLM は実務」に従い、人間が evidence 個別評価、LLM が候補抽出 + 集約判定 (R8)
- **Sources Consulted**: `.kiro/drafts/rwiki-v2-scenarios.md` Scenario 14 §3 / `.kiro/specs/rwiki-v2-perspective-generation/requirements.md` R8
- **Findings**:
  - Step 1: LLM が key terms (hypothesis 本文 + origin) で `raw/**/*.md` grep + semantic similarity → N=5 候補抽出
  - Step 2: user が個別に `supporting / refuting / partial / none` 4 択評価 (`--add-evidence <path>:<span>` で手動追加可)
  - Step 3: LLM 集約判定 (rules: `supporting≥2 ∧ refuting=0 → confirmed` / `refuting≥2 → refuted` / 混在 `partial` / 不足 `verified_pending`)
  - Step 4: frontmatter `verification_attempts` append + `reinforced` event (confirmed/refuted のみ) + `record_decision`
  - record_decision 失敗時は ERROR abort + atomic rollback (R8.7、verification_attempts append + status 遷移を取消)
  - Hypothesis status との対応: `confirmed → confirmed` 遷移 / `refuted → refuted` 遷移 / `partial → verified` 据置 / `verified_pending → verified` 据置 / `evolved → evolved` 遷移
- **Implications**:
  - VerifyWorkflow は 4 step を順次実行する関数 chain で十分 (state machine framework 不要)
  - record_decision 失敗時の rollback には atomic update 規律 (write-to-tmp → rename) が前提

### Maintenance autonomous trigger 6 種 surface

- **Context**: §2.11 Discovery primary / Maintenance LLM guide 原則に従い、Perspective / Hypothesis 利用中に蓄積メンテナンスタスクを能動的に surface (R10)
- **Sources Consulted**: `.kiro/drafts/rwiki-v2-scenarios.md` Scenario 33 / `.kiro/specs/rwiki-v2-knowledge-graph/requirements.md` R21.7 / `.kiro/specs/rwiki-v2-lifecycle-management/requirements.md` R13.7
- **Findings**:
  - Trigger 計算所管:
    - (a) reject queue ≥ 10 件: Spec 5 R21.7 (a)
    - (b) Decay 進行 edges ≥ 20 件 (未 usage > 7 日): Spec 5 R21.7 (b)
    - (c) Typed-edge 整備率 < 2.0: Spec 5 R21.7 (c)
    - (d) Dangling edge ≥ 5 件: Spec 5 R21.7 (d)
    - (e) Audit 未実行 ≥ 14 日: Spec 7 R13.7 (b)
    - (f) 未 approve synthesis ≥ 5 件: Spec 7 R13.7 (a)
  - Surface 規律: `💡` marker / 同 session 1 回まで / `/dismiss` / `/mute maintenance` 受付 / 閾値 config 上書き可
  - 閾値の SSoT は本 spec (R13.4 で確定)
- **Implications**:
  - MaintenanceSurface は Spec 5 / Spec 7 の診断 API を呼んで値を取得 + format するだけの薄い component
  - 表示 layer (`💡` marker 表示 / `/dismiss` 入力受付) は Spec 4 所管、本 spec は surface 内容生成のみ

### Atomic update 規律 (R12.8)

- **Context**: 並行 verify / approve 時の race condition と中断時の partial write を防ぐ (B 観点 並行性)
- **Sources Consulted**: `.kiro/specs/rwiki-v2-perspective-generation/requirements.md` R12.8 / R8.7 / R9.5
- **Findings**:
  - Atomic 更新 (write-to-tmp → rename) 対象 4 種:
    - (a) 対話ログ append (R12.4 / R12.5、per Turn)
    - (b) Perspective 保存版 ファイル新規作成 (R12.2)
    - (c) Hypothesis 候補 ファイル新規作成 (R12.3)
    - (d) Hypothesis frontmatter 編集 (R7 / R8.5 / R9.4 = status 遷移 / verification_attempts append / successor_wiki 記録)
  - record_decision 失敗時の rollback (R8.7 / R9.5) も atomic 更新で担保
- **Implications**:
  - 共通 atomic_write helper を rw_utils 系 (もしくは rw_perspective_types.py) に置く
  - per Turn append は新規 file 末尾追記時の atomic 化が必要 (中断時 partial flush 防止)、buffer flush 戦略は実装で詰める

### Failure mode handling (B 観点 5 種)

- **Context**: 第 4 ラウンド B 観点で identified 5 件の failure mode (requirements.md change log 第 4 ラウンド反映)
- **Sources Consulted**: requirements.md change log (2026-04-27 第 4 ラウンド反映)
- **Findings**:
  1. **R4.1**: `resolve_entity` が None / 例外 → WARN + exit 1 + entity 抽出推奨 message
  2. **R8.7**: `record_decision` 失敗 → verify 全体 ERROR abort + frontmatter atomic rollback
  3. **R9.5**: `record_decision` 失敗 → approve 全体 ERROR abort + status 遷移 + successor_wiki 記録 atomic rollback
  4. **R12.7**: `origin_edges` の edge が reject / deprecated → INFO skip + verify 結果出力に記録
  5. **R8.2**: raw 10K+ ファイル規模での grep + semantic similarity 性能 → incremental indexing 戦略は **design phase で確定** (本 design は contract のみ、実装段階で incremental indexing 戦略選定)
- **Implications**:
  - B 観点 failure mode は handler 層の defensive coding として明示する必要 (Components & Interfaces で明記)
  - R8.2 は本 design では「Verify Step 1 = LLM grep + semantic similarity (実装策略は incremental indexing 含めて実装段階確定)」と書き、design 持ち越し item を Open Questions / Risks に記録

### `reinforced` event 統一 (独自 event 名禁止)

- **Context**: 第 5 ラウンド波及精査で Spec 5 R10.1 11 種との不整合を発見 (`used_in_save_perspective` / `human_verification_support` を独自 event type として宣言していた)
- **Sources Consulted**: `.kiro/specs/rwiki-v2-knowledge-graph/requirements.md` R10.1 / requirements.md change log 第 5-A
- **Findings**:
  - Spec 5 R10.1 11 種列挙の基本セット 8 種に `reinforced` が存在
  - 本 spec が記録すべき event は **`reinforced` event 1 種のみ**
  - 独自意味は **context attribute** で記録: `usage_context` (Perspective `--save` 時) / `verification_type` / `verify_outcome` / `hypothesis_id` / `perspective_path` 等
  - usage_signal 種別 4 種 (Direct / Support / Retrieval / Co-activation) を別 attribute として記録
- **Implications**:
  - EdgeFeedback component は単一 entry point `reinforced(edge_id, usage_signal, context: dict)` で統一
  - Spec 5 R10.1 拡張可規約に従い、新 event type は本 spec で新設しない (Spec 5 を先行改版する規律)

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Layered (Types → Config → Spec5Client → Pipeline → Strategies → Handlers → CLI) | v1 module DAG 継承の階層構造 | 単純、修飾参照規律と整合、テスト容易、依存方向明確 | strategy 注入が必要 (Pattern 採用で吸収) | **採用** |
| Event-driven (message bus) | components が event 経由で通信 | 疎結合 | 過剰抽象、Spec 6 単体は単一 pipeline で十分、debug 困難化 | 却下 |
| Hexagonal (Port / Adapter) | core domain を adapter 層で隔離 | テスト容易性 ↑↑ | adapter 層追加負担、Spec 5 client が事実上 port 役、二重抽象になる | 却下 |
| Pipeline / Stage 関数連鎖 | 5 段階 pipeline を関数連鎖で実装 | シンプル、5 段階フロー (R4) と 1:1 対応 | strategy 注入で柔軟性確保が必要 | Pipeline 内部で **採用** (Layered の中で関数連鎖を使う) |

## Design Decisions

### Decision: 5 段階 pipeline を Perspective / Hypothesize 共通化 (Strategy 注入)

- **Context**: R4 が両 cmd で 5 段階フロー共有を規定。R5 で Perspective scoring (0.6c+0.3r+0.1n) と Hypothesis scoring (0.5n+0.3c+0.2bp) のみ別。
- **Alternatives Considered**:
  1. cmd_perspective と cmd_hypothesize で完全独立 pipeline 実装 → DRY 違反、5 段階重複
  2. 共通 pipeline + ScoringStrategy 注入 → DRY 達成、scoring 差分のみ Strategy で吸収
- **Selected Approach**: 共通 Pipeline class + ScoringStrategy interface (PerspectiveScoringStrategy / HypothesisScoringStrategy 2 実装)。Pipeline.invoke(request) が scoring + 出力先 + filter を request 内で受領し、両 cmd handler は Strategy 注入だけ行う。
- **Rationale**: Generalization 適用 (差は係数値・出力先・filter のみで処理本体は共通)、構造的に R4 と整合
- **Trade-offs**: Strategy 注入で軽い間接化が入るが、可読性・テスト分離性向上。
- **Follow-up**: scoring 計算で必要な情報 (recency / novelty / bridge_potential) を Spec 5 API から取得する helper を ScoringContext として渡す

### Decision: cmd_* 4 関数を 2 module に集約

- **Context**: 4 cmd handler (cmd_perspective / cmd_hypothesize / cmd_verify / cmd_approve_hypothesis) を物理 file 構成にどう分配するか
- **Alternatives Considered**:
  1. 各 cmd で 1 file (4 file)
  2. 機能対 (perspective vs verify) で 2 file
  3. 全 cmd を 1 file (1 file)
- **Selected Approach**: **2 file**
  - `rw_perspective.py` = `cmd_perspective` + `cmd_hypothesize` (生成系、共通 Pipeline 利用)
  - `rw_verify.py` = `cmd_verify` + `cmd_approve_hypothesis` (Hypothesis lifecycle 系、HypothesisState 共通利用)
- **Rationale**: Simplification 適用、機能の責務軸 (生成 vs lifecycle) と一致、各 file ≤ 300 行に収まる見込み
- **Trade-offs**: 4 file より import 連結が少し増えるが、責務軸 alignment で可読性向上

### Decision: Hypothesis state machine を frontmatter 編集のみで表現 (DB / 専用 framework 不使用)

- **Context**: R7.7 物理削除しない、R7.8 ディレクトリ移動しない、R7.8 frontmatter 編集のみで status 遷移
- **Alternatives Considered**:
  1. 専用 state machine framework (transitions library 等) → 過剰
  2. ALLOWED_TRANSITIONS dict + atomic frontmatter editor → シンプル
- **Selected Approach**: ALLOWED_TRANSITIONS 定数 + `transition(from, to)` 関数 + atomic frontmatter editor
- **Rationale**: Simplification 適用、Foundation §2.3 (status frontmatter 媒体) と整合、依存追加なし
- **Trade-offs**: 状態遷移の visualisation が code 内のみ。Mermaid stateDiagram で design.md に記録して mitigate。

### Decision: Atomic update を write-to-tmp → rename で統一 (4 対象)

- **Context**: R12.8 atomic 更新 4 対象 (対話ログ / Perspective 保存版 / Hypothesis 候補 / Hypothesis frontmatter 編集)
- **Alternatives Considered**:
  1. ファイル lock (fcntl) → 複雑、cross-platform 問題
  2. write-to-tmp → rename (POSIX rename atomicity) → シンプル、確立された pattern
- **Selected Approach**: 共通 `atomic_write(path, content)` helper を rw_utils に追加し、4 対象すべてで利用
- **Rationale**: 並行 verify / approve 時の race condition + 中断時 partial write を防ぐ最小実装
- **Trade-offs**: 一時 file が一瞬残る (rename atomic でカバー)、disk space 1 ファイル分一時的に倍

### Decision: Maintenance trigger 計算は Spec 5 / Spec 7 に委譲、本 spec は surface のみ

- **Context**: R10.2 が trigger 計算実装の所管を Spec 5 (a/b/c/d) + Spec 7 (e/f) に明示
- **Alternatives Considered**:
  1. 本 spec で trigger 計算実装 → R10.2 違反、L2 ledger 直接読が必要になる (R11.1 違反)
  2. Spec 5 / Spec 7 の診断 API (`rw doctor` 経由 or 直接 API) を呼んで値取得のみ → 規律遵守、責務分離
- **Selected Approach**: MaintenanceSurface component は Spec 5 / Spec 7 の診断 API を呼ぶだけの薄い orchestrator
- **Rationale**: 規律遵守 (R10.2)、責務分離 (R14)、本 spec の test scope を限定 (mock Spec 5 / Spec 7 で十分)
- **Trade-offs**: 診断 API が遅い場合 surface 表示が遅延 (cache せず R6.7 同方針 = 起動毎再計算で fresh-ness 優先)

### Decision: Edge feedback は `reinforced` event + context attribute で統一 (独自 event 名禁止)

- **Context**: 第 5-A 反映で Spec 5 R10.1 11 種との整合性確保
- **Alternatives Considered**:
  1. `used_in_save_perspective` / `human_verification_support` を独自 event type として Spec 5 に新設要請 → Spec 5 R10.1 拡張、本 spec の context attribute だけで実現可能なため過剰
  2. 既存 `reinforced` event + context attribute 記録 → Spec 5 R10.1 規約遵守、Hygiene Reinforcement 入力として動作
- **Selected Approach**: 単一 EdgeFeedback component が `reinforced(edge_id, usage_signal: Direct|Support|Retrieval|Co-activation, context: dict)` を Spec 5 経由で append。context dict に独自意味 (`usage_context` / `verification_type` / `verify_outcome` / `hypothesis_id` / `perspective_path` 等) を記録。
- **Rationale**: Spec 5 R10.1 拡張可規約遵守、本 spec の write 操作を最小 surface に圧縮
- **Trade-offs**: context attribute 検索が必要な future use case (= analytics) では Spec 5 query API 拡張が必要になる可能性 (現時点 deferred)

### Decision: Verify workflow を関数 chain で実装 (state machine framework 不使用)

- **Context**: R8 が 4 step を線形に列挙 (loop / branching なし)
- **Alternatives Considered**:
  1. 専用 state machine framework → 過剰、4 step に loop なし
  2. 関数 chain (Step 1 → Step 2 → Step 3 → Step 4) → 線形 R8 と 1:1 対応
- **Selected Approach**: VerifyWorkflow class が 4 method (`step1_extract_candidates` / `step2_collect_evaluations` / `step3_aggregate_judgement` / `step4_record`) を順次呼出。各 method 失敗時の rollback は Step 4 内で atomic 化。
- **Rationale**: Simplification、R8 と code 構造一致
- **Trade-offs**: 中断時の resume 機能なし (R8 が resume を要求しない、再 verify 可能 = R7.5 ALLOWED_TRANSITIONS で `verified → verified` 許可)

## Risks & Mitigations

- **R-1**: 並行 verify / approve 時の race condition (frontmatter 同時編集) → atomic update (write-to-tmp → rename) を 4 対象で徹底 (R12.8)、test_concurrent_verify_atomic_update で検証
- **R-2**: Verify Step 1 raw 10K+ ファイル grep の性能劣化 → design phase 段階では contract のみ、実装段階で incremental indexing 戦略 (e.g., ripgrep + ANN index) を選定 (R8.2 で design 持ち越し)
- **R-3**: Spec 5 record_decision API 失敗時の partial state → ERROR abort + atomic rollback (R8.7 / R9.5)、test_verify_workflow_record_decision_failure_rollback で検証
- **R-4**: origin_edges の edge が reject / deprecated 状態の event append 失敗 → INFO skip + verify 結果出力に skip 理由記録 (R12.7)、test_origin_edge_skip で検証
- **R-5**: cache 鮮度 stale で結果不整合 → 起動毎に config / 成熟度 / API 結果 を re-resolve (R6.7 / R13.7)、cache せず動作
- **R-6**: skill (perspective_gen / hypothesis_gen) 不在時の操作拒否で UX 劣化 → ERROR severity + 明確な error message (`<skill>` が `AGENTS/skills/` に存在しないため、Spec 2 で skill install を実行してください)、generic_summary fallback には降格しない (R3.5)
- **R-7**: refuted 時の delta 値 (`refuting_evidence_reinforcement_delta`) が Spec 5 config に未定 → design phase で Spec 5 と coordination 確定。本 design では「Spec 5 が config に新設要請」として記録 (R12.7 / R8.6)
- **R-8**: Maintenance autonomous trigger surface 表示中の Spec 5 / Spec 7 診断 API 性能不足 → 本 spec は cache せず再計算、性能問題は Spec 5 / Spec 7 側で解決 (本 spec scope 外)

## References

- [.kiro/drafts/rwiki-v2-consolidated-spec.md](../../drafts/rwiki-v2-consolidated-spec.md) v0.7.13 — §5.9.1 Hypothesis frontmatter / §5.9.2 Perspective frontmatter / §7.2 Spec 6 / §11.0 Scenario 25 / §11.2 v0.7.10 決定 6-1
- [.kiro/drafts/rwiki-v2-scenarios.md](../../drafts/rwiki-v2-scenarios.md) — Scenario 14 (本丸 5 段階フロー / 7 状態 / scoring) / Scenario 15 (interactive_synthesis 対話ログ) / Scenario 16 (query → synthesis 8 段階昇格) / Scenario 33 (Maintenance UX)
- [Spec 5 (knowledge-graph) design.md](../rwiki-v2-knowledge-graph/design.md) v0.1 — Query API 15 種 / L2 ledger schema / record_decision / Hygiene autonomous 4 trigger
- [Spec 7 (lifecycle-management) design.md](../rwiki-v2-lifecycle-management/design.md) v0.1 — cmd_promote_to_synthesis 8 段階対話 / Page lifecycle 5 status / 13.7 L3 診断項目 5 項目
- [Spec 4 (cli-mode-unification) design.md](../rwiki-v2-cli-mode-unification/design.md) v0.1 — CLI 統一規約 / exit code 0/1/2 / severity 4 / `--auto` 制御 / Maintenance UX 表示
- [Spec 2 (skill-library) design.md](../rwiki-v2-skill-library/design.md) v0.1 — 8 section skill schema / frontmatter 11 field / dialogue log 5 必須 field
- [Spec 3 (prompt-dispatch) design.md](../rwiki-v2-prompt-dispatch/design.md) v0.1 — Spec 6 dispatch 対象外明示
- [Spec 1 (classification) design.md](../rwiki-v2-classification/design.md) v0.1 — frontmatter 共通スキーマ / categories.yml / entity_types.yml / tags.yml
- [Spec 0 (foundation) design.md](../rwiki-v2-foundation/design.md) v0.1 — 13 中核原則 / Hypothesis status 7 種 / 3 層アーキテクチャ
- [.kiro/steering/roadmap.md](../../steering/roadmap.md) — Adjacent Spec Synchronization 運用ルール / v1 から継承する技術決定 / 5 Phase 実装順序
- Karpathy 哲学 §1.3.5 — 「失敗からも学ぶ」 (refuted hypothesis を物理削除しない根拠)
