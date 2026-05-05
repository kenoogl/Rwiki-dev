# §3.7.6.1' Julia 追加再実装案 — 分析記録

_作成: 2026-05-05 49th セッション_
_status: **defer = (c) 選択 = C++ §3.7.6.1 完走後に追加判断**、本 file は議論内容と決定の記録_

## 1. 背景

§3.7.6.1 (= Phase field reverse-engineered C++ 1 sample) の plan 確定後 (= 49th Step (3) 着手予定)、別 1 件として **同じ reverse spec から Julia でも再実装する案**を検討した。本 file はその議論内容とメリット 5 / デメリット 3 / timing 3 / 決定 (= (c) C++ 完走後判断 defer) の記録。後日 C++ 完走時点で再評価し、Julia 追加実施 / non-実施を判断する。

## 2. 既存 artifact 配置 (= 検討前提)

- `/Users/Daily/Development/phasefield/pfm1/` = original C++ code (= forward 実装、計算結果 BMP 多数)
- `/Users/Daily/Development/phasefield/PhaseFieldSim/` = **forward Julia 移植** (= 既に完了、Gemini 経由 4/21、Project.toml + src 4 file + Makie ext)
- `/Users/Daily/Development/DR-pfm/spec_seed/DEVELOPMENT_SPEC.md` = reverse-engineered 仕様書 (22 章、9007 byte、clean-room 前提明記)
- `/Users/Daily/Development/DR-pfm/spec_seed/wingxa.h` = 描画 API ヘッダ (9 関数 prototype)

§3.7.6.1 当初 plan = C++ reverse 再実装 (= clean-room、別 git、local only、DR-pfm 直下)、PhaseFieldSim Julia 版は **完全 ignore**。

## 3. 検討した追加案 = Julia reverse 再実装

§3.7.6.1 完了後に、**同じ reverse spec (= DR-pfm の Kiro 化版)** から Julia でも clean-room 再実装する案。これにより:
- C++ reverse re-impl + Julia reverse re-impl の **2 sample 体制** = 1 spec source × 2 言語
- forward direction (= PhaseFieldSim) との同言語比較が成立 (= post-hoc reference)

## 4. メリット 5 件

### 4.1 言語 generalization 防御の強化 (= reviewer 批判 9 への defense)

C++ 単独完走では「C++ domain only」批判が残る。Julia 追加で「同じ仕様が複数言語で再現される」evidence 取得 = 批判 9 (= 言語 generalization) 防御強化。

### 4.2 仕様の言語非依存性 evidence

reverse spec が 1 言語のみで再現可能か vs 複数言語で再現可能かは、spec の **抽象度・完備度** に直接関わる。Julia でも同じ design choice / acceptance criteria を満たせれば、**spec が真に言語実装に依存しない仕様として機能している**証拠 = Claim B (judgment 効果) に間接補強。

### 4.3 forward PhaseFieldSim を post-hoc 比較 reference として活用可能 (= 本構造特有の利点)

PhaseFieldSim (= forward Julia 移植) と reverse Julia 再実装は **同言語の clean-room 比較**が可能。BMP 出力の bit-level 比較で「forward vs reverse の equivalence」が直接測定可能 = forward-reverse asymmetry の definitive measurement 成立。**C++ 単独では成立しない分析**で、4 way 比較 (= original C++ / reverse C++ / forward Julia / reverse Julia) の強い構図が可能。

### 4.4 cost-benefit が良い

- §3.7.6.1 C++ = 6-10h core + 0-3h Level 6 観測
- Julia 追加 = **同じ reverse spec 再利用 = spec 化作業 0、V4 review も同 spec への review なので skip 検討可**、純 re-implementation cost のみで 6-10h 程度
- 合計 = **12-20h で 2 言語 cover** (= §3.7.6 全 3 sample 20-41h batch よりまだ安い)

### 4.5 reverse engineering bias のうち「言語固有 bias」が分離可能

reverse engineering bias 5 source のうち「実装者の言語固有 idiom 反映」は 1 言語実装のみだと分離不能。2 言語で書き分けると「**spec 自体の bias**」と「**言語固有 bias**」を切り分け可能 = spec quality 評価の rigor が一段上がる。

## 5. デメリット 3 件

### 5.1 Julia 再実装が PhaseFieldSim に汚染される risk

Julia 言語で書く時点で user / Claude が **PhaseFieldSim の存在を知っている**ため、無意識に PhaseFieldSim の design choice を真似してしまう bias。C++ reverse のときの bias 排除より厳しい mitigation 必要:
- PhaseFieldSim repo を作業中は完全 touch 禁止
- Claude session 中も PhaseFieldSim を Read しない規律徹底
- 物理隔離 (= phasefield repo を別 partition or mv で隔離) も検討

