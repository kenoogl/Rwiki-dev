#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "yaml"
require "pathname"

module DualReviewer
  module Evaluation
    class LocalRunLoader
      REQUIRED_ARTIFACTS = {
        "run_manifest" => "run_manifest.yaml",
        "review_case" => "review_case.json",
        "decision_units" => "decisions/decision_units.json",
        "validator_result" => "validation/validator_result.json",
        "invalidation_markers" => "validation/invalidation_markers.json"
      }.freeze

      OPTIONAL_ARTIFACTS = {
        "comparison_eligibility_note" => "derived/comparison_eligibility_note.json",
        "invalid_run_triage_note" => "derived/invalid_run_triage_note.json",
        "v2_review_artifact" => "v2/review_artifact.json",
        "v2_metric_snapshot" => "v2/metric_snapshot.json",
        "v2_trace_note" => "v2/trace_note.json",
        "v2_signal_linkage_note" => "v2/signal_linkage_note.json"
      }.freeze

      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def load_run(run_root:)
        root = Pathname(run_root).expand_path
        artifacts = {}
        missing_artifacts = []

        REQUIRED_ARTIFACTS.each do |artifact_name, relative_path|
          artifact_path = root.join(relative_path)
          if artifact_path.exist?
            artifacts[artifact_name] = load_artifact(artifact_path)
          else
            missing_artifacts << relative_path
          end
        end

        OPTIONAL_ARTIFACTS.each do |artifact_name, relative_path|
          artifact_path = root.join(relative_path)
          artifacts[artifact_name] = load_artifact(artifact_path) if artifact_path.exist?
        end

        {
          "run_root" => root.to_s,
          "required_artifacts" => REQUIRED_ARTIFACTS,
          "optional_artifacts" => OPTIONAL_ARTIFACTS,
          "missing_artifacts" => missing_artifacts,
          "intake_status" => missing_artifacts.empty? ? "complete" : "incomplete",
          "artifacts" => artifacts,
          "metadata" => extract_metadata(artifacts)
        }
      end

      private

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

      def extract_metadata(artifacts)
        run_manifest_metadata = artifacts.fetch("run_manifest", {}).fetch("metadata", {})
        review_case_metadata = artifacts.fetch("review_case", {}).fetch("metadata", {})

        {
          "run_id" => run_manifest_metadata["run_id"] || review_case_metadata["run_id"],
          "phase_profile" => run_manifest_metadata["phase_profile"] || review_case_metadata["phase_profile"],
          "treatment" => run_manifest_metadata["treatment"] || review_case_metadata["treatment"],
          "review_mode" => run_manifest_metadata["review_mode"] || review_case_metadata["review_mode"],
          "run_status" => run_manifest_metadata["run_status"] || review_case_metadata["run_status"],
          "validator_status" => run_manifest_metadata["validator_status"] || review_case_metadata["validator_status"],
          "human_signoff_status" => run_manifest_metadata["human_signoff_status"] || review_case_metadata["human_signoff_status"],
          "evidence_class" => run_manifest_metadata["evidence_class"] || review_case_metadata["evidence_class"]
        }
      end
    end
  end
end
