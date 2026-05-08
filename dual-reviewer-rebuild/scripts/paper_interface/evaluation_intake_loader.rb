#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "yaml"

module DualReviewer
  module PaperInterface
    class EvaluationIntakeLoader
      REQUIRED_ARTIFACTS = {
        "analysis_run_manifest" => "manifests/analysis_run_manifest.yaml",
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

      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def load_analysis(analysis_root:)
        root = Pathname(analysis_root).expand_path
        required_artifacts, missing_required = load_artifact_group(root: root, artifact_map: REQUIRED_ARTIFACTS)
        optional_artifacts, missing_optional = load_artifact_group(root: root, artifact_map: OPTIONAL_ARTIFACTS)

        {
          "analysis_root" => root.to_s,
          "required_artifacts" => REQUIRED_ARTIFACTS,
          "optional_artifacts" => OPTIONAL_ARTIFACTS,
          "missing_required_artifacts" => missing_required,
          "missing_optional_artifacts" => missing_optional,
          "intake_status" => missing_required.empty? ? "complete" : "incomplete",
          "artifacts" => required_artifacts.merge(optional_artifacts),
          "summary" => build_summary(required_artifacts: required_artifacts, optional_artifacts: optional_artifacts)
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

        {
          "analysis_logic_version" => manifest["analysis_logic_version"],
          "input_run_set" => manifest["input_run_set"] || [],
          "comparison_contract_version" => manifest["comparison_contract_version"],
          "treatment_comparison_status" => treatment_comparisons["comparison_status"],
          "phase_comparison_status" => phase_comparisons["comparison_status"],
          "excluded_entry_count" => exclusion_report.fetch("entries", []).length,
          "caveat_count" => caveat_register.fetch("entries", []).length,
          "treatment_metric_count" => treatment_metrics.fetch("entries", []).length
        }
      end
    end
  end
end
