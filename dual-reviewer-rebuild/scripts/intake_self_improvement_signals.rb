#!/usr/bin/env ruby
# frozen_string_literal: true

# 自己改善エントリ（スクラッチ整合）: design Architecture 段 1
# = signal intake → signal extraction。
#
# 旧 v1 エントリ 10 件は第1波で git rm 済（評価外参照ゼロを grep -rl で
# 確認済）。本エントリは新モジュール公開 API（共有 PipelineDriver）のみで
# runtime/evaluation fixture or 実出力から findings/ ・templates/ を
# learning/ 正本配置へ冪等生成する。raw evidence / analysis は mutate
# しない。
#
# usage:
#   ruby scripts/intake_self_improvement_signals.rb \
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
  abort "usage: ruby scripts/intake_self_improvement_signals.rb " \
        "--learning-root <dir> --analysis-root <dir> <run_root>..."
end

driver = DualReviewer::SelfImprovement::PipelineDriver.new(
  repo_root: repo_root
)
res = driver.stage_signal_intake(
  learning_root: learning_root,
  run_roots: run_roots, analysis_root: analysis_root
)
puts JSON.pretty_generate(
  "stage" => "signal_intake",
  "signal_count" => res[:signals].size,
  "signal_classes" => res[:signals].map { |s| s["signal_class"] }.uniq,
  "inventory_entries" => res[:inventory_entries].size,
  "pattern_candidates" => res[:pattern_candidates].size,
  "templates" => res[:templates].size
)
