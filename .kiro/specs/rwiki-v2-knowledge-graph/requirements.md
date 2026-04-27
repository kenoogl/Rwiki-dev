# Requirements Document

## Project Description (Input)

Rwiki v2 の中核価値である **Curated GraphRAG** は、L2 Graph Ledger という新しい層が成立してはじめて実現する。通常 GraphRAG は自動抽出 graph に対する人間レビュー層を持たずノイズが蓄積し、一方で全件 approve を要求すると入力コストが知識蓄積のボトルネックになる（§1.3.2 入力コスト問題）。Trust chain（evidence 裏付け）も切れやすく、LLM の hallucination との差別化が困難である。

本 spec（Spec 5、Phase 2）は、`rwiki-v2-foundation`（Spec 0）が固定したビジョン・原則・用語・3 層アーキテクチャ、特に §2.12 Evidence-backed Candidate Graph 原則の L2 専用適用と §2.2 / §2.4 への優先関係、§2.13 Curation Provenance、Edge status 6 種、§2.6 Git + 層別履歴媒体、§2.10 Evidence chain に準拠しつつ、L2 Graph Ledger を実装する。

具体的には、(a) Ledger 基盤（`entities.yaml` / `edges.jsonl` / `edge_events.jsonl` / `evidence.jsonl` / `rejected_edges.jsonl` / `reject_queue/` / `decision_log.jsonl` の append-only JSONL/YAML ledger および derived `.rwiki/cache/graph.sqlite`）、(b) `relations.yml` / `entity_types.yml` vocabulary、(c) Entity 抽出と正規化、(d) Relation 抽出（LLM 2-stage、evidence 必須、4 extraction_mode）、(e) Confidence scoring（§2.12 の 6 係数加重和の実装）、(f) Edge lifecycle（6 status の自動遷移）、(g) Graph Hygiene 5 ルール（Decay / Reinforcement / Competition / Contradiction tracking / Edge Merging）、(h) Usage signal 4 種別と数式、(i) Competition 3 レベル、(j) Event ledger（edge_events.jsonl の append-only 記録）、(k) Decision log（§2.13 selective recording）、(l) Reject workflow（reject_queue/ → rejected_edges.jsonl、unreject 復元）、(m) Entity ショートカット field の正規化（`normalize_frontmatter` API）、(n) Graph query API 15 種、(o) Community detection（networkx Leiden/Louvain）、(p) Graph audit、(q) Rebuild / sync（増分 / full / stale detection、L3 `related:` cache 同期）を、P0-P4 の 5 Phase で段階的に実装する。

L2 Graph Ledger 操作の CLI dispatch（引数 parse、対話 confirm、結果出力、exit code 制御）は Spec 4 が所管し、本 spec は内部 API を提供する。Page lifecycle の状態遷移は Spec 7 が所管し、本 spec は Spec 7 から呼び出される edge API（`edge demote` / `edge reject` / `edge reassign` 等）を提供する。Frontmatter スキーマは Spec 1 が宣言し、本 spec は宣言を読んで typed edge に展開するロジックを所管する。Skill 設計と dispatch は Spec 2 / Spec 3 の所管であり、本 spec は extraction skill の出力を validation して ledger に永続化する責務のみを担う。Perspective / Hypothesis 生成は Spec 6 の所管であり、本 spec は Query API を contract として提供する。

出典 SSoT: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §2.6（Git + 層別履歴媒体、JSONL 採用理由、edge_events.jsonl）/ §2.9（Graph as first-class）/ §2.10（Evidence chain）/ §2.12（Evidence-backed Candidate Graph、L2 専用、§2.2 / §2.4 優先）/ §2.13（Curation Provenance、decision_log.jsonl）/ §3.1-§3.3（3 層アーキテクチャ）/ §4.3（Graph Ledger 用語）/ §5.10（L2 記録形式）/ §7.2 Spec 5（中核）/ scenarios §13, §14, §34, §35, §36, §37, §38。Upstream: `rwiki-v2-foundation` requirements.md / `rwiki-v2-classification` requirements.md / `rwiki-v2-cli-mode-unification` requirements.md / `rwiki-v2-lifecycle-management` requirements.md。

## Introduction

本 requirements は、Rwiki v2 の Spec 5 として **L2 Graph Ledger（Evidence-backed Candidate Graph + Hygiene + Curation Provenance）** を定義する。読者は Spec 5 の実装者と、本 spec が所管する内部 API・ledger フォーマット・Hygiene 進化則を引用する Spec 4（cli-mode-unification、CLI dispatch）/ Spec 6（perspective-generation、Query API 利用）/ Spec 7（lifecycle-management、Page→Edge 相互作用）/ Spec 1（classification、Entity ショートカット field の宣言）/ Spec 2（skill-library、extraction skill）の起票者である。

本 spec は **L2 Graph Ledger を直接実装する spec** であり、規範文書（Foundation）とも frontmatter 宣言（Spec 1）とも CLI dispatch（Spec 4）とも異なり、ledger の data model・Hygiene 進化則・Query API・Curation Provenance の selective recording・External Graph DB export 等、実装される機能の中核を含む。したがって本 requirements の各 acceptance criterion は、(a) Ledger 基盤が満たすべきフォーマット要件と CRUD 動作要件、(b) Entity / Relation 抽出が満たすべき動作要件と evidence 必須規約、(c) Confidence scoring が満たすべき計算要件と evidence ceiling、(d) Edge lifecycle が満たすべき自動遷移と auto-accept 規約、(e) Hygiene 5 ルールが満たすべき動作要件と固定実行順序、(f) Usage signal 4 種別と暴走防止規約、(g) Competition 3 レベルと MVP / Phase 3 分離、(h) Decision log selective recording trigger、(i) Reject workflow と unreject 復元規約、(j) Entity ショートカット展開 API、(k) Query API 15 種の signature と返り値 schema、(l) Community detection と graph audit、(m) Rebuild / L3 `related:` cache sync、(n) Concurrency lock と Transaction semantics、(o) パフォーマンス目標、(p) Configuration 全項目、(q) 周辺 spec との境界・coordination 要件、として記述される。Subject は概ね `the Knowledge Graph` または個別コンポーネント（`the L2 Graph Ledger` / `the Confidence Scorer` / `the Graph Hygiene` / `the Reject Workflow` / `the Decision Log` / `the Query API` / `the Entity Normalizer` 等）を用いる。

本 spec の成果物は次の 11 種類に分類される。

- Ledger 基盤（7 ファイル：`entities.yaml` / `edges.jsonl` / `edge_events.jsonl` / `evidence.jsonl` / `rejected_edges.jsonl` / `reject_queue/` / `decision_log.jsonl`）と derived `.rwiki/cache/graph.sqlite`、および `.rwiki/vocabulary/relations.yml` / `entity_types.yml` の値定義
- Entity 抽出と正規化（LLM ベース、aliases / canonical 管理）
- Relation 抽出（LLM 2-stage、evidence 必須、4 extraction_mode、initial confidence 計算）
- Edge lifecycle（6 status の自動進化、auto-accept、6 status の意味と境界閾値）
- Graph Hygiene 5 ルール（Decay / Reinforcement / Competition L1 / Contradiction tracking / Edge Merging）と固定実行順序、all-or-nothing transaction、`.rwiki/.hygiene.lock` Concurrency
- Usage signal 4 種別（Direct / Support / Retrieval / Co-activation）の数式と暴走防止
- Decision log（§2.13 Curation Provenance、selective recording trigger、reasoning hybrid input、selective privacy）
- Reject workflow（reject_queue → rejected_edges.jsonl、reject reason 必須、unreject 復元）
- Entity ショートカット field の typed edge 展開（`normalize_frontmatter` API、双方向 edge 自動生成、confidence 0.9 固定、冪等性）
- Query API 15 種（neighbor / path / orphans / hubs / bridges / community / global summary / hierarchical summary / edge history / normalize_frontmatter / resolve_entity / record_decision / get_decisions_for / search_decisions / find_contradictory_decisions）と共通フィルタ、性能目標
- Rebuild / sync（増分 / full / stale detection、L3 `related:` cache invalidation の Hybrid stale-mark + Hygiene batch 戦略）、Graph audit、Community detection、外部 Graph DB export（P4 optional）

Spec 4-7 が本 spec を引用することで、L2 Graph Ledger の data model と Query API contract が複数 spec で分岐することを防ぐ。

## Boundary Context

- **In scope**:
  - **Ledger 基盤**: `.rwiki/graph/entities.yaml` / `edges.jsonl` / `edge_events.jsonl` / `evidence.jsonl` / `rejected_edges.jsonl` / `reject_queue/` / `decision_log.jsonl` の 7 ファイルを append-only JSONL / YAML として定義・操作。derived `.rwiki/cache/graph.sqlite` および `networkx.pkl`（gitignore）。
  - **Vocabulary**: `.rwiki/vocabulary/relations.yml`（typed relation の canonical 12 + 抽象 8 + Entity 固有 10+ セット、`inverse:` / `symmetric:` / `domain:` / `range:` 定義）/ `entity_types.yml` の値定義（スキーマ自体は Spec 1 が所管、本 spec は Spec 1 が宣言した mapping を読んで typed edge に展開する側）。
  - **Entity 抽出**: LLM ベースの entity 抽出、alias / normalization、`entities.yaml` 管理。
  - **Relation 抽出**: LLM 2-stage extraction（GraphRAG-inspired）、evidence 必須（evidence.jsonl への参照）、`extraction_mode` 4 種（`explicit` / `paraphrase` / `inferred` / `co_occurrence`）。
  - **Confidence scoring**: §2.12 の 6 係数加重和の実装（`evidence_score` 0.35 / `explicitness_score` 0.20 / `source_reliability` 0.15 / `graph_consistency` 0.15 / `recurrence_score` 0.10 / `human_feedback` 0.05）、evidence-less ceiling（0.3）の強制クランプ、係数値は `.rwiki/config.yml` の `graph.confidence_weights` から注入。
  - **Edge lifecycle**: 6 status（`weak` / `candidate` / `stable` / `core` / `deprecated` / `rejected`）の自動進化、3 段階閾値（auto_accept 0.75 / candidate_weak_boundary 0.45 / reject_queue_threshold 0.3）、Dangling edge policy（段階的 degrade、30 日継続で deprecated 自動遷移）。
  - **Graph Hygiene 5 ルール**: Decay / Reinforcement / Competition L1（MVP 必須）/ Contradiction tracking / Edge Merging。固定実行順序（Decay → Reinforcement → Competition → Contradiction tracking → Edge Merging）、all-or-nothing transaction（atomic rename）、`.rwiki/.hygiene.lock` 排他、Reinforcement の per-event / per-day 上限による暴走防止。
  - **Usage signal 4 種別**: Direct（1.0）/ Support（0.6）/ Retrieval（0.2）/ Co-activation（0.1）と式 `base_score × contribution × sqrt(confidence) × independence × time_weight`、`edge_events.jsonl` への記録。
  - **Competition 3 レベル**: L1 同一 node pair（MVP）、L2 類似 node pair（Phase 3）、L3 semantic tradeoff / contradiction（Phase 3）。winner→stable / runner-up→candidate / loser→weak / obsolete→deprecated の status transition。
  - **Event ledger**: `edge_events.jsonl` への **初期セット 11 event type** + 拡張可規約の append-only 記録。基本セット 8 種（`created / reinforced(Direct|Support|Retrieval|Co-activation) / decayed / promoted / demoted / rejected / merged / contradiction_flagged`、Foundation Requirement 12.3 と整合）+ 本 spec 追加 3 種（`dangling_flagged / unreject / reassigned`、Requirement 6.7 / 12.7 / 18.1 と整合）。
  - **Decision log（§2.13）**: `decision_log.jsonl` の append-only 記録、selective recording trigger、reasoning hybrid input（chat session auto-generate / `--reason` flag / default skip）、selective privacy（`config.decision_log.gitignore` / per-decision `private:` flag）、Tier 1（CLI views）/ Tier 2（markdown timeline）/ Tier 3（mermaid 埋込）の visualization。
  - **Reject workflow**: `reject_queue/` への candidate 蓄積、`rw reject` 経由の rejected_edges.jsonl 移動、reject_reason_category 6 種（`incorrect_relation` / `wrong_direction` / `low_evidence` / `context_mismatch` / `superseded` / `other`）と reject_reason_text 必須記録、`auto-batch` の取扱い、unreject 復元（status は candidate にリセット、confidence は evidence ceiling とのクランプ）。
  - **Entity ショートカット field 正規化**: `normalize_frontmatter(page_path) → List[Edge]` API、Spec 1 の `entity_types.yml` mapping を読み、双方向 edge 自動生成（`inverse:` / `symmetric:` 参照）、confidence 0.9 固定、extraction_mode=explicit、冪等性保証（edge_id は source+type+target hash）、alias 衝突時 canonical 優先と曖昧時警告。
  - **Query API 15 種**: `get_neighbors` / `get_shortest_path` / `get_orphans` / `get_hubs` / `find_missing_bridges` / `get_communities` / `get_global_summary` / `get_hierarchical_summary` / `get_edge_history` / `normalize_frontmatter` / `resolve_entity` / `record_decision` / `get_decisions_for` / `search_decisions` / `find_contradictory_decisions`。共通フィルタ（`status_in` / `min_confidence` / `relation_types`）、返り値スキーマ（edges.jsonl と同形）、性能目標（neighbor depth=2 ≤ 100ms）。
  - **Community detection**: networkx Leiden / Louvain、community id を node に格納、`rw audit graph --communities` 経由。
  - **Graph audit**: 対称性 / 循環 / 孤立 / 参照整合性 / confidence 分布 / events 整合性。
  - **Rebuild / sync**: 増分 rebuild（ingest / approve 後）、full rebuild（`rw graph rebuild`）、stale detection（CLI 起動時、`stale_pages.txt` ≥ 20 件で警告）、L3 `related:` cache sync（Hybrid stale-mark + Hygiene batch、5 step、`stale_pages.txt` フォーマット定義）。
  - **External Graph DB export（P4 optional）**: Neo4j / GraphML 等、要件発生時のみ。
  - **Configuration**: `.rwiki/config.yml` の `graph.*`（auto_accept_threshold / candidate_weak_boundary / reject_queue_threshold / evidence_required_ceiling / confidence_weights 6 係数 / hygiene 各パラメータ / usage_signal 4 重み + time_decay_half_life_days / competition フラグ / community algorithm / similarity_threshold）と `decision_log.*`（gitignore / auto_record_triggers 6 種 / reasoning_input 設定）の全項目を本 spec が所管。
  - **Concurrency**: Single-user serialized execution、`.rwiki/.hygiene.lock` の物理実装（fcntl/flock、stale lock 検出、PID 記録）、Transaction semantics（all-or-nothing、atomic rename）。
  - **外部依存**: `networkx >= 3.0` の追加。
  - **`[[link]]` 並存**: `[[link]]` syntax を untyped edge として並存させ、後付け typing を可能にする規約。
