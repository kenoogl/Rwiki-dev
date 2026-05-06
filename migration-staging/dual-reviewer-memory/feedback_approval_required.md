---
name: 承認なしで進めない (visible action)
description: spec.json approve / commit / push / phase 移行など visible action はユーザー明示承認必須
type: feedback
---

## 規律

ユーザー明示承認なしに以下の visible action を実行禁止:

- `.kiro/specs/*/spec.json` の `approvals.{requirements,design,tasks}.approved` 変更
- `.kiro/specs/*/spec.json` の `phase` 値変更
- git commit (特に `docs(specs):` / `docs(dev-log):` 系)
- git push
- フェーズ移行 (requirements → design → tasks → implementation) に伴う一括処理

## why

2026-04-26 Spec 4 review で「致命+重要級反映 + γで順次進める」指示を「順次=自動進行可」と過剰解釈 → 修正計画提示 → Edit 適用 → spec.json approve → TODO 更新 → コミット提案を一気に実行 → user「走り過ぎ。私のレビューが入っていないので、approve 取り消し」。Kiro 3-phase 人間承認 gate (requirements → design → tasks) が中核ルール、approve は SSoT に直接影響する visible action でユーザー判断のみが正規。

## 修正適用と approve は別工程

- 修正内容 (Edit) は連続適用 OK
- ただし修正適用後は必ず「approve してよいか?」明示確認してから spec.json 更新
- 「順次進める」「自動で」等の指示も approve / commit / push 等の visible action までは含まないと解釈

## Adjacent Sync 例外

既 approve 済 spec を文言同期する場合、`spec.json.updated_at` 更新 + markdown 末尾 `_change log_` 1 行追記は再 approval 不要。ただし `approved` flag は true 維持、`phase` は変更しない。commit / push は別途明示承認必須。
