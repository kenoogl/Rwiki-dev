#!/usr/bin/env ruby
# frozen_string_literal: true

# Task 8: staleness 伝播（評価所有・スクラッチ再実装）
# 根拠: tasks.md Task 8、Requirement 5 受入 6、design「Versioning Model」。
#       参照していた run が事後に invalidate された場合、その run を入力に
#       含む derived artifact を stale フラグ付け、または再導出する。
#       invalidation を含む run の上に古い derived output を据え置かない。
#       foundation 無効化伝播義務（foundation 要件 6 受入 9）を入力起点と
#       する（適合レビュー 2026-05-19 finding 7）。raw 不変原則
#       （design Decision 1）により巻き戻しは derived 再生成に閉じ raw を
#       一切編集しない。
#
# スクラッチ方針: 旧 v1 評価実装に staleness 伝播は不在（finding 7）。本
# モジュールはスクラッチで新設する。入力は AnalysisManifestWriter#build_manifest
# の戻り（input_run_set を持つ）＋ current_invalidation_state（foundation
# 無効化伝播義務を入力起点として観測された、run_id => 無効化状態の写像。
# 観測のみ・評価は raw を編集しない）。
#
# current_invalidation_state の形（observed のみ）:
#   { "<run_id>" => {
#       "invalidated" => true/false,
#       "invalidation_marker_ids" => [String, ...],
#       "source" => String(optional、既定 foundation_invalidation_propagation)
#     } }
module DualReviewer
  module Evaluation
    class StalenessPropagator
      DEFAULT_SOURCE = "foundation_invalidation_propagation"

      # manifest の input_run_set に、事後 invalidate された run が含まれる
      # 場合に derived artifact を stale 化し再導出要求を立てる。
      def evaluate(manifest:, current_invalidation_state:)
        run_set = Array((manifest || {})["input_run_set"])
        state = current_invalidation_state || {}

        stale_run_ids = run_set.select do |rid|
          entry = state[rid]
          entry.is_a?(Hash) && entry["invalidated"] == true
        end.sort

        stale = !stale_run_ids.empty?

        unless stale
          return {
            "stale" => false,
            "disposition" => "fresh",
            "stale_run_ids" => [],
            "rederivation_required" => false,
            "leave_unchanged" => false,
            "propagation_source" => nil,
            "affected_derived_artifacts" => [],
            "raw_mutation" => false
          }
        end

        {
          "stale" => true,
          # invalidate run の上に古い derived を据え置かない
          # （leave_unchanged=false。再導出要求を立てる）。
          "disposition" => "rederive_required",
          "stale_run_ids" => stale_run_ids,
          "rederivation_required" => true,
          "leave_unchanged" => false,
          "propagation_source" => propagation_source(stale_run_ids, state),
          "affected_derived_artifacts" =>
            affected_derived_artifacts,
          "stale_marker_refs" => marker_refs(stale_run_ids, state),
          # raw 不変原則（Decision 1）。本モジュールは raw を編集しない。
          "raw_mutation" => false
        }
      end

      private

      # stale 化した run を入力に含む derived artifact（design「Interfaces to
      # Downstream Features」「Analysis Artifact Layout」が示す derived 群）。
      # raw run storage は対象外（experiments/runs/ には触れない）。
      def affected_derived_artifacts
        %w[
          classifications/run_classification_index.json
          classifications/exclusion_report.json
          metrics/run_metrics.json
          metrics/finding_metrics.json
          metrics/treatment_metrics.json
          comparisons/treatment_comparisons.json
          comparisons/phase_comparisons.json
          caveats/caveat_register.json
        ]
      end

      def propagation_source(stale_run_ids, state)
        sources = stale_run_ids.map do |rid|
          (state[rid] || {})["source"]
        end.compact.uniq
        sources.length == 1 ? sources.first : (sources.first || DEFAULT_SOURCE)
      end

      def marker_refs(stale_run_ids, state)
        stale_run_ids.each_with_object({}) do |rid, acc|
          acc[rid] = Array((state[rid] || {})["invalidation_marker_ids"])
        end
      end
    end
  end
end
