#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "time"
require "yaml"
require_relative "proposal_status_updater"

module DualReviewer
  module SelfImprovement
    class HistoryRegistry
      attr_reader :repo_root, :proposal_status_updater

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
        @proposal_status_updater = ProposalStatusUpdater.new(repo_root: @repo_root)
      end

      def record_approval(proposal_id:, reviewer_note:)
        ensure_backtest_exists!(proposal_id)
        proposal = load_proposal(proposal_id)
        entry = {
          "proposal_id" => proposal_id,
          "decision_state" => "approved",
          "target_layer" => proposal["target_layer"],
          "required_test_mode" => proposal["required_test_mode"],
          "linked_repo_change_ref" => nil,
          "backtest_ref" => backtest_ref(proposal_id),
          "approved_at" => Time.now.utc.iso8601,
          "reviewer_note" => reviewer_note
        }
        append_register("learning/approved-updates/adoption_register.json", entry)
        proposal_status_updater.update_status(proposal_id: proposal_id, status: "approved")
      end

      def record_adoption(proposal_id:, linked_repo_change_ref:, reviewer_note:)
        ensure_backtest_exists!(proposal_id)
        ensure_approved_or_tested!(proposal_id)
        proposal = load_proposal(proposal_id)
        entry = {
          "proposal_id" => proposal_id,
          "decision_state" => "adopted",
          "target_layer" => proposal["target_layer"],
          "required_test_mode" => proposal["required_test_mode"],
          "linked_repo_change_ref" => linked_repo_change_ref,
          "backtest_ref" => backtest_ref(proposal_id),
          "adopted_at" => Time.now.utc.iso8601,
          "reviewer_note" => reviewer_note
        }
        append_register("learning/approved-updates/adoption_register.json", entry)
        proposal_status_updater.update_status(proposal_id: proposal_id, status: "adopted")
      end

      def record_rejection(proposal_id:, rejection_reason:, reviewer_note:)
        entry = {
          "proposal_id" => proposal_id,
          "rejection_reason" => rejection_reason,
          "rejected_at" => Time.now.utc.iso8601,
          "reviewer_note" => reviewer_note
        }
        append_register("learning/rejected-updates/rejection_register.json", entry)
        proposal_status_updater.update_status(proposal_id: proposal_id, status: "rejected")
      end

      def record_rollback(proposal_id:, adopted_change_ref:, rollback_reason:, rollback_trigger_signal_refs:)
        ensure_adopted!(proposal_id)
        entry = {
          "proposal_id" => proposal_id,
          "adopted_change_ref" => adopted_change_ref,
          "rollback_reason" => rollback_reason,
          "rollback_trigger_signal_refs" => rollback_trigger_signal_refs,
          "rolled_back_at" => Time.now.utc.iso8601
        }
        append_register("learning/rollback/rollback_register.json", entry)
        proposal_status_updater.update_status(proposal_id: proposal_id, status: "rolled_back")
      end

      private

      def load_proposal(proposal_id)
        YAML.load_file(repo_root.join("learning/proposals/#{proposal_id}.yaml"))
      end

      def append_register(relative_path, entry)
        path = repo_root.join(relative_path)
        payload = path.exist? ? JSON.parse(path.read) : { "entries" => [] }
        payload["entries"] << entry
        path.write(JSON.pretty_generate(payload))
        path
      end

      def backtest_ref(proposal_id)
        "learning/backtests/#{proposal_id}.json"
      end

      def ensure_backtest_exists!(proposal_id)
        path = repo_root.join(backtest_ref(proposal_id))
        raise ArgumentError, "missing backtest artifact for #{proposal_id}" unless path.exist?
      end

      def ensure_approved_or_tested!(proposal_id)
        proposal = load_proposal(proposal_id)
        allowed = %w[approved tested draft awaiting_test]
        raise ArgumentError, "proposal #{proposal_id} is not eligible for adoption from status #{proposal['status']}" unless allowed.include?(proposal["status"])
      end

      def ensure_adopted!(proposal_id)
        proposal = load_proposal(proposal_id)
        raise ArgumentError, "proposal #{proposal_id} is not adopted" unless proposal["status"] == "adopted"
      end
    end
  end
end
