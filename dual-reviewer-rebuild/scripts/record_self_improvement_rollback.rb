#!/usr/bin/env ruby
# frozen_string_literal: true

# 自己改善エントリ（スクラッチ整合）: design Architecture 段 5
# = history registry の rollback / 事後 invalidate 起点 reassess。
#
# 旧 v1 エントリは第1波で git rm 済。本エントリは adoption_register の
# motivating_run_refs（段 4 で連結保存）と runtime 正本配置
# validation/invalidation_markers.json を突合し、成り立たない根拠の上に
# 採用済み change を steady state で残さない（Req5 受入 6）。raw evidence
# は mutate しない（register 追記のみ）。
#
# usage:
#   ruby scripts/record_self_improvement_rollback.rb \
#     --learning-root <dir> --proposals-json <file>
require "json"
require "pathname"
require_relative "self_improvement/pipeline_driver"

repo_root = Pathname(File.expand_path("..", __dir__))
learning_root = nil
proposals_json = nil

argv = ARGV.dup
until argv.empty?
  flag = argv.shift
  case flag
  when "--learning-root" then learning_root = argv.shift
  when "--proposals-json" then proposals_json = argv.shift
  end
end

if learning_root.nil? || proposals_json.nil?
  abort "usage: ruby scripts/record_self_improvement_rollback.rb " \
        "--learning-root <dir> --proposals-json <file>"
end

proposals = JSON.parse(
  Pathname(File.expand_path(proposals_json, Dir.pwd)).read
)
proposals = proposals["proposals"] if proposals.is_a?(Hash)

driver = DualReviewer::SelfImprovement::PipelineDriver.new(
  repo_root: repo_root
)
res = driver.stage_rollback_reassess(
  learning_root: learning_root, proposals: Array(proposals)
)
puts JSON.pretty_generate(
  "stage" => "rollback_reassess",
  "reassessed_count" => res.size,
  "results" => res
)
