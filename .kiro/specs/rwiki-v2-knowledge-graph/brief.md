# Brief: rwiki-v2-knowledge-graph

> 出典: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §7.2 Spec 5

## Problem

通常 GraphRAG は自動抽出 graph に対する人間レビュー層を持たず、ノイズが蓄積する。一方で全件 approve を要求すると入力コストが知識蓄積のボトルネックになる（§1.3.2 入力コスト問題）。Trust chain（evidence 裏付け）も切れやすく、LLM の hallucination との差別化が困難。Rwiki v2 の中核価値（Curated GraphRAG）を実現するには、L2 Graph Ledger という新しい層が必要。

## Current State

- consolidated-spec §2.12 に Evidence-backed Candidate Graph の原則（Evidence 必須 / Reject-only / 6 係数 confidence 計算 / 3 段階 status / Hygiene 5 ルール）が整理済
- §7.2 Spec 5 に Ledger 基盤 / Entity 抽出 / Relation 抽出 / Hygiene / Usage signal 4 種別 / Competition 3 レベル / Decision log / Query API 15 種が詳細化済
- v0.7.10 で 6 決定が確定（normalize_frontmatter API、cache invalidation 戦略等）
- networkx ≥ 3.0 を新規依存に追加方針

## Desired Outcome

- L2 Graph Ledger が source of truth として動作（edges.jsonl が正本、L3 frontmatter `related:` は derived cache）
- 全 edge が evidence 裏付けを持ち（evidence なしは confidence ≤ 0.3 強制）、trust chain が逆追跡可能
- candidate → stable auto-accept（confidence ≥ 0.75）が機能、人間は reject のみ判断
- Hygiene（Decay / Reinforcement / Competition L1）で graph が evolving に進化
- Query API（neighbor / path / orphans / hubs / bridges / community / global summary 等）が Spec 6 / audit / CLI から呼び出し可能
- §2.13 Curation Provenance（decision_log.jsonl）で「なぜそう判断したか」が記録される

## Approach

P0-P4 の 5 phase で段階実装（MVP は P0+P1+P2）:

- P0: Ledger 基盤（edges/evidence/entities/scorer/decision_log）
- P1: Query cache（sqlite + neighbor/path/orphans/hubs API、rebuild、decision view）
- P2: Usage event 4 種別 + Hygiene 基礎（Decay/Reinforcement/Competition L1）+ decision search
- P3: Competition L2/L3 + Edge Merging（v0.8 候補、MVP 外）
- P4: 外部 Graph DB export（optional、要件発生時のみ）

## Scope

- **In**:
  - Graph Ledger 基盤（edges.jsonl / edge_events.jsonl / evidence.jsonl / entities.yaml / rejected_edges.jsonl / reject_queue/ / decision_log.jsonl）
  - SQLite derived cache（gitignore）
  - relations.yml / entity_types.yml vocabulary
  - Entity 抽出と正規化（LLM 抽出、alias、entities.yaml 管理）
  - Relation 抽出（LLM 2-stage、evidence 必須、4 extraction_mode）
  - Confidence scoring（§2.12 の 6 係数式の実装）
  - Edge lifecycle（6 status の遷移）
  - Hygiene 5 ルール（Decay / Reinforcement / Competition / Contradiction tracking / Edge Merging）
  - Usage signal 4 種別（Direct/Support/Retrieval/Co-activation）と式
  - Competition 3 レベル（L1 同一 node pair / L2 類似 / L3 contradiction）
  - Event ledger（edge_events.jsonl の append-only 記録）
  - Decision log（§2.13 Curation Provenance、selective recording）
  - Reject workflow（reject_queue/ → rejected_edges.jsonl、unreject 復元）
  - Entity ショートカット field の正規化（normalize_frontmatter API）
  - Graph query API 15 種
  - Community detection（networkx Leiden/Louvain）
  - Graph audit（対称性 / 循環 / 孤立 / 参照整合性 / confidence 分布）
  - Rebuild / sync（増分 / full / stale detection）
- **Out**:
  - Perspective / Hypothesis 生成（Spec 6）
  - Wiki page lifecycle（Spec 7）
  - Skill 設計（Spec 2）
  - Tag vocabulary（Spec 1）

## Boundary Candidates

- L2 Ledger 内部実装（本 spec）と CLI dispatch（Spec 4）
- Edge lifecycle（本 spec）と Page lifecycle（Spec 7）
- 抽出 skill 出力（Spec 2）と抽出結果の永続化（本 spec）
- Query API 提供（本 spec）と利用（Spec 6 / audit）

## Out of Boundary

- Perspective / Hypothesis 生成（Spec 6）
- Page lifecycle 状態遷移（Spec 7）
- Skill 内容（Spec 2）
- Tag / categories vocabulary（Spec 1、ただし relations.yml は本 spec）

