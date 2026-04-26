# Requirements Document

## Project Description (Input)

Rwiki v2 の中核価値（Trust + Graph + **Perspective + Hypothesis** の四位一体）は、L2 Graph Ledger（Spec 5）と L3 Curated Wiki（Spec 1）が揃っただけでは未完成である。両者を traverse して **ユーザー単独では気づかない視点（Perspective）** や **未検証の新命題（Hypothesis）** を提示し、Hypothesis に対して半自動 evidence 検証を回し、Confirmed のみ wiki/synthesis/ への昇格パイプラインに供給する CLI 機能がなければ、v2 の本丸は欠落する（§7.2 Spec 6 / Scenario 14、2026-04-24 確定）。

本 spec（Spec 6、Phase 5、v2 MVP の最後の spec）は、`rwiki-v2-foundation`（Spec 0）が固定したビジョン・13 中核原則（特に §2.10 Evidence chain / §2.11 Discovery primary / Maintenance LLM guide / §2.12 Evidence-backed Candidate Graph、L2 専用）・3 層アーキテクチャ・Hypothesis status 7 種の独立性に準拠しつつ、`rwiki-v2-knowledge-graph`（Spec 5）が contract として固定済みの Query API 14 種（`get_neighbors` / `get_shortest_path` / `get_orphans` / `get_hubs` / `find_missing_bridges` / `get_communities` / `get_global_summary` / `get_hierarchical_summary` / `get_edge_history` / `normalize_frontmatter` / `record_decision` / `get_decisions_for` / `search_decisions` / `find_contradictory_decisions`）を **唯一の L2 入力 contract** として、(a) `rw perspective` / `rw hypothesize` / `rw verify` / `rw approve <hypothesis-id>` の 4 つの独立 CLI コマンドの内部生成ロジック、(b) Spec 2 の skill lifecycle に参加する固定 skill `perspective_gen` / `hypothesis_gen`（dispatch は固定呼出、Spec 3 対象外）、(c) 5 段階処理フロー（seed 特定 → N-hop traverse → top-M 選定 → 本文読込 → 統合分析）、(d) Dual-level retrieval（local / global scope）と Community-aware traversal、(e) `--scope global` flag と `--method hierarchical-summary`、(f) Hypothesis 7 状態管理（draft / verified / confirmed / refuted / promoted / evolved / archived）、(g) Verify workflow 半自動 4 段階（LLM 候補抽出 → user 個別評価 → LLM 集約判定 → 結果記録）、(h) Maintenance autonomous trigger 6 種（reject queue / decay / typed-edge 整備率 / dangling edge / audit 未実行 / 未 approve synthesis 候補）、(i) 候補選定 scoring 2 系統（Perspective: 0.6c + 0.3r + 0.1n / Hypothesis: 0.5n + 0.3c + 0.2bp）、(j) L2 Ledger 成熟度別 fallback（極貧 / 疎 / 通常）、(k) 検証で使われた edge を reinforcement event として `edge_events.jsonl` に記録（Spec 5 連携）、(l) Perspective の自動保存しない default（stdout のみ）/ `--save` で `review/perspectives/` / Hypothesis は必ず `review/hypothesis_candidates/`、(m) 対話ログ自動保存（`raw/llm_logs/chat-sessions/` / `interactive/`、Scenario 15/25 連携）、(n) Confirmed hypothesis の wiki 昇格は Spec 7 の 8 段階対話（Scenario 16）経由、(o) Configuration（`.rwiki/config.yml` の `graph.perspective` / `graph.hypothesis` / `graph.verify`）を所管する。

L2 Graph Ledger の data model・Query API 実装・Hygiene 進化則は Spec 5、Skill ファイルの内容と lifecycle は Spec 2、CLI dispatch の引数 parse / Hybrid 実行 / `rw chat` 統合 / Maintenance UX の表示は Spec 4、Page lifecycle 操作の状態遷移と 8 段階対話 handler は Spec 7 の所管であり、本 spec はそれらに介入しない。

出典 SSoT: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §5.9.1 Hypothesis candidate frontmatter / §5.9.2 Perspective 保存版 frontmatter / §7.2 Spec 6 perspective-generation / §11.0 Scenario 25 LLM 対話ログ / §11.2 v0.7.10 決定 6-1（Perspective / Hypothesis dispatch 対象外）。`.kiro/drafts/rwiki-v2-scenarios.md` Scenario 14（本丸、5 段階フロー / 7 状態 / scoring）/ Scenario 15（interactive_synthesis 対話ログ）/ Scenario 16（query → synthesis 8 段階昇格）/ Scenario 33（Maintenance UX）。Upstream: `rwiki-v2-foundation` requirements.md（13 中核原則・Edge/Page/Hypothesis status の独立性）/ `rwiki-v2-classification` requirements.md（frontmatter スキーマ）/ `rwiki-v2-cli-mode-unification` requirements.md（CLI dispatch 規約・autonomous mode）/ `rwiki-v2-knowledge-graph` requirements.md（Query API 14 種・record_decision・edge_events.jsonl）/ `rwiki-v2-skill-library` requirements.md（skill lifecycle）/ `rwiki-v2-prompt-dispatch` requirements.md（Spec 6 が dispatch 対象外であることの確認）/ `rwiki-v2-lifecycle-management` requirements.md（Confirmed hypothesis の wiki 昇格は 8 段階対話経由）。

## Introduction

本 requirements は、Rwiki v2 の Spec 6 として **Perspective 生成 / Hypothesis 生成 / Verify workflow / Confirmed hypothesis の wiki 昇格 trigger** を定義する。読者は Spec 6 の実装者と、本 spec が呼び出す内部 API を提供する Spec 5（Query API contract）/ Spec 2（perspective_gen / hypothesis_gen skill ファイル）、本 spec の handler を CLI dispatch する Spec 4（`rw perspective` / `rw hypothesize` / `rw verify` / `rw approve <hypothesis-id>` の引数 parse・Hybrid 実行・Maintenance UX surface）、Confirmed hypothesis の wiki 昇格時に呼び出される Spec 7（8 段階対話 handler）の起票者である。

本 spec は **Perspective / Hypothesis 生成ロジックを直接実装する spec** であり、規範文書（Foundation）とも frontmatter 宣言（Spec 1）とも CLI dispatch（Spec 4）とも Query API 実装（Spec 5）とも異なり、生成プロンプトの呼出・5 段階処理フロー・候補選定 scoring・Hypothesis 状態管理・Verify workflow・autonomous trigger 計算結果の取得・対話ログ自動保存連携の中核を含む。したがって本 requirements の各 acceptance criterion は、(a) `rw perspective` / `rw hypothesize` / `rw verify` / `rw approve <hypothesis-id>` の動作要件、(b) 5 段階処理フローが満たすべき動作要件と filter 閾値、(c) 固定 skill `perspective_gen` / `hypothesis_gen` の load 規約と dispatch 対象外規定、(d) 候補選定 scoring 2 系統の計算要件と config 注入、(e) L2 Ledger 成熟度別 fallback、(f) Hypothesis 7 状態の遷移ルール、(g) Verify workflow 半自動 4 段階の手順、(h) Maintenance autonomous trigger 6 種の surface 規約、(i) Perspective / Hypothesis の出力先と対話ログ自動保存、(j) Confirmed hypothesis の wiki 昇格 trigger（Spec 7 の 8 段階対話呼出）、(k) Spec 5 Query API への依存契約、(l) `edge_events.jsonl` への usage_signal / human_verification_support 記録、(m) Configuration、(n) 周辺 spec との境界・coordination、として記述される。Subject は概ね `the Perspective Generator` / `the Hypothesis Generator` / `the Verify Workflow` / `the Maintenance Autonomous Surface` または `the Spec 6 Perspective-Hypothesis Subsystem` を用いる。

本 spec の成果物は次の 9 種類に分類される。

- `rw perspective` 生成ロジック（5 段階処理フロー / Perspective scoring / `--scope global` / `--save` / 対話ログ自動保存）
- `rw hypothesize` 生成ロジック（5 段階処理フロー / Hypothesis scoring / missing bridges 活用 / 必須ファイル化）
- `rw verify <hypothesis-id>` 半自動 4 段階 workflow（LLM 候補抽出 → user 評価 → LLM 集約判定 → 結果記録 + edge reinforcement）
- `rw approve <hypothesis-id>` の Spec 7 8 段階対話呼出 trigger（confirmed のみ昇格可、Scenario 16 経由）
- 固定 skill `perspective_gen` / `hypothesis_gen` の load 規約（Spec 2 lifecycle 参加、Spec 3 dispatch 対象外）
- Hypothesis 7 状態管理と frontmatter 操作（draft / verified / confirmed / refuted / promoted / evolved / archived）
- Maintenance autonomous trigger 6 種の surface 規約（Spec 5 / Spec 7 の診断 API 結果を取得して提示）
- Spec 5 Query API への依存契約と L2 Ledger 成熟度別 fallback（極貧 / 疎 / 通常）
- Configuration（`.rwiki/config.yml` の `graph.perspective.*` / `graph.hypothesis.*` / `graph.verify.*` / `chat.autonomous.maintenance_triggers.*`）

Spec 4 / Spec 7 が本 spec を引用することで、Perspective / Hypothesis 生成の挙動・5 段階フロー・Verify workflow・autonomous trigger の semantics が複数 spec で分岐することを防ぐ。

## Boundary Context

