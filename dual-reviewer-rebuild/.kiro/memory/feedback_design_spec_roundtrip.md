---
name: 仕様⇄設計の往復改版判断軸
description: 設計レビュー中に「仕様 X が実現困難 / 制約緩和必要 / 追加 AC 必要」が判明したとき、仕様改版が必要か設計内吸収可能かの判断基準。仕様 AC として読めるかどうか + ユーザー対話必須。
type: feedback
originSessionId: 72c721dd-8831-4f92-8ac1-4797c74aaff4
---
設計レビュー中に「現状仕様 (requirements) が設計上の制約と衝突する」「設計の具体化で仕様に書かれていない事項が必要」が判明する場合がある。このとき、仕様改版 (requirements 改版 + 再 approve) が必要か、設計内吸収 (仕様の文言は変えず設計で対処) が可能かを判断する基準を定める。

**Why:** 仕様改版は再 approve 経路を伴うため重い手続き。一方、設計内吸収で済ませると仕様と設計の乖離が生じ、後の保守時に「設計はなぜこうなっているのか requirements を見ても分からない」状態を招く。判断軸を明確化し、適切な改版コストを払う。

**How to apply:**

判断基準: **「現状の設計案を仕様の AC 文言として読み戻したとき、既存 AC として読めるかどうか」**

- 既存 AC の範囲内に読める (= 既存 AC の自然な実装具体化に過ぎない) → **設計内吸収**
- 既存 AC と矛盾する / 既存 AC が許容しない動作になる → **仕様改版必須**
- 既存 AC では言及されていない新事項 (=AC を追加すれば書ける) → **仕様改版検討** (ユーザー対話で確定)

ユーザー対話: **必須**

- 設計内吸収 / 仕様改版いずれを選ぶかは Claude 単独では判断しない
- ユーザーに「現状設計案 + 既存 AC + 判断軸 (AC として読めるか)」を提示し、対話で確定
- 仕様改版が必要なら、改版範囲 (どの spec のどの R に何を追加 / 修正するか) も対話で確定

仕様改版が確定した場合の手順:

1. 当該 spec の requirements.md を改版 (深掘り検討 + 自動採択 + escalate 方針継承、feedback_deepdive_autoadopt.md)
2. 必要に応じて他 spec への波及精査 (feedback_review_rounds.md 第 5 ラウンドの 5 step 必須手順を継承、Adjacent Sync TODO 整理)
3. spec.json approve 状態は **再 approval 必要** (Adjacent Spec Synchronization 運用ルール = 再 approval 不要、と区別。本 spec の AC が変わるため)
4. ユーザー明示承認 (feedback_approval_required.md) を得て、approve 状態を維持 / 更新

設計内吸収が確定した場合の手順:

1. design.md 内に「設計決定事項」として記録 (feedback_design_decisions_record.md)
2. requirements.md は改版しない (本文も change log も変更なし)
3. 仕様 AC との整合性は design.md 本文で明示参照 (例: 「本設計は requirements R3.5 の自然な実装具体化として、X を Y で実現する」)

判断のグレーゾーン:

- 「既存 AC として読めるが、AC の表現が曖昧で読み方が複数あり得る」 → ユーザー対話で確定。多くの場合は **AC を明確化する仕様改版** が望ましい (将来の解釈ずれ回避)
- 「設計内吸収できるが、ユーザーが requirements にも書きたい」 → ユーザー意向尊重で仕様改版
- 「複数 spec の AC が交差する箇所での解釈ずれ」 → 該当する全 spec の design でクロス参照、必要なら全 spec を仕様改版 + Adjacent Sync

関連 memory:

- feedback_design_review.md — 設計レビューの観点
- feedback_design_decisions_record.md — 設計決定の記録方式
- feedback_approval_required.md — 仕様改版時の再 approve 必須
- feedback_review_rounds.md — 仕様改版時の波及精査手順
