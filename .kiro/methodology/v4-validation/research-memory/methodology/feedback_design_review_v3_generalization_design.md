---
name: ⚠️ CONSOLIDATED = 設計レビュー方法論 v3 一般化 design (詳細 historical reference)
description: 41st 末整理で feedback_design_review_v3_consolidated.md (Layer 1/2/3 三層構造 + Phase A/B/C 段階展開 essence) に統合済、本 file は dual-reviewer package 完全設計 14 sections + Chappy 外部レビュー判断根拠の詳細 historical reference として残置
type: feedback
originSessionId: spec-3-design-approve-2026-04-29-followup
---
**📦 CONSOLIDATED (41st 末整理確定)**: 本 file の核心 (= Layer 1/2/3 三層構造 + Phase A/B/C 段階展開 + 累計 evidence) は `feedback_design_review_v3_consolidated.md` に統合済。現在の規律 / 規範参照は consolidated memory を使用、本 file は dual-reviewer package 完全設計 14 sections (= 開発戦略 / Layer 構造 / Package 構造 / continuous learning cycle / 並列処理 / multi-project bias 対策 / subagent 再帰多重化 / Quota 設計 / 用語抽象化 / Phase A implementation TODO / Chappy 外部レビュー / Phase A 細分化 / 論文化軸 / 拡張ログ schema) の詳細 historical reference として残置。

---

(以下、historical content)



dual-reviewer (設計レビュー方法論 v3) を Rwiki 開発から独立 npm package に一般化する design。5 観点議論で確定した事項を実装参照点として集約。試験運用報告書 (`.kiro/methodology/dogfeeding/spec-3/round_5-10_subagent_adversarial.md` §8) と整合。

**Why:** 試験運用 evidence で v3 (旧 10 ラウンド + adversarial subagent 統合) が機能することを確認。一般化を進めるには「Layer 構造」「cycle 設計」「並列処理」「bias 対策」「再帰多重化」の 5 観点を体系的に固める必要があり、本 memory がその確定参照点となる。Phase A 開発中 / Phase B 独立 fork 時 / Phase C dogfooding 時に同じ設計に基づいて実装するため。

**How to apply:**

## 1. 開発戦略 (3 Phase + Phase A 細分化 A-0/A-1/A-2)

