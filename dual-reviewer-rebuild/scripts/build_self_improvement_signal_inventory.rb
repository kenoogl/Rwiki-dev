#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require_relative "self_improvement/signal_intake"
require_relative "self_improvement/signal_inventory_writer"

repo_root = Pathname(__dir__).join("..").expand_path
signal_intake = DualReviewer::SelfImprovement::SignalIntake.new(repo_root: repo_root)
inventory_writer = DualReviewer::SelfImprovement::SignalInventoryWriter.new(repo_root: repo_root)

runtime_run_roots = ARGV.empty? ? Dir[repo_root.join("tests/fixtures/evaluation/local_runs/*")].sort : ARGV

all_signals = runtime_run_roots.flat_map do |run_root|
  signal_intake.load_runtime_signals(run_root: run_root).fetch("signals")
end
all_signals.concat(
  signal_intake.load_evaluation_signals(analysis_root: repo_root.join("experiments/analysis")).fetch("signals")
)

recurring_path = inventory_writer.write_recurring_failure_inventory(signals: all_signals)
workflow_path = inventory_writer.write_workflow_failure_inventory(signals: all_signals)

puts "wrote #{recurring_path}"
puts "wrote #{workflow_path}"
