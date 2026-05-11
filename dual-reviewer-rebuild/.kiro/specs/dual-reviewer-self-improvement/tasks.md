# Tasks

## 1. この文書の役割

この文書は `dual-reviewer-self-improvement` を implementation 可能な作業単位へ落とした task plan である。

`self-improvement` は

- runtime / evaluation signal intake
- proposal artifact generation
- imported evidence provenance preservation
- replay / backtest
- approval / adoption / rollback history

を `learning/` 配下の concrete artifact として実装する。

## 2. 実装順序

1. learning directory skeleton を揃える
2. signal intake と signal inventory を実装する
3. proposal artifact と provenance fields を実装する
4. replay / backtest artifact を実装する
5. approval / adoption / rejection / rollback history を実装する
6. fixtures と tests を追加する

理由:

- imported evidence provenance は proposal artifact に入るので、signal intake の次に必要
- backtest は proposal artifact に依存する
- adoption / rollback history は proposal と backtest の後ろに置く

## 3. Tasks

### Task 1: Create learning directory skeleton

目的:

- self-improvement 正本出力先を repo 上に固定する

作業:

- `learning/findings/`
- `learning/proposals/`
- `learning/backtests/`
- `learning/approved-updates/`
- `learning/rejected-updates/`
- `learning/rollback/`

の skeleton を作る。

完了条件:

- self-improvement owner の artifact placement が repo 上に存在する

### Task 2: Implement signal intake from runtime and evaluation

目的:

- runtime / evaluation artifact から改善信号を抽出できるようにする

作業:

- runtime-derived signal loader
- evaluation-derived signal loader
- signal class classifier
- `v2/signal_linkage_note.json` loader
- `v2/trace_note.json` loader
- `derived/comparison_eligibility_note.json` loader

を実装する。

区別すること:

- `review_quality_signal`
- `workflow_failure_signal`
- `evidence_quality_signal`

完了条件:

- valid / invalid / exploratory の signal value の違いが intake で保持される
- v2 補助 artifact が signal 抽出補助入力として保持される

### Task 3: Implement signal inventory artifacts

目的:

- proposal 前の signal を machine-readable inventory にする

作業:

- `learning/findings/recurring_failure_signals.json`
- `learning/findings/workflow_failure_signals.json`

の writer を実装する。

含めること:

- signal class
- source refs
- validity / maturity context
- phase / treatment context

完了条件:

- proposal builder が raw run / analysis を再読しなくても入力 inventory を得られる

### Task 4: Implement proposal artifact generation

目的:

- 1 改善仮説 = 1 proposal artifact を concrete にする

作業:

- `learning/proposals/proposal_index.json`
- `learning/proposals/<proposal_id>.yaml`

の生成処理を実装する。

必須にすること:

- `target_layer`
- `motivation_class`
- `source_evidence_refs`
- `source_origin`
- `source_repository_refs`
- `source_admission_refs`
- `problem_statement`
- `proposed_change_summary`

完了条件:

- imported external bundle 由来の proposal と central local run 由来の proposal を区別できる

### Task 5: Implement imported evidence provenance preservation

目的:

- imported evidence が proposal 以降の artifact でも追跡可能になるようにする

作業:

- `source_origin` enum handling
- `source_repository_id` / `source_revision` propagation
- evaluation admission ref propagation

を proposal builder に実装する。

完了条件:

- provenance-insufficient imported evidence を standard admitted evidence と同列に扱わない

### Task 6: Implement replay input preparation

目的:

- runtime step-level artifact を replay 入力として再利用できるようにする

作業:

- replay input resolver
- `review_case.json`, `steps/*.json`, decision units, validation artifacts, `v2/trace_note.json`, `v2/signal_linkage_note.json` の selection logic

を実装する。

完了条件:

- Step B / Step C を中心とした proposal に対し step-level replay 準備ができる
- v2 補助 artifact を使った replay 補助入力を切り出せる

### Task 7: Implement backtest artifact generation

目的:

- proposal ごとの test result を machine-readable に残す

作業:

- `learning/backtests/backtest_index.json`
- `learning/backtests/<proposal_id>.json`

の writer を実装する。

含めること:

- `test_mode`
- `input_refs`
- `input_origin_refs`
- `result_label`
- `observed_effect`
- `risk_observations`

完了条件:

- `supported / unsupported / inconclusive / untested` が artifact として区別される

### Task 8: Implement approval, adoption, and rejection registers

目的:

- proposal の採否と repo 反映を履歴化する

作業:

- `learning/approved-updates/adoption_register.json`
- `learning/rejected-updates/rejection_register.json`

の writer / updater を実装する。

区別すること:

- `approved` と `adopted`
- rejection reason
- linked repo change ref

完了条件:

- runtime-affecting change の採否履歴が proposal artifact と結び付く

### Task 9: Implement rollback register

目的:

- harmful adopted change を learning history として戻せるようにする

作業:

- `learning/rollback/rollback_register.json`

の writer / updater を実装する。

含めること:

- `proposal_id`
- `adopted_change_ref`
- `rollback_reason`
- `rollback_trigger_signal_refs`
- `rolled_back_at`

完了条件:

- rollback が supersession と区別されて記録される

### Task 10: Implement project-specific pattern extraction helpers

目的:

- recurring signal を project-specific pattern candidate へつなげる最小導線を作る

作業:

- signal -> pattern candidate summarization helper
- project-specific / meta-pattern candidate distinction field
- recurring workflow failure mode から remediation template を派生する helper
- runtime validation summary payload を track 横断で検証する contract と validator helper

を inventory or proposal 周辺に追加する。

完了条件:

- self-improvement が単なる proposal registry で終わらず、pattern layer 成長の入口を持つ
- invalid-run triage の recurring failure mode から operator-facing remediation template を生成できる

### Task 11: Add self-improvement fixtures

目的:

- proposal / backtest / provenance flow の sample を用意する

作業:

- local run-based proposal fixture
- imported bundle-based proposal fixture
- workflow-failure-based proposal fixture
- rollback fixture

を配置する。

完了条件:

- implementation と tests が provenance branch を fixture で検証できる

### Task 12: Add self-improvement tests and smoke checks

目的:

- provenance-preserving proposal loop の最低限の mechanical validation を持つ

作業:

- signal intake test
- proposal provenance test
- imported evidence preservation test
- backtest artifact test
- approval vs adoption distinction test
- rollback registry test

を追加する。

完了条件:

- imported/local/manual origin distinction が proposal loop で失われない

## 4. Downstream Handoff

self-improvement tasks 完了後に、他 feature が参照してよい artifact は少なくとも次である。

- `learning/findings/*.json`
- `learning/proposals/*.yaml`
- `learning/proposals/proposal_index.json`
- `learning/backtests/*.json`
- `learning/approved-updates/adoption_register.json`
- `learning/rejected-updates/rejection_register.json`
- `learning/rollback/rollback_register.json`

## 5. Blocking Dependencies

self-improvement task 着手前の前提:

- runtime step-level artifact が存在する
- evaluation classification / metrics / caveat artifact が存在する
- evaluation imported bundle admission artifact が存在する

self-improvement tasks 完了まで blocked とみなす downstream task:

- paper-interface の methodology note 向け adopted history reuse
- proposal provenance を参照する implementation coordination

## 6. Completion Criteria

- signal intake が runtime / evaluation artifact を読める
- proposal artifact が imported/local/manual origin を区別して保存できる
- backtest artifact が input origin を保持する
- adoption / rejection / rollback history が machine-readable に残る
- imported evidence provenance が proposal loop で失われない
