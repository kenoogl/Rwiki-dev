# Implementation Plan

## Overview

`dual-reviewer-dogfeeding` の成果物 = 3 Python script (`metric_extractor.py` / `figure_data_generator.py` / `phase_b_judgment.py`) + Operational Protocol Documentation (README.md) + A-2 期間 Spec 6 dogfeeding 完走。Consumer-only spec (新規 skill / framework / schema 実装一切なし、Decision 1)、Operational Protocol + Research Script Hybrid pattern (Decision 2、SKILL.md 形式不要)。

**Prerequisite**:
- `dual-reviewer-foundation` tasks 完走 (= 7 portable artifact 配置済)
- `dual-reviewer-design-review` tasks 完走 (= 3 skills + Layer 2 extension + forced_divergence prompt 配置済)
- A-1 期間内 implementation = 本 tasks の Task 1-6 (Python script 実装 + README、Decision 7)
- A-2 期間 (Task 8) = Spec 6 dogfeeding 適用 + 30 review session 完走、`dual-reviewer-design-review` v1.2 revalidation cycle 完了 + Spec 6 design.md generation 進行 が前提 (Task 7 で gate verify)

8 major task / 8 sub-task で構成、Foundation prereqs (Task 1) → 3 Research Script TDD (Task 2-4) → Operational Protocol Documentation (Task 5) → Integration tests (Task 6) → design-review v1.2 revalidation gate (Task 7) → A-2 E2E (Task 8) の phase 順序。3 script は TDD (test first → fail → impl → pass、A5 fix 整合)。

**`(P)` annotation の意味補足** (A8 apply、TDD 文脈): tasks 2.1 / 3.1 / 4.1 (test first sub-tasks) の `(P)` annotation は **同 phase 内の他 sub-task との parallel-capable** (= 3 script の test first 作成は互いに独立、tests/test_metric_extractor.py と tests/test_figure_data_generator.py と tests/test_phase_b_judgment.py を並列作成可) を意味する。**TDD sequential gate (test first → fail 確認 → impl → pass) は各 X.1 → X.2 の `_Depends: X.1` annotation で維持**、sub-task 内の test-first ordering は `(P)` で破壊されない。Tasks 6.1 / 6.2 (integration tests) の `(P)` も同様、3 script implementation 完成後に互いに parallel 実行可、各 integration test 内の TDD ordering は維持。

## Tasks

- [ ] 1. Foundation prereqs 確認 + dogfeeding scaffolding + README scope skeleton
  - foundation tasks + design-review tasks **tasks-approved** 状態 confirm (= 両 spec の tasks.md generated + `approvals.tasks.approved: true` 状態、本 spec implementation phase 着手前提、P4 apply)。注: foundation + design-review **implementation phase 完了** (= 物理 file 生成 + sample 1 round pass 等) は Task 8 (A-2 E2E) prerequisite として後続 phase で確認
  - 本 spec 用 directory `scripts/dual_reviewer_dogfeeding/` create + `tests/` subdirectory create (3 script unit tests 配置先)
  - `.kiro/methodology/v4-validation/` 既存 directory 確認 (= output target = `dogfeeding_metrics.json` / `figure_<n>_data.json` × 4 / `comparison-report.md` append target)
  - Python `pyyaml` + `jsonschema>=4.18` (Draft 2020-12 + Registry API 対応) + `pytest` install 状態 (foundation task 1 で install 済) を確認
  - **Foundation install location resolve mechanism 規約** (C2 fix 整合、P3 apply): 3 Python script (Task 2.2 / 3.2 / 4.2) は `--dual-reviewer-root <absolute path>` CLI flag default + `DUAL_REVIEWER_ROOT` 環境変数 fallback で foundation install location を resolve。**共通 helper module `scripts/dual_reviewer_dogfeeding/helpers.py` を本 task で skeleton 配置** (Task 2.2/3.2/4.2 から import される utility = `_resolve_foundation_path(base_root, relative)` + path resolve helper)、3 script 間の DRY 規律遵守 (= 各 script 内 inline 実装禁止、helpers.py 集約実装)
  - **README scope skeleton** 配置 (`scripts/dual_reviewer_dogfeeding/README.md` 初版): scope (本 spec consumer-only + 30 review session manual flow) + out-of-scope (B-1.x 拡張 schema / multi-vendor / 論文 draft / case study、Req 7.5/7.6/7.7 整合) + Phase A scope constraints + bilingual section heading
  - **invariant**: design-review v1.2 revalidation cycle (Decision 6 = treatment flag / timestamp / commit_hash 改修) は別 spec の責務、Task 7 で gate verify
  - Observable: `tree scripts/dual_reviewer_dogfeeding/` で `tests/` + `README.md` presence、`python3 -c "import yaml, jsonschema, pytest"` 全 import 成功、README で scope + out-of-scope + Phase A scope constraints 3 section presence
  - _Requirements: 1.5, 1.6, 5.2, 7.5, 7.6, 7.7_