- **Out of scope**:
  - **Perspective / Hypothesis 生成ロジック**: Spec 6（`rw perspective` / `rw hypothesize` の prompt 設計、autonomous モード、L2 traverse 戦略）。本 spec は Query API を contract として提供するのみ。
  - **Wiki page lifecycle**: Spec 7（`active` / `deprecated` / `retracted` / `archived` / `merged` の状態遷移、`successor` / `merged_from` / `merged_into` のセマンティクス、警告 blockquote 自動挿入、Backlink 更新）。本 spec は Spec 7 から呼び出される edge API（`edge demote` / `edge reject` / `edge reassign`）を提供する側。
  - **Skill 設計**: Spec 2（`AGENTS/skills/relation_extraction.md` / `entity_extraction.md` / `reject_learner.md` 等の prompt 内容、skill lifecycle）。本 spec は extraction skill の出力 schema を validation して ledger に永続化する側。
  - **Skill 選択 dispatch**: Spec 3（明示 → `type:` → category default → LLM 判断の優先順位）。
  - **Tag vocabulary**: Spec 1（`tags.yml` / `categories.yml` / `entity_types.yml` のスキーマ、tag 操作 CLI `rw tag *`、lint vocabulary 統合）。本 spec は `entity_types.yml` の mapping を **読む側** であり、宣言は Spec 1。
  - **Frontmatter スキーマ**: Spec 1（共通 / L3 wiki 固有 / review 固有 / Entity 固有ショートカット field の宣言）。本 spec は `normalize_frontmatter` API で展開するロジックを所管。
  - **CLI dispatch / argparse / chat 統合フレーム**: Spec 4（`rw graph *` / `rw edge *` / `rw reject` / `rw extract-relations` / `rw audit graph` / `rw decision *` の引数 parse、対話 confirm UI、`--auto` ポリシー、exit code 制御）。本 spec は内部 API を提供する側。
  - **`rw doctor` の診断項目本体ロジック**: Spec 4（CLI 集約）/ 本 spec（L2 診断項目 + Decision Log 健全性診断項目の計算）/ Spec 7（L3 診断項目の計算）の責務分担。本 spec は **L2 診断項目 4 種**（reject queue 件数 / decay 進行中 edges 件数 / typed-edge 整備率 / dangling evidence 件数、Requirement 16.8）+ **Decision Log 健全性診断項目 4 種**（append-only 整合性 / 過去 decision 矛盾候補件数 / schema 違反件数 / `context_ref` dangling 件数、Requirement 11.15 `check_decision_log_integrity()` API）の計算 API を提供。
  - **Severity 4 水準と exit code 0/1/2 分離の規約定義**: Foundation Requirement 11 / roadmap.md「v1 から継承する技術決定」 が固定済、本 spec は継承。
- **Adjacent expectations**:
  - 本 spec は Foundation（Spec 0、`rwiki-v2-foundation`）が固定する 13 中核原則のうち §2.6 Git + 層別履歴媒体 / §2.9 Graph as first-class / §2.10 Evidence chain / §2.12 Evidence-backed Candidate Graph（L2 専用、§2.2 / §2.4 優先）/ §2.13 Curation Provenance を **設計前提** として参照し、独自定義による再解釈・再命名を行わない。Foundation の用語と矛盾する記述が必要になった場合は先に Foundation を改版し、その後本 spec を更新する（roadmap.md「Adjacent Spec Synchronization」運用ルールに従う）。
  - 本 spec は Spec 1（`rwiki-v2-classification`）が宣言する Entity 固有ショートカット field（`authored:` / `collaborated_with:` / `mentored:` / `implements:` 等）の存在・型・許可値を **唯一の入力スキーマ** として参照し、独自に field を追加・改名しない。新規 entity type および新規ショートカット field が必要になった場合は先に Spec 1 を改版する（roadmap.md「Adjacent Spec Synchronization」運用ルール）。
  - 本 spec は Spec 1（`rwiki-v2-classification`）が宣言した L3 frontmatter `related:` field の cache 規約に従い、L2 `edges.jsonl` を正本として L3 `related:` を sync する責務を所管する。Spec 1 は cache 規約定義側、本 spec は cache invalidation / sync 実装側。
  - Spec 4（`rwiki-v2-cli-mode-unification`）は本 spec の内部 API（`rw graph *` / `rw edge *` / `rw reject` / `rw extract-relations` / `rw audit graph` / `rw decision *` の各 handler）を CLI dispatch する。本 spec は API の signature と返り値（exit code 0/1/2 分離 / JSON / human-readable）を Spec 4 が利用可能な形で提供する。
  - Spec 4 と本 spec は `.rwiki/.hygiene.lock` の concurrency strategy を整合させる。本 spec は lock の物理実装（fcntl/flock、stale lock 検出、PID 記録）を所管し、Spec 4 は CLI 側の取得・解放 API を呼び出す責務を持つ。
  - Spec 7（`rwiki-v2-lifecycle-management`）は Page→Edge 相互作用 orchestration の呼出側として、本 spec が提供する edge API（`edge demote(edge_id, reason)` / `edge reject(edge_id, reason_category, reason_text)` / `edge reassign(edge_id, new_endpoint)`）を呼び出す。本 spec はこれら API の signature と error code を Spec 7 と coordination して確定し、内部状態遷移（confidence 更新 / `edge_events.jsonl` への append / `rejected_edges.jsonl` への移動 / `relations.yml` 参照 / decision_log 記録）を所管する。
  - Spec 6（`rwiki-v2-perspective-generation`）は Query API（`get_neighbors` / `get_shortest_path` / `find_missing_bridges` / `get_communities` 等）を contract として呼び出す。本 spec は API の signature と返り値 schema（edges.jsonl と同形 dict）を Spec 6 が依存する形で提供する。
  - Spec 2（`rwiki-v2-skill-library`）は extraction skill（`relation_extraction.md` / `entity_extraction.md`）の prompt と内容を所管し、本 spec は skill の出力 schema を validation interface として固定する。本 spec は skill の出力を受けて ledger に永続化する側。
  - 本 spec は Severity 4 水準（CRITICAL / ERROR / WARN / INFO）と exit code 0/1/2 分離（PASS / runtime error / FAIL 検出）と LLM CLI subprocess timeout 必須を Foundation Requirement 11 / roadmap.md「v1 から継承する技術決定」 経由で継承し、独自に再定義しない。

## Requirements

### Requirement 1: Ledger 基盤（7 ファイル + derived cache）

**Objective:** As a Spec 4 / Spec 6 / Spec 7 起票者, I want L2 Graph Ledger の物理ファイル構成・フォーマット・git 管理方針が一意に定義されている, so that 各 spec が ledger を直接読まず本 spec の API 経由でアクセスでき、ファイル構成の変更が呼出側に波及しない。

#### Acceptance Criteria

1. **[P0]** The L2 Graph Ledger shall `.rwiki/graph/` 配下に `entities.yaml` / `edges.jsonl` / `edge_events.jsonl` / `evidence.jsonl` / `rejected_edges.jsonl` / `reject_queue/` / `decision_log.jsonl` の 7 ledger 構成要素を配置することを規定する。
2. **[P0]** The L2 Graph Ledger shall `entities.yaml` を YAML フォーマットで管理し、各 entity に `canonical_path`（wiki path）/ `entity_type`（entity 種別、`entity_types.yml` の値、Spec 1 Requirement 2.3 と整合）/ `aliases`（文字列配列）の 3 項目を最低限含む構造として定義する。
3. **[P0]** The L2 Graph Ledger shall `edges.jsonl` / `edge_events.jsonl` / `evidence.jsonl` / `rejected_edges.jsonl` / `decision_log.jsonl` を **JSONL（1 行 1 record）** フォーマットで管理し、いずれも append-only として運用することを規定する（§2.6 と整合）。
4. **[P0]** The L2 Graph Ledger shall `edges.jsonl` の各 record を `edge_id` / `source` / `type` / `target` / `confidence` / `status` / `evidence_ids` / `extraction_mode` / `created_at` / `updated_at` / `source_file` / `is_inverse` の 12 field で最低限構成することを規定する（§5.10 SSoT と整合）。
5. **[P0]** The L2 Graph Ledger shall `evidence.jsonl` の各 record を `evidence_id` / `file` / `quote` / `span` / `added_at` の 5 field で最低限構成することを規定し、frontmatter 由来の特殊 evidence は `file: "frontmatter"` として登録することを規定する。
6. **[P0]** The L2 Graph Ledger shall 上記 7 ledger 構成要素を **すべて git 管理対象** とし、`.rwiki/cache/graph.sqlite` および `.rwiki/cache/networkx.pkl` を **derived cache として gitignore** とすることを規定する（§2.6 と整合）。
7. **[P0]** The L2 Graph Ledger shall ledger ファイルへの物理削除を行わないことを規定し、補正は append-only event（`edge_events.jsonl`）で表現することを必須とする（§2.6 と整合）。
8. **[P0]** The L2 Graph Ledger shall ledger ファイルの atomic 更新を「`write-to-tmp → fsync → rename`」のシーケンスで行い、途中クラッシュ時は git commit に revert 可能であることを規定する。

### Requirement 2: Vocabulary（`relations.yml` / `entity_types.yml` 値定義）

**Objective:** As a Spec 1 起票者および relation extraction skill 利用者, I want typed relation の canonical / 抽象 / Entity 固有セットと `inverse:` / `symmetric:` / `domain:` / `range:` の定義が `relations.yml` に固定されている, so that LLM 抽出と `normalize_frontmatter` が一意の vocabulary を参照できる。

#### Acceptance Criteria

1. **[P0]** The L2 Graph Ledger shall `.rwiki/vocabulary/relations.yml` を初期 fixture として配布し、以下 3 セットを最低限含めることを規定する。
   - **Canonical 12 セット**（汎用抽出向け）: `uses` / `depends_on` / `causes` / `improves` / `degrades` / `compares_with` / `alternative_to` / `part_of` / `supports` / `contradicts` / `co_occurs_with` / `related_to`
   - **抽象関係 8 セット**（拡張、任意追加）: `similar_approach_to` / `contrasted_with` / `extended_by` / `unified_in` / `superseded_by` / `prerequisite_of` / `application_of` / `derived_from`
   - **Entity 固有 10+ セット**（frontmatter shortcut 経由）: `authored` / `authored_by` / `collaborated_with` / `mentored` / `mentored_by` / `implements` / `implemented_by` / `critiqued` / `advocates` / `contemporary_of` 等
2. **[P0]** The L2 Graph Ledger shall `relations.yml` の各 relation entry に `inverse:`（逆方向 relation の name、任意）/ `symmetric:`（真偽、対称関係を示す）/ `domain:`（許可される source entity type、任意）/ `range:`（許可される target entity type、任意）の 4 field を宣言可能にする。
3. **[P0]** The L2 Graph Ledger shall `entity_types.yml` の値定義を Spec 1 が宣言したスキーマに従って配置し、初期 entity type として最低 `entity-person` と `entity-tool` を含めることを規定する（Spec 1 Requirement 5 と整合）。
4. **[P0]** The L2 Graph Ledger shall vocabulary 拡張方針として「最初から大きな ontology は作らない、使用実態から必要なものを順次追加」を採用することを規定し、relation 追加時に `relations.yml` を編集すれば即座に LLM 抽出と normalize で利用可能になることを規定する。
5. **[P0]** If LLM 抽出で `relations.yml` に未登録の relation_type が出現した, then the L2 Graph Ledger shall その relation を rejected せず candidate として記録し、`rw audit graph --propose-relations` で人間レビュー候補として surface することを規定する。
6. **[P0]** The L2 Graph Ledger shall `relations.yml` / `entity_types.yml` を起動時に読み込み、cache せずに毎回最新を反映することを規定する（vocabulary 変更が即座に抽出 / normalize 結果に反映）。