### 5.2 結果の解釈が複雑化

「同じ reverse spec から 2 言語で再現された」事実が **spec quality / language generalization / V4 review effectiveness** のどれを強く evidence として裏付けるかは慎重な discussion 必要。paper narrative 構造が複雑化し、claim 書き分けに care 必要。

### 5.3 Level 6 events の言語間比較が解釈困難

C++ reverse re-impl と Julia reverse re-impl の Level 6 events 数差の原因切り分け (= 言語固有 difficulty / spec ambiguity / 実装者 bias) が困難。sub_group_key (= phase_field_reverse_cpp / phase_field_reverse_julia) で分離記録すれば post-hoc 分析可能だが、論文では caveats 明記必要。

## 6. timing 選択肢 3 つ

- (a) **並列実施** = C++ + Julia 同時 → **不採用** (= bias 排除難、Claude context 上 2 言語切替で言語固有 idiom 漏れ risk)
- (b) **順次実施 (事前 plan)** = C++ 完走 → Julia 着手を事前に plan 化 → bias 排除 clean、Level 6 観測言語別分離、ただし paper draft 着手は両方完走後 (+6-10h 遅延)
- (c) **C++ 完走後に追加判断** = §3.7.6.1' として後段 decision → C++ 結果を見てから判断、paper draft 着手は (γ) 当初通り C++ 単独完走時点

## 7. 決定 = (c) C++ 完走後に追加判断

### 7.1 (c) 採用理由

- C++ 再実装が予想より時間かかった場合、Julia 追加は不可能 → 早期判定可能
- C++ Level 6 events 数を見てから「Julia でも観測する価値があるか」判定可能
- paper draft 着手 timing は当初推奨 (γ) のまま維持 = 8 月 timeline 厳守
- Julia 追加 evidence は paper revision phase で「added evidence」として後出し positioning も可能 = 査読対応で強化材料になる

### 7.2 再評価 trigger

C++ §3.7.6.1 完走時点で以下を確認し、Julia 追加 (= §3.7.6.1') 実施 / non-実施を判断:

- C++ Level 6 events 数 (= reverse-engineering difficulty 観測、events 多 = spec ambiguity 検出 evidence、Julia 追加で再現性検証 value 高)
- C++ 完走 wall-clock 実測 (= Julia 追加 cost predictability、当初見積 6-10h からの変動把握)
- paper venue 確定状況 (= conference / journal の rigor 要求度、批判 9 防御重視度)
- paper draft timeline 確定状況 (= 8 月 deadline 厳守か弾力か)
- reviewer 批判 9 (言語 generalization) を最重要視するか否か

### 7.3 採用時の事前確認事項 (= 再評価 timing で議論)

- Julia 再実装 dir = DR-pfm 直下 vs 別 dir? (= C++ 実装と物理分離が望ましい)
- bias mitigation 規律具体化 = PhaseFieldSim 隔離方法 (= mv / git remote remove / 別 user account 等)
- V4 review skip 可否 = 同 spec への review なのでこ scope を skip するか、Julia 言語固有 angle で再実施するか
- sub_group_key naming = phase_field_reverse_cpp / phase_field_reverse_julia 確定

## 8. 関連 reference

- `.kiro/methodology/v4-validation/data-acquisition-plan.md` §3.7.6.1 (= Phase field 再実装 plan、本案 §3.7.6.1' は data-acquisition-plan に未反映、後日 update 候補)
- `.kiro/methodology/v4-validation/preliminary-paper-report.md` §7.4 (= reviewer 批判 9 = 言語 generalization)
- `.kiro/methodology/v4-validation/evidence-catalog.md` §5.2 (= Claim D primary evidence + reverse-engineering bias 5 source)
- `/Users/Daily/Development/phasefield/PhaseFieldSim/` (= 比較 reference 候補、forward Julia 移植、本案採用時は touch 禁止)
- `/Users/Daily/Development/DR-pfm/spec_seed/DEVELOPMENT_SPEC.md` (= reverse spec seed、22 章 9007 byte)
- 49th セッション会話記録 (= 本 file 作成元議論)

## 9. 変更履歴

- **v0.1** (2026-05-05 49th セッション): 本 file 初版 = §3.7.6.1' Julia 追加案分析記録 = メリット 5 / デメリット 3 / timing 3 / (c) 採用決定 / 再評価 trigger 5 件 / 採用時事前確認 4 件。本 file は methodology meta-document (= Level 6 記録対象外)、C++ §3.7.6.1 完走時点で再評価。
