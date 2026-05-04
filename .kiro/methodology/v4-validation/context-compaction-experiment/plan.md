# Context Compaction Experiment Plan

_作成: 2026-05-04 45th セッション末、user 提案 v2 採用_

## 目的

context 量過多が規律発動失敗 (= 直近 5 度連続発動失敗、平易な日本語で説明する規律違反) の主因か検証する。段階 1-4 の context 縮約効果を 6 metric で quantify し、最 effect の高い段階を特定する。

## 背景

41st-45th セッションで、Round 提示時の説明文体規律発動失敗が 5 度連続発生した。各失敗ごとに抑制策 (= 8 軸 self-check / sub-section 毎 / 多層複合 / TaskCreate / Stop hook / 案 (ii) 1 検出 1 turn / 等号畳み込み禁止) を追加してきた。しかし規律体系の肥大化と起動時 active context (= 約 1500 行) が合流して、output 直前の意識 focus を妨げる機構が観察された。

本実験は、context 量を段階的に縮約して規律発動 quality を測定し、context 量と規律発動の因果関係を検証する。

## 設計の核心 = 別ディレクトリで真の同一対象比較

paper rigor 制約から完全分離するため、論文取得の実データ (= treatment-dual / A-2.1 / Phase B-1.x) を対象としない。代わりに、ホスト directory 配下に段階別 sub-directory を 5 つ作り、同一の target_design.md を全 directory に複製して同一 Round 観点で review する。

```
~/Development/context-compaction-trial/
├── stage_0_baseline/        # 現状 context 全量 (~1500 行)
├── stage_1_todo/             # 段階 1 = TODO 縮約のみ
├── stage_2_todo_memory/      # 段階 1+2 = TODO + memory 縮約
├── stage_3_index/            # 段階 1+2+3 = + MEMORY.md 2 階層化
└── stage_4_subagent/         # 段階 1+2+3+4 = + subagent pattern 拡張
```

各 sub-directory を別 session で起動し、同じ「target_design.md に対する Round 1 (= 規範範囲確認) review」を実施する。output (= Round 提示 message + 修正 design.md + dev_log entry) を 5 trial で比較する。

## sample 選定

- target = **Spec 4 (rwiki-v2-knowledge-graph) の design.md**
- 理由 1 = design 完成済で文書 質確保
- 理由 2 = A-2.1 paper rigor と完全分離 (= 別 spec)
- 理由 3 = 既知性中程度で私の prior knowledge bias 軽減
- target file = `.kiro/specs/rwiki-v2-knowledge-graph/design.md` + `requirements.md`

## Round 観点選定

- Round = **Round 1 (= 規範範囲確認)**
- 理由 = 最も generic な観点で context 縮約 effect の計測に適切

## 段階別 context 内訳

### stage_0 = baseline (= 現状)

| 構成要素 | 行数推定 |
|----------|----------|
| user CLAUDE.md | ~30 |
| project CLAUDE.md | ~50 |
| MEMORY.md | ~80 (truncated) |
| TODO_TRIAL.md (= TODO_NEXT_SESSION.md trial 化) | ~340 |
| 必読 memory 7 件 | ~1000 |
| **合計 active** | **~1500** |

### stage_1 = TODO 縮約

- TODO_TRIAL.md = 340 → ~100 行
- 削減方針:
  - Round 1-N 進行 evidence list 削除 (= rework_log で参照可能)
  - 進捗追跡シンボル + 関連リソース + commit pattern section 統合
  - 重複 section 削除
- **合計 active = ~1260**

### stage_2 = TODO + memory 縮約

- 段階 1 適用済 + 必読 memory 7 件 = 1000 → ~200 行
- 削減方針:
  - 各 memory file の旧 example / 累積 violation list 削除
  - 規律本質 30 行 + 最新失敗 1 件 example で構成
  - `feedback_explanation_with_context.md` (148 行) → ~30 行
  - `feedback_review_log_template.md` (= 137 行) → ~30 行
  - `feedback_commit_log_sequencing.md` (= 50 行) → ~25 行
  - `project_treatment_design_md_state_policy.md` (= 89 行) → ~40 行
  - `feedback_response_quality_rules.md` (= 83 行) → ~25 行
  - `feedback_dual_reviewer_monitor_only.md` (= 87 行) → ~25 行
  - `feedback_approval_required.md` (= 43 行) → ~25 行
