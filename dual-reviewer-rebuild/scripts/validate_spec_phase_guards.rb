#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require_relative "track_runs/spec_phase_guard"

def assert(condition, message)
  raise message unless condition
end

repo_root = Pathname(__dir__).join("..").expand_path
guard = DualReviewer::TrackRuns::SpecPhaseGuard.new(repo_root: repo_root)

valid_spec = repo_root.join("tests/fixtures/spec_phase_guard/strict_tasks_ready/spec.json")
valid_ref = repo_root.join("tests/fixtures/spec_phase_guard/strict_tasks_ready/tasks.md")
invalid_spec = repo_root.join("tests/fixtures/spec_phase_guard/strict_invalid_downstream/spec.json")
invalid_ref = repo_root.join("tests/fixtures/spec_phase_guard/strict_invalid_downstream/tasks.md")

guard.validate_spec!(spec_json_path: valid_spec)
guard.assert_phase_entry_allowed!(phase: "implementation", refs: [valid_ref.to_s])

begin
  guard.validate_spec!(spec_json_path: invalid_spec)
  raise "invalid strict fixture should fail validation"
rescue DualReviewer::TrackRuns::SpecPhaseGuard::GuardError => e
  assert(e.message.include?("tasks.generated requires design.approved=true"), "invalid strict fixture should fail on downstream generation guard")
end

begin
  guard.assert_phase_entry_allowed!(phase: "implementation", refs: [invalid_ref.to_s])
  raise "invalid strict fixture should block implementation entry"
rescue DualReviewer::TrackRuns::SpecPhaseGuard::GuardError => e
  assert(e.message.include?("violates spec phase guard"), "implementation entry failure should surface guard violation")
end

strict_specs = guard.strict_opt_in_spec_paths
strict_specs.each do |spec_path|
  guard.validate_spec!(spec_json_path: spec_path)
end

puts "spec phase guard validation passed"
