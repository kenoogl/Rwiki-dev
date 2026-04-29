# Requirements Document

## Project Description (Input)

dual-reviewer (LLM 設計レビュー方法論 v3 一般化 package) を Layer 1/2/3 三層構造で組み立てるには、phase 横断の framework + project bootstrap + 共通 JSON schema + initial seed (23 事例 + fatal patterns) が揃っている必要がある。これらが先行整備されないと、`dr-design` / `dr-log` skill が単独で機能できず、Phase A-2 (Spec 6 dogfeeding) も実行不可。

ドラフト v0.2 (`.kiro/drafts/dual-reviewer-draft.md`) §2.1 で Layer 1 framework 骨組み確定、§2.9 で 23 事例 retrofit 仕様確定 (`seed_patterns.yaml`、Rwiki 由来)、§2.6 で Chappy P0 採用 3 件確定 (うち `fatal_patterns.yaml` 8 種固定)、§2.10.3 で B-1.0 拡張 schema 3 要素 (`miss_type` / `difference_type` / `trigger_state`) 確定。実装は未着手。

本 spec は dual-reviewer の core 基盤 (Layer 1 framework + `dr-init` skill + 共通 JSON schema + `seed_patterns.yaml` + `fatal_patterns.yaml`) を稼働可能にし、`dual-reviewer-design-review` / `dual-reviewer-dogfeeding` が依存する全要素を提供する。Phase A scope = Rwiki repo 内 prototype 段階、B-1.0 minimum 3 skills のうち `dr-init` 部分を担当。詳細は brief.md (`.kiro/specs/dual-reviewer-foundation/brief.md`) 参照。

## Requirements
<!-- Will be generated in /kiro-spec-requirements phase -->
