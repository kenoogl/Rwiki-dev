---
name: A-2.1 3 系統対照実験 design.md state policy
description: A-2.1 30 review session 全 treatment は pristine state 285e762 起点で各 treatment 独立 branch 派生。累積 state 共有禁止 = confounding 排除
type: project
---

## state policy

- pristine state = `285e762` (= 19th sub-step 2 終端、Spec 6 design phase 起草直後)
- 第 1 系統 = main、treatment=dual+judgment、完走済 (Round 1-10、Level 6 events 44 件)
- 第 2 系統 = treatment-single branch、完走済 (Round 1-10、Level 6 events 17 件、過剰修正比率 63.0%)
- 第 3 系統 = treatment-dual branch、Round 1-8 完走 (= 45th 末)、残 Round 9-10

## why

29th 末まで第 1 系統が pristine から 10 round 累積修正で `f6bac54` に到達。accumulated state を起点に第 2/3 系統を回すと「prior treatment による事前修正」と「current treatment 単独 effect」が交絡 = V4 各 layer の機能寄与 quantify 不能 + paper rigor 致命的弱体化 (= self-referential bias = internal validity threat)。

## treatment branch 上で touch する file (= paper data archive)

- `.kiro/specs/rwiki-v2-perspective-generation/design.md` (Round 別修正)
- `.dual-reviewer/dev_log.jsonl` (Round 別 entry append、treatment + branch sub-group key 付与)
- `.kiro/methodology/v4-validation/rework_log.jsonl` (Level 6 events append、独立 sub-group sequence)

## treatment branch 上で touch しない file (= main SSoT)

- methodology 4 文書 = `data-acquisition-plan.md` + `evidence-catalog.md` + `preliminary-paper-report.md` + `comparison-report.md`
- dr-design SKILL.md + foundation patterns + Layer 2 design extension

## why touch しない

pristine state policy 整合 (= confounding 排除)。treatment branch は paper data source archive、accumulated review evidence のみ branch state に含める。methodology 文書 update は treatment 完走後 main checkout して実施。

## 規律参照経路 (= treatment branch 上から最新 main 文書参照)

- (a) memory body から規律参照
- (b) `git show main:<path>` で main 最新を branch 切替なし参照
- (c) main checkout して文書参照後 treatment branch 戻る

## branch 保持規律

- Spec 6 design.md 最終 state = main の post-Round 10 を採用
- 他 2 treatment branch は paper data source archive として保持 = delete 禁止
- archive tag 付与候補: `archive/a2-treatment-single-{date}` + `archive/a2-treatment-dual-{date}`