### Requirement 3: Entity 抽出と正規化

**Objective:** As a relation extraction の前提整備者および query 利用者, I want L1 raw / L3 wiki から entity（人物・概念・手法）が LLM で抽出され、aliases と canonical_path が `entities.yaml` に正規化されている, so that edges の source / target が一意の entity id を指し、alias 表記揺れによる graph 分裂を防げる。

#### Acceptance Criteria

1. **[P0]** The Entity Extractor shall L1 raw および L3 wiki の markdown ページから entity を LLM ベースで抽出し、`entities.yaml` に append または upsert することを規定する。
2. **[P0]** The Entity Extractor shall 各 entity の `canonical_path` を一意の wiki path（または entity id）として固定し、`aliases` を 0 個以上の文字列配列として管理することを規定する。
3. **[P0]** When 抽出された entity が既存 `entities.yaml` の `aliases` または `canonical` に一致した, the Entity Extractor shall 既存 entity に統合することを規定する（重複生成しない）。
4. **[P0]** When 抽出された entity が既存 entity と類似（embedding 距離または name fuzzy match）するが完全一致しない, the Entity Extractor shall 候補として `review/relation_candidates/`（drafts §7.2 Spec 5 line 1789「Entity/Relation 抽出提案の承認 buffer」と整合、Spec 1 Requirement 4.8 で本 spec 所管として再委譲済 / Entity 候補も Relation 候補と同一 buffer に統合）に提示し、人間判断後に統合または別 entity として登録することを規定する。
5. **[P0]** The Entity Extractor shall extraction skill（`AGENTS/skills/entity_extraction.md`、内容は Spec 2 所管）の出力 schema として `name` / `canonical_path` / `entity_type`（`entity_types.yml` の値、Spec 1 Requirement 2.3 と整合）/ `aliases` / `evidence_ids` を validation 対象として固定することを規定する。
6. **[P0]** If extraction skill の出力が schema validation に失敗した, then the Entity Extractor shall ERROR severity で報告し、当該 entity を `entities.yaml` に登録しないことを規定する。
7. **[P0]** The Entity Extractor shall LLM CLI を呼び出す全 subprocess 起動箇所で subprocess timeout を必須設定として渡すことを規定する（roadmap.md「v1 から継承する技術決定」と整合）。

### Requirement 4: Relation 抽出（4 extraction_mode + evidence 必須）

**Objective:** As a L2 Graph Ledger の入力源, I want LLM 2-stage extraction が evidence 必須で動作し、4 extraction_mode（`explicit` / `paraphrase` / `inferred` / `co_occurrence`）が initial confidence 計算に反映される, so that trust chain が evidence なしに途切れることなく、抽出方法の確実性が confidence に正しく反映される。

#### Acceptance Criteria

1. **[P0]** The Relation Extractor shall LLM ベースの 2-stage extraction を実装し、Stage 1（候補抽出）→ Stage 2（evidence 紐付けと extraction_mode 確定）の 2 段階で edge を生成することを規定する。
2. **[P0]** The Relation Extractor shall 全 edge に evidence 必須を強制し、evidence なし edge は confidence ≤ 0.3 にクランプすることを規定する（§2.12 核心ルール 1 と整合、Requirement 7.5 と整合）。
3. **[P0]** The Relation Extractor shall `extraction_mode` を `explicit` / `paraphrase` / `inferred` / `co_occurrence` の 4 値として固定し、それぞれの explicitness_score を `explicit=1.0 / paraphrase=0.75 / inferred=0.5 / co_occurrence=0.25` として initial confidence に反映することを規定する（§2.12 と整合）。
4. **[P0]** When 抽出された edge が既存 edge と source / type / target で完全一致する, the Relation Extractor shall 重複 edge を生成せず既存 edge の `evidence_ids` を merge し、initial confidence を再計算することを規定する（冪等性、edge_id は source+type+target hash で決定）。
5. **[P0]** The Relation Extractor shall extraction skill（`AGENTS/skills/relation_extraction.md`、内容は Spec 2 所管）の出力 schema として `source` / `type` / `target` / `extraction_mode` / `evidence`（quote + span + source_file）を validation 対象として固定することを規定する。
6. **[P0]** The Relation Extractor shall scope 指定として `--scope=recent|wiki|all|path:<path>` を提供し、`--since "<duration>"`（例: "7 days"）と `--new-only`（typed edges がないページだけ）の絞込を支援することを規定する。
7. **[P0]** The Relation Extractor shall 抽出後に edge を初期 status として `candidate` に置き、initial confidence が `auto_accept_threshold`（default 0.75）以上であれば自動的に `stable` に昇格することを規定する（Requirement 8 と整合）。
8. **[P0]** The Relation Extractor shall LLM CLI を呼び出す全 subprocess 起動箇所で subprocess timeout を必須設定として渡すことを規定する。
9. **[P0]** The Relation Extractor shall `[[link]]` syntax を untyped edge として並存させ、後付け typing が可能であることを規定する（Spec 5 内部の untyped edge も `edges.jsonl` に格納し、relation_type は `untyped` または vocabulary が決まった時点で update）。
10. **[P0]** When `rw extract-relations --scope` で複数 page を batch 処理する間に **個別 page の抽出が失敗した**（LLM CLI subprocess timeout / skill schema validation 失敗 / I/O 障害等）, the Relation Extractor shall **per-page 単位の continue-on-error を default 動作** として扱い、失敗 page を集計しつつ残り page の処理を継続することを規定する。batch 完了時に partial failure が発生していた場合は **exit code 2（FAIL 検出、roadmap.md「v1 から継承する技術決定」exit code 0/1/2 分離と整合）** で終了し、JSON 出力に `partial_failure: true` / `successful_pages: int` / `failed_pages: List[{path, reason}]` / `total_pages: int` を含めることを規定する。完全成功時は exit code 0、handler 自身の例外（lock 取得失敗 / config parse 失敗 等）は exit code 1 として返し、append-only ledger と整合する形で部分成功記録（成功した page 分の edges）を保持することを規定する（§2.6 append-only / 失敗からも学ぶ思想と整合）。

### Requirement 5: Confidence scoring（6 係数加重和）

**Objective:** As a 全 edge の信頼度評価基盤, I want initial confidence が §2.12 の 6 係数加重和で計算され、係数値が `.rwiki/config.yml` から注入される, so that confidence 計算式が SSoT（§2.12）と一致し、係数値の調整が config 編集で完結する。

#### Acceptance Criteria

1. **[P0]** The Confidence Scorer shall initial confidence を以下の 6 係数加重和で計算することを規定する: `confidence_initial = 0.35 × evidence_score + 0.20 × explicitness_score + 0.15 × source_reliability + 0.15 × graph_consistency + 0.10 × recurrence_score + 0.05 × human_feedback`（§2.12 SSoT と完全一致、係数の合計は 1.0）。
2. **[P0]** The Confidence Scorer shall 各係数を以下のとおり計算することを規定する。
   - `evidence_score`: `evidence.jsonl` に紐付く裏付けの数と質（0-1）
   - `explicitness_score`: `extraction_mode` から決定（`explicit=1.0 / paraphrase=0.75 / inferred=0.5 / co_occurrence=0.25`）
   - `source_reliability`: 抽出元の信頼度（論文 > 個人メモ等、設定可能なヒューリスティック）
   - `graph_consistency`: 既存 graph との矛盾度（矛盾無し=1.0、矛盾あり=低下）
   - `recurrence_score`: 複数 source で再出現した頻度（0-1）
   - `human_feedback`: 過去の reject / confirm 履歴（0-1）
3. **[P0]** The Confidence Scorer shall 係数値を `.rwiki/config.yml` の `graph.confidence_weights` から注入することを規定し、本 spec のコードに係数値をハードコードしないことを規定する。
4. **[P0]** If `evidence_score == 0`（evidence 完全不在）, then the Confidence Scorer shall 最終 confidence を 0.3 を上限としてクランプすることを規定する（evidence-less upper bound、§2.12 核心ルール 1）。
5. **[P0]** The Confidence Scorer shall confidence 計算結果を edge の `confidence` field に格納し、計算根拠を `edge_events.jsonl` に `created` event として記録することを規定する。
6. **[P0]** While Hygiene 実行で confidence が更新される場合, the Confidence Scorer shall 進化則（`confidence_next = confidence_current + α × usage_signal + β × recurrence - γ × decay - δ × contradiction`）に従って confidence を更新することを規定する（§2.12 と整合、Requirement 9 と整合）。

### Requirement 6: Edge lifecycle（6 status の自動進化）

**Objective:** As a query / perspective / hypothesis 利用者, I want Edge が `weak` / `candidate` / `stable` / `core` / `deprecated` / `rejected` の 6 status を持ち、confidence 閾値で自動進化する, so that 高 confidence edge が auto-accept で stable に昇格し、低 confidence edge は reject queue に流れる流れが自動で成立する。

#### Acceptance Criteria

1. **[P0]** The L2 Graph Ledger shall Edge status を `weak` / `candidate` / `stable` / `core` / `deprecated` / `rejected` の 6 値として固定し、Foundation Requirement 5 / Spec 1 Requirement 13 と完全一致させる。
2. **[P0]** The L2 Graph Ledger shall 各 status の意味を以下のとおり定義する。
   - `weak`: 表示抑制低優先（confidence 0.3-0.45）、reject 推奨
   - `candidate`: 監視対象（confidence 0.45-0.75）、reject queue 任意
   - `stable`: auto-accept（confidence ≥ 0.75）、reject 可能
   - `core`: 高 confidence + 高 usage（運用基準は Hygiene が判定）、perspective / hypothesis の主活用対象
   - `deprecated`: traverse 対象外、Page deprecation orchestration や 30 日継続 dangling で遷移
   - `rejected`: `rejected_edges.jsonl` に保持、`rw edge unreject` で復元可能
3. **[P0]** The L2 Graph Ledger shall confidence 閾値（`auto_accept_threshold` default 0.75 / `candidate_weak_boundary` default 0.45 / `reject_queue_threshold` default 0.3 / `evidence_required_ceiling` default 0.3）を `.rwiki/config.yml` から注入し、ハードコードしないことを規定する。
4. **[P0]** When edge の confidence が `auto_accept_threshold` 以上に達した, the L2 Graph Ledger shall edge を `candidate → stable` に自動昇格し、`promoted` event を `edge_events.jsonl` に追記することを規定する（人間 approve 不要、§2.12 と整合）。
5. **[P0]** When edge の confidence が `candidate_weak_boundary` を下回った, the L2 Graph Ledger shall edge を `candidate → weak` に降格し、`demoted` event を追記することを規定する。
6. **[P0]** When edge の confidence が `reject_queue_threshold` を下回った, the L2 Graph Ledger shall edge を reject_queue 候補として `reject_queue/` に登録し、自動 reject は行わず人間判断を待つことを規定する（Requirement 12 と整合）。
7. **[P0]** The L2 Graph Ledger shall Dangling edge policy を 4 段階の degrade として実装することを規定する。
   - 1 件でも有効 evidence が残る: dangling evidence_id を edge の `evidence_ids` から除外、confidence を再計算
   - 全 evidence_ids が dangling: edge を `weak` に降格、confidence を 0.3 以下にクランプ、`dangling_flagged` event を追記
   - dangling 状態が **30 日以上継続**: Hygiene が `deprecated` に自動遷移
   - 人間が明示的に reject 判断: 通常の reject workflow
8. **[P0]** The L2 Graph Ledger shall edge を物理削除しないことを規定し、`rejected_edges.jsonl` に移動した edge も保持し、`rw edge unreject` で復元可能であることを規定する（§2.6 「失敗からも学ぶ」と整合）。

### Requirement 7: Graph Hygiene 5 ルール（固定実行順序 + Transaction）

**Objective:** As a L2 Graph Ledger の自律進化基盤, I want Hygiene 5 ルール（Decay / Reinforcement / Competition / Contradiction tracking / Edge Merging）が固定実行順序で all-or-nothing transaction として動作する, so that ルール間の依存（後段ルールが前段の結果に依存）が崩れず、途中クラッシュ時も ledger が整合した状態に戻る。

#### Acceptance Criteria

