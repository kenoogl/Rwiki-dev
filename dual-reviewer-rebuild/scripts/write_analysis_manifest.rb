#!/usr/bin/env ruby
# frozen_string_literal: true

# 評価所有エントリ（スクラッチ整合）。旧 v1 は writer.write_manifest を
# 引数なしで呼び derived JSON を逆読みして input_run_set を再構築していた
# （適合レビュー 2026-05-19 finding 9・derivation 正本性違反）。新
# AnalysisManifestWriter#build_manifest(input_run_records:) →
# #write_manifest(manifest:, analysis_root:) の公開 API へ整合する。
# 入力 run は local run root を引数で受け、derived 逆読みに依存しない。
require "json"
require "pathname"
require_relative "evaluation/local_run_loader"
require_relative "evaluation/classification_engine"
require_relative "evaluation/analysis_manifest_writer"

repo_root = Pathname(File.expand_path("..", __dir__))
run_roots = ARGV.dup
if run_roots.empty?
  abort "usage: ruby scripts/write_analysis_manifest.rb <run_root> " \
        "[<run_root> ...]"
end

loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: repo_root)
engine = DualReviewer::Evaluation::ClassificationEngine.new
writer = DualReviewer::Evaluation::AnalysisManifestWriter.new

records = run_roots.map do |rr|
  intake = loader.load_run(run_root: File.expand_path(rr, repo_root))
  cls = engine.classify_local_run(run_intake: intake)
  {
    "run_id" => cls["run_id"],
    "target_id" => intake.fetch("metadata", {})["target_id"],
    "classification" => cls
  }
end

manifest = writer.build_manifest(input_run_records: records)
path = writer.write_manifest(
  manifest: manifest,
  analysis_root: repo_root.join("experiments/analysis")
)

puts JSON.pretty_generate(
  {
    "analysis_run_manifest_path" => path.to_s,
    "input_run_set" => manifest["input_run_set"],
    "analysis_logic_version" => manifest["analysis_logic_version"]
  }
)
