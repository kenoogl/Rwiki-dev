#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

module DualReviewer
  module TrackRuns
    class RuntimeValidationSummaryContract
      attr_reader :repo_root, :schema

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
        @schema = JSON.parse(repo_root.join("scripts/track_runs/contracts/runtime_validation_summary.schema.json").read)
      end

      def validate!(payload:, require_reviewed_phase: false)
        assert_required_keys!(payload, schema.fetch("required"), "runtime validation summary")
        assert(payload["schema_version"] == "1.0.0", "runtime validation summary schema_version mismatch")
        assert(%w[intent spec implementation].include?(payload["track"]), "runtime validation summary track is invalid")
        assert(%w[passed failed].include?(payload["overall_status"]), "runtime validation summary overall_status is invalid")
        assert(payload["remediation_templates"].is_a?(Array), "runtime validation summary remediation_templates must be an array")
        assert(payload["reviewed_phase"].is_a?(String) && !payload["reviewed_phase"].empty?, "runtime validation summary reviewed_phase is required for this track") if require_reviewed_phase

        template_required = schema.fetch("$defs").fetch("remediationTemplate").fetch("required")
        payload["remediation_templates"].each_with_index do |entry, index|
          assert_required_keys!(entry, template_required, "runtime validation remediation template ##{index}")
          assert(entry["recommended_actions"].is_a?(Array), "runtime validation remediation template ##{index} recommended_actions must be an array")
          assert(entry["operator_checklist"].is_a?(Array), "runtime validation remediation template ##{index} operator_checklist must be an array")
        end
      end

      private

      def assert_required_keys!(payload, required_keys, label)
        missing = required_keys.reject { |key| payload.key?(key) }
        assert(missing.empty?, "#{label} missing keys: #{missing.join(', ')}")
      end

      def assert(condition, message)
        raise message unless condition
      end
    end
  end
end
