#!/usr/bin/env ruby
# frozen_string_literal: true

# 評価所有エントリ（スクラッチ整合）。旧 v1 は derived run_metrics.json /
# run_classification_index.json を逆読みし ComparisonBuilder#build(
# run_metrics_entries:, classification_entries:) を呼んでいた。新
# ComparisonBuilder#build(run_records:) は classification + metric +
# metadata + comparison_eligibility を束ねた run_records を受け、比較前に
# 比較可能性条件（version 混在・eligibility note 不可理由・review-mode）を
# 機械確認する（適合レビュー 2026-05-19 finding 6/10）。lossy な derived
# 逆読みでなく run root を一次入力にし derivation 正本性を保つ。
require "json"
require "pathname"
require_relative "evaluation/local_run_loader"
require_relative "evaluation/classification_engine"
require_relative "evaluation/metric_extractor"
require_relative "evaluation/comparison_builder"
require_relative "evaluation/comparison_writer"

repo_root = Pathname(File.expand_path("..", __dir__))
run_roots = ARGV.dup
if run_roots.empty?
  abort "usage: ruby scripts/build_evaluation_comparisons.rb <run_root> " \
        "[<run_root> ...]"
end

loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: repo_root)
engine = DualReviewer::Evaluation::ClassificationEngine.new
extractor = DualReviewer::Evaluation::MetricExtractor.new
builder = DualReviewer::Evaluation::ComparisonBuilder.new
writer = DualReviewer::Evaluation::ComparisonWriter.new(repo_root: repo_root)

run_records = run_roots.map do |rr|
  intake = loader.load_run(run_root: File.expand_path(rr, repo_root))
  {
    "run_id" => intake.fetch("metadata", {})["run_id"],
    "classification" => engine.classify_local_run(run_intake: intake),
    "metrics" => extractor.extract_from_run_intake(run_intake: intake),
    "metadata" => intake.fetch("metadata", {}),
    "comparison_eligibility" => intake["comparison_eligibility"]
  }
end

result = builder.build(run_records: run_records)

treatment_metrics_path = writer.write_treatment_metrics(
  payload: {
    "entries" =>
      result.fetch("treatment_comparisons").fetch("treatment_aggregates")
  }
)
treatment_comparisons_path = writer.write_treatment_comparisons(
  payload: result.fetch("treatment_comparisons")
)
phase_comparisons_path = writer.write_phase_comparisons(
  payload: result.fetch("phase_comparisons")
)

puts JSON.pretty_generate(
  {
    "result" => result,
    "treatment_metrics_path" => treatment_metrics_path.to_s,
    "treatment_comparisons_path" => treatment_comparisons_path.to_s,
    "phase_comparisons_path" => phase_comparisons_path.to_s
  }
)
