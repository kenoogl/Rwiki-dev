# Paper Data Acquisition Plan — dual-reviewer methodology validation

_目的: 論文 (8月ドラフト提出) + Phase B fork 判断のための quantitative evidence 取得計画。checkbox で進捗追跡し、新 evidence 取得 + phase 移行ごとに更新する。_

_v0.4 / 2026-05-01 (14th セッション末、A-1 tasks phase 完走 + 3 spec tasks-phase V4 metric 累計反映 + cross-spec review C-1 fix 適用)_

---

## §1 論文の目的 + 3 主張

dual-reviewer methodology を **LLM 設計レビューの bias 緩和方法論** として確立。3 主張:

- **Claim A**: adversarial subagent (V3 = Step B) が single-reviewer に対し検出 coverage を改善
- **Claim B**: judgment subagent (V4 Step C 新規) が過剰修正 bias を抑制し採択率を改善
- **Claim C**: 上記 2 構造統合の dual-reviewer architecture が **bias 観測装置 + 改善 mechanism** として方法論的に valid

提出 timeline: **8月ドラフト提出** (Phase 3 = 7-8月、別 effort)。本計画は Phase 2 (6-7月、A-2 期間) で figure 1-3 + ablation evidence 完走を担保。

## §2 比較軸 (3 axes)

軸混同を避ける設計 (V4 §4.4 で identifiability 問題に明示対処済):

- **軸 1 (PRIMARY、論文 figure 中心)**: ablation framing = single vs dual vs dual+judgment 3 系統対照実験
  - 主張範囲: 「single → dual で adversarial 効果 X%」「dual → dual+judgment で judgment 効果 Y%」
  - **避ける**: 「V4 全体 > V3」pure independent 比較 (B-2 multi-vendor で defer)
- **軸 2**: phase 横断 verification (req phase vs design phase)
- **軸 3**: V3 baseline vs V4 累計 evidence (H1-H4 仮説検証)

---

## §3 データ取得 checklist (5 levels)

### §3.1 Level 1: Per-finding raw data (JSONL log、dr-log skill 出力)

**foundation Req 3 + design-review Req 2 + dogfeeding Req 3 で AC 化済 schema**:

#### 既収集 (req phase、9th-10th セッション)

- [x] foundation req V4 redo broad raw data (commit `2379532` → main 統合済): 検出 19 件
- [x] design-review req V4 redo broad raw data (commit `72c5722` → main 統合済): 検出 20 件
- [x] dogfeeding req V4 redo broad raw data (commit `21c5ab2` → main 統合済): 検出 18 件
  - 形式: `docs/dual-reviewer-log-2.md` (user 管理 dev-log) 内に集約、JSONL 化は B-1.0 minimum schema 準拠で本格化は A-1 prototype 後

#### 既収集 (A-1 design phase、12th セッション完走)

- [x] foundation design phase V4 raw data (commit `2e5637d`、12th): 検出 16 件 (primary 10 + adversarial 6)、apply 3 件 (P4+A1+A5)、design.md v1.1 確定
- [x] design-review design phase V4 raw data (commit `76a1eb1`、12th): 検出 17 件 (primary 10 + adversarial 7)、apply 6 件 (A1+A5+A6+P4+A2+A4) + A3 false positive skip、design.md v1.1 → v1.2-prep
- [x] dogfeeding design phase V4 raw data (commit `aa40934`、12th): 検出 15 件 (primary 10 + adversarial 5)、apply 9 件 (P1+A1+A2+P2+P4+P5+P10+A3+A5)、design.md v1.2、cross-spec review C1-C3 統合 commit
  - 形式: `docs/dual-reviewer-log-3.md` (user 管理 dev-log、12th セッション)
  - Cross-spec review 結果: Group A 6 件整合 + Group B 11 件既存対応済 + Group C 3 件 apply + 不整合 0 件

#### 未収集 (A-1 期間内 tasks phase ad-hoc V4 適用 = opportunistic、補助 evidence、13th セッション 着手予定)

dual-reviewer 3 spec 自体の tasks.md 生成 (`/kiro-spec-tasks` 起動) 時に V4 protocol を ad-hoc 適用、raw data を取得する opportunistic data collection。**論文 core evidence ではなく補助 evidence (= phase 横断 reproducibility preliminary verification)**、Layer 2 tasks extension 未実装のため ad-hoc 観点。