- [ ] 2. metric_extractor.py 実装 (TDD)
- [ ] 2.1 (P) `tests/test_metric_extractor.py` 先行作成 (TDD step 1: test fail)
  - mock 30 line JSONL fixture (3 treatment × 10 Round = 30 line、`treatment` / `round_index` / `design_md_commit_hash` / `adversarial_counter_evidence` field 含む)
  - **timestamp ISO8601 fixture 形式明示** (A3 apply): `timestamp_start` / `timestamp_end` を ISO8601 UTC 形式 (例: `"timestamp_start": "2026-05-01T10:00:00Z"`, `"timestamp_end": "2026-05-01T10:07:00.700Z"` = V3 baseline 420.7s mock 整合) で fixture 配置、wall-clock 算出 = `datetime.fromisoformat()` で UTC normalize 後の差分秒。UTC/JST 混在 edge case test 1 件含む (例: `"timestamp_start": "2026-05-01T19:00:00+09:00"` → UTC normalize 後 `2026-05-01T10:00:00Z` で同一基準で wall-clock 算出可能、tz-aware datetime 計算)
  - 12 軸 metric 算出 expected value assertion (Req 4.1-4.7 整合): 検出件数 / must_fix 件数+比率 / should_fix 件数+比率 / do_not_fix 件数+比率 / 採択率 / 過剰修正比率 / adversarial 修正否定 disagreement / judgment override + 理由分析 / wall-clock + cost 倍率 / Phase 1 同型 hit / fatal_patterns 8 種 hit
  - **escalate-mapped findings (= `fix_decision.label: should_fix` + `recommended_action: user_decision`、Req 2.5 整合) を judgment subagent disagreement / override 件数算出時に正しく扱う**: mock fixture で escalate finding 含む input → metric output に escalate finding が disagreement / override count に反映されている assertion
  - commit hash variance 検出 mock test (複数 commit hash 含む input → `commit_hash_variance` field warning 記録 assert)
  - 6 top-level field structure (`version` / `session_count` / `treatments` / `rounds` / `commit_hash_variance` / `metrics`) presence assertion
  - 2 スペースインデント遵守 (`.kiro/steering/tech.md` 整合)
  - Observable: pytest run で全 test fail (実装なし、TDD step 1 = test first)
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_
  - _Boundary: scripts/dual_reviewer_dogfeeding/tests/test_metric_extractor.py_

- [ ] 2.2 `metric_extractor.py` 実装 (TDD step 2-4: pass tests)
  - 入力: `--input <jsonl absolute path>` + `--output <json absolute path>` + `--dual-reviewer-root` (CLI flag) または `DUAL_REVIEWER_ROOT` 環境変数 (fallback、C2 fix 整合)。foundation install location resolve は **共通 helper module `scripts/dual_reviewer_dogfeeding/helpers.py` から `_resolve_foundation_path` を import** (P3 apply、DRY 規律 = 各 script 内 inline 実装禁止)
  - 出力: `dogfeeding_metrics.json` (default path = `.kiro/methodology/v4-validation/dogfeeding_metrics.json`)
  - JSONL log read + parse + `treatment` / `round_index` field で 3 系統 × 10 Round = 30 line 識別
  - 12 軸 metric 算出 (Req 4.1-4.7 全件 + V4 protocol §4.1 整合): 検出件数 / 3 ラベル件数+比率 / 採択率 / 過剰修正比率 / adversarial 修正否定 disagreement / judgment override + 理由分析 / wall-clock + cost 倍率 (V3 baseline 420.7s 比 + V4 完全構成 dual+judgment 比) / Phase 1 同型 hit rate / fatal_patterns 8 種 hit
  - **escalate-mapped findings handling**: `fix_decision.label: should_fix` + `recommended_action: user_decision` の組合せを判定 logic で escalate finding として識別、judgment override 件数 + disagreement 件数算出時に正しく count (Req 2.5 整合、design-review skill 側 mapping を本 script 側で読取り処理)
  - commit hash variance 検出 (Req 3.7) = 30 review session で `design_md_commit_hash` 値が複数あれば `commit_hash_variance` field に warning 記録、comparison-report 併記用 input
  - wall-clock 算出 source = `timestamp_end - timestamp_start` (foundation `review_case.schema.json` の field、design-review v1.2 で必須付与、A3 fix 整合)。**ISO8601 timestamp parse → UTC normalize → 差分秒** で実装、`datetime.fromisoformat()` + `astimezone(timezone.utc)` で timezone-aware 計算、UTC/JST 混在 input でも同一基準で算出 (A3 apply)
  - exit code: 0=success / 1=JSONL read fail / 2=JSON parse fail (corruption、line number stderr) / 3=schema validate fail (optional、`--validate` flag 時) / 4=output write fail
  - 2 スペースインデント遵守
  - Observable: pytest run で test_metric_extractor.py 全 test pass (TDD step 4) + `python3 metric_extractor.py --input fixture.jsonl --output metrics.json --dual-reviewer-root scripts/dual_reviewer_prototype/` 実行で `dogfeeding_metrics.json` 生成 + 12 軸 metric presence
  - _Requirements: 1.6, 2.5, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_
  - _Depends: 2.1_

