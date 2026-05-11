# Self-Improvement Proposal Review 2026-05-11

## Scope

このメモは、2026-05-11 時点の `learning/proposals/` を human decision gate に掛ける前の短い整理である。

対象:

- workflow proposal の統合方針
- `analysis_blocked` / `run_not_closed` の運用方針
- caveat proposal の優先順位

## Decisions

### 1. Merge Invalid-Run Workflow Proposals

次の 2 signal は、review 上は 1 テーマとして扱う。

- `validator_failed`
- `invalidation_marker_issued`

理由:

- どちらも invalid run prevention と invalidation handling の同一 remediation surface に乗る
- 分離したままだと、同じ run に対して重複 proposal review が発生する
- 実装側でも validator failure と invalidation marker explanation は close/triage workflow の同一論点である

運用:

- proposal builder は同一 run で両 signal が出たとき、1 workflow proposal に正規化する
- human review では `validator status` と `invalidation reason` を同時に見る

### 2. Formalize Analysis-Blocked Intake Policy

`analysis_blocked` は invalid の弱い別名ではない。次を明示ルールにする。

- `run_status != closed` の run は standard analysis に入れない
- required evaluation artifact が欠ける run は standard analysis に入れない
- これらは `invalid` ではなく `analysis_blocked` として exclusion する
- self-improvement の default inventory も closed run を基準にする

理由:

- aborted / created run を invalid run と同列に扱うと workflow defect と intake incompleteness が混ざる
- valid/invalid population の意味が崩れる

### 3. Caveat Review Priority

caveat proposal 2 件の扱いは次とする。

- `single_treatment_only`
  - `approve-candidate`
- `low_sample_size`
  - `hold-near-approve`

理由:

- `single_treatment_only` は comparison 自体が成立しないことを示すため、分析利用境界に直接効く
- `low_sample_size` は cautionary caveat であり重要だが、比較不能ほどの hard stop ではない

## Current Review Queue

優先順:

1. `proposal-workflow-invalid-run-guard-gap-run-invalid-001`
2. `proposal-workflow-analysis-precondition-gap-run-blocked-001`
3. `proposal-workflow-caveat-observed-single-treatment-only`
4. `proposal-workflow-caveat-observed-low-sample-size`
5. `proposal-prompt-human-decision-mix-run-exploratory-001`
6. `proposal-policy-exploratory-evidence-mode-run-exploratory-001`

補足:

- 5 と 6 は exploratory-only evidence なので引き続き hold 寄り
- 1 から 4 は workflow / analysis 境界の改善で、先に裁く価値が高い
