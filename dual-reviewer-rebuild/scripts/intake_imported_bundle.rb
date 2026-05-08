#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require_relative "evaluation/imported_bundle_loader"

repo_root = File.expand_path("..", __dir__)
bundle_root = ARGV.fetch(0) do
  abort "usage: ruby scripts/intake_imported_bundle.rb <bundle_root>"
end

loader = DualReviewer::Evaluation::ImportedBundleLoader.new(repo_root: repo_root)
result = loader.load_bundle(bundle_root: File.expand_path(bundle_root, repo_root))

puts JSON.pretty_generate(result)