- [ ] 3. figure_data_generator.py 実装 (TDD)
- [ ] 3.1 (P) `tests/test_figure_data_generator.py` 先行作成 (TDD step 1)
  - mock metrics input (`dogfeeding_metrics.json` fixture) + design-review/spec.json `approvals.design.approved` mock (true / false 両 case)
  - figure 1 (`miss_type` 6 enum 分布 × 3 系統) algorithm assertion (Req 5.1)
  - figure 2 (`difference_type` 6 enum × 3 系統 + forced_divergence 効果 = `difference_type=adversarial_trigger` 件数) algorithm assertion (Req 5.2)
  - **figure 2 sequencing 制約 mock test** (Req 5.2): design-review approve = false → figure 2 generation skip + warning (exit 0、不 fail) / approve = true → figure 2 生成 OK
  - figure 3 (`trigger_state` 3 enum [`negative_check` / `escalate_check` / `alternative_considered`] applied/skipped 比率 × 3 系統) algorithm assertion (Req 5.3)
  - figure ablation (dual vs dual+judgment 過剰修正比率削減 + 採択率増加 + judgment override + 必要性判定 quality = `override_reason` 内容分析) algorithm assertion (Req 5.4)
  - figure 4-5 (case study qualitative) は scope 外 (Req 5.5) = 生成しない negative test
  - **figure data file minimum structure 6 top-level field** (P4 fix 整合): `version` + `figure_id` + `generated_at` + `metric_source` + `data` (per treatment) + `metadata` presence assertion
  - 2 スペースインデント遵守
  - Observable: pytest run で全 test fail (TDD step 1)
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_
  - _Boundary: scripts/dual_reviewer_dogfeeding/tests/test_figure_data_generator.py_

- [ ] 3.2 `figure_data_generator.py` 実装 (TDD step 2-4)
  - 入力: `--metrics <json absolute path>` + `--output-dir <directory>` + `--design-review-spec <json absolute path>` (Req 5.2 sequencing check)。foundation install location resolve は **共通 helper `helpers.py` から import** (P3 apply、DRY 規律)
  - 出力: 4 file (`figure_1_data.json` + `figure_2_data.json` + `figure_3_data.json` + `figure_ablation_data.json`)、配置 path = `--output-dir` 引数 (default = `.kiro/methodology/v4-validation/`)
  - figure 1 data 生成: `miss_type` 6 enum 分布 (件数 + 比率) × 3 系統各々 (Req 5.1)
  - figure 2 data 生成: `difference_type` 6 enum 分布 × 3 系統 + forced_divergence 効果 (= dual / dual+judgment 系統 `adversarial_trigger` 発動件数 + 比率) (Req 5.2)
  - **figure 2 sequencing 制約**: `--design-review-spec` で指定された `dual-reviewer-design-review/spec.json` の `approvals.design.approved` 値を read、false なら figure 2 generation skip + stderr warning report ("design-review approve 未完、figure 2 skip"、exit 0 で他 figure は生成継続)
  - figure 3 data 生成: `trigger_state` 3 enum 発動率 (`applied` 比率 vs `skipped` 比率) × 3 系統各々 + Phase 1 同型 hit rate との対応関係 (Req 5.3)
  - figure ablation data 生成 (V4 §4.4 ablation framing 整合): dual vs dual+judgment で過剰修正比率削減効果 + 採択率増加効果 + judgment override 件数 + 必要性判定 quality (= `override_reason` 内容分類) (Req 5.4)
  - 各 figure data file は 6 top-level field 規約 (`version` + `figure_id` + `generated_at` + `metric_source` + `data` + `metadata`、P4 fix 整合) で出力 (Req 5.6)
  - figure 4-5 (case study qualitative) は本 spec scope 外 = 生成しない (Req 5.5)
  - exit code: 0=success / 0+warning=sequencing violation (figure 2 skip) / 1=metrics read fail / 2=output write fail
  - 2 スペースインデント遵守
  - Observable: pytest run で test_figure_data_generator.py 全 test pass + `python3 figure_data_generator.py --metrics dogfeeding_metrics.json --output-dir .kiro/methodology/v4-validation/ --design-review-spec .../dual-reviewer-design-review/spec.json` 実行で 4 file 生成 + 6 top-level field structure 確認
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_
  - _Depends: 3.1, 2.2_

