# frozen_string_literal: true

require "pathname"
require "yaml"

module DualReviewer
  module Runtime
    module ExecutionV2
      class HeuristicProfileLoader
        attr_reader :repo_root

        def initialize(repo_root:)
          @repo_root = Pathname(repo_root).expand_path
        end

        def load(ref:)
          return {} if ref.nil? || ref.empty?

          YAML.load_file(resolve(ref))
        end

        private

        def resolve(ref)
          ref_path = Pathname(ref)
          return ref_path if ref_path.absolute?

          primary = repo_root.join(ref_path)
          return primary if primary.exist?

          secondary = repo_root.parent.join(ref_path)
          return secondary if secondary.exist?

          raise ArgumentError, "heuristic profile not found: #{ref}"
        end
      end
    end
  end
end