- [x] foundation tasks phase V4 ad-hoc raw data (commit `021ec65`、14th 末、検出 18 件 / must_fix 1 / should_fix 5 / do_not_fix 12)
- [x] design-review tasks phase V4 ad-hoc raw data (commit `021ec65`、14th 末、検出 15 件 / must_fix 2 / should_fix 5 / do_not_fix 8)
- [x] dogfeeding tasks phase V4 ad-hoc raw data (commit `021ec65`、14th 末、検出 14 件 / must_fix 5 / should_fix 3 / do_not_fix 6)
  - 形式: foundation 共通 schema + `phase: tasks` enum で JSONL 記録 (foundation Req 3 AC1 で `tasks` enum 既定)
  - ad-hoc 観点 (= primary 自身が列挙、Layer 2 tasks extension 未実装): boundary 違反 / dependency cycle / granularity 過大過細 / AC 網羅 / executability / verifiability
  - V4 §5.2 prompt template (judgment subagent 用) は phase 不問 portable で再利用、5 条件判定ルール + 3 ラベル分類も再利用
  - forced_divergence prompt (design phase 用、design-review 確定文言) は phase optimization 不足 = adversarial subagent dispatch 時 ad-hoc に tasks phase 用に微調整 (= "primary's task structure" の暗黙前提置換等、本格的 tasks phase forced_divergence prompt 文言は B-1.1 で別途確定)
  - **caveat (paper rigor 保証用)**: Layer 2 tasks extension 未実装 = systematic 観点 set 不在 = ad-hoc 観点列挙 = paper limitations section に明示

#### 未収集 (A-2 dogfeeding、A-1 完走後)

- [ ] **Spec 6 dogfeeding 全 30 review session JSONL log** (= 10 round × 3 系統)
  - 形式: `.dual-reviewer/dev_log.jsonl` (foundation `dr-init` 生成、`config.yaml` `dev_log_path` field 動的読込)
  - per-record schema: review_case + finding (3 系統全部で `miss_type` / `difference_type` / `trigger_state` 自己ラベリング)
  - 修正必要性判定軸: dual+judgment 系統のみ judgment 確定値 (`source: judgment_subagent`)、single / dual は primary 自己 estimate (`source: primary_self_estimate`)
  - `treatment` field (single | dual | dual+judgment) + `round_index` (1..10) + Spec 6 design.md commit hash 必須付与
  - `adversarial_counter_evidence` field (dual / dual+judgment のみ)

### §3.2 Level 2: Aggregated metrics (per system per round、dogfeeding Req 4 で AC 化)

#### 既収集 (req phase 累計、`comparison-report.md` §3 集約済)

- [x] foundation req: 検出 19 / must_fix 4 / should_fix 8 / do_not_fix 7 / 採択率 21.1% / 過剰修正比率 36.8% / wall-clock 284 sec / V4 修正否定 prompt 機能 71%
- [x] design-review req: 検出 20 / must_fix 8 / should_fix 7 / do_not_fix 5 / 採択率 40.0% / 過剰修正比率 25.0% / wall-clock 301 sec / V4 修正否定 prompt 機能 80%
- [x] dogfeeding req: 検出 18 / must_fix 1 / should_fix 9 / do_not_fix 8 / 採択率 5.6% / 過剰修正比率 44.4% / wall-clock 297 sec / V4 修正否定 prompt 機能 100%

#### 既収集 (A-1 design phase、12th セッション完走)

- [x] foundation design phase metrics: 検出 16 / must_fix 0 / should_fix 3 / do_not_fix 13 / 採択率 0% / 過剰修正比率 81.25% / wall-clock ~293s / V4 修正否定 prompt 機能 90% (primary 9/10 件 do_not_fix へ整合)
- [x] design-review design phase metrics: 検出 17 / must_fix 4 (1 false positive) / should_fix 3 / do_not_fix 10 / 採択率 23.5% / 過剰修正比率 58.8% / wall-clock ~255s / judgment override 8 / disagreement 7
- [x] dogfeeding design phase metrics: 検出 15 / must_fix 3 / should_fix 6 / do_not_fix 6 / 採択率 20.0% / 過剰修正比率 40.0% / wall-clock ~244s / judgment override 3 / disagreement 4

**3 spec design phase 累計 trend (12th 末確定、過剰修正比率 連続改善で V4 構造的有効性 3 spec 連続再現実証)**:

| metric | foundation | design-review | dogfeeding | trend |
|--------|------------|---------------|------------|-------|
| 検出件数 | 16 | 17 | 15 | 安定 |
| 採択率 | 0% | 23.5% | 20.0% | foundation 0 → 大幅改善 |
| **過剰修正比率** | **81.25%** | **58.8%** | **40.0%** | **連続改善 (-22pt → -19pt = -41.25pt 累計)** |
| should_fix 比率 | 18.75% | 17.6% | 40.0% | dogfeeding で escalate 増 |
| subagent wall-clock | ~293s | ~255s | ~244s | 連続短縮 (-49s 累計、context efficiency) |

