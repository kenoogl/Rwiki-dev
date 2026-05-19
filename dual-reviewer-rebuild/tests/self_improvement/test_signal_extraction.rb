# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"
require "yaml"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 3: signal extraction model（自己改善所有・スクラッチ）。
# 根拠: tasks.md Task 3、Requirement 1 受入 5（出所連鎖）、
#       design「Signal Extraction Model §1〜§4」「Proposal Normalization
#       Rules」「Project-Specific Pattern Extraction」「Findings Artifact
#       Required Fields」「v2 Supporting Inputs」。
#       適合レビュー 2026-05-19 finding 1/2/3 解消を独立検証する。
#
# 入力は第1波で版固定した実 runtime→実 evaluation 出力 fixture
# （tests/fixtures/self_improvement/）。決定的固定入力→期待出力。出力先は
# tmpdir（実 learning/・experiments/ を汚さない）。
class TestSignalExtraction < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path
  FIX = ROOT + "tests/fixtures/self_improvement"
  RUNS = FIX + "runtime_runs"
  ANALYSIS = FIX + "analysis"

  def setup
    require_relative "../../scripts/self_improvement/signal_extraction"
    @model = DualReviewer::SelfImprovement::SignalExtraction.new(
      repo_root: ROOT
    )
  end

  def all_run_roots
    %w[valid_dissent_run invalid_workflow_failure_run
       exploratory_run valid_clean_run].map { |v| RUNS + v }
  end

  def extract_all
    @model.extract(run_roots: all_run_roots, analysis_root: ANALYSIS)
  end

  # --- design §1: runtime 由来 signal を抽出する -----------------------------

  def test_runtime_derived_signal_types_are_extracted
    res = extract_all
    types = res[:signals].select { |s| s["signal_source"] == "runtime" }
                         .map { |s| s["signal_type"] }.uniq
    # 現行確定 fixture corpus は invalid workflow failure run と dissent run
    # を含む。design §1 の runtime-derived 分類語彙で表現される。
    assert_includes types, "repeated_invalidation_categories"
    assert_includes types, "high_reject_concentration"
    # design §1 の全カテゴリが taxonomy として定義済みである。
    assert_equal %w[
      frequent_skip_marker_misuse
      high_reject_concentration
      repeated_defer_clusters
      repeated_invalidation_categories
      repeated_signal_linkage
    ], @model.runtime_signal_types.sort
  end

  # --- design §2: evaluation 由来 signal を抽出する --------------------------

  def test_evaluation_derived_signal_types_are_extracted
    res = extract_all
    types = res[:signals].select { |s| s["signal_source"] == "evaluation" }
                         .map { |s| s["signal_type"] }.uniq
    # 現行 fixture: rejected_finding_cluster → low_acceptance_ratio、
    # caveat → phase_specific_caveat_concentration、exploratory pop member。
    assert_includes types, "low_acceptance_ratio"
    assert_includes types, "phase_specific_caveat_concentration"
    assert_equal %w[
      low_acceptance_ratio
      phase_specific_caveat_concentration
      repeated_analysis_blocked
      repeated_comparison_ineligible
      treatment_specific_quality_drop
    ], @model.evaluation_signal_types.sort
  end

  # --- design §4: findings/recurring_failure_signals.json required fields ----

  def test_recurring_failure_signals_inventory_required_fields
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      @model.write_inventory(
        learning_root: lr,
        run_roots: all_run_roots, analysis_root: ANALYSIS
      )
      inv = JSON.parse(
        (lr + "findings/recurring_failure_signals.json").read
      )
      refute_empty inv["entries"]
      inv["entries"].each do |e|
        %w[signal_id signal_type source_evidence_refs occurrence_count
           first_seen_run_ref last_seen_run_ref summary].each do |f|
          assert e.key?(f), "recurring signal entry に #{f} が無い"
        end
        assert e["occurrence_count"].is_a?(Integer)
        refute_empty Array(e["source_evidence_refs"])
      end
      # 長期保存 artifact は schema_version を持つ（第1波 LearningLayout）。
      assert_equal "1.0.0", inv["schema_version"]
    end
  end

  # workflow_failure_signals.json も同 required field を持つ（design §4）。
  def test_workflow_failure_signals_inventory_required_fields
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      @model.write_inventory(
        learning_root: lr,
        run_roots: all_run_roots, analysis_root: ANALYSIS
      )
      wf = JSON.parse(
        (lr + "findings/workflow_failure_signals.json").read
      )
      refute_empty wf["entries"]
      wf["entries"].each do |e|
        %w[signal_id signal_type source_evidence_refs occurrence_count
           first_seen_run_ref last_seen_run_ref summary].each do |f|
          assert e.key?(f), "workflow signal entry に #{f} が無い"
        end
      end
      # workflow inventory は workflow_failure_signal class のみ。
      classes = wf["entries"].map { |e| e["signal_class"] }.uniq
      assert_equal ["workflow_failure_signal"], classes
    end
  end

  # occurrence_count / first_seen / last_seen が複数 run 集約で正しい。
  def test_occurrence_count_and_seen_run_refs_aggregate_across_runs
    res = extract_all
    entry = res[:inventory_entries].find do |e|
      e["signal_type"] == "repeated_invalidation_categories"
    end
    refute_nil entry, "invalidation 集約 entry が無い"
    # invalid run は validator_failed + failure_observation_recorded の
    # 2 signal が同 signal_type へ集約される（occurrence は signal 件数）。
    assert_equal 2, entry["occurrence_count"]
    # いずれも同一 invalid run 由来であり first/last は同じ run_ref。
    assert_equal "run-si-invalid-workflow-0001", entry["first_seen_run_ref"]
    assert_equal "run-si-invalid-workflow-0001", entry["last_seen_run_ref"]
  end

  # --- design §4 / Req1 受入 5: 出所連鎖が機械的に辿れる -------------------

  def test_provenance_chain_traces_proposal_to_runtime_evidence
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      res = @model.write_inventory(
        learning_root: lr,
        run_roots: all_run_roots, analysis_root: ANALYSIS
      )
      # proposal が持つはずの source_evidence_refs を 1 件取り、findings
      # entry → runtime/evaluation evidence ref まで機械的に辿れる。
      norm = res[:proposal_groups].first
      refute_nil norm
      chain = @model.trace_provenance(
        learning_root: lr,
        source_evidence_refs: norm["source_evidence_refs"]
      )
      refute_empty chain[:findings_entries],
                   "source_evidence_refs から findings entry に辿れない"
      refute_empty chain[:evidence_refs],
                   "findings から runtime/evaluation evidence に辿れない"
      assert chain[:fully_traceable],
             "出所連鎖が断絶している（Req1 受入 5 不成立）"
    end
  end

  def test_provenance_chain_breaks_when_ref_unknown
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      @model.write_inventory(
        learning_root: lr,
        run_roots: all_run_roots, analysis_root: ANALYSIS
      )
      chain = @model.trace_provenance(
        learning_root: lr,
        source_evidence_refs: ["findings/recurring_failure_signals.json#sig-does-not-exist"]
      )
      refute chain[:fully_traceable],
             "存在しない signal_id を辿れると誤判定している"
    end
  end

  # --- design §2.5: proposal normalization rules ---------------------------

  # 同一 invalid run の closely-coupled workflow failure signal
  # （validator_failed + invalidation_marker_issued / failure_observation）は
  # 1 proposal group に統合される。
  def test_closely_coupled_workflow_signals_merge_into_one_proposal
    res = extract_all
    inv_groups = res[:proposal_groups].select do |g|
      g["normalization_kind"] == "coupled_workflow" &&
        g["run_id"] == "run-si-invalid-workflow-0001"
    end
    assert_equal 1, inv_groups.size,
                 "同一 invalid run の workflow failure を分断している"
    g = inv_groups.first
    assert_equal "invalid-run prevention / invalidation handling",
                 g["remediation_surface"]
    member_codes = g["member_signal_codes"]
    assert_includes member_codes, "validator_failed"
    assert_includes member_codes, "failure_observation_recorded"
  end

  # aggregate caveat signal は caveat code ごとに proposal identity を分ける
  # （過併合しない）。
  def test_aggregate_caveat_signals_split_by_caveat_code
    res = extract_all
    caveat_groups = res[:proposal_groups].select do |g|
      g["normalization_kind"] == "aggregate_caveat"
    end
    refute_empty caveat_groups
    codes = caveat_groups.map { |g| g["caveat_code"] }
    assert_equal codes, codes.uniq,
                 "caveat code が異なる aggregate caveat を併合している"
    assert_includes codes, "mixed_maturity_evidence"
    # 各 caveat group は 1 caveat code のみを束ねる（識別子分離）。
    caveat_groups.each do |g|
      assert_equal 1, g["member_signal_codes"].uniq.size
    end
  end

  # --- design §3: project-specific pattern extraction flow ------------------

  def test_pattern_candidates_distinguish_project_specific_and_meta
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      @model.write_inventory(
        learning_root: lr,
        run_roots: all_run_roots, analysis_root: ANALYSIS
      )
      pc = JSON.parse((lr + "findings/pattern_candidates.json").read)
      refute_empty pc["entries"]
      pc["entries"].each do |e|
        %w[candidate_id abstraction_level source_signal_refs
           summary].each do |f|
          assert e.key?(f), "pattern candidate に #{f} が無い"
        end
        assert_includes %w[project-specific meta-pattern\ candidate],
                        e["abstraction_level"]
        refute_empty Array(e["source_signal_refs"])
      end
      levels = pc["entries"].map { |e| e["abstraction_level"] }.uniq
      assert_includes levels, "project-specific",
                      "project-specific concrete が抽出されない"
    end
  end

  # --- design §3: operator-facing remediation template 派生 ------------------

  def test_remediation_templates_derived_from_invalid_run_triage
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      @model.write_inventory(
        learning_root: lr,
        run_roots: all_run_roots, analysis_root: ANALYSIS
      )
      tpl = JSON.parse(
        (lr + "templates/workflow_remediation_templates.json").read
      )
      refute_empty tpl["entries"]
      tpl["entries"].each do |e|
        %w[template_id failure_mode checklist recommended_action
           source_pattern_refs].each do |f|
          assert e.key?(f), "template に #{f} が無い"
        end
        assert e["checklist"].is_a?(Array)
        refute_empty e["checklist"]
        refute_empty Array(e["source_pattern_refs"])
      end
      modes = tpl["entries"].map { |e| e["failure_mode"] }
      assert_includes modes, "validator_failed",
                      "invalid-run triage の recurring failure mode が " \
                      "template 化されていない"
    end
  end

  # --- design §1.5: v2 supporting input は読めなくても基本 flow 維持 --------

  def test_basic_flow_resilient_without_v2_supporting_input
    Dir.mktmpdir do |tmp|
      dst = Pathname(tmp) + "runs"
      FileUtils.mkdir_p(dst)
      roots = []
      %w[valid_dissent_run invalid_workflow_failure_run
         exploratory_run valid_clean_run].each do |v|
        d = dst + v
        FileUtils.cp_r(RUNS + v, d)
        FileUtils.rm_rf(d + "v2")
        roots << d
      end
      res = @model.extract(run_roots: roots, analysis_root: ANALYSIS)
      refute_empty res[:signals],
                   "v2 supporting input 欠落で基本 flow が壊れる"
      refute_empty res[:proposal_groups]
    end
  end

  # write_inventory は冪等で第1波 LearningLayout 正本パスに書き出す。
  def test_write_inventory_is_idempotent_on_canonical_paths
    Dir.mktmpdir do |tmp|
      lr = Pathname(tmp) + "learning"
      2.times do
        @model.write_inventory(
          learning_root: lr,
          run_roots: all_run_roots, analysis_root: ANALYSIS
        )
      end
      %w[findings/recurring_failure_signals.json
         findings/workflow_failure_signals.json
         findings/pattern_candidates.json
         templates/workflow_remediation_templates.json].each do |rel|
        p = lr + rel
        assert p.file?, "正本パス未生成: #{rel}"
        assert_equal "1.0.0", JSON.parse(p.read)["schema_version"]
      end
    end
  end
end
