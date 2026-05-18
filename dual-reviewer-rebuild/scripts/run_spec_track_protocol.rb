#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "optparse"
require "pathname"
require_relative "track_runs/spec_track_writer"

# Task 11 / B: spec track protocol wrapper（新 API 整合・スクラッチ）
# 根拠: tasks.md Task 2「Generic Protocol Entrypoint Rule」。
#   - case_manifest_ref あり → writer 経由で controller が manifest を読む
#   - なし → track 別必須入力を明示必須（ここで検証）
#   - どちらも無し → fail fast
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
  opts.on("--run-label LABEL", "Run label") { |v| options["run_label"] = v }
  opts.on("--case-id ID", "Case id") { |v| options["case_id"] = v }
  opts.on("--review-mode MODE", "Review mode") { |v| options["review_mode"] = v }
  opts.on("--reviewed-phase PHASE", "Reviewed phase") { |v| options["reviewed_phase"] = v }
  opts.on("--reviewed-phase-ref PATH", "Reviewed phase ref path") { |v| options["reviewed_phase_ref"] = v }
  opts.on("--adjacent-ref PATH", "Adjacent phase ref path (repeatable)") { |v| options["adjacent_phase_refs"] << v }
  opts.on("--alignment-ref PATH", "Alignment ref path (repeatable)") { |v| options["alignment_refs"] << v }
  opts.on("--case-manifest-ref PATH", "Case manifest ref path") { |v| options["case_manifest_ref"] = v }
  opts.on("--operator NAME", "Operator name") { |v| options["operator"] = v }
  opts.on("--runtime-run-root-base PATH", "Custom runtime run root base") { |v| options["runtime_run_root_base"] = v }
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
  runtime_run_root_base: options["runtime_run_root_base"]
)

out = writer.write_all

puts JSON.pretty_generate(
  "track" => "spec",
  "run_label" => options.fetch("run_label"),
  "case_id" => options["case_id"],
  "review_mode" => options.fetch("review_mode"),
  "reviewed_phase" => options["reviewed_phase"],
  "run_id" => out.fetch("run_id"),
  "run_status" => out.fetch("run_status"),
  "paths" => out.reject { |k, _| %w[run_id run_status].include?(k) }
                .transform_values(&:to_s)
)
