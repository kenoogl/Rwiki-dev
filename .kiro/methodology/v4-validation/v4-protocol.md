# V4 Review Protocol — 修正必要性 judgment 統合版

_version: v0.3 / 2026-04-30 (7th セッション末) / status: open issues 4 件すべて user 決定済、final_

V3 protocol (5 ラウンド + adversarial subagent 統合) は検出機能を実証したが、検出された issue を「本当に修正すべきか」の judgment step が欠落していた (= 過剰修正 bias 50% 顕在化、`v3-baseline-summary.md` §2.3)。V4 protocol = V3 を base に **修正必要性 judgment step (Step 1c)** を体系的に追加した派生 protocol。

**canonical design source**: `docs/過剰修正バイアス.md` §1-6 (user 拡張) + §7.2 (open issues 決定)

本 protocol は user 拡張 §1-6 + §7.2 決定を SSoT として、適用に必要な operational 詳細 (application procedure / metrics / hypotheses) を補完する。文言矛盾発生時は `docs/過剰修正バイアス.md` を優先。

---

## §1 V4 core 改善 (V3 からの差分)

### §1.1 step 構造変更 (canonical: 過剰修正バイアス.md §5)

V3:

```
Step 1a (軽微検出) → Step 1b (構造的検出 4-5 重検査) → Step 1b-v (自動深掘り) → Step 2 (User 判断)
```

V4:

```
Step 1a (軽微検出) → Step 1b (構造的検出 5 重検査) → Step 1b-v (自動深掘り)
                                                        ↓
                                        ★ Step 1c (修正必要性判定) ← 新規追加
                                                        ↓
                                                  Step 2 (User 判断)
                                                        ↓
                                                  Step 3 (適用)
```

Step 1c は Step 1a/1b の検出結果に対し **必ず通す** (canonical: §5)。

### §1.2 3 subagent 構成 (Issue 1 決定 = option C: dedicated judgment subagent)

V3 → V4 で subagent 構成が変化:

V3 (2 agent):
- **primary reviewer** (Opus): Step 1a + 1b + 1b-v detection + Step 2 user 提示
- **adversarial subagent** (Sonnet): Step 1b 独立 detection (見落とし検出)

V4 (3 agent、Issue 1 user 決定 = option C):
- **primary reviewer** (Opus): Step 1a + 1b + 1b-v detection + Step 2 user 提示
- **adversarial subagent** (Sonnet): Step 1b 独立 detection (見落とし検出) + **修正否定試行** (counter-detection、§1.5 prompt)
- **judgment subagent** (Sonnet or Opus、専用 role): **Step 1c 修正必要性判定のみ** (§1.3 + §1.4 + §1.6 適用、`docs/過剰修正バイアス.md` §7.2 Issue 1 決定)

採用根拠 (user 決定):
- option A (primary が自分で judgment) 却下 → bias 残存懸念、自己採点問題
- option B (adversarial が judgment) 却下 → subagent context 限定で判定精度低下
- **option C (dedicated subagent)** → 役割分離 clean、独立 context で bias 最小化

代償:
- API コスト + wall-clock 増加 (subagent 1 個追加分)
- H4 hypothesis 緩和必要 (§4.3 参照、+30% → +50% 以内に再設定)

### §1.3 Step 1c 仕様 = 修正必要性判定 (canonical: 過剰修正バイアス.md §1-2)

検出された各 issue に **3 段階ラベル** を付与:

- **must_fix**: 放置すると壊れる / 危険 / 矛盾する (条件: requirement / AC を満たせない / security / data loss / sandbox escape / API / schema / implementation 矛盾 / failure mode 未定義 / downstream task 作成不能)
- **should_fix**: 直した方がよいが、止めるほどではない (条件: 明示性不足 / test 方針が弱い / 将来保守性 / 読み手誤解リスク)
- **do_not_fix**: 正しい指摘でも今は直さない (条件: requirements にない / scope 拡張 / 実害曖昧 / 修正コスト高 / ideal design に寄りすぎ)

各 issue に必ず付与する **necessity 5 field schema** (canonical: §2):