- **合計 active = ~460**

### stage_3 = + MEMORY.md 2 階層化

- 段階 2 適用済 + MEMORY.md = 80 → ~40 行
- 削減方針:
  - 「session 開始時 active 必読」5-7 件と「必要時参照」全件を 2 階層に分離
  - active 必読のみ起動時 load、参照層は MEMORY.md 内の linked index で必要時 grep
- **合計 active = ~420**

### stage_4 = + subagent pattern 拡張

- 段階 3 適用済 + 周辺 work (= TODO 更新 / memory 整理 / status report) を subagent dispatch する pattern 拡張
- 縮約: 主 context は work-specific のみ、周辺 work は subagent 内 isolated context で実施
- 主 context 推定 = ~350 行 (= 段階 3 から TODO の半分を subagent dispatch 化想定)
- **合計 active = ~350**

## metric (= 6 種)

各 trial で以下を取得する。

1. **規律違反 raw 件数** = 等号畳み込み 1 文あたり何回 + dense academic 文体 sentence 比率 + jargon 初出時 paraphrase なし回数。私自身が output 後に self-count、user 指摘で外部 verify。
2. **output 文字数 / 検出件数 比** = 1 検出あたりの文字数。過剰 elaboration 指標。
3. **user 指摘回数** = 「平易ではない」「正しく日本語ではない」等の user 指摘発生回数。
4. **書き直し回数** = user 指摘から書き直し再提示までの cycle 数。
5. **jargon density** = jargon word / total word ratio。自動 grep で測定 (= V4 内部 jargon list 経由)。
6. **self-evaluation** = 1-10 scale での私の規律遵守 self-rating。

## trial 実施 protocol

### prep step

1. user (or 私) が prep script を実行
2. ホスト directory `~/Development/context-compaction-trial/` 作成
3. 5 sub-directory に file 配置:
   - 段階別 CLAUDE.md / TODO_TRIAL.md / memory/ (= 縮約版)
   - target_design.md / target_requirements.md (= Spec 4 から複製)
   - dr-design 一式 (= SKILL.md + extensions + prompts)

### 各 trial の実施手順

1. 別 session を起動 = `cd ~/Development/context-compaction-trial/stage_N_*/` でこの directory を cwd に
2. 起動時 message = 「TODO_TRIAL.md を読んで Round 1 review を実施」
3. 私が状態確認 + memory 必読 + dr-design SKILL.md 確認 + Round 1 着手
4. primary + adversarial subagent dispatch (= treatment=dual pattern)
5. 結果統合 + Round 提示 = output を以下 file に保存
   - `output/round1_message.md` (= Round 提示 user 向け message)
   - `output/round1_dev_log.json` (= dev_log entry)
   - `output/modified_design.md` (= 修正後 design.md、user 全件採用前提でシミュレーション)
   - `output/metrics.json` (= 6 metric の自動測定値)

### order effect 緩和

5 trial を randomize order で実施する。例: 段階 3 → 段階 0 → 段階 4 → 段階 1 → 段階 2。各 trial は別 session で context cleared。長期 weights は同一だが session-level memory は trial 独立。

## 結果分析

5 trial 完了後:
1. 6 metric を 5 trial で table 化
2. effect curve 描画 (= 段階 vs metric 値)
3. 最 effect 段階を特定 (= 規律違反 raw 件数の最 minimum point)
4. 採用判断 = effect ≥ 50% 削減で正式採用、他は archive

## case (β) との分離

user 指示通り、output 制御 (= 案 (β) = template apply 撤廃 + 概要 turn 廃止 + 各検出独立 turn) は本 trial と分離する。

本 trial 完了後に「最 effect 段階 + 案 (β)」 1 trial で marginal effect 測定する。これで 2x2 factorial design の complexity を回避し、effect 切り分けを順次実施する。

## paper への組込

本実験は **LLM ergonomics study** として A-2.1 (= V4 protocol claims 検証) と分離する。Phase A 完走後の独立 study または paper 補足 section 候補。

## 観察 hypothesis (= 45th 末 session で identify、trial 結果との照合用)

