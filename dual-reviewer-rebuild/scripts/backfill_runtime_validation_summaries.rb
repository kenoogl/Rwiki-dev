#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "yaml"
require "fileutils"
require "time"
require_relative "track_runs/runtime_validation_summary_builder"

repo_root = Pathname(__dir__).join("..").expand_path
builder = DualReviewer::TrackRuns::RuntimeValidationSummaryBuilder.new(repo_root: repo_root)

selected_tracks = []
force = false

argv = ARGV.dup
until argv.empty?
  flag = argv.shift
  case flag
  when "--track"
    selected_tracks << argv.shift
  when "--force"
    force = true
  else
    abort "unknown argument: #{flag}"
  end
end

selected_tracks = %w[intent spec] if selected_tracks.empty?
supported_tracks = %w[intent spec implementation].freeze
unknown_tracks = selected_tracks - supported_tracks
abort "unsupported track(s): #{unknown_tracks.join(', ')}" unless unknown_tracks.empty?

def summary_filename_for(track)
  track == "implementation" ? "conformance_review_result.yaml" : "runtime_validation_summary.yaml"
end

def runtime_paths_for(runtime_root)
  {
    "validator_result" => runtime_root.join("validation/validator_result.json"),
    "invalidation_markers" => runtime_root.join("validation/invalidation_markers.json"),
    "comparison_eligibility_note" => runtime_root.join("derived/comparison_eligibility_note.json"),
    "invalid_run_triage_note" => runtime_root.join("derived/invalid_run_triage_note.json")
  }
end

def summary_valid?(summary_path:, repo_root:)
  return false unless summary_path.exist?

  payload = YAML.load_file(summary_path)
  triage_ref = payload["invalid_run_triage_note_ref"]
  return false if triage_ref.nil? || triage_ref.empty?

  %w[
    validator_result_ref
    invalidation_markers_ref
    comparison_eligibility_note_ref
    invalid_run_triage_note_ref
  ].all? do |key|
    ref = payload[key]
    ref.nil? || repo_root.join(ref).exist?
  end
end

def case_root_for_manifest(manifest_file)
  manifest_file.dirname.dirname.parent
end

def parsed_time(value)
  return nil if value.nil? || value.to_s.empty?

  Time.iso8601(value)
rescue ArgumentError
  nil
end

def recover_runtime_root(manifest_file:, manifest:)
  case_root = case_root_for_manifest(manifest_file)
  desired_treatment = manifest.dig("runtime", "treatment")
  desired_phase = manifest["phase_profile"] || manifest["reviewed_phase"]
  generated_at = parsed_time(manifest["generated_at"])

  candidates = []
  Dir.glob(case_root.join("runtime-runs/*/run_manifest.yaml").to_s).sort.each do |runtime_manifest_path|
    runtime_manifest = YAML.load_file(runtime_manifest_path)
    metadata = runtime_manifest["metadata"] || {}
    next unless metadata["treatment"] == desired_treatment
    next if desired_phase && metadata["phase_profile"] != desired_phase
    next unless metadata["run_status"] == "closed"

    candidates << {
      "runtime_root" => Pathname(runtime_manifest_path).dirname,
      "started_at" => parsed_time(metadata["started_at"]),
      "run_id" => metadata["run_id"]
    }
  end

  return nil if candidates.empty?

  if generated_at
    prior_candidate = candidates.select { |entry| entry["started_at"] && entry["started_at"] <= generated_at }
                               .max_by { |entry| entry["started_at"] }
    return prior_candidate["runtime_root"] if prior_candidate
  end

  candidates.max_by { |entry| entry["started_at"] || Time.at(0) }.fetch("runtime_root")
end

def replace_text(path, replacements)
  text = path.read
  updated = replacements.reduce(text) { |memo, (before, after)| memo.gsub(before, after) }
  return if updated == text

  path.write(updated)
end

def repair_protocol_runtime_refs!(protocol_run_root:, manifest:, old_run_id:, new_run_id:)
  old_bundle_id = manifest.dig("runtime", "bundle_id")
  new_bundle_id = "bundle-#{new_run_id}"
  replacements = [[old_run_id, new_run_id]]
  replacements << [old_bundle_id, new_bundle_id] if old_bundle_id && old_bundle_id != new_bundle_id

  Dir.glob(protocol_run_root.join("*").to_s).each do |path|
    file = Pathname(path)
    next unless file.file?

    replace_text(file, replacements)
  end
end

