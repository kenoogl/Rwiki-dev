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
  history_registry = DualReviewer::SelfImprovement::HistoryRegistry.new(repo_root: repo_root)

  runtime_roots = Dir[repo_root.join("tests/fixtures/evaluation/local_runs/*")].sort
  runtime_signals = runtime_roots.flat_map do |run_root|
    signal_intake.load_runtime_signals(run_root: run_root).fetch("signals")
  end
  evaluation_signals = signal_intake.load_evaluation_signals(analysis_root: repo_root.join("experiments/analysis")).fetch("signals")
  all_signals = runtime_signals + evaluation_signals

  assert(all_signals.any? { |signal| signal["signal_class"] == "review_quality_signal" }, "missing review quality signal")
  assert(all_signals.any? { |signal| signal["signal_class"] == "workflow_failure_signal" }, "missing workflow failure signal")
  assert(all_signals.any? { |signal| signal["signal_source"] == "evaluation" && signal["signal_code"] == "caveat_observed" }, "missing evaluation caveat signal")

  inventory_writer.write_recurring_failure_inventory(signals: all_signals)
  inventory_writer.write_workflow_failure_inventory(signals: all_signals)

  proposals = DualReviewer::SelfImprovement::ProposalBuilder.new(repo_root: repo_root).build_from_signal_inventories
  proposal_writer.write_proposals(proposals: proposals)

  local_proposal = proposals.find { |proposal| proposal["proposal_id"] == "proposal-prompt-human-decision-mix-run-fixture-001" }
  imported_proposal = proposals.find { |proposal| proposal["proposal_id"] == "proposal-schema-unresolved-judgment-labels-run-fixture-001" }
  manual_proposal = proposals.find { |proposal| proposal["proposal_id"] == "proposal-workflow-caveat-observed-aggregate" }
  assert(local_proposal["source_origin"] == "central_local_run", "local provenance lost")
  assert(imported_proposal["source_origin"] == "imported_external_bundle", "imported provenance lost")
  assert(!imported_proposal["source_admission_refs"].empty?, "imported admission refs missing")
  assert(manual_proposal["source_origin"] == "manual_review_record", "manual origin lost")

  backtests = DualReviewer::SelfImprovement::BacktestBuilder.new(repo_root: repo_root).build_backtests
  backtest_writer.write_backtests(backtests: backtests)
  imported_backtest = backtests.find { |entry| entry["proposal_id"] == imported_proposal["proposal_id"] }
  assert(imported_backtest["result_label"] == "supported", "imported backtest not supported")
  assert(imported_backtest["input_origin_refs"].first["bundle_id"] == "bundle-run-fixture-001", "imported backtest origin missing bundle id")

  pattern_candidates = DualReviewer::SelfImprovement::PatternCandidateBuilder.new(repo_root: repo_root).build_candidates
  pattern_writer.write_candidates(candidates: pattern_candidates)
  assert(pattern_candidates.any? { |entry| entry["candidate_scope"] == "project_specific_concrete" }, "missing project-specific pattern candidate")
  assert(pattern_candidates.any? { |entry| entry["candidate_scope"] == "meta_pattern_candidate" }, "missing meta-pattern candidate")

  history_registry.record_approval(
    proposal_id: imported_proposal["proposal_id"],
    reviewer_note: "smoke approval"
  )
  history_registry.record_adoption(
    proposal_id: imported_proposal["proposal_id"],
    linked_repo_change_ref: "commit:smoke-adoption",
    reviewer_note: "smoke adoption"
  )
  history_registry.record_rejection(
    proposal_id: "proposal-workflow-validator-failed-run-invalid-001",
    rejection_reason: "smoke rejection",
    reviewer_note: "smoke reject"
  )
  history_registry.record_rollback(
    proposal_id: imported_proposal["proposal_id"],
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
  assert(proposal_index["entries"].find { |entry| entry["proposal_id"] == imported_proposal["proposal_id"] }["status"] == "rolled_back", "rolled-back status not persisted")

  puts "self-improvement pipeline validation passed"
end
