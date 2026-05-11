#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "time"
require "yaml"
require_relative "track_runs/implementation_track_runner"
require_relative "evaluation/local_run_loader"
require_relative "evaluation/metric_extractor"

repo_root = Pathname(__dir__).join("..").expand_path

batch_root = repo_root.join("experiments/protocols/implementation-track-runs/F2-heat3d-julia")
runtime_run_root_base = batch_root.join("runtime-runs")
export_root_base = batch_root.join("exports")
protocol_output_root = batch_root.join("protocol-runs")

shared_options = {
  repo_root: repo_root,
  case_id: "F2-heat3d-julia",
  implementation_snapshot_ref: ".kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-julia-implementation-phase-first-snapshot.md",
  upstream_spec_refs: [
    ".kiro/specs/heat3d-spec/intent.md",
    ".kiro/specs/heat3d-spec/brief.md",
    ".kiro/specs/heat3d-spec/research.md",
    ".kiro/specs/heat3d-foundation/requirements.md",
    ".kiro/specs/heat3d-linear-solver/requirements.md",
    ".kiro/specs/heat3d-case-model/requirements.md",
    ".kiro/specs/heat3d-main/requirements.md",
    ".kiro/specs/heat3d-foundation/design.md",
    ".kiro/specs/heat3d-linear-solver/design.md",
    ".kiro/specs/heat3d-case-model/design.md",
    ".kiro/specs/heat3d-main/design.md",
    ".kiro/specs/heat3d-foundation/tasks.md",
    ".kiro/specs/heat3d-linear-solver/tasks.md",
    ".kiro/specs/heat3d-case-model/tasks.md",
    ".kiro/specs/heat3d-main/tasks.md",
    "/Users/Daily/Development/DR-heat3d/spec_seed/thermal_simulator_spec.md"
  ],
  governance_refs: [
    "dual-reviewer-rebuild/docs/coordination/implementation-conformance-review.md",
    "dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md",
    "dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md",
    ".kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-review-acquisition-preparation.md",
    ".kiro/specs/heat3d-spec/reviews/review-acquisition-gate-summary.md"
  ],
  case_manifest_ref: "experiments/protocols/case_manifests/F2-heat3d-julia.yaml",
  operator: "heat3d-gate-approved",
  phase_profile: "tasks",
  target_id: "implementation:heat3d-julia",
  protocol_output_root: protocol_output_root,
  runtime_run_root_base: runtime_run_root_base,
  export_root_base: export_root_base
}.freeze

single_runner = DualReviewer::TrackRuns::ImplementationTrackRunner.new(
  **shared_options,
  run_label: "F2-heat3d-julia-single",
  review_mode: "single_review"
)

dual_only_runner = DualReviewer::TrackRuns::ImplementationTrackRunner.new(
  **shared_options,
  run_label: "F2-heat3d-julia-dual-only",
  review_mode: "dual_review"
)

dual_runner = DualReviewer::TrackRuns::ImplementationTrackRunner.new(
  **shared_options,
  run_label: "F2-heat3d-julia-dual",
  review_mode: "dual_reviewer_workflow"
)

single_result = single_runner.run_all
dual_only_result = dual_only_runner.run_all
dual_result = dual_runner.run_all

loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: repo_root)
extractor = DualReviewer::Evaluation::MetricExtractor.new

single_metrics = extractor.extract_from_run_intake(
  run_intake: loader.load_run(run_root: Pathname(single_result.fetch("runtime_paths").fetch("review_artifact")).dirname)
)
dual_only_metrics = extractor.extract_from_run_intake(
  run_intake: loader.load_run(run_root: Pathname(dual_only_result.fetch("runtime_paths").fetch("review_artifact")).dirname)
)
dual_metrics = extractor.extract_from_run_intake(
  run_intake: loader.load_run(run_root: Pathname(dual_result.fetch("runtime_paths").fetch("review_artifact")).dirname)
)

