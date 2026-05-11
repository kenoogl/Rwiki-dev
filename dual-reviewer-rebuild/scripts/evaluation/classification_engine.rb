#!/usr/bin/env ruby
# frozen_string_literal: true

module DualReviewer
  module Evaluation
    class ClassificationEngine
      TERMINAL_HUMAN_SIGNOFF_STATUSES = %w[approved rejected deferred].freeze

      def classify_local_run(run_intake:)
        metadata = run_intake.fetch("metadata")
        missing_artifacts = run_intake.fetch("missing_artifacts")

        unless metadata["run_status"] == "closed"
          return classification_result(
            run_id: metadata["run_id"],
            classification: "analysis_blocked",
            phase_profile: metadata["phase_profile"],
            treatment: metadata["treatment"],
            reason_codes: ["run_not_closed"],
            reason_details: ["Run lifecycle is #{metadata['run_status'] || 'unknown'} and is not ready for analysis."]
          )
        end

        if missing_artifacts.any?
          return classification_result(
            run_id: metadata["run_id"],
            classification: "analysis_blocked",
            phase_profile: metadata["phase_profile"],
            treatment: metadata["treatment"],
            reason_codes: ["required_artifact_missing"],
            reason_details: ["Missing evaluation input artifacts: #{missing_artifacts.join(', ')}"]
          )
        end

        classify_from_metadata(
          run_id: metadata["run_id"],
          phase_profile: metadata["phase_profile"],
          treatment: metadata["treatment"],
          metadata: metadata,
          invalidation_markers: run_intake.fetch("artifacts").fetch("invalidation_markers").fetch("invalidation_markers", [])
        )
      end

      def classify_imported_bundle(bundle_intake:, admission_result:)
        run_intake = bundle_intake["run_intake"]
        metadata = run_intake ? run_intake.fetch("metadata") : {}

        if bundle_intake.fetch("ingestion_status") == "incomplete"
          return classification_result(
            run_id: admission_result["run_id"] || metadata["run_id"],
            classification: "analysis_blocked",
            phase_profile: metadata["phase_profile"],
            treatment: metadata["treatment"],
            reason_codes: ["bundle_ingestion_incomplete"],
            reason_details: ["Imported bundle is missing required artifacts for evaluation intake."]
          )
        end

        if admission_result.fetch("admission_status") == "rejected"
          return classification_result(
            run_id: admission_result["run_id"] || metadata["run_id"],
            classification: "analysis_blocked",
            phase_profile: metadata["phase_profile"],
            treatment: metadata["treatment"],
            reason_codes: ["bundle_rejected_before_classification"],
            reason_details: ["Imported bundle was rejected during admission and is not eligible for classification."]
          )
        end

        if admission_result.fetch("admission_status") == "admitted_exploratory"
          return classification_result(
            run_id: admission_result["run_id"] || metadata["run_id"],
            classification: "exploratory",
            phase_profile: metadata["phase_profile"],
            treatment: metadata["treatment"],
            reason_codes: admission_result.fetch("admission_reason_codes"),
            reason_details: ["Imported bundle is retained for exploratory analysis only."]
          )
        end

        classify_from_metadata(
          run_id: admission_result["run_id"] || metadata["run_id"],
          phase_profile: metadata["phase_profile"],
          treatment: metadata["treatment"],
          metadata: metadata,
          invalidation_markers: run_intake.fetch("artifacts").fetch("invalidation_markers").fetch("invalidation_markers", [])
        )
      end

      private

      def classify_from_metadata(run_id:, phase_profile:, treatment:, metadata:, invalidation_markers:)
        if invalidation_markers.any? || metadata["validator_status"] == "failed"
          classification_result(
            run_id: run_id,
            classification: "invalid",
            phase_profile: phase_profile,
            treatment: treatment,
            reason_codes: invalid_reason_codes(metadata, invalidation_markers),
            reason_details: invalid_reason_details(metadata, invalidation_markers)
          )
        elsif metadata["evidence_class"] == "exploratory"
          classification_result(
            run_id: run_id,
            classification: "exploratory",
            phase_profile: phase_profile,
            treatment: treatment,
            reason_codes: ["evidence_class_exploratory"],
            reason_details: ["Run metadata marks the evidence class as exploratory."]
          )
        elsif metadata["validator_status"] == "passed" &&
              TERMINAL_HUMAN_SIGNOFF_STATUSES.include?(metadata["human_signoff_status"]) &&
              metadata["evidence_class"] == "valid"
          classification_result(
            run_id: run_id,
            classification: "valid",
            phase_profile: phase_profile,
            treatment: treatment,
            reason_codes: ["valid_population_member"],
            reason_details: ["Run satisfies validator, sign-off, and evidence-class conditions for valid analysis population."]
          )
        else
          classification_result(
            run_id: run_id,
            classification: "analysis_blocked",
            phase_profile: phase_profile,
            treatment: treatment,
            reason_codes: ["classification_precondition_not_met"],
            reason_details: ["Run metadata does not satisfy valid, invalid, or exploratory classification rules."]
          )
        end
      end

      def invalid_reason_codes(metadata, invalidation_markers)
        codes = []
        codes << "validator_failed" if metadata["validator_status"] == "failed"
        codes.concat(invalidation_markers.map { |marker| "invalidation:#{marker['reason_code']}" })
        codes.empty? ? ["invalid_without_marker_detail"] : codes
      end

      def invalid_reason_details(metadata, invalidation_markers)
        details = []
        details << "validator_status is failed" if metadata["validator_status"] == "failed"
        details.concat(invalidation_markers.map { |marker| marker["reason_detail"] })
        details.empty? ? ["Invalid classification triggered without a more specific marker detail."] : details
      end

      def classification_result(run_id:, classification:, phase_profile:, treatment:, reason_codes:, reason_details:)
        {
          "run_id" => run_id,
          "classification" => classification,
          "reason_codes" => reason_codes,
          "reason_details" => reason_details,
          "phase_profile" => phase_profile,
          "treatment" => treatment
        }
      end
    end
  end
end
