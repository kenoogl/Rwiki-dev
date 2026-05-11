#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "time"
require "yaml"
require_relative "proposal_provenance_resolver"

module DualReviewer
  module SelfImprovement
    class ProposalBuilder
      attr_reader :repo_root, :provenance_resolver

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
        @provenance_resolver = ProposalProvenanceResolver.new(repo_root: @repo_root)
      end

      def build_from_signal_inventories
        signals = load_inventory(repo_root.join("learning/findings/recurring_failure_signals.json")) +
                  load_inventory(repo_root.join("learning/findings/workflow_failure_signals.json"))

        normalize_signals(signals).map { |signal| build_proposal(signal: signal) }
      end

      private

      def load_inventory(path)
        return [] unless path.exist?

        JSON.parse(path.read).fetch("entries", [])
      end

      def build_proposal(signal:)
        mapping = proposal_mapping(signal.fetch("signal_code"))
        proposal_id = build_proposal_id(signal: signal, target_layer: mapping.fetch("target_layer"))
        provenance = provenance_resolver.resolve(signal: signal)

        {
          "proposal_id" => proposal_id,
          "status" => existing_status_for(proposal_id: proposal_id),
          "target_layer" => mapping.fetch("target_layer"),
          "motivation_class" => mapping.fetch("motivation_class"),
          "source_signal_id" => signal.fetch("signal_id"),
          "source_signal_class" => signal.fetch("signal_class"),
          "source_evidence_refs" => signal.fetch("source_refs"),
          "source_origin" => provenance.fetch("source_origin"),
          "source_repository_refs" => provenance.fetch("source_repository_refs"),
          "source_admission_refs" => provenance.fetch("source_admission_refs"),
          "source_provenance_status" => provenance.fetch("source_provenance_status"),
          "evidence_maturity_context" => signal.fetch("validity_context"),
          "phase_context" => signal["phase_profile"],
          "treatment_context" => signal["treatment"],
          "problem_statement" => problem_statement(signal: signal),
          "proposed_change_summary" => proposed_change_summary(signal: signal, mapping: mapping, provenance: provenance),
          "expected_benefit" => expected_benefit(signal: signal),
          "possible_risks" => possible_risks(signal: signal, provenance: provenance),
          "required_test_mode" => mapping.fetch("required_test_mode"),
          "created_at" => Time.now.utc.iso8601
        }
      end

      def proposal_mapping(signal_code)
        {
          "invalid_run_guard_gap" => {
            "target_layer" => "workflow",
            "motivation_class" => "workflow_quality",
            "required_test_mode" => "manual_review"
          },
          "human_decision_mix" => {
            "target_layer" => "prompt",
            "motivation_class" => "review_quality",
            "required_test_mode" => "replay"
          },
          "rejected_finding_cluster" => {
            "target_layer" => "prompt",
            "motivation_class" => "review_quality",
            "required_test_mode" => "replay"
          },
          "deferred_finding_cluster" => {
            "target_layer" => "prompt",
            "motivation_class" => "review_quality",
            "required_test_mode" => "replay"
          },
          "validator_failed" => {
            "target_layer" => "workflow",
            "motivation_class" => "workflow_quality",
            "required_test_mode" => "manual_review"
          },
          "invalidation_marker_issued" => {
            "target_layer" => "workflow",
            "motivation_class" => "workflow_quality",
            "required_test_mode" => "manual_review"
          },
          "exploratory_evidence_mode" => {
            "target_layer" => "policy",
            "motivation_class" => "evidence_quality",
            "required_test_mode" => "backtest"
          },
          "analysis_precondition_gap" => {
            "target_layer" => "workflow",
            "motivation_class" => "evidence_quality",
            "required_test_mode" => "manual_review"
          },
          "exploratory_population_member" => {
            "target_layer" => "policy",
            "motivation_class" => "evidence_quality",
            "required_test_mode" => "backtest"
          },
          "analysis_blocked_population_member" => {
            "target_layer" => "workflow",
            "motivation_class" => "evidence_quality",
            "required_test_mode" => "manual_review"
          },
          "unresolved_judgment_labels" => {
            "target_layer" => "schema",
            "motivation_class" => "evidence_quality",
            "required_test_mode" => "backtest"
          },
          "caveat_observed" => {
            "target_layer" => "workflow",
            "motivation_class" => "evidence_quality",
            "required_test_mode" => "backtest"
          }
        }.fetch(signal_code)
      end

      def build_proposal_id(signal:, target_layer:)
        identity = signal["run_id"] || aggregate_signal_identity(signal)
        slug = [
          target_layer,
          signal.fetch("signal_code"),
          identity
        ].join("-").gsub(/[^a-zA-Z0-9]+/, "-").downcase.gsub(/^-|-$/, "")
        "proposal-#{slug}"
      end

      def aggregate_signal_identity(signal)
        source_ref = signal.fetch("source_refs", []).first
        signal_value = signal.fetch("signal_value", {})
        signal_value["caveat_code"] || source_ref || "aggregate"
      end

      def existing_status_for(proposal_id:)
        register_status = status_from_history_registers(proposal_id: proposal_id)
        return register_status if register_status

        path = repo_root.join("learning/proposals/#{proposal_id}.yaml")
        return "draft" unless path.exist?

        proposal = YAML.load_file(path)
        proposal["status"] || "draft"
      end

      def status_from_history_registers(proposal_id:)
        rollback_entries = load_register_entries(repo_root.join("learning/rollback/rollback_register.json"))
        return "rolled_back" if rollback_entries.any? { |entry| entry["proposal_id"] == proposal_id }

        adoption_entries = load_register_entries(repo_root.join("learning/approved-updates/adoption_register.json")).select do |entry|
          entry["proposal_id"] == proposal_id
        end
        return "adopted" if adoption_entries.any? { |entry| entry["decision_state"] == "adopted" }
        return "approved" if adoption_entries.any? { |entry| entry["decision_state"] == "approved" }

        rejection_entries = load_register_entries(repo_root.join("learning/rejected-updates/rejection_register.json"))
        return "rejected" if rejection_entries.any? { |entry| entry["proposal_id"] == proposal_id }

        nil
      end

      def load_register_entries(path)
        return [] unless path.exist?

        JSON.parse(path.read).fetch("entries", [])
      end

      def problem_statement(signal:)
        "#{signal.fetch('summary')} Signal #{signal.fetch('signal_code')} was observed in self-improvement intake."
      end

      def proposed_change_summary(signal:, mapping:, provenance:)
        base = case signal.fetch("signal_code")
               when "invalid_run_guard_gap"
                 "Unify validator failure handling and invalidation-marker handling into one workflow guard so invalid runs are blocked, explained, and triaged consistently."
               when "human_decision_mix"
                 "Tighten reviewer or judgment prompt criteria so decision outcomes become easier to resolve consistently."
               when "validator_failed", "invalidation_marker_issued", "analysis_precondition_gap"
                 "Harden workflow checks and closure conditions so invalid or incomplete runs are prevented earlier."
               when "exploratory_evidence_mode", "exploratory_population_member"
                 "Clarify policy boundaries for exploratory evidence so it is retained without being over-weighted in adoption decisions."
               when "unresolved_judgment_labels"
                 "Extend schema or metric extraction so judgment labels can be resolved without proxy-only analysis."
               when "caveat_observed"
                 "Add analysis workflow support to surface caveat-heavy slices before downstream proposal review."
               else
                 "Refine the affected layer to reduce recurrence of this signal."
               end

        if provenance.fetch("source_origin") == "imported_external_bundle" &&
           provenance.fetch("source_provenance_status") != "standard_admitted"
          "#{base} Imported evidence must remain tagged as non-standard admission during evaluation and proposal review."
        else
          base
        end
      end

      def expected_benefit(signal:)
        case signal.fetch("signal_class")
        when "review_quality_signal"
          "Improve review consistency and reduce repeated ambiguous decisions."
        when "workflow_failure_signal"
          "Reduce invalid or contaminated runs before they reach evaluation."
        else
          "Improve evidence usability for downstream evaluation and adoption decisions."
        end
      end

      def possible_risks(signal:, provenance:)
        risks = []
        risks << "May overfit to exploratory-only observations." if signal.fetch("validity_context") == "exploratory"
        risks << "May optimize for invalid-run cleanup without improving review quality." if signal.fetch("validity_context") == "invalid"
        risks << "Aggregate caveat signals may hide run-level causes." if signal["run_id"].nil?

        if provenance.fetch("source_origin") == "imported_external_bundle"
          risks << "Imported evidence provenance may be insufficient for standard adoption support." if provenance.fetch("source_provenance_status") != "standard_admitted"
        end

        risks.empty? ? ["No special risk flagged at proposal generation time."] : risks
      end

      def normalize_signals(signals)
        passthrough = []
        workflow_merge_groups = Hash.new { |acc, key| acc[key] = [] }

        signals.each do |signal|
          if %w[validator_failed invalidation_marker_issued].include?(signal["signal_code"]) && signal["run_id"]
            workflow_merge_groups[signal["run_id"]] << signal
          else
            passthrough << signal
          end
        end

        merged = workflow_merge_groups.values.map do |group|
          merge_invalid_run_workflow_group(group)
        end.compact

        passthrough + merged
      end

      def merge_invalid_run_workflow_group(group)
        return group.first if group.length == 1

        first = group.first
        {
          "signal_id" => "runtime:#{first.fetch('run_id')}:invalid_run_guard_gap:merged-validator-and-invalidation",
          "signal_class" => "workflow_failure_signal",
          "signal_code" => "invalid_run_guard_gap",
          "signal_source" => "runtime",
          "source_refs" => group.flat_map { |signal| signal.fetch("source_refs") }.uniq,
          "summary" => "Runtime invalid-run workflow signals indicate validator failure and invalidation handling should be reviewed together.",
          "validity_context" => first.fetch("validity_context"),
          "phase_profile" => first["phase_profile"],
          "treatment" => first["treatment"],
          "run_id" => first.fetch("run_id"),
          "signal_value" => {
            "merged_signal_codes" => group.map { |signal| signal.fetch("signal_code") }.uniq,
            "reason_codes" => group.map { |signal| signal.dig("signal_value", "reason_code") }.compact.uniq,
            "validator_statuses" => group.map { |signal| signal.dig("signal_value", "validator_status") }.compact.uniq
          }
        }
      end
    end
  end
end
