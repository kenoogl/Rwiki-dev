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

      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def write_manifest
        manifest = {
          "analysis_logic_version" => ANALYSIS_LOGIC_VERSION,
          "input_run_set" => input_run_set,
          "generated_at" => Time.now.utc.iso8601,
          "metric_set_version" => METRIC_SET_VERSION,
          "phase_metric_profile_version" => PHASE_METRIC_PROFILE_VERSION,
          "comparison_contract_version" => COMPARISON_CONTRACT_VERSION
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
    end
  end
end
