# frozen_string_literal: true

require "securerandom"
require "time"

module DualReviewer
  module Runtime
    class ValidationBridge
      attr_reader :asset_loader

      def initialize(asset_loader:)
        @asset_loader = asset_loader
      end

      def validator_contracts
        {
          "metadata_contract" => asset_loader.metadata_contract.fetch("contract_id"),
          "review_mode_vocab_version" => asset_loader.review_mode_vocabulary.fetch("version")
        }
      end

      def validate_run(run_id:, metadata:, human_signoff:)
        checks = []
        invalidation_markers = []

        checks << required_metadata_check(metadata)
        checks << review_mode_check(metadata.fetch("review_mode"))

        if human_signoff.fetch("human_signoff_status") != "approved"
          checks << failed_check(
            check_id: "human-signoff-status",
            message: "Run cannot be treated as ready because human sign-off is not approved."
          )
          invalidation_markers << invalidation_marker(
            run_id: run_id,
            reason_code: "human_signoff_missing",
            reason_detail: "Run close was attempted without approved human sign-off.",
            scope: "run",
            issued_by: "validator"
          )
        else
          checks << passed_check(
            check_id: "human-signoff-status",
            message: "Human sign-off is approved."
          )
        end

        overall_status = checks.any? { |check| check.fetch("status") == "failed" } ? "failed" : "passed"

        {
          "validator_result" => {
            "schema_version" => "1.0.0",
            "validator_result_id" => "validator-result-#{SecureRandom.hex(4)}",
            "run_id" => run_id,
            "validator_name" => "runtime-validation-bridge",
            "validator_version" => "0.1.0",
            "review_mode" => metadata.fetch("review_mode"),
            "overall_status" => overall_status,
            "executed_at" => Time.now.utc.iso8601,
            "checks" => checks,
            "invalidation_marker_refs" => invalidation_markers.map { |marker| marker.fetch("invalidation_marker_id") }
          },
          "invalidation_markers" => invalidation_markers
        }
      end

      private

      def required_metadata_check(metadata)
        required_fields = asset_loader.metadata_contract.fetch("required_fields")
        missing = required_fields.reject { |field| metadata.key?(field) && !metadata[field].nil? }
        if missing.empty?
          passed_check(check_id: "required-metadata", message: "All required metadata fields are present.")
        else
          failed_check(check_id: "required-metadata", message: "Missing required metadata fields: #{missing.join(', ')}")
        end
      end

      def review_mode_check(review_mode)
        valid_modes = asset_loader.review_mode_vocabulary.fetch("review_modes").map { |entry| entry.fetch("mode") }
        if valid_modes.include?(review_mode)
          passed_check(check_id: "review-mode-vocabulary", message: "Review mode is in canonical vocabulary.")
        else
          failed_check(check_id: "review-mode-vocabulary", message: "Review mode is not in canonical vocabulary.")
        end
      end

      def passed_check(check_id:, message:)
        {
          "check_id" => check_id,
          "status" => "passed",
          "severity" => "info",
          "message" => message
        }
      end

      def failed_check(check_id:, message:)
        {
          "check_id" => check_id,
          "status" => "failed",
          "severity" => "error",
          "message" => message
        }
      end

      def invalidation_marker(run_id:, reason_code:, reason_detail:, scope:, issued_by:)
        {
          "schema_version" => "1.0.0",
          "invalidation_marker_id" => "invalid-#{SecureRandom.hex(4)}",
          "run_id" => run_id,
          "step_id" => nil,
          "finding_id" => nil,
          "reason_code" => reason_code,
          "reason_detail" => reason_detail,
          "scope" => scope,
          "issued_by" => issued_by,
          "issued_at" => Time.now.utc.iso8601
        }
      end
    end
  end
end