```yaml
necessity:
  requirement_link: yes | no | indirect
  ignored_impact: critical | high | medium | low
  fix_cost: high | medium | low
  scope_expansion: yes | no
  uncertainty: high | medium | low
```

### §1.4 判定ルール 5 条件 + semi-mechanical mapping (canonical: 過剰修正バイアス.md §2 末 + §7.2 Issue 2 決定)

#### §1.4.1 判定ルール 5 条件 (canonical: §2 末)

```
critical impact → must_fix
requirement_link=yes かつ ignored_impact>=high → must_fix
scope_expansion=yes かつ critical でない → do_not_fix or escalate
fix_cost > ignored_impact → do_not_fix 寄り
uncertainty=high → escalate
```

これら 5 条件は順次評価、複数条件 hit 時は最も強い (must_fix > escalate > do_not_fix > should_fix) に traverse。

#### §1.4.2 semi-mechanical mapping rule (Issue 2 決定、§2 既存ルールに追加)

LLM 評価の subjective 性を抑制するため、以下 default mapping を judgment subagent prompt 内に埋込 (LLM は override 可、override 時は yaml 内に override reason 明記必須):

- requirements AC 文言と直接紐付き → `requirement_link: yes` + `ignored_impact: high` default
- AC 文言と間接紐付き → `requirement_link: indirect` + `ignored_impact: medium` default
- AC 紐付きなし + security / data loss / sandbox escape 該当 → `ignored_impact: critical` (security default)
- AC 紐付きなし + security/bug でない (consistency / readability / speculative) → `requirement_link: no` + `ignored_impact: low` default
- 修正範囲 1 file 以内 + 5 行以内 → `fix_cost: low` default
- 修正範囲 cross-spec or schema 変更 → `fix_cost: high` default
- それ以外 → `fix_cost: medium` default

### §1.5 adversarial subagent 役割拡張 (canonical: 過剰修正バイアス.md §3)

V3:
- subagent 役割 = 「見落とし検出」 (positive detection only)

V4:
- subagent 役割 = 「見落とし検出」+ **「修正否定試行」** (positive detection + counter-detection)

prompt template (英語固定、§5 で集約):

```
For each proposed fix, argue why it may not be necessary.
Classify it as must_fix, should_fix, or do_not_fix.
Prefer do_not_fix when the issue is speculative, expands scope, or lacks requirement linkage.
```

これにより adversarial subagent は「修正提案」だけでなく「修正否定提案」も同時生成、judgment subagent (§1.2 option C) が necessity 評価する際の counter-evidence として活用。

### §1.6 出力形式 (canonical: 過剰修正バイアス.md §4)

judgment subagent (§1.2) が各 issue を以下 yaml で出力 (concrete examples 抜粋、`docs/過剰修正バイアス.md` §4 より):

**must_fix example**:

```yaml
issue_id: 重-7-5
finding: PATH hijack 防御が未明示
severity: important
fix_decision:
  label: must_fix
  reason:
    - security_risk
    - implementation_failure_risk
necessity:
  requirement_link: indirect
  ignored_impact: high
  fix_cost: low
  scope_expansion: no
  uncertainty: low
recommended_action: fix_now
```

**do_not_fix example**:

```yaml
issue_id: 軽-9-3
finding: test file 名をより詳しく書ける
severity: minor
fix_decision:
  label: do_not_fix
  reason:
    - readability_only
    - no_requirement_link
necessity:
  requirement_link: no
  ignored_impact: low
  fix_cost: medium
  scope_expansion: no
  uncertainty: low
recommended_action: leave_as_is
```

`recommended_action` は user に対する提示用 (must_fix → fix_now / do_not_fix → leave_as_is / should_fix → user_decision)。

### §1.7 metric 改訂

V3 metric (継承):
- adversarial 追加発見件数
- disagreement 数
- Phase 1 同型 hit rate
- 致命級独立発見件数

V4 metric (V3 metric + 以下を追加):

