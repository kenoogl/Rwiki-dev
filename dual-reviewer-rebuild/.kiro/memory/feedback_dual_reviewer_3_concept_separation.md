---
name: dual-reviewer 3 概念分離 (skill / V4 protocol / Level 6)
description: dual-reviewer 関連の 3 概念は scope と適用 phase が異なる = (1) dr-* skill = design phase 専用 / (2) V4 protocol = phase 横断適用可能 / (3) Level 6 = impl phase passive 観測。混同で計画 / 評価誤認識リスク
type: project
originSessionId: b998815a-3db9-4973-bd6a-9ccb1e07caf1
---
dual-reviewer methodology には scope と適用 phase が異なる 3 つの概念が並存。混同すると A-2 phase の scope を design phase のみに limit する等の誤認識につながる。

**Why:** 18th セッション (2026-05-02) で user 議論「dual-reviewer は design phase 専用」が誤認識のため整理確定。3 概念混同リスクが顕在化。19th 末で plan v1.5 / catalog v0.7 / paper v0.3 で SSoT 化済だが、reflexive 認識のため memory 化 (TODO L188 で「memory 化候補」と記載されていた knowledge)。

**How to apply:** dual-reviewer 関連の議論 / plan 起案で常に 3 概念を分離して扱う。3 概念の混同が疑われる発言 (例: 「dual-reviewer は design 専用」「Level 6 は dual-reviewer skill の一部」) は明確化質問で分離。

## 3 概念の scope + 適用 phase

### (1) dual-reviewer skill (= 物理 tool = dr-init / dr-design / dr-log / dr-judgment)
- **scope**: **design phase 専用** (= 17th 末で実装した dr-design は design.md を review する設計、req / tasks / impl phase は対象外)
- **適用 phase**: A-2.1 Spec 6 Design phase = systematic 30 review session (= 主要 evidence、論文 figure 1-4)
- **将来拡張**: Phase B-1.1 で dr-tasks skill (= tasks phase 用) 別 spec 化予定

### (2) V4 protocol (= 方法論本体 = primary + adversarial + judgment 3 subagent)
- **scope**: **phase 横断で適用可能** (= req / design / tasks 全 phase に protocol 適用可)
- **適用 phase**: 14th セッションで tasks phase に **ad-hoc 適用** 済 (= 3 spec の tasks.md を手動で V4 review、補助 evidence 取得)
- **A-2.2 適用**: Spec 6 Tasks phase で V4 ad-hoc 手動再現 (= forced_divergence + Step 1c judgment、補助 evidence、option、cost 数時間-1日)

### (3) Level 6 = downstream rework signal (= 観測軸)
- **scope**: **implementation phase で review ではなく上流 artifact 改版数を passive 観測** (= proactive review でなく post-hoc 観察)
- **適用 phase**: A-1 + A-2.3 implementation phase で `rework_log.jsonl` に Data 1 (commit pattern auto) + Data 2 (manual JSONL) + Data 3 (任意 TDD cycle) を記録
- **Claim D evidence**: 16th-17th + 18-19th methodology 改版 + 19th sub-step 1-2 含めて累計 0 events 継続中、Spec 6 implementation phase で初 event 発生可能性

## 3 概念分離による A-2 phase 3 段構成

3 概念それぞれに対応する A-2 sub-section (= data-acquisition-plan v1.5 §4 整合):

- **A-2.1 Spec 6 Design phase** = (1) dual-reviewer skill 30 session systematic = 主要 evidence (= 論文 figure 1-4)、必須
- **A-2.2 Spec 6 Tasks phase** = (2) V4 protocol ad-hoc 手動再現 = 補助 evidence (= phase 横断 reproducibility)、option
- **A-2.3 Spec 6 Impl phase** = (3) Level 6 passive 観測 = Claim D evidence、dual-reviewer skill 適用なし

## SSoT 文書

- `data-acquisition-plan.md` v1.5 §4 A-2 phase 3 段構成 (= A-2.1 / A-2.2 / A-2.3 + 終端統合分析)
- `evidence-catalog.md` v0.7 §5.2 (3 段構成 + Sub-group analysis 規律) + §5.5 (A-3 batch evidence)
- `preliminary-paper-report.md` v0.3 §1 Validation framing + §7 Future Work
