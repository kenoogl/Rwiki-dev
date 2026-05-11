#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "time"

module DualReviewer
  module SelfImprovement
    class RemediationTemplateBuilder
      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def build_templates
        pattern_candidates.map do |candidate|
          next unless candidate["signal_class"] == "workflow_failure_signal"
          next unless candidate["source_signal_id"].to_s.start_with?("aggregate:invalid_run_triage:")

          build_template(candidate: candidate)
        end.compact
      end

      private

      def build_template(candidate:)
        failure_mode_code = candidate.fetch("source_signal_id").split(":").last

        {
          "template_id" => "workflow-remediation-#{failure_mode_code.gsub(/[^a-zA-Z0-9]+/, '-').downcase}",
          "failure_mode_code" => failure_mode_code,
          "candidate_ref" => "learning/findings/pattern_candidates.json##{candidate.fetch('candidate_id')}",
          "linked_proposal_ids" => candidate.fetch("linked_proposal_ids", []),
          "recommended_actions" => recommended_actions(failure_mode_code: failure_mode_code, candidate: candidate),
          "operator_checklist" => operator_checklist(failure_mode_code: failure_mode_code, candidate: candidate),
          "supporting_signal_ids" => candidate.fetch("supporting_signal_ids", []),
          "created_at" => Time.now.utc.iso8601
        }
      end

      def recommended_actions(failure_mode_code:, candidate:)
        case failure_mode_code
        when "invalidation_marker_present"
          [
            "Review the invalidation marker reason before rerunning or excluding the run.",
            "Check whether the cited invalidation reason is mirrored by validator check failures.",
            "Decide whether this should be treated as a rerun candidate or a permanently excluded run."
          ]
        when "validator_check_failed"
          [
            "Resolve failed validator checks before admitting the run into downstream analysis.",
            "Verify that required metadata, review mode, and close conditions are satisfied.",
            "Do not promote the run into valid/exploratory populations until validator status is repaired."
          ]
        else
          generic_actions(candidate: candidate)
        end
      end

      def operator_checklist(failure_mode_code:, candidate:)
        base = []
        base << "Inspect supporting workflow signals: #{candidate.fetch('supporting_signal_ids', []).join(', ')}" if candidate.fetch("supporting_signal_ids", []).any?
        base << "Inspect triage reason codes: #{candidate.fetch('triage_reason_codes', []).join(', ')}" if candidate.fetch("triage_reason_codes", []).any?
        base << "Inspect linked check ids: #{candidate.fetch('triage_check_ids', []).join(', ')}" if candidate.fetch("triage_check_ids", []).any?

        if failure_mode_code == "invalidation_marker_present"
          base << "Confirm whether the invalidation scope is run-level or finding-level before deciding remediation."
        end

        base
      end

      def generic_actions(candidate:)
        [
          "Review the grouped workflow failure signals and identify the earliest guard that could have blocked the invalid run.",
          "Use the linked proposal set to decide whether a workflow guard or schema/policy change is the right remediation surface.",
          "Keep remediation scoped to repeated workflow failure modes rather than isolated operator mistakes."
        ]
      end

      def pattern_candidates
        @pattern_candidates ||= begin
          path = repo_root.join("learning/findings/pattern_candidates.json")
          return [] unless path.exist?

          JSON.parse(path.read).fetch("entries", [])
        end
      end
    end
  end
end
