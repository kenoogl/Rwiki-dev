#!/usr/bin/env ruby
# frozen_string_literal: true

# 評価所有エントリ（スクラッチ再実装）。
# 旧 v1 は撤廃済み fixture（minimal_runtime_run / minimal_runtime_bundle）と
# 撤廃 API（ComparisonBuilder#build(run_metrics_entries:, classification_
# entries:)・CaveatBuilder#build(classification_entries:, treatment_
# comparisons:, phase_comparisons:)・AnalysisManifestWriter#write_manifest
# 引数なし・manifest.runtime_validation_summary_coverage・bundle_intake.
# ingestion_status・insufficient_variant_count/single_treatment_only コード）
# 前提で書かれており、fixture が runtime 実体出力形を仮装して smoke 緑を
# 作る構造だった（適合レビュー 2026-05-19 finding 1/2/3）。
#
# 本実装は第1波が版固定した実 runtime 出力形 fixture（valid/invalid/
# exploratory/analysis_blocked + standard/missing_provenance bundle）を入力に
# 新モジュール公開 API で end-to-end 主経路を通す決定的スモークへ置き換える。
# 出力は tmpdir。実 experiments/analysis/・experiments/runs/ を一切汚染せず
# raw を一切 mutate しない（design Decision 1）。
require "fileutils"
require "json"
require "pathname"
require "tmpdir"
require "yaml"
require_relative "evaluation/analysis_layout"
require_relative "evaluation/local_run_loader"
require_relative "evaluation/imported_bundle_loader"
require_relative "evaluation/admission_evaluator"
require_relative "evaluation/classification_engine"
require_relative "evaluation/metric_extractor"
require_relative "evaluation/comparison_builder"
require_relative "evaluation/exclusion_report_builder"
require_relative "evaluation/caveat_builder"
require_relative "evaluation/import_register_writer"
require_relative "evaluation/classification_writer"
require_relative "evaluation/metric_writer"
require_relative "evaluation/comparison_writer"
require_relative "evaluation/exclusion_report_writer"
require_relative "evaluation/caveat_writer"
require_relative "evaluation/analysis_manifest_writer"

def assert(condition, message)
  raise message unless condition
end

repo_root = Pathname(File.expand_path("..", __dir__))
local_root = repo_root.join("tests/fixtures/evaluation/local_runs")
bundle_root_dir = repo_root.join("tests/fixtures/evaluation/imported_bundles")

loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: repo_root)
bundle_loader =
  DualReviewer::Evaluation::ImportedBundleLoader.new(repo_root: repo_root)
admission_evaluator = DualReviewer::Evaluation::AdmissionEvaluator.new
engine = DualReviewer::Evaluation::ClassificationEngine.new
extractor = DualReviewer::Evaluation::MetricExtractor.new
comparison_builder = DualReviewer::Evaluation::ComparisonBuilder.new
exclusion_builder = DualReviewer::Evaluation::ExclusionReportBuilder.new
caveat_builder = DualReviewer::Evaluation::CaveatBuilder.new

mixed = %w[valid_runtime_run invalid_runtime_run
           exploratory_runtime_run analysis_blocked_run]
intakes = mixed.to_h do |d|
  [d, loader.load_run(run_root: local_root.join(d))]
end

assert(intakes["valid_runtime_run"].fetch("intake_status") == "complete",
       "valid local run intake should be complete")

bundle_intake = bundle_loader.load_bundle(
  bundle_root: bundle_root_dir.join("standard_runtime_bundle")
)
admission_result =
  admission_evaluator.evaluate(bundle_intake: bundle_intake)
assert(bundle_intake.fetch("intake_status") == "complete",
       "imported bundle intake should be complete")
assert(admission_result.fetch("admission_status") == "admitted_standard",
       "standard imported bundle should be admitted_standard")

rejected_bundle = bundle_loader.load_bundle(
  bundle_root: bundle_root_dir.join("missing_provenance_bundle")
)
rejected_admission =
  admission_evaluator.evaluate(bundle_intake: rejected_bundle)
assert(rejected_admission.fetch("admission_status") == "rejected",
       "missing-provenance bundle should be rejected")

classifications = intakes.transform_values do |intake|
  engine.classify_local_run(run_intake: intake)
end
assert(classifications["valid_runtime_run"]["classification"] == "valid",
       "valid fixture should classify as valid")
assert(classifications["invalid_runtime_run"]["classification"] == "invalid",
       "invalid fixture should classify as invalid")
