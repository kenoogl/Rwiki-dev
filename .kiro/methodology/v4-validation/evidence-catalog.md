# Evidence Catalog — dual-reviewer methodology validation

_目的: V3 baseline / V4 各 attempt / 将来追加される実験データの所在 + 内容 + アクセス方法を継続的に記録するカタログ。新 evidence 生成時 + archive 操作時に必ず更新する。_

_v0.1 / 2026-04-30 (11th セッション初日)_

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

## 4. 将来追加予定 (placeholder)

### 4.1 design phase V4 evidence (11th 以降、A-1 prototype 着手後)

- foundation design phase V4 適用結果
- design-review design phase V4 適用結果
- dogfeeding design phase V4 適用結果
- → 本 catalog §4.1 に詳細追記予定

### 4.2 A-2 dogfeeding 結果 (Phase A 終端時)

- Spec 6 全 Round (1-10) × 3 系統対照実験 = 30 review session
- → 本 catalog §4.2 に詳細追記予定

### 4.3 論文 figure 1-3 + ablation evidence

- figure data file paths
- ablation 比較対照点 (V3 baseline / V4 attempt 1 / V4 redo broad / V4 design phase)
- → 本 catalog §4.3 に詳細追記予定

### 4.4 Phase B fork go/hold 判定 (8 月末 timeline)

- 判定 evidence + decision record
- → 本 catalog §4.4 に詳細追記予定

---

## 5. 運用規律

- **更新義務**: 新 evidence (review 適用、ablation、design/task 完走、Phase 移行) 生成時、必ず本 catalog 該当 § を追記
- **archive 操作時義務**: file 削除 / branch tag 化 / move を行ったら、本 catalog の保全 location を即更新
- **session 末義務**: TODO 更新時に本 catalog の追記漏れ確認、必要なら本 commit に含める
- **整合性 check**:
  - 全 archive branch 名 + commit hash が現存することを定期確認 (年 1 回程度)
  - origin への push 状態 (= remote backup) も定期確認

---

## 6. 関連 reference

- V3 baseline 数値要約: `.kiro/methodology/v4-validation/v3-baseline-summary.md`
- V4 protocol v0.3 final: `.kiro/methodology/v4-validation/v4-protocol.md`
- canonical V4 source: `docs/過剰修正バイアス.md`
- V4 redo broad 中間 evidence: `.kiro/methodology/v4-validation/comparison-report.md`
- 論文化 data 取得計画 (checkbox tracker): `.kiro/methodology/v4-validation/data-acquisition-plan.md`
- TODO 引き継ぎ: `TODO_NEXT_SESSION.md` (各セッション末更新、main)
- dev-log: `docs/dual-reviewer-log-1.md` (1st-7th) + `docs/dual-reviewer-log-2.md` (8th 以降、user 管理)
- archive branches:
  - `archive/v3-foundation-design-7th-session` (V3 endpoint, commit `e6cab03`)
  - `archive/v4-redo-attempt-1-v3-scope` (V4 attempt 1, commit `e8ca94a`)
- tags:
  - `v3-evidence-foundation-7th-session` (= `e6cab03`)
  - `v4-baseline-brief-2026-04-29` (= `06fde00`、3 spec init endpoint)

---

## 変更履歴

- **v0.1** (2026-04-30 11th セッション、本 file 初版): V3 baseline + V4 attempt 1 + V4 redo broad の所在を集約。V3 design phase artifact 3 file の main 削除と同 commit で起草、archive branch + tag による保全 location を明記。将来 evidence の placeholder § を整備。
- **v0.2** (2026-04-30 11th セッション): §3.9 「11th セッション 3 req 整合性 audit gap-list」追加。main 統合後の 3 req 整合性 audit 結果を反映、主要 contract 整合 OK 確認 + soft gap 4 件 (G1-G4) + 対応 timing を track。
- **v0.3** (2026-04-30 11th セッション): §6 関連 reference に `data-acquisition-plan.md` を追加 (論文化 data 取得計画 checkbox tracker、本 catalog と並走 file)。
