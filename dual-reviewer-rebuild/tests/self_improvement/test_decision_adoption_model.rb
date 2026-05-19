# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"
require "yaml"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 6: decision / adoption model（自己改善所有・スクラッチ）。
# 根拠: tasks.md Task 6、Requirement 4（受入 1〜5）、
#       design「Decision and Adoption Model §1〜§3」「Decision 3」
#       「Proposal States」。
#       適合レビュー 2026-05-19 finding（Task 9 決定的検証皆無のうち
#       adoption gate 3 条件部分）解消の品質保証対象。
#
# 決定的固定入力→期待出力。出力先は tmpdir（実 learning/ を汚さない）。
# proposal state machine は第4波 ProposalModel が正本（再定義しない）。
# required test artifact は第5波 ReplayBacktestModel の
# learning/backtests/<proposal_id>.json shape を前提とする。
class TestDecisionAdoptionModel < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path

  def setup
    require_relative "../../scripts/self_improvement/decision_adoption_model"
    require_relative "../../scripts/self_improvement/learning_layout"
    @model = DualReviewer::SelfImprovement::DecisionAdoptionModel.new(
      repo_root: ROOT
    )
    @layout = DualReviewer::SelfImprovement::LearningLayout
  end

  # tested 状態の runtime-affecting proposal（approval gate 対象）。
  def tested_prompt_proposal
    {
      "proposal_id" => "proposal-prompt-1",
      "status" => "tested",
      "target_layer" => "prompt",
      "motivation_class" => "runtime_quality"
    }
  end

  # approved 済み proposal（adoption gate 対象）。
  def approved_schema_proposal
    {
      "proposal_id" => "proposal-schema-1",
      "status" => "approved",
      "target_layer" => "schema",
      "motivation_class" => "evidence_quality"
    }
  end

  # 第5波 ReplayBacktestModel が出す test result artifact 形。
  def build_test_artifact(proposal_id, label: "supported")
    {
      "proposal_id" => proposal_id,
      "test_mode" => "backtest",
      "input_refs" => ["#{proposal_id}:classifications/run_classification_index.json"],
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

  # --- design §1 / Req4 受入 2: approval gate ------------------------------

  def test_runtime_affecting_layers_require_human_approval
    # prompt / policy / schema / runtime / workflow は human approval 必須。
    %w[prompt policy schema runtime workflow].each do |layer|
      g = @model.approval_gate(target_layer: layer)
      assert g["human_approval_required"],
             "#{layer} は human approval 必須のはず"
    end
  end

  def test_non_runtime_affecting_layer_is_rejected_by_approval_gate
    # design §1 の approval 対象 enum 外（report 等）は runtime-affecting
    # でないため approval gate を通さない（境界明示）。
    g = @model.approval_gate(target_layer: "report")
    refute g["human_approval_required"]
    refute g["allowed"]
  end

  def test_approved_does_not_mean_repo_change_landed
    # design §1: `approved` は採否判断であり repo change が入ったことを
    # まだ意味しない。approval 結果に repo 反映フラグが立たない。
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      res = @model.record_approval(
        learning_root: lr, proposal: tested_prompt_proposal,
        approver: "human:maintainer", approval_note: "looks good"
      )
      assert res["recorded"]
      assert_equal "approved", res["status"]
      refute res["repo_change_applied"],
             "approved は repo change 反映を意味してはならない"
      refute res["adopted"], "approved は adopted を意味してはならない"
    end
  end

  def test_approval_respects_state_machine_only_from_tested
    # design Proposal States: approved への許可遷移元は tested のみ。
    # draft から approved への直行は禁止（state machine 尊重）。
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      draft = tested_prompt_proposal.merge("status" => "draft")
      res = @model.record_approval(
        learning_root: lr, proposal: draft,
        approver: "human:maintainer", approval_note: nil
      )
      refute res["recorded"], "draft→approved は禁止のはず"
      assert_equal "draft", res["status"]
    end
  end

  # --- design §2 / Decision 3 / Req4 受入 3・4: adoption gate 3 条件 --------

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

  def test_adoption_succeeds_when_all_three_conditions_met
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      p = approved_schema_proposal
      write_backtest(learning_root: lr,
                     artifact: build_test_artifact(p["proposal_id"]))
      res = @model.adopt(**adopt_args(learning_root: lr, proposal: p))
      assert res["adopted"], "3 条件充足で adopted のはず: #{res['reason']}"
      assert_equal "adopted", res["status"]
    end
  end

  def test_adoption_blocked_when_proposal_not_approved
    # 条件 1 欠落: proposal が approved でない（tested のまま）。
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      p = approved_schema_proposal.merge("status" => "tested")
      write_backtest(learning_root: lr,
                     artifact: build_test_artifact(p["proposal_id"]))
      res = @model.adopt(**adopt_args(learning_root: lr, proposal: p))
      refute res["adopted"], "未 approved で adopted してはならない"
      assert_equal "proposal_not_approved", res["reason"]
    end
  end

  def test_adoption_blocked_when_test_artifact_missing
    # 条件 2 欠落: required test artifact が存在しない。
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      p = approved_schema_proposal
      # backtest artifact を書かない。
      res = @model.adopt(**adopt_args(learning_root: lr, proposal: p))
      refute res["adopted"], "test artifact 不在で adopted してはならない"
      assert_equal "test_artifact_missing", res["reason"]
    end
  end

  def test_adoption_blocked_when_version_update_ref_missing
    # 条件 3 欠落: repo change が version update と結びつかない。
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      p = approved_schema_proposal
      write_backtest(learning_root: lr,
                     artifact: build_test_artifact(p["proposal_id"]))
      args = adopt_args(learning_root: lr, proposal: p)
      args[:version_update_ref] = ""
      res = @model.adopt(**args)
      refute res["adopted"], "version update 不在で adopted してはならない"
      assert_equal "version_update_missing", res["reason"]
    end
  end

  def test_adoption_blocked_when_adopted_change_ref_missing
    # 条件 3 系: repo change 参照そのものが無ければ version update と
    # 結びつけられない。
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      p = approved_schema_proposal
      write_backtest(learning_root: lr,
                     artifact: build_test_artifact(p["proposal_id"]))
      args = adopt_args(learning_root: lr, proposal: p)
      args[:adopted_change_ref] = nil
      res = @model.adopt(**args)
      refute res["adopted"]
      assert_equal "repo_change_missing", res["reason"]
    end
  end

  def test_adoption_respects_state_machine_only_from_approved
    # design Proposal States: adopted への許可遷移元は approved のみ。
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      p = approved_schema_proposal.merge("status" => "draft")
      write_backtest(learning_root: lr,
                     artifact: build_test_artifact(p["proposal_id"]))
      res = @model.adopt(**adopt_args(learning_root: lr, proposal: p))
      refute res["adopted"], "draft→adopted は禁止のはず"
      assert_equal "illegal_transition", res["reason"]
    end
  end

  def test_adoption_blocked_when_test_artifact_untested
    # 条件 2 は単なる存在だけでなく未検証 artifact を adopted の根拠に
    # しない（untested は採用根拠にならない＝Decision 3 / Req3 受入 4）。
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      p = approved_schema_proposal
      write_backtest(
        learning_root: lr,
        artifact: build_test_artifact(p["proposal_id"], label: "untested")
      )
      res = @model.adopt(**adopt_args(learning_root: lr, proposal: p))
      refute res["adopted"], "untested artifact で adopted してはならない"
      assert_equal "test_artifact_untested", res["reason"]
    end
  end

  # --- Req4 受入 3・4: adoption_register 6 field 連結保存 -------------------

  def test_adoption_register_links_proposal_change_version_approval_test
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      p = approved_schema_proposal
      write_backtest(learning_root: lr,
                     artifact: build_test_artifact(p["proposal_id"]))
      @model.adopt(**adopt_args(learning_root: lr, proposal: p))

      reg_path = lr + "approved-updates/adoption_register.json"
      assert reg_path.file?, "adoption_register.json 未生成"
      reg = JSON.parse(reg_path.read)
      assert_equal "1.0.0", reg["schema_version"]
      e = reg["entries"].find { |x| x["proposal_id"] == p["proposal_id"] }
      refute_nil e, "adoption_register に該当 entry が無い"
      %w[proposal_id adopted_change_ref version_update_ref approval_ref
         test_artifact_ref adopted_at].each do |f|
        assert e.key?(f), "adoption_register entry に #{f} が無い"
        refute_nil e[f], "adoption_register entry の #{f} が nil"
      end
      assert_equal "commit:abc123", e["adopted_change_ref"]
      assert_equal "version:prompt_pack@1.2.0", e["version_update_ref"]
    end
  end

  def test_adoption_register_idempotent_per_proposal
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      p = approved_schema_proposal
      write_backtest(learning_root: lr,
                     artifact: build_test_artifact(p["proposal_id"]))
      @model.adopt(**adopt_args(learning_root: lr, proposal: p))
      @model.adopt(**adopt_args(learning_root: lr, proposal: p))
      reg = JSON.parse((lr + "approved-updates/adoption_register.json").read)
      n = reg["entries"].count { |x| x["proposal_id"] == p["proposal_id"] }
      assert_equal 1, n, "adoption_register が proposal ごとに冪等でない"
    end
  end

  # --- design §3 / Req4 受入 5: rejection model（preserved outcome） --------

  def test_rejection_register_preserves_outcome_with_four_fields
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      p = tested_prompt_proposal
      res = @model.reject(
        learning_root: lr, proposal: p,
        rejection_reason: "weak exploratory-only evidence",
        reviewer_note: "revisit if stronger evidence appears"
      )
      assert res["recorded"]
      assert_equal "rejected", res["status"]

      reg_path = lr + "rejected-updates/rejection_register.json"
      assert reg_path.file?, "rejection_register.json 未生成"
      reg = JSON.parse(reg_path.read)
      assert_equal "1.0.0", reg["schema_version"]
      e = reg["entries"].find { |x| x["proposal_id"] == p["proposal_id"] }
      refute_nil e, "rejection が invisible discard になっている"
      %w[proposal_id rejection_reason rejected_at reviewer_note].each do |f|
        assert e.key?(f), "rejection_register entry に #{f} が無い"
      end
      assert_equal "weak exploratory-only evidence", e["rejection_reason"]
    end
  end

  def test_rejection_allowed_from_tested_and_approved_and_draft
    # design Proposal States: rejected への許可遷移元は
    # draft / tested / approved。
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      %w[draft tested approved].each do |from|
        p = tested_prompt_proposal.merge(
          "status" => from,
          "proposal_id" => "proposal-#{from}-r"
        )
        res = @model.reject(
          learning_root: lr, proposal: p,
          rejection_reason: "superseded", reviewer_note: nil
        )
        assert res["recorded"], "#{from}→rejected は許可のはず"
        assert_equal "rejected", res["status"]
      end
    end
  end

  def test_rejection_blocked_from_terminal_state
    # design Proposal States: 終端 rejected/rolled_back は不可逆。
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      %w[rejected rolled_back].each do |from|
        p = tested_prompt_proposal.merge("status" => from)
        res = @model.reject(
          learning_root: lr, proposal: p,
          rejection_reason: "x", reviewer_note: nil
        )
        refute res["recorded"], "#{from} は終端で再 rejected 不可のはず"
      end
    end
  end

  def test_rejection_register_idempotent_per_proposal
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      p = tested_prompt_proposal
      @model.reject(learning_root: lr, proposal: p,
                    rejection_reason: "r1", reviewer_note: nil)
      @model.reject(learning_root: lr, proposal: p,
                    rejection_reason: "r2", reviewer_note: nil)
      reg = JSON.parse((lr + "rejected-updates/rejection_register.json").read)
      n = reg["entries"].count { |x| x["proposal_id"] == p["proposal_id"] }
      assert_equal 1, n, "rejection_register が proposal ごとに冪等でない"
    end
  end

  # --- 完了条件: approval と adoption の違いを説明できる --------------------

  def test_approval_vs_adoption_distinction_is_explained
    diff = @model.approval_vs_adoption_distinction
    assert_kind_of String, diff
    refute diff.strip.empty?
    # approval = 採否判断、adoption = repo 反映 + version update を含む。
    assert_match(/approv/i, diff)
    assert_match(/adopt/i, diff)
    assert_match(/version/i, diff)
  end
end