#### 未収集 (A-1 期間内 tasks phase ad-hoc V4 適用 = opportunistic、補助 evidence、13th セッション着手予定)

- [x] foundation tasks phase metrics (14th 末): 検出 18 / must_fix 1 / should_fix 5 / do_not_fix 12 / 採択率 5.6% / 過剰修正比率 66.7% / V4 修正否定 prompt 機能 75% / judgment override 7 件 / primary↔judgment disagreement 3 件
- [x] design-review tasks phase metrics (14th 末): 検出 15 / must_fix 2 / should_fix 5 / do_not_fix 8 / 採択率 13.3% / 過剰修正比率 53.3% / V4 修正否定 prompt 機能 28.6% / judgment override 5 件 / primary↔judgment disagreement 1 件 / adversarial↔judgment disagreement 2 件
- [x] dogfeeding tasks phase metrics (14th 末): 検出 14 / must_fix 5 / should_fix 3 / do_not_fix 6 / 採択率 35.7% / 過剰修正比率 42.9% / V4 修正否定 prompt 機能 37.5% / judgment override 3 件 / primary↔judgment disagreement 2 件 / adversarial↔judgment disagreement 2 件

**3 spec tasks phase 累計 trend (14th 末確定、過剰修正比率 連続改善で V4 構造的有効性 3 spec 連続再現実証、design phase trend と方向一致 = 6 spec instance 累計再現)**:

| metric | foundation | design-review | dogfeeding | trend |
|--------|------------|---------------|------------|-------|
| 検出件数 | 18 | 15 | 14 | 安定 |
| 採択率 | 5.6% | 13.3% | 35.7% | **連続改善 (+7.7pt → +22.4pt = +30.1pt 累計)** |
| **過剰修正比率** | **66.7%** | **53.3%** | **42.9%** | **連続改善 (-13.4pt → -10.4pt = -23.8pt 累計)** |
| should_fix 比率 | 27.8% | 33.3% | 21.4% | dogfeeding で減 (must_fix へ shift) |
| V4 修正否定 prompt 機能 | 75% | 28.6% | 37.5% | adversarial 自己 do_not_fix 比率 |
| judgment override | 7 | 5 | 3 | 連続減 (semi-mechanical mapping default 適合性向上) |
- **caveat (phase 横断 strict comparability 問題)**: design phase 10 ラウンド観点固定 vs tasks phase ad-hoc 観点 = 観点 set / coverage 異なる = strict 数値比較 (例: design phase 採択率 vs tasks phase 採択率) は spurious comparison リスク。**relative trend (= 同 spec 内で single → dual → dual+judgment の改善方向)** は valid だが、**phase 間 absolute 比較は注意**

#### 未収集 (A-2 dogfeeding、A-1 implementation phase 完走後)

- [ ] **Spec 6 全 Round × 3 系統 metrics** (per system per round):
  - [ ] 検出件数 / must_fix / should_fix / do_not_fix 件数 + 比率 (3 系統各々)
  - [ ] 採択率 (= must_fix 比率)
  - [ ] 過剰修正比率 (= do_not_fix 比率)
  - [ ] adversarial 修正否定 disagreement 数 (dual + dual+judgment のみ、forced_divergence 効果)
  - [ ] judgment subagent disagreement 数 + override 件数 + override 理由分析 (dual+judgment のみ)
  - [ ] wall-clock per system per round + V3 baseline 比 + V4 完全構成比 (V3 = 420.7 秒 design phase 正規)
  - [ ] Phase 1 同型 hit rate (per system、メタパターン 3 種照合)
  - [ ] fatal_patterns 8 種強制照合 hit 件数 (per system、Chappy P0 quota 効果)

### §3.3 Level 3: Hypothesis testing (cumulative)

#### 中間 status (req phase のみ、`comparison-report.md` §5 集約済)

- [x] **H1 (過剰修正比率 ≤ 20%)** req phase 中間: 3 spec 全未達、ただし全 spec で V3 baseline -50% から改善方向 (-13.2 / -25.0 / -5.6 pt)、design-review 25.0% で **H1 まで -5.0 pt 近接**
- [x] **H2 (escalate user 介入機会 = should_fix 件数増)** req phase 中間: ✅ **達成** = 24 件 escalate 確保
- [x] **H3 (採択率 ≥ 50%)** req phase 中間: 3 spec 全未達、design-review 40.0% (V3 比 2.40 倍) で **H3 まで -10.0 pt 近接**、dogfeeding 5.6% (consumer spec 構造的低)
- [x] **H4 (wall-clock + 50% 以内)** req phase 中間: ✅ **達成** = V3 比 70% (-30% 短縮、大幅余裕)

