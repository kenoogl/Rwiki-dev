#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "shellwords"
require "tempfile"
require "English"

repo_root = Pathname(__dir__).join("..").expand_path

track = nil
case_id = nil
phase_profile = nil
allow_missing_summary = false
review_modes = nil
treatments = nil
selection_manifest = nil

argv = ARGV.dup
until argv.empty?
  flag = argv.shift
  case flag
  when "--track"
    track = argv.shift
  when "--case-id"
    case_id = argv.shift
  when "--phase-profile"
    phase_profile = argv.shift
  when "--review-mode"
    review_modes = argv.shift
  when "--treatment"
    treatments = argv.shift
  when "--selection-manifest"
    selection_manifest = argv.shift
  when "--allow-missing-summary"
    allow_missing_summary = true
  else
    abort "unknown argument: #{flag}"
  end
end

if selection_manifest.nil? && (track.nil? || case_id.nil?)
  abort "usage: ruby scripts/refresh_analysis_and_paper_from_selection.rb --track <track> --case-id <case_id> [--phase-profile <phase>] [--review-mode <modes>] [--treatment <treatments>] [--selection-manifest <path>] [--allow-missing-summary]"
end

select_command = ["ruby", repo_root.join("scripts/select_evaluation_run_set.rb").to_s]
if selection_manifest
  select_command.concat(["--selection-manifest", selection_manifest])
else
  select_command.concat(["--track", track, "--case-id", case_id])
end
select_command.concat(["--phase-profile", phase_profile]) if phase_profile
select_command.concat(["--review-mode", review_modes]) if review_modes
select_command.concat(["--treatment", treatments]) if treatments
select_command << "--allow-missing-summary" if allow_missing_summary

Tempfile.create(["analysis-run-set", ".json"]) do |file|
  selection_output = `#{select_command.map(&:to_s).map { |arg| Shellwords.escape(arg) }.join(" ")}`
  abort "selection failed" unless $CHILD_STATUS.success?

  file.write(selection_output)
  file.flush

  rebuild_command = [
    "ruby",
    repo_root.join("scripts/rebuild_evaluation_analysis_from_runs.rb").to_s,
    "--selection-json",
    file.path
  ]
  rebuild_output = `#{rebuild_command.map(&:to_s).map { |arg| Shellwords.escape(arg) }.join(" ")}`
  abort "analysis rebuild failed" unless $CHILD_STATUS.success?

  paper_commands = %w[
    build_paper_claim_map.rb
    build_paper_evidence_register.rb
    build_paper_table_source_bundle.rb
    build_paper_figure_source_bundle.rb
    build_paper_caveat_register.rb
    build_paper_reporting_fragments.rb
    build_paper_methodology_note_linkage.rb
  ].map { |script| ["ruby", repo_root.join("scripts", script).to_s] }

  paper_outputs = paper_commands.map do |command|
    output = `#{command.map(&:to_s).map { |arg| Shellwords.escape(arg) }.join(" ")}`
    abort "paper refresh failed for #{command.last}" unless $CHILD_STATUS.success?
    output
  end

  puts JSON.pretty_generate(
    {
      "selection" => JSON.parse(selection_output),
      "analysis_rebuild" => JSON.parse(rebuild_output),
      "paper_refresh_steps" => paper_outputs.map(&:lines).map { |lines| lines.map(&:strip).reject(&:empty?) }
    }
  )
end
