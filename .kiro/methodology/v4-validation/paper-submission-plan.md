# dual-reviewer 論文化計画

_作成: 2026-05-06 (= 56th セッション完走時点 = §3.7.6.1 完走直後)_
_target: SES 2026 (= 5/29 締切、preliminary submission) + major venue (= 8-9 月想定)_
_status: 着手前、本 plan は data-acquisition-plan v1.9 + preliminary-paper-report v0.8 の上位 roadmap_
_命名規律: 「Phase D」「Phase E」 ad-hoc 命名 撤回、既存 Phase A/B 体系 + 内容由来 label (= F/Q/P/S/R batch) に統一_

---

## 1. 完了済 status

### Phase A 内 既完了

- **A-1 prototype** (= sessions 6-17): foundation + design-review + dogfeeding 3 spec の req + design + tasks 全 phase V4 review + implementation 完走 (= 151 tests pass、rework events 0 件)
- **A-2.1** (= sessions 20-45): Spec 6 (rwiki-v2-perspective-generation) design phase 3 系統対照実験 (= treatment-single + treatment-dual + treatment=dual+judgment 各 10 round) 完走、ablation 数値 final 確定 (= single 63.0% / dual 21.7% / dual+judgment 33.3% over-correction ratio)
- **A-2.2** (= sessions 14): tasks phase ad-hoc V4 適用完走、3 spec 累計 trend 反映済
- **§3.7.6.1** (= sessions 50-56): Phase field reverse-spec 起草 + V4 review 15 round + DR-pfm C++17 clean-room re-impl 22 tasks + L1/L2 構造化完了

### 集約 deliverable 既完了

- `comparison-report.md v0.4` = A-2.1 final ablation table + scripts auto output + 5 件 caveat reconciliation
- `preliminary-paper-report.md v0.8` = 4 claims readiness + 9 spec instance evidence + V4 methodology + Limitations
- `evidence-catalog.md v0.12` = §5.x 全 sample evidence index
- `data-acquisition-plan.md v1.9` = §1-§7 + Timeline (= 8-9 月 paper draft)

### Phase A 内 残 work

- §3.7.6.2 (3D 熱伝導方程式)
- §3.7.6.3 (Arduino IoT)
- A-3.2 multi-vendor LLM cross-validation
- A-3.3 mutation testing
- A-3.4 multi-run reliability
- A-3.5 convergence judgment
- A-2.3 Spec 6 implementation = Phase B-1.x defer (= critical path 外し済)

### Phase B (= post-paper)

- B-1.0 release prep / B-1.x 拡張 = paper submission 後

---

## 2. Target

### 第一 target = SES 2026 (= preliminary submission)

- URL: https://ses.sigse.jp/2026/
- 締切: 2026-05-29 (= 23 calendar day from today 2026-05-06)
- 性質: 国内 SE 会議、査読あり、preliminary acknowledge OK
- 役割: 外部 reviewer feedback 取得 → major venue submission 前の rigor 強化材料

### 第二 target = major venue (= post-SES、8-9 月想定)

- 候補: ACM TOSEM / IEEE TSE / ICSE
- input: SES feedback + Phase A 残 work 完走 evidence

---

## 3. 論文 4 claim 充足 status

### Claim A = adversarial subagent 効果

- **充足** (= 6 spec instance × multi-phase で adversarial 独立補完 5 度目連続再現)
- evidence: V3 試験運用 + A-1 req phase 3 spec + A-2.1 全 3 系統 + §3.7.6.1
- SES paper main 主張可能

### Claim B = judgment subagent 効果

- **充足** (= 3 系統 ablation 完成、figure data 既出力)
- evidence: V3 baseline 50% → V4 4 spec 連続改善 + A-2.1 ablation (single 63.0% → dual 21.7% → dual+judgment 33.3%)
- SES paper main 主張可能

### Claim C = dual-reviewer architecture

- **充足** (= 7 spec instance + forward Adjacent Sync 30 round 全件実証)
- evidence: 6 spec instance × 2 phase + A-2.1 3 系統 + §3.7.6.1 (= C++ 言語拡張)
- SES paper main 主張可能

### Claim D = downstream rework signal (= time-deferred validity)

- **preliminary** (= 4 spec instance / 計画 6 spec instance)
- evidence:
  - A-1 全 implementation phase (= 3 spec、Python、forward-fresh): rework events 0 件
  - §3.7.6.1 re-impl phase (= 1 spec、C++、reverse-engineered): rework events 2 件
