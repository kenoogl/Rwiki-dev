# V4 Review Protocol Draft (skeleton)

_生成: 2026-04-30 (7th セッション末)、暫定 V4 protocol skeleton_
_status: draft、8th セッション以降の適用結果で改訂 → 暫定 V4 → V4 default 採用判断_

V3 protocol (5 ラウンド + adversarial subagent 統合) で検出機能は実証されたが、検出された issue を「本当に修正すべきか」の judgment step が欠落 (= 過剰修正 bias 50% 顕在化、`v3-baseline-summary.md` §2.3 参照)。V4 protocol は V3 を base に **修正必要性 judgment step (Step 1c)** を体系的に追加した派生 protocol。

primary source: `docs/過剰修正バイアス.md` (user 提供、本 protocol 設計の根拠議論)

---

## §1 V4 core 改善 (V3 からの差分)

### §1.1 step 構造変更

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
```

### §1.2 Step 1c 新規仕様 = 修正必要性判定

各検出 issue に対し以下 3 axis assessment を **default 必須** で付与:

#### §1.2.1 necessity_assessment

```yaml
necessity_assessment:
  must_fix: true | false
  category: must_fix | optional | do_not_fix
  reason:
    - breaks_requirement     # requirements 文言 / AC 違反
    - causes_bug             # 実装 / 動作上の bug 発生
    - security_risk          # security / 致命級
    - consistency_only       # 一貫性のみ、実害なし
    - readability_only       # 可読性のみ、実害なし
    - speculative            # 投機的 / 将来仮想要件向け
```

3 分類の判定:

- `must_fix`: reason が `breaks_requirement` / `causes_bug` / `security_risk` のいずれかを含む = 真陽性 = 修正必須
- `optional`: 改善には資するが必須でない = judgment dependent = user 判断 (escalate)
- `do_not_fix`: reason が `consistency_only` / `readability_only` / `speculative` のみ = 過剰修正寄り = 修正回避推奨

#### §1.2.2 overengineering_risk

```yaml
overengineering_risk:
  level: high | medium | low
  signal:
    - adds_new_concept           # 新概念導入
    - expands_scope              # spec scope 拡張
    - requires_requirement_change # req 変更を要する修正
    - unclear_user_value         # user 価値不明確
```

`level: high` または `signal` に該当ありの場合、`category: do_not_fix` に強く push (= ルール 2 適用、§1.3 参照)。

#### §1.2.3 cost_balance

```yaml
cost_balance:
  if_ignored:
    impact: high | medium | low
  if_fixed:
    cost: high | medium | low
  ratio: impact_minus_cost  # +N (修正推奨) / 0 (中立) / -N (修正回避)
```

`impact < cost` (ratio < 0) の場合、ルール 1 適用 (§1.3) で `do_not_fix` 寄り判定。

### §1.3 判定ルール 3 種

V4 で必ず適用する判定 logic (過剰修正バイアス.md「シンプルな判定ルール」継承):

#### ルール 1: cost_balance 主導

```
impact < fix_cost → 修正不要寄り (do_not_fix or optional)
impact > fix_cost → 修正推奨 (must_fix candidate)
impact == fix_cost → escalate (user 判断)
```

#### ルール 2: requirements 紐付け主導

```
requirements に紐づかない → 原則修正しない (do_not_fix)
例外:
  - security_risk = breaks_requirement と同等扱い
  - causes_bug = breaks_requirement と同等扱い
