# frozen_string_literal: true

module DualReviewer
  module Runtime
    module ExecutionV2
      class CaseManifest
        BASE_REQUIRED_FIELDS = %w[case_id track source_refs case_manifest_ref].freeze
        TRACK_REQUIRED_FIELDS = {
          "implementation" => %w[target_id implementation_snapshot_ref upstream_spec_refs governance_refs phase_profile heuristic_profile_ref],
          "spec" => %w[reviewed_phase reviewed_phase_ref adjacent_phase_refs alignment_refs analysis_profile_ref heuristic_profile_ref],
          "intent" => %w[intent_ref supporting_refs traceability_refs objective analysis_profile_ref heuristic_profile_ref]
        }.freeze

        def build(payload)
          validate!(payload)
          payload
        end

        def validate!(payload)
          missing = required_fields_for(payload).reject { |field| payload.key?(field) }
          raise ArgumentError, "missing case manifest fields: #{missing.join(', ')}" unless missing.empty?

          source_refs = payload.fetch("source_refs")
          unless source_refs.is_a?(Array) && source_refs.all? { |entry| entry.is_a?(String) && !entry.empty? }
            raise ArgumentError, "source_refs must be a non-empty-string array"
          end

          true
        end

        def required_fields_for(payload)
          track = payload["track"]
          unless TRACK_REQUIRED_FIELDS.key?(track)
            raise ArgumentError, "unsupported case manifest track: #{track.inspect}"
          end

          BASE_REQUIRED_FIELDS + TRACK_REQUIRED_FIELDS.fetch(track)
        end
      end
    end
  end
end
