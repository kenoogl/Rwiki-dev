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

        proposals_by_signal_id = load_proposals.group_by { |proposal| proposal["source_signal_id"] }

        signals.map do |signal|
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
            "linked_proposal_ids" => linked_proposals.map { |proposal| proposal["proposal_id"] },
            "created_at" => Time.now.utc.iso8601
          }
        end
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
