#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require_relative "self_improvement/pattern_candidate_builder"
require_relative "self_improvement/pattern_candidate_writer"

repo_root = Pathname(__dir__).join("..").expand_path
builder = DualReviewer::SelfImprovement::PatternCandidateBuilder.new(repo_root: repo_root)
writer = DualReviewer::SelfImprovement::PatternCandidateWriter.new(repo_root: repo_root)

candidates = builder.build_candidates
path = writer.write_candidates(candidates: candidates)

puts "wrote #{path}"
puts "pattern_candidate_count=#{candidates.length}"