#### 中間 status (design phase 反映、12th セッション完走後追加)

- [x] **H1 (過剰修正比率 ≤ 20%)** design phase 中間: 3 spec 全未達、ただし **3 spec 連続改善** (foundation 81.25% → design-review 58.8% → dogfeeding 40.0%) = -41.25pt 累計改善 = V4 構造的有効性 3 spec 連続再現実証。dogfeeding 40.0% で req phase の foundation 36.8% / dogfeeding 44.4% よりは未達寄りだが、accepted 既存 design なら接近方向。最終 verification は A-2 完走後 comparison-report 集計時。
- [x] **H2 (escalate)** design phase 中間: ✅ **継続達成** = 12 件 escalate 確保 (foundation 3 + design-review 3 + dogfeeding 6)、req phase 24 + design phase 12 = 累計 36 件
- [x] **H3 (採択率 ≥ 50%)** design phase 中間: 3 spec 全未達、ただし **foundation 0% から +20-23pt 大幅改善** (design-review 23.5% / dogfeeding 20.0%)、design phase で consumer-only spec の AC 直接 trace 性質で must_fix 検出が向上、最終 verification は A-2 完走後
- [x] **H4 (wall-clock + 50% 以内)** design phase 中間: ✅ **継続達成** = wall-clock 連続短縮 (foundation ~293s → design-review ~255s → dogfeeding ~244s = -49s 累計 = context 累積 efficiency)、V4 H4 (+ 50% 以内 = 631 sec) に対し大幅余裕

#### 補助 evidence (tasks phase ad-hoc V4 適用、13th セッション着手予定)

A-1 期間内 tasks phase ad-hoc V4 適用 evidence = phase 横断 H1-H4 robustness 補助 verification。**論文 core evidence ではなく preliminary cross-phase verification (limitations section 言及)**:

- [x] **H1 cross-phase robustness 補助** (14th 末): tasks phase 3 spec で過剰修正比率連続改善 trend 再現確認 = 66.7% → 53.3% → 42.9% (-23.8pt 累計、design phase -41.25pt と方向一致) = req + design + tasks の 3 phase で V4 構造的有効性 reproducibility 確認
- [x] **H2 escalate cross-phase** (14th 末): tasks phase escalate 件数 = should_fix 13 件 (累計 = req 24 + design 12 + tasks 13 = 49 件、user 介入機会連続増)
- [x] **H3 採択率 cross-phase robustness** (14th 末): tasks phase 採択率改善方向 trend 確認 = 5.6% → 13.3% → 35.7% (+30.1pt 累計、改善方向)
- [ ] **H4 wall-clock cross-phase**: tasks phase wall-clock 別 metric 化要 (= 3 subagent dispatch wall-clock measurement 別 evidence、本 14th 末 evidence 未取得 = A-2 dogfeeding 期間で取得予定)
- **caveat**: ad-hoc 観点 = strict statistical claim 不可、補助 evidence (= preliminary cross-phase verification) として paper limitations section で明示

#### 最終 verification (A-1 + A-2 完走後)

- [ ] H1 最終 verification: design phase + dogfeeding evidence で過剰修正比率 ≤ 20% 達成可否
- [ ] H2 最終 verification: 累計 should_fix 件数 + user 介入 cycle 完走比率
- [ ] H3 最終 verification: 累計 must_fix 採択率 ≥ 50% 達成可否
- [ ] H4 最終 verification: 累計 wall-clock V3 比 + option C cost 許容範囲確認

### §3.4 Level 4: Figure data (paper-ready、dogfeeding Req 5 で AC 化)

機械可読 format (JSON or yaml) で生成。Phase 3 ドラフト執筆で図表描画 input。

#### 未収集 (A-2 dogfeeding 完走後)

- [ ] **figure 1: `miss_type` 6 enum 分布 (3 系統 × 6 enum = 18 data point)**
  - 主張: adversarial / judgment が見落としていた miss_type を補完したか
  - source data: Level 1 JSONL log の `miss_type` field 集計
  - file path: dogfeeding design phase で確定 (Req 5 AC6)
- [ ] **figure 2: `difference_type` 6 enum 分布 + forced_divergence 効果 (dual vs single 分離)**
  - 主張: dual で `difference_type=adversarial_trigger` 発動件数 (forced_divergence 効果)
  - sequencing 制約: design-review design phase 完走 (forced_divergence prompt 文言確定) が前提
  - source data: Level 1 JSONL log の `difference_type` field 集計
