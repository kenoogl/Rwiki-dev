---
name: 設計決定の記録方式 (ADR 代替)
description: 設計レビュー中に発生する重要決定の記録方法。ADR 独立ファイルは過去に機能しなかったため採用せず、design.md 本文「設計決定事項」セクション + change log に二重記録する。
type: feedback
originSessionId: 72c721dd-8831-4f92-8ac1-4797c74aaff4
---
設計レビュー中に重要な技術選定 / 数値選定 / アーキテクチャ決定が発生する。これらを孤立させずに保全し、後の参照 / 監査で機能する形で記録する。

**Why:** ADR (Architectural Decision Record) を別 directory で独立ファイル化する方式は過去に機能しなかった (LLM が ADR の存在を忘れる、design.md / requirements.md から参照されず孤立)。ADR ファイルは作成された後、design 変更時にも updated されず、決定の保全媒体として機能しなかった。

**How to apply:**

採用する記録方式: **「design.md 本文 + change log」の二重記録**

- **design.md 本文に「設計決定事項」セクションを設ける**:
- 当該 spec の design.md 内に独立セクション (例: §X 設計決定事項) を作成
- drafts v0.7.10 決定 5-1 / 5-2 / 5-3 / 6-1 / 6-2 / 6-3 と同形式 (決定 ID / 内容 / Why / 採択理由 / 却下案)
- design.md 本文と一体管理されるため、design 変更時にも目に入って更新される (孤立しない)

- **change log にも 1 行サマリで追記**:
- 既存の requirements / design change log 運用ルールに乗せる
- 「2026-MM-DD: 設計決定 D-N  簡潔サマリ」形式
- 履歴 + 検索性確保

- **独立 `decisions/` directory は作らない** (ADR の孤立リスクの再発防止)

記録対象 (基準):

- trade-off が明確で複数案から 1 つを選んだ決定 (例: SQLite ORM の選択 / file lock 実装 / glob 実装の library)
- 設計時に確定した数値 / 閾値 / interval 等で **仕様 AC では明示されていない** もの (例: SQLite cache invalidation 間隔)
- prototype 検証で実測した性能数値とその達成手段 (実測値 + 達成 strategy)
- 仕様 AC として読める範囲で設計内吸収した解釈 (feedback_design_spec_roundtrip.md 整合)

記録しない (低価値):

- 仕様 AC で明示済みの事項 (重複記述になる)
- design.md の自然な記述で十分理解可能な事項 (決定として独立 documentation するほどでない)
- 一時的 workaround で後に再検討予定の事項 (代わりに TODO コメント / change log で残す)

設計決定事項セクションのテンプレート (drafts 形式):

```markdown
## §X 設計決定事項

### 決定 X-1: <決定タイトル>

 **決定日**: 2026-MM-DD
 **決定**: <採択した内容>
 **Why (motivation)**: <設計時の制約 / 課題>
 **採択理由**: <なぜこの案を選んだか>
 **却下案**:
 案 A: <内容> → <却下理由>
 案 B: <内容> → <却下理由>
 **影響範囲**: <他 spec / コンポーネントへの波及>
 **prototype / 検証**: <検証結果があれば>
```

ユーザー対話との関係:

- 重要決定はユーザー対話で確認 (feedback_approval_required.md / feedback_choice_presentation.md 整合)
- 対話で確定した内容を design.md 本文 + change log に記録
- 対話履歴自体は dev-log で保全 (既存運用)

関連 memory:

- feedback_design_review.md — 設計レビューの観点
- feedback_design_spec_roundtrip.md — 仕様⇄設計往復判断軸
- feedback_choice_presentation.md — 選択肢提示の方法 (設計時の trade-off 選択肢でも適用)
- feedback_approval_required.md — 重要決定のユーザー承認必須