1. **[P2]** The Graph Hygiene shall 5 ルール（Decay / Reinforcement / Competition / Contradiction tracking / Edge Merging）を提供し、MVP は **Decay + Reinforcement + Competition L1** を必須実装することを規定する（Contradiction tracking と Edge Merging は P2 範囲、Competition L2/L3 は P3 範囲）。
2. **[P2]** The Graph Hygiene shall ルール実行順序を **Decay → Reinforcement → Competition → Contradiction tracking → Edge Merging** として固定し、並列実行を許可しないことを規定する（後段ルールが前段の結果に依存するため）。
3. **[P2]** The Graph Hygiene shall 1 回の Hygiene 実行を **all-or-nothing transaction** として動作させ、途中クラッシュ時は実行前の git commit に revert することを規定する（`.rwiki/.hygiene.tx.tmp/` 等の一時領域で書いて commit 時に merge、失敗時は tmp 破棄）。
4. **[P2]** The Graph Hygiene shall `edges.jsonl` / `edge_events.jsonl` の更新を atomic rename（`write-to-tmp → fsync → rename`）で行うことを規定する（Requirement 1.8 と整合）。
5. **[P2]** While Hygiene が実行中, the Graph Hygiene shall `.rwiki/.hygiene.lock` を `fcntl/flock` で取得し、ingest / reject / approve / extract-relations が lock 取得待ちまたは明示エラーで失敗することを規定する（Requirement 17 と整合）。Query API（read-only）は lock 不要で動作することを規定する。
6. **[P2]** The Graph Hygiene shall Decay ルールとして「時間経過で未使用 edges の confidence を `decay_rate_per_day` で減衰」を実装することを規定する（係数値は `.rwiki/config.yml` の `graph.hygiene.decay_rate_per_day` から注入、default 0.01）。
7. **[P2]** The Graph Hygiene shall Reinforcement ルールとして「Usage signal が高い edges の confidence を強化」を実装することを規定し、Reinforcement delta の暴走防止として **per-event 上限** 0.1 / **per-day 上限** 0.2 / **session 内重複は `independence_factor` で頭打ち** の 3 制約を強制することを規定する（§2.12 と整合）。
8. **[P2]** The Graph Hygiene shall Contradiction tracking ルールとして「矛盾 edges を **削除せず** `contradiction_with:` で相互参照」を実装することを規定し、両立しない関係を知識として保持することを規定する（Perspective 生成の土壌、§4.3 と整合）。
9. **[P2]** The Graph Hygiene shall `rw graph hygiene --dry-run` を読み取り専用として動作させ、`.rwiki/.hygiene.lock` 取得を要求しないことを規定する（Spec 4 Requirement 10.4 と整合）。
10. **[P2]** While Hygiene のいずれかのルールがランタイムエラーで失敗した場合, the Graph Hygiene shall ledger を実行前状態に restore し、失敗内容を stderr に出力し exit code 1 で終了することを規定する。
11. **[P2]** When 次回 Hygiene が起動した時点で `.rwiki/.hygiene.tx.tmp/` 等の残留 tmp 領域が存在した, the Graph Hygiene shall 残留 tmp 領域を「前回 Hygiene の crash による未完了 transaction」として検出し、起動前に **(a) 残留 tmp の破棄**（commit されていないため安全に削除可能）/ **(b) stale lock 検出と併発処理**（Requirement 17.3 と整合、PID が死亡プロセスを指す場合のみ lock 解放）/ **(c) WARN severity で「前回 Hygiene が異常終了、tmp 領域を破棄して再開」を stderr に通知** の 3 step を実行することを規定する（process kill / disk full / OOM 等で失敗時 tmp 破棄が走らなかった場合の安全回復、原子性保証の補完）。

### Requirement 8: Usage signal 4 種別（Direct / Support / Retrieval / Co-activation）

**Objective:** As a Reinforcement ルールの入力源, I want Usage signal が 4 種別の contribution_weight を持ち、`base_score × contribution × sqrt(confidence) × independence × time_weight` 式で計算され `edge_events.jsonl` に記録される, so that edge の使用実態が confidence に反映され、フィードバックループが暴走しない。

#### Acceptance Criteria

1. **[P2]** The Usage Signal shall 4 種別の contribution_weight を以下のとおり固定することを規定する。
   - **Direct**（直接引用）: 1.0、perspective / hypothesis answer の本文で edge を引用した場合
   - **Support**（補助引用）: 0.6、answer の補強として edge を参照（primary ではない）
   - **Retrieval**（検索ヒット）: 0.2、graph neighbor / path 探索で touch されたが answer に未採用
   - **Co-activation**（同時活性）: 0.1、同 session で他 edge と一緒に traverse された
2. **[P2]** The Usage Signal shall 計算式を `usage_signal = base_score × contribution_weight × sqrt(confidence) × independence_factor × time_weight` として固定することを規定する。
3. **[P2]** The Usage Signal shall `sqrt(confidence)` を高 confidence edge の自己強化緩和（フィードバックループ抑制）として適用することを規定する。
4. **[P2]** The Usage Signal shall `independence_factor` を「同一 session 内で既に強化済なら 0 に近づける」（spam 防止）として動作させることを規定する。
5. **[P2]** The Usage Signal shall `time_weight` を「古い event は減衰」（`time_decay_half_life_days` で調整、default 30 日）として動作させることを規定する。
6. **[P2]** When query / perspective / hypothesize の処理中に edge が touch / 引用された, the Usage Signal shall `edge_events.jsonl` に `reinforced` event を記録し、event の `signal` field に 4 種別のいずれかを記録することを規定する。
7. **[P2]** The Usage Signal shall contribution_weight 4 種別の値を `.rwiki/config.yml` の `graph.usage_signal.contribution_weights` から注入することを規定し、ハードコードしないことを規定する。

### Requirement 9: Competition 3 レベル

**Objective:** As a 重複・類似 edge の整理基盤, I want Competition が L1（同一 node pair、MVP）/ L2（類似、Phase 3）/ L3（semantic tradeoff、Phase 3）の 3 レベルで動作し、winner / runner-up / loser / obsolete の status transition が固定されている, so that 同一 node pair の重複が MVP で整理され、Phase 3 で類似・矛盾が構造化される。

#### Acceptance Criteria

1. **[P2]** The Graph Hygiene shall Competition L1（同一 node pair 内の複数 edge）を **MVP 必須** として実装し、最高 confidence edge を winner、他を runner-up / loser として status を更新することを規定する。
2. **[P3]** The Graph Hygiene shall Competition L2（類似 node pair、概念的に重複する edge、embedding 距離ベース）を **Phase 3** として実装することを規定し、`.rwiki/config.yml` の `graph.competition.enable_level_2` フラグ（default `false`）で有効化可能にする。
3. **[P3]** The Graph Hygiene shall Competition L3（semantic tradeoff / contradiction）を **Phase 3** として実装することを規定し、`graph.competition.enable_level_3` フラグ（default `false`）で有効化可能にする。L3 では両方の edge を残し `contradiction_with:` で相互参照することを規定する（削除しない、Perspective の土壌）。
4. **[P2]** The Graph Hygiene shall Competition の status transition を 3 レベル共通で `winner → stable / runner-up → candidate / loser → weak / obsolete → deprecated` として固定することを規定する（削除ではなく状態変更）。
5. **[P3]** The Graph Hygiene shall L2 Competition の `similarity_threshold` を `.rwiki/config.yml` の `graph.competition.similarity_threshold` から注入することを規定し、default 値を 0.85 とする。
6. **[P3]** The Graph Hygiene shall Edge Merging（Hygiene ルール 5、類似・重複 edges を 1 つに統合して ontology を自然形成）を **Phase 3** として実装することを規定し、L2 edge 単位での merging を行う（Page merged status とは別概念）。

### Requirement 10: Event ledger（edge_events.jsonl の append-only 記録）

**Objective:** As a edge の履歴トレーサビリティ基盤, I want `edge_events.jsonl` に **初期セット 11 event type**（基本セット 8 種 + 本 spec 追加 3 種、拡張可規約付き）を append-only で記録し、edge の confidence / status 変遷を時系列で復元できる, so that perspective / hypothesis の根拠を逆追跡でき、矛盾検出時の根本原因分析ができる。

#### Acceptance Criteria

1. **[P0]** The L2 Graph Ledger shall `edge_events.jsonl` の event type の **初期セット** を以下 11 種として規定し、Foundation Requirement 12.3 が列挙する 8 種（基本セット）を継承しつつ、本 spec が dangling edge policy（Requirement 6.7）/ unreject 復元（Requirement 12.7）/ edge reassign API（Requirement 18.1）に必要な 3 種を追加することを規定する（§2.6 / §4.3 / §5.10 と整合）。

   - **基本セット 8 種（Foundation Requirement 12.3 と整合）**: `created` / `reinforced(Direct|Support|Retrieval|Co-activation)` / `decayed` / `promoted` / `demoted` / `rejected` / `merged` / `contradiction_flagged`
   - **本 spec 追加 3 種**: `dangling_flagged`（全 evidence_ids が dangling 化、Requirement 6.7 と整合）/ `unreject`（rejected → candidate 復元、Requirement 12.7 と整合）/ `reassigned`（source / target 付け替え、Requirement 18.1 と整合）

   The L2 Graph Ledger shall **拡張可規約** として、本 spec が新 event type を追加する場合は本 spec の requirements で新値を宣言した上で Foundation Requirement 12.3 への Adjacent Sync 注記を経由する手順を採ることを規定する（roadmap.md「Adjacent Spec Synchronization」運用ルール、Requirement 11.2 decision_type 拡張可規約と統一の設計パターン）。`edge_events.jsonl` schema 自体（4 field 構成、Requirement 10.2）と event 固有 field 規約の本体は本 spec が所管する。
2. **[P0]** The L2 Graph Ledger shall 各 event record を `edge_id` / `event` / `delta`（confidence 変動量）/ `timestamp`（ISO 8601）の 4 field を最低限含む構造として規定し、event type 固有の field（例: `reinforced` の `signal` / `query_id` / `reason`、`rejected` の `reason` / `reviewer`）を追加可能にする。
3. **[P0]** When edge が新規生成された, the L2 Graph Ledger shall `created` event を `edge_events.jsonl` に追記し、`delta` に initial confidence を記録することを規定する。
4. **[P0]** When edge が auto-accept で `candidate → stable` に昇格した, the L2 Graph Ledger shall `promoted` event を追記し、`from` / `to` field に遷移前後の status を記録することを規定する。
5. **[P0]** When edge が reject された, the L2 Graph Ledger shall `rejected` event を追記し、`reason` field に reject_reason_category を記録することを規定する（Requirement 12 と整合）。
6. **[P0]** The L2 Graph Ledger shall `edge_events.jsonl` に対する物理削除を行わないことを規定し、訂正は compensating event（例: 誤った `reinforced` を打ち消す逆 delta event）で表現することを規定する。
7. **[P1]** The L2 Graph Ledger shall `get_edge_history(edge_id) → List[Event]` API を提供し、edge_events.jsonl から時系列順に event 配列を返すことを規定する（Requirement 14 と整合）。

### Requirement 11: Decision log（§2.13 Curation Provenance、selective recording）

**Objective:** As a curation provenance の保全基盤, I want `decision_log.jsonl` が selective recording trigger に従って append-only で記録され、reasoning が hybrid input（chat session auto-generate / `--reason` flag / default skip）で取得され、selective privacy（gitignore / per-decision `private:` flag）で sanitize 可能である, so that 「なぜそう curate したか」の WHY が evidence の WHAT と直交する次元として保全される。

#### Acceptance Criteria

1. **[P0]** The Decision Log shall `.rwiki/graph/decision_log.jsonl` を append-only JSONL として管理し、各 record に `decision_id` / `ts` / `decision_type` / `actor` / `subject_refs[]` / `reasoning` / `alternatives_considered[]` / `outcome` / `context_ref` / `evidence_ids[]` の 10 field を最低限含むことを規定する（§2.13 / §4.3 と整合）。
2. **[P0]** The Decision Log shall `decision_type` の **初期セット** を以下 22 種として規定し、起源 spec ごとに区分することを明示する。

   - **Edge 起源（4 種、本 spec 所管）**: `edge_extraction` / `edge_reject` / `edge_promote` / `edge_unreject`
   - **Hypothesis 起源（1 種、Spec 6 所管）**: `hypothesis_verify`
   - **Synthesis 起源（1 種、Spec 6 / Spec 7 所管）**: `synthesis_approve`
   - **Page lifecycle 起源（6 種、Spec 7 所管、Spec 7 Requirement 12.7 と整合）**: `page_deprecate` / `page_retract` / `page_archive` / `page_merge` / `page_split` / `page_promote_to_synthesis`
   - **Skill 起源（4 種、Spec 7 所管、Spec 7 Requirement 12.7 と整合）**: `skill_install` / `skill_deprecate` / `skill_retract` / `skill_archive`
   - **Vocabulary 起源（5 種、Spec 1 所管、Spec 1 Requirement 8.13 と整合）**: `vocabulary_merge` / `vocabulary_split` / `vocabulary_rename` / `vocabulary_deprecate` / `vocabulary_register`
   - **Hygiene 起源（1 種、本 spec 所管）**: `hygiene_apply`

   The Decision Log shall **拡張可規約** として、Spec 1（vocabulary 起源）/ Spec 6（hypothesis / synthesis 起源）/ Spec 7（page / skill lifecycle 起源）が新 `decision_type` 値を追加する場合、各 spec の requirements で新値を宣言した上で本 spec を Adjacent Sync で更新する手順を採ることを規定する（roadmap.md「Adjacent Spec Synchronization」運用ルール、Spec 4 Requirement 15.10 / Spec 7 Requirement 12.7 / Spec 1 Requirement 8.13 と整合）。`decision_log.jsonl` schema 自体（10 field 構成、Requirement 11.1）と selective recording ルール（Requirement 11.3 / 11.4）/ privacy mode（Requirement 11.7）/ reasoning input（Requirement 11.5 / 11.6）の本体は本 spec が所管する。
