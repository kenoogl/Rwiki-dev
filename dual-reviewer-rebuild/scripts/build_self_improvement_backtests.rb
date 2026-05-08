#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require_relative "self_improvement/backtest_builder"
require_relative "self_improvement/backtest_writer"

repo_root = Pathname(__dir__).join("..").expand_path
builder = DualReviewer::SelfImprovement::BacktestBuilder.new(repo_root: repo_root)
writer = DualReviewer::SelfImprovement::BacktestWriter.new(repo_root: repo_root)

backtests = builder.build_backtests
writer.write_backtests(backtests: backtests)

puts "wrote #{repo_root.join('learning/backtests/backtest_index.json')}"
puts "backtest_count=#{backtests.length}"