- **検出 → 採択率** = `must_fix` 件数 / 全検出件数 (V4 改善目標 = 50%+、V3 baseline = 16.7%)
- **過剰修正比率** = `do_not_fix` 件数 / 全検出件数 (V4 改善目標 = 20% 以下、V3 baseline = 50%)
- **should_fix 比率** = `should_fix` 件数 / 全検出件数 (escalate user 判断対象、運用 cost 把握)
- **adversarial 修正否定 disagreement 数** = primary が must_fix / adversarial が do_not_fix (or 逆) の件数 (V4 新指標、forced divergence + 修正否定 prompt 効果)
- **judgment subagent disagreement 数** = primary 提案 vs judgment subagent 判定の不一致件数 (V4 option C 新指標、独立 context での bias 検証)
- **judgment subagent override 件数** = semi-mechanical mapping default を judgment subagent が override した件数 + 理由分析 (V4 新指標、§1.4.2 override semantics の運用評価)

---

## §2 step 詳細仕様 (V4 改訂)

### §2.1 Step 1a (軽微検出) — V3 から変更なし

primary reviewer (Opus) が軽微 issue (typo / format / 表記揺れ等) を検出。Step 1c 適用対象だが、軽微 issue は通常 `do_not_fix` (readability_only) または `must_fix` (breaks_requirement = AC 文言違反) に二分。

### §2.2 Step 1b (構造的検出 5 重検査) — V3 から変更なし

memory `feedback_review_step_redesign.md` 規範: Step 1b-i 二重逆算 + ii Phase 1 パターン + iii dev-log 23 patterns + iv 自己診断 + v 内部論理整合 (5 重検査)。検出された各 issue は Step 1c で必須 necessity 評価を受ける。

並行: adversarial subagent も Step 1b 独立 detection + §1.5 修正否定試行 を実施。

### §2.3 Step 1b-v (自動深掘り判定) — V3 から変更なし

5 観点 + 5 切り口 (negative 視点 5 切り口) で深掘り、escalate 候補列挙。Step 1c で深掘り結果も judgment 対象として処理。

### §2.4 Step 1c (修正必要性判定) — V4 新規、judgment subagent が実行

#### §2.4.1 入力 (judgment subagent dispatch payload)

primary reviewer が judgment subagent を起動、以下 payload を渡す:

- Step 1a + 1b + 1b-v で検出された全 issue list (primary + adversarial 検出分の merge)
- adversarial subagent からの修正否定 counter-evidence (§1.5 prompt に基づく出力)
- requirements.md 全文 (AC 文言紐付け検証用)
- (design phase の場合) design.md 全文
- §1.4.2 semi-mechanical mapping rule の default 値

#### §2.4.2 処理 (judgment subagent 内、順次評価)

judgment subagent は各 issue に対し以下を順次実行:

1. **requirement_link 評価**: requirements grep で issue が AC 文言と紐付くか確認 → `requirement_link: yes / indirect / no` を確定 (§1.4.2 mapping 適用)
2. **ignored_impact 評価**: 放置時の impact を `critical / high / medium / low` で評価 (§1.4.2 mapping 適用、override 時は理由明記)
3. **fix_cost 評価**: 修正時の cost を `high / medium / low` で評価 (§1.4.2 mapping 適用、override 時は理由明記)
4. **scope_expansion 評価**: 修正により spec scope が拡張されるか `yes / no` で評価
5. **uncertainty 評価**: 判定の確信度を `high / medium / low` で評価
6. **判定ルール 5 条件 適用** (§1.4.1): 5 条件を順次評価、最強条件で fix_decision.label 確定
7. **adversarial counter-evidence 取込**: adversarial の修正否定試行で `do_not_fix` 推奨があった issue は judgment 反映、disagreement 発生時は escalate
8. **recommended_action 確定**: must_fix → `fix_now` / do_not_fix → `leave_as_is` / should_fix → `user_decision`

#### §2.4.3 出力 (judgment subagent → primary)

§1.6 yaml format で各 issue を記録、JSONL append-only で蓄積。primary reviewer は受領後 Step 2 で user 提示。

### §2.5 Step 2 (User 判断) — V4 改訂、Issue 3 決定の 3 ラベル提示方式採用

Step 1c (judgment subagent 出力) を input に user に階層的提示 (`docs/過剰修正バイアス.md` §7.2 Issue 3 決定):

