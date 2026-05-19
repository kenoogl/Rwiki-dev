# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"
require "yaml"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 4: proposal model（unit / target layer / state machine / normalization）。
# Task 8: paper narrative 分離の強制。自己改善所有・スクラッチ。
# 根拠: tasks.md Task 4・Task 8、Requirement 2（受入 1〜5）/ Requirement 4
#       受入 1 / Requirement 6（受入 1〜5）、design「Proposal Model §1〜§4」
#       「Separation from Paper Narrative」「Interfaces to Other Features」
#       「Decision 1」。適合レビュー 2026-05-19 finding 1/2/3 解消の品質保証。
#
# 入力は第1〜2波で版固定した実 runtime→実 evaluation 出力 fixture
# （tests/fixtures/self_improvement/）を SignalExtraction 経由で消費する。
# 決定的固定入力→期待出力。出力先は tmpdir（実 learning/ を汚さない）。
class TestProposalModel < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path
  FIX = ROOT + "tests/fixtures/self_improvement"
  RUNS = FIX + "runtime_runs"
  ANALYSIS = FIX + "analysis"

  def setup
    require_relative "../../scripts/self_improvement/proposal_model"
    @model = DualReviewer::SelfImprovement::ProposalModel.new(repo_root: ROOT)
  end

  def all_run_roots
    %w[valid_dissent_run invalid_workflow_failure_run
       exploratory_run valid_clean_run].map { |v| RUNS + v }
  end

  def build_all(learning_root:)
    @model.build_proposals(
      learning_root: learning_root,
      run_roots: all_run_roots, analysis_root: ANALYSIS
    )
  end

  # --- design §1 / Req2 受入 1: proposal unit（1 改善仮説 = 1 artifact） -----

  def test_proposal_is_one_artifact_per_hypothesis_with_required_fields
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      res = build_all(learning_root: lr)
      proposals = res[:proposals]
      refute_empty proposals

      # 1 proposal group = 1 proposal artifact（Decision 1）。
      groups = @model.signal_proposal_groups(
        run_roots: all_run_roots, analysis_root: ANALYSIS
      )
      assert_equal groups.size, proposals.size,
                   "proposal group と proposal artifact が 1:1 でない"

      required = %w[
        proposal_id status target_layer motivation_class
        source_evidence_refs source_origin source_repository_refs
        source_admission_refs problem_statement proposed_change_summary
        expected_benefit possible_risks required_test_mode created_at
      ]
      proposals.each do |p|
        required.each do |f|
          assert p.key?(f), "proposal に必須 field #{f} が無い: #{p['proposal_id']}"
        end
        # 各 proposal が <proposal_id>.yaml として正本パスに書かれる。
        ypath = lr + "proposals/#{p['proposal_id']}.yaml"
        assert ypath.file?, "proposals/<id>.yaml 未生成: #{p['proposal_id']}"
        loaded = YAML.safe_load(ypath.read)
        assert_equal p["proposal_id"], loaded["proposal_id"]
      end
    end
  end

  # proposal_index.json が schema_version 付きで正本パスに書かれる。
  def test_proposal_index_written_with_schema_version
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      build_all(learning_root: lr)
      idx_path = lr + "proposals/proposal_index.json"
      assert idx_path.file?, "proposals/proposal_index.json 未生成"
      idx = JSON.parse(idx_path.read)
      assert_equal "1.0.0", idx["schema_version"]
      refute_empty idx["entries"]
      idx["entries"].each do |e|
        %w[proposal_id status target_layer motivation_class].each do |f|
          assert e.key?(f), "index entry に #{f} が無い"
        end
      end
    end
  end

  # --- design §2 / Req2 受入 2: target_layer enum --------------------------

  def test_target_layer_enum_is_design_canonical
    assert_equal %w[policy prompt runtime schema workflow],
                 @model.target_layers.sort
  end

  def test_source_origin_enum_is_design_canonical
    assert_equal %w[central_local_run imported_external_bundle
                     manual_review_record],
                 @model.source_origins.sort
  end

  # 各 proposal の target_layer が enum 内であり曖昧でない（Req2 受入 2）。
  def test_each_proposal_target_layer_within_enum
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      res = build_all(learning_root: lr)
      res[:proposals].each do |p|
        assert_includes @model.target_layers, p["target_layer"],
                        "target_layer が enum 外: #{p['target_layer']}"
        assert_includes @model.source_origins, p["source_origin"]
      end
    end
  end

  # workflow_failure 由来は workflow layer、review_quality 由来は prompt、
  # evidence_quality 由来は schema に決定的に分類される（曖昧にしない）。
  def test_target_layer_derived_deterministically_from_signal_class
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      res = build_all(learning_root: lr)
      by_surface = res[:proposals].each_with_object({}) do |p, acc|
        acc[p["proposal_id"]] = p
      end
      coupled = by_surface.values.find do |p|
        p["normalization_kind"] == "coupled_workflow"
      end
      refute_nil coupled, "coupled_workflow proposal が無い"
      assert_equal "workflow", coupled["target_layer"]
      assert_equal "workflow_quality", coupled["motivation_class"]

      dissent = by_surface.values.find do |p|
        Array(p["source_signal_codes"]).include?("human_decision_dissent")
      end
      refute_nil dissent, "review-quality dissent proposal が無い"
      assert_equal "prompt", dissent["target_layer"]
      assert_equal "runtime_quality", dissent["motivation_class"]
    end
  end

  # --- design §1 / Req8: imported provenance refs を保持 -------------------

  def test_imported_provenance_refs_preserved_on_proposal
    # imported external bundle 由来 signal から proposal を作ると
    # source_repository_refs / source_admission_refs / source_origin が
    # 保持される（Requirement 8 受入 1〜3、design §1）。
    signal = {
      "signal_id" => "imported:bundle-x:run-imp-1:rejected_finding_cluster",
      "signal_class" => "review_quality_signal",
      "signal_code" => "rejected_finding_cluster",
      "signal_source" => "evaluation",
      "run_id" => "run-imp-1",
      "evidence_maturity" => "valid",
      "source_refs" => ["metrics/run_metrics.json#run-imp-1"],
      "source_origin" => "imported_external_bundle",
      "_metadata" => { "source_repository_id" => "kenoogl/Rwiki-dev",
                       "source_revision" => "abc1234",
                       "review_mode" => "runtime_mediated" },
      "imported_provenance" => {
        "source_origin" => "imported_external_bundle",
        "source_repository_id" => "kenoogl/Rwiki-dev",
        "source_revision" => "abc1234",
        "admission_status" => "admitted_standard",
        "provenance_complete" => true
      }
    }
    group = {
      "normalization_kind" => "single_signal",
      "run_id" => "run-imp-1",
      "member_signal_codes" => ["rejected_finding_cluster"],
      "member_signal_ids" => [signal["signal_id"]],
      "source_evidence_refs" =>
        ["findings/recurring_failure_signals.json#sig-low_acceptance_ratio"]
    }
    p = @model.build_proposal_from_group(group: group, signals: [signal])
    assert_equal "imported_external_bundle", p["source_origin"]
    assert_equal [{ "source_repository_id" => "kenoogl/Rwiki-dev",
                    "source_revision" => "abc1234",
                    "run_id" => "run-imp-1" }],
                 p["source_repository_refs"]
    refute_empty p["source_admission_refs"]
    assert_equal "admitted_standard",
                 p["source_admission_refs"].first["admission_status"]
  end

  # provenance 欠落 signal からは proposal を生成しない（Req1 受入 6 接続）。
  def test_proposal_not_generated_when_provenance_missing
    bad_signal = {
      "signal_id" => "runtime::human_decision_dissent",
      "signal_class" => "review_quality_signal",
      "signal_code" => "human_decision_dissent",
      "signal_source" => "runtime",
      "run_id" => nil,
      "evidence_maturity" => "valid",
      "source_refs" => []
    }
    group = {
      "normalization_kind" => "single_signal", "run_id" => nil,
      "member_signal_codes" => ["human_decision_dissent"],
      "member_signal_ids" => [bad_signal["signal_id"]],
      "source_evidence_refs" => []
    }
    p = @model.build_proposal_from_group(group: group, signals: [bad_signal])
    assert_nil p, "provenance 欠落でも proposal を生成している"
  end

  # --- design §3 / Req4 受入 1: proposal state machine ---------------------

  def test_state_enum_is_design_canonical
    assert_equal %w[adopted approved awaiting_test draft rejected
                     rolled_back tested],
                 @model.proposal_states.sort
  end

  # 許可遷移（design §3 正本どおり）はすべて通る。
  def test_allowed_transitions_pass
    allowed = [
      %w[draft awaiting_test],
      %w[draft rejected],
      %w[awaiting_test tested],
      %w[tested approved],
      %w[tested rejected],
      %w[approved adopted],
      %w[approved rejected],
      %w[adopted rolled_back]
    ]
    allowed.each do |from, to|
      res = @model.transition(from: from, to: to)
      assert res["allowed"], "許可遷移 #{from}→#{to} が拒否された"
      assert_equal to, res["status"]
    end
  end

  # 不許可遷移は state machine で禁止される（draft→adopted 直行等）。
  def test_disallowed_transitions_are_blocked
    disallowed = [
      %w[draft adopted],          # 直行禁止
      %w[draft tested],
      %w[draft approved],
      %w[awaiting_test approved], # test を飛ばせない
      %w[awaiting_test adopted],
      %w[tested adopted],         # approval を飛ばせない
      %w[approved rolled_back],   # adopt 前は rollback 不可
      %w[adopted approved],       # adopted から approved へ戻れない
      %w[adopted adopted]
    ]
    disallowed.each do |from, to|
      res = @model.transition(from: from, to: to)
      refute res["allowed"], "不許可遷移 #{from}→#{to} を通している"
      assert_equal "illegal_transition", res["reason"]
    end
  end

  # 終端状態（rejected / rolled_back）からは一切遷移できない（不可逆）。
  def test_terminal_states_are_irreversible
    assert_equal %w[rejected rolled_back], @model.terminal_states.sort
    @model.proposal_states.each do |target|
      r1 = @model.transition(from: "rejected", to: target)
      refute r1["allowed"], "終端 rejected→#{target} を通している"
      assert_equal "terminal_state", r1["reason"]
      r2 = @model.transition(from: "rolled_back", to: target)
      refute r2["allowed"], "終端 rolled_back→#{target} を通している"
      assert_equal "terminal_state", r2["reason"]
    end
  end

  # 生成直後の proposal は draft（state machine 起点）。
  def test_built_proposals_start_in_draft
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      res = build_all(learning_root: lr)
      res[:proposals].each do |p|
        assert_equal "draft", p["status"]
      end
    end
  end

  # --- Req2 受入 5: accepted / rejected を first-class record として保持 ----

  def test_accepted_and_rejected_proposals_are_first_class_records
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      res = build_all(learning_root: lr)
      # accepted は採否判断であり design §3 では tested→approved のみ。
      # draft→approved 直行は不許可（test_record_decision_respects_state_
      # machine が別途検証）。ここでは legal path で tested まで進めた
      # proposal を accepted し first-class record 化を検証する。
      p = res[:proposals].first.dup
      p["status"] = "tested"

      acc = @model.record_decision(
        learning_root: lr, proposal: p, decision: "accepted",
        note: "approved by reviewer"
      )
      assert acc["recorded"]
      assert_equal "approved", acc["status"]
      idx = JSON.parse((lr + "proposals/proposal_index.json").read)
      entry = idx["entries"].find { |e| e["proposal_id"] == p["proposal_id"] }
      assert_equal "approved", entry["status"],
                   "accepted proposal が first-class に反映されない"

      q = res[:proposals].last
      rej = @model.record_decision(
        learning_root: lr, proposal: q, decision: "rejected",
        note: "duplicate hypothesis"
      )
      assert rej["recorded"]
      assert_equal "rejected", rej["status"]
      idx2 = JSON.parse((lr + "proposals/proposal_index.json").read)
      e2 = idx2["entries"].find { |e| e["proposal_id"] == q["proposal_id"] }
      assert_equal "rejected", e2["status"],
                   "rejected proposal が invisible discard になっている"
    end
  end

  # accepted/rejected の record は不正遷移を許さない（draft→accepted は
  # 直行不可。draft からは awaiting_test か rejected のみ）。
  def test_record_decision_respects_state_machine
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      res = build_all(learning_root: lr)
      p = res[:proposals].first.dup
      p["status"] = "draft"
      r = @model.record_decision(
        learning_root: lr, proposal: p, decision: "accepted", note: "x"
      )
      refute r["recorded"],
             "draft から直接 accepted(approved) を許している"
      assert_equal "illegal_transition", r["reason"]
    end
  end

  # --- design §4: review prioritization notes ------------------------------

  def test_review_prioritization_workflow_over_schema_over_prompt
    proposals = [
      { "proposal_id" => "p-prompt", "target_layer" => "prompt",
        "motivation_class" => "runtime_quality",
        "evidence_maturity_context" => "valid" },
      { "proposal_id" => "p-workflow", "target_layer" => "workflow",
        "motivation_class" => "workflow_quality",
        "evidence_maturity_context" => "invalid" },
      { "proposal_id" => "p-schema", "target_layer" => "schema",
        "motivation_class" => "evidence_quality",
        "evidence_maturity_context" => "valid" }
    ]
    ordered = @model.prioritize_review(proposals: proposals)
    ids = ordered.map { |p| p["proposal_id"] }
    assert_equal %w[p-workflow p-schema p-prompt], ids,
                 "design §4 優先順 workflow>schema/evidence>prompt/policy " \
                 "に従っていない"
  end

  # exploratory-only 由来の prompt/policy proposal は hold 候補。
  def test_exploratory_only_prompt_proposal_is_hold_candidate
    p = { "proposal_id" => "p-x", "target_layer" => "prompt",
          "motivation_class" => "runtime_quality",
          "evidence_maturity_context" => "exploratory" }
    note = @model.review_disposition(proposal: p)
    assert_equal "hold_candidate", note["disposition"]
    assert_equal "exploratory_only_evidence", note["reason"]
  end

  # comparison impossibility 系 caveat を cautionary caveat より先に
  # review してよい（design §4）。
  def test_comparison_impossibility_caveat_reviewed_before_cautionary
    proposals = [
      { "proposal_id" => "p-low-sample", "target_layer" => "schema",
        "motivation_class" => "evidence_quality",
        "caveat_code" => "low_sample_size" },
      { "proposal_id" => "p-single-treatment", "target_layer" => "schema",
        "motivation_class" => "evidence_quality",
        "caveat_code" => "single_treatment_only" }
    ]
    ordered = @model.prioritize_review(proposals: proposals)
    assert_equal "p-single-treatment", ordered.first["proposal_id"],
                 "comparison impossibility caveat が cautionary より後"
  end

  # --- Task 8 / Req6 受入 1: paper convenience 単独で runtime-affecting 不可 -

  def test_paper_motivation_class_enum_excludes_paper_convenience
    # motivation_class enum は runtime/workflow/evidence quality のみ。
    assert_equal %w[evidence_quality runtime_quality workflow_quality],
                 @model.motivation_classes.sort
  end

  def test_paper_convenience_alone_blocks_runtime_affecting_proposal
    # 表整形のため runtime field を変える / 論文都合で exploratory を valid
    # 扱い等は禁止（design Separation from Paper Narrative）。
    %w[prompt policy schema runtime workflow].each do |layer|
      res = @model.paper_separation_gate(
        target_layer: layer,
        motivation_class: "paper_convenience",
        motivation_evidence_refs: ["paper/table_layout_note.md"]
      )
      refute res["allowed"],
             "paper convenience 単独で runtime-affecting #{layer} を通した"
      assert_equal "paper_convenience_not_sufficient", res["reason"]
    end
  end

  # report-layer caveat handling は runtime-layer improvement と区別される
  # （Req6 受入 2）。report-layer は self-improvement proposal の対象外。
  def test_report_layer_caveat_handling_distinguished_from_runtime
    res = @model.paper_separation_gate(
      target_layer: "report",
      motivation_class: "evidence_quality",
      motivation_evidence_refs: ["caveats/caveat_register.json#x"]
    )
    refute res["allowed"],
           "report-layer を runtime-affecting proposal として通した"
    assert_equal "report_layer_not_runtime_affecting", res["reason"]
  end

  # 改善 motivation が runtime/workflow/evidence quality のどれかを保持する
  # （Req6 受入 3）。enum 外（paper 由来）は proposal 生成で阻止される。
  def test_proposal_motivation_layer_is_preserved_and_constrained
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      res = build_all(learning_root: lr)
      res[:proposals].each do |p|
        assert_includes @model.motivation_classes, p["motivation_class"],
                        "motivation_class が layer 区別 enum 外: " \
                        "#{p['motivation_class']}"
      end
    end
  end

  # narrative-driven change を steady-state behavior に入れない（受入 4）:
  # paper motivation の signal を渡しても proposal は生成されない。
  def test_narrative_driven_change_does_not_enter_steady_state
    narrative_signal = {
      "signal_id" => "paper:narrative-1",
      "signal_class" => "paper_narrative_signal",
      "signal_code" => "paper_table_layout_pressure",
      "signal_source" => "paper",
      "run_id" => "run-x",
      "evidence_maturity" => "valid",
      "source_refs" => ["paper/methodology_note.md"]
    }
    group = {
      "normalization_kind" => "single_signal", "run_id" => "run-x",
      "member_signal_codes" => ["paper_table_layout_pressure"],
      "member_signal_ids" => [narrative_signal["signal_id"]],
      "source_evidence_refs" => ["paper/methodology_note.md"]
    }
    p = @model.build_proposal_from_group(
      group: group, signals: [narrative_signal]
    )
    assert_nil p,
               "narrative-driven change が proposal として steady-state に入った"
  end

  # --- Task 8 / Req6 受入 5: external evidence intake は将来互換（任意） ----

  def test_external_evidence_intake_not_required_in_initial_rebuild
    # imported_external_bundle 由来が無くても基本 flow が成立する
    # （初期 rebuild で external intake を必須にしない）。
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      res = build_all(learning_root: lr)
      origins = res[:proposals].map { |p| p["source_origin"] }.uniq
      assert_includes origins, "central_local_run"
      refute_empty res[:proposals],
                   "external intake 不在で基本 flow が壊れる"
    end
  end

  # build_proposals は冪等（同入力で同 proposal 集合）。
  def test_build_proposals_is_idempotent
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      a = build_all(learning_root: lr)[:proposals].map { |p| p["proposal_id"] }
      b = build_all(learning_root: lr)[:proposals].map { |p| p["proposal_id"] }
      assert_equal a.sort, b.sort, "build_proposals が冪等でない"
    end
  end
end
