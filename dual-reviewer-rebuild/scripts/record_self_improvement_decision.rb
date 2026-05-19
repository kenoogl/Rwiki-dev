#!/usr/bin/env ruby
# frozen_string_literal: true

# 自己改善エントリ（スクラッチ整合）: design Architecture 段 4
# = decision gate（approval / rejection / adoption）。
#
# 旧 v1 エントリは第1波で git rm 済。本エントリは承認の代行をしない。
# 人間判断（adopt / reject）と連結参照（adopted_change_ref /
# version_update_ref / approval_ref / test_artifact_ref）を引数で受け、
# 共有 PipelineDriver 経由で adoption_register / rejection_register へ
# 連結保存するだけである（Decision 3: approval と adoption は別状態）。
# raw evidence は mutate しない（register 追記のみ）。
#
# usage:
#   ruby scripts/record_self_improvement_decision.rb \
#     --learning-root <dir> --proposal-json <file> --action adopt|reject \
#     [--adopted-change-ref R] [--version-update-ref R] \
#     [--approval-ref R] [--test-artifact-ref R] \
#     [--rejection-reason S] [--reviewer-note S]
require "json"
require "pathname"
require_relative "self_improvement/pipeline_driver"

repo_root = Pathname(File.expand_path("..", __dir__))
opts = {}
argv = ARGV.dup
until argv.empty?
  flag = argv.shift
  case flag
  when "--learning-root" then opts[:learning_root] = argv.shift
  when "--proposal-json" then opts[:proposal_json] = argv.shift
  when "--action" then opts[:action] = argv.shift
  when "--adopted-change-ref" then opts[:adopted_change_ref] = argv.shift
  when "--version-update-ref" then opts[:version_update_ref] = argv.shift
  when "--approval-ref" then opts[:approval_ref] = argv.shift
  when "--test-artifact-ref" then opts[:test_artifact_ref] = argv.shift
  when "--rejection-reason" then opts[:rejection_reason] = argv.shift
  when "--reviewer-note" then opts[:reviewer_note] = argv.shift
  end
end

if opts[:learning_root].nil? || opts[:proposal_json].nil? ||
   opts[:action].nil?
  abort "usage: ruby scripts/record_self_improvement_decision.rb " \
        "--learning-root <dir> --proposal-json <file> " \
        "--action adopt|reject [...refs]"
end

proposal = JSON.parse(
  Pathname(File.expand_path(opts[:proposal_json], Dir.pwd)).read
)
driver = DualReviewer::SelfImprovement::PipelineDriver.new(
  repo_root: repo_root
)
res = driver.stage_decision(
  learning_root: opts[:learning_root],
  proposal: proposal, action: opts[:action],
  adopted_change_ref: opts[:adopted_change_ref],
  version_update_ref: opts[:version_update_ref],
  approval_ref: opts[:approval_ref],
  test_artifact_ref: opts[:test_artifact_ref],
  rejection_reason: opts[:rejection_reason],
  reviewer_note: opts[:reviewer_note]
)
puts JSON.pretty_generate("stage" => "decision", "result" => res)
