# frozen_string_literal: true

module DualReviewer
  module TrackRuns
    module DefaultHeuristicProfileRef
      MAP = {
        "implementation" => "dual-reviewer-rebuild/experiments/protocols/heuristic_profiles/implementation/_minimal_template.yaml",
        "intent" => "dual-reviewer-rebuild/experiments/protocols/heuristic_profiles/intent/_minimal_template.yaml",
        "spec" => "dual-reviewer-rebuild/experiments/protocols/heuristic_profiles/spec/_minimal_template.yaml"
      }.freeze

      module_function

      def for_track(track)
        MAP.fetch(track)
      end
    end
  end
end
