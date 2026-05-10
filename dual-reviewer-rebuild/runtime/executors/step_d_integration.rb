# frozen_string_literal: true

require_relative "base_step_executor"

module DualReviewer
  module Runtime
    class StepDIntegration < BaseStepExecutor
      FOUNDATION_PROMPT_RELATIVE_PATH = "runtime/prompts/integration/integration_reviewer.prompt.md"

      def step_name
        "integration"
      end

      def execute(context)
        decision_units = prior_step_payloads(context)
          .find { |payload| payload.fetch("step_name") == "judgment" }
          &.fetch("judgments", [])
          &.map do |judgment|
            {
              "finding_id" => judgment.fetch("finding_id"),
              "final_label" => judgment.fetch("final_label"),
              "recommended_action" => judgment.fetch("recommended_action")
            }
          end || []

        {
          "step_id" => context.fetch(:step_id),
          "step_name" => step_name,
          "step_status" => "completed",
          "phase_profile" => context.fetch(:phase_profile),
          "treatment" => context.fetch(:treatment),
          "prompt_identity" => resolved_prompt_identity(FOUNDATION_PROMPT_RELATIVE_PATH),
          "decision_units" => decision_units
        }
      end
    end
  end
end
