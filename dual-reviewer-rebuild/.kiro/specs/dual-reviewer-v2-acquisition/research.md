# Research

## v1 汚染メカニズムの調査

v1 取得処理が偽の規則性（単独 2 件・二重 3 件・二重+判断 3 件）を生んでいた原因として、5 層の事前設定が特定されている。

- 各役割のプロンプト（`dual-reviewer-rebuild/runtime/prompts/`）に具体トピックが書き込まれていた。
- ヒューリスティック規則ファイル（`experiments/protocols/heuristic_profiles/` 配下、現在は archive 配下）の方針が件数を固定。
- 各ケースの規則ファイルが共通の三つ組語彙を持っていた。
- Ruby ランタイム層（`dual-reviewer-rebuild/runtime/executors/`）が規則ファイルを決定論的に照合。
- 論文計画書（archive 配下）に観測結果が先取りで書かれていた。

詳細は `.kiro/methodology/dual-reviewer-spec-driven-paper/_archived-evidence-2026-05-13/` 配下の archive を参照。

## v2 設計の原則

設計の正本は次を参照する。

- [v2-acquisition-design.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/v2-acquisition-design.md)（draft v1.0、原則決定）。

## 自前 cc-sdd 同等機能の調査

dual-reviewer-rebuild は cc-sdd 同等の機能を自前で実装している。

- spec phase ガード：`dual-reviewer-rebuild/scripts/check_spec_phase_entry.rb` と `dual-reviewer-rebuild/scripts/track_runs/spec_phase_guard.rb`。
- テスト fixture：`dual-reviewer-rebuild/tests/fixtures/cc_sdd_phase_guard/`。
- 共通規約：`dual-reviewer-rebuild/CONVENTIONS.md`（spec.json を正本とする、phase 用語の使い分け）。

## 上流入力

- プロジェクト全体の意図：`dual-reviewer-rebuild/intent/INTENT.md`、`DESIGN_PRINCIPLES.md`、`NON_GOALS.md`、`TRACEABILITY.md`。
- 運用と人間との分担：`dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md`、`DEPLOYMENT_MODEL.md`、`TRUST_BOUNDARY.md`、`DATA_INVALIDATION_POLICY.md`。