- **must_fix candidates**: 一覧化、**bulk apply default**、user は念のため確認したい case のみ individual review 選択
- **do_not_fix candidates**: 一覧化、**bulk skip default**、user は念のため確認したい case のみ individual review 選択 (LLM 単独で skip 確定せず、user 異議申し立て機会確保)
- **should_fix candidates**: 全件 user 提示、user が「全件 apply / 全件 skip / individual review」3 択 (bulk 操作は user 選択時のみ)

これで user は通常 must_fix / do_not_fix を bulk 処理、should_fix のみ判断 = 認知負荷を user 制御下に置く。

### §2.6 Step 3 (適用) — V3 から変更なし、ただし入力が Step 2 user 確定後の apply 対象のみ

---

## §3 適用 protocol (8th セッション以降の運用手順)

### §3.1 V4 適用前提

- baseline commit = `06fde00` (brief.md + Project Description のみ、AC なし)
- tag `v4-baseline-brief-2026-04-29` で固定参照点
- archive branch `archive/v3-foundation-design-7th-session` で V3 endpoint 保全
- V3 比較対照点 = `v3-baseline-summary.md`

### §3.2 適用順序

1. **foundation 1 spec から start** (cost 集中、効果確認最優先)
2. foundation V4 適用結果を `comparison-report.md` に集約 → 仮説 H1-H4 検証
3. H1-H3 達成 → 暫定 V4 default 採用、残 2 spec (design-review / dogfeeding) に展開
4. 未達成 → V4 protocol 改訂 → 再適用

### §3.3 適用 step

1. baseline state 復元 (foundation requirements を init 状態に戻す):
   - in-place reset = `git checkout v4-baseline-brief-2026-04-29 -- .kiro/specs/dual-reviewer-foundation/{requirements.md,spec.json}`
   - または worktree 並走 = `git worktree add ../Rwiki-dev-v4 v4-baseline-brief-2026-04-29` (main を汚さない運用)
2. spec.json metadata reset (phase: initialized、approvals.requirements.generated: false)
3. `/kiro-spec-requirements dual-reviewer-foundation` 起動 (V4 protocol 下で req 再生成)
4. V4 protocol 下で req review (Step 1a / 1b / 1c / 2 / 3) — **Step 1c 必ず judgment subagent dispatch**
5. user approve → req approve commit
6. `/kiro-spec-design dual-reviewer-foundation` 起動 (V4 protocol 下で design 再生成)
7. V4 protocol 下で design review (Step 1a / 1b / 1b-v / 1c / 2 / 3) — **Step 1c 必ず judgment subagent dispatch**
8. user approve → design approve commit
9. **comparison-report.md 生成** (本 baseline summary との対比)

---

## §4 比較指標 (8th セッション以降の measurement)

### §4.1 必須測定項目

`.kiro/methodology/v4-validation/comparison-report.md` に以下を集計:

- 検出件数 (req phase / design phase 各)
- `must_fix` 件数 + 比率
- `should_fix` 件数 + 比率
- `do_not_fix` 件数 + 比率
- 検出 → 採択率 (= must_fix 比率)
- 過剰修正比率 (= do_not_fix 比率)
- adversarial 修正否定 disagreement 数
- judgment subagent disagreement 数 (primary 提案 vs judgment subagent 判定)
- judgment subagent override 件数 + 理由 (§1.4.2 default mapping override 評価)
- Phase 1 同型 hit rate (V3 と V4 で維持されているか)
- wall-clock (req review 全工程、3 subagent 構成考慮)
- bias 系列出比率 (5 condition 中 fix_cost > ignored_impact / scope_expansion=yes / uncertainty=high の出現件数)

### §4.2 V3 baseline (foundation、対比表)

- 検出件数 (req phase): 14 + 31 = 45 件
- 検出件数 (design phase): 6 件 (本 7th セッション)
- 検出 → 採択率: 16.7% (1 / 6 = design phase 6 件 retroactive judgment より)
- 過剰修正比率: 50% (3 / 6)
- disagreement (V3 主指標): 7 件 (req phase)
- Phase 1 同型 hit rate: 5 度 (全ラウンド該当)
- wall-clock (req review subagent only): 420.7 秒