- **In scope**:
  - **CLI コマンド 4 種の生成・検証ロジック**: `rw perspective <topic>` / `rw hypothesize <topic>` / `rw verify <hypothesis-id>` / `rw approve <hypothesis-id>` の内部 handler ロジック（CLI dispatch / 引数 parse / Hybrid 実行 frame は Spec 4 所管）。
  - **5 段階処理フロー**（Perspective / Hypothesize 共通）: Step 1 seed 特定（Grep + `entities.yaml` 正規化）→ Step 2 SQLite 経由 N-hop traverse（depth default=2、filter 適用）→ Step 3 top-M 選定（scoring function ranking）→ Step 4 選択ページ本文 Read + `evidence.jsonl` 参照 → Step 5 統合分析 + 出力 + edge reinforcement event 記録。
  - **Filter 閾値**: Perspective は `status IN (stable, core) AND confidence ≥ 0.4`、Hypothesis は `status IN (candidate, stable, core) AND confidence ≥ 0.3`。
  - **Dual-level retrieval**: local scope（seed 起点 N-hop）と global scope（`--scope global`、L2 Graph Ledger 全体集約）。
  - **Community-aware traversal**: `get_communities` の結果を活用し、cluster 内 / 境界 bridge を区別して surface（Scenario 14 パターン G）。
  - **`--scope global` flag**: `get_global_summary` を呼び、主要 cluster / 主要人物・著者 / 未検証仮説等の大局俯瞰を返す（Scenario 14 パターン F）。
  - **`--method hierarchical-summary`**: `get_hierarchical_summary(community_id)` を on-demand で呼び、community 単位の要約を返す。
  - **候補選定 scoring 2 系統**:
    - Perspective（信頼性重視）: `score = 0.6 × confidence + 0.3 × recency + 0.1 × novelty`
    - Hypothesis（未発見重視）: `score = 0.5 × novelty + 0.3 × confidence + 0.2 × bridge_potential`
    - 各係数値は config 注入（ハードコードしない）、top_m は default 20。
  - **Hypothesis 7 状態管理**: `draft / verified / confirmed / refuted / promoted / evolved / archived`、Page status / Edge status と独立した第 3 の status 軸。
  - **Verify workflow 半自動 4 段階**: (1) LLM が `raw/**/*.md` を grep + semantic similarity で N 件（default 5）の候補 evidence 抽出 → (2) user が個別に `supporting / refuting / partial / none` を選択（`--add-evidence <path>:<span>` で手動追加可）→ (3) LLM が collected evidence から最終 status 判定（`supporting≥2 ∧ refuting=0 → confirmed` / `refuting≥2 → refuted` / 混在 → `partial` / 不足 → `verified` 据置）→ (4) frontmatter `verification_attempts` に append、confirmed/refuted 時は対応 edge への `human_verification_support` event を `edge_events.jsonl` に append。
  - **Maintenance autonomous trigger 6 種の surface**: (1) reject queue 蓄積 ≥ 10 件 / (2) Decay 進行 edges ≥ 20 件 / (3) Typed-edge 整備率 < 2.0 / (4) Dangling edge ≥ 5 件 / (5) Audit 未実行 ≥ 14 日 / (6) 未 approve synthesis 候補 ≥ 5 件。各 trigger は Spec 5 / Spec 7 の診断 API（`rw doctor` 等経由）を呼んで判定し、surface のみ行い自動実行しない。
  - **autonomous trigger の動作規則**: surface 表示（💡 マーカー）/ 同セッション 1 回まで頻度制限 / `/dismiss` / `/mute maintenance` 受付 / 閾値は config 上書き可 / 複数同時発火時は優先順位付け（Scenario 33 と整合）。閾値計算 API は Spec 5 / Spec 7、surface UX は Spec 4 と coordination。
  - **L2 Ledger 成熟度別 fallback**: 極貧（stable+core edges < 10 件）→ ⚠ 警告 + `rw extract-relations` 推奨 / 疎（stable 比率 < 20%）→ INFO: ledger 成熟途上 / 通常（stable+core 50%超）→ full quality。
  - **固定 skill の load 規約**: `AGENTS/skills/perspective_gen.md` と `AGENTS/skills/hypothesis_gen.md` を Spec 2 の skill lifecycle に participate させる（install / deprecate / retract 対象）が、Spec 3 dispatch は経由せず本 spec 内部で **固定 skill 名で直接呼出**。
  - **出力先**:
    - Perspective: stdout（default）、`--save` 指定時のみ `review/perspectives/<slug>-<ts>.md`（`§5.9.2` frontmatter スキーマ）。
    - Hypothesis: 必ず `review/hypothesis_candidates/<slug>-<ts>.md` にファイル化（`§5.9.1` frontmatter スキーマ）。
  - **対話ログ自動保存**: `rw chat` セッションは `raw/llm_logs/chat-sessions/chat-<ts>.md`、`interactive_synthesis` 等の対話 skill ログは `raw/llm_logs/interactive/interactive-<skill>-<ts>.md`（Scenario 15 / 25 と同仕組み）。
  - **L2 への feedback**:
    - Perspective `--save` 時: `traversed_edges:` field に edge_id を列挙、各 edge へ `used_in_save_perspective` event を追記し usage_signal 加算（Spec 5 Hygiene の reinforcement 入力）。
    - Hypothesis verify 成功（confirmed）時: `origin_edges` で参照される L2 edges に `human_verification_support` event を追記、`edge_events.jsonl` への delta は Spec 5 Hygiene の `supporting_evidence_reinforcement_delta` を参照（default +0.28）。
  - **Confirmed hypothesis の wiki 昇格**: `rw approve <hypothesis-id>` は status `confirmed` のみ受け付け、Spec 7 の `cmd_promote_to_synthesis` 8 段階対話 handler を呼び出して `wiki/synthesis/` 昇格パイプラインに乗せる（Scenario 16 と同フロー）。Hypothesis 本体は `review/hypothesis_candidates/` に残し status を `promoted` に更新、`successor_wiki:` を記録。
  - **Spec 5 Query API への依存**: 本 spec は L2 ledger（`edges.jsonl` / `evidence.jsonl` / `entities.yaml`）を **直接読まず**、Spec 5 が提供する Query API 14 種のみを呼び出す。Frontmatter `related:` は cache として補助的に使うが、正本は L2 ledger（API 経由）。
  - **`record_decision` 呼出**: Verify workflow の confirmed / refuted 判定、Hypothesis approve（promote）、Synthesis approve は **必須記録対象**（Spec 5 Requirement 11.6 と整合）。reasoning は chat session auto-generate / `--reason` flag / default skip の hybrid（Spec 5 Requirement 11.5 と整合）。
  - **`[INFERENCE]` マーカー**: Hypothesis 出力本文に必須付与、推論部分を明示。Perspective は trust chain を維持するため `[INFERENCE]` を使わず wiki / evidence 引用形式。
  - **Configuration**: `.rwiki/config.yml` の `graph.perspective.*` / `graph.hypothesis.*` / `graph.verify.*` / `chat.autonomous.maintenance_triggers.*` の全項目を本 spec が所管（係数値・閾値・top_m・default depth・evidence 候補件数 N 等）。

- **Out of scope**:
  - **L2 Graph Ledger 実装**: ledger 7 ファイルの data model、Query API 14 種の物理実装、Hygiene 進化則、Confidence scoring、Edge lifecycle、Community detection アルゴリズム、SQLite cache、Reject workflow、Decision log 物理実装は Spec 5 所管。本 spec は API contract の呼出側のみ。
  - **Skill ファイル内容**: `perspective_gen.md` / `hypothesis_gen.md` の prompt 本文・Processing Rules・Failure Conditions の記述は Spec 2 所管（本 spec は出力 schema と invocation interface を要求するに留める）。
  - **Skill dispatch ロジック**: 明示 `--skill` → frontmatter `type:` → `categories.yml` `default_skill` → LLM 推論の 4 段階優先順位は Spec 3 所管（distill 専用）。本 spec の Perspective / Hypothesis は Spec 3 dispatch を **経由しない**（固定 skill 直接呼出）。
  - **CLI dispatch / argparse / `rw chat` 統合フレーム**: `rw perspective` / `rw hypothesize` / `rw verify` / `rw approve <hypothesis-id>` の引数 parse、Hybrid 実行（subprocess timeout 必須）、対話 confirm UI、`--auto` ポリシー、exit code 0/1/2 制御、Maintenance UX の表示 layer は Spec 4 所管。本 spec は内部 handler ロジックを `cmd_perspective` / `cmd_hypothesize` / `cmd_verify` / `cmd_approve_hypothesis` 関数として提供する側。
  - **Page lifecycle 操作・8 段階対話 handler**: `cmd_promote_to_synthesis` / `cmd_deprecate` / `cmd_retract` / `cmd_archive` 等の handler ロジック、警告 blockquote 自動挿入、Backlink 更新は Spec 7 所管。本 spec は Confirmed hypothesis の wiki 昇格時に Spec 7 handler を **呼び出す側** であり、状態遷移ルール本体には立ち入らない。
  - **Maintenance autonomous trigger の閾値計算実装**: reject queue 件数計算 / decay edges 件数計算 / typed-edge 整備率計算 / dangling edge 件数計算 / 最終 audit 実行日時取得は Spec 5（L2 診断項目）と Spec 7（L3 診断項目）の所管。本 spec はそれらの結果を取得して surface 表示する側のみ（surface UX 表示自体は Spec 4 と coordination）。
  - **Frontmatter スキーマ宣言**: §5.9.1 Hypothesis candidate / §5.9.2 Perspective 保存版の field 名・型・許可値の **宣言** は Foundation §5.9 / Spec 1 が骨格を所管。本 spec は宣言を **読み書き** する側。
  - **L3 frontmatter `related:` cache の sync 実装**: Spec 5 が `rw graph rebuild --sync-related` / Hygiene batch sync で実装。本 spec は cache が stale でも動作（正本は API 経由で L2 ledger を読む）。
  - **`rw chat` autonomous mode の発火条件・閾値・頻度制限の表示 layer**: Spec 4 所管（信頼度 ≥ 7/10 / 3 発話に 1 回 / novelty 判定 / context sensing の表示処理）。本 spec は autonomous mode が呼び出された場合の Perspective / Hypothesis 生成ロジックのみ。
  - **Severity 4 水準 / exit code 0/1/2 分離 / LLM CLI subprocess timeout 必須 規約定義**: Foundation Requirement 11 / roadmap.md「v1 から継承する技術決定」が固定済、本 spec は継承。

