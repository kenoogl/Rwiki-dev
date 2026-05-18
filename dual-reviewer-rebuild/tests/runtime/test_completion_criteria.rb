# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 11 / D: Completion Criteria 充足の機械確認
# 根拠: tasks.md §6 Completion Criteria、design「Completion Criteria」、
#       §4 Downstream Handoff、実行側 A-5。
#
# 次を機械検証する集約テスト:
#  - 1 run artifact layout が説明可能（RunLayout が正本カタログを持つ）
#  - run close と validation 順序（Step D → human sign-off → validator →
#    close）が説明可能（SessionController の Run Close Boundary 順序）
#  - decision unit が finding と human judgment を接続する
#  - downstream 3 feature が読む artifact を追跡可能
#  - review_case.json が foundation review_case schema に常時準拠し、
#    review_artifact → review_case 投影規約を runtime が所有する（A-5）
class TestCompletionCriteria < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/

  def setup
    require_relative "../../runtime/execution_v2/contracts/run_layout"
    require_relative "../../runtime/execution_v2/writers/evidence_writer"
    require_relative "../../runtime/execution_v2/writers/review_case_projector"
    require_relative "../../runtime/execution_v2/decisions/step_d_integration"
    require_relative "../../runtime/execution_v2/decisions/decision_units"
    @dir = Pathname(Dir.mktmpdir)
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  # 完了条件 1: 1 run の artifact layout を説明できる。
  def test_artifact_layout_is_explainable
    cat = DualReviewer::Runtime::RunLayout.artifact_catalog
    %w[
      run_manifest.yaml review_case.json
      steps/step_a_primary_detection.json steps/step_d_integration.json
      decisions/decision_units.json decisions/human_signoff.json
      validation/validator_result.json validation/invalidation_markers.json
      derived/comparison_eligibility_note.json
      derived/invalid_run_triage_note.json
    ].each do |rel|
      assert cat.key?(rel), "artifact catalog に #{rel} がない"
      refute_empty cat.fetch(rel), "#{rel} の役割説明が空"
    end
    rel_paths = DualReviewer::Runtime::RunLayout
                .run_relative_artifacts("run-x")
    assert(rel_paths.all? { |p| p.start_with?("experiments/runs/run-x/") })
  end

  # 完了条件 2: run close と validation 順序が説明できる
  # （Step D → human sign-off → validator → close）。
  # ソーステキスト照合ではなく controller の実行時挙動で順序不変条件を検証する
  # （前提 3 条件未充足で validator 起動を拒否し、その説明文が canonical
  # 順序を述べる＝順序が機械的に説明可能）。
  def test_run_close_and_validation_order_is_explainable
    require_relative "../../runtime/controller/session_controller"
    require "tmpdir"
    Dir.mktmpdir do |d|
      ctrl = DualReviewer::Runtime::SessionController.new(run_root_base: d)
      run = ctrl.start_run(
        target_id: "t", target_artifact_hash: "h",
        source_repository_id: "r", source_revision: "rev",
        phase_profile: "design", treatment: "dual+judgment",
        review_mode: "runtime_mediated", protocol_version: "1.0.0",
        runtime_version: "0.1.0", prompt_set_version: "1.0.0",
        schema_set_version: "1.0.0", config_version: "1.0.0",
        config_hash: "h", operator_id: "op",
        track: "spec", source_refs: ["x"]
      )
      # 前提 3 条件未充足で validator を呼ぶと fail-closed し、説明文が
      # canonical 順序（Step D → human sign-off → freeze → validator →
      # close）を述べる。順序が機械的に説明可能であることの検証。
      err = assert_raises(
        DualReviewer::Runtime::SessionController::CloseBoundaryViolation
      ) { run.invoke_validator { { "validator_status" => "passed" } } }
      msg = err.message.gsub(/\s+/, " ")
      assert_match(
        /Step D -> human sign-off -> freeze -> validator -> close/, msg
      )
      assert_equal "orchestration_failed", run.run_status
      # close は validator 起動後にのみ成立する（順序）。
      run2 = ctrl.start_run(
        target_id: "t", target_artifact_hash: "h",
        source_repository_id: "r", source_revision: "rev",
        phase_profile: "design", treatment: "single",
        review_mode: "runtime_mediated", protocol_version: "1.0.0",
        runtime_version: "0.1.0", prompt_set_version: "1.0.0",
        schema_set_version: "1.0.0", config_version: "1.0.0",
        config_hash: "h", operator_id: "op",
        track: "spec", source_refs: ["x"]
      )
      e2 = assert_raises(
        DualReviewer::Runtime::SessionController::CloseBoundaryViolation
      ) { run2.close }
      assert_match(/close attempted before validator invocation/, e2.message)
    end
  end

  # 完了条件 3: decision unit が finding と human judgment を接続する。
  def test_decision_unit_connects_finding_and_human_judgment
    integ = DualReviewer::Runtime::StepDIntegration.new
    res = integ.integrate(
      step_a: { "findings" => [
        { "finding_id" => "f1", "source_role" => "primary_reviewer",
          "requirement_link" => "R1" }
      ] },
      step_b: { "assessments" => [
        { "finding_id" => "f1",
          "adversarial_outcome" => "no_counter_evidence_after_challenge" }
      ] },
      step_c: { "judgments" => [
        { "finding_id" => "f1", "final_label" => "necessary",
          "recommended_action" => "fix" }
      ] },
      treatment: "dual+judgment"
    )
    dm = DualReviewer::Runtime::DecisionUnitModel.new(
      run_id: "run-x", decision_units: res[:decision_units]
    )
    u = dm.decision_units.first
    # finding 接続
    assert_includes u.fetch("finding_refs"), "f1"
    assert_includes u.fetch("judgment_refs"), "f1"
    # human judgment 接続（不在 → 明示記録）
    assert_equal "pending", dm.decision_state(u.fetch("decision_unit_id"))
    dm.record_human_decision(decision_unit_id: u.fetch("decision_unit_id"),
                             decision: "approved")
    assert_equal "approved", dm.decision_state(u.fetch("decision_unit_id"))
    link = dm.finding_linkage.fetch("f1")
    assert_equal "decisions/human_signoff.json",
                 link.fetch("human_decision_ref")
  end

  # 完了条件 4: downstream 3 feature が読む artifact を追跡できる。
  def test_downstream_artifact_trace_is_tracked
    trace = DualReviewer::Runtime::ExecutionV2::EvidenceWriter
            .downstream_artifact_trace
    assert_equal %w[evaluation paper_interface self_improvement],
                 trace.keys.sort
    # §4 Downstream Handoff の evaluation 入力（runtime_summary 非依存）。
    assert_includes trace.fetch("evaluation"),
                    "derived/comparison_eligibility_note.json"
    refute_includes trace.fetch("evaluation"), "derived/runtime_summary.json"
    # self-improvement は step file / triage / failure_observation を読む。
    assert_includes trace.fetch("self_improvement"),
                    "steps/step_b_adversarial_review.json"
    assert_includes trace.fetch("self_improvement"),
                    "derived/invalid_run_triage_note.json"
    assert_includes trace.fetch("self_improvement"),
                    "failures/failure_observation.json"
    # paper-interface は raw step を直接読まず原則 evaluation 経由。
    assert(trace.fetch("paper_interface").any? { |s| s =~ /evaluation/ })
  end

  # 完了条件 5: review_case が foundation schema に常時準拠し、投影規約を
  # runtime（ReviewCaseProjector）が所有する（A-5）。
  def test_review_case_always_foundation_schema_compliant_runtime_owned_projection
    projector = DualReviewer::Runtime::ExecutionV2::ReviewCaseProjector.new
    metadata = full_metadata
    rc = projector.project(
      run_id: "run-x",
      metadata: metadata,
      step_records: [
        { "step_id" => "step_a", "step_name" => "primary_detection",
          "execution_state" => "executed",
          "prompt_identity" => { "prompt_id" => "p1" },
          "findings" => [
            { "finding_id" => "f1", "source_role" => "primary_reviewer",
              "severity" => "major", "summary" => "x" }
          ] },
        { "step_id" => "step_d", "step_name" => "integration",
          "execution_state" => "executed" }
      ],
      decision_units: [
        { "decision_unit_id" => "du-001", "finding_refs" => ["f1"] }
      ],
      validator_result_ref: "validation/validator_result.json",
      invalidation_marker_refs: []
    )
    schema = JSON.parse((ROOT + "runtime/schemas/review_case.schema.json").read)
    schema.fetch("required").each { |k| assert rc.key?(k), "top required #{k}" }
    schema.dig("properties", "metadata", "required").each do |k|
      assert rc.fetch("metadata").key?(k), "metadata required #{k}"
    end
    sr_req = schema.dig("properties", "step_records", "items", "required")
    rc.fetch("step_records").each do |sr|
      sr_req.each { |k| assert sr.key?(k), "step_records item required #{k}" }
    end
    # Step D は LLM 非依存のため安定識別子で string required を満たす。
    sd = rc.fetch("step_records").find { |s| s["step_id"] == "step_d" }
    assert_kind_of String, sd.fetch("step_prompt_artifact_id")
    # 投影規約は runtime 所有（ReviewCaseProjector がフィールド対応を定義）。
    f = rc.fetch("findings").first
    assert_equal "du-001", f.fetch("decision_unit_id")
    assert_equal "decisions/human_signoff.json", f.fetch("human_decision_ref")
  end

  private

  def full_metadata
    {
      "run_id" => "run-x", "target_id" => "t", "target_artifact_hash" => "h",
      "source_repository_id" => "r", "source_revision" => "rev",
      "phase_profile" => "design", "treatment" => "dual+judgment",
      "review_mode" => "runtime_mediated", "protocol_version" => "1.0.0",
      "runtime_version" => "0.1.0", "schema_set_version" => "1.0.0",
      "prompt_set_version" => "1.0.0", "config_version" => "1.0.0",
      "config_hash" => "h", "run_status" => "closed",
      "validator_status" => "passed", "human_signoff_status" => "approved",
      "evidence_class" => "candidate", "started_at" => "2026-05-19T00:00:00Z"
    }
  end
end
