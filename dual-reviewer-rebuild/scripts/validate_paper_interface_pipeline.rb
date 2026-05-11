#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "pathname"
require "tmpdir"
require "yaml"
require_relative "paper_interface/evaluation_intake_loader"
require_relative "paper_interface/claim_map_builder"
require_relative "paper_interface/claim_map_writer"
require_relative "paper_interface/evidence_register_builder"
require_relative "paper_interface/evidence_register_writer"
require_relative "paper_interface/table_source_bundle_builder"
require_relative "paper_interface/table_source_bundle_writer"
require_relative "paper_interface/figure_source_bundle_builder"
require_relative "paper_interface/figure_source_bundle_writer"
require_relative "paper_interface/paper_caveat_register_builder"
require_relative "paper_interface/paper_caveat_register_writer"
require_relative "paper_interface/reporting_fragments_builder"
require_relative "paper_interface/reporting_fragments_writer"
require_relative "paper_interface/methodology_note_linkage_builder"
require_relative "paper_interface/methodology_note_linkage_writer"

def assert(condition, message)
  raise message unless condition
end

source_repo = Pathname(__dir__).join("..").expand_path

Dir.mktmpdir do |dir|
  repo_root = Pathname(dir).join("repo")
  %w[experiments learning paper].each do |subdir|
    FileUtils.mkdir_p(repo_root)
    FileUtils.cp_r(source_repo.join(subdir), repo_root)
  end

  analysis_root = repo_root.join("experiments/analysis")

  intake = DualReviewer::PaperInterface::EvaluationIntakeLoader.new(repo_root: repo_root).load_analysis(analysis_root: analysis_root)
  assert(intake["intake_status"] == "complete", "paper intake incomplete")
  assert(intake.fetch("artifacts").fetch("runtime_validation_summaries").key?("entries"), "runtime validation summary intake missing entries")

  claim_payload = DualReviewer::PaperInterface::ClaimMapBuilder.new(repo_root: repo_root).build_claim_map(analysis_root: analysis_root)
  DualReviewer::PaperInterface::ClaimMapWriter.new(repo_root: repo_root).write_claim_map(payload: claim_payload)
  assert(claim_payload["entries"].all? { |entry| entry["supporting_artifact_refs"].any? }, "claim traceability missing")
  assert(claim_payload["entries"].all? { |entry| entry["provenance_refs"].include?("experiments/analysis/manifests/analysis_run_manifest.yaml") }, "claim provenance missing analysis manifest")

  evidence_payload = DualReviewer::PaperInterface::EvidenceRegisterBuilder.new(repo_root: repo_root).build_evidence_register
  DualReviewer::PaperInterface::EvidenceRegisterWriter.new(repo_root: repo_root).write_evidence_register(payload: evidence_payload)
  assert(evidence_payload["entries"].all? { |entry| entry["source_analysis_manifest_ref"] == "experiments/analysis/manifests/analysis_run_manifest.yaml" }, "evidence provenance missing manifest ref")
  assert(evidence_payload["entries"].all? { |entry| entry.key?("runtime_validation_summary_refs") }, "evidence provenance missing validation summary refs")
  assert(evidence_payload["entries"].any? { |entry| entry["maturity_label"] == "preliminary" }, "preliminary evidence missing")

  table_payload = DualReviewer::PaperInterface::TableSourceBundleBuilder.new(repo_root: repo_root).build_table_source_bundle
  DualReviewer::PaperInterface::TableSourceBundleWriter.new(repo_root: repo_root).write_table_source_bundle(payload: table_payload)
  assert(table_payload["entries"].first["field_projection"].any? { |entry| entry["artifact_ref"].include?("phase_comparisons") }, "table field projection missing phase comparisons")

  figure_payload = DualReviewer::PaperInterface::FigureSourceBundleBuilder.new(repo_root: repo_root).build_figure_source_bundle
  DualReviewer::PaperInterface::FigureSourceBundleWriter.new(repo_root: repo_root).write_figure_source_bundle(payload: figure_payload)
  assert(figure_payload["entries"].first["plot_contract"]["metric_fields"].include?("acceptance_ratio"), "figure metric selection missing acceptance_ratio")

  caveat_payload = DualReviewer::PaperInterface::PaperCaveatRegisterBuilder.new(repo_root: repo_root).build_paper_caveat_register
  DualReviewer::PaperInterface::PaperCaveatRegisterWriter.new(repo_root: repo_root).write_paper_caveat_register(payload: caveat_payload)
  if caveat_payload["entries"].any?
    assert(caveat_payload["entries"].any? { |entry| entry["applies_to_claim_refs"].any? }, "caveat retention missing claim refs")
  end

  fragment_payload = DualReviewer::PaperInterface::ReportingFragmentsBuilder.new(repo_root: repo_root).build_reporting_fragments
  DualReviewer::PaperInterface::ReportingFragmentsWriter.new(repo_root: repo_root).write_reporting_fragments(payload: fragment_payload)
  if caveat_payload["entries"].any?
    assert(fragment_payload["entries"].any? { |entry| entry["fragment_type"] == "limitation_note" }, "limitation fragment missing")
  end
  assert(fragment_payload["entries"].any? { |entry| entry["fragment_id"] == "fragment-method-analysis-provenance" && entry["source_artifact_refs"].include?("experiments/analysis/manifests/analysis_run_manifest.yaml") }, "method fragment missing analysis provenance")

  methodology_payload = DualReviewer::PaperInterface::MethodologyNoteLinkageBuilder.new(repo_root: repo_root).build_methodology_note_linkage
  DualReviewer::PaperInterface::MethodologyNoteLinkageWriter.new(repo_root: repo_root).write_methodology_note_linkage(payload: methodology_payload)
  assert(methodology_payload["entries"].all? { |entry| entry["claim_support_allowed"] == false }, "methodology linkage can support claims")

  # No silent strengthening: caveated claim must not become mature.
  treatment_claim = claim_payload["entries"].find { |entry| entry["claim_id"] == "claim-treatment-comparison-status" }
  if treatment_claim["caveat_refs"].any?
    assert(treatment_claim["maturity_label"] != "mature", "caveated treatment claim was silently strengthened")
  end

  puts "paper-interface pipeline validation passed"
end
