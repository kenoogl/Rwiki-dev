---
name: ⚠️ CONSOLIDATED = 設計レビュー方法論 v3 試験運用 + req phase V3 適用 evidence (詳細 historical reference)
description: 41st 末整理で feedback_design_review_v3_consolidated.md (核心 evidence + 4 段階 review pattern) に統合済、本 file は試験運用 metrics + req phase 4 phase 構造の詳細 historical reference として残置
type: feedback
originSessionId: spec-3-design-approve-2026-04-29
---
**📦 CONSOLIDATED (41st 末整理確定)**: 本 file の核心 (= adversarial subagent 統合の有効性 evidence + 累計 12 件致命級独立発見 + 4 段階 review pattern) は `feedback_design_review_v3_consolidated.md` に統合済。現在の規律 / 規範参照は consolidated memory を使用、本 file は試験運用詳細 (= Spec 3 Round 5-10 metrics / req phase 6th セッション 4 phase 構造 / Chappy 採用判断材料 等) の historical reference として残置。

---

(以下、historical content)



設計レビューを **旧 10 ラウンド方式 + adversarial subagent 統合** で実施する v3 方法論。Spec 3 design Round 5-10 で試験運用、bias 共有疑念に対する決定的反証 evidence を確立。

**Why:** 旧 10 ラウンド方式 (feedback_design_review.md / feedback_review_step_redesign.md) では、user 介入が「LLM が user に説明する責任」として bias 抑制機能を果たしていたが、Round 1-4 で user が全件「案 A」即答 = 形式的承認に近い状態が顕在化。**真の抑止力 = 「LLM が説明責任を背負って厳しく検査せざるを得ない構造的 pressure」** だが、user 即答ではこの pressure が機能しない。一方、user の domain knowledge / preference は subagent では完全代替不可。**解 = subagent (Sonnet 4.6) を adversarial reviewer として LLM 主体 (Opus 4.7) を independent 審査、user は disagreement のみ仲裁判断**。

**How to apply:**

## v3 方法論の構造

各 Round で以下 3 ステップを実施:

### Step A: LLM 主体 Step 1 検出 (Claude Opus 4.7)

旧方式の Step 1a / Step 1b / Step 1b-v をそのまま実施 (feedback_review_step_redesign.md 規律遵守):

- Step 1a (軽微検出、自動採択候補)
- Step 1b (構造的検出、4 重検査必須):
  - Step 1b-i: 二重逆算検査
  - Step 1b-ii: Phase 1 escalate 実例パターンマッチング
  - Step 1b-iii: dev-log 23 パターンチェックリスト適用
  - Step 1b-iv: 自己診断義務
- Step 1b-v: 自動深掘り判定 (1 回目 5 観点 + 2 回目 5 切り口)
- 厳しく検証 5 種強制発動 (a 規範範囲先取り / b 構造的不均一 / c 文書 vs 実装不整合 / d 規範前提曖昧化 / e 単純誤記 grep)

### Step B: adversarial subagent 起動 (Claude Sonnet 4.6)

`Agent` tool で general-purpose subagent を起動、`model="sonnet"` 指定 (Opus と異なる偏向で bias 共有を抑制):

