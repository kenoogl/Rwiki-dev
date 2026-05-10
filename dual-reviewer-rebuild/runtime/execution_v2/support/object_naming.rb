# frozen_string_literal: true

module DualReviewer
  module Runtime
    module ExecutionV2
      class ObjectNaming
        def review_artifact_filename
          "review_artifact.json"
        end

        def metric_snapshot_filename
          "metric_snapshot.json"
        end

        def trace_note_filename
          "trace_note.json"
        end

        def signal_linkage_note_filename
          "signal_linkage_note.json"
        end
      end
    end
  end
end
