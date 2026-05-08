#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require_relative "evaluation/local_run_loader"
require_relative "evaluation/metric_extractor"
require_relative "evaluation/metric_writer"

repo_root = File.expand_path("..", __dir__)
run_root = ARGV.fetch(0) do
  abort "usage: ruby scripts/extract_evaluation_metrics.rb <run_root>"
end

run_loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: repo_root)
metric_extractor = DualReviewer::Evaluation::MetricExtractor.new
metric_writer = DualReviewer::Evaluation::MetricWriter.new(repo_root: repo_root)

run_intake = run_loader.load_run(run_root: File.expand_path(run_root, repo_root))
metrics = metric_extractor.extract_from_run_intake(run_intake: run_intake)

run_metrics_path = metric_writer.write_run_metrics(run_metrics: metrics.fetch("run_metrics"))
finding_metrics_path = metric_writer.write_finding_metrics(finding_metrics: metrics.fetch("finding_metrics"))

puts JSON.pretty_generate(
  {
    "metrics" => metrics,
    "run_metrics_path" => run_metrics_path.to_s,
    "finding_metrics_path" => finding_metrics_path.to_s
  }
)
