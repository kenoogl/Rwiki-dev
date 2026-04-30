# Requirements Document

## Project Description (Input)

dual-reviewer prototype の有効性検証 + Phase B fork go/hold 判断 + 論文用 quantitative evidence (figure 1-3 用) 取得が必要。Spec 6 (`rwiki-v2-perspective-generation`) design phase が dogfeeding 場として最適 (dual-reviewer Phase A 期間中ペンディング維持、A-2 で再開 = Spec 6 design approve 同時に Phase A 終端)。対照実験 (single = Opus のみ vs dual = Opus + Sonnet) で adversarial 構造の効果を定量化する必要。

ドラフト v0.3 (`.kiro/drafts/dual-reviewer-draft.md`) §3.1 A-2 + §3.5 で対照実験設計確定 (全 Round で single + dual の両方完走、cost 倍)、§2.10.3 で論文 figure 候補確定 (figure 1-3 = quantitative)、Phase B fork timing 判断基準確定 (致命級 ≥ 2 件 / disagreement ≥ 3 件 / bias 共有反証 evidence 確実 / `impact_score` 分布が minor のみではない)。dual-reviewer prototype は `dual-reviewer-foundation` + `dual-reviewer-design-review` の 2 spec で構築予定 (本 spec の依存元)。

本 spec は dual-reviewer prototype を Spec 6 design に適用、Round 1-10 を single (Opus のみ) + dual の両系統で完走 (cost 倍)、JSONL log 取得 → 比較 metric 抽出 + 論文 figure 1-3 用データ整理 + Phase B fork go/hold 判断 + Spec 6 design approve 同時達成を実現する。終端 = A-2 終端 = Phase A 終端 = 即 Phase B-1.0 release prep (元 A-3 統合) に移行。詳細は brief.md (`.kiro/specs/dual-reviewer-dogfeeding/brief.md`) 参照。

## Introduction

dual-reviewer-dogfeeding は dual-reviewer (LLM 設計レビュー方法論 v3 一般化 package) prototype を Rwiki v2 Spec 6 (`rwiki-v2-perspective-generation`) の design phase に適用し、有効性検証 + Phase B fork go/hold 判断 + 論文用 quantitative evidence (figure 1-3) 取得を実現する dogfeeding 場を提供する。`dual-reviewer-foundation` (Layer 1 framework + 共通 JSON schema + `seed_patterns.yaml` + `fatal_patterns.yaml` + `dr-init` skill) と `dual-reviewer-design-review` (`dr-design` / `dr-log` skill + Layer 2 design extension + Chappy P0 全機能 + B-1.0 拡張 schema 自己ラベリング + single/dual mode 切替) の prototype を活用し、全 Round (1-10) を single mode (Opus のみ) + dual mode (Opus + Sonnet) の両系統で完走する対照実験を実施 (cost 倍)、両系統 JSONL log 取得 + 比較 metric 5 種抽出 + 論文 figure 1-3 用データ整理 + Phase B fork 判断 + Spec 6 design approve 同時達成を実現する。終端 = A-2 終端 = Phase A 終端 = Rwiki v2 design phase 全 8 spec approve 完了 (Spec 6 ペンディング解除) + Phase B-1.0 release prep への即時移行可能性確立。

primary 参照点:

- ドラフト v0.3 = `.kiro/drafts/dual-reviewer-draft.md` §2.10 / §3.1 A-2 / §3.5 / §4.6
- memory = `~/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/feedback_design_review_v3_generalization_design.md` §1-14
- 依存元 spec = `.kiro/specs/dual-reviewer-foundation/requirements.md` (req approve 待ち) / `.kiro/specs/dual-reviewer-design-review/requirements.md` (req approve 待ち)
- 適用対象 = `.kiro/specs/rwiki-v2-perspective-generation/` (Spec 6、req approved phase で待機、design phase 未着手)

## Boundary Context

