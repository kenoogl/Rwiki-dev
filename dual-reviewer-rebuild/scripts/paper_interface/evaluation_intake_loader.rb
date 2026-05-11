#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "yaml"

module DualReviewer
  module PaperInterface
    class EvaluationIntakeLoader
      ANALYSIS_MANIFEST_REF = "manifests/analysis_run_manifest.yaml"
      REQUIRED_ARTIFACTS = {
        "analysis_run_manifest" => ANALYSIS_MANIFEST_REF,
        "treatment_comparisons" => "comparisons/treatment_comparisons.json",
        "phase_comparisons" => "comparisons/phase_comparisons.json",
        "exclusion_report" => "classifications/exclusion_report.json",
        "caveat_register" => "caveats/caveat_register.json"
      }.freeze

      OPTIONAL_ARTIFACTS = {
        "run_metrics" => "metrics/run_metrics.json",
        "finding_metrics" => "metrics/finding_metrics.json",
        "treatment_metrics" => "metrics/treatment_metrics.json"
      }.freeze

      OPTIONAL_DISCOVERED_ARTIFACTS = {
        "runtime_validation_summaries" => "discovered from experiments/protocols/**/runtime_validation_summary.yaml and experiments/protocols/**/conformance_review_result.yaml using analysis_run_manifest.input_run_set"
      }.freeze

      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def load_analysis(analysis_root:)
        root = Pathname(analysis_root).expand_path
        required_artifacts, missing_required = load_artifact_group(root: root, artifact_map: REQUIRED_ARTIFACTS)
        optional_artifacts, missing_optional = load_artifact_group(root: root, artifact_map: OPTIONAL_ARTIFACTS)
        runtime_validation_summaries = discover_runtime_validation_summaries(
          run_ids: Array(required_artifacts.dig("analysis_run_manifest", "input_run_set"))
        )
        optional_artifacts["runtime_validation_summaries"] = runtime_validation_summaries

        {
          "analysis_root" => root.to_s,
          "required_artifacts" => REQUIRED_ARTIFACTS,
          "optional_artifacts" => OPTIONAL_ARTIFACTS.merge(OPTIONAL_DISCOVERED_ARTIFACTS),
          "missing_required_artifacts" => missing_required,
          "missing_optional_artifacts" => missing_optional,
          "intake_status" => missing_required.empty? ? "complete" : "incomplete",
          "artifacts" => required_artifacts.merge(optional_artifacts),
          "summary" => build_summary(required_artifacts: required_artifacts, optional_artifacts: optional_artifacts)
        }
      end

      def discover_runtime_validation_summaries(run_ids:)
        normalized_run_ids = Array(run_ids).compact
        refs = [
          repo_root.join("experiments/protocols/**/runtime_validation_summary.yaml"),
          repo_root.join("experiments/protocols/**/conformance_review_result.yaml")
        ]

        entries = refs.flat_map do |glob_path|
          Dir.glob(glob_path.to_s).sort.map do |path|
            artifact_path = Pathname(path)
            payload = YAML.load_file(artifact_path)
            run_id = payload["run_id"]
            next if run_id.nil?
            next if normalized_run_ids.any? && !normalized_run_ids.include?(run_id)

            {
              "artifact_ref" => relative_ref(artifact_path),
              "run_id" => run_id,
              "track" => payload["track"],
              "case_id" => payload["case_id"],
              "overall_status" => payload["overall_status"],
              "primary_failure_code" => payload["primary_failure_code"],
              "operator_action_hint" => payload["operator_action_hint"]
            }
          end.compact
        end

        {
          "entries" => entries,
          "index_by_run_id" => entries.group_by { |entry| entry.fetch("run_id") }
        }
      end

      private

      def load_artifact_group(root:, artifact_map:)
        artifacts = {}
        missing = []

        artifact_map.each do |artifact_name, relative_path|
          artifact_path = root.join(relative_path)
          if artifact_path.exist?
            artifacts[artifact_name] = load_artifact(artifact_path)
          else
            missing << relative_path
          end
        end

        [artifacts, missing]
      end

      def load_artifact(path)
        case path.extname
        when ".yaml", ".yml"
          YAML.load_file(path)
        when ".json"
          JSON.parse(path.read)
        else
          raise ArgumentError, "unsupported artifact format: #{path}"
        end
      end

      def build_summary(required_artifacts:, optional_artifacts:)
        manifest = required_artifacts.fetch("analysis_run_manifest", {})
        treatment_comparisons = required_artifacts.fetch("treatment_comparisons", {})
        phase_comparisons = required_artifacts.fetch("phase_comparisons", {})
        exclusion_report = required_artifacts.fetch("exclusion_report", {})
        caveat_register = required_artifacts.fetch("caveat_register", {})
        treatment_metrics = optional_artifacts.fetch("treatment_metrics", {})
        runtime_validation_summaries = optional_artifacts.fetch("runtime_validation_summaries", {})

        {
          "analysis_logic_version" => manifest["analysis_logic_version"],
          "input_run_set" => manifest["input_run_set"] || [],
          "comparison_contract_version" => manifest["comparison_contract_version"],
          "treatment_comparison_status" => treatment_comparisons["comparison_status"],
          "phase_comparison_status" => phase_comparisons["comparison_status"],
          "excluded_entry_count" => exclusion_report.fetch("entries", []).length,
          "caveat_count" => caveat_register.fetch("entries", []).length,
          "treatment_metric_count" => treatment_metrics.fetch("entries", []).length,
          "runtime_validation_summary_count" => runtime_validation_summaries.fetch("entries", []).length
        }
      end

      def relative_ref(path)
        path.relative_path_from(repo_root).to_s
      end
    end
  end
end