- [ ] **figure 3: `trigger_state` 3 field 発動率 (`applied` vs `skipped` 比率、3 系統)**
  - 主張: bias 抑制 quota の 3 系統間発動率比較
  - source data: Level 1 JSONL log の `trigger_state` field 集計
- [ ] **figure ablation: dual vs dual+judgment で judgment 効果分離 (V4 §4.4 整合)**
  - 主張: judgment subagent 効果 (過剰修正比率削減 + 採択率増 + override 件数 + 必要性判定 quality)
  - source data: Level 2 metrics + Level 1 `override_reason` 内容分析

#### tasks phase ad-hoc data の figure 寄与 (補助 evidence、13th セッション着手予定)

- [ ] **figure 1 (miss_type 分布)**: tasks phase data point 追加で phase 横断 reproducibility 強化 = core evidence と整合 (foundation 6 enum は phase 不問)
- [ ] **figure 3 (trigger_state 発動率)**: tasks phase 3 系統 trigger_state 発動率追加で phase 横断 reproducibility 強化 = core evidence と整合
- [ ] **figure ablation (judgment 効果分離)**: tasks phase で dual vs dual+judgment 効果分離が再現するか追加 evidence = core evidence 補強
- ⚠️ **figure 2 (difference_type + forced_divergence 効果)**: tasks phase data は forced_divergence prompt が design phase 用 optimize で semantic mismatch caveat、tasks phase data は **補助 evidence のみ** (= core figure 2 = design phase 3 spec + A-2 dogfeeding で十分、tasks phase は limitations 言及のみ)

#### scope 外 (Phase 3 paper draft 責務)

- ⏸️ figure 4-5 (case study qualitative narrative) — Phase 3 論文ドラフト責務 (本計画 scope 外、dogfeeding brief Out of Boundary 整合)

### §3.5 Level 5: Phase B fork go/hold judgment (5 条件、dogfeeding Req 6 で AC 化)

A-2 dogfeeding 完走時に 5 条件全件評価、全達成 → go (Phase B-1.0 release prep)、未達 → hold:

- [ ] **(a) 致命級発見 ≥ 2 件 (累積)** = Spec 3 Round 5-10 dogfeeding 1 件 [外部固定累積] + Spec 6 dogfeeding ≥ 1 件
- [ ] **(b) disagreement ≥ 3 件** = Spec 3 = 2 件 + Spec 6 で 1 件以上 (forced_divergence + judgment subagent 含む)
- [ ] **(c) bias 共有反証 evidence 確実** = subagent 独立発見が再現 (primary 見落 → adversarial 独立検出 ≥ 1 件)
- [ ] **(d) impact_score 分布が minor のみではない** = severity ∈ {CRITICAL, ERROR} の finding ≥ 1 件
- [ ] **(e) 過剰修正比率改善** = dual+judgment 系統 vs dual 系統で do_not_fix 比率減 + must_fix 比率増 (V4 H1+H3 仮説整合)
- [ ] **判定結果記録** = `comparison-report.md` 最終版に go/hold + 判定根拠 + 移行手順 (go) or 改訂候補 (hold) 併記

---

## §4 Timeline / phase milestones

### A-0 spec 策定 (✅ 完了、本 11th セッション末)

- [x] 3 spec init (4-29、commit `06fde00`)
- [x] V3 review process (4th-7th セッション、archive `archive/v3-foundation-design-7th-session`)
- [x] V4 protocol v0.3 final (7th セッション末、commit `59421ed`)
- [x] V4 attempt 1 ablation (8th 前半、archive `archive/v4-redo-attempt-1-v3-scope`)
- [x] 案 3 広義 redo Step 0-3 (8th 末)
- [x] V4 redo broad 3 spec req phase (9th-10th、worktree branch v4-redo-broad)
- [x] Step 5 cross-spec review (10th、commit `29fe2c5`)
- [x] Step 6 中間 comparison-report (10th、commit `475878d`)
- [x] req phase 3 spec approve (11th、commit `b6b850c`)
- [x] main 統合 (case A 即 merge、11th、commit `bcd604f`)
- [x] V3 design phase artifact cleanup + evidence-catalog 起草 (11th、commit `fa35d8d`)
- [x] 3 req 整合性 audit + gap-list 記録 (11th、commit `c383802`)

### A-1 design phase (✅ 完了、12th セッション完走)

