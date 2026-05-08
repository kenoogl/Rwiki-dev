#!/usr/bin/env ruby
# frozen_string_literal: true

module DualReviewer
  module SelfImprovement
    class SignalClassClassifier
      REVIEW_QUALITY_CODES = %w[
        human_decision_mix
        rejected_finding_cluster
        deferred_finding_cluster
      ].freeze

      WORKFLOW_FAILURE_CODES = %w[
        validator_failed
        invalidation_marker_issued
      ].freeze

      EVIDENCE_QUALITY_CODES = %w[
        exploratory_evidence_mode
        analysis_precondition_gap
        exploratory_population_member
        analysis_blocked_population_member
        unresolved_judgment_labels
        caveat_observed
      ].freeze

      def classify(signal_code:)
        return "review_quality_signal" if REVIEW_QUALITY_CODES.include?(signal_code)
        return "workflow_failure_signal" if WORKFLOW_FAILURE_CODES.include?(signal_code)
        return "evidence_quality_signal" if EVIDENCE_QUALITY_CODES.include?(signal_code)

        raise ArgumentError, "unknown signal code for self-improvement classification: #{signal_code}"
      end
    end
  end
end
