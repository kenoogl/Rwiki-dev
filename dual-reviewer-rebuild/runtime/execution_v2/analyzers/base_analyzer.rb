# frozen_string_literal: true

module DualReviewer
  module Runtime
    module ExecutionV2
      class BaseAnalyzer
        def initialize(track:)
          @track = track
        end

        attr_reader :track

        def analyze(execution_contract, review_case:, decision_artifacts:, validation_close:)
          findings = review_case.fetch("findings", [])
          decision_units = decision_artifacts.fetch("decision_units").fetch("decision_units", [])
          invalidation_markers = validation_close.fetch("invalidation_markers", [])

          {
            "track" => track,
            "evidence_observations" => build_evidence_observations(findings: findings),
            "review_issue_candidates" => build_review_issue_candidates(findings: findings),
            "caveat_candidates" => build_caveat_candidates(findings: findings, invalidation_markers: invalidation_markers),
            "reopen_candidates" => build_reopen_candidates(findings: findings),
            "signal_candidates" => build_signal_candidates(
              execution_contract: execution_contract,
              findings: findings,
              decision_units: decision_units,
              invalidation_markers: invalidation_markers
            )
          }
        end

        private

        def build_evidence_observations(findings:)
          findings.map do |finding|
            {
              "observation_id" => "observation:#{finding.fetch('finding_id')}",
              "taxonomy_path" => taxonomy_path_for(finding: finding),
              "summary" => finding.fetch("summary"),
              "severity" => finding.fetch("severity"),
              "source_role" => finding.fetch("source_role"),
              "evidence_refs" => finding.fetch("source_refs"),
              "counter_evidence_refs" => finding.fetch("counter_evidence_refs", [])
            }
          end
        end

        def build_review_issue_candidates(findings:)
          findings.map do |finding|
            {
              "candidate_id" => "issue-candidate:#{finding.fetch('finding_id')}",
              "finding_id" => finding.fetch("finding_id"),
              "taxonomy_path" => taxonomy_path_for(finding: finding),
              "severity" => finding.fetch("severity"),
              "summary" => finding.fetch("summary"),
              "evidence_refs" => finding.fetch("source_refs"),
              "failure_observation_refs" => finding.fetch("failure_observation_refs", [])
            }
          end
        end

        def build_caveat_candidates(findings:, invalidation_markers:)
          finding_caveats = findings.select do |finding|
            finding.fetch("source_role") == "adversarial_reviewer" || finding.fetch("counter_evidence_refs", []).any?
          end.map do |finding|
            {
              "candidate_id" => "caveat-candidate:#{finding.fetch('finding_id')}",
              "kind" => "counter_evidence_preserved",
              "finding_id" => finding.fetch("finding_id"),
              "summary" => finding.fetch("summary"),
              "counter_evidence_refs" => finding.fetch("counter_evidence_refs", [])
            }
          end

          invalidation_caveats = invalidation_markers.map do |marker|
            {
              "candidate_id" => "caveat-candidate:#{marker.fetch('invalidation_marker_id')}",
              "kind" => "validation_invalidation",
              "reason_code" => marker.fetch("reason_code"),
              "summary" => marker.fetch("summary")
            }
          end

          finding_caveats + invalidation_caveats
        end

        def build_reopen_candidates(findings:)
          findings.each_with_object([]) do |finding, acc|
            next unless %w[critical high].include?(finding.fetch("severity"))

            acc << {
              "candidate_id" => "reopen-candidate:#{finding.fetch('finding_id')}",
              "finding_id" => finding.fetch("finding_id"),
              "taxonomy_path" => taxonomy_path_for(finding: finding),
              "reopen_scope" => reopen_scope_for(track: track),
              "reason" => finding.fetch("summary")
            }
          end
        end

        def build_signal_candidates(execution_contract:, findings:, decision_units:, invalidation_markers:)
          finding_signals = findings.map do |finding|
            matching_decision = decision_units.find do |unit|
              unit.fetch("finding_refs", []).include?("review_case.json##{finding.fetch('finding_id')}")
            end

            {
              "signal_id" => "signal:#{finding.fetch('finding_id')}",
              "signal_class" => signal_class_for(finding: finding),
              "taxonomy_path" => taxonomy_path_for(finding: finding),
              "decision_unit_id" => matching_decision && matching_decision.fetch("decision_unit_id"),
              "treatment" => execution_contract.fetch("common_inputs").fetch("treatment")
            }
          end

          invalidation_signals = invalidation_markers.map do |marker|
            {
              "signal_id" => "signal:#{marker.fetch('invalidation_marker_id')}",
              "signal_class" => "validation_invalidation",
              "taxonomy_path" => "validation.invalidation.#{marker.fetch('reason_code')}",
              "decision_unit_id" => nil,
              "treatment" => execution_contract.fetch("common_inputs").fetch("treatment")
            }
          end

          finding_signals + invalidation_signals
        end

        def taxonomy_path_for(finding:)
          severity_bucket = %w[critical high].include?(finding.fetch("severity")) ? "blocking" : "nonblocking"
          role_bucket = finding.fetch("source_role") == "adversarial_reviewer" ? "counter_evidence" : "detected_issue"
          "#{track}.#{severity_bucket}.#{role_bucket}"
        end

        def signal_class_for(finding:)
          %w[critical high].include?(finding.fetch("severity")) ? "workflow_failure_signal" : "quality_signal"
        end

        def reopen_scope_for(track:)
          case track
          when "implementation"
            "implementation_snapshot"
          when "spec"
            "reviewed_phase"
          when "intent"
            "intent"
          else
            "unknown"
          end
        end
      end
    end
  end
end
