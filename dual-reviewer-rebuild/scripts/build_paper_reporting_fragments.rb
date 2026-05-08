#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require_relative "paper_interface/reporting_fragments_builder"
require_relative "paper_interface/reporting_fragments_writer"

repo_root = Pathname(__dir__).join("..").expand_path
builder = DualReviewer::PaperInterface::ReportingFragmentsBuilder.new(repo_root: repo_root)
writer = DualReviewer::PaperInterface::ReportingFragmentsWriter.new(repo_root: repo_root)

payload = builder.build_reporting_fragments
path = writer.write_reporting_fragments(payload: payload)

puts "wrote #{path}"
puts "fragment_count=#{payload.fetch('entries').length}"
