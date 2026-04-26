# Brief: rwiki-v2-foundation

> 出典: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §1-6, §7.2 Spec 0

## Problem

Rwiki v2 は v1 から完全リライトされる Curated GraphRAG 型の知識発見・探索システム。Spec 1-7 は個別機能を実装するが、それらが共通して参照すべきビジョン・原則・用語・アーキテクチャの上位規範が定義されていなければ、各 spec が独自解釈で実装し、整合性が崩れる。

## Current State

- consolidated-spec v0.7.12 にビジョン・13 中核原則・3 層アーキテクチャ・用語集・frontmatter スキーマ・Task & Command モデルが整理済
- v1 の steering / spec は `v1-archive/` に退避済、参照のみ
- v2 の傘 spec が未起票、他 7 spec の上位規範が固定されていない

## Desired Outcome

- v2 全体のビジョン・原則・用語・アーキテクチャを 1 つの spec として固定し、Spec 1-7 が参照する SSoT（Single Source of Truth）が確立される
- 13 中核原則の層別適用マトリクスが明文化され、L1/L2/L3 で異なる人間と LLM の関与モデルが各 spec に伝わる
- 用語の不統一を防ぐ（Edge status 6 種 vs Page status 5 種の混同等）

## Approach

consolidated-spec §1（ビジョン）/ §2（13 中核原則）/ §3（3 層アーキテクチャ）/ §4（用語集 5 分類）/ §5（frontmatter schema）/ §6（command model）を Spec 0 の内容として確定する。個別機能の実装には立ち入らず、規範定義に徹する。

## Scope

- **In**:
  - Trust + Graph + Perspective + Hypothesis 四位一体の中核価値の明文化
  - 3 層アーキテクチャ（L1 Raw / L2 Graph Ledger / L3 Curated Wiki）の定義
  - 13 中核原則（§2.1-§2.13）と層別適用マトリクス
  - コマンド 4 Level 階層（L1 発見 / L2 判断 / L3 メンテ LLM ガイド / L4 Power user）
  - エディタとの責務分離ポリシー（Obsidian を参照実装として）
  - 用語集 5 分類（基本 / アーキテクチャ / Graph Ledger / Perspective-Hypothesis / Operations）
  - Edge status（6 種）と Page status（5 種）の明確な区別
  - Evidence-backed Candidate Graph 原則（§2.12）
- **Out**:
  - 個別機能の実装（他 spec）
  - Graph Ledger 詳細仕様（Spec 5）
  - frontmatter スキーマの実装（Spec 1）

## Boundary Candidates

- 規範定義（本 spec）と実装（他 spec）
- 共通用語集（本 spec）と spec 固有用語（各 spec）
- 13 原則の枠組み（本 spec）と原則の実装ロジック（各 spec）

## Out of Boundary

- frontmatter フィールドの詳細スキーマと vocabulary（Spec 1）
- L2 Graph Ledger の data model と API（Spec 5）
- 個別 CLI コマンドの実装（Spec 4）
- Skill 設計と dispatch（Spec 2 / Spec 3）
- Page lifecycle 操作の実装（deprecate / retract / archive / merge / split / rollback、Spec 7）
- Perspective / Hypothesis 生成ロジックの実装（Spec 6）

## Upstream / Downstream

- **Upstream**: なし（v2 の傘 spec、依存先なし）
- **Downstream**: Spec 1-7 全て（用語・原則・アーキテクチャを参照）

## Existing Spec Touchpoints

- **Extends**: なし（新規）
- **Adjacent**: v1 の `project-foundation`（v1-archive、参考のみ、v2 では新名称・新構成）

## Constraints

> v2 全体の Constraints（フルスクラッチ / LLM 非依存 / Python 3.10+ + networkx ≥ 3.0 / Git 必須 / エディタ非依存 / L2 append-only JSONL / `.rwiki/.hygiene.lock` concurrency / Reject 理由必須）は roadmap.md L22- が SSoT。本 brief には Spec 0 固有の規範レベル制約のみ列挙する。

