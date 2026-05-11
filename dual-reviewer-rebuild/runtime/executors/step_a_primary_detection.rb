# frozen_string_literal: true

require_relative "base_step_executor"

module DualReviewer
  module Runtime
    class StepAPrimaryDetection < BaseStepExecutor
      FOUNDATION_PROMPT_RELATIVE_PATH = "runtime/prompts/primary/primary_reviewer.prompt.md"

      def step_name
        "primary_detection"
      end

      def execute(context)
        analysis = build_rule_matched_analysis(context)
        findings = analysis.fetch("findings")

        {
          "step_id" => context.fetch(:step_id),
          "step_name" => step_name,
          "step_status" => "completed",
          "phase_profile" => context.fetch(:phase_profile),
          "treatment" => context.fetch(:treatment),
          "target_id" => context.fetch(:target_id),
          "prompt_identity" => resolved_prompt_identity(FOUNDATION_PROMPT_RELATIVE_PATH),
          "evidence_records" => analysis.fetch("evidence_records"),
          "observations" => analysis.fetch("observations"),
          "findings" => findings,
          "counter_evidence" => findings.flat_map { |finding| finding.fetch("counter_evidence_refs") }
        }
      end
    end
  end
end
