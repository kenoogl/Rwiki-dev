# Tasks

## 1. この文書の役割

この文書は `dual-reviewer-paper-interface` を implementation 可能な作業単位へ落とした task plan である。

`paper-interface` は

- claim mapping
- evidence register
- table / figure source bundles
- caveat-preserving reporting fragments

を `paper/` 配下の concrete artifact として実装する。

## 2. 実装順序

1. paper directory skeleton を揃える
2. evaluation output intake を実装する
3. claim map と evidence register を実装する
4. table / figure source bundle を実装する
5. caveat register と reporting fragments を実装する
6. optional methodology-note linkage を実装する
7. fixtures と tests を追加する

理由:

- paper-interface は evaluation consumer なので intake が最初
- claim map と evidence register が central artifact
- table / figure bundles は claim/evidence mapping に依存する
- caveat / fragment は source bundle の後ろで組み立てる

## 3. Tasks

### Task 1: Create paper directory skeleton

目的:

- paper-interface 正本出力先を repo 上に固定する

作業:

- `paper/reports/`
- `paper/tables/`
- `paper/figures/`
- `paper/caveats/`

の skeleton を作る。

完了条件:

- paper-interface owner の artifact placement が repo 上に存在する

### Task 2: Implement evaluation output intake

目的:

- paper-interface が standard upstream source を intake できるようにする

作業:

- `analysis_run_manifest.yaml`
- `treatment_comparisons.json`
- `phase_comparisons.json`
- `exclusion_report.json`
- `caveat_register.json`
- 必要に応じて `metrics/*.json`
- 必要なら `input_run_set` に対応する `runtime_validation_summary.yaml` / `conformance_review_result.yaml`

を読む intake loader を実装する。

完了条件:

- paper-interface が runtime raw artifact を再読せずに必要 input を得られる
- validation summary を読んでも、それが claim の primary evidence に昇格しない

### Task 3: Implement `claim_map.json`

目的:

- claim と evidence source の central mapping artifact を作る

作業:

- `paper/reports/claim_map.json`

の writer を実装する。

含めること:

- `claim_id`
- `claim_text`
- `supporting_artifact_refs`
- `maturity_label`
- `caveat_refs`
- `provenance_refs`

完了条件:

- どの claim がどの evaluation output に支えられているか追跡できる

### Task 4: Implement `evidence_register.json`

目的:

- evidence maturity と provenance を paper-facing registry にする

作業:

- `paper/reports/evidence_register.json`

の writer を実装する。

含めること:

- `artifact_ref`
- `source_analysis_manifest_ref`
- `input_run_set_ref`
- `maturity_label`
- `caveat_refs`
- `generated_at`

完了条件:

- local / imported / exploratory / preliminary distinctionを evaluation provenance 経由で保持できる

### Task 5: Implement table source bundles

目的:

- table 用 source data contract を concrete artifact にする

作業:

- `paper/tables/table_source_bundle.json`

の writer を実装する。

含めること:

- `table_id`
- `source_artifact_refs`
- `field_projection`
- `maturity_label`
- `caveat_refs`

完了条件:

- 表生成前の source selection と field projection が machine-readable に残る

### Task 6: Implement figure source bundles

目的:

- figure 用 source data contract を concrete artifact にする

作業:

- `paper/figures/figure_source_bundle.json`

の writer を実装する。

含めること:

- `figure_id`
- `source_artifact_refs`
- `plot_contract`
- `maturity_label`
- `caveat_refs`

完了条件:

- plot grouping / slice / metric selection が machine-readable に残る

### Task 7: Implement paper-facing caveat register

目的:

- evaluation caveat を paper-facing limitation 単位へ再配置する

作業:

- `paper/caveats/paper_caveat_register.json`

の writer を実装する。

含めること:

- `caveat_id`
- `source_caveat_ref`
- `applies_to_claim_refs`
- `applies_to_artifact_refs`
- `limitation_type`
- `narrative_note`

完了条件:

- caveat が報告層で落ちずに残る

### Task 8: Implement `reporting_fragments.json`

目的:

- manuscript 非依存の報告断片を再利用可能にする

作業:

- `paper/reports/reporting_fragments.json`

の writer を実装する。

含めること:

- `fragment_id`
- `fragment_type`
- `source_artifact_refs`
- `maturity_label`
- `caveat_refs`
- `text_stub`

完了条件:

- claim summary / method note / limitation note / comparison summary が structured fragment として残る

### Task 9: Implement methodology-note linkage to adopted changes

目的:

- self-improvement の adopted history を paper convenience に従属させず、必要なら methodology note として参照可能にする

作業:

- adopted change history intake helper
- methodology-note fragment linkage

を optional path として実装する。

制約:

- runtime quality claim の一次根拠としては使わない
- performance claim と methodology note を混同しない

完了条件:

- adopted changes を narrative source として誤用せずに参照できる

### Task 10: Add paper-interface fixtures

目的:

- reporting artifact chain を fixture ベースで検証できるようにする

作業:

- minimal claim map fixture
- mature / preliminary / exploratory evidence fixture
- mixed caveat fixture
- imported evidence provenance fixture

を配置する。

完了条件:

- paper artifact generation が evaluation fixture ベースで試せる

### Task 11: Add paper-interface tests and smoke checks

目的:

- paper-facing artifact が provenance と caveat を保持することを mechanical に確認する

作業:

- claim map traceability test
- evidence register provenance test
- table / figure bundle field test
- caveat retention test
- no silent strengthening test
- methodology-note separation test

を追加する。

完了条件:

- paper-interface が runtime / evaluation を支配せず、consumer として振る舞うことを確認できる

## 4. Downstream Handoff

paper-interface は consumer layer なので、直接の downstream implementation dependency は少ない。完了後に参照される主 artifact は次である。

- `paper/reports/claim_map.json`
- `paper/reports/evidence_register.json`
- `paper/reports/reporting_fragments.json`
- `paper/tables/table_source_bundle.json`
- `paper/figures/figure_source_bundle.json`
- `paper/caveats/paper_caveat_register.json`

## 5. Blocking Dependencies

paper-interface task 着手前の前提:

- evaluation comparison / exclusion / caveat artifact が存在する
- evaluation manifest に analysis provenance が存在する
- imported/local distinction が evaluation provenance で保持される

paper-interface は consumer 終端なので、ここから先の core feature blocking dependency は原則ない。

## 6. Completion Criteria

- claim map と evidence register が生成できる
- table / figure source bundle が生成できる
- caveat が paper-facing artifact で保持される
- imported/local/provisional distinction が reporting artifact に残る
- methodology note と performance claim が混線しない