- **In scope**:
  - Spec 6 (`rwiki-v2-perspective-generation`) design phase への dual-reviewer prototype 適用
  - 全 Round (1-10) を single mode (Opus のみ) + dual mode (Opus + Sonnet) の両系統で完走 (cost 倍)
  - 両系統で foundation 共通 JSON schema 準拠 JSONL log の取得 + 検証
  - 比較 metric 5 種抽出 (致命級発見再現性 / disagreement 率 / Phase 1 同型 hit rate / `impact_score` 分布 / `fatal_patterns.yaml` 強制照合効果)
  - 論文 figure 1-3 用 quantitative evidence 整理 (`miss_type` 分布 / `difference_type` 分布 / `trigger_state` skipped 比率)
  - Phase B fork go/hold 判断 (4 基準照合 + partial 成立時 user escalate)
  - Spec 6 design approve 同時達成 (A-2 終端 = Phase A 終端)
- **Out of scope**:
  - dual-reviewer prototype 本体実装 (`dual-reviewer-foundation` + `dual-reviewer-design-review` の責務)
  - Spec 6 design 内容自体の策定 (`rwiki-v2-perspective-generation` spec が本 spec と並走、本 spec は dual-reviewer 適用と review evidence 提供のみ)
  - 論文ドラフト執筆 (Phase 3 = 7-8月、別 effort、本 spec は figure 1-3 用データ取得のみ)
  - B-1.x 拡張 schema 実装 (`decision_path` / `skipped_alternatives` / `bias_signal`、figure 4-5 用 qualitative evidence は B-1.x で別 spec、本 spec の A-2 期間中に parallel 走行する可能性ありだが本 spec scope 外、ドラフト v0.3 §3.5 Phase 3 規範)
  - case study 記述 (figure 4-5、Phase 3 論文ドラフト)
  - multi-vendor 対照実験 (Claude vs GPT vs Gemini 等、B-2 以降)
  - Phase B-1.0 release prep (固有名詞除去 / npm package 化、本 spec 完了後の作業 = 元 A-3 統合)
  - cross-session resume 対応 (`dual-reviewer-design-review` Boundary Out 整合)
  - Rwiki 既存 spec (Spec 0-5 / 7) の改変 (本 spec の対象は Spec 6 design phase のみ)
- **Adjacent expectations**:
  - `dual-reviewer-foundation` が以下を stable interface で公開していること: Layer 1 framework / 共通 JSON schema (`review_case` / `finding` / `impact_score` 3 軸 / `miss_type` / `difference_type` / `trigger_state` / `phase1_meta_pattern`) / `seed_patterns.yaml` / `seed_patterns_examples.md` / `fatal_patterns.yaml` / `dr-init` skill (`.claude/skills/dr-init/SKILL.md` 形式)
  - `dual-reviewer-design-review` が以下を stable interface で公開していること: `dr-design` skill (10 ラウンド orchestration + Chappy P0 全機能 + B-1.0 拡張 schema 自己ラベリング) / `dr-log` skill (foundation 共通 JSON schema 準拠 JSONL 構造化記録 + single mode / dual mode の出力 path 分離) / single mode + dual mode 切替 (skill argument 経由) / sample 1 round 通過確認済 prototype (Req 7 AC 7.3 evidence)
  - 両依存元 spec の `tasks.md` approve 済 + `dual-reviewer-design-review` Req 7 AC 7.3 の sample 1 round 通過確認 evidence = A-1 prototype 実装完了が本 spec 着手の precondition
  - Spec 6 (`rwiki-v2-perspective-generation`) design phase が本 spec の各 Round 着手前段で初版以上の状態にあること、Spec 6 design 文書の生成 / 改訂 / approve は Spec 6 spec の責務、本 spec 進行中の Spec 6 design 改訂は次 Round 適用時の input として反映 (本 spec は dual-reviewer 適用と review evidence 提供のみで Spec 6 design 内容を改変しない)
  - 本 spec は依存元 prototype の internal 実装詳細に依存せず、公開 contract (skill SKILL.md + JSONL 出力 schema + skill argument 経由 mode 切替 + foundation `config.yaml` 利用) のみ依存する

