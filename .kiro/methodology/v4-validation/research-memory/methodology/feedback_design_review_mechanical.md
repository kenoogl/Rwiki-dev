---
name: ⚠️ ARCHIVED = 設計レビュー方法論 v2 (機械検証中心、ペンディング、historical reference)
description: 2026-04-28 dogfeeding (Spec 2 design) 完走したが false positive 多数 + boundary 調整未済でペンディング、現方法論は v3/v4 default。本 file は再検討時の参照点として残置
type: feedback
originSessionId: cc8aae28-9172-4eff-9651-093fc96db3b4
---
**⚠️ ARCHIVED (41st 末整理確定)**:

本 memory は v2 機械検証方法論。2026-04-28 ペンディング状態で長期化、現運用 default は v3/v4 (= adversarial subagent + judgment subagent + necessity 5-field) で完全置き換え済。再検討時の参照点として本 file + `scripts/design_review_v2/` + `.kiro/methodology/dogfeeding/spec-2/` 残置、新規参照には使わない。

---

(以下、historical content)

**ステータス**: 2026-04-28 ペンディング (Spec 2 dogfeeding 結果から boundary / 抽出ルール調整が必要と判断、user 指示で運用 default は旧方式に戻す)。再検討時の参照点として本 memory + scripts/design_review_v2/ + .kiro/methodology/dogfeeding/spec-2/ を活用する。

設計層 (design.md) / タスク層 (tasks.md) のレビューでは、LLM に「良し悪し」を判定させると判断負荷過大で品質が逆に低下するため、機械検証可能な構造性質に絞る。

**Why:** Spec 5 design 10 ラウンドレビュー (累計 18 件 Edit、本質的レビュー後の検出ゼロ確認) を経た所感として、設計層は判断粒度が細かすぎ、LLM 採点 / 採否判断のばらつきが品質低下要因になりうる。設計・タスク層は「作業単位として健全か」のチェックで足り、内容の良し悪しは構造化メタデータに依存しない構造的検査に置き換えられる。

**How to apply:**

- **requirements 層 (requirements.md) のレビュー** = 旧方式 5 ラウンド + 5 memory 規律 (`feedback_review_rounds.md` / `feedback_deepdive_autoadopt.md` / `feedback_dominant_dominated_options.md` / `feedback_choice_presentation.md` / `feedback_approval_required.md`) を継続使用
- **design 層 (design.md) / tasks 層 (tasks.md) のレビュー** = 新方式 (本 memory) を default で適用
- **比較対象保存**: 旧方式 design 6 memory (`feedback_design_review.md` / `feedback_no_round_batching.md` / `feedback_review_step_redesign.md` / `feedback_review_judgment_patterns.md` / `feedback_design_spec_roundtrip.md` / `feedback_design_decisions_record.md`) は削除せず維持。新方式 default 適用後も旧方式が必要になる局面 (例: 致命的な再設計が必要なケース) で参照可能
- **計測対象**: Spec 5 design (旧方式 10 ラウンド適用済、累計 18 件 Edit) と Spec 2 design (新方式試行先、commit `23fffd0`) の検出件数 / 採用件数 / 所要時間を比較

## 中核原則

- LLM の判断介入を 2 箇所のみに限定 (Phase 1 メタデータ抽出 / Phase 2-E 意味的ドリフト検出)
- 残りの検査はすべて Python script で機械検証 (PyYAML + 単純判定)
- 「内容批評」「改善提案」「良し悪し採点」は LLM プロンプトで明示的に禁止
- 採点結果は `approve / reject` の二値ではなく、5 軸 score + risk_level (A〜D) + `human_review_required` flag

## パイプライン構造 (LLM 呼出 2 箇所)

```
[design.md / tasks.md]
        ↓ Phase 1: メタデータ抽出 (LLM)
design_metadata.yaml
        ↓ Phase 2-A: 構造チェック (script)
        ↓ Phase 2-B: トレーサビリティチェック (script)
        ↓ Phase 2-C: 型チェック (script)
        ↓ Phase 2-D: リスクパターンチェック (script)
        ↓ Phase 2-E: 意味的ドリフトチェック (LLM)
findings[]
        ↓ Phase 3: 採点 + risk_level 判定 (script)
review_report.yaml
```

## 5 種チェック概要

### A. 構造チェック (script)

- `parent_specs` 非空 (該当する design unit のみ)
- `inputs` / `outputs` 非空 (component / interface kind の場合)
- `components` 定義あり
- `dependencies` 未定義要素なし
- `tests` 紐付けあり

### B. トレーサビリティチェック (script)

- `design.parent_specs` 各 ID が `requirements_index` に実在 (orphan design 検出)
- `requirements_index` 各 ID が少なくとも 1 design unit に implemented_by (uncovered requirement 検出)
- 各 design unit が少なくとも 1 test に紐付け (uncovered test 検出)
- 関係チェーン Spec → Design → Task → Test の連結性

### C. 型チェック (script)

- 許容関係集合: `{Design implements Spec, Task implements Design, Test verifies Spec, Test verifies Task}`
- 不正例: `Spec implements Task` / `Design decomposed_into Spec` / `Test verifies Design` (Test は Spec / Task の振る舞い検証であり、Design 構造は検証対象でない)
- 不正関係は ERROR

