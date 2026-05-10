#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "pathname"
require_relative "track_runs/intent_track_writer"

options = {
  "supporting_refs" => [],
  "operator" => "pending",
  "objective" => "intent-track first-run"
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby scripts/write_intent_track_run_artifacts.rb --run-label LABEL --case-id ID --review-mode MODE --intent-ref PATH [options]"

  opts.on("--run-label LABEL", "Run label") { |value| options["run_label"] = value }
  opts.on("--case-id ID", "Case id") { |value| options["case_id"] = value }
  opts.on("--review-mode MODE", "Review mode") { |value| options["review_mode"] = value }
  opts.on("--intent-ref PATH", "Intent ref path") { |value| options["intent_ref"] = value }
  opts.on("--supporting-ref PATH", "Supporting ref path (repeatable)") { |value| options["supporting_refs"] << value }
  opts.on("--operator NAME", "Operator name") { |value| options["operator"] = value }
  opts.on("--objective TEXT", "Objective text") { |value| options["objective"] = value }
  opts.on("--output-root PATH", "Custom output root") { |value| options["output_root"] = value }
  opts.on("--runtime-run-root-base PATH", "Custom runtime run root base") { |value| options["runtime_run_root_base"] = value }
end

parser.parse!(ARGV)

required = %w[run_label case_id review_mode intent_ref]
missing = required.reject { |key| options[key] && !options[key].empty? }
raise OptionParser::MissingArgument, missing.join(", ") unless missing.empty?

repo_root = Pathname(__dir__).join("..").expand_path
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
  runtime_run_root_base: options["runtime_run_root_base"]
)

paths = writer.write_all
puts "wrote #{paths.fetch('run_manifest')}"
puts "artifact_count=#{paths.length}"
