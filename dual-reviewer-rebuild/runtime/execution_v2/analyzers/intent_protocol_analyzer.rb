# frozen_string_literal: true

require_relative "analysis_profile_loader"

module DualReviewer
  module Runtime
    module ExecutionV2
      class IntentProtocolAnalyzer
        attr_reader :repo_root, :review_mode, :analysis_profile_ref

        def initialize(repo_root:, review_mode:, analysis_profile_ref:)
          @repo_root = repo_root
          @review_mode = review_mode
          @analysis_profile_ref = analysis_profile_ref
        end

        def analyze
          AnalysisProfileLoader.new(repo_root: repo_root).load(
            ref: analysis_profile_ref,
            review_mode: review_mode,
            fallback: default_analysis
          )
        end

        private

        def default_analysis
          {
            "major_gap_candidates" => [],
            "scope_drift_candidates" => [],
            "counter_hypotheses" => [],
            "caveats" => [],
            "intent_handback_required" => false,
            "downstream_propagation_targets" => [],
            "intent_attributed_issue_refs" => [],
            "downstream_implication" => "manual population required",
            "next_action" => "manual population required",
            "trace_note" => "Populate after review with downstream propagation and intent-attributed issue refs.",
            "linked_signal_ids" => [],
            "metrics" => {
              "intent_revision_count" => 0,
              "intent_handback_count" => 0,
              "intent_review_findings_count" => 0,
              "review_artifact_presence_rate" => 1.0
            }
          }
        end
      end
    end
  end
end