- **Adjacent expectations**:
  - 本 spec は Foundation（Spec 0、`rwiki-v2-foundation`）が固定する 13 中核原則のうち §2.1 Paradigm C / §2.9 Graph as first-class / §2.10 Evidence chain / §2.11 Discovery primary / Maintenance LLM guide / §2.12 Evidence-backed Candidate Graph（L2 専用）/ §2.13 Curation Provenance を **設計前提** として参照し、独自定義による再解釈・再命名を行わない。Foundation の用語と矛盾する記述が必要になった場合は先に Foundation を改版する（roadmap.md「Adjacent Spec Synchronization」運用ルール）。
  - 本 spec は Foundation Requirement 5 が固定する Hypothesis status 7 種（`draft / verified / confirmed / refuted / promoted / evolved / archived`）を **唯一の所管 status set** として継承し、独自に状態を追加・改名しない。Page status / Edge status とは独立した第 3 の status 軸であることを尊重する。
  - **Spec 6 ↔ Spec 5 coordination**: Spec 5 が SSoT として固定する Query API 14 種の signature と返り値 schema（edges.jsonl と同形 dict）を本 spec の **唯一の L2 入力 contract** として依存し、本 spec は L2 ledger ファイルを直接読まない。`record_decision` API も Spec 5 経由で呼び、Verify confirmed / refuted、Hypothesis promote、Synthesis approve を必須記録する。`edge_events.jsonl` への `used_in_save_perspective` / `human_verification_support` event 追記も Spec 5 が提供する API（Hygiene の usage_signal 入力）を経由。Query API signature 変更が必要な場合は Spec 5 を先行改版（roadmap.md「Adjacent Spec Synchronization」運用ルール）。
  - **Spec 6 ↔ Spec 2 coordination**: 本 spec は `AGENTS/skills/perspective_gen.md` / `AGENTS/skills/hypothesis_gen.md` の **存在と invocation interface（入力 schema・出力 schema）を要求** し、Spec 2 が両 skill を 8 section スキーマ + frontmatter スキーマで配布する。両 skill は Spec 2 の skill lifecycle（install / deprecate / retract）に参加（Spec 2 Adjacent expectations と整合）。両 skill の出力 schema 変更は本 spec を先行改版。
  - **Spec 6 ↔ Spec 3 coordination**: 本 spec の `rw perspective` / `rw hypothesize` / `rw verify` / `rw approve` は Spec 3 dispatch を **経由しない**（v0.7.10 決定 6-1、Spec 3 Requirement 10 と整合）。固定 skill `perspective_gen` / `hypothesis_gen` を本 spec 内部で直接呼出し、`--skill <name>` 指定や frontmatter `type:` 解釈は不要。
  - **Spec 6 ↔ Spec 4 coordination**: 本 spec は handler ロジック（`cmd_perspective` / `cmd_hypothesize` / `cmd_verify` / `cmd_approve_hypothesis`）を Spec 4 の CLI dispatch から呼び出せる形で提供し、引数 parse・Hybrid 実行（subprocess timeout 必須）・対話 confirm UI・`--auto` ポリシー・exit code 制御・Maintenance UX 表示は Spec 4 所管。Maintenance autonomous trigger の surface 表示・`/dismiss` / `/mute maintenance` 受付・`--mode autonomous` toggle も Spec 4 所管、本 spec は trigger 計算結果取得と提示内容生成のみ。
  - **Spec 6 ↔ Spec 7 coordination**: Confirmed hypothesis の wiki 昇格は Spec 7 の `cmd_promote_to_synthesis` 8 段階対話 handler を呼び出す（Scenario 16 と同フロー）。本 spec は呼出側、Spec 7 は handler 実装側として責務分離。`promote-to-synthesis` は Spec 7 Requirement 6 で `--auto` 不可指定として固定済（必ず 8 段階対話を経由）。Hypothesis 本体は `review/hypothesis_candidates/` に残し status `promoted` に更新（本 spec 所管）、wiki/synthesis/ 配置は Spec 7 所管。
  - **Spec 6 ↔ Spec 1 coordination**: Hypothesis candidate frontmatter（§5.9.1）と Perspective 保存版 frontmatter（§5.9.2）の field 宣言は Foundation §5.9 / Spec 1 の所管。本 spec は宣言された field を **読み書き** する側。
  - 本 spec は roadmap.md「v1 から継承する技術決定」のうち、(a) Severity 4 水準（CRITICAL / ERROR / WARN / INFO）、(b) exit code 0/1/2 分離、(c) LLM CLI subprocess timeout 必須、を継承する。

## Requirements

### Requirement 1: `rw perspective <topic>` 生成ロジック

**Objective:** As a Rwiki v2 ユーザーおよび Spec 4 起票者, I want `rw perspective <topic>` がトピックに関連する複数視点（支持・反論・補完・代替）を 5 段階処理フローで生成し、stdout 出力（default）または `review/perspectives/` 保存（`--save` 時）を行う, so that L2 Graph Ledger に蓄積された stable / core edges を活用して既存知識の再解釈・関係性発見を user に surface できる。

#### Acceptance Criteria

1. The Perspective Generator shall `rw perspective <topic>` の handler ロジック（Spec 4 から呼ばれる `cmd_perspective` 関数）として、Requirement 4 の 5 段階処理フローを実行することを規定する。
2. The Perspective Generator shall Step 2 traverse の filter 閾値を **`status IN (stable, core) AND confidence ≥ 0.4`** として固定し、Spec 5 Query API（`get_neighbors` / `get_shortest_path` 等）に当該 filter を渡すことを規定する。
3. The Perspective Generator shall Step 3 候補選定で Requirement 5 の Perspective scoring（`0.6 × confidence + 0.3 × recency + 0.1 × novelty`）を適用し、top-M 件（default 20）を選定することを規定する。
4. The Perspective Generator shall depth default 値を `2` として固定し、`--depth N` で上書き可能にすることを規定する（CLI 引数 parse は Spec 4）。
5. While `--scope global` flag が指定された場合, the Perspective Generator shall Spec 5 Query API `get_global_summary(scope, method)` を呼び、L2 Graph Ledger 全体の主要 cluster / 主要人物・著者 / 未検証仮説等を集約して返すことを規定する（Scenario 14 パターン F）。
6. While `--method hierarchical-summary` flag が指定された場合, the Perspective Generator shall Spec 5 Query API `get_hierarchical_summary(community_id)` を on-demand で呼び、community 単位の要約を返すことを規定する。
7. The Perspective Generator shall 出力 default を **stdout** とし、`--save` 指定時のみ `review/perspectives/<slug>-<ts>.md` にファイル化することを規定する（§5.9.2 frontmatter スキーマに準拠）。
8. When Perspective が `--save` で保存された, the Perspective Generator shall 保存ファイルの frontmatter に `traversed_edges:` field として活用した全 edge_id を列挙し、各 edge に対して `used_in_save_perspective` event を Spec 5 経由で `edge_events.jsonl` に追記することを規定する（usage_signal 加算、Spec 5 Hygiene の Reinforcement 入力）。
9. The Perspective Generator shall trust chain を維持するため出力本文に wiki / evidence 引用形式（`[wiki/path]` / `[ev_XXX]` 等）で根拠を明示し、`[INFERENCE]` マーカーは **使用しない** ことを規定する（Hypothesis との性質差、Scenario 14 §1 表と整合）。
10. The Perspective Generator shall Community-aware traversal として Spec 5 `get_communities` の結果を活用し、cluster 内 / cluster 境界 bridge を区別して提示することを規定する（Scenario 14 パターン G）。

### Requirement 2: `rw hypothesize <topic>` 生成ロジック

**Objective:** As a Rwiki v2 ユーザーおよび Spec 4 起票者, I want `rw hypothesize <topic>` が L2 の missing bridges や candidate edges から evidence 検証可能な未検証命題（Hypothesis）を生成し、必ず `review/hypothesis_candidates/` にファイル化する, so that 「知識の前進・拡張」のための仮説候補が永続化され、後続の `rw verify` で半自動検証ワークフローに供給できる。

#### Acceptance Criteria