```

「requirements を変更しないと成立しない修正」は **危険信号** = `overengineering_risk.signal: requires_requirement_change` を必ず付与、原則 `do_not_fix`。

#### ルール 3: 複数案 escalate (V3 既存規律と一致)

```
合理的選択肢が 2 案以上残る → escalate (user 判断必須)
```

memory `feedback_dominant_dominated_options.md` の dominated 除外 + 厳密化規律と integration。

### §1.4 adversarial subagent 役割拡張

V3:
- subagent 役割 = 「間違いを探す」 (positive detection)
- prompt: `Identify issues primary reviewer might have missed.`

V4:
- subagent 役割 = 「間違いを探す」+ 「**修正否定試行**」 (positive detection + counter-detection)
- prompt 追加: `For each issue, attempt to argue that it should NOT be fixed. Identify: (a) requirements に紐づくか / (b) impact が fix_cost を上回るか / (c) over-engineering signal はあるか. If any of (a)(b)(c) suggests no-fix, classify as do_not_fix candidate.`

これにより V4 subagent は「修正提案」だけでなく「修正否定提案」も同時生成、Step 1c で necessity_assessment を裏付ける counter-evidence として活用。

### §1.5 metric 改訂

V3 metric:
- adversarial 追加発見件数
- disagreement 数
- Phase 1 同型 hit rate
- 致命級独立発見件数

V4 metric (上記 + 新規):

| 指標 | 定義 | V4 改善目標 |
|------|------|-----------|
| 検出 → 採択率 | `must_fix` 件数 / 全検出件数 | 50%+ (V3 baseline 16.7%) |
| 過剰修正比率 | `do_not_fix` 件数 / 全検出件数 | 20% 以下 (V3 baseline 50%) |
| judgment dependent 比率 | `optional` 件数 / 全検出件数 | 30% 以下 (escalate user 判断必須) |
| bias 系列出比率 | overengineering signal 該当件数 / 全検出件数 | 30% 以下 |
| disagreement (counter-detection) | adversarial が do_not_fix と判定 - primary が must_fix と判定 (or 逆) | 増加 (V4 新)、forced divergence + 修正否定 prompt 効果 |

---

## §2 step 詳細仕様 (V4 改訂)

### §2.1 Step 1a (軽微検出) — V3 から変更なし

primary reviewer (Opus) が軽微 issue (typo / format / 表記揺れ等) を検出。Step 1c 適用対象だが、軽微 issue は通常 `do_not_fix` (readability_only) または `must_fix` (breaks_requirement = AC 文言違反) に二分。

### §2.2 Step 1b (構造的検出 5 重検査) — V3 から変更なし

memory `feedback_review_step_redesign.md` 規範: Step 1b-i 二重逆算 + ii Phase 1 パターン + iii dev-log 23 patterns + iv 自己診断 + v 内部論理整合 (5 重検査)。

検出された各 issue は Step 1c で必須 necessity_assessment を受ける。

### §2.3 Step 1b-v (自動深掘り判定) — V3 から変更なし

5 観点 + 5 切り口 (negative 視点 5 切り口) で深掘り、escalate 候補列挙。Step 1c で深掘り結果を judgment 対象として処理。

### §2.4 Step 1c (修正必要性判定) — V4 新規

#### §2.4.1 入力

Step 1a + 1b + 1b-v で検出された全 issue list。

#### §2.4.2 処理

各 issue に対し以下を順次実行:

1. **ルール 2 適用**: requirements grep で issue が AC 文言と紐付くか確認
   - 紐付き = `must_fix` candidate (reason: `breaks_requirement`)
   - 紐付きなし + security/bug = `must_fix` candidate (reason: `security_risk` or `causes_bug`)
   - 紐付きなし + security/bug でない = `do_not_fix` 寄り
2. **overengineering signal 検査**: 4 signal (adds_new_concept / expands_scope / requires_requirement_change / unclear_user_value) のいずれか該当か
   - 該当 = `do_not_fix` 強く push、`overengineering_risk.level: high or medium`
3. **cost_balance 評価**: impact (放置時) と cost (修正時) の比較
   - ルール 1 適用、`ratio` 算出
4. **adversarial subagent counter-evidence 取込**: §1.4 の修正否定試行で adversarial が `do_not_fix` 推奨した issue は judgment 反映
5. **3 分類確定**: 上記 1-4 を統合し `must_fix` / `optional` / `do_not_fix` 確定
6. **複数案検出時の escalate**: ルール 3 適用、`category: optional` 強制 + user 判断 flag

#### §2.4.3 出力

```yaml
issue_id: <ID>
detection_step: 1a | 1b | 1b-v
necessity_assessment:
  category: must_fix | optional | do_not_fix
  reason: [<reason enum list>]
overengineering_risk:
  level: high | medium | low
  signal: [<signal enum list>]
cost_balance:
  if_ignored.impact: high | medium | low
  if_fixed.cost: high | medium | low
  ratio: <integer>
