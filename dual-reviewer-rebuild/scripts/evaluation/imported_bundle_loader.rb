#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "json"
require "pathname"
require "yaml"
require_relative "local_run_loader"

module DualReviewer
  module Evaluation
    class ImportedBundleLoader
      REQUIRED_BUNDLE_ARTIFACTS = {
        "bundle_manifest" => "bundle_manifest.yaml",
        "bundle_checksums" => "checksums/bundle_checksums.json"
      }.freeze

      REQUIRED_PROVENANCE_FIELDS = %w[
        bundle_id
        run_id
        source_repository_id
        source_revision
        review_mode
        export_runtime_version
        included_artifact_refs
      ].freeze

      attr_reader :repo_root, :local_run_loader

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
        @local_run_loader = LocalRunLoader.new(repo_root: repo_root)
      end

      def load_bundle(bundle_root:)
        root = Pathname(bundle_root).expand_path
        bundle_artifacts = {}
        missing_artifacts = []

        REQUIRED_BUNDLE_ARTIFACTS.each do |artifact_name, relative_path|
          artifact_path = root.join(relative_path)
          if artifact_path.exist?
            bundle_artifacts[artifact_name] = load_artifact(artifact_path)
          else
            missing_artifacts << relative_path
          end
        end

        bundle_manifest = bundle_artifacts["bundle_manifest"] || {}
        run_root = resolve_run_root(root, bundle_manifest)
        run_intake = run_root&.exist? ? local_run_loader.load_run(run_root: run_root) : nil
        checksum_verification = bundle_artifacts["bundle_checksums"] ? verify_checksums(root, bundle_artifacts["bundle_checksums"]) : []
        provenance_missing_fields = missing_provenance_fields(bundle_manifest)

        {
          "bundle_root" => root.to_s,
          "required_bundle_artifacts" => REQUIRED_BUNDLE_ARTIFACTS,
          "missing_bundle_artifacts" => missing_artifacts,
          "checksum_verification" => checksum_verification,
          "provenance_missing_fields" => provenance_missing_fields,
          "ingestion_status" => ingestion_status(
            missing_bundle_artifacts: missing_artifacts,
            checksum_verification: checksum_verification,
            provenance_missing_fields: provenance_missing_fields,
            run_intake: run_intake
          ),
          "bundle_manifest" => bundle_manifest,
          "run_root" => run_root&.to_s,
          "run_intake" => run_intake
        }
      end

      private

      def load_artifact(path)
        case path.extname
        when ".yaml", ".yml"
          YAML.load_file(path)
        when ".json"
          JSON.parse(path.read)
        else
          raise ArgumentError, "unsupported artifact format: #{path}"
        end
      end

      def resolve_run_root(bundle_root, bundle_manifest)
        run_id = bundle_manifest["run_id"]
        return nil unless run_id

        bundle_root.join("run", run_id)
      end

      def verify_checksums(bundle_root, checksum_payload)
        checksum_payload.fetch("checksums", []).map do |entry|
          relative_path = entry.fetch("path")
          expected_sha = entry.fetch("sha256")
          artifact_path = bundle_root.join(relative_path)
          actual_sha = artifact_path.exist? ? Digest::SHA256.file(artifact_path).hexdigest : nil

          {
            "path" => relative_path,
            "expected_sha256" => expected_sha,
            "actual_sha256" => actual_sha,
            "status" => artifact_path.exist? && actual_sha == expected_sha ? "matched" : "mismatch"
          }
        end
      end

      def missing_provenance_fields(bundle_manifest)
        REQUIRED_PROVENANCE_FIELDS.reject do |field|
          value = bundle_manifest[field]
          !value.nil? && !(value.respond_to?(:empty?) && value.empty?)
        end
      end

      def ingestion_status(missing_bundle_artifacts:, checksum_verification:, provenance_missing_fields:, run_intake:)
        return "incomplete" unless missing_bundle_artifacts.empty?
        return "incomplete" if run_intake.nil?
        return "incomplete" unless run_intake.fetch("missing_artifacts").empty?
        return "checksum_failed" if checksum_verification.any? { |entry| entry.fetch("status") != "matched" }
        return "provenance_incomplete" unless provenance_missing_fields.empty?

        "complete"
      end
    end
  end
end
