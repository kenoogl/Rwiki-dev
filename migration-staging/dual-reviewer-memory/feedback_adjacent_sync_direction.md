---
name: Adjacent Sync 方向性 + 不整合発見時の自己抑制
description: Adjacent Sync は先行 → 後続方向のみ。後続 spec 未生成段階で先行 spec を修正する誘惑に注意、不整合発見時の即解消提案 bias を Negative 視点で自己抑制
type: feedback
originSessionId: 9c8ae9df-fb52-46db-be70-6279b755b8ae
---
Adjacent Sync (roadmap.md L163-167) は「**先行 spec 変更による波及的な文言同期**」=「先行 → 後続」方向のみ適用可能。後続 spec の design / 仕様が **未生成段階** で先行 spec の不整合を発見しても、即解消せず「後続 spec design 生成時の Discovery input」として保留する。不整合発見時は「発見」(Discovery 段階) と「解消方針」(Synthesis 段階) を時系列で明確に分離する。

**Why**: 2026-04-29 Spec 3 design 着手前の事前確認で、Spec 4 design line 172 の 5 種コマンド拡張記述 (`rw distill / rw query * / rw audit semantic|strategic / rw retag`) に rationale 不在 (change log + grep 確認で 0 件) を発見した直後、「Adjacent Sync で line 172 を `rw distill` のみに限定」と即 user 承認を求めた。user 指摘 (「まだ design.md は生成されていないが？」) で 3 つの根本原因が顕在化:

- **(A) 状態認識の固定化失敗**: Spec 3 spec.json で `phase=requirements-approved、design 未生成` を確認していたが、不整合発見時に判断から脱落させた (LLM の典型 error mode = context 内に情報があっても判断時に引き出すステップが skip される)
- **(B) Adjacent Sync 方向性誤認**: roadmap.md L163-167 規約に存在しない「後続 spec 着手前 precondition」概念で「Spec 4 を先に修正」を独自正当化。Spec 4 = 先行 / Spec 3 = 後続 + Spec 3 design 未生成という状況では Adjacent Sync の発動条件 (先行 spec 変更) を満たしていない
- **(C) Negative 視点の自己適用失敗**: memory `feedback_review_step_redesign.md` Step 1b-v 5 切り口 (5 番目 = Negative 視点強制発動) と `feedback_dominant_dominated_options.md` の self-confirmation 偏向抑制を user に課す立場でありながら、私自身の検討プロセスに自己適用せず、「不整合発見 → 即解消提案」一直線生成に陥った

皮肉な構造として、「規範範囲先取り = LLM の easy wins 偏向」(memory `feedback_review_judgment_patterns.md` パターン a) と診断する側が **同じ偏向** に陥っていた。memory に蓄積された規律は user との Spec レビュー時の規律として整備されていたが、私自身の検討プロセスへの **自己適用トリガー** が明示化されていなかった。

**How to apply**:

- 不整合発見時、関連 spec の phase (requirements-approved / design-approved / tasks-approved / implemented 等) を `spec.json` で必ず確認、状態を判断 context に明示的に組み込む
- 後続 spec が **未生成段階** (design 未生成等) なら、即解消提案せず「後続 spec design 生成時の Discovery input」として保留。user 報告は「発見の事実 + 後続 spec 生成時に検討すべき事項」までに留め、解消方針提示は後続 spec の boundary 確定後
- 後続 spec が **生成中段階** なら、boundary 確定後の Adjacent Sync で対処 (生成前の修正は順序逆転、二度手間 revert リスク)
- Adjacent Sync 規約の方向性 (先行 → 後続) を「後続 → 先行」に逆転させる独自概念 (例: 「後続 spec 着手前 precondition」) は規約違反。提案前に roadmap.md L163-167 を再確認
- 不整合発見後の即解消提案 bias は LLM 根本生成 bias (「価値ある具体アクションを提示したい」)、memory `feedback_review_step_redesign.md` Step 1b-v Negative 視点を **自己の検討プロセスに適用**: 「この提案は順序が逆ではないか?」「後続 spec 未生成という制約に整合しているか?」を最低 1 回自問してから user に提示
- LLM が `/kiro-spec-design` 等の skill bypass で手動検討を進める path は、skill 内 Discovery / Synthesis 段階を主体的に再実装する形になり、本件のような順序逆転を起こしやすい。可能な限り skill 経由で標準フローに乗せる