## Requirements

### Requirement 1: Spec 6 design への dual-reviewer prototype 適用 (10 ラウンド完走)

**Objective:** dual-reviewer 開発者として、Spec 6 (`rwiki-v2-perspective-generation`) design phase に dual-reviewer prototype を適用し全 Round (1-10) を完走したい。これにより、prototype が real-world spec design に対し動作する evidence を取得し、Spec 6 design approve に必要な review evidence を構築する。

#### Acceptance Criteria

1. The dual-reviewer-dogfeeding shall 着手 precondition として以下を確認する: (a) `dual-reviewer-foundation` および `dual-reviewer-design-review` の両 spec の `tasks.md` approve 済 / (b) `dual-reviewer-design-review` Req 7 AC 7.3 の sample 1 round 通過確認 evidence あり (= A-1 prototype 実装完了) / (c) Spec 6 (`rwiki-v2-perspective-generation`) `design.md` が初版以上の状態で review 対象として参照可能、かつ両系統 (single + dual) で参照する Spec 6 `design.md` snapshot を同一に固定 (実行順序前後で改訂された場合は両系統再実行 / limitation 付加で継続 / 中断 の判断を user 判断に escalate、各 Round 適用時に design.md snapshot を input として固定、Round 跨ぎでの design.md 改訂は次 dogfeeding session に回す。未生成 / 部分生成時の着手判断も user 判断に escalate)
2. When Spec 6 design phase に prototype を適用する, the dual-reviewer-dogfeeding shall `dr-design` skill を invoke し全 Round (1-10) の orchestration を完走する (`dual-reviewer-design-review` Req 1 AC 1.2 の 10 ラウンド全件適用 contract 利用)。failure なく全 20 review_case (10 round × 2 系統) 完了時は成功宣言とし、AC 4 の failure 段階化 3 種いずれにも該当しない正常系終端状態として扱う
3. The dual-reviewer-dogfeeding shall Spec 6 design 文書を review 対象 input として `dr-design` skill に渡す (Spec 6 design 内容自体の策定は Spec 6 spec の責務、本 spec は適用のみで内容改変しない)
4. If `dr-design` 実行中に failure 発生, then the dual-reviewer-dogfeeding shall failure 段階化 3 種で対応する: (a) fatal error (artifact load 失敗 / subagent dispatch 失敗 / config 不正等、`dual-reviewer-design-review` Req 1 AC 1.6 fatal error 経路) → 全体中断 + 中断時点までの partial 結果 (`dr-log` 出力 JSONL 経由) を観測し、再実行 / fall back / 中断のいずれを選択するかを user 判断に escalate / (b) 1 round 失敗 (1 round 内で recoverable error) → 残り round 継続 vs 中断の判断を user 判断に escalate / (c) 1 系統失敗 (single 完了 + dual 未着手で系統単位中断 等) → 他系統開始 vs 中断の判断を user 判断に escalate。partial 進行状態の粒度 = round 単位 / 系統単位 / 全体単位 を post-run 観測可能な形式で JSONL 内に記録する
5. While 各 Round 実行中, the dual-reviewer-dogfeeding shall 依存元 prototype の internal 実装詳細に依存せず公開 contract (skill SKILL.md + JSONL 出力 schema + skill argument 経由 mode 切替 + foundation `config.yaml` 利用) のみで運用する。各 Round 開始・完了時の user 可視 progress signal は依存元 (`dual-reviewer-design-review` `dr-design` skill stdout / log 出力等) contract に委譲する

### Requirement 2: 対照実験 (single mode + dual mode 両系統での全 Round 完走)

**Objective:** 論文化 evidence 取得目的で、全 Round (1-10) を single mode (Opus のみ) と dual mode (Opus + Sonnet) の両系統で独立に完走したい (cost 倍)。これにより、adversarial subagent 構造の有無による発見差を定量化し、bias 共有疑念に対する反証 evidence と adversarial 効果の定量化が同時に達成される。