- gap:
  - **causal claim 不成立** (= no-reviewer baseline 不在、correlational のみ)
  - sample diversity 不足 (= §3.7.6.2/.3 残)
  - data quality issue (= §3.7.6.1 rework_log.jsonl format 不正、A-1 0 events が implicit)
- **SES paper では preliminary acknowledge + future work で extending plan 提示**

---

## 4. SES 2026 までに実施する work batch

### Batch F = evidence format 確定 work (= 新規、cost 2-4 calendar day)

#### 動機

§3.7.6.1 の L1 構造化で「事後 LLM ラベリング」caveat 発生 (= reviewer self-label ではなく自然言語からの subagent batch 抽出)。後続 sample でこの caveat を引きずらないよう **schema enforce + write protocol 文書化 + validation tooling** を整備。

#### 内訳

- **F-1**: schema 6 件起草 / 拡張
  - 既存 `finding.schema.json` の `failure_observation` を required 化 (= self-label enforce)
  - 新規 5 件: `l2_metric.schema.json` / `rework_event.schema.json` (= severity / discovered_phase_detail / propagation 4 field 拡張) / `spec_characteristic.schema.json` / `no_rework_record.schema.json` / `paired_comparison.schema.json`
- **F-2**: path convention 確定
  - 新設 `samples/` directory 階層 (= a1/ + a21/ + a3/ で per-spec evidence 集約)
  - 既存 `a3_batch/code_derived/phase_field/` を `samples/a3/3_7_6_1_phase_field_cpp/` に `git mv` (= history 保持)
- **F-3**: V4 protocol v0.4 への write protocol section 追加
  - V4 review round 内 = primary / adversarial / judgment subagent が finding 検出時 self-label 必須
  - round close hook で L1 + L2 atomic append
  - implementation phase = rework event 発生時 L6 entry append
- **F-4**: validation tooling 起草
  - `validate_evidence.py` = 全 evidence file の schema validation (= jsonschema lib)
  - `emit_round_close.py` = V4 round close で format-correct entry atomic emission
  - `aggregate_metrics.py` = cross-sample metric 集計
- **F-5**: 既存 §3.7.6.1 evidence の re-validate
  - L1 file = failure_observation 既付与済 → schema validation pass 想定
  - rework_log.jsonl format 不正は Q-1 で修復

### Batch Q = data quality 整備 work (= 新規、cost 0.5-1 calendar day)

#### 動機

§3.7.6.1 の rework_log.jsonl format 不正 + A-1 implementation rework 0 events implicit を修復し、Claim D primary metric の data integrity 確立。

#### 内訳

- **Q-1**: §3.7.6.1 rework_log format 修復 (= 1 line null entry → 2 entries: time_step return 1→6 / wingxa boundary fix)
- **Q-2**: A-1 implementation rework 0 events を `a1_implementation_rework_log.jsonl` 明示記録 (= 3 spec × 1 entry)
- **Q-3**: 既存 rework events を L6 拡張 schema (= F-1 で定義) で retrofit (= severity / root_cause / discovered_phase_detail / propagation 付与)

### Batch P = SES paper-input 整備 work (= 既存 A category 11 件、cost 1-2 calendar day)

#### 内訳 (= 既 TaskCreate 済 task #9-19、修正版)

- **P-1 (= ex A.6)**: cross-spec miss/diff/trigger 分布 — **scope 縮減**: §3.7.6.1 単独 characterization に re-scope (= A-1 L1 不在のため cross-spec 直接比較は future work)
- **P-2 (= A.7)**: spec_characteristic 横並び table (= 4 spec instance: foundation / design-review / dogfeeding / phase-field)
- **P-3 (= A.8)**: Claim D primary evidence preliminary 集計 — **scope 縮減**: 4 spec instance preliminary table (= A-1 0 + §3.7.6.1 2)、§3.7.6.2/.3 + Julia paired は future work
- **P-4 (= A.9)**: forced_divergence cross-spec pattern (= A-2.1 dual 14 件 + §3.7.6.1 forced_div_rate 0.21-0.31)
- **P-5 (= A.10)**: P+A 横断同型重複 §3.7.6.1 適用確認 (= L1 grep)
- **P-6 (= A.4)**: comparison-report v0.5 §14 起草 (= forward-fresh A-1 vs reverse-engineered §3.7.6.1 preliminary sub-group 比較、sample 1/3 caveat)
- **P-7 (= A.5)**: figure 1-3 + ablation figure rendering (= matplotlib で PNG 生成)
- **P-8 (= A.1)**: preliminary-paper-report v0.9 起草 (= §3.7.6.1 完走 status 反映)
- **P-9 (= A.2)**: data-acquisition-plan v2.0 起草 (= 実績 base timeline + SES schedule 反映)
- **P-10 (= A.3)**: evidence-catalog v0.13 起草 (= §5.5.6.1 + §5.6 sub-group base 確立宣言)
- **P-11 (= A.11)**: L1 caveat cross-document 同期 (= 「事後 LLM ラベリング」caveat を spec_characteristic + paper Limitations + Threats to Validity に展開)

