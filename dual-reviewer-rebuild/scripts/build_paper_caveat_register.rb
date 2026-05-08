#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require_relative "paper_interface/paper_caveat_register_builder"
require_relative "paper_interface/paper_caveat_register_writer"

repo_root = Pathname(__dir__).join("..").expand_path
builder = DualReviewer::PaperInterface::PaperCaveatRegisterBuilder.new(repo_root: repo_root)
writer = DualReviewer::PaperInterface::PaperCaveatRegisterWriter.new(repo_root: repo_root)

payload = builder.build_paper_caveat_register
path = writer.write_paper_caveat_register(payload: payload)

puts "wrote #{path}"
puts "paper_caveat_count=#{payload.fetch('entries').length}"