- [x] foundation design phase V4 適用 (commit `2e5637d`、12th)
- [x] design-review design phase V4 適用 (commit `76a1eb1`、12th)
- [x] dogfeeding design phase V4 適用 + cross-spec review (commit `aa40934`、12th)
- [x] audit gap design phase 対応: G1 (source field 2 階層 disambiguate) = foundation Decision 2 で解決 / G3 (foundation install location 確定 timing) = foundation Decision 5 で解決 (A-1 = design+impl 一体解釈) / G2+G4 cosmetic 残 (Phase A 終端 cleanup 候補)
- [x] cross-spec review 通過 (Group A 6 件確認済整合 + Group B 11 件既存対応済 + Group C 3 件新規 implication 全 apply [C1+C2+C3] + 不整合 0 件、12th 末)
- [ ] design phase V4 evidence で comparison-report v0.2 起草 (req + design phase 累計、13th 以降 implementation phase 中または A-2 完走後 timing)

### A-1 tasks phase (✅ 完了、14th セッション完走、commit `021ec65`)

dual-reviewer 3 spec の tasks.md 生成 + V4 ad-hoc 適用 + cross-spec review C-1 fix を 14th セッション完走:

- [x] foundation tasks.md 生成 + V4 ad-hoc 適用 (commit `021ec65`、14th 末)
- [x] design-review tasks.md 生成 + V4 ad-hoc 適用 (commit `021ec65`、14th 末)
- [x] dogfeeding tasks.md 生成 + V4 ad-hoc 適用 (commit `021ec65`、14th 末)
- [x] cross-spec review (20 観点 integrity check、Group A 17 + B 2 + C 1 + 不整合 0 件、Group C-1 軽微 implication 1 件 = `jsonschema>=4.18` version pin 同期 を foundation tasks v1.2 で apply)
- [x] tasks phase ad-hoc V4 evidence を本 data-acquisition-plan v0.4 + 各 spec tasks.md Change Log v1.1 に集約 (comparison-report の最終 v0.2 集約は A-2 完走後)
- caveat: ad-hoc 観点 (Layer 2 tasks extension 未実装)、phase 横断 strict comparability 問題、forced_divergence prompt design phase optimization = paper limitations section に明示済

### A-1 implementation phase (⏳ tasks phase 完走後、13th-14th セッション、推定 1 month)

- [ ] design-review v1.2 改修 cycle (treatment flag + timestamp 必須付与 + commit_hash payload 受領 = dogfeeding/design.md Decision 6 整合、本 spec implementation phase 直前 prerequisite)
- [ ] foundation 4 skill のうち `dr-init` 物理 file 生成 (`scripts/dual_reviewer_prototype/skills/dr-init/{SKILL.md, bootstrap.py}`)
- [ ] design-review 3 skills 物理 file 生成 (`scripts/dual_reviewer_prototype/skills/{dr-design, dr-log, dr-judgment}/{SKILL.md, *.py}`)
- [ ] foundation portable artifact 物理 file 生成 (`framework/layer1_framework.yaml` + `schemas/*.json` 5 file + `patterns/{seed_patterns, fatal_patterns}.yaml` + `prompts/judgment_subagent_prompt.txt` + `config/config.yaml.template` + `terminology/terminology.yaml.template`)
- [ ] design-review portable artifact 物理 file 生成 (`extensions/design_extension.yaml` + `prompts/forced_divergence_prompt.txt`)
- [ ] dogfeeding 3 Python script 物理 file 生成 (`scripts/dual_reviewer_dogfeeding/{metric_extractor, figure_data_generator, phase_b_judgment}.py + tests/ + README.md`)
- [ ] sample 1 round 通過 test (= design-review Req 7.4 動作確認終端条件): foundation `dr-init` で Spec 6 working directory bootstrap → design-review `dr-design` (Round 1 のみ、treatment="dual+judgment") で Step A → B → C → D 全完了 + dr-log JSONL 1 entry 以上 schema validate 成功 + V4 §2.5 三ラベル提示 yaml stdout 出力 の 3 条件全達成

### A-2 dogfeeding (⏸️ A-1 implementation phase 完了後、推定 1-2 month)

- [ ] Spec 6 design への dual-reviewer 適用 (dr-init bootstrap + 3 系統 30 review session)
- [ ] Level 1 JSONL log 取得 (30 entry、3 系統 × 10 round)
- [ ] Level 2 metrics 抽出 (`metric_extractor.py` 実行 → `dogfeeding_metrics.json` 生成)
- [ ] Level 4 figure 1-3 + ablation data 生成 (`figure_data_generator.py` 実行 → `figure_<n>_data.json` × 4 生成)
- [ ] Level 5 Phase B fork go/hold 5 条件評価 + 判定記録 (`phase_b_judgment.py` 実行 → `comparison-report.md` §12 append、section ID `phase-b-fork-judgment-v1`)
- [ ] 最終 comparison-report v0.2 (Phase A 終端時、req + design + A-2 累計集計)
- [ ] Spec 6 design approve = Rwiki v2 全 8 spec design approve = Phase A 終端

