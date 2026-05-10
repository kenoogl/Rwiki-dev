# frozen_string_literal: true

require_relative "base_step_executor"

module DualReviewer
  module Runtime
    class StepBAdversarialReview < BaseStepExecutor
      FOUNDATION_PROMPT_RELATIVE_PATH = "runtime/prompts/adversarial/adversarial_reviewer.prompt.md"
      PARAMETER_PATTERNS = [/input parameters/i, /parameter/i, /既定値/i, /default value/i, /delt/i, /平均組成/i].freeze
      CAVEAT_PATTERNS = [/caveat/i, /limitation/i, /clean-room/i, /digest/i, /constraint/i, /reconstruction/i].freeze

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

        findings = []
        if phase_field_target?(context)
          parameter_refs = refs_matching(context, PARAMETER_PATTERNS)
          caveat_refs = refs_matching(context, CAVEAT_PATTERNS)
          relevant_refs = (parameter_refs + caveat_refs).uniq

          if relevant_refs.any?
            findings << build_step_finding(
              context: context,
              finding_id: "#{context.fetch(:step_id)}-finding-parameter-caveat",
              severity: "medium",
              summary: parameter_caveat_summary(relevant_refs),
              source_role: "adversarial_reviewer",
              source_refs: relevant_refs,
              counter_evidence_refs: parameter_refs,
              failure_observation_refs: [
                "implementation:parameter_interpretation_drift"
              ]
            )
          end
        end

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

      private

      def parameter_caveat_summary(refs)
        excerpt = first_matching_excerpt(refs, PARAMETER_PATTERNS + CAVEAT_PATTERNS)
        base = "Parameter interpretation remains adversarially review-worthy because defaults, CLI meaning, and clean-room reconstruction caveats can diverge unless the mapping from upstream spec to implementation snapshot is made explicit."
        excerpt ? "#{base} Evidence excerpt: #{excerpt}" : base
      end
    end
  end
end