assert(classifications["exploratory_runtime_run"]["classification"] ==
       "exploratory", "exploratory fixture should classify as exploratory")
assert(classifications["analysis_blocked_run"]["classification"] ==
       "analysis_blocked",
       "blocked fixture should classify as analysis_blocked")

metrics = intakes.transform_values do |intake|
  extractor.extract_from_run_intake(run_intake: intake)
end
vm = metrics["valid_runtime_run"]["run_metrics"]
assert(vm.fetch("total_findings") == 2,
       "run metrics should count structured findings")
assert(vm.fetch("accepted_findings") == 2,
       "run metrics should resolve decision labels from decision units")
assert(metrics["valid_runtime_run"]["finding_metrics"]
       .fetch("judgment_label_distribution")
       .fetch("unresolved_judgment_labels") == 0,
       "finding metrics should not leave labels unresolved")

run_records = mixed.map do |d|
  {
    "run_id" => classifications[d]["run_id"],
    "classification" => classifications[d],
    "metrics" => metrics[d],
    "metadata" => intakes[d].fetch("metadata", {}),
    "comparison_eligibility" => intakes[d]["comparison_eligibility"]
  }
end

comparison_result = comparison_builder.build(run_records: run_records)
assert(comparison_result.fetch("treatment_comparisons")
       .fetch("comparison_status") == "valid",
       "valid-population comparison should be valid")

exclusion_report = exclusion_builder.build(
  classification_results: run_records.map { |r| r["classification"] }
)
assert(exclusion_report.fetch("total_excluded") == 3,
       "invalid/exploratory/blocked should be excluded from population")

caveat_register = caveat_builder.build(
  classification_results: run_records.map { |r| r["classification"] },
  comparison_result: comparison_result
)
assert(caveat_register.fetch("population_collapsed") == false,
       "invalid と valid population を silent に潰さない")

Dir.mktmpdir("dual-reviewer-eval-smoke") do |tmpdir|
  tmp_root = Pathname(tmpdir)
  analysis_root = tmp_root.join("experiments/analysis")
  DualReviewer::Evaluation::AnalysisLayout.create_skeleton(
    analysis_root: analysis_root
  )

  import_writer =
    DualReviewer::Evaluation::ImportRegisterWriter.new(repo_root: tmp_root)
  classification_writer =
    DualReviewer::Evaluation::ClassificationWriter.new(repo_root: tmp_root)
  metric_writer =
    DualReviewer::Evaluation::MetricWriter.new(repo_root: tmp_root)
  comparison_writer =
    DualReviewer::Evaluation::ComparisonWriter.new(repo_root: tmp_root)
  exclusion_writer =
    DualReviewer::Evaluation::ExclusionReportWriter.new(
      analysis_root: analysis_root
    )
  caveat_writer =
    DualReviewer::Evaluation::CaveatWriter.new(analysis_root: analysis_root)
  manifest_writer = DualReviewer::Evaluation::AnalysisManifestWriter.new

  import_writer.write_ingestion_entry(bundle_intake: bundle_intake)
  import_writer.write_admission_entry(admission_result: admission_result)
  run_records.each do |r|
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
    input_run_records: run_records.map do |r|
      {
        "run_id" => r["run_id"],
        "target_id" => r["metadata"]["target_id"],
        "classification" => r["classification"]
      }
    end
  )
  manifest_writer.write_manifest(
    manifest: manifest, analysis_root: analysis_root
  )

  # downstream（design「Interfaces to Downstream Features」）が読む
  # artifact が AnalysisLayout 正本配置に揃うことを確認する。
  %w[
    imports/ingestion_register.json
    imports/admission_register.json
    classifications/run_classification_index.json
    classifications/exclusion_report.json
    metrics/run_metrics.json
    metrics/finding_metrics.json
    metrics/treatment_metrics.json
    comparisons/treatment_comparisons.json
    comparisons/phase_comparisons.json
    caveats/caveat_register.json
    manifests/analysis_run_manifest.yaml
  ].each do |rel|
    assert(analysis_root.join(rel).exist?,
           "downstream artifact not written: #{rel}")
  end

  manifest_payload = YAML.safe_load(
    analysis_root.join("manifests/analysis_run_manifest.yaml").read
  )
  %w[analysis_logic_version input_run_set generated_at
     metric_set_version phase_metric_profile_version
     comparison_contract_version].each do |k|
    assert(!manifest_payload[k].nil?, "manifest missing #{k}")
  end
end

puts "evaluation pipeline validation passed"
