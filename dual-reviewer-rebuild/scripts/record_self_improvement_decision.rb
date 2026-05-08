#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require_relative "self_improvement/history_registry"

mode = ARGV.shift
proposal_id = ARGV.shift

unless %w[approve adopt reject].include?(mode) && proposal_id
  warn "usage: ruby scripts/record_self_improvement_decision.rb <approve|adopt|reject> <proposal_id> [args...]"
  exit 1
end

repo_root = Pathname(__dir__).join("..").expand_path
registry = DualReviewer::SelfImprovement::HistoryRegistry.new(repo_root: repo_root)

case mode
when "approve"
  reviewer_note = ARGV.shift || "approval recorded"
  registry.record_approval(proposal_id: proposal_id, reviewer_note: reviewer_note)
when "adopt"
  linked_repo_change_ref = ARGV.shift
  reviewer_note = ARGV.shift || "adoption recorded"
  if linked_repo_change_ref.nil? || linked_repo_change_ref.empty?
    warn "adopt requires linked_repo_change_ref"
    exit 1
  end
  registry.record_adoption(
    proposal_id: proposal_id,
    linked_repo_change_ref: linked_repo_change_ref,
    reviewer_note: reviewer_note
  )
when "reject"
  rejection_reason = ARGV.shift || "unspecified_rejection"
  reviewer_note = ARGV.shift || "rejection recorded"
  registry.record_rejection(
    proposal_id: proposal_id,
    rejection_reason: rejection_reason,
    reviewer_note: reviewer_note
  )
end

puts "recorded #{mode} for #{proposal_id}"