- [ ] 4. phase_b_judgment.py 実装 (TDD)
- [ ] 4.1 (P) `tests/test_phase_b_judgment.py` 先行作成 (TDD step 1)
  - 5 条件評価 mock (Req 6.1):
    - (a) 致命級発見 ≥ 2 件 (Spec 3 dogfeeding 1 件 [外部固定累積値、定数として hardcode] + Spec 6 dogfeeding ≥ 1 件 mock)
    - (b) disagreement ≥ 3 件 (Spec 3 = 2 件 + Spec 6 で 1 件以上 mock)
    - (c) bias 共有反証 evidence (= JSONL `source: adversarial` finding で primary 未検出 issue_id ≥ 1 件、A2 fix 機械評価 logic)
    - (d) `impact_score.severity` enum で `CRITICAL` または `ERROR` を含む finding ≥ 1 件
    - (e) 過剰修正比率改善 (dual+judgment 系統 vs dual 系統で `do_not_fix` 比率減 + `must_fix` 比率増)
  - go/hold 判定 mock test (5 条件全達成 → go / 1 件未達 → hold、Req 6.2)
  - V4 仮説検証併記 mock (H1 ≤ 20% / H3 ≥ 50% / H4 + 50% 以内、Req 6.3)
  - **comparison-report append idempotent test** (P5 fix 整合): 既に section ID `<!-- section-id: phase-b-fork-judgment-v1 -->` 存在 mock → append skip + warning + judgment record stdout 出力 + exit 0 / 既存なし mock → 新規 § append + destructive 改変なし
  - **condition (c) 機械評価 logic test** (A2 fix + A1 apply): adversarial finding の **issue_id 区別** を mock fixture で 2 cases 明示:
    - case 1: adversarial finding が **完全独立発見** (= primary 未検出 issue、new issue_id で生成、primary issue_id array に存在しない) → condition (c) count up
    - case 2: adversarial finding が **counter_evidence** (= primary issue に対する counter_evidence、design-review tasks Task 5.1 = "adversarial 出力 yaml の counter_evidence section を issue_id 単位 decompose" 整合、primary issue_id 流用 = primary issue_id array に存在) → condition (c) **count up しない** (= primary 検出済を adversarial が議論しているのみ、primary 見落 evidence ではない)
    - case 3: 全 adversarial finding が case 2 (primary 検出済との counter_evidence のみ) → condition (c) bool false
    - case 4: 1 件以上 case 1 (完全独立発見) → condition (c) bool true、output `evidence_references` に該当 issue_id list 付与
  - client-verifiable evidence 形式 (Req 6.5): judgment record output に `evidence_references` field (issue_id + treatment + round_index) presence assertion
  - 2 スペースインデント遵守
  - Observable: pytest run で全 test fail (TDD step 1)
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_
  - _Boundary: scripts/dual_reviewer_dogfeeding/tests/test_phase_b_judgment.py_

- [ ] 4.2 `phase_b_judgment.py` 実装 (TDD step 2-4)
  - 入力: `--metrics <json absolute path>` + `--figure-dir <directory>` + `--report <comparison-report.md absolute path>`。foundation install location resolve は **共通 helper `helpers.py` から import** (P3 apply、DRY 規律)
  - 出力: comparison-report.md に新 §12 (Phase B fork 判定) を append (destructive 改変なし、既存 §1-11 改変なし、append-only、Decision 4 整合) + judgment record stdout (JSON format)
  - 5 条件評価 logic (Req 6.1) を constants として明記 (致命級 ≥ 2、disagreement ≥ 3、impact_score CRITICAL/ERROR ≥ 1)
  - **condition (c) 機械評価 logic** (A2 fix + A1 apply): JSONL log iterate → `source: adversarial` finding 抽出 → 同 review_case 内 primary findings の `issue_id` array 照合 → **不存在 = "primary 未検出 + adversarial 完全独立発見" (= new issue_id 生成、counter_evidence ではない)** = 1 件 count up / **存在 = "adversarial が primary issue_id 流用で counter_evidence 提供" (= design-review tasks Task 5.1 = primary issue_id 単位 decompose 整合)** = count up しない (= primary 検出済を議論しているのみ) → ≥ 1 で condition (c) bool true、output `evidence_references` list (issue_id + treatment + round_index) 付与
  - **adversarial subagent prompt 設計前提**: adversarial subagent が primary 検出済 issue を議論する場合は primary issue_id 流用 (counter_evidence)、primary 未検出 issue を独立発見する場合は new issue_id 生成 = この区別は design-review skill (`dr-design` SKILL.md adversarial dispatch instructions) で実現される前提、本 task は logic 実装と test fixture で区別を明示するのみ
  - go/hold 判定 (Req 6.2): 5 条件全達成 → `decision: "go"` / 1 件未達 → `decision: "hold"`
  - V4 仮説検証併記 (Req 6.3): H1 (過剰修正 ≤ 20%) + H3 (採択率 ≥ 50%) + H4 (wall-clock + 50% 以内) の達成度を `v4_hypotheses` field で record
  - 8 月 timeline check (Decision 5、Req 2.6 b 整合): 8 月末日までに figure 1-3 + ablation evidence 完了状態 confirm、未達時 hold 判定の補助根拠として comparison-report に明記
  - go 判定時: Phase B-1.0 release prep 移行手順併記 (固有名詞除去 / npm package 化 / GitHub repo 公開検討、本 spec scope 外として記述、Req 6.4)
  - hold 判定時: V4 protocol 改訂候補 + 追加 dogfeeding 範囲記述 (実施は本 spec scope 外、別 spec 責務として明示、Req 6.4)
  - **comparison-report append idempotent logic** (P5 fix): section ID `phase-b-fork-judgment-v1` 固定、`<!-- section-id: phase-b-fork-judgment-v1 -->` HTML comment で既存 check → 既存あり = append skip + stderr warning ("already appended、skip") + judgment record stdout + exit 0 / 既存なし = 新規 §12 append (既存 §1-11 + 変更履歴後に挿入)
  - client-verifiable evidence 形式 (Req 6.5): judgment record output に JSONL log + metric + figure data への参照を `evidence_references` field として記述、第三者再算出可能 (subjective 判断のみ禁止)
  - exit code: 0=success / 0=warning(idempotent re-run) / 1=input read fail / 2=append fail
  - 2 スペースインデント遵守
  - **granularity 注記** (P6 apply): 本 task は 5 条件評価 + V4 仮説検証 + condition (c) 機械評価 + comparison-report append idempotent + 8 月 timeline check + go/hold mapping + judgment record stdout = 多機能、推定 3+h で kiro 1-3h ガイドライン上限超過 risk。**implementation 着手時に split 判断**: 4.2a [5 条件評価 + V4 仮説 + condition (c) 機械評価 = `judgment_logic.py`] / 4.2b [comparison-report append + idempotent + 8 月 timeline check = `report_writer.py`] に分割可、または single file `phase_b_judgment.py` 内で関数 module 分離維持。判断は implementation 着手 reviewer で確定
  - Observable: pytest run で test_phase_b_judgment.py 全 test pass + `python3 phase_b_judgment.py --metrics dogfeeding_metrics.json --figure-dir .kiro/methodology/v4-validation/ --report .../comparison-report.md` 実行で comparison-report.md 新 §12 append 確認 (idempotent re-run で既存 detect + skip)
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_
  - _Depends: 4.1, 2.2, 3.2_

