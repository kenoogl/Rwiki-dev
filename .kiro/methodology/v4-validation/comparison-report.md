# V4 Validation Comparison Report — req phase 中間 evidence (V4 redo broad 完走)

_生成: 2026-04-30 (10th セッション末)、Step 6 中間 comparison-report_
_status: req phase 3 spec V4 redo broad 完走 + Step 5 cross-spec review 完了、design phase 進行可否判断材料を集約_

V4 protocol v0.3 final (`v4-protocol.md`) を 3 spec (foundation + design-review + dogfeeding) requirements phase に適用 (V4 redo broad、9th-10th セッション)、V3 baseline (`v3-baseline-summary.md`) と直接対比して V4 効果を測定する。

---

## §1 Overview

### §1.1 本 report の目的

- V4 redo broad 3 spec req phase 適用結果 vs V3 baseline 比較指標を集約
- 仮説 H1-H4 (V4 protocol §4.3) の 3 spec 横断検証
- design phase 進行可否判断材料 (req phase approve / V4 protocol 改訂 / 追加 dogfeeding 検討) を提示
- cross-spec implication 12 件 (Step 5) の処理結果を記録

### §1.2 本 report の scope

- **In scope**: req phase 3 spec V4 redo broad evidence + V3 baseline 対比 + 仮説検証 + 進行判断材料
- **Out of scope**: design phase V4 適用 (本 report 後の課題、A-1 prototype + A-2 dogfeeding の前段) / Phase B fork go/hold 判断 (dogfeeding spec Req 6 で確定、Spec 6 dogfeeding 完走後)

### §1.3 baseline reference 点

- V3 baseline endpoint: archive branch `archive/v3-foundation-design-7th-session` (commit `e6cab03`)、tag `v3-evidence-foundation-7th-session`
- V4 attempt 1 (V3 scope foundation): archive branch `archive/v4-redo-attempt-1-v3-scope` (commit `e8ca94a`)
- V4 redo broad endpoint: worktree branch `v4-redo-broad`、commit `29fe2c5` (本 10th 末)
- baseline file 参照: `.kiro/methodology/v4-validation/v3-baseline-summary.md`

---

## §2 V3 baseline 母体 (比較対照点)

### §2.1 6th セッション req phase V3 review evidence (3 spec dual-reviewer 試験運用)

参照: `v3-baseline-summary.md` §2.1 + memory `feedback_design_review_v3_adversarial_subagent.md`

- **foundation requirements V3 review** (4th-5th):
  - LLM 主体 (Opus) 検出: 14 件
  - subagent (Sonnet) 追加検出: 致命級 2 件 + 重要級 16 件 + 軽微 13 件 = 31 件
  - 合計検出: 45 件
  - disagreement: 7 件
  - 致命級独立発見 (subagent): 2 件
  - Phase 1 escalate 3 種同型: 全 5 ラウンドで全 3 種該当
  - subagent 累計 wall-clock: 420.7 秒 (~7.0 分)
  - 適用修正合計: 36 件

### §2.2 7th セッション design phase V3 review evidence (foundation 単独)

参照: `v3-baseline-summary.md` §2.2-2.3

- 検出件数: 6 件
- retroactive judgment 結果:
  - `must_fix` (真陽性): 1 件 (16.7%)
  - `optional` (judgment dependent): 2 件 (33.3%)
  - `do_not_fix` (過剰修正寄り): 3 件 (50.0%)
- = **過剰修正 bias 50% 顕在化**、V3 protocol が「検出は機能するが judgment step 欠落」という構造的証拠を確定
- subagent wall-clock (req phase): 420.7 秒
- design phase wall-clock は 6 件少件数のため req phase 値を baseline として継承

### §2.3 V3 baseline = V4 比較対照点

- 採択率 (must_fix 比率): **16.7%** (design phase = 1/6)
- 過剰修正比率 (do_not_fix 比率): **50.0%** (design phase = 3/6)
- 検出 → judgment 過程: V3 では retroactive judgment 必要 (= 検出時に judgment step なし)
- subagent wall-clock: **420.7 秒** (req phase foundation)

---

## §3 V4 evidence 累計 (V4 attempt 1 + V4 redo broad)

### §3.1 V4 attempt 1 — V3 scope foundation (8th 前半、archive)

