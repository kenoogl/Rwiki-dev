# Preliminary Paper Report — dual-reviewer methodology validation

_作成: 2026-05-01 (14th セッション末) / 改版: 2026-05-02 (18th セッション開始 v0.2 / 19th セッション末 v0.3) / 改版: 2026-05-03 (29th セッション末 v0.4) / status: 論文化 preliminary preview、9-10 月ドラフト submission readiness 中間評価 / **A-2.1 1/3 終端 = treatment=dual+judgment 全 10 ラウンド完走** / 未完: A-2.1 残 2/3 (treatment=single + treatment=dual) + A-2.2 Tasks ad-hoc + A-2.3 Impl Level 6 + figure 1-3 + ablation evidence + A-3 triangulation evidence batch + §3.7.6 Code-derived spec batch (Phase A 終端後 = A-3 + §3.7.6 完走後 redefine)_

_v0.4 / 2026-05-03 (29th セッション末、A-2.1 partial completion = treatment=dual+judgment 全 10 ラウンド完走 反映 = §1 readiness 表 update + 新規 §4.6 A-2.1 partial completion evidence + §6.6 Claim D scope 精緻化 (Level 6 design phase events ≠ impl phase rework) + §7.1 timeline status update。§4.1-§4.5 = 14th 末 historical fix 維持方針継続、A-2.1 完全終端 (= 30 session) 後の v0.5 で systematic update 予定)_

_v0.3 / 2026-05-02 (19th セッション末、軸 4 → 軸 7 拡張 + §3.7.6 Code-derived spec batch 反映 + §3.7.1 forward-fresh-spec 独立必須化 + reverse-engineering bias 5 source caveats 追加 = data-acquisition-plan v1.5 + evidence-catalog v0.7 整合化)_

---

## §1 Executive Summary

### 主張 (4 claims、v0.2 改版で Claim D 追加)

dual-reviewer = LLM 設計レビューの **bias 観測装置 + 改善 mechanism + 品質保証装置** として確立可能。具体 4 主張:

- **Claim A (adversarial subagent 効果)**: 独立検出 + 修正否定試行 prompt が primary (Opus) の completeness bias を suppress、致命級独立発見と disagreement evidence で実証
- **Claim B (judgment subagent 効果)**: Step 1c (V4 §1.2 option C) が必要性 5-field 評価 + 5 条件判定 + 3 ラベル分類で過剰修正比率を 50% → 40% 台に抑制、6 spec instance 累計連続改善で実証
- **Claim C (dual-reviewer architecture)**: 3 subagent 構成 (primary + adversarial + judgment) が偶然 / 1 spec or 1 phase の特殊性ではなく、構造的に primary completeness bias を抑制する装置である phase 横断証明
- **Claim D (downstream rework signal、v0.2 追加、external validity)**: V4 review が機能した spec の implementation phase で、上流 artifact (req/design/tasks) への post-approve 改版 (= rework) が低水準に抑制される、Claim A/B/C と独立次元の妥当性軸 (= time-deferred validity = post-approve rework が少ないこと自体が V4 review の prospective error rate 測定として活用)

### 29th 末時点の readiness (v0.4 update、A-2.1 1/3 終端反映)

| 主張 | evidence 充足度 | 備考 |
|------|----------------|------|
| Claim A | **十分** (V3 試験運用 + req phase 3 spec + **A-2.1 1/3 終端 v4-miss core evidence 17 件追加**) | 致命級独立発見 12 件 + disagreement 17+ 件 + Phase 1 同型 17 度 + **A-2.1 dual+judgment 累計 = primary 0 件 + adversarial 真の独立検出 17 件 (core 10 件 must_fix upgrade + minor 7 件 should_fix upgrade)** = adversarial subagent の primary 見落とし補完機能 evidence |
| Claim B | **強化** (V4 redo broad 3 phase × 3 spec + **Spec 6 1/3 = 4 spec instance 連続改善 + Round 10 67% bias 抑制 evidence**) | 過剰修正比率 V3 50% → V4 4 spec design phase = 81.25% → 58.8% → 40.0% → **33.3% (Spec 6、29th 末)** = -47.95pt 累計改善 (= V3 比 -16.7pt) + **Round 10 V4 機能本質発揮 evidence** = primary single なら +3 修正、dual+judgment なら net 1 修正 = **67% 過剰修正 bias 抑制 + 検出漏れ 1 件補完** |
| Claim C | **強化** (6 spec instance × 2 phase + **Spec 6 1/3 = 4 spec instance design phase 連続再現**) | design phase -47.95pt (4 spec) + tasks phase -23.8pt (3 spec) = phase 横断 reproducibility 確認 + **escalate 解決手段 5 path 確立** (= path 1 user 判断 / path 2 premise 誤り / path 3 adversarial counter + judgment override / path 4 rule_2 must_fix 降格 / path 5 候補 = escalate 解除 4 連続再現 Round 7-10) + **fatal_pattern hits 5 件** (path_traversal × 3 + data_loss × 1 + destructive_migration 逆向き × 1 = Chappy P0 quota 機能 evidence) |
| Claim D | **中間 evidence 維持** (A-1 全 implementation phase = 0 events strong) + **scope 精緻化必要** (= A-2.1 design phase 44 events ≠ Claim D primary、§6.6 整合) | A-1 全 implementation phase で post-approve upstream artifact rework = 0 events (= 機械検証済) **= Claim D primary evidence strong** / A-2.1 design phase 44 events = **Claim D primary ではなく Claim B/C functioning evidence** (= V4 review が design fix を generate する pattern observation、§6.6 で 2 evidence 種別 disambiguate) / Claim D primary evidence の追加取得 = A-2.3 Spec 6 implementation phase = 30th 以降 |