1. The Hypothesis Generator shall `rw hypothesize <topic>` の handler ロジック（Spec 4 から呼ばれる `cmd_hypothesize` 関数）として、Requirement 4 の 5 段階処理フローを実行することを規定する。
2. The Hypothesis Generator shall Step 2 traverse の filter 閾値を **`status IN (candidate, stable, core) AND confidence ≥ 0.3`** として固定し、Spec 5 Query API に当該 filter を渡すことを規定する（candidate も対象、未確定 edge から仮説種を拾う、`evidence-less ceiling 0.3` と同値で evidence のある weak edge は除外）。
3. The Hypothesis Generator shall Step 3 候補選定で Requirement 5 の Hypothesis scoring（`0.5 × novelty + 0.3 × confidence + 0.2 × bridge_potential`）を適用し、top-M 件（default 20）を選定することを規定する。
4. The Hypothesis Generator shall Spec 5 Query API `find_missing_bridges(cluster_a, cluster_b, top_n)` を呼び、bridge_potential 計算に活用することを規定する。
5. The Hypothesis Generator shall 出力を **必ず** `review/hypothesis_candidates/<slug>-<ts>.md` にファイル化することを規定する（stdout 出力のみは禁止、§5.9.1 frontmatter スキーマに準拠）。
6. The Hypothesis Generator shall 出力本文の推論部分に **`[INFERENCE]` マーカーを必須付与** し、Trust chain が検証前であることを明示することを規定する（Scenario 14 §1 表 / Foundation §1 中核価値と整合）。
7. The Hypothesis Generator shall Hypothesis 候補を **evidence 検証可能な命題に限定** することを規定し、純粋な理論的命題（定義変更提案、概念の一般化等）は Perspective 担当である旨を skill prompt（Spec 2 所管）と本 spec の handler ロジックの両方で参照可能にする。
8. When Hypothesis が新規生成された, the Hypothesis Generator shall frontmatter に以下を必須記録することを規定する（§5.9.1 と整合）。
   - `title` / `hypothesis`（仮説本文 1-2 文）/ `origin: [wiki/path, ...]`（根拠 wiki ページ）/ `origin_edges: [edge_id, ...]`（L2 Graph Ledger への逆参照）/ `generated_by: hypothesis_generation` / `generated_at`（YYYY-MM-DD）/ `status: draft` / `confidence: low|medium|high` / `verification_attempts: []`（空配列で初期化）
9. The Hypothesis Generator shall Hypothesis ID（slug）を `hyp-<short-hash-or-topic-slug>` 等の一意の文字列として生成することを規定し、後続 `rw verify <hypothesis-id>` / `rw approve <hypothesis-id>` で参照可能にする（具体的命名規則は design 段階で確定）。
10. The Hypothesis Generator shall 生成された Hypothesis 候補の status 初期値を `draft` とすることを規定する（Foundation Requirement 5 / Hypothesis status 7 種と整合）。

### Requirement 3: 固定 skill `perspective_gen` / `hypothesis_gen` の load 規約と Spec 3 dispatch 対象外

**Objective:** As a Spec 2 / Spec 3 起票者, I want `rw perspective` / `rw hypothesize` が Spec 2 配布の固定 skill `perspective_gen` / `hypothesis_gen` を本 spec 内部で直接呼び出し、Spec 3 dispatch を経由しないことが固定されている, so that L1 発見 CLI の UX が `--skill <name>` 指定不要で完結し、Perspective / Hypothesis 用 skill 選択ロジックが二重実装されない。

#### Acceptance Criteria

1. The Spec 6 Perspective-Hypothesis Subsystem shall `rw perspective` 実行時に `AGENTS/skills/perspective_gen.md` を **固定 skill 名で直接 load** し、Spec 3 dispatch を経由しないことを規定する（v0.7.10 決定 6-1 / Spec 3 Requirement 10 と整合）。
2. The Spec 6 Perspective-Hypothesis Subsystem shall `rw hypothesize` 実行時に `AGENTS/skills/hypothesis_gen.md` を **固定 skill 名で直接 load** し、Spec 3 dispatch を経由しないことを規定する。
3. The Spec 6 Perspective-Hypothesis Subsystem shall `--skill <name>` flag や frontmatter `type:` 解釈を Perspective / Hypothesis 起動時に **要求しない** ことを規定する（distill 専用機能であるため）。
4. The Spec 6 Perspective-Hypothesis Subsystem shall `perspective_gen` / `hypothesis_gen` skill が Spec 2 の skill lifecycle（install / deprecate / retract）に参加することを規定し、両 skill が Spec 2 Requirement 2 の 8 section スキーマと Requirement 3 の frontmatter スキーマを満たすことを Spec 2 ↔ Spec 6 coordination 確定事項として依存する。
5. If `perspective_gen` または `hypothesis_gen` skill が `AGENTS/skills/` に存在しない、または frontmatter `status` が `active` 以外（`deprecated` / `retracted` / `archived`）である, then the Spec 6 Perspective-Hypothesis Subsystem shall ERROR severity で操作を拒否し、`generic_summary` fallback には **降格しない** ことを規定する（distill とは異なり Perspective / Hypothesis は固定 skill が必須）。
6. The Spec 6 Perspective-Hypothesis Subsystem shall 両 skill の出力 schema 変更が必要となった場合に Spec 2 を先行改版する手順（roadmap.md「Adjacent Spec Synchronization」運用ルール）を参照点として残すことを規定する。
7. The Spec 6 Perspective-Hypothesis Subsystem shall LLM CLI を呼び出す全 subprocess 起動箇所で subprocess timeout を必須設定として渡すことを規定する（roadmap.md「v1 から継承する技術決定」と整合）。

### Requirement 4: 5 段階処理フロー（Step 1-5、Perspective / Hypothesize 共通）

**Objective:** As a Perspective / Hypothesis 生成の中核処理基盤, I want 5 段階処理フロー（seed 特定 → N-hop traverse → top-M 選定 → 本文読込 → 統合分析 + 出力 + edge reinforcement）が固定されている, so that Perspective と Hypothesis が同一フローを共有し、各 step の責務が明確化される。

#### Acceptance Criteria

1. The Spec 6 Perspective-Hypothesis Subsystem shall **Step 1（seed 特定）** として、`<topic>` を Grep（`raw/` / `wiki/`）または user 指定から取得し、Spec 5 Query API（`entities.yaml` の正規化結果を返す API）で正規化することを規定する。
2. The Spec 6 Perspective-Hypothesis Subsystem shall **Step 2（N-hop traverse）** として、Spec 5 Query API（`get_neighbors(seed, depth, filter)` / `get_shortest_path(from, to, filter)` 等）を depth default 2 で呼び、Requirement 1.2 / 2.2 の filter 閾値を渡し、edges + nodes の metadata を取得することを規定する（**本文未読**、SQLite cache 経由で高速 traverse）。
3. The Spec 6 Perspective-Hypothesis Subsystem shall **Step 3（top-M 選定）** として、Step 2 で取得した候補集合に対し Requirement 5 の scoring function を適用して ranking し、上位 M 件（default 20）を選定することを規定する。
4. The Spec 6 Perspective-Hypothesis Subsystem shall **Step 4（本文読込）** として、Step 3 で選択された M 件の wiki ページ本文を Read し、Spec 5 Query API（`get_edge_history` 等）で関連 evidence を `evidence.jsonl` から参照することを規定する。
5. The Spec 6 Perspective-Hypothesis Subsystem shall **Step 5（統合分析 + 出力 + edge reinforcement）** として、(a) LLM が固定 skill prompt（`perspective_gen` または `hypothesis_gen`）に Step 4 の本文 + evidence を投入して統合分析、(b) 結果を Perspective stdout/save または Hypothesis review file に出力、(c) 使われた edge 全てに `usage_signal` を加算（Spec 5 経由で `edge_events.jsonl` に追記）することを規定する。
6. The Spec 6 Perspective-Hypothesis Subsystem shall Step 5 で記録する usage_signal の種別を **Direct**（answer 本文で edge を引用）/ **Support**（補強引用）/ **Retrieval**（traverse touch、answer に未採用）/ **Co-activation**（同 session 内同時 traverse）の 4 種から適切に選んで Spec 5 API に渡すことを規定する（Spec 5 Requirement 8 / Hygiene Reinforcement 入力と整合）。
7. The Spec 6 Perspective-Hypothesis Subsystem shall 5 段階フローのいずれかの step がランタイムエラーで失敗した場合、stderr にエラー内容を出力し exit code 1（runtime error）で終了することを規定する（exit code 制御は Spec 4 経由）。
8. While Step 2 traverse 結果が **空集合**（seed に紐付く edges が 0 件）, the Spec 6 Perspective-Hypothesis Subsystem shall WARN severity で「seed `<topic>` に紐付く edge が見つかりません、`rw extract-relations` で typed edges を育てるか、別 topic を試してください」と通知することを規定する。

### Requirement 5: 候補選定 scoring（Perspective / Hypothesis 別系統）

**Objective:** As a Step 3 top-M 選定の基盤, I want Perspective scoring（信頼性重視）と Hypothesis scoring（未発見重視）が別系統で固定され、各係数値・top_m が config 注入される, so that 同じ traverse 結果から Perspective は高 confidence の安定 edge を、Hypothesis は novelty の高い未発見関係を surface できる。

#### Acceptance Criteria

1. The Spec 6 Perspective-Hypothesis Subsystem shall Perspective scoring を **`score = 0.6 × confidence + 0.3 × recency + 0.1 × novelty`** として固定することを規定する（係数値合計 1.0、信頼性重視）。
2. The Spec 6 Perspective-Hypothesis Subsystem shall Hypothesis scoring を **`score = 0.5 × novelty + 0.3 × confidence + 0.2 × bridge_potential`** として固定することを規定する（係数値合計 1.0、未発見重視）。
3. The Spec 6 Perspective-Hypothesis Subsystem shall 各 score 要素を以下のとおり計算することを規定する。
   - `confidence`: edge.confidence（0.0-1.0、Spec 5 が edges.jsonl で管理）
   - `recency`: `exp(-days_since_last_event / half_life)`、half_life default 30 日（Spec 5 `get_edge_history` から `edge_events.jsonl` の最新 event 日時を取得）
   - `novelty`: `1 - (edges_derived_from_same_raw_count / total_related_edges)`、高いほど独自（同一 raw 由来の edges が少ないほど novel）
   - `bridge_potential`: `find_missing_bridges` 由来の類似度スコア（Hypothesis のみ）
