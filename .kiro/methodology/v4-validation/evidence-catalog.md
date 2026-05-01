# Evidence Catalog — dual-reviewer methodology validation

_目的: V3 baseline / V4 各 attempt / 将来追加される実験データの所在 + 内容 + アクセス方法を継続的に記録するカタログ。新 evidence 生成時 + archive 操作時に必ず更新する。_

_v0.5 / 2026-05-01 (14th セッション末、A-1 tasks phase 累計 evidence + cross-spec review C-1 fix + 14th 末 cleanup 反映)_

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

### 5.1 A-1 implementation phase evidence (13th 以降、本 catalog §5.1 に追記予定)

- design-review v1.2 改修 (treatment flag + timestamp + commit_hash 対応 implementation 設計、本 spec implementation phase 直前 cycle)
- 4 skill 物理 file 生成 (`scripts/dual_reviewer_prototype/skills/{dr-init, dr-design, dr-log, dr-judgment}/{SKILL.md, *.py}`)
- 3 Python script 物理 file 生成 (`scripts/dual_reviewer_dogfeeding/{metric_extractor, figure_data_generator, phase_b_judgment}.py + tests/`)
- portable artifact 物理 file 生成 (foundation `framework/` + `schemas/` + `patterns/` + `prompts/` + `config/` + `terminology/`)
- sample 1 round 通過 test 結果 (= design-review Req 7.4 動作確認終端条件)

### 5.2 A-2 dogfeeding 結果 (Phase A 終端時、本 catalog §5.2 に追記予定)

- Spec 6 全 Round (1-10) × 3 系統対照実験 = 30 review session
- JSONL log 蓄積 (foundation 共通 schema 2 軸並列 + 本 spec consumer 拡張 4 field)

### 5.3 論文 figure 1-3 + ablation evidence (A-2 完走後、本 catalog §5.3 に追記予定)

- figure data file paths (`figure_<n>_data.json` × 4 = `figure_1_data.json` miss_type 分布 / `figure_2_data.json` difference_type 分布 + forced_divergence / `figure_3_data.json` trigger_state 発動率 / `figure_ablation_data.json` dual vs dual+judgment 効果分離)
- ablation 比較対照点 (V3 baseline / V4 attempt 1 / V4 redo broad / V4 design phase + A-2 dogfeeding)
- 配置 path = `.kiro/methodology/v4-validation/`

### 5.4 Phase B fork go/hold 判定 (8 月末 timeline、本 catalog §5.4 に追記予定)

- 判定 evidence (5 条件評価結果 + V4 仮説検証併記)
- decision record (= comparison-report.md §12 Phase B Fork Judgment、section ID `phase-b-fork-judgment-v1`)

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
