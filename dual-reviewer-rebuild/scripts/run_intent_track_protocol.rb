#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "optparse"
require "pathname"
require_relative "track_runs/intent_track_writer"

repo_root = Pathname(__dir__).join("..").expand_path

options = {
  "run_label" => "F1-intent-track-single",
  "case_id" => "F1-intent-dual-reviewer-rebuild",
  "review_mode" => "single_review",
  "intent_ref" => ".kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-paper-plan.md",
  "supporting_refs" => [
    "dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md",
    "dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md",
    "dual-reviewer-rebuild/docs/coordination/implementation-conformance-review.md"
  ],
  "operator" => "pending",
  "objective" => "intent bootstrap pilot",
  "case_manifest_ref" => "experiments/protocols/case_manifests/F1-intent-dual-reviewer-rebuild.yaml"
}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby scripts/run_intent_track_protocol.rb [options]"
  opts.on("--run-label LABEL", "Run label") { |value| options["run_label"] = value }
  opts.on("--case-id ID", "Case id") { |value| options["case_id"] = value }
  opts.on("--review-mode MODE", "Review mode") { |value| options["review_mode"] = value }
  opts.on("--intent-ref PATH", "Intent ref path") { |value| options["intent_ref"] = value }
  opts.on("--supporting-ref PATH", "Supporting ref path (repeatable)") { |value| options["supporting_refs"] << value }
  opts.on("--operator NAME", "Operator name") { |value| options["operator"] = value }
  opts.on("--objective TEXT", "Objective text") { |value| options["objective"] = value }
  opts.on("--case-manifest-ref PATH", "Case manifest ref path") { |value| options["case_manifest_ref"] = value }
  opts.on("--output-root PATH", "Custom output root") { |value| options["output_root"] = value }
  opts.on("--runtime-run-root-base PATH", "Custom runtime run root base") { |value| options["runtime_run_root_base"] = value }
end.parse!(ARGV)

writer = DualReviewer::TrackRuns::IntentTrackWriter.new(
  repo_root: repo_root,
  run_label: options.fetch("run_label"),
  case_id: options.fetch("case_id"),
  review_mode: options.fetch("review_mode"),
  intent_ref: options.fetch("intent_ref"),
  supporting_refs: options.fetch("supporting_refs"),
  operator: options.fetch("operator"),
  objective: options.fetch("objective"),
  output_root: options["output_root"],
  case_manifest_ref: options["case_manifest_ref"],
  runtime_run_root_base: options["runtime_run_root_base"]
)

puts JSON.pretty_generate(
  "track" => "intent",
  "run_label" => options.fetch("run_label"),
  "case_id" => options.fetch("case_id"),
  "review_mode" => options.fetch("review_mode"),
  "paths" => writer.write_all.transform_values(&:to_s)
)
