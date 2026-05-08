#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "yaml"

module DualReviewer
  module SelfImprovement
    class ProposalProvenanceResolver
      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def resolve(signal:)
        run_id = signal["run_id"]
        local_ref = run_id ? local_manifest_refs_by_run_id[run_id] : nil
        imported_ref = run_id ? imported_refs_by_run_id[run_id] : nil

        if signal["signal_source"] == "runtime"
          return build_local_resolution(signal: signal, local_ref: local_ref) if local_ref
          return build_imported_resolution(signal: signal, imported_ref: imported_ref) if imported_ref
        else
          return build_imported_resolution(signal: signal, imported_ref: imported_ref) if imported_ref
          return build_local_resolution(signal: signal, local_ref: local_ref) if local_ref
        end

        {
          "source_origin" => "manual_review_record",
          "source_repository_refs" => [],
          "source_admission_refs" => [],
          "source_provenance_status" => "manual_or_aggregate"
        }
      end

      private

      def build_imported_resolution(signal:, imported_ref:)
        admission_entry = imported_ref.fetch("admission_entry")
        ingestion_entry = imported_ref.fetch("ingestion_entry")

        {
          "source_origin" => "imported_external_bundle",
          "source_repository_refs" => [
            {
              "source_repository_id" => ingestion_entry["source_repository_id"],
              "source_revision" => ingestion_entry["source_revision"],
              "run_id" => signal["run_id"],
              "bundle_id" => admission_entry["bundle_id"]
            }
          ],
          "source_admission_refs" => [
            {
              "bundle_id" => admission_entry["bundle_id"],
              "run_id" => signal["run_id"],
              "admission_status" => admission_entry["admission_status"],
              "admission_reason_codes" => admission_entry["admission_reason_codes"],
              "eligible_for_standard_comparison" => admission_entry["eligible_for_standard_comparison"],
              "eligible_for_exploratory_analysis" => admission_entry["eligible_for_exploratory_analysis"]
            }
          ],
          "source_provenance_status" => imported_provenance_status(admission_entry)
        }
      end

      def build_local_resolution(signal:, local_ref:)
        {
          "source_origin" => "central_local_run",
          "source_repository_refs" => [
            {
              "source_repository_id" => local_ref["source_repository_id"],
              "source_revision" => local_ref["source_revision"],
              "run_id" => signal["run_id"]
            }
          ],
          "source_admission_refs" => [],
          "source_provenance_status" => "central_local"
        }
      end

      def imported_provenance_status(admission_entry)
        case admission_entry["admission_status"]
        when "admitted_standard"
          "standard_admitted"
        when "admitted_exploratory"
          "nonstandard_exploratory"
        else
          "nonstandard_rejected"
        end
      end

      def imported_refs_by_run_id
        @imported_refs_by_run_id ||= begin
          ingestion_by_run = load_entries(repo_root.join("experiments/analysis/imports/ingestion_register.json")).each_with_object({}) do |entry, acc|
            acc[entry["run_id"]] = entry
          end
          load_entries(repo_root.join("experiments/analysis/imports/admission_register.json")).each_with_object({}) do |entry, acc|
            run_id = entry["run_id"]
            acc[run_id] = {
              "admission_entry" => entry,
              "ingestion_entry" => ingestion_by_run[run_id]
            }
          end
        end
      end

      def local_manifest_refs_by_run_id
        @local_manifest_refs_by_run_id ||= begin
          manifest_paths = Dir[repo_root.join("tests/fixtures/evaluation/local_runs/*/run_manifest.yaml")] +
                           Dir[repo_root.join("experiments/runs/*/run_manifest.yaml")]
          manifest_paths.each_with_object({}) do |manifest_path, acc|
            payload = YAML.load_file(manifest_path)
            metadata = payload.fetch("metadata", {})
            run_id = metadata["run_id"]
            next unless run_id

            acc[run_id] = {
              "source_repository_id" => metadata["source_repository_id"],
              "source_revision" => metadata["source_revision"],
              "manifest_path" => manifest_path
            }
          end
        end
      end

      def load_entries(path)
        return [] unless path.exist?

        JSON.parse(path.read).fetch("entries", [])
      end
    end
  end
end
