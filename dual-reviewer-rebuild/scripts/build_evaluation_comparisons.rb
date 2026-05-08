#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require_relative "evaluation/comparison_builder"
require_relative "evaluation/comparison_writer"

repo_root = File.expand_path("..", __dir__)
run_metrics_path = File.join(repo_root, "experiments/analysis/metrics/run_metrics.json")
classification_path = File.join(repo_root, "experiments/analysis/classifications/run_classification_index.json")

run_metrics_entries = JSON.parse(File.read(run_metrics_path)).fetch("entries")
classification_entries = JSON.parse(File.read(classification_path)).fetch("entries")

builder = DualReviewer::Evaluation::ComparisonBuilder.new
writer = DualReviewer::Evaluation::ComparisonWriter.new(repo_root: repo_root)

result = builder.build(
  run_metrics_entries: run_metrics_entries,
  classification_entries: classification_entries
)

treatment_metrics_path = writer.write_treatment_metrics(payload: { "entries" => result.fetch("treatment_metrics") })
treatment_comparisons_path = writer.write_treatment_comparisons(payload: result.fetch("treatment_comparisons"))
phase_comparisons_path = writer.write_phase_comparisons(payload: result.fetch("phase_comparisons"))

puts JSON.pretty_generate(
  {
    "result" => result,
    "treatment_metrics_path" => treatment_metrics_path.to_s,
    "treatment_comparisons_path" => treatment_comparisons_path.to_s,
    "phase_comparisons_path" => phase_comparisons_path.to_s
  }
)
