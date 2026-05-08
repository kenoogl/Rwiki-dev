#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "yaml"

module DualReviewer
  module SelfImprovement
    class ProposalWriter
      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def write_proposals(proposals:)
        index_payload = {
          "generated_at" => proposals.first && proposals.first["created_at"],
          "entries" => proposals.map { |proposal| index_entry(proposal) }
        }

        repo_root.join("learning/proposals/proposal_index.json").write(JSON.pretty_generate(index_payload))
        proposals.each do |proposal|
          repo_root.join("learning/proposals/#{proposal.fetch('proposal_id')}.yaml").write(YAML.dump(proposal))
        end
      end

      private

      def index_entry(proposal)
        {
          "proposal_id" => proposal.fetch("proposal_id"),
          "status" => proposal.fetch("status"),
          "target_layer" => proposal.fetch("target_layer"),
          "motivation_class" => proposal.fetch("motivation_class"),
          "source_origin" => proposal.fetch("source_origin"),
          "source_provenance_status" => proposal.fetch("source_provenance_status"),
          "required_test_mode" => proposal.fetch("required_test_mode"),
          "source_signal_id" => proposal.fetch("source_signal_id"),
          "created_at" => proposal.fetch("created_at")
        }
      end
    end
  end
end
