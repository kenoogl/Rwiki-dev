#!/usr/bin/env ruby
# frozen_string_literal: true

# 自己改善エントリ（スクラッチ整合）: design Architecture 5 段の
# end-to-end pipeline 検証（決定的スモーク）。
#
# 旧 v1 validate_self_improvement_pipeline.rb（適合レビュー 2026-05-19
# finding 1: review_quality_signal を旧 fixture corpus 前提で必須化し
# 現行確定 evaluation/runtime fixture で構造的 FAIL）は第1波で git rm
# 済。本エントリは新モジュール公開 API（共有 PipelineDriver）のみで、
# 既定では第1〜2波が版固定した「実 runtime → 実 evaluation」出力
# fixture（tests/fixtures/self_improvement/）を入力に主経路を通す
# （fixture 仮装でなく実出力固定。finding 1/2/3 の再発防止）。
# 出力は --learning-root（既定 tmpdir）に限定し実 learning/・実
# experiments/ を汚さない。raw evidence / analysis は mutate しない。
#
# usage:
#   ruby scripts/validate_self_improvement_pipeline.rb \
#     [--learning-root <dir>] [--analysis-root <dir>] [<run_root>...]
require "json"
require "tmpdir"
require "pathname"
require_relative "self_improvement/pipeline_driver"

repo_root = Pathname(File.expand_path("..", __dir__))
fixture_root = repo_root + "tests/fixtures/self_improvement"
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

# 既定入力 = 版固定 fixture（実 runtime→実 evaluation 出力）。
if run_roots.empty?
  run_roots = %w[valid_dissent_run invalid_workflow_failure_run
                 exploratory_run valid_clean_run].map do |v|
    (fixture_root + "runtime_runs" + v).to_s
  end
end
analysis_root ||= (fixture_root + "analysis").to_s

run_validation = lambda do |lr|
  driver = DualReviewer::SelfImprovement::PipelineDriver.new(
    repo_root: repo_root
  )
  driver.validate_pipeline(
    learning_root: lr, run_roots: run_roots, analysis_root: analysis_root
  )
end

result =
  if learning_root
    run_validation.call(learning_root)
  else
    # 実 learning/ を汚さないため tmpdir で検証する。
    Dir.mktmpdir do |tmp|
      run_validation.call(Pathname(tmp) + "learning")
    end
  end

puts JSON.pretty_generate("stage" => "validate_pipeline",
                          "result" => result)
exit(result["ok"] ? 0 : 1)
