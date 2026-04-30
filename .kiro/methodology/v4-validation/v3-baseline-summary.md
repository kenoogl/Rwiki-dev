# V3 Baseline Summary — 比較用 evidence 集約

_生成: 2026-04-30 (7th セッション末)、V4 protocol 適用前の baseline state 確定文書_

V4 protocol (過剰修正バイアス.md ベース) 適用後の比較用に、V3 protocol 下で蓄積された evidence を構造化集約する。8th セッション以降の V4 適用結果と本文書を直接対比して V4 効果を測定する。

---

## 1. baseline 確定 (代替 A 採用)

### baseline 選定根拠

候補 1 (req initial draft commit による復元) は git history 調査で実行不能と判明:

- 06fde00 (init commit): requirements.md は Project Description のみ + AC 生成前 placeholder = reviewable な initial draft ではない
- 2f6479e / ce0a958 / ea17473: req initial 生成 + V3 review 適用が同一 commit に固められている (one-shot pipeline 運用)

→ git commit による req initial draft 復元は不能、代替 A (brief.md baseline = req 再生成) を採用。

### 確定 baseline reference 点

- **commit**: `06fde00` (3 spec init、brief.md + Project Description のみ、AC なし)
- **tag**: `v4-baseline-brief-2026-04-29`
- **archive branch**: `archive/v3-foundation-design-7th-session` (V3 適用済 endpoint state 保全)
- **V3 evidence endpoint tag**: `v3-evidence-foundation-7th-session` (commit `e6cab03`)

### 比較対象 spec

- 1st 適用: `dual-reviewer-foundation` (本 baseline summary の主対象)
- 2nd 適用: `dual-reviewer-design-review` (foundation V4 適用後 + 効果確認後)
- 3rd 適用: `dual-reviewer-dogfeeding` (上記 2 spec V4 適用後)

---

## 2. V3 protocol 下で蓄積された evidence (比較対照点)

### 2.1 6th セッション req phase V3 review evidence (foundation のみ抜粋、全 3 spec の合算は memory 参照)

参照: `feedback_design_review_v3_adversarial_subagent.md` の req phase V3 適用 evidence section

#### foundation requirements V3 review (4th セッション末 〜 5th セッション、commit `2f6479e`)

- **LLM 主体 (Opus) 検出**: 14 件
- **subagent (Sonnet) 追加検出**: 致命級 2 件 + 重要級 16 件 + 軽微 13 件 = 31 件
- **disagreement**: 7 件 (E1 / E2 / E3 / A1 / B3-1 / D5-1 / A2-3 致命度再判定)
- **致命級独立発見 (subagent)**: 2 件 (A2-3 draft 内部矛盾 / D5-1 design-review brief.md quota 旧定義)
- **Phase 1 escalate 3 種同型**: 全 5 ラウンドで全 3 種該当検出
- **subagent 累計 wall-clock**: 420.7 秒 (~7.0 分)
- **適用修正合計**: 36 件 (本 spec 27 件 + 隣接 spec brief.md 6 件 + draft v0.2 → v0.3 改訂 3 件)

#### V4 retroactive judgment 課題 (8th セッション以降)

上記 36 件の適用修正各々に V4 protocol を遡及適用し、以下を判定:

- `must_fix`: 真陽性 (要対応、放置すれば実害発生)
- `optional`: judgment dependent (改善には資するが必須でない)
- `do_not_fix`: 過剰修正寄り (false positive bias)

reason 6 種 (過剰修正バイアス.md): `breaks_requirement` / `causes_bug` / `security_risk` / `consistency_only` / `readability_only` / `speculative`

→ 結果は `comparison-report.md` (8th セッション以降) に記録。

### 2.2 7th セッション design phase V3 review evidence (foundation、本セッション)

#### Step 5 修正パス 1 = 適用 3 件

参照: 本セッションでの design.md 起草過程 + 修正パス記録

| # | 修正内容 | 検出根拠 (V3) | 7th セッション末の retroactive judgment |
|---|---------|--------------|----------------------------------|
| S5-1 | REVIEW_CASE entity ERD field 列挙に trigger_state 追加 | requirements 3.1 「id / phase / timestamp / round / primary_findings / adversarial_findings / integration_result / trigger_state」8 field | judgment dependent (relation で semantic 等価表現済、文言整合は厳密性向上だが approve gate 必須ではない) |
| S5-2 | seed_patterns yaml の origin field を per entry 配置 | requirements 4.2「全 entry に `origin: rwiki-v2-dev-log` を付与」 | **must_fix** (要件文言と yaml 構造論で真陽性) |
| S5-3 | Loader API を SeedPattern + FatalPattern の 2 つの TypedDict に分離 | requirements 5.2 詳細 `detection_hints` 複数形 vs 4.4 pattern_schema 準拠の type safety 整合 | judgment dependent (単一 TypedDict + Optional でも表現可能、cleanup として valuable だが必須ではない) |

#### Validation gate 提示 3 件 (未適用、approve 前要対応として critical 該当判断)

