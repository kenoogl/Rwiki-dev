#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "optparse"
require "pathname"
require_relative "track_runs/runtime_session_driver"

# Task 11 / B: run entrypoint（新 controller API 整合・スクラッチ）
# 根拠: tasks.md Task 2「Reference-Free Runtime Entry Principle」「Generic
#       Protocol Entrypoint Rule」、design「File Placement」。旧 v1
#       （dangling controller API: initialize_run / emit_step_artifacts /
#       aggregate_review_case / close_run / export_run_bundle 等）は
#       スクラッチ方針で置換。旧ロジックは流用しない。
#
# reference-free entry: pilot case を hidden default にしない。case manifest
# か明示 track 入力（target-id / phase-profile / source-ref）を受ける。
repo_root = Pathname(__dir__).join("..").expand_path

options = {
  "phase_profile" => "tasks",
  "review_mode" => "dual_reviewer_workflow",
  "operator" => "local-operator",
  "source_refs" => [],
  "case_manifest_ref" => nil,
  "run_root_base" => nil
}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby scripts/run_review_session.rb [options]"
  opts.on("--target-id ID", "Runtime target id") { |v| options["target_id"] = v }
  opts.on("--phase-profile NAME", "Phase profile") { |v| options["phase_profile"] = v }
  opts.on("--review-mode MODE", "Review mode") { |v| options["review_mode"] = v }
  opts.on("--operator NAME", "Operator name") { |v| options["operator"] = v }
  opts.on("--source-ref PATH", "Source ref (repeatable)") { |v| options["source_refs"] << v }
  opts.on("--case-manifest-ref PATH", "Case manifest ref path") { |v| options["case_manifest_ref"] = v }
  opts.on("--run-root-base PATH", "Custom runtime run root base") { |v| options["run_root_base"] = v }
end.parse!(ARGV)

run_root_base =
  if options["run_root_base"]
    Pathname(options["run_root_base"]).expand_path
  else
    repo_root + "experiments/runs"
  end

# Generic Protocol Entrypoint Rule: case_manifest_ref も明示 track 入力も
# 無ければ controller が fail fast する（ここで暗黙 default を作らない）。
driver = DualReviewer::TrackRuns::RuntimeSessionDriver.new(
  repo_root: repo_root, run_root_base: run_root_base
)

result = driver.run_session(
  target_id: options["target_id"] || "spec:dual-reviewer-runtime:tasks",
  phase_profile: options.fetch("phase_profile"),
  review_mode: options.fetch("review_mode"),
  operator: options.fetch("operator"),
  source_refs:
    options["source_refs"].empty? ? ["scripts/run_review_session.rb"] : options["source_refs"],
  track: options["case_manifest_ref"] ? nil : "spec",
  case_manifest_ref: options["case_manifest_ref"]
)

summary = {
  "entrypoint" => "run_review_session",
  "run_id" => result.fetch("run_id"),
  "treatment" => result.fetch("treatment"),
  "run_status" => result.fetch("run_status"),
  "runtime_paths" => result.fetch("runtime_paths")
}

puts JSON.pretty_generate(summary)
