---
name: wave 手順遵守規律
description: requirements wave 内の作業進行で誤った確認・修正提案を挟まないための規律
type: feedback
originSessionId: 46dad2ac-2292-40ba-b36b-b7e8a3a42f99
---
wave に入る前に必ずワークフロー文書（WORKFLOW_OVERVIEW.md）を読み、全ステップを一覧化してから着手する。

**Why:** feature-local review で must-fix が出た後、正しい次の行動を取らずに別の機能のレビューに進もうとした。また「次のステップは must-fix を直すこと」と自分で明言した直後に、ユーザーの短い返答（「承認」）に反応して別の行動に移った（言行不一致）。

**How to apply:**
- feature-local review で must-fix が出た場合、その機能の requirements.md を修正してから次の機能に進む（reopen 10 ステップに従う）
- 自分が「次にやること」と述べた内容は拘束条件として扱い、行動前に必ず直前の発言を確認する
- ユーザーの短い返答（「承認」「了解」など）を受けたときは、何が承認されたかを確認してから次の行動に移る
- 「承認が必要か」の判断は spec.json 承認 / コミット / プッシュ / フェーズ移行に限定する