### Batch S = SES paper 起草 work (= 新規、cost 7 calendar day = Week 2)

#### 内訳

- **S-1**: outline + abstract + LaTeX setup
- **S-2**: §1 はじめに (= problem + 4 claims + 貢献)
- **S-3**: §2 背景 (= V3 → V4 evolution)
- **S-4**: §3 V4 protocol (= 3 subagent + 5-field schema + 5 条件判定)
- **S-5**: §4 評価 setup (= 7 spec instance + V3 baseline + 3 系統対照実験)
- **S-6**: §5 結果 (= claim A/B/C/D 別 + figure 1-3 + ablation table)
- **S-7**: §6 議論 (= layer 機能分離 hypothesis + convergent triangulation)
- **S-8**: §7 Limitations (= reverse-engineering bias 5 source + paired n=0 + sample size + LLM-on-LLM bias + L1 post-hoc labeling caveat)
- **S-9**: §8 関連研究 + §9 おわりに

### Batch R = revision + format + submission work (= cost 5 calendar day = Week 3-Final)

#### 内訳

- **R-1**: self-review (= claim 検証 + figure 整合 + reference 完全性)
- **R-2**: prose 推敲 (= 日本語 academic style 統一)
- **R-3**: LaTeX format 微調整 (= page limit / table / figure caption)
- **R-4** (= optional rigor 補強): §3.7.6.1' Julia WITH + §3.7.6.1'' Julia WITHOUT paired control (= Week 3 buffer 余裕次第、cost 1.5-2 day)
- **R-5**: final review + format check
- **R-6**: submission prep + submission

---

## 5. SES schedule (= 5/6 - 5/29、23 calendar day)

### Week 1 (= 5/6 - 5/12、7 day) — format 整備 + data quality + paper-input + outline

- **5/6 (今日)**: SES 2026 公式 site 確認 (= page limit / template / submission process) + Batch F-1 schema 起草着手
- **5/7-5/8**: F-1 + F-2 完了 (= schema 6 件 + path convention)
- **5/9**: F-3 + F-4 (= write protocol + validation tooling) + Q batch 完了 (= rework_log 修復 + A-1 明示 + L6 retrofit)
- **5/10-5/11**: F-5 + P-1〜P-7 (= §3.7.6.1 re-validate + figure rendering + spec_characteristic table + comparison-report v0.5 §14)
- **5/12**: P-8〜P-11 + S-1 (= 3 document 改版 + caveat 同期 + paper outline + abstract)

### Week 2 (= 5/13 - 5/19、7 day) — paper main body draft

- **5/13-5/14**: S-2 + S-3 + S-4 (= §1 はじめに + §2 背景 + §3 V4 protocol)
- **5/15-5/17**: S-5 + S-6 (= §4 評価 setup + §5 結果)
- **5/18-5/19**: S-7 + S-8 + S-9 (= §6 議論 + §7 Limitations + §8 関連研究 + §9 おわりに)

### Week 3 (= 5/20 - 5/26、7 day) — revision + optional rigor 補強

- **5/20-5/22**: R-1 + R-2 (= self-review + prose 推敲)
- **5/23-5/24**: R-4 (= optional Julia paired control 1.5-2 day)
  - 余裕あれば §3.7.6.1' + §3.7.6.1'' 実施 → §5.4 Claim D を correlational → causal direction 1 paired に格上げ
  - 余裕なければ skip = future work entry に残す
- **5/25-5/26**: R-3 + R-5 (= LaTeX format 微調整 + final review)

### Final (= 5/27 - 5/29、3 day) — submission

- **5/27-5/28**: R-6 prep (= pdf 生成 + 著者情報 + meta data + supplementary material)
- **5/29**: submission

---

## 6. post-SES schedule (= 5/30 - 8 月)

### Phase A 残 work (= 5/30 - 6/30、~1 calendar 月)

