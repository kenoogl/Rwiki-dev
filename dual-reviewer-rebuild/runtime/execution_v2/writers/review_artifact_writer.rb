# frozen_string_literal: true

module DualReviewer
  module Runtime
    module ExecutionV2
      class ReviewArtifactWriter
        def build(execution_contract:, decision_context:, compatibility_projection:)
          analysis_result = decision_context.fetch("analysis_result")

          {
            "schema_version" => "1.0.0",
            "contract_version" => execution_contract.fetch("contract_version"),
            "track" => execution_contract.fetch("common_inputs").fetch("track"),
            "target_id" => execution_contract.fetch("common_inputs").fetch("target_id"),
            "common_inputs" => execution_contract.fetch("common_inputs"),
            "track_inputs" => execution_contract.fetch("track_inputs"),
            "evidence_observations" => analysis_result.fetch("evidence_observations"),
            "review_issue_candidates" => analysis_result.fetch("review_issue_candidates"),
            "caveat_candidates" => analysis_result.fetch("caveat_candidates"),
            "reopen_candidates" => analysis_result.fetch("reopen_candidates"),
            "signal_candidates" => analysis_result.fetch("signal_candidates"),
            "compatibility_projection" => compatibility_projection,
            "decision_context" => decision_context
          }
        end
      end
    end
  end
end
