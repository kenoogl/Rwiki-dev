#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require "time"
require_relative "evaluation_intake_loader"

module DualReviewer
  module PaperInterface
    class ClaimMapBuilder
      ANALYSIS_MANIFEST_REF = "experiments/analysis/manifests/analysis_run_manifest.yaml"
      TREATMENT_COMPARISON_REF = "experiments/analysis/comparisons/treatment_comparisons.json"
      PHASE_COMPARISON_REF = "experiments/analysis/comparisons/phase_comparisons.json"
      EXCLUSION_REPORT_REF = "experiments/analysis/classifications/exclusion_report.json"
      CAVEAT_REGISTER_REF = "experiments/analysis/caveats/caveat_register.json"

      attr_reader :repo_root, :evaluation_intake_loader

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
        @evaluation_intake_loader = EvaluationIntakeLoader.new(repo_root: @repo_root)
      end

      def build_claim_map(analysis_root:)
        intake = evaluation_intake_loader.load_analysis(analysis_root: analysis_root)
        artifacts = intake.fetch("artifacts")
        manifest = artifacts.fetch("analysis_run_manifest")
        caveat_entries = artifacts.fetch("caveat_register").fetch("entries", [])

        {
          "generated_at" => Time.now.utc.iso8601,
          "entries" => [
            build_phase_claim(artifacts: artifacts, manifest: manifest, caveat_entries: caveat_entries),
            build_treatment_claim(artifacts: artifacts, manifest: manifest, caveat_entries: caveat_entries),
            build_exclusion_claim(artifacts: artifacts, manifest: manifest, caveat_entries: caveat_entries)
          ]
        }
      end

      private

      def build_phase_claim(artifacts:, manifest:, caveat_entries:)
        phase_comparisons = artifacts.fetch("phase_comparisons")
        phase_slices = phase_comparisons.fetch("phase_slices", [])
        first_slice = phase_slices.first || {}
        {
          "claim_id" => "claim-phase-comparison-summary",
          "claim_text" => if phase_comparisons["comparison_status"] == "valid"
                           "Phase-aware comparison is available for the current analysis set, anchored at #{first_slice['phase_profile']}."
                         else
                           "Phase-aware comparison is not yet available for the current analysis set."
                         end,
          "supporting_artifact_refs" => [PHASE_COMPARISON_REF],
          "maturity_label" => phase_comparisons["comparison_status"] == "valid" ? "mature" : "preliminary",
          "caveat_refs" => caveat_refs_for_scope(caveat_entries, "phase_comparison"),
          "provenance_refs" => provenance_refs(artifacts: artifacts, manifest: manifest)
        }
      end

      def build_treatment_claim(artifacts:, manifest:, caveat_entries:)
        treatment_comparisons = artifacts.fetch("treatment_comparisons")
        invalid_reasons = treatment_comparisons.fetch("comparison_invalid_reason", [])
        {
          "claim_id" => "claim-treatment-comparison-status",
          "claim_text" => if treatment_comparisons["comparison_status"] == "valid"
                           "Treatment comparison is available for the current analysis set."
                         else
                           "Treatment comparison is not yet supportable for the current analysis set because #{invalid_reasons.join(', ')}."
                         end,
          "supporting_artifact_refs" => [TREATMENT_COMPARISON_REF, CAVEAT_REGISTER_REF],
          "maturity_label" => treatment_comparisons["comparison_status"] == "valid" ? "mature" : "preliminary",
          "caveat_refs" => caveat_refs_for_scope(caveat_entries, "treatment_comparison"),
          "provenance_refs" => provenance_refs(artifacts: artifacts, manifest: manifest)
        }
      end

      def build_exclusion_claim(artifacts:, manifest:, caveat_entries:)
        exclusion_entries = artifacts.fetch("exclusion_report").fetch("entries", [])
        has_nonvalid = exclusion_entries.any? { |entry| entry["classification"] != "valid" }
        {
          "claim_id" => "claim-analysis-population-transparency",
          "claim_text" => if has_nonvalid
                           "Analysis population exclusions are explicitly recorded and should be reported alongside any claim."
                         else
                           "Current analysis population contains only valid entries, but exclusion reporting remains part of the evidence trail."
                         end,
          "supporting_artifact_refs" => [EXCLUSION_REPORT_REF, ANALYSIS_MANIFEST_REF],
          "maturity_label" => has_nonvalid ? "mature" : "preliminary",
          "caveat_refs" => caveat_entries.map { |entry| "#{CAVEAT_REGISTER_REF}##{entry['caveat_code']}" },
          "provenance_refs" => provenance_refs(artifacts: artifacts, manifest: manifest)
        }
      end

      def provenance_refs(artifacts:, manifest:)
        runtime_validation_summary_refs = artifacts
          .fetch("runtime_validation_summaries", {})
          .fetch("entries", [])
          .map { |entry| entry.fetch("artifact_ref") }

        [
          ANALYSIS_MANIFEST_REF,
          "analysis_logic_version:#{manifest['analysis_logic_version']}",
          "input_run_set:#{Array(manifest['input_run_set']).join(',')}"
        ] + runtime_validation_summary_refs
      end

      def caveat_refs_for_scope(caveat_entries, scope)
        caveat_entries
          .select { |entry| entry["affected_scope"] == scope }
          .map { |entry| "#{CAVEAT_REGISTER_REF}##{entry['caveat_code']}" }
      end
    end
  end
end
