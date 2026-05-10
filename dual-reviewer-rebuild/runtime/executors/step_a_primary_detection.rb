# frozen_string_literal: true

require_relative "base_step_executor"

module DualReviewer
  module Runtime
    class StepAPrimaryDetection < BaseStepExecutor
      FOUNDATION_PROMPT_RELATIVE_PATH = "runtime/prompts/primary/primary_reviewer.prompt.md"
      BOUNDARY_PATTERNS = [/periodic boundary/i, /boundary handling/i, /boundary semantics/i, /描画.*連続/i].freeze
      UPDATE_ORDER_PATTERNS = [/fixed order/i, /step \(0\)/i, /step \(1\)/i, /time step/i, /update ordering/i, /時間発展手順/i].freeze

      def step_name
        "primary_detection"
      end

      def execute(context)
        findings = []
        if phase_field_target?(context)
          boundary_refs = refs_matching(context, BOUNDARY_PATTERNS)
          update_refs = refs_matching(context, UPDATE_ORDER_PATTERNS)

          if boundary_refs.any?
            findings << build_step_finding(
              context: context,
              finding_id: "#{context.fetch(:step_id)}-finding-boundary",
              severity: "high",
              summary: boundary_summary(boundary_refs),
              source_role: "primary_reviewer",
              source_refs: boundary_refs,
              failure_observation_refs: [
                "implementation:boundary_condition_semantics"
              ]
            )
          end

          if update_refs.any?
            findings << build_step_finding(
              context: context,
              finding_id: "#{context.fetch(:step_id)}-finding-update-order",
              severity: "medium",
              summary: update_order_summary(update_refs),
              source_role: "primary_reviewer",
              source_refs: update_refs,
              failure_observation_refs: [
                "implementation:update_ordering_state_mutation"
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
          "target_id" => context.fetch(:target_id),
          "prompt_identity" => resolved_prompt_identity(FOUNDATION_PROMPT_RELATIVE_PATH),
          "findings" => findings,
          "counter_evidence" => findings.flat_map { |finding| finding.fetch("counter_evidence_refs") }
        }
      end

      private

      def boundary_summary(refs)
        excerpt = first_matching_excerpt(refs, BOUNDARY_PATTERNS)
        base = "Boundary-condition semantics are review-critical because the upstream spec and snapshot explicitly require periodic-edge consistency across simulation and rendering."
        excerpt ? "#{base} Evidence excerpt: #{excerpt}" : base
      end

      def update_order_summary(refs)
        excerpt = first_matching_excerpt(refs, UPDATE_ORDER_PATTERNS)
        base = "Update ordering and state mutation risk should be inspected because the time-step sequence is explicitly fixed, so sequencing drift can change phase-field evolution."
        excerpt ? "#{base} Evidence excerpt: #{excerpt}" : base
      end
    end
  end
end
