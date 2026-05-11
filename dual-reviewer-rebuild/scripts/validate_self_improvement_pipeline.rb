#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "pathname"
require "tmpdir"
require "yaml"
require_relative "self_improvement/signal_intake"
require_relative "self_improvement/signal_inventory_writer"
require_relative "self_improvement/proposal_builder"
require_relative "self_improvement/proposal_writer"
require_relative "self_improvement/backtest_builder"
require_relative "self_improvement/backtest_writer"
require_relative "self_improvement/pattern_candidate_builder"
require_relative "self_improvement/pattern_candidate_writer"
require_relative "self_improvement/remediation_template_builder"
require_relative "self_improvement/remediation_template_writer"
require_relative "self_improvement/history_registry"

def assert(condition, message)
  raise message unless condition
end

source_repo = Pathname(__dir__).join("..").expand_path

Dir.mktmpdir do |dir|
  repo_root = Pathname(dir).join("repo")
  %w[experiments learning tests].each do |subdir|
    FileUtils.mkdir_p(repo_root)
    FileUtils.cp_r(source_repo.join(subdir), repo_root)
  end

  signal_intake = DualReviewer::SelfImprovement::SignalIntake.new(repo_root: repo_root)
  inventory_writer = DualReviewer::SelfImprovement::SignalInventoryWriter.new(repo_root: repo_root)
  proposal_writer = DualReviewer::SelfImprovement::ProposalWriter.new(repo_root: repo_root)
  backtest_writer = DualReviewer::SelfImprovement::BacktestWriter.new(repo_root: repo_root)
  pattern_writer = DualReviewer::SelfImprovement::PatternCandidateWriter.new(repo_root: repo_root)
  remediation_writer = DualReviewer::SelfImprovement::RemediationTemplateWriter.new(repo_root: repo_root)
  history_registry = DualReviewer::SelfImprovement::HistoryRegistry.new(repo_root: repo_root)

  runtime_roots = Dir[repo_root.join("tests/fixtures/evaluation/local_runs/*")].sort
  runtime_signals = runtime_roots.flat_map do |run_root|
    signal_intake.load_runtime_signals(run_root: run_root).fetch("signals")
  end
  v2_runtime_root = Dir[repo_root.join("experiments/runs/*")].sort.first
  v2_runtime_result = signal_intake.load_runtime_signals(run_root: v2_runtime_root)
  v2_runtime_signals = v2_runtime_result.fetch("signals")
  evaluation_signals = signal_intake.load_evaluation_signals(analysis_root: repo_root.join("experiments/analysis")).fetch("signals")
  all_signals = runtime_signals + v2_runtime_signals + evaluation_signals

  assert(all_signals.any? { |signal| signal["signal_class"] == "review_quality_signal" }, "missing review quality signal")
  assert(all_signals.any? { |signal| signal["signal_class"] == "workflow_failure_signal" }, "missing workflow failure signal")
  assert(v2_runtime_result.fetch("classification").fetch("classification") == "valid", "unexpected v2 runtime classification")
  assert(v2_runtime_signals.none? { |signal| signal["signal_code"] == "comparison_eligibility_observed" }, "supporting comparison artifact should not become a standalone signal")

  inventory_writer.write_recurring_failure_inventory(signals: all_signals)
  inventory_writer.write_workflow_failure_inventory(signals: all_signals)

  proposals = DualReviewer::SelfImprovement::ProposalBuilder.new(repo_root: repo_root).build_from_signal_inventories
  proposal_writer.write_proposals(proposals: proposals)

  local_proposal = proposals.find { |proposal| proposal["source_signal_id"].include?(":human_decision_mix:") }
  workflow_proposal = proposals.find { |proposal| proposal["source_signal_id"].include?(":invalid_run_guard_gap:") }
  assert(local_proposal["source_origin"] == "central_local_run", "local provenance lost")
  assert(workflow_proposal["target_layer"] == "workflow", "merged invalid-run proposal lost workflow target")
  assert(workflow_proposal["source_evidence_refs"].any? { |ref| ref.include?("derived/invalid_run_triage_note.json") }, "invalid-run triage note should propagate into workflow proposal evidence")
  assert(proposals.none? { |proposal| proposal["source_signal_id"].include?(":unresolved_judgment_labels:") }, "resolved judgment labels should not emit a schema proposal")

  manual_proposal = proposals.find { |proposal| proposal["source_signal_id"].include?(":caveat_observed:") }
  if all_signals.any? { |signal| signal["signal_source"] == "evaluation" && signal["signal_code"] == "caveat_observed" }
    assert(manual_proposal, "missing manual caveat proposal")
    assert(manual_proposal["source_origin"] == "manual_review_record", "manual origin lost")
  end

  backtests = DualReviewer::SelfImprovement::BacktestBuilder.new(repo_root: repo_root).build_backtests
  backtest_writer.write_backtests(backtests: backtests)
  if manual_proposal
    manual_backtest = backtests.find { |entry| entry["proposal_id"] == manual_proposal["proposal_id"] }
    assert(manual_backtest["result_label"] == "supported", "aggregate caveat backtest should be supported")
  end

  pattern_candidates = DualReviewer::SelfImprovement::PatternCandidateBuilder.new(repo_root: repo_root).build_candidates
  pattern_writer.write_candidates(candidates: pattern_candidates)
  assert(pattern_candidates.any? { |entry| entry["candidate_scope"] == "project_specific_concrete" }, "missing project-specific pattern candidate")
  assert(pattern_candidates.any? { |entry| entry["candidate_scope"] == "meta_pattern_candidate" }, "missing meta-pattern candidate")
  assert(pattern_candidates.any? { |entry| entry["source_signal_id"] == "aggregate:invalid_run_triage:invalidation_marker_present" }, "missing invalid-run triage meta-pattern candidate")
  remediation_templates = DualReviewer::SelfImprovement::RemediationTemplateBuilder.new(repo_root: repo_root).build_templates
  remediation_writer.write_templates(templates: remediation_templates)
  triage_template = remediation_templates.find { |entry| entry["failure_mode_code"] == "invalidation_marker_present" }
  assert(triage_template, "missing invalid-run remediation template")
  assert(triage_template["recommended_actions"].any? { |entry| entry.include?("invalidation marker reason") }, "invalid-run remediation template should include marker review guidance")

  history_registry.record_approval(
    proposal_id: (manual_proposal || local_proposal).fetch("proposal_id"),
    reviewer_note: "smoke approval"
  )
  history_registry.record_adoption(
    proposal_id: (manual_proposal || local_proposal).fetch("proposal_id"),
    linked_repo_change_ref: "commit:smoke-adoption",
    reviewer_note: "smoke adoption"
  )
  history_registry.record_rejection(
    proposal_id: workflow_proposal["proposal_id"],
    rejection_reason: "smoke rejection",
    reviewer_note: "smoke reject"
  )
  history_registry.record_rollback(
    proposal_id: (manual_proposal || local_proposal).fetch("proposal_id"),
    adopted_change_ref: "commit:smoke-adoption",
    rollback_reason: "smoke rollback",
    rollback_trigger_signal_refs: ["signal:smoke-trigger"]
  )

  adoption_register = JSON.parse(repo_root.join("learning/approved-updates/adoption_register.json").read)
  rejection_register = JSON.parse(repo_root.join("learning/rejected-updates/rejection_register.json").read)
  rollback_register = JSON.parse(repo_root.join("learning/rollback/rollback_register.json").read)
  proposal_index = JSON.parse(repo_root.join("learning/proposals/proposal_index.json").read)

  assert(adoption_register["entries"].any? { |entry| entry["decision_state"] == "approved" }, "approval entry missing")
  assert(adoption_register["entries"].any? { |entry| entry["decision_state"] == "adopted" && entry["linked_repo_change_ref"] == "commit:smoke-adoption" }, "adoption entry missing")
  assert(rejection_register["entries"].any? { |entry| entry["rejection_reason"] == "smoke rejection" }, "rejection entry missing")
  assert(rollback_register["entries"].any? { |entry| entry["rollback_reason"] == "smoke rollback" }, "rollback entry missing")
  tracked_proposal = manual_proposal || local_proposal
  assert(proposal_index["entries"].find { |entry| entry["proposal_id"] == tracked_proposal["proposal_id"] }["status"] == "rolled_back", "rolled-back status not persisted")

  puts "self-improvement pipeline validation passed"
end
