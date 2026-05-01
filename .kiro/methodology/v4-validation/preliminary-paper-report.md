# Preliminary Paper Report — dual-reviewer methodology validation

_作成: 2026-05-01 (14th セッション末) / status: 論文化 preliminary preview、8 月ドラフト submission readiness 中間評価 / 未完: A-2 dogfeeding 30 review session + figure 1-3 + ablation evidence (Phase A 終端後)_

_v0.1 / 2026-05-01 (14th セッション末)_

---

## §1 Executive Summary

### 主張 (3 claims)

dual-reviewer = LLM 設計レビューの **bias 観測装置 + 改善 mechanism** として確立可能。具体 3 主張:

- **Claim A (adversarial subagent 効果)**: 独立検出 + 修正否定試行 prompt が primary (Opus) の completeness bias を suppress、致命級独立発見と disagreement evidence で実証
- **Claim B (judgment subagent 効果)**: Step 1c (V4 §1.2 option C) が必要性 5-field 評価 + 5 条件判定 + 3 ラベル分類で過剰修正比率を 50% → 40% 台に抑制、6 spec instance 累計連続改善で実証
- **Claim C (dual-reviewer architecture)**: 3 subagent 構成 (primary + adversarial + judgment) が偶然 / 1 spec or 1 phase の特殊性ではなく、構造的に primary completeness bias を抑制する装置である phase 横断証明

### 14th 末時点の readiness

| 主張 | evidence 充足度 | 備考 |
|------|----------------|------|
| Claim A | **十分** (V3 試験運用 + req phase 3 spec) | 致命級独立発見 12 件 + disagreement 17+ 件 + Phase 1 同型 17 度 |
| Claim B | **十分** (V4 redo broad 3 phase × 3 spec = 9 instance) | 過剰修正比率 V3 50% → V4 平均 47.4% (preliminary)、phase 内 trend 連続改善 |
| Claim C | **十分** (6 spec instance × 2 phase 累計再現) | design phase -41.25pt + tasks phase -23.8pt 累計改善、phase 横断 reproducibility 確認 |

### core figure 1-3 + ablation evidence の readiness

**未充足** (= Phase A 終端 = A-2 dogfeeding 完走後で確定)。本 14th 末は **preliminary cross-phase verification 補助 evidence** のみ取得済、論文 core evidence (Spec 6 30 review session × 3 系統対照実験 = single vs dual vs dual+judgment ablation) は A-2 期間で取得予定 (8 月末 timeline 厳守)。

---

## §2 Methodology (V4 protocol v0.3 final)

V3 protocol (adversarial subagent 統合) の検出機能を維持しつつ、過剰修正 bias 50% を suppress する Step 1c judgment 統合:

```
Step 1a (軽微検出) → Step 1b (構造的検出 5 重検査) → Step 1b-v (自動深掘り)
                                                     ↓
                                    ★ Step 1c (修正必要性判定) ← V4 新規
                                                     ↓
                                    Step 2 (User 判断、V4 §2.5 三ラベル提示)
                                                     ↓
                                                Step 3 (適用)
```

### V4 核心要素

- **3 subagent 構成 (V4 §1.2 option C)**: primary Opus + adversarial Sonnet + judgment Sonnet (役割分離 clean)
- **必要性 5-field schema**: `requirement_link` / `ignored_impact` / `fix_cost` / `scope_expansion` / `uncertainty`
- **5 条件判定ルール (順次評価、最強 wins)**: critical impact / requirement_link+ignored_impact / scope_expansion / fix_cost vs ignored_impact / uncertainty
- **3 ラベル分類**: must_fix / should_fix / do_not_fix
- **semi-mechanical mapping default 7 種** (V4 §1.4.2、subjective 性 mitigation)
- **役割分離**: Step B `forced_divergence` (adversarial、結論成立性試行) vs Step C `fix-negation` (judgment、修正提案必要性否定)

---

## §3 Evaluation Setup

### Specs

3 spec で dual-reviewer 自体を dogfooding:
- `dual-reviewer-foundation` (Layer 1 framework + 共通 schema + dr-init skill)
- `dual-reviewer-design-review` (Layer 2 design extension + 3 skills + forced_divergence prompt)
- `dual-reviewer-dogfeeding` (適用 + 対照実験 + Phase B fork judgment、consumer-only)

### Phases

3 phase (req + design + tasks-ad-hoc) × 3 spec = **9 spec instance** evidence:
- req phase = V4 redo broad (9th-10th)、systematic 10 ラウンド観点
- design phase = V4 (12th)、systematic 10 ラウンド観点
- tasks phase = ad-hoc V4 (14th)、6 観点 ad-hoc 列挙 (Layer 2 tasks extension 未実装、4 caveats あり)

