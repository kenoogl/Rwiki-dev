# frozen_string_literal: true

module DualReviewer
  module Runtime
    module ExecutionV2
      class CommonExecutionContract
        REQUIRED_COMMON_INPUTS = %w[
          track
          target_id
          target_artifact_hash
          source_repository_id
          source_revision
          phase_profile
          treatment
          review_mode
          source_refs
          governance_refs
          case_manifest_ref
        ].freeze

        CONTRACT_VERSION = "v2-draft-1"

        attr_reader :asset_loader

        def initialize(asset_loader:)
          @asset_loader = asset_loader
        end

        def build(common_inputs:, track_inputs: {})
          validate_common_inputs!(common_inputs)

          {
            "contract_version" => CONTRACT_VERSION,
            "common_inputs" => common_inputs,
            "track_inputs" => track_inputs,
            "provenance_tuple" => {
              "target_id" => common_inputs.fetch("target_id"),
              "target_artifact_hash" => common_inputs.fetch("target_artifact_hash"),
              "source_repository_id" => common_inputs.fetch("source_repository_id"),
              "source_revision" => common_inputs.fetch("source_revision")
            }
          }
        end

        def validate_common_inputs!(common_inputs)
          missing = REQUIRED_COMMON_INPUTS.reject { |field| common_inputs.key?(field) }
          raise ArgumentError, "missing common execution inputs: #{missing.join(', ')}" unless missing.empty?

          validate_track!(common_inputs.fetch("track"))
          validate_phase_profile!(common_inputs.fetch("phase_profile"))
          validate_treatment!(common_inputs.fetch("treatment"))
          validate_review_mode!(common_inputs.fetch("review_mode"))
          validate_reference_array!(common_inputs.fetch("source_refs"), field_name: "source_refs")
          validate_reference_array!(common_inputs.fetch("governance_refs"), field_name: "governance_refs")

          true
        end

        private

        def validate_track!(track)
          allowed = %w[intent spec implementation]
          return if allowed.include?(track)

          raise ArgumentError, "unsupported track: #{track}"
        end

        def validate_phase_profile!(phase_profile)
          allowed = asset_loader.metadata_contract.fetch("enum_definitions").fetch("phase_profile")
          return if allowed.include?(phase_profile)

          raise ArgumentError, "unsupported phase_profile: #{phase_profile}"
        end

        def validate_treatment!(treatment)
          allowed = asset_loader.metadata_contract.fetch("enum_definitions").fetch("treatment")
          return if allowed.include?(treatment)

          raise ArgumentError, "unsupported treatment: #{treatment}"
        end

        def validate_review_mode!(review_mode)
          allowed = asset_loader.review_mode_vocabulary.fetch("review_modes").map { |entry| entry.fetch("mode") }
          return if allowed.include?(review_mode)

          raise ArgumentError, "unsupported review_mode: #{review_mode}"
        end

        def validate_reference_array!(value, field_name:)
          return if value.is_a?(Array) && value.all? { |entry| entry.is_a?(String) && !entry.empty? }

          raise ArgumentError, "#{field_name} must be a non-empty-string array"
        end
      end
    end
  end
end
