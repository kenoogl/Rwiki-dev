#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require_relative "self_improvement/signal_intake"

repo_root = Pathname(__dir__).join("..").expand_path
signal_intake = DualReviewer::SelfImprovement::SignalIntake.new(repo_root: repo_root)

mode = ARGV.shift
target_path = ARGV.shift

unless %w[runtime evaluation].include?(mode) && target_path
  warn "usage: ruby scripts/intake_self_improvement_signals.rb <runtime|evaluation> <path>"
  exit 1
end

result =
  case mode
  when "runtime"
    signal_intake.load_runtime_signals(run_root: target_path)
  when "evaluation"
    signal_intake.load_evaluation_signals(analysis_root: target_path)
  end

puts JSON.pretty_generate(result)