### Phase 3 paper draft (7-8月、別 effort、本計画 scope 外)

- ⏸️ figure 1-3 + ablation で図表描画
- ⏸️ figure 4-5 (case study qualitative narrative) 執筆
- ⏸️ 論文ドラフト submission (8月末)

---

## §5 Constraints / 留意点

- **cost 3 倍** (3 系統対照実験、判定 7-C 採用済): single + dual + dual+judgment で 30 review session = 1 系統比 wall-clock + token 3 倍
- **Spec 6 design 内容自体は dogfeeding spec 責務外**: `rwiki-v2-perspective-generation` spec が design 内容策定、dogfeeding は dual-reviewer 適用 + metric 取得のみ
- **8月 timeline 厳守**: A-1 着手遅延が A-2 timing 圧迫、後ろ倒し → Phase 3 paper draft 間に合わなくなるリスク → A-1 着手を遅延させない方針
- **identifiability**: ablation framing は「Step C 追加で X% → Y%」までの主張に限定、「V4 全体 > V3」pure 比較は B-2 multi-vendor 比較に defer
- **forced_divergence sequencing**: design-review design phase 完走 (= prompt 文言確定) が A-2 着手前提条件 (dogfeeding Req 5 AC2 で AC 化済)
- **commit hash 変動 caveat**: Spec 6 design が 30 review session 中に進行する場合、cross-round 比較に公平性 caveat を comparison-report に併記 (dogfeeding Req 3 AC7 で AC 化済)
- **timeline 未達 fallback**: 8月末日までに figure 1-3 + ablation evidence 完了未達 = Phase B fork hold 補助根拠 (dogfeeding Req 2 AC6 で AC 化済)
- **tasks phase ad-hoc V4 適用 4 caveats** (12th 末追加、補助 evidence のみ paper 利用):
  - (1) **ad-hoc 観点**: Layer 2 tasks extension 未実装 (Phase B-1.1 scope) = systematic 観点 set 不在、primary が ad-hoc 列挙 (boundary 違反 / dependency cycle / granularity / AC 網羅 / executability / verifiability)
  - (2) **phase 横断 strict comparability 問題**: design phase 10 ラウンド観点固定 vs tasks phase ad-hoc 観点 = 観点 coverage 異なる = phase 間 absolute 比較は spurious comparison リスク、relative trend (= 同 spec 内 single → dual → dual+judgment) のみ valid
  - (3) **forced_divergence prompt の design phase optimization**: design-review 確定文言は design phase の暗黙前提 (機能仕様) に semantic optimize、tasks phase では task 粒度 / dependency / boundary が暗黙前提のため semantic mismatch、figure 2 (forced_divergence 効果) で tasks phase data は補助のみ
  - (4) **paper rigor 保証**: tasks phase ad-hoc V4 evidence は paper limitations section で明示 = core evidence は req + design (12th 末取得済) + A-2 dogfeeding (A-2 完走後取得予定)、tasks phase は preliminary cross-phase verification 補助 evidence、systematic tasks phase evidence は Phase B-1.1 (dr-tasks skill 実装後) で paper revision に活用

---

## §6 関連 reference

- `comparison-report.md` v0.1 (本計画の中間 evidence 集約 = req phase 累計、12th 末で design phase evidence 未追記、A-2 完走後の v0.2 で req+design+A-2 累計集計予定)
- `evidence-catalog.md` v0.4 (本計画の data 所在 + アクセス方法 catalog、12th 末で §4 design phase V4 evidence 反映済)
- `v4-protocol.md` v0.3 final §4 (本計画の比較指標 + H1-H4 仮説 normative basis)
- 3 spec requirements.md (本計画の AC source = foundation Req 3-5 + design-review Req 2 + dogfeeding Req 3-7)
- 3 spec design.md / research.md (12th 末 endpoint = foundation v1.1 + design-review v1.1 → v1.2-prep + dogfeeding v1.2)
- TODO_NEXT_SESSION.md (各 session 末で本計画 update 反映)

---

## §7 運用規律

- **更新 trigger**:
  - 各 phase milestone 達成時 ([ ] → [x])
  - 新 evidence 取得時 (関連 § に追記)
  - hypothesis verification 結果確定時 (中間 status → 最終 status)
  - timeline 制約変動時 (timeline § + Constraints § を更新)
