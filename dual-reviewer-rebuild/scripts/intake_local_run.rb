#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require_relative "evaluation/local_run_loader"

repo_root = File.expand_path("..", __dir__)
run_root = ARGV.fetch(0) do
  abort "usage: ruby scripts/intake_local_run.rb <run_root>"
end

loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: repo_root)
result = loader.load_run(run_root: File.expand_path(run_root, repo_root))

puts JSON.pretty_generate(result)
