# frozen_string_literal: true

require_relative "analyzers/spec_protocol_analyzer"
require_relative "analyzers/intent_protocol_analyzer"
require_relative "protocol_track_artifact_builder"
require_relative "protocol_track_mediator"

module DualReviewer
  module Runtime
    module ExecutionV2
      class ProtocolTrackSession
        attr_reader :repo_root, :protocol_track_mediator, :protocol_track_artifact_builder

        def initialize(repo_root:)
          @repo_root = repo_root
          @protocol_track_mediator = ProtocolTrackMediator.new(repo_root: repo_root)
          @protocol_track_artifact_builder = ProtocolTrackArtifactBuilder.new
        end

        def build_spec_case(case_id:, review_mode:, analysis_profile_ref:, reviewed_phase:, reviewed_phase_ref:, adjacent_phase_refs:, alignment_refs:, workflow_gate_status_ref:, case_manifest_ref:, compatibility_projection:)
          analysis = SpecProtocolAnalyzer.new(
            repo_root: repo_root,
            review_mode: review_mode,
            analysis_profile_ref: analysis_profile_ref
          ).analyze

          execution_contract = protocol_track_mediator.build_spec_execution_contract(
            case_id: case_id,
            reviewed_phase: reviewed_phase,
            reviewed_phase_ref: reviewed_phase_ref,
            adjacent_phase_refs: adjacent_phase_refs,
            alignment_refs: alignment_refs,
            workflow_gate_status_ref: workflow_gate_status_ref,
            case_manifest_ref: case_manifest_ref,
            review_mode: review_mode
          )

          analysis_result = {
            "track" => "spec",
            "evidence_observations" => spec_evidence_observations(analysis: analysis),
            "review_issue_candidates" => spec_issue_candidates(analysis: analysis),
            "caveat_candidates" => spec_caveat_candidates(analysis: analysis),
            "reopen_candidates" => spec_reopen_candidates(analysis: analysis),
            "signal_candidates" => spec_signal_candidates(analysis: analysis, treatment: execution_contract.fetch("common_inputs").fetch("treatment"))
          }

          bundle = protocol_track_artifact_builder.build(
            execution_contract: execution_contract,
            analysis_result: analysis_result,
            compatibility_projection: compatibility_projection,
            decision_context_extras: {
              "reopen_required" => analysis.fetch("reopen_required"),
              "target_reopen_phases" => analysis.fetch("target_reopen_phases")
            },
            trace_note: {
              "schema_version" => "1.0.0",
              "track" => "spec",
              "case_id" => case_id,
              "target_id" => "spec:#{case_id}",
              "reviewed_phase" => reviewed_phase,
              "source_refs" => ([reviewed_phase_ref] + adjacent_phase_refs + alignment_refs).uniq,
              "governance_refs" => [workflow_gate_status_ref],
              "target_reopen_phases" => analysis.fetch("target_reopen_phases")
            },
            metric_snapshot: {
              "schema_version" => "1.0.0",
              "track" => "spec",
              "case_id" => case_id,
              "reviewed_phase" => reviewed_phase,
              "metrics" => analysis.fetch("metrics")
            },
            signal_linkage_note: {
              "schema_version" => "1.0.0",
              "track" => "spec",
              "case_id" => case_id,
              "linked_signal_ids" => analysis.fetch("linked_signal_ids"),
              "comparison_eligibility_status" => "not_applicable"
            }
          )

          {
            "analysis" => analysis,
            "execution_contract" => execution_contract,
            "analysis_result" => analysis_result,
            "bundle" => bundle
          }
        end

        def build_intent_case(case_id:, review_mode:, analysis_profile_ref:, intent_ref:, supporting_refs:, traceability_refs:, workflow_gate_status_ref:, case_manifest_ref:, compatibility_projection:)
          analysis = IntentProtocolAnalyzer.new(
            repo_root: repo_root,
            review_mode: review_mode,
            analysis_profile_ref: analysis_profile_ref
          ).analyze

          execution_contract = protocol_track_mediator.build_intent_execution_contract(
            case_id: case_id,
            intent_ref: intent_ref,
            supporting_refs: supporting_refs,
            traceability_refs: traceability_refs,
            workflow_gate_status_ref: workflow_gate_status_ref,
            case_manifest_ref: case_manifest_ref,
            review_mode: review_mode
          )

          analysis_result = {
            "track" => "intent",
            "evidence_observations" => intent_evidence_observations(analysis: analysis),
            "review_issue_candidates" => intent_issue_candidates(analysis: analysis),
            "caveat_candidates" => intent_caveat_candidates(analysis: analysis),
            "reopen_candidates" => intent_reopen_candidates(analysis: analysis),
            "signal_candidates" => intent_signal_candidates(analysis: analysis, treatment: execution_contract.fetch("common_inputs").fetch("treatment"))
          }

          bundle = protocol_track_artifact_builder.build(
            execution_contract: execution_contract,
            analysis_result: analysis_result,
            compatibility_projection: compatibility_projection,
            decision_context_extras: {
              "intent_handback_required" => analysis.fetch("intent_handback_required"),
              "downstream_propagation_targets" => analysis.fetch("downstream_propagation_targets")
            },
            trace_note: {
              "schema_version" => "1.0.0",
              "track" => "intent",
              "case_id" => case_id,
              "target_id" => "intent:#{case_id}",
              "source_refs" => ([intent_ref] + supporting_refs + traceability_refs).uniq,
              "governance_refs" => [workflow_gate_status_ref],
              "downstream_propagation_targets" => analysis.fetch("downstream_propagation_targets")
            },
            metric_snapshot: {
              "schema_version" => "1.0.0",
              "track" => "intent",
              "case_id" => case_id,
              "metrics" => analysis.fetch("metrics")
            },
            signal_linkage_note: {
              "schema_version" => "1.0.0",
              "track" => "intent",
              "case_id" => case_id,
              "linked_signal_ids" => analysis.fetch("linked_signal_ids"),
              "comparison_eligibility_status" => "not_applicable"
            }
          )

          {
            "analysis" => analysis,
            "execution_contract" => execution_contract,
            "analysis_result" => analysis_result,
            "bundle" => bundle
          }
        end

        private

        def spec_evidence_observations(analysis:)
          spec_issue_candidates(analysis: analysis).map do |candidate|
            {
              "observation_id" => "observation:#{candidate.fetch('candidate_id')}",
              "taxonomy_path" => candidate.fetch("taxonomy_path"),
              "summary" => candidate.fetch("summary"),
              "severity" => candidate.fetch("severity"),
              "source_role" => "protocol_track",
              "evidence_refs" => candidate.fetch("evidence_refs"),
              "counter_evidence_refs" => []
            }
          end
        end

        def spec_issue_candidates(analysis:)
          phase_local = analysis.fetch("phase_local_issues").map do |issue|
            build_spec_candidate(issue: issue, prefix: "phase-local", taxonomy_path: "spec.nonblocking.detected_issue")
          end
          cross_phase = analysis.fetch("cross_phase_inconsistencies").map do |issue|
            taxonomy = issue.fetch("severity") == "high" ? "spec.blocking.detected_issue" : "spec.nonblocking.detected_issue"
            build_spec_candidate(issue: issue, prefix: "cross-phase", taxonomy_path: taxonomy)
          end
          intent_issues = analysis.fetch("intent_attributed_issues").map do |issue|
            build_spec_candidate(issue: issue, prefix: "intent-attributed", taxonomy_path: "spec.nonblocking.detected_issue")
          end

          phase_local + cross_phase + intent_issues
        end

        def build_spec_candidate(issue:, prefix:, taxonomy_path:)
          {
            "candidate_id" => "#{prefix}:#{issue.fetch('issue_id')}",
            "issue_id" => issue.fetch("issue_id"),
            "taxonomy_path" => taxonomy_path,
            "severity" => issue.fetch("severity"),
            "summary" => issue.fetch("summary"),
            "evidence_refs" => issue.fetch("source_refs"),
            "failure_observation_refs" => []
          }
        end

        def spec_caveat_candidates(analysis:)
          analysis.fetch("caveats").map do |issue|
            {
              "candidate_id" => "caveat:#{issue.fetch('issue_id')}",
              "kind" => "review_caveat",
              "summary" => issue.fetch("summary"),
              "counter_evidence_refs" => issue.fetch("source_refs")
            }
          end
        end

        def spec_reopen_candidates(analysis:)
          return [] unless analysis.fetch("reopen_required")

          analysis.fetch("target_reopen_phases").map do |phase|
            {
              "candidate_id" => "reopen:#{phase}",
              "reopen_scope" => phase,
              "reason" => analysis.fetch("alignment_note")
            }
          end
        end

        def spec_signal_candidates(analysis:, treatment:)
          analysis.fetch("linked_signal_ids").map.with_index do |signal_id, index|
            {
              "signal_id" => signal_id,
              "signal_class" => index.zero? ? "workflow_failure_signal" : "quality_signal",
              "taxonomy_path" => index.zero? ? "spec.blocking.detected_issue" : "spec.nonblocking.detected_issue",
              "decision_unit_id" => nil,
              "treatment" => treatment
            }
          end
        end

        def intent_evidence_observations(analysis:)
          intent_issue_candidates(analysis: analysis).map do |candidate|
            {
              "observation_id" => "observation:#{candidate.fetch('candidate_id')}",
              "taxonomy_path" => candidate.fetch("taxonomy_path"),
              "summary" => candidate.fetch("summary"),
              "severity" => candidate.fetch("severity"),
              "source_role" => "protocol_track",
              "evidence_refs" => candidate.fetch("evidence_refs"),
              "counter_evidence_refs" => candidate.fetch("counter_evidence_refs", [])
            }
          end
        end

        def intent_issue_candidates(analysis:)
          major_gaps = analysis.fetch("major_gap_candidates").map do |issue|
            build_intent_candidate(issue: issue, prefix: "major-gap", taxonomy_path: "intent.blocking.detected_issue")
          end
          scope_drifts = analysis.fetch("scope_drift_candidates").map do |issue|
            build_intent_candidate(issue: issue, prefix: "scope-drift", taxonomy_path: "intent.nonblocking.detected_issue")
          end
          counter_hypotheses = analysis.fetch("counter_hypotheses").map do |issue|
            build_intent_candidate(issue: issue, prefix: "counter-hypothesis", taxonomy_path: "intent.nonblocking.counter_evidence")
          end

          major_gaps + scope_drifts + counter_hypotheses
        end

        def build_intent_candidate(issue:, prefix:, taxonomy_path:)
          {
            "candidate_id" => "#{prefix}:#{issue.fetch('issue_id')}",
            "issue_id" => issue.fetch("issue_id"),
            "taxonomy_path" => taxonomy_path,
            "severity" => issue.fetch("severity"),
            "summary" => issue.fetch("summary"),
            "evidence_refs" => issue.fetch("source_refs"),
            "counter_evidence_refs" => taxonomy_path.end_with?("counter_evidence") ? issue.fetch("source_refs") : [],
            "failure_observation_refs" => []
          }
        end

        def intent_caveat_candidates(analysis:)
          analysis.fetch("caveats").map do |issue|
            {
              "candidate_id" => "caveat:#{issue.fetch('issue_id')}",
              "kind" => "review_caveat",
              "summary" => issue.fetch("summary"),
              "counter_evidence_refs" => issue.fetch("source_refs")
            }
          end
        end

        def intent_reopen_candidates(analysis:)
          return [] unless analysis.fetch("intent_handback_required")

          analysis.fetch("downstream_propagation_targets").map do |target|
            {
              "candidate_id" => "reopen:#{target}",
              "reopen_scope" => target,
              "reason" => analysis.fetch("downstream_implication")
            }
          end
        end

        def intent_signal_candidates(analysis:, treatment:)
          analysis.fetch("linked_signal_ids").map.with_index do |signal_id, index|
            {
              "signal_id" => signal_id,
              "signal_class" => index.zero? ? "workflow_failure_signal" : "quality_signal",
              "taxonomy_path" => index.zero? ? "intent.blocking.detected_issue" : "intent.nonblocking.detected_issue",
              "decision_unit_id" => nil,
              "treatment" => treatment
            }
          end
        end
      end
    end
  end
end
