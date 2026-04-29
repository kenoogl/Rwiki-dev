# Requirements Document

## Project Description (Input)

dual-reviewer の主機能 = 設計 phase の 10 ラウンド review を adversarial subagent 構成で実行 + Chappy P0 機能 (`fatal_patterns.yaml` 強制照合 / forced divergence prompt / `impact_score`) 組込 + JSONL 構造化記録 (`impact_score` 3 軸 + B-1.0 拡張 schema 3 要素)。`dual-reviewer-foundation` の Layer 1 を活用しつつ Layer 2 design extension を実装し、Spec 6 dogfeeding で運用可能なレベルの prototype を構築する必要。

ドラフト v0.2 (`.kiro/drafts/dual-reviewer-draft.md`) §2.1 で Layer 2 design extension 仕様確定 (10 ラウンド + Phase 1 escalate 3 メタパターン)、§2.6 で Chappy P0 3 件採用確定、§2.7 で Quota 設計確定、§2.10.3 で B-1.0 拡張 schema 3 要素確定。`dual-reviewer-foundation` spec で共通 schema + Layer 1 framework + seed/fatal patterns yaml 整備予定、`dr-design` / `dr-log` skill は未実装。

本 spec は dual-reviewer の主 review 機能 = `dr-design` skill (10 ラウンド orchestration + adversarial subagent dispatch + Chappy P0 全機能) + `dr-log` skill (JSONL 構造化記録 + impact_score 3 軸 + B-1.0 拡張 schema) + Layer 2 design extension を実装し、Spec 6 dogfeeding (`dual-reviewer-dogfeeding` spec) に適用可能なレベル (sample 1 round 通過確認まで) で動作させる。Phase A scope = Rwiki repo 内 prototype 段階、subagent 構成 = 単純 dual のみ (Opus + Sonnet)。詳細は brief.md (`.kiro/specs/dual-reviewer-design-review/brief.md`) 参照。

## Requirements
<!-- Will be generated in /kiro-spec-requirements phase -->