- [ ] 5. Operational Protocol Documentation (= README full、3 script 完成後)
  - `scripts/dual_reviewer_dogfeeding/README.md` を 3 script 完成後に full 記述 (Task 1 で配置した skeleton scope を expand)
  - section 構成 (bilingual heading 適用):
    1. **Scope** (Task 1 配置済 = consumer-only + Phase A scope constraints + out-of-scope: B-1.x / multi-vendor / 論文 draft / case study)
    2. **Treatment Flag Contract section** (Decision 3 + 6 整合、design-review v1.2 cycle で改修される dr-design `--treatment` flag behavior table = single / dual / dual+judgment 各 Step A/B/C/D 切替動作 + user 提示 skip/実行 切替)
    3. **Consumer 拡張 4 field section** (foundation Req 3.6 整合、`treatment` / `round_index` / `design_md_commit_hash` / `adversarial_counter_evidence` 4 field 仕様)
    4. **3 Script 連携手順** (起動順序: dr-init bootstrap → 30 review session → metric_extractor.py → figure_data_generator.py → phase_b_judgment.py + 各 script 起動 CLI 引数 + exit code mapping)
    5. **Round 開始時 commit hash 取得手順** (P10 fix 整合、Operational Protocol 内 4 step = Round 開始時 `git rev-parse HEAD` 取得 → 同一 Round 内 3 系統で同一 hash 使用 → Round 完了後次 Round で再取得 → 30 session 中 hash variance metric_extractor で検出 + comparison-report 併記)
    6. **dogfeeding session 全体フロー** (Spec 6 適用 → 30 review session → 3 script 実行 → Spec 6 design approve 確認 → A-2 終端 = Phase A 終端 = Phase B-1.0 release prep 移行 trigger)
  - foundation `dr-init` skill + design-review 3 skills の起動順序 + payload 規約 (`--treatment` / `--round_index` / `--design-md-commit-hash` 引数) を 3 系統別に記述 (Req 1.4 / 2.1 / 2.3 / 2.4 / 3.4 / 3.6 / 3.7 / 3.8 整合)
  - Phase A scope = `scripts/dual_reviewer_prototype/` 配下のみ対象、Phase B fork 移行 trigger 明示 (Req 7.4 / 7.5 整合)
  - Observable: README.md content で 6 section 全 presence + Treatment Flag behavior table presence + Consumer 拡張 4 field 仕様 presence + 3 script 起動順序 + Round 開始時 commit hash 取得 4 step 手順 presence
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 2.6, 2.7, 3.4, 3.6, 3.7, 3.8, 7.1, 7.2, 7.3, 7.4_
  - _Depends: 4.2_

