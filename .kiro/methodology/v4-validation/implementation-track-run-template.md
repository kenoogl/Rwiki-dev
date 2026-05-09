# Implementation Track run template

_作成: 2026-05-09_  
_status: draft v0.1_  
_purpose: Implementation Track first-run の実行テンプレート_

---

## 1. この文書の役割

この文書は、`Implementation Track` の first-run を実際に回すときの
最小 run template である。

対象は implementation/review phase であり、
upstream spec と implementation artifact を切らずに review evidence を残す。

---

## 2. Run Header

記録すべき最小 header:

- run label
- case id
- track
- review mode
- implementation snapshot ref
- upstream spec ref
- operator
- date

template:

```yaml
run_label: F1-implementation-track
case_id: <case-id>
track: implementation
review_mode: <single_review|dual_reviewer_workflow>
implementation_snapshot_ref: <path-or-snapshot-id>
upstream_spec_ref: <path>
operator: <name>
date: <YYYY-MM-DD>
```

---

## 3. Inputs

最低限必要な入力:

- implementation snapshot
- upstream `requirements / design / tasks`
- relevant workflow/governance refs

記録欄:

```yaml
inputs:
  implementation_snapshot_ref: <path>
  upstream_spec_refs:
    - <path>
  governance_refs:
    - <path>
```

---

## 4. Execution Steps

### 4.1 `single review`

1. implementation snapshot を読む
2. implementation issue 候補を列挙する
3. 必要なら upstream spec inconsistency を別枠で記録する
4. artifact を保存する

### 4.2 `dual-reviewer workflow`

1. implementation snapshot を読む
2. primary reading を作る
3. adversarial pass で counter-hypothesis を出す
4. judgment で must-fix / should-fix / leave-as-is を分ける
5. caveat と disagreement を保持する
6. upstream spec への reopen 要否を判定する
7. conformance review に接続する artifact を保存する

---

## 5. Required Outputs

各 run で最低限残すもの:

- review artifact
- decision units
- caveat / exclusion artifact
- signal linkage note
- conformance review result
- downstream rework placeholder or log

template:

```yaml
outputs:
  review_artifact: <path>
  decision_units: <path>
  caveat_artifact: <path>
  signal_linkage_note: <path>
  conformance_review_result: <path>
  downstream_rework_log: <path>
```

---

## 6. Review Memo Fields

最小 memo field:

- implementation-local issue
- upstream-spec inconsistency
- disagreement
- reopen required
- target reopen phase
- caveat

template:

```yaml
memo:
  implementation_local_issues:
    - <text>
  upstream_spec_inconsistencies:
    - <text>
  disagreements:
    - <text>
  reopen_required: <true|false>
  target_reopen_phases:
    - <requirements|design|tasks|intent>
  caveats:
    - <text>
```

---

## 7. Success Check

run 後に確認すること:

1. review artifact と decision units が残ったか
2. caveat / disagreement が消えていないか
3. conformance review に接続できるか
4. implementation issue と upstream spec issue を混同していないか

---

## 8. Failure Handling

次の場合は protocol mismatch note を残す。

- upstream spec ref が不足
- implementation snapshot boundary が曖昧
- reopen depth を決められない
- `single` と `dual-reviewer` の比較が成立しない

