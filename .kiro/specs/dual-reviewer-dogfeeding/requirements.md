# Requirements Document

## Project Description (Input)

dual-reviewer prototype の有効性検証 + Phase B fork go/hold 判断 + 論文用 quantitative evidence (figure 1-3 用) 取得が必要。Spec 6 (`rwiki-v2-perspective-generation`) design phase が dogfeeding 場として最適 (dual-reviewer Phase A 期間中ペンディング維持、A-2 で再開 = Spec 6 design approve 同時に Phase A 終端)。対照実験 (single = Opus のみ vs dual = Opus + Sonnet) で adversarial 構造の効果を定量化する必要。

ドラフト v0.2 (`.kiro/drafts/dual-reviewer-draft.md`) §3.1 A-2 + §3.5 で対照実験設計確定 (全 Round で single + dual の両方完走、cost 倍)、§2.10.3 で論文 figure 候補確定 (figure 1-3 = quantitative)、Phase B fork timing 判断基準確定 (致命級 ≥ 2 件 / disagreement ≥ 3 件 / bias 共有反証 evidence 確実 / `impact_score` 分布が minor のみではない)。dual-reviewer prototype は `dual-reviewer-foundation` + `dual-reviewer-design-review` の 2 spec で構築予定 (本 spec の依存元)。

本 spec は dual-reviewer prototype を Spec 6 design に適用、Round 1-10 を single (Opus のみ) + dual の両系統で完走 (cost 倍)、JSONL log 取得 → 比較 metric 抽出 + 論文 figure 1-3 用データ整理 + Phase B fork go/hold 判断 + Spec 6 design approve 同時達成を実現する。終端 = A-2 終端 = Phase A 終端 = 即 Phase B-1.0 release prep (元 A-3 統合) に移行。詳細は brief.md (`.kiro/specs/dual-reviewer-dogfeeding/brief.md`) 参照。

## Requirements
<!-- Will be generated in /kiro-spec-requirements phase -->