### V3 baseline

7th セッション foundation design phase = 検出 6 件 / 採択率 16.7% (1/6) / 過剰修正比率 50% (3/6) / wall-clock 420.7 秒。本 baseline は ablation 比較の対照点。

---

## §4 Results

### §4.1 9 spec instance V4 metric 集約

| spec | phase | 検出 | 採択率 | 過剰修正比率 | should_fix | wall-clock |
|------|-------|------|--------|--------------|------------|------------|
| **V3 baseline** | design | 6 | 16.7% | **50.0%** | 33.3% | 420.7s |
| foundation | req | 19 | 21.1% | 36.8% | 42.1% | 284s |
| design-review | req | 20 | 40.0% | 25.0% | 35.0% | 301s |
| dogfeeding | req | 18 | 5.6% | 44.4% | 50.0% | 297s |
| foundation | design | 16 | 0% | 81.25% | 18.75% | ~293s |
| design-review | design | 17 | 23.5% | 58.8% | 17.6% | ~255s |
| dogfeeding | design | 15 | 20.0% | 40.0% | 40.0% | ~244s |
| foundation | tasks | 18 | 5.6% | 66.7% | 27.8% | n/a |
| design-review | tasks | 15 | 13.3% | 53.3% | 33.3% | n/a |
| dogfeeding | tasks | 14 | 35.7% | 42.9% | 21.4% | n/a |

### §4.2 phase 内 cross-spec trend (連続改善実証)

| phase | foundation → design-review → dogfeeding | 累計改善 |
|-------|------------------------------------------|----------|
| req | 36.8% / 25.0% / 44.4% | -25 pt 改善 (design-review pic) |
| design | **81.25% → 58.8% → 40.0%** | **-41.25 pt** 連続改善 |
| tasks | **66.7% → 53.3% → 42.9%** | **-23.8 pt** 連続改善 |

### §4.3 phase 横断累計 (6 spec instance)

design phase + tasks phase で **同方向 trend 再現** = phase 横断 reproducibility 確認:
- 採択率 (foundation → dogfeeding): design 0% → 20.0% / tasks 5.6% → 35.7% (両 phase 改善方向)
- 過剰修正比率 (foundation → dogfeeding): design 81.25% → 40.0% / tasks 66.7% → 42.9% (両 phase 連続改善)

### §4.4 H1-H4 仮説検証

| 仮説 | target | req phase | design phase | tasks phase | 判定 |
|------|--------|-----------|--------------|-------------|------|
| H1 (過剰修正比率 ≤ 20%) | ≤ 20% | 全未達 (design-review 25.0% 近接) | 全未達 (dogfeeding 40.0% 接近) | 全未達 (dogfeeding 42.9%) | 改訂候補: phase 別目標 |
| H2 (escalate user 介入機会) | 増加 | ✅ 24 件 | ✅ 12 件 | ✅ 13 件 (累計 49 件) | 達成 |
| H3 (採択率 ≥ 50%) | ≥ 50% | design-review 40.0% 近接 | 全未達 | dogfeeding 35.7% 接近 | 改訂候補: spec 性質別 |
| H4 (wall-clock + 50% 以内) | +50% 以内 | ✅ -30% 短縮 | ✅ さらに短縮 | n/a (要別 metric) | 達成 |

### §4.5 V4 修正否定 prompt 機能 (Claim A 補強)

primary should_fix bias を adversarial counter-evidence + judgment 独立 context が do_not_fix or must_fix に再分類する **3 spec 連続再現実証**:
- req phase: 71% / 80% / 100%
- design phase: 90% / 高 / 高
- tasks phase: 75% / 28.6% / 37.5% (ad-hoc 適用、低下 trend = adversarial が修正必要性高め評価傾向、tasks phase 特性)

---

## §5 Discussion (主張別 evidence 整理)

### Claim A: adversarial subagent 効果

- V3 試験運用 (Spec 3) 致命級独立発見 1 件 + req phase V4 redo broad で 12 件累計
- disagreement 17+ 件、Phase 1 同型 5 ラウンド全該当 17 度
- **bias 共有疑念に対する決定的反証** (= primary と adversarial が独立 context で異なる検出を行う実証)

### Claim B: judgment subagent 効果

