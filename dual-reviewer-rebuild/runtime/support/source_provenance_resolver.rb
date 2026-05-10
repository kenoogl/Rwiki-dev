# frozen_string_literal: true

require "open3"
require "pathname"

module DualReviewer
  module Runtime
    class SourceProvenanceResolver
      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def repository_id
        stdout, status = Open3.capture2("git", "config", "--get", "remote.origin.url", chdir: repo_root.to_s)
        return repo_root.basename.to_s unless status.success?

        origin_url_to_repository_id(stdout.strip)
      end

      def revision
        stdout, status = Open3.capture2("git", "rev-parse", "HEAD", chdir: repo_root.to_s)
        status.success? ? stdout.strip : "UNKNOWN"
      end

      private

      def origin_url_to_repository_id(origin_url)
        return repo_root.basename.to_s if origin_url.empty?

        normalized = origin_url.sub(%r{\Ahttps://github\.com/}, "").sub(%r{\Agit@github\.com:}, "")
        normalized.delete_suffix(".git")
      end
    end
  end
end
