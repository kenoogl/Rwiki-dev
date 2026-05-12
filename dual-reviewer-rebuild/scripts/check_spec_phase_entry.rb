#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "pathname"
require_relative "track_runs/spec_phase_guard"

repo_root = Pathname(__dir__).join("..").expand_path
guard = DualReviewer::TrackRuns::SpecPhaseGuard.new(repo_root: repo_root)

options = {
  "phase" => nil,
  "refs" => []
}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby scripts/check_spec_phase_entry.rb --phase <design|tasks|implementation> --ref PATH [--ref PATH ...]"
  opts.on("--phase PHASE", "Target phase entry to check") { |value| options["phase"] = value }
  opts.on("--ref PATH", "Spec or phase artifact ref path (repeatable)") { |value| options["refs"] << value }
end.parse!(ARGV)

raise ArgumentError, "--phase is required" unless options["phase"]
raise ArgumentError, "--ref is required at least once" if options["refs"].empty?

guard.assert_phase_entry_allowed!(phase: options.fetch("phase"), refs: options.fetch("refs"))

puts "spec phase entry allowed for phase=#{options.fetch('phase')}"
