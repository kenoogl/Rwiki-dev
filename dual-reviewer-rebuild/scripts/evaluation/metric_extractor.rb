#!/usr/bin/env ruby
# frozen_string_literal: true

module DualReviewer
  module Evaluation
    class MetricExtractor
      def extract_from_run_intake(run_intake:)
        metadata = run_intake.fetch("metadata")
        review_case = run_intake.fetch("artifacts").fetch("review_case")
        decision_units = run_intake.fetch("artifacts").fetch("decision_units").fetch("decision_units", [])
        validator_result = run_intake.fetch("artifacts").fetch("validator_result")
        findings = review_case.fetch("findings", [])
        decision_unit_index = decision_units.each_with_object({}) do |unit, acc|
          acc[unit["decision_unit_id"]] = unit
        end

        {
          "run_metrics" => build_run_metrics(
            metadata: metadata,
            findings: findings,
            decision_units: decision_units,
            validator_result: validator_result
          ),
          "finding_metrics" => build_finding_metrics(
            metadata: metadata,
            findings: findings,
            decision_unit_index: decision_unit_index
          )
        }
      end

      private

      def build_run_metrics(metadata:, findings:, decision_units:, validator_result:)
        decisions = decision_units.map { |unit| unit["human_decision"] }

        {
          "run_id" => metadata["run_id"],
          "phase_profile" => metadata["phase_profile"],
          "treatment" => metadata["treatment"],
          "total_findings" => findings.length,
          "accepted_findings" => decisions.count("approved"),
          "rejected_findings" => decisions.count("rejected"),
          "deferred_findings" => decisions.count("deferred"),
          "validation_outcome" => validator_result["overall_status"]
        }
      end

      def build_finding_metrics(metadata:, findings:, decision_unit_index:)
        resolved_labels = findings.map do |finding|
          resolved_judgment_label(finding: finding, decision_unit_index: decision_unit_index)
        end.compact
        referenced_label_count = findings.count do |finding|
          truthy_string?(finding["judgment_ref"]) || truthy_string?(finding["human_decision_ref"])
        end

        {
          "run_id" => metadata["run_id"],
          "phase_profile" => metadata["phase_profile"],
          "treatment" => metadata["treatment"],
          "severity_distribution" => distribution(findings.map { |finding| finding["severity"] }),
          "source_role_distribution" => distribution(findings.map { |finding| finding["source_role"] }),
          "judgment_label_distribution" => {
            "resolved_labels" => distribution(resolved_labels),
            "judgment_ref_present" => findings.count { |finding| truthy_string?(finding["judgment_ref"]) },
            "unresolved_judgment_labels" => referenced_label_count - resolved_labels.length
          }
        }
      end

      def resolved_judgment_label(finding:, decision_unit_index:)
        return unless truthy_string?(finding["human_decision_ref"])

        decision_unit_id = finding["human_decision_ref"].to_s.split("#", 2).last
        return unless truthy_string?(decision_unit_id)

        decision_unit = decision_unit_index[decision_unit_id]
        decision_unit && decision_unit["human_decision"]
      end

      def distribution(values)
        values.compact.each_with_object({}) do |value, acc|
          acc[value] ||= 0
          acc[value] += 1
        end
      end

      def truthy_string?(value)
        value.is_a?(String) && !value.empty?
      end
    end
  end
end
