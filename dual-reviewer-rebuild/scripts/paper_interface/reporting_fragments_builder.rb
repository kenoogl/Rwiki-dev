#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "yaml"
require "time"

module DualReviewer
  module PaperInterface
    class ReportingFragmentsBuilder
      CLAIM_MAP_REF = "paper/reports/claim_map.json"
      PAPER_CAVEAT_REF = "paper/caveats/paper_caveat_register.json"
      ANALYSIS_MANIFEST_REF = "experiments/analysis/manifests/analysis_run_manifest.yaml"

      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def build_reporting_fragments
        claim_map = JSON.parse(repo_root.join(CLAIM_MAP_REF).read)
        paper_caveats = JSON.parse(repo_root.join(PAPER_CAVEAT_REF).read)
        manifest = YAML.load_file(repo_root.join(ANALYSIS_MANIFEST_REF))

        claim_fragments = claim_map.fetch("entries").map do |claim|
          {
            "fragment_id" => "fragment-#{claim.fetch('claim_id')}",
            "fragment_type" => fragment_type_for_claim(claim),
            "source_artifact_refs" => claim.fetch("supporting_artifact_refs"),
            "maturity_label" => claim.fetch("maturity_label"),
            "caveat_refs" => claim.fetch("caveat_refs"),
            "text_stub" => claim_text_stub(claim)
          }
        end

        limitation_fragments = paper_caveats.fetch("entries").map do |caveat|
          {
            "fragment_id" => "fragment-#{caveat.fetch('caveat_id')}",
            "fragment_type" => "limitation_note",
            "source_artifact_refs" => [caveat.fetch("source_caveat_ref"), *caveat.fetch("applies_to_artifact_refs")],
            "maturity_label" => "preliminary",
            "caveat_refs" => [caveat.fetch("source_caveat_ref")],
            "text_stub" => caveat.fetch("narrative_note")
          }
        end

        method_note_fragment = {
          "fragment_id" => "fragment-method-analysis-provenance",
          "fragment_type" => "method_note",
          "source_artifact_refs" => [ANALYSIS_MANIFEST_REF],
          "maturity_label" => "mature",
          "caveat_refs" => [],
          "text_stub" => "Analysis was generated with logic version #{manifest['analysis_logic_version']} over input runs #{Array(manifest['input_run_set']).join(', ')}."
        }

        {
          "generated_at" => Time.now.utc.iso8601,
          "entries" => [*claim_fragments, *limitation_fragments, method_note_fragment]
        }
      end

      private

      def fragment_type_for_claim(claim)
        case claim.fetch("claim_id")
        when "claim-phase-comparison-summary"
          "comparison_summary"
        else
          "claim_summary"
        end
      end

      def claim_text_stub(claim)
        suffix = if claim.fetch("caveat_refs").empty?
                   "No caveat is currently attached to this fragment."
                 else
                   "This fragment should be reported with caveat context."
                 end
        "#{claim.fetch('claim_text')} #{suffix}"
      end
    end
  end
end
