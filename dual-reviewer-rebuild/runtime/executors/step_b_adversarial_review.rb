# frozen_string_literal: true

require_relative "base_step_executor"

module DualReviewer
  module Runtime
    class StepBAdversarialReview < BaseStepExecutor
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
            "prompt_identity" => placeholder_prompt_identity(role: "adversarial_reviewer", step: step_name),
            "findings" => [],
            "counter_evidence" => []
          }
        end

        {
          "step_id" => context.fetch(:step_id),
          "step_name" => step_name,
          "step_status" => "completed",
          "phase_profile" => context.fetch(:phase_profile),
          "treatment" => context.fetch(:treatment),
          "prompt_identity" => placeholder_prompt_identity(role: "adversarial_reviewer", step: step_name),
          "findings" => [],
          "counter_evidence" => []
        }
      end
    end
  end
end
