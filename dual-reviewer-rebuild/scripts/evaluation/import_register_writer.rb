#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "time"

module DualReviewer
  module Evaluation
    class ImportRegisterWriter
      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def write_ingestion_entry(bundle_intake:)
        entry = {
          "bundle_id" => bundle_intake.fetch("bundle_manifest", {})["bundle_id"],
          "run_id" => bundle_intake.fetch("bundle_manifest", {})["run_id"],
          "source_repository_id" => bundle_intake.fetch("bundle_manifest", {})["source_repository_id"],
          "source_revision" => bundle_intake.fetch("bundle_manifest", {})["source_revision"],
          "review_mode" => bundle_intake.fetch("bundle_manifest", {})["review_mode"],
          "ingested_at" => Time.now.utc.iso8601,
          "ingestion_status" => bundle_intake.fetch("ingestion_status"),
          "missing_fields" => combined_missing_fields(bundle_intake)
        }

        write_register(
          register_path: repo_root.join("experiments/analysis/imports/ingestion_register.json"),
          top_level_key: "entries",
          entry: entry
        )
      end

      def write_admission_entry(admission_result:)
        write_register(
          register_path: repo_root.join("experiments/analysis/imports/admission_register.json"),
          top_level_key: "entries",
          entry: admission_result
        )
      end

      private

      def combined_missing_fields(bundle_intake)
        [
          *bundle_intake.fetch("missing_bundle_artifacts", []),
          *bundle_intake.fetch("provenance_missing_fields", []),
          *bundle_intake.fetch("run_intake", {}).fetch("missing_artifacts", [])
        ]
      end

      def write_register(register_path:, top_level_key:, entry:)
        payload = if register_path.exist?
                    JSON.parse(register_path.read)
                  else
                    { top_level_key => [] }
                  end
        payload[top_level_key] << entry
        register_path.write(JSON.pretty_generate(payload))
        register_path
      end
    end
  end
end