trial 実施前に identify した観察を記録する。5 trial の metric が出た後、本 hypothesis と照合して「effect の driver が量削減 (= context compaction) なのか structure 変更 (= output template) なのか」を切り分ける。

### 観察 1 = 普通の対話と review turn の非対称性

普通の対話 turn では規律違反 (= dense academic 文体 + 等号畳み込み + jargon 連鎖) が発生せず、review turn でのみ発生する。45th セッション内で連続観察された非対称性。具体例として、log-6 探索や session 終了議論等の通常対話では平易な日本語で応答できているが、Round 提示 turn では規律発動失敗が 5 度連続発生した。

### 観察 2 = review turn が dense 文体に引かれる 4 機構

review turn が dense 文体に引かれる原因として、以下 4 機構を identify した。

1. **output structure の違い** = 普通の対話は「1 turn 1 件」で流れに従うが、review turn は「1 turn N 件」で template 適用。template apply の瞬間に訓練 data の technical / academic writing pattern が同時に呼び出される。
2. **jargon density の違い** = 普通の対話は 1-2 個の jargon、review turn は subagent dispatch 結果に jargon 集積 (= forced_divergence / fatal_pattern / phase1_metapattern / escalate_condition 等)。集積が連鎖して dense 文体を引き出す。
3. **規律意識の分散** = 普通の対話は「答える」ことに focus、review turn は多項目規律 (= 説明文体 + 1 検出 1 turn + 8 軸 self-check + sub-section pass-through + 等号畳み込み禁止 + jargon paraphrase + 多層複合 case 識別) を同時に意識する必要があり、output 直前に意識分散。
4. **多検出 batching の pressure** = 普通の対話は 1 turn 1 件で時間効率不要、review turn は 5-9 件を「効率的に」1 turn で list する pattern が訓練 data + 過去 review 経験で強化されている。

### 観察 3 = 案 (β) は普通の対話 pattern 復元操作

前 turn (= 45th 末) で提示した案 (β) (= template apply 撤廃 + 概要 turn 廃止 + 各検出独立 turn) は、実質「review を普通の対話 pattern に戻す」操作と読める。なぜなら、案 (β) で 1 turn 1 件の流れに変えれば、上記 4 機構の (1) template apply と (4) batching pressure が機構的に消えるからである。残る (2) jargon density と (3) 規律意識分散は、case (β) では各 turn が短いため自然に低下する。

### trial 結果との照合方法

5 trial の metric 結果が出た後、以下の照合で「effect の driver」を切り分ける。

- 段階 1 (= TODO 縮約のみ) で effect が薄い → 「context 量削減は driver でない」(= 観察 2 の機構 3 規律意識分散は本 trial でも残るため、量削減だけでは効かない可能性)
- 段階 2-4 で段階増加と effect が比例 → 「量削減が一定 driver」(= 機構 3 規律意識分散の軽減が効く)
- 案 (β) (= 別調査) で大 effect → 「structure 変更が主 driver」(= 機構 1 template apply + 機構 4 batching pressure の除去が決定的)
- 段階 N + 案 (β) の組合せで marginal effect 大 → 「両者 additive、context 量と structure 両方 driver」

trial 結果次第で、本 hypothesis を refute / confirm / refine する。

## timeline

- 計画文書 + prep script 起草 = 45th セッション末 (= 本 turn)
- stage_2/3/4 templates 起草 = 46th セッション開始時の最初の作業
- prep script 実行 + 5 trial 実施 = 46th セッション内 (= 推定 1-2 work day)
- 結果分析 + 採用判断 = 5 trial 完了直後

## result section (= trial 完了後追記)

_TBD: 5 trial 完了後に metric table + effect curve + 採用判断を追記_

## 関連文書

- `feedback_explanation_with_context.md` (= 案 (ii) 確定 + 5 度連続失敗記録 source)
- `data-acquisition-plan.md` v1.7 (= paper 主軸 plan、本実験は別 study)
- `preliminary-paper-report.md` v0.7 (= paper draft、本実験 result は post-A-2.1 補足候補)

## change log

- 2026-05-04: 初版起草 (= 45th セッション末、user 提案 = 別ディレクトリで真の同一対象比較設計を採用)