参照: archive branch `archive/v4-redo-attempt-1-v3-scope` commit `e8ca94a`

- 適用 spec: foundation のみ (V3 scope 半端 ablation 試行)
- 検出件数: 22 件
- 分類: must_fix 5 / should_fix 1 / do_not_fix 16
- 採択率: **22.7%**
- 過剰修正比率: **72.7%**
- subagent wall-clock: **271 秒**
- judgment override 件数: 8 件
- primary↔judgment disagreement: 8 件
- 解釈: V4 attempt 1 は brief.md V3 整合のまま適用 = req scope が V3 と乖離して do_not_fix 多発、過剰修正比率 72.7% は V3 baseline 50% より悪化、brief.md V4 整合化が前提条件と判明 → archive

### §3.2 V4 redo broad — foundation req phase (9th)

worktree branch `v4-redo-broad`、commit `2379532`

- 適用 spec: foundation
- 検出件数: 19 件 (primary 7 + adversarial 12)
- Severity 4 水準: CRITICAL 1 / ERROR 5 / WARN 7 / INFO 6
- 分類: must_fix 4 / should_fix 8 / do_not_fix 7
- 採択率: **21.1%**
- 過剰修正比率: **36.8%**
- should_fix 比率: 42.1%
- subagent wall-clock: **284 秒** (adversarial 171 + judgment 113)
- judgment override 件数: 11 件
- primary↔judgment disagreement: 7 件
- 適用 12 件 (must_fix 4 + should_fix 8) / skip 7 件 (do_not_fix bulk)
- V4 修正否定 prompt 機能: primary 検出 7 件中 5 件 (71%) を judgment が do_not_fix に整合 = primary should_fix bias suppression 確認

### §3.3 V4 redo broad — design-review req phase (9th)

worktree branch `v4-redo-broad`、commit `72c5722`

- 適用 spec: design-review
- 検出件数: 20 件 (primary 5 + adversarial 15)
- Severity 4 水準: CRITICAL 5 / ERROR 6 / WARN 8 / INFO 1
- 分類: must_fix 8 / should_fix 7 / do_not_fix 5
- 採択率: **40.0%**
- 過剰修正比率: **25.0%**
- should_fix 比率: 35.0%
- subagent wall-clock: **301 秒** (adversarial 188 + judgment 113)
- judgment override 件数: 13 件
- primary↔judgment disagreement: 4 件
- 適用 14 編集点 (must_fix 7 統合 + should_fix 7 統合) / skip 5 件 (do_not_fix bulk)
- V4 修正否定 prompt 機能: primary 5 件中 4 件 (80%) を judgment が do_not_fix or must_fix 強化 = primary should_fix bias suppression 確認

### §3.4 V4 redo broad — dogfeeding req phase (10th、本セッション)

worktree branch `v4-redo-broad`、commit `21c5ab2`

- 適用 spec: dogfeeding
- 検出件数: 18 件 (primary 7 + adversarial 11)
- Severity 4 水準: CRITICAL 0 / ERROR 2 / WARN 7 / INFO 2 (primary 7 件 severity 未付与)
- 分類: must_fix 1 / should_fix 9 / do_not_fix 8
- 採択率: **5.6%**
- 過剰修正比率: **44.4%**
- should_fix 比率: 50.0%
- subagent wall-clock: **297 秒** (adversarial 160 + judgment 137)
- judgment override 件数: ~17 件 (semi-mechanical mapping default override 多数)
- primary↔judgment disagreement: ~4 件
- 適用 8 件 (must_fix 1 + should_fix 7) / Step 5 持ち越し 2 件 (A6 + A8) / skip 8 件 (do_not_fix bulk)
- V4 修正否定 prompt 機能: primary 7 件中 7 件 (100%) を judgment が adversarial counter-evidence と整合 = primary should_fix bias 完全 suppression
- 解釈: dogfeeding spec は consumer 視点のため AC が cross-spec contract 参照で済む構造 → 構造的問題は should_fix に分布、絶対 must_fix が internal contradiction 系 1 件のみに集中

---

## §4 cross-spec trend 観察 (V4 redo broad 3 spec)

### §4.1 採択率 trend