comparison_summary = {
  "batch_id" => "F2-heat3d-julia",
  "generated_at" => Time.now.utc.iso8601,
  "scope" => "heat3d gate-approved implementation acquisition",
  "comparison_modes" => [
    {
      "review_mode" => "single_review",
      "run_id" => single_result.fetch("run_id"),
      "bundle_id" => single_result.fetch("bundle_id"),
      "run_metrics" => single_metrics.fetch("run_metrics"),
      "finding_metrics" => single_metrics.fetch("finding_metrics")
    },
    {
      "review_mode" => "dual_review",
      "run_id" => dual_only_result.fetch("run_id"),
      "bundle_id" => dual_only_result.fetch("bundle_id"),
      "run_metrics" => dual_only_metrics.fetch("run_metrics"),
      "finding_metrics" => dual_only_metrics.fetch("finding_metrics")
    },
    {
      "review_mode" => "dual_reviewer_workflow",
      "run_id" => dual_result.fetch("run_id"),
      "bundle_id" => dual_result.fetch("bundle_id"),
      "run_metrics" => dual_metrics.fetch("run_metrics"),
      "finding_metrics" => dual_metrics.fetch("finding_metrics")
    }
  ],
  "comparison_observations" => {
    "single_total_findings" => single_metrics.dig("run_metrics", "total_findings"),
    "dual_only_total_findings" => dual_only_metrics.dig("run_metrics", "total_findings"),
    "dual_total_findings" => dual_metrics.dig("run_metrics", "total_findings"),
    "dual_only_minus_single_findings" => dual_only_metrics.dig("run_metrics", "total_findings") - single_metrics.dig("run_metrics", "total_findings"),
    "dual_minus_single_findings" => dual_metrics.dig("run_metrics", "total_findings") - single_metrics.dig("run_metrics", "total_findings"),
    "dual_plus_judgment_minus_dual_only_findings" => dual_metrics.dig("run_metrics", "total_findings") - dual_only_metrics.dig("run_metrics", "total_findings"),
    "dual_only_has_adversarial_role" => dual_only_metrics.dig("finding_metrics", "source_role_distribution", "adversarial_reviewer").to_i.positive?,
    "dual_has_adversarial_role" => dual_metrics.dig("finding_metrics", "source_role_distribution", "adversarial_reviewer").to_i.positive?
  },
  "caveats" => [
    "Intent Track and Spec Track are not part of this implementation batch, but approved requirements/design/tasks are included as upstream review inputs.",
    "Implementation findings are generated by a source-driven heuristic runtime layer for the heat3d acquisition run; replace this layer before claiming main-evidence-grade review quality."
  ]
}

batch_root.mkpath
(batch_root.join("batch_manifest.yaml")).write(
  YAML.dump(
    {
      "batch_id" => "F2-heat3d-julia",
      "scope" => "heat3d gate-approved implementation acquisition",
      "protocol_output_root" => protocol_output_root.relative_path_from(repo_root).to_s,
      "runtime_run_root_base" => runtime_run_root_base.relative_path_from(repo_root).to_s,
      "export_root_base" => export_root_base.relative_path_from(repo_root).to_s,
      "run_labels" => [
        "F2-heat3d-julia-single",
        "F2-heat3d-julia-dual-only",
        "F2-heat3d-julia-dual"
      ]
    }
  )
)
(batch_root.join("comparison_summary.json")).write(JSON.pretty_generate(comparison_summary))

puts JSON.pretty_generate(
  {
    "batch_id" => "F2-heat3d-julia",
    "batch_root" => batch_root.to_s,
    "single_run_id" => single_result.fetch("run_id"),
    "dual_only_run_id" => dual_only_result.fetch("run_id"),
    "dual_run_id" => dual_result.fetch("run_id"),
    "comparison_summary_path" => batch_root.join("comparison_summary.json").to_s
  }
)