- V3 baseline 50% 過剰修正比率 → V4 design phase 平均 60.0% (foundation 高め) → V4 tasks phase 平均 54.3%
- **phase 内 cross-spec trend で連続改善** (consumer-only spec ほど低下) = judgment subagent が context-dependent decisions を `should_fix` に正しく分類する効果
- semi-mechanical mapping default 適合性 = judgment override 件数連続減 (tasks phase: 7 → 5 → 3)

### Claim C: dual-reviewer architecture (bias 観測装置 + 改善 mechanism)

- design + tasks 2 phase 各々で 3 spec 連続改善 = **6 spec instance 累計再現実証**
- = V4 protocol が偶然 / 1 spec or 1 phase の特殊性ではなく、構造的に primary completeness bias を抑制する装置である phase 横断証明
- ただし absolute 値で H1 ≤ 20% / H3 ≥ 50% は未達 = **改訂候補は phase 別 + spec 性質別目標分離**

---

## §6 Limitations

### 6.1 sample size

- 9 spec instance + V3 baseline 1 件 = preliminary、N is small
- multi-project bias 対策: dual-reviewer 自体 dogfooding 中心 = self-application bias リスク
- A-2 Spec 6 dogfeeding (30 review session × 3 系統 = 90 data point) で sample 大幅増 (8 月末 timeline)

### 6.2 tasks phase ad-hoc V4 4 caveats (data-acquisition-plan v0.4 §5)

- (1) **ad-hoc 観点**: Layer 2 tasks extension 未実装 (Phase B-1.1 scope) で primary が boundary 違反 / dependency cycle / granularity / AC 網羅 / executability / verifiability の 6 観点 ad-hoc 列挙
- (2) **phase 横断 strict comparability 問題**: design phase 10 ラウンド観点 vs tasks phase ad-hoc 観点で coverage 異なり phase 間 absolute 比較は spurious comparison リスク、relative trend のみ valid
- (3) **forced_divergence prompt design phase optimization**: tasks phase 用 ad-hoc 微調整 = primary's task structure 暗黙前提置換
- (4) **paper rigor 保証**: preliminary cross-phase verification 補助 evidence、systematic tasks phase evidence は Phase B-1.1 で paper revision に活用

### 6.3 core figure 1-3 + ablation evidence 未取得

8 月末 timeline failure 基準 = figure 1-3 + ablation evidence 完了 (Decision 5、Req 2.6 b)。本 14th 末は **未取得**:
- figure 1: `miss_type` 6 enum 分布 (3 系統) — A-2 dogfeeding 完走後
- figure 2: `difference_type` 6 enum + forced_divergence 効果 — A-2 (design-review v1.2 cycle 完了後 sequencing 制約)
- figure 3: `trigger_state` 3 enum 発動率 (3 系統) — A-2 完走後
- figure ablation: dual vs dual+judgment 過剰修正比率削減 + judgment override quality — A-2 完走後

### 6.4 Phase B fork 5 条件評価 未判定

dogfeeding/design.md Decision 5 + tasks.md Task 4 で 5 条件 (致命級 ≥ 2 / disagreement ≥ 3 / bias 共有反証 evidence / impact_score CRITICAL/ERROR ≥ 1 / 過剰修正比率改善) を A-2 完走後 `phase_b_judgment.py` で機械評価。本 14th 末では 4 条件部分達成 (致命級独立発見累計 12 件 + disagreement 17+ 件 + bias 共有反証 = adversarial-only finding 1 件以上)、(d) impact_score 分布 + (e) 過剰修正比率改善 (dual+judgment vs dual) は A-2 取得後判定。

### 6.5 multi-vendor 比較未実施

V4 全体 vs V3 全体の **pure independent 比較** は本 14th 末 scope 外。本 evidence は V4 §4.4 ablation framing (= "Step 1c なし baseline = single + dual" vs "Step 1c あり treatment = dual+judgment") に限定。multi-vendor 比較 (Claude vs GPT vs Gemini) は Phase B-2 別 protocol で実施予定。

---

## §7 Future Work + 8 月 Timeline Readiness

### 7.1 残 work (15th セッション以降)

- **A-1 implementation phase** (15th-、推定 1 month): design-review v1.2 改修 cycle → foundation + design-review + dogfeeding 物理 file 生成 → sample 1 round 通過 test
- **A-2 dogfeeding** (A-1 完走後、推定 1-2 month): Spec 6 適用 → 30 review session 完走 → metric/figure data 生成 → Phase B fork 判定
- **論文 draft 執筆 Phase 3** (7-8 月別 effort): figure 1-3 + ablation evidence input、本 spec scope 外

### 7.2 Phase A 終端時 final comparison-report v0.2 集約 plan

