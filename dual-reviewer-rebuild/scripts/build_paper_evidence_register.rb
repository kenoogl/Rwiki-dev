#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require_relative "paper_interface/evidence_register_builder"
require_relative "paper_interface/evidence_register_writer"

repo_root = Pathname(__dir__).join("..").expand_path
builder = DualReviewer::PaperInterface::EvidenceRegisterBuilder.new(repo_root: repo_root)
writer = DualReviewer::PaperInterface::EvidenceRegisterWriter.new(repo_root: repo_root)

payload = builder.build_evidence_register
path = writer.write_evidence_register(payload: payload)

puts "wrote #{path}"
puts "evidence_count=#{payload.fetch('entries').length}"