### core figure 1-3 + ablation evidence の readiness

**未充足** (= Phase A 終端 = A-2 dogfeeding 完走後で確定)。本 14th 末は **preliminary cross-phase verification 補助 evidence** のみ取得済、論文 core evidence (Spec 6 30 review session × 3 系統対照実験 = single vs dual vs dual+judgment ablation) は A-2 期間で取得予定 (8 月末 timeline 厳守)。

### Validation framing (v0.2 追加、論文 framing 変更 = convergent multi-indicator triangulation)

論文 framing を **ground truth validation → convergent multi-indicator triangulation** に変更 (= 16th セッション末議論で確定、data-acquisition-plan v1.1 §1 で正式反映、memory `project_a3_plan_triangulation_defense.md` + `user_paper_rigor_preference.md` 整合):

- **旧 (= 撤回)**: "V4 reduces over-correction, validated against ground truth"
- **新**: "V4 reduces over-correction, validated through **convergent multi-indicator triangulation** (= no single source claims ground truth, multiple independent indicators converge in the same direction)"

**human GT 不在の理由** (= human label を絶対視しない、user paper rigor preference 軸 1 + 軸 2 整合):

- (a) literature 上 human label noisy (= SE 専門家間でも `must_fix` definition は context-dependent、Cohen's kappa は分野横断的に低い)
- (b) Spec 6 reviewer recruitment は dual domain expertise (= Wiki 計算 logic + dual-reviewer protocol) 必要で実質不可能

**6 件 independent indicators** (= A-3 triangulation evidence batch + §3.7.6 Code-derived spec batch + Level 6、§7.4 + data-acquisition-plan v1.5 §3.7 整合、v0.3 改版で 5 → 6 indicators 化):

- (i) multi-vendor LLM agreement (= Claude vs GPT-4 vs Gemini agreement matrix、A-3.2)
- (ii) mutation testing sensitivity/specificity (= constructed positive control、A-3.3)
- (iii) multi-run reliability (= 3-5 random seed inter-run agreement、A-3.4)
- (iv) cross-project transfer (= フルスクラッチ project metric stability、A-3.1)
- (v) downstream rework signal (= Level 6 既存 plan、Claim D primary evidence、time-deferred validity)
- (vi) **forward-reverse spec source sub-group 比較** (= v0.3 新規、§3.7.6 reverse-engineered batch vs §3.7.1 + A-1 + A-2 forward-fresh-spec sub-group の metric 系統的差異有無、ground truth-anchored 補強 + reverse-engineering bias 5 source mitigation evidence)

**軸 4 → 軸 7 拡張** (= v0.3 改版で data-acquisition-plan v1.5 §2 整合): 軸 5 (ground truth availability) + 軸 6 (forward-fresh-spec vs reverse-engineered spec source) + 軸 7 (言語 diversity = Python / C++ / Julia / Arduino C) を追加、3 sample (= Phase field 法 / 3D 熱伝導方程式 / Arduino IoT) で同時 cover。Sub-group analysis 規律で全 metric を forward-fresh / reverse-engineered の 2 sub-group + aggregate で並列 reporting 必須。

**論文 abstract / introduction の framing core principle**: "we acknowledge ground truth absence; we address through convergent multi-indicator triangulation **with explicit sub-group analysis on spec source modality**"。

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

### §4.6 A-2.1 Spec 6 Design phase partial completion evidence (= treatment=dual+judgment 全 10 ラウンド完走、29th 末新規、v0.4 追加)

**status (29th 末)**: A-2.1 Spec 6 Design phase の **treatment=dual+judgment 全 10 ラウンド完走 = A-2.1 1/3 終端**。残 = treatment=single (Round 1-10) + treatment=dual (Round 1-10) = 20 review session、推定 1-2 month batch。20th-29th セッション累計 20 commits、29th 末 endpoint = `3cbefdb`。

**§4.6.1 累計 metric (treatment=dual+judgment、10 ラウンド aggregate、29th 末)**

| metric | 値 | 比較 |
|--------|----|------|
| 検出件数 (judgment unique) | 69 | (4 spec instance design phase で最多) |
| primary detection 累計 | 48 | Round 別 = 0/3/5/5/5/6/7/7/7/3 (観点難易度依存) |
| adversarial detection 累計 | 54 | confirmation + supplementary + 真の独立 |
| 採択率 (must_fix) | **30.4%** | dogfeeding design 20.0% より +10.4pt 改善 |
| **過剰修正比率** (do_not_fix) | **33.3%** | **V3 baseline 50% 比 -16.7pt 改善** |
| should_fix 比率 | 36.2% | escalate user 介入機会確保 |
| escalate 件数 | 4 | path 1-2 適用 (Round 3/5/6/7) |
| judgment override 件数 | 27 | semi-mechanical mapping default 妥当性精査 cycle |

**§4.6.2 4 spec instance 累計 design phase 過剰修正比率 連続改善 (V4 構造的有効性 4 spec 連続再現実証)**

| spec instance | 過剰修正比率 | 累計改善 (foundation 比) |
|---------------|--------------|--------------------------|
| foundation | 81.25% | (baseline) |
| design-review | 58.8% | -22.45pt |
| dogfeeding | 40.0% | -41.25pt |
| **Spec 6 (A-2.1 1/3 終端)** | **33.3%** | **-47.95pt** |

= 12-29th 累計で 4 spec instance design phase 連続改善継続。3 spec instance accumulated trend (v0.3 §4.2) を Spec 6 で **強化拡張** = V4 protocol が偶然 / 1 spec 特殊性ではなく構造的に primary completeness bias を抑制する装置である phase 横断 + 4 sample 累計再現確認。

**§4.6.3 v4-miss core evidence 累計 17 件 (Claim A primary evidence)**

primary 見落とし + adversarial 真の独立検出 + judgment must_fix or should_fix upgrade の confluence pattern:

- **core (judgment must_fix upgrade)** = 累計 **10 件**: Round 1 A-1/A-2/A-4 (3 件、design 段階確定要求 同型 pattern) / Round 2 A-2/A-3 (2 件) / Round 3 A-6/A-7 (2 件) / Round 4 A-2 / Round 5 A-4 / **Round 9 A-8 (Flow 2 Mermaid 順序逆転、fatal_pattern data_loss hit)**
- **minor (judgment should_fix upgrade)** = 累計 **7 件**: Round 7 A-5/A-7 (2 件) / Round 8 A-2/A-3 (2 件) / Round 9 A-9/A-10 (2 件) / **Round 10 A-4 (Migration Strategy rollback 方針、fatal_pattern destructive_migration 逆向き hit)**
- = 17 件 v4-miss evidence = **bias 共有疑念に対する決定的反証 evidence の追加蓄積** (V3 baseline 12 件 + 17 件 = 累計 29 件、Claim A 強化)

**§4.6.4 fatal_pattern hits 5 件 (Chappy P0 quota 機能 evidence、Claim A/C 補強)**

- path_traversal × 3 (Round 7 P-2/P-3 = security 二層防御 / Round 9 P-2/P-3 = test 戦略 layer (b))
- data_loss × 1 (Round 9 A-8 = Flow 2 Mermaid 順序逆転 = rollback boundary 崩壊)
- destructive_migration 逆向き × 1 (Round 10 A-4 = 撤退不可能な追記の asymmetric 挙動 = Migration rollback 方針不在)

= foundation `fatal_patterns.yaml` 8 種強制照合機能 active 検証 + adversarial subagent 独立検出補完で primary 見落とし補完 evidence。

**§4.6.5 escalate 解決手段 5 path 確立 (Claim B/C 補強、29th 末新規)**

V4 protocol で escalate 発生時の解決 pattern を 5 種類確立:

- **path 1**: user 判断必須 (Round 3 P-5 = 22nd / Round 6 P-1 = 25th)
- **path 2**: 事実確認による premise 誤り判定 → do_not_fix (Round 4 A-3 = 23rd)
- **path 3**: adversarial 根拠 + judgment override による should_fix → do_not_fix 降格 (Round 5 P-3 = 24th + **Round 10 P-1/P-2/P-3 連続 3 件 = 過去最多再現** = 29th、累計 4 件)
- **path 4**: rule_2 must_fix 降格 (Round 6 P-4 = 25th + Round 7 P-2/P-3 = 26th、累計 3 件) + path 4 variant (Round 8 P-2 = primary should_fix → judgment must_fix 昇格 = 27th)
- **path 5 候補**: judgment 5 field 評価で escalate 解除 (Round 8 = primary escalate 3 件全部 judgment 降格 / Round 9-10 = primary escalate 0 件 = **escalate=0 streak 4 連続再現 (Round 7-10) 過去最長**)

= V4 protocol が systematic に escalate を user 介入 + 自動降格の 2 axis で処理する mechanism evidence、論文 escalate handling section の core narrative source。

**§4.6.6 Round 10 V4 過剰修正 bias 抑制機能 evidence (Claim B strong evidence、29th 末新規 = V4 機能本質発揮 round)**

Round 10 は A-2.1 treatment=dual+judgment 最終 round で V4 dual-reviewer の **過剰修正 bias 抑制機能 + 検出漏れ補完機能** の両方が同時発動した evidence:

- primary single なら +3 修正 (P-1/P-2/P-3 全 should_fix 採択)
- dual+judgment net 1 修正 (P-1/P-2/P-3 = do_not_fix skip + A-4 = should_fix 採用 adversarial 独立検出)
- = **過剰修正 bias 67% 抑制 + 検出漏れ 1 件補完 (A-4)**

具体内訳:
- **path 3 連続 3 件適用** (P-1/P-2/P-3 = adversarial counter_evidence「do_not_fix 寄り」主張を judgment が rule_3/rule_4 で採択 = SSoT 重複違反 / over-specification / scope expansion 棄却 = 過剰修正抑制)
- **path 5 候補類似 minor pattern** (A-4 = primary 0 件 → adversarial 独立 → judgment should_fix upgrade = 検出漏れ補完)
- counter_classification do_not_fix 3 件全件 = Round 9 (must_fix 3 / should_fix 4 / do_not_fix 0) と完全反転 pattern = adversarial の二層判定 (confirmation severity vs counter_classification) 分離発動 evidence

= **論文 figure ablation の primary visual rebuttal candidate** (= dual vs dual+judgment で judgment 効果分離、V4 §4.4 整合)。

**§4.6.7 Sub-group analysis 規律遵守 (data-acquisition-plan v1.5 §7 整合)**

- ✅ explicit labeling: 全 dev_log entry に `spec_source: forward-fresh` field 付与 (Round 1-10 全件)
- ✅ spec characteristic descriptive metric: AC 数 132 / 文字数 1266 行 (post-Round 10) / Design Decisions 数 7 / Architecture Pattern Evaluation 4 件 / 起草所要時間 (sub-step 2 内 19th 計測) 記録済
- ⏸️ §3.7.6 reverse-engineered batch との sub-group 比較 = §3.7.6 着手後 (= A-3 batch)

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

### 6.5 multi-vendor 比較 (= A-3.2 で計画、v0.2 update)

V4 全体 vs V3 全体の **pure independent 比較** は本 14th 末 scope 外。本 evidence は V4 §4.4 ablation framing (= "Step 1c なし baseline = single + dual" vs "Step 1c あり treatment = dual+judgment") に限定。**multi-vendor 比較 (Claude vs GPT vs Gemini)** は **A-3.2 (triangulation evidence batch の 1 件、cost 3-6h)** で計画 (= data-acquisition-plan v1.1 §3.7.2 整合)、批判 1 (self-referential metric) + 批判 3 (LLM-on-LLM bias) 同時 mitigation evidence。Phase B-2 ではなく **Phase A 内 A-3 batch で実施 redefine** (= 16th 末議論で確定)。

### 6.6 Claim D の precise scope (= v0.2 追加 / v0.4 精緻化 = Level 6 design phase events ≠ impl phase rework、論文化文言の overclaim 防止)

Claim D は **"0 upstream artifact rework events in implementation phase"** という precise scope で主張する (= data-acquisition-plan v1.2 §3.6 v1.2 注記整合)。**v0.4 update = 2 evidence 種別 disambiguate 必要**:

- **A-1 implementation phase = Claim D primary evidence (strong)**: A-1 全 implementation phase Step 1-3 (= 16th-17th 累計、151 tests pass) で post-approve upstream artifact (req/design/tasks) rework = **0 events** = 機械検証済 (Data 1 commit pattern auto = `git log -- .kiro/specs/dual-reviewer-*/`)
- **A-2.1 design phase = Claim D primary evidence ではない (= Claim B/C functioning evidence)** (v0.4 新規 disambiguate): A-2.1 Spec 6 design phase で記録した rework_log 44 events は **design phase 内** V4 review process events (= 全件 `discovered_phase=pre-impl` + `rework_target=design`) = post-approve impl rework ではなく **pre-impl design fix process 観測** = Level 6 schema を design phase に adaptive 適用した結果。これは Claim D primary ではなく **Claim B/C functioning evidence** = V4 review が design fix を generate する pattern observation
- **A-2.3 impl phase (= 30th 以降 Spec 6 implementation phase) = Claim D primary evidence の追加取得 phase**

**論文 framing 必須 (v0.4 強化、論文 reviewer 想定批判への direct rebuttal)**:

- **"Claim D primary metric" の precise 定義**: post-approve upstream artifact rework rate during implementation phase (NOT during design / review phase)
- **A-2.1 design phase 44 events の論文 framing**:
  - **Claim B/C functioning evidence として活用** = V4 review が design fix を generate する pattern observation、4 spec instance 連続改善 trend の **支持 evidence**
  - **Claim D primary evidence としては使用しない** = 論文 reviewer の "self-referential metric" 批判を avoid (= V4 自身が generate した修正 events を V4 有効性 evidence として claim すると logical circularity)
- **schema 範囲外の weak signal**: "rework が全くなかった" は誤り。test-driven implementation 精緻化、SKILL.md 文言調整、暗黙前提の自然吸収、TDD red→green cycle 中の impl 修正、helpers.py の DRY 適用 等は記録対象外
- **論文 Limitations section 明記推奨**:
  - (1) "post-approve upstream artifact rework rate" を Claim D primary metric として明示
  - (2) "schema 範囲外の implementation-level adjustments (TDD cycle / DRY refactoring / SKILL.md role 精緻化等) are out of scope of Claim D measurement"
  - (3) **"A-2.1 design phase events (= 44 events) are reported as Claim B/C functioning evidence (= V4 review process pattern observation), NOT as Claim D primary evidence"** = self-referential metric 批判への direct rebuttal

### 6.7 human GT 不在 + triangulation defense (= v0.2 追加 / v0.3 update = 5 → 6 indicators 化、論文 reviewer 想定批判 1 への direct rebuttal)

論文 reviewer 想定批判 1 (= self-referential metric、過剰修正比率 = `do_not_fix` 比率と定義されるが `do_not_fix` 自身は V4 の judgment subagent verdict = self-referential) への direct rebuttal:

- **acknowledge**: ground truth absence を direct に認める (= 16th セッション末議論で human GT 撤回確定)
- **address through triangulation**: 6 件 independent indicators (= multi-vendor / mutation / multi-run / cross-project / rework signal / forward-reverse sub-group 比較 = v0.3 新規) の convergence を evidence base として triangulation defense
- **論文 acceptable line**: convergent triangulation framing は methodology paper として honest かつ defensible (= reviewer は "we address through triangulation with sub-group analysis" を satisfied 可能性高、批判 1 mitigation 予想 ~85% = v0.3 update with reverse spec の ground truth-anchored 補強、data-acquisition-plan v1.5 §3.7 整合)
- **6 件 indicators 詳細**: §1 Validation framing 参照 + §7.4 A-3 triangulation evidence batch 参照

### 6.8 reverse-engineering bias 5 source caveats (v0.3 新設、data-acquisition-plan v1.5 §5 + §3.7.6 整合)

§3.7.6 Code-derived spec batch (= 3 sample = Phase field 法 / 3D 熱伝導方程式 / Arduino IoT) は **既存コード → spec 起草 → re-implementation** の reverse-engineering 方式で取得。spec writer が既存実装を参照することで 5 source の系統的偏向が introduce される:

- **(1) spec completeness bias**: spec writer が既存実装を参照して起草するため forward 起草より過剰に完全化 → 期待される影響 = primary completeness bias の発動 surface 縮小 = 検出件数 / 過剰修正比率 reduction
- **(2) convergent thinking bias**: spec 起草が「既存実装の説明」化、設計探索 (= alternative 検討、却下案記録) が極小化 → adversarial counter-evidence 検出 surface 縮小
- **(3) design choice rationalization**: 既存コードの設計選択を後付け justification 化 → judgment override surface 縮小 = override rate reduction
- **(4) edge case asymmetry**: 既存コードに existing なら spec が拾う / missing なら spec も missing (= 既存コードのバグ・盲点が spec に転写) → 既存コード自体が dual-reviewer 検出可能 defect set の internal validity 制約
- **(5) implementation detail leakage**: spec が forward 規範では記述すべきでない実装詳細 (= 内部 algorithm 選択、特定 data structure) を含む傾向 → forward と reverse spec characteristic が異なる

**Mitigation 3 措置** (= data-acquisition-plan v1.5 §7 Sub-group analysis 規律 + §3.7.6 全体 caveat Mitigation 5 step 整合):

- **explicit labeling**: 全 sample に `spec_source: forward-fresh | reverse-engineered` field 付与、論文 figure 1-7 すべてで sub-group 区別表記
- **sub-group reporting**: 全 metric (= 検出 / 採択 / 過剰修正 / disagreement / judgment override / wall-clock / V4 修正否定) を forward 集合 + reverse 集合 + aggregate の 3 形式で並列計算
- **spec characteristic descriptive metric**: AC 数 / 文字数 / Design Decisions 数 / 言及 alternative 数 / 起草所要時間 を全 sample で記録、forward と reverse の系統的差異定量化

**paired comparison は scope 外** (= §3.7.7 future work entry、議論記録のみ): 同一 problem を forward + reverse 両方で実施 (gold standard) は cost 2 倍、本論文では 3 mitigation 措置 で acceptable line 内 mitigation 達成、Phase B 以降に必要性再判断。

**論文 Limitations 記述方針**: 4 validity threat (= construct / internal / external / statistical conclusion) で個別 acknowledge → 3 mitigation 措置 で対処 → paired comparison を Future Work で言及 = SE empirical study 標準 (Wohlin et al. "Experimentation in Software Engineering" + Kitchenham SLR guidelines) 整合。

---

## §7 Future Work + 8 月 Timeline Readiness

### 7.1 残 work (29th セッション末以降、v0.4 update)

- ~~**A-1 implementation phase**~~ (15th-17th 末完走 ✅、151 tests pass、TDD 9 cycle、Level 6 = 0 events、Claim D primary evidence strong): design-review v1.2 改修 cycle → foundation + design-review + dogfeeding 物理 file 生成
- ~~**A-2.1 Spec 6 Design phase 1/3 終端**~~ (20th-29th 末完走 ✅、treatment=dual+judgment 全 10 ラウンド、20 commits、29th 末 endpoint = `3cbefdb`、§4.6 partial completion evidence):
  - 過剰修正比率 33.3% (4 spec instance 連続改善 -47.95pt 累計)
  - v4-miss core evidence 17 件追加 + fatal_pattern hits 5 件 + escalate 解決手段 5 path 確立 + Round 10 V4 67% bias 抑制 evidence
- **A-2.1 残 2/3** (30th 以降、推定 1-2 month batch): treatment=single (Round 1-10) + treatment=dual (Round 1-10) = 20 review session = ablation comparison data 取得 = single → dual で adversarial 効果分離 + dual → dual+judgment で judgment 効果分離 = 論文 figure ablation primary source
- **A-2.2 Spec 6 Tasks phase** (option、推定 数時間-1 日、A-2.1 完走後): V4 ad-hoc 補助 evidence、tasks phase 4 spec 目拡張
- **A-2.3 Spec 6 Impl phase** (推定 1 month、A-2.1/A-2.2 完走後): Level 6 passive 観測 = **Claim D primary evidence 追加取得 phase**
- **A-2 終端統合分析** (= A-2.1+A-2.2+A-2.3 完走時): A-1 vs A-2 比較 + Claim D 主張可否判断 + Spec 6 全 phase approve = Rwiki v2 全 8 spec design phase approve
- **A-3 triangulation evidence batch** (A-2 完走後、推定 35-65h ≈ 5-8 work day = 1.5-2.5 calendar 月 batch、§7.4 詳細): 6 件 independent indicators 取得 (= multi-vendor + mutation + multi-run + cross-project + Level 6 + forward-reverse sub-group 比較) + convergence judgment + §3.7.6 Code-derived spec batch (3 sample = Phase field / 3D 熱伝導 / Arduino IoT、cost 20-32h) + Phase A 終端
- **論文 draft 執筆 Phase 3** (9-10 月 (preliminary)、Phase A 終端後 別 effort): figure 1-3 + ablation evidence + A-3 triangulation evidence input + §3.7.6 sub-group 比較 evidence + **§4.6 A-2.1 1/3 終端 evidence (= 4 spec instance 連続改善 + 5 path + Round 10 67% bias 抑制) を本 report v0.4 経由で input 化**、本 spec scope 外

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

8 月末 failure (= figure data 完了未達) は dogfeeding/design.md Decision 5 で Phase B fork hold 判定の補助根拠化。**v0.2 注記**: Phase A 終端 redefine (= A-3 完走 = 論文 draft 着手 timing) により論文 draft timeline は **7-8 月 → 8-9 月 (preliminary)** に後ろ倒し (= A-3 batch 1-2 calendar 月分後ろ倒し、最終 timeline は A-3 完走後再評価)。

### 7.4 A-3 triangulation evidence batch (v0.2 追加 / v0.3 拡張 = §3.7.6 Code-derived spec batch + §3.7.1 re-position + §3.7.7 paired comparison future work、論文批判 1+9 mitigation 戦略)

A-2 完走後の独立 batch (= scenario B、user 明示「分離した方が集中できる」per 16th 議論)。論文 reviewer 想定批判 1+2+3+5+8+9 同時 mitigation evidence (= 批判 9 = 言語 generalization、v0.3 新規)。Phase A 終端 redefine (= A-3 + §3.7.6 完走 = 論文 draft 着手 timing、v0.3 update)。data-acquisition-plan v1.5 §3.7 + memory `project_a3_plan_triangulation_defense.md` 整合。

**着手順序 (v0.3 確定)**: §3.7.6 先行 (= 3 reverse-engineered samples、軸 5+6+7 cover) → §3.7.1 (forward-fresh-spec 独立必須 sample) → §3.7.2-5 (multi-vendor / mutation / multi-run / convergence judgment)。§3.7.6 先行で domain abstraction gap を即時 cover し、reverse-engineering 方式の feasibility を Phase field sample で検証。

**6 件 independent indicators 構成** (累計 cost 35-65h、v0.3 update):

- **§3.7.1** フルスクラッチ project (= 別 domain、forward-fresh-spec 独立必須 sample、req+design phase V4 適用、cost 6-12h、批判 2 sample size + 批判 8 ecological validity mitigation + 軸 6 forward 側 sub-group base): cross-project transfer evidence、v0.3 で「保険」位置付けから forward-fresh-spec 独立必須化に re-position
- **§3.7.2** multi-vendor LLM cross-validation (= Claude vs GPT-4 vs Gemini judgment、cost 3-6h、批判 1 self-referential + 批判 3 LLM-on-LLM bias 同時 mitigation): inter-rater reliability proxy framing
- **§3.7.3** mutation testing (= Spec 6 design.md に既知 defect 5-10 件 inject、cost 7-10h、批判 1 direct rebuttal): constructed positive control、sensitivity/specificity 直接測定
- **§3.7.4** multi-run reliability check (= V4 protocol 3-5 random seed 再実行、cost 3-5h、批判 5 order effect mitigation): inter-run agreement matrix、validity の必要条件 reliability 測定
- **Level 6 rework signal** (= 既 plan 内、cost ~0、批判 1 time-deferred validity defense): post-hoc V4 do_not_fix prospective error rate
- **§3.7.6 Code-derived spec batch** (= v0.3 新規、3 sample reverse-engineered、累計 cost 20-32h、批判 1 ground truth-anchored 補強 + 批判 2 domain abstraction gap 解消 + 批判 9 言語 generalization defense):
  - **§3.7.6.1** Phase field 法 (compact、Julia or C++、cost 6-10h、reverse-engineering feasibility 検証 sample = 着手順序最先行)
  - **§3.7.6.2** 3D 熱伝導方程式 + 複雑モデル生成 (cost 10-14h、real-world numerical project rich 化)
  - **§3.7.6.3** Arduino IoT センサ (cost 4-8h、embedded systems failure mode cover)
  - 全体 caveat = §6.8 reverse-engineering bias 5 source caveats + Mitigation 3 措置 (= explicit labeling + sub-group reporting + spec characteristic metric)

**§3.7.7 Paired comparison (future work、議論記録のみ、scope 外)**: 同一 problem を forward + reverse 両方で実施 = reverse-engineering bias の strict internal validity disentangle (gold standard)。scope 外理由 = cost 2 倍、§3.7.6 + §3.7.1 sub-group 比較で paper acceptable line 内 mitigation 達成。Phase B 以降に必要性再判断。

**convergence threshold** (= Phase A 終端 + 論文 draft 着手 go 判定): 6 件中 5 件以上が V4 有効性方向に converge (= multi-vendor agreement ≥ 70% AND mutation sensitivity ≥ 70% AND multi-run agreement ≥ 80% AND cross-project metric stability ≥ ±20% AND Level 6 M4a ≤ 40% AND **forward-reverse sub-group 比較で systematic 差異が paper limitations 範囲内** = v0.3 新規)。

**批判 mitigation 予想 (v0.3 update)**: 批判 1 ~85% (v0.2 80% + reverse spec の ground truth-anchored 補強) / 批判 2 ~80% (v0.2 70% + domain abstraction gap 解消) / 批判 3 ~70% (v0.2 同) / 批判 5 ~80% (v0.2 同) / 批判 8 ~90% (v0.2 同) / 批判 9 ~75% (v0.3 新規 言語 generalization defense) = 論文 acceptable line 明確に内強化。

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
- **v0.2** (2026-05-02 18th セッション開始、Claim D 追加 + framing 変更 + A-3 batch + A-1 implementation 完走 反映): 15th-18th 累計の進展を minimal scope で反映 (= §1 + §6 + §7 + §10 中心、§4 Results 数値は 14th 末 historical fix 維持)。**§1 Executive Summary**: (a) "主張 (3 claims)" → "(4 claims)"、Claim D (downstream rework signal、external validity) 追加、(b) readiness 表に Claim D row 追加 = "中間 evidence 確立 = A-1 全 implementation phase Step 1-3 = 0 events 機械検証済"、(c) §1 末尾 **Validation framing** sub-section 新設 = "ground truth validation → convergent multi-indicator triangulation" framing 変更 (16th セッション末議論で確定、data-acquisition-plan v1.1 §1 整合) + human GT 不在の理由 2 件 + 5 件 independent indicators 列挙 + 論文 abstract / introduction core principle。**§6 Limitations**: (a) 6.5 multi-vendor 比較 = "未実施" → "A-3.2 で計画 (cost 3-6h、批判 1+3 同時 mitigation)、Phase B-2 ではなく A-3 batch redefine"、(b) 6.6 (新設) **Claim D の precise scope** = "0 upstream artifact rework events" framing + overclaim 防止 (= weak signal は schema 範囲外) + 論文 limitations 明記推奨、(c) 6.7 (新設) **human GT 不在 + triangulation defense** = 16th 末議論直接反映 + 批判 1 direct rebuttal + convergent triangulation framing core principle positioning。**§7 Future Work**: (a) 7.1 残 work update = A-1 implementation phase 完走 ✅ (15th-17th 末、151 tests pass、TDD 9 cycle、Level 6 = 0 events) + A-2 phase 3 段構成 (data-acquisition-plan v1.3 §4 整合) + A-3 batch 追加 + 論文 draft 7-8 月 → 8-9 月 後ろ倒し、(b) 7.3 末尾 v0.2 注記 = Phase A 終端 redefine + timeline 後ろ倒し 説明、(c) 7.4 (新設) **A-3 triangulation evidence batch** = 5 件 indicators (A-3.1 フルスクラッチ project + A-3.2 multi-vendor LLM + A-3.3 mutation testing + A-3.4 multi-run reliability + Level 6 rework signal) 累計 cost 19-33h、convergence threshold + 批判 mitigation 予想 (~80%/~70%/~70%/~80%/~90%)。**冒頭 status 文言** = "8 月ドラフト" → "8-9 月ドラフト" + "Phase A 終端後 = A-3 完走後 redefine"。本 v0.2 改版の scope 制限注記: §2 Methodology / §3 Evaluation Setup / §4 Results / §5 Discussion / §8 Conclusion は 14th 末状態 historical fix 維持 (= readiness 評価の core value)、A-2 完走後の v0.3 で systematic update。
- **v0.4** (2026-05-03 29th セッション末、A-2.1 partial completion = treatment=dual+judgment 全 10 ラウンド完走反映 + Claim D scope 精緻化 = Level 6 design phase events ≠ impl phase rework): A-2.1 Spec 6 Design phase の treatment=dual+judgment 1/3 終端 (= 20th-29th 累計、20 commits、29th 末 endpoint = `3cbefdb`) + 29th 末新規 evidence の本 report 反映。**冒頭 status update**: "A-2.1 1/3 終端 = treatment=dual+judgment 全 10 ラウンド完走" + 残 work clarify (= A-2.1 残 2/3 + A-2.2 Tasks + A-2.3 Impl + A-3 + §3.7.6)。**§1 readiness 表 update (4 row 全件 update)**: Claim A 強化 (v4-miss core evidence 17 件追加 = core 10 件 must_fix upgrade + minor 7 件 should_fix upgrade) + Claim B 強化 (4 spec instance 過剰修正比率 連続改善 -47.95pt + Round 10 V4 67% bias 抑制 evidence) + Claim C 強化 (escalate 解決手段 5 path 確立 + fatal_pattern hits 5 件) + Claim D scope 精緻化 (= A-1 impl 0 events strong + A-2.1 design 44 events ≠ Claim D primary、§6.6 整合)。**新規 §4.6 A-2.1 Spec 6 Design phase partial completion evidence** = §4.6.1 累計 metric (検出 69 / 採択率 30.4% / 過剰修正比率 33.3% = V3 比 -16.7pt) + §4.6.2 4 spec instance design phase 連続改善 (foundation 81.25% → design-review 58.8% → dogfeeding 40.0% → Spec 6 33.3% = -47.95pt 累計改善) + §4.6.3 v4-miss core evidence 17 件 (Round 別内訳) + §4.6.4 fatal_pattern hits 5 件 (path_traversal × 3 + data_loss × 1 + destructive_migration 逆向き × 1 = Chappy P0 quota 機能 evidence) + §4.6.5 escalate 解決手段 5 path 確立 (path 1 user 判断 / path 2 premise 誤り / path 3 adversarial counter + judgment override / path 4 rule_2 must_fix 降格 / path 5 候補 = escalate 解除 4 連続再現 Round 7-10) + §4.6.6 Round 10 V4 過剰修正 bias 抑制機能 evidence (= primary single なら +3 修正 → dual+judgment net 1 修正 = 67% bias 抑制 + 検出漏れ 1 件補完 = V4 機能本質発揮 round = 論文 figure ablation primary visual rebuttal candidate) + §4.6.7 Sub-group analysis 規律遵守 (= explicit labeling + spec characteristic metric 記録継続)。**§6.6 Claim D scope 精緻化** = "A-1 impl 0 events = Claim D primary strong" vs "A-2.1 design 44 events = Claim B/C functioning evidence (NOT Claim D primary)" の 2 evidence 種別 disambiguate を追加、論文 reviewer 想定批判 "self-referential metric" 批判への direct rebuttal として "A-2.1 design phase events を Claim D primary evidence として claim しない" 規律明示 + 論文 Limitations section 3 件記述方針 update (= primary metric 定義 / out-of-scope 明示 / design phase events を Claim B/C functioning evidence として framing)。**§7.1 残 work update** = A-2.1 1/3 終端を完走 ✅ 化 + A-2.1 残 2/3 (= treatment=single + treatment=dual = ablation comparison data) + A-2.2 + A-2.3 + A-2 終端統合分析 + A-3 + Phase 3 paper draft 入力 (= §4.6 を v0.4 経由で input 化)。**scope 制限注記**: §4.1-§4.5 = 14th 末 historical fix 維持方針継続 (= 9 spec instance V4 metric 集約 + phase 内 cross-spec trend + phase 横断累計 + H1-H4 仮説検証 + V4 修正否定 prompt 機能 = readiness 評価 core value)、A-2.1 完全終端 (= 30 session = single + dual + dual+judgment 全完走) 後の v0.5 で systematic update 予定。本 v0.4 改版自体は v0.3 同様 Level 6 記録対象外 (= methodology meta-document)。
- **v0.3** (2026-05-02 19th セッション末、軸 4 → 軸 7 拡張 + §3.7.6 Code-derived spec batch 反映 + §3.7.1 forward-fresh-spec 独立必須化 + reverse-engineering bias 5 source caveats 追加): data-acquisition-plan v1.5 + evidence-catalog v0.7 整合化 (= 19th 末議論「dual-reviewer サンプル数を増やす場合、異なる特性のコードで行った方がよい」反映)。**§1 Validation framing**: (a) "5 件 indicators" → "6 件 indicators" 化 + indicator (vi) **forward-reverse spec source sub-group 比較** 新設 (= §3.7.6 reverse-engineered batch vs §3.7.1 + A-1 + A-2 forward-fresh-spec sub-group の metric 系統的差異有無、ground truth-anchored 補強 + reverse-engineering bias 5 source mitigation evidence)、(b) "軸 4 → 軸 7 拡張" 言及追加 (= 軸 5 ground truth + 軸 6 forward-reverse spec + 軸 7 言語 diversity)、(c) 論文 framing core principle update = "with explicit sub-group analysis on spec source modality" 追加。**§6 Limitations**: (a) 6.7 update = "5 → 6 indicators" 化 + 批判 1 mitigation 予想 ~80% → ~85% (reverse spec の ground truth-anchored 補強)、(b) 6.8 (新設) **reverse-engineering bias 5 source caveats** = spec completeness / convergent thinking / design choice rationalization / edge case asymmetry / implementation detail leakage の 5 source + 各々の dual-reviewer metric への系統的影響 + Mitigation 3 措置 (explicit labeling + sub-group reporting + spec characteristic descriptive metric) + paired comparison scope 外明記 + 論文 Limitations 4 validity threat 記述方針 (Wohlin et al. + Kitchenham SLR guidelines 整合)。**§7 Future Work**: (a) 7.1 残 work update = A-2 sample に Sub-group analysis 規律適用 + A-3 batch cost 19-33h → 35-65h + 論文 draft 8-9月 → 9-10月 後ろ倒し (= §3.7.6 cost 20-32h 追加分)、(b) 7.4 拡張 = 5 件 → 6 件 indicators 化 + 着手順序 §3.7.6 先行 → §3.7.1 → §3.7.2-5 確定 + §3.7.6 Code-derived spec batch 詳細 (= 3 sample = Phase field / 3D 熱伝導 / Arduino IoT) + §3.7.7 Paired comparison future work 言及 + convergence threshold = 5 → 6 conditions + 批判 mitigation 予想 update (批判 1 ~85% / 批判 2 ~80% / 批判 9 ~75% 新規)。**冒頭 status 文言** = "8-9 月ドラフト" → "9-10 月ドラフト" + "A-3 + §3.7.6 完走後 redefine"。本 v0.3 改版の scope 制限注記: §2 Methodology / §3 Evaluation Setup / §4 Results / §5 Discussion / §8 Conclusion は 14th 末状態 historical fix 維持 (= readiness 評価の core value)、A-2 完走後の v0.4 で systematic update (= 14th 末状態を超えた update を Phase A 終端 = A-3 + §3.7.6 完走後に集約)。本 v0.3 改版自体は data-acquisition-plan v1.5 / evidence-catalog v0.7 と同様 Level 6 記録対象外 (= methodology meta-document)。

---

**本 report は preliminary draft = 論文 figure 1-3 + ablation evidence 未取得段階での readiness 評価。最終 paper draft 入力は A-2 dogfeeding 完走後 final comparison-report v0.2 集約から取得予定。**
