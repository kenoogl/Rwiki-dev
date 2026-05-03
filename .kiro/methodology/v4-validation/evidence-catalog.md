# Evidence Catalog — dual-reviewer methodology validation

_目的: V3 baseline / V4 各 attempt / 将来追加される実験データの所在 + 内容 + アクセス方法を継続的に記録するカタログ。新 evidence 生成時 + archive 操作時に必ず更新する。_

_v0.11 / 2026-05-04 (40th セッション末、treatment=single 系統 10 round 完走 = A-2.1 1/3 段階完了 = §5.2.1.6 新設 = primary 単独 detection 累計 evidence (46 detect / 17 採用 / 29 skip / 過剰修正比率 63.0% / Level 6 events 17 件 / treatment-single endpoint `33e1a12`) + 観点 axis 別 escalate 出現 pattern 全 Round 累計 (Round 1 0% → Round 10 40% suppress) + §5.2.1 残作業 update = treatment=dual 残のみ反映 = data-acquisition-plan v1.8 §A-2.1 checkbox 整合化)_

_v0.10 / 2026-05-03 (30th セッション初頭、A-2.1 3 系統対照実験 design.md state policy 明示 = pristine state `285e762` 起点 + 各 treatment 独立 branch 戦略 + 第 1 系統 main archive + 第 2/3 系統 new branch 派生 + 3 branch 統合分析 = data-acquisition-plan v1.7 §3.6 B4 + §4 A-2.1 整合化、paper rigor 確保のための confounding 排除)_

_v0.9 / 2026-05-03 (29th セッション末、A-2.3 critical path 外し + §3.7.6 re-impl phase で Claim D primary evidence 代替 = §5.1.6 Claim D primary evidence 構成 update + §5.2.3 A-2.3 を Phase B-1.x supplementary defer 明示 + §5.5.6.1-3 entries に Level 6 観測対象明示 = data-acquisition-plan v1.6 整合化)_

_v0.8 / 2026-05-03 (29th セッション末、§5.1.6 Level 6 status update = 0 → 44 events 反映 + §5.2.1.5 A-2.1 partial completion evidence partial fill = treatment=dual+judgment 全 10 ラウンド完走 (= A-2.1 1/3 終端) + §7 endpoint commits 19th-29th 追加)_

_v0.7 / 2026-05-02 (19th セッション末、§5.5 A-3 triangulation batch evidence + §3.7.6 Code-derived spec batch entries 新設 = data-acquisition-plan v1.5 整合化、§5.2 に Sub-group analysis 規律言及追加)_

---

## 1. V3 baseline evidence

### 1.1 V3 req phase review (foundation, 4th-5th セッション)

- **内容**: foundation requirements V3 review evidence
  - LLM (Opus) 主体検出: 14 件
  - subagent (Sonnet) 追加検出: 致命級 2 件 + 重要級 16 件 + 軽微 13 件 = 31 件
  - 合計検出: 45 件 / disagreement: 7 件 / 致命級独立発見 (subagent): 2 件
  - Phase 1 escalate 3 種同型: 全 5 ラウンド全該当
  - subagent 累計 wall-clock: 420.7 秒
  - 適用修正合計: 36 件
- **保全 location**:
  - branch `archive/v3-foundation-design-7th-session` (commit `e6cab03`)
  - tag `v3-evidence-foundation-7th-session`
  - origin push 済 (= remote backup あり)
  - file paths in archive: `.kiro/specs/dual-reviewer-foundation/{brief.md,requirements.md,spec.json}` 等
- **数値要約**: `.kiro/methodology/v4-validation/v3-baseline-summary.md` §2.1
- **関連 dev-log**: `docs/dual-reviewer-log-1.md` (4th-5th セッション)

### 1.2 V3 design phase review (foundation, 7th セッション)

- **内容**: foundation design phase V3 review evidence
  - 検出件数: 6 件
  - retroactive judgment: must_fix 1 件 (16.7%) / optional 2 件 (33.3%) / do_not_fix 3 件 (50.0%)
  - = 過剰修正 bias 50% 顕在化 (V4 protocol 構築の動機 evidence)
  - subagent wall-clock (req phase value 継承): 420.7 秒
- **保全 location**:
  - branch `archive/v3-foundation-design-7th-session` (commit `e6cab03`)
  - tag `v3-evidence-foundation-7th-session`
  - file paths in archive: `.kiro/specs/dual-reviewer-foundation/{design.md,research.md}` + `.kiro/specs/dual-reviewer-design-phase-defer-list.md`
  - main からは削除済 (本 catalog 起草と同 commit、2026-04-30 11th セッション)
- **数値要約**: `.kiro/methodology/v4-validation/v3-baseline-summary.md` §2.2-2.3
- **関連 dev-log**: `docs/dual-reviewer-log-1.md` (7th セッション)
- **比較利用 use case**:
  - ablation 実験: 同じ V3 design.md に V4 protocol を適用したらどうなるか
  - 数値再検証: 1/6 = 16.7% の根拠を後日確認
  - 論文 figure: V3 design vs V4 design 並列提示
  - V4 design phase 適用後の比較: A-1 prototype + V4 design 完走後

### 1.3 cross-spec V3 review (design-review + dogfeeding, 4th-6th セッション)

- **内容**: design-review + dogfeeding spec の V3 review evidence (foundation V3 review との横断整合性)
- **保全 location**: 同 archive branch `archive/v3-foundation-design-7th-session` (commit `e6cab03`)
- **要約**: `v3-baseline-summary.md` §2.1 (foundation 中心、横断要素含む)

---

## 2. V4 attempt 1 (V3 scope ablation、archive)

- **内容**: foundation V4 protocol 適用試験 (V3 brief.md 整合のまま、半端 ablation)
  - 検出 22 件 / must_fix 5 / should_fix 1 / do_not_fix 16
  - 採択率 22.7% / 過剰修正比率 72.7% (V3 baseline 50% より悪化、brief.md V4 整合化が前提条件と判明)
  - subagent wall-clock 271 秒 / judgment override 8 件 / disagreement 8 件
- **保全 location**:
  - branch `archive/v4-redo-attempt-1-v3-scope` (commit `e8ca94a`)
  - origin push 済
- **位置付け**: 案 3 広義 redo (= 本 main 統合済 V4 redo broad) への分岐判断根拠 evidence
- **関連 dev-log**: `docs/dual-reviewer-log-2.md` (8th セッション前半)

---

## 3. V4 redo broad (10th セッション末確定、本 main 統合済)

### 3.1 worktree setup + V4 整合 (commit `3b629cc`)

- draft v0.3 (内容 545 行、V4 整合反映)
- 3 spec brief.md V4 整合
- V4 protocol files 配置 (`v4-protocol.md` / `v3-baseline-summary.md`)
- canonical V4 source (`docs/過剰修正バイアス.md`) 配置

### 3.2 foundation req V4 redo broad (commit `2379532`、9th)

- 検出 19 件 / must_fix 4 / should_fix 8 / do_not_fix 7
- 採択率 21.1% / 過剰修正比率 36.8% / wall-clock 284 sec
- judgment override 11 / disagreement 7
- V4 修正否定 prompt 機能: primary 7 件中 5 件 (71%) judgment 整合

### 3.3 design-review req V4 redo broad (commit `72c5722`、9th)

- 検出 20 件 / must_fix 8 / should_fix 7 / do_not_fix 5
- 採択率 40.0% / 過剰修正比率 25.0% / wall-clock 301 sec
- judgment override 13 / disagreement 4
- V4 修正否定 prompt 機能: primary 5 件中 4 件 (80%)

### 3.4 dogfeeding req V4 redo broad (commit `21c5ab2`、10th)

- 検出 18 件 / must_fix 1 / should_fix 9 / do_not_fix 8
- 採択率 5.6% / 過剰修正比率 44.4% / wall-clock 297 sec
- judgment override ~17 / disagreement ~4
- V4 修正否定 prompt 機能: primary 7 件中 7 件 (100%)

### 3.5 Step 5 cross-spec review 統合改版 (commit `29fe2c5`、10th)

- 12 implication 全処理: apply 8 / 自動解消 3 / resolved 2 / cosmetic 1
- foundation 改版時の傘下 spec 精査 (memory `feedback_review_rounds.md` 第 5 ラウンド規範) 整合確認

### 3.6 Step 6 中間 comparison-report (commit `475878d`、10th)

- file: `.kiro/methodology/v4-validation/comparison-report.md` (11 章 389 行)
- 仮説検証: H2 + H4 達成、H1 + H3 未達 (改善方向、design-review 近接)
- design phase 進行可否推奨: 候補 1 (暫定 V4 default 採用)

### 3.7 req phase 3 spec approve (commit `b6b850c`、11th)

- 3 spec.json `approvals.requirements.approved: true`
- phase: `requirements-approved`
- 判断根拠: comparison-report.md §8.3 候補 1

### 3.8 main 統合 (本 catalog 起草直前)

- merge commit `bcd604f` (本 11th セッション)
- 統合戦略: case A (即 merge)
- conflict 解消: 全 10 file v4-redo-broad 版採用 (`--theirs`)
- 同時 cleanup (本 commit): V3 design phase artifact 3 file 削除
- 関連 dev-log: `docs/dual-reviewer-log-2.md` (9th-10th + 11th)

### 3.9 11th セッション 3 req 整合性 audit gap-list

main 統合直後 (commit `bcd604f` + `fa35d8d` 完了後) に user 指示で 3 req 整合性 audit を実施 (11th セッション)。Step 5 cross-spec review (10th、commit `29fe2c5`) で処理済の implications を verify、新規 + 残存 gap を以下に記録。

**主要 contract 整合 OK (audit verified)**:
- 3 subagent 構成 (V4 §1.2 option C) / 4 skills 責務分離 / Step A/B/C/D / 共通 schema 2 軸並列 / Adjacent expectations 双方向 / Phase A scope vs B-1.x demarcation / escalate mapping / dogfeeding 5 条件 / cross-spec reference 実存性

**Soft gap 4 件 (cosmetic / 軽微 semantic、blocking なし)**:

- **G1: `source` field naming overlap (semantic、design phase で対応)**
  - foundation Req 3 AC2 で `finding.source` enum = `primary | adversarial`
  - design-review Req 2 AC7 + dogfeeding Req 3 AC4 で `source: primary_self_estimate | judgment_subagent` を 修正必要性判定軸 context で使用
  - 同名 field が 2 階層で別 enum = 実装混乱可能性
  - 対応: design phase で `fix_decision.source` 等 nested field 名で disambiguate (foundation Req 3 AC6 consumer 拡張 mechanism 範囲内)

- **G2: `judgment_reviewer` vs `judgment subagent` 用語揺れ (cosmetic、Step 5 T3 既知未対応)**
  - foundation Req 7 AC1 = `judgment_reviewer` (role 抽象名)
  - foundation Req 6 + 他 = "judgment subagent" (V4 protocol 用語)
  - cosmetic 混在
  - 対応: design phase で文言統一可、または並列容認

- **G3: foundation install location 確定 timing (semantic、design phase で対応)**
  - foundation Boundary Context = "A-1 prototype 実装時に確定"
  - design-review Req 5 AC2 = "本 spec (design-review) の design phase で確定"
  - A-1 = foundation/design-review design phase 含意なら整合、明示されていない
  - 対応: foundation または design-review いずれかで「A-1 = design+impl phase」明示

- **G4: relative path canonical form (cosmetic)**
  - foundation `patterns/seed_patterns.yaml` 表記、design-review `./patterns/seed_patterns.yaml` 表記
  - 意味的等価
  - 対応: design phase で統一、または現状容認 (POSIX `./` 慣習)

**対応 timing**:
- G1 + G3: design phase で対応 (A-1 prototype 着手後、foundation または design-review design phase で fix)
- G2 + G4: cosmetic、design phase 中の自然修正で吸収 OR Phase A 終端 (A-2 完了時) に最終 cleanup

**判断**: 8 月 timeline 厳守 + design phase 実体化前に詳細修正は cost / value 不釣合のため、A-1 prototype 着手前の追加 req 修正は実施せず、本 gap-list で track して design phase で対応する。

