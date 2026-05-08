#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

module DualReviewer
  module SelfImprovement
    class PatternCandidateWriter
      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def write_candidates(candidates:)
        payload = {
          "generated_at" => candidates.first && candidates.first["created_at"],
          "entries" => candidates
        }
        path = repo_root.join("learning/findings/pattern_candidates.json")
        path.write(JSON.pretty_generate(payload))
        path
      end
    end
  end
end
