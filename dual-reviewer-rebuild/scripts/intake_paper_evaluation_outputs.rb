#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require_relative "paper_interface/evaluation_intake_loader"

analysis_root = ARGV.shift
unless analysis_root
  warn "usage: ruby scripts/intake_paper_evaluation_outputs.rb <analysis_root>"
  exit 1
end

repo_root = Pathname(__dir__).join("..").expand_path
loader = DualReviewer::PaperInterface::EvaluationIntakeLoader.new(repo_root: repo_root)
puts JSON.pretty_generate(loader.load_analysis(analysis_root: analysis_root))
