#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require_relative "evaluation/local_run_loader"
require_relative "evaluation/imported_bundle_loader"
require_relative "evaluation/admission_evaluator"
require_relative "evaluation/classification_engine"
require_relative "evaluation/classification_writer"

repo_root = File.expand_path("..", __dir__)
mode = ARGV.fetch(0) do
  abort "usage: ruby scripts/classify_evaluation_input.rb <local_run|imported_bundle> <path>"
end
input_path = ARGV.fetch(1) do
  abort "usage: ruby scripts/classify_evaluation_input.rb <local_run|imported_bundle> <path>"
end

classification_engine = DualReviewer::Evaluation::ClassificationEngine.new
classification_writer = DualReviewer::Evaluation::ClassificationWriter.new(repo_root: repo_root)

classification_result =
  case mode
  when "local_run"
    loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: repo_root)
    run_intake = loader.load_run(run_root: File.expand_path(input_path, repo_root))
    classification_engine.classify_local_run(run_intake: run_intake)
  when "imported_bundle"
    bundle_loader = DualReviewer::Evaluation::ImportedBundleLoader.new(repo_root: repo_root)
    admission_evaluator = DualReviewer::Evaluation::AdmissionEvaluator.new
    bundle_intake = bundle_loader.load_bundle(bundle_root: File.expand_path(input_path, repo_root))
    admission_result = admission_evaluator.evaluate(bundle_intake: bundle_intake)
    classification_engine.classify_imported_bundle(
      bundle_intake: bundle_intake,
      admission_result: admission_result
    )
  else
    abort "unknown mode: #{mode}"
  end

classification_path = classification_writer.write_classification(classification_result: classification_result)
exclusion_path = classification_writer.write_exclusion_entry(classification_result: classification_result)

puts JSON.pretty_generate(
  {
    "classification_result" => classification_result,
    "classification_path" => classification_path.to_s,
    "exclusion_path" => exclusion_path.to_s
  }
)
