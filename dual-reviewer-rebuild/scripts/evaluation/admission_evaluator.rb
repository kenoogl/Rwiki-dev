#!/usr/bin/env ruby
# frozen_string_literal: true

module DualReviewer
  module Evaluation
    class AdmissionEvaluator
      STANDARD_REVIEW_MODES = ["runtime_mediated"].freeze
      EXPLORATORY_REVIEW_MODES = ["manual_dogfooding", "imported_bundle"].freeze

      def evaluate(bundle_intake:)
        bundle_manifest = bundle_intake.fetch("bundle_manifest", {})
        run_metadata = bundle_intake.fetch("run_intake", {}).fetch("metadata", {})

        reason_codes = []
        admission_status = nil

        ingestion_status = bundle_intake.fetch("ingestion_status")
        review_mode = bundle_manifest["review_mode"] || run_metadata["review_mode"]

        if ingestion_status == "checksum_failed"
          admission_status = "rejected"
          reason_codes << "checksum_verification_failed"
        elsif ingestion_status == "incomplete"
          admission_status = "rejected"
          reason_codes << "required_artifact_missing"
        elsif ingestion_status == "provenance_incomplete"
          admission_status = "admitted_exploratory"
          reason_codes << "provenance_incomplete"
        elsif STANDARD_REVIEW_MODES.include?(review_mode)
          admission_status = "admitted_standard"
          reason_codes << "standard_runtime_mode"
        elsif EXPLORATORY_REVIEW_MODES.include?(review_mode)
          admission_status = "admitted_exploratory"
          reason_codes << "non_standard_review_mode"
        else
          admission_status = "rejected"
          reason_codes << "unknown_review_mode"
        end

        {
          "bundle_id" => bundle_manifest["bundle_id"],
          "run_id" => bundle_manifest["run_id"] || run_metadata["run_id"],
          "admission_status" => admission_status,
          "admission_reason_codes" => reason_codes,
          "eligible_for_standard_comparison" => admission_status == "admitted_standard",
          "eligible_for_exploratory_analysis" => %w[admitted_standard admitted_exploratory].include?(admission_status)
        }
      end
    end
  end
end