### §4.3 仮説 H1-H4 (Issue 1 = option C 採用に伴い H4 緩和)

- **H1**: V4 過剰修正比率 ≤ 20% (V3 baseline 50%)
- **H2**: V4 judgment step が escalate 必須条件と integration、user 介入機会が `should_fix` 件数だけ増加
- **H3**: V4 検出 → 採択率 ≥ 50% (V3 baseline 16.7%、3 倍改善目標)
- **H4 (緩和)**: V4 wall-clock + **50%** 以内 (V3 baseline 比、option C で subagent +1 個追加分のコスト許容、元 +30% → +50% に緩和)

H1-H3 全達成 = 暫定 V4 default 採用、design-review / dogfeeding 展開。
H4 達成 = 運用許容範囲確認、未達成は judgment subagent 軽量化検討 (例: judgment-only role に Haiku 採用 / 並列実行で wall-clock 抑制)。

### §4.4 ablation framing (Issue 4 決定)

`comparison-report.md` 記述で以下を明記:

- 「V3 = step 1c なし baseline」「V4 = step 1c 追加 + judgment subagent treatment」
- 主張は「Step 1c 追加によって過剰修正比率が X% から Y% に低下した」(ablation 効果) に限定、「V4 全体が V3 より優れる」と断じない
- pure independent 比較は B-2 multi-vendor + 並列 multi-subagent 段階で別 protocol との比較で実施

---

## §5 prompt template 集約

### §5.1 adversarial subagent 修正否定試行 prompt (canonical: 過剰修正バイアス.md §3)

英語固定 3 行、subagent prompt の末尾に追加:

```
For each proposed fix, argue why it may not be necessary.
Classify it as must_fix, should_fix, or do_not_fix.
Prefer do_not_fix when the issue is speculative, expands scope, or lacks requirement linkage.
```

### §5.2 judgment subagent dispatch prompt (Issue 1 = option C、Claude 起草、§1.4 + §1.6 整合)

dedicated judgment subagent への dispatch prompt:

```
You are a judgment-only subagent for V4 review protocol.
Your role: evaluate the necessity of each issue detected by primary reviewer
and adversarial subagent. Do NOT detect new issues. Do NOT propose fixes.
Only classify and assess necessity per issue.

Input:
  - issue_list: detected issues from primary + adversarial
  - counter_evidence: adversarial's "argue not to fix" outputs
  - requirements_text: full requirements.md
  - design_text: full design.md (if design phase)

For each issue, evaluate the following 5 fields:
  - requirement_link: yes (directly linked to AC text) | indirect (related but not direct AC) | no (no AC linkage)
  - ignored_impact: critical (system breaks) | high (function-blocking) | medium (degraded but functional) | low (cosmetic only)
  - fix_cost: high (cross-spec or schema change) | medium | low (within 1 file 5 lines)
  - scope_expansion: yes (would require spec scope change) | no
  - uncertainty: high (judgment unclear) | medium | low

Apply semi-mechanical mapping defaults first:
  - AC linkage direct → requirement_link=yes, ignored_impact=high
  - AC linkage indirect → requirement_link=indirect, ignored_impact=medium
  - No AC linkage + security/data_loss/sandbox_escape → ignored_impact=critical
  - No AC linkage + no security → requirement_link=no, ignored_impact=low
  - Fix scope: 1 file ≤5 lines → fix_cost=low
  - Fix scope: cross-spec or schema change → fix_cost=high
  - Otherwise → fix_cost=medium

You MAY override defaults, but document override_reason in yaml output.

Apply 5 judgment rules in order:
  1. critical impact → must_fix
  2. requirement_link=yes AND ignored_impact>=high → must_fix
  3. scope_expansion=yes AND not critical → do_not_fix or escalate
  4. fix_cost > ignored_impact → do_not_fix-leaning
  5. uncertainty=high → escalate

Output yaml per issue with fix_decision.label, necessity 5 fields, recommended_action,
and override_reason if any.
```

### §5.3 prompt 言語 policy

