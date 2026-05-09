# Spec Track run template

_作成: 2026-05-09_  
_status: draft v0.1_  
_purpose: Spec Track first-run の実行テンプレート_

---

## 1. この文書の役割

この文書は、`Spec Track` の first-run を実際に回すときの
最小 run template である。

対象は `requirements / design / tasks` が既にある case であり、
phase 間伝播と alignment/reopen の扱いを記録する。

---

## 2. Run Header

記録すべき最小 header:

- run label
- case id
- track
- review mode
- reviewed phase
- upstream ref
- operator
- date

template:

```yaml
run_label: F1-spec-track
case_id: <case-id>
track: spec
review_mode: <single_review|dual_reviewer_workflow>
reviewed_phase: <requirements|design|tasks>
upstream_ref: <intent-or-spec-ref>
operator: <name>
date: <YYYY-MM-DD>
```

---

## 3. Inputs

最低限必要な入力:

- reviewed phase 文書
- 隣接 phase 文書
- alignment / dependency 文書

記録欄:

```yaml
inputs:
  reviewed_phase_ref: <path>
  adjacent_phase_refs:
    - <path>
  alignment_refs:
    - <path>
```

---

## 4. Execution Steps

### 4.1 `single review`

1. 対象 phase を読む
2. phase 内の gap / ambiguity / ordering issue を列挙する
3. 必要なら upstream/downstream propagation を手で判断する
4. artifact を保存する

### 4.2 `dual-reviewer workflow`

1. 対象 phase を読む
2. primary reading を作る
3. adversarial pass で cross-phase inconsistency 仮説を出す
4. judgment で must-fix / should-fix / leave-as-is を分ける
5. reopen / recheck depth を判定する
6. alignment note を保存する
7. phase-review metric snapshot を残す

---

## 5. Required Outputs

各 run で最低限残すもの:

- reviewed phase note
- alignment artifact or memo
- phase-review metric snapshot
- signal linkage note
- workflow gate status reference

template:

```yaml
outputs:
  reviewed_phase_note: <path>
  alignment_artifact: <path>
  phase_metric_snapshot: <path>
  signal_linkage_note: <path>
  workflow_gate_status_ref: <path>
```

---

## 6. Review Memo Fields

最小 memo field:

- phase-local issue
- cross-phase inconsistency
- reopen required
- target reopen phase
- intent-attributed issue
- caveat

template:

```yaml
memo:
  phase_local_issues:
    - <text>
  cross_phase_inconsistencies:
    - <text>
  reopen_required: <true|false>
  target_reopen_phases:
    - <requirements|design|tasks>
  intent_attributed_issues:
    - <text>
  caveats:
    - <text>
```

---

## 7. Success Check

run 後に確認すること:

1. alignment artifact が残ったか
2. phase-review metric snapshot を取れたか
3. reopen / recheck depth が明示されたか
4. phase 間伝播が記録されたか

---

## 8. Failure Handling

次の場合は protocol mismatch note を残す。

- reviewed phase と adjacent phase の対応が曖昧
- alignment ref が不足
- reopen depth を決められない
- `single` と `dual-reviewer` の比較が成立しない

