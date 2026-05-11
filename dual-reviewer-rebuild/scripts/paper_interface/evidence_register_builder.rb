#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "time"
require "yaml"
require_relative "evaluation_intake_loader"

module DualReviewer
  module PaperInterface
    class EvidenceRegisterBuilder
      CLAIM_MAP_REF = "paper/reports/claim_map.json"
      ANALYSIS_MANIFEST_REF = "experiments/analysis/manifests/analysis_run_manifest.yaml"

      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def build_evidence_register
        claim_map = JSON.parse(repo_root.join(CLAIM_MAP_REF).read)
        manifest = YAML.load_file(repo_root.join(ANALYSIS_MANIFEST_REF))
        validation_summary_refs = runtime_validation_summary_refs_for(run_ids: Array(manifest["input_run_set"]))

        entries = claim_map.fetch("entries").flat_map do |claim|
          claim.fetch("supporting_artifact_refs").map do |artifact_ref|
            {
              "artifact_ref" => artifact_ref,
              "source_analysis_manifest_ref" => ANALYSIS_MANIFEST_REF,
              "input_run_set_ref" => Array(manifest["input_run_set"]).map { |run_id| "#{ANALYSIS_MANIFEST_REF}##{run_id}" },
              "runtime_validation_summary_refs" => validation_summary_refs,
              "maturity_label" => claim.fetch("maturity_label"),
              "caveat_refs" => relevant_caveat_refs(claim: claim, artifact_ref: artifact_ref),
              "generated_at" => Time.now.utc.iso8601
            }
          end
        end

        {
          "generated_at" => Time.now.utc.iso8601,
          "entries" => dedupe_entries(entries)
        }
      end

      private

      def relevant_caveat_refs(claim:, artifact_ref:)
        return [] unless claim.fetch("supporting_artifact_refs").include?(artifact_ref)

        claim.fetch("caveat_refs")
      end

      def dedupe_entries(entries)
        grouped = entries.group_by { |entry| entry["artifact_ref"] }
        grouped.map do |_artifact_ref, grouped_entries|
          first = grouped_entries.first.dup
          first["caveat_refs"] = grouped_entries.flat_map { |entry| entry["caveat_refs"] }.uniq
          first["runtime_validation_summary_refs"] = grouped_entries.flat_map { |entry| entry["runtime_validation_summary_refs"] }.uniq
          first["maturity_label"] = grouped_entries.map { |entry| maturity_rank(entry["maturity_label"]) }.min.then { |rank| maturity_label_for(rank) }
          first
        end
      end

      def runtime_validation_summary_refs_for(run_ids:)
        EvaluationIntakeLoader.new(repo_root: repo_root)
                             .discover_runtime_validation_summaries(run_ids: run_ids)
                             .fetch("entries", [])
                             .map { |entry| entry.fetch("artifact_ref") }
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