#### Acceptance Criteria

1. The dual-reviewer-dogfeeding shall 全 Round (1-10) を single mode と dual mode の 2 系統で独立に完走する (各系統で 10 ラウンド = 合計 20 ラウンド分の review session 実行、cost 倍)
2. While single mode 実行中, the dual-reviewer-dogfeeding shall `dr-design` skill argument 経由で adversarial subagent dispatch を skip し primary reviewer (config `primary_model` = Phase A 期間中現状値 Opus) 単独で 10 ラウンドを完走する (`dual-reviewer-design-review` Req 2 AC 2.5 の single mode 切替 contract 利用)
3. While dual mode 実行中, the dual-reviewer-dogfeeding shall `dr-design` skill argument 経由で primary reviewer (config `primary_model` = Phase A 期間中現状値 Opus) + adversarial reviewer (config `adversarial_model` = Phase A 期間中現状値 Sonnet) の dual-reviewer 構成で 10 ラウンドを完走する (`dual-reviewer-design-review` Req 2 AC 2.1-2.3 の dual mode contract 利用)
4. The dual-reviewer-dogfeeding shall single mode と dual mode の両系統が独立 review session として完走することを保証する: 2 系統間の cross-context isolation = 実行順序を single 先行 dual 後行に固定し、single session 完了後に dual session を独立起動 (context 引継ぎなし、memory state リセット = `dr-design` / `dr-log` skill の internal state クリア + LLM context window 独立、`~/.claude/projects/` 配下 memory ファイルは Phase A scope 内で touch しない) する。両系統開始前に config snapshot (`seed_patterns.yaml` / `fatal_patterns.yaml` / Spec 6 `design.md`) を固定し、A-2 期間中の更新は次 dogfeeding session に回す (isolation の具体実装方式 = session 起動方式 / state クリア方式 / 等は design phase で確定、`dual-reviewer-design-review` Req 2 AC 2.3 strict context 分離 contract と整合)
5. While 両系統実行中, the dual-reviewer-dogfeeding shall single mode と dual mode の JSONL log を出力先 path で分離する (`dual-reviewer-design-review` Req 5 AC 5.3 の path 分離 contract 利用)
6. While single mode 実行中, the dual-reviewer-dogfeeding shall `miss_type` + `trigger_state` の自己ラベリングを発動し、`difference_type` field は absent として記録する (`dual-reviewer-design-review` Req 6 AC 6.6 整合、single mode の trigger failure 率と dual mode の比較で adversarial 効果を定量化、ドラフト v0.3 §3.1 A-2 規範)。`trigger_state.alternative_considered: skipped` は forced divergence prompt の skip を意味し、primary reviewer 自身による代替案検討の有無は `negative_check` / `escalate_check` 軸で記録する (識別 distinction は依存元 spec design phase で確定)
7. While 両系統実行中, the dual-reviewer-dogfeeding shall 両系統の concurrent write を前提しない (逐次実行のみ、`dual-reviewer-design-review` Req 5 AC 5.10 整合、ドラフト v0.3 §3.1 A-2 規範)

### Requirement 3: JSONL log 取得 + foundation 共通 JSON schema 準拠

**Objective:** 比較 metric 抽出と論文用 quantitative evidence 取得の前提として、両系統の review session 全 finding と review_case を foundation 共通 JSON schema 準拠の JSONL log として保持したい。これにより、後段の analyze (本 spec の比較 metric 抽出 + 論文 figure 用データ整理) が schema validate された data に対して機械的に実行可能になる。

#### Acceptance Criteria