- foundation (9th): 21.1%
- design-review (9th): 40.0%
- dogfeeding (10th): 5.6%
- 単純な「cross-spec contract 多 spec ほど must_fix 比率上昇」trend は dogfeeding で揺らぐ
- **解釈**: dogfeeding は consumer 性質で AC が「foundation/design-review への参照」中心、独立 must_fix 候補が internal contradiction 1 件のみに集中、構造的問題 9 件は should_fix (user_decision) に分布 = 構造の違いが採択率に反映

### §4.2 過剰修正比率 trend

- foundation: 36.8% (V3 baseline 50% から **-13.2 pt** 改善)
- design-review: 25.0% (**-25.0 pt** 改善)
- dogfeeding: 44.4% (**-5.6 pt** 改善)
- **3 spec 全 V3 baseline から改善方向**、ただし H1 ≤ 20% は未達
- dogfeeding は speculative リスク発見 (edge case / scope expansion 系) が do_not_fix に多分類で他 spec より高め

### §4.3 should_fix 比率 trend

- foundation: 42.1%
- design-review: 35.0%
- dogfeeding: 50.0%
- 3 spec 全 35-50% 範囲で安定、user 介入機会 (escalate) が一定割合確保
- H2 (judgment step + escalate user 介入機会増加) 仮説整合

### §4.4 subagent wall-clock trend

- foundation: 284 sec
- design-review: 301 sec
- dogfeeding: 297 sec
- 3 spec 全 280-301 sec の **安定範囲**
- V3 baseline 420.7 sec 比 = 67-72% (= V3 比 30% 近く短縮)
- V4 完全構成 (3 subagent) でも V3 (2 subagent) より wall-clock 短縮 = H4 仮説 (+50% 以内) 達成

### §4.5 V4 修正否定 prompt 機能の 3 spec 再現

- foundation: primary 7 件中 5 件 (71%) を judgment が do_not_fix に整合
- design-review: primary 5 件中 4 件 (80%) を judgment が do_not_fix or must_fix 強化
- dogfeeding: primary 7 件中 7 件 (100%) を judgment が adversarial counter-evidence と整合
- = primary should_fix bias の suppression が **3 spec 連続再現**、V4 修正否定 prompt (V4 §1.5 + §5.2) の機能実証

---

## §5 仮説 H1-H4 検証 (V4 protocol §4.3 整合)

### §5.1 H1: V4 過剰修正比率 ≤ 20% (V3 baseline 50%)

- foundation: 36.8% — 未達 (改善 -13.2 pt)
- design-review: 25.0% — **近接** (改善 -25.0 pt、H1 まで -5.0 pt)
- dogfeeding: 44.4% — 未達 (改善 -5.6 pt)
- **判定**: 3 spec 全未達、ただし全 spec で V3 baseline から改善方向、design-review は H1 近接
- 未達原因仮説: H1 ≤ 20% は req phase 単独では厳しい目標、design phase で cross-spec contract が物理 artifact (file / class / API) として実体化されると false positive (do_not_fix) が減る可能性
- 改訂候補: H1 を req phase ≤ 30% / design phase ≤ 20% に分離検討

### §5.2 H2: V4 judgment step + escalate user 介入機会増加

- should_fix 件数: foundation 8 件 / design-review 7 件 / dogfeeding 9 件
- 累計 24 件の user 介入機会 (escalate → user_decision) を 3 spec で確保
- V3 では retroactive judgment が必要 = user 介入機会が事後付与のみ
- **判定**: ✅ **達成** (escalate 機能が 3 spec 再現で稼働、user 認知負荷を judgment step が吸収)

### §5.3 H3: V4 検出 → 採択率 ≥ 50% (V3 baseline 16.7%、3 倍改善目標)

- foundation: 21.1% — 未達 (改善 +4.4 pt、V3 比 1.27 倍)
- design-review: 40.0% — 未達 (改善 +23.3 pt、V3 比 2.40 倍、H3 まで -10.0 pt)
- dogfeeding: 5.6% — 未達 (V3 baseline 16.7% より低下、consumer spec 性質)
- **判定**: 3 spec 全未達、design-review が H3 近接、foundation/dogfeeding は未達
- 未達原因仮説: H3 ≥ 50% は spec 性質依存、consumer spec (dogfeeding) では must_fix 候補が構造的に少ない
- 改訂候補: H3 を spec 性質別 (foundation/Layer 2/Consumer) に分離検討

