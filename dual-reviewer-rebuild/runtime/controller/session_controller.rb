# frozen_string_literal: true

require "securerandom"
require "time"
require_relative "../support/foundation_asset_loader"
require_relative "../support/source_provenance_resolver"
require_relative "../execution_v2/contracts/common_execution_contract"
require_relative "../execution_v2/contracts/track_contract_specializer"
require_relative "../execution_v2/manifests/case_manifest"
require_relative "../execution_v2/analyzers/base_analyzer"
require_relative "../execution_v2/decisions/decision_context"
require_relative "../execution_v2/writers/compatibility_projector"
require_relative "../execution_v2/writers/review_artifact_writer"
require_relative "../execution_v2/support/object_naming"
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
      attr_reader :asset_loader,
                  :evidence_writer,
                  :validation_bridge,
                  :bundle_exporter,
                  :source_provenance_resolver,
                  :common_execution_contract,
                  :track_contract_specializer,
                  :case_manifest_builder,
                  :decision_context_builder,
                  :compatibility_projector,
                  :review_artifact_writer,
                  :execution_v2_object_naming

      def initialize(repo_root:, run_root_base: nil, export_root_base: nil)
        @asset_loader = FoundationAssetLoader.new(repo_root: repo_root)
        @evidence_writer = EvidenceWriter.new(
          repo_root: repo_root,
          run_root_base: run_root_base,
          export_root_base: export_root_base
        )
        @validation_bridge = ValidationBridge.new(asset_loader: asset_loader)
        @bundle_exporter = BundleExporter.new(
          asset_loader: asset_loader,
          evidence_writer: evidence_writer
        )
        @source_provenance_resolver = SourceProvenanceResolver.new(repo_root: repo_root)
        @common_execution_contract = ExecutionV2::CommonExecutionContract.new(asset_loader: asset_loader)
        @track_contract_specializer = ExecutionV2::TrackContractSpecializer.new
        @case_manifest_builder = ExecutionV2::CaseManifest.new
        @decision_context_builder = ExecutionV2::DecisionContext.new
        @compatibility_projector = ExecutionV2::CompatibilityProjector.new
        @review_artifact_writer = ExecutionV2::ReviewArtifactWriter.new
        @execution_v2_object_naming = ExecutionV2::ObjectNaming.new
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
          "canonical_run_subdirectories" => evidence_writer.canonical_subdirectories,
          "execution_v2_contract_version" => ExecutionV2::CommonExecutionContract::CONTRACT_VERSION
        }
      end

      def build_execution_contract(track:, common_inputs:, track_inputs:)
        normalized_common_inputs = common_inputs.merge("track" => track)
        contract = common_execution_contract.build(
          common_inputs: normalized_common_inputs,
          track_inputs: track_inputs
        )

        track_contract_specializer.specialize(
          track: track,
          common_inputs: contract.fetch("common_inputs"),
          track_inputs: track_inputs
        )

        contract
      end

      def build_case_manifest(payload)
        case_manifest_builder.build(payload)
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

      def emit_step_artifacts(run_id:, target_id:, phase_profile:, treatment:, analysis_inputs: {})
        step_payloads = []
        step_executors.each_with_index do |executor, index|
          step_id = format("step-%02d", index + 1)
          payload = executor.execute(
            step_id: step_id,
            target_id: target_id,
            phase_profile: phase_profile,
            treatment: treatment,
            analysis_inputs: analysis_inputs,
            prior_step_payloads: step_payloads
          )
          evidence_writer.write_step_artifact(run_id: run_id, step_name: executor.step_name, payload: payload)
          step_payloads << payload
        end

        step_payloads
      end

      def aggregate_review_case(run_id:, metadata:, step_payloads:)
        judgment_index = step_payloads
          .select { |payload| payload.fetch("step_name") == "judgment" }
          .flat_map { |payload| payload.fetch("judgments", []) }
          .each_with_object({}) { |judgment, acc| acc[judgment.fetch("finding_id")] = judgment }
        step_observation_index = step_payloads
          .flat_map { |payload| payload.fetch("observations", []) }
          .each_with_object({}) { |observation, acc| acc[observation.fetch("observation_id")] = observation }
        step_evidence_record_index = step_payloads
          .flat_map { |payload| payload.fetch("evidence_records", []) }
          .each_with_object({}) { |record, acc| acc[record.fetch("evidence_record_id")] = record }

        findings = step_payloads
          .flat_map { |payload| payload.fetch("findings", []) }
          .map do |finding|
            judgment = judgment_index[finding.fetch("finding_id")]
            {
              "schema_version" => "1.0.0",
              "finding_id" => finding.fetch("finding_id"),
              "run_id" => run_id,
              "step_id" => finding.fetch("finding_id").split("-finding-").first,
              "source_role" => finding.fetch("source_role"),
              "severity" => finding.fetch("severity"),
              "summary" => finding.fetch("summary"),
              "source_refs" => finding.fetch("source_refs"),
              "counter_evidence_refs" => finding.fetch("counter_evidence_refs"),
              "judgment_ref" => judgment ? "steps/#{evidence_writer.step_filename('judgment')}.json##{judgment.fetch('necessity_judgment_id')}" : nil,
              "decision_unit_id" => nil,
              "human_decision_ref" => nil,
              "impact_score_ref" => nil,
              "failure_observation_refs" => finding.fetch("failure_observation_refs", []),
              "validation_refs" => {
                "invalidation_marker_refs" => []
              }
            }
          end
        observations = step_observation_index.values.map do |observation|
          {
            "observation_id" => observation.fetch("observation_id"),
            "source_role" => observation.fetch("source_role"),
            "severity" => observation.fetch("severity"),
            "summary" => observation.fetch("summary"),
            "source_refs" => observation.fetch("source_refs"),
            "counter_evidence_refs" => observation.fetch("counter_evidence_refs", []),
            "taxonomy_path" => observation["taxonomy_path"],
            "observation_class" => observation["observation_class"],
            "evidence_record_refs" => observation.fetch("evidence_record_ids", []).map { |id| "review_case.json##{id}" },
            "counter_evidence_record_refs" => observation.fetch("counter_evidence_record_ids", []).map { |id| "review_case.json##{id}" },
            "matched_pattern_ids" => observation.fetch("matched_pattern_ids", []),
            "counter_evidence_pattern_ids" => observation.fetch("counter_evidence_pattern_ids", []),
            "evidence_types" => observation.fetch("evidence_types", []),
            "counter_evidence_types" => observation.fetch("counter_evidence_types", []),
            "review_focuses" => observation.fetch("review_focuses", []),
            "source_kinds" => observation.fetch("source_kinds", []),
            "counter_evidence_source_kinds" => observation.fetch("counter_evidence_source_kinds", []),
            "section_classes" => observation.fetch("section_classes", []),
            "counter_evidence_section_classes" => observation.fetch("counter_evidence_section_classes", [])
          }
        end
        evidence_records = step_evidence_record_index.values.map do |record|
          {
            "evidence_record_id" => record.fetch("evidence_record_id"),
            "source_ref" => record.fetch("source_ref"),
            "source_kind" => record["source_kind"],
            "pattern_id" => record["pattern_id"],
            "evidence_type" => record["evidence_type"],
            "review_focus" => record["review_focus"],
            "section_heading" => record["section_heading"],
            "section_class" => record["section_class"],
            "first_line_number" => record["first_line_number"],
            "line_numbers" => record["line_numbers"],
            "matched_terms" => record["matched_terms"],
            "matched_excerpt" => record["matched_excerpt"]
          }
        end

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
          "evidence_records" => evidence_records,
          "observations" => observations,
          "findings" => findings,
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

      def emit_decision_artifacts(run_id:, step_payloads:, human_decision:, operator_id:, review_case: nil)
        judgments = step_payloads
          .select { |payload| payload.fetch("step_name") == "judgment" }
          .flat_map { |payload| payload.fetch("judgments", []) }
        findings = review_case ? review_case.fetch("findings", []) : []

        decision_units_payload = {
          "decision_units" => findings.map do |finding|
            judgment = judgments.find { |entry| entry.fetch("finding_id") == finding.fetch("finding_id") }
            {
              "decision_unit_id" => "decision-unit-#{finding.fetch('finding_id')}",
              "finding_refs" => ["review_case.json##{finding.fetch('finding_id')}"],
              "judgment_refs" => judgment ? ["#{evidence_writer.step_filename('judgment')}.json##{judgment.fetch('necessity_judgment_id')}"] : [],
              "proposed_action" => judgment ? judgment.fetch("recommended_action") : "manual_review_required",
              "human_decision" => human_decision,
              "human_decision_timestamp" => Time.now.utc.iso8601,
              "human_decision_note" => "Protocol pilot decision artifact."
            }
          end
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

        evidence_writer.update_review_case(run_id: run_id) do |review_case_payload|
          review_case_payload["findings"].each do |finding|
            decision_unit_id = "decision-unit-#{finding.fetch('finding_id')}"
            finding["decision_unit_id"] = decision_unit_id
            finding["human_decision_ref"] = "decisions/decision_units.json##{decision_unit_id}"
          end
        end

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
        comparison_eligibility_note = build_comparison_eligibility_note(
          run_id: run_id,
          metadata: metadata_for_validation,
          validator_result: validation_result.fetch("validator_result"),
          invalidation_markers: validation_result.fetch("invalidation_markers"),
          human_signoff: human_signoff
        )
        comparison_eligibility_note_path = evidence_writer.write_comparison_eligibility_note(
          run_id: run_id,
          payload: comparison_eligibility_note
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
          "comparison_eligibility_note_path" => comparison_eligibility_note_path.to_s,
          "validator_result" => validation_result.fetch("validator_result"),
          "invalidation_markers" => validation_result.fetch("invalidation_markers"),
          "comparison_eligibility_note" => comparison_eligibility_note
        }
      end

      def emit_execution_v2_artifacts(run_id:, track:, common_inputs:, track_inputs:, case_manifest:, review_case:, decision_artifacts:, validation_close:)
        execution_contract = build_execution_contract(
          track: track,
          common_inputs: common_inputs.merge("case_manifest_ref" => case_manifest.fetch("case_manifest_ref")),
          track_inputs: track_inputs
        )
        analyzer = ExecutionV2::BaseAnalyzer.new(track: track)
        analysis_result = analyzer.analyze(
          execution_contract,
          review_case: review_case,
          decision_artifacts: decision_artifacts,
          validation_close: validation_close
        )
        decision_context = decision_context_builder.build(
          execution_contract: execution_contract,
          analysis_result: analysis_result,
          decision_artifacts: decision_artifacts,
          validation_close: validation_close
        )
        compatibility_projection = compatibility_projector.build(
          review_case: review_case,
          decision_artifacts: decision_artifacts,
          analysis_result: analysis_result,
          validation_close: validation_close
        )
        review_artifact_payload = review_artifact_writer.build(
          execution_contract: execution_contract,
          decision_context: decision_context,
          compatibility_projection: compatibility_projection
        ).merge(
          "case_manifest" => case_manifest,
          "validation" => {
            "validator_result_ref" => "validation/validator_result.json##{validation_close.fetch('validator_result').fetch('validator_result_id')}",
            "invalidation_marker_refs" => validation_close.fetch("invalidation_markers").map do |marker|
              "validation/invalidation_markers.json##{marker.fetch('invalidation_marker_id')}"
            end,
            "comparison_eligibility_note_ref" => "derived/comparison_eligibility_note.json##{validation_close.fetch('comparison_eligibility_note').fetch('comparison_eligibility_note_id')}"
          }
        )
        metric_snapshot_payload = build_metric_snapshot(run_id: run_id, review_case: review_case, decision_artifacts: decision_artifacts)
        trace_note_payload = build_trace_note(run_id: run_id, track: track, case_manifest: case_manifest, common_inputs: common_inputs)
        signal_linkage_note_payload = build_signal_linkage_note(
          run_id: run_id,
          track: track,
          analysis_result: analysis_result,
          validation_close: validation_close
        )

        review_artifact_path = evidence_writer.write_v2_review_artifact(run_id: run_id, payload: review_artifact_payload)
        metric_snapshot_path = evidence_writer.write_v2_metric_snapshot(run_id: run_id, payload: metric_snapshot_payload)
        trace_note_path = evidence_writer.write_v2_trace_note(run_id: run_id, payload: trace_note_payload)
        signal_linkage_note_path = evidence_writer.write_v2_signal_linkage_note(run_id: run_id, payload: signal_linkage_note_payload)

        {
          "execution_contract" => execution_contract,
          "analysis_result" => analysis_result,
          "decision_context" => decision_context,
          "review_artifact_path" => review_artifact_path.to_s,
          "metric_snapshot_path" => metric_snapshot_path.to_s,
          "trace_note_path" => trace_note_path.to_s,
          "signal_linkage_note_path" => signal_linkage_note_path.to_s
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
        @source_repository_id ||= source_provenance_resolver.repository_id
      end

      def source_revision
        @source_revision ||= source_provenance_resolver.revision
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

      def build_comparison_eligibility_note(run_id:, metadata:, validator_result:, invalidation_markers:, human_signoff:)
        eligible = validator_result.fetch("overall_status") == "passed" &&
          human_signoff.fetch("human_signoff_status") == "approved" &&
          invalidation_markers.empty?

        {
          "schema_version" => "1.0.0",
          "comparison_eligibility_note_id" => "comparison-eligibility-#{run_id}",
          "run_id" => run_id,
          "eligibility_status" => eligible ? "eligible_standard" : "ineligible_standard",
          "review_mode" => metadata.fetch("review_mode"),
          "treatment" => metadata.fetch("treatment"),
          "reason_codes" => comparison_eligibility_reason_codes(
            validator_result: validator_result,
            invalidation_markers: invalidation_markers,
            human_signoff: human_signoff
          )
        }
      end

      def comparison_eligibility_reason_codes(validator_result:, invalidation_markers:, human_signoff:)
        codes = []
        codes << "validator_failed" unless validator_result.fetch("overall_status") == "passed"
        codes << "human_signoff_not_approved" unless human_signoff.fetch("human_signoff_status") == "approved"
        codes.concat(invalidation_markers.map { |marker| "invalidation:#{marker.fetch('reason_code')}" })
        codes = ["eligible_standard"] if codes.empty?
        codes
      end

      def build_metric_snapshot(run_id:, review_case:, decision_artifacts:)
        decisions = decision_artifacts.fetch("decision_units").fetch("decision_units")
        {
          "schema_version" => "1.0.0",
          "run_id" => run_id,
          "finding_count" => review_case.fetch("findings", []).length,
          "decision_unit_count" => decisions.length,
          "approved_decision_count" => decisions.count { |entry| entry["human_decision"] == "approved" },
          "rejected_decision_count" => decisions.count { |entry| entry["human_decision"] == "rejected" },
          "deferred_decision_count" => decisions.count { |entry| entry["human_decision"] == "deferred" }
        }
      end

      def build_trace_note(run_id:, track:, case_manifest:, common_inputs:)
        {
          "schema_version" => "1.0.0",
          "run_id" => run_id,
          "track" => track,
          "case_id" => case_manifest.fetch("case_id"),
          "target_id" => common_inputs.fetch("target_id"),
          "phase_profile" => common_inputs.fetch("phase_profile"),
          "source_refs" => common_inputs.fetch("source_refs"),
          "governance_refs" => common_inputs.fetch("governance_refs")
        }
      end

      def build_signal_linkage_note(run_id:, track:, analysis_result:, validation_close:)
        {
          "schema_version" => "1.0.0",
          "run_id" => run_id,
          "track" => track,
          "linked_signal_ids" => analysis_result.fetch("signal_candidates", []).map { |entry| entry.fetch("signal_id") },
          "validator_status" => validation_close.fetch("validator_result").fetch("overall_status"),
          "comparison_eligibility_status" => validation_close.fetch("comparison_eligibility_note").fetch("eligibility_status")
        }
      end
    end
  end
end