---

## 4. design + tasks phase V4 evidence (12-14th セッション完走、main 統合済)

### 4.1 foundation design phase V4 (commit `2e5637d`、12th)

- **内容**: A-0 → A-1 phase transition design、foundation v1.1 確定
  - 検出 16 件 (primary 10 + adversarial 6 独立)
  - 分類: must_fix 0 / should_fix 3 / do_not_fix 13
  - 採択率 0% / 過剰修正比率 81.25% / should_fix 比率 18.75%
  - subagent wall-clock 約 293 秒 (adversarial 157s + judgment 136s)
  - judgment override 8 件 / primary↔judgment disagreement 1 件 (P3 ERROR → do_not_fix)
  - V4 修正否定 prompt 機能 90% (primary 9/10 件が judgment で do_not_fix へ整合 = primary should_fix bias suppression 実証)
  - apply 3 件 (P4 + A1 + A5、user 全 apply 採択 → design.md v1.1)
  - 5 設計決定: foundation install location = `scripts/dual_reviewer_prototype/` (audit G3 解決、X1 採用) / source field 2 階層 disambiguate (audit G1 解決、`finding.source` vs `necessity_judgment.source`) / V4 §5.2 prompt sync mechanism = header 3 行 manual sync / dr-init skill format = SKILL.md + Python helper / A-1 phase = design + implementation phase 一体解釈
- **保全 location**:
  - main `.kiro/specs/dual-reviewer-foundation/{design.md, research.md, spec.json}` (commit `2e5637d`)
  - design.md v1.1 + research.md v1.0 + spec.json (`phase: design-approved`、`approvals.design.approved: true`)
- **関連 dev-log**: `docs/dual-reviewer-log-3.md` (12th セッション、user 管理)

### 4.2 design-review design phase V4 (commit `76a1eb1`、12th)

- **内容**: A-1 design phase の主機能 spec、design-review v1.1 → v1.2-prep
  - 検出 17 件 (primary 10 + adversarial 7 独立)
  - 分類: must_fix 4 (うち A3 = false positive 1 件) / should_fix 3 / do_not_fix 10
  - 採択率 23.5% / 過剰修正比率 58.8% / should_fix 比率 17.6%
  - subagent wall-clock 約 255 秒 (adversarial 125s + judgment 130s、foundation 比 -38s)
  - judgment override 8 件 / primary↔judgment disagreement 7 件
  - V4 修正否定 prompt 機能 高 (must_fix 4 件全 adversarial ERROR と一致)
  - apply 6 件 (A1 + A5 + A6 + P4 + A2 + A4、user B 採択 = A3 false positive skip + 残 must_fix 3 件 + should_fix 3 件全 apply)
  - 5 設計決定: install root 共有 (foundation 同 directory) / forced_divergence prompt 文言 = 3 段落構成英語固定 / V4 §1.5 fix-negation prompt 配置 = adversarial dispatch payload inline embed / 3 skill format = SKILL.md + Python helper / dr-judgment 出力受領 mechanism = stdout default
- **保全 location**:
  - main `.kiro/specs/dual-reviewer-design-review/{design.md, research.md, spec.json}` (commit `76a1eb1` + `aa40934` v1.2-prep cross-spec C1 fix)
  - design.md v1.1 → v1.2-prep + research.md v1.0 + spec.json (`phase: design-approved`、`approvals.design.approved: true`)
- **関連 dev-log**: `docs/dual-reviewer-log-3.md` (12th セッション)

### 4.3 dogfeeding design phase V4 + cross-spec review (commit `aa40934`、12th)

- **内容**: A-1 design phase 最終 spec、dogfeeding v1.2 + 3 spec cross-spec review 統合
  - 検出 15 件 (primary 10 + adversarial 5 独立)
  - 分類: must_fix 3 / should_fix 6 / do_not_fix 6
  - 採択率 20.0% / 過剰修正比率 40.0% / should_fix 比率 40.0%
  - subagent wall-clock 約 244 秒 (adversarial 122s + judgment 122s、3 spec で最短 = context 累積 efficiency)
  - judgment override 3 件 / primary↔judgment disagreement 4 件
  - V4 修正否定 prompt 機能 高 (must_fix 3 件全 adversarial 検出と整合)
  - apply 9 件 (P1+A1 + A2 + P2 + P4 + P5 + P10 + A3 + A5、user A 採択で全 apply)
  - 7 設計決定: dogfeeding scripts location = `scripts/dual_reviewer_dogfeeding/` (X1 採用、prototype 本体と分離) / Operational Protocol + Research Script Hybrid (SKILL.md 不要、一回限り manual session) / dr-design Treatment Flag Contract = design-review revalidation trigger / comparison-report append-only (section ID `phase-b-fork-judgment-v1` 固定 + idempotent re-run) / 8 月 timeline failure 基準 = figure data 完了 / Decision 6 (design-review revalidation triggers 集約 3 件) / Decision 7 (A-1 解釈の dogfeeding 適用 = Python script 実装 (A-1 内) + Spec 6 適用 (A-2) 2 segment)
- **cross-spec review (本 commit に統合、3 spec 累計 design phase 完走後)**:
  - Group A 確認済整合 6 件 (install location / relative path / source field / V4 prompt / skill format / 3 系統対応)
  - Group B 既存対応済 11 件 (req phase Step 5 12 件 + 各 spec design phase 内 fix で対応済)
  - Group C 新規 implication 3 件 全 apply (C1: design-review/design.md Revalidation Triggers section に dogfeeding 要請 3 件反映 / C2: dogfeeding 3 Python script に foundation install location resolve mechanism 注記 / C3: Decision 7 = A-1 解釈)
  - 不整合 0 件
- **保全 location**:
  - main `.kiro/specs/dual-reviewer-dogfeeding/{design.md, research.md, spec.json}` (commit `aa40934`)
  - design.md v1.2 + research.md v1.0 + spec.json (`phase: design-approved`、`approvals.design.approved: true`)
  - design-review/design.md C1 fix 同 commit に統合 (Revalidation Triggers section に v1.2-prep entry 追加)
- **関連 dev-log**: `docs/dual-reviewer-log-3.md` (12th セッション)

### 4.4 3 spec 累計 V4 metric trend (12th 末確定)

| metric | foundation | design-review | dogfeeding | trend |
|--------|------------|---------------|------------|-------|
| 検出件数 | 16 | 17 | 15 | 安定 (15-17) |
| 採択率 | 0% | 23.5% | 20.0% | foundation 0 → 大幅改善 (+20-23pt) |
| **過剰修正比率** | **81.25%** | **58.8%** | **40.0%** | **連続改善 (-22pt → -19pt = -41.25pt 累計)** |
| should_fix 比率 | 18.75% | 17.6% | 40.0% | dogfeeding で escalate 増 (consumer 視点 context-dependent decisions 多) |
| subagent wall-clock | ~293s | ~255s | ~244s | 連続短縮 (-49s 累計、context efficiency) |

3 spec 連続で過剰修正比率改善 (81% → 59% → 40%) = V4 protocol 構造的有効性の **3 spec 連続再現実証** + design phase ablation framing 機能。req phase 累計と合わせて H1+H3 改善方向継続:
- H1 (過剰修正比率 ≤ 20%): req phase = foundation 36.8% / design-review 25.0% / dogfeeding 44.4%、design phase = 81.25% → 58.8% → 40.0% (dogfeeding 接近、未達)
- H3 (採択率 ≥ 50%): req phase = 21.1% / 40.0% / 5.6%、design phase = 0% → 23.5% → 20.0% (改善方向、未達)

最終 H1+H3 verification は A-2 dogfeeding 完走後の最終 comparison-report 集計時に判定 (Phase A 終端時)。

### 4.5 12th 末 cleanup (worktree + branch + origin 同期)

- **worktree remove**: `/Users/Daily/Development/Rwiki-dev-v4` 削除 (clean state + main 統合済 = 安全)
- **local branch rename**: `v4-redo-broad` → `archive/v4-redo-broad-merged-2026-05-01` (3 archive branches 統一 namespace)
- **origin 同期**: main 14 commits push (`b4da1fd..aa40934`) + origin v4-redo-broad delete + new archive branch push + tag 作成 + push
- **新規 archive branch**: `archive/v4-redo-broad-merged-2026-05-01` (commit `b6b850c`、req phase V4 redo broad endpoint 保全、origin push 済)
- **新規 tag**: `v4-redo-broad-merged-2026-05-01` (= `b6b850c`、3 archive tags pattern 整合 = `v3-evidence-foundation-7th-session` / `v4-baseline-brief-2026-04-29` / `v4-redo-broad-merged-2026-05-01`)

### 4.6 foundation tasks phase ad-hoc V4 (commit `021ec65` + cross-spec C-1 v1.2、14th)

- **内容**: A-1 tasks phase 全 3 spec approve に foundation tasks.md v1.2 を含む
  - 検出 18 件 (primary 10 + adversarial 8 独立)
  - 分類: must_fix 1 / should_fix 5 / do_not_fix 12
  - 採択率 5.6% / 過剰修正比率 66.7% / should_fix 比率 27.8%
  - judgment override 7 件 / primary↔judgment disagreement 3 件 (P3, P4, P5) / adversarial↔judgment disagreement 1 件 (A4)
  - V4 修正否定 prompt 機能 75% (adversarial 自己分類 do_not_fix 6/8)
  - apply 6 件 (must_fix A4 + should_fix P1 + P2 + P3 + P6 + A6、user 三ラベル提示で全 apply)
  - cross-spec review C-1 fix で v1.2 確定 = `jsonschema>=4.18` version pin 同期 (Task 1 description) を追加 apply
  - Step 3.5 sanity review subagent verdict = `PASS` (1 pass で完走)
- **保全 location**:
  - main `.kiro/specs/dual-reviewer-foundation/{tasks.md, spec.json}` (commit `021ec65` + cross-spec C-1 fix で v1.2)
  - tasks.md v1.2 + spec.json (`phase: tasks-approved` + `approvals.tasks.approved: true` + `ready_for_implementation: true`)
- **関連 dev-log**: `docs/dual-reviewer-log-4.md` (14th セッション、user 管理)

### 4.7 design-review tasks phase ad-hoc V4 (commit `021ec65`、14th)