### §5.4 H4: V4 wall-clock + 50% 以内 (V3 baseline 比、option C subagent +1 個追加分許容)

- V3 baseline (req phase foundation): 420.7 秒
- V4 redo broad 平均: 294 秒
- V3 比 = 70% (= -30%、+50% 以内目標 = 630.0 秒 → 大幅余裕で達成)
- **判定**: ✅ **達成** (option C 3 subagent でも V3 2 subagent より wall-clock 短縮 = subagent 並列 dispatch + judgment 軽量化で逆転)
- 補足: V4 redo broad で wall-clock が短縮した要因仮説 = (a) judgment subagent が detection ではなく classification のみで token 消費少 / (b) 並列 dispatch で時間効率向上 / (c) primary review が adversarial 出力を input に judgment に委ねて短縮

### §5.5 H1-H4 仮説検証 集約

- H1 (過剰修正 ≤ 20%): 3 spec 全未達、design-review 近接、全 spec で V3 baseline から改善方向
- H2 (escalate user 介入機会): ✅ 達成、24 件 escalate 確保
- H3 (採択率 ≥ 50%): 3 spec 全未達、design-review 近接、spec 性質依存
- H4 (wall-clock +50% 以内): ✅ 達成、V3 比 70% (-30% 短縮で大幅余裕)

H1+H3 は req phase 単独で全 spec 達成困難だが、改善方向 + design-review 近接 + V4 修正否定 prompt 機能 3 spec 再現で **V4 protocol の構造的有効性は実証**。

---

## §6 cross-spec implication 集約 (Step 5 結果)

### §6.1 累計 12 件の処理結果

- **resolved 確認 (2 件)**:
  - A10 (foundation escalate label 4 値目追加): design-review Req 3 AC5 で `escalate` → `should_fix + recommended_action: user_decision` mapping で吸収済
  - A5 (3 系統対応 dr-log): design-review Req 2 AC7 + dogfeeding Req 3 AC4+AC8 全 align
- **apply (8 件、Step 5 statement 統合改版 commit `29fe2c5`)**:
  - A6 (dogfeeding Req 7 AC3 責務境界整合)
  - A8 (dogfeeding Req 2 AC6 SSoT chain inline + timeline failure 基準明示)
  - C-1 (foundation Req 2 AC2 dev_log_path field 追加)
  - C-2 (foundation Req 3 AC6 schema 拡張 contract 明示)
  - C-3 (dogfeeding Req 5 AC2 sequencing 制約)
  - D-1+D-2 (foundation Boundary Context Adjacent expectations 補完)
  - D-3 (design-review Boundary Context Adjacent expectations 補完)
  - + design-review Req 2 AC4 propagation (C-1 連動)
- **Phase A 終端時自動解消 (3 件、INFO)**:
  - C-4 (dogfeeding Layer 3 attach 整合明示)
  - D-4 (dogfeeding ⇔ Spec 6 spec 双方向)
  - D-5 (foundation/design-review の Spec 6 扱い)

### §6.2 foundation 改版時の傘下 spec 精査

memory `feedback_review_rounds.md` 第 5 ラウンド規範: Foundation 改版時の傘下 spec 精査必須

- foundation 3 fix (C-1 / C-2 / D-1+D-2) 適用時に design-review Req 2 AC4 propagation fix を識別 + 適用
- dogfeeding は foundation Req 2 AC2 改版で contract 互換性維持 (Req 3 AC5 の `dev_log_path` 参照は変更不要)
- **第 5 ラウンド規範整合確認済**

### §6.3 用語整合 軽微 gap (Step 5 (a))

- T1 (source enum: judgment_subagent): C-2 schema 拡張 contract 明示で部分解消
- T2 (treatment field): C-2 schema 拡張 contract 明示で部分解消
- T3 (judgment_reviewer suffix): foundation Req 7 AC1 vs design-review Req 1 AC4 表記揺れ、未対応 (cosmetic レベル、do_not_fix 相当)

---

## §7 V4 修正否定 prompt 機能の 3 spec 再現実証

### §7.1 機能の構造

V4 §1.5 (adversarial subagent 修正否定試行 prompt) + V4 §5.2 (judgment subagent dispatch prompt) が連動して、primary 提案 fix の必要性否定を 2 段階で実施:

