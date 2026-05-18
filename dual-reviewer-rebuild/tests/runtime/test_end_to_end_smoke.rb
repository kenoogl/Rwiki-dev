# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"
require "yaml"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 11 / C: end-to-end スモーク（旧 conformance review finding 1 再発防止）
# 根拠: tasks.md Task 11、§4 Downstream Handoff、§6 Completion Criteria、
#       design「Run Close Boundary」「Reference-Free Runtime Entry Principle」、
#       requirements Requirement 1 受入 6、reviews 旧 finding 1。
#
# 旧実装は initialize_run が即失敗し run を 1 件も開始できなかった（finding 1）。
# 本テストは reference-free entry から 1 run を通し、experiments/runs/<run_id>/
# 相当（tmpdir）に run_manifest / review_case / steps / decisions / validation /
# derived が生成され Run Close Boundary 順序（Step D → human sign-off →
# freeze → validator → close → post-close）が成立することを決定的に検証する。
# LLM seam は固定応答注入。実 experiments/runs/ は汚さない（tmpdir）。
# 最低 single / dual / dual+judgment の 3 treatment で 1 run ずつ通す。
class TestEndToEndSmoke < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/

  def setup
    require_relative "../../runtime/controller/session_controller"
    require_relative "../../runtime/execution_v2/analyzers/step_executors"
    require_relative "../../runtime/execution_v2/decisions/step_d_integration"
    require_relative "../../runtime/execution_v2/contracts/treatment_matrix"
    require_relative "../../runtime/execution_v2/decisions/decision_units"
    require_relative "../../runtime/execution_v2/writers/evidence_writer"
    require_relative "../../runtime/execution_v2/validation/validation_bridge"
    @dir = Pathname(Dir.mktmpdir)
    @ctrl = DualReviewer::Runtime::SessionController.new(run_root_base: @dir)
    @bridge = DualReviewer::Runtime::ExecutionV2::ValidationBridge.new(
      foundation_root: ROOT + "runtime/foundation"
    )
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  # 固定応答 seam（決定的）。
  class FixedSeam
    def call(role:, step:, prompt_body:, target:, context:)
      case step
      when "primary_detection"
        { "findings" => [
          { "finding_id" => "f1", "source_role" => "primary_reviewer",
            "requirement_link" => "R1", "severity" => "major",
            "summary" => "scope drift" }
        ] }
      when "adversarial_review"
        { "assessments" => [
          { "finding_id" => "f1",
            "adversarial_outcome" => "no_counter_evidence_after_challenge" }
        ] }
      when "judgment"
        { "judgments" => [
          { "finding_id" => "f1", "final_label" => "necessary",
            "recommended_action" => "fix" }
        ] }
      end
    end
  end

  def base_inputs(treatment)
    {
      target_id: "spec/dual-reviewer-runtime/tasks.md",
      target_artifact_hash: "sha256:deadbeef",
      source_repository_id: "Rwiki-v2-code-mod",
      source_revision: "abc1234",
      phase_profile: "design",
      treatment: treatment,
      review_mode: "runtime_mediated",
      protocol_version: "1.0.0",
      runtime_version: "0.1.0",
      prompt_set_version: "1.0.0",
      schema_set_version: "1.0.0",
      config_version: "1.0.0",
      config_hash: "sha256:cfg",
      operator_id: "kenji",
      track: "spec",
      source_refs: ["spec/x"]
    }
  end

  def identity(role)
    {
      "prompt_artifact_path" => "runtime/prompts/#{role}.md",
      "prompt_id" => "foundation.#{role}", "prompt_version" => "1.0.0",
      "role" => role
    }
  end

  # 1 run を reference-free entry から close + post-close まで通す。
  def drive_one_run(treatment)
    run = @ctrl.start_run(**base_inputs(treatment))
    run_root = @dir + "experiments/runs/#{run.run_id}"
    ex = DualReviewer::Runtime::StepExecutors.new(llm_seam: FixedSeam.new)
    writer = DualReviewer::Runtime::ExecutionV2::EvidenceWriter.new(
      run_root: run_root, run_id: run.run_id
    )
    writer.metadata = run.manifest_metadata

    matrix = DualReviewer::Runtime::TreatmentMatrix.execution_state_for(
      treatment: treatment
    )

    step_a = step_b = step_c = nil
    if matrix["step_a"] == "executed"
      step_a = ex.run_step_a(target: { "artifact" => "x" },
                             phase_profile: "design",
                             prompt_identity: identity("primary_reviewer"),
                             treatment: treatment)
      writer.write_raw_step(step_a)
    end
    if matrix["step_b"] == "executed"
      step_b = ex.run_step_b(target: {},
                             step_a_findings: step_a["findings"],
                             phase_profile: "design",
                             prompt_identity: identity("adversarial_reviewer"),
                             treatment: treatment)
      writer.write_raw_step(step_b)
    else
      writer.write_raw_step(
        DualReviewer::Runtime::StepExecutors.skip_marker(
          step_id: "step_b", step_name: "adversarial_review",
          treatment: treatment
        )
      )
    end
    if matrix["step_c"] == "executed"
      step_c = ex.run_step_c(step_a_findings: step_a["findings"],
                             step_b_assessments: step_b["assessments"],
                             phase_profile: "design",
                             prompt_identity: identity("judgment_reviewer"),
                             treatment: treatment)
      writer.write_raw_step(step_c)
    else
      writer.write_raw_step(
        DualReviewer::Runtime::StepExecutors.skip_marker(
          step_id: "step_c", step_name: "judgment", treatment: treatment
        )
      )
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

    # Run Close Boundary 順序: Step D → human sign-off → freeze → validator
    # → close → post-close。
    run.mark_step_d_complete
    signoff = dm.build_human_signoff(signed_off_by: "kenji")
    run.write_human_signoff(
      status: signoff["human_signoff_status"], signed_off_by: "kenji",
      covered_decision_unit_ids: signoff["covered_decision_unit_ids"]
    )
    run.freeze_raw_evidence
    run.invoke_validator do
      @bridge.validate(run_id: run.run_id, metadata: run.manifest_metadata,
                       frozen_evidence: { "raw" => "frozen" })
    end
    run.close
    writer.write_review_case(
      validator_result_ref: "validation/validator_result.json",
      invalidation_marker_refs: []
    )
    run.finalize_post_close(validation_bridge: @bridge)
    { run: run, run_root: run_root }
  end

  # foundation review_case schema の required を機械検証する最小チェッカ
  # （外部 gem 不使用。required キー存在のみを確認）。
  def assert_review_case_schema_compliant(run_root)
    schema = JSON.parse((ROOT + "runtime/schemas/review_case.schema.json").read)
    rc = JSON.parse((run_root + "review_case.json").read)
    schema.fetch("required").each do |k|
      assert rc.key?(k), "review_case top-level required 欠落: #{k}"
    end
    md_req = schema.dig("properties", "metadata", "required")
    md_req.each do |k|
      assert rc.fetch("metadata").key?(k),
             "review_case.metadata required 欠落: #{k}"
    end
    sr_req = schema.dig("properties", "step_records", "items", "required")
    rc.fetch("step_records").each do |sr|
      sr_req.each do |k|
        assert sr.key?(k), "review_case.step_records item required 欠落: #{k}"
      end
    end
    assert rc.key?("validation_refs")
  end

  def assert_run_layout_present(run_root)
    %w[
      run_manifest.yaml
      review_case.json
      steps/step_a_primary_detection.json
      steps/step_d_integration.json
      decisions/decision_units.json
      decisions/human_signoff.json
      validation/validator_result.json
      validation/invalidation_markers.json
      derived/invalid_run_triage_note.json
      derived/comparison_eligibility_note.json
    ].each do |rel|
      assert (run_root + rel).exist?, "run artifact 欠落: #{rel}"
    end
  end

  # finding 1 再発防止: reference-free entry から run を 1 件開始できる
  # （旧 initialize_run 即失敗の再発がない）。
  def test_reference_free_entry_starts_a_run
    run = @ctrl.start_run(**base_inputs("single"))
    refute_nil run.run_id
    assert_equal "in_progress", run.run_status
    rr = @dir + "experiments/runs/#{run.run_id}"
    assert (rr + "run_manifest.yaml").exist?
  end

  def test_single_treatment_full_run
    res = drive_one_run("single")
    assert_equal "closed", res[:run].run_status
    assert_run_layout_present(res[:run_root])
    assert_review_case_schema_compliant(res[:run_root])
    # single は Step B/C を意図的 skip marker として残す（事故的欠落と区別）。
    sb = JSON.parse((res[:run_root] + "steps/step_b_adversarial_review.json").read)
    assert_equal "skipped", sb["execution_state"]
    assert_match(/treatment/i, sb["reason"])
  end

  def test_dual_treatment_full_run
    res = drive_one_run("dual")
    assert_equal "closed", res[:run].run_status
    assert_run_layout_present(res[:run_root])
    assert_review_case_schema_compliant(res[:run_root])
    assert (res[:run_root] + "steps/step_b_adversarial_review.json").exist?
    sc = JSON.parse((res[:run_root] + "steps/step_c_judgment.json").read)
    assert_equal "skipped", sc["execution_state"]
  end

  def test_dual_judgment_treatment_full_run
    res = drive_one_run("dual+judgment")
    assert_equal "closed", res[:run].run_status
    assert_run_layout_present(res[:run_root])
    assert_review_case_schema_compliant(res[:run_root])
    %w[step_a_primary_detection step_b_adversarial_review
       step_c_judgment step_d_integration].each do |s|
      assert (res[:run_root] + "steps/#{s}.json").exist?
    end
    # decision unit が finding と human judgment を接続している。
    du = JSON.parse((res[:run_root] + "decisions/decision_units.json").read)
    u = du.fetch("decision_units").first
    assert_includes u.fetch("finding_refs"), "f1"
    assert_equal "approved", u.fetch("human_decision")
    so = JSON.parse((res[:run_root] + "decisions/human_signoff.json").read)
    assert_equal "approved", so.fetch("human_signoff_status")
  end

  # Run Close Boundary 順序が成立する（validator が human decision に先行しない）。
  def test_run_close_boundary_order_holds
    res = drive_one_run("dual+judgment")
    run_root = res[:run_root]
    so = JSON.parse((run_root + "decisions/human_signoff.json").read)
    vr = JSON.parse((run_root + "validation/validator_result.json").read)
    # human sign-off の signed_off_at <= validator validated_at（順序保証）。
    require "time"
    assert Time.parse(so.fetch("signed_off_at")) <=
           Time.parse(vr.fetch("validated_at")),
           "validator が human sign-off に先行した（順序違反）"
    md = YAML.safe_load((run_root + "run_manifest.yaml").read).fetch("metadata")
    assert_equal "closed", md.fetch("run_status")
    refute_nil md.fetch("closed_at")
  end
end
