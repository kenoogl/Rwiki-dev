#!/usr/bin/env ruby
# frozen_string_literal: true

# 自己改善エントリ（スクラッチ整合）: design Architecture 段 3
# = replay / backtest gate（proposal ごとに 3 要素で test mode 判定し
# 結果 artifact を raw evidence と別 artifact として残す）。
#
# 旧 v1 エントリは第1波で git rm 済。本エントリは段 2 で生成した
# proposals/ を読み、共有 PipelineDriver 経由で test gate を回す。
# raw run evidence / analysis は mutate しない。
#
# usage:
#   ruby scripts/build_self_improvement_backtests.rb \
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
  abort "usage: ruby scripts/build_self_improvement_backtests.rb " \
        "--learning-root <dir> --analysis-root <dir> <run_root>..."
end

driver = DualReviewer::SelfImprovement::PipelineDriver.new(
  repo_root: repo_root
)
pres = driver.stage_proposals(
  learning_root: learning_root,
  run_roots: run_roots, analysis_root: analysis_root
)
results = driver.stage_test_gate(
  learning_root: learning_root, proposals: pres[:proposals],
  run_roots: run_roots, analysis_root: analysis_root
)
puts JSON.pretty_generate(
  "stage" => "test_gate",
  "result_count" => results.size,
  "results" => results.map do |r|
    { "proposal_id" => r["proposal_id"], "test_mode" => r["test_mode"],
      "result_label" => r["result_label"] }
  end
)