4. The Spec 6 Perspective-Hypothesis Subsystem shall scoring 係数値 / top_m / depth default を `.rwiki/config.yml` の `graph.perspective.*` / `graph.hypothesis.*` から注入することを規定し、本 spec のコードに係数値をハードコードしないことを規定する（Requirement 13 と整合）。
5. The Spec 6 Perspective-Hypothesis Subsystem shall top_m の default 値を **20** として固定し、`graph.perspective.top_m` / `graph.hypothesis.top_m` で上書き可能にすることを規定する。
6. If config 値が未配置である, then the Spec 6 Perspective-Hypothesis Subsystem shall default 値（Requirement 5.1 / 5.2 / 5.5）で動作し、INFO で「config 未配置、default 値で動作」と通知することを規定する。
7. The Spec 6 Perspective-Hypothesis Subsystem shall scoring 計算で必要な情報（confidence / recency 元 event / novelty 元 raw 由来集合 / bridge_potential）を **すべて Spec 5 Query API から取得** することを規定し、L2 ledger ファイルを直接読まないことを規定する（Requirement 11 と整合）。

### Requirement 6: L2 Ledger 成熟度別 fallback（graceful degradation）

**Objective:** As a Typed edges 未整備時の Perspective / Hypothesis 利用者, I want L2 Ledger の成熟度に応じて fallback（極貧時は警告 + extract-relations 推奨、疎時は INFO、通常時は full quality）が動作する, so that ledger が育っていない初期段階でも Perspective / Hypothesis が破綻せず、ユーザーが ledger を育てる動機付けを得られる。

#### Acceptance Criteria

1. The Spec 6 Perspective-Hypothesis Subsystem shall L2 Ledger 成熟度を以下 3 段階で判定することを規定する（Spec 5 Query API から件数を取得して計算）。
   - **極貧**: stable + core edges < 10 件
   - **疎**: stable 比率（stable / total）< 20%
   - **通常**: stable + core が全 edges の 50% 超
2. While L2 Ledger が **極貧** 状態である場合, the Spec 6 Perspective-Hypothesis Subsystem shall WARN severity で「L2 Graph Ledger が成熟していません（stable+core edges < 10 件）。`rw extract-relations` で typed edges を育成してください」を出力し、Perspective / Hypothesis の生成は **試行する**（拒否はせず）ことを規定する。
3. While L2 Ledger が **疎** 状態である場合, the Spec 6 Perspective-Hypothesis Subsystem shall INFO severity で「ledger 成熟途上、candidate 多」を出力し、生成を継続することを規定する。
4. While L2 Ledger が **通常** 状態である場合, the Spec 6 Perspective-Hypothesis Subsystem shall fallback 通知を出さず full quality で動作することを規定する。
5. The Spec 6 Perspective-Hypothesis Subsystem shall 成熟度判定の閾値（10 / 20% / 50%）を `.rwiki/config.yml` の `graph.perspective.maturity_thresholds.*` から注入することを規定し、ハードコードしないことを規定する。
6. If Step 2 traverse 結果が空集合かつ ledger 成熟度が極貧, then the Spec 6 Perspective-Hypothesis Subsystem shall Requirement 4.8 の WARN と Requirement 6.2 の WARN を **両方** 出力することを規定する（重複ではなく、別観点の通知）。
7. The Spec 6 Perspective-Hypothesis Subsystem shall L2 Ledger 成熟度を毎回起動時に再計算することを規定する（cache せず、ledger 状態の変化を即座に反映）。

### Requirement 7: Hypothesis 7 状態管理（draft / verified / confirmed / refuted / promoted / evolved / archived）

**Objective:** As a Hypothesis lifecycle の管理基盤, I want Hypothesis status 7 種の状態遷移が固定され、Page status / Edge status と独立した第 3 の status 軸として運用される, so that 仮説の生成 → 検証 → 確認 → 昇格 / 棄却 / 進化 / 履歴化のライフサイクルが追跡可能になり、Trust chain が保全される。

#### Acceptance Criteria

1. The Spec 6 Perspective-Hypothesis Subsystem shall Hypothesis status を `draft` / `verified` / `confirmed` / `refuted` / `promoted` / `evolved` / `archived` の 7 値として固定し、Foundation Requirement 5 と完全一致させる。
2. The Spec 6 Perspective-Hypothesis Subsystem shall 各 status の意味を以下のとおり定義することを規定する。
   - `draft`: 生成直後、未 verify
   - `verified`: `rw verify` 実行済、判定保留中（evidence 不足含む）
   - `confirmed`: `rw verify` で confirmed 判定、`rw approve` 可能
   - `refuted`: `rw verify` で refuted 判定、wiki 昇格不可だが履歴として保存（「失敗からも学ぶ」）
   - `promoted`: `rw approve` 経由で `wiki/synthesis/` に昇格済、`successor_wiki:` 記録
   - `evolved`: 検証結果から新 hypothesis が派生、当該 hypothesis は履歴扱い
   - `archived`: 古い hypothesis を履歴化（手動）
3. The Spec 6 Perspective-Hypothesis Subsystem shall status 遷移先を以下のとおり規定する: `draft → {verified}` / `verified → {confirmed, refuted, evolved, verified}`（再 verify 可）/ `confirmed → {promoted, archived, evolved}` / `refuted → {archived, evolved}` / `promoted → {}`（不可逆、wiki/synthesis/ への昇格完了）/ `evolved → {archived}` / `archived → {}`（不可逆）。
4. When Hypothesis 候補が新規生成された, the Spec 6 Perspective-Hypothesis Subsystem shall status を `draft` で初期化することを規定する（Requirement 2.10 と整合）。
5. When `rw verify <hypothesis-id>` が完了した, the Spec 6 Perspective-Hypothesis Subsystem shall 判定結果に応じて status を `verified`（保留 / 不足）/ `confirmed`（supporting≥2 ∧ refuting=0）/ `refuted`（refuting≥2）/ `evolved`（新 hypothesis 派生時）に遷移させることを規定する（Requirement 8 と整合）。
6. When `rw approve <hypothesis-id>` が成功した（Spec 7 の 8 段階対話を完走した）, the Spec 6 Perspective-Hypothesis Subsystem shall status を `confirmed → promoted` に遷移させ、`successor_wiki:` field に `wiki/synthesis/<slug>.md` の path を記録することを規定する（Requirement 9 と整合）。
7. The Spec 6 Perspective-Hypothesis Subsystem shall Hypothesis 本体ファイル（`review/hypothesis_candidates/<id>.md`）を **物理削除しない** ことを規定し、`promoted` / `refuted` / `archived` 状態でも履歴として保持することを規定する（Foundation §2.6 / §1.3.5「失敗からも学ぶ」と整合）。
8. The Spec 6 Perspective-Hypothesis Subsystem shall status 遷移を frontmatter 編集のみで表現し、ディレクトリ移動を伴わないことを規定する（Foundation §2.3 と整合）。
9. The Spec 6 Perspective-Hypothesis Subsystem shall Hypothesis status を Page status（5 種）/ Edge status（6 種）と **独立した第 3 の status 軸** として扱い、共通の状態セットとして混同しないことを規定する（Foundation Requirement 5.4 / §5.9.1 「3 種類の status の独立性」表と整合）。

### Requirement 8: Verify workflow 半自動 4 段階（`rw verify <hypothesis-id>`）

**Objective:** As a Hypothesis 検証の中核基盤, I want `rw verify <hypothesis-id>` が半自動 4 段階（LLM 候補抽出 → user 個別評価 → LLM 集約判定 → 結果記録）で動作し、人間が「個別 evidence の採否判断」に集中、LLM が「候補抽出」と「集約判定」で support する, so that Karpathy 哲学 §1.3.5「人間は判断、LLM は実務」と整合した検証ワークフローが成立し、検証で使われた edge が reinforcement event として L2 にフィードバックされる。

#### Acceptance Criteria

1. The Verify Workflow shall `rw verify <hypothesis-id>` の handler ロジック（Spec 4 から呼ばれる `cmd_verify` 関数）として、以下 4 段階を順次実行することを規定する。
2. The Verify Workflow shall **Step 1（LLM が candidate evidence 抽出）** として、対象 hypothesis の key terms（hypothesis 本文 + `origin: [wiki/path, ...]` から抽出）で `raw/**/*.md` を grep + semantic similarity で検索し、N 件（default 5）の候補 evidence を抽出することを規定する。各候補について `file` / `quote` / `span`（行番号 range）を提示する。
3. The Verify Workflow shall **Step 2（ユーザーが evidence を個別評価）** として、各候補に対し `supporting / refuting / partial / none` の 4 択を user に提示することを規定する。`--add-evidence <path>:<span>` で手動追加 evidence を指定可能にする。
4. The Verify Workflow shall **Step 3（LLM が collected evidence から最終 status を判定）** として、以下のルールで status を決定することを規定する。
   - **supporting ≥ 2 件 かつ refuting = 0 → `confirmed`**
   - **refuting ≥ 2 件 → `refuted`**
   - **supporting + refuting が混在 → `partial`**（user が追加調査するか、`--force-status` で強制 status 指定可能）
   - **evidence 不足（supporting + refuting < 2）→ `verified`**（status 据置、追加 verify 待ち）
5. The Verify Workflow shall **Step 4（結果の記録）** として、frontmatter `verification_attempts` に append-only で entry を追加することを規定する（§5.9.1 と整合）。entry 構造は以下のとおり。
   - `date: YYYY-MM-DD` / `evidence_searched: [path, ...]` / `supporting_evidence: [{evidence_id, quote, source}, ...]` / `refuting_evidence: [...]` / `outcome: pending|confirmed|refuted|evolved` / `edge_reinforcements: [{edge_id, delta: +0.NN}, ...]`（confirmed/refuted のみ）
