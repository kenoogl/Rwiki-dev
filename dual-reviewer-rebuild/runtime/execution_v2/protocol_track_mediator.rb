# frozen_string_literal: true

require "digest"
require_relative "../support/foundation_asset_loader"
require_relative "../support/source_provenance_resolver"
require_relative "contracts/common_execution_contract"
require_relative "contracts/track_contract_specializer"

module DualReviewer
  module Runtime
    module ExecutionV2
      class ProtocolTrackMediator
        attr_reader :repo_root, :asset_loader, :source_provenance_resolver, :common_execution_contract, :track_contract_specializer

        def initialize(repo_root:)
          @repo_root = repo_root
          @asset_loader = DualReviewer::Runtime::FoundationAssetLoader.new(repo_root: repo_root)
          @source_provenance_resolver = DualReviewer::Runtime::SourceProvenanceResolver.new(repo_root: repo_root)
          @common_execution_contract = CommonExecutionContract.new(asset_loader: asset_loader)
          @track_contract_specializer = TrackContractSpecializer.new
        end

        def build_spec_execution_contract(case_id:, reviewed_phase:, reviewed_phase_ref:, adjacent_phase_refs:, alignment_refs:, workflow_gate_status_ref:, case_manifest_ref:, review_mode:)
          common_inputs = {
            "track" => "spec",
            "target_id" => "spec:#{case_id}",
            "target_artifact_hash" => "sha256:#{Digest::SHA256.hexdigest(reviewed_phase_ref)}",
            "source_repository_id" => source_provenance_resolver.repository_id,
            "source_revision" => source_provenance_resolver.revision,
            "phase_profile" => reviewed_phase,
            "treatment" => mapped_treatment(review_mode),
            "review_mode" => "manual_dogfooding",
            "source_refs" => ([reviewed_phase_ref] + adjacent_phase_refs + alignment_refs).uniq,
            "governance_refs" => [workflow_gate_status_ref],
            "case_manifest_ref" => case_manifest_ref
          }
          track_inputs = {
            "reviewed_phase" => reviewed_phase,
            "reviewed_phase_ref" => reviewed_phase_ref,
            "adjacent_phase_refs" => adjacent_phase_refs,
            "alignment_refs" => alignment_refs
          }

          contract = common_execution_contract.build(common_inputs: common_inputs, track_inputs: track_inputs)
          track_contract_specializer.specialize(track: "spec", common_inputs: common_inputs, track_inputs: track_inputs)
          contract
        end

        def build_intent_execution_contract(case_id:, intent_ref:, supporting_refs:, traceability_refs:, workflow_gate_status_ref:, case_manifest_ref:, review_mode:)
          common_inputs = {
            "track" => "intent",
            "target_id" => "intent:#{case_id}",
            "target_artifact_hash" => "sha256:#{Digest::SHA256.hexdigest(intent_ref)}",
            "source_repository_id" => source_provenance_resolver.repository_id,
            "source_revision" => source_provenance_resolver.revision,
            "phase_profile" => "intent",
            "treatment" => mapped_treatment(review_mode),
            "review_mode" => "manual_dogfooding",
            "source_refs" => ([intent_ref] + supporting_refs + traceability_refs).uniq,
            "governance_refs" => [workflow_gate_status_ref],
            "case_manifest_ref" => case_manifest_ref
          }
          track_inputs = {
            "intent_ref" => intent_ref,
            "supporting_refs" => supporting_refs,
            "traceability_refs" => traceability_refs
          }

          contract = common_execution_contract.build(common_inputs: common_inputs, track_inputs: track_inputs)
          track_contract_specializer.specialize(track: "intent", common_inputs: common_inputs, track_inputs: track_inputs)
          contract
        end

        private

        def mapped_treatment(review_mode)
          review_mode == "dual_reviewer_workflow" ? "dual+judgment" : "single"
        end
      end
    end
  end
end
