---
name: reactive 書き直しモデル (= self-rewrite abandon 後の運用)
description: user 説明応答は通常応答で出す、user が「分かりにくい」等指摘したら finding 4 要素テンプレで書き直す。draft / final 併記なし、user simulate なし。
type: feedback
originSessionId: 1283956e-4c99-432f-93a6-d028407b7c75
---
self-rewrite section (= global CLAUDE.md 旧記述、2026-05-05 新設) は **abandon** (= 同日 で判定、削除済)。代わりに以下の reactive 書き直しモデルを運用:

1. **通常応答を出す** = draft / final 併記なし、user simulate (internal step) なし
2. **user が「分かりにくい」「説明不足」「もう一度」「平易に」等を指摘** したら、finding 4 要素テンプレ (= `feedback_finding_4elements.md`) を参考に書き直し
3. **連続 NG (= 3 回以上)** の場合は別案検討 (= 1 turn 1 escalate / approach pivot)

**Why**: 2026-05-05 で self-rewrite を運用したが、critique 段階の中身を保証する仕組みがなく形式 procedure に陥り、何度補強 (= user simulate / 4 要素 / 1 turn 1 escalate) しても「分かりにくい」が再発。critique の depth 保証は user feedback signal でしか実現できないため、self-rewrite の前置 procedure を全て止め、reactive 書き直しに一本化する方が cost / 効果のバランスが良い (= user 提案、私側分析でも同意)。

**How to apply**:
- user 説明応答 (= 推奨提示 / 判断材料提示 / 完了報告) で **draft / final 併記しない**
- user 指摘あれば即書き直し、書き直し時は finding 4 要素 (= 箇所 / 現状 / 問題 / 修正後) を必須参考
- 既存 memory「1 検出 1 turn 分割」(= `feedback_explanation_with_context.md`) は別軸で維持、長大応答は分割

**関連処理**:
- `feedback_finding_4elements.md` = 書き直し時参考
