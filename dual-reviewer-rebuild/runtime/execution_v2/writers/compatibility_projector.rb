# frozen_string_literal: true

module DualReviewer
  module Runtime
    module ExecutionV2
      class CompatibilityProjector
        def build(review_case:, decision_artifacts:, analysis_result:, validation_close:)
          {
            "review_case_ref" => "review_case.json##{review_case.fetch('review_case_id')}",
            "finding_projection" => build_finding_projection(
              findings: review_case.fetch("findings", []),
              analysis_result: analysis_result
            ),
            "decision_unit_projection" => build_decision_unit_projection(
              decision_units: decision_artifacts.fetch("decision_units").fetch("decision_units", []),
              analysis_result: analysis_result
            ),
            "validation_projection" => {
              "validator_result_ref" => "validation/validator_result.json##{validation_close.fetch('validator_result').fetch('validator_result_id')}",
              "invalidation_marker_refs" => validation_close.fetch("invalidation_markers").map do |marker|
                "validation/invalidation_markers.json##{marker.fetch('invalidation_marker_id')}"
              end,
              "comparison_eligibility_note_ref" => "derived/comparison_eligibility_note.json##{validation_close.fetch('comparison_eligibility_note').fetch('comparison_eligibility_note_id')}",
              "invalid_run_triage_note_ref" => "derived/invalid_run_triage_note.json##{validation_close.fetch('invalid_run_triage_note').fetch('invalid_run_triage_note_id')}"
            }
          }
        end

        private

        def build_finding_projection(findings:, analysis_result:)
          issue_candidates = analysis_result.fetch("review_issue_candidates", [])
          signal_candidates = analysis_result.fetch("signal_candidates", [])
          reopen_candidates = analysis_result.fetch("reopen_candidates", [])

          findings.map do |finding|
            issue_candidate = issue_candidates.find { |entry| entry.fetch("finding_id") == finding.fetch("finding_id") }
            linked_signals = signal_candidates.select { |entry| entry.fetch("signal_id") == "signal:#{finding.fetch('finding_id')}" }
            reopen_candidate = reopen_candidates.find { |entry| entry.fetch("finding_id") == finding.fetch("finding_id") }

            {
              "finding_ref" => "review_case.json##{finding.fetch('finding_id')}",
              "candidate_ref" => issue_candidate && "v2/review_artifact.json##{issue_candidate.fetch('candidate_id')}",
              "taxonomy_path" => issue_candidate && issue_candidate.fetch("taxonomy_path"),
              "linked_signal_refs" => linked_signals.map { |entry| "v2/review_artifact.json##{entry.fetch('signal_id')}" },
              "reopen_candidate_ref" => reopen_candidate && "v2/review_artifact.json##{reopen_candidate.fetch('candidate_id')}"
            }
          end
        end

        def build_decision_unit_projection(decision_units:, analysis_result:)
          signal_candidates = analysis_result.fetch("signal_candidates", [])

          decision_units.map do |unit|
            linked_signals = signal_candidates.select { |entry| entry["decision_unit_id"] == unit.fetch("decision_unit_id") }

            {
              "decision_unit_ref" => "decisions/decision_units.json##{unit.fetch('decision_unit_id')}",
              "finding_refs" => unit.fetch("finding_refs", []),
              "linked_signal_refs" => linked_signals.map { |entry| "v2/review_artifact.json##{entry.fetch('signal_id')}" },
              "proposed_action" => unit.fetch("proposed_action"),
              "human_decision" => unit.fetch("human_decision")
            }
          end
        end
      end
    end
  end
end