### D. リスクパターンチェック (script)

- 単一 component が責務 3+ (responsibilities 配列長)
- 入力ありで出力なし
- 状態変更あり (`state_change: true`) で rollback なし (`rollback_defined: false`)
- 外部依存あり (`dependencies.kind == 'external'`) で failure_modes なし
- LLM 判断あり (`llm_judgment: true`) で confidence / escalation 設計なし (`llm_confidence_or_escalation: false`)
- 自動承認あり (`auto_approval: true`) で human gate なし (`human_gate: false`)

### E. 意味的ドリフトチェック (LLM)

drift 4 種のみ検出、内容批評・改善提案は禁止:

- **drift_authority**: 上位「人間判断必須」↔ 設計「LLM 自動判断」のズレ
- **drift_conservatism**: 上位「危険側に倒す」↔ 設計「効率側に倒す」のズレ
- **drift_scope**: 上位の適用範囲 ↔ 設計の適用範囲のズレ
- **drift_invariant**: 上位の不変条件 (atomicity / consistency / monotonicity) を、設計が破る経路を含む

ズレが見当たらない場合は `drift_kind: no_drift` で明示記録 (省略しない、判定済の証跡)。

## 採点と risk_level 判定

```yaml
review_result:
  scores:
    structural_score: <pass_count> / <total_count>           # A
    traceability_score: <pass_count> / <total_count>         # B
    type_score: <pass_count> / <total_count>                 # C
    risk_pattern_score: <pass_count> / <total_count>         # D
    semantic_alignment_score: 1 - (<drift_count> / <pair_count>)  # E
  composite_score: weighted_avg(traceability=0.3, risk_pattern=0.25, structural=0.2, type=0.15, semantic=0.1)
  risk_level: A | B | C | D
  human_review_required: bool
```

risk_level 判定 (初期値、運用後調整):

- **A (auto-approve 可)**: 全 score >= 0.95 かつ ERROR 0 件
- **D (人間判断必須)**: ERROR 1+ 件 または `semantic_alignment_score < 0.8`
- **B / C (中間)**: composite_score 範囲で B (0.85+) / C (0.70-0.85)

`human_review_required` 規律:

- risk_level = A のみ false (auto-approve 可)
- risk_level B / C / D はすべて true
- E (意味的ドリフト) の `drift_kind != no_drift` が 1 件以上 → 必ず true (構造 score が高くても人間判断)

## LLM プロンプト規律 (Phase 1 / Phase 2-E 共通)

- 「judgement / 改善提案 / 良し悪し評価は出力に含めない」を冒頭で明示
- 抽出 / 検出は「明示記述のみ」を根拠とし、推測で項目を埋めない
- 不明 / 抽出不能な項目は `null` または空配列で明示 (省略禁止、Phase 2 機械検証が欠落として検出する)
- LLM の自由度を制約することで、判断負荷を script 側に移譲する

## 旧方式との分担マトリクス

| Phase | 旧方式 (10 ラウンド) | 新方式 (機械検証 5 種) |
|-------|---------------------|----------------------|
| requirements 層 | ✅ 適用 (継続) | — |
| design 層 | 比較対象保存 | ✅ default 適用 |
| tasks 層 | (旧方式は適用ルール未確立) | ✅ default 適用 |
| approve gate | 各ラウンド Step 2 user 判断 | risk_level A 以外は user 判断必須 |
| LLM 判断回数 | 10 ラウンド × Step 1a/1b/1b-v 内検査 = ~30 LLM 呼出 | Phase 1 / Phase 2-E = 2 LLM 呼出 |

## 詳細仕様の参照先

- **Phase 1 メタデータ抽出 LLM プロンプト本文** / **Phase 2-A〜D 機械検証 script 規約** (各 Check ID + severity 表) / **Phase 2-E 意味的ドリフト検出 LLM プロンプト本文** / **Phase 3 採点 + risk_level 判定 script 仕様** (weight / boundary 初期値) / **計測項目 (Spec 5 vs Spec 2 比較表)** はプロジェクト内の以下に保存:
- `<repo>/.kiro/methodology/design_review_v2_full_spec.md` (Rwiki-dev リポジトリ git 管理)
- 次セッションで実装着手する場合、本仕様を Read してから Phase 1 LLM 試行 → Phase 2 script 実装 → Phase 3 dogfeeding の順で進める

## 試行先と計測項目

- **最初の試行先**: Spec 2 design (commit `23fffd0`、design.md 918 行 / Decision 2-1 〜 2-15) — 旧方式 10 ラウンドを実行する代わりに新方式 5 種機械検証で評価
- **比較計測項目**:
  - 検出件数 (旧 = 18 件、新 = ?)
  - 採用件数 / 採用率
  - LLM 呼出回数 (旧 ~30 / 新 = 2)
  - 所要時間 (旧 = 数セッション、新 = 1 セッション内完了見込み)
  - 検出された drift / risk pattern の有用性 (人間判断時に「ああ、これは確かに」となる比率)
- **判断基準** (新方式継続 vs 旧方式併用 vs 旧方式回帰): 計測結果を見て次々セッションで決定。新方式が決定的に劣る場合のみ旧方式に戻す
