#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require_relative "../runtime/controller/session_controller"

repo_root = File.expand_path("..", __dir__)
controller = DualReviewer::Runtime::SessionController.new(repo_root: repo_root)

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
controller.aggregate_review_case(
  run_id: initialized_run.fetch("run_id"),
  metadata: initialized_run.fetch("metadata"),
  step_payloads: step_payloads
)
decision_artifacts = controller.emit_decision_artifacts(
  run_id: initialized_run.fetch("run_id"),
  step_payloads: step_payloads,
  human_decision: "approved",
  operator_id: "local-operator"
)
controller.close_run(
  run_id: initialized_run.fetch("run_id"),
  metadata: initialized_run.fetch("metadata"),
  human_signoff: decision_artifacts.fetch("human_signoff")
)

summary = {
  "entrypoint" => "export_evidence_bundle",
  "export_bundle" => controller.export_run_bundle(
    run_id: initialized_run.fetch("run_id"),
    metadata: initialized_run.fetch("metadata")
  )
}

puts JSON.pretty_generate(summary)
