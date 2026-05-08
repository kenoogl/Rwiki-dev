#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

module DualReviewer
  module PaperInterface
    class PaperCaveatRegisterWriter
      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def write_paper_caveat_register(payload:)
        path = repo_root.join("paper/caveats/paper_caveat_register.json")
        path.write(JSON.pretty_generate(payload))
        path
      end
    end
  end
end
