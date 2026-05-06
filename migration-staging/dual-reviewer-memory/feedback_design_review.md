---
name: 設計レビューの観点と 10 ラウンド構成 (中庸統合版、structure SSoT)
description: 設計 (design) フェーズのレビュー方法。10 観点 = 10 ラウンドの structure SSoT として継続有効。subagent dispatch 等の現方法論は v3/v4 memory (= feedback_design_review_v3_consolidated.md + feedback_review_v4_necessity_judgment.md) 参照
type: feedback
originSessionId: 72c721dd-8831-4f92-8ac1-4797c74aaff4
---
**📍 現方法論との関係 (整理確定)**:

本 memory は **10 観点 = 10 ラウンド structure の SSoT** として継続有効。各ラウンドの観点定義 / 中庸統合 (= 12 → 10 統合) / 全ラウンド網羅実施規律は現在も適用。subagent dispatch protocol (= adversarial / judgment) + necessity 5-field schema 等の現方法論詳細は別 memory:
- v3 (= adversarial subagent 統合): `feedback_design_review_v3_consolidated.md`
- v4 (= judgment subagent + necessity 5-field): `feedback_review_v4_necessity_judgment.md`

本 file の Step 構造 (= 各ラウンド 5 step) は v4 では Step 1a/1b/1b-v + 1c に再構成済 = `feedback_review_step_redesign.md` 参照。

---

設計レビューは仕様レビューと観点が異なる。仕様は「何 (WHAT) を満たすか」の宣言、設計は「どう (HOW) 実現するか」の具体化が中心。本 memory は設計フェーズのレビュー観点と進め方を規定する。

**Why:** 仕様レビューの 5 ラウンド構成 (feedback_review_rounds.md) を設計に流用すると、設計特有の観点 (アーキテクチャ整合 / 性能達成手段 / 失敗 handler 具体化 / 観測性) が不足する。仕様レビューで確定済みの内部矛盾 / SSoT 整合は設計時には再検証コスト低、代わりに設計特有の観点を網羅すべき。設計フェーズはラウンド数を仕様の 5 から増やし、**10 観点 = 10 ラウンド** として **全ラウンドを基本実施** する。**Spec 4 design 試行 (2026-04-28) で 12 → 10 へ中庸統合**: アルゴリズム+性能 / 失敗+観測の 2 ペアは技術的に密接 (アルゴリズム選択 = 性能直結 / 失敗観測 = 復旧設計の前提) のため統合、時間負荷 17% 削減 + 観点 cover 維持。

**How to apply:**

設計レビューの観点 (10 項目、**基本全 10 ラウンドを網羅実施、省略しない**):

1. requirements 全 AC の網羅 (設計が AC を漏れなくカバーしているか)
2. アーキテクチャ整合性 (モジュール分割 / レイヤ / 依存グラフが requirements と整合)
3. データモデル / スキーマ詳細 (仕様で宣言された field / 値域が実装スキーマで具体化されているか)
4. API interface 具体化 (signature / error model / idempotency / pagination)
5. **アルゴリズム + 性能達成手段** (統合): 計算量 / 数値安定性 / edge case 網羅 + prototype 測定 / SQLite index / cache / 並列化 (アルゴリズム選択 = 性能直結のため統合)
6. **失敗モード handler + 観測性** (統合): rollback / retry / timeout の具体的実装パターン + ログフォーマット / メトリクス収集点 / トレース ID / 診断 dump (失敗観測 = 復旧設計の前提のため統合)
7. セキュリティ / プライバシー具体化 (sanitize / encryption / log redaction / git ignore)
8. 依存選定 (library / version 制約 / v1 継承との整合)
9. テスト戦略 (unit / integration / cross-spec)
10. マイグレーション戦略 (v1 → v2 移行 / ledger フォーマット変更時の migration script)

ラウンド構成: **基本 10 ラウンド (10 観点) を網羅実施、省略しない**。spec 性質によって変わるのは **各ラウンドの深さ / 検出量** であって、ラウンドそのものの有無ではない:

- 規範 spec (例: Spec 0 foundation): 全 10 ラウンドを実施、結果として観点 2-9 で「該当なし / 軽微」が多くなる程度の差。観点を skip するのではなく、「該当なし」を確認して次ラウンドに進む
- 実装重 spec (例: Spec 5 knowledge-graph / Spec 7 lifecycle-management): 全 10 ラウンドを実施、観点 3 / 5 / 6 (データモデル / アルゴリズム+性能 / 失敗+観測) が深く厚くなる
- interface 重 spec (例: Spec 3 prompt-dispatch / Spec 4 cli-mode-unification): 全 10 ラウンドを実施、観点 4 / 9 (API interface / テスト戦略) が深く厚くなる

**Phase 1 完了 spec への遡り適用** (Spec 0 / Spec 1 は 12 ラウンドで実施済): 12 → 10 統合は構成軽量化のみ、Phase 1 の検出内容は維持される (12 ラウンド実施結果を 10 ラウンドの統合観点に再分類するだけ)。Spec 0 / Spec 1 への新方式遡り適用判断時に、Phase 1 既検出を 10 ラウンド構成にマッピングする。

設計レビューでも仕様レビュー同様に **第 N ラウンドの 5 step 必須手順** (feedback_review_rounds.md 継承の精神) を踏襲: 各ラウンド Step 1 で観点に対応する設計記述を提示 → Step 2 でユーザー判断 (詳細 / approve) → Step 3 で詳細抽出 → Step 4 で深掘り検討 + 自動採択 / escalate 判断 → Edit 適用。「該当なし」確認も明示的に行い、ラウンドを跳ばさない。

**ラウンド一括処理禁止 (重要)**: 「ラウンド N-M を一括して実施」「9 ラウンド分集約」「結果報告」型の batching は禁止。1 ラウンド = 1 turn 以上で必ず個別実施し、各ラウンドで Step 2 ユーザー判断機会を確保する。「該当なし」判定でも Step 1 提示 → Step 2 ユーザー確認 → 次ラウンドという turn 境界を作る。詳細は feedback_no_round_batching.md 参照。

特に観点 9 (テスト戦略) と観点 10 (マイグレーション) は実装フェーズに直結するため、規模の小さい spec でも **該当なし扱いせず必ずラウンドを実施** する (テスト戦略は最小でも unit / integration の境界を明示、マイグレーションは v1 から継承の有無を明示)。

継承する仕様レビューの方針 (修正なしで継続適用):

- dominated 選択肢を提案しない (feedback_dominant_dominated_options.md): 設計でも継承
- 選択肢提示の方法 (feedback_choice_presentation.md): 設計の trade-off 選択肢提示でも継承
- 承認なしで進めない (feedback_approval_required.md): 設計 phase 移行 / design.md approve も継承

設計特有の追加方針:

- **ADR 独立ファイルは採用しない** (機能しなかった経験あり)。決定事項は design.md 本文「設計決定事項」セクション + change log に二重記録 (feedback_design_decisions_record.md 参照)
- **性能は prototype で測定**、機能優先 (correctness 優先で性能は実測ベース)
- **Failure scenario walkthrough は best effort** (必須ではなく、できる範囲で実施)
- **Cross-spec integration テスト設計はハイブリッド方式**: 2 spec 間 test は consumer design に記述 (例: Spec 6 が Spec 5 Query API を呼ぶ test は Spec 6 design)、3+ spec triad は中心 spec design で end-to-end フロー記述 (例: hypothesis verify → approve → wiki/synthesis/ 昇格 = Spec 6 / Spec 5 / Spec 7 triad、中心は Spec 6 design)。中心 spec はユーザー視点の起点となる spec で判断
- **仕様⇄設計の往復改版判断軸**: 仕様 AC として読めるかどうか + ユーザー対話必須 (feedback_design_spec_roundtrip.md 参照)

関連 memory:

- feedback_design_spec_roundtrip.md — 仕様⇄設計往復判断軸
- feedback_design_decisions_record.md — 設計決定の記録方式 (ADR 代替)
- feedback_no_round_batching.md — ラウンド一括処理禁止 (skip 防止策)
- feedback_review_rounds.md (仕様向け) — 仕様レビューでの 5 ラウンド構成 (設計時は柔軟化)
- feedback_dominant_dominated_options.md / feedback_choice_presentation.md / feedback_approval_required.md — 仕様 / 設計両フェーズで継承