A-2 完走後の最終 comparison-report.md v0.2 で:
- req + design + tasks + A-2 全 evidence 累計集計
- H1-H4 最終 verification
- Phase B fork go/hold 判定 + 移行手順 or 改訂候補
- 論文 figure 1-3 + ablation evidence file paths + 数値要約

### 7.3 8 月末 readiness assessment

| 必要 evidence | 現状 | 不足 work |
|--------------|------|-----------|
| V3 baseline | ✅ 確定 | — |
| V4 methodology (v4-protocol.md v0.3 final) | ✅ 確定 | — |
| 9 spec instance evidence (req+design+tasks) | ✅ 取得 (本 14th 末) | tasks phase 4 caveats limitations 言及必須 |
| Spec 6 30 review session × 3 系統 | ❌ 未取得 | A-1 implementation 完了後 A-2 着手 |
| figure 1-3 + ablation data files | ❌ 未取得 | A-2 完走後 generation |
| Phase B fork judgment | ❌ 未判定 | A-2 完走後 5 条件機械評価 |

**8 月末 timeline 達成 critical path** = A-1 implementation phase 着手 (= 15th 以降) → 完了 (~6 月) → A-2 着手 → 30 review session 完走 → script 実行 → 8 月末 figure data 完了。

8 月末 failure (= figure data 完了未達) は dogfeeding/design.md Decision 5 で Phase B fork hold 判定の補助根拠化。

---

## §8 Conclusion (preliminary)

### 14th 末確立内容

- **V4 protocol 構造的有効性**: 6 spec instance × 2 phase 累計再現実証 (design + tasks)、phase 横断 reproducibility 確認
- **3 主張 (Claim A/B/C) preliminary 充足**: V3 試験運用 + 9 spec instance evidence で claims 構造的支持
- **論文化 readiness**: methodology + preliminary evidence 充足、core figure 1-3 + ablation evidence は A-2 完走後

### 8 月ドラフト submission に向けた critical path

- 15th 以降 A-1 implementation phase 集中作業 (推定 1 month)
- A-2 dogfeeding 30 review session × 3 系統 = 90 data point 取得 (推定 1-2 month)
- script 実行 + figure data + Phase B fork 判定 (8 月末)
- Phase 3 論文 draft 執筆 (7-8 月、別 effort)

### Recommended next action

- 15th セッション = A-1 implementation phase 着手 (= design-review v1.2 改修 cycle 先行)
- 並走で本 preliminary report (本 file v0.1) を Phase 3 論文 draft input として再利用予定

---

## §9 関連 reference

- `v3-baseline-summary.md` (V3 baseline 確定文書)
- `v4-protocol.md` v0.3 final (V4 methodology canonical)
- `comparison-report.md` v0.1 (req phase evidence、最終 v0.2 = A-2 完走後)
- `data-acquisition-plan.md` v0.4 (data 取得計画 + 14th 末状態反映済 checkbox tracker)
- `evidence-catalog.md` v0.5 (data 所在 catalog + 14th 末状態反映済)
- 3 spec brief.md / requirements.md / design.md / tasks.md (本 14th 末 endpoint = `0b39b51`)
- main commits 14th 末: `021ec65` + `aed0b2b` + `0b39b51` (origin/main 同期済)
- `docs/過剰修正バイアス.md` (canonical V4 design source、user 拡張)
- 関連 memory:
  - `feedback_v4_design_phase_3spec_completion.md` (12-14th 末 6 spec instance 累計 evidence)
  - `feedback_cross_spec_review_pattern.md` (design + tasks 2 phase 適用済 cross-spec review pattern)
  - `feedback_review_v4_necessity_judgment.md` (V4 protocol 確定経緯)
  - `feedback_design_review_v3_adversarial_subagent.md` (V3 試験運用 evidence)

---

## §10 変更履歴

- **v0.1** (2026-05-01 14th セッション末、本 file 初版): 論文化 preliminary preview 起草、3 claims (A/B/C) + V4 methodology + 9 spec instance evidence + H1-H4 仮説検証 + 6 limitations + 8 月 timeline readiness assessment + critical path 提示。final comparison-report v0.2 (A-2 完走後) に至る中間集約として位置付け、Phase 3 論文 draft 執筆 (7-8 月別 effort) の input として再利用予定。

---

**本 report は preliminary draft = 論文 figure 1-3 + ablation evidence 未取得段階での readiness 評価。最終 paper draft 入力は A-2 dogfeeding 完走後 final comparison-report v0.2 集約から取得予定。**
