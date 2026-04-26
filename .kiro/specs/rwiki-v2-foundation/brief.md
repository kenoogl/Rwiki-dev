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
- 用語の不統一を防ぐ（Edge status 6 種 vs Page status 4 種の混同等）

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

## Upstream / Downstream

- **Upstream**: なし（v2 の傘 spec、依存先なし）
- **Downstream**: Spec 1-7 全て（用語・原則・アーキテクチャを参照）

## Existing Spec Touchpoints

- **Extends**: なし（新規）
- **Adjacent**: v1 の `project-foundation`（v1-archive、参考のみ、v2 では新名称・新構成）

## Constraints

- v1 を「知らない前提」で自己完結的に設計（§9.1 フルスクラッチ方針）
- Python 3.10+、Git 必須、LLM CLI 非依存
- 13 中核原則は層別適用が前提（全層一律ではない）
- §2.12 Evidence-backed Candidate Graph は L2 専用、§2.2 / §2.4 より優先
