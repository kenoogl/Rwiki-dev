# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 4: metric extraction（3 tier + core/phase overlay 2 層、評価所有）
# 根拠: tasks.md Task 4、Requirement 3 受入 1〜5、Requirement 8 受入 1〜5、
#       Requirement 7 受入 1・4、design「Metric Model §1〜§3」
#       「§2 Minimum Metric Set」「§2.5 Phase-Specific Metric Overlays」
#       「§3 Derivation Rule」。適合レビュー 2026-05-19 finding 2
#       （human_decision_ref 解決）/ 中心問い 2（runtime_summary 非依存）。
#
# 入力は第1波が版固定した実 runtime 出力形 fixture
# （tests/fixtures/evaluation/local_runs/*）。ハンドメイド仮装をしない。
# raw run evidence は不変（derived のみ生成）。
class TestMetricModel < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/
  LOCAL = ROOT + "tests/fixtures/evaluation/local_runs"

  def setup
    require_relative "../../scripts/evaluation/local_run_loader"
    require_relative "../../scripts/evaluation/metric_extractor"
    @loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: ROOT)
    @extractor = DualReviewer::Evaluation::MetricExtractor.new
  end

  def extract(dir)
    @extractor.extract_from_run_intake(
      run_intake: @loader.load_run(run_root: LOCAL + dir)
    )
  end

  # --- 3 tier 分離（Req3 受入 5・design §1） ---------------------------------

  def test_three_tiers_separated
    m = extract("valid_runtime_run")
    assert m.key?("run_metrics"), "run-level tier"
    assert m.key?("finding_metrics"), "finding-level tier"
    # treatment-level tier は複数 run の集約。単 run 抽出でも tier 名は分離。
    assert m.key?("treatment_metrics_contribution"),
           "treatment-level tier への寄与単位"
    refute_equal m["run_metrics"], m["finding_metrics"]
  end

  # --- run-level minimum metric set（design §2、Req3 受入 1） ----------------

  def test_run_level_minimum_metric_set
    m = extract("valid_runtime_run")["run_metrics"]
    assert_equal "run-eval-valid-0001", m["run_id"]
    assert_equal "design", m["phase_profile"]
    assert_equal "dual+judgment", m["treatment"]
    assert_equal 2, m["total_findings"]
    # decision_units の human_decision = approved x2（捏造しない・finding 2）。
    assert_equal 2, m["accepted_findings"]
    assert_equal 0, m["rejected_findings"]
    assert_equal 0, m["deferred_findings"]
    # validation outcome は validator_result.validator_status（runtime 実体
    # キー。v1 の存在しない overall_status に依存しない）。
    assert_equal "passed", m["validation_outcome"]
  end

  # accepted/rejected/deferred を捏造しない: decision_units に無い human
  # decision は計上しない（finding 2 解消）。
  def test_decision_counts_from_runtime_entities_not_fabricated
    m = extract("valid_runtime_run")["run_metrics"]
    total_decided = m["accepted_findings"] + m["rejected_findings"] +
                    m["deferred_findings"]
    # decision_units で human_signoff covered かつ終端のもののみ計上。
    assert_equal 2, total_decided
    assert_operator total_decided, :<=, m["total_findings"]
  end

  # decision_units 不在（analysis_blocked_run は decision_units.json 欠落）
  # でも metric 導出は構造化証跡から成立し、解決不能を捏造で埋めない。
  def test_missing_decision_units_not_fabricated
    m = extract("analysis_blocked_run")["run_metrics"]
    assert_equal 2, m["total_findings"]
    assert_equal 0, m["accepted_findings"]
    assert_equal 0, m["rejected_findings"]
    assert_equal 0, m["deferred_findings"]
  end

  # --- finding-level minimum metric set（design §2） ------------------------

  def test_finding_level_distributions
    fm = extract("valid_runtime_run")["finding_metrics"]
    assert_equal({ "major" => 1, "minor" => 1 }, fm["severity_distribution"])
    assert_equal({ "primary_reviewer" => 2 },
                 fm["source_role_distribution"])
    jl = fm["judgment_label_distribution"]
    assert_kind_of Hash, jl["resolved_labels"]
    assert jl.key?("judgment_ref_present")
    assert jl.key?("unresolved_judgment_labels")
  end

  # judgment label 解決は runtime 実体（finding.decision_unit_id →
  # decision_units[].human_decision、human_signoff 整合）で行う。
  # human_decision_ref="decisions/human_signoff.json"（# フラグメント無し）
  # を decision_unit_id として split しない（finding 2 解消）。
  def test_judgment_label_resolved_via_runtime_entities
    fm = extract("valid_runtime_run")["finding_metrics"]
    jl = fm["judgment_label_distribution"]
    # du-001/du-002 とも human_decision=approved → 解決済 2 件。
    assert_equal({ "approved" => 2 }, jl["resolved_labels"])
    assert_equal 0, jl["unresolved_judgment_labels"]
  end

  # human_decision_ref のリテラル文字列を decision_unit_id に誤分解しない。
  def test_human_decision_ref_not_split_as_fragment
    src = File.read(ROOT + "scripts/evaluation/metric_extractor.rb")
    refute_includes src, 'split("#"',
                     "human_decision_ref を # で分解する旧ロジック禁止"
  end

  # --- derivation order（design §3、Req3 受入 2） ---------------------------

  # metadata → structured findings → decision units → validation/invalidation
  # の順。runtime_summary を正本入力にしない。
  def test_derivation_path_order_and_runtime_summary_independent
    d = extract("valid_runtime_run")["derivation_path"]
    assert_equal(
      %w[metadata structured_findings decision_units
         validation_invalidation],
      d["order"]
    )
    assert_equal false, d["runtime_summary_used"]
    refute_includes d["inputs"].join(","), "runtime_summary"
  end

  # コード自体が derived/runtime_summary.json を読まない（中心問い 2）。
  def test_metric_extractor_does_not_read_runtime_summary
    src = File.read(ROOT + "scripts/evaluation/metric_extractor.rb")
    refute_includes src, "runtime_summary"
  end

  # --- core + phase overlay 2 層（Req8 受入 1〜5・design §2.5） --------------

  def test_core_and_phase_overlay_two_layers
    p = extract("valid_runtime_run")["phase_metric_profile"]
    assert_equal "design", p["phase"]
    # phase 共通 core layer。
    assert_includes p["core_metric_keys"], "total_findings"
    assert_includes p["core_metric_keys"], "acceptance_ratio"
    # phase ごと overlay layer（design §2.5 の design 観点）。
    assert_equal(
      %w[cross_section_consistency responsibility_boundary_defects
         failure_mode_omission_detection],
      p["overlay_observation_points"]
    )
    # phase-specific metric selection を derived artifact に明示（受入 4）。
    assert_equal "design", p["selected_overlay"]
  end

  # phase ごとに overlay 観点が異なる（design 中心 baseline を全 phase 主指標
  # と見なさない・受入 3）。requirements phase は別観点。
  def test_phase_overlay_differs_per_phase
    req = extract("exploratory_runtime_run")["phase_metric_profile"]
    assert_equal "requirements", req["phase"]
    assert_equal(
      %w[requirement_inconsistency_detection scope_drift_detection
         missing_acceptance_condition_detection],
      req["overlay_observation_points"]
    )
    dsn = extract("valid_runtime_run")["phase_metric_profile"]
    refute_equal req["overlay_observation_points"],
                 dsn["overlay_observation_points"]
    # core layer は phase 間で共通保持。
    assert_equal dsn["core_metric_keys"], req["core_metric_keys"]
  end

  # future implementation-oriented review へ contract 全体再設計なしに拡張
  # 可能（受入 5）: overlay catalog に implementation キーが定義として在る。
  def test_overlay_extensible_to_implementation_oriented
    cat = DualReviewer::Evaluation::MetricExtractor::PHASE_OVERLAY_CATALOG
    assert cat.key?("implementation"),
           "implementation-oriented overlay を contract 再設計なしに拡張可能"
    assert_equal(
      %w[change_impact_mismatch test_gap_indication
         unsafe_patch_recommendation_detection],
      cat["implementation"]
    )
    assert cat.key?("intent")
  end

  # 未知 phase でも core layer は崩れず overlay は空集合で明示（拡張安全）。
  def test_unknown_phase_keeps_core_layer
    Dir.mktmpdir do |dir|
      build_run_with_phase(dir, "unknown_phase")
      p = @extractor.extract_from_run_intake(
        run_intake: @loader.load_run(run_root: dir)
      )["phase_metric_profile"]
      assert_equal "unknown_phase", p["phase"]
      assert_includes p["core_metric_keys"], "total_findings"
      assert_equal [], p["overlay_observation_points"]
      assert_nil p["selected_overlay"]
    end
  end

  # --- treatment-level tier（design §1・§2、Req3 受入 5） --------------------

  # findings per run / acceptance ratio / judgment invocation coverage を
  # treatment ごとに集約する。
  def test_treatment_level_aggregation
    runs = %w[valid_runtime_run exploratory_runtime_run].map do |d|
      @loader.load_run(run_root: LOCAL + d)
    end
    per_run = runs.map do |ri|
      @extractor.extract_from_run_intake(run_intake: ri)
    end
    tm = @extractor.extract_treatment_metrics(run_metric_set: per_run)
    by_treatment = tm.each_with_object({}) { |e, h| h[e["treatment"]] = e }

    dj = by_treatment.fetch("dual+judgment")
    assert_equal 1, dj["run_count"]
    assert_in_delta 2.0, dj["findings_per_run"], 0.0001
    assert_in_delta 1.0, dj["acceptance_ratio"], 0.0001
    assert_in_delta 1.0, dj["judgment_invocation_coverage"], 0.0001

    sg = by_treatment.fetch("single")
    assert_equal 1, sg["run_count"]
  end

  # --- 再計算可能性（Req3 受入 3・4） ---------------------------------------

  # schema 互換 raw evidence 不変なら再計算で同一 derived（決定的）。
  def test_recomputable_and_deterministic
    a = extract("valid_runtime_run")
    b = extract("valid_runtime_run")
    assert_equal a, b
  end

  # derivation path（raw evidence → derived metric）を保持する（受入 3）。
  def test_derivation_path_preserved
    d = extract("valid_runtime_run")["derivation_path"]
    assert_includes d["inputs"], "review_case.json"
    assert_includes d["inputs"], "decisions/decision_units.json"
    assert_includes d["inputs"], "validation/validator_result.json"
    assert_equal "run-eval-valid-0001", d["run_id"]
  end

  # --- downstream（後続波 self-improvement signal_intake）契約維持 ----------

  # run_metrics は rejected_findings/deferred_findings/total_findings、
  # finding_metrics は judgment_label_distribution.unresolved_judgment_labels
  # を持つ（後続波が読む shape を無用に壊さない）。
  def test_downstream_consumable_shape
    m = extract("valid_runtime_run")
    %w[run_id total_findings rejected_findings
       deferred_findings].each do |k|
      assert m["run_metrics"].key?(k)
    end
    jl = m["finding_metrics"]["judgment_label_distribution"]
    %w[judgment_ref_present unresolved_judgment_labels].each do |k|
      assert jl.key?(k)
    end
  end

  private

  def build_run_with_phase(dir, phase)
    root = Pathname(dir)
    FileUtils.cp_r((LOCAL + "valid_runtime_run").to_s + "/.", root.to_s)
    rc = root + "review_case.json"
    data = JSON.parse(rc.read)
    data["metadata"]["phase_profile"] = phase
    rc.write(JSON.pretty_generate(data))
    rm = root + "run_manifest.yaml"
    rm.write(rm.read.sub("phase_profile: design",
                         "phase_profile: #{phase}"))
  end
end
