#!/usr/bin/env ruby
# frozen_string_literal: true

module DualReviewer
  module Evaluation
    class CaveatBuilder
      LOW_SAMPLE_THRESHOLD = 2

      def build(classification_entries:, treatment_comparisons:, phase_comparisons:)
        caveats = []

        valid_entries = classification_entries.select { |entry| entry["classification"] == "valid" }
        exploratory_entries = classification_entries.select { |entry| entry["classification"] == "exploratory" }
        available_treatments = treatment_comparisons.fetch("available_treatments", [])

        if valid_entries.length < LOW_SAMPLE_THRESHOLD
          caveats << caveat(
            caveat_code: "low_sample_size",
            severity: "warning",
            details: "Valid population has fewer than #{LOW_SAMPLE_THRESHOLD} runs.",
            affected_scope: "global"
          )
        end

        if available_treatments.length < 2
          caveats << caveat(
            caveat_code: "single_treatment_only",
            severity: "warning",
            details: "Only one treatment is present in valid population, so treatment comparison is not meaningful.",
            affected_scope: "treatment_comparison"
          )
        end

        if valid_entries.empty? && exploratory_entries.any?
          caveats << caveat(
            caveat_code: "exploratory_only_slice",
            severity: "warning",
            details: "Current analysis slice has exploratory runs but no valid runs.",
            affected_scope: "global"
          )
        end

        if phase_comparisons.fetch("available_phases", []).empty?
          caveats << caveat(
            caveat_code: "no_valid_phase_slice",
            severity: "warning",
            details: "No valid phase slice is available for phase-aware comparison.",
            affected_scope: "phase_comparison"
          )
        end

        caveats
      end

      private

      def caveat(caveat_code:, severity:, details:, affected_scope:)
        {
          "caveat_code" => caveat_code,
          "severity" => severity,
          "details" => details,
          "affected_scope" => affected_scope
        }
      end
    end
  end
end