- prompt 言語 = 英語固定 (subagent 安定性 + multi-language 移行性)
- subagent 出力 = document auto-detect (yaml field 値は英語 enum 固定)
- user 提示 message = project 言語 (この場合 `ja`)

---

## §6 open issues 決定済 (canonical: `docs/過剰修正バイアス.md` §7.2)

`docs/過剰修正バイアス.md` §7.2 で 4 件すべて user 決定済 (2026-04-30 7th セッション末):

- **Issue 1**: Step 1c の execution agent 選定 → **option C 採用 (dedicated judgment subagent)**、§1.2 + §2.4 + §5.2 反映
- **Issue 2**: necessity 5 field の subjective 性 mitigation → **semi-mechanical mapping rule 採用**、§1.4.2 + §5.2 反映
- **Issue 3**: 3 ラベルの user 提示方式 → **3 ラベル提示方式 採用** (must_fix bulk apply / do_not_fix bulk skip / should_fix individual review)、§2.5 反映
- **Issue 4**: V3 vs V4 比較の公平性 → **ablation 性質明記 + 比較 framing 限定 採用**、§4.4 反映

8th セッション以降の作業:
- 新規 memory `feedback_review_v4_necessity_judgment.md` に上記 4 決定 + V4 protocol 確定経緯を記録
- `comparison-report.md` 生成時に §4.4 ablation framing 適用
- judgment subagent の実装 (Claude Code Agent tool で `subagent_type: general-purpose` + §5.2 prompt)

---

## §7 関連 reference

- canonical V4 design source: `docs/過剰修正バイアス.md` §1-6 (user 拡張) + §7.2 (open issues 決定)
- V3 baseline evidence: `.kiro/methodology/v4-validation/v3-baseline-summary.md`
- V3 protocol 母体: memory `feedback_design_review.md` (10 ラウンド本質的レビュー) + `feedback_design_review_v3_adversarial_subagent.md` (adversarial subagent 統合)
- Step 1b 5 重検査: memory `feedback_review_step_redesign.md`
- 23 retrofit pattern: memory `feedback_review_judgment_patterns.md`
- dominated 除外規律: memory `feedback_dominant_dominated_options.md`
- escalate 必須条件 5 種: memory `feedback_review_step_redesign.md` (V3 と integration)

---

## 変更履歴

- **v0.1** (2026-04-30 7th セッション中、`v4-protocol-draft.md` として初版): skeleton 起草、過剰修正バイアス.md (user 拡張前 v0) ベース、Claude 独自 3 axis schema (necessity_assessment + overengineering_risk + cost_balance)
- **v0.2** (2026-04-30 7th セッション末、`v4-protocol.md` に rename): user 拡張 §1-6 を canonical design として整合修正:
  - 3 段階ラベル: `optional` → `should_fix` (user 拡張 §1)
  - schema: 3 axis → 5 field necessity (user 拡張 §2)
  - 判定ルール: 3 種 → 5 条件 (user 拡張 §2 末)
  - adversarial 修正否定 prompt: 英語固定 3 行確定 (user 拡張 §3)
  - 出力形式: yaml concrete examples 採用 (user 拡張 §4)
  - prompt template 集約 §5 新規追加
  - open issues 4 件は §6 で reference、`docs/過剰修正バイアス.md` §7 で議論
- **v0.3** (2026-04-30 7th セッション末、open issues 4 件 user 決定後): final 確定:
  - **Issue 1 = option C** 採用 → 3 subagent 構成 (primary + adversarial + judgment) を §1.2 で正式定義、§2.4 / §5.2 反映、H4 hypothesis 緩和 (+30% → +50%)
  - **Issue 2 = semi-mechanical mapping rule** 採用 → §1.4.2 + §5.2 prompt に default mapping 7 種埋込、override 時は yaml で reason 明記
  - **Issue 3 = 3 ラベル提示方式** 採用 → §2.5 で must_fix bulk apply / do_not_fix bulk skip / should_fix individual review 規定
  - **Issue 4 = ablation framing 限定** 採用 → §4.4 で ablation 比較性質明記
  - §6 を「open issues 決定済」に更新、`docs/過剰修正バイアス.md` §7.2 を canonical decision source として参照
