# Workflow documentation graspability finding (2026-05-13)

_作成: 2026-05-13_
_status: reflection v0.1_
_purpose: 方法論自身の文書が一見して把握しづらいことを発見として記録する_

---

## 1. 発見の概要

dual-reviewer methodology の正本文書は完備されているが、一見して全体像を把握しづらく、LLM 支援者と人間の両方が誤動作する余地があることが判明した。

## 2. 発見の経緯

2026-05-13 のセッションで、Codex（LLM 支援者）が review wave と reopen 手続きの動作をユーザに説明する際、canonical な文書（`operations/HUMAN_WORKFLOW.md`、`docs/coordination/workflow-repair-procedure.md`）を読まずに不正確な説明を行った。ユーザの指摘で気づき、canonical 文書を完読して訂正した。

その後ユーザは「重要なところは合っていそうだが、一見して把握できないことの方が問題。正しい動作が保証できない」と指摘した。

## 3. 構造的な問題分析

主な要因：

- 関連情報が複数の正本文書に分散している。
  - wave 定義は `HUMAN_WORKFLOW.md`。
  - reopen / handback class は `workflow-repair-procedure.md`。
  - gate 状態語彙は `workflow-gate-status.md`。
  - 状態正本の所在は `CONVENTIONS.md`。
- 単一の at-a-glance 概観文書がない。
- 長い文書を読み切らないと相互関係が組み立てられない。
- 視覚的な概観（flowchart、状態遷移図など）がない。
- 暗黙の関係が複数文書をまたぐ。

## 4. dogfooding 上の意味

dual-reviewer は意図駆動開発の複雑性増大を支援する道具と銘打っている（[INTENT.md](../../intent/INTENT.md) 第 4.6 節）。にもかかわらず、方法論自身の文書が一見して把握できないのは次の問題を示す。

- 方法論の信頼性問題：自分自身の複雑性増大を支えきれていない。
- LLM 支援運用上の品質問題：LLM が誤動作する余地が残る。
- 人間 maintainer の onboarding 障害：短時間で全体像を掴めない。

## 5. 対応と今後の参照先

本 finding は次の対応で部分的に緩和した。

- `operations/WORKFLOW_OVERVIEW.md` の作成：1 ページの at-a-glance 概観を新設。各項目から正本文書へリンク。

今後、方法論の品質改善が必要なときに本 finding を参照する。視覚的な概観（flowchart、状態遷移図）や文書統合の検討は、今後の課題として残す。
