#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "pathname"
require "tmpdir"
require "yaml"
require_relative "evaluation/local_run_loader"
require_relative "evaluation/imported_bundle_loader"
require_relative "evaluation/admission_evaluator"
require_relative "evaluation/classification_engine"
require_relative "evaluation/metric_extractor"
require_relative "evaluation/comparison_builder"
require_relative "evaluation/caveat_builder"
require_relative "evaluation/import_register_writer"
require_relative "evaluation/classification_writer"
require_relative "evaluation/metric_writer"
require_relative "evaluation/comparison_writer"
require_relative "evaluation/caveat_writer"
require_relative "evaluation/analysis_manifest_writer"

def assert(condition, message)
  raise message unless condition
end

repo_root = Pathname(File.expand_path("..", __dir__))

local_loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: repo_root)
bundle_loader = DualReviewer::Evaluation::ImportedBundleLoader.new(repo_root: repo_root)
admission_evaluator = DualReviewer::Evaluation::AdmissionEvaluator.new
classification_engine = DualReviewer::Evaluation::ClassificationEngine.new
metric_extractor = DualReviewer::Evaluation::MetricExtractor.new
comparison_builder = DualReviewer::Evaluation::ComparisonBuilder.new
caveat_builder = DualReviewer::Evaluation::CaveatBuilder.new

valid_run = local_loader.load_run(run_root: repo_root.join("tests/fixtures/evaluation/local_runs/minimal_runtime_run"))
invalid_run = local_loader.load_run(run_root: repo_root.join("tests/fixtures/evaluation/local_runs/invalid_runtime_run"))
blocked_run = local_loader.load_run(run_root: repo_root.join("tests/fixtures/evaluation/local_runs/analysis_blocked_run"))
bundle_intake = bundle_loader.load_bundle(bundle_root: repo_root.join("tests/fixtures/evaluation/imported_bundles/minimal_runtime_bundle"))
admission_result = admission_evaluator.evaluate(bundle_intake: bundle_intake)

assert(valid_run.fetch("intake_status") == "complete", "valid local run intake should be complete")
assert(bundle_intake.fetch("ingestion_status") == "complete", "imported bundle intake should be complete")
assert(admission_result.fetch("admission_status") == "admitted_standard", "imported bundle should be admitted_standard")

valid_classification = classification_engine.classify_local_run(run_intake: valid_run)
invalid_classification = classification_engine.classify_local_run(run_intake: invalid_run)
blocked_classification = classification_engine.classify_local_run(run_intake: blocked_run)
bundle_classification = classification_engine.classify_imported_bundle(
  bundle_intake: bundle_intake,
  admission_result: admission_result
)

assert(valid_classification.fetch("classification") == "valid", "valid fixture should classify as valid")
assert(invalid_classification.fetch("classification") == "invalid", "invalid fixture should classify as invalid")
assert(blocked_classification.fetch("classification") == "analysis_blocked", "blocked fixture should classify as analysis_blocked")
assert(bundle_classification.fetch("classification") == "valid", "admitted imported bundle should classify as valid")

metrics = metric_extractor.extract_from_run_intake(run_intake: valid_run)
assert(metrics.fetch("run_metrics").fetch("total_findings") == 1, "run metrics should count findings")
assert(metrics.fetch("finding_metrics").fetch("severity_distribution").fetch("medium") == 1, "finding metrics should count severity")

comparison_result = comparison_builder.build(
  run_metrics_entries: [metrics.fetch("run_metrics")],
  classification_entries: [valid_classification]
)
assert(comparison_result.fetch("treatment_comparisons").fetch("comparison_status") == "invalid", "single-treatment comparison should be invalid")
assert(comparison_result.fetch("treatment_comparisons").fetch("comparison_invalid_reason").include?("insufficient_variant_count"), "comparison invalidity reason should be recorded")

caveats = caveat_builder.build(
  classification_entries: [valid_classification],
  treatment_comparisons: comparison_result.fetch("treatment_comparisons"),
  phase_comparisons: comparison_result.fetch("phase_comparisons")
)
assert(caveats.any? { |entry| entry.fetch("caveat_code") == "single_treatment_only" }, "single_treatment_only caveat should be emitted")

Dir.mktmpdir("dual-reviewer-eval-smoke") do |tmpdir|
  tmp_root = Pathname(tmpdir)
  FileUtils.mkdir_p(tmp_root.join("experiments/analysis/imports"))
  FileUtils.mkdir_p(tmp_root.join("experiments/analysis/classifications"))
  FileUtils.mkdir_p(tmp_root.join("experiments/analysis/metrics"))
  FileUtils.mkdir_p(tmp_root.join("experiments/analysis/comparisons"))
  FileUtils.mkdir_p(tmp_root.join("experiments/analysis/caveats"))
  FileUtils.mkdir_p(tmp_root.join("experiments/analysis/manifests"))

  import_writer = DualReviewer::Evaluation::ImportRegisterWriter.new(repo_root: tmp_root)
  classification_writer = DualReviewer::Evaluation::ClassificationWriter.new(repo_root: tmp_root)
  metric_writer = DualReviewer::Evaluation::MetricWriter.new(repo_root: tmp_root)
  comparison_writer = DualReviewer::Evaluation::ComparisonWriter.new(repo_root: tmp_root)
  caveat_writer = DualReviewer::Evaluation::CaveatWriter.new(repo_root: tmp_root)
  manifest_writer = DualReviewer::Evaluation::AnalysisManifestWriter.new(repo_root: tmp_root)

  import_writer.write_ingestion_entry(bundle_intake: bundle_intake)
  import_writer.write_admission_entry(admission_result: admission_result)
  classification_writer.write_classification(classification_result: valid_classification)
  classification_writer.write_exclusion_entry(classification_result: valid_classification)
  metric_writer.write_run_metrics(run_metrics: metrics.fetch("run_metrics"))
  metric_writer.write_finding_metrics(finding_metrics: metrics.fetch("finding_metrics"))
  comparison_writer.write_treatment_metrics(payload: { "entries" => comparison_result.fetch("treatment_metrics") })
  comparison_writer.write_treatment_comparisons(payload: comparison_result.fetch("treatment_comparisons"))
  comparison_writer.write_phase_comparisons(payload: comparison_result.fetch("phase_comparisons"))
  caveat_writer.write(caveats: caveats)
  manifest_writer.write_manifest

  assert(tmp_root.join("experiments/analysis/imports/ingestion_register.json").exist?, "ingestion register should be written")
  assert(tmp_root.join("experiments/analysis/classifications/run_classification_index.json").exist?, "classification index should be written")
  assert(tmp_root.join("experiments/analysis/metrics/run_metrics.json").exist?, "run metrics should be written")
  assert(tmp_root.join("experiments/analysis/comparisons/treatment_comparisons.json").exist?, "treatment comparisons should be written")
  assert(tmp_root.join("experiments/analysis/caveats/caveat_register.json").exist?, "caveat register should be written")
  assert(tmp_root.join("experiments/analysis/manifests/analysis_run_manifest.yaml").exist?, "analysis manifest should be written")
end

puts "evaluation pipeline validation passed"
