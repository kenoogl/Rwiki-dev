#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "optparse"
require "pathname"
require_relative "track_runs/implementation_track_runner"

# Task 11 / B: implementation track protocol wrapper（新 API 整合・スクラッチ）
# 根拠: tasks.md Task 2「Generic Protocol Entrypoint Rule」。
#   - case_manifest_ref あり → runner 経由で controller が manifest を読む
#   - なし → track 別必須入力を明示必須（ここで検証）
#   - どちらも無し → fail fast
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
  opts.on("--run-label LABEL", "Run label") { |v| options["run_label"] = v }
  opts.on("--case-id ID", "Case id") { |v| options["case_id"] = v }
  opts.on("--review-mode MODE", "Review mode") { |v| options["review_mode"] = v }
  opts.on("--snapshot-ref PATH", "Implementation snapshot ref path") { |v| options["implementation_snapshot_ref"] = v }
  opts.on("--upstream-spec-ref PATH", "Upstream spec ref path (repeatable)") { |v| options["upstream_spec_refs"] << v }
  opts.on("--governance-ref PATH", "Governance ref path (repeatable)") { |v| options["governance_refs"] << v }
  opts.on("--case-manifest-ref PATH", "Case manifest ref path") { |v| options["case_manifest_ref"] = v }
  opts.on("--operator NAME", "Operator name") { |v| options["operator"] = v }
  opts.on("--phase-profile NAME", "Phase profile") { |v| options["phase_profile"] = v }
  opts.on("--target-id ID", "Runtime target id") { |v| options["target_id"] = v }
  opts.on("--runtime-run-root-base PATH", "Custom runtime run root base") { |v| options["runtime_run_root_base"] = v }
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
  runtime_run_root_base: options["runtime_run_root_base"]
)

result = runner.run_all

puts JSON.pretty_generate(
  "track" => "implementation",
  "run_label" => options.fetch("run_label"),
  "case_id" => options["case_id"],
  "review_mode" => options.fetch("review_mode"),
  "run_id" => result.fetch("run_id"),
  "run_status" => result.fetch("run_status"),
  "treatment" => result.fetch("treatment"),
  "runtime_paths" => result.fetch("runtime_paths")
)