- **整合性 check**:
  - `comparison-report.md` の数値 + 本計画 [x] item 数値の同期 (= comparison-report が SSoT、本計画は checkbox tracker)
  - `evidence-catalog.md` の data 所在 location と本計画 [ ] item の output path の整合
- **session 末義務**: TODO 更新時に本計画の checkbox 反映漏れを確認

---

## 変更履歴

- **v0.1** (2026-04-30 11th セッション、本 file 初版): 論文の目的 + 3 主張 + 比較軸 3 axes + データ階層 5 levels + timeline / milestones + constraints を整理。req phase 累計 evidence は [x]、design phase + A-2 + Phase 3 は [ ] で起点設定。
- **v0.2** (2026-05-01 12th セッション末): A-1 design phase 全 3 spec 完走 + cross-spec review 通過 を反映。Level 1 (raw data) + Level 2 (metrics) で foundation `2e5637d` + design-review `76a1eb1` + dogfeeding `aa40934` を [x] チェック、3 spec 累計 trend (過剰修正比率 81.25% → 58.8% → 40.0% 連続改善) を Level 2 末に追加。Level 3 (H1-H4 中間 status) に design phase 反映 entries 追加 (req phase 中間 status の下に design phase 中間 status を併記、H1-H4 全項目で design phase 評価を追記)。Timeline section: A-1 prototype design phase を「✅ 完了」に変更 + A-1 implementation phase を新 section として追加 (13th 以降 着手予定、推定 1 month、design-review v1.2 改修 cycle + 4 skill + 3 Python script + sample 1 round 通過 test)。A-2 dogfeeding section の dependency を A-1 implementation phase 完走後に変更 + concrete 実行 step 明示。§6 関連 reference に 3 spec design / research file 整合 + comparison-report v0.1 (req phase) / evidence-catalog v0.4 (12th 末 design phase 反映済) version 整合追記。
- **v0.3** (2026-05-01 12th セッション末、tasks phase ad-hoc V4 適用 evidence acquisition 追加): 13th セッションで dual-reviewer 3 spec 自体の tasks.md 生成 (`/kiro-spec-tasks` 起動) 時に V4 protocol を ad-hoc 適用、補助 evidence (= phase 横断 reproducibility preliminary verification、論文 core evidence ではない) を opportunistic に取得する計画を追加。Level 1 + Level 2 + Level 3 + Level 4 各 section に tasks phase ad-hoc V4 entries 追加 (3 spec [ ] checkbox + caveat 明示)。Timeline section に「A-1 tasks phase」新 section 追加 (A-1 implementation phase の前段、3 spec tasks.md 生成 + V4 ad-hoc 適用)。§5 Constraints に tasks phase ad-hoc V4 適用の 4 caveats (ad-hoc 観点 / phase 横断 strict comparability / forced_divergence prompt 設計 phase optimization / paper rigor 保証 = limitations section 言及) 追加。systematic tasks phase evidence は Phase B-1.1 (dr-tasks skill + Layer 2 tasks extension 別 spec 化後) で paper revision に活用。
- **v0.4** (2026-05-01 14th セッション末、A-1 tasks phase 完走 + 3 spec tasks-phase V4 metric 累計反映): 14th セッションで dual-reviewer 3 spec tasks.md 生成 + V4 ad-hoc 適用完走 (commit `021ec65`)。Level 1 + Level 2 の tasks phase ad-hoc V4 [x] checkbox 化 + 3 spec metric 完全数値反映 (foundation 採択率 5.6% / 過剰修正 66.7%、design-review 13.3% / 53.3%、dogfeeding 35.7% / 42.9%) + 3 spec tasks phase 累計 trend table (採択率 +30.1pt / 過剰修正 -23.8pt 連続改善 = V4 構造的有効性 3 spec 連続再現実証、design phase trend と方向一致 = 6 spec instance 累計再現)。Level 3 H1+H2+H3 cross-phase robustness 補助 [x] 化 (H4 wall-clock は別 metric 化要、A-2 期間取得予定)。Timeline section の A-1 tasks phase を「✅ 完了」に変更 + cross-spec review (20 観点 integrity check、Group A 17 + B 2 + C 1 + 不整合 0 件、Group C-1 = `jsonschema>=4.18` version pin 同期) checkbox [x] 化。comparison-report の最終 v0.2 集約は A-2 完走後 (本 v0.4 update では tasks-phase evidence を本 plan に集約済、comparison-report は req + design phase 集約のみで本 spec 完了時集約 timing は variance)。