- [ ] 6. Integration tests
- [ ] 6.1 (P) 3 script sequential flow integration test (metric_extractor → figure_data_generator → phase_b_judgment)
  - clean test JSONL (sample 30 line fixture、3 treatment × 10 Round + 必要 4 field 完備) 投入 → 3 script 順次実行 → 全 file 生成 + comparison-report append 完了 確認
  - test fixture 内に condition (c) trigger (= adversarial finding で primary 未検出 issue_id 1 件以上、A1 apply の "完全独立発見 case" 整合) + impact_score CRITICAL finding 1 件以上 含める (= go 判定可能 fixture)
  - 順次実行: `metric_extractor.py` → `figure_data_generator.py` → `phase_b_judgment.py`、各 script の output (前段) を input (後段) として連鎖
  - **figure data 内容参照確認 assertion** (A2 apply、Req 6.5 client-verifiable evidence 充足): `phase_b_judgment.py` 実行後の judgment record output (stdout JSON) の `evidence_references` field に figure data file path **+ figure data 内の数値 reference** (例: figure_ablation_data.json の `dual+judgment` vs `dual` 過剰修正比率削減 numeric value) が含まれることを assertion (= phase_b_judgment.py が figure data file を path 記録のみではなく content を read して judgment evidence に reflect することを mechanical verify)
  - Observable: pytest run で test pass + `dogfeeding_metrics.json` + 4 figure data file (figure_1/2/3/ablation_data.json) + comparison-report.md 新 §12 append 全 presence + judgment record `evidence_references` field に figure data 数値 reference 含む確認
  - _Requirements: 7.2_
  - _Depends: 2.2, 3.2, 4.2_
  - _Boundary: scripts/dual_reviewer_dogfeeding/tests/test_integration_flow.py_

- [ ] 6.2 (P) Consumer 拡張 4 field integration test (mock-JSONL fixture 利用)
  - mock-JSONL fixture (30 line、design-review v1.2 implementation 不要 = mock 形式で 4 field 強制付与) 投入 → metric_extractor.py が 4 field (`treatment` / `round_index` / `design_md_commit_hash` / `adversarial_counter_evidence`) を正しく認識 + 30 review_case 全件で 4 field presence 確認
  - 4 field 値整合性: `treatment` ∈ {single, dual, dual+judgment} / `round_index` ∈ 1..10 / `design_md_commit_hash` non-empty string / `adversarial_counter_evidence` は dual / dual+judgment 系統で必須、single 系統で省略可
  - foundation schema consumer 拡張 mechanism (`additionalProperties: true`、foundation Req 3.6 整合) 経由で 4 field を許容することを foundation `finding.schema.json` + `review_case.schema.json` で validate pass 確認
  - **4 field 全件 presence 独立 assertion** (A6 apply、Req 3.6/3.7/3.8 必須付与 contract verifiability): foundation schema は `additionalProperties: true` で field 不在でも validate pass する性質 = consumer 側で field existence assertion 必要。30 line 全 review_case dict に対し `assertIn("treatment", review_case)` + `assertIn("round_index", review_case)` + `assertIn("design_md_commit_hash", review_case)` で **key としての presence** 明示確認 + `adversarial_counter_evidence` は finding object 単位で treatment 値と組み合わせ assert (dual / dual+judgment 系統 finding で `assertIn`、single 系統 finding で省略可)
  - Observable: pytest run で test pass + 30 line 全 review_case で 4 field 整合 + foundation schema validate pass + **4 field 全件 presence assertion 全 pass** (= 1 件でも field absence あれば test fail = 必須付与違反 mechanically detect、A6 apply)
  - _Requirements: 3.6, 3.7, 3.8_
  - _Depends: 2.2_
  - _Boundary: scripts/dual_reviewer_dogfeeding/tests/test_consumer_extension_fields.py_

- [ ] 7. design-review v1.2 revalidation gate verify (= A-2 prerequisite gate)
  - design-review/spec.json `phase` + `approvals.design.approved` 状態 confirm (= design-review v1.2 状態が re-approve されているか)
  - design-review v1.2 改修内容 confirm (Decision 6 = treatment flag / timestamp / commit_hash 3 件):
    - dr-design skill が `--treatment` flag を受領 + Step A/B/C/D 切替動作 + user 提示 skip/実行 切替 implementation 完了
    - dr-log skill が `timestamp_start` / `timestamp_end` を JSONL append 時必須付与 implementation 完了
    - dr-log Service Interface が `--design-md-commit-hash` payload 受領 implementation 完了
  - dr-design `--treatment=dual+judgment` smoke test (= sample 1 round 通過 test、design-review Req 7.4 整合): foundation `dr-init` で test target project bootstrap → dr-design 起動 (Round 1 のみ、treatment=dual+judgment) → Step A/B/C/D 全完了 + JSONL 1 entry validate 成功 + V4 §2.5 三ラベル提示 yaml stdout 出力 の 3 条件達成 confirm (本 task では smoke test として単発実行 = A-2 30 session 開始前の動作確認)
  - **A-2 prerequisite check**: 全 confirm 達成で Task 8 (A-2 E2E) 着手可能、未達なら design-review revalidation cycle 完走待ち
  - Observable: design-review/spec.json approve 状態 confirm log + 3 改修要件 implementation 完了 confirm log + dr-design smoke test 3 条件達成 log
  - _Requirements: design-review/Decision 6 (本 spec contract verify)、Req 7.2 a-c prerequisite_
  - _Depends: 6.1, 6.2_

