---
name: 複数 file 操作前に dependency graph 調査必須
description: 複数 file の categorization / restructuring / deletion / 統合 を提案する前に grep で cross-reference / dependency / lineage を実地調査。表面読みで即提案する習性が 失態 3 件の共通原因
type: feedback
originSessionId: 5550c82b-3239-48a1-aad5-ca9566a9ec80
---
複数 file (≥3 件) の categorization / restructuring / deletion / 統合 を提案する前に、以下 4 step を必須実施:

1. **scope verification** = 対象 file 全件を ls / find で実地列挙 (= frontmatter description だけで判断しない)
2. **dependency graph** = grep で cross-reference / dependency 全件抽出 (= 表層 metadata でなく実 link)
3. **lineage check** = consolidation / 廃止 / 統合 履歴を frontmatter / git log で確認 (= 現役 vs historical 区別)
4. **role 多軸 classification** = 単一軸推定でなく protocol / ops / project / β 等の複数軸で identify

**Why**: 2026-05-06 で同 pattern 失態 3 件:
- 朝 memory 整理 = 表面読みで削除判断 → 7 file 不可逆喪失
- U-1 提案 = context cost を暗黙根拠化 → user 「読みがあさい」指摘
- M-1 第 1 提案 = cross-ref 未調査で group 提案 → user Q1/Q2/Q3 再分類指示 + 構造問題 4 件遅延 surface

3 件全て「対象を独立要素 list として treat、表層 metadata で immediate 提案」が共通失態モード。V4 Step 1b 4 重検査は review 文脈 bind のため memory / file 操作で発動しない gap。本規律は V4 が cover しない multi-entity work での depth-of-investigation を担保。

**How to apply**:
- task 文言に「再分類」「整理」「削除候補」「統合」「再構成」+ 対象 ≥3 file → 即 trigger
- 提案 1 turn 内で「scope + dependency graph 結果」を併記 (= user が depth verify 可能)
- 提案前に「私が今やろうとしているのは表層 categorization か、構造把握か」を 1 step 自問
- 1 file 深掘り操作は本規律 scope 外 (= 別途必要なら別規律)

## 関連 memory

- `feedback_review_step_redesign.md` (= V4 Step 1b 4 重検査、本規律と complementary)
- `feedback_response_quality_rules.md` (= performative honesty 禁止、本規律と独立軸)
- `feedback_reactive_rewriting_model.md` (= 提案後 user 指摘あれば書き直し、本規律で proactive 防止)
