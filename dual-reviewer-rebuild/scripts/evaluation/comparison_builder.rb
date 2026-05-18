#!/usr/bin/env ruby
# frozen_string_literal: true

# Task 5: comparison model（treatment / phase-aware / valid population /
# 比較可能性条件、評価所有・スクラッチ再実装）
# 根拠: tasks.md Task 5、Requirement 2 受入 1〜6、Requirement 7 受入 2・3・5、
#       design「Comparison Model §1（Treatment Comparison）」「§2
#       Phase-Aware Comparison」「§3 Valid Population Rule」「Key Decision 3」。
#       runtime 所有 comparison_eligibility_note（最小 6 項目・評価 A-7。
#       評価は再定義しない）、ClassificationEngine（in_comparison_population /
#       review_mode / in_standard_runtime_comparison_set /
#       step_omission_disposition の正本）、MetricExtractor（phase overlay 正本）。
#       適合レビュー 2026-05-19 finding 6（protocol/prompt version uniformity
#       を比較可能性条件として要求し per-run metadata 完備でも version 混在を
#       検出・報告）/ finding 4（撤廃 review_mode 語彙非依存）/ finding 10
#       （eligibility note 不可理由を先に尊重し comparison に接続）。
#
# スクラッチ方針: 旧 v1 comparison_builder（version uniformity 検査なし・
# eligibility note 不参照・exploratory appendix 分離なし・review-mode slice
# なし・treatment-driven skip vs runtime failure 区別なし）は流用せず破棄して
# 作り直す。入力単位を classification + metric + metadata + eligibility を
# 束ねた run_records とし、比較前に比較可能性条件を機械的に確認する。
#
# 入力 run_records の各要素（評価所有の集約単位）:
#   {
#     "run_id" => String,
#     "classification" => ClassificationEngine#classify_local_run の戻り,
#     "metrics" => MetricExtractor#extract_from_run_intake の戻り,
#     "metadata" => LocalRunLoader#load_run の metadata,
#     "comparison_eligibility" => LocalRunLoader の eligibility_view（or nil）
#   }
#
# downstream（paper-interface）が読む treatment_comparisons /
# phase_comparisons は machine-readable first-class で出す。
module DualReviewer
  module Evaluation
    class ComparisonBuilder
      # version 比較可能性条件（finding 6）。per-run metadata が全て揃って
      # いても、これらが混在する set は標準比較に入れない（Req2 受入 6）。
      # foundation metadata_contract.yaml の required version fields を正本に
      # 参照するだけで再定義しない。
      VERSION_FIELDS = %w[
        protocol_version prompt_set_version runtime_version schema_set_version
      ].freeze

      # 比較可能性 reason code（version 混在は field 名に対応付ける）。
      MIX_REASON_BY_FIELD = {
        "protocol_version" => "mixed_protocol_version",
        "prompt_set_version" => "mixed_prompt_version",
        "runtime_version" => "mixed_runtime_version",
        "schema_set_version" => "mixed_schema_set_version"
      }.freeze

      def build(run_records:)
        records = Array(run_records).map { |r| normalize(r) }

        # --- 比較可能性の前段フィルタ（design §1 の確認順序） ---------------
        # 1. comparison_eligibility_note の不可理由を先に尊重（design §1）。
        eligibility_excluded, after_note = partition_eligibility(records)
        # 2. review-mode による標準集団切り分け（classification 所有の
        #    in_standard_runtime_comparison_set を尊重。silent 混入防止）。
        review_mode_excluded, after_mode = partition_review_mode(after_note)
        # 3. treatment-driven step omission と runtime failure を区別
        #    （Req2 受入 3。failure_gap の run は比較から障害排除する。
        #    design_skip は排除しない）。
        failure_excluded, after_failure = partition_runtime_failure(after_mode)
        # 4. valid population rule（design §3・Decision 3）。
        #    in_comparison_population（=valid）のみ標準比較。
        #    exploratory は separate appendix。invalid/blocked は集団外。
        exploratory_records = after_failure.select do |r|
          r["classification"]["classification"] == "exploratory"
        end
        valid_records = after_failure.select do |r|
          r["classification"]["in_comparison_population"] == true
        end

        {
          "treatment_comparisons" => treatment_comparisons(valid_records),
          "phase_comparisons" => phase_comparisons(valid_records),
          "exploratory_appendix" =>
            exploratory_appendix(exploratory_records),
          "respected_eligibility_note_exclusions" => eligibility_excluded,
          "review_mode_excluded" => review_mode_excluded,
          "runtime_failure_excluded" => failure_excluded
        }
      end

      private

      def normalize(record)
        {
          "run_id" => record["run_id"],
          "classification" => record.fetch("classification"),
          "metrics" => record.fetch("metrics"),
          "metadata" => record.fetch("metadata", {}) || {},
          "comparison_eligibility" => record["comparison_eligibility"]
        }
      end

      # --- step 1: eligibility note 不可理由を先に尊重（design §1） ----------
      # runtime 所有 6 項目のうち eligible_for_standard_comparison が false の
      # run は標準比較に入れず ineligibility_reason_codes を保持する。
      def partition_eligibility(records)
        excluded = []
        kept = []
        records.each do |r|
          note = r["comparison_eligibility"]
          if note.is_a?(Hash) &&
             note["eligible_for_standard_comparison"] == false
            excluded << {
              "run_id" => r["run_id"],
              "ineligibility_reason_codes" =>
                Array(note["ineligibility_reason_codes"])
            }
          else
            kept << r
          end
        end
        [excluded, kept]
      end

      # --- step 2: review-mode 標準集団切り分け（classification 所有尊重） ---
      # valid だが in_standard_runtime_comparison_set=false（manual dogfooding
      # 等）の run は標準 runtime-mediated 比較に silent 混入させない。
      # exploratory/invalid/blocked は後段 valid population rule で扱うため
      # ここでは valid のみ対象にする。
      def partition_review_mode(records)
        excluded = []
        kept = []
        records.each do |r|
          cls = r["classification"]
          if cls["classification"] == "valid" &&
             cls["in_standard_runtime_comparison_set"] == false
            excluded << {
              "run_id" => r["run_id"],
              "review_mode" => cls["review_mode"],
              "review_mode_slice_codes" =>
                Array(cls["review_mode_slice_codes"])
            }
          else
            kept << r
          end
        end
        [excluded, kept]
      end

      # --- step 3: treatment-driven skip vs runtime failure（Req2 受入 3） --
      # ClassificationEngine の step_omission_disposition を正本に弁別する
      # （評価は Treatment×Step 対応を再定義しない）。failure_gap を含む run
      # は比較から障害排除する。design_skip は排除しない。
      def partition_runtime_failure(records)
        excluded = []
        kept = []
        records.each do |r|
          disp = r["classification"]["step_omission_disposition"] || {}
          failure_steps = disp.select do |_sid, d|
            d.is_a?(Hash) && d["kind"] == "failure_gap"
          end.keys
          if failure_steps.empty?
            kept << r
          else
            excluded << {
              "run_id" => r["run_id"],
              "failure_gap_steps" => failure_steps,
              "distinction" => "runtime_failure_not_treatment_driven_skip"
            }
          end
        end
        [excluded, kept]
      end

      # --- treatment comparison（design §1、Req2 受入 1・2・4・5・6） --------

      def treatment_comparisons(records)
        if records.empty?
          return treatment_result(
            status: "invalid",
            reasons: ["no_valid_population"],
            treatments: [], aggregates: []
          )
        end

        target_reasons = target_condition_reasons(records)
        version_reasons = version_uniformity_reasons(records)
        reasons = target_reasons + version_reasons

        unless reasons.empty?
          # 比較可能性条件不成立 -> aggregate しない（Req2 受入 5・6）。
          return treatment_result(
            status: "invalid",
            reasons: reasons,
            treatments:
              records.map { |r| r["metadata"]["treatment"] }.compact.uniq.sort,
            aggregates: []
          )
        end

        treatment_result(
          status: "valid",
          reasons: [],
          treatments:
            records.map { |r| r["metadata"]["treatment"] }.compact.uniq.sort,
          aggregates: treatment_aggregates(records)
        )
      end

      # target condition（target_id）一致を確認（design §1、Req2 受入 5）。
      def target_condition_reasons(records)
        targets = records.map { |r| r["metadata"]["target_id"] }.compact.uniq
        targets.length > 1 ? ["mismatched_target_condition"] : []
      end

      # protocol/prompt/runtime/schema version uniformity（finding 6・
      # Req2 受入 6）。per-run metadata が全て揃っていても混在を検出する。
      def version_uniformity_reasons(records)
        VERSION_FIELDS.each_with_object([]) do |field, acc|
          values = records.map { |r| r["metadata"][field] }.compact.uniq
          acc << MIX_REASON_BY_FIELD.fetch(field) if values.length > 1
        end
      end

      # treatment 軸 aggregate。treatment identity を全 aggregate に見せる
      # （Req2 受入 4）。findings per run / acceptance ratio / judgment
      # invocation coverage は MetricExtractor の treatment 寄与を集約する。
      def treatment_aggregates(records)
        groups = Hash.new { |h, k| h[k] = [] }
        records.each do |r|
          c = r["metrics"].fetch("treatment_metrics_contribution")
          groups[c["treatment"]] << { "record" => r, "contribution" => c }
        end

        groups.keys.compact.sort.map do |treatment|
          entries = groups.fetch(treatment)
          contributions = entries.map { |e| e["contribution"] }
          run_count = contributions.length
          total_findings =
            contributions.sum { |c| c["total_findings"].to_i }
          decided = contributions.sum { |c| c["decided_findings"].to_i }
          accepted = contributions.sum { |c| c["accepted_findings"].to_i }
          judgment_referenced =
            contributions.sum { |c| c["judgment_ref_present"].to_i }

          {
            "treatment" => treatment,
            "run_count" => run_count,
            "run_ids" =>
              entries.map { |e| e["record"]["run_id"] }.compact.sort,
            "findings_per_run" => ratio(total_findings, run_count),
            "acceptance_ratio" => ratio(accepted, decided),
            "judgment_invocation_coverage" =>
              ratio(judgment_referenced, total_findings)
          }
        end
      end

      def treatment_result(status:, reasons:, treatments:, aggregates:)
        {
          "comparison_status" => status,
          "comparison_invalid_reason" => reasons,
          "treatments_present" => treatments,
          "treatment_aggregates" => aggregates
        }
      end

      # --- phase-aware comparison（design §2、Req7 受入 2・3・5） ------------
      # phase identity を消さず保持し phase-specific overlay 選択を明示する。
      # phase-distinct run を default で 1 集約に潰さない。

      def phase_comparisons(records)
        if records.empty?
          return {
            "comparison_status" => "invalid",
            "comparison_invalid_reason" => ["no_valid_phase_population"],
            "phase_slices" => []
          }
        end

        groups = Hash.new { |h, k| h[k] = [] }
        records.each do |r|
          groups[r["metadata"]["phase_profile"]] << r
        end

        slices = groups.keys.compact.sort.map do |phase|
          entries = groups.fetch(phase)
          {
            "phase_profile" => phase,
            # phase-specific overlay 選択を明示（design §2、Req7 受入 3）。
            # MetricExtractor の phase overlay 正本を再導出しない。
            "selected_overlay" => selected_overlay(entries),
            "run_count" => entries.length,
            "run_ids" => entries.map { |e| e["run_id"] }.compact.sort,
            "treatments_present" =>
              entries.map { |e| e["metadata"]["treatment"] }.compact.uniq.sort
          }
        end

        {
          "comparison_status" => "valid",
          "comparison_invalid_reason" => [],
          "phase_slices" => slices
        }
      end

      # phase slice の overlay は MetricExtractor の phase_metric_profile の
      # overlay_observation_points を正本とする（評価内で再導出しない）。
      def selected_overlay(entries)
        profiles = entries.map do |e|
          profile = e["metrics"]["phase_metric_profile"] || {}
          profile["overlay_observation_points"]
        end.compact.uniq
        # 同一 phase 内は overlay 観点が一意のはず。複数なら先頭を保持し
        # phase identity を消さない（潰さない）。
        profiles.first || []
      end

      # --- exploratory separate appendix（design §3・Decision 3） -----------
      # 主比較に混ぜず appendix-style aggregate として保持する。
      def exploratory_appendix(records)
        return nil if records.empty?

        {
          "aggregate_role" => "appendix",
          "treatment_aggregates" => treatment_aggregates(records)
        }
      end

      def ratio(numerator, denominator)
        return 0.0 if denominator.to_i.zero?

        numerator.to_f / denominator
      end
    end
  end
end
