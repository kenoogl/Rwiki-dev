#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "pathname"
require "yaml"
require_relative "evaluation/local_run_loader"
require_relative "evaluation/classification_engine"
require_relative "evaluation/metric_extractor"
require_relative "evaluation/comparison_builder"
require_relative "evaluation/caveat_builder"
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
  selection_payload = JSON.parse(Pathname(File.expand_path(selection_json_path, Dir.pwd)).read)
  run_roots.concat(selection_payload.fetch("runtime_run_roots"))
end

abort "usage: ruby scripts/rebuild_evaluation_analysis_from_runs.rb <run_root> [<run_root> ...]" if run_roots.empty?

analysis_root = repo_root.join("experiments/analysis")
imports_root = analysis_root.join("imports")
classifications_root = analysis_root.join("classifications")
metrics_root = analysis_root.join("metrics")
comparisons_root = analysis_root.join("comparisons")
caveats_root = analysis_root.join("caveats")
manifests_root = analysis_root.join("manifests")

[imports_root, classifications_root, metrics_root, comparisons_root, caveats_root, manifests_root].each do |path|
  FileUtils.mkdir_p(path)
end

local_loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: repo_root)
classification_engine = DualReviewer::Evaluation::ClassificationEngine.new
metric_extractor = DualReviewer::Evaluation::MetricExtractor.new
comparison_builder = DualReviewer::Evaluation::ComparisonBuilder.new
caveat_builder = DualReviewer::Evaluation::CaveatBuilder.new
manifest_writer = DualReviewer::Evaluation::AnalysisManifestWriter.new(repo_root: repo_root)

run_intakes = run_roots.map do |run_root|
  expanded = Pathname(File.expand_path(run_root, repo_root))
  local_loader.load_run(run_root: expanded)
end

classification_entries = run_intakes.map do |run_intake|
  classification_engine.classify_local_run(run_intake: run_intake)
end.sort_by { |entry| entry.fetch("run_id") }

exclusion_entries = classification_entries.map do |entry|
  {
    "run_id" => entry.fetch("run_id"),
    "classification" => entry.fetch("classification"),
    "reason_codes" => entry.fetch("reason_codes"),
    "reason_details" => entry.fetch("reason_details"),
    "phase_profile" => entry.fetch("phase_profile"),
    "treatment" => entry.fetch("treatment")
  }
end

metric_payloads = run_intakes.map do |run_intake|
  metric_extractor.extract_from_run_intake(run_intake: run_intake)
end

run_metrics_entries = metric_payloads.map { |payload| payload.fetch("run_metrics") }.sort_by { |entry| entry.fetch("run_id") }
finding_metrics_entries = metric_payloads.map { |payload| payload.fetch("finding_metrics") }.sort_by { |entry| entry.fetch("run_id") }

comparison_payload = comparison_builder.build(
  run_metrics_entries: run_metrics_entries,
  classification_entries: classification_entries
)

caveat_entries = caveat_builder.build(
  classification_entries: classification_entries,
  treatment_comparisons: comparison_payload.fetch("treatment_comparisons"),
  phase_comparisons: comparison_payload.fetch("phase_comparisons")
)

imports_root.join("ingestion_register.json").write(JSON.pretty_generate({ "entries" => [] }))
imports_root.join("admission_register.json").write(JSON.pretty_generate({ "entries" => [] }))
classifications_root.join("run_classification_index.json").write(JSON.pretty_generate({ "entries" => classification_entries }))
classifications_root.join("exclusion_report.json").write(JSON.pretty_generate({ "entries" => exclusion_entries }))
metrics_root.join("run_metrics.json").write(JSON.pretty_generate({ "entries" => run_metrics_entries }))
metrics_root.join("finding_metrics.json").write(JSON.pretty_generate({ "entries" => finding_metrics_entries }))
metrics_root.join("treatment_metrics.json").write(JSON.pretty_generate({ "entries" => comparison_payload.fetch("treatment_metrics") }))
comparisons_root.join("treatment_comparisons.json").write(JSON.pretty_generate(comparison_payload.fetch("treatment_comparisons")))
comparisons_root.join("phase_comparisons.json").write(JSON.pretty_generate(comparison_payload.fetch("phase_comparisons")))
caveats_root.join("caveat_register.json").write(JSON.pretty_generate({ "entries" => caveat_entries }))
manifest_path = manifest_writer.write_manifest
manifest_payload = YAML.load_file(manifest_path)

puts JSON.pretty_generate(
  {
    "reconstructed_run_ids" => classification_entries.map { |entry| entry.fetch("run_id") },
    "analysis_manifest_path" => manifest_path.to_s,
    "treatment_comparison_status" => comparison_payload.fetch("treatment_comparisons").fetch("comparison_status"),
    "runtime_validation_summary_coverage" => manifest_payload.fetch("runtime_validation_summary_coverage")
  }
)
