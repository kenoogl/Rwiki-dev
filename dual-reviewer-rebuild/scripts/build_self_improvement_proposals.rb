#!/usr/bin/env ruby
# frozen_string_literal: true

# 自己改善エントリ（スクラッチ整合）: design Architecture 段 2
# = proposal builder（1 改善仮説 = 1 artifact、provenance gate / paper
# narrative 分離を内包）。
#
# 旧 v1 エントリは第1波で git rm 済。本エントリは共有 PipelineDriver
# 経由で ProposalModel#build_proposals を駆動し proposals/ 正本配置へ
# 冪等生成する。スキーマ・語彙は再定義せず raw を mutate しない。
#
# usage:
#   ruby scripts/build_self_improvement_proposals.rb \
#     --learning-root <dir> --analysis-root <dir> <run_root> [<run_root>...]
require "json"
require "pathname"
require_relative "self_improvement/pipeline_driver"

repo_root = Pathname(File.expand_path("..", __dir__))
learning_root = nil
analysis_root = nil
run_roots = []

argv = ARGV.dup
until argv.empty?
  flag = argv.shift
  case flag
  when "--learning-root" then learning_root = argv.shift
  when "--analysis-root" then analysis_root = argv.shift
  else run_roots << flag
  end
end

if learning_root.nil? || run_roots.empty?
  abort "usage: ruby scripts/build_self_improvement_proposals.rb " \
        "--learning-root <dir> --analysis-root <dir> <run_root>..."
end

driver = DualReviewer::SelfImprovement::PipelineDriver.new(
  repo_root: repo_root
)
res = driver.stage_proposals(
  learning_root: learning_root,
  run_roots: run_roots, analysis_root: analysis_root
)
puts JSON.pretty_generate(
  "stage" => "proposals",
  "proposal_count" => res[:proposals].size,
  "proposals" => res[:proposals].map do |p|
    { "proposal_id" => p["proposal_id"], "status" => p["status"],
      "target_layer" => p["target_layer"],
      "motivation_class" => p["motivation_class"] }
  end
)
