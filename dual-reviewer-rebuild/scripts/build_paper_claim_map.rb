#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require_relative "paper_interface/claim_map_builder"
require_relative "paper_interface/claim_map_writer"

analysis_root = ARGV.shift || "experiments/analysis"

repo_root = Pathname(__dir__).join("..").expand_path
builder = DualReviewer::PaperInterface::ClaimMapBuilder.new(repo_root: repo_root)
writer = DualReviewer::PaperInterface::ClaimMapWriter.new(repo_root: repo_root)

payload = builder.build_claim_map(analysis_root: repo_root.join(analysis_root))
path = writer.write_claim_map(payload: payload)

puts "wrote #{path}"
puts "claim_count=#{payload.fetch('entries').length}"