- v1 を「知らない前提」で自己完結的に設計（§9.1 フルスクラッチ方針）— 本 spec は v2 規範文書を生成し、v1 spec / 実装を参照しない
- 13 中核原則は層別適用が前提（全層一律ではない）— L1/L2/L3 で人間と LLM の関与モデルが異なる
- §2.12 Evidence-backed Candidate Graph は L2 専用、§2.2 / §2.4 より優先
- §2.10 Evidence chain（縦軸）と §2.13 Curation Provenance（横軸）は直交関係として規範化

## Coordination

### Foundation 規範文書 spec の testability スコープ

- 本 spec は規範文書を生成する spec であり、全 14 Requirement の subject は `the Foundation`、述語は「shall ～を記述する／含める／明示する」に統一されている
- 結果として **要件レベルで testable なのは「文書内に該当項目が存在するか」までに限定される**。「項目の内容が規範として正しいか」は人間レビュー（spec.json approval gate）に委ねる
- design phase で過剰な機械検証手段（内容妥当性 verifier 等）を構築しない方針。検証範囲は次の 4 種に限定:
  - 章節アンカーの存在チェック（目次との対応）
  - SSoT 出典 (`.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12) の章番号整合
  - 用語集語彙の Spec 1-7 からの引用 link 切れ検出
  - frontmatter / マトリクス枠組みの schema 妥当性
- 上記限定は I-6 の design 持ち越し対応の **設計上限** として固定する

### Foundation 自身の curation provenance 構造

- §2.13 Curation Provenance は L2 / L3 操作の curation 決定を `decision_log.jsonl` で保全する規範
- 一方 **Foundation 自身の curation 決定**（13 原則の選択 / 用語集 5 分類の境界 / §2.13 後付けの判断 etc.）は次の 3 媒体で記録される:
  - `docs/Rwiki-V2-dev-log.md` — 議論ログ
  - `docs/キュレートプロセス可視化.md` 等 — 個別議論の保全
  - `roadmap.md` Coordination 必要事項 — 起票中決定事項
- この **構造的非対称性**（規範 spec の curation は decision_log の対象外）は **意識的に肯定**する
  - 理由: decision_log.jsonl は「Vault 内 L2/L3 操作」の運用専用、Foundation 改版は「meta レベルの SDLC 決定」で異なる layer
  - Foundation 改版時の Adjacent Spec Synchronization は `roadmap.md` Governance に従い、`spec.json.updated_at` + 各 markdown 末尾 `_change log` で追跡

### 3 層対称性の意図的限定

- Foundation の規範密度は L2 Graph Ledger に偏る（core schema 6 ファイル / event types / reject 必須フィールド等）
- L1 raw / L3 wiki の subdirectory 規約（`raw/incoming/` `raw/llm_logs/` / `wiki/concepts/` `wiki/methods/` 等）は **Foundation の規範対象外**
- これらは Spec 1（frontmatter / category vocabulary）と steering `structure.md`（Vault layout）が SSoT
- 3 層対称性は **「層モデルとしての対称性」**（L1/L2/L3 の役割・更新頻度・人間関与の対称的定義）で完結し、内部構造規範の対称性は要求しない

### v1 から継承される技術決定の SSoT

- v1 から継承される実装レベル技術決定（**Severity 4 水準** / **Exit code 0/1/2 分離** / **LLM CLI subprocess timeout 必須** / **モジュール責務分割** / **CLI 命名統一**）は roadmap.md L132- が SSoT
- Foundation（規範文書）はビジョン・原則・用語に専念し、これら実装レベル決定は規範対象外
- 「v1 を知らない前提」（Constraints）は **規範文書としての自己完結性** を指し、roadmap.md レベルの実装決定継承と矛盾しない（分離された責務）

### Design phase 持ち越し

- **I-6: Foundation の subject = `the Foundation` を testable にする方法**
  - 本 spec は規範文書を生成する spec であり、全 14 Requirement の subject は `the Foundation` に統一されている
  - CLI 系 spec のように runtime 挙動で acceptance criteria を検証することができないため、検証手段を design phase で確定する必要がある
  - 候補: 章節アンカーの machine-readable 化 / 文書 lint スクリプト / SSoT 出典との章番号整合 verifier / Spec 1-7 からの「引用 link 切れ」検出
  - 関連: R14.3「章立て番号を SSoT と整合させる」が一部根拠になる
