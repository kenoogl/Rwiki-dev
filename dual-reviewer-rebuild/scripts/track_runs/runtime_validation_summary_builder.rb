#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

module DualReviewer
  module TrackRuns
    class RuntimeValidationSummaryBuilder
      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def build(run_label:, case_id:, track:, run_id:, runtime_paths:, extra_fields: {})
        triage_note = JSON.parse(Pathname(runtime_paths.fetch("invalid_run_triage_note")).read)

        {
          "schema_version" => "1.0.0",
          "run_label" => run_label,
          "case_id" => case_id,
          "track" => track,
          "run_id" => run_id,
          "validator_result_ref" => relative_to_repo(runtime_paths.fetch("validator_result")),
          "invalidation_markers_ref" => relative_to_repo(runtime_paths.fetch("invalidation_markers")),
          "comparison_eligibility_note_ref" => relative_to_repo(runtime_paths.fetch("comparison_eligibility_note")),
          "invalid_run_triage_note_ref" => relative_to_repo(runtime_paths.fetch("invalid_run_triage_note")),
          "overall_status" => triage_note.fetch("validator_status"),
          "primary_failure_code" => triage_note.fetch("primary_failure_code"),
          "operator_action_hint" => triage_note.fetch("operator_action_hint"),
          "remediation_templates" => remediation_templates_for(triage_note: triage_note)
        }.merge(extra_fields)
      end

      private

      def remediation_templates_for(triage_note:)
        path = repo_root.join("learning/templates/workflow_remediation_templates.json")
        return [] unless path.exist?

        entries = JSON.parse(path.read).fetch("entries", [])
        entries.select { |entry| entry["failure_mode_code"] == triage_note.fetch("primary_failure_code") }.map do |entry|
          {
            "template_id" => entry.fetch("template_id"),
            "template_ref" => "learning/templates/workflow_remediation_templates.json##{entry.fetch('template_id')}",
            "recommended_actions" => entry.fetch("recommended_actions"),
            "operator_checklist" => entry.fetch("operator_checklist")
          }
        end
      end

      def relative_to_repo(path)
        Pathname(path).expand_path.relative_path_from(repo_root).to_s
      end
    end
  end
end
