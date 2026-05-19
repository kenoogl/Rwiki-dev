# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"
require "yaml"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 2: input model（3 class・valid/invalid/exploratory・provenance 必須・
# manual→runtime handoff・imported provenance）。自己改善所有。
# 根拠: tasks.md Task 2、Requirement 1（受入 1〜6）/ Requirement 7（受入
#       1〜5）/ Requirement 8（受入 1〜5）、design「Input Model §1〜§2.5」
#       「v2 Supporting Inputs」「Signal Extraction Model §1〜§2」。
#       適合レビュー 2026-05-19 finding 1/2/3 解消を独立検証する。
#
# 入力は第1波で版固定した実 runtime→実 evaluation 出力 fixture
# （tests/fixtures/self_improvement/）。決定的固定入力→期待出力。
class TestInputModel < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path
  FIX = ROOT + "tests/fixtures/self_improvement"
  RUNS = FIX + "runtime_runs"
  ANALYSIS = FIX + "analysis"

  def setup
    require_relative "../../scripts/self_improvement/input_model"
    @intake = DualReviewer::SelfImprovement::InputModel.new(repo_root: ROOT)
  end

  # --- Requirement 1 受入 1・2 / design §1: 3 input class ---------------------

  def test_defines_three_input_classes
    assert_equal %w[evidence_quality_signal review_quality_signal
                     workflow_failure_signal],
                 @intake.input_classes.sort
  end

  # review-quality vs workflow-failure 弁別（受入 2）。実 fixture corpus で
  # review_quality_signal が産出される（finding 1 解消＝旧 v1 は不発だった）。
  def test_runtime_dissent_run_yields_review_quality_signal
    res = @intake.load_runtime_signals(
      run_root: RUNS + "valid_dissent_run"
    )
    classes = res["signals"].map { |s| s["signal_class"] }
    assert_includes classes, "review_quality_signal",
                    "実 dissent fixture から review_quality_signal が出ない"
    rq = res["signals"].find do |s|
      s["signal_class"] == "review_quality_signal"
    end
    assert_equal "valid", rq["evidence_maturity"]
  end

  # evaluation 経路でも review_quality_signal（rejected_finding_cluster）が
  # 現行確定 fixture corpus で産出される（finding 1 解消）。
  def test_evaluation_signals_include_review_quality_from_rejected_cluster
    res = @intake.load_evaluation_signals(analysis_root: ANALYSIS)
    codes = res["signals"].map { |s| s["signal_code"] }
    assert_includes codes, "rejected_finding_cluster"
    rq = res["signals"].find do |s|
      s["signal_code"] == "rejected_finding_cluster"
    end
    assert_equal "review_quality_signal", rq["signal_class"]
    assert_equal "run-si-valid-dissent-0001", rq["run_id"]
  end

  # --- Requirement 1 受入 3 / design §2 / Decision 2: validity 弁別 ----------

  def test_validity_aware_input_policy
    pol = @intake.input_policy_for(evidence_maturity: "valid")
    assert_equal "review_quality_primary", pol["primary_use"]
    assert pol["adoption_supporting"]

    inv = @intake.input_policy_for(evidence_maturity: "invalid")
    assert_equal "workflow_prevention_primary", inv["primary_use"]

    exp = @intake.input_policy_for(evidence_maturity: "exploratory")
    assert_equal "hypothesis_seed_only", exp["primary_use"]
    refute exp["adoption_supporting"],
           "exploratory を adoption 根拠として強く扱っている"
  end

  # proposal-ready record は input class と evidence maturity を必ず記録する。
  def test_proposal_input_binding_records_class_and_maturity
    res = @intake.load_runtime_signals(run_root: RUNS + "valid_dissent_run")
    sig = res["signals"].find do |s|
      s["signal_class"] == "review_quality_signal"
    end
    binding = @intake.proposal_input_binding(signal: sig)
    assert_equal "review_quality_signal", binding["input_class"]
    assert_equal "valid", binding["evidence_maturity"]
    refute_nil binding["source_evidence_refs"]
    assert binding["adoption_supporting"]
  end

  # --- Requirement 1 受入 4 / Requirement 7 受入 3: 未記録 intuition 排除 ----

  def test_unrecorded_intuition_is_not_sufficient_input
    refute @intake.sufficient_input?(
      candidate: { "source" => "operator_intuition", "recorded" => false }
    )
    refute @intake.sufficient_input?(
      candidate: { "source" => "unstructured_editing_history" }
    )
    assert @intake.sufficient_input?(
      candidate: {
        "source" => "runtime_evidence",
        "source_evidence_refs" => ["decisions/decision_units.json"],
        "run_id" => "run-si-valid-dissent-0001"
      }
    )
  end

  # --- Requirement 1 受入 5・6 / design §2: provenance 保持と欠落時阻止 ------

  def test_provenance_preserved_from_evidence_to_proposal
    res = @intake.load_runtime_signals(run_root: RUNS + "valid_clean_run")
    sig = res["signals"].first
    prov = @intake.resolve_provenance(signal: sig)
    assert prov["provenance_complete"]
    assert_equal "central_local_run", prov["source_origin"]
    assert_equal "run-si-valid-clean-0001", prov["run_id"]
    refute_nil prov["source_repository_id"]
    refute_nil prov["source_revision"]
  end

  def test_proposal_generation_blocked_when_provenance_missing
    broken = {
      "signal_id" => "x", "signal_class" => "review_quality_signal",
      "run_id" => nil, "source_evidence_refs" => []
    }
    gate = @intake.proposal_provenance_gate(signal: broken)
    refute gate["allowed"], "provenance 欠落でも proposal を通している"
    assert_includes gate["block_reasons"], "missing_run_provenance"

    ok = @intake.load_runtime_signals(
      run_root: RUNS + "valid_clean_run"
    )["signals"].first
    assert @intake.proposal_provenance_gate(signal: ok)["allowed"]
  end

  # --- Requirement 7: review-mode provenance / manual↔runtime handoff -------

  def test_review_mode_provenance_preserved_and_distinguished
    res = @intake.load_runtime_signals(run_root: RUNS + "valid_clean_run")
    prov = @intake.resolve_provenance(signal: res["signals"].first)
    assert_equal "runtime_mediated", prov["review_mode"]
    # 撤廃語彙を使わない（metadata_contract canonical のみ）。
    assert_includes %w[manual_dogfooding runtime_mediated],
                    prov["review_mode"]
  end

  def test_manual_to_runtime_handoff_boundary_is_non_destructive
    manual = {
      "proposal_id" => "p-manual-001",
      "source_origin" => "manual_review_record",
      "signal_id" => "manual:obs-1"
    }
    runtime = {
      "proposal_id" => "p-runtime-001",
      "source_origin" => "central_local_run",
      "signal_id" => "runtime:run-si-valid-clean-0001:x"
    }
    res = @intake.supersede(prior: manual, successor: runtime,
                            reason: "later_runtime_evidence")
    prior = res["prior"]
    succ = res["successor"]
    # 非破壊: 先行は削除されず保持され manual である事実が残る。
    assert_equal "p-runtime-001", prior["superseded_by"]
    assert_equal "later_runtime_evidence", prior["supersession_reason"]
    refute_nil prior["supersession_at"]
    assert_equal "manual_review_record", prior["source_origin"]
    assert_equal "p-manual-001", succ["supersedes"]
  end

  def test_manual_dogfooding_motivates_workflow_without_runtime_equivalence
    cls = @intake.motivation_eligibility(
      review_mode: "manual_dogfooding"
    )
    assert_includes cls["allowed_motivations"], "workflow_quality"
    refute cls["implies_runtime_quality_equivalence"]
  end

  # --- Requirement 8: imported evidence provenance --------------------------

  def test_imported_bundle_provenance_preserved
    prov = @intake.resolve_imported_provenance(
      bundle: {
        "source_origin" => "imported_external_bundle",
        "source_repository_id" => "kenoogl/Rwiki-dev",
        "source_revision" => "abc1234",
        "admission_status" => "admitted_standard"
      }
    )
    assert_equal "imported_external_bundle", prov["source_origin"]
    assert_equal "kenoogl/Rwiki-dev", prov["source_repository_id"]
    assert_equal "abc1234", prov["source_revision"]
    assert_equal "admitted_standard", prov["admission_status"]
    assert prov["provenance_complete"]
  end

  def test_provenance_insufficient_imported_not_equivalent_to_admitted
    prov = @intake.resolve_imported_provenance(
      bundle: {
        "source_origin" => "imported_external_bundle",
        "source_repository_id" => nil,
        "source_revision" => nil,
        "admission_status" => nil
      }
    )
    refute prov["provenance_complete"]
    refute prov["equivalent_to_admitted_standard"],
           "provenance 不足 imported を admitted standard と等価扱い"
    gate = @intake.proposal_provenance_gate(
      signal: { "signal_class" => "review_quality_signal",
                "run_id" => "x", "source_evidence_refs" => ["a"],
                "imported_provenance" => prov }
    )
    refute gate["allowed"]
    assert_includes gate["block_reasons"],
                    "imported_provenance_insufficient"
  end

  # --- finding 2 解消: triage/failure を runtime 正本配置から直接解決 --------

  def test_triage_note_resolved_directly_from_runtime_canonical_placement
    res = @intake.load_runtime_signals(
      run_root: RUNS + "invalid_workflow_failure_run"
    )
    wf = res["signals"].find do |s|
      s["signal_code"] == "validator_failed"
    end
    refute_nil wf, "invalid run から validator_failed signal が出ない"
    assert_equal "workflow_failure_signal", wf["signal_class"]
    # triage enrichment が loader 経由でなく derived/ 正本から取得され、
    # 現行 runtime triage shape（failed_validator_check_ids）に追随する。
    v = wf["signal_value"]
    assert_equal "validator_failed", v["primary_failure_code"]
    assert_equal ["review_mode_not_in_contract_enum"],
                 v["failed_validator_check_ids"]
    assert_includes wf["source_refs"],
                    "derived/invalid_run_triage_note.json"
  end

  def test_failure_observation_resolved_from_runtime_canonical_placement
    res = @intake.load_runtime_signals(
      run_root: RUNS + "invalid_workflow_failure_run"
    )
    fo = res["signals"].find do |s|
      s["signal_code"] == "failure_observation_recorded"
    end
    refute_nil fo, "failures/failure_observation.json が intake されない"
    assert_equal "workflow_failure_signal", fo["signal_class"]
    assert_equal "validator_contract_violation",
                 fo["signal_value"]["failure_type"]
    assert_includes fo["source_refs"], "failures/failure_observation.json"
  end

  # triage/failure が無い valid run でも例外を出さず基本 flow を維持する。
  def test_valid_run_without_triage_or_failure_is_resilient
    res = @intake.load_runtime_signals(run_root: RUNS + "valid_clean_run")
    assert res["signals"].is_a?(Array)
    codes = res["signals"].map { |s| s["signal_code"] }
    refute_includes codes, "validator_failed"
    refute_includes codes, "failure_observation_recorded"
  end

  # --- design §1.5: v2 supporting input は読めなくても基本 flow 維持 --------

  def test_v2_supporting_input_is_optional
    Dir.mktmpdir do |tmp|
      dst = Pathname(tmp) + "run"
      FileUtils.cp_r(RUNS + "valid_clean_run", dst)
      FileUtils.rm_rf(dst + "v2")
      res = @intake.load_runtime_signals(run_root: dst)
      assert res["signals"].is_a?(Array),
             "v2 supporting input 欠落で基本 flow が壊れる"
    end
  end

  # exploratory run は hypothesis seed のみ（adoption 根拠は弱い）。
  def test_exploratory_run_signal_is_hypothesis_seed_only
    res = @intake.load_runtime_signals(run_root: RUNS + "exploratory_run")
    sig = res["signals"].find do |s|
      s["signal_code"] == "exploratory_evidence_mode"
    end
    refute_nil sig
    binding = @intake.proposal_input_binding(signal: sig)
    refute binding["adoption_supporting"]
    assert_equal "hypothesis_seed_only", binding["primary_use"]
  end
end
