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

batch_root = repo_root.join("experiments/protocols/implementation-track-runs/F3-iot-arduino")
runtime_run_root_base = batch_root.join("runtime-runs")
export_root_base = batch_root.join("exports")
protocol_output_root = batch_root.join("protocol-runs")

shared_options = {
  repo_root: repo_root,
  case_id: "F3-iot-arduino",
  implementation_snapshot_ref: ".kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-first-snapshot.md",
  upstream_spec_refs: [
    ".kiro/specs/iot-arduino-spec/intent.md",
    ".kiro/specs/iot-arduino-loop-outside-control/requirements.md",
    ".kiro/specs/iot-arduino-watering-loop/requirements.md",
    ".kiro/specs/iot-arduino-loop-outside-control/design.md",
    ".kiro/specs/iot-arduino-watering-loop/design.md",
    ".kiro/specs/iot-arduino-loop-outside-control/tasks.md",
    ".kiro/specs/iot-arduino-watering-loop/tasks.md",
    "/Users/Daily/Development/DR-IoT/intent.md",
    "/Users/Daily/Development/DR-IoT/仕様.md"
  ],
  governance_refs: [
    "dual-reviewer-rebuild/docs/coordination/implementation-conformance-review.md",
    "dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md",
    "dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md",
    ".kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-review-acquisition-preparation.md",
    ".kiro/specs/iot-arduino-spec/reviews/review-acquisition-gate-summary.md"
  ],
  case_manifest_ref: "experiments/protocols/case_manifests/F3-iot-arduino.yaml",
  operator: "iot-arduino-gate-approved",
  phase_profile: "tasks",
  target_id: "implementation:iot-arduino-c",
  protocol_output_root: protocol_output_root,
  runtime_run_root_base: runtime_run_root_base,
  export_root_base: export_root_base
}.freeze

single_runner = DualReviewer::TrackRuns::ImplementationTrackRunner.new(
  **shared_options,
  run_label: "F3-iot-arduino-single",
  review_mode: "single_review"
)

dual_only_runner = DualReviewer::TrackRuns::ImplementationTrackRunner.new(
  **shared_options,
  run_label: "F3-iot-arduino-dual-only",
  review_mode: "dual_review"
)

dual_runner = DualReviewer::TrackRuns::ImplementationTrackRunner.new(
  **shared_options,
  run_label: "F3-iot-arduino-dual",
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
  "batch_id" => "F3-iot-arduino",
  "generated_at" => Time.now.utc.iso8601,
  "scope" => "iot-arduino gate-approved implementation acquisition",
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
    "This batch evaluates a spec-origin Arduino skeleton snapshot, not a hardware-verified implementation.",
    "Review evidence is bounded to the gate-approved snapshot note and approved upstream specs; compile-time and device behavior remain out of scope for this acquisition."
  ]
}

batch_root.mkpath
(batch_root.join("batch_manifest.yaml")).write(
  YAML.dump(
    {
      "batch_id" => "F3-iot-arduino",
      "scope" => "iot-arduino gate-approved implementation acquisition",
      "protocol_output_root" => protocol_output_root.relative_path_from(repo_root).to_s,
      "runtime_run_root_base" => runtime_run_root_base.relative_path_from(repo_root).to_s,
      "export_root_base" => export_root_base.relative_path_from(repo_root).to_s,
      "run_labels" => [
        "F3-iot-arduino-single",
        "F3-iot-arduino-dual-only",
        "F3-iot-arduino-dual"
      ]
    }
  )
)
(batch_root.join("comparison_summary.json")).write(JSON.pretty_generate(comparison_summary))

puts JSON.pretty_generate(
  {
    "batch_id" => "F3-iot-arduino",
    "batch_root" => batch_root.to_s,
    "single_run_id" => single_result.fetch("run_id"),
    "dual_only_run_id" => dual_only_result.fetch("run_id"),
    "dual_run_id" => dual_result.fetch("run_id"),
    "comparison_summary_path" => batch_root.join("comparison_summary.json").to_s
  }
)