3. **[P0]** The Decision Log shall **selective recording trigger** を以下 5 条件として固定することを規定する。
   - **Confidence boundary**: `candidate_weak_boundary`（default 0.45）の ±0.05 範囲（`auto_record_triggers.confidence_boundary_window`）
   - **Contradiction 検出**: 矛盾検出時は必須記録
   - **Human action**: approve / reject / merge / split は必須記録
   - **Status 遷移**: `candidate → stable` 等の遷移時に必須記録
   - **Synthesis promotion**: `wiki/synthesis/` 昇格時に必須記録
4. **[P0]** The Decision Log shall **記録しない**（routine、event log で十分）対象を以下 3 条件として固定することを規定する: `hygiene_routine_decay` / `hygiene_routine_reinforce` / `extraction_with_confidence_above_0.85`。
5. **[P0]** The Decision Log shall reasoning 入力として hybrid 方式を採用することを規定する。
   - **Auto-generate from chat session**: `rw chat` 中の対話が context にある時、LLM が直近の議論を要約して reasoning 候補を生成（user 確認後採用、`auto_generate_from_chat: true`）
   - **Manual `--reason` flag**: `rw approve --reason "理由..."` で明示記述
   - **Default skip**: 入力負担回避時、`approved without specific reason` 等の default を採用（reasoning field は空ではなく "default" 印、`allow_default_skip: true`）
6. **[P0]** The Decision Log shall reasoning 必須（skip 不可）対象を以下 4 条件として固定することを規定する（`reasoning_input.require_for`）: `hypothesis_verify_confirmed` / `hypothesis_verify_refuted` / `synthesis_approve` / `retract`。
7. **[P0]** The Decision Log shall **selective privacy** として `.rwiki/config.yml` の `decision_log.gitignore`（default `false`、`true` で privacy mode）と per-decision `private:` flag をサポートすることを規定する。
8. **[P0]** The Decision Log shall `record_decision(decision) → decision_id` API を提供し、selective recording trigger を満たす場合のみ呼出側が invoke することを規定する（Requirement 14 と整合）。
9. **[P0]** The Decision Log shall `get_decisions_for(subject_ref) → List[Decision]` API を提供し、特定 edge / page / hypothesis に関連する decisions を時系列取得可能にすることを規定する。
10. **[P1]** The Decision Log shall `search_decisions(query, filter) → List[Decision]` API を提供し、reasoning text の keyword / type / actor / 期間で検索可能にすることを規定する。
11. **[P1]** The Decision Log shall **Tier 2 markdown timeline** を `rw decision render --edge <id>` 経由で `review/decision-views/<id>-timeline.md` として自動生成することを規定する。
12. **[P1]** The Decision Log shall **Tier 3 mermaid diagrams** を Tier 2 markdown timeline に gantt / flowchart として埋め込むことを規定する（Obsidian / GitHub で render 可能）。
13. **[P2]** The Decision Log shall `find_contradictory_decisions() → List[(Decision, Decision)]` API を提供し、過去 decisions 間で矛盾する判断（同一 subject に対する反対方向の decision）を検出可能にすることを規定する。
14. **[P0]** The Decision Log shall `context_ref` field を「decision の reasoning が依拠する議論ログへの link」（例: `raw/llm_logs/chat-sessions/<timestamp>-<session-id>.md#L42-67`、path 規約は Spec 4 Requirement 1.8 と整合）として運用し、議論本体は別 file で管理することで重複保存を避けることを規定する。
15. **[P1]** The Decision Log shall **Decision Log 健全性診断 API** として `check_decision_log_integrity() → IntegrityReport` を提供し、以下 4 診断項目を計算可能にすることを規定する（Spec 4 Requirement 4.5 / 8.2 と整合、`rw doctor` および Maintenance UX autonomous surface から呼び出される）。

    - **append-only 整合性**: timestamp 順序の逆転検出 / record 削除（compensating event 以外の物理削除）検出 / `decision_id` 重複検出
    - **過去 decision 間の矛盾候補件数**: `find_contradictory_decisions()`（Requirement 11.13）の集計件数
    - **schema 違反件数**: 必須 10 field（Requirement 11.1）の欠落 / `decision_type` 22 種（Requirement 11.2）外の不正値 / `actor` / `subject_refs` 等の型違反
    - **`context_ref` dangling 件数**: `context_ref` field が指す path（例: `raw/llm_logs/chat-sessions/<timestamp>-<session-id>.md#L42-67`）の対象ファイル消失検出 / line range 外参照検出 / `evidence_ids` の dangling と同様に参照整合性を保証（Requirement 11.14 / Spec 4 Requirement 1.8 path 規約と整合）
16. **[P0]** The Decision Log shall **partial failure 記録形式** として、`outcome` field 内に `partial_failure: bool` / `successful_edge_ops: int` / `failed_edge_ops: int` / `followup_ids: List[str]` の 4 field をサポートし、Spec 7 Requirement 3.7 / 3.8 から渡される partial failure 情報を `decision_type: page_*`（Page lifecycle 起源 6 種）の decision として記録可能にすることを規定する（Spec 7 Requirement 12.8 由来の edge API timeout も partial failure として `failed_edge_ops` に計上、Requirement 18.7 / 18.8 と整合）。

### Requirement 12: Reject workflow（reject_queue → rejected_edges.jsonl、unreject 復元）

**Objective:** As a 人間の reject-only filter 基盤, I want `reject_queue/` に candidate edges が蓄積され、`rw reject` 経由で `rejected_edges.jsonl` に移動し、reject_reason_category と reject_reason_text が必須記録され、`rw edge unreject` で復元可能である, so that §2.12 核心ルール 2（Reject-only filter）が成立し、失敗からも学べる ledger が維持される。

#### Acceptance Criteria

1. **[P0]** The Reject Workflow shall `reject_queue/` 配下に reject 候補 edges（confidence < `reject_queue_threshold`）を `<edge_id>.json` として蓄積することを規定する。
2. **[P0]** When `rw reject` が引数なしで呼び出された, the Reject Workflow shall `reject_queue/` から confidence 昇順で candidate edges を提示し、各 edge について `reject / keep / more-evidence-needed / skip` の 4 選択肢を提供することを規定する（Scenario 35 と整合）。
3. **[P0]** When `rw reject <edge-id>` で特定 edge が指定された, the Reject Workflow shall 該当 edge を `rejected_edges.jsonl` に移動し、reject_reason の入力を求めることを規定する（Simple dangerous op、1-stage confirm）。
4. **[P0]** The Reject Workflow shall `rejected_edges.jsonl` の各 entry に以下 8 field を必須記録することを規定する（§2.6 / Foundation Requirement 13.5 と整合）。
   - `edge_id` / `rejected_at`（ISO 8601 timestamp）
   - `reject_reason_category`（6 種定型: `incorrect_relation` / `wrong_direction` / `low_evidence` / `context_mismatch` / `superseded` / `other`）
   - `reject_reason_text`（自由記述、1 行以上、**空文字禁止**、`reject_learner` skill の学習素材として必須）
   - `rejected_by`（`user` / `auto-batch`）
   - `pre_reject_status`（reject 直前の edge status、unreject 時の復元に使用）
   - `pre_reject_evidence_ids`（reject 直前の evidence_ids）
   - `pre_reject_confidence`（reject 直前の confidence 値、float [0.0, 1.0]、unreject 時の復元クランプ計算に使用、Requirement 12.7 と整合）
5. **[P0]** If `reject_reason_text` が空文字または未指定で reject が要求された, then the Reject Workflow shall ERROR severity で操作を拒否し、reason の入力を求めることを規定する。
6. **[P0]** When `rw reject --auto-batch` が実行された, the Reject Workflow shall `confidence < reject_queue_threshold`（default 0.3）の edges を一括 candidate 化（`reject_queue/` への追加）するのみを行い、**実際の reject は 1 件ずつ user が確認してコミットする**ことを規定する（reject_reason_text は user 記述必須、1 件ずつ最小限の一言でよい）。
7. **[P0]** When `rw edge unreject <edge-id>` が実行された, the Reject Workflow shall 以下 5 step で復元することを規定する。
   - **Status**: reject 直前の `pre_reject_status` に復帰、ただし `stable` / `core` からの reject だった場合は `candidate` にリセット（時間経過による再評価を強制）
   - **Confidence**: `evidence_required_ceiling`（default 0.3）と `pre_reject_confidence` の **低い方にクランプ**（Requirement 12.4 で必須記録、`pre_reject_evidence_ids` から再計算ではなく直接保存値を参照することで決定的復元を保証）。reject 後の時間経過で decay が本来進行していたはずなので、復帰時点で一度リセットして Hygiene サイクルで再評価させる
   - **evidence_ids**: reject 時点の `pre_reject_evidence_ids` を復元、復元後 dangling チェックを走らせる
   - **Event**: `unreject` event を `edge_events.jsonl` に追記（`from: rejected`, `to: candidate`, `reason: <user_supplied>`）、理由記録は必須
   - **rejected_edges.jsonl からの移動**: 物理削除ではなく `status: unrejected` としてマーク、履歴保全
8. **[P0]** The Reject Workflow shall reject / unreject 操作を `decision_log.jsonl` に記録することを規定する（`decision_type: edge_reject` / `edge_unreject`、Requirement 11 と整合）。

### Requirement 13: Entity ショートカット field の正規化（`normalize_frontmatter` API）

**Objective:** As a Spec 1 の Entity 固有ショートカット field（`authored:` / `collaborated_with:` / `mentored:` / `implements:` 等）の展開実装, I want `normalize_frontmatter(page_path) → List[Edge]` API が `entity_types.yml` mapping を読み、双方向 edge を自動生成し、confidence 0.9 固定で edges.jsonl に append し、冪等性を保証する, so that ユーザーが frontmatter にショートカットを書くだけで typed edge が L2 ledger に展開される。

#### Acceptance Criteria

1. **[P0]** The Entity Normalizer shall `normalize_frontmatter(page_path) → List[Edge]` API を提供し、指定 page の frontmatter にある Entity 固有ショートカット field を typed edge に展開することを規定する。
2. **[P0]** The Entity Normalizer shall API の invoker として Spec 4 CLI の `rw ingest` / `rw approve` / `rw graph rebuild` が呼び出すことを規定する（直接実装は Spec 4 に置かない、Spec 5 API 経由で責務を集中）。
3. **[P0]** The Entity Normalizer shall 内部ロジックを以下 7 step で実装することを規定する。
   - **Step 1**: Entity 固有 field → `entity_types.yml` の mapping table を参照（Spec 1 が宣言）
   - **Step 2**: source は当該ページ、target は field の値（`[[link]]` または entity id）
   - **Step 3**: `extraction_mode` は `explicit`（frontmatter 明示のため最高 explicitness）
   - **Step 4**: `relations.yml` の `inverse:` / `symmetric:` に従って双方向 edge を自動生成（`authored` ⇄ `authored_by` 等）
   - **Step 5**: `evidence_ids` は空（frontmatter 自体が evidence、`evidence.jsonl` に特殊 source `"frontmatter"` で登録）
   - **Step 6**: confidence は **0.9 固定**（人間が直接記述した root of trust として高値固定）
   - **Step 7**: Entity alias 衝突時は `relations.yml` の `canonical:` 値を優先、曖昧時は警告出力（normalize は skip、user に手動 resolve を要求）
4. **[P0]** The Entity Normalizer shall **冪等性** を保証することを規定する（同一 page を複数回 normalize しても duplicate edge を作らない、edge_id は source+type+target の hash で決定、既存は upsert）。
5. **[P0]** The Entity Normalizer shall ショートカット field がいずれの登録 entity type にも属さない場合、当該 field を skip し、WARN として lint task に報告することを規定する（Spec 1 Requirement 5.6 と整合）。
6. **[P0]** The Entity Normalizer shall ユーザーが `entity_types.yml` に新規 entity type および新規ショートカット field を追加した場合、その mapping を即座に参照することを規定する（cache せずに毎回最新を反映）。

### Requirement 14: Query API 15 種（共通フィルタ + 性能目標）

**Objective:** As a Spec 6 / audit / CLI からの呼出側, I want Query API 15 種の signature と返り値 schema が固定され、共通フィルタ（`status_in` / `min_confidence` / `relation_types`）が指定可能で、性能目標（neighbor depth=2 で 100-500 edges を 100ms 以下）が満たされる, so that 呼出元が JSONL を直接読まず API contract に依存でき、性能要件が contract として保証される。

#### Acceptance Criteria