adversarial_counter_evidence: <subagent 修正否定試行の根拠 narrative>
recommended_action: apply | escalate | skip
```

### §2.5 Step 2 (User 判断) — V4 改訂

Step 1c 出力を input に user に提示する判断 packet:

- **apply 候補** (`category: must_fix`): user 確認後に適用 (V3 と同じ flow)
- **escalate 候補** (`category: optional`): user 判断必須、複数案併記 + impact-cost 提示
- **skip 候補** (`category: do_not_fix`): user に「これは修正しないことを推奨」と明示提示 (LLM 単独で skip 確定せず、user 異議申し立て機会確保)

user は各 category について bulk approve / bulk skip / individual review を選択可能。

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

1. baseline state 復元 (foundation requirements.md は init 状態に戻す = `git checkout 06fde00 -- .kiro/specs/dual-reviewer-foundation/requirements.md`)
2. spec.json metadata reset (phase: initialized、approvals.requirements.generated: false)
3. `/kiro-spec-requirements dual-reviewer-foundation` 起動 (V4 protocol 下で req 再生成)
4. V4 protocol 下で req review (Step 1a / 1b / 1c / 2) — **Step 1c 必ず実施**
5. user approve → req approve commit
6. `/kiro-spec-design dual-reviewer-foundation` 起動 (V4 protocol 下で design 再生成)
7. V4 protocol 下で design review (Step 1a / 1b / 1b-v / 1c / 2) — **Step 1c 必ず実施**
8. user approve → design approve commit
9. **comparison report 生成** (本 baseline summary との対比)

---

## §4 比較指標 (8th セッション以降の measurement)

### §4.1 必須測定項目

`comparison-report.md` に以下を集計:

| 指標 | V3 baseline (foundation) | V4 result (foundation) | 差分 / 達成判定 |
|------|------------------------|----------------------|---------------|
| 検出件数 (req phase) | 14 + 31 = 45 件 | TBD | — |
| 検出件数 (design phase) | 6 件 (本 7th セッション) | TBD | — |
| `must_fix` 件数 | 1 (本 7th 適用済 S5-2) | TBD | — |
| `optional` 件数 | 2 (本 7th 適用済 S5-1, S5-3) | TBD | — |
| `do_not_fix` 件数 | 3 (本 7th VG-1, VG-2, VG-3) | TBD | — |
| 検出 → 採択率 | 16.7% | TBD | H3 達成判定 (50%+) |
| 過剰修正比率 | 50% | TBD | H1 達成判定 (20% 以下) |
| disagreement (V3 主指標) | 7 件 (req phase) | TBD | 検出機能維持確認 |
| Phase 1 同型 hit rate | 5 度 (全ラウンド該当) | TBD | 検出機能維持確認 |
| wall-clock (req review) | 420.7 秒 (subagent only) | TBD | H4 達成判定 (+30% 以内) |

### §4.2 仮説検証

| 仮説 | 内容 | 達成条件 |
|------|------|--------|
| H1 | V4 は V3 検出機能を維持しつつ過剰修正比率 20% 以下に抑制 | `do_not_fix` 比率 ≤ 20% かつ disagreement / Phase 1 同型 hit rate が V3 と同水準 |
| H2 | V4 judgment step は escalate 必須条件 5 種と integration、user 介入機会が `optional` 件数だけ増加 | escalate 件数 = `optional` 件数、user 判断機会の漏れなし |
| H3 | V4 検出 → 採択率は V3 比 3 倍 (16.7% → 50%+) | `must_fix` 比率 ≥ 50% |
| H4 | V4 wall-clock は V3 +20-30% 以内 | total wall-clock 増加 ≤ 30% |

H1-H3 全達成 = 暫定 V4 default 採用、design-review / dogfeeding 適用に展開。
H4 達成 = 運用許容範囲確認、未達成は Step 1c 軽量化検討。

---

## §5 V4 protocol open issues (skeleton 段階で要解決)

8th セッション適用前に user 確認が必要な open issue:

### §5.1 Step 1c の execution agent

- **option A**: primary reviewer (Opus) が Step 1c 実行 = 自分の検出結果を自分で judgment、bias 残存懸念
- **option B**: adversarial subagent (Sonnet) が Step 1c 実行 = bias diversity 高、ただし subagent は context 限定
- **option C**: 別 dedicated subagent (judgment-only role) を起動 = 役割分離 clean、cost +1 subagent
- 暫定推奨: **option A + adversarial counter-evidence 統合** (cost 最小、bias は §1.4 の修正否定 prompt で緩和)

### §5.2 cost_balance 評価の subjective 性

- impact / cost の 3 段階判定 (high/medium/low) は LLM の subjective evaluation
- mitigation: requirements AC 文言と紐付く issue は impact = high default、無関連 issue は impact = low default の semi-mechanical rule を導入予定

### §5.3 user 介入頻度の bound

- ルール 3 (複数案 escalate) で user 判断機会が増加、user 認知負荷上昇懸念
- mitigation: 各 round 終端で `optional` 件数を bulk 提示、individual review は user 選択制

### §5.4 V3 vs V4 比較の公平性

- 本 protocol は V3 を base に Step 1c 追加した派生 = 純粋な independent 比較ではなく ablation 比較
- mitigation: comparison-report.md で「V3 = step 1c なし baseline」「V4 = step 1c 追加 treatment」と明示、ablation 性質を明記

---

## §6 関連 reference

- primary source 議論: `docs/過剰修正バイアス.md` (user 提供、本 protocol 設計の根拠)
- V3 baseline evidence: `.kiro/methodology/v4-validation/v3-baseline-summary.md`
- V3 protocol 母体: memory `feedback_design_review.md` (10 ラウンド本質的レビュー) + `feedback_design_review_v3_adversarial_subagent.md` (adversarial subagent 統合)
- Step 1b 5 重検査: memory `feedback_review_step_redesign.md`
- 23 retrofit pattern: memory `feedback_review_judgment_patterns.md`
- dominated 除外規律: memory `feedback_dominant_dominated_options.md`
- escalate 必須条件 5 種: memory `feedback_review_step_redesign.md` (V3 と integration)

---

## 変更履歴

- v0.1 (2026-04-30、7th セッション末): 初版 skeleton、過剰修正バイアス.md ベースで起草、8th セッション適用結果で改訂予定
