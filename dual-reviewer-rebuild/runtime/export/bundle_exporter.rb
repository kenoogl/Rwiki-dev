# frozen_string_literal: true

require "digest"
require "pathname"
require "time"

module DualReviewer
  module Runtime
    class BundleExporter
      attr_reader :asset_loader, :evidence_writer

      def initialize(asset_loader:, evidence_writer:)
        @asset_loader = asset_loader
        @evidence_writer = evidence_writer
      end

      def export_manifest_seed(run_id:)
        {
          "run_id" => run_id,
          "source_metadata_contract" => asset_loader.metadata_contract.fetch("contract_id"),
          "export_status" => "not_implemented"
        }
      end

      def export_bundle(run_id:, metadata:)
        bundle_id = "bundle-#{run_id}"
        copied_run_root = evidence_writer.copy_run_to_bundle(run_id: run_id, bundle_id: bundle_id)
        included_artifact_refs = collect_relative_paths(copied_run_root)

        bundle_manifest = {
          "bundle_id" => bundle_id,
          "run_id" => run_id,
          "source_repository_id" => metadata.fetch("source_repository_id"),
          "source_revision" => metadata.fetch("source_revision"),
          "review_mode" => metadata.fetch("review_mode"),
          "exported_at" => Time.now.utc.iso8601,
          "export_runtime_version" => "0.1.0",
          "included_artifact_refs" => included_artifact_refs
        }

        bundle_manifest_path = evidence_writer.write_bundle_manifest(bundle_id: bundle_id, payload: bundle_manifest)
        checksums_path = evidence_writer.write_bundle_checksums(bundle_id: bundle_id, payload: build_checksum_payload(bundle_id))

        {
          "bundle_id" => bundle_id,
          "bundle_root" => evidence_writer.export_root(bundle_id).to_s,
          "bundle_manifest_path" => bundle_manifest_path.to_s,
          "checksums_path" => checksums_path.to_s
        }
      end

      private

      def collect_relative_paths(root)
        root_path = Pathname(root)
        Dir[root_path.join("**/*").to_s]
          .select { |path| File.file?(path) }
          .map { |path| Pathname(path).relative_path_from(root_path).to_s }
          .sort
      end

      def build_checksum_payload(bundle_id)
        bundle_root = evidence_writer.export_root(bundle_id)
        files = Dir[bundle_root.join("**/*").to_s]
          .select { |path| File.file?(path) }
          .reject { |path| path.end_with?("bundle_checksums.json") }
          .sort

        {
          "bundle_id" => bundle_id,
          "checksums" => files.map do |path|
            {
              "path" => Pathname(path).relative_path_from(bundle_root).to_s,
              "sha256" => Digest::SHA256.file(path).hexdigest
            }
          end
        }
      end
    end
  end
end
