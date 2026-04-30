# Paper Data Acquisition Plan — dual-reviewer methodology validation

_目的: 論文 (8月ドラフト提出) + Phase B fork 判断のための quantitative evidence 取得計画。checkbox で進捗追跡し、新 evidence 取得 + phase 移行ごとに更新する。_

_v0.1 / 2026-04-30 (11th セッション末)_

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

#### 未収集 (A-1 design phase、12th 以降)

- [ ] foundation design phase V4 raw data (12th〜、`/kiro-spec-design dual-reviewer-foundation` 起動後)
- [ ] design-review design phase V4 raw data (foundation 完走後)
- [ ] dogfeeding design phase V4 raw data (design-review 完走後)

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

#### 未収集 (A-1 design phase + A-2 dogfeeding)

- [ ] foundation design phase metrics
- [ ] design-review design phase metrics
- [ ] dogfeeding design phase metrics
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

- [x] **H1 (過剰修正比率 ≤ 20%)** 中間: 3 spec 全未達、ただし全 spec で V3 baseline -50% から改善方向 (-13.2 / -25.0 / -5.6 pt)、design-review 25.0% で **H1 まで -5.0 pt 近接**
- [x] **H2 (escalate user 介入機会 = should_fix 件数増)** 中間: ✅ **達成** = 24 件 escalate 確保
- [x] **H3 (採択率 ≥ 50%)** 中間: 3 spec 全未達、design-review 40.0% (V3 比 2.40 倍) で **H3 まで -10.0 pt 近接**、dogfeeding 5.6% (consumer spec 構造的低)
- [x] **H4 (wall-clock + 50% 以内)** 中間: ✅ **達成** = V3 比 70% (-30% 短縮、大幅余裕)

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

### A-1 prototype design phase (⏳ 12th セッション 着手予定、推定数 month)

- [ ] foundation design phase V4 適用 (`/kiro-spec-design dual-reviewer-foundation`)
- [ ] design-review design phase V4 適用 (foundation 完走後)
- [ ] dogfeeding design phase V4 適用 (design-review 完走後)
- [ ] 4 skill 実装 (`dr-init` / `dr-design` / `dr-log` / `dr-judgment`)
- [ ] design phase V4 evidence で comparison-report v0.2 起草 (req + design phase 累計)
- [ ] audit gap (G1+G3 主) を design phase 中に対応

### A-2 dogfeeding (⏸️ A-1 完了後、推定 1-2 month)

- [ ] Spec 6 design への dual-reviewer 適用 (dr-init bootstrap + 3 系統 30 review session)
- [ ] Level 1 JSONL log 取得 (30 entry、3 系統 × 10 round)
- [ ] Level 2 metrics 抽出
- [ ] Level 4 figure 1-3 + ablation data 生成
- [ ] Level 5 Phase B fork go/hold 5 条件評価 + 判定記録
- [ ] 最終 comparison-report (Phase A 終端時)
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

---

## §6 関連 reference

- `comparison-report.md` (本計画の中間 evidence 集約 = req phase 累計)
- `evidence-catalog.md` (本計画の data 所在 + アクセス方法 catalog)
- `v4-protocol.md` §4 (本計画の比較指標 + H1-H4 仮説 normative basis)
- 3 spec requirements.md (本計画の AC source = foundation Req 3-5 + design-review Req 2 + dogfeeding Req 3-7)
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