def synthesized_triage_note(run_root:, run_id:, runtime_paths:)
  validator_result = JSON.parse(runtime_paths.fetch("validator_result").read)
  invalidation_payload = JSON.parse(runtime_paths.fetch("invalidation_markers").read)
  invalidation_markers = invalidation_payload.fetch("invalidation_markers", [])
  runtime_manifest = YAML.load_file(run_root.join("run_manifest.yaml"))
  human_signoff_status = runtime_manifest.fetch("metadata").fetch("human_signoff_status")

  failed_checks = validator_result.fetch("checks", []).select { |check| check.fetch("status") == "failed" }
  primary_failure_code =
    if invalidation_markers.any?
      "invalidation_marker_present"
    elsif failed_checks.any?
      "validator_check_failed"
    else
      "no_invalid_run_condition_detected"
    end

  operator_action_hint =
    if invalidation_markers.any?
      "Review invalidation marker reasons first, then decide whether the run should be rerun or formally excluded from downstream analysis."
    elsif failed_checks.any?
      "Resolve validator check failures before treating this run as analysis-ready."
    else
      "No invalid-run triage action is required."
    end

  {
    "schema_version" => "1.0.0",
    "invalid_run_triage_note_id" => "invalid-run-triage-#{run_id}",
    "run_id" => run_id,
    "validator_status" => validator_result.fetch("overall_status"),
    "human_signoff_status" => human_signoff_status,
    "primary_failure_code" => primary_failure_code,
    "failed_checks" => failed_checks.map do |check|
      {
        "check_id" => check.fetch("check_id"),
        "message" => check.fetch("message"),
        "severity" => check.fetch("severity")
      }
    end,
    "invalidation_marker_summary" => invalidation_markers.map do |marker|
      {
        "invalidation_marker_id" => marker.fetch("invalidation_marker_id"),
        "reason_code" => marker.fetch("reason_code"),
        "reason_detail" => marker.fetch("reason_detail"),
        "scope" => marker.fetch("scope"),
        "issued_by" => marker.fetch("issued_by"),
        "linked_check_ids" => marker.fetch("linked_check_ids", [])
      }
    end,
    "operator_action_hint" => operator_action_hint
  }
end

results = []

selected_tracks.each do |track|
  track_root =
    case track
    when "intent"
      repo_root.join("experiments/protocols/intent-track-runs")
    when "spec"
      repo_root.join("experiments/protocols/spec-track-runs")
    when "implementation"
      repo_root.join("experiments/protocols/implementation-track-runs")
    end

  Dir.glob(track_root.join("**/protocol-runs/*/run_manifest.yaml").to_s).sort.each do |manifest_path|
    manifest_file = Pathname(manifest_path)
    protocol_run_root = manifest_file.dirname
    manifest = YAML.load_file(manifest_file)
    summary_path = protocol_run_root.join(summary_filename_for(track))

    run_id = manifest.dig("runtime", "run_id")
    runtime_root =
      if run_id
        case_root_for_manifest(manifest_file).join("runtime-runs", run_id.to_s)
      end
    runtime_root = nil unless runtime_root&.exist?

    recovered_runtime_root = false
    unless runtime_root
      runtime_root = recover_runtime_root(manifest_file: manifest_file, manifest: manifest)
      recovered_runtime_root = !runtime_root.nil?
    end

    next if summary_valid?(summary_path: summary_path, repo_root: repo_root) && !force && !recovered_runtime_root

    unless runtime_root&.exist?
      missing_runtime_root =
        if run_id
          case_root_for_manifest(manifest_file).join("runtime-runs", run_id.to_s)
        end
      results << {
        "track" => track,
        "run_label" => manifest["run_label"],
        "status" => "skipped",
        "reason" => "runtime_run_missing",
        "runtime_root" => missing_runtime_root ? missing_runtime_root.relative_path_from(repo_root).to_s : nil
      }
      next
    end

    actual_run_manifest = YAML.load_file(runtime_root.join("run_manifest.yaml"))
    actual_run_id = actual_run_manifest.fetch("metadata").fetch("run_id")
    if run_id != actual_run_id
      repair_protocol_runtime_refs!(
        protocol_run_root: protocol_run_root,
        manifest: manifest,
        old_run_id: run_id,
        new_run_id: actual_run_id
      )
      manifest = YAML.load_file(manifest_file)
      run_id = actual_run_id
    end

    runtime_paths = runtime_paths_for(runtime_root)
    missing_non_triage = runtime_paths.reject { |key, path| key == "invalid_run_triage_note" || path.exist? }
    unless missing_non_triage.empty?
      results << {
        "track" => track,
        "run_label" => manifest["run_label"],
        "status" => "skipped",
        "reason" => "runtime_artifact_missing",
        "missing_paths" => missing_non_triage.values.map { |path| path.relative_path_from(repo_root).to_s }
      }
      next
    end

    triage_note_backfilled = false
    triage_note_path = runtime_paths.fetch("invalid_run_triage_note")
    unless triage_note_path.exist?
      FileUtils.mkdir_p(triage_note_path.dirname)
      triage_note_path.write(JSON.pretty_generate(synthesized_triage_note(run_root: runtime_root, run_id: run_id, runtime_paths: runtime_paths)) + "\n")
      triage_note_backfilled = true
    end

    extra_fields = {}
    extra_fields["reviewed_phase"] = manifest["reviewed_phase"] if track == "spec" && manifest["reviewed_phase"]

    payload = builder.build(
      run_label: manifest.fetch("run_label"),
      case_id: manifest.fetch("case_id"),
      track: track,
      run_id: run_id,
      runtime_paths: runtime_paths.transform_values(&:to_s),
      extra_fields: extra_fields
    )

    summary_path.write(YAML.dump(payload))
    results << {
      "track" => track,
      "run_label" => manifest["run_label"],
      "status" => "written",
      "summary_ref" => summary_path.relative_path_from(repo_root).to_s,
      "triage_note_backfilled" => triage_note_backfilled,
      "runtime_run_ref" => runtime_root.relative_path_from(repo_root).to_s,
      "runtime_run_recovered" => recovered_runtime_root
    }
  end
end

puts JSON.pretty_generate(
  {
    "repo_root" => repo_root.to_s,
    "selected_tracks" => selected_tracks,
    "force" => force,
    "written_count" => results.count { |entry| entry["status"] == "written" },
    "skipped_count" => results.count { |entry| entry["status"] == "skipped" },
    "results" => results
  }
)
