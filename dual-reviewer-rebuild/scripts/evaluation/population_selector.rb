#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"

# Task 2: analysis population selection（評価所有・新規）
# 根拠: tasks.md Task 2、design「Analysis Population Selection」、
#       Requirement 6 受入 1〜3、Requirement 7 受入 3。
#
# default analysis population を任意の寄せ集めでなく再現可能な selection
# policy で選ぶ。selection manifest と refresh workflow に落とせる形にする。
# 優先条件（design）:
#   - run_status=closed
#   - standard intake complete
#   - protocol-facing validation summary available
#   - 同一 case_id / phase_profile 内で比較対象 treatment が揃う
module DualReviewer
  module Evaluation
    class PopulationSelector
      LOCAL_RUNS_RELROOT = "tests/fixtures/evaluation/local_runs"

      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      # run_intakes: LocalRunLoader#load_run の戻り値配列。
      # 決定的: 同一入力からは常に同一 selected_run_ids（sort 済み）。
      def select(run_intakes:)
        candidates = run_intakes.select { |ri| eligible?(ri) }

        selected_ids = candidates
          .map { |ri| ri.fetch("metadata", {})["run_id"] }
          .compact
          .sort

        treatment_grouping = build_treatment_grouping(candidates)

        {
          "selected_run_ids" => selected_ids,
          "selection_policy" => {
            "run_status_closed" => true,
            "standard_intake_complete" => true,
            "protocol_facing_validation_summary_available" => true,
            "comparison_treatment_grouping" => treatment_grouping
          },
          "refresh_inputs" => {
            "local_runs_root" => LOCAL_RUNS_RELROOT,
            "selector_logic_version" => "1.0.0"
          }
        }
      end

      private

      # design 優先条件を機械的に適用する。protocol-facing validation summary
      # は review_case foundation スキーマ準拠の validation_refs.validator_result_ref
      # で表す（runtime 新契約。runtime_summary には依存しない）。
      def eligible?(run_intake)
        return false unless run_intake["intake_status"] == "complete"

        md = run_intake.fetch("metadata", {})
        return false unless md["run_status"] == "closed"

        refs = run_intake.fetch("validation_refs", {})
        vref = refs["validator_result_ref"]
        return false if vref.nil? || vref.to_s.strip.empty?

        true
      end

      # 同一 case_id（target_id）/ phase_profile 内で treatment を束ねる。
      # phase identity を消さず保持（Requirement 7 受入 3）。
      def build_treatment_grouping(candidates)
        groups = {}
        candidates.each do |ri|
          md = ri.fetch("metadata", {})
          key = "#{md['target_id']}::#{md['phase_profile']}"
          groups[key] ||= []
          groups[key] << md["treatment"]
        end
        groups.each_value { |v| v.sort!.uniq! }
        groups
      end
    end
  end
end