- [ ] 8. A-2 Termination Tracker (= Spec 6 dogfeeding 完走 + Phase A 終端)
  - **A-2 Prerequisite confirm** (Task 7 で gate verify 済): foundation + design-review implementation phase 完了 + design-review v1.2 cycle 完了 + Spec 6 (`rwiki-v2-perspective-generation`) design.md generation 進行 (Spec 6 spec 責務、本 spec 並走、本 spec は Spec 6 design 内容に介入せず Req 7.1 整合)
  - **A-2 dogfeeding session 6 完了状態必要条件** (Req 7.2 a-f 全達成):
    - (a) Spec 6 適用 + dr-init bootstrap (Spec 6 working directory) + dual-reviewer prototype 動作確認 (Req 1.1-1.6)
    - (b) Round 1-10 × 3 系統 = 30 review session 完走、各 Round 開始時 commit hash 取得 + 同 Round 内 3 系統で同一 hash 使用 (Req 2.1-2.7、Round 開始時 commit hash 取得手順 = README section 5 整合)
    - (c) JSONL log 30 line 蓄積 + foundation schema validate 通過 (Req 3.1-3.8、4 consumer 拡張 field 必須付与)
    - (d) `metric_extractor.py` 実行 → `dogfeeding_metrics.json` 生成 (Req 4.1-4.7 全 12 軸 metric)
    - (e) `figure_data_generator.py` 実行 → 4 figure data file 生成 (Req 5.1-5.6、figure 2 sequencing 制約 = design-review approve 後)
    - (f) `phase_b_judgment.py` 実行 → comparison-report.md §12 append (5 条件評価 + go/hold + V4 仮説検証 + evidence_references、Req 6.1-6.5)
  - **Spec 6 design approve 確認条件** (Req 7.3): `.kiro/specs/rwiki-v2-perspective-generation/spec.json` `approvals.design.approved: true` 確認 (= Spec 6 spec 自身の責務、本 spec は approve 強制せず確認のみ)
  - **Phase A 終端記録**: 6 完了状態必要条件 (a-f) 全達成 + Spec 6 design approve 確認 → Rwiki v2 design phase 全 8 spec approve 完了 = **Phase A 終端 = Phase B-1.0 release prep 移行 trigger 成立** (Req 7.4)
  - 8 月 timeline failure check (Decision 5、Req 2.6 b): 8 月末日までに figure 1-3 + ablation evidence (= a-f の e 達成) 完了 = timeline 達成 / 未達 = `phase_b_judgment.py` の hold 判定補助根拠
  - **scope 外明示**: 論文 draft 執筆 (Phase 3 = 7-8 月、別 effort) + case study 記述 (figure 4-5 qualitative) + B-1.x 拡張 schema + multi-vendor 対照実験 + Phase B-1.0 release prep 自体 (= 元 A-3 統合 #3) は本 spec scope 外 (Req 7.5/7.6/7.7)
  - Observable: 6 完了状態必要条件 (a-f) 全達成 + Spec 6 design approve 成立 + Phase A 終端 (Rwiki v2 design phase 全 8 spec approve 完了) record + comparison-report §12 内容 = 5 条件評価 + go/hold + V4 仮説 + evidence references presence
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_
  - _Depends: 7_

## Change Log

- **v1.0** (2026-05-01 14th セッション、本 file 初版): A-1 tasks phase = `/kiro-spec-tasks dual-reviewer-dogfeeding` Skill 経由生成、8 major task / 8 sub-task、consumer-only spec の Operational Protocol + Research Script Hybrid pattern (Decision 2 整合)、TDD 順序 (test first → fail → impl → pass、A5 fix + Decision 7 整合)、A-1 phase = Python script 実装 (Task 1-6) + A-2 phase = Spec 6 適用 (Task 8) の 2 segment 分担。Step 3 Task plan review gate pass + Step 3.5 sanity review subagent verdict = `NEEDS_FIXES` (7 fix list)、1 repair pass で 7 fix integrate (= Task 2 削除統合 + 7.2 / 7.3 dependency 修正 + Task 7 design-review v1.2 gate task 追加 + Task 1 boundary clean + README order 後置 + Req 2.5 mapping 追加)。
- **v1.1** (2026-05-01 14th セッション、V4 ad-hoc protocol Step 1a/1b/1b-v/1c/2/3 review gate 完走後): V4 review 14 件 (P1-P6 primary + A1-A8 adversarial) 検出、judgment subagent 必要性評価で must_fix 5 / should_fix 3 / do_not_fix 6、user 三ラベル提示で全 8 件 apply (must_fix bulk apply + should_fix bulk apply + do_not_fix bulk skip)。
  - **P3 apply** (must_fix): Task 1 で Foundation install location resolve helper を **共通 module `scripts/dual_reviewer_dogfeeding/helpers.py`** として skeleton 配置明示 + Task 2.2/3.2/4.2 で各 script は helpers.py から import (DRY 規律遵守、3 script 内 inline 実装禁止)
  - **P4 apply** (must_fix): Task 1 description で "foundation tasks + design-review tasks **tasks-approved** 状態 confirm" 明示 (= tasks-approved phase prerequisite)、Task 8 で "implementation phase 完了" prerequisite 明示の 2 段階 prerequisite separation
  - **A1 apply** (must_fix): Task 4.1/4.2 condition (c) 機械評価 logic で adversarial finding の **issue_id 区別** (= 完全独立発見 [new issue_id] vs counter_evidence [primary issue_id 流用]) を明示、test fixture で 4 cases 区別 (case 1-4) + adversarial subagent prompt 設計前提を design-review skill 責務として明示
  - **A2 apply** (must_fix): Task 6.1 Observable に "figure data 内容参照確認 assertion" 追加 (= judgment record `evidence_references` field に figure data 数値 reference を含む = phase_b_judgment.py が figure data file content を read して judgment evidence に reflect する mechanical verify、Req 6.5 client-verifiable evidence 充足)
  - **A6 apply** (must_fix): Task 6.2 Observable に "4 field 全件 presence 独立 assertion" 追加 (= `assertIn` で 30 line 全 review_case dict に key presence 明示確認、`additionalProperties: true` で schema validate pass しても field absence mechanically detect 可能、Req 3.6/3.7/3.8 必須付与 contract verifiability)
  - **P6 apply** (should_fix): Task 4.2 description 末尾に "granularity 注記 + implementation 着手時 split 判断" annotation (= 4.2a [5 条件評価 + V4 仮説 + condition (c)] / 4.2b [comparison-report append + idempotent + 8 月 timeline] split 候補、kiro 1-3h ガイドライン超過 risk 対応)
  - **A3 apply** (should_fix): Task 2.1 mock fixture で `timestamp_start` / `timestamp_end` ISO8601 UTC 形式具体例 (`2026-05-01T10:00:00Z` 等) + UTC/JST 混在 edge case test 1 件 + Task 2.2 で `datetime.fromisoformat()` + `astimezone(timezone.utc)` で timezone-aware 計算明示 (V3 baseline 420.7s 比較 = H4 仮説 wall-clock 算出 correctness)
  - **A8 apply** (should_fix): Overview に "(P) annotation の意味補足" 追加 = "tasks 2.1/3.1/4.1 の (P) は同 phase 内 sub-task 間 parallel-capable (= 3 script の test first 並列作成可)、TDD sequential gate (test → fail → impl → pass) は `_Depends: X.1` で維持" (TDD 規律実効性確保)
  - V4 metric: 採択率 35.7% (5/14) / 過剰修正比率 42.9% (6/14) / should_fix 比率 21.4% (3/14) / judgment override 3 件 / primary↔judgment disagreement 2 件 (P3 INFO→must_fix / P4 WARN→must_fix) / adversarial↔judgment disagreement 2 件 (A2 should_fix→must_fix / A3 must_fix→should_fix) / V4 修正否定 prompt 機能 37.5% (adversarial 自己 do_not_fix 3/8)
  - do_not_fix 6 件 bulk skip (V4 §2.5 規範通り、内訳 = P1 [hold fixture coverage、_Depends_ 記述済] / P2 [README presence のみ pytest 化困難 acceptable] / P5 [8 月 timeline check 具体実装 implementation phase 確定] / A4 [consumer-only spec 範囲内、approve 強制せず Req 7.3 整合] / A5 [Task 5 "6 section 全 presence" で網羅済] / A7 [Spec 3 hardcode = AC 確定固定値、over-spec])
  - **3 spec tasks-phase 累計 trend** (foundation → design-review → dogfeeding): 採択率 5.6% → 13.3% → 35.7% (+30.1pt 累計改善) / 過剰修正比率 66.7% → 53.3% → 42.9% (-23.8pt 累計改善) / should_fix 27.8% → 33.3% → 21.4%。3 spec 連続改善で V4 protocol 構造的有効性再現実証 (= design phase trend 81.25% → 58.8% → 40.0% と方向一致)
  - **tasks-phase ad-hoc V4 caveat 4 件** (`data-acquisition-plan.md` v0.3 §5 整合、paper limitations 明示用): (1) ad-hoc 観点 / (2) phase 横断 strict comparability 問題 / (3) forced_divergence prompt design phase optimization / (4) paper rigor 保証
