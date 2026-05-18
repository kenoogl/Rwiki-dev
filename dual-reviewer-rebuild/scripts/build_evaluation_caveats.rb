#!/usr/bin/env ruby
# frozen_string_literal: true

# 評価所有エントリ（スクラッチ整合）。旧 v1 は CaveatBuilder#build(
# classification_entries:, treatment_comparisons:, phase_comparisons:) を
# 呼び CaveatWriter.new(repo_root:).write(caveats:) で {"entries"=>...} 形を
# 書いていた。新 CaveatBuilder#build(classification_results:,
# comparison_result:) は ComparisonBuilder#build の戻り全体を受け、
# CaveatWriter.new(analysis_root:).write(caveat_register:) が register 全体を
# first-class artifact として保存する（paper-interface が raw 再読せず継承・
# Requirement 4 受入 2）。run root を一次入力にし derivation 正本性を保つ。
require "json"
require "pathname"
require_relative "evaluation/local_run_loader"
require_relative "evaluation/classification_engine"
require_relative "evaluation/metric_extractor"
require_relative "evaluation/comparison_builder"
require_relative "evaluation/caveat_builder"
require_relative "evaluation/caveat_writer"

repo_root = Pathname(File.expand_path("..", __dir__))
run_roots = ARGV.dup
if run_roots.empty?
  abort "usage: ruby scripts/build_evaluation_caveats.rb <run_root> " \
        "[<run_root> ...]"
end

loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: repo_root)
engine = DualReviewer::Evaluation::ClassificationEngine.new
extractor = DualReviewer::Evaluation::MetricExtractor.new
comparison_builder = DualReviewer::Evaluation::ComparisonBuilder.new
caveat_builder = DualReviewer::Evaluation::CaveatBuilder.new
caveat_writer = DualReviewer::Evaluation::CaveatWriter.new(
  analysis_root: repo_root.join("experiments/analysis")
)

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

comparison_result = comparison_builder.build(run_records: run_records)
caveat_register = caveat_builder.build(
  classification_results: run_records.map { |r| r["classification"] },
  comparison_result: comparison_result
)
path = caveat_writer.write(caveat_register: caveat_register)

puts JSON.pretty_generate(
  {
    "caveat_register" => caveat_register,
    "caveat_register_path" => path.to_s
  }
)
