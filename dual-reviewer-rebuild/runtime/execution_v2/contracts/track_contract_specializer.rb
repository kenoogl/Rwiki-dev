# frozen_string_literal: true

module DualReviewer
  module Runtime
    module ExecutionV2
      class TrackContractSpecializer
        REQUIRED_TRACK_INPUTS = {
          "intent" => %w[intent_ref supporting_refs traceability_refs],
          "spec" => %w[reviewed_phase reviewed_phase_ref adjacent_phase_refs alignment_refs],
          "implementation" => %w[implementation_snapshot_ref upstream_spec_refs governance_refs]
        }.freeze

        def specialize(track:, common_inputs:, track_inputs:)
          required_fields = REQUIRED_TRACK_INPUTS.fetch(track) do
            raise ArgumentError, "unsupported track for specialization: #{track}"
          end

          missing = required_fields.reject { |field| track_inputs.key?(field) }
          raise ArgumentError, "missing #{track} track inputs: #{missing.join(', ')}" unless missing.empty?

          {
            "track" => track,
            "common_inputs" => common_inputs,
            "track_inputs" => track_inputs
          }
        end
      end
    end
  end
end
