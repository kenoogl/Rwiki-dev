#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "tmpdir"
require "yaml"
require_relative "track_runs/intent_track_writer"
require_relative "track_runs/spec_track_writer"
require_relative "track_runs/implementation_track_runner"

def assert(condition, message)
  raise message unless condition
end

repo_root = Pathname(File.expand_path("..", __dir__))

Dir.mktmpdir("dual-reviewer-protocol-runs") do |tmpdir|
  tmp_root = Pathname(tmpdir)

  intent_writer = DualReviewer::TrackRuns::IntentTrackWriter.new(
    repo_root: repo_root,
    run_label: "F1-intent-track-single",
    case_id: "F1-intent-dual-reviewer-rebuild",
    review_mode: "single_review",
    intent_ref: ".kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-paper-plan.md",
    supporting_refs: [
      "dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md",
      "dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md"
    ],
    operator: "validator",
    objective: "intent bootstrap pilot",
    output_root: tmp_root.join("intent-track-runs")
  )

  intent_paths = intent_writer.write_all
  assert(intent_paths.values.all?(&:exist?), "intent protocol should create all files")
  intent_manifest = YAML.load_file(intent_paths.fetch("run_manifest"))
  assert(intent_manifest.fetch("track") == "intent", "intent protocol manifest should record intent track")

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
      "dual-reviewer-rebuild/docs/alignment/cross-spec-tasks-alignment.md"
    ],
    operator: "validator",
    output_root: tmp_root.join("spec-track-runs")
  )

  spec_paths = spec_writer.write_all
  assert(spec_paths.values.all?(&:exist?), "spec protocol should create all files")
  spec_manifest = YAML.load_file(spec_paths.fetch("run_manifest"))
  assert(spec_manifest.fetch("track") == "spec", "spec protocol manifest should record spec track")

  implementation_single_runner = DualReviewer::TrackRuns::ImplementationTrackRunner.new(
    repo_root: repo_root,
    run_label: "F1-implementation-track-single",
    case_id: "F1-phase-field-cpp",
    review_mode: "single_review",
    implementation_snapshot_ref: ".kiro/methodology/dual-reviewer-spec-driven-paper/phase-field-implementation-phase-first-snapshot.md",
    upstream_spec_refs: [
      ".kiro/specs/phase-field-reverse-spec/intent.md",
      ".kiro/specs/phase-field-reverse-spec/requirements.md",
      ".kiro/specs/phase-field-reverse-spec/design.md",
      ".kiro/specs/phase-field-reverse-spec/tasks.md"
    ],
    governance_refs: [
      "dual-reviewer-rebuild/docs/coordination/implementation-conformance-review.md",
      "dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md"
    ],
    operator: "validator",
    phase_profile: "tasks",
    target_id: "implementation:phase-field-cpp",
    protocol_output_root: tmp_root.join("implementation-track-runs"),
    runtime_run_root_base: tmp_root.join("runtime-runs"),
    export_root_base: tmp_root.join("exports")
  )

  implementation_dual_runner = DualReviewer::TrackRuns::ImplementationTrackRunner.new(
    repo_root: repo_root,
    run_label: "F1-implementation-track-dual",
    case_id: "F1-phase-field-cpp",
    review_mode: "dual_reviewer_workflow",
    implementation_snapshot_ref: ".kiro/methodology/dual-reviewer-spec-driven-paper/phase-field-implementation-phase-first-snapshot.md",
    upstream_spec_refs: [
      ".kiro/specs/phase-field-reverse-spec/intent.md",
      ".kiro/specs/phase-field-reverse-spec/requirements.md",
      ".kiro/specs/phase-field-reverse-spec/design.md",
      ".kiro/specs/phase-field-reverse-spec/tasks.md"
    ],
    governance_refs: [
      "dual-reviewer-rebuild/docs/coordination/implementation-conformance-review.md",
      "dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md"
    ],
    operator: "validator",
    phase_profile: "tasks",
    target_id: "implementation:phase-field-cpp",
    protocol_output_root: tmp_root.join("implementation-track-runs"),
    runtime_run_root_base: tmp_root.join("runtime-runs"),
    export_root_base: tmp_root.join("exports")
  )

  implementation_single_result = implementation_single_runner.run_all
  implementation_dual_result = implementation_dual_runner.run_all

  protocol_paths = implementation_single_result.fetch("protocol_paths").transform_values { |path| Pathname(path) }
  runtime_paths = implementation_single_result.fetch("runtime_paths").transform_values { |path| Pathname(path) }
  dual_runtime_paths = implementation_dual_result.fetch("runtime_paths").transform_values { |path| Pathname(path) }

  assert(protocol_paths.values.all?(&:exist?), "implementation protocol should create all protocol files")
  assert(runtime_paths.values.all?(&:exist?), "implementation protocol should create all runtime files")
  assert(dual_runtime_paths.values.all?(&:exist?), "dual implementation protocol should create all runtime files")

  implementation_manifest = YAML.load_file(protocol_paths.fetch("run_manifest"))
  assert(implementation_manifest.fetch("track") == "implementation", "implementation manifest should record implementation track")
  assert(implementation_manifest.dig("runtime", "treatment") == "single", "single review should map to runtime single treatment")
  assert(protocol_paths.fetch("execution_packet").read.include?("## 3. execution steps"), "implementation execution packet should include execution steps section")

  single_review_case = JSON.parse(runtime_paths.fetch("review_artifact").read)
  dual_review_case = JSON.parse(dual_runtime_paths.fetch("review_artifact").read)
  assert(single_review_case.fetch("findings").any?, "single implementation protocol should emit non-empty findings")
  assert(dual_review_case.fetch("findings").length > single_review_case.fetch("findings").length, "dual implementation protocol should emit more findings than single in the phase-field pilot")
  assert(dual_review_case.fetch("findings").any? { |finding| finding["source_role"] == "adversarial_reviewer" }, "dual implementation protocol should preserve adversarial findings")
  single_steps = %w[step_a_primary_detection step_c_judgment step_d_integration].map do |step_filename|
    JSON.parse(tmp_root.join("runtime-runs", implementation_single_result.fetch("run_id"), "steps", "#{step_filename}.json").read)
  end
  dual_steps = %w[step_a_primary_detection step_b_adversarial_review step_d_integration].map do |step_filename|
    JSON.parse(tmp_root.join("runtime-runs", implementation_dual_result.fetch("run_id"), "steps", "#{step_filename}.json").read)
  end
  assert(single_steps.all? { |payload| payload.dig("prompt_identity", "resolution_status") == "resolved" }, "single implementation prompts should resolve")
  assert(dual_steps.all? { |payload| payload.dig("prompt_identity", "resolution_status") == "resolved" }, "dual implementation prompts should resolve")

  validator_result = JSON.parse(runtime_paths.fetch("conformance_review_result").read)
  assert(validator_result.fetch("overall_status") == "passed", "implementation validation should pass in protocol runner check")
end

puts "protocol runner validation passed"