6. When Verify Workflow が **confirmed** または **refuted** で完了した, the Verify Workflow shall hypothesis の `origin_edges` で参照される L2 edges に対し、Spec 5 経由で `human_verification_support` event を `edge_events.jsonl` に append することを規定する。delta 値は Spec 5 Hygiene の `supporting_evidence_reinforcement_delta`（default +0.28）を参照する。
7. When Verify Workflow が **confirmed** または **refuted** で完了した, the Verify Workflow shall Spec 5 `record_decision` API を呼び、`decision_type: hypothesis_verify` で必須記録することを規定する（Spec 5 Requirement 11.6「`hypothesis_verify_confirmed` / `hypothesis_verify_refuted` は reasoning 必須」と整合、reasoning 入力は hybrid 方式）。
8. When Verify Workflow が完了した, the Verify Workflow shall Requirement 7.5 に従い hypothesis の status を `verified` / `confirmed` / `refuted` / `evolved` のいずれかに遷移させることを規定する。
9. The Verify Workflow shall N（candidate evidence 件数）の default 値を **5** とし、`graph.verify.candidate_evidence_count` で上書き可能にすることを規定する（Requirement 13 と整合）。
10. The Verify Workflow shall LLM CLI を呼び出す全 subprocess 起動箇所で subprocess timeout を必須設定として渡すことを規定する。
11. While Step 1 で候補 evidence が **0 件** 抽出された場合, the Verify Workflow shall INFO severity で「key terms に該当する evidence が `raw/**/*.md` に見つかりませんでした、`--add-evidence` で手動指定するか、新規 raw を ingest してから再 verify してください」を出力し、status を `verified`（据置）にすることを規定する。

### Requirement 9: `rw approve <hypothesis-id>` と Confirmed hypothesis の wiki 昇格 trigger

**Objective:** As a Spec 7 起票者および Confirmed hypothesis を wiki 昇格させる利用者, I want `rw approve <hypothesis-id>` が status `confirmed` のみ受け付け、Spec 7 の 8 段階対話 handler（`cmd_promote_to_synthesis`）を呼び出して Scenario 16 と同フローで `wiki/synthesis/` に昇格させる, so that Hypothesis の wiki 昇格 trigger が本 spec、状態遷移ルールと 8 段階対話本体が Spec 7 という責務分離が明確になる。

#### Acceptance Criteria

1. The Spec 6 Perspective-Hypothesis Subsystem shall `rw approve <hypothesis-id>` の handler ロジック（Spec 4 から呼ばれる `cmd_approve_hypothesis` 関数）として、対象 hypothesis の status が `confirmed` であることを **事前 check** することを規定する。
2. If 対象 hypothesis の status が `confirmed` 以外（`draft` / `verified` / `refuted` / `promoted` / `evolved` / `archived`）, then the Spec 6 Perspective-Hypothesis Subsystem shall ERROR severity で「`rw approve` は status: confirmed の hypothesis のみ受け付けます。`rw verify <id>` を先に実行してください」を出力し、exit code 2（FAIL 検出）で終了することを規定する。
3. When 対象 hypothesis の status が `confirmed` である場合, the Spec 6 Perspective-Hypothesis Subsystem shall Spec 7 の `cmd_promote_to_synthesis(hypothesis_id, target_path)` 8 段階対話 handler を呼び出し、`wiki/synthesis/<slug>.md` 昇格パイプラインに乗せることを規定する（Scenario 16 と同フロー、Spec 7 Requirement 6 で `--auto` 不可指定済み）。
4. When Spec 7 の 8 段階対話が approve まで完走した, the Spec 6 Perspective-Hypothesis Subsystem shall hypothesis 本体（`review/hypothesis_candidates/<id>.md`）の status を `confirmed → promoted` に遷移させ、`successor_wiki:` field に `wiki/synthesis/<slug>.md` の path を記録することを規定する（Requirement 7.6 と整合）。
5. When 昇格が完了した, the Spec 6 Perspective-Hypothesis Subsystem shall Spec 5 `record_decision` API を呼び、`decision_type: synthesis_approve` で必須記録することを規定する（Spec 5 Requirement 11.6「`synthesis_approve` は reasoning 必須」と整合）。
6. The Spec 6 Perspective-Hypothesis Subsystem shall Hypothesis 本体を `wiki/synthesis/` 昇格後も `review/hypothesis_candidates/` に残す（物理削除しない）ことを規定する（Requirement 7.7「歴史保全」と整合）。
7. If Spec 7 の 8 段階対話が user の中断で完了しなかった, then the Spec 6 Perspective-Hypothesis Subsystem shall hypothesis status を `confirmed` のまま維持し、`successor_wiki:` を記録しないことを規定する（再 approve 可能な状態を保つ）。
8. The Spec 6 Perspective-Hypothesis Subsystem shall `rw approve <hypothesis-id>` を `--auto` 不可コマンドとして扱うことを規定し（Spec 7 Requirement 6.4 / Spec 4 Requirement 3.3 と整合、`promote-to-synthesis` は `--auto` 不可リスト）、`--auto` flag が渡されても 8 段階対話を必ず経由することを規定する。

### Requirement 10: Maintenance autonomous trigger 6 種の surface

**Objective:** As a Maintenance UX 利用者および Spec 4 起票者, I want Perspective / Hypothesis 利用中または `rw chat` autonomous mode 中に Maintenance autonomous trigger 6 種が能動的に surface され、ユーザーが蓄積メンテナンスタスクを見逃さない, so that §2.11 Discovery primary / Maintenance LLM guide 原則に従った UX が成立し、reject queue 蓄積 / decay 進行 / typed-edge 整備率低下等が早期に解消される。

#### Acceptance Criteria

1. The Maintenance Autonomous Surface shall 以下 6 種の trigger を提供することを規定する（SSoT v0.7.12 §7.2 Spec 6 / Scenario 33 と整合）。
   - **(a) reject queue 蓄積**: 未処理 reject 候補 ≥ 10 件
   - **(b) Decay 進行 edges**: 未 usage > 7 日の edges ≥ 20 件
   - **(c) Typed-edge 整備率低下**: ページあたり平均 typed-edge < 2.0
   - **(d) Dangling edge**: dangling_flagged 状態 ≥ 5 件
   - **(e) Audit 未実行**: 最終 `rw audit graph` 実行から ≥ 14 日
   - **(f) 未 approve synthesis 候補**: `review/synthesis_candidates/` 未 approve ≥ 5 件
2. The Maintenance Autonomous Surface shall 各 trigger の **計算実装** を Spec 5（L2 診断: a / b / c / d / e）/ Spec 7（L3 診断: f）の API（`rw doctor` 経由 or 直接 API）に委ね、本 spec はそれら値を取得・surface する責務のみを所管することを規定する（Spec 4 Requirement 7.7 / Requirement 8.7 / Spec 5 Requirement 16.8 と整合）。
3. The Maintenance Autonomous Surface shall trigger に該当する状態が検出された場合、`💡 マーカー` で提案を表示することを規定し、各提案に「(該当 trigger) → (推奨対応コマンド)」を併記することを規定する。例: `💡 reject queue に 12 件の candidate edge が蓄積、`rw reject` でレビューしますか？`
4. The Maintenance Autonomous Surface shall **surface のみ行い、自動実行しない** ことを規定する（user 同意があって初めて対応コマンド起動、§1.3.5 哲学「人間は判断、LLM は実務」と整合）。
5. The Maintenance Autonomous Surface shall 同セッション内で同一 trigger を **1 回まで** surface することを規定し、重複表示を防ぐ。
6. While ユーザーが `/dismiss` を入力した場合, the Maintenance Autonomous Surface shall 当該セッション中は同じ trigger を再 surface しないことを規定する（Spec 4 Requirement 8.4 と整合、表示 layer は Spec 4 所管）。
7. While ユーザーが `/mute maintenance` を入力した場合, the Maintenance Autonomous Surface shall それ以降のセッション（永続的）で Maintenance autonomous trigger を抑止することを規定する（Spec 4 Requirement 8.5 と整合、永続化媒体は Spec 4 所管）。
8. The Maintenance Autonomous Surface shall 6 種の trigger 閾値を `.rwiki/config.yml` の `chat.autonomous.maintenance_triggers.*` から注入することを規定し、ハードコードしないことを規定する（Requirement 13 と整合）。
9. While 複数 trigger が同時発火した場合, the Maintenance Autonomous Surface shall Scenario 33 の「複合メンテナンス」原則で優先順位付けして提示することを規定する（具体的優先順位ロジックは design 段階で確定、Spec 4 Maintenance UX と coordination）。
10. The Maintenance Autonomous Surface shall `rw chat --mode autonomous` toggle および対話中 `/mode` toggle に応じて autonomous mode を有効/無効化することを規定する（mode toggle 自体は Spec 4 所管、本 spec は mode 状態を尊重して trigger 発火を抑制 / 許可）。

### Requirement 11: Spec 5 Query API 14 種への依存契約

**Objective:** As a Spec 5 起票者および本 spec 実装者, I want 本 spec が L2 ledger を直接読まず Spec 5 Query API 14 種の signature と返り値 schema を contract として依存することが固定されている, so that Spec 5 の内部実装変更が本 spec に波及せず、L2 ledger 操作の責務が二重に分散しない。

#### Acceptance Criteria

