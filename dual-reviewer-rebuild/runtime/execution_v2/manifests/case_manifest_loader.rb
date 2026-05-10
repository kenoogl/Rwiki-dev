# frozen_string_literal: true

require "pathname"
require "yaml"
require_relative "case_manifest"

module DualReviewer
  module Runtime
    module ExecutionV2
      class CaseManifestLoader
        attr_reader :repo_root, :case_manifest

        def initialize(repo_root:)
          @repo_root = Pathname(repo_root).expand_path
          @case_manifest = CaseManifest.new
        end

        def load(path_ref)
          path = Pathname(path_ref)
          path = repo_root.join(path) unless path.absolute?
          payload = YAML.load_file(path)
          case_manifest.build(payload.merge("case_manifest_ref" => path.relative_path_from(repo_root).to_s))
        end
      end
    end
  end
end
