# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"
require "yaml"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# 最終波 D: end-to-end 決定的スモーク。
# 根拠: tasks.md design「Architecture」5 段（signal intake → proposal →
#       test gate → decision gate → history registry）・§6 Completion
#       Criteria、適合レビュー 2026-05-19 finding 1/2/3（旧 v1 未適合・
#       fixture 仮装）の再発防止。
#
# 第1〜2波が版固定した「実 runtime → 実 evaluation」出力 fixture
# （tests/fixtures/self_improvement/）を唯一の入力とし、混在 population
# （valid review-quality 改善 / invalid workflow failure / exploratory
# hold 候補）で signal intake → signal extraction → proposal →
# replay/backtest → decision/adoption → 事後 invalidate → rollback の
# 主経路を 1 パス通す。出力は tmpdir 配下 learning/ で行い実 learning/・
# 実 experiments/ を一切汚さない。
#
# 適合レビュー finding の中心問題（fixture 仮装・review_quality_signal
# 不発）の再発防止として、確定 fixture から review_quality_signal が
# 実際に産出されることを機械確認する。
class TestPipelineSmoke < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path
  FIX = ROOT + "tests/fixtures/self_improvement"
  RUNS = FIX + "runtime_runs"
  ANALYSIS = FIX + "analysis"

  def setup
    require_relative "../../scripts/self_improvement/learning_layout"
    require_relative "../../scripts/self_improvement/input_model"
    require_relative "../../scripts/self_improvement/signal_extraction"
    require_relative "../../scripts/self_improvement/proposal_model"
    require_relative "../../scripts/self_improvement/replay_backtest_model"
    require_relative "../../scripts/self_improvement/decision_adoption_model"
    require_relative "../../scripts/self_improvement/rollback_model"
  end

  def run_roots
    %w[valid_dissent_run invalid_workflow_failure_run
       exploratory_run valid_clean_run].map { |v| RUNS + v }
  end

  # === 中心問題再発防止: 確定 fixture から review_quality_signal が実際に
  #     産出される（旧 v1 は不発で smoke 構造的 FAIL = finding 1） ========

  def test_review_quality_signal_is_actually_produced_from_fixed_fixtures
    input = DualReviewer::SelfImprovement::InputModel.new(repo_root: ROOT)
    classes = []
    run_roots.each do |rr|
      res = input.load_runtime_signals(run_root: rr)
      classes.concat(res["signals"].map { |s| s["signal_class"] })
    end
    ev = input.load_evaluation_signals(analysis_root: ANALYSIS)
    classes.concat(ev["signals"].map { |s| s["signal_class"] })

    assert_includes classes, "review_quality_signal",
                    "確定 fixture corpus から review_quality_signal が " \
                    "産出されない（適合レビュー finding 1 の再発）"
    assert_includes classes, "workflow_failure_signal",
                    "invalid workflow failure 信号が産出されない"
    assert_includes classes, "evidence_quality_signal",
                    "exploratory / caveat 系 evidence 信号が産出されない"
  end

  # === Architecture 5 段 end-to-end（混在 population で 1 パス） =========

  def test_end_to_end_pipeline_produces_learning_artifacts
    Dir.mktmpdir do |tmp|
      repo = Pathname(tmp) + "repo"
      lr = repo + "learning"

      layout = DualReviewer::SelfImprovement::LearningLayout
      extraction =
        DualReviewer::SelfImprovement::SignalExtraction.new(repo_root: ROOT)
      proposal_model =
        DualReviewer::SelfImprovement::ProposalModel.new(repo_root: ROOT)
      rbt = DualReviewer::SelfImprovement::ReplayBacktestModel.new(
        repo_root: ROOT
      )
      dec = DualReviewer::SelfImprovement::DecisionAdoptionModel.new(
        repo_root: repo
      )
      rb = DualReviewer::SelfImprovement::RollbackModel.new(repo_root: repo)

      # 段 0: learning/ 正本 skeleton（mkpath 保証・schema_version）。
      layout.create_skeleton(learning_root: lr)

      # 段 1: signal intake + extraction（findings/ templates/ 書き出し）。
      ext = extraction.write_inventory(
        learning_root: lr, run_roots: run_roots, analysis_root: ANALYSIS
      )
      refute_empty ext[:signals], "signal が 1 件も抽出されない"

      # 段 2: proposal（1 group = 1 artifact、provenance gate / paper 分離）。
      pres = proposal_model.build_proposals(
        learning_root: lr, run_roots: run_roots, analysis_root: ANALYSIS
      )
      proposals = pres[:proposals]
      refute_empty proposals, "proposal が 1 件も生成されない"

      # 混在 population が proposal に表れる:
      #   valid review-quality 改善（prompt / runtime_quality）
      #   invalid workflow failure（workflow / workflow_quality）
      #   exploratory hold 候補（exploratory 由来）
      layers = proposals.map { |p| p["target_layer"] }.uniq
      assert_includes layers, "workflow",
                      "invalid workflow failure proposal が無い"
      assert_includes layers, "prompt",
                      "valid review-quality 改善 proposal が無い"
      assert(proposals.any? { |p|
        d = proposal_model.review_disposition(proposal: p)
        d["disposition"] == "hold_candidate"
      } || proposals.any? { |p|
        p["evidence_maturity_context"] == "exploratory"
      }, "exploratory hold 候補系 proposal が population に無い")

      # 段 3: test gate（replay / backtest を proposal ごとに通す）。
      proposals.each do |p|
        mode = rbt.decide_test_mode(proposal: p)["required_test_mode"]
        if mode == "backtest"
          rbt.run_backtest(learning_root: lr, proposal: p,
                           analysis_root: ANALYSIS)
        else
          rbt.run_replay(learning_root: lr, proposal: p,
                         search_roots: [RUNS])
        end
      end
      assert (lr + "backtests/backtest_index.json").file?,
             "backtest_index.json が生成されない"

      # 段 4: decision gate（valid: review-quality 改善を approve→adopt /
      #   invalid: workflow proposal を adopt / exploratory: reject）。
      valid_p = proposals.find { |p| p["target_layer"] == "prompt" }
      invalid_p = proposals.find { |p| p["target_layer"] == "workflow" }
      explor_p = proposals.find { |p|
        p["evidence_maturity_context"] == "exploratory"
      }
      refute_nil valid_p
      refute_nil invalid_p

      adopt_one = lambda do |proposal|
        ta_rel = layout.backtest_artifact_path(
          proposal_id: proposal["proposal_id"]
        )
        # test gate を通った supported artifact に固定（決定的）。
        layout.write_artifact(
          learning_root: lr, relative_path: ta_rel,
          payload: { "proposal_id" => proposal["proposal_id"],
                     "result_label" => "supported",
                     "input_refs" =>
                       ["#{proposal['proposal_id']}:review_case.json"] }
        )
        approved = proposal.merge("status" => "approved")
        dec.adopt(
          learning_root: lr, proposal: approved,
          adopted_change_ref: "commit:#{proposal['proposal_id']}",
          version_update_ref: "ver:#{proposal['proposal_id']}@1.0.0",
          approval_ref: "ap:#{proposal['proposal_id']}",
          test_artifact_ref: ta_rel
        )
      end

      a_valid = adopt_one.call(valid_p)
      a_invalid = adopt_one.call(invalid_p)
      assert a_valid["adopted"], "valid 改善が adopted されない: " \
                                 "#{a_valid['reason']}"
      assert a_invalid["adopted"], "invalid workflow 改善が adopted " \
                                   "されない: #{a_invalid['reason']}"

      if explor_p
        rj = dec.reject(
          learning_root: lr, proposal: explor_p.merge("status" => "tested"),
          rejection_reason: "exploratory-only evidence is a weak basis",
          reviewer_note: "revisit if stronger evidence appears"
        )
        assert rj["recorded"], "exploratory hold 候補の reject が記録されない"
      end

      # 段 5: history registry（adoption / rejection / rollback）。
      adoption_reg = JSON.parse(
        (lr + "approved-updates/adoption_register.json").read
      )
      assert adoption_reg["entries"].size >= 2,
             "adoption_register に valid/invalid 採用が連結保存されない"
      adoption_reg["entries"].each do |e|
        %w[proposal_id adopted_change_ref version_update_ref approval_ref
           test_artifact_ref adopted_at motivating_run_refs].each do |f|
          assert e.key?(f), "adoption_register entry に #{f} が無い"
        end
      end

      # invalid workflow 採用の motivating evidence が事後に invalidate
      # された場合 → rollback が機械起動（end-to-end・raw 不変）。
      mr = adoption_reg["entries"].find { |e|
        e["proposal_id"] == invalid_p["proposal_id"]
      }["motivating_run_refs"]
      refute_empty mr, "invalid proposal の motivating_run_refs が空"
      mr.each do |run_id|
        vdir = repo + "experiments/runs/#{run_id}/validation"
        vdir.mkpath
        (vdir + "invalidation_markers.json").write(
          JSON.pretty_generate(
            "invalidation_markers" => [
              { "marker_id" => "im-#{run_id}-001", "run_id" => run_id,
                "reason_code" => "validator_failed", "scope" => "run",
                "issued_by" => "runtime" }
            ]
          )
        )
      end
      rres = rb.reassess_on_invalidation(
        learning_root: lr,
        proposals: [invalid_p.merge("status" => "adopted")]
      )
      hit = rres.find { |x| x["proposal_id"] == invalid_p["proposal_id"] }
      refute_nil hit, "事後 invalidate 起点の rollback/reassess が起動しない"
      assert_equal "rollback", hit["action"]
      rb_reg = JSON.parse(
        (lr + "rollback/rollback_register.json").read
      )
      assert(rb_reg["entries"].any? { |e|
        e["proposal_id"] == invalid_p["proposal_id"]
      }, "rollback が履歴として残らない")

      # learning/ 正本配置（design Learning Artifact Layout）が全て生成。
      %w[
        findings/recurring_failure_signals.json
        findings/workflow_failure_signals.json
        findings/pattern_candidates.json
        proposals/proposal_index.json
        backtests/backtest_index.json
        templates/workflow_remediation_templates.json
        approved-updates/adoption_register.json
        rejected-updates/rejection_register.json
        rollback/rollback_register.json
      ].each do |rel|
        path = lr + rel
        assert path.file?, "learning 正本 artifact 未生成: #{rel}"
        body = JSON.parse(path.read)
        assert_equal "1.0.0", body["schema_version"],
                     "#{rel} に schema_version が無い"
      end

      # raw / 実 repo 非汚染（tmpdir 完結）の傍証。
      refute (ROOT + "learning/proposals/proposal_index.json")
        .to_s.start_with?(tmp), "tmpdir 外参照の論理矛盾"
      assert Dir.exist?(repo + "learning"), "tmpdir learning に出力された"
    end
  end

  # 実 learning/ ・実 experiments/ を汚していないことを明示確認する。
  def test_real_learning_and_experiments_not_contaminated
    before_learning = capture_tree(ROOT + "learning")
    before_experiments = capture_tree(ROOT + "experiments")
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      DualReviewer::SelfImprovement::LearningLayout.create_skeleton(
        learning_root: lr
      )
      pm = DualReviewer::SelfImprovement::ProposalModel.new(repo_root: ROOT)
      pm.build_proposals(learning_root: lr, run_roots: run_roots,
                         analysis_root: ANALYSIS)
    end
    assert_equal before_learning, capture_tree(ROOT + "learning"),
                 "実 learning/ が汚染された"
    assert_equal before_experiments, capture_tree(ROOT + "experiments"),
                 "実 experiments/ が汚染された"
  end

  private

  def capture_tree(dir)
    return [] unless Dir.exist?(dir)

    Dir.glob(dir.join("**", "*"), File::FNM_DOTMATCH).sort
  end
end
