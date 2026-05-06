---
name: ⚠️ 廃止済 = 大規模 spec レビューでの深掘り検討 + 自動採択方針 (historical reference)
description: 廃止済 (2026-04-28 user 再指示で自動承認モード廃止)、現方針は feedback_review_step_redesign.md 参照。本 file は historical reference として残置、深掘り process / dominated 除外規律の一部は他 memory で carry over 済
type: feedback
originSessionId: ab0afad3-4130-433a-86ce-46090be98883
---
**⚠️ ARCHIVED (2026-04-28 user 明示廃止、41st 末整理確定)**:

本 memory の「自動採択方針」は廃止済。現方針 = **各ラウンドで必ず Step 2 user 判断を経る** (= `feedback_review_step_redesign.md` 「自動承認モード廃止」明記)。escalate 必須条件 5 種 (a-e) と同等の判定 trigger は現在 `feedback_review_step_redesign.md` の escalate 必須条件 5 種 (= internal_contradiction / implementation_impossibility / responsibility_boundary / normative_scope / multiple_options_tradeoff) として carry over 済。深掘りプロセス (= SSoT 再照合 / 代替案検討 / 副作用確認 / dominated 案除外) は現在も生きており `feedback_dominant_dominated_options.md` + `feedback_review_step_redesign.md` Step 1b 5 重検査で適用継続。

本 file は historical reference として残置、現在の規律適用 / 新規参照には使わない。

---

(以下、historical content)

大規模 spec レビュー（Spec 5/2/3/6 等の 100+ AC 規模）で当初推薦案を再度深掘り検討し、致命的デメリットなしと確認できた修正は自動採択して進める方針。

**Why:** 174 AC × 残り 4 spec を従来手順で進めるとユーザーの細部判断負荷が判断品質を下回る。Spec 1/4/7 のセッションで第 3-4 ラウンド以降に致命級が初出する事例が頻発しており、最初の推薦から深掘りで結論が変わる現象を実証。深掘り検討は LLM の得意領域で、ユーザーは全体構造と escalate 案件の判断に集中する方が品質が高い。`feedback_dominant_dominated_options.md`（合理的選択肢のみに絞る方針）の自然な拡張。

**How to apply:**

- **自動採択対象 ✅**: requirements.md / brief.md / design.md への文言追加・AC 追記・enum 拡張・SSoT 整合修正等の機械的・派生的な修正
- **自動採択対象外 ❌**: spec.json approve / commit / push / phase 移行（`feedback_approval_required.md` を維持）、設計トレードオフ（複数案で性質が異なる判断）

**escalate 条件**（以下のいずれかで自動採択せず必ずユーザー判断を仰ぐ）:

- a. 既 approve 済 spec への破壊的波及（再 approval 級、`updated_at` 更新だけで済まない）
- b. 複数の合理的案が拮抗（性能 vs 単純性、厳格性 vs 拡張性 等メリット軸が異なる）
- c. drafts / Foundation との SSoT 矛盾が残る
- d. 不可逆性が高い（用語・enum・schema の確定で後から覆すと多 spec 修正が必要）
- e. 深掘り中に新規致命級発見で当初推薦の前提が崩れる

**深掘りプロセス**（各候補修正で実施）:

- SSoT 再照合（drafts / Foundation / 上流 spec の該当箇所を再読）
- 代替案検討（最低 2 案、案 B が dominated でなければ escalate）
- 副作用確認（他 spec / 他 Req への波及）
- dominated 案除外（明らかに劣る案を除外、合理的案のみ残す）

**ログ形式**（各修正で報告 + dev-log に記録）:

- 当初推薦案
- 深掘り検討プロセス
- 採択結論（自動採択 / escalate / 案修正）
- 理由（致命的デメリットの有無、escalate 時はその条件）

**最終確認**: 全致命級・重要級の修正完了後、ユーザーに差分要約を提示 → spec.json approve は明示承認（既存ルール維持）。

## 関連 memory

- `feedback_review_rounds.md`: 5 ラウンド構成の各ラウンドで発見した修正候補に本方針を適用
- `feedback_dominant_dominated_options.md`: 深掘りプロセスの「代替案検討」「dominated 案除外」で参照
- `feedback_choice_presentation.md`: escalate 判定された案件の選択肢提示方法 (ラベル + 階層性)
- `feedback_approval_required.md`: 自動採択は修正適用のみ、spec.json approve / commit / push は本 memory の規範に従う別工程
