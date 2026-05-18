#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "pathname"

module DualReviewer
  module Evaluation
    class ClassificationWriter
      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def write_classification(classification_result:)
        write_register(
          register_path: repo_root.join("experiments/analysis/classifications/run_classification_index.json"),
          top_level_key: "entries",
          entry: classification_result
        )
      end

      def write_exclusion_entry(classification_result:)
        exclusion_entry = {
          "run_id" => classification_result.fetch("run_id"),
          "classification" => classification_result.fetch("classification"),
          "reason_codes" => classification_result.fetch("reason_codes"),
          "reason_details" => classification_result.fetch("reason_details"),
          "phase_profile" => classification_result.fetch("phase_profile"),
          "treatment" => classification_result.fetch("treatment")
        }

        write_register(
          register_path: repo_root.join("experiments/analysis/classifications/exclusion_report.json"),
          top_level_key: "entries",
          entry: exclusion_entry
        )
      end

      private

      def write_register(register_path:, top_level_key:, entry:)
        payload = if register_path.exist?
                    JSON.parse(register_path.read)
                  else
                    { top_level_key => [] }
                  end
        if entry["run_id"]
          payload[top_level_key].reject! { |existing| existing["run_id"] == entry["run_id"] }
        end
        payload[top_level_key] << entry
        FileUtils.mkdir_p(register_path.dirname)
        register_path.write(JSON.pretty_generate(payload))
        register_path
      end
    end
  end
end
