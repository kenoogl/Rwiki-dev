#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

module DualReviewer
  module Evaluation
    class MetricWriter
      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def write_run_metrics(run_metrics:)
        write_register(
          register_path: repo_root.join("experiments/analysis/metrics/run_metrics.json"),
          top_level_key: "entries",
          entry: run_metrics
        )
      end

      def write_finding_metrics(finding_metrics:)
        write_register(
          register_path: repo_root.join("experiments/analysis/metrics/finding_metrics.json"),
          top_level_key: "entries",
          entry: finding_metrics
        )
      end

      private

      def write_register(register_path:, top_level_key:, entry:)
        payload = if register_path.exist?
                    JSON.parse(register_path.read)
                  else
                    { top_level_key => [] }
                  end
        payload[top_level_key] << entry
        register_path.write(JSON.pretty_generate(payload))
        register_path
      end
    end
  end
end
