#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require_relative "self_improvement/remediation_template_builder"
require_relative "self_improvement/remediation_template_writer"

repo_root = Pathname(__dir__).join("..").expand_path
builder = DualReviewer::SelfImprovement::RemediationTemplateBuilder.new(repo_root: repo_root)
writer = DualReviewer::SelfImprovement::RemediationTemplateWriter.new(repo_root: repo_root)

templates = builder.build_templates
path = writer.write_templates(templates: templates)

puts "wrote #{path}"
puts "remediation_template_count=#{templates.length}"
