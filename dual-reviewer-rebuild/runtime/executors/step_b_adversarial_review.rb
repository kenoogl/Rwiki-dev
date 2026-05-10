# frozen_string_literal: true

require_relative "base_step_executor"

module DualReviewer
  module Runtime
    class StepBAdversarialReview < BaseStepExecutor
      FOUNDATION_PROMPT_RELATIVE_PATH = "runtime/prompts/adversarial/adversarial_reviewer.prompt.md"

      def step_name
        "adversarial_review"
      end

      def execute(context)
        if context.fetch(:treatment) == "single"
          return {
            "step_id" => context.fetch(:step_id),
            "step_name" => step_name,
            "step_status" => "skipped",
            "phase_profile" => context.fetch(:phase_profile),
            "treatment" => context.fetch(:treatment),
            "skip_reason" => "treatment_single_skips_adversarial_review",
            "prompt_identity" => resolved_prompt_identity(FOUNDATION_PROMPT_RELATIVE_PATH),
            "findings" => [],
            "counter_evidence" => []
          }
        end

        findings = build_rule_matched_findings(context)

        {
          "step_id" => context.fetch(:step_id),
          "step_name" => step_name,
          "step_status" => "completed",
          "phase_profile" => context.fetch(:phase_profile),
          "treatment" => context.fetch(:treatment),
          "prompt_identity" => resolved_prompt_identity(FOUNDATION_PROMPT_RELATIVE_PATH),
          "findings" => findings,
          "counter_evidence" => findings.flat_map { |finding| finding.fetch("counter_evidence_refs") }
        }
      end
    end
  end
end
