#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "time"
require "yaml"

module DualReviewer
  module Evaluation
    class AnalysisManifestWriter
      ANALYSIS_LOGIC_VERSION = "0.1.0"
      METRIC_SET_VERSION = "0.1.0"
      PHASE_METRIC_PROFILE_VERSION = "overlay-v1"
      COMPARISON_CONTRACT_VERSION = "0.1.0"
      RUNTIME_VALIDATION_SUMMARY_GLOBS = [
        "experiments/protocols/**/runtime_validation_summary.yaml",
        "experiments/protocols/**/conformance_review_result.yaml"
      ].freeze

      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def write_manifest
        run_set = input_run_set
        validation_summary_coverage = runtime_validation_summary_coverage(run_ids: run_set)
        manifest = {
          "analysis_logic_version" => ANALYSIS_LOGIC_VERSION,
          "input_run_set" => run_set,
          "generated_at" => Time.now.utc.iso8601,
          "metric_set_version" => METRIC_SET_VERSION,
          "phase_metric_profile_version" => PHASE_METRIC_PROFILE_VERSION,
          "comparison_contract_version" => COMPARISON_CONTRACT_VERSION,
          "runtime_validation_summary_coverage" => validation_summary_coverage
        }

        path = repo_root.join("experiments/analysis/manifests/analysis_run_manifest.yaml")
        path.write(YAML.dump(manifest))
        path
      end

      private

      def input_run_set
        run_ids = []

        run_metrics_path = repo_root.join("experiments/analysis/metrics/run_metrics.json")
        if run_metrics_path.exist?
          run_metrics = JSON.parse(run_metrics_path.read).fetch("entries", [])
          run_ids.concat(run_metrics.map { |entry| entry["run_id"] })
        end

        admission_register_path = repo_root.join("experiments/analysis/imports/admission_register.json")
        if admission_register_path.exist?
          admission_entries = JSON.parse(admission_register_path.read).fetch("entries", [])
          run_ids.concat(admission_entries.map { |entry| entry["run_id"] })
        end

        run_ids.compact.uniq.sort
      end

      def runtime_validation_summary_coverage(run_ids:)
        entries = discover_runtime_validation_summaries(run_ids: run_ids)
        covered_run_ids = entries.map { |entry| entry.fetch("run_id") }.uniq.sort

        {
          "input_run_count" => run_ids.length,
          "covered_run_count" => covered_run_ids.length,
          "missing_run_ids" => (run_ids - covered_run_ids).sort,
          "summary_artifact_refs" => entries.map { |entry| entry.fetch("artifact_ref") }.uniq.sort
        }
      end

      def discover_runtime_validation_summaries(run_ids:)
        normalized_run_ids = Array(run_ids).compact

        RUNTIME_VALIDATION_SUMMARY_GLOBS.flat_map do |glob|
          Dir.glob(repo_root.join(glob).to_s).sort.map do |path|
            artifact_path = Pathname(path)
            payload = YAML.load_file(artifact_path)
            run_id = payload["run_id"]
            next if run_id.nil?
            next if normalized_run_ids.any? && !normalized_run_ids.include?(run_id)

            {
              "artifact_ref" => artifact_path.relative_path_from(repo_root).to_s,
              "run_id" => run_id
            }
          end.compact
        end
      end
    end
  end
end
