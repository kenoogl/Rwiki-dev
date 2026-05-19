# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"
require "yaml"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 5: replay / backtest model（自己改善所有・スクラッチ）。
# 根拠: tasks.md Task 5、Requirement 3（受入 1〜7）、
#       design「Replay and Backtest Model §1〜§4」、
#       foundation `runtime/foundation/metadata_contract.yaml`（要件 6）。
#       適合レビュー 2026-05-19 finding 1/2/3 解消の品質保証対象。
#
# 入力は第1〜2波で版固定した実 runtime→実 evaluation 出力 fixture
# （tests/fixtures/self_improvement/）を第4波 ProposalModel 経由で消費する。
# 決定的固定入力→期待出力。出力先は tmpdir（実 learning/・experiments/ を
# 汚さない）。run root 解決は fixture 名/固定 path 列挙に依存せず
# run_manifest.yaml + run_id を canonical anchor とする manifest-based
# discovery で検証する（replay readiness false negative 防止）。
class TestReplayBacktestModel < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path
  FIX = ROOT + "tests/fixtures/self_improvement"
  RUNS = FIX + "runtime_runs"
  ANALYSIS = FIX + "analysis"

  def setup
    require_relative "../../scripts/self_improvement/replay_backtest_model"
    require_relative "../../scripts/self_improvement/proposal_model"
    @model = DualReviewer::SelfImprovement::ReplayBacktestModel.new(
      repo_root: ROOT
    )
    @proposals = DualReviewer::SelfImprovement::ProposalModel.new(
      repo_root: ROOT
    )
  end

  def all_run_roots
    %w[valid_dissent_run invalid_workflow_failure_run
       exploratory_run valid_clean_run].map { |v| RUNS + v }
  end

  def build_proposals(learning_root:)
    @proposals.build_proposals(
      learning_root: learning_root,
      run_roots: all_run_roots, analysis_root: ANALYSIS
    )[:proposals]
  end

  def prompt_proposal
    { "proposal_id" => "p-prompt-1", "target_layer" => "prompt",
      "status" => "draft", "source_origin" => "central_local_run",
      "evidence_maturity_context" => "valid",
      "source_evidence_refs" => ["finding:s1"],
      "source_signal_codes" => %w[human_decision_dissent],
      "possible_risks" => ["No special risk flagged at proposal generation time."] }
  end

  def schema_proposal
    { "proposal_id" => "p-schema-1", "target_layer" => "schema",
      "status" => "draft", "source_origin" => "central_local_run",
      "evidence_maturity_context" => "valid",
      "source_evidence_refs" => ["finding:s2"],
      "source_signal_codes" => %w[unresolved_judgment_labels],
      "possible_risks" => ["No special risk flagged at proposal generation time."] }
  end

  def workflow_proposal
    { "proposal_id" => "p-workflow-1", "target_layer" => "workflow",
      "status" => "draft", "source_origin" => "central_local_run",
      "evidence_maturity_context" => "invalid",
      "source_evidence_refs" => ["finding:s3"],
      "source_signal_codes" => %w[validator_failed],
      "possible_risks" => ["May optimize for invalid-run cleanup."] }
  end

  # --- design §1 / Req3 受入 1・6: test mode を 3 要素で判定 -----------------

  def test_test_mode_decided_by_three_components
    d = @model.decide_test_mode(proposal: schema_proposal)
    assert_equal "backtest", d["required_test_mode"]
    # 3 要素（変更規模 / リスク水準 / 対象レイヤー）が判定根拠に明示される。
    %w[change_scope risk_level target_layer].each do |c|
      assert d["criteria"].key?(c),
             "test mode 判定根拠に #{c} が無い"
    end
    assert_equal "schema", d["criteria"]["target_layer"]
  end

  def test_replay_required_for_step_b_c_behavior_layers
    # prompt/policy/runtime は Step B・Step C 挙動に関わるため step-level
    # replay 必須（design §2）。
    %w[prompt policy runtime].each do |layer|
      p = prompt_proposal.merge("target_layer" => layer,
                                "proposal_id" => "p-#{layer}")
      d = @model.decide_test_mode(proposal: p)
      assert_equal "replay", d["required_test_mode"],
                   "#{layer} は replay 必須のはず"
      assert d["step_level_replay_required"],
             "#{layer} は step-level replay 必須のはず"
    end
  end

  def test_schema_uses_backtest_workflow_uses_manual_review
    assert_equal "backtest",
                 @model.decide_test_mode(proposal: schema_proposal)["required_test_mode"]
    assert_equal "manual_review",
                 @model.decide_test_mode(proposal: workflow_proposal)["required_test_mode"]
  end

  def test_exploratory_evidence_raises_risk_level
    p = prompt_proposal.merge("evidence_maturity_context" => "exploratory")
    d = @model.decide_test_mode(proposal: p)
    assert_equal "high", d["criteria"]["risk_level"]
    # 高リスクでも layer 判定は維持（prompt → replay）。
    assert_equal "replay", d["required_test_mode"]
  end

  # --- design §2: manifest-based run root discovery（false negative 防止） ---

  def test_run_root_resolved_by_manifest_run_id_not_fixture_name
    # fixture 名や固定 path 列挙に依存せず run_manifest.yaml の run_id を
    # canonical anchor として解決する。
    resolved = @model.resolve_run_root(
      run_id: "run-si-valid-clean-0001",
      search_roots: [RUNS]
    )
    refute_nil resolved
    assert (Pathname(resolved) + "run_manifest.yaml").file?
    md = YAML.safe_load((Pathname(resolved) + "run_manifest.yaml").read)
    assert_equal "run-si-valid-clean-0001", md["metadata"]["run_id"]
    # ディレクトリ名は valid_clean_run であり run_id とは一致しない。
    refute_equal "run-si-valid-clean-0001", Pathname(resolved).basename.to_s
  end

  def test_run_root_discovery_no_false_negative_for_all_fixtures
    {
      "run-si-valid-clean-0001" => "valid_clean_run",
      "run-si-invalid-workflow-0001" => "invalid_workflow_failure_run",
      "run-si-valid-dissent-0001" => "valid_dissent_run"
    }.each do |run_id, dirname|
      resolved = @model.resolve_run_root(run_id: run_id,
                                         search_roots: [RUNS])
      refute_nil resolved, "#{run_id} の run root が解決できない"
      assert_equal dirname, Pathname(resolved).basename.to_s
    end
  end

  def test_unknown_run_id_resolves_to_nil_not_raise
    assert_nil @model.resolve_run_root(run_id: "run-does-not-exist",
                                       search_roots: [RUNS])
  end

  # --- design §2: replay 最低入力 -------------------------------------------

  def test_replay_minimum_inputs_present_for_valid_run
    rd = @model.replay_readiness(run_id: "run-si-valid-clean-0001",
                                 search_roots: [RUNS],
                                 step_level_required: true)
    assert rd["ready"], "replay readiness が false: #{rd['missing']}"
    refs = rd["input_refs"]
    assert(refs.any? { |r| r.include?("review_case.json") })
    assert(refs.any? { |r| r.include?("decisions/decision_units.json") })
    assert(refs.any? { |r| r.include?("validation/validator_result.json") })
    assert(refs.any? { |r| r.include?("validation/invalidation_markers.json") })
    assert(refs.any? { |r| r.include?("run_manifest.yaml") })
    # Step B / Step C step-level replay 必須。
    assert(refs.any? { |r| r.include?("steps/step_b") })
    assert(refs.any? { |r| r.include?("steps/step_c") })
  end

  def test_replay_optional_v2_absence_does_not_break_readiness
    # v2/trace_note.json・v2/signal_linkage_note.json は optional。
    # fixture には存在しないが readiness は false negative にならない。
    rd = @model.replay_readiness(run_id: "run-si-valid-clean-0001",
                                 search_roots: [RUNS],
                                 step_level_required: true)
    assert rd["ready"]
    assert_kind_of Array, rd["optional_missing"]
    assert(rd["optional_missing"].any? { |m| m.include?("trace_note") })
  end

  def test_replay_unresolvable_run_root_reports_not_ready
    rd = @model.replay_readiness(run_id: "run-absent",
                                 search_roots: [RUNS],
                                 step_level_required: true)
    refute rd["ready"]
    assert_includes rd["missing"], "run_root_unresolved"
  end

  # --- design §3: backtest 最低入力 -----------------------------------------

  def test_backtest_minimum_inputs_present
    bd = @model.backtest_readiness(analysis_root: ANALYSIS)
    assert bd["ready"], "backtest readiness が false: #{bd['missing']}"
    refs = bd["input_refs"]
    assert(refs.any? { |r| r.include?("run_classification_index.json") })
    assert(refs.any? { |r| r.include?("run_metrics.json") })
    assert(refs.any? { |r| r.include?("finding_metrics.json") })
    assert(refs.any? { |r| r.include?("caveat_register.json") })
  end

  def test_backtest_missing_required_input_reports_not_ready
    Dir.mktmpdir do |tmp|
      empty = Pathname(tmp) + "analysis"
      empty.mkpath
      bd = @model.backtest_readiness(analysis_root: empty)
      refute bd["ready"]
      refute_empty bd["missing"]
    end
  end

  # --- design §4: test result artifact 9 field + foundation 束縛 ------------

  def test_result_artifact_has_required_fields_and_foundation_binding
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      art = @model.run_backtest(
        learning_root: lr, proposal: schema_proposal,
        analysis_root: ANALYSIS
      )
      required = %w[
        proposal_id test_mode input_refs input_origin_refs result_label
        observed_effect risk_observations tested_at
        foundation_run_metadata_ref
      ]
      required.each do |f|
        assert art.key?(f), "result artifact に必須 field #{f} が無い"
      end
      # 正本パス learning/backtests/<proposal_id>.json に書かれる。
      path = lr + "backtests/#{schema_proposal['proposal_id']}.json"
      assert path.file?, "learning/backtests/<id>.json 未生成"
      loaded = JSON.parse(path.read)
      assert loaded["schema_version"], "result artifact に schema_version 無し"
      assert_equal schema_proposal["proposal_id"], loaded["proposal_id"]
      # foundation 実行メタデータ契約に束縛（要件 3 受入 7）。
      fref = art["foundation_run_metadata_ref"]
      assert_kind_of Hash, fref
      assert_equal "runtime/foundation/metadata_contract.yaml",
                   fref["contract_path"]
      assert_equal "1.0.0", fref["contract_version"]
    end
  end

  def test_result_artifact_is_separate_from_raw_run_evidence
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      @model.run_replay(
        learning_root: lr,
        proposal: prompt_proposal.merge("run_id" => "run-si-valid-clean-0001"),
        search_roots: [RUNS]
      )
      # raw run evidence（fixture）を mutate しない。
      raw = RUNS + "valid_clean_run" + "review_case.json"
      assert raw.file?
      # 別 artifact として learning/backtests 下に保持（受入 3）。
      out = lr + "backtests/#{prompt_proposal['proposal_id']}.json"
      assert out.file?
      refute_equal raw.to_s, out.to_s
    end
  end

  def test_result_label_enum_enforced
    assert_equal %w[supported unsupported inconclusive untested].sort,
                 @model.result_labels.sort
  end

  # --- Req3 受入 4: unsupported と untested を区別 --------------------------

  def test_untested_distinct_from_unsupported
    # 検証未実施 → untested（awaiting_test→tested 遷移条件を満たさない）。
    untested = @model.untested_result(proposal: schema_proposal)
    assert_equal "untested", untested["result_label"]
    # untested は tested 遷移を許可しない（design §4 / Task 5 完了条件）。
    refute @model.satisfies_tested_transition?(result: untested)

    # 実検証で証跡不十分 → unsupported（untested とは別概念）。
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      art = @model.run_backtest(learning_root: lr, proposal: schema_proposal,
                                analysis_root: ANALYSIS)
      refute_equal "untested", art["result_label"]
      assert @model.satisfies_tested_transition?(result: art),
             "実検証完了 result は tested 遷移を満たすべき"
    end
  end

  def test_anecdotal_plausibility_not_equivalent_to_backtest_evidence
    # 逸話的尤もらしさ（証跡 ref なし）は backtest evidence と等価扱いしない。
    res = @model.evaluate_anecdotal(proposal: schema_proposal,
                                    anecdote: "seems plausible")
    assert_equal "untested", res["result_label"]
    refute res["counts_as_backtest_evidence"]
  end

  # --- Req3 / design §2: imported provenance を result artifact に残す ------

  def test_imported_provenance_preserved_in_result_artifact
    imported = schema_proposal.merge(
      "proposal_id" => "p-imported-1",
      "source_origin" => "imported_external_bundle",
      "source_repository_refs" => [
        { "source_repository_id" => "kenoogl/Rwiki-dev",
          "source_revision" => "0943943", "run_id" => "run-fixture-001" }
      ],
      "source_admission_refs" => [
        { "run_id" => "run-fixture-001",
          "admission_status" => "admitted_standard" }
      ]
    )
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      art = @model.run_backtest(learning_root: lr, proposal: imported,
                                analysis_root: ANALYSIS)
      origin = art["input_origin_refs"]
      assert_equal "imported_external_bundle", origin["source_origin"]
      assert(origin["source_repository_refs"].any? do |r|
        r["source_repository_id"] == "kenoogl/Rwiki-dev" &&
          r["source_revision"] == "0943943"
      end)
      assert(origin["source_admission_refs"].any? do |r|
        r["admission_status"] == "admitted_standard"
      end)
    end
  end

  # --- Task 5 完了条件: untested と awaiting_test→tested 整合 ----------------

  def test_untested_blocks_awaiting_test_to_tested_transition
    untested = @model.untested_result(proposal: prompt_proposal)
    g = @model.tested_transition_guard(
      proposal: prompt_proposal.merge("status" => "awaiting_test"),
      result: untested
    )
    refute g["allowed"]
    assert_equal "result_untested", g["reason"]
  end

  def test_completed_result_allows_awaiting_test_to_tested_transition
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      art = @model.run_backtest(learning_root: lr, proposal: schema_proposal,
                                analysis_root: ANALYSIS)
      g = @model.tested_transition_guard(
        proposal: schema_proposal.merge("status" => "awaiting_test"),
        result: art
      )
      assert g["allowed"], "完了 result は tested 遷移を許可すべき: #{g['reason']}"
    end
  end

  # --- ProposalModel との結合: 第4波 proposal を本波で詳細化 ----------------

  def test_proposal_required_test_mode_refined_by_three_factor
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      proposals = build_proposals(learning_root: lr)
      refute_empty proposals
      proposals.each do |p|
        d = @model.decide_test_mode(proposal: p)
        assert_includes %w[replay backtest manual_review],
                        d["required_test_mode"]
        # 3 要素判定根拠が常に提示される。
        %w[change_scope risk_level target_layer].each do |c|
          assert d["criteria"].key?(c)
        end
      end
    end
  end

  def test_backtest_index_records_each_artifact
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      @model.run_backtest(learning_root: lr, proposal: schema_proposal,
                          analysis_root: ANALYSIS)
      idx = lr + "backtests/backtest_index.json"
      assert idx.file?, "backtest_index.json 未生成"
      data = JSON.parse(idx.read)
      assert data["schema_version"]
      assert(Array(data["entries"]).any? do |e|
        e["proposal_id"] == schema_proposal["proposal_id"]
      end)
    end
  end
end
