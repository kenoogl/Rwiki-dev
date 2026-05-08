#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "time"

module DualReviewer
  module PaperInterface
    class MethodologyNoteLinkageBuilder
      ADOPTION_REGISTER_REF = "learning/approved-updates/adoption_register.json"

      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def build_methodology_note_linkage
        adoption_entries = load_entries(repo_root.join(ADOPTION_REGISTER_REF))
        adopted_entries = adoption_entries.select { |entry| entry["decision_state"] == "adopted" }

        {
          "generated_at" => Time.now.utc.iso8601,
          "entries" => adopted_entries.map do |entry|
            {
              "methodology_note_id" => "methodology-note-#{entry.fetch('proposal_id')}",
              "source_adoption_ref" => "#{ADOPTION_REGISTER_REF}##{entry.fetch('proposal_id')}",
              "linked_repo_change_ref" => entry["linked_repo_change_ref"],
              "note_scope" => "system_revision_history",
              "narrative_stub" => "Adopted system revision #{entry['linked_repo_change_ref']} originated from proposal #{entry['proposal_id']}. This note is methodology-only and not a performance claim.",
              "claim_support_allowed" => false
            }
          end
        }
      end

      private

      def load_entries(path)
        return [] unless path.exist?

        JSON.parse(path.read).fetch("entries", [])
      end
    end
  end
end
