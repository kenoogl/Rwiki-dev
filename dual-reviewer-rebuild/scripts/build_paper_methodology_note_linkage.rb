#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require_relative "paper_interface/methodology_note_linkage_builder"
require_relative "paper_interface/methodology_note_linkage_writer"

repo_root = Pathname(__dir__).join("..").expand_path
builder = DualReviewer::PaperInterface::MethodologyNoteLinkageBuilder.new(repo_root: repo_root)
writer = DualReviewer::PaperInterface::MethodologyNoteLinkageWriter.new(repo_root: repo_root)

payload = builder.build_methodology_note_linkage
path = writer.write_methodology_note_linkage(payload: payload)

puts "wrote #{path}"
puts "methodology_note_count=#{payload.fetch('entries').length}"