| # | 提示内容 | critical 該当根拠 (V3) | 7th セッション末の retroactive judgment |
|---|---------|----------------------|----------------------------------|
| VG-1 | extension_points.md content 未定義 | requirements 1.4 「shall extension point を提供する」readiness 不足、downstream design-review 依存契約欠落 | 軽度〜中度過剰寄り (downstream design-review spec の design phase で逆方向に Layer 1 継承点定義する依存反転パターンも妥当、design.md で全 shape 確定する LLM の completeness bias の可能性) |
| VG-2 | Logical Data Model ERD の PATTERN / PRIMARY_GROUP entity 定義欠落 | ERD relation 描画に entity field block が無い = self-containedness 不足 | 中度過剰 (Domain Model 文 + artifact yaml 例 + Loader TypedDict で domain 網羅済、ERD は補助的視覚化、critical 該当は self-containedness bias) |
| VG-3 | 並行 dr-init 起動時 race condition 取扱未明示 | dev-log pattern F18 (race condition window) 同型疑い | 高度過剰 (Phase A scope = single-session 想定で大半 OK、research.md Risk 3 で言及済、design.md 本文転写は文字数増加のみで本質価値低い、completeness bias) |

### 2.3 7th セッション末 集計

| 分類 | 件数 | 比率 |
|------|------|------|
| `must_fix` (真陽性、要対応) | 1 | 16.7% |
| `optional` (judgment dependent、改善資するが必須ではない) | 2 | 33.3% |
| `do_not_fix` (過剰修正寄り、false positive bias) | 3 | 50.0% |
| **合計** | **6** | **100%** |

= **検出 6 件中 50% が過剰修正 bias**。adversarial subagent 検出 (V3) は機能するが「修正必要性 judgment」step が欠落していた構造的証拠。

---

## 3. V4 protocol 適用後の比較指標 (8th セッション以降で測定)

### 3.1 主指標

- **検出 → 採択率** = `must_fix` 件数 / 全検出件数 (V3 = 16.7%、V4 改善目標 = 50%+)
- **過剰修正比率** = `do_not_fix` 件数 / 全検出件数 (V3 = 50%、V4 改善目標 = 20% 以下)
- **judgment dependent 比率** = `optional` 件数 / 全検出件数 (V3 = 33.3%、escalate user 判断必須化)

### 3.2 sub 指標

- **検出件数** (V3 vs V4): adversarial 検出機能自体は維持されているか
- **disagreement 数**: V4 で primary 否定型 disagreement が増加するか (adversarial 修正否定 prompt 効果)
- **Phase 1 同型 hit rate**: V3 evidence 累計と同等水準維持できるか
- **wall-clock**: judgment step 追加で時間 cost 増加幅
- **bias 系列出**: `adds_new_concept` / `expands_scope` / `requires_requirement_change` / `unclear_user_value` の出現比率

### 3.3 比較期待値

V4 効果仮説 (検証対象):

- **仮説 H1**: V4 は V3 の検出機能を維持しつつ過剰修正比率を 20% 以下に抑制
- **仮説 H2**: V4 の judgment step は escalate 必須条件 5 種と integration し、user 介入機会が `optional` 件数だけ増加
- **仮説 H3**: V4 検出 → 採択率は V3 比 3 倍 (16.7% → 50%+)
- **仮説 H4**: V4 wall-clock は V3 +20-30% 以内 (judgment step 追加 cost 限定的)

H1-H3 達成 = 暫定 V4 default 採用条件、H4 = 運用許容範囲確認。

---

## 4. 比較作業フロー (8th セッション以降)

1. **V4 protocol 適用** (foundation 1 spec から start):
   - baseline = `06fde00` (brief.md + Project Description のみ、AC なし)
   - `/kiro-spec-requirements dual-reviewer-foundation` 起動 (V4 protocol 下で req 再生成)
   - V4 protocol 下で req review (Step 1a / 1b / **1c (新規)** / 2)
   - `/kiro-spec-design dual-reviewer-foundation` 起動 (V4 protocol 下で design 再生成 + review)

2. **比較データ集約** (`comparison-report.md`):
   - V3 evidence (本 summary の §2 + 6th セッション req review 36 件) vs V4 検出件数 + judgment 分類
   - 主指標 + sub 指標を表化
   - 仮説 H1-H4 検証結果

3. **暫定 V4 判定**:
   - H1-H3 達成 → 暫定 V4 default 採用、残 2 spec (design-review / dogfeeding) も V4 適用
   - 未達成 → V4 protocol 改訂 (Step 1c 拡張 / 判定ルール調整 / metric 改訂) → 再適用
   - 教訓は `feedback_v3_adoption_lessons_phase_a.md` に教訓 12 として追記

4. **dev-log 連動**:
   - V3 evidence: `docs/dual-reviewer-log-1.md` (read-only、改変なし、V3 正本)
   - V4 evidence: `docs/dual-reviewer-log-2.md` (8th セッション以降 user 管理で append-only)

---

## 5. 関連 reference

- baseline commit: `06fde00`
- V3 evidence endpoint: tag `v3-evidence-foundation-7th-session` (commit `e6cab03`)
- V3 適用 archive branch: `archive/v3-foundation-design-7th-session`
- V4 protocol skeleton: `.kiro/methodology/v4-validation/v4-protocol.md`
- V4 protocol source 議論: `docs/過剰修正バイアス.md` (user 提供)
- V3 review 過程記録: `docs/dual-reviewer-log-1.md` (user 管理 dev-log)
- V3 累計 evidence: `~/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/feedback_design_review_v3_adversarial_subagent.md`
- V3 適用教訓 (req phase): `~/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/feedback_v3_adoption_lessons_phase_a.md`
