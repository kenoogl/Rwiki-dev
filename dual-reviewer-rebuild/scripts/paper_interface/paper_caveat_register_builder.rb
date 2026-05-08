#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "time"

module DualReviewer
  module PaperInterface
    class PaperCaveatRegisterBuilder
      CLAIM_MAP_REF = "paper/reports/claim_map.json"
      TABLE_BUNDLE_REF = "paper/tables/table_source_bundle.json"
      FIGURE_BUNDLE_REF = "paper/figures/figure_source_bundle.json"
      EVALUATION_CAVEAT_REF = "experiments/analysis/caveats/caveat_register.json"

      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def build_paper_caveat_register
        claim_map = JSON.parse(repo_root.join(CLAIM_MAP_REF).read)
        table_bundle = JSON.parse(repo_root.join(TABLE_BUNDLE_REF).read)
        figure_bundle = JSON.parse(repo_root.join(FIGURE_BUNDLE_REF).read)
        evaluation_caveats = JSON.parse(repo_root.join(EVALUATION_CAVEAT_REF).read)

        {
          "generated_at" => Time.now.utc.iso8601,
          "entries" => evaluation_caveats.fetch("entries").map do |entry|
            build_entry(
              entry: entry,
              claim_map: claim_map,
              table_bundle: table_bundle,
              figure_bundle: figure_bundle
            )
          end
        }
      end

      private

      def build_entry(entry:, claim_map:, table_bundle:, figure_bundle:)
        source_ref = "#{EVALUATION_CAVEAT_REF}##{entry.fetch('caveat_code')}"
        {
          "caveat_id" => "paper-caveat-#{entry.fetch('caveat_code')}",
          "source_caveat_ref" => source_ref,
          "applies_to_claim_refs" => claim_refs_for(source_ref: source_ref, claim_map: claim_map),
          "applies_to_artifact_refs" => artifact_refs_for(source_ref: source_ref, table_bundle: table_bundle, figure_bundle: figure_bundle),
          "limitation_type" => limitation_type_for(entry.fetch("affected_scope")),
          "narrative_note" => narrative_note_for(entry: entry)
        }
      end

      def claim_refs_for(source_ref:, claim_map:)
        claim_map.fetch("entries")
                 .select { |claim| claim.fetch("caveat_refs").include?(source_ref) }
                 .map { |claim| "paper/reports/claim_map.json##{claim.fetch('claim_id')}" }
      end

      def artifact_refs_for(source_ref:, table_bundle:, figure_bundle:)
        refs = []
        table_bundle.fetch("entries").each do |entry|
          refs << "paper/tables/table_source_bundle.json##{entry.fetch('table_id')}" if entry.fetch("caveat_refs").include?(source_ref)
        end
        figure_bundle.fetch("entries").each do |entry|
          refs << "paper/figures/figure_source_bundle.json##{entry.fetch('figure_id')}" if entry.fetch("caveat_refs").include?(source_ref)
        end
        refs
      end

      def limitation_type_for(affected_scope)
        case affected_scope
        when "treatment_comparison"
          "insufficient_comparison_coverage"
        when "phase_comparison"
          "phase_slice_constraint"
        else
          "analysis_caveat"
        end
      end

      def narrative_note_for(entry:)
        "Paper-facing limitation: #{entry.fetch('details')} This caveat should remain attached to any claim or artifact that depends on #{entry.fetch('affected_scope')}."
      end
    end
  end
end
