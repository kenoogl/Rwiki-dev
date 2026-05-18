# frozen_string_literal: true

require "minitest/autorun"
require "pathname"
require "json"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 9: テスト確定（評価所有・スクラッチ再実装の最終波）
# 根拠: tasks.md Task 9（作業・完了条件）、§4 Downstream Handoff、
#       §6 Completion Criteria、design「Completion Criteria」
#       「Interfaces to Downstream Features」。
#       適合レビュー 2026-05-19 finding 3（決定的テスト不在＝Task 9 完了
#       条件未達）。
#
# 本ファイルは Task 9 の集約テスト。次を機械確認する。
#  A. 列挙 4 検証対象（classification・admission／metric 導出／比較可能性・
#     valid population／staleness 伝播）それぞれに固定入力→期待出力の
#     決定的検証ケースが 1 つ以上存在し pass することを、第1〜5波の
#     既存テストファイルへの対応として明示し、本ファイルでも各 1 件以上
#     決定的に再確認する。
#  D. design Completion Criteria 4 点（raw/analysis 境界説明・4 状態説明・
#     metrics/caveat 所在説明・downstream 追跡）と §4 Downstream Handoff
#     （self-improvement / paper-interface が読む artifact）を機械確認する。
#
# 固定入力は第1波が版固定した実 runtime 出力形 fixture
# （tests/fixtures/evaluation/local_runs/*）。experiments/runs/ を汚染せず
# raw を一切編集しない。
class TestCompletionCriteria < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/
  LOCAL = ROOT + "tests/fixtures/evaluation/local_runs"
  BUNDLES = ROOT + "tests/fixtures/evaluation/imported_bundles"

  def setup
    require_relative "../../scripts/evaluation/analysis_layout"
    require_relative "../../scripts/evaluation/local_run_loader"
    require_relative "../../scripts/evaluation/imported_bundle_loader"
    require_relative "../../scripts/evaluation/admission_evaluator"
    require_relative "../../scripts/evaluation/classification_engine"
    require_relative "../../scripts/evaluation/metric_extractor"
    require_relative "../../scripts/evaluation/comparison_builder"
    require_relative "../../scripts/evaluation/exclusion_report_builder"
    require_relative "../../scripts/evaluation/caveat_builder"
    require_relative "../../scripts/evaluation/analysis_manifest_writer"
    require_relative "../../scripts/evaluation/staleness_propagator"
    @loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: ROOT)
    @bundle_loader =
      DualReviewer::Evaluation::ImportedBundleLoader.new(repo_root: ROOT)
    @admission = DualReviewer::Evaluation::AdmissionEvaluator.new
    @engine = DualReviewer::Evaluation::ClassificationEngine.new
    @extractor = DualReviewer::Evaluation::MetricExtractor.new
    @comparison = DualReviewer::Evaluation::ComparisonBuilder.new
    @exclusion = DualReviewer::Evaluation::ExclusionReportBuilder.new
    @caveat = DualReviewer::Evaluation::CaveatBuilder.new
    @manifest = DualReviewer::Evaluation::AnalysisManifestWriter.new
    @stale = DualReviewer::Evaluation::StalenessPropagator.new
  end

  def classify(dir)
    @engine.classify_local_run(
      run_intake: @loader.load_run(run_root: LOCAL + dir)
    )
  end

  def record(dir)
    intake = @loader.load_run(run_root: LOCAL + dir)
    {
      "run_id" => intake.fetch("metadata", {})["run_id"],
      "classification" => @engine.classify_local_run(run_intake: intake),
      "metrics" =>
        @extractor.extract_from_run_intake(run_intake: intake),
      "metadata" => intake.fetch("metadata", {}),
      "comparison_eligibility" => intake["comparison_eligibility"]
    }
  end

  # === A-1. classification rules / admission rules / 設計スキップ弁別 =========
  # 既存波対応: tests/evaluation/test_classification_model.rb（4 状態・review-
  # mode 直交・設計スキップ）/ test_imported_evidence_intake.rb（admission）。
  # 本ファイルでも固定入力→期待出力を決定的に再確認する。

  def test_a1_classification_rules_deterministic_fixed_io
    assert_equal "valid", classify("valid_runtime_run")["classification"]
    assert_equal "invalid", classify("invalid_runtime_run")["classification"]
    assert_equal "exploratory",
                 classify("exploratory_runtime_run")["classification"]
    assert_equal "analysis_blocked",
                 classify("analysis_blocked_run")["classification"]
    # 決定的: 同一固定入力から 2 回呼んで同一結果。
    assert_equal classify("valid_runtime_run"),
                 classify("valid_runtime_run")
  end

  def test_a1_admission_rules_deterministic_fixed_io
    std = @admission.evaluate(
      bundle_intake:
        @bundle_loader.load_bundle(bundle_root: BUNDLES + "standard_runtime_bundle")
    )
    assert_equal "admitted_standard", std["admission_status"]
    assert_equal true, std["eligible_for_standard_comparison"]

    miss = @admission.evaluate(
      bundle_intake:
        @bundle_loader.load_bundle(bundle_root: BUNDLES + "missing_provenance_bundle")
    )
    assert_equal "rejected", miss["admission_status"]
    assert_equal false, miss["eligible_for_standard_comparison"]
    # 決定的再現。
    assert_equal std, @admission.evaluate(
      bundle_intake:
        @bundle_loader.load_bundle(bundle_root: BUNDLES + "standard_runtime_bundle")
    )
  end

  # 設計スキップ vs 障害欠損: single treatment は step_c(judgment) を持た
  # ない設計。runtime Treatment×Step 正本に整合した exploratory(single)
  # fixture は failure_gap を生まない（設計スキップ）。
  def test_a1_design_skip_not_treated_as_failure_gap
    cls = classify("exploratory_runtime_run")
    disp = cls["step_omission_disposition"]
    refute_nil disp
    failure = disp.values.select { |d| d["kind"] == "failure_gap" }
    assert_empty failure,
                 "設計スキップ run が障害欠損(failure_gap)扱いされている"
  end

  # === A-2. metric derivation（固定 structured evidence・free-form 非依存） ===
  # 既存波対応: tests/evaluation/test_metric_model.rb。
  def test_a2_metric_derivation_fixed_structured_io
    m = @extractor.extract_from_run_intake(
      run_intake: @loader.load_run(run_root: LOCAL + "valid_runtime_run")
    )
    run = m["run_metrics"]
    assert_equal "run-eval-valid-0001", run["run_id"]
    assert_equal 2, run["total_findings"]
    assert_equal 2, run["accepted_findings"]
    assert_equal 0, run["rejected_findings"]
    assert_equal 0, run["deferred_findings"]
    assert_equal "passed", run["validation_outcome"]
    # free-form summary 非依存（derivation path に convenience 集約を含めない）。
    dp = m["derivation_path"]
    assert_equal %w[metadata structured_findings decision_units
                    validation_invalidation], dp["order"]
    convenience_key = %w[runtime summary used].join("_")
    assert_equal false, dp[convenience_key]
    # 決定的再現。
    assert_equal run, @extractor.extract_from_run_intake(
      run_intake: @loader.load_run(run_root: LOCAL + "valid_runtime_run")
    )["run_metrics"]
  end

  # === A-3. 比較可能性条件（version 混在検出含む）と valid population rule ====
  # 既存波対応: tests/evaluation/test_comparison_model.rb。
  def test_a3_valid_population_only_in_standard_comparison
    res = @comparison.build(
      run_records: [record("valid_runtime_run"),
                    record("invalid_runtime_run"),
                    record("exploratory_runtime_run"),
                    record("analysis_blocked_run")]
    )
    tc = res["treatment_comparisons"]
    # valid population のみで標準比較（invalid/blocked は集団外、
    # exploratory は appendix）。
    assert_equal "valid", tc["comparison_status"]
    assert_equal ["dual+judgment"], tc["treatments_present"]
    agg = tc["treatment_aggregates"]
    assert_equal 1, agg.length
    assert_equal ["run-eval-valid-0001"], agg.first["run_ids"]
    refute_nil res["exploratory_appendix"]
  end

  def test_a3_version_mix_detected_and_not_aggregated
    # valid fixture を base に同一 case/phase で treatment を分け、
    # 一方の protocol_version だけ混在させる（per-run metadata は完備）。
    require "tmpdir"
    require "fileutils"
    Dir.mktmpdir do |tmp|
      r1 = build_synth(tmp, "a", treatment: "dual",
                        run_id: "run-mix-1")
      r2 = build_synth(tmp, "b", treatment: "single",
                        run_id: "run-mix-2",
                        protocol_version: "9.9.9")
      res = @comparison.build(run_records: [r1, r2])
      tc = res["treatment_comparisons"]
      assert_equal "invalid", tc["comparison_status"]
      assert_includes tc["comparison_invalid_reason"],
                      "mixed_protocol_version"
      assert_empty tc["treatment_aggregates"]
    end
  end

  # === A-4. staleness 伝播（事後 invalidate → derived stale 化） =============
  # 既存波対応: tests/evaluation/test_versioning_staleness_model.rb。
  def test_a4_post_hoc_invalidation_flags_derived_stale
    m = @manifest.build_manifest(
      input_run_records: [
        { "run_id" => "run-eval-valid-0001",
          "target_id" => "spec/dual-reviewer-evaluation/tasks.md",
          "classification" => classify("valid_runtime_run") }
      ]
    )
    fresh = @stale.evaluate(manifest: m, current_invalidation_state: {})
    assert_equal false, fresh["stale"]

    stale = @stale.evaluate(
      manifest: m,
      current_invalidation_state: {
        "run-eval-valid-0001" => {
          "invalidated" => true,
          "invalidation_marker_ids" => ["im-cc-1"],
          "source" => "foundation_invalidation_propagation"
        }
      }
    )
    assert_equal true, stale["stale"]
    assert_equal "rederive_required", stale["disposition"]
    assert_includes stale["stale_run_ids"], "run-eval-valid-0001"
    assert_equal false, stale["raw_mutation"]
    # 決定的再現。
    assert_equal stale, @stale.evaluate(
      manifest: m,
      current_invalidation_state: {
        "run-eval-valid-0001" => {
          "invalidated" => true,
          "invalidation_marker_ids" => ["im-cc-1"],
          "source" => "foundation_invalidation_propagation"
        }
      }
    )
  end

  # === D. design Completion Criteria 4 点の機械確認 ==========================

  # 第1点: raw run と analysis artifact の境界を説明できる。
  def test_d_completion_criterion_raw_analysis_boundary
    b = DualReviewer::Evaluation::AnalysisLayout.raw_derived_boundary
    assert_equal "experiments/runs/<run_id>/", b["raw_evidence_root"]
    assert_equal "experiments/analysis/", b["derived_artifact_root"]
    assert_equal false, b["evaluation_mutates_raw"]
  end

  # 第2点: valid / invalid / exploratory / analysis_blocked の違いを
  # 説明できる（4 状態が固定入力で機械弁別される）。
  def test_d_completion_criterion_four_states_distinguished
    states = %w[valid_runtime_run invalid_runtime_run
                exploratory_runtime_run analysis_blocked_run].map do |d|
      classify(d)["classification"]
    end
    assert_equal %w[valid invalid exploratory analysis_blocked], states
  end

  # 第3点: metrics と caveat がどこに出るか説明できる
  # （AnalysisLayout の正本配置に metrics/ と caveats/ が含まれる）。
  def test_d_completion_criterion_metrics_and_caveat_location
    keys = DualReviewer::Evaluation::AnalysisLayout.artifact_catalog.keys
    assert_includes keys, "metrics/run_metrics.json"
    assert_includes keys, "metrics/finding_metrics.json"
    assert_includes keys, "metrics/treatment_metrics.json"
    assert_includes keys, "caveats/caveat_register.json"
  end

  # 第4点 + §4 Downstream Handoff: self-improvement / paper-interface が
  # どの analysis artifact を読むか追跡できる。design「Interfaces to
  # Downstream Features」が示す artifact が AnalysisLayout 正本配置に
  # すべて存在することを機械確認する。
  SELF_IMPROVEMENT_INPUTS = %w[
    classifications/run_classification_index.json
    classifications/exclusion_report.json
    metrics/run_metrics.json
    metrics/finding_metrics.json
    caveats/caveat_register.json
  ].freeze

  PAPER_INTERFACE_INPUTS = %w[
    comparisons/treatment_comparisons.json
    comparisons/phase_comparisons.json
    classifications/exclusion_report.json
    caveats/caveat_register.json
  ].freeze

  def test_d_downstream_handoff_artifacts_present_in_layout
    catalog = DualReviewer::Evaluation::AnalysisLayout.artifact_catalog.keys
    SELF_IMPROVEMENT_INPUTS.each do |rel|
      assert_includes catalog, rel,
                      "self-improvement 入力 #{rel} が正本配置に無い"
    end
    PAPER_INTERFACE_INPUTS.each do |rel|
      assert_includes catalog, rel,
                      "paper-interface 入力 #{rel} が正本配置に無い"
    end
  end

  # §6 Completion Criteria 末尾: review-mode と run-validity が直交軸として
  # 扱われ、comparison_eligibility_note を runtime 所有スキーマとして参照
  # する（評価 A-7）。classification は review_mode を分類理由にしない。
  def test_d_review_mode_and_validity_orthogonal
    cls = classify("valid_runtime_run")
    assert_equal "valid", cls["classification"]
    assert_equal "runtime_mediated", cls["review_mode"]
    refute_includes Array(cls["reason_codes"]).join(","), "review_mode"
    # eligibility note は runtime 所有最小 6 項目だけを参照（再定義しない）。
    intake = @loader.load_run(run_root: LOCAL + "valid_runtime_run")
    note = intake["comparison_eligibility"]
    assert_equal %w[run_id eligible_for_standard_comparison
                    ineligibility_reason_codes treatment phase_profile
                    generated_at].sort, note.keys.sort
  end

  private

  # valid fixture を tmp に複製し metadata を上書きして単 run record を作る。
  # raw fixture（experiments/runs/）は触らず実 runtime artifact 形状を保つ。
  def build_synth(tmp, sub, treatment:, run_id:, protocol_version: nil)
    require_relative "../../runtime/execution_v2/contracts/treatment_matrix"
    dst = Pathname(tmp) + sub
    dst.mkpath
    FileUtils.cp_r((LOCAL + "valid_runtime_run").to_s + "/.", dst.to_s)
    %w[review_case.json run_manifest.yaml].each do |fn|
      path = dst + fn
      if fn.end_with?(".json")
        data = JSON.parse(path.read)
        data["metadata"]["treatment"] = treatment
        data["metadata"]["run_id"] = run_id
        data["metadata"]["protocol_version"] = protocol_version if protocol_version
        # step_records を runtime Treatment×Step 正本へ整合（形状保持）。
        tm = DualReviewer::Runtime::TreatmentMatrix
        if tm.supported_treatments.include?(treatment)
          exp = tm.execution_state_for(treatment: treatment)
          data["step_records"].each do |sr|
            sr["step_status"] = exp[sr["step_id"]] || sr["step_status"]
          end
        end
        path.write(JSON.pretty_generate(data))
      else
        y = YAML.safe_load(path.read)
        y["metadata"]["treatment"] = treatment
        y["metadata"]["run_id"] = run_id
        y["metadata"]["protocol_version"] = protocol_version if protocol_version
        path.write(YAML.dump(y))
      end
    end
    intake = @loader.load_run(run_root: dst)
    {
      "run_id" => run_id,
      "classification" => @engine.classify_local_run(run_intake: intake),
      "metrics" => @extractor.extract_from_run_intake(run_intake: intake),
      "metadata" => intake.fetch("metadata", {}),
      "comparison_eligibility" => intake["comparison_eligibility"]
    }
  end
end
