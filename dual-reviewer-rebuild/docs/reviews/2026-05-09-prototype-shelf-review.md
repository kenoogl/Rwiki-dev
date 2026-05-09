# 2026-05-09 prototype shelf review

## 1. review scope

- review type: `implementation conformance review`
- reviewed branch: `codex/dual-reviewer-foundation`
- reviewed commit: `d20d08c`
- reviewed features:
  - `dual-reviewer-runtime`
  - `dual-reviewer-evaluation`
  - `dual-reviewer-self-improvement`
  - `dual-reviewer-paper-interface`
- review focus:
  - approval / adoption boundary
  - replay input resolution boundary
  - caveat / evidence traceability

## 2. validation rerun

次を再実行し、いずれも pass を確認した。

- `ruby scripts/validate_evaluation_pipeline.rb`
- `ruby scripts/validate_self_improvement_pipeline.rb`
- `ruby scripts/validate_paper_interface_pipeline.rb`

この review は smoke pass 後の nonconformance 棚卸しである。

## 3. findings

### Finding 1 `P1`

- title: adoption gate allows unapproved proposals to become `adopted`
- file: `scripts/self_improvement/history_registry.rb`
- references:
  - `scripts/self_improvement/history_registry.rb:37`
  - `scripts/self_improvement/history_registry.rb:102`
  - `.kiro/specs/dual-reviewer-self-improvement/design.md:302`
- description:
  - `record_adoption` は `ensure_approved_or_tested!` に依存しているが、
    helper 側で `draft` と `awaiting_test` を adoption 対象に含めている。
  - spec では `adopted` 条件として `approved`、required test artifact、
    repo change と version update の結びつきが必要である。
- impact:
  - human approval を経ていない runtime-affecting proposal が adoption register に入る
  - `approved` と `adopted` の分離が崩れる
- recommended action: `fix-before-next-feature`
- handback assessment: `A`
- status: `open`

### Finding 2 `P2`

- title: replay input resolution is fixture-name-bound for local runs
- file: `scripts/self_improvement/replay_input_resolver.rb`
- references:
  - `scripts/self_improvement/replay_input_resolver.rb:64`
- description:
  - `central_local_run` の探索が `experiments/runs/<run_id>` と
    4 つの固定 fixture path に限定されている。
  - 新しい local fixture や別配置の local run では `unresolved_run_root` が起きる。
- impact:
  - replay readiness が false negative を返す
  - fixture 拡張時に prototype が silent に brittle になる
- recommended action: `fix-in-current-branch`
- handback assessment: `A`
- status: `open`

### Finding 3 `P2`

- title: evidence-to-caveat linkage relies on basename heuristic
- file: `scripts/paper_interface/evidence_register_builder.rb`
- references:
  - `scripts/paper_interface/evidence_register_builder.rb:46`
- description:
  - caveat ref に artifact basename が含まれるかで artifact-specific caveat を判定している。
  - 現在の caveat ref は caveat code 中心であり、artifact scope を構造的に表していない。
- impact:
  - `evidence_register.json` の caveat 付与が不安定
  - paper-interface の traceability が heuristic 依存になる
- recommended action: `fix-in-current-branch`
- handback assessment: `A`
- status: `open`

## 4. metric snapshot

- `conformance_findings_count`: `3`
- `severity_weighted_finding_score`: `7`
- `post_smoke_nonconformance_count`: `3`
- `fixture_bound_resolution_count`: `1`
- `heuristic_linkage_count`: `1`
- `review_artifact_presence_rate`: `1.0`
- `finding_to_signal_link_rate`: `1.0`

## 5. disposition summary

- immediate disposition:
  - Finding 1 は次 feature へ進む前に修正する
  - Finding 2 と Finding 3 は同一 branch で順次修正する
- evidence linkage:
  - 3 finding とも `implementation-signal-register` に signal として起票する
- next action:
  - implementation fix
  - fix 後に conformance review short rerun
