#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require_relative "evaluation/analysis_manifest_writer"

repo_root = File.expand_path("..", __dir__)
writer = DualReviewer::Evaluation::AnalysisManifestWriter.new(repo_root: repo_root)
path = writer.write_manifest

puts JSON.pretty_generate(
  {
    "analysis_run_manifest_path" => path.to_s
  }
)
