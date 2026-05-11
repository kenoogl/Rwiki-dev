#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "yaml"

repo_root = Pathname(__dir__).join("..").expand_path

def runtime_root_from_summary(summary_path:, repo_root:)
  payload = YAML.load_file(summary_path)
  validator_ref = payload["validator_result_ref"]
  return runtime_root_from_validator_ref(validator_ref) if validator_ref

  invalidation_ref = payload["invalidation_markers_ref"]
  return runtime_root_from_validator_ref(invalidation_ref) if invalidation_ref

  raise ArgumentError, "unable to resolve runtime root from summary: #{summary_path.relative_path_from(repo_root)}"
end

def runtime_root_from_validator_ref(ref)
  Pathname(ref).dirname.dirname.to_s
end

def runtime_root_fallback(case_id:, track:, run_id:, repo_root:)
  track_root =
    case track
    when "implementation"
      repo_root.join("experiments/protocols/implementation-track-runs")
    when "intent"
      repo_root.join("experiments/protocols/intent-track-runs")
    when "spec"
      repo_root.join("experiments/protocols/spec-track-runs")
    end

  pattern = track_root.join("**/runtime-runs/#{run_id}").to_s
  path = Dir.glob(pattern).sort.first
  raise ArgumentError, "runtime run not found for #{case_id}: #{run_id}" if path.nil?

  Pathname(path).relative_path_from(repo_root).to_s
end

def treatment_rank(treatment)
  {
    "single" => 0,
    "dual" => 1,
    "dual+judgment" => 2
  }.fetch(treatment, 99)
end

def review_mode_rank(review_mode)
  {
    "single_review" => 0,
    "dual_review" => 1,
    "dual_reviewer_workflow" => 2
  }.fetch(review_mode, 99)
end

case_id = nil
track = nil
phase_profile = nil
require_protocol_summary = true
allowed_review_modes = ["single_review", "dual_review", "dual_reviewer_workflow"].freeze
allowed_treatments = nil
selection_manifest_path = nil
explicit_allow_missing_summary = false

argv = ARGV.dup
until argv.empty?
  flag = argv.shift
  case flag
  when "--case-id"
    case_id = argv.shift
  when "--track"
    track = argv.shift
  when "--phase-profile"
    phase_profile = argv.shift
  when "--review-mode"
    allowed_review_modes = argv.shift.to_s.split(",").map(&:strip).reject(&:empty?)
  when "--treatment"
    allowed_treatments = argv.shift.to_s.split(",").map(&:strip).reject(&:empty?)
  when "--selection-manifest"
    selection_manifest_path = argv.shift
  when "--allow-missing-summary"
    require_protocol_summary = false
    explicit_allow_missing_summary = true
  else
    abort "unknown argument: #{flag}"
  end
end

if selection_manifest_path
  manifest_payload = YAML.load_file(Pathname(File.expand_path(selection_manifest_path, Dir.pwd)))
  track ||= manifest_payload["track"]
  case_id ||= manifest_payload["case_id"]
  phase_profile ||= manifest_payload["phase_profile"]
  require_protocol_summary = manifest_payload.fetch("require_protocol_summary", true) unless explicit_allow_missing_summary
  allowed_review_modes = Array(manifest_payload["review_modes"]).map(&:to_s) if manifest_payload["review_modes"]
  allowed_treatments = Array(manifest_payload["treatments"]).map(&:to_s) if manifest_payload["treatments"]
end

abort "usage: ruby scripts/select_evaluation_run_set.rb --track <track> --case-id <case_id> [--phase-profile <phase>] [--review-mode <modes>] [--treatment <treatments>] [--selection-manifest <path>] [--allow-missing-summary]" if case_id.nil? || track.nil?

summary_filename =
  case track
  when "implementation"
    "conformance_review_result.yaml"
  when "intent", "spec"
    "runtime_validation_summary.yaml"
  else
    abort "unsupported track: #{track}"
  end

protocol_root =
  case track
  when "implementation"
    repo_root.join("experiments/protocols/implementation-track-runs")
  when "intent"
    repo_root.join("experiments/protocols/intent-track-runs")
  when "spec"
    repo_root.join("experiments/protocols/spec-track-runs")
  end

entries = Dir.glob(protocol_root.join("**/protocol-runs/*/run_manifest.yaml").to_s).sort.map do |manifest_path|
  manifest = YAML.load_file(manifest_path)
  next unless manifest["case_id"] == case_id
  next unless allowed_review_modes.include?(manifest["review_mode"])
  next if phase_profile && manifest["phase_profile"] != phase_profile && manifest["reviewed_phase"] != phase_profile

  runtime = manifest["runtime"] || {}
  run_id = runtime["run_id"]
  treatment = runtime["treatment"]
  next if run_id.nil? || treatment.nil?
  next if allowed_treatments && !allowed_treatments.include?(treatment)

  summary_path = Pathname(manifest_path).dirname.join(summary_filename)
  next if require_protocol_summary && !summary_path.exist?

  runtime_root = repo_root.join(summary_path.exist? ? runtime_root_from_summary(summary_path: summary_path, repo_root: repo_root) : runtime_root_fallback(case_id: case_id, track: track, run_id: run_id, repo_root: repo_root))
  next unless runtime_root.exist?

  {
    "run_id" => run_id,
    "review_mode" => manifest["review_mode"],
    "treatment" => treatment,
    "phase_profile" => manifest["phase_profile"] || manifest["reviewed_phase"],
    "protocol_run_manifest_ref" => Pathname(manifest_path).relative_path_from(repo_root).to_s,
    "protocol_summary_ref" => summary_path.exist? ? summary_path.relative_path_from(repo_root).to_s : nil,
    "runtime_run_root" => runtime_root.relative_path_from(repo_root).to_s
  }
end.compact

ordered_entries = entries.sort_by do |entry|
  [
    treatment_rank(entry.fetch("treatment")),
    review_mode_rank(entry.fetch("review_mode")),
    entry.fetch("run_id")
  ]
end

puts JSON.pretty_generate(
  {
    "selection_policy_version" => "1.0.0",
    "track" => track,
    "case_id" => case_id,
    "phase_profile" => phase_profile,
    "require_protocol_summary" => require_protocol_summary,
    "review_modes" => allowed_review_modes,
    "treatments" => allowed_treatments,
    "selected_run_count" => ordered_entries.length,
    "entries" => ordered_entries,
    "runtime_run_roots" => ordered_entries.map { |entry| entry.fetch("runtime_run_root") }
  }
)
