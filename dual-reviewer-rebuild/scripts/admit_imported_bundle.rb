#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require_relative "evaluation/imported_bundle_loader"
require_relative "evaluation/admission_evaluator"
require_relative "evaluation/import_register_writer"

repo_root = File.expand_path("..", __dir__)
bundle_root = ARGV.fetch(0) do
  abort "usage: ruby scripts/admit_imported_bundle.rb <bundle_root>"
end

bundle_loader = DualReviewer::Evaluation::ImportedBundleLoader.new(repo_root: repo_root)
admission_evaluator = DualReviewer::Evaluation::AdmissionEvaluator.new
register_writer = DualReviewer::Evaluation::ImportRegisterWriter.new(repo_root: repo_root)

bundle_intake = bundle_loader.load_bundle(bundle_root: File.expand_path(bundle_root, repo_root))
admission_result = admission_evaluator.evaluate(bundle_intake: bundle_intake)

ingestion_register_path = register_writer.write_ingestion_entry(bundle_intake: bundle_intake)
admission_register_path = register_writer.write_admission_entry(admission_result: admission_result)

puts JSON.pretty_generate(
  {
    "bundle_intake" => bundle_intake,
    "admission_result" => admission_result,
    "ingestion_register_path" => ingestion_register_path.to_s,
    "admission_register_path" => admission_register_path.to_s
  }
)