```
subagent_type: general-purpose
model: sonnet
prompt:
- 役割明示: 「あなたは adversarial reviewer subagent です。LLM 主体 (Opus 4.7) の検出結果を independent 審査し、easy wins 偏向 / 自動採択偏向を意図的に抑制する役割」
- 入力: design.md + requirements.md (Read tool で読込) + LLM 主体検出結果 (prompt に埋込)
- bias 抑制必須 quota:
  (1) LLM 主体の自動採択候補に formal challenge (challenge 経緯 1 行明示)
  (2) 検出漏れ minimum 5 観点検査 (該当なしなら「N 観点検査済」明示、skim 禁止証跡)
  (3) Phase 1 escalate 3 実例 (Spec 0 R4 / Spec 1 R5 / Spec 1 R7) の同型探索を必ず実施
- 検査観点候補リスト: Round 観点に応じた具体的 13-15 観点を prompt に列挙 (LLM 主体が見落とす可能性のある観点)
- 出力フォーマット厳密遵守:
  - LLM 主体検出への審査 (同意 / 緩和推奨 / 致命級格上げ / 反転推奨 + challenge 経緯)
  - 検出漏れ追加 (致命級 / 重要級 / 軽微 評価 + 推奨対応)
  - Phase 1 同型探索結果 (3 種別 該当 / 該当なし)
  - 総合判断 (適否 / disagreement 件数 / 致命級追加検出 / mitigation 効果自己評価)
```

### Step C: 検出統合 + user 報告

LLM 主体検出と subagent 検出を統合:
- 一致部分: user 確認のみで Edit 適用
- disagreement (LLM ≠ subagent 推奨): user 仲裁判断必須
- subagent 緩和推奨 (LLM 主体推奨を縮小修正): user 確認後反映
- subagent 追加検出 (致命級 / 重要級 / 軽微): 推奨案提示後 user 判断

各 Round 末尾で metrics 記録:
- LLM 主体検出 (自動採択 / escalate)
- subagent 追加検出 (致命級 / 重要級 / 軽微)
- disagreement 件数
- Phase 1 同型該当数
- 致命級追加検出 (subagent 由来)
- wall-clock (subagent 実行時間)

## 試験運用 evidence (Spec 3 design Round 5-10、2026-04-29)

### 累計 metrics

- LLM 主体検出: 自動 7 件 + escalate 16 件 = 24 件
- subagent 追加検出: **致命級 1 件 + 重要級 13 件 + 軽微 9 件 = 23 件** (LLM 主体検出と同等規模の補完 value-add)
- disagreement: 2 件 (Round 6 / Round 7)
- 致命級独立発見 (subagent): 1 件 (Round 7、symlink follow 攻撃 = LLM 主体完全見落とし)
- Phase 1 同型 3 種全該当: 2 度達成 (Round 7 + Round 9)
- wall-clock: subagent 1 回平均 ~152 秒 (122-220 秒範囲)、全 6 Round 合計 ~15 分

### bias 共有疑念に対する反証 evidence

1. **致命級独立発見**: subagent が LLM 主体完全見落としの致命級を独立検出 (symlink follow 攻撃) → 同モデル偏向共有では発見不可能な検出
2. **disagreement 発生**: subagent が LLM 主体推奨の見落とし (Monitoring section / Notification.source 7 値列挙) を発見 → 単純同意ではなく真の independent 視点維持
3. **Phase 1 escalate 同型 3 種全該当を 2 度達成**: subagent が Spec 0 R4 / Spec 1 R5 / Spec 1 R7 の全 3 種 escalate パターンを独立に該当検出 → Phase 1 学習適用が安定化
4. **緩和推奨 3 件**: LLM 主体推奨が過剰 (規範範囲先取りリスク) と subagent が指摘 → bias 抑制機能発動

## req phase V3 適用 evidence (dual-reviewer 3 spec、2026-04-30)

Spec 3 design Round 5-10 (試験運用 1 件) に続き、**req phase の 3 spec (foundation / design-review / dogfeeding)** に V3 を適用。req phase でも design phase と同等粒度で機能することを実証 = **req phase V3 default 採用推奨**。

### 適用範囲 (本セッション = 6th セッション、4 phase 構造)

- **Phase α**: dogfeeding requirements 生成 → V3 5 ラウンド review (Round 1-5)
- **Phase β**: 3 spec 横断 adjacent integrity 再点検 (cross-spec)
- **Phase γ**: 各 spec 単独 内部整合性 audit (3 spec parallel subagent dispatch)
- **Phase δ**: 3 観点追加 audit (statistical 独立性 / Reproducibility / defer 集約)

