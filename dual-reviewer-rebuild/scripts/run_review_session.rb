#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require_relative "../runtime/controller/session_controller"

repo_root = File.expand_path("..", __dir__)
controller = DualReviewer::Runtime::SessionController.new(repo_root: repo_root)

summary = {
  "entrypoint" => "run_review_session",
  "foundation_contract_summary" => controller.foundation_contract_summary,
  "step_names" => controller.step_executors.map(&:step_name)
}

initialized_run = controller.initialize_run(
    target_id: "spec:dual-reviewer-runtime:tasks",
    target_artifact_hash: "sha256:example-target-hash",
    phase_profile: "tasks",
    treatment: "dual+judgment",
    review_mode: "runtime_mediated",
    operator_id: "local-operator"
  )
step_payloads = controller.emit_step_artifacts(
  run_id: initialized_run.fetch("run_id"),
  target_id: initialized_run.fetch("metadata").fetch("target_id"),
  phase_profile: initialized_run.fetch("metadata").fetch("phase_profile"),
  treatment: initialized_run.fetch("metadata").fetch("treatment")
)
review_case = controller.aggregate_review_case(
  run_id: initialized_run.fetch("run_id"),
  metadata: initialized_run.fetch("metadata"),
  step_payloads: step_payloads
)

summary["sample_run_initialization"] = initialized_run
summary["step_artifacts"] = step_payloads
summary["review_case_path"] = review_case.fetch("review_case_path")

decision_artifacts = controller.emit_decision_artifacts(
  run_id: initialized_run.fetch("run_id"),
  step_payloads: step_payloads,
  human_decision: "approved",
  operator_id: "local-operator"
)
validation_close = controller.close_run(
  run_id: initialized_run.fetch("run_id"),
  metadata: initialized_run.fetch("metadata"),
  human_signoff: decision_artifacts.fetch("human_signoff")
)

case_manifest = controller.build_case_manifest(
  "case_id" => "sample-runtime-session",
  "target_id" => initialized_run.fetch("metadata").fetch("target_id"),
  "source_refs" => ["scripts/run_review_session.rb"],
  "case_manifest_ref" => "sample/runtime-session"
)

execution_v2_artifacts = controller.emit_execution_v2_artifacts(
  run_id: initialized_run.fetch("run_id"),
  track: "implementation",
  common_inputs: {
    "target_id" => initialized_run.fetch("metadata").fetch("target_id"),
    "target_artifact_hash" => initialized_run.fetch("metadata").fetch("target_artifact_hash"),
    "source_repository_id" => initialized_run.fetch("metadata").fetch("source_repository_id"),
    "source_revision" => initialized_run.fetch("metadata").fetch("source_revision"),
    "phase_profile" => initialized_run.fetch("metadata").fetch("phase_profile"),
    "treatment" => initialized_run.fetch("metadata").fetch("treatment"),
    "review_mode" => initialized_run.fetch("metadata").fetch("review_mode"),
    "source_refs" => ["scripts/run_review_session.rb"],
    "governance_refs" => ["runtime/foundation/metadata_contract.yaml"]
  },
  track_inputs: {
    "implementation_snapshot_ref" => "scripts/run_review_session.rb",
    "upstream_spec_refs" => [],
    "governance_refs" => ["runtime/foundation/metadata_contract.yaml"]
  },
  case_manifest: case_manifest,
  review_case: review_case.fetch("review_case"),
  decision_artifacts: decision_artifacts,
  validation_close: validation_close
)

summary["decision_artifacts"] = decision_artifacts
summary["validation_close"] = validation_close
summary["execution_v2_artifacts"] = execution_v2_artifacts

puts JSON.pretty_generate(summary)
