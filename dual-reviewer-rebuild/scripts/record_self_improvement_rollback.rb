#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require_relative "self_improvement/history_registry"

proposal_id = ARGV.shift
adopted_change_ref = ARGV.shift
rollback_reason = ARGV.shift
trigger_signal_refs = (ARGV.shift || "").split(",").reject(&:empty?)

if [proposal_id, adopted_change_ref, rollback_reason].any? { |value| value.nil? || value.empty? }
  warn "usage: ruby scripts/record_self_improvement_rollback.rb <proposal_id> <adopted_change_ref> <rollback_reason> [trigger_signal_refs_csv]"
  exit 1
end

repo_root = Pathname(__dir__).join("..").expand_path
registry = DualReviewer::SelfImprovement::HistoryRegistry.new(repo_root: repo_root)
registry.record_rollback(
  proposal_id: proposal_id,
  adopted_change_ref: adopted_change_ref,
  rollback_reason: rollback_reason,
  rollback_trigger_signal_refs: trigger_signal_refs
)

puts "recorded rollback for #{proposal_id}"