### 累計 metrics (本セッション)

- subagent dispatch 回数: **8 回** (Round 1-4 = 4 + cross-spec 1 + parallel 単独 audit 3、Round 5 は grep ベース)
- 累計 wall-clock: ~25-30 分
- LLM 主体 + subagent 統合検出: **約 100 件超**
- **致命級独立発見 (subagent 由来): 7 件** (Round 1 R1-03 metric 論理欠陥 / Round 4 SA-01 cross-mode race / Round 5 D-1 cross-spec contract 欠陥 等)
- **Phase 1 同型 3 種全該当達成: 5 度** (Round 1 / Round 3 / Round 4 / foundation 単独 audit / dogfeeding 単独 audit)
- **disagreement 件数: 8 件以上** (subagent 反転推奨 / 緩和推奨 / 致命級格上げ)
- 修正適用: 69 件 + 新規 file 1 (defer list)

### 全プロジェクト累計 (Spec 3 + foundation + design-review + dogfeeding)

- 致命級独立発見: **12 件** (Spec 3 = 1 + 4th セッション foundation = 2 + 5th セッション design-review = 2 + 本セッション dogfeeding = 7)
- Phase 1 同型 3 種全該当: **17 度**
- disagreement: **17 件以上**

→ Spec 3 試験運用「致命級 1 + disagreement 2/24 + 同型 2 度」を遥かに超える decisive reproduction = bias 共有疑念に対する反証 evidence の決定的蓄積継続

### req phase V3 適用で機能した点

1. **subagent 独立致命級発見**: LLM 主体 escalate 推奨 → subagent 致命級格上げ (R1-03 metric 論理欠陥) / subagent 完全独立検出 (Round 4 SA-01 cross-mode race condition、LLM 主体未検出) = req phase でも design phase と同型の bias 抑制機能発動
2. **cross-spec contract 欠陥検出**: Round 1 で発見した「JSONL schema に Phase 1 メタパターン field 不在」(R5 同型) を Round 5 で foundation Req 3 AC 10 + design-review Req 6 AC 8 + dogfeeding Req 4 AC 3 の 3 spec 連鎖改版 = cross-spec 視点が単一 spec review では発見困難
3. **同期漏れ検出**: Round 5 で phase1_meta_pattern 追加後、brief / 一部 requirements に未同期 → 単独 audit で発見 = **3 段階 (V3 → cross-spec → 単独 audit) 構造の必要性実証**
4. **論理矛盾検出**: dogfeeding Req 1 AC 4 failure 段階化 4 種に成功宣言 (d) 混入 = 単独 audit (8 観点 G = AC 内部論理整合) で初めて検出
5. **statistical 健全性検出**: Req 6 AC 1 4 基準の包含関係 (実質 3 独立 evidence) = 観点 2 追加 audit で発見

### req phase 適用で確立した review pattern (template 化推奨)

req approve 直前 gate として以下 4 段階を default 採用:

1. **V3 5 ラウンド review** (Round 1 基本整合性 / Round 2 上位文書照合 / Round 3 本質的観点 / Round 4 B 観点 / Round 5 波及精査)
2. **3 spec 横断 adjacent integrity 再点検** (cross-spec dependency / contract 欠陥)
3. **各 spec 単独 内部整合性 audit** (8 観点 = AC 連番 / Subject / Boundary / field 名 / 用語 / Objective / 内部論理 / 連鎖整合) を parallel subagent で実施
4. **追加観点 audit** (statistical 独立性 / Reproducibility / defer 集約) で残存 risk を補完検出

### 適用対象拡張

- **req phase**: 本セッションで 3 spec に適用 → req phase V3 default 採用推奨
- **design phase**: Phase 5b 以降 (Spec 6 含む) で継続適用 (既存方針)
- **tasks phase**: req / design 同様に V3 適用推奨 (B-1.1 で `dr-tasks` skill 実装後に default 化)
- **implementation phase**: PR review 形式で V3 適用推奨 (B-1.4 で `dr-impl` skill 実装後)

