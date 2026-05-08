#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "time"

module DualReviewer
  module PaperInterface
    class FigureSourceBundleBuilder
      EVIDENCE_REGISTER_REF = "paper/reports/evidence_register.json"
      CLAIM_MAP_REF = "paper/reports/claim_map.json"

      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def build_figure_source_bundle
        evidence_register = JSON.parse(repo_root.join(EVIDENCE_REGISTER_REF).read)
        claim_map = JSON.parse(repo_root.join(CLAIM_MAP_REF).read)
        treatment_claim = claim_map.fetch("entries").find { |entry| entry["claim_id"] == "claim-treatment-comparison-status" }
        phase_claim = claim_map.fetch("entries").find { |entry| entry["claim_id"] == "claim-phase-comparison-summary" }

        source_artifact_refs = [
          "experiments/analysis/comparisons/phase_comparisons.json",
          "experiments/analysis/metrics/treatment_metrics.json",
          "experiments/analysis/comparisons/treatment_comparisons.json"
        ]

        {
          "generated_at" => Time.now.utc.iso8601,
          "entries" => [
            {
              "figure_id" => "figure-phase-treatment-overview-v1",
              "source_artifact_refs" => source_artifact_refs,
              "plot_contract" => {
                "chart_family" => "faceted_bar_plus_status_annotation",
                "primary_slice" => "phase_profile",
                "secondary_grouping" => "treatment",
                "metric_fields" => [
                  "acceptance_ratio",
                  "findings_per_run",
                  "judgment_invocation_coverage"
                ],
                "status_annotations" => [
                  {
                    "artifact_ref" => "experiments/analysis/comparisons/phase_comparisons.json",
                    "field" => "comparison_status"
                  },
                  {
                    "artifact_ref" => "experiments/analysis/comparisons/treatment_comparisons.json",
                    "field" => "comparison_invalid_reason"
                  }
                ]
              },
              "maturity_label" => lowest_maturity(evidence_register: evidence_register, artifact_refs: source_artifact_refs),
              "caveat_refs" => bundled_caveat_refs(phase_claim: phase_claim, treatment_claim: treatment_claim)
            }
          ]
        }
      end

      private

      def bundled_caveat_refs(phase_claim:, treatment_claim:)
        [*phase_claim.fetch("caveat_refs"), *treatment_claim.fetch("caveat_refs")].uniq
      end

      def lowest_maturity(evidence_register:, artifact_refs:)
        relevant = evidence_register.fetch("entries").select { |entry| artifact_refs.include?(entry["artifact_ref"]) }
        relevant.map { |entry| maturity_rank(entry["maturity_label"]) }.max.then { |rank| maturity_label_for(rank) }
      end

      def maturity_rank(label)
        {
          "mature" => 0,
          "preliminary" => 1,
          "exploratory" => 2
        }.fetch(label)
      end

      def maturity_label_for(rank)
        {
          0 => "mature",
          1 => "preliminary",
          2 => "exploratory"
        }.fetch(rank)
      end
    end
  end
end
