# Analysis Run-Set Selection Policy

この文書は、`experiments/analysis/` に入れる run set をどう選ぶかを固定するための運用メモである。

## 目的

- analysis population を再現可能にする
- paper-interface と self-improvement が同じ母集団を見るようにする
- protocol summary coverage の有無を selection 条件に組み込む

## 基本方針

analysis に入れる run は、単に `valid` そうに見えるものではなく、次の条件を満たすものを優先する。

1. `run_status=closed`
2. evaluation standard intake が complete
3. `validator_status=passed`
4. `human_signoff_status` が終端状態
5. protocol-facing summary artifact が存在する
6. 同一 `case_id` / `phase_profile` の中で比較したい treatment 群が揃っている

ここでいう protocol-facing summary artifact は次を指す。

- implementation: `conformance_review_result.yaml`
- intent/spec: `runtime_validation_summary.yaml`

## 非推奨の run

次の run は、分析対象に入れないか、少なくとも default population からは外す。

- `run_status != closed`
- required artifact 欠落 run
- protocol summary coverage が無い legacy run
- case / phase / treatment の比較目的と一致しない run

## 現在の推奨 selection

2026-05-11 時点では、paper-interface optional intake の実運用確認用として、次の run set を基準にする。

- `case_id = F2-heat3d-julia`
- `track = implementation`
- `phase_profile = tasks`
- treatments:
  - `single`
  - `dual`
  - `dual+judgment`

この集合は protocol-backed であり、`runtime_validation_summary_coverage.covered_run_count = input_run_count` を満たす。

対応する selection manifest は [F2-heat3d-julia-selection.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/analysis/manifests/F2-heat3d-julia-selection.yaml:1) で管理する。

## Scripted Workflow

run set の選定は [select_evaluation_run_set.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/select_evaluation_run_set.rb:1) を使う。

例:

```sh
ruby dual-reviewer-rebuild/scripts/select_evaluation_run_set.rb \
  --track implementation \
  --case-id F2-heat3d-julia \
  --phase-profile tasks
```

analysis 再構築は [rebuild_evaluation_analysis_from_runs.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/rebuild_evaluation_analysis_from_runs.rb:1) を使う。

入力には selector が返した `runtime_run_roots` を渡す。

例:

```sh
ruby dual-reviewer-rebuild/scripts/select_evaluation_run_set.rb \
  --track implementation \
  --case-id F2-heat3d-julia \
  --phase-profile tasks \
  > /tmp/f2-heat3d-run-set.json

ruby dual-reviewer-rebuild/scripts/rebuild_evaluation_analysis_from_runs.rb \
  --selection-json /tmp/f2-heat3d-run-set.json
```

analysis と paper artifact をまとめて更新する場合は [refresh_analysis_and_paper_from_selection.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/refresh_analysis_and_paper_from_selection.rb:1) を使う。

```sh
ruby dual-reviewer-rebuild/scripts/refresh_analysis_and_paper_from_selection.rb \
  --track implementation \
  --case-id F2-heat3d-julia \
  --phase-profile tasks
```

manifest ベースで回す場合:

```sh
ruby dual-reviewer-rebuild/scripts/refresh_analysis_and_paper_from_selection.rb \
  --selection-manifest dual-reviewer-rebuild/experiments/analysis/manifests/F2-heat3d-julia-selection.yaml
```

## 今後の拡張

- case ごとの preferred population policy を manifest 化する
- intent/spec/implementation を横断した narrative analysis population を定義する
