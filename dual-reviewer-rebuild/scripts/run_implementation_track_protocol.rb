#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "optparse"
require "pathname"
require_relative "track_runs/implementation_track_runner"

repo_root = Pathname(__dir__).join("..").expand_path

options = {
  "run_label" => "implementation-track-run",
  "review_mode" => "single_review",
  "upstream_spec_refs" => [],
  "governance_refs" => [],
  "operator" => "pending",
  "case_manifest_ref" => nil
}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby scripts/run_implementation_track_protocol.rb [options]"
  opts.on("--run-label LABEL", "Run label") { |value| options["run_label"] = value }
  opts.on("--case-id ID", "Case id") { |value| options["case_id"] = value }
  opts.on("--review-mode MODE", "Review mode") { |value| options["review_mode"] = value }
  opts.on("--snapshot-ref PATH", "Implementation snapshot ref path") { |value| options["implementation_snapshot_ref"] = value }
  opts.on("--upstream-spec-ref PATH", "Upstream spec ref path (repeatable)") { |value| options["upstream_spec_refs"] << value }
  opts.on("--governance-ref PATH", "Governance ref path (repeatable)") { |value| options["governance_refs"] << value }
  opts.on("--case-manifest-ref PATH", "Case manifest ref path") { |value| options["case_manifest_ref"] = value }
  opts.on("--operator NAME", "Operator name") { |value| options["operator"] = value }
  opts.on("--phase-profile NAME", "Phase profile") { |value| options["phase_profile"] = value }
  opts.on("--target-id ID", "Runtime target id") { |value| options["target_id"] = value }
  opts.on("--target-artifact-hash HASH", "Target artifact hash") { |value| options["target_artifact_hash"] = value }
  opts.on("--protocol-output-root PATH", "Custom protocol output root") { |value| options["protocol_output_root"] = value }
  opts.on("--runtime-run-root-base PATH", "Custom runtime run root base") { |value| options["runtime_run_root_base"] = value }
  opts.on("--export-root-base PATH", "Custom export root base") { |value| options["export_root_base"] = value }
end.parse!(ARGV)

if options["case_manifest_ref"].nil?
  required = %w[case_id implementation_snapshot_ref phase_profile target_id]
  missing = required.select { |key| options[key].nil? || options[key].to_s.empty? }
  missing << "upstream_spec_refs" if options["upstream_spec_refs"].empty?
  unless missing.empty?
    warn "missing required options without --case-manifest-ref: #{missing.join(', ')}"
    exit 1
  end
end

runner = DualReviewer::TrackRuns::ImplementationTrackRunner.new(
  repo_root: repo_root,
  run_label: options.fetch("run_label"),
  case_id: options["case_id"],
  review_mode: options.fetch("review_mode"),
  implementation_snapshot_ref: options["implementation_snapshot_ref"],
  upstream_spec_refs: options.fetch("upstream_spec_refs"),
  governance_refs: options.fetch("governance_refs"),
  case_manifest_ref: options["case_manifest_ref"],
  operator: options.fetch("operator"),
  phase_profile: options["phase_profile"],
  target_id: options["target_id"],
  target_artifact_hash: options["target_artifact_hash"],
  protocol_output_root: options["protocol_output_root"],
  runtime_run_root_base: options["runtime_run_root_base"],
  export_root_base: options["export_root_base"]
)

result = runner.run_all

puts JSON.pretty_generate(
  "track" => "implementation",
  "run_label" => options.fetch("run_label"),
  "case_id" => options["case_id"],
  "review_mode" => options.fetch("review_mode"),
  "run_id" => result.fetch("run_id"),
  "bundle_id" => result.fetch("bundle_id"),
  "protocol_paths" => result.fetch("protocol_paths"),
  "runtime_paths" => result.fetch("runtime_paths")
)
