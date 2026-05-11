#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

module DualReviewer
  module SelfImprovement
    class RemediationTemplateWriter
      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def write_templates(templates:)
        payload = {
          "generated_at" => templates.first && templates.first["created_at"],
          "entries" => templates
        }
        path = repo_root.join("learning/templates/workflow_remediation_templates.json")
        path.dirname.mkpath
        path.write(JSON.pretty_generate(payload))
        path
      end
    end
  end
end
