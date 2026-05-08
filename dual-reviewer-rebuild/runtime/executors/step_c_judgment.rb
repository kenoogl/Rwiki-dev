# frozen_string_literal: true

require_relative "base_step_executor"

module DualReviewer
  module Runtime
    class StepCJudgment < BaseStepExecutor
      FOUNDATION_PROMPT_RELATIVE_PATH = "runtime/prompts/judgment/judgment_reviewer.prompt.md"

      def step_name
        "judgment"
      end

      def execute(context)
        if context.fetch(:treatment) == "dual"
          return {
            "step_id" => context.fetch(:step_id),
            "step_name" => step_name,
            "step_status" => "skipped",
            "phase_profile" => context.fetch(:phase_profile),
            "treatment" => context.fetch(:treatment),
            "skip_reason" => "treatment_dual_skips_judgment",
            "prompt_identity" => prompt_identity,
            "judgments" => []
          }
        end

        {
          "step_id" => context.fetch(:step_id),
          "step_name" => step_name,
          "step_status" => "completed",
          "phase_profile" => context.fetch(:phase_profile),
          "treatment" => context.fetch(:treatment),
          "prompt_identity" => prompt_identity,
          "judgments" => []
        }
      end

      private

      def prompt_identity
        frontmatter = asset_loader.prompt_frontmatter(FOUNDATION_PROMPT_RELATIVE_PATH)
        {
          "prompt_artifact_path" => foundation_prompt_path(FOUNDATION_PROMPT_RELATIVE_PATH).to_s,
          "prompt_id" => frontmatter.fetch("prompt_id"),
          "prompt_version" => frontmatter.fetch("prompt_version"),
          "resolution_status" => "resolved"
        }
      end
    end
  end
end