1. The Spec 6 Perspective-Hypothesis Subsystem shall L2 ledger ファイル（`edges.jsonl` / `evidence.jsonl` / `entities.yaml` / `edge_events.jsonl` / `decision_log.jsonl` / `rejected_edges.jsonl` / `reject_queue/`）を **直接読まず**、Spec 5 が提供する Query API 14 種のみを呼び出すことを規定する（Spec 5 Requirement 14 と整合）。
2. The Spec 6 Perspective-Hypothesis Subsystem shall 以下 Spec 5 Query API を本 spec の中核機能で利用することを規定する。
   - **5 段階フロー Step 1（seed 正規化）**: `entities.yaml` 参照系 API
   - **5 段階フロー Step 2（traverse）**: `get_neighbors` / `get_shortest_path` / `get_orphans` / `get_hubs`
   - **`--scope global`**: `get_global_summary(scope, method)`
   - **`--method hierarchical-summary`**: `get_hierarchical_summary(community_id)`
   - **Community-aware traversal**: `get_communities(algorithm)`
   - **Hypothesis bridge_potential 計算**: `find_missing_bridges(cluster_a, cluster_b, top_n)`
   - **Step 4 evidence 参照 / scoring recency**: `get_edge_history(edge_id)`
   - **Verify Step 4 / Approve Step 5 必須記録**: `record_decision(decision)`
   - **Decision 検索（autonomous / 矛盾検出）**: `get_decisions_for(subject_ref)` / `search_decisions(query, filter)` / `find_contradictory_decisions()`
   - **Frontmatter 正規化（参照のみ）**: `normalize_frontmatter(page_path)`
3. The Spec 6 Perspective-Hypothesis Subsystem shall Spec 5 Query API の共通フィルタ（`status_in: List[EdgeStatus]` / `min_confidence: float` / `relation_types: List[str]`）を Requirement 1.2 / 2.2 の filter 閾値に従って渡すことを規定する（Spec 5 Requirement 14.2 と整合）。
4. The Spec 6 Perspective-Hypothesis Subsystem shall Spec 5 Query API の返り値スキーマ（`edges.jsonl` と同形 dict）を入力 contract として参照することを規定し、本 spec が独自の中間スキーマを定義しないことを規定する（Spec 5 Requirement 14.3 と整合）。
5. The Spec 6 Perspective-Hypothesis Subsystem shall L3 frontmatter `related:` を **cache として補助的に使う** ことを許容するが、正本は Spec 5 Query API 経由で L2 ledger を読むことを規定する（cache 鮮度を必須条件にしない、Spec 1 の eventual consistency 規約と整合）。
6. The Spec 6 Perspective-Hypothesis Subsystem shall Spec 5 Query API が Hygiene 実行中でも lock 取得を要求せず動作することを前提とする（Spec 5 Requirement 14.8 / Requirement 17.5 と整合、本 spec は read-only 動作のため `.rwiki/.hygiene.lock` を取得しない）。
7. If Spec 5 Query API の signature 変更が本 spec の利用箇所に影響する, then the Spec 6 Perspective-Hypothesis Subsystem 実装者 shall Spec 5 を先行改版する手順（roadmap.md「Adjacent Spec Synchronization」運用ルール）を参照点として残し、本 spec が独自に L2 ledger を直接読む形に逸脱しないことを規定する。
8. The Spec 6 Perspective-Hypothesis Subsystem shall Spec 5 Query API の性能目標（neighbor depth=2、100-500 edges で 100ms 以下、10,000 edges で 300ms 以下）に依存して Perspective / Hypothesis 生成全体の応答性を担保することを規定する（Spec 5 Requirement 21.3 / 21.4 と整合）。

### Requirement 12: 出力先・対話ログ自動保存・L2 feedback

**Objective:** As a Perspective / Hypothesis / 対話ログの永続化基盤, I want Perspective は stdout default / `--save` で `review/perspectives/`、Hypothesis は必ず `review/hypothesis_candidates/`、`rw chat` セッションは `raw/llm_logs/chat-sessions/`、interactive_synthesis 等の対話 skill ログは `raw/llm_logs/interactive/` に自動保存され、Perspective `--save` / Hypothesis verify confirmed 時に L2 edges へ usage_signal / human_verification_support event が記録される, so that 出力の永続化方針と L2 feedback ループが固定され、Scenario 15 / 25 連携と Spec 5 Hygiene Reinforcement が成立する。

#### Acceptance Criteria

1. The Spec 6 Perspective-Hypothesis Subsystem shall Perspective 出力 default を **stdout** とすることを規定し、ファイル化を default で行わない（CPU / IO コスト最小化、即時利用優先）ことを規定する。
2. When `rw perspective <topic> --save` が実行された, the Spec 6 Perspective-Hypothesis Subsystem shall `review/perspectives/<slug>-<ts>.md` に §5.9.2 frontmatter スキーマで保存することを規定する。frontmatter 必須 field は `title` / `type: perspective` / `generated_by: perspective_generation` / `generated_at` / `trigger`（user 発話・文脈）/ `sources: [wiki/path, ...]` / `traversed_edges: [edge_id, ...]` / `traversed_depth: integer` / `confidence: low|medium|high` / `tags: [...]`。
3. The Spec 6 Perspective-Hypothesis Subsystem shall Hypothesis 出力を **必ず** `review/hypothesis_candidates/<slug>-<ts>.md` にファイル化することを規定する（Requirement 2.5 と整合、§5.9.1 frontmatter スキーマ）。
4. When `rw chat` セッションが起動された, the Spec 6 Perspective-Hypothesis Subsystem shall 対話ログを `raw/llm_logs/chat-sessions/chat-<ts>.md` に自動保存することを規定する（Scenario 15 / 25 と同仕組み、保存実装契約は Spec 4 と coordination）。
5. When interactive_synthesis 等の対話 skill が Perspective / Hypothesis 文脈で呼ばれた, the Spec 6 Perspective-Hypothesis Subsystem shall 対話ログを `raw/llm_logs/interactive/interactive-<skill>-<ts>.md` に自動保存することを規定する（Scenario 15 と同仕組み）。
6. When Perspective が `--save` で保存された, the Spec 6 Perspective-Hypothesis Subsystem shall 保存 file の `traversed_edges:` field に列挙された全 edge_id について、Spec 5 経由で `used_in_save_perspective` event を `edge_events.jsonl` に追記することを規定する（usage_signal 種別 Direct or Support、Spec 5 Hygiene の Reinforcement 入力）。
7. When Hypothesis verify が **confirmed** で完了した, the Spec 6 Perspective-Hypothesis Subsystem shall hypothesis の `origin_edges` で参照される L2 edges に対して Spec 5 経由で `human_verification_support` event を追記することを規定する（Requirement 8.6 と整合、delta は Spec 5 Hygiene `supporting_evidence_reinforcement_delta` を参照）。
8. The Spec 6 Perspective-Hypothesis Subsystem shall 対話ログ自動保存を含む全 file 書込で atomic 更新（write-to-tmp → rename）を採用することを規定する。
9. The Spec 6 Perspective-Hypothesis Subsystem shall 出力本文の言語を **対話文脈に従う**（user 入力言語に追従）こととし、frontmatter は ASCII / 英数記号で記述する（YAML parse 互換性のため）。

### Requirement 13: Configuration（`.rwiki/config.yml` の `graph.perspective` / `graph.hypothesis` / `graph.verify` / `chat.autonomous.maintenance_triggers`）

**Objective:** As a 本 spec 実装者および運用者, I want `.rwiki/config.yml` の本 spec 所管セクション全項目が固定され、係数値・閾値・top_m・default depth・evidence 候補件数・autonomous trigger 閾値をハードコードしないことが規定されている, so that 運用調整が config 編集で完結し、コード変更を伴わない。

#### Acceptance Criteria

1. The Spec 6 Perspective-Hypothesis Subsystem shall `.rwiki/config.yml` の `graph.perspective.*` セクションに以下の項目を所管することを規定する。
   - `scoring_weights.confidence`（default 0.6）
   - `scoring_weights.recency`（default 0.3）
   - `scoring_weights.novelty`（default 0.1）
   - `top_m`（default 20）
   - `depth_default`（default 2）
   - `recency_half_life_days`（default 30）
   - `maturity_thresholds.poor_stable_core_count`（default 10、極貧判定）
   - `maturity_thresholds.sparse_stable_ratio`（default 0.20、疎判定）
   - `maturity_thresholds.normal_stable_core_ratio`（default 0.50、通常判定）
2. The Spec 6 Perspective-Hypothesis Subsystem shall `graph.hypothesis.*` セクションに以下の項目を所管することを規定する。
   - `scoring_weights.novelty`（default 0.5）
   - `scoring_weights.confidence`（default 0.3）
   - `scoring_weights.bridge_potential`（default 0.2）
   - `top_m`（default 20）
   - `depth_default`（default 2）
3. The Spec 6 Perspective-Hypothesis Subsystem shall `graph.verify.*` セクションに以下の項目を所管することを規定する。
   - `candidate_evidence_count`（default 5、Step 1 で抽出する候補 evidence 件数 N）
   - `confirmed_threshold_supporting`（default 2、`supporting ≥ 2 ∧ refuting = 0 → confirmed` の閾値）
   - `refuted_threshold_refuting`（default 2、`refuting ≥ 2 → refuted` の閾値）
4. The Spec 6 Perspective-Hypothesis Subsystem shall `chat.autonomous.maintenance_triggers.*` セクションに以下の項目を所管することを規定する。
   - `reject_queue_threshold`（default 10、Requirement 10.1.a）
   - `decay_edges_threshold`（default 20、Requirement 10.1.b）
   - `decay_warn_days`（default 7、Requirement 10.1.b の「未 usage > 7 日」）
   - `typed_edge_ratio_threshold`（default 2.0、Requirement 10.1.c）
   - `dangling_edge_threshold`（default 5、Requirement 10.1.d）
   - `audit_overdue_days`（default 14、Requirement 10.1.e）
   - `unapproved_synthesis_threshold`（default 5、Requirement 10.1.f）
