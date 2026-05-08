#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require_relative "evaluation/caveat_builder"
require_relative "evaluation/caveat_writer"

repo_root = File.expand_path("..", __dir__)
classification_entries = JSON.parse(File.read(File.join(repo_root, "experiments/analysis/classifications/run_classification_index.json"))).fetch("entries")
treatment_comparisons = JSON.parse(File.read(File.join(repo_root, "experiments/analysis/comparisons/treatment_comparisons.json")))
phase_comparisons = JSON.parse(File.read(File.join(repo_root, "experiments/analysis/comparisons/phase_comparisons.json")))

builder = DualReviewer::Evaluation::CaveatBuilder.new
writer = DualReviewer::Evaluation::CaveatWriter.new(repo_root: repo_root)

caveats = builder.build(
  classification_entries: classification_entries,
  treatment_comparisons: treatment_comparisons,
  phase_comparisons: phase_comparisons
)
path = writer.write(caveats: caveats)

puts JSON.pretty_generate(
  {
    "caveats" => caveats,
    "caveat_register_path" => path.to_s
  }
)
