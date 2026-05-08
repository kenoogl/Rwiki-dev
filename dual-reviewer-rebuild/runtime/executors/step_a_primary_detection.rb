# frozen_string_literal: true

require_relative "base_step_executor"

module DualReviewer
  module Runtime
    class StepAPrimaryDetection < BaseStepExecutor
      def step_name
        "primary_detection"
      end

      def execute(context)
        {
          "step_id" => context.fetch(:step_id),
          "step_name" => step_name,
          "step_status" => "completed",
          "phase_profile" => context.fetch(:phase_profile),
          "treatment" => context.fetch(:treatment),
          "target_id" => context.fetch(:target_id),
          "prompt_identity" => placeholder_prompt_identity(role: "primary_reviewer", step: step_name),
          "findings" => [],
          "counter_evidence" => []
        }
      end
    end
  end
end
