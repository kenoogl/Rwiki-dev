# frozen_string_literal: true

require_relative "analysis_profile_loader"

module DualReviewer
  module Runtime
    module ExecutionV2
      class SpecProtocolAnalyzer
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
            "phase_local_issues" => [],
            "cross_phase_inconsistencies" => [],
            "intent_attributed_issues" => [],
            "caveats" => [],
            "reopen_required" => false,
            "target_reopen_phases" => [],
            "next_action" => "manual population required",
            "alignment_note" => "manual population required",
            "linked_signal_ids" => [],
            "metrics" => {
              "phase_blocking_issue_count" => 0,
              "phase_nonblocking_open_point_count" => 0,
              "phase_recheck_count" => 0,
              "phase_handback_count_by_class" => { "A" => 0, "B" => 0, "C" => 0, "D" => 0 },
              "phase_reopen_required_count" => 0,
              "phase_minor_adjustment_count" => 0,
              "phase_major_correction_count" => 0,
              "phase_intent_attributed_issue_count" => 0
            }
          }
        end
      end
    end
  end
end
