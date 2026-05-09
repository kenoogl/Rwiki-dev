#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "tmpdir"
require "yaml"
require_relative "track_runs/intent_track_writer"
require_relative "track_runs/spec_track_writer"

def assert(condition, message)
  raise message unless condition
end

repo_root = Pathname(File.expand_path("..", __dir__))

Dir.mktmpdir("dual-reviewer-track-runs") do |tmpdir|
  tmp_root = Pathname(tmpdir)

  intent_writer = DualReviewer::TrackRuns::IntentTrackWriter.new(
    repo_root: repo_root,
    run_label: "F1-intent-track-single",
    case_id: "dual-reviewer-rebuild",
    review_mode: "single_review",
    intent_ref: "intent/INTENT.md",
    supporting_refs: ["intent/NON_GOALS.md", "intent/DESIGN_PRINCIPLES.md"],
    operator: "validator",
    objective: "intent bootstrap pilot",
    output_root: tmp_root.join("intent-track-runs")
  )

  intent_paths = intent_writer.write_all
  assert(intent_paths.values.all?(&:exist?), "intent writer should create all files")

  intent_manifest = YAML.load_file(intent_paths.fetch("run_manifest"))
  assert(intent_manifest.fetch("track") == "intent", "intent manifest should record intent track")
  assert(intent_manifest.fetch("outputs").keys.sort == %w[intent_review_artifact intent_trace_note phase_metric_snapshot signal_linkage_note], "intent manifest outputs should match required artifacts")

  intent_metrics = JSON.parse(intent_paths.fetch("phase_metric_snapshot").read)
  assert(intent_metrics.fetch("metrics").key?("intent_revision_count"), "intent metrics should include intent_revision_count")
  assert(intent_paths.fetch("intent_review_artifact").read.include?("## 3. metric snapshot"), "intent review artifact should include metric snapshot section")

  spec_writer = DualReviewer::TrackRuns::SpecTrackWriter.new(
    repo_root: repo_root,
    run_label: "F1-spec-track-dual",
    case_id: "phase-field-reverse-spec",
    review_mode: "dual_reviewer_workflow",
    reviewed_phase: "design",
    reviewed_phase_ref: ".kiro/specs/phase-field-reverse-spec/design.md",
    adjacent_phase_refs: [
      ".kiro/specs/phase-field-reverse-spec/requirements.md",
      ".kiro/specs/phase-field-reverse-spec/tasks.md"
    ],
    alignment_refs: ["docs/alignment/cross-spec-design-alignment.md"],
    operator: "validator",
    output_root: tmp_root.join("spec-track-runs")
  )

  spec_paths = spec_writer.write_all
  assert(spec_paths.values.all?(&:exist?), "spec writer should create all files")

  spec_manifest = YAML.load_file(spec_paths.fetch("run_manifest"))
  assert(spec_manifest.fetch("track") == "spec", "spec manifest should record spec track")
  assert(spec_manifest.fetch("outputs").keys.sort == %w[alignment_artifact phase_metric_snapshot reviewed_phase_note signal_linkage_note], "spec manifest outputs should match required artifacts")

  spec_metrics = JSON.parse(spec_paths.fetch("phase_metric_snapshot").read)
  assert(spec_metrics.fetch("metrics").key?("phase_blocking_issue_count"), "spec metrics should include phase_blocking_issue_count")
  assert(spec_paths.fetch("reviewed_phase_note").read.include?("## 3. reopen assessment"), "reviewed phase note should include reopen assessment section")
end

puts "track run artifact validation passed"
