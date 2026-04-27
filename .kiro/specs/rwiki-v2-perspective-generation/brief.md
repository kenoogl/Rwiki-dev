# Brief: rwiki-v2-perspective-generation

> 出典: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §7.2 Spec 6 / Scenario 14

## Problem

L2 Graph Ledger（Spec 5）と L3 Curated Wiki（Spec 1）が揃っても、それを traverse して**ユーザー単独では気づかない視点**や**未検証の新命題**を提示する CLI 機能がなければ、Rwiki v2 の中核価値（Trust + Graph + **Perspective + Hypothesis** の四位一体）は完成しない。本 spec は v2 の本丸。

## Current State

- consolidated-spec §7.2 Spec 6 / Scenario 14 で要件確定済（2026-04-24）
- v0.7.10 で「standalone CLI + skill invoke hybrid 構造」「semi-auto verify workflow」「scoring function 別系統」の 3 決定が確定
- Spec 5 が提供する Query API 15 種（neighbor / path / bridge / community / global summary / `resolve_entity` 等）の signature と返り値 schema が contract として固定済 (`resolve_entity` は seed 正規化用、Spec 5 R14.1 P0 API)
- Scenario 14 の 5 段階処理フロー（seed → traverse → top-M 選定 → 本文読込 → 統合分析）が確定

## Desired Outcome

- `rw perspective <topic>` でトピックに関連する複数視点（支持・反論・補完・代替）が提示される
- `rw hypothesize <topic>` で L2 の missing bridges / candidate edges から仮説が生成される
- `rw verify <hypothesis-id>` で半自動 4 段階の evidence 検証が動作（LLM が候補抽出 → user が個別評価 → LLM が集約判定 → 結果記録）
- Confirmed hypothesis は Scenario 16 経由で wiki/synthesis/ 昇格可能
- Maintenance autonomous mode で reject queue 蓄積 / decay 進行 / audit 未実行等を surface
- 検証で使われた edge は reinforcement event として edge_events.jsonl に記録され、Spec 5 の Hygiene にフィードバック

## Approach

`rw perspective` / `rw hypothesize` / `rw verify` を独立 CLI コマンドとして実装。内部で `AGENTS/skills/perspective_gen.md` / `hypothesis_gen.md` を load（Spec 2 の skill lifecycle に参加、ただし dispatch は固定 skill 呼出で Spec 3 対象外）。L2 traverse は Spec 5 の Query API 経由（直接 JSONL 読まない）。Scoring function は Perspective（信頼性重視: 0.6c + 0.3r + 0.1n）と Hypothesis（未発見重視: 0.5n + 0.3c + 0.2bp）で別系統。

## Scope

- **In**:
  - `rw perspective` / `rw hypothesize` / `rw verify` / `rw approve <hypothesis-id>` コマンド
  - L2 ledger からの graph traverse（Spec 5 の Query API 活用）
  - 5 段階処理フロー（seed → N-hop traverse → top-M 選定 → 本文読込 → 統合分析）
  - Dual-level retrieval（local / global scope）
  - Community-aware traversal（GraphRAG-inspired）
  - `--scope global` flag、`--method hierarchical-summary`
  - Hypothesis の 7 状態管理（draft / verified / confirmed / refuted / promoted / evolved / archived）
  - Verify workflow 半自動 4 段階
  - Maintenance autonomous trigger 6 種（reject queue / decay / typed-edge 整備率 / dangling edge / audit 未実行 / 未 approve synthesis）
  - 候補選定 scoring（Perspective / Hypothesis 別系統）
  - L2 Ledger 成熟度別 fallback（極貧 / 疎 / 通常）
- **Out**:
  - Graph Ledger 実装（Spec 5）
  - Community detection アルゴリズム（Spec 5、networkx ベース）
  - Skill 設計（Spec 2）
  - Skill 選択ロジック（Spec 3、Perspective/Hypothesis は固定 skill）

## Boundary Candidates

- Perspective / Hypothesis 生成ロジック（本 spec）と Graph traverse 基盤（Spec 5）
- Verify workflow の処理（本 spec）と evidence の data model（Spec 5）
- Maintenance autonomous trigger 提示（本 spec）と trigger 計算（Spec 5 の Hygiene 運用ポリシー）

## Out of Boundary

- L2 Ledger の data model（Spec 5）
- Community detection / missing bridge アルゴリズム（Spec 5）
- Skill ファイル定義（Spec 2、ただし perspective_gen / hypothesis_gen は本 spec が要求する）
- Page lifecycle（Spec 7、ただし Confirmed hypothesis の wiki 昇格 trigger は本 spec が起こす）

## Upstream / Downstream

- **Upstream**: 全前 spec（Spec 0-5, 7）
- **Downstream**: なし（v2 MVP の最後の spec）

## Existing Spec Touchpoints

- **Extends**: なし（v2 新規、v1 に Perspective / Hypothesis 概念なし）
- **Adjacent**: v1 `cli-query`（v1-archive、query 系 CLI の構造を参考）

## Constraints

- L2 ledger を主 query 対象（frontmatter `related:` は cache、正本は ledger）
- Typed edges 未整備時でも動作（graceful degradation、極貧時は警告 + extract-relations 推奨）
- Hypothesis は evidence 検証可能な命題に限定（純粋な理論命題は Perspective 担当）
- `[INFERENCE]` マーカーで仮説部分を明示
- Confirmed hypothesis の wiki 昇格は Scenario 16 と同じ 8 段階対話
- Perspective の自動保存しない default（stdout のみ）、`--save` で `review/perspectives/`
- Hypothesis 出力は `review/hypothesis_candidates/`（必ずファイル化）
- 対話ログ自動保存: `raw/llm_logs/chat-sessions/` / `interactive/`（Scenario 15/25 連携）
- Verify は半自動 4 段階（人間が evidence 採否判断、LLM が候補抽出と集約判定）
- Filter 閾値: Perspective は status IN (stable, core) AND confidence ≥ 0.4、Hypothesis は status IN (candidate, stable, core) AND confidence ≥ 0.3

## Coordination 必要事項

- **Spec 6 ↔ Spec 5**: Query API の signature と返り値 schema を contract として依存
- **Spec 6 ↔ Spec 2**: perspective_gen / hypothesis_gen を skill として定義（lifecycle 参加、ただし dispatch 不要）
