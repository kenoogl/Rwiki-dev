#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require_relative "self_improvement/replay_input_resolver"

proposal_id = ARGV.shift
unless proposal_id
  warn "usage: ruby scripts/prepare_self_improvement_replay_inputs.rb <proposal_id>"
  exit 1
end

repo_root = Pathname(__dir__).join("..").expand_path
resolver = DualReviewer::SelfImprovement::ReplayInputResolver.new(repo_root: repo_root)
puts JSON.pretty_generate(resolver.resolve_for_proposal(proposal_id: proposal_id))
