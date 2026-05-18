# frozen_string_literal: true

require "json"
require "pathname"
require_relative "../../runtime/controller/session_controller"
require_relative "../../runtime/execution_v2/analyzers/step_executors"
require_relative "../../runtime/execution_v2/decisions/step_d_integration"
require_relative "../../runtime/execution_v2/contracts/treatment_matrix"
require_relative "../../runtime/execution_v2/decisions/decision_units"
require_relative "../../runtime/execution_v2/writers/evidence_writer"
require_relative "../../runtime/execution_v2/validation/validation_bridge"

# Task 11 / B: 実行系所有 runner の新 controller API 整合（共有ドライバ）
# 根拠: tasks.md Task 2「Generic Protocol Entrypoint Rule」「Reference-Free
#       Runtime Entry Principle」、design「File Placement for v2 Runtime Core」
#       （scripts/track_runs/ は runtime 所有 adapter 層）、Run Close Boundary
#       順序（Step D → human sign-off → freeze → validator → close →
#       post-close）、設計再確定 finding 5（LLM seam）/ finding 9（順序不変条件）。
#
# 旧 v1 runner は新 controller に存在しない dangling API
# （initialize_run / emit_step_artifacts / aggregate_review_case /
# emit_decision_artifacts / close_run / build_case_manifest /
# emit_execution_v2_artifacts / export_run_bundle）と撤廃済み heuristic
# profile を呼んでいた。本ドライバはスクラッチ方針で、旧ロジックを流用せず
# 新 controller / execution_v2 公開 API のみで 1 run を canonical 順序で通す
# 最小実装を提供する（取得方式は v2-acquisition 所有のため LLM seam は既定
# モック。決定的に動く）。各 track runner はこのドライバの薄い wrapper にする。
module DualReviewer
  module TrackRuns
    class RuntimeSessionDriver
      # foundation review_mode enum（runtime で再定義しない）。track CLI の
      # review_mode 表現 → treatment 軸への写像（treatment と review_mode/
      # phase_profile は独立軸＝Requirement 8 受入 5）。
      TREATMENT_BY_REVIEW_MODE = {
        "single_review" => "single",
        "dual_review" => "dual",
        "dual_reviewer_workflow" => "dual+judgment"
      }.freeze

      def initialize(repo_root:, run_root_base:)
        @repo_root = Pathname(repo_root).expand_path
        @run_root_base = Pathname(run_root_base).expand_path
        @controller = DualReviewer::Runtime::SessionController.new(
          run_root_base: @run_root_base
        )
        @bridge = DualReviewer::Runtime::ExecutionV2::ValidationBridge.new(
          foundation_root: @repo_root + "runtime/foundation"
        )
      end

      def treatment_for(review_mode)
        TREATMENT_BY_REVIEW_MODE.fetch(review_mode) do
          raise ArgumentError, "unsupported review_mode: #{review_mode.inspect}"
        end
      end

      # reference-free entry で 1 run を canonical Run Close Boundary 順序で
      # 通し、生成 artifact path 群と run identity を返す。
      #
      # case_manifest_ref があれば controller がそれを読む。無ければ
      # track + source_refs（明示 track 必須入力）を渡す。どちらも無ければ
      # controller が fail fast（Generic Protocol Entrypoint Rule）。
      def run_session(target_id:, phase_profile:, review_mode:, operator:,
                      source_refs:, track: nil, case_manifest_ref: nil,
                      target_artifact_hash: "sha256:unspecified",
                      source_repository_id: "dual-reviewer-rebuild",
                      source_revision: "working")
        treatment = treatment_for(review_mode)

        run = @controller.start_run(
          target_id: target_id,
          target_artifact_hash: target_artifact_hash,
          source_repository_id: source_repository_id,
          source_revision: source_revision,
          phase_profile: phase_profile,
          treatment: treatment,
          review_mode: "runtime_mediated",
          protocol_version: "1.0.0",
          runtime_version: "0.1.0",
          prompt_set_version: "1.0.0",
          schema_set_version: "1.0.0",
          config_version: "1.0.0",
          config_hash: "sha256:unspecified",
          operator_id: operator,
          case_manifest_ref: case_manifest_ref,
          track: track,
          source_refs: source_refs
        )

        run_root = @run_root_base +
                   "experiments/runs/#{run.run_id}"
        result = drive(run: run, run_root: run_root, treatment: treatment,
                       phase_profile: phase_profile)
        result.merge("run_id" => run.run_id, "treatment" => treatment)
      end

      private

      def drive(run:, run_root:, treatment:, phase_profile:)
        ex = DualReviewer::Runtime::StepExecutors.new # 既定モック seam（決定的）
        writer = DualReviewer::Runtime::ExecutionV2::EvidenceWriter.new(
          run_root: run_root, run_id: run.run_id
        )
        writer.metadata = run.manifest_metadata
        matrix = DualReviewer::Runtime::TreatmentMatrix
                 .execution_state_for(treatment: treatment)

        step_a = step_b = step_c = nil
        if matrix["step_a"] == "executed"
          step_a = ex.run_step_a(
            target: {}, phase_profile: phase_profile,
            prompt_identity: identity("primary_reviewer"),
            treatment: treatment
          )
          writer.write_raw_step(step_a)
        end
        if matrix["step_b"] == "executed"
          step_b = ex.run_step_b(
            target: {}, step_a_findings: Array(step_a && step_a["findings"]),
            phase_profile: phase_profile,
            prompt_identity: identity("adversarial_reviewer"),
            treatment: treatment
          )
          writer.write_raw_step(step_b)
        else
          writer.write_raw_step(skip("step_b", "adversarial_review",
                                     treatment))
        end
        if matrix["step_c"] == "executed"
          step_c = ex.run_step_c(
            step_a_findings: Array(step_a && step_a["findings"]),
            step_b_assessments: Array(step_b && step_b["assessments"]),
            phase_profile: phase_profile,
            prompt_identity: identity("judgment_reviewer"),
            treatment: treatment
          )
          writer.write_raw_step(step_c)
        else
          writer.write_raw_step(skip("step_c", "judgment", treatment))
        end

        integ = DualReviewer::Runtime::StepDIntegration.new
        d = integ.integrate(step_a: step_a, step_b: step_b, step_c: step_c,
                            treatment: treatment)
        writer.write_raw_step(d[:step_d_record])

        dm = DualReviewer::Runtime::DecisionUnitModel.new(
          run_id: run.run_id, decision_units: d[:decision_units]
        )
        d[:decision_units].each do |u|
          dm.record_human_decision(decision_unit_id: u["decision_unit_id"],
                                   decision: "approved")
        end
        dm.write_decision_units(run_root: run_root)
        writer.write_decision_units(dm.decision_units)
        writer.write_metric_snapshot
        writer.write_comparison_eligibility_note(
          eligible_for_standard_comparison: true
        )

        # Run Close Boundary 順序（finding 9 不変条件）。
        run.mark_step_d_complete
        signoff = dm.build_human_signoff(signed_off_by: "runtime-driver")
        run.write_human_signoff(
          status: signoff["human_signoff_status"],
          signed_off_by: "runtime-driver",
          covered_decision_unit_ids: signoff["covered_decision_unit_ids"]
        )
        run.freeze_raw_evidence
        run.invoke_validator do
          @bridge.validate(run_id: run.run_id,
                           metadata: run.manifest_metadata,
                           frozen_evidence: { "raw" => "frozen" })
        end
        run.close
        writer.write_review_case(
          validator_result_ref: "validation/validator_result.json",
          invalidation_marker_refs: []
        )
        run.finalize_post_close(validation_bridge: @bridge)

        {
          "run_status" => run.run_status,
          "runtime_paths" => {
            "run_manifest" => (run_root + "run_manifest.yaml").to_s,
            "review_case" => (run_root + "review_case.json").to_s,
            "decision_units" =>
              (run_root + "decisions/decision_units.json").to_s,
            "human_signoff" =>
              (run_root + "decisions/human_signoff.json").to_s,
            "validator_result" =>
              (run_root + "validation/validator_result.json").to_s,
            "invalidation_markers" =>
              (run_root + "validation/invalidation_markers.json").to_s,
            "comparison_eligibility_note" =>
              (run_root + "derived/comparison_eligibility_note.json").to_s,
            "invalid_run_triage_note" =>
              (run_root + "derived/invalid_run_triage_note.json").to_s
          }
        }
      end

      def identity(role)
        {
          "prompt_artifact_path" => "runtime/prompts/#{role}.prompt.md",
          "prompt_id" => "foundation.#{role}",
          "prompt_version" => "1.0.0",
          "role" => role
        }
      end

      def skip(step_id, step_name, treatment)
        DualReviewer::Runtime::StepExecutors.skip_marker(
          step_id: step_id, step_name: step_name, treatment: treatment
        )
      end
    end
  end
end
