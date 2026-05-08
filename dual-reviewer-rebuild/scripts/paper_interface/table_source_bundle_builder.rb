#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "time"

module DualReviewer
  module PaperInterface
    class TableSourceBundleBuilder
      CLAIM_MAP_REF = "paper/reports/claim_map.json"
      EVIDENCE_REGISTER_REF = "paper/reports/evidence_register.json"

      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def build_table_source_bundle
        claim_map = JSON.parse(repo_root.join(CLAIM_MAP_REF).read)
        evidence_register = JSON.parse(repo_root.join(EVIDENCE_REGISTER_REF).read)

        treatment_claim = claim_map.fetch("entries").find { |entry| entry["claim_id"] == "claim-treatment-comparison-status" }
        phase_claim = claim_map.fetch("entries").find { |entry| entry["claim_id"] == "claim-phase-comparison-summary" }
        transparency_claim = claim_map.fetch("entries").find { |entry| entry["claim_id"] == "claim-analysis-population-transparency" }

        {
          "generated_at" => Time.now.utc.iso8601,
          "entries" => [
            {
              "table_id" => "table-analysis-summary-v1",
              "source_artifact_refs" => bundled_artifact_refs(
                treatment_claim: treatment_claim,
                phase_claim: phase_claim,
                transparency_claim: transparency_claim
              ),
              "field_projection" => [
                {
                  "artifact_ref" => "experiments/analysis/comparisons/phase_comparisons.json",
                  "fields" => ["comparison_status", "available_phases", "phase_slices[].phase_profile", "phase_slices[].overlay_metric_profile", "phase_slices[].run_count"]
                },
                {
                  "artifact_ref" => "experiments/analysis/comparisons/treatment_comparisons.json",
                  "fields" => ["comparison_status", "comparison_invalid_reason", "available_treatments"]
                },
                {
                  "artifact_ref" => "experiments/analysis/classifications/exclusion_report.json",
                  "fields" => ["entries[].run_id", "entries[].classification", "entries[].reason_codes"]
                },
                {
                  "artifact_ref" => "experiments/analysis/caveats/caveat_register.json",
                  "fields" => ["entries[].caveat_code", "entries[].severity", "entries[].affected_scope"]
                }
              ],
              "maturity_label" => lowest_maturity(evidence_register: evidence_register, artifact_refs: bundled_artifact_refs(
                treatment_claim: treatment_claim,
                phase_claim: phase_claim,
                transparency_claim: transparency_claim
              )),
              "caveat_refs" => bundled_caveat_refs(
                treatment_claim: treatment_claim,
                phase_claim: phase_claim,
                transparency_claim: transparency_claim
              )
            }
          ]
        }
      end

      private

      def bundled_artifact_refs(treatment_claim:, phase_claim:, transparency_claim:)
        [
          *phase_claim.fetch("supporting_artifact_refs"),
          *treatment_claim.fetch("supporting_artifact_refs"),
          *transparency_claim.fetch("supporting_artifact_refs")
        ].uniq
      end

      def bundled_caveat_refs(treatment_claim:, phase_claim:, transparency_claim:)
        [
          *phase_claim.fetch("caveat_refs"),
          *treatment_claim.fetch("caveat_refs"),
          *transparency_claim.fetch("caveat_refs")
        ].uniq
      end

      def lowest_maturity(evidence_register:, artifact_refs:)
        register_entries = evidence_register.fetch("entries")
        relevant = register_entries.select { |entry| artifact_refs.include?(entry["artifact_ref"]) }
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
