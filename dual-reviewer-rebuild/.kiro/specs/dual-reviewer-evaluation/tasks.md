# Tasks

## 1. この文書の役割

この文書は `dual-reviewer-evaluation` を implementation 可能な作業単位へ落とした task plan である。

`evaluation` は

- local run intake
- imported bundle ingestion
- admission / classification
- metrics / comparisons / caveats

を `experiments/analysis/` 配下の concrete artifact として実装する。

## 2. 実装順序

1. analysis directory skeleton を揃える
2. local run intake を実装する
3. imported bundle ingestion と admission を実装する
4. classification と exclusion を実装する
5. metric extraction を実装する
6. comparisons と caveats を実装する
7. analysis manifest と fixtures/tests を追加する

理由:

- self-improvement と paper-interface は evaluation output がないと tasks を具体化しにくい
- imported bundle ingestion は classification / metrics の前提になる
- exclusion / caveat は comparisons の前に必要になる

## 3. Tasks

### Task 1: Create analysis directory skeleton

目的:

- evaluation 正本出力先を repo 上に固定する

作業:

- `experiments/analysis/imports/`
- `experiments/analysis/manifests/`
- `experiments/analysis/classifications/`
- `experiments/analysis/metrics/`
- `experiments/analysis/comparisons/`
- `experiments/analysis/caveats/`

の skeleton を作る。

完了条件:

- evaluation owner の artifact placement が repo 上に存在する

### Task 2: Implement local run intake

目的:

- in-repo local run directory を標準入力として読めるようにする

作業:

- `run_manifest.yaml`
- `review_case.json`
- `decisions/decision_units.json`
- `validation/validator_result.json`
- `validation/invalidation_markers.json`

を読む intake loader を実装する。

完了条件:

- runtime fixture を入力にして local run intake が成立する
- missing required artifact を識別できる

### Task 3: Implement imported bundle ingestion

目的:

- portable evidence bundle を central-side evaluation が intake できるようにする

作業:

- `bundle_manifest.yaml` loader
- exported run subtree resolver
- bundle checksum verifier
- required provenance check
- imported bundle materialization or in-memory intake path

を実装する。

完了条件:

- exported bundle fixture を evaluation が読める
- missing provenance を黙って補完しない
- bundle integrity を checksum で確認できる

### Task 4: Implement admission decision logic

目的:

- imported bundle を `standard / exploratory / rejected` に分ける

作業:

- admission rule evaluator
- `imports/ingestion_register.json` writer
- `imports/admission_register.json` writer

を実装する。

含めること:

- provenance sufficiency check
- review-mode distinction
- standard comparison eligibility

完了条件:

- imported evidence が admission status を持たずに比較へ入らない

### Task 5: Implement classification and exclusion logic

目的:

- valid / invalid / exploratory / analysis_blocked を concrete に分類する

作業:

- classification engine
- `classifications/run_classification_index.json`
- `classifications/exclusion_report.json`

を実装する。

区別すること:

- missing vs invalid
- imported admission vs run validity
- standard exclusion vs exploratory retention

完了条件:

- invalid / missing / analysis_blocked が混線しない
- exclusion reasons が machine-readable に残る

### Task 6: Implement run-level and finding-level metric extraction

目的:

- structured evidence から core metrics を再計算可能に抽出する

作業:

- `metrics/run_metrics.json`
- `metrics/finding_metrics.json`

の生成処理を実装する。

含めること:

- total / accepted / rejected / deferred
- severity distribution
- source-role distribution
- judgment label distribution

完了条件:

- `derived/runtime_summary.json` に依存せず metric を計算できる

### Task 7: Implement treatment-level metrics and comparisons

目的:

- treatment / phase-aware aggregate を concrete artifact にする

作業:

- `metrics/treatment_metrics.json`
- `comparisons/treatment_comparisons.json`
- `comparisons/phase_comparisons.json`

を生成する。

含めること:

- comparison precondition checks
- invalid comparison reason emission
- phase-specific overlay selection visibility

完了条件:

- `single / dual / dual+judgment` の比較条件が machine-readable に残る
- phase-aware comparison が `design / tasks` を中心に slice できる

### Task 8: Implement caveat and limitation artifacts

目的:

- exclusion と別軸で limitation を保持する

作業:

- `caveats/caveat_register.json` writer
- low sample size
- mixed maturity
- protocol drift
- exploratory-only slice

などの caveat emission を実装する。

完了条件:

- paper-interface と self-improvement が raw archive 再読なしに caveat を継承できる

### Task 9: Implement analysis manifest and versioning

目的:

- 同じ raw run set でも analysis logic 変更を区別できるようにする

作業:

- `manifests/analysis_run_manifest.yaml` writer

を実装し、

- `analysis_logic_version`
- `input_run_set`
- `metric_set_version`
- `phase_metric_profile_version`
- `comparison_contract_version`

を記録する。

完了条件:

- analysis output の再生成と差分追跡が可能になる

### Task 10: Add evaluation fixtures

目的:

- downstream feature と tests が使える evaluation output sample を用意する

作業:

- valid local run fixture intake result
- imported bundle admission fixture
- invalid / analysis_blocked fixture
- minimal comparison fixture

を配置する。

完了条件:

- self-improvement と paper-interface が fixture ベースで後続 task を起こせる

### Task 11: Add evaluation tests and smoke checks

目的:

- intake / admission / metrics の最低限の mechanical validation を持つ

作業:

- local run intake test
- imported bundle ingestion test
- admission decision test
- classification / exclusion test
- core metric extraction test
- comparison invalidity test

を追加する。

完了条件:

- imported / local / exploratory / invalid の区別が mechanical に確認できる

## 4. Downstream Handoff

evaluation tasks 完了後に、次の feature が依存してよい artifact は少なくとも次である。

- `experiments/analysis/imports/*.json`
- `experiments/analysis/classifications/*.json`
- `experiments/analysis/metrics/*.json`
- `experiments/analysis/comparisons/*.json`
- `experiments/analysis/caveats/caveat_register.json`
- `experiments/analysis/manifests/analysis_run_manifest.yaml`

## 5. Blocking Dependencies

evaluation task 着手前の前提:

- foundation metadata / review-mode / provenance field naming が存在する
- runtime canonical run artifact が存在する
- runtime exported bundle shape が存在する

evaluation tasks 完了まで blocked とみなす downstream task:

- self-improvement の imported evidence provenance task
- self-improvement の backtest-on-analysis task
- paper-interface の comparison source bundle task
- paper-interface の evidence register task

## 6. Completion Criteria

- local run と imported bundle の両 intake path が存在する
- admission status が machine-readable に残る
- valid / invalid / exploratory / analysis_blocked が分類できる
- metrics / comparisons / caveats が `experiments/analysis/` に出力される
- downstream feature が evaluation output を参照する前提を持てる
