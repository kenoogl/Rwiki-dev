#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "analysis_intake"
require_relative "reference"

# Task 5: figure / table bundle model（論文インターフェース所有・スクラッチ）。
# 根拠: tasks.md Task 5、Requirement 2（受入 1・2・4・5）、
#       Requirement 4 受入 2、design「Figure and Table Bundle Model §1〜§2」。
#       適合レビュー 2026-05-19 Finding 2（旧 comparison キー死参照）・
#       Finding 8（旧 exclusion 形依存）解消。
#
# スクラッチ方針: 旧 v1 table_source_bundle_builder.rb /
# figure_source_bundle_builder.rb（available_treatments/available_phases/
# overlay_metric_profile を field_projection に固定する旧 evaluation 形
# 依存）は流用せず破棄して作り直す。新 evaluation 実体スキーマ
# （treatments_present / treatment_aggregates / selected_overlay /
# total_excluded / population_separation）の構造化集計を field_projection
# に反映する。plot_contract は描画でなく slice/metric/grouping の
# reporting-side definition。formatting 都合で下層 schema 変更を強制しない。
module DualReviewer
  module PaperInterfaceV2
    class BundleBuilder
      Ref = DualReviewer::PaperInterfaceV2::Reference

      def initialize(analysis_root:)
        @intake = AnalysisIntake.new(analysis_root: analysis_root)
      end

      def build_table_bundle
        {
          "tables" => [
            {
              "table_id" => "table-treatment-comparison",
              "source_artifact_refs" => [
                source_ref(:treatment_comparisons)
              ],
              # 新 evaluation 実体キーのみを projection（旧
              # available_treatments/overlay_metric_profile を使わない）。
              "field_projection" => %w[
                comparison_status
                treatments_present
                treatment_aggregates.treatment
                treatment_aggregates.run_count
                treatment_aggregates.acceptance_ratio
                treatment_aggregates.judgment_invocation_coverage
              ],
              "maturity_label" => maturity_label,
              "caveat_refs" => caveat_refs
            },
            {
              "table_id" => "table-phase-comparison",
              "source_artifact_refs" => [
                source_ref(:phase_comparisons)
              ],
              "field_projection" => %w[
                comparison_status
                phase_slices.phase_profile
                phase_slices.selected_overlay
                phase_slices.treatments_present
              ],
              "maturity_label" => maturity_label,
              "caveat_refs" => caveat_refs
            },
            {
              "table_id" => "table-population-exclusion",
              "source_artifact_refs" => [
                source_ref(:exclusion_report)
              ],
              # 新 exclusion 実体の構造化集計を消費（entries=除外のみ）。
              "field_projection" => %w[
                total_excluded
                exclusion_counts
                exclusion_counts_by_reason_code
                population_separation.valid_population_count
                population_separation.excluded_population_count
                entries.run_id
                entries.classification
                entries.reason_codes
              ],
              "maturity_label" => maturity_label,
              "caveat_refs" => caveat_refs
            }
          ]
        }
      end

      def build_figure_bundle
        {
          "figures" => [
            {
              "figure_id" => "figure-treatment-acceptance",
              "source_artifact_refs" => [
                source_ref(:treatment_comparisons)
              ],
              # plot_contract = どの slice/metric/grouping を使うかの
              # reporting-side definition（描画指示でない）。
              "plot_contract" => {
                "slice" => "treatment_aggregates",
                "metric" => "acceptance_ratio",
                "grouping" => "treatment"
              },
              "maturity_label" => maturity_label,
              "caveat_refs" => caveat_refs
            },
            {
              "figure_id" => "figure-phase-overlay-coverage",
              "source_artifact_refs" => [
                source_ref(:phase_comparisons)
              ],
              "plot_contract" => {
                "slice" => "phase_slices",
                "metric" => "selected_overlay",
                "grouping" => "phase_profile"
              },
              "maturity_label" => maturity_label,
              "caveat_refs" => caveat_refs
            }
          ]
        }
      end

      private

      def source_ref(key)
        Ref.build(
          ref_type: "evaluation_#{key}",
          target_path: @intake.relative_target_path(key)
        )
      end

      # design §1 束縛規則と整合: valid かつ安定比較集合なら mature、
      # valid のみなら preliminary、なければ exploratory。
      def maturity_label
        rows = Array(@intake.run_classification_index["entries"])
        return "mature" if rows.any? do |r|
          r["classification"] == "valid" &&
            r["in_standard_runtime_comparison_set"] == true
        end

        rows.any? { |r| r["classification"] == "valid" } ?
          "preliminary" : "exploratory"
      end

      def caveat_refs
        Array(@intake.caveat_register["caveats"]).map do |c|
          Ref.build(
            ref_type: "evaluation_caveat",
            target_path: @intake.relative_target_path(:caveat_register),
            target_id: c["caveat_code"]
          )
        end
      end
    end
  end
end
