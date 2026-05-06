---
name: TODO 作成・更新時の SSoT 確認義務
description: TODO_NEXT_SESSION.md / 引き継ぎ文書を作成・更新する際は、前 TODO の記述を継承せず、SSoT 文書 (roadmap.md / steering / brief / requirements / design) と必ず照合する。前 TODO 鵜呑みは不整合伝播リスク
type: feedback
originSessionId: 46415c6c-3c5a-45f8-b612-a8974c027800
---
TODO_NEXT_SESSION.md / dev-log / 引き継ぎ文書を作成・更新する際は、**前 TODO の記述を信頼せず SSoT 文書 (roadmap.md / steering / brief / requirements / design) と必ず照合**する。前 TODO の記述を継承するだけでは、前 TODO に存在する不整合がそのまま伝播し、複数セッションを跨いで誤りが蓄積される構造的リスクがある。

**Why:** 2026-04-28 Spec 4 design approve やり直しセッションで、前セッション作成の TODO_NEXT_SESSION.md の Phase 順序記述 (Phase 3 = Spec 5 / Spec 2 並列、Phase 5 = Spec 6 + Spec 7) が steering の `roadmap.md` L43-72 (Phase 2 後半 = Spec 4 → Spec 7、Phase 3 = Spec 5 → Spec 2、Phase 5 = Spec 6) と不整合。Claude は前 TODO を継承して TODO_NEXT_SESSION.md を再記述、ユーザー指摘で発覚。**SSoT 確認なしに前文書を鵜呑みにする怠惰が原因**。

これは memory `feedback_review_judgment_patterns.md` の dev-log パターン「規範前提曖昧化」「文書記述 vs 実装不整合」の同型問題 = SSoT 文書と引き継ぎ文書の不整合が複数セッションで増幅される構造的リスク。

**How to apply:**

## TODO_NEXT_SESSION.md / 引き継ぎ文書 更新時の SSoT 照合手順

各 TODO 項目について、対応 SSoT 文書を最低 1 件 Read で確認:

- **Phase 順序 / 次セッション着手対象 / 依存順** → `roadmap.md` (`.kiro/steering/roadmap.md`)
- **Spec 関係性 / 依存グラフ / 並列実施可否** → `roadmap.md` の Phase 図 + 「順序理由」section
- **requirements 範囲 / AC 数 / change log** → 該当 spec の `requirements.md`
- **設計決定継承 / 申し送り** → 該当 spec の `design.md`「設計決定事項」 + 「Coordination 申し送り一覧」
- **brief 持ち越し** → 該当 spec の `brief.md`
- **Foundation 13 中核原則 / 用語集** → Spec 0 (``) `requirements.md` / `design.md`

## 前 TODO 鵜呑み禁止の確認規律

- TODO 更新時、前 TODO の Phase 順序 / 次セッション着手対象 / spec 依存記述をそのまま引用せず、**必ず roadmap.md を 1 度 Read して照合**
- 不整合発見時: 即時訂正 + 学習として「TODO の不整合源」を本 memory に追記、または別途記録
- 「前 TODO で X と書かれていたから X」と判断する場合も、必ず SSoT で X を再確認 (前 TODO の事実関係は時間経過で stale になりうる)

## 引き継ぎ文書全般への一般化

本規律は TODO_NEXT_SESSION.md だけでなく、以下の引き継ぎ文書全般に適用:

- **dev-log 追記**: spec 状態 / Phase 完了状況の記述で SSoT 照合
- **memory MEMORY.md index 更新**: memory ファイル間の依存関係記述で各 memory の現状を確認
- **session 完了報告 / 開始報告**: 次セッションの想定作業内容で roadmap / steering 確認

## 関連 memory

- `feedback_review_judgment_patterns.md`: dev-log パターン「規範前提曖昧化」「文書記述 vs 実装不整合」と同型 = SSoT との整合性 verify 義務
- `feedback_review_step_redesign.md` Step 1b-v 5 切り口の「(2) 関連文書間矛盾チェック (cross-document consistency)」: 設計レビュー時の SSoT 照合と同じ精神を引き継ぎ文書更新にも適用
