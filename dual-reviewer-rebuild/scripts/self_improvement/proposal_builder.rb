#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "time"
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

        signals.map { |signal| build_proposal(signal: signal) }
      end

      private

      def load_inventory(path)
        return [] unless path.exist?

        JSON.parse(path.read).fetch("entries", [])
      end

      def build_proposal(signal:)
        mapping = proposal_mapping(signal.fetch("signal_code"))
        provenance = provenance_resolver.resolve(signal: signal)
        proposal_id = build_proposal_id(signal: signal, target_layer: mapping.fetch("target_layer"))

        {
          "proposal_id" => proposal_id,
          "status" => "draft",
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
        slug = [
          target_layer,
          signal.fetch("signal_code"),
          signal["run_id"] || "aggregate"
        ].join("-").gsub(/[^a-zA-Z0-9]+/, "-").downcase.gsub(/^-|-$/, "")
        "proposal-#{slug}"
      end

      def problem_statement(signal:)
        "#{signal.fetch('summary')} Signal #{signal.fetch('signal_code')} was observed in self-improvement intake."
      end

      def proposed_change_summary(signal:, mapping:, provenance:)
        base = case signal.fetch("signal_code")
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
    end
  end
end
