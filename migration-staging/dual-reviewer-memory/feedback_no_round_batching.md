---
name: ラウンド一括処理禁止 (skip 防止策、例外条件追加)
description: 設計レビュー / 仕様レビューで「第 N-M ラウンドを一括実施」「結果報告」などの batching を禁止。各ラウンドは独立 turn で Step 1-4 個別実施、Step 2 ユーザー判断機会を必ず確保する。**例外**: per-session 多 round dispatch (= 1 session 内で N round 順次完走 + 各 round で Step D user 判断機会維持) は batching ではない、fixed cost 償却目的の効率化として許容
type: feedback
originSessionId: d8fd6618-0784-4212-9ecc-ebbb641383e3
---
レビューラウンド (設計 12 ラウンド / 仕様 5 ラウンド) は **必ず 1 ラウンド = 1 turn 以上で個別実施** する。「一括して実施」「ラウンド N-M を集約」「結果報告」型の batching 処理は禁止。

**Why:** Spec 0 / Spec 1 の design review で、ラウンド 4-12 を「一括実施結果」として 1 turn で集約処理した実態あり。Step 1 (要点提示) のみで Step 2 (ユーザー判断) / Step 3 (詳細抽出) / Step 4 (深掘り) が省略され、9 ラウンド分のユーザー判断機会が失われた。「検出なし」「該当なし」判定が連続して、本来検出されるべき問題 (実装 spec のアルゴリズム選定根拠 / 性能達成手段 / 失敗 handler の具体化など) が素通りした。memory feedback_design_review.md「全ラウンドを基本実施、省略しない」「Step 1-4 必須手順」の規定が実態として skip と等価になった。

**How to apply:**

各ラウンドで明示的に:

- **1 ラウンド = 最低 1 turn 以上**: 1 turn 内で複数ラウンドを処理しない。Step 1 提示 → ユーザー応答 → Step 3-4 → 次ラウンド Step 1 という形で turn 境界を必ず作る
- **Step 2 ユーザー判断を省略しない**: 「全 N Req を順に詳細確認」「該当なし確認」など 2-3 択でユーザー判断を取る。判断機会なしで Step 3 に進まない
- **「該当なし」判定も明示的に提示してユーザー承認を取る**: ラウンド N で「該当なし」と判断した場合、それを Step 1 として提示し、Step 2 で「該当なしで次ラウンドに進む / もう少し深掘りする」のユーザー判断を取る
- **batching 表現は禁止**: 「ラウンド N-M を一括して実施します」「9 ラウンド分まとめて結果報告」「以下 9 ラウンドの集約結果」など、複数ラウンドを 1 turn で済ませる宣言は使わない

容認される効率化:

- **1 ラウンド内の Step 3-4 は同 turn で連続実施可能** (Step 2 でユーザー判断を取った後、自動採択が並ぶ場合は同 turn で適用 OK)
- **「軽微検出 0 件」のラウンドでも Step 1 で観点に対応する設計記述を提示し、Step 2 でユーザー確認を取る** ことで turn を分ける (大幅な短縮にはなるが skip にはならない)
- **per-session 多 round dispatch (追加)**: 1 session 内で N round (例: 2-3 round) 順次完走、**各 round で Step D user 判断機会を必ず維持** することで batching と区別。fixed cost (= 状態確認 / memory 読込 / TODO update / push、約 25-30 分/session) を多 round に償却で per-round 12-16% 効率化 + total session 数削減目的。 = 4-5 session 完走想定 (= -)。**判定基準**: 「N round の検出 + 修正を 1 turn で集約報告」 = 違反、「N round を順次 (= round N → Step D user 判断 → round N+1 → Step D user 判断 ...) に処理」 = 容認

skip 検出の自己チェック (各ラウンド完了時):

- 「このラウンドで Step 2 ユーザー判断を取ったか？」 → No なら skip
- 「このラウンドの user turn を経て次ラウンドに進んだか？」 → No なら batching
- 「次のラウンドの Step 1 を同 turn 内で提示していないか？」 → Yes なら batching

関連 memory:

- feedback_design_review.md — 設計レビュー 12 ラウンド構成 / 全観点基本実施
- feedback_review_rounds.md — 仕様レビュー 5 ラウンド構成
- feedback_approval_required.md — visible action / ユーザー判断 gate
- feedback_choice_presentation.md — 選択肢提示の方法 (Step 2 で活用)
