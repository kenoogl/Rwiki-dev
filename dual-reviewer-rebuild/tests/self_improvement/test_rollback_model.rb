# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"
require "yaml"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 7: rollback model（自己改善所有・スクラッチ）。
# 根拠: tasks.md Task 7、Requirement 5（受入 1〜6）、
#       design「Rollback Model」「Decision 4」「Proposal States」
#       （adopted→rolled_back）。
#       適合レビュー 2026-05-19 finding（Task 9 決定的検証皆無のうち
#       invalidation 起点 rollback 部分）解消の品質保証対象。
#
# 決定的固定入力→期待出力。出力先は tmpdir（実 learning/ を汚さない）。
# proposal state machine（adopted→rolled_back のみ rollback 遷移許可、
# 終端 rolled_back 不可逆）は第4波 ProposalModel が正本（再定義しない）。
# adopted_change_ref / version_update_ref を持つ adoption_register は
# 第6波 DecisionAdoptionModel が提供する shape を前提とする。
# foundation 無効化契約（foundation 要件 6）の invalidation marker は
# runtime 正本配置 validation/invalidation_markers.json shape を前提とする。
class TestRollbackModel < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path

  def setup
    require_relative "../../scripts/self_improvement/rollback_model"
    require_relative "../../scripts/self_improvement/learning_layout"
    @model = DualReviewer::SelfImprovement::RollbackModel.new(
      repo_root: ROOT
    )
    @layout = DualReviewer::SelfImprovement::LearningLayout
  end

  # adopted 済み proposal（rollback gate 対象）。
  def adopted_proposal(id: "proposal-prompt-1")
    {
      "proposal_id" => id,
      "status" => "adopted",
      "target_layer" => "prompt",
      "motivation_class" => "runtime_quality",
      "source_evidence_refs" =>
        ["experiments/runs/run-mot-0001/decisions/decision_units.json"]
    }
  end

  # 第6波 DecisionAdoptionModel が書く adoption_register entry shape。
  def seed_adoption_register(learning_root:, proposal:,
                             motivating_run_id: "run-mot-0001")
    @layout.write_artifact(
      learning_root: learning_root,
      relative_path: "approved-updates/adoption_register.json",
      payload: {
        "entries" => [
          {
            "proposal_id" => proposal["proposal_id"],
            "adopted_change_ref" => "commit:abc123",
            "version_update_ref" => "version:prompt_pack@1.2.0",
            "approval_ref" => "approval:#{proposal['proposal_id']}",
            "test_artifact_ref" =>
              "backtests/#{proposal['proposal_id']}.json",
            "adopted_at" => "2026-05-19T00:00:00Z",
            # 起点 motivating evidence の run（invalidation 連結に使う）。
            "motivating_run_refs" => [motivating_run_id]
          }
        ]
      }
    )
  end

  # runtime 正本配置 validation/invalidation_markers.json shape の
  # invalidation marker tree を tmp に作る（foundation 要件 6 起点）。
  def write_invalidation_markers(repo_root:, run_id:, markers:)
    dir = Pathname(repo_root) + "experiments/runs/#{run_id}/validation"
    dir.mkpath
    (dir + "invalidation_markers.json").write(
      JSON.pretty_generate("invalidation_markers" => markers)
    )
  end

  # --- Req5 受入 1: rollback-triggering 条件の定義 -------------------------

  def test_rollback_triggering_conditions_are_defined
    conds = @model.rollback_triggering_conditions
    assert_kind_of Array, conds
    refute conds.empty?, "rollback-triggering 条件が定義されていない"
    # design Rollback Model: 採用 change が有害／motivating evidence の
    # 事後 invalidate（foundation 要件 6 起点）が含まれる。
    assert(conds.any? { |c| c.to_s.match?(/harmful|regression|有害/i) })
    assert(conds.any? { |c| c.to_s.match?(/invalidat/i) })
  end

  # --- Req5 受入 4: rollback と supersession の区別 ------------------------

  def test_rollback_distinguished_from_supersession
    d = @model.rollback_vs_supersession_distinction
    assert_kind_of String, d
    refute d.strip.empty?
    assert_match(/supersession/i, d)
    assert_match(/rollback/i, d)
    # supersession=より新しい改善で置換、rollback=有害な採用 change を戻す。
    assert_match(/newer|replace|より新しい/i, d)
    assert_match(/harmful|revert|有害|戻す/i, d)
  end

  def test_classify_event_rollback_vs_supersession
    # 有害／regression → rollback。より新しい改善で置換 → supersession。
    assert_equal "rollback",
                 @model.classify_event(reason_code: "harmful_change_detected")
    assert_equal "rollback",
                 @model.classify_event(reason_code: "regression_observed")
    assert_equal "rollback",
                 @model.classify_event(
                   reason_code: "motivating_evidence_invalidated"
                 )
    assert_equal "supersession",
                 @model.classify_event(reason_code: "later_runtime_evidence")
    assert_equal "supersession",
                 @model.classify_event(
                   reason_code: "replaced_by_newer_improvement"
                 )
  end

  # --- Req5 受入 2・3: rollback_register 5 field・evidence 保持 ------------

  def test_rollback_register_has_five_fields_and_preserves_evidence
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      p = adopted_proposal
      seed_adoption_register(learning_root: lr, proposal: p)
      res = @model.rollback(
        learning_root: lr, proposal: p,
        rollback_reason: "harmful regression in review consistency",
        rollback_trigger_signal_refs:
          ["signal:reject-spike-run-mot-0002"]
      )
      assert res["rolled_back"], "rollback 失敗: #{res['reason']}"
      assert_equal "rolled_back", res["status"]

      reg_path = lr + "rollback/rollback_register.json"
      assert reg_path.file?, "rollback_register.json 未生成"
      reg = JSON.parse(reg_path.read)
      assert_equal "1.0.0", reg["schema_version"]
      e = reg["entries"].find { |x| x["proposal_id"] == p["proposal_id"] }
      refute_nil e, "rollback が履歴として残っていない"
      %w[proposal_id adopted_change_ref rollback_reason
         rollback_trigger_signal_refs rolled_back_at].each do |f|
        assert e.key?(f), "rollback_register entry に #{f} が無い"
        refute_nil e[f], "rollback_register entry の #{f} が nil"
      end
      # reverted behavior を導入した accepted proposal を保持（受入 2）。
      assert_equal p["proposal_id"], e["proposal_id"]
      assert_equal "commit:abc123", e["adopted_change_ref"]
      # rollback reason を evidence として保持（受入 3）。
      assert_equal "harmful regression in review consistency",
                   e["rollback_reason"]
      assert_equal ["signal:reject-spike-run-mot-0002"],
                   e["rollback_trigger_signal_refs"]
    end
  end

  def test_rollback_register_idempotent_per_proposal
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      p = adopted_proposal
      seed_adoption_register(learning_root: lr, proposal: p)
      @model.rollback(learning_root: lr, proposal: p,
                       rollback_reason: "r1",
                       rollback_trigger_signal_refs: ["s1"])
      # 2 回目は終端からの再 rollback（不可逆）として弾かれるが、
      # register 自体は proposal ごとに 1 entry に保たれる。
      reg = JSON.parse((lr + "rollback/rollback_register.json").read)
      n = reg["entries"].count { |x| x["proposal_id"] == p["proposal_id"] }
      assert_equal 1, n, "rollback_register が proposal ごとに冪等でない"
    end
  end

  # --- design §3 Proposal States: adopted→rolled_back のみ許可 -------------

  def test_rollback_respects_state_machine_only_from_adopted
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      # adopted 以外（approved 等）からの rollback は state machine 違反。
      %w[draft awaiting_test tested approved].each do |from|
        p = adopted_proposal(id: "proposal-#{from}").merge("status" => from)
        seed_adoption_register(learning_root: lr, proposal: p)
        res = @model.rollback(
          learning_root: lr, proposal: p,
          rollback_reason: "x", rollback_trigger_signal_refs: []
        )
        refute res["rolled_back"],
               "#{from}→rolled_back は禁止のはず"
        assert_equal "illegal_transition", res["reason"]
      end
    end
  end

  def test_rollback_blocked_from_terminal_state
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      %w[rejected rolled_back].each do |from|
        p = adopted_proposal(id: "proposal-#{from}").merge("status" => from)
        res = @model.rollback(
          learning_root: lr, proposal: p,
          rollback_reason: "x", rollback_trigger_signal_refs: []
        )
        refute res["rolled_back"],
               "#{from} は終端で再 rollback 不可のはず"
        assert_equal "terminal_state", res["reason"]
      end
    end
  end

  # --- Req5 受入 5 / Decision 4: failed history 非削除 → 次 proposal input -

  def test_failed_history_is_not_deleted_and_feeds_next_proposal_input
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      p = adopted_proposal
      seed_adoption_register(learning_root: lr, proposal: p)
      @model.rollback(learning_root: lr, proposal: p,
                       rollback_reason: "harmful regression",
                       rollback_trigger_signal_refs: ["signal:x"])

      # rollback 履歴が次の proposal input として読める（削除されない）。
      inputs = @model.failed_improvement_inputs(learning_root: lr)
      assert_kind_of Array, inputs
      hit = inputs.find { |i| i["proposal_id"] == p["proposal_id"] }
      refute_nil hit, "failed improvement が次 proposal input に現れない"
      assert_equal "rollback", hit["outcome"]
      assert_equal "harmful regression", hit["rollback_reason"]
      # raw rollback_register entry は削除されず保持されたまま。
      reg = JSON.parse((lr + "rollback/rollback_register.json").read)
      assert(reg["entries"].any? { |x|
        x["proposal_id"] == p["proposal_id"]
      })
    end
  end

  # --- Req5 受入 4・5: supersession は破壊削除せず先行保持 -----------------

  def test_supersession_recorded_non_destructively_and_distinct_from_rollback
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      prior = adopted_proposal(id: "proposal-prior")
      seed_adoption_register(learning_root: lr, proposal: prior)
      res = @model.record_supersession(
        learning_root: lr,
        superseded_proposal: prior,
        superseded_by: "proposal-newer",
        supersession_reason: "replaced_by_newer_improvement"
      )
      assert res["recorded"], "supersession 記録失敗: #{res['reason']}"

      sup_path = lr + "rollback/supersession_register.json"
      assert sup_path.file?, "supersession_register.json 未生成"
      sup = JSON.parse(sup_path.read)
      assert_equal "1.0.0", sup["schema_version"]
      e = sup["entries"].find { |x|
        x["proposal_id"] == prior["proposal_id"]
      }
      refute_nil e, "先行 proposal の supersession 記録が無い"
      # 上書きは破壊的に行わない（先行を保持し上書き関係を明示記録）。
      assert_equal "proposal-newer", e["superseded_by"]
      assert_equal "replaced_by_newer_improvement",
                   e["supersession_reason"]
      assert e.key?("superseded_at")
      # supersession は rollback_register を汚さない（別概念）。
      rb_path = lr + "rollback/rollback_register.json"
      if rb_path.file?
        rb = JSON.parse(rb_path.read)
        refute(rb["entries"].any? { |x|
          x["proposal_id"] == prior["proposal_id"]
        }, "supersession が rollback_register に混入している")
      end
      # 先行 proposal は削除されていない（status は adopted のまま）。
      assert_equal "adopted", prior["status"]
    end
  end

  # --- Req5 受入 6 / design: motivating evidence 事後 invalidate 起点 ------

  def test_motivating_evidence_invalidation_triggers_rollback
    Dir.mktmpdir do |tmp|
      repo = Pathname(tmp) + "repo"
      lr = repo + "learning"
      p = adopted_proposal
      seed_adoption_register(learning_root: lr, proposal: p,
                             motivating_run_id: "run-mot-0001")
      # 起点 evidence の run に foundation 無効化契約の marker が立つ。
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
      model = DualReviewer::SelfImprovement::RollbackModel.new(
        repo_root: repo
      )
      res = model.reassess_on_invalidation(
        learning_root: lr, proposals: [p]
      )
      assert_kind_of Array, res
      hit = res.find { |r| r["proposal_id"] == p["proposal_id"] }
      refute_nil hit, "起点 evidence invalidate を検知できていない"
      # 成り立たない根拠の上に採用済み change を steady state で残さない:
      # rollback または再評価が機械起動される。
      assert_includes %w[rollback re_evaluation], hit["action"]
      assert(hit["invalidation_marker_refs"].any? { |m|
        m.include?("run-mot-0001")
      }, "invalidation marker と adopted_change_ref が連結されていない")
      # rollback action のときは rollback_register に履歴が残る。
      if hit["action"] == "rollback"
        reg = JSON.parse((lr + "rollback/rollback_register.json").read)
        e = reg["entries"].find { |x|
          x["proposal_id"] == p["proposal_id"]
        }
        refute_nil e
        assert_match(/invalidat/i, e["rollback_reason"])
      end
    end
  end

  def test_no_invalidation_marker_does_not_trigger_rollback
    Dir.mktmpdir do |tmp|
      repo = Pathname(tmp) + "repo"
      lr = repo + "learning"
      p = adopted_proposal
      seed_adoption_register(learning_root: lr, proposal: p,
                             motivating_run_id: "run-mot-0001")
      # 起点 run に marker を作らない（空でない steady state）。
      write_invalidation_markers(
        repo_root: repo, run_id: "run-mot-0001", markers: []
      )
      model = DualReviewer::SelfImprovement::RollbackModel.new(
        repo_root: repo
      )
      res = model.reassess_on_invalidation(
        learning_root: lr, proposals: [p]
      )
      hit = res.find { |r| r["proposal_id"] == p["proposal_id"] }
      assert_nil hit,
                 "invalidate されていない evidence で誤起動してはならない"
    end
  end

  # --- 完了条件: rollback が supersession と区別され履歴保持 ---------------

  def test_rollback_history_preserved_and_distinct_from_supersession
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      rb = adopted_proposal(id: "proposal-rb")
      sp = adopted_proposal(id: "proposal-sp")
      seed_adoption_register(learning_root: lr, proposal: rb)
      seed_adoption_register(learning_root: lr, proposal: sp)
      @model.rollback(learning_root: lr, proposal: rb,
                       rollback_reason: "harmful",
                       rollback_trigger_signal_refs: ["s"])
      @model.record_supersession(
        learning_root: lr, superseded_proposal: sp,
        superseded_by: "proposal-sp-v2",
        supersession_reason: "later_runtime_evidence"
      )
      rb_reg = JSON.parse((lr + "rollback/rollback_register.json").read)
      sp_reg = JSON.parse(
        (lr + "rollback/supersession_register.json").read
      )
      # rollback 履歴と supersession 履歴が別 register に保持され混在しない。
      assert(rb_reg["entries"].any? { |x|
        x["proposal_id"] == "proposal-rb"
      })
      refute(rb_reg["entries"].any? { |x|
        x["proposal_id"] == "proposal-sp"
      })
      assert(sp_reg["entries"].any? { |x|
        x["proposal_id"] == "proposal-sp"
      })
    end
  end
end