5. The Spec 6 Perspective-Hypothesis Subsystem shall 上記 config 値をコードにハードコードせず、起動時に config から注入することを規定する。
6. If `.rwiki/config.yml` が存在しない, then the Spec 6 Perspective-Hypothesis Subsystem shall default 値で動作し、INFO で「config 未配置、default 値で動作」と通知することを規定する。
7. The Spec 6 Perspective-Hypothesis Subsystem shall config 値を **cache せず** 起動毎に最新を反映することを規定する（vocabulary 変更が即座に動作に反映、Spec 5 Requirement 2.6 と同方針）。
8. If config 値の合計値（Perspective scoring weights / Hypothesis scoring weights）が 1.0 から逸脱している（例: 0.95 や 1.1）, then the Spec 6 Perspective-Hypothesis Subsystem shall WARN severity で「scoring weights の合計が 1.0 ではありません、ranking が想定挙動と異なる可能性があります」を通知し、当該値で動作を継続することを規定する（拒否はしない）。

### Requirement 14: Coordination の責務分離（Spec 1 / 2 / 3 / 4 / 5 / 7）

**Objective:** As a 周辺 spec 起票者, I want 本 spec の所管（Perspective / Hypothesis 生成ロジック、Verify workflow、Hypothesis 7 状態管理、autonomous trigger surface、Confirmed hypothesis の wiki 昇格 trigger）と周辺 spec の所管（Query API 実装、Skill 内容、CLI dispatch、Page lifecycle 8 段階対話、frontmatter 宣言）の境界が明文で固定されている, so that 周辺 spec 起票時に本 spec を再変更する coordination リスクが消える。

#### Acceptance Criteria

1. The Spec 6 Perspective-Hypothesis Subsystem shall **Spec 6 ↔ Spec 5 coordination** として、Query API 14 種の **signature と返り値 schema** を contract として依存し、L2 ledger ファイルを直接読まないことを本 spec の所管として明示する（Requirement 11 / Spec 5 Requirement 14 / 19.5 と整合）。Query API 実装と Hygiene 進化則は Spec 5 の所管。
2. The Spec 6 Perspective-Hypothesis Subsystem shall **Spec 6 ↔ Spec 2 coordination** として、`perspective_gen` / `hypothesis_gen` skill の **存在と invocation interface** を Spec 2 の所管とし、本 spec が両 skill を固定 skill 名で直接 load することを明示する（Requirement 3 / Spec 2 Adjacent expectations と整合）。両 skill は Spec 2 skill lifecycle に参加し、prompt 内容変更は Spec 2 が所管。
3. The Spec 6 Perspective-Hypothesis Subsystem shall **Spec 6 ↔ Spec 3 coordination** として、本 spec の Perspective / Hypothesis が Spec 3 dispatch を **経由しない** ことを明示する（Requirement 3 / Spec 3 Requirement 10 と整合）。Spec 3 dispatch は distill 専用、Perspective / Hypothesis は固定 skill 直接呼出。
4. The Spec 6 Perspective-Hypothesis Subsystem shall **Spec 6 ↔ Spec 4 coordination** として、`rw perspective` / `rw hypothesize` / `rw verify` / `rw approve <hypothesis-id>` の **CLI dispatch（引数 parse、Hybrid 実行、subprocess timeout、対話 confirm UI、`--auto` ポリシー、Maintenance UX 表示、`--mode autonomous` toggle）** を Spec 4 の所管とし、**生成ロジック・5 段階フロー・Verify workflow・Hypothesis 状態管理・autonomous trigger 計算結果取得** を本 spec の所管として明示する（Spec 4 Requirement 13.3 と整合）。
5. The Spec 6 Perspective-Hypothesis Subsystem shall **Spec 6 ↔ Spec 7 coordination** として、Confirmed hypothesis の wiki 昇格時に Spec 7 の `cmd_promote_to_synthesis` 8 段階対話 handler を **呼び出す側** であり、Page lifecycle 状態遷移ルール本体・8 段階対話 handler・警告 blockquote 自動挿入は Spec 7 の所管であることを明示する（Requirement 9 / Spec 7 Requirement 5 / 6 と整合、`promote-to-synthesis` は Spec 7 で `--auto` 不可指定済み）。
6. The Spec 6 Perspective-Hypothesis Subsystem shall **Spec 6 ↔ Spec 1 coordination** として、Hypothesis candidate frontmatter（§5.9.1）と Perspective 保存版 frontmatter（§5.9.2）の **field 宣言** を Foundation §5.9 / Spec 1 の所管とし、本 spec は **読み書き** する側であることを明示する。
7. If 周辺 spec 起票時に本 spec の生成ロジック・5 段階フロー・Verify workflow・Hypothesis 状態管理・autonomous trigger 設計に変更が必要になった, then the Spec 6 Perspective-Hypothesis Subsystem 実装者 shall 本 spec を先に改版する手順（roadmap.md「Adjacent Spec Synchronization」運用ルール）を参照点として残し、本 spec が独自に逸脱しないことを規定する。

### Requirement 15: Foundation 規範への準拠と文書品質

**Objective:** As a 本 spec の品質保証および将来の更新者, I want 本 spec が Foundation（Spec 0、`rwiki-v2-foundation`）の 13 中核原則・用語集・3 層アーキテクチャ・Hypothesis status 7 種の独立性・§2.10 / §2.11 / §2.12 / §2.13 を SSoT として参照し、CLAUDE.md の出力ルール（日本語・表は最小限・長文は表外箇条書き）に準拠する, so that 用語と原則の解釈が複数 spec で分岐せず、本 spec の可読性と運用整合性が保たれる。

#### Acceptance Criteria

1. The Spec 6 Perspective-Hypothesis Subsystem shall Foundation の 13 中核原則のうち §2.1 Paradigm C / §2.9 Graph as first-class / §2.10 Evidence chain / §2.11 Discovery primary / Maintenance LLM guide / §2.12 Evidence-backed Candidate Graph / §2.13 Curation Provenance を本 spec の **設計前提** として参照することを明示する。
2. The Spec 6 Perspective-Hypothesis Subsystem shall Foundation Requirement 5 が固定する Hypothesis status 7 種（`draft / verified / confirmed / refuted / promoted / evolved / archived`）を本 spec が **唯一の所管 status set** として継承し、独自に状態を追加・改名しないことを規定する（Requirement 7.1 と整合）。
3. The Spec 6 Perspective-Hypothesis Subsystem shall Foundation Requirement 5 の Page status 5 種（Spec 7 所管）と Edge status 6 種（Spec 5 所管）を **本 spec の所管外** として扱い、Page status / Edge status を本 spec で再定義しないことを規定する。
4. The Spec 6 Perspective-Hypothesis Subsystem shall §2.12 を **L2 専用** として扱い、L2 への feedback（usage_signal / `human_verification_support` event）が Spec 5 Hygiene の Reinforcement 入力として動作することを本 spec の前提として規定することを明示する（Foundation Requirement 4 と整合）。
5. The Spec 6 Perspective-Hypothesis Subsystem shall §2.10 Evidence chain を全層を貫く唯一の不変原則として尊重し、Hypothesis verify で `evidence.jsonl` への参照を維持し、Confirmed hypothesis の wiki 昇格時に trust chain（L1 raw → L2 edge / evidence → L3 wiki/synthesis）が切れないことを規定する。
6. The Spec 6 Perspective-Hypothesis Subsystem shall §2.13 Curation Provenance を尊重し、Verify confirmed / refuted、Hypothesis promote、Synthesis approve を Spec 5 `record_decision` API で必須記録することを規定する（Requirement 8.7 / Requirement 9.5 / Spec 5 Requirement 11.6 と整合）。
7. The Spec 6 Perspective-Hypothesis Subsystem shall 本 spec の requirements / design / tasks 文書を日本語で記述し、`spec.json.language=ja` および CLAUDE.md「All Markdown content written to project files MUST be written in the target language」要件に準拠することを規定する。
8. While 本 spec 文書中で表形式を用いる場合, the Spec 6 Perspective-Hypothesis Subsystem shall 表は最小限に留め、長文・解説は表外の箇条書きまたは段落で記述することを規定する（CLAUDE.md 出力ルールと整合）。
9. The Spec 6 Perspective-Hypothesis Subsystem shall 運用前提（Python 3.10+ / git 必須 / LLM CLI subprocess timeout 必須 / Severity 4 水準 / exit code 0/1/2 分離）を Foundation Requirement 11 / roadmap.md「v1 から継承する技術決定」 経由で継承し、独自に再定義しないことを規定する。
10. The Spec 6 Perspective-Hypothesis Subsystem shall 本 spec 自身が `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §5.9.1 / §5.9.2 / §7.2 Spec 6 / §11.0 Scenario 25 / §11.2 v0.7.10 決定 6-1 と `.kiro/drafts/rwiki-v2-scenarios.md` Scenario 14 / 15 / 16 / 33 を SSoT 出典とすることを明示する。
11. If Foundation の用語・原則・マトリクスと矛盾する記述が本 spec に必要となった, then the Spec 6 Perspective-Hypothesis Subsystem 実装者 shall 先に Foundation を改版する手順（roadmap.md「Adjacent Spec Synchronization」運用ルール）を参照点として残し、本 spec を独自に逸脱させないことを規定する。
12. The Spec 6 Perspective-Hypothesis Subsystem shall 本 requirements が定める 15 個の Requirement の各々について、design 段階で「Boundary Commitments」として境界が再確認されることを前提とし、本 requirements の境界（in scope / out of scope / adjacent expectations）を design phase に渡せる形で固定することを規定する。

---

_change log_

- 2026-04-26: 初版生成（v0.7.12 SSoT を基に Spec 6 全 15 Requirement を定義。5 段階フロー / Verify 4 段階 / Maintenance autonomous 6 trigger / Scoring 2 系統 / Hypothesis 7 状態管理を要件化）
