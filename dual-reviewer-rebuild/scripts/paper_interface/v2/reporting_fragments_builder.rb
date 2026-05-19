#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "analysis_intake"
require_relative "reference"

# Task 7: reporting fragment model（論文インターフェース所有・スクラッチ）。
# 根拠: tasks.md Task 7、Requirement 5 受入 3・4、
#       design「Reporting Fragment Model」「Key Decision 3」。
#       適合レビュー 2026-05-19 Finding 群（決定的検証皆無）解消。
#
# スクラッチ方針: 旧 v1 reporting_fragments_builder.rb は流用せず破棄
# して作り直す。fragment は manuscript そのものにしない（text_stub）。
# 複数出典 fragment の maturity_label は出典の最も保守的な値
# （exploratory < preliminary < mature、1 つでも低ければ全体をその値に）。
# 出典ごとの成熟度区分（per_source_maturity）を fragment 内に保持し
# 束ねても見えなくしない。集約値は保守表示で per_source の保持を
# 代替しない。
module DualReviewer
  module PaperInterfaceV2
    class ReportingFragmentsBuilder
      Ref = DualReviewer::PaperInterfaceV2::Reference

      MATURITY_ORDER = { "exploratory" => 0, "preliminary" => 1,
                         "mature" => 2 }.freeze

      def initialize(analysis_root:)
        @intake = AnalysisIntake.new(analysis_root: analysis_root)
      end

      # design 集約規則: 最も保守的な値（順序最小）。空なら exploratory。
      def aggregate_maturity(labels)
        ls = Array(labels).compact
        return "exploratory" if ls.empty?

        ls.min_by { |l| MATURITY_ORDER.fetch(l, 0) }
      end

      def build
        treatment_src = source_ref(:treatment_comparisons)
        phase_src = source_ref(:phase_comparisons)
        exclusion_src = source_ref(:exclusion_report)

        treatment_mat = comparison_maturity
        phase_mat = comparison_maturity
        exclusion_mat = "preliminary"

        fragments = []

        fragments << {
          "fragment_id" => "fragment-treatment-claim-summary",
          "fragment_type" => "claim_summary",
          "source_artifact_refs" => [treatment_src],
          "maturity_label" => treatment_mat,
          "caveat_refs" => caveat_refs,
          "text_stub" => "Treatment comparison summary fragment.",
          "per_source_maturity" => [
            per_source(treatment_src, treatment_mat)
          ]
        }

        fragments << {
          "fragment_id" => "fragment-method-note",
          "fragment_type" => "method_note",
          "source_artifact_refs" => [manifest_ref],
          "maturity_label" => "mature",
          "caveat_refs" => [],
          "text_stub" => "Analysis logic / run set provenance note.",
          "per_source_maturity" => [
            per_source(manifest_ref, "mature")
          ]
        }

        fragments << {
          "fragment_id" => "fragment-limitation-note",
          "fragment_type" => "limitation_note",
          "source_artifact_refs" => [exclusion_src],
          "maturity_label" => exclusion_mat,
          "caveat_refs" => caveat_refs,
          "text_stub" => "Population exclusion limitation note.",
          "per_source_maturity" => [
            per_source(exclusion_src, exclusion_mat)
          ]
        }

        # 複数出典 fragment（comparison_summary）。保守的集約しつつ
        # per_source_maturity を保持（圧縮しない）。
        per_sources = [
          per_source(treatment_src, treatment_mat),
          per_source(phase_src, phase_mat),
          per_source(exclusion_src, exclusion_mat)
        ]
        fragments << {
          "fragment_id" => "fragment-comparison-summary",
          "fragment_type" => "comparison_summary",
          "source_artifact_refs" => [treatment_src, phase_src,
                                     exclusion_src],
          "maturity_label" =>
            aggregate_maturity(per_sources.map { |s| s["maturity_label"] }),
          "caveat_refs" => caveat_refs,
          "text_stub" =>
            "Cross-artifact comparison summary (conservative " \
            "maturity aggregation; per-source maturity preserved).",
          "per_source_maturity" => per_sources
        }

        { "fragments" => fragments }
      end

      private

      def per_source(ref, maturity)
        { "source_artifact_ref" => ref, "maturity_label" => maturity }
      end

      def source_ref(key)
        Ref.build(
          ref_type: "evaluation_#{key}",
          target_path: @intake.relative_target_path(key)
        )
      end

      def manifest_ref
        Ref.build(
          ref_type: "analysis_run_manifest",
          target_path: @intake.relative_target_path(:manifest)
        )
      end

      def comparison_maturity
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