- **§3.7.6.2** 3D 熱伝導 (= cost 2.5-4 calendar day、format native で取得 = caveat 排除)
- **§3.7.6.3** Arduino IoT (= cost 1.5-2.5 calendar day、format native)
- Julia paired control (= week 3 で実施しなかった場合、cost 1.5-2 calendar day)
- A-3.2 multi-vendor LLM cross-validation (= cost 3-6h)
- A-3.4 multi-run reliability (= cost 3-5h)
- A-3.3 mutation testing (= cost 7-10h)
- A-3.5 convergence judgment (= 6 indicators 統合判定)
- A-1 spec L1 per-finding 遡及構造化 (= subagent batch、format native re-validate)

### SES feedback 取得 (= 7-8 月想定)

- reviewer 批判 = 期待される pattern (= LLM-on-LLM bias / sample size / 言語 generalization / Claim D causal 不成立)
- mitigation 戦略 = 既計画 work の優先度判定 + 後出し evidence

### major venue paper draft (= 8-9 月)

- input = SES feedback + Phase A 残 work 完走 evidence
- comparison-report final 集約 (= §3.7.6.2/.3 + Julia paired + A-3 全完走後)
- evidence-catalog final / preliminary-paper-report final
- venue 候補 (= ACM TOSEM / IEEE TSE / ICSE) 確定 + format 準備

### Phase A 終端 redefine

- 旧 v1.6: "A-3 + §3.7.6 完走 = Phase A 終端"
- 新 v2.0: "**6-7 月 = Phase A 終端**" (= 実績 base 推定、SES submission 後 1 月)

---

## 7. 着手順序 (= 依存関係考慮)

### 即時着手 (= 5/6 today)

- SES 2026 公式 site 確認 (= page limit / template / submission process / 共同著者 制約)
- Batch F-1 schema 起草

### 順序根拠

- F batch (= format 確定) を **最先行**: 後続 work が schema enforce で取得されるため、後段の caveat 発生防止
- Q batch を F batch 直後: F-1 で定義した拡張 schema を Q-3 retrofit で適用
- P batch を F + Q 直後: F-2 で確定した path で P-2 spec_characteristic 横並び実施
- S batch を P 完了後: P-8〜P-11 の document 改版が S batch input
- R-4 (= Julia paired) を Week 3 内 placement: format native で取得 = caveat 排除、SES paper §5.4 Claim D 格上げ
- post-SES = SES feedback 取得 trigger

---

## 8. cost 累計 + buffer

### Week 1 (= 5/6 - 5/12)

- F batch: 2-4 calendar day
- Q batch: 0.5-1 calendar day
- P batch: 1-2 calendar day
- S-1 outline: 0.5 calendar day
- 合計 = 4-7.5 calendar day → 7 day budget で fit (= F + Q parallel + P 並走)

### Week 2 (= 5/13 - 5/19)

- S-2〜S-9 paper draft: 7 calendar day
- 合計 = 7 day budget で fit

### Week 3 (= 5/20 - 5/26)

- R-1 + R-2 + R-3 + R-5: 5 calendar day
- R-4 optional: 1.5-2 calendar day
- 合計 = 5-7 day budget で fit (= R-4 採否次第)

### Final (= 5/27 - 5/29)

- R-6 submission: 1-2 day + buffer
- 合計 = 3 day budget で fit

### Total

- 5/6 - 5/29 = 23 calendar day
- 推奨 plan = 21-22 day 想定 + 1-2 day buffer
- conservative pace なら R-4 skip + 短縮 1 day buffer

---

## 9. caveat / risk

### 短期 risk (= SES 23 day budget)

- SES 2026 page limit / template が現時点不明 → 5/6 中に確認必須
- LaTeX 環境構築 + template 適合 = 0.5-1 day buffer 必要
- 日本語 academic prose iteration = LLM 校正でも 2-3 cycle 必要
- F batch schema migration で既存 §3.7.6.1 file path 変更 → comparison-report / preliminary-paper-report / evidence-catalog の path 引用 update 漏れ risk

### 中期 risk (= post-SES Phase A 残)

