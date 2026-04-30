# Brief: dual-reviewer-dogfeeding

> 出典: `.kiro/drafts/dual-reviewer-draft.md` v0.3 §3.1 A-2 / §3.5 / §2.10 (V4 protocol 整合 + 3 系統対照実験 = single + dual + dual+judgment、判定 7-C reflect)

## Problem

dual-reviewer prototype (4 skill 構成、V4 protocol §1.2 整合) の有効性検証 + Phase B fork go/hold 判断 + 論文用 quantitative evidence (figure 1-3 + V4 ablation evidence) 取得が必要。Spec 6 (`rwiki-v2-perspective-generation`) design phase が dogfeeding 場として最適 (dual-reviewer Phase A 期間中ペンディング維持、A-2 で再開 = Spec 6 design approve 同時に Phase A 終端)。**3 系統対照実験** (single = Opus のみ / dual = Opus + Sonnet (V3 構成) / dual+judgment = V4 完全構成 Opus + Sonnet + Sonnet) で adversarial 構造の効果 + V4 judgment 構造の効果を段階的に分離定量化する必要 (cost 3 倍、判定 7-C 採用、論文 8 月 timeline 厳守)。

## Current State

- Spec 6 (`rwiki-v2-perspective-generation`) = design phase 未着手 (Phase A 期間中ペンディング維持)
- dual-reviewer prototype (4 skill = `dr-init` + `dr-design` + `dr-log` + `dr-judgment`、V4 protocol §1.2 整合) は `dual-reviewer-foundation` + `dual-reviewer-design-review` の 2 spec で構築予定 (本 spec の依存元)
- ドラフト v0.3 §3.1 A-2 + §3.5 で対照実験設計確定 (全 Round で **3 系統 single + dual + dual+judgment** 完走、cost 3 倍、判定 7-C 採用)
- ドラフト v0.3 §2.10.3 で論文 figure 候補確定 (figure 1-5、本 spec で取得するのは figure 1-3 = quantitative + V4 ablation evidence = dual vs dual+judgment 効果分離)
- Phase B fork timing 判断基準確定 (致命級 ≥ 2 件 / disagreement ≥ 3 件 / bias 共有反証 evidence 確実 / `impact_score` 分布が minor のみではない / **過剰修正比率改善 (V4 dual+judgment vs V3 dual で do_not_fix 比率減 / 採択率増、V4 protocol H1+H3 仮説整合)**)

## Desired Outcome

A-2 完了 (= Phase A 終端) 状態:

- Spec 6 design Round 1-10 完走 + Spec 6 design approve = Rwiki v2 design phase 全 8 spec approve 完了
- 全 Round で **3 系統 (single + dual + dual+judgment) 対照実験完了 (cost 3 倍、判定 7-C)**
- 比較 metric 取得 (致命級発見再現性 / disagreement 率 / Phase 1 同型 hit rate / `impact_score` 分布 / `fatal_patterns.yaml` 強制照合効果 + **必要性 5-field 評価分布 / 3 ラベル分類比率 / 過剰修正比率 / 採択率**)
- Phase B fork go/hold 判断完了 (V4 protocol H1+H3+H4 仮説検証含む)
- 論文用 quantitative evidence 取得:
  - figure 1: `miss_type` 分布 (3 系統比較)
  - figure 2: `difference_type` 分布 + forced divergence 効果 (dual vs single で adversarial 効果分離)
  - figure 3: trigger 発動率 (`trigger_state` skipped 比率、3 系統比較)
  - figure ablation (V4 §4.4 整合): dual vs dual+judgment で **judgment subagent 効果分離** = 過剰修正比率削減効果 / 必要性判定 quality

## Approach

- dual-reviewer prototype を Spec 6 design に適用、Round 1-10 を **3 系統** で完走 (判定 7-C、cost 3 倍):
  - **single 系統**: primary (Opus) のみで 10 ラウンド、adversarial subagent なし、judgment subagent なし、`dr-log` で 2 軸並列 schema で JSONL 記録 (失敗構造観測軸のみ自己ラベリング、修正必要性判定軸は primary 自身が暫定値付与)
  - **dual 系統 (V3 構成)**: primary (Opus) + adversarial (Sonnet) の dual-reviewer 構成、judgment subagent なし、現行 v3 同様の運用、修正必要性判定軸は primary 自身が暫定値付与
  - **dual+judgment 系統 (V4 完全構成)**: primary (Opus) + adversarial (Sonnet) + judgment (Sonnet) の V4 §1.2 option C 構成、修正必要性判定軸は judgment subagent が確定値付与 (= `dr-judgment` skill 起動)
