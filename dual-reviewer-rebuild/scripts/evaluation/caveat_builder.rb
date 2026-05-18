#!/usr/bin/env ruby
# frozen_string_literal: true

# Task 6: caveat reporting（評価所有・スクラッチ再実装）
# 根拠: tasks.md Task 6、Requirement 4 受入 2・3・5、design「Exclusion and
#       Caveat Model §2 Caveat Register」「Key Decision 4」。
#       入力は ClassificationEngine の戻り（valid/exploratory/invalid 等の
#       分布の正本）＋ ComparisonBuilder#build の戻り（version 混在 =
#       comparison_invalid_reason、exploratory appendix、eligibility note /
#       review-mode 除外の正本）。
#
# スクラッチ方針: 旧 v1 caveat_builder（available_treatments など旧 v1
# comparison 形依存・data/runtime quality 区別なし・mixed maturity 非保持）
# は流用せず破棄して作り直す。本 builder は paper-interface が raw archive を
# 再読せず継承できる machine-readable first-class caveat を出す
# （Requirement 4 受入 2）。data-quality caveat と runtime-quality caveat を
# caveat_class で機械弁別する（Requirement 4 受入 3）。invalid と valid を
# silent に 1 集約へ潰さない（Requirement 4 受入 5・Decision 4）。
module DualReviewer
  module Evaluation
    class CaveatBuilder
      LOW_SAMPLE_THRESHOLD = 2

      # caveat_class 語彙（Requirement 4 受入 3 の機械弁別軸）。
      DATA_QUALITY = "data_quality"
      RUNTIME_QUALITY = "runtime_quality"

      def build(classification_results:, comparison_result:)
        results = Array(classification_results)
        cmp = comparison_result || {}

        valid = results.select { |r| r["classification"] == "valid" }
        exploratory = results.select { |r| r["classification"] == "exploratory" }
        invalid = results.select { |r| r["classification"] == "invalid" }

        caveats = []
        caveats.concat(sample_caveats(valid, exploratory))
        caveats.concat(maturity_caveats(valid, exploratory, invalid))
        caveats.concat(comparison_caveats(cmp))

        {
          "caveats" => caveats,
          "caveats_by_class" => index_by_class(caveats),
          # invalid と valid を silent に 1 集約へ潰さない（Decision 4）。
          "population_collapsed" => false,
          "population_summary" => {
            "valid_count" => valid.length,
            "exploratory_count" => exploratory.length,
            "invalid_count" => invalid.length
          }
        }
      end

      private

      # low sample size / exploratory only slice（design §2）。
      # いずれも data-quality caveat（標本側の限界）。
      def sample_caveats(valid, exploratory)
        list = []

        if valid.length < LOW_SAMPLE_THRESHOLD
          list << caveat(
            caveat_code: "low_sample_size",
            caveat_class: DATA_QUALITY,
            severity: "warning",
            details:
              "Valid population has fewer than " \
              "#{LOW_SAMPLE_THRESHOLD} runs (#{valid.length}).",
            affected_scope: "global"
          )
        end

        if valid.empty? && !exploratory.empty?
          list << caveat(
            caveat_code: "exploratory_only_slice",
            caveat_class: DATA_QUALITY,
            severity: "warning",
            details:
              "Current analysis slice has exploratory runs but no " \
              "valid runs.",
            affected_scope: "global"
          )
        end

        list
      end

      # mixed maturity evidence（design §2）。valid と exploratory が併存する
      # 場合に「maturity を混在させたまま読むな」と継承させる。data-quality。
      def maturity_caveats(valid, exploratory, _invalid)
        return [] unless !valid.empty? && !exploratory.empty?

        [caveat(
          caveat_code: "mixed_maturity_evidence",
          caveat_class: DATA_QUALITY,
          severity: "warning",
          details:
            "Slice mixes valid (#{valid.length}) and exploratory " \
            "(#{exploratory.length}) evidence; do not collapse maturity.",
          affected_scope: "global"
        )]
      end

      # protocol drift across comparison set（design §2）。ComparisonBuilder が
      # version 混在を comparison_invalid_reason に出した場合に runtime-quality
      # caveat として継承する（証跡の混在は runtime 側品質課題）。
      def comparison_caveats(cmp)
        list = []
        tc = cmp["treatment_comparisons"] || {}
        reasons = Array(tc["comparison_invalid_reason"])

        drift = reasons.select { |c| c.to_s.start_with?("mixed_") }
        unless drift.empty?
          list << caveat(
            caveat_code: "protocol_drift",
            caveat_class: RUNTIME_QUALITY,
            severity: "warning",
            details:
              "Comparison set mixes differing versions: " \
              "#{drift.join(', ')}.",
            affected_scope: "treatment_comparison"
          )
        end

        if reasons.include?("mismatched_target_condition")
          list << caveat(
            caveat_code: "mismatched_target_condition",
            caveat_class: RUNTIME_QUALITY,
            severity: "warning",
            details:
              "Comparison set mixes differing target conditions.",
            affected_scope: "treatment_comparison"
          )
        end

        list
      end

      def index_by_class(caveats)
        caveats.each_with_object({}) do |c, acc|
          k = c["caveat_class"]
          acc[k] ||= []
          acc[k] << c
        end
      end

      def caveat(caveat_code:, caveat_class:, severity:, details:,
                 affected_scope:)
        {
          "caveat_code" => caveat_code,
          "caveat_class" => caveat_class,
          "severity" => severity,
          "details" => details,
          "affected_scope" => affected_scope
        }
      end
    end
  end
end
