#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "yaml"
require "time"

module DualReviewer
  module SelfImprovement
    class PatternCandidateBuilder
      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def build_candidates
        signals = load_entries(repo_root.join("learning/findings/recurring_failure_signals.json")) +
                  load_entries(repo_root.join("learning/findings/workflow_failure_signals.json"))

        proposals = load_proposals
        proposals_by_signal_id = proposals.group_by { |proposal| proposal["source_signal_id"] }

        signal_candidates = signals.map do |signal|
          linked_proposals = proposals_by_signal_id.fetch(signal["signal_id"], [])
          {
            "candidate_id" => "pattern-#{signal.fetch('signal_id').gsub(/[^a-zA-Z0-9]+/, '-').downcase.gsub(/^-|-$/, '')}",
            "source_signal_id" => signal.fetch("signal_id"),
            "candidate_scope" => candidate_scope(signal),
            "abstraction_basis" => abstraction_basis(signal),
            "signal_class" => signal.fetch("signal_class"),
            "phase_profile" => signal["phase_profile"],
            "treatment" => signal["treatment"],
            "summary" => candidate_summary(signal),
            "linked_proposal_ids" => resolved_linked_proposal_ids(signal: signal, linked_proposals: linked_proposals, proposals: proposals),
            "created_at" => Time.now.utc.iso8601
          }
        end

        signal_candidates + build_invalid_run_triage_candidates(signals: signals, proposals: proposals)
      end

      private

      def candidate_scope(signal)
        if signal["run_id"].nil? || %w[caveat_observed unresolved_judgment_labels].include?(signal["signal_code"])
          "meta_pattern_candidate"
        else
          "project_specific_concrete"
        end
      end

      def abstraction_basis(signal)
        case candidate_scope(signal)
        when "meta_pattern_candidate"
          "cross-run-or-aggregate-analysis"
        else
          "single-project-runtime-observation"
        end
      end

      def candidate_summary(signal)
        prefix = candidate_scope(signal) == "meta_pattern_candidate" ? "Abstractable pattern candidate:" : "Project-specific pattern candidate:"
        "#{prefix} #{signal.fetch('summary')}"
      end

      def resolved_linked_proposal_ids(signal:, linked_proposals:, proposals:)
        return linked_proposals.map { |proposal| proposal["proposal_id"] } if linked_proposals.any?
        return [] unless %w[validator_failed invalidation_marker_issued].include?(signal["signal_code"])
        return [] unless signal["run_id"]

        proposals.select do |proposal|
          proposal["source_signal_id"].include?(":invalid_run_guard_gap:") &&
            proposal.dig("source_repository_refs", 0, "run_id") == signal["run_id"]
        end.map { |proposal| proposal["proposal_id"] }.uniq
      end

      def build_invalid_run_triage_candidates(signals:, proposals:)
        triage_groups = signals
          .select { |signal| signal["signal_class"] == "workflow_failure_signal" }
          .group_by { |signal| signal.dig("signal_value", "primary_failure_code") }

        triage_groups.map do |primary_failure_code, grouped_signals|
          next unless primary_failure_code

          {
            "candidate_id" => "pattern-invalid-run-triage-#{primary_failure_code.gsub(/[^a-zA-Z0-9]+/, '-').downcase}",
            "source_signal_id" => "aggregate:invalid_run_triage:#{primary_failure_code}",
            "candidate_scope" => "meta_pattern_candidate",
            "abstraction_basis" => "cross-run-invalid-triage-cluster",
            "signal_class" => "workflow_failure_signal",
            "phase_profile" => nil,
            "treatment" => nil,
            "summary" => "Abstractable pattern candidate: invalid-run triage repeatedly points to `#{primary_failure_code}` as the primary failure mode.",
            "linked_proposal_ids" => linked_invalid_run_proposals(grouped_signals: grouped_signals, proposals: proposals),
            "supporting_signal_ids" => grouped_signals.map { |signal| signal["signal_id"] }.uniq,
            "triage_reason_codes" => grouped_signals.map { |signal| signal.dig("signal_value", "reason_code") }.compact.uniq,
            "triage_check_ids" => grouped_signals.flat_map do |signal|
              Array(signal.dig("signal_value", "failed_check_ids")) + Array(signal.dig("signal_value", "linked_check_ids"))
            end.uniq,
            "created_at" => Time.now.utc.iso8601
          }
        end.compact
      end

      def linked_invalid_run_proposals(grouped_signals:, proposals:)
        run_ids = grouped_signals.map { |signal| signal["run_id"] }.compact.uniq
        proposals.select do |proposal|
          proposal["source_signal_id"].include?(":invalid_run_guard_gap:") &&
            run_ids.include?(proposal.dig("source_repository_refs", 0, "run_id"))
        end.map { |proposal| proposal["proposal_id"] }.uniq
      end

      def load_entries(path)
        return [] unless path.exist?

        JSON.parse(path.read).fetch("entries", [])
      end

      def load_proposals
        Dir[repo_root.join("learning/proposals/proposal-*.yaml")].sort.map do |path|
          YAML.load_file(path)
        end
      end
    end
  end
end