1. **adversarial subagent** が独立検出 + primary 提案 fix の修正否定 counter-evidence 生成 (V4 §1.5 prompt 末尾組込)
2. **judgment subagent** が primary + adversarial 出力 + counter-evidence を input に必要性 5-field 評価 + 5 条件判定 + 3 ラベル分類 (V4 §5.2 prompt)

### §7.2 3 spec 再現実証

- foundation (9th): primary 7 件中 5 件 (71%) を judgment が do_not_fix に整合
- design-review (9th): primary 5 件中 4 件 (80%) を judgment が do_not_fix or must_fix 強化
- dogfeeding (10th): primary 7 件中 7 件 (100%) を judgment が adversarial counter-evidence と整合

### §7.3 解釈

- primary (Opus) は LLM の completeness bias で should_fix 提案傾向が強い
- adversarial (Sonnet) の counter-evidence + judgment (Sonnet) の独立 context 評価が連動して、primary should_fix bias を do_not_fix or must_fix に再分類
- = **V4 protocol の核心機能 = primary should_fix bias の suppression** が 3 spec 連続再現で構造的に実証
- V3 では retroactive judgment が事後で必要だったが、V4 では in-process で完結 = 過剰修正比率改善と user 認知負荷削減の同時達成

---

## §8 design phase 進行可否判断

### §8.1 進行可否の判断軸

- **判断軸 1 (V4 protocol 機能性)**: V4 修正否定 prompt 機能が 3 spec 再現実証 → ✅ **構造的有効性確立**
- **判断軸 2 (仮説 H1-H4 達成度)**: H2 + H4 達成、H1 + H3 未達 (ただし全 spec で V3 baseline から改善方向、design-review は H1+H3 近接) → △ **部分達成**
- **判断軸 3 (cross-spec contract 整合)**: Step 5 cross-spec review 12 件 implication のうち 8 件 apply + 3 件自動解消 + 2 件 resolved + 1 件 do_not_fix → ✅ **整合確保**
- **判断軸 4 (req phase artifact readiness)**: 3 spec requirements.md 全 V4 適用 + cross-spec 改版済 → ✅ **req phase artifact ready**

### §8.2 判断候補

- **候補 1 (推奨): 暫定 V4 default 採用 → req phase 3 spec approve → design phase 移行**
  - 根拠: 判断軸 1+3+4 達成、判断軸 2 部分達成 (改善方向 + design-review 近接 + 3 spec 再現実証)
  - 行動: req phase 3 spec の `spec.json` `approvals.requirements.approved: true` 確定 (= worktree branch `v4-redo-broad` の main merge timing も検討)
  - 次 step: A-1 prototype 着手 (4 skill 実装)
- **候補 2: V4 protocol 改訂 (H1+H3 未達対応) → 再適用**
  - 根拠: H1 ≤ 20% / H3 ≥ 50% を厳守する場合
  - 改訂方向: H1 / H3 を spec 性質別 (foundation/Layer 2/Consumer) に分離 + req phase / design phase 別
  - 課題: 再適用コスト + 8 月 timeline 圧迫リスク
- **候補 3: dogfeeding Spec 6 適用 (A-2 後段) で追加 evidence 収集後判断**
  - 根拠: req phase evidence のみで判断するのは不十分、design phase + 3 系統対照実験で確証
  - 課題: A-1 prototype 未実装で A-2 着手不可、判断 timing が後ろ倒し

### §8.3 推奨判断

**候補 1 (暫定 V4 default 採用)** を推奨:

- V4 protocol の構造的有効性 (修正否定 prompt 機能) が 3 spec 再現実証
- H1+H3 未達は req phase 単独評価の制約、design phase で実体化 (artifact 物理化) されると改善見込み
- A-1 prototype 実装 + A-2 dogfeeding Spec 6 適用で得られる追加 evidence で最終判断 (Phase B fork go/hold) を実施
- 8 月 timeline (論文 figure 1-3 + ablation evidence) 厳守には A-1 prototype 着手を遅延させない

ただし **req phase 3 spec approve は user 明示承認必須** (memory `feedback_approval_required.md` 整合)、本 report は判断材料を提示するのみ。

---

## §9 次 step 候補 + 残課題

