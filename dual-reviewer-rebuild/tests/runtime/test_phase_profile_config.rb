# frozen_string_literal: true

require "minitest/autorun"
require "pathname"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 10: phase-aware review profiles
# 根拠: tasks.md Task 10、Requirement 8（受入 1〜5）、
#       design「Phase-Aware Review Profiles」「Phase/Profile and Treatment Axes」
#       「Step Execution Model」（state machine 不変）。
# 外部依存なし（gem 不使用）・repo 内で完結・UTF-8。
class TestPhaseProfileConfig < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/

  def setup
    require_relative "../../runtime/execution_v2/profiles/phase_profile_config"
    require_relative "../../runtime/execution_v2/analyzers/step_executors"
    @C = DualReviewer::Runtime::PhaseProfileConfig
  end

  # 受入 1: intent/requirements/design/tasks の explicit phase/profile 選択を支援。
  def test_supports_four_explicit_phase_profiles
    assert_equal %w[intent requirements design tasks], @C.phase_profiles
    %w[intent requirements design tasks].each do |p|
      assert @C.supported?(p), "#{p} must be selectable"
    end
    refute @C.supported?("deployment")
  end

  # 受入 1: 未知 profile の選択は拡張解釈せず明示エラー。
  def test_unknown_profile_rejected
    err = assert_raises(ArgumentError) { @C.emphasis_for("deployment") }
    assert_match(/unknown phase_profile/, err.message)
  end

  # design 正本どおりの初版 emphasis（4 profile）。
  def test_initial_emphasis_matches_design_canon
    assert_equal %w[goal_ambiguity non_goal_leakage],
                 @C.emphasis_for("intent")
    assert_equal %w[scope_drift requirement_inconsistency],
                 @C.emphasis_for("requirements")
    assert_equal %w[responsibility_boundary dependency_mismatch
                    failure_mode_omission],
                 @C.emphasis_for("design")
    assert_equal %w[coverage_gap ordering_risk
                    unverifiable_task_decomposition],
                 @C.emphasis_for("tasks")
  end

  # emphasis は呼び出し側で破壊できない（config の正本性を守る）。
  def test_emphasis_is_not_mutable_across_calls
    first = @C.emphasis_for("design")
    first << "injected"
    assert_equal %w[responsibility_boundary dependency_mismatch
                    failure_mode_omission],
                 @C.emphasis_for("design")
  end

  # 受入 4: design/tasks は upstream(intent/requirements) より強い構造・
  # 依存指向 review。orientation 強度が upstream を厳密に上回る。
  def test_design_and_tasks_stronger_structural_dependency_than_upstream
    upstream = %w[intent requirements].map { |p| @C.structural_dependency_rank(p) }
    downstream = %w[design tasks].map { |p| @C.structural_dependency_rank(p) }
    assert downstream.min > upstream.max,
           "design/tasks structural-dependency rank must strictly exceed upstream"
    assert @C.structural_dependency_oriented?("design")
    assert @C.structural_dependency_oriented?("tasks")
    refute @C.structural_dependency_oriented?("intent")
    refute @C.structural_dependency_oriented?("requirements")
  end

  # 受入 5: treatment 選択と phase/profile 選択を区別。profile config は
  # treatment 語彙を持たず、判定にも用いない。
  def test_phase_profile_axis_distinct_from_treatment
    refute_respond_to @C, :treatments
    %w[single dual dual+judgment].each do |t|
      refute @C.supported?(t), "treatment #{t} must not be a phase_profile"
    end
    # 同一 profile は treatment が変わっても emphasis 不変（軸独立）。
    assert_equal @C.emphasis_for("design"), @C.emphasis_for("design")
  end

  # 受入 2: canonical Step A/B/C/D state machine を変えずに emphasis を切替。
  # profile を変えても step 列・順序・state は不変、emphasis のみ変わる。
  def test_state_machine_unchanged_emphasis_switches_per_profile
    seam = RecordingSeam.new
    ex = DualReviewer::Runtime::StepExecutors.new(llm_seam: seam)
    ident = {
      "prompt_artifact_path" => "p", "prompt_id" => "id",
      "prompt_version" => "1", "role" => "primary", "body" => "B"
    }
    results = {}
    %w[intent requirements design tasks].each do |profile|
      a = ex.run_step_a(target: "T", phase_profile: profile,
                        prompt_identity: ident, treatment: "single")
      b_ident = ident.merge("role" => "adversarial")
      b = ex.run_step_b(target: "T", step_a_findings: a["findings"],
                        phase_profile: profile, prompt_identity: b_ident,
                        treatment: "dual")
      results[profile] = [a, b]
    end
    # step 順序・id・state は profile に依らず不変（state machine 不変）。
    results.each do |profile, (a, b)|
      assert_equal "step_a", a["step_id"]
      assert_equal "primary_detection", a["step_name"]
      assert_equal "executed", a["execution_state"]
      assert_equal profile, a["phase_profile"]
      assert_equal "step_b", b["step_id"]
      assert_equal "adversarial_review", b["step_name"]
      assert_equal "executed", b["execution_state"]
      assert_equal profile, b["phase_profile"]
    end
    # emphasis は profile ごとに seam context へ供給され切り替わる。
    intent_ctx = seam.contexts.find { |c| c[:phase_profile] == "intent" }
    design_ctx = seam.contexts.find { |c| c[:phase_profile] == "design" }
    assert_equal @C.emphasis_for("intent"),
                 intent_ctx[:profile_emphasis]
    assert_equal @C.emphasis_for("design"),
                 design_ctx[:profile_emphasis]
    refute_equal intent_ctx[:profile_emphasis],
                 design_ctx[:profile_emphasis]
  end

  # 受入 3: 使用 phase/profile を run metadata に保持できる形を提供。
  def test_run_metadata_descriptor_tracks_used_profile
    desc = @C.run_metadata_descriptor("design")
    assert_equal "design", desc["phase_profile"]
    assert_equal @C.emphasis_for("design"), desc["profile_emphasis"]
    assert_equal true, desc["structural_dependency_oriented"]
    assert_equal @C.structural_dependency_rank("design"),
                 desc["structural_dependency_rank"]
    # treatment はこの descriptor に含めない（軸分離・受入 5）。
    refute desc.key?("treatment")
  end

  # 固定応答かつ seam に渡る context を記録するテスト用 seam。
  class RecordingSeam
    attr_reader :contexts

    def initialize
      @contexts = []
    end

    def call(role:, step:, prompt_body:, target:, context:)
      @contexts << context
      case step
      when "primary_detection" then { "findings" => [] }
      when "adversarial_review" then { "assessments" => [] }
      else { "judgments" => [] }
      end
    end
  end
end
