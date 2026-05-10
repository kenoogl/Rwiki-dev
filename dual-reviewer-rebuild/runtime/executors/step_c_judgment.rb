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

        findings = prior_step_payloads(context).flat_map { |payload| payload.fetch("findings", []) }
        judgments = findings.map do |finding|
          final_label, recommended_action = judgment_for(finding)
          {
            "schema_version" => "1.0.0",
            "necessity_judgment_id" => "judgment-#{finding.fetch('finding_id')}",
            "finding_id" => finding.fetch("finding_id"),
            "step_id" => context.fetch(:step_id),
            "necessity_dimensions" => {
              "issue_validity" => dimension(score: 0.8, rationale: "The concern is grounded in the implementation-phase snapshot and upstream spec refs."),
              "issue_materiality" => dimension(score: severity_materiality(finding.fetch("severity")), rationale: "Materiality is derived from the seeded severity label."),
              "actionability" => dimension(score: 0.7, rationale: "The issue can be carried into a concrete review memo and downstream rework log."),
              "fix_readiness" => dimension(score: 0.6, rationale: "The current pilot can identify the issue even if the final remediation remains implementation-specific."),
              "adoption_priority" => dimension(score: adoption_priority(finding.fetch("severity")), rationale: "Priority tracks the pilot severity ranking.")
            },
            "final_label" => final_label,
            "recommended_action" => recommended_action,
            "override_reason" => nil
          }
        end

        {
          "step_id" => context.fetch(:step_id),
          "step_name" => step_name,
          "step_status" => "completed",
          "phase_profile" => context.fetch(:phase_profile),
          "treatment" => context.fetch(:treatment),
          "prompt_identity" => prompt_identity,
          "judgments" => judgments
        }
      end

      private

      def dimension(score:, rationale:)
        {
          "score" => score,
          "rationale" => rationale
        }
      end

      def severity_materiality(severity)
        {
          "critical" => 1.0,
          "high" => 0.9,
          "medium" => 0.7,
          "low" => 0.4,
          "info" => 0.2
        }.fetch(severity, 0.5)
      end

      def adoption_priority(severity)
        {
          "critical" => 1.0,
          "high" => 0.9,
          "medium" => 0.75,
          "low" => 0.5,
          "info" => 0.25
        }.fetch(severity, 0.5)
      end

      def judgment_for(finding)
        case finding.fetch("severity")
        when "high", "critical"
          ["necessary", "Escalate into implementation review memo and mark for downstream rework consideration."]
        when "medium"
          ["optional", "Preserve as caveat and inspect alongside upstream spec consistency before forcing a fix."]
        else
          ["defer", "Record the concern but defer mandatory action until stronger evidence appears."]
        end
      end

      def prompt_identity
        resolved_prompt_identity(FOUNDATION_PROMPT_RELATIVE_PATH)
      end
    end
  end
end