1. The dual-reviewer-dogfeeding shall single mode と dual mode の両系統で foundation 共通 JSON schema (`review_case` / `finding` / `impact_score` 3 軸 / `miss_type` / `difference_type` / `trigger_state` / `phase1_meta_pattern`、foundation Req 3 AC 3.1-3.10 定義に準拠) 準拠の JSONL output を取得する
2. When 各系統の全 Round (1-10) 完了時, the dual-reviewer-dogfeeding shall `dr-log` skill が出力した JSONL を foundation 共通 JSON schema validator (foundation Req 3 AC 3.9 + design-review Req 5 AC 5.5 contract 利用) で検証 pass することを確認する (検証失敗時の挙動は依存元 spec の design phase で確定)
3. The dual-reviewer-dogfeeding shall JSONL log を A-2 期間中保持し、本 spec 完了後 (Phase B-1.0 release prep 移行時) に独立 fork に持ち越し可能な形式で archive する。基本 archive 形式 = repo 内 fix path 配下 (具体 path naming convention は design phase で確定、外部 storage 利用は B-1.x 以降で別途検討)。本 req 段階で「repo 内保持」を確定し、cross-session resume 機構 (`dual-reviewer-design-review` Boundary Out 整合、B-1.x 以降) との依存関係を本 spec scope 内に閉じる
4. If JSONL 書込失敗 (disk full / 権限不足 / 不正 path 等、`dual-reviewer-design-review` Req 5 AC 5.4 failure mode) を後段で検出, then the dual-reviewer-dogfeeding shall 中断時点までの partial 書込を観測し、再実行 / fall back の判断を user 判断に escalate する (依存元 contract が出力する actionable error message を利用)
5. The dual-reviewer-dogfeeding shall JSONL log を post-run analyze (Req 4 / Req 5) の唯一入力データとして扱い、`dr-design` / `dr-log` skill 実行中の追加副作用を発生させない (測定中の Goodhart's Law 回避、ドラフト v0.3 §2.7 規範)
6. The dual-reviewer-dogfeeding shall Round 完了判定および JSONL 永続化を以下で運用する: (a) Round 完了判定 = JSONL 内 review_case の `round` field aggregate (1-10 全件存在 + 系統識別 path で完走確認) / (b) 各 round 完了時に JSONL append が atomic に永続化される (依存元 `dual-reviewer-design-review` Req 5 AC 5.4 の atomic 書込 contract 利用) / (c) schema 違反 record 検出時は当該 record を除外し metric 抽出を継続 + limitation 付加 (具体除外ロジック / limitation 注記方式は依存元 design phase で確定)
7. The dual-reviewer-dogfeeding shall review_case ID を cross-mode 識別可能な形式 (mode prefix / path 分離 / field 付加等は design phase で確定) で重複防止し、single mode JSONL と dual mode JSONL が混合した場合でも post-run analyze が systematic に分離可能であることを保証する

### Requirement 4: 比較 metric 5 種抽出

**Objective:** dual-reviewer 開発者として、両系統の JSONL log から比較 metric 5 種を抽出し、Phase B fork go/hold 判断 (Req 6) と論文用 quantitative evidence 整理 (Req 5) の入力データを構築したい。これにより、件数中心 metric から脱却した「事故防止価値」観点の評価が evidence-based に可能になる。

#### Acceptance Criteria

1. The dual-reviewer-dogfeeding shall 両系統の JSONL log から致命級発見再現性を抽出する: `fatal_patterns.yaml` 強制照合 hit による CRITICAL severity finding を `impact_score.severity` 経由で集計し、Spec 3 既往 (= 1 件) との累計 ≥ 2 件達成可否を判定可能な形式に整理する
2. The dual-reviewer-dogfeeding shall dual mode の JSONL log から disagreement 率を抽出する: adversarial subagent 独立追加 finding 数 (= `finding.origin: adversarial`) / (primary 検出 finding 数 (= `finding.origin: primary` の finding 数) + adversarial 独立追加 finding 数) = 全 finding に占める adversarial 追加率を集計し、Spec 3 既往 (= 2/24、同定義に基づく) との累計 ≥ 3 件達成可否を判定可能な形式に整理する (forced divergence prompt 効果含む、disagreement 意味付け = adversarial 追加発見、primary 否定された finding を含む真の disagreement の細分化は design phase で確定)
3. The dual-reviewer-dogfeeding shall 両系統の JSONL log から Phase 1 同型 hit rate を抽出する: Spec 0 R4 / Spec 1 R5 / Spec 1 R7 の同型 escalate 3 メタパターン全該当発生回数を集計する (foundation Req 3 AC 3.10 定義の `finding.phase1_meta_pattern` enum 値 = norm_range_preemption / doc_impl_inconsistency / norm_premise_ambiguity 経由、Spec 3 既往 = 3 種全該当 2 度、`dual-reviewer-design-review` Req 6 AC 8 LLM 自己ラベリング + Req 3 AC 3.7 escalate 検出 finding を経由、独立 metric として抽出 + Req 4 AC 8 の構成要素として再利用)
4. The dual-reviewer-dogfeeding shall 両系統の JSONL log から `impact_score` 3 軸 (severity / fix_cost / downstream_effect) 分布を抽出する (件数中心 metric から脱却できているか = minor のみではない比率を観測可能な形式に整理)
5. The dual-reviewer-dogfeeding shall 両系統の JSONL log から `fatal_patterns.yaml` 強制照合効果を抽出する: (a) 強制照合 hit 数 / 全 finding 数 (hit 率、系統別) + (b) single mode で `impact_score.severity = CRITICAL` が absent だった round のうち dual mode で CRITICAL finding が検出された round 数 (cross-mode 漏れ防止 evidence)
6. The dual-reviewer-dogfeeding shall 抽出した metric を single mode vs dual mode の比較形式 (具体 形式は design phase で確定、本 requirements scope では「両 mode 比較可能な形式」のみ要請) として整理する
7. The dual-reviewer-dogfeeding shall metric 抽出を JSONL log の post-run analyze として実装し review session 実行と分離する (測定中の Goodhart's Law 回避、ドラフト v0.3 §2.7 規範)
8. The dual-reviewer-dogfeeding shall 両系統の JSONL log から bias 共有反証 evidence を抽出する: (a) adversarial subagent 独立検出した致命級件数 (= `finding.origin: adversarial` かつ `impact_score.severity: CRITICAL` の件数) + (b) AC 2 の disagreement 率 + (c) AC 3 の Phase 1 同型 hit rate の複合 evidence として整理する (Req 6 AC 1 (3) bias 共有反証 evidence 基準と対応)

### Requirement 5: 論文 figure 1-3 用 quantitative evidence の取得

**Objective:** 論文 (8 月ドラフト提出) の figure 1-3 (quantitative evidence) 用データを本 spec で取得したい。これにより、Phase 3 (7-8月) の論文ドラフト執筆段階で別実験を組まず figure 用データが揃う (二重ループ構造 = 開発と論文の同時前進、ドラフト v0.3 §2.10.1 / §3.5 規範)。

#### Acceptance Criteria

1. The dual-reviewer-dogfeeding shall 両系統の JSONL log から `miss_type` 6 値 enum 分布 (implicit_assumption / boundary_leakage / spec_implementation_gap / failure_mode_missing / security_oversight / consistency_overconfidence) を集計し figure 1 用データとして整理する
2. The dual-reviewer-dogfeeding shall dual mode の JSONL log から `difference_type` 6 値 enum 分布 (assumption_shift / perspective_divergence / constraint_activation / scope_expansion / adversarial_trigger / reasoning_depth) を集計し forced divergence prompt 効果 (どの difference_type が増えたか) と合わせて figure 2 用データとして整理する
3. The dual-reviewer-dogfeeding shall 両系統の JSONL log から `trigger_state` 3 軸 (negative_check / escalate_check / alternative_considered) の skipped 比率を集計し figure 3 用データ (trigger 発動率) として整理する (集計単位 = review_case level、全 20 review_case = 10 ラウンド × 2 系統 = 1 round = 1 review_case、foundation Req 3 AC 3.1 の `review_case.round` field 整合、`trigger_state` は review_case フラグとして draft v0.3 §4.6 整合)
4. The dual-reviewer-dogfeeding shall figure 1 / figure 3 用データを single mode と dual mode の比較として整理する (single の trigger failure 率と dual の比較で adversarial 効果定量化、figure 2 は dual mode のみ = `difference_type` が single mode で absent のため、具体比較形式は design phase で確定、本 requirements scope では single vs dual の系統別 metric 値 / 差分 / ratio が抽出可能な形式のみ要請、Req 4 AC 6 整合)
5. The dual-reviewer-dogfeeding shall figure 1-3 用データに論文 limitation 注記を含める: (a) LLM 自己ラベリング信頼性 = aggregate 統計信頼性は確保 / 個別精度は完全信頼不可 / (b) `trigger_state.skipped` の意図的 skip vs 記録漏れ識別不能 / (c) Req 6 AC 1 (3) bias 共有反証 evidence 基準も同 limitation 範囲に含む / (d) sample 数 = 1 spec × 1 run (single 系統 + dual 系統各 1 回 = 20 review_case) = LLM stochasticity による run-to-run variance は未考慮、cross-spec / multi-run reproducibility 統計は本 spec scope 外で B-1.x 以降検討 (ドラフト v0.3 §2.10.3 規範、`dual-reviewer-design-review` Req 6 AC 6.3 整合)。aggregate 統計信頼性の受容条件 = サンプル数 ≥ 20 review_case (10 round × 2 系統)、系統別独立性は Req 2 AC 4 cross-context isolation で確保、サンプル数不足時 (= partial failure で 20 review_case 未達) は limitation 付加で対応
6. The dual-reviewer-dogfeeding shall B-1.x 拡張 schema 3 要素 (`decision_path` / `skipped_alternatives` / `bias_signal`) の取得を本 spec scope 外として明示する (figure 4-5 用 qualitative evidence は B-1.x で別 spec、ドラフト v0.3 §2.10.3 / Boundary Context Out 整合)

### Requirement 6: Phase B fork go/hold 判断

**Objective:** dual-reviewer 開発者として、本 spec の比較 metric を基準に Phase B fork (独立 GitHub repo `dual-reviewer` への移行) の go/hold を判断したい。これにより、Phase A 終端時点で Phase B 移行の妥当性が evidence-based に決定される。

#### Acceptance Criteria

1. The dual-reviewer-dogfeeding shall Phase B fork go/hold 判断軸として以下 4 基準を採用する: (1) 致命級発見 ≥ 2 件 (Spec 3 既往 = 1 件 + 本 spec で 1 件以上) / (2) disagreement ≥ 3 件 (Spec 3 既往 = 2 件 + 本 spec で 1 件以上、forced divergence 効果含む) / (3) bias 共有反証 evidence 確実 (operational 定義 = Req 4 AC 8 の (a) subagent 独立致命級件数 ≥ 1 + (b) disagreement 率 ≥ 8.3% [Spec 3 = 2/24 base] + (c) Phase 1 同型 hit rate ≥ 1 件 の複合 evidence が all present であること、subagent 独立発見が再現) / (4) `impact_score` 分布が minor のみではない (重要 / 致命級が含まれる)。基準間の包含関係 = (1) → (4) 自動 imply (致命級発見成立時 impact_score 分布も自動で minor のみではない) / (2) ≈ (3) (b) (同 source data) / (1) → (3) (a) 条件付き (本 spec 致命級が adversarial 由来時) = 実質 3 独立 evidence (致命級発見 + disagreement 関連 + Phase 1 同型 hit rate)、AND condition は包含関係考慮で評価する
2. When 4 基準すべて成立, the dual-reviewer-dogfeeding shall Phase B fork go の十分条件として A-2 終端 (= Phase A 終端) を宣言する
3. If 4 基準のいずれかが不成立, then the dual-reviewer-dogfeeding shall partial 成立として追加検証 (再 dogfeeding / prototype 改修 / 等) の判断を user 判断に escalate する (基準 logic を strict AND として固定せず、partial 成立時の対応は user 判断)
4. The dual-reviewer-dogfeeding shall 4 基準の判定根拠を JSONL log 由来の数値 evidence で裏付ける (judgment の subjective bias 排除)。基準と Req 4 metric の対応 = (1) 致命級発見 ≥ 2 件 → Req 4 AC 1 / (2) disagreement ≥ 3 件 → Req 4 AC 2 / (3) bias 共有反証 evidence 確実 → Req 4 AC 8 ((a) subagent 独立致命級件数 + (b) disagreement 率 + (c) Phase 1 同型 hit rate の複合) / (4) `impact_score` 分布が minor のみではない → Req 4 AC 4。Req 4 AC 5 (fatal_patterns 強制照合効果) は補足 evidence、Req 4 AC 3 (Phase 1 同型 hit rate) は基準 (3) 構成要素として再利用
5. The dual-reviewer-dogfeeding shall 判断結果 (go / hold + 4 基準の数値 evidence + judgment 根拠) を本 spec の deliverable (具体 documenting 形式は design phase で確定) として残し、Phase B-1.0 release prep に持ち越し可能な形式で archive する

### Requirement 7: Spec 6 design approve 同時達成 (A-2 終端 = Phase A 終端)

**Objective:** 本 spec 完了 = A-2 終端 = Phase A 終端 = Rwiki v2 design phase 全 8 spec approve 完了 (Spec 6 ペンディング解除) を実現したい。これにより、Rwiki v2 implementation phase への移行 + dual-reviewer Phase B-1.0 release prep への即時移行が可能になる。

#### Acceptance Criteria

1. When 全 Round (1-10) の両系統完走 + 比較 metric 抽出 + 論文 figure 1-3 用データ整理 + Phase B fork 判断完了, the dual-reviewer-dogfeeding shall Spec 6 (`rwiki-v2-perspective-generation`) `design.md` approve 達成のための review evidence (両系統 JSONL log + 5 種 metric + figure 1-3 用データ) を Spec 6 spec が参照可能な path に配置済であることを confirm し提供する (deliverable 提供完了 = path 配置確認、本 spec の deliverable は review evidence 提供で終端、ドラフト v0.3 §3.1 A-2「同時に」の解釈 = A-2 期間終端時期一致 = 並走後同時宣言、session 内 simultaneous approve ではない)
2. The dual-reviewer-dogfeeding shall Spec 6 design 内容自体の策定および `design.md` approve 操作を Spec 6 spec の責務として分離する (本 spec は dual-reviewer 適用 evidence の提供のみ、Spec 6 design 内容を改変しない)
3. The dual-reviewer-dogfeeding shall A-2 終端宣言時に Phase A 全体終端 (3 spec すべての `tasks.md` approve + Spec 6 design approve は post-本 spec の Spec 6 spec 責務) と Phase B-1.0 release prep (元 A-3 統合) への移行可能性を user 判断に escalate する (移行判断は Phase B fork go 結論を前提、approve 操作は本 spec scope 外)
4. While 本 spec 進行中, the dual-reviewer-dogfeeding shall Spec 6 spec 自体の進行状態 (design 文書の生成 / 改訂 / approve) と本 spec の dual-reviewer 適用結果が独立に管理されることを保証する (本 spec ↔ Spec 6 spec は review evidence 提供 contract のみで結合、双方向の direct 改変は発生しない)
5. When A-2 終端宣言時, the dual-reviewer-dogfeeding shall Phase A 終端を遅滞なく宣言し Phase B-1.0 release prep 着手可能状態を確認する (本 spec の Phase A 内に閉じない、ドラフト v0.3 §3.2 B-1.0 規範)
