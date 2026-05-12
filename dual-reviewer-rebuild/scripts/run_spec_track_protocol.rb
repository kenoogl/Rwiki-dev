#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "optparse"
require "pathname"
require_relative "track_runs/spec_track_writer"

repo_root = Pathname(__dir__).join("..").expand_path

options = {
  "run_label" => "spec-track-run",
  "review_mode" => "single_review",
  "adjacent_phase_refs" => [],
  "alignment_refs" => [],
  "case_manifest_ref" => nil,
  "operator" => "pending"
}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby scripts/run_spec_track_protocol.rb [options]"
  opts.on("--run-label LABEL", "Run label") { |value| options["run_label"] = value }
  opts.on("--case-id ID", "Case id") { |value| options["case_id"] = value }
  opts.on("--review-mode MODE", "Review mode") { |value| options["review_mode"] = value }
  opts.on("--reviewed-phase PHASE", "Reviewed phase") { |value| options["reviewed_phase"] = value }
  opts.on("--reviewed-phase-ref PATH", "Reviewed phase ref path") { |value| options["reviewed_phase_ref"] = value }
  opts.on("--adjacent-ref PATH", "Adjacent phase ref path (repeatable)") { |value| options["adjacent_phase_refs"] << value }
  opts.on("--alignment-ref PATH", "Alignment ref path (repeatable)") { |value| options["alignment_refs"] << value }
  opts.on("--case-manifest-ref PATH", "Case manifest ref path") { |value| options["case_manifest_ref"] = value }
  opts.on("--operator NAME", "Operator name") { |value| options["operator"] = value }
  opts.on("--output-root PATH", "Custom output root") { |value| options["output_root"] = value }
  opts.on("--runtime-run-root-base PATH", "Custom runtime run root base") { |value| options["runtime_run_root_base"] = value }
end.parse!(ARGV)

if options["case_manifest_ref"].nil?
  required = %w[case_id reviewed_phase reviewed_phase_ref]
  missing = required.select { |key| options[key].nil? || options[key].to_s.empty? }
  unless missing.empty?
    warn "missing required options without --case-manifest-ref: #{missing.join(', ')}"
    exit 1
  end
end

writer = DualReviewer::TrackRuns::SpecTrackWriter.new(
  repo_root: repo_root,
  run_label: options.fetch("run_label"),
  case_id: options["case_id"],
  review_mode: options.fetch("review_mode"),
  reviewed_phase: options["reviewed_phase"],
  reviewed_phase_ref: options["reviewed_phase_ref"],
  adjacent_phase_refs: options.fetch("adjacent_phase_refs"),
  alignment_refs: options.fetch("alignment_refs"),
  case_manifest_ref: options["case_manifest_ref"],
  operator: options.fetch("operator"),
  output_root: options["output_root"],
  runtime_run_root_base: options["runtime_run_root_base"]
)

puts JSON.pretty_generate(
  "track" => "spec",
  "run_label" => options.fetch("run_label"),
  "case_id" => options["case_id"],
  "review_mode" => options.fetch("review_mode"),
  "reviewed_phase" => options["reviewed_phase"],
  "paths" => writer.write_all.transform_values(&:to_s)
)
