#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "optparse"
require "pathname"
require_relative "track_runs/spec_track_writer"

repo_root = Pathname(__dir__).join("..").expand_path

options = {
  "run_label" => "F1-spec-track-single",
  "case_id" => "F1-spec-phase-field-reverse-spec",
  "review_mode" => "single_review",
  "reviewed_phase" => "tasks",
  "reviewed_phase_ref" => ".kiro/specs/phase-field-reverse-spec/tasks.md",
  "adjacent_phase_refs" => [
    ".kiro/specs/phase-field-reverse-spec/requirements.md",
    ".kiro/specs/phase-field-reverse-spec/design.md"
  ],
  "alignment_refs" => [],
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
  opts.on("--operator NAME", "Operator name") { |value| options["operator"] = value }
  opts.on("--output-root PATH", "Custom output root") { |value| options["output_root"] = value }
end.parse!(ARGV)

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
  output_root: options["output_root"]
)

puts JSON.pretty_generate(
  "track" => "spec",
  "run_label" => options.fetch("run_label"),
  "case_id" => options.fetch("case_id"),
  "review_mode" => options.fetch("review_mode"),
  "reviewed_phase" => options.fetch("reviewed_phase"),
  "paths" => writer.write_all.transform_values(&:to_s)
)
