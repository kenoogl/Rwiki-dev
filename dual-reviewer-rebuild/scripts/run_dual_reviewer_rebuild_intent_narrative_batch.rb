#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "time"
require "yaml"
require_relative "track_runs/intent_track_writer"

repo_root = Pathname(__dir__).join("..").expand_path

batch_id = "F1-intent-dual-reviewer-rebuild-narrative"
batch_root = repo_root.join("experiments/protocols/intent-track-runs", batch_id)
output_root = batch_root.join("protocol-runs")
runtime_run_root_base = batch_root.join("runtime-runs")

shared_options = {
  repo_root: repo_root,
  case_id: "F1-intent-dual-reviewer-rebuild",
  intent_ref: ".kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-paper-plan.md",
  supporting_refs: [
    "dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md",
    "dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md",
    "dual-reviewer-rebuild/docs/coordination/implementation-conformance-review.md"
  ],
  operator: "intent-track-narrative-batch",
  objective: "intent bootstrap acquisition for cross-track narrative",
  output_root: output_root,
  case_manifest_ref: "experiments/protocols/case_manifests/F1-intent-dual-reviewer-rebuild.yaml",
  runtime_run_root_base: runtime_run_root_base
}.freeze

single_writer = DualReviewer::TrackRuns::IntentTrackWriter.new(
  **shared_options,
  run_label: "F1-intent-dual-reviewer-rebuild-narrative-single",
  review_mode: "single_review"
)

dual_writer = DualReviewer::TrackRuns::IntentTrackWriter.new(
  **shared_options,
  run_label: "F1-intent-dual-reviewer-rebuild-narrative-dual",
  review_mode: "dual_reviewer_workflow"
)

single_paths = single_writer.write_all
dual_paths = dual_writer.write_all

single_metrics = JSON.parse(single_paths.fetch("phase_metric_snapshot").read)
dual_metrics = JSON.parse(dual_paths.fetch("phase_metric_snapshot").read)
single_trace = YAML.load_file(single_paths.fetch("intent_trace_note"))
dual_trace = YAML.load_file(dual_paths.fetch("intent_trace_note"))

comparison_summary = {
  "batch_id" => batch_id,
  "generated_at" => Time.now.utc.iso8601,
  "scope" => "dual-reviewer-rebuild intent-track narrative batch",
  "comparison_modes" => [
    {
      "review_mode" => "single_review",
      "run_label" => "F1-intent-dual-reviewer-rebuild-narrative-single",
      "metrics" => single_metrics.fetch("metrics"),
      "intent_handback_required" => single_trace.fetch("intent_handback_required"),
      "downstream_propagation_targets" => single_trace.fetch("downstream_propagation_targets"),
      "linked_signal_ids" => YAML.load_file(single_paths.fetch("signal_linkage_note")).fetch("linked_signal_ids")
    },
    {
      "review_mode" => "dual_reviewer_workflow",
      "run_label" => "F1-intent-dual-reviewer-rebuild-narrative-dual",
      "metrics" => dual_metrics.fetch("metrics"),
      "intent_handback_required" => dual_trace.fetch("intent_handback_required"),
      "downstream_propagation_targets" => dual_trace.fetch("downstream_propagation_targets"),
      "linked_signal_ids" => YAML.load_file(dual_paths.fetch("signal_linkage_note")).fetch("linked_signal_ids")
    }
  ],
  "comparison_observations" => {
    "single_intent_review_findings_count" => single_metrics.dig("metrics", "intent_review_findings_count"),
    "dual_intent_review_findings_count" => dual_metrics.dig("metrics", "intent_review_findings_count"),
    "single_intent_handback_count" => single_metrics.dig("metrics", "intent_handback_count"),
    "dual_intent_handback_count" => dual_metrics.dig("metrics", "intent_handback_count"),
    "dual_requires_intent_handback" => dual_trace.fetch("intent_handback_required")
  },
  "caveats" => [
    "This batch is a fresh narrative-connected acquisition and preserves the older pilot batch as separate provenance.",
    "Intent-track outputs remain bootstrap evidence; they do not by themselves claim correct downstream artifact generation."
  ]
}

batch_root.mkpath
(batch_root.join("batch_manifest.yaml")).write(
  YAML.dump(
    {
      "batch_id" => batch_id,
      "scope" => "dual-reviewer-rebuild intent-track narrative batch",
      "output_root" => output_root.relative_path_from(repo_root).to_s,
      "runtime_run_root_base" => runtime_run_root_base.relative_path_from(repo_root).to_s,
      "run_labels" => [
        "F1-intent-dual-reviewer-rebuild-narrative-single",
        "F1-intent-dual-reviewer-rebuild-narrative-dual"
      ]
    }
  )
)
(batch_root.join("comparison_summary.json")).write(JSON.pretty_generate(comparison_summary))

puts JSON.pretty_generate(
  {
    "batch_id" => batch_id,
    "batch_root" => batch_root.to_s,
    "comparison_summary_path" => batch_root.join("comparison_summary.json").to_s
  }
)