- **内容**: design-review tasks.md v1.1 確定
  - 検出 15 件 (primary 8 + adversarial 7 独立)
  - 分類: must_fix 2 / should_fix 5 / do_not_fix 8
  - 採択率 13.3% / 過剰修正比率 53.3% / should_fix 比率 33.3%
  - judgment override 5 件 / primary↔judgment disagreement 1 件 (P3) / adversarial↔judgment disagreement 2 件 (A6 should_fix → must_fix / A7 should_fix → do_not_fix)
  - V4 修正否定 prompt 機能 28.6% (adversarial 自己分類 do_not_fix 2/7、foundation 75% より低下 = adversarial が修正必要性高めに評価傾向)
  - apply 7 件 (must_fix A1 + A6 + should_fix P4 + P5 + P6 + A3 + A4、user 三ラベル提示で全 apply)
  - Step 3.5 sanity review subagent verdict = `NEEDS_FIXES` 10 件 → 1 repair pass で 9 件 integrate (#6 sequential ordering で sufficient のため skip)
- **保全 location**:
  - main `.kiro/specs/dual-reviewer-design-review/{tasks.md, spec.json}` (commit `021ec65`)
  - tasks.md v1.1 + spec.json (`phase: tasks-approved` + `approvals.tasks.approved: true` + `ready_for_implementation: true`)
- **関連 dev-log**: `docs/dual-reviewer-log-4.md` (14th セッション)

### 4.8 dogfeeding tasks phase ad-hoc V4 (commit `021ec65`、14th)

- **内容**: dogfeeding tasks.md v1.1 確定 (consumer-only spec、Operational Protocol + Research Script Hybrid pattern)
  - 検出 14 件 (primary 6 + adversarial 8 独立)
  - 分類: must_fix 5 / should_fix 3 / do_not_fix 6
  - 採択率 35.7% / 過剰修正比率 42.9% / should_fix 比率 21.4%
  - judgment override 3 件 / primary↔judgment disagreement 2 件 (P3 INFO → must_fix / P4 WARN → must_fix) / adversarial↔judgment disagreement 2 件 (A2 should_fix → must_fix / A3 must_fix → should_fix)
  - V4 修正否定 prompt 機能 37.5% (adversarial 自己分類 do_not_fix 3/8)
  - apply 8 件 (must_fix P3 + P4 + A1 + A2 + A6 + should_fix P6 + A3 + A8、user 三ラベル提示で全 apply)
  - Step 3.5 sanity review subagent verdict = `NEEDS_FIXES` 7 件 → 1 repair pass で 7 件 integrate (Task 2 削除統合 + 7.2/7.3 dependency 修正 + Task 7 design-review v1.2 gate task 追加 + Task 1 boundary clean + README order 後置 + Req 2.5 mapping 追加)
  - Decision 7 = A-1 implementation phase = Python script 実装 (Task 1-6) + A-2 = Spec 6 適用 (Task 8) の 2 segment 分担
- **保全 location**:
  - main `.kiro/specs/dual-reviewer-dogfeeding/{tasks.md, spec.json}` (commit `021ec65`)
  - tasks.md v1.1 + spec.json (`phase: tasks-approved` + `approvals.tasks.approved: true` + `ready_for_implementation: true`)
- **関連 dev-log**: `docs/dual-reviewer-log-4.md` (14th セッション)

### 4.9 cross-spec review (commit `021ec65` 統合、14th 末)

- **内容**: 3 spec tasks phase 完走後 (foundation v1.1 + design-review v1.1 + dogfeeding v1.1) の 20 観点 integrity check
  - **Group A 確認済整合 17 件** (install location 統一 / resolve mechanism (CLI flag + env fallback) / cross-file `$ref` resolver foundation Task 7.5 集約 / Consumer 拡張 4 field / Severity 4 水準 / Python 3.10+ + 2 スペースインデント / Phase A scope / Decision 7 解釈 / sample 1 round 通過 test / 3 系統対照実験 treatment flag / 8 月 timeline / Phase B fork 5 条件 / bilingual heading / frontmatter / tasks-phase ad-hoc V4 caveat 4 件 / dispatch payload 構造 / forced_divergence vs fix-negation 役割分離) = 各 spec tasks 内で確定済 (design phase 6 件から大幅増 = tasks phase で contract integrity 厚め確認)
  - **Group B 既存対応済 2 件** (design-review v1.2 revalidation cycle 3 改修要件 / TDD 規律) = 3 spec で適切に対応済
  - **Group C 新規 implication 1 件 全 apply**: C-1 = foundation tasks Task 1 で `jsonschema>=4.18` version pin 同期適用 (= design-review tasks v1.1 P6 apply の cross-spec implication、Task 7.5 cross-file `$ref` resolver で `Registry` 必須)
  - **不整合 0 件**
  - **2 phase 比較 (Group 分布)**: design phase = Group A 6 / B 11 / C 3 (各 spec 内で部分確定、3 spec 横断で軽微 implication 残) vs tasks phase = Group A 17 / B 2 / C 1 (= design phase で確定した contract integrity が tasks phase で広く再確認、Group C は version pin 同期のみ)。両 phase で 不整合 0 件、Group C 軽微 implication 全 apply で完走 = pattern 安定性確認
- **保全 location**:
  - main `.kiro/specs/dual-reviewer-foundation/tasks.md` v1.2 (cross-spec C-1 fix 統合)
  - 同 commit `021ec65` で 3 spec tasks.md + spec.json approve + cross-spec C-1 fix bulk apply (= 単一 commit 一括統合)
- **関連 dev-log**: `docs/dual-reviewer-log-4.md` (14th セッション)

### 4.10 3 spec tasks phase 累計 V4 metric trend (14th 末確定)

| metric | foundation | design-review | dogfeeding | trend |
|--------|------------|---------------|------------|-------|
| 検出件数 | 18 | 15 | 14 | 安定 (14-18) |
| 採択率 | 5.6% | 13.3% | 35.7% | **連続改善 (+7.7pt → +22.4pt = +30.1pt 累計)** |
| **過剰修正比率** | **66.7%** | **53.3%** | **42.9%** | **連続改善 (-13.4pt → -10.4pt = -23.8pt 累計)** |
| should_fix 比率 | 27.8% | 33.3% | 21.4% | dogfeeding で減 (must_fix へ shift) |
| V4 修正否定 prompt 機能 | 75% | 28.6% | 37.5% | adversarial 自己 do_not_fix 比率 |
| judgment override | 7 | 5 | 3 | 連続減 (semi-mechanical mapping default 適合性向上) |

3 spec 連続で過剰修正比率改善 (66.7% → 53.3% → 42.9%) + 採択率改善 (5.6% → 13.3% → 35.7%) = V4 protocol 構造的有効性の **3 spec 連続再現実証** (= tasks phase ad-hoc 適用でも再現)。

**6 spec instance 累計 (design + tasks 2 phase) 過剰修正比率 連続改善**:
- design phase: 81.25% → 58.8% → 40.0% (-41.25pt 累計、12th 末)
- tasks phase: 66.7% → 53.3% → 42.9% (-23.8pt 累計、14th 末)
- = phase 横断 reproducibility 確認 = V4 protocol が偶然 / 1 spec or 1 phase の特殊性ではなく構造的に primary completeness bias を抑制する装置である phase 横断証明

**tasks phase ad-hoc V4 4 caveats** (`data-acquisition-plan.md` v0.4 §5 整合、paper limitations 明示用):
- (1) ad-hoc 観点 = Layer 2 tasks extension 未実装 (Phase B-1.1 scope) で primary が boundary 違反 / dependency cycle / granularity / AC 網羅 / executability / verifiability の 6 観点 ad-hoc 列挙
- (2) phase 横断 strict comparability 問題 = design phase 10 ラウンド観点 vs tasks phase ad-hoc 観点で coverage 異なり phase 間 absolute 比較は spurious comparison リスク、relative trend (= 同 spec 内 single → dual → dual+judgment) のみ valid
- (3) forced_divergence prompt design phase optimization = adversarial subagent dispatch で tasks phase 用 ad-hoc 微調整 (= primary's task structure 暗黙前提置換)
- (4) paper rigor 保証 = preliminary cross-phase verification 補助 evidence、systematic tasks phase evidence は Phase B-1.1 (`dr-tasks` skill 実装後) で paper revision に活用

### 4.11 14th 末 cleanup (data-acquisition-plan v0.4 + memory updates、commit `aed0b2b`)

- **`data-acquisition-plan.md` v0.3 → v0.4 update** (commit `aed0b2b`):
  - Level 1 §3.1: tasks phase ad-hoc V4 raw data 3 [ ] checkbox 化 (3 spec metric 数値含む)
  - Level 2 §3.2: tasks phase metrics 3 [ ] checkbox 化 + 3 spec 累計 trend table 追加
  - Level 3 §3.3: H1+H2+H3 cross-phase robustness 補助 [x] 化 (H4 wall-clock は別 metric 化要、A-2 期間取得予定)
  - §4 Timeline A-1 tasks phase: ⏳ → ✅ 完了 + cross-spec review C-1 checkbox [x] 化
  - 変更履歴 v0.4 entry 追加
- **memory updates** (user dir `/Users/keno/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/`、git 追跡対象外):
  - `feedback_v4_design_phase_3spec_completion.md` → "12-14th 末 3 spec × 2 phase = 6 spec instance" rename + tasks-phase evidence 拡張
  - `feedback_cross_spec_review_pattern.md` → "design + tasks 2 phase 適用済" rename + 14th tasks phase Group A/B/C 結果追記
  - `MEMORY.md` index 2 line update
- **origin push** = `e327847..aed0b2b` 2 commits push 完了、main = origin/main 同期済

---

## 5. 将来追加予定 (placeholder、A-1 implementation phase 後 + A-2 dogfeeding 完走後 fill)

### 5.1 A-1 implementation phase evidence (15th-18th セッション完走、main 統合済、v0.6 fill)

#### 5.1.1 design-review v1.2 改修 cycle + Level 6 infrastructure (15th セッション、commits `15cffa6` + `7722f9e`)

- **内容**: design-review spec の req + design + tasks 整合化 cycle (= treatment flag + timestamp 必須付与 + commit_hash payload 受領、dogfeeding/design.md Decision 6 整合) + data-acquisition-plan v1.0 改版 (Claim D + Level 6 schema 新設) + Level 6 記録 infrastructure 立ち上げ
- **commits**:
  - `15cffa6` design-review v1.2 改修: requirements (AC10/AC8/AC9 追加) + design.md v1.2 + tasks.md v1.1 + spec.json updated_at
  - `7722f9e` data-acquisition-plan v1.0 + `rework_log.jsonl` 雛形 (0 bytes、append-only target)
- **保全 location**: main branch (origin push 済)
  - `.kiro/specs/dual-reviewer-design-review/{requirements.md, design.md, tasks.md, spec.json}` v1.2
  - `.kiro/methodology/v4-validation/data-acquisition-plan.md` v1.0
  - `.kiro/methodology/v4-validation/rework_log.jsonl` (空 file)
- **数値要約**: data-acquisition-plan v1.0 = Claim D 追加 (4 主張化) + Level 6 schema (M1 Volume / M2 Scope / M3 Discovery Phase / M4 Root Cause) + 3 data source (Data 1 auto / Data 2 manual / Data 3 任意 A-2 から導入) + per-line schema + baseline 制約 3 件 + checkbox tracker (A-1 4 件 + A-2 2 件) + Claim D 評価基準 3 段階 (Strong / Moderate / Weak)
- **関連 dev-log**: `docs/dual-reviewer-log-5.md` (15th)

#### 5.1.2 A-3 plan 確定 + A-1 implementation Step 1 = foundation 物理 file 生成 (16th セッション、commits `7774860` / `375809b` / `a96482b` / `8cd8bf8`)

- **内容**: A-3 plan 確定 (= triangulation evidence batch 新設、論文 reviewer 想定批判 1 = self-referential metric mitigation、TODO 反映のみで本 16th 末は plan 改版 commit なし、17th `8876328` で v1.1 改版に正式反映) + A-1 implementation phase Step 1 = foundation 物理 file 生成 (4 commit、56 tests pass、TDD 1 cycle)
- **commits**:
  - `7774860` Task 1+2 install location skeleton + portable static artifacts
  - `375809b` Task 3+4 = 5 JSON schemas + Layer 1 framework + 2 templates
  - `a96482b` Task 5+6 dr-init skill impl + unit tests (TDD)
  - `8cd8bf8` Task 7 integration tests (5 sub-task、56 tests pass)
- **保全 location**: main branch (origin push 済)
  - `scripts/dual_reviewer_prototype/framework/layer1_framework.yaml`
  - `scripts/dual_reviewer_prototype/patterns/{seed_patterns, fatal_patterns}.yaml`
  - `scripts/dual_reviewer_prototype/prompts/judgment_subagent_prompt.txt`
  - `scripts/dual_reviewer_prototype/skills/dr-init/{SKILL.md, bootstrap.py}`
  - `scripts/dual_reviewer_prototype/tests/{conftest.py, dr_init/, integration/{dr_init_consumer, framework_structure, relative_path, schema_complex, v4_sync}/, schemas/}`
  - `scripts/dual_reviewer_prototype/README.md`
- **数値要約**: 4 commit / ~25 file / ~1500 insertions / 56 tests pass / TDD 1 cycle (dr-init)
- **関連 dev-log**: `docs/dual-reviewer-log-5.md` (15th-16th)

#### 5.1.3 data-acquisition-plan v1.1 + A-1 implementation Step 2 (design-review) + Step 3 (dogfeeding) (17th セッション、10 commit、151 tests pass)

- **内容**: data-acquisition-plan v1.0 → v1.1 改版 (= 16th 末確定 A-3 plan + framing 変更 + 4 axes 化 + Phase A 終端 redefine) + A-1 implementation Step 2 = design-review 物理 file 生成 (5 commit、113 tests cumulative、TDD 3 cycle = dr-judgment / dr-log / dr-design) + A-1 implementation Step 3 = dogfeeding 物理 file 生成 (4 commit、151 tests cumulative、TDD 3 cycle = metric_extractor / figure_data_generator / phase_b_judgment)
- **commits**:
  - `8876328` docs(methodology): data-acquisition-plan v1.1 (155 insertions / 10 deletions)
  - `2f104fa` design-review Task 1+2 scaffolding + design_extension.yaml + forced_divergence_prompt.txt
  - `85f51f9` design-review Task 3+6.6 dr-judgment skill impl + 12 unit tests
  - `bdda6dd` design-review Task 4+6.3-6.5 dr-log skill impl + 11 unit tests
  - `7541896` design-review Task 5+6.1-6.2 dr-design skill impl + 13 unit tests
  - `4e4a33d` design-review Task 7 integration tests (5 sub-task、113 tests pass)
  - `06bcdcf` dogfeeding Task 1+2 scaffolding + helpers + metric_extractor.py + 13 unit tests
  - `367a7aa` dogfeeding Task 3 figure_data_generator.py + 9 unit tests
  - `0234251` dogfeeding Task 4 phase_b_judgment.py + 11 unit tests
  - `3d72d56` dogfeeding Task 5+6 README full + 2 integration tests (151 tests pass)
- **保全 location**: main branch (origin push 済 17th 末 endpoint = `3d72d56`)
  - `scripts/dual_reviewer_prototype/extensions/design_extension.yaml`
  - `scripts/dual_reviewer_prototype/prompts/forced_divergence_prompt.txt`
  - `scripts/dual_reviewer_prototype/skills/{dr-design, dr-log, dr-judgment}/{SKILL.md, *.py}`
  - `scripts/dual_reviewer_prototype/tests/{dr_design/, dr_log/, dr_judgment/, integration/design_review/{conftest.py, path_resolution, prompt_embed, role_separation, skill_flow, three_treatment}/}`
  - `scripts/dual_reviewer_dogfeeding/{helpers, metric_extractor, figure_data_generator, phase_b_judgment}.py + README.md + tests/`
- **数値要約**: 17th 累計 = 10 commit / 31 file / 3685 insertions / 8 deletions / **151 tests pass** (foundation 56 + design-review 57 + dogfeeding 38)、TDD 6 cycle 連続記録 (Step 2 = 3 + Step 3 = 3)
- **関連 dev-log**: `docs/dual-reviewer-log-5.md` (17th)

#### 5.1.4 data-acquisition-plan v1.2/v1.3 + 17th 末持ち越し cleanup (18th セッション開始、commits `87e3047` + `fd55902` + `5f27a21`)

- **内容**: 18th セッション開始 = (a) user 指摘「rework_log = 0 は self-report か機械検証か」契機 → data-acquisition-plan v1.2 = Data 2 operational guide + framing 精緻化注記 / (b) 17th 末持ち越し未 commit 整理 = settings.local.json (permission allowlist 23 行追加) + docs/dual-reviewer-log-1~5.md (modified 2 + untracked 3) / (c) user 議論「dual-reviewer は design phase 専用」誤認識整理 → data-acquisition-plan v1.3 = A-2 phase 3 段構成 (A-2.1 Design / A-2.2 Tasks ad-hoc V4 / A-2.3 Impl Level 6 / A-2 終端) で §4 と §3.6 整合化
- **commits**:
  - `87e3047` data-acquisition-plan v1.2 = Data 2 operational guide + framing 精緻化注記 (35 insertions)
  - `fd55902` 17th 末持ち越し cleanup (= settings.local.json + docs/dual-reviewer-log-1~5.md、6 file / 7797 insertions / 40 deletions)
  - `5f27a21` data-acquisition-plan v1.3 = A-2 phase 3 段構成展開 (31 insertions / 2 deletions)
- **保全 location**: main branch (origin push 済 18th 開始 endpoint = `5f27a21`)
  - `.kiro/methodology/v4-validation/data-acquisition-plan.md` v1.3
  - `.claude/settings.local.json`
  - `docs/dual-reviewer-log-{1,2,3,4,5}.md`
- **数値要約**: 18th 累計 (本セッション) = 3 commit / 8 file / 7863 insertions / 42 deletions、data-acquisition-plan v1.3 = A-2 phase の正確な scope 整理 (= "dual-reviewer skill は design phase 専用、V4 protocol は phase 横断適用可能、Level 6 観測は impl phase passive" の 3 段分離)
- **関連 dev-log**: `docs/dual-reviewer-log-5.md` (18th 開始反映待ち)

#### 5.1.5 sample 1 round 通過 test status (= A-2 統合 defer)

- **元 plan** (data-acquisition-plan §4 A-1 implementation phase entry L509): foundation `dr-init` で Spec 6 working directory bootstrap → design-review `dr-design` (Round 1 のみ、treatment="dual+judgment") で Step A → B → C → D 全完了 + dr-log JSONL 1 entry 以上 schema validate 成功 + V4 §2.5 三ラベル提示 yaml stdout 出力 の 3 条件全達成
- **状態**: ⏸️ defer
- **justification**: Spec 6 (`rwiki-v2-perspective-generation`) 休止により本 spec implementation phase scope では実施不可、dogfeeding spec Task 8 = A-2 phase で execute (= TODO L86-87 + dogfeeding tasks.md Task 8 (a) 整合)
- **統合先**: dogfeeding tasks.md Task 8 = A-2 phase の (a) Spec 6 適用 + dr-init bootstrap (Spec 6 working directory) + dual-reviewer prototype 動作確認 (Req 1.1-1.6) に統合
- **関連 dev-log**: `docs/dual-reviewer-log-5.md` (17th = defer 確定)

#### 5.1.6 Level 6 rework_log status (= A-1 impl 0 events / A-2.1 design 44 events、Claim D vs Claim B/C 解釈分離)

- **状態 (29th 末)**: 44 entries (= R-spec-6-1 ~ R-spec-6-44、A-2.1 design phase Round 1-10 累計、treatment=dual+judgment のみ)
- **記録範囲**: 16th 末 (foundation Step 1 着手) ~ 29th 末 (Round 10 完走)
- **2 phase 分離 (Claim D vs Claim B/C 解釈分離、29th 末識別)**:
  - **A-1 implementation phase (16th-17th)**: **0 events** = upstream artifact 改版 物理的 0 件 (Data 1 commit pattern auto 機械検証済 = `git log --name-status -- .kiro/specs/dual-reviewer-{foundation,design-review,dogfeeding}/` 完全空)。**Claim D primary evidence = strong** (= V4 review が impl phase で破綻しない signal)
  - **A-2.1 design phase (20th-29th)**: **44 events** = design phase **内** V4 review process rework (= cross-Round propagation + cross-spec inconsistency + AC orphan 等の design fix events、全件 `discovered_phase=pre-impl` + `rework_target=design`)。**Claim D primary evidence ではない** (= post-approve impl rework ではなく pre-impl design fix process 観測)、**Claim B/C functioning evidence = V4 review process が design phase で active 検出 + 修正 cycle を回した signal** (= adaptive 用法、§3.6 Level 6 schema を design phase に適用)
- **44 events 内訳 (29th 末)**: v4-miss 43 件 / external 1 件、structural 33 件 / cosmetic 11 件、single-spec 41 件 / cross-spec 3 件、全件 pre-impl + rework_target=design
- **Round 別 events 数**: Round 1: 3 / 2: 4 / 3: 6 / 4: 4 / 5: 4 / 6: 2 / 7: 3 / 8: 7 / 9: 10 (Round 別最多更新) / 10: 1 = **Round 別 variance あり** (観点難易度依存)
- **A-2.3 impl phase (= Spec 6 implementation phase)** (v0.9 update = critical path 外し): ⏸️ Phase B-1.x post-paper supplementary evidence として defer (= 論文 draft 着手の前提条件にしない、Spec 6 implementation 完了時点で paper revision 用補強 data として後付け、data-acquisition-plan v1.6 §3.6 Claim D primary evidence 構成 + §4 A-2.3 entry 整合)
- **§3.7.6 re-impl phase (v0.9 新設、Claim D primary evidence の主要 source)**: ⏸️ A-3 batch 内、3 sample (Phase field / 3D 熱伝導 / Arduino IoT) の re-implementation phase で発生する rework events を Level 6 schema で観測、Level 6 観測 overhead +0-3h per sample (= rework_log.jsonl append per event)、§5.5.6.1-3 entries 整合
- **Claim D primary evidence 構成 (v0.9 update、6 spec instance)**:
  - **A-1 全 implementation phase**: 3 spec self-dogfooding (Python、forward-fresh-spec)、現状 0 events strong evidence
  - **§3.7.6 re-implementation phase**: 3 sample external project (Julia or C++ / Julia or C++ / Arduino C、reverse-engineered-spec)、A-3 batch 内で取得予定
  - = **合計 6 spec instance** (= sample size 倍増 + cross-project transfer + 言語 diversity + ground truth-anchored 補強)
  - sub-group reporting 必須: forward-fresh (= A-1) vs reverse-engineered (= §3.7.6) で別 metric 計算 + reverse-engineering 5 source bias を paper Limitations sub-section で acknowledge
- **解釈 (v0.9 update)**:
  - Claim D primary evidence = A-1 全 impl + §3.7.6 re-impl の events、weak signal (= TDD cycle / DRY refactoring / SKILL.md role 精緻化等) は schema 範囲外
  - Claim B/C functioning evidence = A-2.1 design phase events = V4 review が design fix を generate する pattern observation
  - **論文 framing 必要**: 2 evidence 種別 (Claim D primary vs Claim B/C functioning) を Limitations / Validity threats section で disambiguate + forward-fresh / reverse-engineered sub-group 比較を Claim D primary metric narrative で明示
- **保全 location**: `.kiro/methodology/v4-validation/rework_log.jsonl` (44 lines、append-only)

### 5.2 A-2 dogfeeding 結果 (3 段構成、A-2 完走時に本 catalog §5.2 に追記予定、v0.6 = data-acquisition-plan v1.3 §4 整合化)

A-2 phase = Spec 6 (`rwiki-v2-perspective-generation`) を題材に **3 phase 段構成**で evidence acquisition (= data-acquisition-plan v1.3 §4 A-2.1/A-2.2/A-2.3 + 終端 整合)。Spec 6 Design = systematic main / Tasks = ad-hoc V4 補助 (option) / Impl = Level 6 passive 観測 (Claim D)。

#### 5.2.1 Spec 6 Design phase (= 主要 evidence、systematic、必須、論文 figure 1-4)

- Spec 6 全 Round (1-10) × 3 系統対照実験 = 30 review session (= treatment ∈ {single, dual, dual+judgment})
- **branch 戦略 (v0.10 新設、data-acquisition-plan v1.7 §3.6 B4 + §4 A-2.1 整合)**: 全 treatment は **pristine state `285e762`** (= 19th sub-step 2 = Spec 6 design.md 起草直後) を起点として独立 branch で完走 = paper rigor 確保のための confounding 排除。第 1 系統 (`treatment=dual+judgment`、main) = 完走済 (20-29th、`6e26aa8` ~ `f6bac54`)。第 2 系統 (`treatment=single`) = 30th 以降に new branch `treatment-single` で `285e762` 起点に Round 1-10 完走。第 3 系統 (`treatment=dual`) = 第 2 系統完走後に new branch `treatment-dual` で同様完走。Level 6 events は各 treatment 別 file/sub-group key で記録 (= confound 回避)。3 branch 統合分析で comparison-report v0.2 final 集約 (= ablation figure 成立)。Spec 6 design.md 最終 state は main の post-Round 10 (`f6bac54`) を採用、他 2 treatment branch は paper data source archive として保持 (delete 禁止)
- JSONL log 蓄積 (foundation 共通 schema 2 軸並列 + 本 spec consumer 拡張 4 field、30 entry / 3 系統 × 10 round)
- `metric_extractor.py` 実行 → `dogfeeding_metrics.json` 生成 (= 12 軸 metric)
- `figure_data_generator.py` 実行 → 4 figure data file 生成 (= figure 1-3 + ablation、論文 core evidence)
- `phase_b_judgment.py` 実行 → `comparison-report.md` §12 append (= 5 条件評価 + V4 仮説検証 H1-H4 + evidence_references)

##### 5.2.1.5 A-2.1 partial completion = treatment=dual+judgment 全 10 ラウンド完走 (29th 末、A-2.1 1/3 終端、v0.8 partial fill)

20th セッション着手 (Round 1) ~ 29th セッション完走 (Round 10) で **treatment=dual+judgment** 全 10 ラウンド完走。残 20 review session = treatment=single (Round 1-10) + treatment=dual (Round 1-10)、推定 1-2 month batch。

**累計 metric (treatment=dual+judgment、10 ラウンド aggregate)**:

| metric | 値 | 備考 |
|--------|----|------|
| 検出件数 (judgment unique) | 69 | primary 48 + adversarial 真の独立 17 + adversarial 4 (補強他) - merge 後 unique |
| primary detection 累計 | 48 | Round 別 = 0/3/5/5/5/6/7/7/7/3 (観点難易度依存、Round 1 = 0 + Round 7-9 = 7 過去最多 tie + Round 10 = 3 過去最低 tie) |
| adversarial detection 累計 | 54 | confirmation + supplementary + 真の独立検出 |
| 採択率 (must_fix) | **30.4%** (21/69) | dogfeeding design 20.0% / req phase 5.6% より改善 |
| **過剰修正比率** (do_not_fix) | **33.3%** (23/69) | **V3 baseline 50% 比 -16.7pt 改善** |
| should_fix 比率 | 36.2% (25/69) | escalate user 介入機会確保 |
| escalate 件数 | 4 | Round 3 (1) + Round 5 (1) + Round 6 (1) + Round 7 (1) = path 1-2 適用 case |
| judgment override 件数 | 27 | semi-mechanical mapping default 妥当性精査 cycle、各 Round 0-4 件分布 |

**4 spec instance 累計 design phase 過剰修正比率 連続改善**:

| spec | design phase 過剰修正比率 | 累計改善 |
|------|---------------------------|----------|
| foundation | 81.25% | (baseline) |
| design-review | 58.8% | -22.45pt |
| dogfeeding | 40.0% | -41.25pt |
| **Spec 6 (A-2.1 1/3 終端)** | **33.3%** | **-47.95pt** |

= V4 構造的有効性 **4 spec instance 連続再現実証** (= 12-29th 累計、A-2.1 1/3 終端で Spec 6 dogfeeding 40.0% より +6.7pt 改善継続)。

**v4-miss core evidence 累計** (= primary 0 件 + adversarial 真の独立検出、Round 1-10):

- **core (judgment must_fix upgrade、論文 reviewer 想定批判 1 への direct rebuttal evidence)** = 累計 **10 件**
  - Round 1: A-1 (R8.2 Performance Strategy) / A-2 (R12.4 Buffer Flush Strategy) / A-4 (R10.9 Priority Strategy) = 3 件
  - Round 2: A-2 / A-3 = 2 件
  - Round 3: A-6 / A-7 = 2 件
  - Round 4: A-2 = 1 件
  - Round 5: A-4 = 1 件
  - Round 9: A-8 (Flow 2 Mermaid 順序逆転、fatal_pattern data_loss hit) = 1 件
- **minor (judgment should_fix upgrade、supplementary)** = 累計 **7 件**
  - Round 7: A-5 / A-7 = 2 件
  - Round 8: A-2 / A-3 = 2 件
  - Round 9: A-9 / A-10 = 2 件
  - Round 10: A-4 (Migration Strategy rollback 方針、fatal_pattern destructive_migration 逆向き hit) = 1 件
- **合計 = 17 件 v4-miss evidence** = adversarial subagent の primary 見落とし補完機能 evidence (= Claim A 補強)

**fatal_pattern hits 累計 (Chappy P0 quota 機能 evidence)** = **5 件**:
- path_traversal × 3 (Round 7 P-2/P-3、Round 9 P-2/P-3 = test 戦略 layer (b))
- data_loss × 1 (Round 9 A-8 = Flow 2 Mermaid 順序逆転)
- destructive_migration 逆向き × 1 (Round 10 A-4 = Migration rollback 方針不在)

**escalate 解決手段 5 path 確立 + path 5 候補 4 連続再現 evidence**:

- **path 1**: user 判断必須 (Round 3 P-5 = 22nd / Round 6 P-1 = 25th)
- **path 2**: 事実確認による premise 誤り判定 → do_not_fix (Round 4 A-3 = 23rd)
- **path 3**: adversarial 根拠 + judgment override による should_fix 降格 (Round 5 P-3 = 24th + **Round 10 P-1/P-2/P-3 = 連続 3 件 = 過去最多再現** = 29th、累計 4 件)
- **path 4**: rule_2 must_fix 降格 (Round 6 P-4 = 25th + Round 7 P-2/P-3 = 26th、累計 3 件) + path 4 variant (Round 8 P-2 = primary should_fix → judgment must_fix 昇格 = 27th)
- **path 5 候補**: judgment 5 field 評価で escalate 解除 (Round 8 = primary escalate 3 件全部 judgment 降格 / Round 9-10 = primary escalate 0 件 = **escalate=0 streak 4 連続再現 (Round 7-10) = 過去最長**)

**Round 10 V4 過剰修正 bias 抑制機能 evidence (= Claim B strong evidence、29th 末新規)**:

- primary single なら +3 修正 (P-1/P-2/P-3 全 should_fix 採択)
- dual+judgment net 1 修正 (P-1/P-2/P-3 = do_not_fix skip + A-4 = should_fix 採用 adversarial 独立検出)
- = **過剰修正 bias 67% 抑制 + 検出漏れ 1 件補完 (A-4) = V4 機能本質発揮 round**

**Sub-group analysis 規律遵守状況 (v0.7 §5.2.5 整合)**:
- ✅ explicit labeling: 全 dev_log entry に `spec_source: forward-fresh` field 付与 (Round 1-10 全件)
- ✅ spec characteristic descriptive metric: AC 数 132 / 文字数 1266 行 (post-Round 10) / Design Decisions 数 7 / Architecture Pattern Evaluation 4 件 / 起草所要時間 (sub-step 2 内 19th 計測) 記録済
- ⏸️ §3.7.6 reverse-engineered batch との sub-group 比較 = §3.7.6 着手後

**保全 location**:
- `.dual-reviewer/dev_log.jsonl` (10 lines、Round 1-10 entries、treatment=dual+judgment)
- `.kiro/methodology/v4-validation/rework_log.jsonl` (44 lines、Level 6 累計 = R-spec-6-1 ~ R-spec-6-44)
- `.kiro/specs/rwiki-v2-perspective-generation/design.md` (1266 行、post-Round 10 修正済)
- main commits 20 件 (= 各 Round 修正 + log commit、20th-29th endpoint = `3cbefdb`)

##### 5.2.1.6 A-2.1 partial completion = treatment=single 全 10 ラウンド完走 (40th 末、A-2.1 2/3 終端、v0.11 partial fill)

31st セッション着手 (Round 1) ~ 40th セッション完走 (Round 10) で **treatment=single** 全 10 ラウンド完走 (= treatment-single branch 上、pristine state `285e762` 起点)。残 10 review session = treatment=dual (Round 1-10)、推定 1 month batch。

**累計 metric (treatment=single、10 ラウンド aggregate)**:

| metric | 値 | 備考 |
|--------|----|------|
| primary detection 累計 | 46 | Round 別 = 3/3/5/5/5/5/5/5/5/5 (Round 1-2 = 3 件 / Round 3-10 = 5 件 default) |
| 採用累計 | 17 | Round 別 = 2/1/0/1/0/3/2/3/3/2 (40% suppress group = Round 6/8/9/10 = 各 2-3 件採用) |
| skip 累計 | 29 | bias_self_suppression default + dominated 除外 |
| escalate=true 累計 | 17 件 | primary 単独 escalate (= adversarial / judgment skip 系統) |
| **過剰修正比率 (= skip / detect)** | **63.0%** (29/46) | = primary 単独 = adversarial/judgment 補完なし pattern observation |
| Level 6 events 累計 | 17 件 | R-spec-6-1 ~ R-spec-6-17 (treatment-single branch、treatment="single" + branch="treatment-single" sub-group key 付与) |
| design.md 行数増加 | +63 行 | pristine 1150 → post-Round 10 1213 (Round 別 1-2 行 ~ +22 行 = Round 9 max) |

**Round 別 escalate=true 出現率 (= bias_self_suppression default 適用率の逆指標)**:

| Round | 観点 | escalate=true 件数 / 検出 | suppress 率 | metapattern 主軸 + escalate 必須条件 hit |
|-------|------|-------------------------|------------|---------------------------------------|
| 1 | 規範範囲確認 | 3/3 | **0%** | a 規範範囲先取り (escalate 必須条件 normative_scope 直接 hit) |
| 2 | 一貫性 | 1/3 | 67% | b 構造的不均一 |
| 3 | 実装可能性+アルゴリズム+性能 | 0/5 | **100%** | none (impl phase 委譲可) |
| 4 | 責務境界 | 1/5 | 80% | c 文書 vs 実装不整合 (escalate 必須条件 responsibility_boundary 直接 hit) |
| 5 | 失敗モード+観測 | 0/5 | **100%** | b 構造的不均一 |
| 6 | concurrency / timing | 3/5 | 40% | b+c 多軸 (escalate 必須条件 concurrency_safety + responsibility_boundary 多軸同時 hit) |
| 7 | security | 2/5 | 60% | b+c 多軸 (path_traversal fatal_pattern hit + responsibility_boundary 同時 hit) |
| 8 | cross-spec 整合 | 3/5 | 40% | c 主軸 cross-spec (responsibility_boundary + multiple_options_tradeoff 多軸同時 hit) |
| 9 | test 戦略 | 3/5 | 40% | b+c 双方 (responsibility_boundary + normative_scope 多軸同時 hit) |
| 10 | 運用 | 2/5 | 40% | b 5 + c 1 (responsibility_boundary + multiple_options_tradeoff 多軸同時 hit) |

= **observation**: primary subagent が観点 axis 別に escalate 出現 pattern を異にする evidence (sample 10、20 session 完走後の 3 系統比較で評価):
- 規範範囲 (Round 1) = escalate 必須条件 5 種に直接含まれる → 0% suppress
- 構造軸 (Round 2 一貫性、Round 5 失敗モード+観測) = 67-100% suppress
- 実装軸 (Round 3) = impl phase 委譲可で 100% suppress
- 責務境界系 (Round 4 / 6 / 7 / 8 / 9 / 10) = escalate 必須条件 5 種に直接含まれる → 40-80% suppress (= primary が単独で escalate 判定する困難観点 group)

**観察 pattern (= treatment=dual 比較時の predictor)**:

- **既存節拡張 vs 新節新設同型処置 pattern 確立観察**: Round 6 P-1 (Concurrency Boundary 節新設) + Round 7 P-2 (Security Considerations 節 4 軸構造化既存節拡張) + Round 9 P-1 (Cross-spec Contract Tests 節新設) + Round 9 P-2 (TDD 規律節新設) + Round 10 P-2 (Atomic Write 実装パターン sub-heading 新設) = **新節新設 4 件累計** + Round 10 P-1 (Monitoring 既存節拡張 = 2 bullet 追加) = 処置 type 多様性確認
- **forward Adjacent Sync 規律遵守完全実証**: Round 1-10 全件 forward sync (= 本 spec design.md 内自己完結化採択) + 後続 → 先行改版要請 0 件 + dominated 除外案厳格運用 = memory `feedback_adjacent_sync_direction.md` 規律遵守完全実証
- **fatal_patterns hit 累計 (treatment=single)** = 1 件 (Round 7 P-1 path_traversal hit、escalate 反転 = Round 4 P-1 cosmetic skip → Round 7 P-1 fatal_pattern hit escalate=true 反転、観点切替で fresh detect)
- **採取軸保護観察事例 (= 補完深掘り深化系列)**: Round 4 P-1 → Round 7 P-1 → Round 9 P-3 + Round 4 P-4 → Round 7 P-1 → Round 8 P-2 → Round 10 P-1 = caller-callee consistency / responsibility_boundary 軸の独立 detect 系列拡張

**Sub-group analysis 規律遵守状況 (v0.7 §5.2.5 整合)**:
- ✅ explicit labeling: 全 dev_log entry に `spec_source: forward-fresh` field 付与 (Round 1-10 全件)
- ✅ explicit treatment + branch labeling: 全 dev_log + rework_log entry に `treatment="single"` + `branch="treatment-single"` sub-group key 付与 (Round 1-10 全件)
- ✅ spec characteristic descriptive metric: AC 数 132 / 文字数 1213 行 (post-Round 10 single = R-spec-6-17 endpoint) / Design Decisions 数 7 / Architecture Pattern Evaluation 4 件 / 起草所要時間 (sub-step 2 内 19th 計測) 記録済
- ✅ branch 物理分離 + sub-group key 分離 double protection: main の 44 events (第 1 系統 dual+judgment) と treatment-single branch の 17 events (第 2 系統 single) が完全分離維持 = confound 回避

**保全 location**:
- `.dual-reviewer/dev_log.jsonl` (10 lines、Round 1-10 entries、treatment=single = treatment-single branch 上)
- `.kiro/methodology/v4-validation/rework_log.jsonl` (17 lines、Level 6 累計 = R-spec-6-1 ~ R-spec-6-17、treatment-single branch 上)
- `.kiro/specs/rwiki-v2-perspective-generation/design.md` (1213 行、post-Round 10 single 修正済 = R-spec-6-17 endpoint `850fc51`)
- treatment-single branch endpoint = `33e1a12` (40th 末 push 済 = `86e7760..33e1a12`)、累計 commits = 31st-40th で多数

**残作業 (41st 以降、A-2.1 残 1/3、v0.11 update = treatment=single 完走反映)**:
- treatment=dual (Round 1-10) = new branch `treatment-dual` で pristine state `285e762` 起点に完走 = 推定 10-20 commit batch、Level 6 events 別 sub-group key (treatment="dual" + branch="treatment-dual") 記録
- A-2.1 完走時 = 3 branch 統合 = `metric_extractor.py` + `figure_data_generator.py` + `phase_b_judgment.py` 実行 → comparison-report v0.2 final 集約 (= 3 系統 ablation figure 成立、treatment=single 過剰修正比率 63.0% vs treatment=dual+judgment 33.3% vs treatment=dual 比較で adversarial / judgment 各 layer 機能寄与 quantify)

**関連 dev-log**: `docs/dual-reviewer-log-5.md` (15-29th、user 管理) + `docs/sual-reviewer-log-6.md` (30th-、user 管理) + `TODO_NEXT_SESSION.md` (40th 末 slim) + `TODO_HISTORY_through_40th.md` (40th 末新設 archive、repo 追跡)

#### 5.2.2 Spec 6 Tasks phase (= 補助 evidence、V4 ad-hoc 適用、option)

- `/kiro-spec-tasks rwiki-v2-perspective-generation` Skill 経由 + V4 protocol §4 (forced_divergence + Step 1c judgment) 手動再現
- tasks phase metric (= 採択率 / 過剰修正比率 / V4 修正否定率) を 4 spec 目 tasks phase 拡張として記録
- 補助 evidence 役割: phase 横断 reproducibility 補強 (= 14th 累計 6 spec instance design + tasks → Spec 6 拡張で 7 spec instance)
- dr-tasks skill 不在 (= Phase B-1.1 別 spec 化予定) のため manual 適用、推定 cost 数時間-1日

#### 5.2.3 Spec 6 Impl phase (v0.9 update = Phase B-1.x supplementary defer、critical path 外)

**v0.9 update (data-acquisition-plan v1.6 整合)**: A-2.3 を **critical path から外し、Phase B-1.x post-paper supplementary evidence として defer**。Claim D primary evidence は **A-1 (3 spec self-dogfooding) + §3.7.6 (3 sample re-impl phase) = 6 spec instance** で構成 (= §5.1.6 Claim D primary evidence 構成 + §5.5.6.1-3 entries 整合)。

- ⏸️ Spec 6 implementation 完了時点で paper revision 用補強 data として後付け (= 論文 draft 着手の前提条件にしない)
- `rework_log.jsonl` への append (= Data 1 commit pattern auto + Data 2 manual + Data 3 任意、§3.6 Data 2 operational guide v1.2 整合) は既存運用維持、ただし paper draft critical path には含めない
- within-spec rework 内訳分析 (= M1 Volume / M2 Scope / M3 Discovery Phase / M4 Root Cause 比率算出) は Phase B-1.x で実施
- A-1 (3 spec impl) vs §3.7.6 (3 sample re-impl) cross-project 比較が **primary**、A-1 vs A-2.3 は supplementary
- dual-reviewer skill 適用なし、通常の wiki 機能実装 (= perspective-generation 機能の実装作業) を進行しながら observation 継続 (= Spec 6 implementation 自体は別 timeline で進行)

#### 5.2.4 A-2 終端 + 統合分析 (= A-2 完走時)

- A-2 完走時の final analysis = A-1 vs A-2 比較 + Claim D 主張可否判断 (Strong / Moderate / Weak) + paper claim 文言確定
- Spec 6 全 phase approve = Rwiki v2 全 8 spec design phase approve = **A-2 終端** (= Phase A 終端ではない、v1.5 redefine、A-3 + §3.7.6 完走 = Phase A 終端)
- comparison-report v0.2 final 起草準備 (= req + design + A-2 累計集計、A-3 + §3.7.6 完走後に最終版完成)

#### 5.2.5 Sub-group analysis 規律 (v0.7 追加、data-acquisition-plan v1.5 §7 整合)

A-2 evidence 取得時の必須規律 (= 軸 5+6+7 evidence 整合性保護、§5.5 §3.7.6 reverse-engineered batch との sub-group 比較 base):

- **explicit labeling 必須**: A-2 raw data JSONL の per-finding entry に `spec_source: forward-fresh` field 付与 (= A-2 / A-1 全 sample は forward-fresh、§5.5 §3.7.6 sample は `reverse-engineered` ラベル)
- **spec characteristic descriptive metric 記録**: Spec 6 design.md の AC 数 / 文字数 / Design Decisions 数 / 言及 alternative 数 / 起草所要時間 を記録 (= reverse-engineering bias 5 source 定量化方法、§5.5 §3.7.6 entry と並列比較)
- **A-2 metric を sub-group reporting**: A-2 全 metric (= 検出件数 / 採択率 / 過剰修正比率 / disagreement / judgment override / wall-clock / V4 修正否定 prompt 機能) を §5.5 §3.7.6 reverse-engineered metric と並列比較形式で comparison-report v0.2 final に集約

### 5.3 論文 figure 1-3 + ablation evidence (A-2 完走後、本 catalog §5.3 に追記予定)

- figure data file paths (`figure_<n>_data.json` × 4 = `figure_1_data.json` miss_type 分布 / `figure_2_data.json` difference_type 分布 + forced_divergence / `figure_3_data.json` trigger_state 発動率 / `figure_ablation_data.json` dual vs dual+judgment 効果分離)
- ablation 比較対照点 (V3 baseline / V4 attempt 1 / V4 redo broad / V4 design phase + A-2 dogfeeding)
- 配置 path = `.kiro/methodology/v4-validation/`

### 5.4 Phase B fork go/hold 判定 (8 月末 timeline、本 catalog §5.4 に追記予定)

- 判定 evidence (5 条件評価結果 + V4 仮説検証併記)
- decision record (= comparison-report.md §12 Phase B Fork Judgment、section ID `phase-b-fork-judgment-v1`)

### 5.5 A-3 triangulation batch evidence (v0.7 新設、A-3 完走時に本 catalog §5.5 に追記予定、data-acquisition-plan v1.5 §3.7 整合)

A-3 batch = 軸 4-7 (= multi-indicator convergence + ground truth + forward-reverse spec + 言語 diversity) の triangulation evidence 取得。論文 reviewer 想定批判 1+2+3+5+8+9 同時 mitigation evidence。Phase A 終端 redefine = A-3 + §3.7.6 完走 = 論文 draft 着手 timing (data-acquisition-plan v1.5)。

#### 5.5.1 §3.7.1 forward-fresh-spec sample (= cross-project transfer + 軸 6 forward 側独立必須 sample)

- フルスクラッチ project (= 別 domain、規模 + 複雑度 = dual-reviewer 同程度) の brief + req + design phase に V4 適用
- per-finding raw data + per-system metrics + spec characteristic descriptive metric (= AC 数 / 文字数 / Design Decisions 数 / 言及 alternative 数 / 起草所要時間)
- §5.5.6 §3.7.6 reverse-engineered batch との sub-group 比較 base (= 軸 6 forward / reverse 比較の base sample)
- explicit label = `spec_source: forward-fresh`、cost 6-12h
- 配置 path = `.kiro/methodology/v4-validation/a3_batch/forward_fresh/`

#### 5.5.2 §3.7.2 multi-vendor LLM cross-validation evidence

- dual-reviewer 3 spec design phase finding set (= 12th 末取得済 累計 48 件) を base に GPT-4 + Gemini judgment subagent 投入
- 3-vendor agreement matrix (= must_fix / should_fix / do_not_fix の 3 ラベル合致率、per-finding) + disagreement qualitative analysis
- 配置 path = `.kiro/methodology/v4-validation/a3_batch/multi_vendor/`、cost 3-6h

#### 5.5.3 §3.7.3 mutation testing evidence (constructed positive control)

- Spec 6 design.md に mutation 5-10 件 inject (= AC 矛盾 / 責務境界違反 / dependency cycle / 規範 outsource 化 / interface 不整合 等の defect type)
- mutation 適用版 × N+1 バリアントに V4 protocol 適用 (= dual+judgment 系統 only)
- sensitivity (= true positive rate) + specificity (= true negative rate) → ROC-like figure 6 data
- 配置 path = `.kiro/methodology/v4-validation/a3_batch/mutation/`、cost 7-10h

#### 5.5.4 §3.7.4 multi-run reliability evidence (reproducibility)

- V4 protocol を Spec 6 に対し 3-5 random seed で再実行
- per-seed finding set + per-seed 3 ラベル分布 + inter-run agreement matrix (= ≥ 80% で structural property evidence)
- 配置 path = `.kiro/methodology/v4-validation/a3_batch/multi_run/`、cost 3-5h

#### 5.5.5 §3.7.5 A-3 evidence convergence judgment (Phase A 終端 trigger)

- 6 indicators の convergence judgment (= multi-vendor + mutation + multi-run + cross-project + Level 6 + forward-reverse sub-group 比較)
- convergence verdict (= convergent / mixed / non-convergent) + narrative を `comparison-report.md` 最終版に append (= section ID `triangulation-convergence-judgment-v1.5`)

#### 5.5.6 §3.7.6 Code-derived spec batch evidence (v1.5 新設、軸 5+6+7、reverse-engineered samples)

reverse-engineering 方式 (= 既存コード → spec → re-impl) で 3 sample 取得。§5.5.1 §3.7.1 forward-fresh-spec との sub-group 比較が paper rigor の core defense。

- **§5.5.6.1 Phase field 法 (compact、Julia or C++)**:
  - reverse-engineering feasibility 検証 sample (= A-3 batch 着手順序最先行)
  - 既存 Phase field コード → reverse engineering で spec 起草 → V4 適用 → re-impl + behavior 差分検証
  - **re-impl phase 中の Level 6 rework events 観測** (v0.9 新設、Claim D primary evidence の主要 source、`spec_id="phase-field"` + `discovered_phase="impl-mid"` 付与、A-1 vs §3.7.6 sub-group 比較 base)
  - per-finding raw data + per-system metrics + spec characteristic descriptive metric (= 全 sample 共通)
  - explicit label = `spec_source: reverse-engineered`、cost 6-10h + Level 6 観測 overhead 0-3h
  - 配置 path = `.kiro/methodology/v4-validation/a3_batch/code_derived/phase_field/`
- **§5.5.6.2 3D 熱伝導方程式 + 複雑モデル生成 (Julia or C++)**:
  - real-world numerical project rich 化 (= mesh / boundary condition / I/O 含む)
  - **re-impl phase 中の Level 6 rework events 観測** (v0.9 新設、`spec_id="heat-equation-3d"` 付与)
  - cost 10-14h + Level 6 観測 overhead 0-3h、配置 path = `.../code_derived/heat_equation_3d/`
- **§5.5.6.3 Arduino IoT センサ (Arduino C/C++)**:
  - embedded systems failure mode cover (= real-time / hardware / interrupt)
  - **re-impl phase 中の Level 6 rework events 観測** (v0.9 新設、`spec_id="arduino-iot"` 付与)
  - cost 4-8h + Level 6 観測 overhead 0-3h、配置 path = `.../code_derived/arduino_iot/`
- **全体 reverse-engineering bias mitigation 5 step** (data-acquisition-plan v1.5 §3.7.6 全体 caveat 整合):
  - Step 1 explicit labeling / Step 2 spec characteristic metric / Step 3 sub-group reporting / Step 4 paper Limitations sub-section / Step 5 paired comparison defer
- **Level 6 観測統合 (v0.9 新設、data-acquisition-plan v1.6 整合)**: 3 sample 全件 re-impl phase で Level 6 rework events 観測 = Claim D primary evidence の主要 source、A-1 (3 spec self-dogfooding、forward-fresh) と sub-group 比較で 6 spec instance accumulated Claim D evidence 構成
- §3.7.6 全体 cost (v0.9 update) = 20-32h + Level 6 観測 overhead 0-9h (= 0-3h × 3 sample) = **20-41h ≈ 3-6 work day = A-2 完走後 1 calendar 月 batch**

#### 5.5.7 §3.7.7 Paired comparison (future work、議論記録のみ、scope 外)

- 同一 problem を forward-spec + reverse-engineered 両方で実施 = reverse-engineering bias の strict internal validity disentangle (gold standard)
- scope 外理由: cost 2 倍、§3.7.6 + §3.7.1 sub-group 比較で paper acceptable line 内 mitigation 達成
- 採用条件: §3.7.6 sub-group 比較で systematic 差異が paper limitations 範囲外 = forward / reverse 混合で aggregate metric が confound する場合のみ Phase B 以降に追加検討
- 配置 path 予約 = `.../a3_batch/paired_comparison/` (= 採用時のみ生成、scope 外段階では未配置)

---

## 6. 運用規律

- **更新義務**: 新 evidence (review 適用、ablation、design/task 完走、Phase 移行) 生成時、必ず本 catalog 該当 § を追記
- **archive 操作時義務**: file 削除 / branch tag 化 / move を行ったら、本 catalog の保全 location を即更新
- **session 末義務**: TODO 更新時に本 catalog の追記漏れ確認、必要なら本 commit に含める
- **整合性 check**:
  - 全 archive branch 名 + commit hash が現存することを定期確認 (年 1 回程度)
  - origin への push 状態 (= remote backup) も定期確認

---

## 7. 関連 reference

- V3 baseline 数値要約: `.kiro/methodology/v4-validation/v3-baseline-summary.md`
- V4 protocol v0.3 final: `.kiro/methodology/v4-validation/v4-protocol.md`
- canonical V4 source: `docs/過剰修正バイアス.md`
- V4 redo broad 中間 evidence + req phase 累計: `.kiro/methodology/v4-validation/comparison-report.md` v0.1 (12th 末で design phase evidence 未追記、A-2 完走後の最終 comparison-report v0.2 で req+design+A-2 累計集計予定)
- 論文化 data 取得計画 (checkbox tracker): `.kiro/methodology/v4-validation/data-acquisition-plan.md`
- TODO 引き継ぎ: `TODO_NEXT_SESSION.md` (各セッション末更新、main)
- dev-log: `docs/dual-reviewer-log-1.md` (1st-7th) + `docs/dual-reviewer-log-2.md` (8th-11th) + `docs/dual-reviewer-log-3.md` (12th 以降、user 管理)
- 12th 末 endpoint commits (origin push 済):
  - `2e5637d` design(dual-reviewer-foundation): A-0 → A-1 transition design approve
  - `76a1eb1` design(dual-reviewer-design-review): A-1 design phase approve
  - `aa40934` design(dual-reviewer-dogfeeding): A-1 design phase approve + cross-spec review C1-C3 fix
- 14th 末 endpoint commits (origin push 済):
  - `021ec65` tasks(dual-reviewer): A-1 3 spec tasks approve + V4 ad-hoc + cross-spec C-1
  - `aed0b2b` docs(methodology): data-acquisition-plan v0.4 = tasks phase 累計反映
- 15th 末 endpoint commits (origin push 済):
  - `15cffa6` design-review v1.2 改修 cycle (req + design + tasks 整合化、AC10/AC8/AC9 追加)
  - `7722f9e` data-acquisition-plan v1.0 + `rework_log.jsonl` 雛形 (Claim D + Level 6 schema 新設)
- 16th 末 endpoint commits (origin push 済、A-1 implementation phase Step 1 = foundation):
  - `7774860` foundation Task 1+2 install location skeleton + portable static artifacts
  - `375809b` foundation Task 3+4 = 5 JSON schemas + Layer 1 framework + 2 templates
  - `a96482b` foundation Task 5+6 dr-init skill impl + unit tests (TDD)
  - `8cd8bf8` foundation Task 7 integration tests (5 sub-task、56 tests pass)
- 17th 末 endpoint commits (origin push 済、10 commit / 31 file / 3685 insertions / 151 tests pass):
  - `8876328` data-acquisition-plan v1.1 = A-3 plan + framing 変更 + 4 axes 化
  - `2f104fa` design-review Task 1+2 scaffolding + design_extension.yaml + forced_divergence_prompt.txt
  - `85f51f9` design-review Task 3+6.6 dr-judgment skill impl + 12 unit tests
  - `bdda6dd` design-review Task 4+6.3-6.5 dr-log skill impl + 11 unit tests
  - `7541896` design-review Task 5+6.1-6.2 dr-design skill impl + 13 unit tests
  - `4e4a33d` design-review Task 7 integration tests (5 sub-task、113 tests pass)
  - `06bcdcf` dogfeeding Task 1+2 scaffolding + helpers + metric_extractor.py + 13 unit tests
  - `367a7aa` dogfeeding Task 3 figure_data_generator.py + 9 unit tests
  - `0234251` dogfeeding Task 4 phase_b_judgment.py + 11 unit tests
  - `3d72d56` dogfeeding Task 5+6 README full + 2 integration tests (151 tests pass、A-1 implementation phase 完走)
- 18th 開始 endpoint commits (origin push 済):
  - `87e3047` data-acquisition-plan v1.2 = Data 2 operational guide + framing 精緻化注記
  - `fd55902` 17th 末持ち越し未 commit cleanup (settings.local.json + dev-log 5 file)
  - `5f27a21` data-acquisition-plan v1.3 = A-2 phase 3 段構成展開 (§4 ⇄ §3.6 整合化)
- 19th-29th 末 A-2.1 evidence acquisition commits (origin push 済、20 commits = A-2.1 1/3 終端、treatment=dual+judgment 全 10 ラウンド完走、29th 末 endpoint = `3cbefdb`):
  - 19th methodology 拡張: `data-acquisition-plan` v1.4 (Self-review skill skip 規律) + v1.5 (軸 5+6+7 + §3.7.6 batch) / `evidence-catalog` v0.6 → v0.7 / `preliminary-paper-report` v0.3
  - 20th Round 1 (option B): `6e26aa8` Round 1 fix (R8.2 + R12.4 + R10.9 = v4-miss core 3 件) + `4c162f8` dev_log + Level 6 init
  - 21st Decision 6 + Round 2: `d3b0877` Decision 6 確定 (primary subagent default) + `7b61122` Round 2 fix + `8ad2615` log
  - 22nd Round 3 (実装可能性+アルゴリズム+性能): `acaa86d` + `dc5fcb2`
  - 23rd Round 4 (責務境界): `e240595` + `1fe87cf`
  - 24th Round 5 (失敗モード+観測): `45eb78a` + `2fdec21`
  - 25th Round 6 (concurrency+timing): `748c096` + `0c98944`
  - 26th Round 7 (security): `26c165e` + `7d22d4a`
  - 27th Round 8 (cross-spec 整合): `5259393` + `e21ee2d`
  - 28th Round 9 (test 戦略): `a2784a8` + `8113dc3`
  - 29th Round 10 (運用): `f6bac54` + `3cbefdb` = **treatment=dual+judgment 全 10 ラウンド完走 endpoint**
- 3 spec design.md / research.md (12th 末 endpoint):
  - `.kiro/specs/dual-reviewer-foundation/design.md` v1.1 + `research.md` v1.0
  - `.kiro/specs/dual-reviewer-design-review/design.md` v1.1 → v1.2-prep + `research.md` v1.0
  - `.kiro/specs/dual-reviewer-dogfeeding/design.md` v1.2 + `research.md` v1.0
- 3 spec tasks.md (14th 末 endpoint):
  - `.kiro/specs/dual-reviewer-foundation/tasks.md` v1.2 (cross-spec C-1 fix 統合済)
  - `.kiro/specs/dual-reviewer-design-review/tasks.md` v1.1
  - `.kiro/specs/dual-reviewer-dogfeeding/tasks.md` v1.1
- archive branches (origin push 済):
  - `archive/v3-foundation-design-7th-session` (V3 endpoint, commit `e6cab03`)
  - `archive/v4-redo-attempt-1-v3-scope` (V4 attempt 1, commit `e8ca94a`)
  - `archive/v4-redo-broad-merged-2026-05-01` (V4 redo broad endpoint = req phase 完走、commit `b6b850c`、12th 末 archive 化)
- tags (origin push 済):
  - `v3-evidence-foundation-7th-session` (= `e6cab03`)
  - `v4-baseline-brief-2026-04-29` (= `06fde00`、3 spec init endpoint)
  - `v4-redo-broad-merged-2026-05-01` (= `b6b850c`、12th 末 archive 化と同期 tag)

---

## 変更履歴

- **v0.1** (2026-04-30 11th セッション、本 file 初版): V3 baseline + V4 attempt 1 + V4 redo broad の所在を集約。V3 design phase artifact 3 file の main 削除と同 commit で起草、archive branch + tag による保全 location を明記。将来 evidence の placeholder § を整備。
- **v0.2** (2026-04-30 11th セッション): §3.9 「11th セッション 3 req 整合性 audit gap-list」追加。main 統合後の 3 req 整合性 audit 結果を反映、主要 contract 整合 OK 確認 + soft gap 4 件 (G1-G4) + 対応 timing を track。
- **v0.3** (2026-04-30 11th セッション): §6 関連 reference に `data-acquisition-plan.md` を追加 (論文化 data 取得計画 checkbox tracker、本 catalog と並走 file)。
- **v0.4** (2026-05-01 12th セッション末): §4 を「将来追加予定 (placeholder)」から「design phase V4 evidence (12th セッション完走、main 統合済)」に展開 (foundation `2e5637d` + design-review `76a1eb1` + dogfeeding + cross-spec `aa40934` の 3 spec evidence 集約 + 3 spec 累計 V4 metric trend = 過剰修正比率 81.25% → 58.8% → 40.0% 連続改善 + 12th 末 cleanup record)。§5 を新規 placeholder section (A-1 implementation phase + A-2 dogfeeding + 論文 figure + Phase B fork) に renumber、§6/§7 (運用規律 + 関連 reference) も連動 renumber。§7 関連 reference に 12th 末 commits + 3 spec design / research file paths + 新規 archive branch (`archive/v4-redo-broad-merged-2026-05-01`) + 新規 tag (`v4-redo-broad-merged-2026-05-01`) を追記。
- **v0.5** (2026-05-01 14th セッション末): §4 を「design + tasks phase V4 evidence (12-14th セッション完走、main 統合済)」に rename + §4.6-§4.11 を新規追加 (14th 末 tasks phase ad-hoc V4 evidence 集約 = 3 spec tasks phase metric (foundation 採択率 5.6% / 過剰修正 66.7% + design-review 13.3% / 53.3% + dogfeeding 35.7% / 42.9%) + cross-spec review (Group A 17 + B 2 + C 1 + 不整合 0 件、Group C-1 = `jsonschema>=4.18` version pin 同期 を foundation tasks v1.2 で apply) + 3 spec tasks phase 累計 V4 metric trend (採択率 +30.1pt / 過剰修正比率 -23.8pt 累計改善 = V4 構造的有効性 3 spec 連続再現実証、design phase trend 81.25% → 58.8% → 40.0% と方向一致 = 6 spec instance 累計再現) + 14th 末 cleanup (data-acquisition-plan v0.4 + memory 2 file update + origin push) record)。§7 関連 reference に 14th 末 endpoint commits (`021ec65` + `aed0b2b`) + 3 spec tasks.md path + tasks phase ad-hoc V4 caveat 4 件 reference 追加。
- **v0.6** (2026-05-02 18th セッション開始、§5.1 placeholder fill + §5.2 3 段構成展開): 14th 末起草の §5.1 placeholder 5 件を 15th-18th 累計の完走 evidence に書き換え = **§5.1.1** (15th = design-review v1.2 改修 cycle + Level 6 schema infrastructure + data-acquisition-plan v1.0、commits `15cffa6` + `7722f9e`) / **§5.1.2** (16th = A-3 plan 確定 + A-1 Step 1 = foundation 物理 file 生成、commits `7774860` / `375809b` / `a96482b` / `8cd8bf8`、56 tests pass、TDD 1 cycle) / **§5.1.3** (17th = data-acquisition-plan v1.1 + Step 2 design-review impl + Step 3 dogfeeding impl、10 commit / 31 file / 3685 insertions / 151 tests pass、TDD 6 cycle) / **§5.1.4** (18th 開始 = data-acquisition-plan v1.2 + 17th 末持ち越し cleanup + v1.3、commits `87e3047` + `fd55902` + `5f27a21`、3 commit / 8 file / 7863 insertions / 42 deletions) / **§5.1.5** (sample 1 round 通過 test = A-2 統合 defer = Spec 6 休止により dogfeeding spec Task 8 = A-2 phase で execute) / **§5.1.6** (Level 6 rework_log = 0 events for A-1 全 implementation phase = Data 1 commit pattern auto 機械検証済 = Claim D 中間 evidence 累積継続)。**§5.2 placeholder を 3 段構成展開** (= data-acquisition-plan v1.3 §4 A-2 phase 整合) = §5.2.1 Spec 6 Design phase (= 主要 evidence、systematic) + §5.2.2 Spec 6 Tasks phase (= 補助 evidence、V4 ad-hoc 適用、option) + §5.2.3 Spec 6 Impl phase (= passive、Level 6 rework signal、Claim D evidence) + §5.2.4 A-2 終端統合分析。**§7 関連 reference に 15th-18th endpoint commits 16 件追加** (= 15th 末 2 + 16th 末 4 + 17th 末 10 + 18th 開始 3 = 累計 19 commit、main origin push 済全件)。本 v0.6 改版自体は data-acquisition-plan v1.0/v1.1/v1.2/v1.3 と同様 Level 6 記録対象外 (= methodology meta-document)。
- **v0.7** (2026-05-02 19th セッション末、§5.5 A-3 triangulation batch evidence 新設 + §5.2 Sub-group analysis 規律言及追加 = data-acquisition-plan v1.5 整合化): data-acquisition-plan v1.5 改版 (= 軸 4 → 軸 7 拡張 + §3.7.6 Code-derived spec batch 新設 + §3.7.1 forward-fresh-spec 独立必須化 + Sub-group analysis 規律) を catalog 側に反映。**§5.5 A-3 triangulation batch evidence を新設** = §5.5.1 §3.7.1 forward-fresh-spec sample (= cross-project transfer + 軸 6 forward 側) + §5.5.2-4 §3.7.2-4 (multi-vendor / mutation / multi-run) + §5.5.5 §3.7.5 convergence judgment 6 indicators + **§5.5.6 §3.7.6 Code-derived spec batch (3 sub-entry = §5.5.6.1 Phase field / §5.5.6.2 3D 熱伝導 / §5.5.6.3 Arduino IoT、reverse-engineering bias mitigation 5 step 整合)** + §5.5.7 §3.7.7 paired comparison future work (= 議論記録のみ、scope 外)。各 entry に 配置 path 予約 (= `.kiro/methodology/v4-validation/a3_batch/{forward_fresh,multi_vendor,mutation,multi_run,code_derived/{phase_field,heat_equation_3d,arduino_iot},paired_comparison}/`)。**§5.2 末尾に §5.2.5 Sub-group analysis 規律 sub-section 追加** = explicit labeling (`spec_source: forward-fresh | reverse-engineered`) + spec characteristic descriptive metric (AC 数 / 文字数 / Design Decisions 数 / 言及 alternative 数 / 起草所要時間) + sub-group reporting 必須化を A-2 evidence 取得時から適用、§5.5.6 reverse-engineered batch との sub-group 比較 base として A-2 sample (= forward-fresh) を運用。Phase A 終端 redefine = A-3 + §3.7.6 完走 (v1.5 redefine 反映)。本 v0.7 改版自体は v0.6 同様 Level 6 記録対象外 (= methodology meta-document)。
- **v0.10** (2026-05-03 30th セッション初頭、A-2.1 3 系統対照実験 design.md state policy 明示 = pristine state 起点 + 各 treatment 独立 branch 戦略 = data-acquisition-plan v1.7 整合化、paper rigor 確保のための confounding 排除): 30th セッション開始時に user 指摘「single の Round 1 を開始するとき、元になる design.md はどうやって準備するか」を契機に、A-2.1 30 review session の input design.md state policy が SSoT 文書群に明示記述されていない盲点を identified。29th 末まで第 1 系統 (= main、`treatment=dual+judgment`) が pristine state `285e762` から 10 round 累積修正で `f6bac54` に到達、accumulated state を起点に第 2/第 3 系統を回すと「prior treatment による事前修正」と「current treatment 単独 effect」が交絡 = V4 各 layer の機能寄与を quantify 不能 + Claim B/C primary evidence の paper rigor 致命的弱体化 (= self-referential bias)。**§5.2.1 Spec 6 Design phase entry に branch 戦略 sub-bullet 追加** = 全 treatment は pristine state `285e762` 起点で完走、第 1 系統 main 完走済 + 第 2 系統 (`treatment-single`) + 第 3 系統 (`treatment-dual`) は 30th 以降に new branch 派生で 10 round 完走、Level 6 events 別 file/sub-group key 記録 (= confound 回避)、3 branch 統合分析で comparison-report v0.2 final 集約 (= ablation figure 成立)、Spec 6 design.md 最終 state は main の post-Round 10 (`f6bac54`) 採用 + 他 2 treatment branch は paper data source archive として保持 (delete 禁止)。**§5.2.1.5 残作業 sub-section update** = treatment=single / treatment=dual の Round 1-10 を new branch で pristine 起点完走する明示記述追加 + Level 6 events 別記録明示。本 v0.10 改版自体は v0.9 同様 Level 6 記録対象外 (= methodology meta-document)。timeline 文言 (= 9-10 月 paper draft 着手) は user 指示「現状維持」遵守、本 v0.10 update は scope (= 3 系統対照実験 state policy 明示) 整合化のみ。
- **v0.9** (2026-05-03 29th セッション末、A-2.3 critical path 外し + §3.7.6 re-impl phase で Claim D primary evidence 代替 = §3.7.6 Level 6 観測統合 = data-acquisition-plan v1.6 整合化): 29th 末議論「§3.7.6 で planned されている 3 sample (Phase field / 3D 熱伝導 / Arduino IoT) は既に re-implementation phase を含む = re-impl phase で発生する rework events を Level 6 で観測すれば A-2.3 と等価な Claim D primary evidence を取得可能」採用、A-2.3 を critical path から外し Phase B-1.x post-paper supplementary evidence として defer する方針確定。**§5.1.6 Claim D primary evidence 構成 update** = A-1 全 implementation phase (3 spec self-dogfooding、Python、forward-fresh) + §3.7.6 re-implementation phase (3 sample external、Julia/C++/Arduino C、reverse-engineered) = **6 spec instance** で構成 + sub-group reporting 必須 (= forward-fresh A-1 vs reverse-engineered §3.7.6 で別 metric 計算 + reverse-engineering 5 source bias を paper Limitations sub-section で acknowledge)。**§5.2.3 Spec 6 Impl phase update** = A-2.3 を critical path から外し Phase B-1.x supplementary defer 明示 + Spec 6 implementation 完了時点で paper revision 用補強 data として後付け運用。**§5.5.6.1-3 entries に "re-impl phase 中の Level 6 rework events 観測" sub-step 追加** = `spec_id="phase-field|heat-equation-3d|arduino-iot"` + `discovered_phase="impl-mid"` 付与、A-1 vs §3.7.6 sub-group 比較 base、Level 6 観測 overhead 0-3h per sample。**§5.5.6 全体 cost update** = 20-32h → 20-41h (= Level 6 観測 overhead 0-9h 追加分)、3-6 work day。本 v0.9 改版自体は v0.8 同様 Level 6 記録対象外 (= methodology meta-document)。timeline 文言 (= 9-10 月 paper draft 着手) は user 指示「現状維持」遵守、本 v0.9 update は scope 整合化のみ。
- **v0.8** (2026-05-03 29th セッション末、§5.1.6 Level 6 status update + §5.2.1.5 A-2.1 partial completion partial fill + §7 endpoint commits 19th-29th 追加): A-2.1 Spec 6 Design phase の treatment=dual+judgment 全 10 ラウンド完走 (= A-2.1 1/3 終端、20th-29th 累計、20 commits、29th 末 endpoint = `3cbefdb`) を反映。**§5.1.6 Level 6 rework_log status を 0 → 44 events に update** = A-1 impl 0 events (Claim D primary evidence = strong) と A-2.1 design 44 events (Claim B/C functioning evidence = V4 review が design fix を generate する pattern observation、design rework は Claim D primary ではなく Claim B/C functioning = adaptive 用法) の **2 phase 解釈分離** を明示、論文 framing で 2 evidence 種別 disambiguate 必要を明記、A-2.3 impl phase events は 30th 以降 append 開始予定。**§5.2.1 末尾に §5.2.1.5 A-2.1 partial completion sub-section を partial fill** = treatment=dual+judgment 累計 metric (検出 69 / 採択率 30.4% / **過剰修正比率 33.3% = V3 baseline 50% 比 -16.7pt 改善**) + **4 spec instance 累計 design phase 過剰修正比率 連続改善** (foundation 81.25% → design-review 58.8% → dogfeeding 40.0% → Spec 6 33.3% = -47.95pt 累計改善 = V4 構造的有効性 4 spec 連続再現実証) + **v4-miss core evidence 累計 17 件** (10 件 must_fix upgrade core + 7 件 should_fix upgrade minor、Round 1-10) + **fatal_pattern hits 5 件** (path_traversal × 3 + data_loss × 1 + destructive_migration 逆向き × 1 = Chappy P0 quota 機能 evidence) + **escalate 解決手段 5 path 確立 + path 5 候補 4 連続再現** (Round 7-10 escalate=0 streak 過去最長) + **Round 10 V4 過剰修正 bias 抑制機能 evidence** (= primary single なら +3 修正 → dual+judgment net 1 修正 = 67% 抑制 + 検出漏れ 1 件補完 = Claim B strong evidence、29th 末新規)。残作業 = treatment=single + treatment=dual の Round 1-10 = 20 review session (推定 1-2 month batch、A-2.1 残 2/3)。**§7 関連 reference に 19th-29th endpoint commits 20 件追加** (= 各 Round design.md 修正 + log commit、20th-29th セッション、20 commits、main origin push 済全件)。本 v0.8 改版自体は v0.7 同様 Level 6 記録対象外 (= methodology meta-document)。
