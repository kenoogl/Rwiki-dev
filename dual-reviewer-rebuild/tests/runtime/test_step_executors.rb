# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 3: Step A/B/C/D executors と treatment × step 実行
# 根拠: tasks.md Task 3、Requirement 1（受入 1〜4）、Requirement 2（受入 1〜5）、
#       design「Step Execution Model」「Treatment × Step Execution Matrix」、
#       設計再確定 finding 5（LLM seam 1 点集約・注入可能）。
# 外部依存なし（gem 不使用）・repo 内で完結。
class TestStepExecutors < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/

  def setup
    require_relative "../../runtime/execution_v2/analyzers/step_executors"
    require_relative "../../runtime/execution_v2/decisions/step_d_integration"
    require_relative "../../runtime/execution_v2/contracts/treatment_matrix"
    @M = DualReviewer::Runtime::TreatmentMatrix
    @dir = Pathname(Dir.mktmpdir)
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  # finding 5: LLM 呼び出しを差し替え可能な seam に集約。
  # default はモック、テストは固定応答を注入し決定的に検証。
  class StubSeam
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
      "prompt_artifact_path" => "runtime/prompts/primary_detection/primary_reviewer.prompt.md",
      "prompt_id" => "foundation.primary_detection.primary_reviewer",
      "prompt_version" => "1.0.0",
      "role" => "primary_reviewer"
    }
  end

  def adversarial_identity
    {
      "prompt_artifact_path" => "runtime/prompts/adversarial_review/adversarial_reviewer.prompt.md",
      "prompt_id" => "foundation.adversarial_review.adversarial_reviewer",
      "prompt_version" => "1.0.0",
      "role" => "adversarial_reviewer"
    }
  end

  def judgment_identity
    {
      "prompt_artifact_path" => "runtime/prompts/judgment/judgment_reviewer.prompt.md",
      "prompt_id" => "foundation.judgment.judgment_reviewer",
      "prompt_version" => "1.0.0",
      "role" => "judgment_reviewer"
    }
  end

  # ---- Treatment × Step Execution Matrix（design 表・正本どおり）----

  def test_matrix_single
    s = @M.execution_state_for(treatment: "single")
    assert_equal "executed", s["step_a"]
    assert_equal "skipped",  s["step_b"]
    assert_equal "skipped",  s["step_c"]
    assert_equal "executed", s["step_d"]
  end

  def test_matrix_dual
    s = @M.execution_state_for(treatment: "dual")
    assert_equal "executed", s["step_a"]
    assert_equal "executed", s["step_b"]
    assert_equal "skipped",  s["step_c"]
    assert_equal "executed", s["step_d"]
  end

  def test_matrix_dual_judgment
    s = @M.execution_state_for(treatment: "dual+judgment")
    %w[step_a step_b step_c step_d].each do |k|
      assert_equal "executed", s[k]
    end
  end

  # 実行状態 3 値・reduced は将来語彙として定義（現行未使用）。
  def test_execution_states_vocabulary
    assert_equal %w[executed skipped reduced], @M::EXECUTION_STATES
  end

  def test_unknown_treatment_fails
    assert_raises(ArgumentError) { @M.execution_state_for(treatment: "triple") }
  end

  # ---- Step A: primary detection（LLM seam 経由・固定応答で決定的）----

  def test_step_a_executes_via_seam_and_records_identity
    seam = StubSeam.new(
      "primary_detection" => {
        "findings" => [
          { "finding_id" => "f1", "summary" => "scope drift",
            "severity" => "major", "requirement_link" => "R1" }
        ]
      }
    )
    ex = DualReviewer::Runtime::StepExecutors.new(llm_seam: seam)
    out = ex.run_step_a(
      target: { "artifact" => "x" }, phase_profile: "design",
      prompt_identity: primary_identity, treatment: "single"
    )
    assert_equal "step_a", out["step_id"]
    assert_equal "primary_detection", out["step_name"]
    assert_equal "executed", out["execution_state"]
    assert_equal "single", out["treatment"]
    assert_equal 1, out["findings"].length
    assert_equal "primary_reviewer", out["prompt_identity"]["role"]
    assert_equal [{ role: "primary_reviewer", step: "primary_detection" }],
                 seam.calls
  end

  # ---- Step B: forced-divergence（各 finding に adversarial_outcome 必須）----

  def test_step_b_sets_adversarial_outcome_per_finding
    seam = StubSeam.new(
      "adversarial_review" => {
        "assessments" => [
          { "finding_id" => "f1",
            "adversarial_outcome" => "counter_evidence_raised",
            "counter_evidence" => [{ "note" => "counterexample" }] },
          { "finding_id" => "f2",
            "adversarial_outcome" => "no_counter_evidence_after_challenge" }
        ]
      }
    )
    ex = DualReviewer::Runtime::StepExecutors.new(llm_seam: seam)
    a_findings = [{ "finding_id" => "f1" }, { "finding_id" => "f2" }]
    out = ex.run_step_b(
      target: {}, step_a_findings: a_findings, phase_profile: "design",
      prompt_identity: adversarial_identity, treatment: "dual"
    )
    assert_equal "executed", out["execution_state"]
    outcomes = out["assessments"].map { |x| x["adversarial_outcome"] }
    assert_includes %w[counter_evidence_raised
                       no_counter_evidence_after_challenge
                       not_assessed], outcomes[0]
    # 全 finding に必ず adversarial_outcome（空 counter_evidence で曖昧化しない）。
    out["assessments"].each do |x|
      refute_nil x["adversarial_outcome"]
      assert_includes %w[counter_evidence_raised
                         no_counter_evidence_after_challenge
                         not_assessed], x["adversarial_outcome"]
    end
  end

  # adversarial_outcome 欠落の seam 応答は invalid（曖昧化を許さない）。
  def test_step_b_rejects_missing_adversarial_outcome
    seam = StubSeam.new(
      "adversarial_review" => {
        "assessments" => [{ "finding_id" => "f1" }]
      }
    )
    ex = DualReviewer::Runtime::StepExecutors.new(llm_seam: seam)
    assert_raises(DualReviewer::Runtime::StepExecutors::StepExecutionError) do
      ex.run_step_b(
        target: {}, step_a_findings: [{ "finding_id" => "f1" }],
        phase_profile: "design", prompt_identity: adversarial_identity,
        treatment: "dual"
      )
    end
  end

  # ---- skip marker（treatment 由来の意図的 skip を run record だけで区別）----

  def test_skip_marker_record_shape
    m = DualReviewer::Runtime::StepExecutors.skip_marker(
      step_id: "step_b", step_name: "adversarial_review", treatment: "single"
    )
    assert_equal "step_b", m["step_id"]
    assert_equal "adversarial_review", m["step_name"]
    assert_equal "skipped", m["execution_state"]
    assert_equal "single", m["treatment"]
    refute_nil m["reason"]
    assert_match(/treatment/i, m["reason"])
  end

  # ---- Step C: judgment（LLM seam 経由）----

  def test_step_c_executes_via_seam
    seam = StubSeam.new(
      "judgment" => {
        "judgments" => [
          { "finding_id" => "f1", "final_label" => "necessary",
            "recommended_action" => "fix" }
        ]
      }
    )
    ex = DualReviewer::Runtime::StepExecutors.new(llm_seam: seam)
    out = ex.run_step_c(
      step_a_findings: [{ "finding_id" => "f1" }],
      step_b_assessments: [],
      phase_profile: "design", prompt_identity: judgment_identity,
      treatment: "dual+judgment"
    )
    assert_equal "executed", out["execution_state"]
    assert_equal "judgment_reviewer", out["prompt_identity"]["role"]
    assert_equal 1, out["judgments"].length
  end

  # ---- Step D: 機械統合（追加 LLM 呼び出しなし・入出力対応で検証）----

  def test_step_d_mechanical_integration_no_llm
    step_a = {
      "findings" => [
        { "finding_id" => "f1", "source_role" => "primary_reviewer",
          "requirement_link" => "R1" },
        { "finding_id" => "f2", "source_role" => "primary_reviewer",
          "requirement_link" => "R2" }
      ]
    }
    step_b = {
      "assessments" => [
        { "finding_id" => "f1",
          "adversarial_outcome" => "counter_evidence_raised" }
      ]
    }
    step_c = {
      "judgments" => [
        { "finding_id" => "f1", "final_label" => "necessary",
          "recommended_action" => "fix" }
      ]
    }
    integ = DualReviewer::Runtime::StepDIntegration.new
    res = integ.integrate(
      step_a: step_a, step_b: step_b, step_c: step_c,
      treatment: "dual+judgment"
    )
    # decision unit は requirement_link で集約（新推論なし）。
    units = res[:decision_units]
    assert_equal 2, units.length
    u1 = units.find { |u| u["finding_refs"].include?("f1") }
    # Step C final_label を proposed_action に写像。
    assert_equal "fix", u1["proposed_action"]
    # human_decision は未確定（Step D は確定しない）。
    assert_nil u1["human_decision"]
    assert_nil u1["human_decision_timestamp"]
    # run close readiness は必須 step 出力の充足のみで機械判定。
    assert_equal true, res[:run_close_readiness]["ready"]
    # step_d record は LLM 非依存（prompt_identity を持たない）。
    assert_equal "step_d", res[:step_d_record]["step_id"]
    assert_equal "executed", res[:step_d_record]["execution_state"]
    refute res[:step_d_record].key?("prompt_identity")
  end

  # Step C 非実行時（dual）は judgment 紐づけをスキップ・既定規則で proposed_action。
  def test_step_d_without_step_c_uses_default_rule
    step_a = { "findings" => [
      { "finding_id" => "f1", "source_role" => "primary_reviewer",
        "requirement_link" => "R1" }
    ] }
    step_b = { "assessments" => [
      { "finding_id" => "f1",
        "adversarial_outcome" => "no_counter_evidence_after_challenge" }
    ] }
    integ = DualReviewer::Runtime::StepDIntegration.new
    res = integ.integrate(step_a: step_a, step_b: step_b, step_c: nil,
                          treatment: "dual")
    u = res[:decision_units].first
    refute_nil u["proposed_action"] # 既定規則で必ず決まる
    assert_empty u["judgment_refs"]
  end

  # close readiness: 必須 step 出力欠落で ready=false（事故的欠落を機械判定）。
  def test_step_d_close_readiness_false_when_required_step_missing
    integ = DualReviewer::Runtime::StepDIntegration.new
    res = integ.integrate(
      step_a: { "findings" => [] }, step_b: nil, step_c: nil,
      treatment: "dual" # dual は Step B 必須
    )
    assert_equal false, res[:run_close_readiness]["ready"]
    refute_empty res[:run_close_readiness]["missing_required_steps"]
  end
end
