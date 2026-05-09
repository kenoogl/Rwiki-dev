# Intent Track run template

_作成: 2026-05-09_  
_status: draft v0.1_  
_purpose: Intent Track first-run の実行テンプレート_

---

## 1. この文書の役割

この文書は、`Intent Track` の first-run を実際に回すときの
最小 run template である。

plan 文書で固定した条件を、実行手順と artifact 記録単位に落とす。

---

## 2. Run Header

記録すべき最小 header:

- run label
- case id
- track
- review mode
- input intent ref
- operator
- date
- objective

template:

```yaml
run_label: F1-intent-track
case_id: <case-id>
track: intent
review_mode: <single_review|dual_reviewer_workflow>
input_intent_ref: <path-or-doc-id>
operator: <name>
date: <YYYY-MM-DD>
objective: intent-to-spec bootstrap pilot
```

---

## 3. Inputs

最低限必要な入力:

- intent 文書
- non-goals / design principles があればその ref
- 関連する workflow/governance 文書 ref

記録欄:

```yaml
inputs:
  intent_ref: <path>
  supporting_refs:
    - <path>
```

---

## 4. Execution Steps

### 4.1 `single review`

1. intent を読む
2. requirement 化の major gap / scope drift 候補を列挙する
3. 必要なら `intent-attributed` のまま保持する
4. 意図を prematurely close しない
5. artifact を保存する

### 4.2 `dual-reviewer workflow`

1. intent を読む
2. primary reading を作る
3. adversarial pass で counter-hypothesis を出す
4. judgment で must-fix / should-fix / leave-as-is を分ける
5. `D` handback 要否を判定する
6. downstream (`requirements/design/tasks`) への propagation note を作る
7. artifact を保存する

---

## 5. Required Outputs

各 run で最低限残すもの:

- intent review artifact
- intent-to-requirements trace note
- phase-review metric snapshot
- signal linkage note
- workflow gate status reference

template:

```yaml
outputs:
  intent_review_artifact: <path>
  intent_trace_note: <path>
  phase_metric_snapshot: <path>
  signal_linkage_note: <path>
  workflow_gate_status_ref: <path>
```

---

## 6. Review Memo Fields

最小 memo field:

- major gap candidate
- scope drift candidate
- counter-hypothesis
- intent handback required
- downstream propagation target
- caveat

template:

```yaml
memo:
  major_gap_candidates:
    - <text>
  scope_drift_candidates:
    - <text>
  counter_hypotheses:
    - <text>
  intent_handback_required: <true|false>
  downstream_propagation_targets:
    - <requirements|design|tasks>
  caveats:
    - <text>
```

---

## 7. Success Check

run 後に確認すること:

1. intent review artifact が残ったか
2. `intent_revision_count` / `intent_handback_count` を更新できるか
3. downstream propagation target が明示されたか
4. disagreement / caveat が消えていないか

---

## 8. Failure Handling

次の場合は protocol mismatch note を残す。

- intent ref が曖昧
- supporting ref が不足
- downstream propagation target が定まらない
- `single` と `dual-reviewer` の比較が成立しない

