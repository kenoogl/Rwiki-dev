#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "imported_bundle_loader"

# Task 7: imported evidence admission（評価所有・スクラッチ再実装）
# 根拠: tasks.md Task 7、Requirement 10 受入 2〜5、design「Admission States
#       for Imported Bundles」「Imported Evidence Intake Artifacts」。
#       適合レビュー 2026-05-19 finding 4（撤廃 review_mode 語彙非依存）。
#
# スクラッチ方針: 旧 v1 admission_evaluator（review_mode 駆動・ingestion_status
# 語彙前提・撤廃語彙）は流用せず破棄して作り直す。
#
# 本モジュールは admission 判定の単一所有者である（Req10 受入 4）。判定は
# design「Admission States」の優先順で評価し、最初に該当した状態を採る:
#   1. rejected            （bundle_manifest 不在/不正・必須 provenance 欠落・
#                            必須 intake 入力 schema 不適合で読めない）
#   2. admitted_exploratory（必須 intake は読めるが provenance 非致命欠落・
#                            version 不整合/mixed maturity・low sample/
#                            exploratory-only・manual_dogfooding・
#                            invalidation marker 在）
#   3. admitted_standard   （必須 intake 完備・required provenance 完備・
#                            version 整合・invalidation marker 無し）
# Task 3 は本 Task の admission_status を参照のみ（再判定しない）。
module DualReviewer
  module Evaluation
    class AdmissionEvaluator
      # foundation canonical review_mode のみ（finding 4: 撤廃語彙非依存）。
      STANDARD_REVIEW_MODE = "runtime_mediated"
      MANUAL_DOGFOODING_REVIEW_MODE = "manual_dogfooding"

      # design「Admission States」rejected 条件で読めねばならない必須 intake
      # 入力（ImportedBundleLoader の EXPORTED_RUN_ARTIFACTS 部分集合）。
      REQUIRED_INTAKE_INPUTS = %w[
        run_manifest review_case validator_result invalidation_markers
      ].freeze

      def evaluate(bundle_intake:)
        manifest = bundle_intake.fetch("bundle_manifest", {}) || {}
        run_artifacts = bundle_intake.fetch("run_artifacts", {}) || {}
        review_mode = manifest["review_mode"]
        bundle_id = manifest["bundle_id"]
        run_id = manifest["run_id"]

        status, codes = decide(bundle_intake, manifest, run_artifacts)

        {
          "bundle_id" => bundle_id,
          "run_id" => run_id,
          "review_mode" => review_mode,
          "admission_status" => status,
          "admission_reason_codes" => codes,
          "eligible_for_standard_comparison" => status == "admitted_standard",
          "eligible_for_exploratory_analysis" =>
            %w[admitted_standard admitted_exploratory].include?(status)
        }
      end

      private

      # design 優先順で評価し最初に該当した状態を返す。
      def decide(bundle_intake, manifest, run_artifacts)
        # --- 1. rejected -----------------------------------------------------
        if manifest.nil? || manifest.empty? ||
           Array(bundle_intake["missing_artifacts"])
             .include?("bundle_manifest.yaml")
          return ["rejected", ["bundle_manifest_absent_or_invalid"]]
        end

        missing_prov = Array(bundle_intake["missing_provenance"])
        unless missing_prov.empty?
          return ["rejected",
                  ["required_provenance_missing:#{missing_prov.join(',')}",
                   "required_provenance_missing"]]
        end

        unreadable = REQUIRED_INTAKE_INPUTS.reject do |k|
          run_artifacts[k].is_a?(Hash)
        end
        unless unreadable.empty?
          return ["rejected",
                  ["required_intake_input_unreadable:#{unreadable.join(',')}",
                   "required_intake_input_unreadable"]]
        end

        # --- 2. admitted_exploratory ----------------------------------------
        exploratory_codes = exploratory_reason_codes(manifest, run_artifacts)
        unless exploratory_codes.empty?
          return ["admitted_exploratory", exploratory_codes]
        end

        # --- 3. admitted_standard -------------------------------------------
        ["admitted_standard", ["standard_admission_all_conditions_met"]]
      end

      # admitted_exploratory に倒す非致命理由を集める（空なら standard）。
      def exploratory_reason_codes(manifest, run_artifacts)
        codes = []

        review_mode = manifest["review_mode"]
        if review_mode == MANUAL_DOGFOODING_REVIEW_MODE
          # manual dogfooding は Phase 1 evidence。標準集団に直接入れない。
          codes << "manual_dogfooding_not_standard"
        elsif review_mode != STANDARD_REVIEW_MODE
          codes << "non_standard_review_mode:#{review_mode}"
        end

        # invalidation marker 在 -> standard にしない（design 末尾条件）。
        im = run_artifacts["invalidation_markers"]
        markers = im.is_a?(Hash) ? Array(im["invalidation_markers"]) : []
        codes << "invalidation_marker_present" unless markers.empty?

        # comparison_eligibility_note が standard 不可を宣言していれば尊重。
        note = run_artifacts["comparison_eligibility_note"]
        if note.is_a?(Hash) && note["eligible_for_standard_comparison"] == false
          codes << "eligibility_note_standard_ineligible"
          Array(note["ineligibility_reason_codes"]).each do |rc|
            codes << "eligibility:#{rc}"
          end
        end

        codes.uniq
      end
    end
  end
end