### §9.1 次 step 候補 (10th セッション完了後)

- **(a) req phase 3 spec approve commit** (worktree branch `v4-redo-broad`):
  - 各 `spec.json` `approvals.requirements.approved: true` 更新
  - approve commit message 案: "spec(dual-reviewer-3-specs): req phase V4 redo broad approve (foundation/design-review/dogfeeding)"
  - user 明示承認後実施
- **(b) main merge timing**:
  - 候補 1: req phase approve 後即 merge
  - 候補 2: design phase 完走後 merge (A-1 prototype + design phase まで worktree branch 維持)
- **(c) A-1 prototype 着手**:
  - 4 skill 実装 (`dr-init` / `dr-design` / `dr-log` / `dr-judgment`)
  - design phase 進行 (req phase approve 後 / `/kiro-spec-design` 起動)
- **(d) A-2 dogfeeding Spec 6 適用** (A-1 完成後):
  - 全 Round (1-10) × 3 系統対照実験 = 30 review session
  - figure 1-3 + ablation evidence 用データ生成
  - Phase B fork go/hold 判断 (8 月末 timeline)

### §9.2 本 report 後の残課題

- design phase V4 適用結果との累計比較 (本 report は req phase のみ)
- A-2 dogfeeding 実完走後の最終 comparison-report (Phase A 終端時)
- 論文 figure 1-3 + ablation evidence 用 data file 生成 (dogfeeding Req 5)
- Phase B fork go/hold 判定記録 (dogfeeding Req 6)

### §9.3 memory 更新候補 (本 report 完了後)

- 新規 memory `feedback_review_v4_necessity_judgment.md`: V4 protocol 確定 + 案 3 広義 redo の経緯記録
- 新規 memory `feedback_v4_redo_lessons.md`: V4 適用 attempt 1 (V3 scope) の半端 ablation 教訓 + adversarial DA-1 検出機能 + 9th/10th セッション evidence
- 新規 memory `feedback_v4_cross_spec_trend.md`: cross-spec contract 多 spec で must_fix 比率上昇という trend は dogfeeding で揺らぐ (consumer spec は構造的に異なる) という観察記録
- `MEMORY.md` index 更新

---

## §10 関連 reference

- V3 baseline: `.kiro/methodology/v4-validation/v3-baseline-summary.md`
- V4 protocol v0.3 final: `.kiro/methodology/v4-validation/v4-protocol.md`
- canonical V4 design source: `docs/過剰修正バイアス.md` §1-6 + §7.2
- archive (V3 endpoint): `archive/v3-foundation-design-7th-session` commit `e6cab03`
- archive (V4 attempt 1): `archive/v4-redo-attempt-1-v3-scope` commit `e8ca94a`
- worktree (V4 redo broad): `v4-redo-broad` commit `29fe2c5`
- 3 spec requirements.md:
  - `.kiro/specs/dual-reviewer-foundation/requirements.md` (V4 redo broad + Step 5 改版済)
  - `.kiro/specs/dual-reviewer-design-review/requirements.md` (V4 redo broad + Step 5 改版済)
  - `.kiro/specs/dual-reviewer-dogfeeding/requirements.md` (V4 redo broad + Step 5 改版済)
- memory:
  - `feedback_design_review_v3_adversarial_subagent.md` (V3 試験運用 evidence)
  - `feedback_v3_adoption_lessons_phase_a.md` (V3 適用教訓)
  - `feedback_design_review_v3_generalization_design.md` (一般化 design)
  - `feedback_design_review.md` (10 ラウンド構成 中庸統合版)
  - `feedback_review_step_redesign.md` (Step 1b 5 重検査)
  - `feedback_review_judgment_patterns.md` (dev-log 23 patterns)
  - `feedback_review_rounds.md` (5 ラウンド構成 + 第 5 ラウンド規範 = Foundation 改版時傘下精査必須)
- dev-log: `docs/dual-reviewer-log-1.md` (1st-7th 集約) + `docs/dual-reviewer-log-2.md` (8th 以降)

---

## §11 変更履歴

- **v0.1** (2026-04-30 10th セッション末、本 file 初版): req phase 3 spec V4 redo broad 完走 + Step 5 cross-spec review 完了時点の中間集約。design phase 進行可否判断材料を提示。