- 各 Round 実施後、JSONL log を分析して比較 metric 抽出
- 3 系統で `miss_type` / `difference_type` / `trigger_state` を同 schema で記録 (single/dual でも自己ラベリング、dual+judgment との差を可視化)
- 修正必要性判定軸 (V4 §1.3 5-field + 3 ラベル分類) は dual+judgment 系統のみで judgment subagent 確定値、他系統は primary 自己 estimate (= ablation framing V4 §4.4 整合 = 「Step 1c なし baseline (single + dual)」 vs 「Step 1c あり (dual+judgment)」)
- 全 Round 完了後、A-2 終端判断 (Phase B fork go/hold):
  - 致命級発見 ≥ 2 件 (Spec 3 = 1 件 + Spec 6 で 1 件以上) → go
  - disagreement ≥ 3 件 (Spec 3 = 2 件 + Spec 6 で 1 件以上、forced divergence 効果含む) → go
  - bias 共有反証 evidence 確実 (subagent 独立発見が再現) → go
  - `impact_score` 分布が minor のみではない (重要 / 致命級が含まれる) → go
  - **過剰修正比率改善 (dual+judgment vs dual で do_not_fix 比率減 / 採択率増、V4 protocol H1+H3 仮説整合)** → go

## Scope

- **In**:
  - Spec 6 (`rwiki-v2-perspective-generation`) design への dual-reviewer 適用 (4 skill prototype、V4 protocol §1.2 整合)
  - 全 Round (1-10) の **3 系統対照実験** (single + dual + dual+judgment、cost 3 倍、判定 7-C)
  - JSONL log 取得 (3 系統、2 軸並列 schema)
  - 比較 metric 抽出 + 論文 figure 1-3 用データ整理 + V4 ablation evidence (dual vs dual+judgment effect 分離)
  - Phase B fork go/hold 判断 (V4 protocol H1+H3+H4 仮説検証含む)
  - Spec 6 design approve 同時達成
- **Out**:
  - dual-reviewer prototype 本体実装 (`dual-reviewer-foundation` / `dual-reviewer-design-review` で別 spec)
  - Spec 6 design 内容自体の策定 (`rwiki-v2-perspective-generation` spec で本 spec と並走、本 spec の scope 外)
  - 論文ドラフト執筆 (Phase 3 = 7-8月、別 effort、本 spec は figure 用データ取得のみ)
  - B-1.x 拡張 schema 実装 (`decision_path` / `skipped_alternatives` / `bias_signal`、B-1.x で別 spec)
  - case study 記述 (figure 4-5、Phase 3 論文ドラフト)
  - multi-vendor 対照実験 (B-2 以降)

## Boundary Candidates

- dual-reviewer 適用ロジック (本 spec) と Spec 6 design 内容 (Spec 6 spec) の境界
- quantitative evidence 取得 (本 spec、figure 1-3) と qualitative evidence 取得 (B-1.x で別 spec、figure 4-5) の境界
- 比較 metric 抽出 (本 spec) と論文ドラフト執筆 (Phase 3、別 effort) の境界

## Out of Boundary

- B-1.x 拡張 schema (`decision_path` / `skipped_alternatives` / `bias_signal`) の取得 (本 spec の scope 外、A-2 後半 〜 B-1.x で実装)
- case study 記述 (Phase 3 論文ドラフト)
- multi-vendor 対照実験 (Claude vs GPT vs Gemini etc.、B-2 以降)
- Phase B-1.0 release prep (固有名詞除去 / npm package 化、本 spec 完了後の作業 = 元 A-3 統合 #3)
- Spec 6 自体の design 内容策定 (`rwiki-v2-perspective-generation` spec 自身の作業)

## Upstream / Downstream

- **Upstream**: `dual-reviewer-foundation`, `dual-reviewer-design-review`, `rwiki-v2-perspective-generation` (Spec 6 design 用、本 spec と並走)
- **Downstream**: Phase B-1.0 release prep (本 spec 完了 = A-2 終端 = Phase A 終端後)

## Existing Spec Touchpoints

- **Extends**: なし
- **Adjacent**:
  - `rwiki-v2-perspective-generation` (Spec 6): 本 spec と並走、Spec 6 の design phase 進行は Spec 6 spec 自身で実施、本 spec は dual-reviewer の適用と metric 取得のみ
  - `dual-reviewer-foundation` / `dual-reviewer-design-review`: 依存元 prototype を utilizing

## Constraints

- **cost 3 倍** (single + dual + dual+judgment 3 系統で全 Round 1-10 = cost 約 3 倍、判定 7-C 採用、論文 8 月 timeline は Phase 2 期間集中で厳守)
- Spec 6 design は本 spec と並走 = Spec 6 design 完成 = 本 spec 終端 = A-2 終端 = Phase A 終端
- A-2 終端後 = 即 Phase B-1.0 release prep に移行 (#3 統合判断、本 spec の Phase A 内に閉じない)
- 論文 timing = 8 月ドラフト提出、本 spec は Phase 2 (6-7月、A-2 期間) で quantitative evidence 取得 = figure 1-3 用データ + V4 ablation evidence (judgment subagent 効果分離)
- 3 系統すべてで `miss_type` / `difference_type` / `trigger_state` を自己ラベリング (3 系統の trigger failure 率比較で adversarial 効果 + judgment 効果を段階的分離 = 単純な「dual で多く拾えた」を超えた構造的 ablation evidence)
- 修正必要性判定軸 (V4 §1.3 5-field + `fix_decision.label`) は dual+judgment 系統のみ judgment subagent 確定値、single/dual 系統は primary 自己 estimate (= ablation 比較で judgment subagent の決定根拠 quality を定量化)
