#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "pathname"
require_relative "track_runs/spec_track_writer"

options = {
  "adjacent_phase_refs" => [],
  "alignment_refs" => [],
  "operator" => "pending"
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby scripts/write_spec_track_run_artifacts.rb --run-label LABEL --case-id ID --review-mode MODE --reviewed-phase PHASE --reviewed-phase-ref PATH [options]"

  opts.on("--run-label LABEL", "Run label") { |value| options["run_label"] = value }
  opts.on("--case-id ID", "Case id") { |value| options["case_id"] = value }
  opts.on("--review-mode MODE", "Review mode") { |value| options["review_mode"] = value }
  opts.on("--reviewed-phase PHASE", "Reviewed phase") { |value| options["reviewed_phase"] = value }
  opts.on("--reviewed-phase-ref PATH", "Reviewed phase ref path") { |value| options["reviewed_phase_ref"] = value }
  opts.on("--adjacent-ref PATH", "Adjacent phase ref path (repeatable)") { |value| options["adjacent_phase_refs"] << value }
  opts.on("--alignment-ref PATH", "Alignment ref path (repeatable)") { |value| options["alignment_refs"] << value }
  opts.on("--operator NAME", "Operator name") { |value| options["operator"] = value }
  opts.on("--output-root PATH", "Custom output root") { |value| options["output_root"] = value }
  opts.on("--runtime-run-root-base PATH", "Custom runtime run root base") { |value| options["runtime_run_root_base"] = value }
end

parser.parse!(ARGV)

required = %w[run_label case_id review_mode reviewed_phase reviewed_phase_ref]
missing = required.reject { |key| options[key] && !options[key].empty? }
raise OptionParser::MissingArgument, missing.join(", ") unless missing.empty?

repo_root = Pathname(__dir__).join("..").expand_path
writer = DualReviewer::TrackRuns::SpecTrackWriter.new(
  repo_root: repo_root,
  run_label: options.fetch("run_label"),
  case_id: options.fetch("case_id"),
  review_mode: options.fetch("review_mode"),
  reviewed_phase: options.fetch("reviewed_phase"),
  reviewed_phase_ref: options.fetch("reviewed_phase_ref"),
  adjacent_phase_refs: options.fetch("adjacent_phase_refs"),
  alignment_refs: options.fetch("alignment_refs"),
  operator: options.fetch("operator"),
  output_root: options["output_root"],
  runtime_run_root_base: options["runtime_run_root_base"]
)

paths = writer.write_all
puts "wrote #{paths.fetch('run_manifest')}"
puts "artifact_count=#{paths.length}"
