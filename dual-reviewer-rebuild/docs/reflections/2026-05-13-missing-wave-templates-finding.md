# Missing wave templates finding (2026-05-13)

_作成: 2026-05-13_
_status: reflection v0.1_
_purpose: requirements / design / tasks の各 review wave に必要なテンプレートが揃っていなかったことを発見として記録する_

---

## 1. 発見の概要

dual-reviewer methodology の review wave 手順を実施するにあたり、各 phase（requirements / design / tasks）の feature-local review、review wave、alignment gate に対応するテンプレートが `dual-reviewer-rebuild/docs/reviews/templates/` 配下に揃っていなかったことが判明した。

既存テンプレートは intent / implementation / review acquisition の 3 phase 向けのみで、requirements / design / tasks の 3 phase × 3 artifact 種別 = 9 テンプレートが不足していた。

## 2. 発見の経緯

2026-05-13 のセッションで、Codex（LLM 支援者）が v2-acquisition spec の requirements wave を起草するためにテンプレートを探した。テンプレートディレクトリには intent / implementation / review acquisition 用のテンプレートはあったが、requirements / design / tasks 用は欠落していた。

ユーザは次の指摘をした。

> 本システムをデプロイして使用する場合にも同じ問題が発生する。それぞれ、ひな形があるべき。

つまり、本プロジェクトの v2-acquisition だけの問題ではなく、方法論をデプロイしたときに新規ユーザが同じ困難に直面する構造的問題だ、という指摘である。

## 3. 構造的問題分析

- review wave 手順は `HUMAN_WORKFLOW.md` で正本化されているが、その手順を実行するためのテンプレートが揃っていなかった。
- 既存ユーザ（このプロジェクトの開発者）は `intent-review-template.md` を流用するなど暗黙の慣行で運用していた可能性があるが、それを明示するテンプレートはない。
- 結果として、各ユーザは毎回独自に形式を考えなければならず、形式の不整合が生じやすい。
- これは [2026-05-13-workflow-graspability-finding.md](2026-05-13-workflow-graspability-finding.md) と同類の問題で、方法論の文書整備が不完全であることを示す。

## 4. dogfooding 上の意味

dual-reviewer は意図駆動開発を支援する方法論として銘打っているが、

- 方法論自身の review wave 手順を実行する文書が揃っていない、
- 結果として LLM 支援者は intent-review-template を勘で流用する、

という状況は、方法論の信頼性と再現性に直接影響する。同じ問題が他のユーザ環境で再発する。

## 5. 対応と今後の参照先

本 finding は次の対応で部分的に緩和した。

- `dual-reviewer-rebuild/docs/reviews/templates/` 配下に 9 テンプレートを追加：
  - `requirements-local-review-template.md`
  - `requirements-review-wave-template.md`
  - `requirements-alignment-template.md`
  - `design-local-review-template.md`
  - `design-review-wave-template.md`
  - `design-alignment-template.md`
  - `tasks-local-review-template.md`
  - `tasks-review-wave-template.md`
  - `tasks-alignment-template.md`

各テンプレートは `intent-review-template.md` と `phase-evidence-summary-template.md` の構造を踏襲しつつ、phase 固有の review focus と alignment area を明示する。

今後、テンプレートの不足が判明した場合は、本 finding を参照しつつ追加対応する。
