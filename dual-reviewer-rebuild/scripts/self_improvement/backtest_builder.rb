#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "yaml"
require "time"
require_relative "replay_input_resolver"

module DualReviewer
  module SelfImprovement
    class BacktestBuilder
      attr_reader :repo_root, :replay_input_resolver

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
        @replay_input_resolver = ReplayInputResolver.new(repo_root: @repo_root)
      end

      def build_backtests
        proposal_paths.map do |proposal_path|
          proposal = YAML.load_file(proposal_path)
          build_backtest(proposal: proposal)
        end
      end

      private

      def proposal_paths
        Dir[repo_root.join("learning/proposals/proposal-*.yaml")].sort
      end

      def build_backtest(proposal:)
        case proposal.fetch("required_test_mode")
        when "replay"
          build_replay_backtest(proposal: proposal)
        when "backtest"
          build_analysis_backtest(proposal: proposal)
        when "manual_review"
          build_manual_review_backtest(proposal: proposal)
        else
          raise ArgumentError, "unsupported test mode: #{proposal.fetch('required_test_mode')}"
        end
      end

      def build_replay_backtest(proposal:)
        replay_bundle = replay_input_resolver.resolve_for_proposal(proposal_id: proposal.fetch("proposal_id"))
        readiness = replay_bundle.fetch("replay_readiness")

        {
          "proposal_id" => proposal.fetch("proposal_id"),
          "test_mode" => "replay",
          "input_refs" => replay_input_refs(replay_bundle),
          "input_origin_refs" => proposal.fetch("source_repository_refs"),
          "result_label" => "untested",
          "observed_effect" => if readiness == "ready"
                                 "Replay input bundle is ready, but step-level replay execution is not yet implemented."
                               else
                                 "Replay is blocked until required inputs are resolved."
                               end,
          "risk_observations" => replay_risks(replay_bundle),
          "tested_at" => Time.now.utc.iso8601
        }
      end

      def build_analysis_backtest(proposal:)
        evaluation_match = supporting_evaluation_evidence(proposal: proposal)

        {
          "proposal_id" => proposal.fetch("proposal_id"),
          "test_mode" => "backtest",
          "input_refs" => evaluation_match.fetch("input_refs"),
          "input_origin_refs" => proposal.fetch("source_repository_refs"),
          "result_label" => evaluation_match.fetch("result_label"),
          "observed_effect" => evaluation_match.fetch("observed_effect"),
          "risk_observations" => evaluation_match.fetch("risk_observations"),
          "tested_at" => Time.now.utc.iso8601
        }
      end

      def build_manual_review_backtest(proposal:)
        {
          "proposal_id" => proposal.fetch("proposal_id"),
          "test_mode" => "manual_review",
          "input_refs" => proposal.fetch("source_evidence_refs"),
          "input_origin_refs" => proposal.fetch("source_repository_refs"),
          "result_label" => "untested",
          "observed_effect" => "This proposal requires human review of workflow or validation behavior before adoption.",
          "risk_observations" => manual_review_risks(proposal),
          "tested_at" => Time.now.utc.iso8601
        }
      end

      def replay_input_refs(replay_bundle)
        inputs = replay_bundle.fetch("replay_inputs")
        [
          inputs["review_case_ref"],
          *inputs.fetch("step_refs"),
          inputs["decision_unit_ref"],
          inputs["validator_result_ref"],
          inputs["invalidation_markers_ref"]
        ].compact
      end

      def replay_risks(replay_bundle)
        missing = replay_bundle.fetch("replay_inputs").fetch("missing_refs")
        risks = []
        risks << "Replay execution logic is not implemented yet." if replay_bundle.fetch("replay_readiness") == "ready"
        risks << "Missing replay inputs: #{missing.join(', ')}" if missing.any?
        risks.empty? ? ["No additional replay risk observed."] : risks
      end

      def manual_review_risks(proposal)
        risks = ["Result remains untested until a human review gate is performed."]
        risks << "Evidence maturity is #{proposal.fetch('evidence_maturity_context')}." unless proposal.fetch("evidence_maturity_context") == "valid"
        risks
      end

      def supporting_evaluation_evidence(proposal:)
        signal_id = proposal.fetch("source_signal_id")
        recurring_entries = load_entries(repo_root.join("learning/findings/recurring_failure_signals.json"))
        signal_entry = recurring_entries.find { |entry| entry["signal_id"] == signal_id }

        case proposal.fetch("source_signal_id")
        when /unresolved_judgment_labels/
          unresolved = finding_metrics_by_run_id.dig(proposal.fetch("source_repository_refs").first.fetch("run_id"), "judgment_label_distribution", "unresolved_judgment_labels").to_i
          if unresolved.positive?
            {
              "input_refs" => ["experiments/analysis/metrics/finding_metrics.json"],
              "result_label" => "supported",
              "observed_effect" => "Finding metrics record unresolved judgment labels for this run, substantiating the schema-oriented proposal.",
              "risk_observations" => proposal_backtest_risks(proposal: proposal)
            }
          else
            unsupported_backtest("Finding metrics did not preserve unresolved judgment labels for this run.")
          end
        when /caveat_observed/
          code = proposal.fetch("source_evidence_refs").first.to_s.split("#").last
          present = caveat_codes.include?(code)
          if present
            {
              "input_refs" => ["experiments/analysis/caveats/caveat_register.json"],
              "result_label" => "supported",
              "observed_effect" => "Evaluation caveat register contains the cited caveat, so the workflow concern is preserved in analysis artifacts.",
              "risk_observations" => proposal_backtest_risks(proposal: proposal)
            }
          else
            unsupported_backtest("Caveat register does not contain the cited caveat code.")
          end
        else
          if signal_entry
            {
              "input_refs" => signal_entry.fetch("source_refs"),
              "result_label" => proposal.fetch("evidence_maturity_context") == "exploratory" ? "inconclusive" : "supported",
              "observed_effect" => if proposal.fetch("evidence_maturity_context") == "exploratory"
                                     "Signal is present, but only exploratory evidence currently supports this proposal."
                                   else
                                     "Signal inventory preserves the cited evidence for this proposal."
                                   end,
              "risk_observations" => proposal_backtest_risks(proposal: proposal)
            }
          else
            unsupported_backtest("No supporting signal inventory entry was found for this proposal.")
          end
        end
      end

      def unsupported_backtest(message)
        {
          "input_refs" => [],
          "result_label" => "unsupported",
          "observed_effect" => message,
          "risk_observations" => ["Proposal evidence could not be substantiated from current analysis artifacts."]
        }
      end

      def proposal_backtest_risks(proposal:)
        risks = []
        risks << "Evidence is exploratory and should not be treated as strong adoption support." if proposal.fetch("evidence_maturity_context") == "exploratory"
        risks << "Imported evidence should preserve admission context during downstream review." if proposal.fetch("source_origin") == "imported_external_bundle"
        risks.empty? ? ["No additional backtest risk observed."] : risks
      end

      def finding_metrics_by_run_id
        @finding_metrics_by_run_id ||= load_entries(repo_root.join("experiments/analysis/metrics/finding_metrics.json")).each_with_object({}) do |entry, acc|
          acc[entry["run_id"]] = entry
        end
      end

      def caveat_codes
        @caveat_codes ||= load_entries(repo_root.join("experiments/analysis/caveats/caveat_register.json")).map { |entry| entry["caveat_code"] }
      end

      def load_entries(path)
        return [] unless path.exist?

        JSON.parse(path.read).fetch("entries", [])
      end
    end
  end
end
