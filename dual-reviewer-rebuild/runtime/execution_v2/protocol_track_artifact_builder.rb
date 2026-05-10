# frozen_string_literal: true

require_relative "writers/review_artifact_writer"

module DualReviewer
  module Runtime
    module ExecutionV2
      class ProtocolTrackArtifactBuilder
        attr_reader :review_artifact_writer

        def initialize
          @review_artifact_writer = ReviewArtifactWriter.new
        end

        def build(execution_contract:, analysis_result:, compatibility_projection:, decision_context_extras:, trace_note:, metric_snapshot:, signal_linkage_note:)
          decision_context = {
            "track" => execution_contract.fetch("common_inputs").fetch("track"),
            "treatment" => execution_contract.fetch("common_inputs").fetch("treatment"),
            "review_mode" => execution_contract.fetch("common_inputs").fetch("review_mode"),
            "analysis_result" => analysis_result
          }.merge(decision_context_extras)

          {
            "review_artifact" => review_artifact_writer.build(
              execution_contract: execution_contract,
              decision_context: decision_context,
              compatibility_projection: compatibility_projection
            ),
            "metric_snapshot" => metric_snapshot,
            "trace_note" => trace_note,
            "signal_linkage_note" => signal_linkage_note
          }
        end
      end
    end
  end
end
