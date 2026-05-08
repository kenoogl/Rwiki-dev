# frozen_string_literal: true

require_relative "base_step_executor"

module DualReviewer
  module Runtime
    class StepDIntegration < BaseStepExecutor
      def step_name
        "integration"
      end

      def execute(context)
        {
          "step_id" => context.fetch(:step_id),
          "step_name" => step_name,
          "step_status" => "completed",
          "phase_profile" => context.fetch(:phase_profile),
          "treatment" => context.fetch(:treatment),
          "prompt_identity" => placeholder_prompt_identity(role: "integration", step: step_name),
          "decision_units" => []
        }
      end
    end
  end
end
