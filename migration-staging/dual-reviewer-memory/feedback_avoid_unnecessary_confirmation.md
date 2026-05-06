---
name: 不要な確認質問を避ける
description: 戦略 / 方針が user 承認済の場合、commit message や実行詳細など派生する routine 判断は user に再確認せず自分の判断で実行する
type: feedback
originSessionId: fa52a8e3-2afa-479b-8095-c636cebe5123
---
戦略 / 方針 / 主要選択肢が user 承認済の場合、それに付随する commit message 文面、実行順序、技術的詳細などの派生 routine 判断は user に再度確認しない。自分の判断で実行する。

**Why**: で main merge 実行時、case A 採用 + Combo X (V4 reset + V3 file 削除) + (e) 案 3 + (3-a) draft.md 採用が全て user 承認済の状態で、私が「(a) Phase 1 commit message OK? (b) Phase 2 commit message OK? (c) catalog structure OK? (d) plan で実行 OK?」と 4 段階確認したところ、user が「本来やらなくてよい判断をする負荷が高くいやだ」と明示的に拒否反応。決定済 plan の派生 routine 判断は cognitive load を増やすだけで価値がない。

**How to apply**:
- 戦略 / 方針 / 選択肢が approve 済 → 派生する commit message, 実行順序, 文言調整は **自分で判断して実行**
- 例外 (= user 承認必須): memory `feedback_approval_required.md` の visible action (spec.json approve / push / phase 移行 / 大規模削除 / 不可逆操作)
- 確認すべき場面の判別:
- **要確認**: 戦略選択肢が複数あって user 価値判断が必要、不可逆操作、新規未議論の論点が浮上
- **不要確認**: 既決定 plan の commit message 案、実行順序の細部、文言の trivial 調整、verbose な status 報告
- 実行報告は「短く事実のみ」: 「Phase X 完了 (commit YYY)」+ 必要なら次 action 提示。「OK ですか?」確認は付加しない
- 軽率さとの区別: 決定済 plan の routine 判断は dispatch の問題で軽率さではない。新たに発覚した複雑論点 (例: spec.json design-generated 不整合) は別途 escalate