## Upstream / Downstream

- **Upstream**: rwiki-v2-foundation（Spec 0）/ rwiki-v2-classification（Spec 1 — frontmatter スキーマ）/ rwiki-v2-cli-mode-unification（Spec 4 — CLI dispatch）/ rwiki-v2-lifecycle-management（Spec 7 — Page lifecycle interaction）
- **Downstream**: rwiki-v2-skill-library（Spec 2 — extraction skill 出力先）/ rwiki-v2-perspective-generation（Spec 6 — Query API 利用）

## Existing Spec Touchpoints

- **Extends**: なし（v2 新規、v1 に L2 Ledger に相当する概念なし）
- **Adjacent**: v1 `agents-system`（v1-archive、AGENTS prompt の参考のみ）

## Constraints

- 全 edge は evidence 必須（evidence なしは confidence ≤ 0.3 強制）
- candidate → stable auto-accept は confidence ≥ 0.75
- relation type 初期 canonical 12 + 抽象 8 + Entity 固有 10+ セット（拡張可能）
- `[[link]]` syntax は untyped edge として並存、後付け typing 可能
- JSONL append-only フォーマット、derived sqlite cache は gitignore
- Single-user serialized execution（`.rwiki/.hygiene.lock` で排他）
- Hygiene 実行は all-or-nothing transaction（途中クラッシュは git revert）
- ルール実行順序固定: Decay → Reinforcement → Competition → Contradiction → Merging
- パフォーマンス目標: 1,000 edges で hygiene ≤ 30 秒、neighbor depth=2 ≤ 100ms
- L3 `related:` は eventual consistency（hygiene batch で sync、stale_pages.txt で追跡）
- Edge unreject 復元: status は candidate にリセット（stable/core からの reject だった場合）、confidence は evidence ceiling とのクランプ
- 外部依存: networkx ≥ 3.0
- MVP 範囲は P0+P1+P2、P3 は v0.8 候補、P4 は要件発生時のみ

## Coordination 必要事項

- **Spec 5 ↔ Spec 1**: Entity 固有 field のスキーマ宣言と展開ロジックの境界
- **Spec 5 ↔ Spec 2**: extraction skill（relation_extraction / entity_extraction）の出力 validation interface
- **Spec 5 ↔ Spec 7**: Page deprecation → Edge demotion の interaction flow
- **Spec 5 ↔ Spec 4**: `.rwiki/.hygiene.lock` Concurrency strategy
- **Spec 5 ↔ Spec 6**: Query API の signature と返り値 schema が contract

## Design phase 持ち越し項目（第 1-4 ラウンドレビュー由来）

第 1 ラウンド（基本整合性 + coordination 反映、致命級 5 件 + 重要級 3 件、すべて requirements に反映済み）。
第 2 ラウンド（roadmap/brief/drafts 厳格照合、第 2-A pre_reject_confidence 必須化を requirements + Foundation Adjacent Sync で反映済み）。
第 3 ラウンド（本質的観点、致命級 1 件 + 重要級 2 件、すべて requirements に反映済み）。
第 4 ラウンド（B 観点 = failure mode / 並行 / セキュリティ / 観測 / 可逆性 / 規模、重要級 3 件は requirements に反映、軽微 3 件は本セクションに記録）:

- **第 4-A**: `decision_log` の privacy mode（`gitignore: true`）切替時の意味の明示。過去 git history を含むか、未来分のみ git 管理外か、運用パターンを design phase で確定（ただし default は「`gitignore` に追加されるが過去 git history はそのまま残る、未来分のみ git 管理外」が現実的、明示要）
- **第 4-B**: edge_id の hash 衝突時の handling（`source+type+target` hash で edge_id 決定、Requirement 4.4 / 13.4 / 13.6 と整合、衝突は実用上ないが衝突検出時の挙動 = ERROR で abort or 衝突解決アルゴリズム = を design phase で確定）
- **第 4-E**: 大規模 Vault（edges > 5,000）での Reinforcement per-day cap 接触問題の対処戦略（Requirement 7.7 / 20.2 で per-event 0.1 / per-day 0.2 上限を規定、Vault 規模拡大時に一部 edge のみが reinforced され他は cap で skip される現象の運用上の影響と緩和策 = community 単位 / 直近 N 日更新分の部分 Hygiene 推奨 = を design phase で詳細化、Requirement 21.6 と整合）

第 5 ラウンド（C 観点 = 他 spec 波及）と第 6 ラウンド（D 観点 = drafts 整合）は本ファイル更新時点で進行中、結果は requirements 末尾 `_change log_` に追記される。
