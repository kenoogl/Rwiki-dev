#!/usr/bin/env ruby
# frozen_string_literal: true

# Task 6: exclusion reporting（評価所有・スクラッチ再実装）
# 根拠: tasks.md Task 6、Requirement 4 受入 1・4・5、Requirement 1 受入 3、
#       design「Exclusion and Caveat Model §1 Exclusion Report」
#       「Key Decision 4」。入力は ClassificationEngine#classify_local_run /
#       classify_imported_bundle の戻り（分類・除外理由の正本）。
#
# スクラッチ方針: 旧 v1 評価実装は流用せず作り直す。本 builder は分類結果
# から「どの run がなぜ標準集団から除外されたか」を design §1 の 6 フィールド
# で機械的に列挙し、raw run log を手読みせず exclusion counts / reasons を
# 報告可能にする。valid（in_comparison_population=true）は除外でないため
# entries に出さない。invalid と valid を silent に 1 集約へ潰さない
# （Requirement 4 受入 5・Decision 4）。
module DualReviewer
  module Evaluation
    class ExclusionReportBuilder
      # design §1 が要求する exclusion entry の最小 6 フィールド。
      ENTRY_FIELDS = %w[
        run_id classification reason_codes reason_details
        phase_profile treatment
      ].freeze

      def build(classification_results:)
        results = Array(classification_results)

        excluded = results.reject { |r| in_population?(r) }
        valid = results.select { |r| in_population?(r) }

        entries = excluded.map { |r| entry(r) }

        {
          "entries" => entries,
          "total_excluded" => entries.length,
          "exclusion_counts" => counts_by_classification(excluded),
          "exclusion_counts_by_reason_code" =>
            counts_by_reason_code(excluded),
          # invalid と valid を silent に 1 集約へ潰さない（Decision 4）。
          "population_separation" => {
            "valid_population_count" => valid.length,
            "excluded_population_count" => excluded.length,
            "collapsed_into_single_aggregate" => false
          }
        }
      end

      private

      # 標準比較集団に入るのは valid（ClassificationEngine が
      # in_comparison_population=true を立てる run）のみ。それ以外
      # （invalid / exploratory / analysis_blocked）は除外として扱う。
      def in_population?(result)
        result["in_comparison_population"] == true
      end

      def entry(result)
        {
          "run_id" => result["run_id"],
          "classification" => result["classification"],
          "reason_codes" => Array(result["reason_codes"]),
          "reason_details" => Array(result["reason_details"]),
          "phase_profile" => result["phase_profile"],
          "treatment" => result["treatment"]
        }
      end

      # raw run log を手読みせず classification 別 counts を報告可能にする
      # （Requirement 1 受入 3・Requirement 4 受入 4）。valid は集計しない。
      def counts_by_classification(excluded)
        excluded.each_with_object({}) do |r, acc|
          key = r["classification"].to_s
          acc[key] ||= 0
          acc[key] += 1
        end
      end

      def counts_by_reason_code(excluded)
        excluded.each_with_object({}) do |r, acc|
          Array(r["reason_codes"]).each do |code|
            acc[code] ||= 0
            acc[code] += 1
          end
        end
      end
    end
  end
end
