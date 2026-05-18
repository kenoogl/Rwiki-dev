#!/usr/bin/env ruby
# frozen_string_literal: true

# 評価所有エントリ（スクラッチ整合）。旧 v1 は ComparisonBuilder#build(
# run_metrics_entries:, classification_entries:) / CaveatBuilder#build(
# classification_entries:, treatment_comparisons:, phase_comparisons:) /
# AnalysisManifestWriter.new(repo_root:).write_manifest（引数なし）/
# manifest の runtime_validation_summary_coverage 読取という撤廃前提で
# 書かれていた（適合レビュー 2026-05-19 finding 3/9）。新モジュール公開
# API（ComparisonBuilder#build(run_records:)・CaveatBuilder#build(
# classification_results:, comparison_result:)・ExclusionReportBuilder・
# AnalysisManifestWriter#build_manifest/#write_manifest・AnalysisLayout
# 正本出力先・各 writer の mkpath 保証）へ整合する。raw run evidence は
# 読むだけで一切 mutate しない（design Decision 1）。
#
# CLI 契約は据え置き（cross-feature の refresh_analysis_and_paper_from_
# selection.rb が `--selection-json <file>`（runtime_run_roots を持つ）で
# 呼び stdout JSON を埋め込む）。
require "fileutils"
require "json"
require "pathname"
require "yaml"
require_relative "evaluation/analysis_layout"
require_relative "evaluation/local_run_loader"
require_relative "evaluation/classification_engine"
require_relative "evaluation/metric_extractor"
require_relative "evaluation/comparison_builder"
require_relative "evaluation/exclusion_report_builder"
require_relative "evaluation/caveat_builder"
require_relative "evaluation/classification_writer"
require_relative "evaluation/metric_writer"
require_relative "evaluation/comparison_writer"
require_relative "evaluation/exclusion_report_writer"
require_relative "evaluation/caveat_writer"
require_relative "evaluation/analysis_manifest_writer"

repo_root = Pathname(File.expand_path("..", __dir__))
run_roots = []
selection_json_path = nil

argv = ARGV.dup
until argv.empty?
  flag = argv.shift
  case flag
  when "--selection-json"
    selection_json_path = argv.shift
  else
    run_roots << flag
  end
end

if selection_json_path
  selection_payload = JSON.parse(
    Pathname(File.expand_path(selection_json_path, Dir.pwd)).read
  )
  run_roots.concat(selection_payload.fetch("runtime_run_roots"))
end

if run_roots.empty?
  abort "usage: ruby scripts/rebuild_evaluation_analysis_from_runs.rb " \
        "<run_root> [<run_root> ...] | --selection-json <path>"
end

analysis_root = repo_root.join("experiments/analysis")
# AnalysisLayout 正本 skeleton を冪等生成（finding 9・ENOENT 非再発）。
DualReviewer::Evaluation::AnalysisLayout.create_skeleton(
  analysis_root: analysis_root
)

loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: repo_root)
engine = DualReviewer::Evaluation::ClassificationEngine.new
extractor = DualReviewer::Evaluation::MetricExtractor.new
comparison_builder = DualReviewer::Evaluation::ComparisonBuilder.new
exclusion_builder = DualReviewer::Evaluation::ExclusionReportBuilder.new
caveat_builder = DualReviewer::Evaluation::CaveatBuilder.new
classification_writer =
  DualReviewer::Evaluation::ClassificationWriter.new(repo_root: repo_root)
metric_writer =
  DualReviewer::Evaluation::MetricWriter.new(repo_root: repo_root)
comparison_writer =
  DualReviewer::Evaluation::ComparisonWriter.new(repo_root: repo_root)
exclusion_writer =
  DualReviewer::Evaluation::ExclusionReportWriter.new(
    analysis_root: analysis_root
  )
caveat_writer =
  DualReviewer::Evaluation::CaveatWriter.new(analysis_root: analysis_root)
manifest_writer = DualReviewer::Evaluation::AnalysisManifestWriter.new

records = run_roots.map do |rr|
  intake = loader.load_run(run_root: File.expand_path(rr, repo_root))
  cls = engine.classify_local_run(run_intake: intake)
  metrics = extractor.extract_from_run_intake(run_intake: intake)
  {
    "run_id" => cls["run_id"],
    "classification" => cls,
    "metrics" => metrics,
    "metadata" => intake.fetch("metadata", {}),
    "comparison_eligibility" => intake["comparison_eligibility"]
  }
end.sort_by { |r| r["run_id"].to_s }

# 既存 derived index を素の skeleton 状態に戻してから entry を書き直す
# （冪等再生成。stale な前回 entry を据え置かない）。
%w[
  classifications/run_classification_index.json
  classifications/exclusion_report.json
  metrics/run_metrics.json
  metrics/finding_metrics.json
].each do |rel|
  path = analysis_root + rel
  path.write(JSON.pretty_generate({ "entries" => [] }))
end

records.each do |r|
  classification_writer.write_classification(
    classification_result: r["classification"]
  )
  metric_writer.write_run_metrics(
    run_metrics: r["metrics"]["run_metrics"]
  )
  metric_writer.write_finding_metrics(
    finding_metrics: r["metrics"]["finding_metrics"]
  )
end

comparison_result = comparison_builder.build(
  run_records: records.map do |r|
    {
      "run_id" => r["run_id"],
      "classification" => r["classification"],
      "metrics" => r["metrics"],
      "metadata" => r["metadata"],
      "comparison_eligibility" => r["comparison_eligibility"]
    }
  end
)
exclusion_report = exclusion_builder.build(
  classification_results: records.map { |r| r["classification"] }
)
caveat_register = caveat_builder.build(
  classification_results: records.map { |r| r["classification"] },
  comparison_result: comparison_result
)

comparison_writer.write_treatment_comparisons(
  payload: comparison_result.fetch("treatment_comparisons")
)
comparison_writer.write_phase_comparisons(
  payload: comparison_result.fetch("phase_comparisons")
)
comparison_writer.write_treatment_metrics(
  payload: {
    "entries" =>
      comparison_result.fetch("treatment_comparisons")
                        .fetch("treatment_aggregates")
  }
)
exclusion_writer.write(exclusion_report: exclusion_report)
caveat_writer.write(caveat_register: caveat_register)

manifest = manifest_writer.build_manifest(
  input_run_records: records.map do |r|
    {
      "run_id" => r["run_id"],
      "target_id" => r["metadata"]["target_id"],
      "classification" => r["classification"]
    }
  end
)
manifest_path = manifest_writer.write_manifest(
  manifest: manifest, analysis_root: analysis_root
)

puts JSON.pretty_generate(
  {
    "reconstructed_run_ids" => records.map { |r| r["run_id"] },
    "analysis_manifest_path" => manifest_path.to_s,
    "input_run_set" => manifest["input_run_set"],
    "treatment_comparison_status" =>
      comparison_result.fetch("treatment_comparisons")
                       .fetch("comparison_status"),
    "total_excluded" => exclusion_report.fetch("total_excluded")
  }
)