### 適用対象スコープへの追記

req phase V3 適用 evidence は B-1.0 拡張 schema 4 要素 (`phase1_meta_pattern` 含む) で記録され、`dr-log` が JSONL に保存。論文用 figure 1-3 + Phase 1 同型 hit rate (Req 4 AC 3) で集計可能。

## 採用判断材料

### Pro
- 致命級独立発見 + LLM 主体見落とし 2 件指摘 + bias 抑制機能 evidence
- user 認知負荷分散 (disagreement のみ仲裁判断)
- wall-clock 影響限定的 (subagent 並行実行可能)

### Con
- subagent token cost 増加 (Sonnet 4.6 で平均 ~150 秒 / Round)
- 致命級発見の保証なし (Round 5/6/8/10 は致命級 0 件)
- subagent の追加検出粒度が LLM 主体と類似する傾向あり (self-limitation 記録あり)

### 総合判断
**subagent token cost は致命級 1 件防止 (production deploy 後の工数 vs subagent 数分のコスト) で十分回収可能、採用推奨**。Phase 5b 以降の spec で継続適用し統計を蓄積。

## 適用対象 + 運用 default

- **Phase 5b 以降 (Spec 6 含む)**: 設計レビュー方法論 v3 を default 採用、各 Round で adversarial subagent 起動
- **Phase 1-4 既 approve spec**: やり直し対象外 (致命級は Round 1-10 で既解消、再適用 ROI 低)
- **新規 spec の design 生成 + Round 1-10 レビュー**: v3 default 適用
- **適用例外**: 緊急 hotfix で時間制約厳しい場合のみ subagent 省略可、ただし LLM 主体検出のみで致命級リスクを認識した上での意思決定

## 残課題 (Phase 5b 以降で継続観察)

1. **致命級発見率の継続観察**: Round 7 のみ致命級発見 (1/6 Round = 17%)、他 5 Round は 0 件 → 統計蓄積で平均率を確定
2. **Sonnet vs Haiku の比較**: より cheap な Haiku 4.5 で同等の adversarial 機能が発揮されるか検証する余地
3. **subagent prompt 改良**: Phase 1 escalate 同型 3 種全該当が Round 7 / Round 9 に集中した理由分析、より早期の Round で達成できる prompt 設計
4. **user による subagent 結果 review 経験の蓄積**: 試験運用では user 反転 0 件、Phase 5b 以降で蓄積 → false positive 比率を確定

## 関連 memory

- `feedback_design_review.md`: 10 ラウンド構成 (v3 で継承、Step A LLM 主体検出に適用)
- `feedback_review_step_redesign.md`: Step 1a/1b 分割 + 4 重検査 + Step 1b-v 自動深掘り (v3 で継承)
- `feedback_no_round_batching.md`: ラウンド一括処理禁止 (v3 で継承)
- `feedback_dominant_dominated_options.md`: dominated 選択肢除外 + 厳密化規律 (v3 で継承)
- `feedback_review_judgment_patterns.md`: dev-log 23 パターン (Step 1b-iii で適用、subagent prompt にも要点埋込)
- `feedback_design_review_mechanical.md`: v2 機械検証中心 (ペンディング、v3 とは独立した代替方法論として残存)

## 参照点

- **試験運用報告書**: `.kiro/methodology/dogfeeding/spec-3/round_5-10_subagent_adversarial.md` (commit `4703ac4`)
- **dev-log**: `docs/Rwiki-V2-dev-log-6.md` (commit `793648d` + `4703ac4`)
- **適用 spec**: `.kiro/specs/rwiki-v2-prompt-dispatch/design.md` (commit `f28f0a0`、Round 1-10 全完走 + Round 5-10 で v3 試験運用)