- §3.7.6.2 言語選択 (= Julia or C++) で sub-group 厚み変動
- bias mitigation 物理隔離 verification (= §3.7.6.1' / .1'' で初実施、手順未確立)
- A-1 L1 遡及構造化 (= 既存 dual-reviewer-log-1〜-7 source、subagent batch で post-hoc labeling = §3.7.6.1 caveat と同質、format native ではない)

### 長期 risk (= major venue paper draft)

- venue 確定遅延で 8-9 月 timeline 圧迫
- SES feedback 受領タイミング (= 6 月末 - 7 月想定、想定外遅延あれば 8-9 月 timeline 圧縮)

---

## 10. user 判断事項 (= 着手前確認)

### 確認 1 = SES 2026 公式情報

- page limit + template format (= LaTeX / Word)
- submission process (= EasyChair / email / web form)
- 共同著者 制約 (= 単著 OK か)
- 日本語 paper 必須か (= 想定 yes)

### 確認 2 = Batch F path migration 範囲

- 既存 `a3_batch/code_derived/phase_field/` 配下 file を `samples/a3/3_7_6_1_phase_field_cpp/` に移行するか
- もしくは新規 sample (= §3.7.6.2/.3 + Julia paired) のみ新 path で取得し、既存 §3.7.6.1 は path 維持か
- 推奨 = 移行 (= path convention 統一、reference 一括 update で integrity)

### 確認 3 = SES paper scope

- Claim A/B/C main + Claim D preliminary 4 instance (= 推奨)
- vs Week 3 R-4 で Julia paired 追加 → Claim D 5 instance + 1 paired direction (= rigor 強化)
- 推奨 = R-4 を Week 3 buffer に置き、執筆順調なら実施 / 遅延なら skip

### 確認 4 = 命名規律

- 「Phase D」「Phase E」 ad-hoc 命名 撤回承認
- F batch / Q batch / P batch / S batch / R batch 内容由来 label 採用承認
- 推奨 = 採用、data-acquisition-plan v2.0 起草時に正式反映

### 確認 5 = Phase A 終端 redefine

- 旧 v1.6: "A-3 + §3.7.6 完走 = Phase A 終端 = 8-9 月 paper draft 着手"
- 新 v2.0: "6-7 月 = Phase A 終端 = SES submission 後 1 月で完走想定 + 実績 base"
- 推奨 = 採用

---

## 11. 推奨 path (= 直近 着手)

1. **5/6 中**: SES 2026 公式 site 確認 (= 確認 1) + Batch F-1 schema 起草着手
2. **5/7**: F-1 + F-2 + Q-1 完了
3. **5/8**: F-3 + F-4 + Q-2 + Q-3 完了
4. **5/9**: F-5 + P-1〜P-3 着手
5. 以降は Week 1-3 + Final schedule 通り

承認なら以下 next action:

- TaskList 整理 (= 既存 A category 12 件 → P batch 11 件 に rename + F batch 5 件 + Q batch 3 件 + S batch 9 件 + R batch 6 件 を追加)
- SES 2026 公式 site fetch
- Batch F-1 schema 起草着手

---

## 12. 関連 reference

- `data-acquisition-plan.md` v1.9 (= Phase A scope + Timeline、本 plan 起草の上位 source、本 plan 反映後 v2.0 へ改版予定)
- `comparison-report.md` v0.4 (= A-2.1 final ablation + scripts auto + caveat reconciliation)
- `preliminary-paper-report.md` v0.8 (= 4 claims readiness + 9 spec instance evidence、SES paper input)
- `evidence-catalog.md` v0.12 (= §5.x 全 sample evidence index)
- `v4-protocol.md` (= V4 protocol v0.4、本 plan F-3 で改版済)
- `sample_3_7_6_1/` (= §3.7.6.1 evidence directory、Q-1 で rework_log 修復対象)
- `sample_3_7_6_1_julia_addition_analysis.md` (= 49th 末作成、§3.7.6.1' Julia 追加案分析、本 plan R-4 で活用)
- `a3_batch/code_derived/phase_field/` (= §3.7.6.1 evidence files、F-2 で path 移行対象)

---

## 13. 変更履歴

- **v1.0** (2026-05-06 56th セッション直後): 本 file 初版 = 論文化計画 清書版。SES 2026 (5/29 締切) を第一 target、major venue (8-9 月) を第二 target として全 work batch (= F/Q/P/S/R) と schedule (= Week 1-3 + Final + post-SES) を統合整理。前 turn までの「Phase D」「Phase E」 ad-hoc 命名を撤回、既存 Phase A/B 体系 + 内容由来 label に統一。data-acquisition-plan v1.9 + preliminary-paper-report v0.8 の上位 roadmap として位置付け、v2.0 改版時に本 plan 内容を data-acquisition-plan に反映予定。本 v1.0 自体は methodology meta-document (= Level 6 記録対象外)。
