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
    case_id: "F1-intent-dual-reviewer-rebuild",
    review_mode: "single_review",
    intent_ref: ".kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-paper-plan.md",
    supporting_refs: [
      "dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md",
      "dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md",
      "dual-reviewer-rebuild/docs/coordination/implementation-conformance-review.md"
    ],
    operator: "validator",
    objective: "intent bootstrap pilot",
    output_root: tmp_root.join("intent-track-runs")
  )

  intent_paths = intent_writer.write_all
  assert(intent_paths.values.all?(&:exist?), "intent writer should create all files")

  intent_manifest = YAML.load_file(intent_paths.fetch("run_manifest"))
  assert(intent_manifest.fetch("track") == "intent", "intent manifest should record intent track")
  assert(intent_manifest.fetch("outputs").keys.sort == %w[execution_packet intent_review_artifact intent_trace_note phase_metric_snapshot signal_linkage_note], "intent manifest outputs should match required artifacts")

  intent_metrics = JSON.parse(intent_paths.fetch("phase_metric_snapshot").read)
  assert(intent_metrics.fetch("metrics").key?("intent_revision_count"), "intent metrics should include intent_revision_count")
  intent_review_text = intent_paths.fetch("intent_review_artifact").read
  assert(intent_review_text.include?("## 3. metric snapshot"), "intent review artifact should include metric snapshot section")
  assert(intent_review_text.include?("major gap candidates:"), "intent review artifact should include populated major gap section")
  assert(intent_metrics.dig("metrics", "intent_review_findings_count").to_i.positive?, "intent metrics should include non-empty findings count")
  assert(intent_paths.fetch("execution_packet").read.include?("## 3. execution steps"), "intent execution packet should include execution steps section")

  spec_writer = DualReviewer::TrackRuns::SpecTrackWriter.new(
    repo_root: repo_root,
    run_label: "F1-spec-track-dual",
    case_id: "F1-spec-phase-field-reverse-spec",
    review_mode: "dual_reviewer_workflow",
    reviewed_phase: "tasks",
    reviewed_phase_ref: ".kiro/specs/phase-field-reverse-spec/tasks.md",
    adjacent_phase_refs: [
      ".kiro/specs/phase-field-reverse-spec/requirements.md",
      ".kiro/specs/phase-field-reverse-spec/design.md"
    ],
    alignment_refs: [
      ".kiro/methodology/dual-reviewer-spec-driven-paper/spec-track-first-case-phase-field-reverse-spec.md",
      "dual-reviewer-rebuild/docs/alignment/cross-spec-tasks-alignment.md"
    ],
    operator: "validator",
    output_root: tmp_root.join("spec-track-runs")
  )

  spec_paths = spec_writer.write_all
  assert(spec_paths.values.all?(&:exist?), "spec writer should create all files")

  spec_manifest = YAML.load_file(spec_paths.fetch("run_manifest"))
  assert(spec_manifest.fetch("track") == "spec", "spec manifest should record spec track")
  assert(spec_manifest.fetch("outputs").keys.sort == %w[alignment_artifact execution_packet phase_metric_snapshot reviewed_phase_note signal_linkage_note], "spec manifest outputs should match required artifacts")

  spec_metrics = JSON.parse(spec_paths.fetch("phase_metric_snapshot").read)
  assert(spec_metrics.fetch("metrics").key?("phase_blocking_issue_count"), "spec metrics should include phase_blocking_issue_count")
  reviewed_phase_text = spec_paths.fetch("reviewed_phase_note").read
  assert(reviewed_phase_text.include?("## 3. reopen assessment"), "reviewed phase note should include reopen assessment section")
  assert(reviewed_phase_text.include?("phase-local issues:"), "reviewed phase note should include populated phase-local issues section")
  assert(spec_metrics.dig("metrics", "phase_blocking_issue_count").to_i.positive?, "spec metrics should include blocking issue count")
  assert(spec_paths.fetch("execution_packet").read.include?("## 3. execution steps"), "spec execution packet should include execution steps section")

  requirements_spec_writer = DualReviewer::TrackRuns::SpecTrackWriter.new(
    repo_root: repo_root,
    run_label: "F1-spec-track-requirements-dual",
    case_id: "F1-requirements-phase-field-reverse-spec",
    review_mode: "dual_reviewer_workflow",
    reviewed_phase: "requirements",
    reviewed_phase_ref: ".kiro/specs/phase-field-reverse-spec/requirements.md",
    adjacent_phase_refs: [
      ".kiro/specs/phase-field-reverse-spec/intent.md",
      ".kiro/specs/phase-field-reverse-spec/design.md",
      ".kiro/specs/phase-field-reverse-spec/tasks.md"
    ],
    alignment_refs: [
      ".kiro/methodology/dual-reviewer-spec-driven-paper/spec-track-first-case-phase-field-reverse-spec.md",
      "dual-reviewer-rebuild/docs/alignment/cross-spec-requirements-alignment.md"
    ],
    operator: "validator",
    output_root: tmp_root.join("spec-track-requirements-runs")
  )

  requirements_paths = requirements_spec_writer.write_all
  assert(requirements_paths.values.all?(&:exist?), "requirements spec writer should create all files")
  requirements_metrics = JSON.parse(requirements_paths.fetch("phase_metric_snapshot").read)
  requirements_phase_text = requirements_paths.fetch("reviewed_phase_note").read
  assert(requirements_phase_text.include?("requirements"), "requirements reviewed phase note should record the reviewed phase")
  assert(requirements_phase_text.include?("clean-room"), "requirements reviewed phase note should include clean-room findings")
  assert(requirements_metrics.dig("metrics", "phase_handback_count_by_class", "C").to_i.positive?, "requirements metrics should include class C handback count")

  design_spec_writer = DualReviewer::TrackRuns::SpecTrackWriter.new(
    repo_root: repo_root,
    run_label: "F1-spec-track-design-dual",
    case_id: "F1-design-phase-field-reverse-spec",
    review_mode: "dual_reviewer_workflow",
    reviewed_phase: "design",
    reviewed_phase_ref: ".kiro/specs/phase-field-reverse-spec/design.md",
    adjacent_phase_refs: [
      ".kiro/specs/phase-field-reverse-spec/requirements.md",
      ".kiro/specs/phase-field-reverse-spec/tasks.md"
    ],
    alignment_refs: [
      ".kiro/methodology/dual-reviewer-spec-driven-paper/spec-track-first-case-phase-field-reverse-spec.md",
      "dual-reviewer-rebuild/docs/alignment/cross-spec-design-alignment.md"
    ],
    operator: "validator",
    output_root: tmp_root.join("spec-track-design-runs")
  )

  design_paths = design_spec_writer.write_all
  assert(design_paths.values.all?(&:exist?), "design spec writer should create all files")
  design_metrics = JSON.parse(design_paths.fetch("phase_metric_snapshot").read)
  design_phase_text = design_paths.fetch("reviewed_phase_note").read
  assert(design_phase_text.include?("design"), "design reviewed phase note should record the reviewed phase")
  assert(design_phase_text.include?("component"), "design reviewed phase note should include design boundary findings")
  assert(design_metrics.dig("metrics", "phase_handback_count_by_class", "B").to_i.positive?, "design metrics should include class B handback count")
end

puts "track run artifact validation passed"
