#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require_relative "self_improvement/proposal_builder"
require_relative "self_improvement/proposal_writer"

repo_root = Pathname(__dir__).join("..").expand_path
builder = DualReviewer::SelfImprovement::ProposalBuilder.new(repo_root: repo_root)
writer = DualReviewer::SelfImprovement::ProposalWriter.new(repo_root: repo_root)

proposals = builder.build_from_signal_inventories
writer.write_proposals(proposals: proposals)

puts "wrote #{repo_root.join('learning/proposals/proposal_index.json')}"
puts "proposal_count=#{proposals.length}"
