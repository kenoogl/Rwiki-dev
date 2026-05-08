#!/usr/bin/env ruby
# frozen_string_literal: true

module DualReviewer
  module Evaluation
    class ComparisonBuilder
      PHASE_OVERLAY_SELECTION = {
        "intent" => "intent_overlay_v1",
        "requirements" => "requirements_overlay_v1",
        "design" => "design_overlay_v1",
        "tasks" => "tasks_overlay_v1"
      }.freeze

      def build(run_metrics_entries:, classification_entries:)
        valid_run_ids = classification_entries
          .select { |entry| entry["classification"] == "valid" }
          .map { |entry| entry["run_id"] }

        valid_run_metrics = run_metrics_entries.select { |entry| valid_run_ids.include?(entry["run_id"]) }

        {
          "treatment_metrics" => build_treatment_metrics(valid_run_metrics),
          "treatment_comparisons" => build_treatment_comparisons(valid_run_metrics),
          "phase_comparisons" => build_phase_comparisons(valid_run_metrics)
        }
      end

      private

      def build_treatment_metrics(valid_run_metrics)
        grouped = valid_run_metrics.group_by { |entry| entry["treatment"] }
        grouped.keys.sort.map do |treatment|
          entries = grouped.fetch(treatment)
          total_runs = entries.length
          total_findings = entries.sum { |entry| entry["total_findings"] }
          accepted_findings = entries.sum { |entry| entry["accepted_findings"] }
          judgment_invocation_coverage = treatment == "dual" ? 0.0 : 1.0

          {
            "treatment" => treatment,
            "run_count" => total_runs,
            "findings_per_run" => total_runs.zero? ? 0.0 : total_findings.to_f / total_runs,
            "acceptance_ratio" => total_findings.zero? ? 0.0 : accepted_findings.to_f / total_findings,
            "judgment_invocation_coverage" => judgment_invocation_coverage
          }
        end
      end

      def build_treatment_comparisons(valid_run_metrics)
        grouped = valid_run_metrics.group_by { |entry| entry["treatment"] }
        available_treatments = grouped.keys.sort

        if available_treatments.length < 2
          return {
            "comparison_status" => "invalid",
            "comparison_invalid_reason" => ["insufficient_variant_count"],
            "available_treatments" => available_treatments,
            "comparisons" => []
          }
        end

        {
          "comparison_status" => "valid",
          "comparison_invalid_reason" => [],
          "available_treatments" => available_treatments,
          "comparisons" => pairwise_treatment_comparisons(grouped)
        }
      end

      def build_phase_comparisons(valid_run_metrics)
        grouped = valid_run_metrics.group_by { |entry| entry["phase_profile"] }
        available_phases = grouped.keys.sort

        {
          "comparison_status" => available_phases.empty? ? "invalid" : "valid",
          "comparison_invalid_reason" => available_phases.empty? ? ["no_valid_phase_population"] : [],
          "available_phases" => available_phases,
          "phase_slices" => available_phases.map do |phase|
            entries = grouped.fetch(phase)
            {
              "phase_profile" => phase,
              "overlay_metric_profile" => PHASE_OVERLAY_SELECTION.fetch(phase, "unknown_overlay"),
              "run_count" => entries.length,
              "treatments_present" => entries.map { |entry| entry["treatment"] }.uniq.sort
            }
          end
        }
      end

      def pairwise_treatment_comparisons(grouped)
        treatments = grouped.keys.sort
        treatments.combination(2).map do |left, right|
          left_entries = grouped.fetch(left)
          right_entries = grouped.fetch(right)

          {
            "left_treatment" => left,
            "right_treatment" => right,
            "comparison_status" => "valid",
            "comparison_invalid_reason" => [],
            "left_run_count" => left_entries.length,
            "right_run_count" => right_entries.length
          }
        end
      end
    end
  end
end