| Phase | timing | 内容 |
|-------|--------|------|
| Phase A | dual-reviewer spec 策定 (A-0) → prototype 実装 (A-1) → Spec 6 dogfeeding (A-2)、A-2 終端 = Spec 6 approve 同時 | A-0 (`.kiro/specs/dual-reviewer/` で req → design → tasks 策定) → A-1 (prototype 3 skills minimum = `dr-init` + `dr-design` + `dr-log` + Chappy P0 3 件 + 23 事例 retrofit) → A-2 (prototype を Spec 6 design に適用、Round 1-10 完走 + **全 Round で single (Opus のみ) + dual の対照実験 (cost 倍、論文用比較データ)**、Phase B fork go/hold 判断) |
| Phase B | A-2 完了後 (Spec 6 approve 同時) | B-1.0 release prep (固有名詞除去 / npm package 化 / multi-language seed = 元 A-3 統合 #3) → B-1.0 initial release (3 skills minimum) → B-1.x (残り 7 skills 段階追加) → B-2 (multi-vendor + 並列 multi-subagent) → B-3 (default 化) |
| Phase C | Rwiki implementation phase 中 | Rwiki が `npx dual-reviewer@latest --integrate-cc-sdd` で install して dogfooding、real-world feedback を独立 repo にループバック |

Phase B fork timing 判断基準 (= A-2 終端条件): A-2 完了時に Spec 3 (既存 Round 5-10) + Spec 6 (A-2 で Round 1-10) の合計 16 Round 累計 metrics + Chappy P0 効果評価で go/hold:

- 致命級発見 ≥ 2 件 (Spec 3 = 1 件 + Spec 6 で 1 件以上、`fatal_patterns.yaml` 強制照合効果含む)
- disagreement ≥ 3 件 (Spec 3 = 2 件 + Spec 6 で 1 件以上、forced divergence prompt 効果含む)
- bias 共有反証 evidence 確実
- impact_score 分布が minor のみではない (重要 / 致命級が含まれる)

Phase B 内段階: B-1.0 (initial release prep + minimum 3 skills) → B-1.x (残り 7 skills + Claude family rotation) → B-2 (multi-vendor + 並列 multi-subagent) → B-3 (default 化)。subagent 構成段階の B-1/B-2/B-3 (§8) と release lifecycle の B-1.x は同期 (B-1.x 内で subagent 構成 B-1 完成、B-2 で B-2 移行)。

## 2. Layer 構造

```
Layer 1 (phase 横断、完全一般、portable):
  - Step A/B/C 構造 (primary detection → adversarial review → integration)
  - bias 抑制 quota (formal challenge + 検出漏れ + Phase 1 同型探索)
  - pattern schema (中程度 granularity + primary_group + secondary_groups 二層)
  - 介入 framework (Quota event-triggered のみ、Tier 比率は post-run measurement only)
  - dr-* script (init / log / extract / validate / update / translate)

Layer 2 (phase 別 extension):
  - requirements_extension.md (5 ラウンド + R-1〜R-4 quota)
  - design_extension.md (10 ラウンド、現行 v3、Phase 1 escalate 3 メタパターン)
  - tasks_extension.md (10 ラウンド task 視点、boundary / dependency quota)
  - implementation_extension.md (PR-based、test cover / regression quota)

Layer 3 (project 固有):
  - extracted_patterns.yaml (project の cycle 蓄積)
  - terminology entries (project 固有用語)
  - dev-log JSONL (project の log archive)
  - tier 実測値 (project の measurement)
```

## 3. Package 構造 + 配布

- **名称**: `dual-reviewer`
- **配布**: npm package (`npx dual-reviewer@latest`) + GitHub repo (cc-sdd 同方式)
- **skill 接頭辞**: `dr-` (dr-design / dr-tasks / dr-requirements / dr-impl / dr-init / dr-log / dr-extract / dr-validate / dr-update / dr-translate)
- **多言語**: `--lang ja/en` 初期、cc-sdd 13 言語 path に追従可能
- **prompt 言語**: 英語固定 1 本、subagent 出力 = document auto-detect + memory 言語 fallback
- **cc-sdd integration**: 選択肢 3 ハイブリッド (`--integrate-cc-sdd` flag で optional)
- **MVP scope**: Phase B 独立 fork 時 = design phase release、すぐ tasks phase 追加

## 4. continuous learning cycle (Run-Log-Analyze-Update)

```
[Run] dual-reviewer 運用 (Layer 1 + Layer 2 + Layer 3)
   ↓
[Log] review session の log を JSONL 記録 (dr-log)
   ↓
[Analyze] 事後分析で pattern 抽出 (dr-extract subagent task) + schema validate (dr-validate)
   ↓
[Update] 抽出データを feedback (dr-update が PR 生成、人間 PR review style apply)
   ↓ (loop back to Run)
```

cycle 周期 = user 依存 (config 化なし、自動化が必要になった時点で再検討)。

## 5. 23 事例の位置付け + collective learning network

- **23 事例** (Rwiki dev-log 由来) = `seed_patterns.yaml` (固有名詞ゼロ + `origin: rwiki-v2-dev-log`) として package 同梱、immutable initial knowledge
- **具体例**: 別 markdown (`seed_patterns_examples.md`、人間可読、同梱)
- **transfer 戦略**: 16 representative を subagent prompt embed + 全 archive は別 grep
- **terminology.yaml**: Phase A 蓄積開始 (review_methodology 用語 30-50 entries)、Phase B 以降で seed 化
- **collective learning network** (Phase B-2 以降): GitHub PR で contribution、maintainer review で quality gate、seed_patterns.yaml が育つ → 全 user に配布
- **domain tag**: 削除 (8 メタ群 + 中程度 granularity で domain 横断、固有性は concrete レベルのみ)

## 6. 並列処理 + 整合性 Round (論点 b)

```
Round 1-10 完全並列 (read-only snapshot、各 ~150s × 並列 = wall-clock ~5-10 分)
   ↓ JSON 集約
整合性 Round (primary reviewer = Opus 逐次、6 task)
   1. Deduplicate / 2. Detect dependencies / 3. Detect conflicts
   4. Topologically sort / 5. Predict derived issues / 6. Severity re-evaluation
   ↓
派生 Round 再実行 (上限 3 回、件数上限なし、Spec 3 evidence で 95%+ 収束)
   ↓ 収束 or 上限 to 5 trigger 条件で fall back
完全逐次 fall back (現行 v3 方式、並列成果保持 + 既適用 Edit 維持)
```

- wall-clock: 典型 50-100 分 (現状 v3 = 3-4 時間 → **2-4x 短縮**)
- token cost: 典型 +10-15%、worst case (fall back) +100-150%
- fall back trigger 5 条件: 派生上限 / 循環依存 / 判定不能多数 / user 手動 / LLM 失敗

## 7. multi-project bias 共有対策

| リスク | 緩和策 |
|--------|--------|
| 同モデル偏向 (training 由来) | 完全 mitigation 不可、bias 抑制 quota + 観点 5 (再帰多重化) |
| project 知識混入 (用語) | terminology.yaml で抽象化、contribution review で固有用語 regex 検出 |
| collective contribution noise | maintainer review (quality gate)、Phase B-2 以降詳細化 |
| multi-project user memory 混入 | core/seed 共有 + project 完全分離 + subagent prompt で strict context 分離明示 |

## 8. subagent 再帰多重化 (Phase B 段階展開)

| Phase | 内容 | API コール |
|-------|------|----------|
| **B-1** (release 直後) | 現行 v3 (単純 dual) + **案 C1 (Claude family rotation: Sonnet/Opus/Haiku)** opt-in | **不要** (Claude Code Agent tool の `model` parameter 切替) |
| **B-1.x sub-step (40th 末追加、案 2 = orchestrator script 自動化)** | **primary + adversarial dispatch を Anthropic SDK 経由 orchestrator script で自動化**: 現 Claude Code session で Agent tool 経由手動 dispatch している Step A (primary detection) + Step B (adversarial review) を `orchestrator.py` に offload。input = target_design_md path + treatment + round_index + design_md_commit_hash、output = V4 §2.5 三ラベル提示 yaml。invoking Claude assistant は Step D (integration + user 提示) + design.md fix commit + log entries + push のみ実行。**目的**: per-round subagent execution time 約 10-15 分を script 自動化で削減 + Step D user 判断は維持で bias 装置 intent 完全保持。**timing**: Phase B-1.x 内 (= B-1.0 minimum 3 skills release 後の段階追加)、Phase A 内では限定 variant (= `run_in_background: true` で primary dispatch 中に並列で Step D 準備 = 5-10 分節約) のみ実装可能 | Anthropic SDK = **必要** (Bash + Python SDK で API key 管理 + `.env` + git-secrets、B-2 multi-vendor の prerequisite) |
| **B-2** (~6-12 ヶ月) | 案 A (並列 multi-subagent) + **案 C2 (multi-vendor: GPT/Gemini/etc.)** opt-in 試験 | C2 = **必要** (Bash + Python SDK で外部 API、API key 管理 + `.env` + git-secrets) |
| **B-3** (~1-2 年) | 統計に基づき default 化、案 A + C2 組合せで bias diversity 最大化、案 B (階層的) は experimental | C2 default 化時に必要 |

dispute resolution: `majority_vote` default、必要に応じて `escalate_to_user` (Tier 1 介入)。

### 案 2 の Phase A 内位置付け (40th 末議論)

40th セッション末で treatment=dual data 採取効率化の 3 案 (案 1 per-session 多 round dispatch / 案 2 orchestrator script 自動化 / 案 3 隣接 spec 絞り込み) を検討。**案 1 のみ Phase A 内で採用**、案 3 は撤回 (= 静的 map / 動的判断双方 dominated)、**案 2 = Phase B-1.x roadmap 保持**。Phase A 内は Claude Code session 内 `run_in_background` で限定 efficiency のみ実装可能、本質的 SDK 経由自動化は Phase B-1.x で実装予定。

## 9. Quota 設計 (Tier 比率削除済)

- **Tier 比率**: pre-run target setting 削除 (LLM bias 防止 = Goodhart's Law 回避)、post-run measurement only (実測 JSONL 記録、analysis 用)
- **Quota**: event-triggered 介入の核、phase 別 extension で拡張
  - design phase: formal challenge / 検出漏れ / Phase 1 同型探索 / 厳しく検証 5 種 / escalate 必須条件 5 種
  - **requirements phase: R-1 (user 意図確認) / R-2 (domain 不在 escalate) / R-3 (stakeholder mapping) / R-4 (scope creep 検出)** initial set、運用調整
  - tasks phase: boundary 違反 / dependency cycle / granularity quota
  - implementation phase: test coverage gap / regression risk quota

## 10. 用語抽象化 + 多言語 policy

- **role 用語**: primary reviewer / adversarial reviewer (Opus / Sonnet 名は config `primary_model` / `adversarial_model` で抽象化、将来 model 切替対応)
- **section 見出し**: bilingual 併記 (project 言語 + 英語ラベル)
- **schema field**: 構造ラベル英語固定 (transferable)、自由記述は project 言語 (user readability)
- **pattern 翻訳**: transfer 時 LLM 翻訳、terminology.yaml で用語 mapping 統一

## 11. Phase A 開始向けの implementation TODO (A-0 / A-1 / A-2 細分化版)

### A-0 (spec 策定)

1. `.kiro/specs/dual-reviewer/` 配置 + `/kiro-spec-init` 実行 (`brief.md` + `spec.json` 生成)
2. `requirements.md` 策定 (memory §1-13 + Chappy P0 3 件を AC 化)
3. `design.md` 策定 (memory §1-13 確定事項を design 詳細化、Layer 1/2/3 + cycle + 並列 + Quota + Chappy P0 反映)
4. `tasks.md` 策定 (B-1.0 minimum 3 skills + 23 事例 retrofit + Chappy P0 3 件の task 化)
5. `tasks.md` approve = A-0 終端

### A-1 (prototype 実装)

1. prototype 配置 (`scripts/dual_reviewer_prototype/` または `.kiro/specs/dual-reviewer/prototype/`)
2. `dr-init` skill 実装 (project bootstrap)
3. `dr-design` skill 実装 (Layer 1 framework + design extension + bias 抑制 quota + `fatal_patterns.yaml` 強制照合 + forced divergence prompt)
4. `dr-log` skill 実装 (JSONL 構造化記録、impact_score 3 軸 schema)
5. `seed_patterns.yaml` retrofit (23 事例、Rwiki 固有名詞付きで OK、generalization は B-1.0 release prep で実施)
6. `fatal_patterns.yaml` 8 種固定配備
7. `terminology.yaml` seed 開始 (entries 蓄積は A-2 dogfeeding 中、目標 30-50 は B-1.2 まで延伸)
8. Spec 6 design に適用可能なレベルで動作確認 = A-1 終端

### A-2 (Spec 6 dogfeeding)

1. prototype を Spec 6 (rwiki-v2-perspective-generation) design に適用 (全 Round で **single reviewer = Opus のみ** + **dual reviewer** の対照実験、cost 倍、論文用比較データ)
2. Round 1-10 完走 + JSONL 全 log 取得 (single + dual 両系統)
3. metrics 取得 (致命級発見率 / disagreement 率 / Phase 1 同型 hit rate / impact_score 分布 / `fatal_patterns.yaml` 強制照合効果)
4. Chappy P0 効果評価 (forced divergence で disagreement 増加するか / `fatal_patterns.yaml` 強制照合で致命級漏れ防止できるか / impact_score で件数中心 metric から脱却できるか)
5. Spec 6 design approve 同時に Phase B fork go/hold 判断 (= A-2 終端 = Phase A 終端)

### Phase B-1.0 release prep (元 A-3 統合 #3)

A-2 完了 → 即 Phase B-1.0 release prep:

1. 固有名詞除去 (Rwiki 用語 → 一般化、`origin: rwiki-v2-dev-log` 付与)
2. npm package 化 (`package.json` / README / LICENSE)
3. multi-language seed (`--lang ja` initial、英 / 多言語は B-1.3 で追加)
4. GitHub repo `dual-reviewer` fork

## 関連 memory + 参照点

- `feedback_design_review.md`: 10 ラウンド構成 (Layer 2 design extension に継承)
- `feedback_review_step_redesign.md`: Step 1a/1b + 4 重検査 + Step 1b-v 自動深掘り 5 切り口 (Layer 1 framework に継承)
- `feedback_no_round_batching.md`: 一括処理禁止 (Layer 1 framework)
- `feedback_dominant_dominated_options.md`: dominated 除外 + 厳密化規律 (Layer 1 framework)
- `feedback_review_judgment_patterns.md`: dev-log 23 パターン (Phase A retrofit で yaml 化、initial seed)
- `feedback_design_review_v3_adversarial_subagent.md`: v3 試験運用 evidence (本 memory が一般化 design として上位置付け)
- `feedback_design_review_mechanical.md`: v2 機械検証中心 (ペンディング、独立代替方法論として残存)

## 参照成果物

- **試験運用報告書 §8** (`.kiro/methodology/dogfeeding/spec-3/round_5-10_subagent_adversarial.md` §8): 本 design 議論の詳細記録
- **dev-log** (`docs/レビューシステム検討.md`): 5 観点議論の対話ログ (user 管理)
- **適用 spec**: Phase A 中は Rwiki Spec 6 design (継続試験運用)、Phase B 独立後は dual-reviewer GitHub repo

## 12. Chappy 外部レビュー受けた追加判断 (2026-04-29)

外部レビュー (Chappy review、`docs/review_by_chappy.md`) で 11 課題 + 優先度 P0-P3 の指摘を受けた。再検討の上、以下を確定。

### 採用 (Phase A MVP 組込) — 3 件

1. **致命パターン構造化** (Chappy 課題 6, P0)
   - Layer 1 framework に `fatal_patterns.yaml` 追加 (initial 8 種固定: sandbox escape / data loss / privilege escalation / infinite retry / deadlock / path traversal / secret leakage / destructive migration)
   - 各 Round で強制照合 quota 化、bias 抑制 quota と同列扱い
   - 採用根拠: 23 事例 (seed_patterns) は中程度 granularity で致命級だけのレイヤ未提供、価値高 + コスト低
   - 反映先: §2 Layer 1 + §9 Quota

2. **impact_score** (Chappy 課題 7, P0)
   - 既存 severity (CRITICAL/ERROR/WARN/INFO) を 3 軸 (severity / fix_cost / downstream_effect) に拡張
   - post-run JSONL schema (dr-log) に追加、analysis 用 metric
   - 採用根拠: 件数 metric では「事故防止価値」が見えず ROI 説明力が弱い
   - 反映先: §9 Quota measurement

3. **forced divergence** (Chappy 課題 5、P1 → P0 格上げ)
   - adversarial subagent prompt template に 1 行追加
   - 微調整版文言案: 「primary reviewer の暗黙前提を 1 つ identify し、別の妥当な代替前提に置換した場合に同じ結論が成立するか評価せよ」(spec 検討時に最終確定)
   - 採用根拠: Spec 3 disagreement 2/24 は bias 共有疑念への反証と総括したが「収束しすぎ警告」という別解釈も妥当 = 直接対策。コスト極低 (prompt 1 行)
   - 反映先: §8 subagent + §9 Quota

### 保留 (Phase B-2 以降検討) — 3 件

1. **hypothesis generator role 3 体構成** (Chappy 課題 4)
   - 配置: Phase B-2 並列 multi-subagent (§8) と統合検討
   - 役割: 「設計が満たしていない隠れ要件を推定」「failure シナリオ生成」
   - 保留根拠: MVP には不要、Phase B-2 multi-vendor 試験と同時導入が効率的

2. **意味レビュー層** (Chappy 課題 11)
   - 配置: Phase C 以降 (Chappy P3 と一致)
   - 関連: requirements_extension R-1 (user 意図確認) が部分カバー
   - 保留根拠: 規模大 (intent → requirement → design 関手チェック)、研究テーマ性

3. **Layer 境界明確化** (Chappy 課題 9)
   - 圏論的整理 (モルフィズム / ファンクタ / オブジェクト) は overengineering、却下
   - 代替: 実装用語 (transformer / specialization / instance) で境界明示、Phase A 文書化作業に含める
   - 保留根拠: 概念整理は価値あるが実装直結性が低い

### 却下 (恒久的除外、再提案抑止) — 3 件

将来 conversation で再提案された際の re-derive を抑止するため、根拠を明記。

1. **リスク駆動 Adaptive Rounds** (Chappy 課題 1)
   - 却下根拠: §9 で Tier 比率 pre-run target setting を **Goodhart's Law 回避** で意図的削除済 = 同根拠で「リスクスコア事前重み付け」も LLM の pre-run target 化 = 自己充足的 bias を生む。「security_risk が高い → R7 を重視 → R7 で多く検出 → やはり security_risk が高い」の confirmation loop
   - 代替実装: post-run severity_re_evaluation (§6 整合性 Round 6 task の 6 番目) が事後に重み付け = 同等効果を bias なしで実現

2. **escalate 確率モデル化 (P(escalate|context) > θ)** (Chappy 課題 3)
   - 却下根拠: §4 cycle (Run-Log-Analyze-Update) で経験則更新は組込済。確率モデル化は LLM が「閾値以下なら escalate しない」という新たな bias 源 = 「過去 escalate 後に修正された割合」を学習対象にすると、修正されにくい指摘 (controversial だが致命的な指摘) を escalate しない方向に学習が偏る
   - 代替実装: 5 条件は静的だが human escalate 必須 (§9 Quota) = bias 学習を排除しつつ知見蓄積は cycle で対応

3. **並列レビュー収束関数 (Δ monotonic decrease)** (Chappy 課題 10)
   - 却下根拠: §6 = 派生 Round 再実行上限 3 回 + fall back trigger 5 条件 + Spec 3 evidence 95%+ 収束 = 経験的に対応済。数学的保証 (monotonic decrease) は理想だが「unresolved_issues + conflicts」を関数化する際の定義 (どれが unresolved か) 自体が判定不能多数を含む = 自己参照ループ
   - 将来余地: Phase C 以降に formal verification 候補

### 反映タイミング

- memory 追記 (本セクション): 即時
- design.md 反映 (P0 採用 3 件): dual-reviewer spec 検討 (`/kiro-spec-design`) 時
- 却下根拠の seed_patterns.yaml への retrofit: Phase A 文書化作業

## 13. Phase A 細分化 + A-3 統合判断 (2026-04-29 続論)

Chappy review 後の続論で、Phase A の細分化と Phase A 範囲縮小を確定。Spec 6 ペンディングは「dual-reviewer 開発期間中の一時停止 + dual-reviewer 動作後に dogfeeding 場として Spec 6 を実施」と再定義。

### Phase A 細分化 (A-0 / A-1 / A-2)

- **A-0 (spec 策定)**: `.kiro/specs/dual-reviewer/` で req → design → tasks 策定。memory §1-12 確定事項 + Chappy P0 3 件を design.md に転写。終端条件 = tasks.md approve。Spec 6 はペンディング維持。
- **A-1 (prototype 実装)**: prototype = B-1.0 minimum 相当 = `dr-init` + `dr-design` + `dr-log` の **3 skills のみ** (残り 7 skills は B-1.x 段階追加、#2 採用)。Chappy P0 3 件全件 (`fatal_patterns.yaml` / impact_score 3 軸 / forced divergence) + 23 事例 retrofit (`seed_patterns.yaml`、Rwiki 固有名詞付きで OK、generalization は Phase B-1.0 release prep)。終端条件 = Spec 6 design に適用可能なレベルで動作確認。Spec 6 ペンディング維持。
- **A-2 (Spec 6 dogfeeding)**: prototype を Spec 6 (rwiki-v2-perspective-generation) design に適用、Round 1-10 完走。metrics 取得 = 致命級発見再現性 / disagreement 率 (forced divergence 効果) / Phase 1 同型 hit rate / impact_score 分布 / fatal_patterns 強制照合効果。終端条件 = Spec 6 design approve **同時に** Phase B fork go/hold 判断。Spec 6 ペンディング解除 = Rwiki v2 design phase 全 8 spec approve 完了。

### prototype 範囲縮小 (#2 採用)

prototype = 3 skills minimum (`dr-init` + `dr-design` + `dr-log`)、残り 7 skills (`dr-tasks` / `dr-requirements` / `dr-impl` / `dr-extract` / `dr-validate` / `dr-update` / `dr-translate`) は B-1.x 段階追加。

採用根拠: memory §3 MVP scope = design phase release と整合。Phase A で 6 dr-* 全部実装は overengineering、minimum で運用試験 → 機能拡張は dogfeeding 後の B-1.x で十分。

反映先: §3 MVP scope (A-0 開始後 §1 / §11 と一括反映)

### A-3 統合判断 (#3 採用)

元想定の A-3 (固有名詞除去 / npm package 化準備 / multi-language) を **Phase B-1.0 release prep に統合**。Phase A 内で generalization 作業を閉じる必要なし。

採用根拠: A-2 完了 = Phase A 終了 = 即 Phase B-1.0 release prep に移行が直接的。Phase A 内に B-1.0 の準備作業を抱える必要なし。

反映先: §1 Phase B 行 (A-0 開始後 §1 / §11 と一括反映)

### memory §1 / §11 修正のタイミング (2026-04-29 続論で前倒し → 反映完了)

user 指示変更: ドラフト作成前に §1 / §11 を先に修正する判断 (2026-04-29 続論)。本セクション §13 で確定した判断を §1 / §11 に反映完了:

- §1 = Phase A 細分化 (A-0/A-1/A-2) + Phase B 内段階 (B-1.0 / B-1.x / B-2 / B-3) + Phase B fork timing 判断基準に Chappy P0 効果評価追加 + 用語衝突注記 (subagent 構成段階 B-1/B-2/B-3 と release lifecycle B-1.x の同期関係)
- §11 = A-0 / A-1 / A-2 / Phase B-1.0 release prep (元 A-3 統合) の 4 段階に細分化、各段階の implementation TODO を具体化

## 14. 論文化軸 + 拡張ログ schema (2026-04-29 後段議論)

dual-reviewer の **二重位置付け** + 拡張ログ schema を確定。`docs/ログサンプル.md` (Chappy との論文化議論) を反映。

### dual-reviewer の二重位置付け

- **主軸 (プロダクト)**: 設計レビュー方法論パッケージ
- **副産物 (研究)**: LLM レビューバイアスの観測装置

user 方針: **プロダクトが主、論文は副産物**。論文化のため別実験せず、日々の開発をそのまま実験化 (二重ループ構造 = 開発ループと研究ループが同 JSONL log を参照)。論文 timing = 8 月ドラフト提出。

### 主張のアップグレード版

「LLM は批判的推論フレームワークを知識として保持していても、それを自己推論に適用する機構を持たない = 構造的見落とし発生 = 外部化 adversarial 構造が必要」。LLM の問題は **制御フローの欠如**、dual-reviewer = 制御フローを外付け。LLM を「賢くする」研究ではなく「壊れにくくする」研究。

### 拡張ログ schema (B-1.0 + B-1.x、impact_score とは直交軸)

#### B-1.0 採用 3 要素 (軽量 enum / boolean、B-1.0 minimum 同梱)

1. **`miss_type`** (finding ラベル、6 種 enum): `implicit_assumption` / `boundary_leakage` / `spec_implementation_gap` / `failure_mode_missing` / `security_oversight` / `consistency_overconfidence` (論文核心)
2. **`difference_type`** (adversarial 拾い分のラベル、6 種 enum): `assumption_shift` (adversarial 本質) / `perspective_divergence` / `constraint_activation` / `scope_expansion` / `adversarial_trigger` / `reasoning_depth`
3. **`trigger_state`** (review_case フラグ、3 軸 boolean、論文核心): `negative_check: applied | skipped` / `escalate_check: applied | skipped` / `alternative_considered: applied | skipped`

論文 figure 候補 (B-1.0 で取得可能、quantitative evidence):

- figure 1: miss_type 分布
- figure 2: difference_type 分布 + forced divergence 効果
- figure 3: trigger 発動率 (skipped 頻出 = 制御フロー外付け効果裏付け)

#### B-1.x 採用 3 要素 (自由記述 + 内省、B-1.x 段階追加)

1. **`decision_path`** (思考分岐軌跡): observation → immediate_judgment → action
2. **`skipped_alternatives`** (考えなかった代替案、subagent 後段問い直しで取得)
3. **`bias_signal`** (bias パターンタグ、5-10 種 enum、初期セットは Phase A dogfeeding から経験的抽出)

論文 figure 候補 (B-1.x で取得、qualitative evidence):

- figure 4: failure pipeline (decision_path 図、Spec 3 self-diagnosis ログ再構成)
- figure 5: bias_signal 頻度 + skipped_alternatives 例示

#### B-1.0 vs B-1.x 切り分け根拠 (3 点)

1. LLM 自己ラベリング難易度: B-1.0 (enum / boolean = 認知負荷低) vs B-1.x (自由記述 + 内省 = 認知負荷高)
2. 論文 evidence 階層: B-1.0 quantitative (figure 1-3) → B-1.x qualitative (figure 4-5)
3. 8 月 timeline: Phase 2 (6-7月、A-2) で B-1.0 + 対照実験 → Phase 3 (7-8月) で B-1.x 追加 + 論文ドラフト

### A-2 対照実験 (#C 採用、全 Round 2 倍)

A-2 期間に Spec 6 全 Round (1-10) を **single reviewer (Opus のみ) + dual reviewer の対照実験** で完走 (cost 倍、論文用比較データ):

- 比較指標: adversarial 追加検出率 / miss_type 別検出率 / impact_score 別検出率 / trigger_state skipped 率
- single 版でも miss_type / difference_type / trigger_state を記録 = single の trigger failure 率と dual の比較で adversarial 効果を定量化

### 論文化ロードマップ (8 月ドラフト提出向け)

- Phase 1 仕込み (今〜6月): A-0 (spec 策定) + A-1 (prototype 実装、B-1.0 schema 含む)
- Phase 2 溜め (6-7月): A-2 (Spec 6 dogfeeding + 対照実験) で quantitative evidence 取得
- Phase 3 書き (7-8月): A-2 後半に B-1.x 段階追加 + case study 強化、論文ドラフト

### 反映先

- ドラフト §2.10 (論文化軸 + 拡張ログ schema)
- ドラフト §3.1 A-2 (対照実験追記)
- ドラフト §3.5 (8 月ロードマップ)
- ドラフト §4.6 (B-1.0 拡張 schema 同梱)
- §1 / §11 = A-2 部分のみ局所修正 (対照実験追記、本セクション §14 が判断根拠)
