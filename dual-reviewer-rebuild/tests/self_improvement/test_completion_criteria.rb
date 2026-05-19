# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"
require "yaml"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 9: テスト確定（決定的検証ケースの集約）。
# 根拠: tasks.md Task 9（完了条件）・§6 Completion Criteria、
#       design「Completion Criteria」、適合レビュー 2026-05-19 finding 3
#       （決定的テスト不在＝Task 9 完了条件未達）の最終解消。
#
# 本ファイルは Task 9 が要求する「列挙 4 検証対象それぞれに固定入力→
# 期待出力の決定的検証ケースが 1 つ以上存在し pass する」ことを 1 箇所で
# 機械確認する集約テストである。各検証対象の詳細決定的ケースは波別テスト
# （test_proposal_model / test_input_model / test_replay_backtest_model /
# test_decision_adoption_model / test_rollback_model）が保持しており、本
# テストは (a) 4 検証対象の代表決定的ケースを直接 1 件ずつ再確認し、(b)
# design Completion Criteria 4 点（signal 使い分け説明・artifact 所在説明・
# approval/adoption 区別説明・runtime/evaluation/paper-interface 境界説明）
# の説明面を機械確認し、(c) 波別テストファイルの存在を対応として明示する。
class TestCompletionCriteria < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path
  FIX = ROOT + "tests/fixtures/self_improvement"

  def setup
    require_relative "../../scripts/self_improvement/learning_layout"
    require_relative "../../scripts/self_improvement/input_model"
    require_relative "../../scripts/self_improvement/proposal_model"
    require_relative "../../scripts/self_improvement/replay_backtest_model"
    require_relative "../../scripts/self_improvement/decision_adoption_model"
    require_relative "../../scripts/self_improvement/rollback_model"
    @layout = DualReviewer::SelfImprovement::LearningLayout
    @input = DualReviewer::SelfImprovement::InputModel.new(repo_root: ROOT)
    @prop = DualReviewer::SelfImprovement::ProposalModel.new(repo_root: ROOT)
    @rbt =
      DualReviewer::SelfImprovement::ReplayBacktestModel.new(repo_root: ROOT)
    @dec = DualReviewer::SelfImprovement::DecisionAdoptionModel.new(
      repo_root: ROOT
    )
    @rb = DualReviewer::SelfImprovement::RollbackModel.new(repo_root: ROOT)
  end

  # === 検証対象 1: proposal state machine 許可/不許可遷移（終端不可逆） ===

  def test_target1_proposal_state_machine_allowed_and_forbidden_transitions
    # 許可遷移（design §3 正本どおり）。
    {
      "draft" => "awaiting_test", "awaiting_test" => "tested",
      "tested" => "approved", "approved" => "adopted",
      "adopted" => "rolled_back", "draft2" => nil
    }
    [%w[draft awaiting_test], %w[draft rejected],
     %w[awaiting_test tested], %w[tested approved],
     %w[tested rejected], %w[approved adopted],
     %w[approved rejected], %w[adopted rolled_back]].each do |from, to|
      t = @prop.transition(from: from, to: to)
      assert t["allowed"], "許可遷移 #{from}->#{to} が拒否された"
      assert_equal to, t["status"]
    end

    # 不許可遷移（直行・終端からの遷移）。
    [%w[draft adopted], %w[draft approved], %w[awaiting_test approved],
     %w[tested adopted], %w[approved rolled_back]].each do |from, to|
      t = @prop.transition(from: from, to: to)
      refute t["allowed"], "不正遷移 #{from}->#{to} が許可された"
      assert_equal "illegal_transition", t["reason"]
    end

    # 終端は不可逆（rejected / rolled_back からは一切遷移しない）。
    %w[rejected rolled_back].each do |term|
      DualReviewer::SelfImprovement::ProposalModel::PROPOSAL_STATES
        .each do |to|
        next if to == term

        t = @prop.transition(from: term, to: to)
        refute t["allowed"], "終端 #{term}->#{to} が許可された"
        assert_equal "terminal_state", t["reason"]
      end
    end
  end

  # === 検証対象 2: provenance 欠落時の proposal 生成阻止 ==================

  def test_target2_proposal_generation_blocked_when_provenance_missing
    # run provenance も source_evidence も無い signal は阻止される
    # （Requirement 1 受入 6・design Input Model §2）。
    bare = { "run_id" => "", "source_refs" => [],
             "source_evidence_refs" => [] }
    gate = @input.proposal_provenance_gate(signal: bare)
    refute gate["allowed"], "provenance 欠落で阻止されていない"
    assert_includes gate["block_reasons"], "missing_run_provenance"
    assert_includes gate["block_reasons"], "missing_source_evidence_refs"

    # provenance 完備なら通る（決定的対照）。
    ok = { "run_id" => "run-x-1",
           "source_evidence_refs" => ["findings/x.json#sig-y"] }
    assert @input.proposal_provenance_gate(signal: ok)["allowed"]

    # provenance 不足 imported を admitted standard と等価扱いしない
    # （Requirement 8 受入 5）。
    imp = @input.resolve_imported_provenance(
      bundle: { "source_repository_id" => "r", "source_revision" => "",
                "admission_status" => "" }
    )
    refute imp["provenance_complete"]
    refute imp["equivalent_to_admitted_standard"]
  end

  # === 検証対象 3: test mode 3 要素分岐 + result_label 整合 =============

  def test_target3_test_mode_branching_and_result_label_consistency
    # 3 要素（変更規模・リスク水準・対象レイヤー）で判定し criteria を返す。
    workflow = { "target_layer" => "workflow",
                 "normalization_kind" => "coupled_workflow",
                 "source_signal_codes" => %w[validator_failed],
                 "evidence_maturity_context" => "invalid" }
    d = @rbt.decide_test_mode(proposal: workflow)
    assert_equal "manual_review", d["required_test_mode"]
    %w[change_scope risk_level target_layer].each do |k|
      assert d["criteria"].key?(k), "test mode 判定 criteria に #{k} が無い"
    end

    prompt = { "target_layer" => "prompt", "normalization_kind" => "single",
               "source_signal_codes" => %w[human_decision_dissent],
               "evidence_maturity_context" => "valid" }
    dp = @rbt.decide_test_mode(proposal: prompt)
    assert_equal "replay", dp["required_test_mode"]
    assert dp["step_level_replay_required"],
           "prompt は Step B/C 関与で step-level replay 必須のはず"

    # result_label 整合: untested は awaiting_test→tested を満たさない。
    untested = @rbt.untested_result(proposal: prompt)
    assert_equal "untested", untested["result_label"]
    refute @rbt.satisfies_tested_transition?(result: untested),
           "untested で tested 遷移を満たしてはならない"
    awaiting = prompt.merge("status" => "awaiting_test",
                            "proposal_id" => "p-await")
    g = @rbt.tested_transition_guard(proposal: awaiting, result: untested)
    refute g["allowed"]
    assert_equal "result_untested", g["reason"]

    # 実検証完了（label != untested かつ input_refs あり）は tested 可。
    supported = untested.merge("result_label" => "supported",
                               "input_refs" => ["p-await:review_case.json"])
    assert @rbt.satisfies_tested_transition?(result: supported)
    assert @rbt.tested_transition_guard(
      proposal: awaiting, result: supported
    )["allowed"]
  end

  # === 検証対象 4: adoption gate 3 条件 + invalidation 起点 rollback ====

  def test_target4_adoption_gate_three_conditions_and_invalidation_rollback
    Dir.mktmpdir do |tmp|
      repo = Pathname(tmp) + "repo"
      lr = repo + "learning"
      proposal = {
        "proposal_id" => "proposal-cc-1", "status" => "approved",
        "target_layer" => "prompt", "motivation_class" => "runtime_quality",
        "source_signal_ids" => [
          "runtime:run-cc-1:human_decision_dissent:decisions-decision-units-json"
        ]
      }
      ta_rel = @layout.backtest_artifact_path(proposal_id: "proposal-cc-1")
      @layout.write_artifact(
        learning_root: lr, relative_path: ta_rel,
        payload: { "proposal_id" => "proposal-cc-1",
                   "result_label" => "supported",
                   "input_refs" => ["proposal-cc-1:review_case.json"] }
      )
      dec = DualReviewer::SelfImprovement::DecisionAdoptionModel.new(
        repo_root: repo
      )
      common = { learning_root: lr, proposal: proposal,
                 adopted_change_ref: "commit:cc", approval_ref: "ap:cc",
                 test_artifact_ref: ta_rel }

      # 条件 3 欠落: version_update_ref 空 → adopted にならない。
      r0 = dec.adopt(**common.merge(version_update_ref: ""))
      refute r0["adopted"]
      assert_equal "version_update_missing", r0["reason"]

      # 3 条件充足 → adopted（motivating_run_refs も連結）。
      r1 = dec.adopt(**common.merge(version_update_ref: "ver:cc@1.0.0"))
      assert r1["adopted"], "3 条件充足で adopted のはず: #{r1['reason']}"
      reg = JSON.parse(
        (lr + "approved-updates/adoption_register.json").read
      )
      e = reg["entries"].find { |x| x["proposal_id"] == "proposal-cc-1" }
      assert_includes e["motivating_run_refs"], "run-cc-1"

      # invalidation 起点 rollback: 起点 run に marker → rollback 起動。
      vdir = repo + "experiments/runs/run-cc-1/validation"
      vdir.mkpath
      (vdir + "invalidation_markers.json").write(
        JSON.pretty_generate(
          "invalidation_markers" => [
            { "marker_id" => "im-cc-1", "run_id" => "run-cc-1",
              "reason_code" => "validator_failed", "scope" => "run",
              "issued_by" => "runtime" }
          ]
        )
      )
      rb = DualReviewer::SelfImprovement::RollbackModel.new(repo_root: repo)
      res = rb.reassess_on_invalidation(
        learning_root: lr, proposals: [proposal.merge("status" => "adopted")]
      )
      hit = res.find { |x| x["proposal_id"] == "proposal-cc-1" }
      refute_nil hit, "invalidation 起点 reassess が起動しない"
      assert_equal "rollback", hit["action"]
    end
  end

  # === design Completion Criteria 4 点の説明面（機械確認） ===============

  # 第 1 点: valid / invalid / exploratory の signal 使い分けを説明できる。
  def test_completion_point1_signal_usage_explained
    expl = @input.signal_usage_explanation
    assert_kind_of String, expl
    refute expl.strip.empty?
    assert_match(/valid/i, expl)
    assert_match(/invalid/i, expl)
    assert_match(/exploratory/i, expl)
    # 実体（policy）が説明と一致する決定的対照。
    assert_equal "review_quality_primary",
                 @input.input_policy_for(
                   evidence_maturity: "valid"
                 )["primary_use"]
    assert_equal "workflow_prevention_primary",
                 @input.input_policy_for(
                   evidence_maturity: "invalid"
                 )["primary_use"]
    assert_equal "hypothesis_seed_only",
                 @input.input_policy_for(
                   evidence_maturity: "exploratory"
                 )["primary_use"]
    refute @input.input_policy_for(
      evidence_maturity: "exploratory"
    )["adoption_supporting"], "exploratory は adoption 根拠として弱いはず"
  end

  # 第 2 点: proposal / backtest / adoption / rollback artifact 所在説明。
  def test_completion_point2_artifact_locations_explained
    loc = @layout.artifact_locations
    assert_equal "proposals/", loc["proposal"]
    assert_equal "backtests/", loc["backtest"]
    assert_equal "approved-updates/adoption_register.json", loc["adoption"]
    assert_equal "rollback/rollback_register.json", loc["rollback"]
    assert_equal "rejected-updates/rejection_register.json",
                 loc["rejection"]
  end

  # 第 3 点: approval と adoption の違いを説明できる。
  def test_completion_point3_approval_vs_adoption_explained
    d = @dec.approval_vs_adoption_distinction
    assert_kind_of String, d
    assert_match(/approv/i, d)
    assert_match(/adopt/i, d)
    assert_match(/version/i, d)
  end

  # 第 4 点: runtime / evaluation / paper-interface 境界を説明できる。
  def test_completion_point4_feature_boundary_explained
    b = @input.feature_boundary_explanation
    assert_kind_of String, b
    refute b.strip.empty?
    assert_match(/runtime/i, b)
    assert_match(/evaluation/i, b)
    assert_match(/paper/i, b)
    # rollback / supersession 境界も別途説明面を持つ（design Rollback）。
    rs = @rb.rollback_vs_supersession_distinction
    assert_match(/supersession/i, rs)
    assert_match(/rollback/i, rs)
  end

  # === 4 検証対象 ↔ 波別決定的テストファイルの対応を明示 ================

  def test_verification_targets_map_to_wave_local_deterministic_tests
    td = Pathname(__dir__)
    {
      "target1_state_machine" => "test_proposal_model.rb",
      "target2_provenance_block" => "test_input_model.rb",
      "target3_test_mode_result_label" => "test_replay_backtest_model.rb",
      "target4_adoption_gate" => "test_decision_adoption_model.rb",
      "target4_invalidation_rollback" => "test_rollback_model.rb"
    }.each do |target, file|
      assert (td + file).file?,
             "#{target} の波別決定的テスト #{file} が存在しない"
    end
  end
end
