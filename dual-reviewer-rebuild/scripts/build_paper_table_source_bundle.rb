#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require_relative "paper_interface/table_source_bundle_builder"
require_relative "paper_interface/table_source_bundle_writer"

repo_root = Pathname(__dir__).join("..").expand_path
builder = DualReviewer::PaperInterface::TableSourceBundleBuilder.new(repo_root: repo_root)
writer = DualReviewer::PaperInterface::TableSourceBundleWriter.new(repo_root: repo_root)

payload = builder.build_table_source_bundle
path = writer.write_table_source_bundle(payload: payload)

puts "wrote #{path}"
puts "table_bundle_count=#{payload.fetch('entries').length}"
