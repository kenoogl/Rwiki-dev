#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "yaml"

module DualReviewer
  module SelfImprovement
    class ProposalStatusUpdater
      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def update_status(proposal_id:, status:)
        proposal_path = repo_root.join("learning/proposals/#{proposal_id}.yaml")
        proposal = YAML.load_file(proposal_path)
        proposal["status"] = status
        proposal_path.write(YAML.dump(proposal))
        refresh_index_status(proposal_id: proposal_id, status: status)
      end

      private

      def refresh_index_status(proposal_id:, status:)
        index_path = repo_root.join("learning/proposals/proposal_index.json")
        payload = JSON.parse(index_path.read)
        entry = payload.fetch("entries").find { |item| item["proposal_id"] == proposal_id }
        return unless entry

        entry["status"] = status
        index_path.write(JSON.pretty_generate(payload))
      end
    end
  end
end
