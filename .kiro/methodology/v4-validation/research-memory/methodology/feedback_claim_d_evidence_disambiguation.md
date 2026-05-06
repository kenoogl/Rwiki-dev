---
name: Claim D evidence の 3 種別 disambiguate 規律 (29th 末確定、self-referential metric 批判への direct rebuttal)
description: Claim D primary (= A-1 + §3.7.6) / Claim B/C functioning (= A-2.1 design phase events) / Phase B-1.x supplementary (= A-2.3) を論文化文言で必ず分離。混同すると self-referential metric 批判で paper rigor 崩壊
type: feedback
originSessionId: 04a89373-89cf-445e-bb8f-c575f15cc75f
---
論文化議論で Claim D evidence を扱う際、3 種別を必ず disambiguate する。混同すると「V4 自身が generate した design fix events を V4 有効性 evidence として claim する logical circularity」(= self-referential metric 批判) に陥り、paper rigor が崩壊する。

**Why:** 29th 末で A-2.1 design phase の rework_log 44 events を Claim D primary evidence と扱うか議論があり、scope 精緻化で「pre-impl design fix process events」≠「post-approve impl phase rework events」と判明。A-2.1 events = V4 自身が generate した修正 = self-referential、Claim D primary evidence としては使用不可。Claim B/C functioning evidence (= V4 review が design fix を generate する pattern observation) として再 framing が必要。

**How to apply:**

### 3 evidence 種別の precise 定義

- **Claim D primary evidence** = post-approve upstream artifact (req/design/tasks) rework rate during **implementation phase** (NOT during design / review phase)
  - 構成: A-1 全 implementation phase (3 spec self-dogfooding、Python、forward-fresh、現状 0 events) + §3.7.6 re-implementation phase (3 sample external、Julia/C++/Arduino C、reverse-engineered) = **6 spec instance**
  - rework_log entry 特徴: `discovered_phase="impl-mid|tdd-red|e2e-test"` + `rework_target="requirements|design|tasks"`
  - 論文での扱い: Claim D primary metric として直接 claim 可能
- **Claim B/C functioning evidence** = V4 review が design fix を generate する pattern observation
  - 構成: A-2.1 Spec 6 design phase rework_log 44 events (29th 末確定)
  - rework_log entry 特徴: 全件 `discovered_phase="pre-impl"` + `rework_target="design"`
  - 論文での扱い: Claim B (= judgment 効果) + Claim C (= architecture valid) の支持 evidence、Claim D primary には絶対に使わない
- **Phase B-1.x supplementary evidence** = post-paper revision 用補強 data
  - 構成: A-2.3 Spec 6 implementation phase events (= 30th 以降取得、論文 draft 着手の前提条件にしない)
  - 論文での扱い: paper revision 時に付加可能な supplementary data、初版 paper には含めない

### 論文 Limitations section 4 件記述方針 (必須)

1. "post-approve upstream artifact rework rate" を Claim D primary metric として明示
2. "schema 範囲外の implementation-level adjustments (TDD cycle / DRY refactoring / SKILL.md role 精緻化等) are out of scope of Claim D measurement"
3. **"A-2.1 design phase events (= 44 events) are reported as Claim B/C functioning evidence (= V4 review process pattern observation), NOT as Claim D primary evidence"** = self-referential metric 批判への direct rebuttal
4. **"Claim D primary evidence is composed of forward-fresh-spec sub-group (A-1) and reverse-engineered-spec sub-group (§3.7.6); reverse-engineering 5 source bias is acknowledged and addressed via sub-group reporting"** = forward / reverse 別 sub-group reporting で reverse-engineering bias 5 source を direct acknowledge

### future session 適用場面

- 論文 draft / preliminary report / evidence-catalog / data-acquisition-plan の Claim D 関連記述
- Level 6 events を analyze する際、phase tag (pre-impl / impl-mid / etc) で 3 種別を分離
- user / reviewer に Claim D evidence を説明する際、上記 3 種別 framing を冒頭で明示

### 論文化議論時の preflight check (= 30th セッション初回失敗を踏まえた再発防止規律)

論文化文脈 / Claim D evidence / A-2.1 events / Level 6 events / dual-reviewer evidence 種別 等の議論を開始する前に、以下を **必ず** 実行:

1. **memory body 実 read**: 本 memory (= `feedback_claim_d_evidence_disambiguation.md`) の body を直接 Read tool で読む。MEMORY.md index の 1 行 description で済ませない。
2. **3 種別 disambiguate を冒頭で明示**: 議論開始時に Claim D primary / Claim B/C functioning / Phase B-1.x supplementary の 3 種別を **箇条書きで明示**。総合化 framing (= 「論文化目的」「Claim D 蓄積」等) で済ませない。
3. **input source 検証**: TODO_NEXT_SESSION.md / 過去 commit message / dev_log entry 等の input source 内に stale framing (= 「Level 6 events 蓄積 = Claim D primary evidence」型の誤った association) が残存していないか grep で確認、残存時は本 memory body の precise 定義で覆す (= TODO 文言を鵜呑みにしない)。

### 観察された失敗 pattern (= 30th セッション初回観察、再発防止用)

- **memory description 1 行で済ませる pattern**: MEMORY.md index の description (1 行) を読んで本体 body を read せず、jargon-loaded topic で precise 定義を欠いた回答を生成した
- **TODO summary 文言の uncritical 継承**: TODO_NEXT_SESSION.md 内に「Level 6 累計 events = Claim D primary evidence 蓄積継続」型の stale framing が残存しており、これを critical 検証せず継承
- **jargon 一括化 pattern**: A-2 phase 全体目的を「論文化目的 = Claim B/C primary evidence」と総合化、3 種別個別 disambiguate を skip
- **訓練 data origin 不在 jargon の generic abstraction 偏向**: 「primary evidence」「functioning evidence」の disambiguate は dual-reviewer プロジェクト固有規律で訓練 data に存在しない、generic「research methodology evidence」pattern に置換されやすい

## 関連 memory

- 親文脈: `project_a23_substitute_with_a376.md` (= A-2.3 critical path 外し + §3.7.6 substitute 戦略)
- 反映文書: `preliminary-paper-report.md` v0.5 §6.6 + `data-acquisition-plan.md` v1.6 §3.6 + `evidence-catalog.md` v0.9 §5.1.6
- 補強規律: `feedback_todo_ssot_verification.md` (= TODO 鵜呑み禁止、SSoT 照合義務) — 本 memory での failure pattern は TODO 鵜呑みの一形態
