# frozen_string_literal: true

require "securerandom"
require "time"
require "open3"
require_relative "../support/foundation_asset_loader"
require_relative "../executors/step_a_primary_detection"
require_relative "../executors/step_b_adversarial_review"
require_relative "../executors/step_c_judgment"
require_relative "../executors/step_d_integration"
require_relative "../writers/evidence_writer"
require_relative "../validation/validation_bridge"
require_relative "../export/bundle_exporter"

module DualReviewer
  module Runtime
    class SessionController
      attr_reader :asset_loader, :evidence_writer, :validation_bridge, :bundle_exporter

      def initialize(repo_root:)
        @asset_loader = FoundationAssetLoader.new(repo_root: repo_root)
        @evidence_writer = EvidenceWriter.new(repo_root: repo_root)
        @validation_bridge = ValidationBridge.new(asset_loader: asset_loader)
        @bundle_exporter = BundleExporter.new(
          asset_loader: asset_loader,
          evidence_writer: evidence_writer
        )
      end

      def step_executors
        @step_executors ||= [
          StepAPrimaryDetection.new(asset_loader: asset_loader, evidence_writer: evidence_writer),
          StepBAdversarialReview.new(asset_loader: asset_loader, evidence_writer: evidence_writer),
          StepCJudgment.new(asset_loader: asset_loader, evidence_writer: evidence_writer),
          StepDIntegration.new(asset_loader: asset_loader, evidence_writer: evidence_writer)
        ]
      end

      def foundation_contract_summary
        {
          "metadata_contract_version" => asset_loader.metadata_contract.fetch("version"),
          "prompt_frontmatter_contract_version" => asset_loader.prompt_frontmatter_contract.fetch("version"),
          "review_case_schema_id" => asset_loader.review_case_schema.fetch("$id"),
          "canonical_run_subdirectories" => evidence_writer.canonical_subdirectories
        }
      end

      def bootstrap_run_context(target_id:, phase_profile:, treatment:)
        {
          target_id: target_id,
          phase_profile: phase_profile,
          treatment: treatment,
          foundation_contract_summary: foundation_contract_summary
        }
      end

      def initialize_run(target_id:, target_artifact_hash:, phase_profile:, treatment:, review_mode:, operator_id:)
        run_id = generate_run_id
        manifest = build_run_manifest(
          run_id: run_id,
          target_id: target_id,
          target_artifact_hash: target_artifact_hash,
          phase_profile: phase_profile,
          treatment: treatment,
          review_mode: review_mode,
          operator_id: operator_id
        )

        validate_required_metadata!(manifest.fetch("metadata"))
        manifest_path = evidence_writer.write_run_manifest(run_id: run_id, manifest: manifest)

        {
          "run_id" => run_id,
          "run_root" => evidence_writer.canonical_run_root(run_id).to_s,
          "run_manifest_path" => manifest_path.to_s,
          "metadata" => manifest.fetch("metadata")
        }
      end

      def emit_step_artifacts(run_id:, target_id:, phase_profile:, treatment:)
        step_payloads = step_executors.each_with_index.map do |executor, index|
          step_id = format("step-%02d", index + 1)
          payload = executor.execute(
            step_id: step_id,
            target_id: target_id,
            phase_profile: phase_profile,
            treatment: treatment
          )
          evidence_writer.write_step_artifact(run_id: run_id, step_name: executor.step_name, payload: payload)
          payload
        end

        step_payloads
      end

      def aggregate_review_case(run_id:, metadata:, step_payloads:)
        payload = {
          "schema_version" => "1.0.0",
          "review_case_id" => "review-case-#{run_id}",
          "metadata" => metadata,
          "step_records" => step_payloads.map do |payload_item|
            {
              "step_id" => payload_item.fetch("step_id"),
              "step_name" => payload_item.fetch("step_name"),
              "step_status" => payload_item.fetch("step_status"),
              "step_prompt_artifact_id" => payload_item.fetch("prompt_identity").fetch("prompt_id"),
              "step_started_at" => nil,
              "step_closed_at" => nil
            }
          end,
          "findings" => [],
          "validation_artifacts" => {
            "validator_result_refs" => [],
            "invalidation_marker_refs" => []
          }
        }

        review_case_path = evidence_writer.write_review_case(run_id: run_id, payload: payload)
        {
          "review_case_path" => review_case_path.to_s,
          "review_case" => payload
        }
      end

      def emit_decision_artifacts(run_id:, step_payloads:, human_decision:, operator_id:)
        decision_units_payload = {
          "decision_units" => [
            {
              "decision_unit_id" => "decision-unit-001",
              "finding_refs" => [],
              "judgment_refs" => step_payloads
                .select { |payload| payload.fetch("step_name") == "judgment" }
                .map { |payload| "#{evidence_writer.step_filename(payload.fetch('step_name'))}.json##{payload.fetch('step_id')}" },
              "proposed_action" => "no_action_yet",
              "human_decision" => human_decision,
              "human_decision_timestamp" => Time.now.utc.iso8601,
              "human_decision_note" => "Skeleton runtime decision artifact."
            }
          ]
        }
        human_signoff_payload = {
          "run_id" => run_id,
          "human_signoff_status" => human_decision == "approved" ? "approved" : "pending",
          "operator_id" => operator_id,
          "signoff_timestamp" => Time.now.utc.iso8601,
          "note" => "Skeleton runtime sign-off artifact."
        }

        decision_units_path = evidence_writer.write_decision_units(run_id: run_id, payload: decision_units_payload)
        human_signoff_path = evidence_writer.write_human_signoff(run_id: run_id, payload: human_signoff_payload)

        {
          "decision_units_path" => decision_units_path.to_s,
          "human_signoff_path" => human_signoff_path.to_s,
          "decision_units" => decision_units_payload,
          "human_signoff" => human_signoff_payload
        }
      end

      def close_run(run_id:, metadata:, human_signoff:)
        closed_at = Time.now.utc.iso8601
        metadata_for_validation = metadata.merge(
          "run_status" => "closed",
          "human_signoff_status" => human_signoff.fetch("human_signoff_status"),
          "closed_at" => closed_at
        )
        validation_result = validation_bridge.validate_run(
          run_id: run_id,
          metadata: metadata_for_validation,
          human_signoff: human_signoff
        )

        validator_result_path = evidence_writer.write_validator_result(
          run_id: run_id,
          payload: validation_result.fetch("validator_result")
        )
        invalidation_markers_path = evidence_writer.write_invalidation_markers(
          run_id: run_id,
          payload: { "invalidation_markers" => validation_result.fetch("invalidation_markers") }
        )

        final_validator_status = validation_result.fetch("validator_result").fetch("overall_status") == "passed" ? "passed" : "failed"
        final_evidence_class = if human_signoff.fetch("human_signoff_status") == "approved" && final_validator_status == "passed"
                                 "valid"
                               else
                                 "invalid"
                               end

        evidence_writer.update_run_manifest(run_id: run_id) do |manifest|
          manifest.fetch("metadata")["run_status"] = "closed"
          manifest.fetch("metadata")["validator_status"] = final_validator_status
          manifest.fetch("metadata")["human_signoff_status"] = human_signoff.fetch("human_signoff_status")
          manifest.fetch("metadata")["evidence_class"] = final_evidence_class
          manifest.fetch("metadata")["closed_at"] = closed_at
        end

        evidence_writer.update_review_case(run_id: run_id) do |review_case|
          review_case["metadata"]["run_status"] = "closed"
          review_case["metadata"]["validator_status"] = final_validator_status
          review_case["metadata"]["human_signoff_status"] = human_signoff.fetch("human_signoff_status")
          review_case["metadata"]["evidence_class"] = final_evidence_class
          review_case["metadata"]["closed_at"] = closed_at
          review_case["validation_artifacts"]["validator_result_refs"] = ["validation/validator_result.json##{validation_result.fetch('validator_result').fetch('validator_result_id')}"]
          review_case["validation_artifacts"]["invalidation_marker_refs"] = validation_result.fetch("invalidation_markers").map do |marker|
            "validation/invalidation_markers.json##{marker.fetch('invalidation_marker_id')}"
          end
        end

        {
          "validator_result_path" => validator_result_path.to_s,
          "invalidation_markers_path" => invalidation_markers_path.to_s,
          "validator_result" => validation_result.fetch("validator_result"),
          "invalidation_markers" => validation_result.fetch("invalidation_markers")
        }
      end

      def export_run_bundle(run_id:, metadata:)
        bundle_exporter.export_bundle(run_id: run_id, metadata: metadata)
      end

      private

      def build_run_manifest(run_id:, target_id:, target_artifact_hash:, phase_profile:, treatment:, review_mode:, operator_id:)
        {
          "manifest_version" => "1.0.0",
          "runtime_feature" => "dual-reviewer-runtime",
          "operator_id" => operator_id,
          "metadata" => {
            "run_id" => run_id,
            "target_id" => target_id,
            "target_artifact_hash" => target_artifact_hash,
            "source_repository_id" => source_repository_id,
            "source_revision" => source_revision,
            "phase_profile" => phase_profile,
            "treatment" => treatment,
            "review_mode" => review_mode,
            "protocol_version" => config_protocol_version,
            "runtime_version" => runtime_version,
            "schema_set_version" => asset_loader.review_case_schema.fetch("$id").split(":").last,
            "prompt_set_version" => asset_loader.prompt_frontmatter_contract.fetch("version"),
            "run_status" => "created",
            "validator_status" => "not_run",
            "human_signoff_status" => "pending",
            "evidence_class" => "candidate",
            "started_at" => Time.now.utc.iso8601,
            "closed_at" => nil
          }
        }
      end

      def validate_required_metadata!(metadata)
        required_fields = asset_loader.metadata_contract.fetch("required_fields")
        missing = required_fields.reject { |field| metadata.key?(field) }
        raise ArgumentError, "missing required metadata fields: #{missing.join(', ')}" unless missing.empty?

        empty_required = required_fields.reject do |field|
          value = metadata[field]
          !value.nil? && !(value.respond_to?(:empty?) && value.empty?)
        end
        empty_allowed = ["closed_at"]
        invalid_empty = empty_required - empty_allowed
        raise ArgumentError, "empty required metadata fields: #{invalid_empty.join(', ')}" unless invalid_empty.empty?
      end

      def generate_run_id
        timestamp = Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
        "run-#{timestamp}-#{SecureRandom.hex(4)}"
      end

      def source_repository_id
        @source_repository_id ||= begin
          stdout, status = Open3.capture2("git", "config", "--get", "remote.origin.url", chdir: asset_loader.repo_root.to_s)
          if status.success?
            origin_url_to_repository_id(stdout.strip)
          else
            asset_loader.repo_root.basename.to_s
          end
        end
      end

      def source_revision
        @source_revision ||= begin
          stdout, status = Open3.capture2("git", "rev-parse", "HEAD", chdir: asset_loader.repo_root.to_s)
          status.success? ? stdout.strip : "UNKNOWN"
        end
      end

      def config_protocol_version
        asset_loader.foundation_asset_path("runtime/config/config.yaml.template").yield_self do |path|
          config = YAML.load_file(path)
          config.fetch("review_protocol").fetch("protocol_version")
        end
      end

      def runtime_version
        "0.1.0"
      end

      def origin_url_to_repository_id(origin_url)
        return asset_loader.repo_root.basename.to_s if origin_url.empty?

        normalized = origin_url.sub(%r{\Ahttps://github\.com/}, "").sub(%r{\Agit@github\.com:}, "")
        normalized.delete_suffix(".git")
      end
    end
  end
end
