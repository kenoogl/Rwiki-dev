---
name: SSoT 構造的決定明示性 check 規律 (30th 末確定、A-2.1 design.md state policy 盲点契機)
description: 重要な構造的決定 (treatment 切替時 input state / phase 移行時 prerequisite / cross-spec dependency / branch 戦略等) を運用前に SSoT 文書群に明示記述があるか preflight grep。不在時は LLM 単独採択せず user に質問。
type: feedback
originSessionId: b59c8258-2bcb-4361-84b2-c5a7094358e6
---
重要な構造的決定を運用する前に、SSoT 文書群 (= data-acquisition-plan / SKILL.md / steering / requirements / design / tasks 等) に該当決定が明示記述されているか preflight grep する。明示記述が不在の場合、LLM 単独で暗黙 default を採択せず、user に質問して方針確定する。確定後は SSoT 文書群への反映を必須とする。

**Why:** 30th セッション開始時に user 指摘「single の Round 1 を開始するとき、元になる design.md はどうやって準備するか」を契機に、A-2.1 30 review session の input design.md state policy が SSoT 文書群 (= data-acquisition-plan / dr-design SKILL.md / evidence-catalog / preliminary-paper-report) に明示記述されていない盲点を identified。29th 末まで第 1 系統 (= main、`treatment=dual+judgment`) は pristine state `285e762` から累積修正で `f6bac54` に到達したが、第 2/3 系統の input state (= pristine か accumulated か) は plan に未明示。LLM 単独で「post-Round 10 累積 state を起点」を暗黙 default に進めると、prior treatment 修正と current treatment 単独 effect が交絡 = paper rigor 致命的弱体化。user 質問で確定 = pristine state 起点 + 各 treatment 独立 branch 戦略を SSoT 4 文書 + memory に反映。

**How to apply:**

### preflight grep 手順 (3 step、重要構造的決定運用前に必ず実行)

1. **trigger 識別**: 以下のいずれかに該当する場面を構造的決定運用と判定
   - treatment / mode / 系統切替時の input state / 起点 / state 維持規律
   - phase 移行 (= req → design → tasks → impl) 時の prerequisite / approve criteria / handoff 規律
   - cross-spec dependency (= 先行 spec 改版が後続 spec に与える影響、Adjacent Sync direction 等)
   - branch / worktree / archive 戦略 (= 独立性確保 / merge 規律 / cleanup policy)
   - rework / Level 6 / metric 記録の sub-group key / file 分離規律
   - schema / contract / interface 改版時の互換性規律
2. **SSoT 文書群 grep**: 該当決定の keyword (= treatment / state / pristine / branch / accumulated 等) を SSoT 文書群で grep 確認
   - data-acquisition-plan / 関連 SKILL.md / steering / requirements / design / tasks / 関連 memory
   - 明示記述あり = そのまま運用、明示記述なし = 次 step へ
3. **user 質問 + 反映**: 不在時は LLM 単独採択せず user に**選択肢提示して質問**
   - dominated 選択肢を提示しない (= `feedback_dominant_dominated_options.md` 整合)
   - 確定後は SSoT 文書群 (= 主に上流文書) + 関連文書 + memory に整合連鎖反映必須
   - 反映完了 commit 後に当該決定の運用着手 (= 反映前に運用着手しない)

### 運用例 (30th 末事例)

- 30th 開始時、treatment=single Round 1 着手前に「元になる design.md state は?」が SSoT 不在
- LLM 単独で「post-Round 10 累積 state」を暗黙 default に進めず、user 質問
- pristine state 起点 + 各 treatment 独立 branch 戦略確定
- data-acquisition-plan v1.7 §3.6 B4 + §4 A-2.1 / evidence-catalog v0.10 / preliminary-paper-report v0.6 / dr-design SKILL.md / memory `project_treatment_design_md_state_policy.md` に整合連鎖反映
- 反映完了 commit `d5139f3` 後に sub-step 4.10 着手準備完了

### 観察された失敗 pattern (= 30th 初頭観察、再発防止用)

- **既存文書 jargon 拾い pattern**: SSoT 文書群から既存記述された jargon (= treatment 切替の Step A/B/C/D skip 構造) を拾うが、**未明示の構造的決定** (= input state policy) を能動的に identify しない
- **暗黙 default 採択 bias**: 構造的決定が SSoT 不在時、LLM は典型 design pattern (= main 単純継承) を default 採択しやすい、paper rigor 観点で fatal な選択も confounding 排除観点なしに進む risk
- **user 質問起点 identification dependency**: 構造的決定盲点は user の自然な質問 (= 「どうやって準備するか」) で初めて identified、self-identification rate が低い
- **多文書 SSoT 構造的整合 fragility**: SSoT が複数文書に分散 (= plan / SKILL.md / catalog / paper report) する場合、構造的決定が一部文書のみ記述 + 他文書は暗黙前提 = 整合性 gap が発生しやすい

### future session 適用場面

- A-2.1 第 3 系統 (`treatment=dual`) 着手前 (= 第 2 系統完走後、本規律で同様 preflight grep)
- A-2.2 Tasks phase ad-hoc V4 適用着手前 (= forced_divergence prompt の tasks phase 用調整方針が SSoT 明示か grep)
- A-2.3 Phase B-1.x supplementary 着手時 (= post-paper revision 時の rework_log 後付け運用規律 grep)
- A-3 + §3.7.6 batch 着手前 (= reverse-engineering 5 source bias mitigation の各 sample への適用方針 grep)
- 論文 draft 執筆着手時 (= Methodology / Threats to Validity sections の構造的決定明示記述 prerequisite)
- Spec 6 implementation 着手時 (= TDD cycle / DRY refactoring scope / SKILL.md role 精緻化等の rework_log 範囲規律 grep)

## 関連 memory

- 補強規律: `feedback_todo_ssot_verification.md` (= TODO 作成・更新時の SSoT 確認義務、本規律は構造的決定運用時にも同様の SSoT 照合義務を拡張)
- 補強規律: `feedback_dominant_dominated_options.md` (= dominated 選択肢提示禁止、user 質問時の選択肢提示で適用)
- 補強規律: `feedback_approval_required.md` (= 承認なしで進めない、構造的決定確定後の SSoT 反映 commit + push は user 承認対象)
- 適用事例: `project_treatment_design_md_state_policy.md` (= 30th 初頭事例、3 系統対照実験 design.md state policy 盲点 → preflight grep → user 質問 → 確定 → SSoT 反映 連鎖の参考)
- 親規律: `feedback_claim_d_evidence_disambiguation.md` (= 論文化議論時 preflight check 規律、本規律は jargon-loaded topic 全般への一般化)
