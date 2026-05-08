#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

module DualReviewer
  module Evaluation
    class ComparisonWriter
      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def write_treatment_metrics(payload:)
        write_payload(
          repo_root.join("experiments/analysis/metrics/treatment_metrics.json"),
          payload
        )
      end

      def write_treatment_comparisons(payload:)
        write_payload(
          repo_root.join("experiments/analysis/comparisons/treatment_comparisons.json"),
          payload
        )
      end

      def write_phase_comparisons(payload:)
        write_payload(
          repo_root.join("experiments/analysis/comparisons/phase_comparisons.json"),
          payload
        )
      end

      private

      def write_payload(path, payload)
        path.write(JSON.pretty_generate(payload))
        path
      end
    end
  end
end
