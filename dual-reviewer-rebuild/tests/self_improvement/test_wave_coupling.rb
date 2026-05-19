# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"
require "yaml"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# 最終波 A: 波間結合解消（DecisionAdoptionModel ↔ RollbackModel）。
# 根拠: tasks.md Task 6・Task 7、design「Decision and Adoption Model §2」
#       「Rollback Model」（Req5 受入 6：motivating evidence 事後 invalidate
#       起点 rollback）。
#
# 既知ギャップ: RollbackModel#reassess_on_invalidation は adoption_register
# の motivating_run_refs（起点 run を invalidation marker に連結する）を
# 期待するが、DecisionAdoptionModel#adopt が現状これを出力していない。
# 本波で DecisionAdoptionModel を最小拡張し adoption_register に
# motivating_run_refs（proposal の source_evidence_refs / source_signal_ids
# から起点 run_id 群を機械導出）を冪等に追加出力する。既存 6 field 不変・
# 後方互換（追加のみ）。これにより rollback の事後 invalidate 起点
# reassess/rollback が end-to-end で機能する。
#
# 決定的固定入力→期待出力。出力先は tmpdir（実 learning/ を汚さない）。
class TestWaveCoupling < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path

  def setup
    require_relative "../../scripts/self_improvement/decision_adoption_model"
    require_relative "../../scripts/self_improvement/rollback_model"
    require_relative "../../scripts/self_improvement/learning_layout"
    @adopt = DualReviewer::SelfImprovement::DecisionAdoptionModel.new(
      repo_root: ROOT
    )
    @layout = DualReviewer::SelfImprovement::LearningLayout
  end

  # source_signal_ids は SignalExtraction の signal_id 形
  # （runtime:<run_id>:<code>:<ref> / evaluation:<run_id>:<code>:<ref>）。
  # これと source_evidence_refs を持つ approved proposal。
  def approved_proposal(id: "proposal-prompt-1",
                        run_id: "run-mot-0001")
    {
      "proposal_id" => id,
      "status" => "approved",
      "target_layer" => "prompt",
      "motivation_class" => "runtime_quality",
      "source_evidence_refs" =>
        ["findings/recurring_failure_signals.json#sig-high_reject_concentration"],
      "source_signal_ids" => [
        "runtime:#{run_id}:human_decision_dissent:decisions-decision-units-json"
      ]
    }
  end

  def build_test_artifact(proposal_id, label: "supported")
    {
      "proposal_id" => proposal_id,
      "test_mode" => "replay",
      "input_refs" => ["#{proposal_id}:review_case.json"],
      "result_label" => label,
      "tested_at" => "2026-05-19T00:00:00Z",
      "foundation_run_metadata_ref" => { "independently_verifiable" => true }
    }
  end

  def write_backtest(learning_root:, artifact:)
    @layout.write_artifact(
      learning_root: learning_root,
      relative_path: @layout.backtest_artifact_path(
        proposal_id: artifact["proposal_id"]
      ),
      payload: artifact
    )
  end

  def adopt_args(learning_root:, proposal:)
    {
      learning_root: learning_root,
      proposal: proposal,
      adopted_change_ref: "commit:abc123",
      version_update_ref: "version:prompt_pack@1.2.0",
      approval_ref: "approval:#{proposal['proposal_id']}",
      test_artifact_ref: @layout.backtest_artifact_path(
        proposal_id: proposal["proposal_id"]
      )
    }
  end

  def write_invalidation_markers(repo_root:, run_id:, markers:)
    dir = Pathname(repo_root) + "experiments/runs/#{run_id}/validation"
    dir.mkpath
    (dir + "invalidation_markers.json").write(
      JSON.pretty_generate("invalidation_markers" => markers)
    )
  end

  # --- A: adoption_register に motivating_run_refs が冪等追加される ---------

  def test_adoption_register_includes_motivating_run_refs_derived_from_proposal
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      p = approved_proposal(run_id: "run-mot-0001")
      write_backtest(learning_root: lr,
                     artifact: build_test_artifact(p["proposal_id"]))
      res = @adopt.adopt(**adopt_args(learning_root: lr, proposal: p))
      assert res["adopted"], "3 条件充足で adopted のはず: #{res['reason']}"

      reg = JSON.parse(
        (lr + "approved-updates/adoption_register.json").read
      )
      e = reg["entries"].find { |x| x["proposal_id"] == p["proposal_id"] }
      refute_nil e
      # 既存 6 field は不変（後方互換）。
      %w[proposal_id adopted_change_ref version_update_ref approval_ref
         test_artifact_ref adopted_at].each do |f|
        assert e.key?(f), "既存 field #{f} が消えている（後方互換違反）"
        refute_nil e[f]
      end
      # 追加: motivating_run_refs が起点 run を機械導出して持つ。
      assert e.key?("motivating_run_refs"),
             "adoption_register に motivating_run_refs が追加されていない"
      assert_includes e["motivating_run_refs"], "run-mot-0001",
                      "proposal の起点 run_id を導出できていない"
    end
  end

  def test_motivating_run_refs_idempotent_per_proposal
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      p = approved_proposal(run_id: "run-mot-0001")
      write_backtest(learning_root: lr,
                     artifact: build_test_artifact(p["proposal_id"]))
      @adopt.adopt(**adopt_args(learning_root: lr, proposal: p))
      @adopt.adopt(**adopt_args(learning_root: lr, proposal: p))
      reg = JSON.parse(
        (lr + "approved-updates/adoption_register.json").read
      )
      n = reg["entries"].count { |x| x["proposal_id"] == p["proposal_id"] }
      assert_equal 1, n, "adoption_register が冪等でない"
      e = reg["entries"].first
      assert_equal ["run-mot-0001"], e["motivating_run_refs"],
                   "motivating_run_refs が冪等でない（重複/増殖）"
    end
  end

  def test_motivating_run_refs_derived_from_source_evidence_refs_run_ids
    # source_signal_ids が無い proposal でも source_evidence_refs に
    # 直接 runtime run path があれば起点 run を導出できる。
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      p = {
        "proposal_id" => "proposal-direct-1",
        "status" => "approved",
        "target_layer" => "workflow",
        "motivation_class" => "workflow_quality",
        "source_evidence_refs" => [
          "experiments/runs/run-direct-9/validation/validator_result.json"
        ]
      }
      write_backtest(learning_root: lr,
                     artifact: build_test_artifact(p["proposal_id"]))
      @adopt.adopt(**adopt_args(learning_root: lr, proposal: p))
      reg = JSON.parse(
        (lr + "approved-updates/adoption_register.json").read
      )
      e = reg["entries"].find { |x| x["proposal_id"] == p["proposal_id"] }
      assert_includes e["motivating_run_refs"], "run-direct-9"
    end
  end

  # --- A: end-to-end 結合（adopt → 事後 invalidate → rollback 起動） --------

  def test_end_to_end_adopt_then_invalidation_triggers_rollback
    Dir.mktmpdir do |tmp|
      repo = Pathname(tmp) + "repo"
      lr = repo + "learning"
      p = approved_proposal(run_id: "run-mot-0001")
      write_backtest(learning_root: lr,
                     artifact: build_test_artifact(p["proposal_id"]))

      # 1) DecisionAdoptionModel で実際に adopt（motivating_run_refs 出力）。
      adopt_model = DualReviewer::SelfImprovement::DecisionAdoptionModel.new(
        repo_root: repo
      )
      res = adopt_model.adopt(**adopt_args(learning_root: lr, proposal: p))
      assert res["adopted"], "adopt 失敗: #{res['reason']}"

      # 2) 起点 evidence の run に foundation 無効化契約の marker が立つ。
      write_invalidation_markers(
        repo_root: repo, run_id: "run-mot-0001",
        markers: [
          {
            "marker_id" => "im-run-mot-0001-001",
            "run_id" => "run-mot-0001",
            "reason_code" => "validator_failed",
            "reason_detail" => "post-hoc contract violation",
            "issued_by" => "runtime", "scope" => "run"
          }
        ]
      )

      # 3) RollbackModel#reassess_on_invalidation が adoption_register の
      #    motivating_run_refs を辿り rollback を機械起動する。
      adopted = p.merge("status" => "adopted")
      rb_model = DualReviewer::SelfImprovement::RollbackModel.new(
        repo_root: repo
      )
      rres = rb_model.reassess_on_invalidation(
        learning_root: lr, proposals: [adopted]
      )
      hit = rres.find { |r| r["proposal_id"] == p["proposal_id"] }
      refute_nil hit, "DecisionAdoptionModel 出力経由で reassess が結合しない"
      assert_equal "rollback", hit["action"],
                   "adopted change の事後 invalidate で rollback 起動のはず"
      assert(hit["invalidation_marker_refs"].any? { |m|
        m.include?("run-mot-0001")
      }, "起点 run と invalidation marker が連結されていない")

      reg = JSON.parse((lr + "rollback/rollback_register.json").read)
      e = reg["entries"].find { |x| x["proposal_id"] == p["proposal_id"] }
      refute_nil e, "rollback 履歴が残っていない"
      assert_match(/invalidat/i, e["rollback_reason"])
    end
  end

  def test_no_marker_keeps_adopted_change_in_steady_state
    Dir.mktmpdir do |tmp|
      repo = Pathname(tmp) + "repo"
      lr = repo + "learning"
      p = approved_proposal(run_id: "run-mot-0001")
      write_backtest(learning_root: lr,
                     artifact: build_test_artifact(p["proposal_id"]))
      adopt_model = DualReviewer::SelfImprovement::DecisionAdoptionModel.new(
        repo_root: repo
      )
      adopt_model.adopt(**adopt_args(learning_root: lr, proposal: p))
      write_invalidation_markers(
        repo_root: repo, run_id: "run-mot-0001", markers: []
      )
      rb_model = DualReviewer::SelfImprovement::RollbackModel.new(
        repo_root: repo
      )
      rres = rb_model.reassess_on_invalidation(
        learning_root: lr, proposals: [p.merge("status" => "adopted")]
      )
      assert_nil rres.find { |r| r["proposal_id"] == p["proposal_id"] },
                 "invalidate されていない adopted change を誤起動してはならない"
    end
  end
end