1. **[P1]** The Query API shall 以下 15 種の API を提供することを規定する（Phase マーカー付き、§Spec 5 Query API Design SSoT と整合）。
   - **[P0]** `get_edge_history(edge_id) → List[Event]`: edge_events.jsonl からの時系列復元
   - **[P0]** `normalize_frontmatter(page_path) → List[Edge]`: Requirement 13 と同じ
   - **[P0]** `resolve_entity(name_or_alias) → Entity`: entity 名または alias から `entities.yaml` の正規化 entity を返す（Spec 6 perspective / hypothesize の seed 正規化、Spec 5 内部の重複 entity 検出にも使用）
   - **[P0]** `record_decision(decision) → decision_id`: Requirement 11 と同じ
   - **[P0]** `get_decisions_for(subject_ref) → List[Decision]`: Requirement 11 と同じ
   - **[P1]** `get_neighbors(node, depth, filter) → List[Edge]`: N-hop 近傍取得
   - **[P1]** `get_shortest_path(from, to, filter) → List[Edge]`: 2 node 間最短経路
   - **[P1]** `get_orphans() → List[Node]`: 孤立 node（in_degree = out_degree = 0）
   - **[P1]** `get_hubs(top_n) → List[Node]`: 中心性 top N（degree / pagerank）
   - **[P1]** `find_missing_bridges(cluster_a, cluster_b, top_n) → List[(Node, Node, score)]`: 2 cluster 間の候補 edge（類似度ベース）
   - **[P1]** `search_decisions(query, filter) → List[Decision]`: Requirement 11 と同じ
   - **[P2]** `get_communities(algorithm) → List[Community]`: community detection の結果
   - **[P2]** `get_global_summary(scope, method) → Summary`: 大局 scope の集約
   - **[P2]** `get_hierarchical_summary(community_id) → Summary`: community 単位の on-demand 要約
   - **[P2]** `find_contradictory_decisions() → List[(Decision, Decision)]`: Requirement 11 と同じ
2. **[P1]** The Query API shall 共通フィルタ引数として以下 3 種を全 API 共通で提供することを規定する。
   - `status_in: List[EdgeStatus]` — edge status の集合（default `[stable, core]`）
   - `min_confidence: float` — 絶対値フィルタ（edge status filter とは独立）
   - `relation_types: List[str]` — relation_type の絞込（default 全て）
3. **[P1]** The Query API shall 返り値スキーマを `.rwiki/graph/edges.jsonl` と同形の dict として固定することを規定し、呼出元は JSONL を直接読まず API が返す dict に依存することを規定する。
4. **[P1]** The Query API shall `get_neighbors(depth=2)` を **100-500 edges 規模で 100ms 以下** で応答することを性能目標として規定する。
5. **[P2]** The Query API shall `get_neighbors(depth=2)` を **10,000 edges 規模で 300ms 以下** で応答することを規定する。
6. **[P2]** The Query API shall Community / global summary をキャッシュ利用とし、キャッシュ無効化を Hygiene バッチのタイミングで行うことを規定する。
7. **[P1]** The Query API shall SQLite cache（`.rwiki/cache/graph.sqlite`）ベースの高速 traverse を実装することを規定し、JSONL からの逐次読込ではなく SQL クエリによる絞込を行うことを規定する。
8. **[P1]** While Hygiene が実行中, the Query API shall lock 取得を要求せず動作することを規定する（Hygiene 実行中でも append-only の事前状態を読む、Requirement 7.5 と整合）。

### Requirement 15: Community detection（networkx Leiden / Louvain）

**Objective:** As a global query / hierarchical summary の前提, I want community detection が networkx ベース（Leiden / Louvain）で動作し、community id が node に格納される, so that GraphRAG 由来の 4 技法（Community detection / Global query / Missing bridge detection / Hierarchical summary on-demand）が成立する。

#### Acceptance Criteria

1. **[P2]** The Community Detector shall networkx ベースの community detection を実装し、algorithm として `louvain` および `leiden` を提供することを規定する（`.rwiki/config.yml` の `graph.community.algorithm` で選択、default `louvain`）。
2. **[P2]** The Community Detector shall community id を node（entity）に付与し、`.rwiki/cache/graph.sqlite` の nodes テーブルに格納することを規定する。
3. **[P2]** The Community Detector shall `rw audit graph --communities` 経由で community detection を起動可能にすることを規定する（CLI dispatch は Spec 4）。
4. **[P2]** The Community Detector shall `resolution` パラメータを `.rwiki/config.yml` の `graph.community.resolution` から注入することを規定し、default 値を 1.0 とする。
5. **[P2]** The Community Detector shall `get_communities(algorithm) → List[Community]` API を提供し、Spec 6 / audit / CLI から呼び出し可能にすることを規定する（Requirement 14.1 と整合）。
6. **[P0]** The L2 Graph Ledger shall 外部依存として `networkx >= 3.0` を新規追加することを規定する（roadmap.md「v1 から継承する技術決定」と整合、Foundation Requirement 11 と整合）。

### Requirement 16: Graph audit と Rebuild / sync

**Objective:** As a graph 整合性の保証および L3 `related:` cache の sync 基盤, I want `rw audit graph` で対称性 / 循環 / 孤立 / 参照整合性 / confidence 分布 / events 整合性を検査でき、`rw graph rebuild` で増分 / full rebuild が可能で、L3 `related:` cache が Hybrid stale-mark + Hygiene batch で sync される, so that ledger の整合性が定期的に検証され、L3 frontmatter `related:` が L2 正本と eventual consistency で同期する。

#### Acceptance Criteria

1. **[P1]** The Graph Audit shall `rw audit graph` の検査項目として「対称性（`inverse:` / `symmetric:` 違反）」「循環（cycle detection）」「孤立 node」「参照整合性（dangling evidence_ids、消失 entity 参照）」「confidence 分布」「events 整合性（rejected 済 edge への reinforcement 等）」を含むことを規定する。
2. **[P1]** The Graph Audit shall 検査結果を JSON / human-readable 両形式で出力可能とし、CI から下流 consumer が parse できる構造を提供することを規定する。
3. **[P1]** The Graph Rebuild shall **増分 rebuild**（ingest / approve 後）として、変更分のみを `.rwiki/cache/graph.sqlite` に反映することを規定する。
4. **[P1]** The Graph Rebuild shall **full rebuild**（`rw graph rebuild`）として、`edges.jsonl` 全体から `.rwiki/cache/graph.sqlite` を再生成することを規定する。
5. **[P1]** The Graph Rebuild shall **stale detection** として、CLI 起動時に `.rwiki/cache/stale_pages.txt` の蓄積件数が閾値（default 20 件）以上であれば「L3 sync 未反映 N 件、`rw graph hygiene` 推奨」と警告することを規定する。
6. **[P1]** The Graph Rebuild shall L3 `related:` cache invalidation 戦略を **Hybrid stale-mark + Hygiene batch** として 5 step で実装することを規定する。
   - **Step 1（Stale mark）**: edges.jsonl の追加・更新・削除イベントが発生したとき、影響する L3 page path を `.rwiki/cache/stale_pages.txt` に追記（append-only、重複は後続で解消）
   - **Step 2（Batch sync）**: Hygiene batch の最終段階で `stale_pages.txt` を読み、該当 page の `related:` を L2 ledger から再計算して frontmatter 更新、処理後 stale list をクリア。再計算時は **stable / core status の typed edge** のうち、**source ページの frontmatter Entity-specific shortcuts（`authored:` / `collaborated_with:` / `mentored:` / `implements:` 等、Spec 1 Requirement 5 で宣言）で表現される typed edge を除外** することを規定する（Spec 1 Requirement 5.5 / 10.1 と整合、shortcut field 自身が当該 edge の表現を担うため `related:` への重複展開は行わない、完全分離方針）
   - **Step 3（Stale detection）**: CLI 起動時に `stale_pages.txt` ≥ 20 件で警告（上記 Step 5）
   - **Step 4（Manual sync）**: `rw graph rebuild --sync-related` で即座実行可（緊急時）
   - **Step 5（整合性レベル）**: L3 `related:` は eventual consistency、正本は L2 ledger なので query / perspective / hypothesis は L2 を直接読み、cache 遅延の影響を受けない。全 typed edge を統合的に閲覧する用途は cache 統合ではなく L2 `edges.jsonl` を Query API（Requirement 14）経由で直接参照することが推奨される（Spec 1 Requirement 10.1 と整合）
7. **[P1]** The Graph Rebuild shall `stale_pages.txt` のフォーマットを「`page_path \t timestamp \t event_summary`」（タブ区切り）として固定することを規定し、batch sync 時に page_path 単位に集約することを規定する。
8. **[P1]** The Graph Audit shall **L2 診断項目** および **Decision Log 健全性診断項目** の計算 API を提供し、Spec 4 の `rw doctor` および Maintenance UX autonomous surface から呼び出し可能にすることを規定する（Spec 4 Requirement 4.5 / 4.7 / 7.7 / 8.2 / 8.7 と整合）。

   - **L2 診断項目（4 種、本 Requirement で集約）**: reject queue 件数 / decay 進行中 edges 件数 / typed-edge 整備率 / dangling evidence 件数
   - **Decision Log 健全性診断項目（4 種、Requirement 11.15 `check_decision_log_integrity()` API として提供）**: append-only 整合性 / 過去 decision 間の矛盾候補件数 / schema 違反件数 / `context_ref` dangling 件数

### Requirement 17: Concurrency（`.rwiki/.hygiene.lock`） + Single-user serialized

**Objective:** As a Spec 4 起票者および Hygiene と CLI 操作の整合性保証者, I want `.rwiki/.hygiene.lock` の物理実装を本 spec が所管し、Spec 4 と整合した取得・解放契約と Single-user serialized 動作モデルが固定されている, so that 複数 CLI プロセスが同時に `.rwiki/graph/*.jsonl` を書かないことが保証され、Hygiene と他操作の競合が起きない。

#### Acceptance Criteria

1. **[P2]** The L2 Graph Ledger shall Concurrency モデルを **Single-user serialized execution** として固定することを規定する（MVP の前提、Phase 2 以降で multi-user / distributed lock の検討余地）。
2. **[P2]** The L2 Graph Ledger shall `.rwiki/.hygiene.lock` の物理実装を `fcntl/flock` によるファイルロックとして提供することを規定し、Hygiene 実行中に取得し、終了時（成功・失敗いずれも）に解放することを規定する。
3. **[P2]** The L2 Graph Ledger shall lock ファイルに **PID 記録**（lock holder の特定）と **stale lock 検出**（プロセス死亡時の自動解放）を実装することを規定する。
4. **[P2]** While Hygiene が実行中, the L2 Graph Ledger shall ingest / reject / approve / extract-relations / `edge promote` / `edge demote` を lock 取得待ち（short wait）または明示エラーで失敗させることを規定する（Spec 4 Requirement 10.2 と整合）。
5. **[P2]** While Hygiene が実行中, the L2 Graph Ledger shall Query API（read-only）を lock 不要で動作させ、append-only の事前状態を読むことを規定する（Requirement 14.8 と整合）。
6. **[P2]** The L2 Graph Ledger shall lock 取得・解放 API を Spec 4 の CLI 側から呼び出し可能な形で提供することを規定する（Spec 4 Requirement 10.5 と整合）。
7. **[P2]** If lock 取得 / 解放がランタイムエラーで失敗した, then the L2 Graph Ledger shall lock の状態を不定にしないよう例外として上位層に伝搬することを規定する（lock の半状態を残さない）。

### Requirement 18: Page→Edge 相互作用 API（Spec 7 との coordination）

**Objective:** As a Spec 7 起票者, I want Page lifecycle 操作（deprecate / retract / merge）から呼び出される edge API（`edge demote` / `edge reject` / `edge reassign`）の signature と error code が本 spec で確定している, so that Spec 7 が呼出側として API のみを利用でき、edge 内部状態遷移の実装に立ち入らない。

#### Acceptance Criteria

1. **[P0]** The L2 Graph Ledger shall Spec 7 から呼び出される edge API として最低 3 種を提供することを規定する。各 API は **timeout を必須パラメータ** として受け取る（Requirement 18.7 / 18.8 と整合、timeout 値の確定は Spec 7 design phase）。
   - `edge_demote(edge_id, reason, timeout)`: edge を `stable / core → candidate` に降格、`demoted` event を追記
   - `edge_reject(edge_id, reason_category, reason_text, timeout)`: edge を `rejected_edges.jsonl` に移動、reject_reason を必須記録
   - `edge_reassign(edge_id, new_endpoint, timeout)`: edge の source または target を新しい endpoint に付け替え、`reassigned` または `merged` event を追記
