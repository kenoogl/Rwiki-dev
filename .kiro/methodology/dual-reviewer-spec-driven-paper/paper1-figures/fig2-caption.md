# 図2 キャプション案（メモ）

_対象: `fig2-rework-graph.png`（オリジナル: `dual-reviewer-rebuild/docs/fig-rework.png`）_
_最終更新: 2026-05-20_
_状態: 本文執筆時に確定。本書は素材_
_注: 当初 Graphviz で描画していたが、自己ループと長距離手戻り矢印を `splines=ortho` モードでクリーンに分離できず、手描き版に切り替えた。Graphviz 版のソース（`fig2-rework-graph.dot` 等）は履歴として保持_

---

## キャプション案（日本語版・本文用）

> **図2**: 仕様駆動開発サイクルにおける手戻りの有向グラフ。箱はフェーズ（Intent＝意図、Requirements＝要件、Design＝設計、Tasks＝タスク、Implementation/Conformance＝実装と適合確認）。実線の黒矢印は順方向の処理の流れ（仕様サイクル）。**B**（青の弧）は実装→設計の差し戻し（6本＝基盤1・実行系4・統治候補1）。**Br**（Design の自己ループ）は差し戻し後の再設計で記録された所見（中 4・軽 6 件、基盤・実行系の2機能のみ）。**A**（Implementation/Conformance の自己ループ）は自己内吸収（実装内で完結した手戻り、6機能累計44本）。手戻り **C**（実装→要件）と **D**（実装→意図）は全6機能で該当ゼロのため描画を省略。**Leak**（漏れ）は前段の人間承認関門通過後に**Human Audit**（人間による事後監査・独立適合レビュー・補完レビュー・対話による点検）で初出捕捉された、承認時の正規レビューには記録されなかった仕様逸脱または関門省略の事例の集約点。点線の **L1** は漏れ→実装/適合（手製試験データ＝fixture 仮装による検証迂回が承認後に発覚、4機能：評価・自己改善・論文インターフェース・統治。実装層で実出力契約形に切り替えて対処）、点線の **L2** は漏れ→タスク（タスク 1〜10 を含む全体18件の節5違反＝10件超の依存グラフ別表が必須要件、補完レビューで初出論点化、統治機能。タスク層で依存グラフ別表を追記して対処）。出典: `evidence-extract-2026-05-20.md` §1〜§6。

---

## キャプション案（英語版・将来の国際投稿向け参考）

> **Fig. 2**: Directed rework graph across the spec-driven development cycle. Boxes are phases (Intent, Requirements, Design, Tasks, Implementation/Conformance). Solid black arrows denote the forward process flow. **B** (the blue arc) = design handback (Impl → Design; 6 edges aggregated across features). **Br** (Design self-loop) = post-handback redesign findings (4 medium + 6 minor across 2 features). **A** (Implementation/Conformance self-loop) = task-local absorption (rework absorbed within Impl; 44 instances aggregated across six features). Reworks **C** (Impl → Req) and **D** (Impl → Intent) are zero across all six features and are not drawn. The **Leak** node aggregates issues that passed the prior human-approval gate but were detected later by **Human Audit** (independent conformance review, supplemental review, or interactive inspection). Dashed **L1** = leak to Impl: fake-fixture–based verification bypass surfaced after task approval in four features (evaluation, self-improvement, paper-interface, governance); remediated at the implementation layer by switching fixtures to real-output contracts. Dashed **L2** = leak to Tasks: a Section-5 dependency-graph requirement was violated across the 18 tasks (including tasks 1–10) and surfaced by supplemental review (governance); remediated at the tasks layer by adding the dependency-graph supplement. Source: `evidence-extract-2026-05-20.md` §1–§6.

---

## ラベル対応表（簡易）

- **Intent / Requirements / Design / Tasks / Implementation/Conformance**：仕様サイクルの各フェーズ
- **黒矢印（実線）**：順方向の処理の流れ
- **A**：自己内吸収（実装の自己ループ、task-local 手戻り）。6機能累計 44本
- **B**：設計差し戻し（実装→設計、青弧）。6本＝基盤1・実行系4・統治候補1
- **Br**：差し戻し後の再設計（Design の自己ループ）。中 4・軽 6 件（基盤・実行系の2機能のみ）
- **C**：要件差し戻し（該当ゼロのため非描画）
- **D**：意図差し戻し（該当ゼロのため非描画）
- **Leak**：前段関門を通過した後に独立プロセスが初出捕捉した事例の集約点
- **Human Audit**：人間による事後監査（独立適合レビュー・補完レビュー・対話による点検）
- **L1**：漏れ→実装/適合（点線）。fixture 仮装による検証迂回（4機能）
- **L2**：漏れ→タスク（点線）。節5違反の補完レビュー初出（統治機能）

---

## 注意事項（本文執筆時に確認）

- 「fixture 仮装」の用語定義は本文 §2 で先に与える（骨子 §2 参照）
- 「漏れ」の操作的定義は本文 §3 で示す（骨子 §3 参照）
- 手戻り区分 A／B／C／D の定義は本文 §3 取り組みで示す（骨子 §3 参照）
- 「節5違反」とは、本リポジトリの REVIEW_PROTOCOL 節5「10件超は依存グラフ別表が必須」の違反を指す。本文では「タスク間依存グラフ別表の欠落」と平易に言い換える可能性
- 図中の数値ラベル（A=44、Br=10、B=6 など）は本文または本キャプションで明示。図中には書き込まない
