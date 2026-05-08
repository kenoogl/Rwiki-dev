#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

module DualReviewer
  module Evaluation
    class CaveatWriter
      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def write(caveats:)
        path = repo_root.join("experiments/analysis/caveats/caveat_register.json")
        payload = { "entries" => caveats }
        path.write(JSON.pretty_generate(payload))
        path
      end
    end
  end
end
