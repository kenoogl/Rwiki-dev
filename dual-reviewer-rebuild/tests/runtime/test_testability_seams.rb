# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"
require "yaml"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 11: 4 testability seam の決定的検証ケース集約確認
# 根拠: tasks.md Task 11、design「Testability Seams」（4 点）、Completion Criteria。
#
# design「Testability Seams」4 点それぞれに、固定入力 → 期待出力の決定的
# 検証ケースが 1 つ以上存在し pass することを機械確認する集約テスト。
# 既存 tests/runtime/ への参照集約だが、各 seam に対して「決定的検証ケースが
# 存在し pass する」を本ファイル内で実行可能なアサーションとして再現する
# （無回帰の既存テストへの対応関係も明示する）。
class TestTestabilitySeams < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/

  def setup
    require_relative "../../runtime/execution_v2/analyzers/step_executors"
    require_relative "../../runtime/execution_v2/decisions/step_d_integration"
    require_relative "../../runtime/controller/session_controller"
    require_relative "../../runtime/execution_v2/validation/validation_bridge"
    @dir = Pathname(Dir.mktmpdir)
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  # 固定応答 seam（依存性注入。決定性のため固定応答を返す）。
  class FixedSeam
    def initialize(responses)
      @responses = responses
      @calls = []
    end
    attr_reader :calls

    def call(role:, step:, prompt_body:, target:, context:)
      @calls << { role: role, step: step }
      @responses.fetch(step)
    end
  end

  def primary_identity
    {
      "prompt_artifact_path" => "runtime/prompts/p.md",
      "prompt_id" => "foundation.primary_detection.primary_reviewer",
      "prompt_version" => "1.0.0", "role" => "primary_reviewer"
    }
  end

  # --- Seam 1: 言語モデル差し替え点 ---------------------------------------
  # 各 step executor の LLM 呼び出しが seam で差し替え可能・固定応答で決定的。
  # 対応既存テスト: tests/runtime/test_step_executors.rb
  #   test_step_a_executes_via_seam_and_records_identity ほか。
  def test_seam1_language_model_substitution_is_deterministic
    seam = FixedSeam.new(
      "primary_detection" => {
        "findings" => [{ "finding_id" => "f1", "requirement_link" => "R1" }]
      }
    )
    ex = DualReviewer::Runtime::StepExecutors.new(llm_seam: seam)
    out1 = ex.run_step_a(target: { "a" => 1 }, phase_profile: "design",
                         prompt_identity: primary_identity, treatment: "single")
    out2 = DualReviewer::Runtime::StepExecutors.new(llm_seam: FixedSeam.new(
      "primary_detection" => {
        "findings" => [{ "finding_id" => "f1", "requirement_link" => "R1" }]
      }
    )).run_step_a(target: { "a" => 1 }, phase_profile: "design",
                  prompt_identity: primary_identity, treatment: "single")
    # 固定応答で 2 回の実行が完全一致（決定的）。
    assert_equal out1["findings"], out2["findings"]
    assert_equal "executed", out1["execution_state"]
    assert_equal [{ role: "primary_reviewer", step: "primary_detection" }],
                 seam.calls
    # default seam は LLM を呼ばないモック（v2-acquisition 未承認段）。
    mock_default = DualReviewer::Runtime::StepExecutors.new
    md = mock_default.run_step_a(target: {}, phase_profile: "design",
                                 prompt_identity: primary_identity,
                                 treatment: "single")
    assert_equal [], md["findings"]
  end

  # --- Seam 2: 検証ブリッジ起動点 ----------------------------------------
  # validator 呼び出しが Run Close Boundary 単一起動点に集約。入力（凍結後
  # raw evidence）と出力（validator_result.json）で単体検証。
  # 対応既存テスト: tests/runtime/test_run_close_boundary_integration.rb /
  #   tests/runtime/test_validation_bridge.rb。
  def test_seam2_validation_bridge_single_invocation_point
    ctrl = DualReviewer::Runtime::SessionController.new(run_root_base: @dir)
    bridge = DualReviewer::Runtime::ExecutionV2::ValidationBridge.new(
      foundation_root: ROOT + "runtime/foundation"
    )
    run = ctrl.start_run(**base_inputs)
    run.mark_step_d_complete
    run.write_human_signoff(status: "approved", signed_off_by: "kenji")
    run.freeze_raw_evidence
    frozen = { "raw" => "frozen-fixed-input" }
    result = run.invoke_validator do
      bridge.validate(run_id: run.run_id, metadata: run.manifest_metadata,
                      frozen_evidence: frozen)
    end
    assert_equal "passed", result.fetch("validator_status")
    run.close
    rr = @dir + "experiments/runs/#{run.run_id}"
    saved = JSON.parse((rr + "validation/validator_result.json").read)
    assert_equal run.run_id, saved.fetch("run_id")
    # 単一起動点: 多重起動は禁止される（集約点が 1 つ）。
    assert_raises(
      DualReviewer::Runtime::SessionController::CloseBoundaryViolation
    ) do
      run.invoke_validator do
        bridge.validate(run_id: run.run_id, metadata: run.manifest_metadata,
                        frozen_evidence: frozen)
      end
    end
  end

  # --- Seam 3: ステップ入出力分離点 --------------------------------------
  # 各 step executor が入力（前 step 出力・prompt artifact・config）と出力
  # （steps/*.json 相当 record）で分離、前後 step なしで単体検証可能。
  # 対応既存テスト: tests/runtime/test_step_executors.rb（step 単体実行）。
  def test_seam3_step_io_isolation_without_neighbors
    seam = FixedSeam.new(
      "judgment" => {
        "judgments" => [{ "finding_id" => "f1", "final_label" => "necessary",
                          "recommended_action" => "fix" }]
      }
    )
    ex = DualReviewer::Runtime::StepExecutors.new(llm_seam: seam)
    # Step C を Step A/B executor を一切起動せず、固定入力のみで単体検証。
    out = ex.run_step_c(
      step_a_findings: [{ "finding_id" => "f1" }],
      step_b_assessments: [],
      phase_profile: "design",
      prompt_identity: {
        "prompt_artifact_path" => "x", "prompt_id" => "j",
        "prompt_version" => "1.0.0", "role" => "judgment_reviewer"
      },
      treatment: "dual+judgment"
    )
    assert_equal "step_c", out["step_id"]
    assert_equal "executed", out["execution_state"]
    assert_equal 1, out["judgments"].length
    refute_nil out["prompt_identity"]
  end

  # --- Seam 4: 決定単位生成検証 ------------------------------------------
  # Step D 機械統合に固定 Step A/B/C 出力を与え入出力対応で検証（LLM 非依存）。
  # 対応既存テスト: tests/runtime/test_step_executors.rb
  #   test_step_d_mechanical_integration_no_llm / tests/runtime/test_decision_units.rb。
  def test_seam4_step_d_mechanical_integration_io_correspondence
    step_a = { "findings" => [
      { "finding_id" => "f1", "source_role" => "primary_reviewer",
        "requirement_link" => "R1" }
    ] }
    step_b = { "assessments" => [
      { "finding_id" => "f1",
        "adversarial_outcome" => "counter_evidence_raised" }
    ] }
    step_c = { "judgments" => [
      { "finding_id" => "f1", "final_label" => "necessary",
        "recommended_action" => "fix" }
    ] }
    integ = DualReviewer::Runtime::StepDIntegration.new
    res1 = integ.integrate(step_a: step_a, step_b: step_b, step_c: step_c,
                           treatment: "dual+judgment")
    res2 = DualReviewer::Runtime::StepDIntegration.new.integrate(
      step_a: step_a, step_b: step_b, step_c: step_c,
      treatment: "dual+judgment"
    )
    # 固定入力 → 同一出力（決定的・新推論なし）。
    assert_equal res1[:decision_units], res2[:decision_units]
    u = res1[:decision_units].first
    assert_equal "fix", u["proposed_action"]
    assert_nil u["human_decision"]
    assert_equal true, res1[:run_close_readiness]["ready"]
    refute res1[:step_d_record].key?("prompt_identity")
  end

  # 4 seam すべてに決定的検証ケースが存在し pass することの集約宣言。
  # 本テストファイル内の 4 メソッド名と design 4 seam の対応を機械確認。
  def test_all_four_seams_have_deterministic_case_present
    seam_methods = {
      "language_model_substitution" =>
        :test_seam1_language_model_substitution_is_deterministic,
      "validation_bridge_invocation" =>
        :test_seam2_validation_bridge_single_invocation_point,
      "step_io_isolation" =>
        :test_seam3_step_io_isolation_without_neighbors,
      "step_d_mechanical_integration" =>
        :test_seam4_step_d_mechanical_integration_io_correspondence
    }
    assert_equal 4, seam_methods.size
    seam_methods.each_value do |m|
      assert_respond_to self, m, "seam の決定的検証ケース #{m} が存在しない"
    end
  end

  private

  def base_inputs
    {
      target_id: "spec/dual-reviewer-runtime/tasks.md",
      target_artifact_hash: "sha256:deadbeef",
      source_repository_id: "Rwiki-v2-code-mod",
      source_revision: "abc1234",
      phase_profile: "design",
      treatment: "dual+judgment",
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
end