2. **[P0]** The L2 Graph Ledger shall edge API の signature として必須パラメータ（`edge_id` / `reason_category` / `reason_text` / `actor` / `pre_status` / `timeout` / その他 design phase で確定）を Spec 7 と coordination して確定することを規定する（Spec 7 Requirement 3.5 / 12.3 / 12.8 と整合、`timeout` は Requirement 18.7 / 18.8 で必須化済み）。
3. **[P0]** The L2 Graph Ledger shall edge API を **同期 API** として提供することを規定し、Spec 7 が orchestration で逐次呼出可能であることを規定する（Spec 7 Requirement 12.4 と整合）。
4. **[P0]** When edge API のいずれかが呼び出された, the L2 Graph Ledger shall 内部状態遷移（confidence 更新 / `edge_events.jsonl` への append / `rejected_edges.jsonl` への移動 / `relations.yml` 参照）を完結し、`decision_log.jsonl` に該当 decision を記録することを規定する（Requirement 11 と整合）。
5. **[P0]** If edge API の呼出がランタイムエラーで失敗した, then the L2 Graph Ledger shall 例外として呼出側（Spec 7）に伝搬し、Spec 7 が follow-up タスクで事後判断を促せるよう失敗内容を含むエラー情報を返すことを規定する（Spec 7 Requirement 3.4 / 3.7 と整合）。
6. **[P0]** The L2 Graph Ledger shall L2 edge の独自 lifecycle（Hygiene による decay / reinforcement / Competition / Contradiction tracking 等）が Spec 7 から呼び出されないことを規定し、本 spec 内の自律進化として完結することを規定する（Spec 7 Requirement 12.5 と整合）。
7. **[P0]** The L2 Graph Ledger shall edge API（`edge_demote` / `edge_reject` / `edge_reassign`）の各呼出に **timeout を必須パラメータ** として受け取ることを規定する（Spec 7 Requirement 12.8 と整合、roadmap.md「v1 から継承する技術決定」の LLM CLI subprocess timeout 必須と並列概念、ただし edge API は内部関数呼出のため値・実装機構は別系統）。timeout 値の確定は Spec 7 design phase で行い、本 spec は signature として timeout パラメータの受付規約を所管する。
8. **[P0]** When edge API の呼出が timeout に達した, the L2 Graph Ledger shall 当該 edge 操作を **partial failure** として呼出側（Spec 7）に伝搬し、内部状態を timeout 発生時点の整合状態に保つことを規定する（途中 commit を残さない、`edges.jsonl` / `edge_events.jsonl` の atomic rename 規約に従う、Requirement 1.8 と整合）。Spec 7 は当該 edge 操作を `failed_edge_ops` に計上して follow-up タスク化し、orchestration 全体は継続する（Spec 7 Requirement 3.4 / 3.8 / 12.8 と整合）。

### Requirement 19: Coordination の責務分離（Spec 1 / 2 / 4 / 6 / 7）

**Objective:** As a 周辺 spec 起票者, I want 本 spec の所管（L2 Ledger 内部実装、Hygiene 進化則、Query API、Decision log、edge API）と周辺 spec の所管（CLI dispatch、Skill 内容、frontmatter スキーマ、Page lifecycle 状態遷移、Perspective / Hypothesis 生成）の境界が明文で固定されている, so that 周辺 spec 起票時に本 spec を再変更する coordination リスクが消える。

#### Acceptance Criteria

1. **[P0]** The L2 Graph Ledger shall **Spec 5 ↔ Spec 1 coordination** として、Entity 固有 field の **スキーマ宣言と `entity_types.yml` の mapping table 定義** を Spec 1 の所管とし、**展開ロジック実装（`normalize_frontmatter` API）** を本 spec の所管として明示する（Requirement 13 / Spec 1 Requirement 12 と整合）。
2. **[P0]** The L2 Graph Ledger shall **Spec 5 ↔ Spec 2 coordination** として、extraction skill（`relation_extraction.md` / `entity_extraction.md` / `reject_learner.md`）の **prompt 内容と skill lifecycle** を Spec 2 の所管とし、**skill の出力 schema の validation interface と ledger への永続化** を本 spec の所管として明示する。
3. **[P0]** The L2 Graph Ledger shall **Spec 5 ↔ Spec 4 coordination** として、L2 Graph Ledger 管理コマンド（`rw graph *` / `rw edge *` / `rw reject` / `rw extract-relations` / `rw audit graph` / `rw decision *`）の **CLI dispatch（引数 parse、対話 confirm、結果整形、exit code 制御）** を Spec 4 の所管とし、**内部 API（edges.jsonl 操作、Hygiene 進化則、reject queue の append-only 規約、initial confidence 計算、`relations.yml` 参照、`normalize_frontmatter` API、L2 診断項目の計算）** を本 spec の所管として明示する（Spec 4 Requirement 9 / 13.1 と整合）。
4. **[P0]** The L2 Graph Ledger shall **Spec 5 ↔ Spec 4 coordination** として、`.rwiki/.hygiene.lock` の **物理実装（fcntl/flock、stale lock 検出、PID 記録）** を本 spec の所管とし、**CLI 側の取得・解放 API 呼出契約** を Spec 4 の所管として明示する（Requirement 17 / Spec 4 Requirement 10 と整合）。
5. **[P1]** The L2 Graph Ledger shall **Spec 5 ↔ Spec 6 coordination** として、Query API 15 種の **signature と返り値 schema** を contract として固定し、Spec 6 が perspective / hypothesis 生成で本 spec の API のみに依存することを規定する（Requirement 14 と整合）。Perspective / Hypothesis の prompt 設計・autonomous モード・traverse 戦略は Spec 6 の所管。
6. **[P0]** The L2 Graph Ledger shall **Spec 5 ↔ Spec 7 coordination** として、edge API 3 種（`edge_demote` / `edge_reject` / `edge_reassign`）の **signature と error code** を本 spec の所管として確定し、Page→Edge 相互作用 orchestration の **呼出側責務** を Spec 7 の所管として明示する（Requirement 18 / Spec 7 Requirement 3 / 12 と整合）。
7. **[P0]** If 周辺 spec 起票時に本 spec の API signature・vocabulary 値・Hygiene 進化則・selective recording trigger に変更が必要になった, then the L2 Graph Ledger 実装者 shall 本 spec を先に改版する手順（roadmap.md「Adjacent Spec Synchronization」運用ルール）を参照点として残し、本 spec が独自に逸脱しないことを規定する。

### Requirement 20: Configuration（`.rwiki/config.yml` graph セクション全項目）

**Objective:** As a 本 spec 実装者および運用者, I want `.rwiki/config.yml` の `graph.*` および `decision_log.*` の全項目を本 spec が所管し、係数値や閾値をハードコードしないことが規定されている, so that 運用調整が config 編集で完結し、コード変更を伴わない。

#### Acceptance Criteria

1. **[P0]** The L2 Graph Ledger shall `.rwiki/config.yml` の `graph.*` セクションに以下の項目を所管することを規定する。
   - `auto_accept_threshold`（default 0.75）
   - `candidate_weak_boundary`（default 0.45）
   - `reject_queue_threshold`（default 0.3）
   - `evidence_required_ceiling`（default 0.3）
   - `confidence_weights`（6 係数：`evidence` 0.35 / `explicitness` 0.20 / `source_reliability` 0.15 / `graph_consistency` 0.15 / `recurrence` 0.10 / `human_feedback` 0.05、合計 1.0）
2. **[P0]** The L2 Graph Ledger shall `graph.hygiene.*` セクションに以下の項目を所管することを規定する。
   - `decay_rate_per_day`（default 0.01）
   - `usage_reinforcement_alpha`（default 0.05）
   - `recurrence_beta`（default 0.03）
   - `contradiction_penalty`（default 0.1）
   - `batch_schedule`（`weekly` または `on-demand`、default `weekly`）
   - `max_reinforcement_delta_per_event`（default 0.1、暴走防止）
   - `max_reinforcement_delta_per_day`（default 0.2、暴走防止）
3. **[P0]** The L2 Graph Ledger shall `graph.usage_signal.*` セクションに以下の項目を所管することを規定する。
   - `contribution_weights`（4 重み：`direct` 1.0 / `support` 0.6 / `retrieval` 0.2 / `co_activation` 0.1）
   - `time_decay_half_life_days`（default 30）
4. **[P0]** The L2 Graph Ledger shall `graph.competition.*` セクションに以下の項目を所管することを規定する。
   - `enable_level_2`（default `false`、Phase 3 で有効化）
   - `enable_level_3`（default `false`、Phase 3 で有効化）
   - `similarity_threshold`（default 0.85、L2 の embedding 距離閾値）
5. **[P0]** The L2 Graph Ledger shall `graph.community.*` セクションに以下の項目を所管することを規定する。
   - `algorithm`（`louvain` または `leiden`、default `louvain`）
   - `resolution`（default 1.0）
6. **[P0]** The L2 Graph Ledger shall `decision_log.*` セクションに以下の項目を所管することを規定する。
   - `gitignore`（default `false`、`true` で privacy mode）
   - `auto_record_triggers.confidence_boundary_window`（default 0.05）
   - `auto_record_triggers.record_on_human_action`（default `true`）
   - `auto_record_triggers.record_on_contradiction`（default `true`）
   - `auto_record_triggers.record_on_status_transition`（default `true`）
   - `auto_record_triggers.record_on_synthesis_promotion`（default `true`）
   - `auto_record_triggers.record_silent`（list: `hygiene_routine_decay` / `hygiene_routine_reinforce` / `extraction_with_confidence_above_0.85`）
   - `reasoning_input.auto_generate_from_chat`（default `true`）
   - `reasoning_input.allow_default_skip`（default `true`）
   - `reasoning_input.require_for`（list: `hypothesis_verify_confirmed` / `hypothesis_verify_refuted` / `synthesis_approve` / `retract`）
7. **[P0]** The L2 Graph Ledger shall 上記 config 値をコードにハードコードせず、起動時に config から注入することを規定する。
8. **[P0]** If `.rwiki/config.yml` が存在しない, then the L2 Graph Ledger shall default 値で動作し、INFO で「config 未配置、default 値で動作」と通知することを規定する。

### Requirement 21: パフォーマンス目標

**Objective:** As a 運用基準, I want Hygiene 実行時間と Query API 応答時間がパフォーマンス目標として規定されている, so that 本 spec 実装が性能上の前提を満たすことを検証可能になる。

#### Acceptance Criteria

1. **[P2]** The Graph Hygiene shall **1,000 edges 規模で `rw graph hygiene` 実行時間 ≤ 30 秒**、`--dry-run` 実行時間 ≤ 10 秒を満たすことを規定する。
2. **[P2]** The Graph Hygiene shall **10,000 edges 規模で `rw graph hygiene` 実行時間 ≤ 5 分**、`--dry-run` 実行時間 ≤ 1 分を満たすことを規定する。
3. **[P1]** The Query API shall **100-500 edges 規模で `get_neighbors(depth=2)` 応答時間 ≤ 100ms** を満たすことを規定する（Requirement 14.4 と整合）。
4. **[P2]** The Query API shall **10,000 edges 規模で `get_neighbors(depth=2)` 応答時間 ≤ 300ms** を満たすことを規定する（Requirement 14.5 と整合）。
5. **[P1]** The L2 Graph Ledger shall MVP 想定の Vault 規模を「個人用途で edges 500-5000、entities 100-500、evidences 1000-10000 程度」として明示することを規定する。
6. **[P3]** The Graph Hygiene shall 100,000 edges 規模（将来）では `--scope` による部分 Hygiene（community 単位 / 直近 N 日更新分）を推奨することを規定する（Phase 2 以降で詳細化）。
7. **[P2]** The Graph Hygiene shall **Autonomous 発火 trigger 条件** を以下 4 条件として固定することを規定し、いずれかに該当時に Maintenance autonomous mode（Spec 4 / Spec 6 の autonomous 提案）が「Hygiene を走らせますか？」を surface することを規定する。
   - **reject queue 蓄積**: 未処理 reject 候補 ≥ 10 件
   - **Decay 進行 edges**: `days_since_last_usage > decay_warn_days`（default 7）の edges ≥ 20 件
   - **typed-edge 整備率低下**: wiki ページあたり平均 typed-edge 数が閾値（default 2.0）未満
   - **Dangling edge 増加**: dangling_flagged 状態の edges ≥ 5 件

### Requirement 22: External Graph DB export（P4 optional）

**Objective:** As a 将来の外部システム連携要件発生時の備え, I want 外部 Graph DB（Neo4j / GraphML 等）への export が optional 機能として規定されている, so that Rwiki の JSONL を正本としつつ、必要時に外部の graph 可視化 / クエリツールに dump できる。

#### Acceptance Criteria

1. **[P4]** The L2 Graph Ledger shall 外部 Graph DB export を **P4 optional 機能** として位置付け、要件発生時のみ実装することを規定する（MVP 範囲外）。
2. **[P4]** Where 外部 Graph DB export が要件として発生した場合, the L2 Graph Ledger shall `rw graph export --format {neo4j|graphml|...}` のような export command を提供することを規定する（CLI dispatch は Spec 4）。
3. **[P4]** The L2 Graph Ledger shall 外部 Graph DB export 実装時も Rwiki の JSONL を **正本** とし、外部 DB は **derived** であることを規定する（双方向 sync は MVP では行わない）。
4. **[P4]** The L2 Graph Ledger shall 既存の `rw graph export --format {dot|mermaid|json}` を P0/P1 範囲で提供し、可視化用途として動作することを規定する（CLI dispatch は Spec 4）。

### Requirement 23: Foundation 規範への準拠と文書品質

**Objective:** As a 本 spec の品質保証および将来の更新者, I want 本 spec が Foundation（Spec 0、`rwiki-v2-foundation`）の 13 中核原則・用語集・3 層アーキテクチャ・Edge status 6 種・§2.12 / §2.13 の優先関係を SSoT として参照し、CLAUDE.md の出力ルール（日本語・表は最小限・長文は表外箇条書き）に準拠する, so that 用語と原則の解釈が複数 spec で分岐せず、本 spec の可読性と運用整合性が保たれる。

#### Acceptance Criteria

