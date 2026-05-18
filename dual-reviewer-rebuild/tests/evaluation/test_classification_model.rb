# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 3: classification model（valid/invalid/exploratory/analysis_blocked）
# 根拠: tasks.md Task 3、Requirement 1 受入 1〜6、Requirement 9 受入 1〜6、
#       Requirement 10 受入 4・5、Requirement 2 受入 3、design「Classification
#       Model §1〜§4」「Admission States」。runtime treatment_matrix（Treatment
#       ×Step 正本・runtime 所有）。適合レビュー finding 4/5/7/8。
#
# Task 7 -> Task 3 一方向: 本 Task は Task 7 の admission_status を参照のみ
# し再判定しない。入力は第1波が版固定した実 runtime 出力形 fixture。
class TestClassificationModel < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/
  LOCAL = ROOT + "tests/fixtures/evaluation/local_runs"
  BUNDLES = ROOT + "tests/fixtures/evaluation/imported_bundles"

  def setup
    require_relative "../../scripts/evaluation/local_run_loader"
    require_relative "../../scripts/evaluation/imported_bundle_loader"
    require_relative "../../scripts/evaluation/admission_evaluator"
    require_relative "../../scripts/evaluation/classification_engine"
    @loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: ROOT)
    @engine = DualReviewer::Evaluation::ClassificationEngine.new
  end

  def classify(dir)
    @engine.classify_local_run(
      run_intake: @loader.load_run(run_root: LOCAL + dir)
    )
  end

  # --- 4 状態分類（design §1・§2、Req1 受入 1） -------------------------------

  def test_valid_run_classified_valid
    r = classify("valid_runtime_run")
    assert_equal "valid", r["classification"]
    assert_equal "run-eval-valid-0001", r["run_id"]
    assert_equal "design", r["phase_profile"]
    assert_equal "dual+judgment", r["treatment"]
  end

  # invalidation marker あり or validator_status failed -> invalid。
  def test_invalid_run_classified_invalid
    r = classify("invalid_runtime_run")
    assert_equal "invalid", r["classification"]
    assert_includes r["reason_codes"], "validator_failed"
    assert(r["reason_codes"].any? { |c| c.start_with?("invalidation:") })
  end

  # evidence_class exploratory -> exploratory。
  def test_exploratory_run_classified_exploratory
    r = classify("exploratory_runtime_run")
    assert_equal "exploratory", r["classification"]
    assert_includes r["reason_codes"], "evidence_class_exploratory"
  end

  # run_status!=closed or validator_status blocked or required input 不足
  # -> analysis_blocked。created/中断 run は invalid でなく analysis_blocked。
  def test_blocked_run_classified_analysis_blocked
    r = classify("analysis_blocked_run")
    assert_equal "analysis_blocked", r["classification"]
    refute_equal "invalid", r["classification"]
    codes = r["reason_codes"]
    assert(codes.include?("run_status_not_closed") ||
           codes.include?("validator_status_blocked") ||
           codes.include?("required_input_missing"))
  end

  # analysis_blocked は exclusion report に出すが比較集団に入れない。
  def test_analysis_blocked_excluded_from_comparison_population
    r = classify("analysis_blocked_run")
    assert_equal false, r["in_comparison_population"]
    assert_equal true, r["excluded"]
  end

  def test_valid_run_in_comparison_population
    r = classify("valid_runtime_run")
    assert_equal true, r["in_comparison_population"]
  end

  # --- missing vs invalid（design §3、Req1 受入 4） ---------------------------

  # missing（入力なし）と invalid（入力はあるが contract 違反）を区別する。
  def test_missing_distinguished_from_invalid
    blocked = classify("analysis_blocked_run")
    invalid = classify("invalid_runtime_run")
    assert_equal "missing_input", blocked["insufficiency_kind"]
    assert_equal "invalid_input", invalid["insufficiency_kind"]
  end

  # --- review-mode 直交軸（Req1 受入 6・Req9 受入 1、finding 8） --------------

  # 有効性分類と review-mode を直交独立軸として保持。manual_dogfooding の
  # 内容的 valid を review-mode 理由で invalid 誤分類しない。
  def test_review_mode_orthogonal_to_validity
    r = classify("valid_runtime_run")
    assert_equal "valid", r["classification"]
    assert_equal "runtime_mediated", r["review_mode"]
    # 分類軸は review_mode を理由にしない。
    refute_includes r["reason_codes"], "review_mode_runtime_mediated"
  end

  # manual_dogfooding でも内容的 valid なら invalid と誤分類しない（直交）。
  def test_manual_dogfooding_valid_not_misclassified_as_invalid
    Dir.mktmpdir do |dir|
      build_manual_dogfooding_valid_run(dir)
      r = @engine.classify_local_run(
        run_intake: @loader.load_run(run_root: dir)
      )
      assert_equal "valid", r["classification"]
      assert_equal "manual_dogfooding", r["review_mode"]
      # 直交 slice: standard runtime-mediated 比較集団からは別 slice。
      assert_equal false, r["in_standard_runtime_comparison_set"]
      assert_includes r["review_mode_slice_codes"],
                      "manual_dogfooding_phase1_separate_slice"
    end
  end

  # runtime_mediated の valid は標準 runtime-mediated 比較集団に入る。
  def test_runtime_mediated_valid_in_standard_set
    r = classify("valid_runtime_run")
    assert_equal true, r["in_standard_runtime_comparison_set"]
  end

  # 撤廃済み review_mode 語彙を classification が一切使わない（finding 4）。
  def test_no_retired_review_mode_vocabulary_in_classification
    src = File.read(ROOT + "scripts/evaluation/classification_engine.rb")
    %w[single_review dual_review dual_reviewer_workflow].each do |retired|
      refute_includes src, retired
    end
  end

  # --- Task 7 -> Task 3 一方向参照（Req10 受入 4・5） ------------------------

  # imported bundle の admission status を参照のみし再判定しない。
  def test_imported_bundle_admission_referenced_not_rejudged
    bl = DualReviewer::Evaluation::ImportedBundleLoader.new(repo_root: ROOT)
    ae = DualReviewer::Evaluation::AdmissionEvaluator.new
    bundle = bl.load_bundle(bundle_root: BUNDLES + "standard_runtime_bundle")
    admission = ae.evaluate(bundle_intake: bundle)

    r = @engine.classify_imported_bundle(
      bundle_intake: bundle,
      admission_result: admission
    )
    # admission state を run validity と別に保持（受入 5）。
    assert_equal admission["admission_status"], r["admission_status"]
    # 本 Task は admission を再判定しない（Task 7 が単一所有者）。
    refute r.key?("recomputed_admission_status")
    # admitted_standard かつ内容 valid なら valid 分類。
    assert_equal "valid", r["classification"]
  end

  # rejected admission の bundle は分類前段で比較集団外（再判定しない）。
  def test_rejected_admission_excluded_without_rejudgment
    bl = DualReviewer::Evaluation::ImportedBundleLoader.new(repo_root: ROOT)
    ae = DualReviewer::Evaluation::AdmissionEvaluator.new
    bundle = bl.load_bundle(bundle_root: BUNDLES + "missing_provenance_bundle")
    admission = ae.evaluate(bundle_intake: bundle)
    assert_equal "rejected", admission["admission_status"]

    r = @engine.classify_imported_bundle(
      bundle_intake: bundle,
      admission_result: admission
    )
    assert_equal "rejected", r["admission_status"]
    assert_equal false, r["in_comparison_population"]
  end

  # --- 設計スキップ vs 障害欠損（Req2 受入 3・design §4、finding 5） ---------

  # exploratory_runtime_run は treatment=single で step_b/step_c が
  # treatment 由来 skipped。Treatment×Step 正本に整合 -> 設計スキップ
  # （障害扱いで減点・誤排除しない）。
  def test_treatment_driven_skip_not_treated_as_failure
    r = classify("exploratory_runtime_run")
    sd = r.fetch("step_omission_disposition")
    %w[step_b step_c].each do |sid|
      assert_equal "design_skip", sd[sid]["kind"], "#{sid} は設計スキップ"
    end
    # 設計スキップは障害欠損理由に計上しない。
    refute_includes r["reason_codes"], "step_failure_gap"
  end

  # dual+judgment の valid run は全 step executed -> design_skip 無し。
  def test_full_treatment_has_no_design_skip
    r = classify("valid_runtime_run")
    sd = r.fetch("step_omission_disposition")
    DualReviewer::Runtime::TreatmentMatrix::STEP_IDS.each do |sid|
      assert_equal "executed", sd[sid]["kind"]
    end
  end

  # 印が宣言 treatment と矛盾する step は障害欠損として弁別する。
  def test_marker_inconsistent_with_treatment_is_failure_gap
    Dir.mktmpdir do |dir|
      build_treatment_inconsistent_run(dir)
      r = @engine.classify_local_run(
        run_intake: @loader.load_run(run_root: dir)
      )
      sd = r.fetch("step_omission_disposition")
      # treatment=dual+judgment は step_c executed のはずだが skipped 印 ->
      # 宣言 treatment と矛盾 -> failure_gap。
      assert_equal "failure_gap", sd["step_c"]["kind"]
      assert_includes r["reason_codes"], "step_failure_gap"
    end
  end

  # --- 決定性（Task 9 完了条件: 固定入力 -> 期待出力） -----------------------

  def test_classification_is_deterministic
    a = classify("valid_runtime_run")
    b = classify("valid_runtime_run")
    assert_equal a, b
  end

  # signal_intake（後続波）が読む result shape を維持する。
  def test_result_shape_preserved_for_downstream
    r = classify("valid_runtime_run")
    %w[run_id classification reason_codes reason_details
       phase_profile treatment].each do |k|
      assert r.key?(k), "downstream 契約 key 欠落: #{k}"
    end
    assert_kind_of Array, r["reason_codes"]
    assert_kind_of Array, r["reason_details"]
  end

  private

  def build_manual_dogfooding_valid_run(dir)
    root = Pathname(dir)
    FileUtils.cp_r((LOCAL + "valid_runtime_run").to_s + "/.", root.to_s)
    %w[run_manifest.yaml].each do |f|
      p = root + f
      p.write(p.read.sub("review_mode: runtime_mediated",
                          "review_mode: manual_dogfooding"))
    end
    rc = root + "review_case.json"
    data = JSON.parse(rc.read)
    data["metadata"]["review_mode"] = "manual_dogfooding"
    rc.write(JSON.pretty_generate(data))
  end

  # treatment=dual+judgment（step_c は executed のはず）なのに step_c の
  # execution_state を skipped にした矛盾 run（障害欠損弁別ケース）。
  def build_treatment_inconsistent_run(dir)
    root = Pathname(dir)
    FileUtils.cp_r((LOCAL + "valid_runtime_run").to_s + "/.", root.to_s)
    sc = root + "steps" + "step_c_judgment.json"
    data = JSON.parse(sc.read)
    data["execution_state"] = "skipped"
    sc.write(JSON.pretty_generate(data))
    rc = root + "review_case.json"
    rcd = JSON.parse(rc.read)
    rcd["step_records"].each do |s|
      s["step_status"] = "skipped" if s["step_id"] == "step_c"
    end
    rc.write(JSON.pretty_generate(rcd))
  end
end
