#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "time"

module DualReviewer
  module SelfImprovement
    class SignalInventoryWriter
      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def write_recurring_failure_inventory(signals:)
        payload = {
          "generated_at" => Time.now.utc.iso8601,
          "entries" => normalize_signals(signals.reject { |signal| signal["signal_class"] == "workflow_failure_signal" })
        }
        write_json(repo_root.join("learning/findings/recurring_failure_signals.json"), payload)
      end

      def write_workflow_failure_inventory(signals:)
        payload = {
          "generated_at" => Time.now.utc.iso8601,
          "entries" => normalize_signals(signals.select { |signal| signal["signal_class"] == "workflow_failure_signal" })
        }
        write_json(repo_root.join("learning/findings/workflow_failure_signals.json"), payload)
      end

      private

      def normalize_signals(signals)
        signals
          .uniq { |signal| signal["signal_id"] }
          .map do |signal|
            {
              "signal_id" => signal.fetch("signal_id"),
              "signal_class" => signal.fetch("signal_class"),
              "signal_code" => signal.fetch("signal_code"),
              "signal_source" => signal.fetch("signal_source"),
              "source_refs" => signal.fetch("source_refs"),
              "summary" => signal.fetch("summary"),
              "validity_context" => signal.fetch("evidence_maturity"),
              "phase_profile" => signal["phase_profile"],
              "treatment" => signal["treatment"],
              "run_id" => signal["run_id"],
              "signal_value" => signal.fetch("signal_value")
            }
          end
      end

      def write_json(path, payload)
        path.write(JSON.pretty_generate(payload))
        path
      end
    end
  end
end