1. **[P0]** The L2 Graph Ledger shall Foundation の 13 中核原則のうち §2.6 Git + 層別履歴媒体 / §2.9 Graph as first-class / §2.10 Evidence chain / §2.12 Evidence-backed Candidate Graph / §2.13 Curation Provenance を本 spec の **設計前提** として参照することを明示する。
2. **[P0]** The L2 Graph Ledger shall §2.12 を **L2 専用** として扱い、§2.2 Review layer first および §2.4 Dangerous ops 8 段階より優先する関係を本 spec の動作前提として規定することを明示する（Foundation Requirement 4 / 3 と整合）。
3. **[P0]** The L2 Graph Ledger shall Foundation Requirement 5 の Edge status 6 種（`weak` / `candidate` / `stable` / `core` / `deprecated` / `rejected`）を本 spec が **唯一の所管 status set** として継承し、独自に状態を追加・改名しないことを規定する（Requirement 6.1 と整合）。
4. **[P0]** The L2 Graph Ledger shall Foundation Requirement 5 の Page status 5 種（`active` / `deprecated` / `retracted` / `archived` / `merged`）を **本 spec の所管外** として扱い、Page status を本 spec で再定義しないことを規定する（Requirement 18 / Spec 7 所管と整合）。
5. **[P0]** The L2 Graph Ledger shall 本 spec の requirements / design / tasks 文書を日本語で記述し、`spec.json.language=ja` および CLAUDE.md「All Markdown content written to project files MUST be written in the target language」要件に準拠することを規定する。
6. **[P0]** While 本 spec 文書中で表形式を用いる場合, the L2 Graph Ledger shall 表は最小限に留め、長文・解説は表外の箇条書きまたは段落で記述することを規定する（CLAUDE.md 出力ルールと整合）。
7. **[P0]** The L2 Graph Ledger shall 運用前提として 2 系統の継承元を区別することを規定する。**v1 から継承する技術決定**（Python 3.10+ / git 必須 / LLM CLI subprocess timeout 必須 / Severity 4 水準 / exit code 0/1/2 分離 / モジュール責務分割）は Foundation Requirement 11 / roadmap.md「v1 から継承する技術決定」 経由で継承し、独自に再定義しない。一方 **v2 新規依存** である `networkx >= 3.0` は roadmap.md「Constraints」（追加依存は networkx ≥ 3.0 のみ）で v2 全体の制約として規定されており、本 spec が L2 community detection / graph traverse の実装基盤として最初に必要とする依存を Foundation Requirement 11 / Requirement 15.6 経由で正式に組み込む。
8. **[P0]** The L2 Graph Ledger shall 本 spec 自身が `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §2.6 / §2.9 / §2.10 / §2.12 / §2.13 / §3.1-§3.3 / §4.3 / §5.10 / §7.2 Spec 5 と `.kiro/drafts/rwiki-v2-scenarios.md` Scenario 13, 14, 34, 35, 36, 37, 38 を SSoT 出典とすることを明示する。
9. **[P0]** If Foundation の用語・原則・マトリクスと矛盾する記述が本 spec に必要となった, then the L2 Graph Ledger 実装者 shall 先に Foundation を改版する手順（roadmap.md「Adjacent Spec Synchronization」運用ルール）を参照点として残し、本 spec を独自に逸脱させないことを規定する。
10. **[P0]** The L2 Graph Ledger shall MVP 範囲を **P0 + P1 + P2** と明示し、**P3**（Competition L2/L3 + Edge Merging）を **v0.8 候補（MVP 外）**、**P4**（外部 Graph DB export）を **要件発生時のみ** とする実装フェーズ計画を本 spec の前提として規定する。
11. **[P0]** The L2 Graph Ledger shall 本 requirements が定める 23 個の Requirement の各々について、design 段階で「Boundary Commitments」として境界が再確認されることを前提とし、本 requirements の境界（in scope / out of scope / adjacent expectations）を design phase に渡せる形で固定する。

## Phase × Requirement 対応一覧

実装 Phase と Requirement の対応を整理用に表形式で示す（長文解説は本文側に記述）。

| Phase | 対応 Requirement | 概要 |
|-------|----------------|------|
| **P0**（Ledger 基盤） | 1, 2, 3, 4, 5, 6, 10, 11（11.1-11.9 / 11.14 / 11.16）, 12, 13, 14（11 中 5 API: get_edge_history / normalize_frontmatter / resolve_entity / record_decision / get_decisions_for）, 15.6, 18, 19, 20, 23 | Ledger 7 ファイル、Vocabulary、Entity / Relation 抽出、Confidence scoring、Edge lifecycle、Event ledger（11 種 + 拡張可規約）、Decision log 基本（22 種 decision_type + partial failure outcome）、Reject workflow、normalize_frontmatter / resolve_entity API、record_decision / get_decisions_for / get_edge_history API、Spec 7 edge API（timeout 必須 + partial failure 伝搬）、Coordination、Configuration、Foundation 準拠 |
| **P1**（Query cache + Decision view） | 11.10-11.12, 11.15, 14（11 中 6 API: get_neighbors / get_shortest_path / get_orphans / get_hubs / find_missing_bridges / search_decisions）, 15（部分）, 16, 21（neighbor 性能） | SQLite cache、neighbor / path / orphans / hubs / bridges / search_decisions API、Tier 2 markdown timeline、Tier 3 mermaid 埋込、`check_decision_log_integrity()` API（4 診断項目、context_ref dangling 含む）、Rebuild / sync、L3 `related:` cache invalidation（shortcut 由来 typed edge 除外）、Audit、neighbor depth=2 性能 |
| **P2**（Hygiene + Usage event + Decision search） | 7（7.11 含む）, 8, 9.1, 9.4, 11.13, 14（4 API: get_communities / get_global_summary / get_hierarchical_summary / find_contradictory_decisions）, 15（community detection）, 17, 21（hygiene 性能） | Hygiene 5 ルール（Decay / Reinforcement / Competition L1 + crash 後 tmp clean-up）、Usage signal 4 種別、Competition L1、Community / global / hierarchical summary API、find_contradictory_decisions API、Concurrency lock、性能目標 |
| **P3**（v0.8 候補、MVP 外） | 9.2, 9.3, 9.5, 9.6, 21.6 | Competition L2 / L3、Edge Merging、100,000 edges 規模対応 |
| **P4**（optional、要件発生時のみ） | 22 | 外部 Graph DB export |

---

_change log_

- 2026-04-26: 初版生成（v0.7.12 SSoT を基に Spec 5 全 23 Requirement を P0-P4 マーカー付きで定義）
- 2026-04-27: 第 1 ラウンドレビュー反映（致命級 5 件 + 重要級 3 件、深掘り検討 + 自動採択方針で適用）。
  - **致-1**: R11.2 を `decision_type` 21 種（Edge 4 + Hypothesis 1 + Synthesis 1 + Page 6 + Skill 3 + Vocabulary 5 + Hygiene 1）+ 拡張可規約に拡張（旧 10 種に対し `tag_merge` を `vocabulary_merge` に吸収、`split` を `page_split` にリネーム、Page lifecycle 5 種 / Skill lifecycle 3 種 / Vocabulary 4 種を追加。Spec 7 R12.7 / Spec 1 R8.13 と整合）
  - **致-2**: R18 に新 AC 18.7 / 18.8 を追加し edge API（`edge_demote` / `edge_reject` / `edge_reassign`）の timeout 必須パラメータと partial failure 伝搬規約を規定（Spec 7 R12.8 と整合）
  - **致-3**: R11 に新 AC 11.15 として Decision Log 健全性診断 API（`check_decision_log_integrity()`、3 診断項目）を追加 + R16.8 を拡張して `rw doctor` 経由の Decision Log 健全性診断項目への参照を追記（Spec 4 R4.5 と整合）
  - **致-4**: R16.6 Step 2（Batch sync）に shortcut 由来 typed edge 除外フィルタ規定を追加 + Step 5（整合性レベル）に Query API 直接参照推奨を追記（Spec 1 R5.5 / R10.1 と整合）
  - **致-5**: R11 に新 AC 11.16 として `outcome` field 内 partial failure 4 field（`partial_failure` / `successful_edge_ops` / `failed_edge_ops` / `followup_ids`）サポートを規定（Spec 7 R3.7 / R3.8 と整合）
  - **重-1**: Query API「14 種」→「15 種」表記統一（タイトル / Objective / Boundary Context / introduction / brief.md / R19.5 / 概要文 (n)(k)）。`resolve_entity` を Spec 6 perspective seed 正規化用 API として 15 番目に明示
  - **重-2**: entity の YAML field 名を `type` → `entity_type` に統一（R1.2 / R3.5、Spec 1 R2.3 と整合）
  - **重-3**: R11.14 `context_ref` の path 形式を `chat-<ts>.md` → `<timestamp>-<session-id>.md` に統一（Spec 4 R1.8 と整合）
  - **第 2-A（roadmap/brief/drafts 厳格照合）**: R12.4 を 7 field → 8 field に拡張し `pre_reject_confidence`（reject 直前 confidence 値、float [0.0, 1.0]）を必須追加 + R12.7 unreject 復元の confidence クランプ計算を `pre_reject_confidence` 参照に明示化（drafts §5.10 example の `original_confidence` と整合、unreject 動作の決定的復元を保証）。本変更は Foundation Requirement 13.5 の必須フィールド 7 → 8 への拡張を伴うため、Foundation 側を Adjacent Spec Synchronization で同期更新（roadmap.md「Adjacent Spec Synchronization」運用ルール）
  - **第 3-D（本質的観点・致命級）**: R10.1 の `edge_events.jsonl` event type を 8 種固定 → **初期セット 11 種 + 拡張可規約** に変更（基本セット 8 種を Foundation R12.3 と整合継承 + 本 spec 追加 3 種 `dangling_flagged` / `unreject` / `reassigned` を R6.7 / R12.7 / R18.1 との内部矛盾解消のため列挙）。Foundation R12.3 は基本セット 8 種を初期セットとして規定するのみで本 spec が拡張規定を所管する設計、R11.2 decision_type 拡張可規約と統一の設計パターン（Foundation 不変）
  - **第 3-A（本質的観点・重要級）**: R23.7 の運用前提継承表現を 2 系統に分離 — v1 継承の技術決定（Python 3.10+ / git / timeout / Severity / exit code / モジュール責務分割）と v2 新規依存（`networkx >= 3.0`）を区別表現（roadmap.md「Constraints」の v2 新規依存表記と整合）
  - **第 3-B（本質的観点・重要級）**: R3.4 の Entity 抽出 review buffer 名から「または別途定義する review buffer」の曖昧表現を削除し、`review/relation_candidates/` で固定（drafts §7.2 Spec 5 line 1789 の Entity/Relation 統合方針 / Spec 1 R4.8 の本 spec 所管再委譲と整合）
  - **第 4-D（B 観点・重要級）**: R7 に新 AC R7.11 を追加し、Hygiene crash 後の残留 tmp 領域 `.rwiki/.hygiene.tx.tmp/` 検出 + 破棄 + stale lock 併発処理 + WARN 通知の 3 step 規定（process kill / disk full / OOM 等で失敗時 tmp 破棄が走らなかった場合の安全回復、原子性保証の補完）
  - **第 4-F（B 観点・重要級）**: R4 に新 AC R4.10 を追加し、`rw extract-relations --scope` batch 処理の partial failure handling 規定（per-page continue-on-error default + exit code 2 + JSON 出力に partial_failure / successful_pages / failed_pages[{path, reason}] / total_pages、handler 自身の例外は exit 1）
  - **第 4-C（B 観点・重要級）**: R11.15 の Decision Log 健全性診断項目を 3 → 4 種に拡張、`context_ref` dangling 件数（指す path のファイル消失 / line range 外参照検出）を追加
  - **精査ラウンド（修正適用後の整合性精査、重要級 3 件 + 軽微 2 件）**: 第 1-6 ラウンド修正適用後の内部不整合を再点検し、以下を反映 — (発見 1) R18.1 の edge API シグネチャに `timeout` を明示パラメータ追加 + R18.2 の必須パラメータ列挙に `timeout` を追加（R18.7 / R18.8 の規定との整合）/ (発見 2) R16.8 の Decision Log 健全性診断項目を「3 種」→「4 種」に更新（R11.15 第 4-C 拡張時の更新漏れ）/ (発見 5) Boundary Context In scope の Event ledger 説明を「8 event type」→「初期セット 11 event type + 拡張可規約」に更新（R10.1 第 3-D 拡張時の更新漏れ）/ (発見 3) Phase × Requirement 表 P0 概要文に `resolve_entity` API を追加（重-1 で 15 種化した時の波及）/ (発見 4) Phase 表の R11 / R7.11 / R14 の Phase 分類を詳細化（R11 = P0: 1-9/14/16 / P1: 10-12/15 / P2: 13、R7 内 R7.11 は P2、R14 内 API は Phase ごとに細分）
- 2026-04-27 (Adjacent Sync): Spec 2 レビュー由来の重-2 修正反映 — R11.2 を `decision_type` 21 種 → 22 種に拡張、Skill 起源を「lifecycle 3 種」→「Skill 起源 4 種」に再分類して `skill_install` を追加（Spec 2 R12.4 が install 完了時の履歴保全で参照する起点として、Spec 7 R12.7 と同期宣言）。連鎖更新 3 箇所: R11.2 文言（line 266 / 272）/ R11.15 schema 違反件数の「21 種」記述（line 301）/ Phase 表 P0 概要文の「21 種 decision_type」（line 564）を 22 種に統一。Adjacent Spec Synchronization 運用ルールに従い再 approval は不要、`spec.json.updated_at` 更新のみ。
