# frozen_string_literal: true

module DualReviewer
  module Runtime
    module ExecutionV2
      class DecisionContext
        def build(execution_contract:, analysis_result:, decision_artifacts:, validation_close:)
          decision_units = decision_artifacts.fetch("decision_units").fetch("decision_units", [])
          invalidation_markers = validation_close.fetch("invalidation_markers", [])
          validator_result = validation_close.fetch("validator_result")
          comparison_note = validation_close.fetch("comparison_eligibility_note")
          triage_note = validation_close.fetch("invalid_run_triage_note")

          {
            "track" => execution_contract.fetch("common_inputs").fetch("track"),
            "treatment" => execution_contract.fetch("common_inputs").fetch("treatment"),
            "review_mode" => execution_contract.fetch("common_inputs").fetch("review_mode"),
            "analysis_result" => analysis_result,
            "decision_units" => decision_units.map { |unit| normalize_decision_unit(unit) },
            "validation_summary" => {
              "validator_status" => validator_result.fetch("overall_status"),
              "invalidation_count" => invalidation_markers.length,
              "comparison_eligibility_status" => comparison_note.fetch("eligibility_status"),
              "comparison_reason_codes" => comparison_note.fetch("reason_codes"),
              "invalid_run_primary_failure_code" => triage_note.fetch("primary_failure_code"),
              "invalid_run_action_hint" => triage_note.fetch("operator_action_hint")
            },
            "reopen_summary" => build_reopen_summary(analysis_result: analysis_result, decision_units: decision_units)
          }
        end

        private

        def normalize_decision_unit(unit)
          {
            "decision_unit_id" => unit.fetch("decision_unit_id"),
            "proposed_action" => unit.fetch("proposed_action"),
            "human_decision" => unit.fetch("human_decision"),
            "finding_refs" => unit.fetch("finding_refs", []),
            "disposition_class" => disposition_class_for(unit)
          }
        end

        def disposition_class_for(unit)
          return "accepted" if unit.fetch("human_decision") == "approved"
          return "rejected" if unit.fetch("human_decision") == "rejected"

          "deferred"
        end

        def build_reopen_summary(analysis_result:, decision_units:)
          reopen_candidates = analysis_result.fetch("reopen_candidates", [])
          accepted_ids = decision_units.select { |unit| unit.fetch("human_decision") == "approved" }.map { |unit| unit.fetch("decision_unit_id") }

          {
            "reopen_candidate_count" => reopen_candidates.length,
            "accepted_decision_unit_ids" => accepted_ids
          }
        end
      end
    end
  end
end
